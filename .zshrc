###############################################
# IntelliJ Environment Reader Guard
###############################################
# When IntelliJ spawns a shell only to read the environment,
# skip Zim/prompt/plugins to avoid side effects (e.g. noclobber issues).
if [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]]; then
  set +o noclobber 2>/dev/null
  return
fi


###############################################
# Basic Zsh Configuration
###############################################

# history: keep only the most recent duplicate command
setopt HIST_IGNORE_ALL_DUPS

# keymap: use Emacs-style key bindings
bindkey -e

# Remove / from WORDCHARS to improve path navigation behavior
WORDCHARS=${WORDCHARS//[\/]}


###############################################
# Zim Initialization (Homebrew zimfw)
###############################################

# Directory used by zimfw
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

# Homebrew zimfw script path (Apple Silicon)
ZIMFW_SCRIPT=/opt/homebrew/opt/zimfw/share/zimfw.zsh

# If init.zsh is missing or older than the config file, regenerate it.
if [[ -f "${ZIMFW_SCRIPT}" ]]; then
  if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZIM_CONFIG_FILE:-${ZDOTDIR:-${HOME}}/.zimrc} ]]; then
    source "${ZIMFW_SCRIPT}" init
  fi
fi

# Initialize Zim modules
[[ -f ${ZIM_HOME}/init.zsh ]] && source ${ZIM_HOME}/init.zsh

# history-substring-search (works only if the Zim module is enabled)
zmodload -F zsh/terminfo +p:terminfo
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key

# zsh-autosuggestions (Zim module option)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1


###############################################
# PATH & Languages
###############################################

export EDITOR="vim"
export VISUAL="$EDITOR"

# uv tool / pipx global CLI executables
export PATH="$HOME/.local/bin:$PATH"

# Go
export GOPATH="$HOME/go"
export GOROOT="/opt/homebrew/opt/go/libexec"

# Rust
export RUSTUP_ROOT="/opt/homebrew/opt/rustup"

# Flutter / Go / Rust / Ruby / Obsidian
export PATH=$PATH:$HOME/flutter/bin:${RUSTUP_ROOT}/bin:${GOPATH}/bin:${GOROOT}/bin:/Applications/Obsidian.app/Contents/MacOS

# Ruby (Homebrew + gem bin)
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=$(gem environment gemdir)/bin:$PATH
fi

# Android
export ANDROID_HOME=~/Library/Android/sdk


###############################################
# Aliases
###############################################

alias rtw='printf "\e[8;24;80t"'
alias k='kubectl'
alias lg='lazygit'
alias lzd='lazydocker'


###############################################
# Functions (~/.zsh/functions/*.zsh)
###############################################

for f in $HOME/.zsh/functions/*.zsh; do
  [[ -r "$f" ]] && source "$f"
done


###############################################
# Tools (pyenv, fnm, fzf, Colima, secrets)
###############################################

# pyenv initialization
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# fnm (Node Version Manager)
if command -v fnm 1>/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

# fzf (Homebrew)
if [[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
fi

# Colima / Testcontainers
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export DOCKER_HOST="unix://${HOME}/.colima/docker.sock"

# Secret keys
[ -f "$HOME/.secret_keys" ] && source "$HOME/.secret_keys"


###############################################
# Powerlevel10k (Prompt)
###############################################

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"


###############################################
# Kubernetes (kubectl completion)
###############################################

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)


###############################################
# SDKMAN (must be last)
###############################################

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
