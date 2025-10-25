#!/usr/bin/env bash
# scripts/run-container.sh
# Construire l'image et lancer le conteneur (par défaut affichage et suppression après exécution)

set -euo pipefail

IMAGE_NAME="devops-intern-final:latest"
CONTAINER_NAME="devops-intern-run"
MODE="run" # run | detached

usage() {
  cat <<EOF
Usage: $0 [--detached]

Options:
  --detached    Run container in background (docker run -d)
  --name NAME   Use custom container name (default: ${CONTAINER_NAME})
  --help         Show this help
EOF
}

# parse args
while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --detached)
      MODE="detached"
      shift
      ;;
    --name)
      CONTAINER_NAME="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      exit 2
      ;;
  esac
done

# build image
echo "[run-container] Building image ${IMAGE_NAME}..."
docker build -t ${IMAGE_NAME} .. || docker build -t ${IMAGE_NAME} .

if [ "${MODE}" = "detached" ]; then
  echo "[run-container] Running container in detached mode (name=${CONTAINER_NAME})..."
  docker run -d --name "${CONTAINER_NAME}" ${IMAGE_NAME}
  echo "[run-container] Container started. Use 'docker logs -f ${CONTAINER_NAME}' to follow logs."
else
  echo "[run-container] Running container (will remove on exit)..."
  docker run --rm --name "${CONTAINER_NAME}" ${IMAGE_NAME}
fi
