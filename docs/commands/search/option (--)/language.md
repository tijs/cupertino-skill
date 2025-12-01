# --language

Filter search results by programming language.

## Synopsis

```bash
cupertino search <query> --language <language>
cupertino search <query> -l <language>
```

## Description

Filters search results to show only documentation written for a specific programming language. Most Apple documentation is available in both Swift and Objective-C variants.

## Values

| Value | Description |
|-------|-------------|
| `swift` | Swift documentation |
| `objc` | Objective-C documentation |

## Examples

### Swift Only

```bash
cupertino search "URLSession" --language swift
```

### Objective-C Only

```bash
cupertino search "NSURLSession" --language objc
```

### Combined with Other Filters

```bash
cupertino search "async" --language swift --framework foundation
```

## Notes

- Most Swift Evolution proposals are Swift-only
- Swift.org documentation is Swift-only
- Apple framework documentation often has both Swift and Objective-C variants
- If not specified, searches all languages

## See Also

- [--source](../source.md) - Filter by documentation source
- [--framework](../framework.md) - Filter by framework
