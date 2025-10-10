# Plist Support for HelpView

HelpView now supports both **JSON** and **plist** file formats for storing FAQ data.

## Automatic Format Detection

The `FAQLoader` automatically detects and loads the correct format:

```swift
// This will try app_help.json first, then app_help.plist
HelpView(named: "app_help")
```

The loader tries formats in this order:
1. `.json` (preferred)
2. `.plist` (fallback)

## File Format Requirements

### JSON Format (Recommended)
```json
{
  "faqs": [
    {
      "id": "UUID-STRING",
      "title": "Question text",
      "details": "Answer in markdown format",
      "topic": "Topic Name"
    }
  ]
}
```

### Plist Format
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>faqs</key>
    <array>
        <dict>
            <key>id</key>
            <string>UUID-STRING</string>
            <key>title</key>
            <string>Question text</string>
            <key>details</key>
            <string>Answer in markdown format</string>
            <key>topic</key>
            <string>Topic Name</string>
        </dict>
    </array>
</dict>
</plist>
```

## Important Notes

### Plist Limitations
- **No null values**: Plist format doesn't support null. Use empty strings (`""`) for optional fields like `topic`
- **String UUIDs**: UUIDs must be stored as strings in plist files
- **Empty strings treated as nil**: The FAQ decoder automatically converts empty strings to nil for optional fields

### JSON Benefits
- Supports null values for optional fields
- More compact and readable
- Widely supported by tools and editors

## Converting Between Formats

### JSON to Plist

You can convert the JSON file to plist format using Python:

```python
import json
import plistlib

# Read JSON
with open('app_help.json', 'r') as f:
    data = json.load(f)

# Convert nulls to empty strings
def convert_for_plist(obj):
    if isinstance(obj, dict):
        return {k: convert_for_plist(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_for_plist(item) for item in obj]
    elif obj is None:
        return ""
    else:
        return obj

plist_data = convert_for_plist(data)

# Write plist
with open('app_help.plist', 'wb') as f:
    plistlib.dump(plist_data, f, fmt=plistlib.FMT_XML)
```

### Plist to JSON

```bash
plutil -convert json app_help.plist -o app_help.json
```

## Usage Examples

### Load Specific Format

```swift
// Load JSON explicitly
let faqs = FAQLoader.loadFile(named: "app_help", format: .json)

// Load plist explicitly
let faqs = FAQLoader.loadFile(named: "app_help", format: .plist)
```

### Automatic Detection (Recommended)

```swift
// Tries .json first, then .plist
let faqs = FAQLoader.load(named: "app_help")
```

## Migration Guide

If you're migrating from JSON to plist:

1. **Convert your JSON file** to plist format (see conversion script above)
2. **Add the plist to your Xcode project** - drag it into the project navigator
3. **Ensure it's in the Copy Bundle Resources** build phase
4. **Remove the JSON file** if you no longer need it (optional)

The HelpView will automatically use the plist file if JSON is not found.

## Example Files

- `app_help.json` - JSON format example (included)
- `app_help.plist` - Plist format example (included)

Both files contain the same FAQ data and can be used interchangeably.
