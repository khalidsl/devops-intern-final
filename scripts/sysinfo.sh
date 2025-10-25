#!/usr/bin/env bash
# scripts/sysinfo.sh
# Affiche l'utilisateur courant, la date et l'utilisation du disque

set -euo pipefail

echo "--- Informations système ---"
echo "Utilisateur courant: $(whoami)"
echo "Date actuelle: $(date)"
echo "\nUtilisation des disques (df -h):"
df -h || true
