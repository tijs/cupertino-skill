# Cupertino Binaries

Executable binaries included in the Cupertino package.

## Binaries

| Binary | Description |
|--------|-------------|
| [cupertino-tui](cupertino-tui/) | Terminal UI for browsing packages, archives, and settings |
| [mock-ai-agent](mock-ai-agent/) | MCP testing tool for debugging server communication |
| [cupertino-rel](cupertino-rel/) | Release automation tool (maintainers only) |

## Installation

All binaries are built when you run:

```bash
cd Packages
swift build -c release
```

The binaries are located in `.build/release/`:
- `.build/release/cupertino`
- `.build/release/cupertino-tui`
- `.build/release/mock-ai-agent`
- `.build/release/cupertino-rel`

## See Also

- [Commands](../commands/) - Main CLI commands (`cupertino`)
- [Tools](../tools/) - MCP tools provided by the server
