---
title: pnpm 使用指南
tags:
  - nodejs
  - pnpm
  - 包管理
aliases:
  - Node.js中的pnpm
  - pnpm指南
---

# pnpm 使用指南

## 1. pnpm 是什么

`pnpm` 是 Node.js 生态中的包管理工具，功能上和 `npm`、`yarn` 类似，用来安装依赖、管理脚本、维护锁文件和支持多包项目。

`pnpm` 的核心特点是：

- 安装速度通常较快
- 更节省磁盘空间
- 依赖结构更严格，能更早暴露错误依赖
- 对 monorepo（多包仓库）支持较好

简单理解，`pnpm` 可以看作是一个更注重性能、空间利用率和依赖规范性的 Node.js 包管理器。

> [!info]
> 如果你已经会用 `npm`，上手 `pnpm` 很快。大多数常用命令都只是把 `npm` 换成 `pnpm`。

## 2. 为什么很多项目会选择 pnpm

相比 `npm`，`pnpm` 常见优势有：

- 使用全局内容寻址存储，相同依赖不会在每个项目里重复保存
- 通过链接机制组织 `node_modules`，减少磁盘占用
- 默认依赖访问更严格，能减少“明明没声明依赖却能运行”的问题
- workspace 能力成熟，适合前端工程化和 monorepo 项目

对团队项目来说，`pnpm` 的价值通常不只是“更快”，还包括：

- 安装结果更稳定
- 锁文件一致性更好
- 多项目协作更方便

## 3. pnpm 和 npm 的主要区别

### 3.1 存储方式不同

`npm` 通常会在每个项目中都放一份依赖内容。  
`pnpm` 会把依赖内容放到统一存储中，再通过硬链接或符号链接组织到项目里。

这样做的结果是：

- 多个项目共用相同依赖时，更省磁盘
- 安装重复依赖时，通常更快

### 3.2 依赖管理更严格

有些项目虽然没有在 `package.json` 中声明某个依赖，但因为 `node_modules` 结构“碰巧能访问到”，代码依然能跑。

`pnpm` 对这类隐式依赖更敏感，更容易在开发阶段暴露问题。这通常是好事，因为它能逼着项目把依赖声明写准确。

### 3.3 锁文件不同

- `npm` 使用 `package-lock.json`
- `pnpm` 使用 `pnpm-lock.yaml`

如果团队决定使用 `pnpm`，通常应该统一提交 `pnpm-lock.yaml`，不要和其他锁文件混用。

## 4. 安装 pnpm

先确认本地已经安装 Node.js：

```bash
node -v
```

再检查是否已有 `pnpm`：

```bash
pnpm -v
```

常见安装方式：

```bash
npm install -g pnpm
```

安装完成后再次检查：

```bash
pnpm -v
```

> [!tip]
> 如果你的 Node.js 版本较新，也可以结合 `corepack` 管理 `pnpm` 版本。在团队项目里，这种方式更容易统一环境。

## 5. 常用命令速查

## 5.1 初始化项目

创建 `package.json`：

```bash
pnpm init
```

## 5.2 安装依赖

安装项目依赖：

```bash
pnpm install
```

简写：

```bash
pnpm i
```

如果项目里已经有 `package.json` 和 `pnpm-lock.yaml`，执行 `pnpm install` 就会按锁文件安装依赖。

## 5.3 添加依赖

安装生产依赖：

```bash
pnpm add axios
```

安装开发依赖：

```bash
pnpm add -D typescript vite
```

安装指定版本：

```bash
pnpm add react@18
```

## 5.4 删除依赖

```bash
pnpm remove axios
```

## 5.5 更新依赖

更新指定依赖：

```bash
pnpm update axios
```

更新全部依赖：

```bash
pnpm update
```

## 5.6 运行脚本

