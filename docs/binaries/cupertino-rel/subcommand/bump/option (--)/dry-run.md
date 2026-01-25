# --dry-run

Preview changes without modifying files.

## Synopsis

```bash
cupertino-rel bump <version-or-type> --dry-run
```

## Description

Shows what changes would be made without actually modifying any files. Useful for verifying the bump before committing.

## Example

```bash
cupertino-rel bump minor --dry-run
```

Output shows which files would be modified and the new version.
