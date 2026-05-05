#!/usr/bin/env bash
# Creates soa-prefixed symlinks in .claude/skills/ for each son-of-anton agent skill.
# Also ensures .agents and tools symlinks exist at the repo root (consumer repos only).
#
# Works in two modes:
#   source repo  — run from the son-of-anton repo itself (.agents/skills/ exists at root)
#   consumer repo — run from a repo that has done `git subtree add` (.son-of-anton/ exists)
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SKILLS_DEST="$REPO_ROOT/.claude/skills"

if [ -d "$REPO_ROOT/.agents/skills" ] && [ ! -d "$REPO_ROOT/.son-of-anton" ]; then
  # Source repo: skills live at .agents/skills/ directly
  SKILLS_SRC="$REPO_ROOT/.agents/skills"
  LINK_TARGET_PREFIX="../../.agents/skills"
  IS_SOURCE_REPO=true
else
  # Consumer repo: skills live under .son-of-anton/
  SKILLS_SRC="$REPO_ROOT/.son-of-anton/.agents/skills"
  LINK_TARGET_PREFIX="../../.son-of-anton/.agents/skills"
  IS_SOURCE_REPO=false
fi

mkdir -p "$SKILLS_DEST"

for skill_dir in "$SKILLS_SRC"/*/; do
  name="$(basename "$skill_dir")"
  link="$SKILLS_DEST/soa-$name"
  target="$LINK_TARGET_PREFIX/$name"
  ln -sf "$target" "$link"
  echo "  linked: .claude/skills/soa-$name"
done

# Ensure repo-root symlinks required by the delivery orchestrator exist (consumer only).
if [ "$IS_SOURCE_REPO" = false ]; then
  for pair in ".agents:.son-of-anton/.agents" "tools:.son-of-anton/tools"; do
    link_name="${pair%%:*}"
    target="${pair##*:}"
    link="$REPO_ROOT/$link_name"
    if [ ! -e "$link" ] && [ ! -L "$link" ]; then
      ln -s "$target" "$link"
      echo "  linked: $link_name -> $target"
    fi
  done
fi

echo "sync-skills: done"
