# cupertino-rel databases

Package and upload databases to GitHub Releases.

## Synopsis

```bash
cupertino-rel databases [options]
```

## Description

Packages the documentation databases and uploads them to the cupertino-docs GitHub repository for distribution via `cupertino setup`.

## Options

| Option | Description |
|--------|-------------|
| [--base-dir](option (--)/base-dir.md) | Base directory containing databases |
| [--repo](option (--)/repo.md) | GitHub repository (owner/repo) |
| [--dry-run](option (--)/dry-run.md) | Create release without uploading |
| [--repo-root](option (--)/repo-root.md) | Path to repository root |

## Files Uploaded

- `search.db.zip` - Main documentation search index
- `samples.db.zip` - Sample code search index

## Examples

```bash
cupertino-rel databases
cupertino-rel databases --dry-run
cupertino-rel databases --repo mihaelamj/cupertino-docs
```
