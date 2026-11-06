# Spark 学习指南（大数据工程 - 实战架构方向）

> [!note] 学习路线定位
> 你的背景更偏 Java 后端、数仓、Doris、Kafka、IoT 数据处理、异步任务与海量统计，这种情况下，学习 Spark 最适合走**"数据工程 + 数仓计算 + 离线/准实时分析"**路线，而不是纯算法/ML 路线。

你真正需要掌握的是：

- Spark 如何处理 TB/PB 级数据
- Spark SQL 如何替代复杂 MySQL/Doris 批处理
- Spark 如何和 Kafka / Hive / Iceberg / Doris 协同
- Spark 如何优化 Shuffle / Join / 倾斜 / 内存
- Spark 如何做车辆轨迹、围栏、统计任务等海量计算

本文包含以下内容：

- 学习路径与阶段目标
- 技术栈地图与学习顺序
- 每阶段实战项目与推荐资料
- 你当前场景对应的 Spark 落地方向

---

## 一、先理解 Spark 到底是什么

Spark 本质是一个**分布式计算引擎**，核心能力包括：分布式计算、海量数据处理、SQL 分析、批处理、流处理、机器学习、图计算。

它解决的问题——你单机 Java 只能处理百万级：

```java
for (...) {
    // 计算
}
```

而 Spark SQL 可以处理**亿级、百亿级、TB/PB 级**数据：

```sql
SELECT ...
GROUP BY ...
JOIN ...
```

---

## 二、Spark 技术体系

你必须先建立全景图。

### Spark 生态核心

```text
                Spark
                   |
    --------------------------------
    |              |               |
 Spark SQL    Spark Core     Structured Streaming
    |
 DataFrame / Dataset
```

### 各模块重要度

| 模块 | 重要度 |
| --- | --- |
| Spark SQL | ★★★★★ |
| DataFrame | ★★★★★ |
| Structured Streaming | ★★★★ |
| RDD | ★★ |
| MLlib | ★ |
| GraphX | ★ |

> [!tip] 现在企业里 90% Spark 工作是 Spark SQL + DataFrame，RDD 已经不是重点。

---

## 三、推荐学习路线

### 第一阶段：大数据基础（1~2 周）

> 目标：先建立"大数据世界观"

#### 1. Hadoop 生态

理解各组件作用：

| 组件 | 作用 |
| --- | --- |
| HDFS | 分布式存储 |
| YARN | 资源调度 |
| Hive | 数据仓库 |
| MapReduce | 旧计算模型 |
| Spark | 新计算引擎 |

不用深入 Hadoop 开发，但必须知道 **Spark 为什么比 MapReduce 快**。

#### 2. Linux 基础

必须会的基本命令：

```bash
grep awk sed tail less find tar vim
```

以及排查工具：

```bash
jps jstack top free iostat netstat
```

因为 Spark 问题最终都在 Linux 上排查。

#### 3. JVM 基础

你已经有 Java 背景，重点补：堆内存、GC、OOM、对象序列化、Off-Heap、Netty。Spark 很多性能问题本质是 JVM 问题。

---

### 第二阶段：Spark SQL 入门（核心阶段，2~4 周）

这是最关键阶段。

#### 1. 安装 Spark

- 建议 Docker 或本地 standalone，不建议一开始搞 Hadoop 集群
- 推荐 Spark 3.5+

#### 2. 学习 DataFrame

```python
df.select()
df.filter()
df.groupBy()
df.join()
```

这是 Spark 真正日常开发。

#### 3. Spark SQL

必须重点学：

```sql
SELECT GROUP BY JOIN WINDOW CTE UNION
```

企业 70% Spark 开发本质就是 SQL。

#### 4. 学习执行计划

```python
df.explain(True)
```

理解 Logical Plan、Physical Plan、Catalyst Optimizer —— 这是 Spark 灵魂。

#### 5. Parquet / ORC

| 格式 | 是否列式 |
| --- | --- |
| CSV | 否 |
| JSON | 否 |
| Parquet | 是 |
| ORC | 是 |

理解为什么列式存储快。

---

### 第三阶段：Spark 原理（核心进阶）

#### 1. Spark 执行模型

必须理解 Driver → Executor → Task → Stage → Job → Shuffle，这是面试必问。

#### 2. 宽依赖 / 窄依赖

| 类型 | 是否 Shuffle |
| --- | --- |
| map | 否 |
| filter | 否 |
| join | 是 |
| groupBy | 是 |

#### 3. Shuffle 原理

Shuffle 是 Spark 性能核心，必须掌握：Shuffle Write、Shuffle Read、Sort Shuffle、Spill、Shuffle 文件。

#### 4. 内存模型

理解 Execution Memory 和 Storage Memory，以及 cache、persist、broadcast 的使用。

---

### 第四阶段：Spark 性能优化（最重要）

> [!important] 这一阶段决定你是不是"真正会 Spark"。

#### 1. 数据倾斜（企业最大问题）

例如 `group by vehicle_id`，某些热点车数据巨大。解决方案：salting（加盐）、随机前缀、两阶段聚合、skew join。

#### 2. Join 优化

| Join 类型 | 使用场景 |
| --- | --- |
| Broadcast Join | 小表 |
| Shuffle Hash Join | 中等 |
| Sort Merge Join | 大表 |

#### 3. 分区优化

