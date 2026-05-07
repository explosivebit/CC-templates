#!/usr/bin/env bash
#
# install-skill.sh — устанавливает skill из этого репо в ~/.claude/skills/.
#
# По умолчанию создаёт симлинк — правки в репо сразу видны Claude Code.
# С флагом --copy копирует файлы (полезно если не хочешь зависеть от репо).
#
# Usage:
#   ./scripts/install-skill.sh <skill-name>            # симлинк
#   ./scripts/install-skill.sh <skill-name> --copy     # копия
#   ./scripts/install-skill.sh <skill-name> --force    # перезаписать существующее
#   ./scripts/install-skill.sh <skill-name> --dry-run  # показать что будет сделано

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"

usage() {
  cat <<EOF
Usage: $0 <skill-name> [--copy] [--force] [--dry-run]

Options:
  --copy      Copy files instead of creating a symlink (default: symlink)
  --force     Overwrite existing destination
  --dry-run   Print what would happen, don't touch anything

Available skills:
EOF
  find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d \
    -not -name 'README*' -exec basename {} \; | sort | sed 's/^/  - /'
  exit 1
}

[[ $# -lt 1 ]] && usage

SKILL_NAME="$1"
shift

MODE="symlink"
FORCE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy) MODE="copy" ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage ;;
    *) echo "Unknown flag: $1" >&2; usage ;;
  esac
  shift
done

SRC="$REPO_ROOT/skills/$SKILL_NAME"
DST="$CLAUDE_SKILLS_DIR/$SKILL_NAME"

if [[ ! -d "$SRC" ]]; then
  echo "error: skill '$SKILL_NAME' not found at $SRC" >&2
  exit 1
fi

if [[ ! -f "$SRC/SKILL.md" ]]; then
  echo "error: $SRC has no SKILL.md — not a valid skill" >&2
  exit 1
fi

say() { echo "[install-skill] $*"; }

if [[ -e "$DST" || -L "$DST" ]]; then
  if [[ $FORCE -eq 0 ]]; then
    echo "error: destination already exists: $DST" >&2
    echo "       use --force to overwrite" >&2
    exit 1
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    say "DRY-RUN would remove: $DST"
  else
    say "removing existing: $DST"
    rm -rf "$DST"
  fi
fi

if [[ $DRY_RUN -eq 1 ]]; then
  say "DRY-RUN mkdir -p $CLAUDE_SKILLS_DIR"
  if [[ "$MODE" == "symlink" ]]; then
    say "DRY-RUN ln -s $SRC $DST"
  else
    say "DRY-RUN cp -r $SRC $DST"
  fi
  exit 0
fi

mkdir -p "$CLAUDE_SKILLS_DIR"

case "$MODE" in
  symlink)
    ln -s "$SRC" "$DST"
    say "symlinked: $DST -> $SRC"
    ;;
  copy)
    cp -r "$SRC" "$DST"
    say "copied: $SRC -> $DST"
    ;;
esac

say "done. Skill '$SKILL_NAME' is installed."
say "SKILL.md: $DST/SKILL.md"
