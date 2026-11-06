# Liquibase 与 Node.js 数据库版本管理实践

## 1. Liquibase 概述与核心原理

Liquibase 是一款开源的数据库版本控制（Database Schema Migration）工具，其核心目标是将数据库结构变更像软件代码一样纳入版本管理、审查和自动化发布。

### 1.1 核心概念

* **Changeset（变更集）**：数据库变更的最小逻辑单元。由 `id`、`author` 唯一标识，包含具体的 DDL/DML 操作及回滚逻辑（`rollback`）。
* **Changelog（变更日志）**：管理并组织一组 Changeset 的文件，支持 XML、YAML、JSON 或 Formatted SQL 格式。
* **DATABASECHANGELOG（元数据表）**：Liquibase 在目标数据库中维护的专用追踪表。每次执行变更集前，Liquibase 会先查询此表判断是否已执行（避免重复执行）；执行成功后写入记录（记录执行时间、哈希校验码 `MD5SUM`、执行者等）。
* **DATABASECHANGELOGLOCK（锁表）**：在执行迁移期间提供分布式锁，防止多个节点或进程并发执行变更引起冲突。

---

## 2. Liquibase 多语言与技术栈支持全景

Liquibase 的核心引擎是基于 **Java (JVM)** 构建的。针对不同编程语言与运行环境，支持方式可划分为“原生嵌入”与“外部驱动/包装器”两大类：

| 支持层次 | 编程语言 / 生态 | 适用场景与集成方式 |
| :--- | :--- | :--- |
| **原生一等公民<br>(JVM 嵌入式)** | **Java, Kotlin, Scala, Groovy** | **进程内直接嵌入执行**。<br>• Spring Boot 原生启动器：`spring-boot-starter-liquibase`<br>• Quarkus, Micronaut 等框架深度集成<br>• Maven/Gradle 构建插件：`liquibase-maven-plugin`、`liquibase-gradle-plugin` |
| **语言封装库<br>(Wrapper)** | **Node.js / TypeScript** | 通过 npm 包 `liquibase` 包装 CLI / JAR，需宿主环境安装 JRE。 |
| | **Python** | 通过 PyPI 包 `pyliquibase`、`liquibase` 包装执行。 |
| | **.NET / C#** | 通过 NuGet 包装器或构建任务（MSBuild）调用 CLI。 |
| | **PHP** | 通过 Composer 包装库调用 CLI。 |
| **云原生 / 外部驱动<br>(语言无关)** | **Go, Rust, Python, Node.js 等任意语言** | **推荐在微服务与容器化环境中采用**：<br>• **独立 CLI**：通过官方二进制 CLI 运行 `liquibase update`<br>• **Docker 容器**：使用官方镜像 `liquibase/liquibase`<br>• **K8s InitContainer**：在业务容器启动前通过 InitContainer 完成变更<br>• **CI/CD Pipeline**：在代码部署流水线中作为发布前置门禁 |

### 2.1 Changelog 支持的文件格式

无论上层使用何种语言，变更日志均支持：
1. **Formatted SQL**（在 `.sql` 中使用 `--changeset author:id` 注释声明，对 DBA 和 SQL 开发者最友好）。
2. **YAML / JSON**（轻量易读，适合微服务与自动化场景）。
3. **XML**（功能最全的原生格式，支持最完整的标签与约束校验）。
4. **Groovy DSL**（JVM 生态，支持动态逻辑）。

---

## 3. Liquibase 在 Node.js 生态中的支持与现状

### 3.1 npm 包（`liquibase`）的工作机制

在 Node.js 中安装 `npm install liquibase` 后，可通过 Node.js 代码触发迁移：

```typescript
import { Liquibase } from 'liquibase';

const instance = new Liquibase({
  changeLogFile: 'src/database/changelog.xml',
  url: 'jdbc:mysql://localhost:3306/demo_db',
  username: 'root',
  password: 'password',
  // ...
});

await instance.update();
```

* **本质**：该 npm 包不是用 JavaScript 重写的 Liquibase 引擎，而是通过 Node.js 的 `child_process.spawn()` 去唤起底层的 Java JAR 包或二进制 CLI。
* **局限性**：
  * **强依赖 JRE**：运行环境（服务器或 Docker 容器）必须额外安装 Java 运行环境（几百 MB）。
  * **容器体积膨胀**：对于轻量的 Node.js Alpine/Slim 基础镜像，安装 OpenJDK 会大幅增加镜像体积与构建耗时。
  * **调试复杂**：Node 异常栈与底层 Java CLI 输出割裂，错误定位路径长。

---

## 4. 最佳实践：Node.js 项目中的“兼顾兼容与轻量”方案

