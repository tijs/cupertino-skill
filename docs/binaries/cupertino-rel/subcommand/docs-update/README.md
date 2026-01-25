# cupertino-rel docs-update

Update documentation databases and bump minor version.

## Synopsis

```bash
cupertino-rel docs-update [options]
```

## Description

Convenience command for documentation-only releases. Updates the pre-built databases and creates a minor version bump.

Workflow:
1. Run `cupertino save` to rebuild search index
2. Query database for document/framework counts
3. Update README.md with new counts
4. Bump minor version (e.g., 0.4.0 → 0.5.0)
5. Optionally continue with tag and database upload

## Options

| Option | Description |
|--------|-------------|
| [--dry-run](option (--)/dry-run.md) | Preview changes without executing |
| [--skip-save](option (--)/skip-save.md) | Skip running `cupertino save` |
| [--release](option (--)/release.md) | Continue with tag and upload after bump |
| [--repo-root](option (--)/repo-root.md) | Path to repository root |

## Examples

```bash
cupertino-rel docs-update
cupertino-rel docs-update --dry-run
cupertino-rel docs-update --release
cupertino-rel docs-update --skip-save --release
```