重点掌握 `repartition` 和 `coalesce`，理解小文件问题、分区数、并行度。

#### 4. AQE（Adaptive Query Execution）

Spark 3 核心特性：

```sql
spark.sql.adaptive.enabled=true
```

功能：自动优化 Join、自动处理倾斜、自动调整分区。

#### 5. Cache

理解什么时候用 `df.cache()`，什么时候不能 cache。

---

### 第五阶段：Structured Streaming（强烈推荐）

你有 Kafka、MQTT、车辆实时数据、在线状态、IoT 背景，非常适合学。

#### 1. Kafka + Spark Streaming

```python
.readStream
.writeStream
```

#### 2. Watermark

解决乱序和延迟数据问题。

#### 3. 状态计算

例如：在线车辆数、轨迹聚合、5 分钟窗口。

---

### 第六阶段：湖仓体系（未来重点）

Spark 已经不只是计算引擎，而是 Lakehouse 架构的核心。

| 技术 | 重要度 |
| --- | --- |
| Iceberg | ★★★★★ |
| Hudi | ★★★★ |
| Delta Lake | ★★★★ |

未来趋势：`Kafka → Spark → Iceberg → Doris`

---

## 四、你当前场景最适合 Spark 的方向

### 1. 海量车辆轨迹分析

围栏计算、轨迹聚合、停留点识别、里程统计 —— Spark 非常适合。

### 2. Doris 前置 ETL

你现在很多复杂 SQL，实际上更适合 `Spark 预聚合 → Doris 查询`，而不是 Doris 实时跑超复杂 SQL。

### 3. Geohash 空间计算

你最近一直在研究 GeoHash、ST_CONTAINS、围栏，Spark + Sedona 非常适合。重点技术：Apache Sedona、空间索引。

### 4. 批量统计任务

"用户创建统计任务"是典型 Spark 场景：`任务提交 → Spark Job → 离线计算 → 结果入 Doris`

---

## 五、推荐学习语言

### 第一推荐：PySpark

Spark 官方生态最好、教程最多、DataFrame API 最成熟、AI/Data 工程生态统一。即使你是 Java 后端，也建议 Spark 主学 PySpark。

### 第二推荐：Spark SQL

很多企业 90% 逻辑是 SQL。

### 第三推荐：Scala（可选）

现在已经不是必须，除非需要深度 Spark 开发、Spark 插件、Catalyst 扩展，否则没必要先学 Scala。

---

## 六、推荐学习顺序

> [!warning] 不要先学 RDD！很多人路线错了。

正确顺序：

```text
Spark SQL → DataFrame → 执行计划 → Shuffle → 优化 → Streaming → 湖仓
```

---

## 七、实战项目

### 项目 1：日志分析（入门）

实现 PV/UV、TopN、留存统计。

### 项目 2：车辆轨迹分析（非常适合你）

实现轨迹切分、停留点、围栏判断、里程统计。

### 项目 3：Kafka 实时流

实现实时在线车辆统计、实时告警、窗口聚合。

### 项目 4：Doris + Spark

实现 Spark ETL、Doris 导入、宽表生成。

---

## 八、核心能力清单

> [!important] 真正核心能力不是 `df.select()`，而是以下这些。

1. **看执行计划** —— `df.explain(True)`
2. **能发现 Shuffle**
3. **能发现数据倾斜**
4. **能优化 Join**
5. **能设计分区**
6. **能控制小文件**
7. **能控制内存**

---

## 九、推荐资料

### 视频入门（B 站）

搜索：Spark 尚硅谷、黑马 Spark、Spark3 教程

### 书籍

| 阶段 | 书名 | 说明 |
| --- | --- | --- |
| 入门 | 《Spark 快速大数据分析》 | 非常适合入门 |
| 进阶 | 《Spark SQL 内核剖析》 | 非常好 |
| 原理 | 《Spark 内核设计的艺术》 | 偏源码 |

### 官方文档（必须）

[Apache Spark Documentation](https://spark.apache.org/docs/latest/)

重点看：SQL、Structured Streaming、Performance Tuning

---

## 十、实用学习路径（按月规划）

### 第一个月

**目标：会写 Spark SQL**

学习：DataFrame、SQL、Parquet、explain

### 第二个月

**目标：理解 Spark 原理**

学习：Shuffle、Stage、Join、AQE、倾斜

### 第三个月

**目标：做真实项目**

实现：Kafka 实时流、车辆轨迹、围栏统计、Doris ETL

### 第四个月

**目标：企业级能力**

学习：Iceberg、Streaming、湖仓、调优、资源管理

---

## 十一、你当前最值得切入的 Spark 场景

按收益排序：

| 场景 | 推荐度 |
| --- | --- |
| 车辆轨迹离线统计 | ★★★★★ |
| 围栏空间计算 | ★★★★★ |
| Doris ETL | ★★★★★ |
| Kafka 实时统计 | ★★★★ |
| 风险指标批处理 | ★★★★ |
| Geohash 聚合 | ★★★★ |
| IoT 在线状态流计算 | ★★★★ |

---

## 十二、给你的建议

> [!tip] 先把 Spark 当"分布式 SQL 引擎"，这是最快进入生产的路线。

你现在**不要**：深入 RDD、深入 Scala、上来研究源码。

等你真正开始遇到 Shuffle 瓶颈、Executor OOM、数据倾斜、小文件爆炸，再深入内核，这样效率最高。
