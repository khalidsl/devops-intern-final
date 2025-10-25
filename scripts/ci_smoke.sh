#!/usr/bin/env bash
set -euo pipefail

# Start the app in background, do a quick HTTP smoke-test, then stop it.
python hello.py &
APP_PID=$!

cleanup() {
  kill "$APP_PID" 2>/dev/null || true
  wait "$APP_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Wait for the server to be available (default port 8080 in CI)
for i in $(seq 1 10); do
  if curl -sS "http://127.0.0.1:8080/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

# Perform the actual request and print output (so Action logs contain the response)
curl -S "http://127.0.0.1:8080/"
echo

# cleanup will run on EXIT via trap
