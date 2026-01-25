# cupertino-rel tag

Commit changes and create git tag.

## Synopsis

```bash
cupertino-rel tag [options]
```

## Description

Commits the version bump changes and creates a git tag for the new version.

## Options

| Option | Description |
|--------|-------------|
| [--version](option (--)/version.md) | Version to tag (e.g., 0.5.0) |
| [--dry-run](option (--)/dry-run.md) | Preview commands without executing |
| [--push](option (--)/push.md) | Push tag to origin after creation |
| [--repo-root](option (--)/repo-root.md) | Path to repository root |

## Examples

```bash
cupertino-rel tag
cupertino-rel tag --version 1.0.0
cupertino-rel tag --push
cupertino-rel tag --dry-run
```
