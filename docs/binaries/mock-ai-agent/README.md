# mock-ai-agent

MCP testing tool for debugging server communication.

## Synopsis

```bash
mock-ai-agent [options]
mock-ai-agent <server-command> [args...]
```

## Options

| Option | Description |
|--------|-------------|
| [--version](option (--)/version.md) | Show version information |

## Description

A mock AI agent that demonstrates and tests the MCP (Model Context Protocol) request/response cycle. It connects to an MCP server via stdio and executes a sequence of MCP operations with full JSON logging.

Useful for:
- Testing MCP server implementations
- Debugging communication issues
- Understanding the MCP protocol
- Verifying tool and resource availability

## Usage

### Test Local Cupertino Server

```bash
# Requires local build first
cd Packages
swift build
swift run mock-ai-agent
```

The agent will:
1. Start the local `cupertino serve` process
2. Send `initialize` request
3. List available tools (`tools/list`)
4. Call `search` tool with "SwiftUI" query
5. List available resources (`resources/list`)
6. Read a resource (`resources/read`)
7. Send shutdown notification

### Test External MCP Server

```bash
# Test any MCP server
mock-ai-agent npx -y @modelcontextprotocol/server-memory
```

## Output

The agent logs the complete JSON-RPC communication:

```
🤖 Mock AI Agent Starting...
================================================================================

🚀 Starting MCP Server Process...
   Using cupertino server: .build/debug/cupertino

✅ MCP Server Started (PID: 12345)

📡 Starting MCP Communication...
================================================================================

📨 CLIENT → SERVER: initialize
--------------------------------------------------------------------------------

📤 Sending JSON:
{
  "id": 1,
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "capabilities": { ... },
    "clientInfo": { "name": "Mock AI Agent", "version": "1.0.0" },
    "protocolVersion": "2024-11-05"
  }
}

📬 SERVER → CLIENT: initialize response
--------------------------------------------------------------------------------
{ ... }

✅ Initialized with server: Cupertino v0.9.0
   Protocol Version: 2024-11-05
   Capabilities:
     - Tools: ✓
     - Resources: ✓
```

## Requirements

- Local build of cupertino (`swift build`)
- Or an external MCP server command

## Notes

- Only uses local builds (`.build/debug/cupertino` or `.build/release/cupertino`)
- Will not fall back to installed `/usr/local/bin/cupertino` to ensure testing current code
- Exits with error if no local build is found

## See Also

- [cupertino serve](../../commands/serve/) - Start MCP server
- [cupertino doctor](../../commands/doctor/) - Check server health
