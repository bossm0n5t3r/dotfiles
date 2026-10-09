# shellcheck shell=bash
pyenv-global() {
  if (($# > 1)); then
    printf 'Usage: pyenv-global [version]\n' >&2
    return 2
  fi

  local version answer current_global
  version=$(pyenv latest -k "${1:-3}") || return $?
  current_global=$(pyenv global) || return $?
  if [[ "$current_global" == "$version" ]] && pyenv prefix "$version" >/dev/null 2>&1; then
    printf 'Already set as pyenv global: %s\n' "$version"
    return 0
  fi

  printf 'Install Python %s if needed and set it as pyenv global? [y/N] ' "$version"
  if ! IFS= read -r answer; then
    answer=
  fi
  case "$answer" in
  [yY] | [yY][eE][sS])
    pyenv install -s "$version" && pyenv global "$version"
    ;;
  *)
    printf 'Cancelled; pyenv global unchanged.\n'
    ;;
  esac
}
