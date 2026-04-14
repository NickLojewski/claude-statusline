# Claude Code Status Line

Custom status line for Claude Code CLI.

```
 myproject  | ● ⎇ feature-branch | Opus 4.6 | 34% | 51% → 3:42 PM | $1.23
```

Shows: directory, git branch + dirty indicator, model, context usage, 5hr rate limit with reset time, and session cost.

## Install

1. Copy the script:

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
```

2. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

3. Restart Claude Code.

## Requirements

- `jq`
- `git`
