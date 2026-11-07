#!/usr/bin/env bash
# Copy whitelisted notes from private ai-notebook/技术学习 into this public repo,
# remap paths via scripts/path-remap.txt, apply B-class scrubs, never copy C-class,
# then run sensitive scan. Does NOT git commit or push.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRIVATE_ROOT="${PRIVATE_NOTES_ROOT:-/Users/zwx/IdeaProjects/ai-notebook/技术学习}"
WHITELIST="$ROOT/publish.txt"
REMAP_FILE="$ROOT/scripts/path-remap.txt"

cd "$ROOT"

if [[ ! -d "$PRIVATE_ROOT" ]]; then
  echo "ERROR: private source not found: $PRIVATE_ROOT" >&2
  exit 1
fi
if [[ ! -f "$WHITELIST" ]]; then
  echo "ERROR: missing whitelist $WHITELIST" >&2
  exit 1
fi
if [[ ! -f "$REMAP_FILE" ]]; then
  echo "ERROR: missing remap $REMAP_FILE" >&2
  exit 1
fi

# Copy + remap in Python (macOS bash 3.x has no associative arrays)
PRIVATE_ROOT="$PRIVATE_ROOT" WHITELIST="$WHITELIST" REMAP_FILE="$REMAP_FILE" ROOT="$ROOT" python3 - <<'PY'
import os, re
from pathlib import Path

root = Path(os.environ["ROOT"])
private_root = Path(os.environ["PRIVATE_ROOT"])
whitelist = Path(os.environ["WHITELIST"])
remap_file = Path(os.environ["REMAP_FILE"])

remap = {}
for line in remap_file.read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if not line or line.startswith("#") or "\t" not in line:
        continue
    src, dst = line.split("\t", 1)
    remap[src] = dst

def deny(rel: str) -> bool:
    if rel.startswith("后端框架培训/") or rel.startswith("测试/"):
        return True
    if rel == "偶现查询Hive报错.md" or rel == "Python/爬虫.md":
        return True
    if "inFlow" in rel:
        return True
    return False

copied = skipped = 0
for raw in whitelist.read_text(encoding="utf-8").splitlines():
    rel = raw.strip()
    if not rel or rel.startswith("#"):
        continue
    if deny(rel):
        print(f"DENY(C): {rel}")
        skipped += 1
        continue
    src = private_root / rel
    dst_rel = remap.get(rel, rel)
    dst = root / dst_rel
    if not src.is_file():
        print(f"MISS: {rel} (not in private tree)")
        skipped += 1
        continue
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(src.read_bytes())
    if rel != dst_rel:
        print(f"MAP: {rel} -> {dst_rel}")
    copied += 1

print(f"copied={copied} skipped={skipped}")
PY

# ----- B scrubs on PUBLIC copies -----
python3 - <<'PY'
from pathlib import Path
import re

root = Path(".")

def read(p):
    return Path(p).read_text(encoding="utf-8")

def write(p, t):
    Path(p).write_text(t, encoding="utf-8")

p = root / "Node.js/Liquibase与Node.js数据库版本管理实践.md"
if p.exists():
    t = read(p)
    t = t.replace("dev-asset-hub-backend-node", "demo-app-backend")
    t = t.replace("dev-asset-hub", "示例项目")
    t = t.replace("author='inchtek'", "author='demo-author'")
    t = t.replace("'inchtek'", "'demo-author'")
    t = t.replace("jdbc:mysql://localhost:3306/asset_hub", "jdbc:mysql://localhost:3306/demo_db")
    t = t.replace("asset_hub", "demo_db")
    write(p, t)

p = root / "Node.js/Node.js数据库迁移工具选型与Liquibase对比.md"
if p.exists():
    t = read(p)
    t = t.replace("dev-asset-hub", "示例项目")
    t = t.replace("本项目 示例项目", "示例项目")
    t = t.replace("（本项目模式）", "（示例项目模式）")
    write(p, t)

p = root / "NestJS/NestJS框架介绍.md"
if p.exists():
    t = read(p)
    t = re.sub(r"\[\[last30days/2026-08-12-nestjs\|([^\]]+)\]\]", r"\1", t)
    write(p, t)

p = root / "Kubernetes/kubectl 日志过滤命令.md"
if p.exists():
    t = read(p)
    t = re.sub(r"\[\[运维部署/k8s/K8s常用命令#[^\|]+\|([^\]]+)\]\]", r"\1", t)
    t = re.sub(r"\[\[运维部署/k8s/K8s常用命令\|([^\]]+)\]\]", r"\1", t)
    write(p, t)

