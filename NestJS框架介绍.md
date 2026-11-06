---
title: NestJS 框架介绍
tags:
  - nodejs
  - nestjs
  - typescript
  - 后端框架
date: 2026-08-13
---

# NestJS 框架介绍

> 整理日期：2026-08-13
> 定位：Node.js 服务端框架入门资料

**NestJS** 是一个用于构建高效、可扩展 Node.js 服务端应用的框架，基于 TypeScript，采用**渐进式架构**（底层 HTTP 层可切换 Express 或 Fastify）。

## 核心特点

| 特点 | 说明 |
|------|------|
| 架构风格 | 借鉴 Angular 的分层思想：模块化（Module）、依赖注入（DI）、装饰器驱动 |
| 语言 | TypeScript 原生支持，也兼容纯 JavaScript |
| 底层 | 默认 Express，可切换 Fastify（性能更高） |
| 设计模式 | 控制器（Controller）→ 服务（Service）→ 数据访问（Repository/DAO），与 Spring 分层极其相似 |
| 可测试性 | 内置依赖注入容器，方便单元测试和模块替换 |

## 核心概念

- **Module（模块）**：用 `@Module()` 组织代码，每个功能一个模块，可导入/导出，是架构的最小单元
- **Controller（控制器）**：`@Controller('users')` + `@Get()` / `@Post()` 等装饰器定义路由
- **Provider（提供者）**：`@Injectable()` 标记的服务类，通过构造函数注入
- **装饰器体系**：`@Body()`、`@Param()`、`@Query()`、`@Headers()` 等自动绑定请求数据

## 典型代码结构

```typescript
// users.module.ts
@Module({
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}

// users.controller.ts
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }
}
```

## 生态能力

- **数据库**：TypeORM / Prisma / MikroORM，支持 MySQL、PostgreSQL、MongoDB 等
- **校验**：`class-validator` + `class-transformer` 的 DTO 管道校验（`ValidationPipe`）
- **认证授权**：Passport 策略、JWT、Guard 守卫
- **微服务**：内置微服务传输层（TCP、Redis、gRPC、Kafka、MQTT）
- **其他**：WebSocket（`@nestjs/websockets`）、定时任务（`@nestjs/schedule`）、配置（`@nestjs/config`）、日志、缓存、Swagger 集成等

## 适用场景

- 中大型 Node.js 后端项目，需要**清晰架构**和团队协作规范
- 从 Java/Spring 转 Node 的团队（心智模型几乎一致，学习成本低）
- 需要微服务、GraphQL、WebSocket 等复杂能力的服务端

## 与 Spring Boot 的对照

| Spring Boot | NestJS |
|-------------|--------|
| `@RestController` | `@Controller()` |
| `@Service` | `@Injectable()` |
| `@Autowired` | 构造函数注入 |
| `@Configuration` + Bean | `@Module` + Provider |
| AOP 切面 | 拦截器（Interceptor）/ 中间件 |
| Spring Security | Guard + Passport |
| MyBatis / JPA | TypeORM / Prisma |

NestJS 的核心卖点就是**在 Node 世界里提供 Spring 级别的工程化体验**——如果团队熟悉 Java 后端，NestJS 是 Node 技术栈里最平滑的选择。

## 延伸资料

- 社区近期动态（RBAC/多租户、Swagger 体验等）：NestJS 社区近 30 天研究
