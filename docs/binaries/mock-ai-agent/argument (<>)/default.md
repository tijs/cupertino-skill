# mock-ai-agent arguments

Optional arguments for the mock AI agent.

## Arguments

| Argument | Description |
|----------|-------------|
| [server-command](server-command.md) | External MCP server command to test |

## Default Behavior

When no arguments are provided, mock-ai-agent tests the local cupertino build.

```bash
mock-ai-agent              # Tests local .build/debug/cupertino
mock-ai-agent npx server   # Tests external MCP server
```
