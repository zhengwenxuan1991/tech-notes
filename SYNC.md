# 如何同步

本仓库是从私有库 `ai-notebook/技术学习/` **白名单拷贝**出来的公开笔记，不直接改私有库。

## 日常同步

在本仓库根目录执行：

```bash
./scripts/sync-from-private.sh
```

脚本会：

1. 按 `publish.txt` 白名单，从 `~/IdeaProjects/ai-notebook/技术学习/` 复制文件到本仓对应相对路径  
2. **拒绝** C 类路径（`后端框架培训/`、`测试/`、Hive 偶现笔记、名称含产研落地计划的笔记、空的 `Python/爬虫.md` 等）  
3. 对 B 类文件自动脱敏（项目名、作者、越界链接、内网 IP、未公开实战计划指针等）  
4. 调用 `./scripts/scan-sensitive.sh`；有命中则 **非 0 退出**  
5. **不会** `git commit` / `git push` —— 请你本地 diff 确认后再提交推送

可选环境变量：

```bash
PRIVATE_NOTES_ROOT=/path/to/ai-notebook/技术学习 ./scripts/sync-from-private.sh
```

## 仅扫描

```bash
./scripts/scan-sensitive.sh
```

## 增删公开篇目

编辑根目录 `publish.txt`（每行一个相对路径，相对 `技术学习/` / 本仓根），再跑同步。
