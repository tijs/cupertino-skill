# <version-or-type>

Version or bump type argument.

## Synopsis

```bash
cupertino-rel full <version-or-type>
```

## Description

Specify either an exact version number or a bump type for the release.

## Values

| Value | Description | Example |
|-------|-------------|---------|
| `major` | Major release | 0.9.0 → 1.0.0 |
| `minor` | Minor release | 0.9.0 → 0.10.0 |
| `patch` | Patch release | 0.9.0 → 0.9.1 |
| `X.Y.Z` | Set exact version | 0.9.0 → 1.0.0 |

## Examples

```bash
cupertino-rel full patch
cupertino-rel full 1.0.0
cupertino-rel minor          # full is default
```
