---
title: Git 09 · tag 标签
tags:
  - 技术学习
  - git
date: 2026-11-06
status: active
---

# 09 · tag 标签

> 上一篇：[reflog 与回退](08-reflog与回退.md) · 下一篇：[hooks 概览](10-hooks概览.md)

## 1. 标签是什么

tag 给某次 commit 起一个**不会随提交前移的名字**，常用于发版：`v1.2.0`。

| 类型 | 特点 |
|------|------|
| **轻量 tag** | 只是一个引用名 |
| **附注 tag（annotated）** | 对象，含打标人、时间、说明；发版推荐 |

## 2. 创建与查看

```bash
git tag v1.0.0                    # 轻量，打在 HEAD
git tag -a v1.0.0 -m "release 1.0.0"
git tag -a v1.0.0 abc123 -m "..." # 打在指定 commit

git tag                           # 列表
git tag -l "v1.*"
git show v1.0.0
```

## 3. 推送与删除

```bash
git push origin v1.0.0
git push origin --tags            # 推所有本地 tag（可能过多，慎）
git push origin refs/tags/v1.0.0

# 删除
git tag -d v1.0.0
git push origin --delete v1.0.0   # 或 :refs/tags/v1.0.0
```

## 4. 检出 tag

```bash
git switch --detach v1.0.0        # 游离 HEAD
# 要基于旧版改：git switch -c hotfix/1.0.1 v1.0.0
```

## 5. 版本号习惯

语义化版本 `MAJOR.MINOR.PATCH`（如 `v2.3.1`）：不兼容变更 / 兼容功能 / 兼容修复。团队约定是否带 `v` 前缀、是否用 CI 自动打 tag。

## 6. tag 与分支

- 分支可移动；tag 一般**不动**。移动已发布 tag 会让依赖该 tag 的人混乱，应打新 tag。
- 发布产物应对应附注 tag 的 commit，便于追溯。

## 7. 小结

- 发版用附注 tag，并显式 push 该 tag。
- 不要改写已对外的 tag；修复打新版本号。
