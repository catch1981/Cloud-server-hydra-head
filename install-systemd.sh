#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_FILE="/etc/systemd/system/hydra-node.service"

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Hydra Node (self-healing)
After=network.target

[Service]
Type=simple
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/env node ${APP_DIR}/src/runner.js
Restart=always
RestartSec=2
EnvironmentFile=${APP_DIR}/.env

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable hydra-node
sudo systemctl restart hydra-node
echo "[*] Installed. Logs: journalctl -u hydra-node -f"
