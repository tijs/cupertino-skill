# cupertino-rel bump

Bump version in all required files.

## Synopsis

```bash
cupertino-rel bump <version-or-type> [options]
```

## Description

Updates the version number in:
- `Sources/Shared/Constants.swift`
- `README.md`
- `CHANGELOG.md`

## Arguments

| Argument | Description |
|----------|-------------|
| [version-or-type](argument (<>)/version-or-type.md) | New version (e.g., 0.5.0) or bump type (major, minor, patch) |

## Options

| Option | Description |
|--------|-------------|
| [--dry-run](option (--)/dry-run.md) | Preview changes without modifying files |
| [--repo-root](option (--)/repo-root.md) | Path to repository root |

## Examples

```bash
cupertino-rel bump patch        # 0.9.0 → 0.9.1
cupertino-rel bump minor        # 0.9.0 → 0.10.0
cupertino-rel bump major        # 0.9.0 → 1.0.0
cupertino-rel bump 1.0.0        # Set exact version
cupertino-rel bump patch --dry-run  # Preview only
```
