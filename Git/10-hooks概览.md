---
title: Git 10 · hooks 概览
tags:
  - 技术学习
  - git
date: 2026-11-06
status: active
---

# 10 · hooks 概览

> 上一篇：[tag](09-tag.md) · 下一篇：[最佳实践与常见坑](11-最佳实践与常见坑.md)

## 1. 是什么

hook = Git 在特定事件**前后**调用的脚本。仓库模板在 `.git/hooks/*.sample`，去掉 `.sample` 并赋予可执行权限即可生效。

**默认 hooks 只在本地**，不会随 `clone` 带给别人（`.git` 不共享）。团队要统一时用：

- 文档约定 + 安装脚本
- [Husky](https://typicode.github.io/husky/) / pre-commit 框架等把 hook 装进开发环境
- 服务端：托管平台的 webhook、CI、或自建 git 服务器的 `update`/`pre-receive`

## 2. 常见客户端 hook

| Hook | 时机 | 典型用途 |
|------|------|----------|
| `pre-commit` | commit 生成前 | lint、格式化、禁止大文件 |
| `prepare-commit-msg` | 说明模板就绪时 | 插入分支名、Issue 号 |
| `commit-msg` | 写完说明后 | 校验 conventional commit |
| `post-commit` | 提交完成后 | 通知（少用） |
| `pre-push` | push 前 | 跑单测、禁止 push 到 main |

示例（示意，勿照搬密钥逻辑）：

```bash
# .git/hooks/pre-commit
#!/bin/sh
npm test --silent || exit 1
```

失败时 Git 中止操作；可用 `git commit --no-verify` **跳过**（紧急时，勿当习惯）。

## 3. 服务端 hook（了解）

| Hook | 作用 |
|------|------|
| `pre-receive` / `update` | 拒绝不符合规则的推送（保护分支、禁止 force） |
| `post-receive` | 部署通知、触发 CI |

托管平台（GitHub/GitLab）上多数用分支保护 + CI 代替裸 hook。

## 4. 实践注意

- hook 太重会拖慢每次 commit；重测试放 CI / `pre-push`。
- 路径、Node 版本在 GUI 客户端里可能与终端不同，导致「终端能过、GUI 不过」。
- 不要在 hook 里写死本机绝对路径或密钥。

## 5. 小结

- hooks 是自动化闸门；本地与远端职责分开。
- 团队共享靠工具安装，不靠复制 `.git/hooks`。
- `--no-verify` 存在但不该成为日常逃逸口。
