# cupertino-rel homebrew

Update Homebrew formula with new version.

## Synopsis

```bash
cupertino-rel homebrew [options]
```

## Description

Updates the Homebrew formula in the tap repository with the new version and SHA256 hash.

## Options

| Option | Description |
|--------|-------------|
| [--version](option (--)/version.md) | Version to release (e.g., 0.5.0) |
| [--dry-run](option (--)/dry-run.md) | Preview changes without modifying files |
| [--tap-path](option (--)/tap-path.md) | Path to homebrew-tap repository |
| [--repo](option (--)/repo.md) | GitHub repository for CLI releases |
| [--repo-root](option (--)/repo-root.md) | Path to repository root |

## Formula Location

`mihaelamj/homebrew-tap/Formula/cupertino.rb`

## Examples

```bash
cupertino-rel homebrew
cupertino-rel homebrew --version 1.0.0
cupertino-rel homebrew --dry-run
```
