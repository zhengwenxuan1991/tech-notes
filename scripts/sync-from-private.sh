#!/usr/bin/env bash
# Copy whitelisted notes from private ai-notebook/技术学习 into this public repo,
# apply B-class scrubs, never copy C-class paths, then run sensitive scan.
# Does NOT git commit or push.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRIVATE_ROOT="${PRIVATE_NOTES_ROOT:-/Users/zwx/IdeaProjects/ai-notebook/技术学习}"
WHITELIST="$ROOT/publish.txt"

cd "$ROOT"

if [[ ! -d "$PRIVATE_ROOT" ]]; then
  echo "ERROR: private source not found: $PRIVATE_ROOT" >&2
  exit 1
fi
if [[ ! -f "$WHITELIST" ]]; then
  echo "ERROR: missing whitelist $WHITELIST" >&2
  exit 1
fi

# Hard deny list (category C) — never copy even if somehow listed
deny_match() {
  local rel="$1"
  case "$rel" in
    后端框架培训/*|测试/*|偶现查询Hive报错.md|*inFlow*|Python/爬虫.md)
      return 0 ;;
  esac
  return 1
}

copied=0
skipped=0
while IFS= read -r rel || [[ -n "${rel:-}" ]]; do
  [[ -z "$rel" || "$rel" =~ ^# ]] && continue
  if deny_match "$rel"; then
    echo "DENY(C): $rel"
    skipped=$((skipped+1))
    continue
  fi
  src="$PRIVATE_ROOT/$rel"
  dst="$ROOT/$rel"
  if [[ ! -f "$src" ]]; then
    echo "MISS: $rel (not in private tree)"
    skipped=$((skipped+1))
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  copied=$((copied+1))
done < "$WHITELIST"

echo "copied=$copied skipped=$skipped"

# ----- B scrubs on copies (idempotent) -----
python3 - <<'PY'
from pathlib import Path
import re

root = Path(".")

def read(p):
    return Path(p).read_text(encoding="utf-8")

def write(p, t):
    Path(p).write_text(t, encoding="utf-8")

# Liquibase
p = root / "Liquibase与Node.js数据库版本管理实践.md"
if p.exists():
    t = read(p)
    t = t.replace("dev-asset-hub-backend-node", "demo-app-backend")
    t = t.replace("dev-asset-hub", "示例项目")
    t = t.replace("author='inchtek'", "author='demo-author'")
    t = t.replace("'inchtek'", "'demo-author'")
    t = t.replace("jdbc:mysql://localhost:3306/asset_hub", "jdbc:mysql://localhost:3306/demo_db")
    t = t.replace("asset_hub", "demo_db")
    write(p, t)

# Node migration
p = root / "Node.js数据库迁移工具选型与Liquibase对比.md"
if p.exists():
    t = read(p)
    t = t.replace("dev-asset-hub", "示例项目")
    t = t.replace("本项目 示例项目", "示例项目")
    t = t.replace("（本项目模式）", "（示例项目模式）")
    write(p, t)

# NestJS intro — drop last30days wikilink
p = root / "NestJS框架介绍.md"
if p.exists():
    t = read(p)
    t = re.sub(r"\[\[last30days/2026-08-12-nestjs\|([^\]]+)\]\]", r"\1", t)
    write(p, t)

# kubectl — drop 运维部署 links
p = root / "Kubernetes/kubectl 日志过滤命令.md"
if p.exists():
    t = read(p)
    t = re.sub(r"\[\[运维部署/k8s/K8s常用命令#[^\|]+\|([^\]]+)\]\]", r"\1", t)
    t = re.sub(r"\[\[运维部署/k8s/K8s常用命令\|([^\]]+)\]\]", r"\1", t)
    write(p, t)

# MySQL 03
p = root / "MySQL深水区/03-事务隔离级别与MVCC.md"
if p.exists():
    t = read(p)
    t = t.replace("[[MySQL高频面试题Top10]]", "《MySQL 高频面试题》系列")
    write(p, t)

# 等保二级 — delete 雄安 line
p = root / "安全/网络安全等级保护（等保二级）详解与实施指南.md"
if p.exists():
    lines = read(p).splitlines(keepends=True)
    write(p, "".join(l for l in lines if "雄安" not in l and "项目管理/雄安" not in l))

# DDD 蓝皮书
p = root / "微服务/领域驱动设计/领域驱动设计_蓝皮书_5天学习计划.md"
if p.exists():
    t = read(p)
    old = """五日阅读结业后，用 inFlow 产研链路填本计划里的练习。正式范围和产出在父仓 `ai-native-development/docs/03-design/项目全生命周期管理/现状/产研领域分析/README.md`。本库只保留入口：[[技术学习/微服务/领域驱动设计/领域驱动设计_inFlow产研实战落地计划|inFlow 产研实战落地计划]]。"""
    new = """五日阅读结业后，用自选业务练习填本计划里的练习（任选一条端到端业务链路即可）。"""
    if old in t:
        t = t.replace(old, new)
    else:
        # fallback line-wise
        out = []
        for line in t.splitlines(keepends=True):
            if "inFlow" in line or "ai-native-development" in line:
                if "实战" in line or "changelog" in line.lower() or line.strip().startswith("-"):
                    continue
                continue
            out.append(line)
        t = "".join(out)
        if "自选业务练习" not in t:
            t = t.rstrip() + "\n\n五日阅读结业后，用自选业务练习填本计划里的练习（任选一条端到端业务链路即可）。\n"
    t = t.replace("- 实战：2026-10-19 增加 inFlow 产研落地计划链接", "- 实战：结业后用自选业务练习巩固")
    write(p, t)

# DDD 学习进度
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

# MacOS IP
p = root / "MacOS常用命令.md"
if p.exists():
    t = read(p).replace("192.168.1.100", "192.0.2.10")
    write(p, t)

# Git Worktree — out-of-set + example paths
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

# JWKS RFC wiki → plain
p = root / "安全/JWKS规范与标准端点详解.md"
if p.exists():
    t = read(p).replace("[[RFC 7517]]", "RFC 7517").replace("[[RFC 8414]]", "RFC 8414")
    write(p, t)

# Lambda path note
p = root / "大数据/Lambda架构.md"
if p.exists():
    t = read(p).replace("（若在 `技术学习/大数据` 下）", "（同目录）")
    write(p, t)

# Drop 技术学习/ wikilink prefix everywhere
for p in root.rglob("*.md"):
    if p.name in ("README.md", "SYNC.md"):
        continue
    t = read(p)
    t2 = t.replace("[[技术学习/", "[[").replace('"[[技术学习/', '"[[')
    if t2 != t:
        write(p, t2)

# Git series outline — public wording
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
        t = t.replace(old, new)
        write(p, t)

print("B scrubs applied")
PY

echo "running sensitive scan..."
"$ROOT/scripts/scan-sensitive.sh"
echo "SYNC_DONE (no commit/push performed)"
