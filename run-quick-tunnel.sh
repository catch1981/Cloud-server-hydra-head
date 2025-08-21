#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

PORT="${PORT:-3000}"
BIN_DIR="./bin"
mkdir -p "$BIN_DIR"

if ! command -v "$BIN_DIR/cloudflared" >/dev/null 2>&1 && ! command -v cloudflared >/dev/null 2>&1; then
  echo "[*] Downloading cloudflared..."
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  URL=""
  if [[ "$OS" == "Linux" ]]; then
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
      URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
      URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    else
      echo "Unsupported arch: $ARCH"; exit 1
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
      URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz"
    else
      URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz"
    fi
  else
    echo "Unsupported OS: $OS"; exit 1
  fi

  if [[ "$URL" == *".tgz" ]]; then
    curl -L "$URL" -o /tmp/cf.tgz
    tar -xzf /tmp/cf.tgz -C "$BIN_DIR"
    rm /tmp/cf.tgz
  else
    curl -L "$URL" -o "$BIN_DIR/cloudflared"
    chmod +x "$BIN_DIR/cloudflared"
  fi
fi

CFF="$BIN_DIR/cloudflared"
if command -v cloudflared >/dev/null 2>&1; then CFF="$(command -v cloudflared)"; fi

echo "[*] Starting quick tunnel to http://localhost:$PORT ..."
exec "$CFF" tunnel --url "http://localhost:$PORT"
