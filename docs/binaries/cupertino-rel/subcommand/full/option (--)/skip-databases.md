# --skip-databases

Skip database upload.

## Synopsis

```bash
cupertino-rel full <version-or-type> --skip-databases
```

## Description

Skip the step that uploads databases to GitHub Releases. Useful when only releasing code changes without documentation updates.

## Use Case

- Code-only releases
- When databases haven't changed
- When uploading databases separately
