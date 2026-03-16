#!/usr/bin/env bash
set -euo pipefail

# MODE=safe (default): dangling image + stopped container + old build cache
# MODE=aggressive: all unused images + all build cache
MODE="${MODE:-safe}"
PRUNE_VOLUMES="${PRUNE_VOLUMES:-0}"
CACHE_UNTIL="${CACHE_UNTIL:-168h}"
DRY_RUN="${DRY_RUN:-0}"

usage() {
  cat <<'EOF'
Usage:
  ./docker_cleanup.sh [--help]

Environment variables:
  MODE            Cleanup mode: safe | aggressive (default: safe)
  PRUNE_VOLUMES   Prune unused volumes: 0 | 1 (default: 0)
  CACHE_UNTIL     Build cache age filter in safe mode (default: 168h)
  DRY_RUN         Print commands without executing: 0 | 1 (default: 0)

Examples:
  ./docker_cleanup.sh
  CACHE_UNTIL=48h ./docker_cleanup.sh
  MODE=aggressive PRUNE_VOLUMES=1 ./docker_cleanup.sh
  DRY_RUN=1 MODE=aggressive PRUNE_VOLUMES=1 ./docker_cleanup.sh
EOF
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command is required" >&2
  exit 1
fi

if [[ "${MODE}" != "safe" && "${MODE}" != "aggressive" ]]; then
  echo "invalid MODE: ${MODE} (expected: safe or aggressive)" >&2
  exit 1
fi

if [[ "${PRUNE_VOLUMES}" != "0" && "${PRUNE_VOLUMES}" != "1" ]]; then
  echo "invalid PRUNE_VOLUMES: ${PRUNE_VOLUMES} (expected: 0 or 1)" >&2
  exit 1
fi

if [[ "${DRY_RUN}" != "0" && "${DRY_RUN}" != "1" ]]; then
  echo "invalid DRY_RUN: ${DRY_RUN} (expected: 0 or 1)" >&2
  exit 1
fi

run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

run_quiet() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "[dry-run] $*"
  else
    "$@" >/dev/null
  fi
}

echo "[1/4] prune stopped containers"
run_quiet docker container prune -f

if [[ "${MODE}" == "aggressive" ]]; then
  echo "[2/4] prune all unused images (image prune -a)"
  run_quiet docker image prune -a -f
else
  echo "[2/4] prune dangling images"
  run_quiet docker image prune -f
fi

if [[ "${MODE}" == "aggressive" ]]; then
  echo "[3/4] prune all build cache"
  run_quiet docker builder prune -a -f
else
  echo "[3/4] prune build cache older than ${CACHE_UNTIL}"
  run_quiet docker builder prune -f --filter "until=${CACHE_UNTIL}"
fi

if [[ "${PRUNE_VOLUMES}" == "1" ]]; then
  echo "[4/4] prune unused volumes"
  run_quiet docker volume prune -f
else
  echo "[4/4] skip volume prune (set PRUNE_VOLUMES=1 to enable)"
fi

echo "done"
run docker system df
