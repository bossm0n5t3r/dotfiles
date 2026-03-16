#!/usr/bin/env bash
set -euo pipefail

# MODE=safe (default): dangling image + stopped container + old build cache
# MODE=aggressive: remove all unused images too (equivalent to image prune -a)
MODE="${MODE:-safe}"
PRUNE_VOLUMES="${PRUNE_VOLUMES:-0}"
CACHE_UNTIL="${CACHE_UNTIL:-168h}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command is required" >&2
  exit 1
fi

echo "[1/4] prune stopped containers"
docker container prune -f >/dev/null

if [[ "${MODE}" == "aggressive" ]]; then
  echo "[2/4] prune all unused images (image prune -a)"
  docker image prune -a -f >/dev/null
else
  echo "[2/4] prune dangling images"
  docker image prune -f >/dev/null
fi

echo "[3/4] prune build cache older than ${CACHE_UNTIL}"
docker builder prune -f --filter "until=${CACHE_UNTIL}" >/dev/null

if [[ "${PRUNE_VOLUMES}" == "1" ]]; then
  echo "[4/4] prune unused volumes"
  docker volume prune -f >/dev/null
else
  echo "[4/4] skip volume prune (set PRUNE_VOLUMES=1 to enable)"
fi

echo "done"
docker system df
