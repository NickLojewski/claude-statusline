# Claude Code Status Line

Custom status line for Claude Code CLI.

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
