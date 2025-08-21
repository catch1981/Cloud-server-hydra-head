#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLIST=~/Library/LaunchAgents/com.mandemos.hydranode.plist

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.mandemos.hydranode</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/env</string>
    <string>node</string>
    <string>${APP_DIR}/src/runner.js</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>NODE_ENV</key><string>production</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>WorkingDirectory</key><string>${APP_DIR}</string>
  <key>StandardOutPath</key><string>${APP_DIR}/logs/launchd.out.log</string>
  <key>StandardErrorPath</key><string>${APP_DIR}/logs/launchd.err.log</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
launchctl start com.mandemos.hydranode
echo "[*] launchd service installed. Tail logs in ./logs"