假设 `package.json` 中有：

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  }
}
```

运行脚本：

```bash
pnpm run dev
pnpm run build
```

很多常用脚本可以省略 `run`：

```bash
pnpm dev
pnpm build
```

## 5.7 执行本地命令

执行项目内依赖提供的命令：

```bash
pnpm exec tsc --version
pnpm exec eslint .
```

这适合避免全局安装工具。

## 6. package.json 中的常见配合方式

一个典型 Node.js 项目通常至少会有：

- `package.json`：项目信息、依赖、脚本
- `pnpm-lock.yaml`：依赖锁文件
- `node_modules`：安装后的依赖目录

示例：

```json
{
  "name": "demo-project",
  "version": "1.0.0",
  "scripts": {
    "dev": "node index.js",
    "test": "vitest"
  },
  "dependencies": {
    "axios": "^1.0.0"
  },
  "devDependencies": {
    "vitest": "^1.0.0"
  }
}
```

## 7. pnpm workspace 是什么

当一个仓库里包含多个 Node.js 子项目时，通常会用到 workspace。

例如：

- 一个前端项目
- 一个后台管理项目
- 一个公共组件包
- 一个共享工具包

这时可以使用 `pnpm workspace` 统一管理依赖和脚本。

目录示例：

```text
my-monorepo/
├── package.json
├── pnpm-workspace.yaml
├── apps/
│   ├── web/
│   └── admin/
└── packages/
    └── shared/
```

`pnpm-workspace.yaml` 示例：

```yaml
packages:
  - apps/*
  - packages/*
```

这样 `pnpm` 就知道哪些目录属于同一个工作区。

常见收益：

- 统一安装依赖
- 统一执行脚本
- 本地包互相引用更方便
- 更适合大型前端工程

## 8. npm 和 pnpm 命令对照

| 场景 | npm | pnpm |
|------|------|------|
| 安装依赖 | `npm install` | `pnpm install` |
| 添加依赖 | `npm install axios` | `pnpm add axios` |
| 添加开发依赖 | `npm install -D vite` | `pnpm add -D vite` |
| 删除依赖 | `npm uninstall axios` | `pnpm remove axios` |
| 运行脚本 | `npm run dev` | `pnpm dev` |
| 执行本地命令 | `npx eslint .` | `pnpm exec eslint .` |

如果你原来习惯 `npm`，记住下面几条就够了：

- `npm install xxx` 对应 `pnpm add xxx`
- `npm uninstall xxx` 对应 `pnpm remove xxx`
- `npx xxx` 在很多场景下可对应 `pnpm exec xxx`

## 9. 日常使用建议

### 9.1 团队内统一包管理工具

一个项目最好统一使用一种包管理工具。

如果决定使用 `pnpm`，建议：

- 提交 `pnpm-lock.yaml`
- 不再提交 `package-lock.json` 或 `yarn.lock`
- README 中明确写清楚安装和启动命令

### 9.2 不要随意删除锁文件

锁文件的作用是保证团队成员和 CI 安装出一致的依赖结果。  
除非明确要重新解析依赖，否则不要随意删除 `pnpm-lock.yaml`。

### 9.3 优先使用本地依赖命令

例如不要全局安装 `eslint`、`typescript`、`vite` 后再直接执行，优先使用：

```bash
pnpm exec eslint .
pnpm exec tsc
pnpm exec vite
```

这样更容易保证团队环境一致。

## 10. 一个简单的上手流程

```bash
# 1. 初始化项目
pnpm init

# 2. 安装依赖
pnpm add express

# 3. 安装开发依赖
pnpm add -D nodemon

# 4. 安装项目全部依赖
pnpm install

# 5. 启动脚本
pnpm run dev
```

## 11. 总结

`pnpm` 是一个适合现代 Node.js 开发的包管理工具，特别适合下面几类场景：

- 想提升依赖安装速度
- 想减少磁盘占用
- 想让依赖管理更规范
- 项目是 monorepo 或未来可能演进成 monorepo

如果你只是做普通 Node.js 项目，`pnpm` 也完全值得使用；如果你在做前端工程化、多包仓库或团队协作项目，`pnpm` 的优势会更明显。
