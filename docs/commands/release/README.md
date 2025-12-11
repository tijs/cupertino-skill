# cupertino release (REMOVED)

> **Note:** The `cupertino release` command has been removed from the CLI in version 0.4.0.

## Why Removed?

The release command was for maintainers only. Regular users should not have access to it. It has been moved to a separate executable.

## New Location

Use `cupertino-rel` instead:

```bash
# Build the release tool
cd Packages
swift build --product cupertino-rel

# Upload databases
export GITHUB_TOKEN="your-cupertino-docs-token"
.build/debug/cupertino-rel databases
```

## See Also

- [Packages/Sources/ReleaseTool/README.md](../../../Packages/Sources/ReleaseTool/README.md) - Full ReleaseTool documentation
- [docs/DEPLOYMENT.md](../../DEPLOYMENT.md) - Complete release workflow
