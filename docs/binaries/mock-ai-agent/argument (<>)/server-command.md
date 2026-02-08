# <server-command>

External MCP server command to test.

## Synopsis

```bash
mock-ai-agent <command> [args...]
```

## Description

Specify an external MCP server to test instead of the local cupertino build. The command and all following arguments are passed to start the MCP server.

## Examples

```bash
# Test memory server
mock-ai-agent npx -y @modelcontextprotocol/server-memory

# Test filesystem server
mock-ai-agent npx -y @modelcontextprotocol/server-filesystem /path/to/dir

# Test custom server
mock-ai-agent /path/to/my-mcp-server --port 3000
```

## How It Works

1. mock-ai-agent spawns the specified command as a subprocess
2. Connects via stdio (stdin/stdout)
3. Sends MCP protocol messages
4. Logs all JSON-RPC communication

## Requirements

- The command must be available in PATH or use full path
- Server must support MCP stdio transport
- Server must respond to standard MCP methods
