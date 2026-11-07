# 如何同步

本仓库是从私有库 `ai-notebook/技术学习/` **白名单拷贝**出来的公开笔记。

**公开目录与私库不完全一致**（例如根目录散落的 HTTP/NestJS 笔记归入主题文件夹，`MySQL深水区/` 在公开仓为 `MySQL/`）。映射表：`scripts/path-remap.txt`（`私库相对路径<TAB>公开相对路径`）。

## 日常同步

在本仓库根目录执行：

```bash
./scripts/sync-from-private.sh
```

脚本会：

1. 读取 `publish.txt`（每行是**私库** `技术学习/` 下的相对路径）
2. 按 `scripts/path-remap.txt` 拷到公开仓对应路径；无映射则路径不变
3. **拒绝** C 类路径（`后端框架培训/`、`测试/`、Hive 偶现笔记、名称含产研落地计划 / inFlow、空的 `Python/爬虫.md` 等）
4. 对 B 类文件自动脱敏
5. 调用 `./scripts/scan-sensitive.sh`；有命中则非 0 退出
6. **不会** `git commit` / `git push`

可选：

```bash
PRIVATE_NOTES_ROOT=/path/to/ai-notebook/技术学习 ./scripts/sync-from-private.sh
```

## 仅扫描

```bash
./scripts/scan-sensitive.sh
```

## 增删公开篇目

1. 编辑 `publish.txt` 增加/删除**私库**相对路径  
2. 若公开落点与私库不同，在 `scripts/path-remap.txt` 增加一行映射  
3. 跑同步，确认 diff 与扫描通过后再提交推送
