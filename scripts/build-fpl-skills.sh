#!/usr/bin/env bash
# Build fpl-skills plugin snapshot from this lab repo into the marketplace repo.
#
# Usage:
#   ./scripts/build-fpl-skills.sh              # dry-run, prints what would be copied
#   ./scripts/build-fpl-skills.sh --apply      # actually copies
#
# Default marketplace path: ~/Work/Skills/forgeplan-marketplace
# Override with FPL_MARKETPLACE_DIR env var.

set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE_DIR="${FPL_MARKETPLACE_DIR:-$HOME/Work/Skills/forgeplan-marketplace}"
PLUGIN_DIR="$MARKETPLACE_DIR/plugins/fpl-skills"

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

echo "fpl-skills build"
echo "  lab:         $LAB_DIR"
echo "  marketplace: $MARKETPLACE_DIR"
echo "  target:      $PLUGIN_DIR"
echo "  mode:        $([ $APPLY -eq 1 ] && echo APPLY || echo DRY-RUN)"
echo ""

# Sanity checks
[ -d "$LAB_DIR/skills" ] || { echo "❌ no skills/ in lab"; exit 1; }
[ -f "$LAB_DIR/.claude-plugin/plugin.json" ] || { echo "❌ no plugin.json in lab"; exit 1; }
[ -d "$MARKETPLACE_DIR" ] || { echo "❌ marketplace not at $MARKETPLACE_DIR (set FPL_MARKETPLACE_DIR)"; exit 1; }

# What we copy (lab → plugin)
ITEMS=(
  ".claude-plugin/plugin.json"
  "hooks/"
  "skills/"
  "README.md"
)
[ -f "$LAB_DIR/GETTING-STARTED.md" ] && ITEMS+=("GETTING-STARTED.md")
[ -f "$LAB_DIR/CHANGELOG.md" ]       && ITEMS+=("CHANGELOG.md")

# What we explicitly do NOT copy (lab-only)
EXCLUDES=(
  "skills/*/references/*.draft.md"   # WIP refs
  "*.swp"
  ".DS_Store"
)

echo "Items to sync:"
for item in "${ITEMS[@]}"; do echo "  + $item"; done
echo ""
echo "Exclusions:"
for excl in "${EXCLUDES[@]}"; do echo "  - $excl"; done
echo ""

if [ $APPLY -eq 0 ]; then
  echo "Dry-run only. Re-run with --apply to copy."
  exit 0
fi

# Apply: rsync each item with excludes
mkdir -p "$PLUGIN_DIR"
for item in "${ITEMS[@]}"; do
  src="$LAB_DIR/$item"
  dst="$PLUGIN_DIR/$item"
  if [ ! -e "$src" ]; then
    echo "  skip (not in lab): $item"
    continue
  fi
  if [ -d "$src" ]; then
    rsync -a --delete \
      --exclude='*.swp' --exclude='.DS_Store' \
      --exclude='*.draft.md' \
      "$src/" "$dst/"
    echo "  synced dir:  $item"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  synced file: $item"
  fi
done

echo ""
echo "✅ fpl-skills snapshot ready at: $PLUGIN_DIR"
echo ""
echo "Next steps:"
echo "  1. cd $MARKETPLACE_DIR"
echo "  2. ./scripts/validate-all-plugins.sh           # local CI"
echo "  3. Update .claude-plugin/marketplace.json      # add/update fpl-skills entry"
echo "  4. git add plugins/fpl-skills .claude-plugin/marketplace.json"
echo "  5. git commit -m 'feat(fpl-skills): release 1.0.0'"
echo "  6. git push"
