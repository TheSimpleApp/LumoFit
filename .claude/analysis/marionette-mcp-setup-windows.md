# Marionette MCP Setup for Windows

**Date:** January 20, 2026
**Issue:** `'marionette_mcp' is not recognized as an internal or external command`

---

## Root Cause

Marionette MCP is a **Dart package** (not npm), so it installs as a Windows `.bat` file. MCP clients trying to run `marionette_mcp` directly fail because:

1. Dart global executables are `.bat` files on Windows
2. MCP clients need to invoke `.bat` files via `cmd /c`
3. The path `C:\Users\dotso\AppData\Local\Pub\Cache\bin\` must be in system PATH

---

## Solution

### Step 1: Install from Git (WITH SIGTERM FIX)

**IMPORTANT:** Version 0.2.4 on pub.dev has a Windows bug (SignalException on SIGTERM).
Install from git main branch to get the fix:

```bash
# Remove old version if present
dart pub global deactivate marionette_mcp

# Install from git with SIGTERM fix (PR #17)
dart pub global activate --source git https://github.com/leancodepl/marionette_mcp.git --git-path packages/marionette_mcp

# Verify it works (should NOT show SignalException)
cmd /c "marionette_mcp --version"
# Expected: marionette_mcp version: 0.2.4
```

**Alternative (when fix is published):**
```bash
dart pub global activate marionette_mcp
```

### Step 2: Fix MCP Configuration

**WRONG (doesn't work on Windows):**
```json
{
  "marionette": {
    "command": "marionette_mcp",
    "args": []
  }
}
```

**CORRECT (Windows):**
```json
{
  "marionette": {
    "command": "cmd",
    "args": ["/c", "marionette_mcp"]
  }
}
```

---

## Config File Locations

| Client | Config Path |
|--------|-------------|
| **Cursor** | `~/.cursor/mcp.json` |
| **Claude Desktop** | `%APPDATA%\Claude\claude_desktop_config.json` |
| **Claude Code** | `~/.config/claude-code/mcp.json` |

---

## Complete Working Configs

### Cursor (`~/.cursor/mcp.json`)

```json
{
  "mcpServers": {
    "marionette": {
      "command": "cmd",
      "args": ["/c", "marionette_mcp"]
    }
  }
}
```

### Claude Desktop (`%APPDATA%\Claude\claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "marionette": {
      "command": "cmd",
      "args": ["/c", "marionette_mcp"]
    }
  }
}
```

### Claude Code (`~/.config/claude-code/mcp.json`)

```json
{
  "mcpServers": {
    "marionette": {
      "command": "cmd",
      "args": ["/c", "marionette_mcp"]
    }
  }
}
```

---

## Verify PATH

Ensure Dart global bin is in your PATH:

```bash
# Check if marionette_mcp is findable
where marionette_mcp
# Expected: C:\Users\dotso\AppData\Local\Pub\Cache\bin\marionette_mcp.bat

# If not found, add to PATH:
# 1. Open System Properties > Environment Variables
# 2. Add to User PATH: C:\Users\<username>\AppData\Local\Pub\Cache\bin
```

---

## Test Connection

After fixing the config:

1. **Restart Cursor/Claude Desktop** to reload MCP config

2. **Start your Flutter app** in debug mode:
   ```bash
   flutter run -d windows
   ```

3. **Copy the VM Service URL** from console:
   ```
   A Dart VM Service on Windows is available at: http://127.0.0.1:52132/z7Ey8M6DvVo=/
   ```

4. **Use the MCP tools** - Marionette should now be available in the AI tools list

---

## Troubleshooting

### Error: `SignalException: Failed to listen for SIGTERM`
- **Cause:** Version 0.2.4 on pub.dev has a Windows bug
- **Fix:** Install from git main branch:
  ```bash
  dart pub global deactivate marionette_mcp
  dart pub global activate --source git https://github.com/leancodepl/marionette_mcp.git --git-path packages/marionette_mcp
  ```
- **Reference:** [GitHub Issue #16](https://github.com/leancodepl/marionette_mcp/issues/16), fixed by [PR #17](https://github.com/leancodepl/marionette_mcp/pull/17)

### Error: `ENOENT` or "not recognized"
- **Cause:** Using wrong command format
- **Fix:** Use `"command": "cmd", "args": ["/c", "marionette_mcp"]`

### Error: `cmd not found`
- **Cause:** Running in non-Windows shell context
- **Fix:** Ensure PATH includes `C:\Windows\System32`

### Error: `marionette_mcp.bat not found`
- **Cause:** Dart global bin not in PATH
- **Fix:** Add `C:\Users\<username>\AppData\Local\Pub\Cache\bin` to PATH

### MCP Server doesn't appear in tools
- **Cause:** Client hasn't reloaded config
- **Fix:** Restart Cursor/Claude Desktop completely

---

## Flutter App Setup

Make sure your Flutter app has Marionette binding:

**pubspec.yaml:**
```yaml
dependencies:
  marionette_flutter: ^0.1.0
```

**main.dart:**
```dart
import 'package:marionette_flutter/marionette_flutter.dart';

void main() async {
  MarionetteBinding.ensureInitialized(const MarionetteConfiguration());
  // ... rest of app
}
```

---

## Links

- [Marionette MCP Repository](https://github.com/leancodepl/marionette_mcp)
- [Marionette Flutter Package](https://pub.dev/packages/marionette_flutter)
- [MCP Specification](https://modelcontextprotocol.io/)
