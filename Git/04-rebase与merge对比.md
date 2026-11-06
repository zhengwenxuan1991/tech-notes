---
title: Git 04 · rebase 与 merge 对比
tags:
  - 技术学习
  - git
date: 2026-11-06
status: active
---

# 04 · rebase 与 merge 对比

> 上一篇：[分支与合并](03-分支与合并.md) · 下一篇：[冲突处理](05-冲突处理.md)

## 1. 一句话

| 操作 | 在做什么 | 历史观感 |
|------|----------|----------|
| **merge** | 把两条线收成一条，常留合并节点 | 真实反映「何时合入」 |
| **rebase** | 把你的提交「挪到」目标尖上重放 | 更直、像一直基于最新 main 开发 |

二者都能整合变更；差在**历史形状**和**是否改写已有 commit 的 SHA**。

## 2. merge 示意

```text
main:     A---B---C---------M
               \           /
feature:        D----E----F
```

`M` 有两个父。原 `D/E/F` 的 SHA **不变**。

## 3. rebase 示意

在 `feature` 上：`git rebase main`

```text
# 之前
main:     A---B---C
               \
feature:        D---E---F

# 之后（D/E/F 变成 D'/E'/F'，新 SHA）
main:     A---B---C
                   \
feature:            D'---E'---F'
```

然后可以 `git switch main && git merge feature`（常为快进）。

## 4. 何时用哪个（实践建议）

| 场景 | 更常见选择 |
|------|------------|
| 功能分支合入 `main`，且要保留「合入事件」 | `merge`（可 `--no-ff`） |
| 更新功能分支到最新 `main`，准备开 PR 前整理 | 本地 `rebase main`（或 `git pull --rebase`） |
| 多人已推共享的功能分支 | **不要**对已共享历史随意 rebase + force-push；需团队约定 |
| 对外已发布的 tag / 生产分支 | 禁止改写历史 |

**黄金法则：不要 rebase 公共分支上别人已经基于其上的提交。**

## 5. 常用命令

```bash
git switch feature/login
git fetch origin
git rebase origin/main
# 有冲突：改文件 → git add → git rebase --continue
# 放弃：git rebase --abort

git rebase -i HEAD~3          # 交互式：压缩、改说明、调序（仅限未推或可改写范围）
```

交互式常见动作：`pick` / `reword` / `squash` / `fix` / `drop`。

## 6. `pull` 里的策略

```bash
git pull                      # 默认常为 merge
git pull --rebase             # 用 rebase 整合远程更新
git config pull.rebase true   # 设为默认（团队统一）
```

## 7. 和 squash merge 的关系

GitHub/GitLab 的 **Squash and merge**：在服务端把 PR 里多笔提交压成一笔再进主分支——效果类似「干净线性」，但不是本地 `rebase` 本身。选哪种合入按钮也是团队规范的一部分。

## 8. 小结

- merge：非破坏性整合，历史有分叉真相。
- rebase：改写提交序列，求直线；只安全用于**尚未共享或明确可强推**的提交。
- 冲突解法两边类似，见下一篇。
