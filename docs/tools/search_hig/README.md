# search_hig

Search Apple Human Interface Guidelines for design principles and UI patterns.

## Synopsis

```json
{
  "name": "search_hig",
  "arguments": {
    "query": "buttons",
    "platform": "iOS",
    "category": "components",
    "limit": 10
  }
}
```

## Description

Searches the Human Interface Guidelines (HIG) index using SQLite FTS5 with BM25 ranking. Returns a ranked list of matching design guidelines with URIs that can be used with `read_document` to retrieve full content.

This tool is optimized for design-related queries and supports HIG-specific filters like platform and category.

## Parameters

### query (required)

Search keywords to find in HIG documentation.

**Type:** String

**Examples:**
- `"buttons"` - Find button design guidelines
- `"navigation patterns"` - Find navigation UX patterns
- `"dark mode"` - Find dark mode design guidelines
- `"accessibility"` - Find accessibility guidelines

**Search Tips:**
- Use design terminology for better results
- Platform-specific terms help narrow results (e.g., "sidebar macOS")
- Component names return focused results (e.g., "picker", "toggle")

### platform (optional)

Filter results to a specific Apple platform.

**Type:** String

**Default:** None (searches all platforms)

**Values:**
- `"iOS"` - iPhone and iPad guidelines
- `"macOS"` - Mac application guidelines
- `"watchOS"` - Apple Watch guidelines
- `"visionOS"` - Apple Vision Pro spatial computing
- `"tvOS"` - Apple TV guidelines

### category (optional)

Filter results to a specific HIG category.

**Type:** String

**Default:** None (searches all categories)

**Values:**
- `"foundations"` - Core design principles (color, typography, icons)
- `"patterns"` - Common interaction and UX patterns
- `"components"` - UI controls and views
- `"technologies"` - Platform-specific features (Siri, HealthKit, etc.)
- `"inputs"` - Input devices and interaction methods

### limit (optional)

Maximum number of results to return.

**Type:** Integer

**Default:** 20

**Maximum:** 100

## Response

Returns markdown-formatted search results:

```markdown
# HIG Search Results for "buttons"

Found **8** guidelines:

## 1. Buttons

- **URI:** `hig://components/buttons`
- **Score:** 15.32

A button initiates an instantaneous action. Versatile and highly customizable, buttons give people simple, familiar ways to do tasks in your app...

---

## 2. Toggle buttons

- **URI:** `hig://components/toggle-buttons`
- **Score:** 12.18
...
```

### Result Fields

| Field | Description |
|-------|-------------|
| URI | Document identifier for use with `read_document` |
| Score | BM25 relevance score (higher = more relevant) |
| Summary | Brief excerpt from the guideline |

## Examples

### Basic Search

```json
{
  "query": "buttons"
}
```

### Platform-Filtered Search

```json
{
  "query": "navigation",
  "platform": "iOS"
}
```

### Category-Filtered Search

```json
{
  "query": "color",
  "category": "foundations"
}
```

### Combined Filters

```json
{
  "query": "sidebar",
  "platform": "macOS",
  "category": "components",
  "limit": 5
}
```

### Accessibility Guidelines

```json
{
  "query": "accessibility VoiceOver",
  "category": "foundations"
}
```

## Common Use Cases

### Finding UI Component Guidelines

```json
{"query": "text fields"}
{"query": "pickers"}
{"query": "navigation bars"}
{"query": "tab bars"}
```

### Finding Design Patterns

```json
{"query": "onboarding"}
{"query": "modality sheets"}
{"query": "drag and drop"}
{"query": "searching"}
```

### Platform-Specific Design

```json
{"query": "menu bar", "platform": "macOS"}
{"query": "complications", "platform": "watchOS"}
{"query": "spatial interactions", "platform": "visionOS"}
{"query": "focus navigation", "platform": "tvOS"}
```

### Accessibility Implementation

```json
{"query": "VoiceOver support"}
{"query": "Dynamic Type"}
{"query": "reduce motion"}
{"query": "color contrast"}
```

### App Store Preparation

```json
{"query": "app icons requirements"}
{"query": "launch screen"}
{"query": "privacy best practices"}
```

## Comparison with search_docs

| Feature | search_hig | search_docs |
|---------|-----------|-------------|
| Purpose | Design guidelines | API documentation |
| Content | UX patterns, design principles | Code reference, APIs |
| Filters | platform, category | source, framework, language |
| Best for | Design decisions | Implementation details |

Use `search_hig` when you need:
- Design guidance and best practices
- UI component appearance and behavior
- Platform-specific conventions
- Accessibility requirements

Use `search_docs` when you need:
- API reference and method signatures
- Code examples and implementation
- Technical specifications
- Framework documentation

## See Also

- [search_docs](../search_docs/) - Search all documentation
- [read_document](../read_document/) - Read document content by URI
- [list_frameworks](../list_frameworks/) - List available frameworks
