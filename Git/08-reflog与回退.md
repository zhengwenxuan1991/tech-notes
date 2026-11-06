---
title: Git 08 · reflog 与回退
tags:
  - 技术学习
  - git
date: 2026-11-06
status: active
---

# 08 · reflog 与回退

> 上一篇：[stash](07-stash.md) · 下一篇：[tag](09-tag.md)

## 1. 回退前先分清「要撤什么」

| 目标 | 常见手段 | 是否改写已推送历史 |
|------|----------|--------------------|
| 去掉未提交改动 | `restore` | 否 |
| 改写最近本地提交 | `commit --amend` / `reset` | 若已推送则需强推 |
| 撤销某次已推送提交但保留历史 | `revert` | 否（新增一笔） |
| 「找回」看似丢掉的 commit | `reflog` + `reset`/`branch` | 视操作而定 |

## 2. `git reflog`：本地的安全网

reflog 记录 **HEAD（以及分支）在本地动过的位置**，包括 reset、rebase、amend 后「旧尖」还能找到。

```bash
git reflog
git reflog show main
# 例：
# abc1234 HEAD@{0}: commit: feat: x
# def5678 HEAD@{1}: reset: moving to HEAD~1
# ...
git show HEAD@{1}
git switch -c recover/temp HEAD@{1}    # 从旧位置拉出分支
```

默认约 90 天过期（可配）。**未 fetch 到你机器的提交、没进过你本地 HEAD 的对象，reflog 救不了。**

## 3. `reset` 三兄弟

相对某目标 commit（如 `HEAD~1`、`abc123`）：

| 模式 | 分支尖 | 暂存区 | 工作区 |
|------|--------|--------|--------|
| `--soft` | 移动 | 不变（仍是原暂存） | 不变 |
| `--mixed`（默认） | 移动 | 对齐目标 | 不变（改动变未暂存） |
| `--hard` | 移动 | 对齐目标 | 对齐目标（**丢未提交改动**） |

```bash
git reset --soft HEAD~1     # 整笔提交撤回，改动留在暂存区
git reset HEAD~1            # 提交撤回，改动留在工作区
git reset --hard HEAD~1     # 提交与改动都丢（危险）
git reset --hard origin/main
```

已推送到共享分支时，用 reset 改历史后再 push 需要 force-with-lease，优先考虑 `revert`。

## 4. `revert`：正向「反做」

```bash
git revert <sha>              # 新增一笔，抵消该提交
git revert <sha1>..<sha2>     # 区间（语法需查清左开右闭）
git revert -m 1 <merge_sha>   # 反合并提交时指定主线父
```

适合 `main` 上已公开的错误提交。

## 5. 找回误删分支

```bash
git reflog
git branch feature/login abc1234     # abc 是删前尖端
```

## 6. 推荐决策树

```text
只改工作区？ → restore
撤销本地未推送提交？ → reset --soft/--mixed
撤销已推送提交？ → revert
rebase/reset 后找不到了？ → reflog → 建分支
```

## 7. 小结

- reflog 是本地移动轨迹，不是远程备份。
- 共享历史优先 **revert**；**hard reset** 前确认无未保存劳动成果。
- 救回后立刻 `branch` 或 `tag`，避免过期被 gc。
