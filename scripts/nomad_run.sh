#!/usr/bin/env bash
# scripts/nomad_run.sh
# Build docker image, start nomad agent -dev (if not running) and run nomad job nomad/hello.nomad

set -euo pipefail

# Helper: is nomad running locally or as a container named 'nomad'?
is_nomad_up() {
  # local nomad process?
  if command -v nomad >/dev/null 2>&1 && pgrep -x nomad >/dev/null 2>&1; then
    return 0
  fi
  # docker container named 'nomad'?
  if command -v docker >/dev/null 2>&1; then
    if docker ps --filter "name=^/nomad$" --format '{{.Names}}' | grep -q '^nomad$'; then
      return 0
    fi
    # or any running container from hashicorp/nomad image
    if docker ps --filter ancestor=hashicorp/nomad --format '{{.ID}}' | head -n1 | grep -q '.'; then
      return 0
    fi
  fi
  return 1
}

# Build image
IMAGE_NAME="devops-intern-final:latest"
echo "[nomad_run] Building Docker image ${IMAGE_NAME}..."
# Try build using current directory; if user runs from scripts/ call parent
if [ -f "../Dockerfile" ] && [ ! -f "./Dockerfile" ]; then
  docker build -t ${IMAGE_NAME} ..
else
  docker build -t ${IMAGE_NAME} .
fi

# Start nomad in dev mode if not running
if is_nomad_up; then
  echo "[nomad_run] Nomad agent already running (local process or container detected)"
else
  if command -v nomad >/dev/null 2>&1; then
    echo "[nomad_run] Starting Nomad agent in dev mode (background)..."
    nohup nomad agent -dev > /tmp/nomad.log 2>&1 &
  elif command -v docker >/dev/null 2>&1; then
    echo "[nomad_run] No local Nomad binary found. Will start a Nomad Docker container (detached)."
    echo "[nomad_run] Mounting /var/run/docker.sock so the Nomad container can use the host Docker daemon."
    docker run --rm -d --name nomad -p 4646:4646 -p 4647:4647 -p 4648:4648 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      hashicorp/nomad:1.6.6 agent -dev -bind=0.0.0.0 >/dev/null
    echo "[nomad_run] Started Nomad container 'nomad'"
  else
    echo "[nomad_run] ERROR: Neither 'nomad' binary nor 'docker' command available. Please install Nomad or run the Nomad container manually."
    exit 2
  fi

  echo "[nomad_run] Waiting for Nomad to be ready (timeout 30s)..."
  ready=0
  for _ in $(seq 1 30); do
    if curl -sS http://127.0.0.1:4646/v1/status/leader >/dev/null 2>&1; then
      echo "[nomad_run] Nomad ready"
      ready=1
      break
    fi
    sleep 1
  done
  if [ $ready -ne 1 ]; then
    echo "[nomad_run] Warning: Nomad did not become ready in 30s. Check the Nomad logs (container 'nomad' logs or /tmp/nomad.log)."
  fi
fi

# Run the job
echo "[nomad_run] Running job nomad/hello.nomad..."
# Try local nomad first, else submit via the Nomad container (docker exec) or via HTTP API as a last resort
JOB_FILE="../nomad/hello.nomad"
if [ ! -f "${JOB_FILE}" ]; then
  JOB_FILE="nomad/hello.nomad"
fi

if command -v nomad >/dev/null 2>&1; then
  nomad job run "${JOB_FILE}" || true
elif docker ps --filter "name=^/nomad$" --format '{{.Names}}' | grep -q '^nomad$'; then
  # submit using nomad binary inside the container by piping the file to stdin
  cat "${JOB_FILE}" | docker exec -i nomad nomad job run - || true
else
  # try to find any running nomad container
  NOMAD_CID=$(docker ps --filter ancestor=hashicorp/nomad --format '{{.ID}}' | head -n1 || true)
  if [ -n "${NOMAD_CID}" ]; then
    cat "${JOB_FILE}" | docker exec -i ${NOMAD_CID} nomad job run - || true
  else
    # fallback: HTTP API
    if command -v curl >/dev/null 2>&1; then
      echo "[nomad_run] Submitting job via Nomad HTTP API (POST /v1/jobs)."
      curl --fail --silent --show-error --request POST --data-binary @"${JOB_FILE}" http://127.0.0.1:4646/v1/jobs || true
    else
      echo "[nomad_run] ERROR: Unable to submit job: no nomad binary, no nomad container detected, and no curl available for HTTP API submission."
    fi
  fi
fi

# Show job status
echo "[nomad_run] Job status:"
if command -v nomad >/dev/null 2>&1; then
  nomad job status hello || true
elif docker ps --filter "name=^/nomad$" --format '{{.Names}}' | grep -q '^nomad$'; then
  docker exec -i nomad nomad job status hello || true
else
  NOMAD_CID=$(docker ps --filter ancestor=hashicorp/nomad --format '{{.ID}}' | head -n1 || true)
  if [ -n "${NOMAD_CID}" ]; then
    docker exec -i ${NOMAD_CID} nomad job status hello || true
  else
    if command -v curl >/dev/null 2>&1; then
      curl -sS http://127.0.0.1:4646/v1/job/hello | head -n 200 || true
    fi
  fi
fi

# Try to get first allocation id (best-effort) and tail logs
echo
echo "[nomad_run] Attempting to find an allocation and stream logs (best-effort)..."
ALLOC_ID=""
if command -v nomad >/dev/null 2>&1; then
  if command -v jq >/dev/null 2>&1; then
    ALLOC_ID=$(nomad job status -json hello 2>/dev/null | jq -r '.Summary.Allocations[0]' 2>/dev/null || true)
  fi
elif docker ps --filter "name=^/nomad$" --format '{{.Names}}' | grep -q '^nomad$'; then
  if docker exec -i nomad sh -c 'command -v jq >/dev/null 2>&1' >/dev/null 2>&1; then
    ALLOC_ID=$(docker exec -i nomad nomad job status -json hello 2>/dev/null | docker exec -i nomad jq -r '.Summary.Allocations[0]' 2>/dev/null || true)
  fi
fi

if [ -n "${ALLOC_ID}" ] && [ "${ALLOC_ID}" != "null" ]; then
  echo "[nomad_run] Following stdout logs for alloc ${ALLOC_ID} (task 'hello')"
  if command -v nomad >/dev/null 2>&1; then
    nomad alloc logs -stdout ${ALLOC_ID} -task hello -f || true
  else
    if docker ps --filter "name=^/nomad$" --format '{{.Names}}' | grep -q '^nomad$'; then
      docker exec -i nomad nomad alloc logs -stdout ${ALLOC_ID} -task hello -f || true
    else
      docker exec -i ${NOMAD_CID} nomad alloc logs -stdout ${ALLOC_ID} -task hello -f || true
    fi
  fi
else
  echo "[nomad_run] No allocation ID found automatically."
  echo "[nomad_run] To inspect allocations and logs manually run one of the following (from WSL or a shell that can reach the Nomad HTTP API):"
  echo "  # If you have the nomad CLI locally:"
  echo "  nomad job status hello"
  echo "  nomad job allocations hello"
  echo "  nomad alloc status <alloc_id>"
  echo "  nomad alloc logs -stdout <alloc_id> -task hello -f"
  echo
  echo "  # Or, if using the Nomad container named 'nomad':"
  echo "  docker exec -i nomad nomad job status hello"
  echo "  docker exec -i nomad nomad job allocations -json hello | jq -r '.[0].ID'"
  echo "  docker exec -i nomad nomad alloc logs -stdout <alloc_id> -task hello -f"
fi
