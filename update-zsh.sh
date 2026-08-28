#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
  -d | --dry-run)
    DRY_RUN=true
    shift
    ;;
  -h | --help)
    cat <<EOF
Usage: $0 [--dry-run]

Re-link only the Zsh package with GNU Stow.

Options:
    -d, --dry-run   Show changes without modifying links
    -h, --help      Show this help message
EOF
    exit 0
    ;;
  *)
    printf 'Unknown option: %s\n' "$1" >&2
    exit 2
    ;;
  esac
done

if ! command -v stow >/dev/null 2>&1; then
  printf 'GNU Stow is required. Install it with: brew install stow\n' >&2
  exit 1
fi

if [[ ! -d "$DOTFILES_DIR/zsh" ]]; then
  printf 'Zsh package not found: %s/zsh\n' "$DOTFILES_DIR" >&2
  exit 1
fi

stow_args=(
  --restow
  --verbose
  --dir="$DOTFILES_DIR"
  --target="$HOME"
  --no-folding
)

if [[ "$DRY_RUN" == true ]]; then
  stow_args+=(--simulate)
fi

stow "${stow_args[@]}" zsh

if [[ "$DRY_RUN" == true ]]; then
  printf 'Zsh link update dry-run completed.\n'
else
  printf 'Zsh links updated. Open a new shell to load the changes.\n'
fi
