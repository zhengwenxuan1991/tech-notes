---
title: NestJS YAML 配置管理指南
tags:
  - nodejs
  - nestjs
  - yaml
  - 配置管理
  - 研发规范
aliases:
  - NestJS YAML 配置规范
  - NestJS 配置文件指南
created: 2026-08-25
updated: 2026-08-25
status: draft
---

# NestJS YAML 配置管理指南

> [!abstract] 文档定位
> 本文约定 NestJS 项目只使用 YAML 作为业务运行配置文件，不从 `.env` 或操作系统环境变量读取配置。数据库密码、JWT 密钥和第三方 Token 等敏感信息也由 YAML 统一管理。

项目整体目录和模块边界参见 [[NestJS项目结构与模块划分指南]]。

## 1. 方案概述

NestJS 的 `@nestjs/config` 默认使用 dotenv 加载 `.env` 文件，但也允许通过自定义配置工厂加载 YAML。YAML 不会被 NestJS 自动解析，需要使用 `js-yaml` 读取后，通过 `ConfigModule.forRoot({ load: [...] })` 注册。

本项目采用以下固定链路：

```mermaid
flowchart LR
    YAML[config.yaml] --> Loader[YAML 加载器]
    Loader --> Validator[配置校验]
    Validator --> ConfigModule[ConfigModule]
    ConfigModule --> ConfigService[ConfigService]
    ConfigService --> Modules[业务与基础设施模块]
```

## 2. 安装依赖

```bash
npm install @nestjs/config js-yaml
npm install --save-dev @types/js-yaml
```

## 3. 目录结构

```text
src/
├── config/
│   ├── config.yaml
│   ├── configuration.ts
│   ├── config.types.ts
│   └── config.validation.ts
├── app.module.ts
└── main.ts

nest-cli.json
```

| 文件 | 职责 |
|---|---|
| `config.yaml` | 存放全部运行配置，包括密钥和密码 |
| `configuration.ts` | 读取 YAML，调用校验器并返回配置对象 |
| `config.types.ts` | 定义完整配置结构 |
| `config.validation.ts` | 在应用启动时校验 YAML 内容 |
| `nest-cli.json` | 将 YAML 复制到编译产物目录 |

## 4. YAML 配置文件

```yaml
# src/config/config.yaml

app:
  name: vehicle-network-api
  host: 0.0.0.0
  port: 3000
  globalPrefix: api

database:
  type: postgres
  host: 127.0.0.1
  port: 5432
  name: vehicle_network
  username: postgres
  password: change-me
  ssl: false

redis:
  host: 127.0.0.1
  port: 6379
  password: change-me
  database: 0

jwt:
  secret: replace-with-a-long-random-secret
  expiresInSeconds: 7200

thirdParty:
  map:
    baseUrl: https://example.com/api
    accessKey: replace-with-access-key
    secretKey: replace-with-secret-key

logging:
  level: info
```

YAML 书写时遵守以下规则：

- 使用空格缩进，不使用 Tab。
- 同一层级保持相同缩进，建议每层两个空格。
- 端口、超时时间和数量使用数字，开关使用 `true` 或 `false`。
- 包含 `:`、`#`、前后空格或特殊字符的字符串应使用引号。
- 配置键使用 `camelCase`，并按 `app`、`database`、`redis` 等技术或功能域分组。

> [!warning] 密钥保护
> 密钥和密码按本规范写入 YAML，因此必须对真实配置文件设置严格的文件权限、部署权限和日志脱敏规则。禁止在日志、异常信息或健康检查接口中输出完整配置对象。

## 5. 配置类型

```typescript
// src/config/config.types.ts

export interface AppConfig {
  app: {
    name: string;
    host: string;
    port: number;
    globalPrefix: string;
  };
  database: {
    type: 'postgres';
    host: string;
    port: number;
    name: string;
    username: string;
    password: string;
    ssl: boolean;
  };
  redis: {
    host: string;
    port: number;
    password: string;
    database: number;
  };
  jwt: {
    secret: string;
    expiresInSeconds: number;
  };
  thirdParty: {
    map: {
      baseUrl: string;
      accessKey: string;
      secretKey: string;
    };
  };
  logging: {
    level: 'debug' | 'info' | 'warn' | 'error';
  };
}
```

TypeScript 接口只提供编译期类型约束，不会校验 YAML 的实际内容，因此仍需要启动时校验。

## 6. 启动时校验

```typescript
// src/config/config.validation.ts

import type { AppConfig } from './config.types';

export function validateConfig(config: AppConfig): AppConfig {
  if (!config.app?.name) {
    throw new Error('config.app.name 不能为空');
  }

  if (!Number.isInteger(config.app.port) || config.app.port < 1 || config.app.port > 65535) {
    throw new Error('config.app.port 必须是 1—65535 之间的整数');
  }

  if (!config.database?.host || !config.database?.username || !config.database?.password) {
    throw new Error('database.host、database.username 和 database.password 不能为空');
  }

  if (!config.jwt?.secret || config.jwt.secret.length < 32) {
    throw new Error('config.jwt.secret 不能为空且长度不能小于 32');
  }

  return config;
}
```

> [!note] 校验边界
> `ConfigModule` 的 `validationSchema` 主要用于校验环境变量。自定义 YAML 配置应在配置工厂中显式校验，保证配置错误时应用立即停止启动。

## 7. 加载 YAML

```typescript
// src/config/configuration.ts

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import * as yaml from 'js-yaml';
import type { AppConfig } from './config.types';
import { validateConfig } from './config.validation';

const YAML_CONFIG_FILENAME = 'config.yaml';

export default (): AppConfig => {
  const configPath = join(__dirname, YAML_CONFIG_FILENAME);
  const fileContent = readFileSync(configPath, 'utf8');
  const config = yaml.load(fileContent) as AppConfig;

  return validateConfig(config);
};
```