p = root / "MySQL/03-事务隔离级别与MVCC.md"
if p.exists():
    t = read(p)
    t = t.replace("[[MySQL高频面试题Top10]]", "《MySQL 高频面试题》系列")
    write(p, t)

p = root / "安全/网络安全等级保护（等保二级）详解与实施指南.md"
if p.exists():
    lines = read(p).splitlines(keepends=True)
    write(p, "".join(l for l in lines if "雄安" not in l and "项目管理/雄安" not in l))

p = root / "微服务/领域驱动设计/领域驱动设计_蓝皮书_5天学习计划.md"
if p.exists():
    t = read(p)
    old = """五日阅读结业后，用 inFlow 产研链路填本计划里的练习。正式范围和产出在父仓 `ai-native-development/docs/03-design/项目全生命周期管理/现状/产研领域分析/README.md`。本库只保留入口：[[技术学习/微服务/领域驱动设计/领域驱动设计_inFlow产研实战落地计划|inFlow 产研实战落地计划]]。"""
    new = """五日阅读结业后，用自选业务练习填本计划里的练习（任选一条端到端业务链路即可）。"""
    if old in t:
        t = t.replace(old, new)
    else:
        out = []
        for line in t.splitlines(keepends=True):
            if "inFlow" in line or "ai-native-development" in line:
                continue
            out.append(line)
        t = "".join(out)
        if "自选业务练习" not in t:
            t = t.rstrip() + "\n\n五日阅读结业后，用自选业务练习填本计划里的练习（任选一条端到端业务链路即可）。\n"
    t = t.replace("- 实战：2026-10-19 增加 inFlow 产研落地计划链接", "- 实战：结业后用自选业务练习巩固")
    write(p, t)

p = root / "微服务/领域驱动设计/领域驱动设计_学习进度.md"
if p.exists():
    out = []
    for line in read(p).splitlines(keepends=True):
        if "正式计划：父仓" in line or "ai-native-development" in line:
            out.append("- 实战：用自选业务练习巩固\n")
            continue
        if "本库入口：[[" in line and "inFlow" in line:
            continue
        if "inFlow" in line:
            line = line.replace("inFlow", "自选业务练习")
        out.append(line)
    write(p, "".join(out))

p = root / "工具/MacOS常用命令.md"
if p.exists():
    write(p, read(p).replace("192.168.1.100", "192.0.2.10"))

p = root / "Git/Git Worktree 使用指南.md"
if p.exists():
    t = read(p)
    t = re.sub(
        r"\[\[AI学习/Orca、Skill 与 Vibe Coding 实践分享#[^\|]+\|([^\]]+)\]\]",
        r"\1",
        t,
    )
    t = t.replace("/Users/user/projects/", "~/projects/")
    write(p, t)

p = root / "安全/JWKS规范与标准端点详解.md"
if p.exists():
    t = read(p).replace("[[RFC 7517]]", "RFC 7517").replace("[[RFC 8414]]", "RFC 8414")
    write(p, t)

p = root / "大数据/Lambda架构.md"
if p.exists():
    write(p, read(p).replace("（若在 `技术学习/大数据` 下）", "（同目录）"))

for p in root.rglob("*.md"):
    if p.name in ("README.md", "SYNC.md"):
        continue
    t = read(p)
    t2 = t.replace("[[技术学习/", "[[").replace('"[[技术学习/', '"[[')
    if t2 != t:
        write(p, t2)

p = root / "Git/00-课程大纲.md"
if p.exists():
    t = read(p)
    old = """## 相关公开笔记

若已同步到公开仓 `tech-notes`，同步规则见该仓 `SYNC.md`；本系列属 `技术学习/Git/` 白名单候选，推公开前仍需脱敏扫描。
"""
    new = """## 相关说明

本系列同步自个人笔记库的公开白名单；仓库维护方式见根目录 [SYNC.md](../SYNC.md)。
"""
    if old in t:
        write(p, t.replace(old, new))

# Fix cross-folder relative links that break after remap from private root layout
p = root / "HTTP/HTTP状态码梳理.md"
if p.exists():
    t = read(p)
    t = t.replace("](安全/TLS知识梳理.md)", "](../安全/TLS知识梳理.md)")
    write(p, t)

p = root / "架构/软件系统架构分类与常见架构风格.md"
if p.exists():
    t = read(p)
    t = t.replace("](微服务/", "](../微服务/")
    t = t.replace("](../../微服务/", "](../微服务/")
    write(p, t)

print("B scrubs applied")
PY

echo "running sensitive scan..."
"$ROOT/scripts/scan-sensitive.sh"
echo "SYNC_DONE (no commit/push performed)"
