#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "[*] Ensuring dependencies (curl, ca-certificates, tar, unzip)..."
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y curl ca-certificates tar unzip
fi

if ! command -v node >/dev/null 2>&1; then
  echo "[*] Installing Node.js LTS via NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo "[*] Installing npm deps..."
npm ci || npm install

echo "[*] Creating data/logs dirs..."
mkdir -p data logs

# Optional Tailscale
if [[ -n "${TAILSCALE_AUTHKEY:-}" ]]; then
  if ! command -v tailscale >/dev/null 2>&1; then
    echo "[*] Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
  fi
  echo "[*] Bringing node onto tailnet..."
  sudo tailscale up --authkey "${TAILSCALE_AUTHKEY}" --hostname "${TAILSCALE_HOSTNAME:-hydra-node}" --accept-routes --ssh || true
fi

echo "[*] Bootstrap complete. Start with: node src/runner.js"
