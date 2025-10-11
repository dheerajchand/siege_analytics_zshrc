# Obsidian File System Timeout Issue

## Problem Summary
Obsidian fails to load with error: "File system operation timed out"

## Root Cause
macOS default file descriptor limit (`launchctl maxfiles`) is only **256**, which is insufficient for applications that need to open many files simultaneously (like Obsidian with large vaults and multiple plugins).

## Symptoms
- Obsidian hangs on "Loading plugins..."
- Error message: "An error occurred while loading Obsidian. Error: File system operation timed out"
- Finder may also become slow or unresponsive
- Issue persists for days until system limits are adjusted

## Diagnosis
Run this command to check current limits:
```bash
launchctl limit maxfiles
```

If output shows `maxfiles    256    unlimited`, the limit is too low.

Also use the built-in diagnostic:
```bash
check_file_limits
```

## Solution

### Temporary Fix (Until Next Reboot)
```bash
sudo launchctl limit maxfiles 65536 200000
killall Obsidian
open -a Obsidian
```

### Permanent Fix
1. Create launch daemon plist:
```bash
sudo cp /tmp/limit.maxfiles.plist /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chmod 644 /Library/LaunchDaemons/limit.maxfiles.plist
```

2. The plist file (`/tmp/limit.maxfiles.plist`) contains:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
        <string>launchctl</string>
        <string>limit</string>
        <string>maxfiles</string>
        <string>65536</string>
        <string>200000</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceDescription</key>
    <string>Set maxfiles limit for system</string>
</dict>
</plist>
```

3. Verify after next reboot:
```bash
launchctl limit maxfiles
# Should show: maxfiles    65536          200000 (or unlimited)
```

## Prevention
The `check_file_limits` function (in utils module) will warn you if limits are too low:

```bash
check_file_limits
```

Output:
- ✅ if limits are >= 4096
- ⚠️ if limits are 1024-4095
- 🚨 if limits are < 1024 (dangerous)

## Why This Happened
1. macOS ships with very conservative file limits (256)
2. As your Obsidian vault grew (more notes, more plugins), file descriptor usage increased
3. Eventually crossed the threshold where 256 was insufficient
4. The error message was cryptic and didn't point to file limits

## Related Issues
- Finder slowness/hangs
- Other Electron apps timing out
- Database applications failing to connect
- Docker containers hitting file limits

## Prevention Checklist
- ✅ Install permanent launchd plist
- ✅ Run `check_file_limits` periodically
- ✅ Monitor vault size growth
- ✅ Keep plugin count reasonable

## Date Documented
October 11, 2025

## Resolution Time
Days to diagnose → Minutes to fix once root cause identified
