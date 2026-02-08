# --skip-wait

Skip waiting for GitHub Actions.

## Synopsis

```bash
cupertino-rel full <version-or-type> --skip-wait
```

## Description

Normally the release workflow waits for GitHub Actions to complete building the release. Use this flag to skip that wait.

## Use Case

- When you know the build will succeed
- When running steps manually
- For faster iteration during testing
