# <version-or-type>

Version or bump type argument.

## Synopsis

```bash
cupertino-rel bump <version-or-type>
```

## Description

Specify either an exact version number or a bump type.

## Values

| Value | Description | Example |
|-------|-------------|---------|
| `major` | Bump major version | 0.9.0 → 1.0.0 |
| `minor` | Bump minor version | 0.9.0 → 0.10.0 |
| `patch` | Bump patch version | 0.9.0 → 0.9.1 |
| `X.Y.Z` | Set exact version | 0.9.0 → 1.0.0 |

## Examples

```bash
cupertino-rel bump patch    # Increment patch
cupertino-rel bump 2.0.0    # Set to 2.0.0
```