加载器使用 `__dirname` 定位与编译后的 `configuration.js` 同目录的 `config.yaml`，避免应用从不同工作目录启动时出现路径错误。

## 8. 注册 ConfigModule

```typescript
// src/app.module.ts

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      ignoreEnvFile: true,
      skipProcessEnv: true,
      load: [configuration],
    }),
  ],
})
export class AppModule {}
```

| 选项 | 作用 |
|---|---|
| `isGlobal: true` | 全局注册 `ConfigService` |
| `ignoreEnvFile: true` | 不加载 `.env` 文件 |
| `skipProcessEnv: true` | `ConfigService#get` 不再回退读取操作系统环境变量 |
| `load: [configuration]` | 加载并注册 YAML 配置对象 |

这些选项确保业务配置只来自 `config.yaml`。

## 9. 读取配置

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { AppConfig } from './config/config.types';

@Injectable()
export class DatabaseService {
  constructor(
    private readonly configService: ConfigService<AppConfig, true>,
  ) {}

  connect() {
    const host = this.configService.get('database.host', { infer: true });
    const port = this.configService.get('database.port', { infer: true });
    const password = this.configService.get('database.password', { infer: true });

    // 仅将密码传给数据库驱动，不得记录到日志。
    return { host, port, password };
  }
}
```

启动入口也必须从 `ConfigService` 读取：

```typescript
// src/main.ts

import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import type { AppConfig } from './config/config.types';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService<AppConfig, true>);

  app.setGlobalPrefix(
    configService.get('app.globalPrefix', { infer: true }),
  );

  await app.listen(
    configService.get('app.port', { infer: true }),
    configService.get('app.host', { infer: true }),
  );
}

void bootstrap();
```

## 10. 异步模块中使用

数据库、Redis、JWT 等动态模块应使用 `forRootAsync()` 从 `ConfigService` 取值：

```typescript
JwtModule.registerAsync({
  inject: [ConfigService],
  useFactory: (configService: ConfigService<AppConfig, true>) => ({
    secret: configService.get('jwt.secret', { infer: true }),
    signOptions: {
      expiresIn: configService.get('jwt.expiresInSeconds', { infer: true }),
    },
  }),
});
```

禁止各业务模块自行读取 `config.yaml`。YAML 只由统一加载器解析一次，各模块通过 `ConfigService` 访问配置。

## 11. 构建时复制 YAML

Nest CLI 不会默认复制非 TypeScript 文件，需要在 `nest-cli.json` 中显式声明：

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "sourceRoot": "src",
  "compilerOptions": {
    "deleteOutDir": true,
    "assets": [
      {
        "include": "config/*.yaml",
        "watchAssets": true
      }
    ]
  }
}
```

执行 `npm run build` 后应得到：

```text
dist/
├── config/
│   ├── config.yaml
│   ├── configuration.js
│   ├── config.types.js
│   └── config.validation.js
└── main.js
```

> [!warning] 部署检查
> 如果未复制 YAML，本地开发可能正常，但运行 `dist/main.js` 时会因找不到 `dist/config/config.yaml` 而启动失败。CI 应在构建后检查该文件存在。

## 12. 多环境部署

本方案不使用环境变量决定配置文件。开发、测试和生产环境使用相同的目标文件名 `config.yaml`，由构建或部署流程选择对应内容并将其放入 `dist/config/config.yaml`。

```text
部署包/
├── development/config.yaml
├── test/config.yaml
└── production/config.yaml
```

应用始终只读取一个固定路径，不在代码中判断当前环境。这样可以保持配置来源单一，也避免 YAML 和其他配置源互相覆盖。

## 13. 安全与运维规则

由于 YAML 中包含真实密钥，必须遵守：

1. 仅允许应用运行账号和授权的部署账号读取生产 YAML。
2. 生产配置不进入普通源码仓库；仓库中可保留字段完整、使用占位值的示例 YAML。
3. 部署时通过受控制的制品库、配置中心或 Kubernetes Secret Volume 提供完整 YAML 文件。
4. 容器和主机上的 YAML 文件建议权限为 `0600`，并将所有权设置为应用运行用户。
5. 日志系统对 `password`、`secret`、`token`、`accessKey` 和 `secretKey` 等字段统一脱敏。
6. 更换密钥时更新完整 YAML，通过重启或滚动发布使新配置生效。

> [!important] 配置不会自动热更新
> 本方案在应用启动时读取 YAML。修改文件后需要重启应用，才能使新配置生效。

## 14. 检查清单

- [ ] 项目只有一个运行配置入口 `config.yaml`。
- [ ] `ConfigModule` 已设置 `ignoreEnvFile: true` 和 `skipProcessEnv: true`。
- [ ] 所有必填项、类型、范围和密钥长度都在启动时校验。
- [ ] 业务模块通过 `ConfigService` 取值，不直接解析 YAML。
- [ ] `nest-cli.json` 已配置 YAML 资源复制。
- [ ] CI 已验证 `dist/config/config.yaml` 存在且可解析。
- [ ] 生产 YAML 的读取权限和传输链路受控。
- [ ] 日志和诊断接口不会暴露密钥、密码或完整配置。

## 15. 参考资料

- [NestJS Configuration](https://docs.nestjs.com/techniques/configuration)
- [`js-yaml`](https://github.com/nodeca/js-yaml)
- [[NestJS项目结构与模块划分指南]]