在企业级微服务演进中（例如从 Java 单体拆分出 Node.js 服务，或纯 Node.js 服务需兼容公司既有 Liquibase 规范），常见的选型与实施模式包括：

### 4.1 方案对比

| 方案 | 实现方式 | 优点 | 缺点 | 适用场景 |
| :--- | :--- | :--- | :--- | :--- |
| **方案 A：npm 封装库** | `npm i liquibase`，Node 内调用 | 支持完整 Liquibase 高级特性 | 镜像需装 Java，臃肿 | 开发环境全栈依赖 Java 的团队 |
| **方案 B：InitContainer / CI/CD 独立执行** | 官方 Docker 镜像作为 K8s InitContainer | Node 镜像纯净，完全解耦，支持全特性 | 本地开发启动需额外编排容器 | 生产规范严格的 K8s 云原生部署 |
| **方案 C：规范兼容 + 自研轻量 Runner（本项目实践）** | 沿用 `DATABASECHANGELOG` 表结构，TypeScript 编写 Runner 与启动校验 | **零 Java 依赖，镜像极小，启动秒级校验，开发体验一致** | 仅支持 SQL 格式，需自行维护执行器 | 纯 Node.js/TS 模块化项目，追求极致轻量与可控 |

---

### 4.2 本项目（示例项目）的落地设计剖析

本项目在 `demo-app-backend` 中采用了 **方案 C**：

#### 1. 元数据与 SQL 格式完全兼容 Liquibase
数据库初始化时创建标准的 `DATABASECHANGELOG` 表：
```sql
CREATE TABLE IF NOT EXISTS `DATABASECHANGELOG` (
  `ID` VARCHAR(255) NOT NULL,
  `AUTHOR` VARCHAR(255) NOT NULL,
  `FILENAME` VARCHAR(255) NOT NULL,
  `DATEEXECUTED` DATETIME NOT NULL,
  `ORDEREXECUTED` INT NOT NULL,
  `EXECTYPE` VARCHAR(10) NOT NULL,
  `MD5SUM` VARCHAR(35) NULL,
  `DESCRIPTION` VARCHAR(255) NULL,
  `COMMENTS` VARCHAR(255) NULL,
  `LIQUIBASE` VARCHAR(20) NULL,
  `DEPLOYMENT_ID` VARCHAR(10) NULL,
  PRIMARY KEY (`ID`, `AUTHOR`, `FILENAME`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
每个迁移文件（如 `056_feature_ledger_publish.sql`）末尾均由 SQL 自带写入：
```sql
INSERT IGNORE INTO `DATABASECHANGELOG`
  (`ID`, `AUTHOR`, `FILENAME`, `DATEEXECUTED`, `ORDEREXECUTED`, `EXECTYPE`, `DESCRIPTION`, `COMMENTS`)
VALUES
  ('20260923-01', 'demo-author', 'node/database/sql/056_feature_ledger_publish.sql', NOW(), 56,
   'EXECUTED', 'Add feature ledger publish status and initial project backfill', 'manual');
```

#### 2. 服务启动只校验，不自动执行变更
后端遵循严谨的架构门禁：**服务启动时只做只读校验，绝对不隐式执行 DDL 修改生产库**。
* `DatabaseSchemaValidator` 会在启动时查询 `DATABASECHANGELOG` 表。
* 检查当前库已应用的 Changeset 是否覆盖代码中声明的最新基线（`requiredChangeset: 20260923-01`）。
* 如果存在未应用的变更集，**启动快速失败（Fail-Fast）**，防止业务代码向结构不匹配的数据库写入脏数据。

#### 3. 显式迁移脚本（Migration Runner）
通过统一的 TypeScript 脚本进行受控迁移：
```bash
# 预览迁移计划（不执行修改）
npx tsx scripts/apply-database-changesets.ts --dry-run

# 执行迁移
npm run migrate
# 或
npx tsx scripts/apply-database-changesets.ts
```

---

## 5. 总结

1. **核心定位**：Liquibase 是一套由 Java 驱动的数据库版本管理体系；对 JVM 生态是一等公民原生集成，对其他语言主要通过 CLI / Docker 或子进程 Wrapper 协同。
2. **Node.js 选型建议**：
   * 如果仅在 **CI/CD 或 Kubernetes 部署** 中执行变更，推荐官方 `liquibase/liquibase` 容器或 InitContainer。
   * 如果追求 **纯 TypeScript / Node 本地自洽与轻量容器**，推荐“**复用 Liquibase `DATABASECHANGELOG` 表结构 + TS 脚本受控执行 + 启动严格只读校验**”模式，兼顾工业标准与轻量可控。
