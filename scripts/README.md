# scripts/

Helper scripts for working with the library: installing skills/agents into
`~/.claude`, validating frontmatter, regenerating the index.

---

## Planned scripts

| Script                    | What it does                                          |
|---------------------------|-------------------------------------------------------|
| `install-skill.sh <name>` | Copies/symlinks `skills/<name>` to `~/.claude/skills/`      |
| `install-agent.sh <name>` | Copies `agents/<name>.md` to `~/.claude/agents/`      |
| `install-command.sh <n>`  | Copies `commands/<name>.md` to `~/.claude/commands/`  |
| `lint-frontmatter.sh`     | Validates YAML frontmatter across all `.md` in repo   |
| `update-index.sh`         | Regenerates `INDEX.md` from current contents          |

Created as needed. Until they exist, install by hand using the README
instructions in each folder.

---

## Rules

- **Shell**: `bash`, with `set -euo pipefail` at the top.
- **Idempotent**: re-running must not break state (check for the file
  before copying, use `ln -sf`).
- **No destruction by default**: if the target file already exists, prompt
  for confirmation or require a `--force` flag.
- **Dry run**: `--dry-run` flag for preview.

## Script template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: $0 <name> [--force] [--dry-run]"
  exit 1
}

[[ $# -lt 1 ]] && usage

# ...
```
