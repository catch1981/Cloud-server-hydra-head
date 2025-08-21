#!/usr/bin/env bash
set -euo pipefail
URL="${1:-http://127.0.0.1:3000}"
echo "[*] GET $URL/health"
curl -sS "$URL/health" | jq . || curl -sS "$URL/health"
echo
echo "[*] GET $URL/id"
curl -sS "$URL/id"
echo
