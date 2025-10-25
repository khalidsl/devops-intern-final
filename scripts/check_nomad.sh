#!/usr/bin/env bash
set -euo pipefail

# Simple smoke-test for the Nomad job
# - builds local image
# - purges previous job
# - submits nomad/hello_fixed.nomad
# - waits for an allocation to be running
# - curls the dynamic http address

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[check_nomad] Building image devops-intern-final:latest..."
docker build -t devops-intern-final:latest .

echo "[check_nomad] Stopping existing job (if any)..."
docker exec -i nomad nomad job stop -purge hello || true

echo "[check_nomad] Submitting job..."
docker exec -i nomad nomad job run - < nomad/hello_fixed.nomad

echo "[check_nomad] Waiting for allocation to become running (timeout 60s)..."
alloc=""
for i in $(seq 1 30); do
  # Try to get alloc ID from job status output
  alloc=$(docker exec -i nomad nomad job status hello 2>/dev/null | awk '/^[0-9a-f]{6,}/ {print $1; exit}') || true
  if [ -n "$alloc" ]; then
    status=$(docker exec -i nomad nomad alloc status -verbose "$alloc" 2>/dev/null | awk -F"= " '/Client Status/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}') || true
    if [ "$status" = "running" ]; then
      echo "[check_nomad] Allocation $alloc is running"
      break
    fi
  fi
  echo "[check_nomad] waiting... ($i)"
  sleep 2
done

if [ -z "$alloc" ]; then
  echo "[check_nomad] No allocation found after timeout" >&2
  docker exec -i nomad nomad job status hello || true
  exit 2
fi

addr=$(docker exec -i nomad nomad alloc status -verbose "$alloc" | awk '/\*http/ {print $3; exit}') || true
if [ -z "$addr" ]; then
  echo "[check_nomad] Could not find http address in alloc status" >&2
  docker exec -i nomad nomad alloc status -verbose "$alloc" || true
  exit 3
fi

echo "[check_nomad] Curling http://$addr/"
curl -fsS "http://$addr/" && echo "[check_nomad] OK" || { echo "[check_nomad] Request failed" >&2; exit 4; }

exit 0
