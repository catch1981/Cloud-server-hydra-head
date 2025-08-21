#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v node >/dev/null 2>&1; then
  echo "[*] Installing Node via Homebrew (requires brew)..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Install from https://brew.sh or install Node manually, then rerun."
    exit 1
  fi
  brew install node
fi

echo "[*] Installing npm deps..."
npm ci || npm install

mkdir -p data logs

echo "[*] Bootstrap complete. Start with: node src/runner.js"
