# cupertino-rel full

Run the complete release workflow.

## Synopsis

```bash
cupertino-rel full <version-or-type> [options]
cupertino-rel <version-or-type> [options]
```

## Description

Executes the entire release workflow in sequence. This is the default subcommand.

## Arguments

| Argument | Description |
|----------|-------------|
| [version-or-type](argument (<>)/version-or-type.md) | New version (e.g., 0.5.0) or bump type (major, minor, patch) |

## Options

| Option | Description |
|--------|-------------|
| [--dry-run](option (--)/dry-run.md) | Preview all steps without executing |
| [--skip-wait](option (--)/skip-wait.md) | Skip waiting for GitHub Actions |
| [--skip-databases](option (--)/skip-databases.md) | Skip database upload |
| [--skip-homebrew](option (--)/skip-homebrew.md) | Skip Homebrew formula update |
| [--repo-root](option (--)/repo-root.md) | Path to repository root |

## Workflow Steps

1. **Bump** - Update version in all files
2. **Tag** - Commit and create git tag
3. **Wait** - Wait for GitHub Actions to build
4. **Databases** - Upload databases to GitHub Releases
5. **Homebrew** - Update Homebrew formula

## Examples

```bash
cupertino-rel full patch
cupertino-rel minor                    # full is default
cupertino-rel patch --dry-run          # preview only
cupertino-rel minor --skip-homebrew    # skip homebrew update
```

## Prerequisites

- `GITHUB_TOKEN` environment variable with `repo` scope
- Clean git working directory
- Push access to repository
