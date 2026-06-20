###############################################
# IntelliJ Environment Reader Guard
###############################################
# When IntelliJ spawns a shell only to read the environment,
# skip Zim/prompt/plugins to avoid side effects (e.g. noclobber issues).
if [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]]; then
    set +o noclobber 2>/dev/null
    return
fi

# Powerlevel10k instant prompt. Keep this close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

###############################################
# Basic Zsh Configuration
###############################################

# history: keep only the most recent duplicate command
setopt HIST_IGNORE_ALL_DUPS

# keymap: use Emacs-style key bindings
bindkey -e

# Remove / from WORDCHARS to improve path navigation behavior
WORDCHARS=${WORDCHARS//[\/]/}

# GPG: tell pinentry which terminal to use
export GPG_TTY=$(tty)

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

# Keep Zim's environment defaults, but do not auto-cd into directories
unsetopt AUTO_CD

# history-substring-search (works only if the Zim module is enabled)
zmodload -F zsh/terminfo +p:terminfo
for key in '^[[A' '^P' ${terminfo[kcuu1]}; do
    bindkey "${key}" history-substring-search-up
done
for key in '^[[B' '^N' ${terminfo[kcud1]}; do
    bindkey "${key}" history-substring-search-down
done
for key in 'k'; do
    bindkey -M vicmd "${key}" history-substring-search-up
done
for key in 'j'; do
    bindkey -M vicmd "${key}" history-substring-search-down
done
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

# GraalVM
export GRAALVM_HOME=$HOME/.sdkman/candidates/java/25.0.2-graalce

# Go
export GOPATH="$HOME/go"
export GOROOT="/opt/homebrew/opt/go/libexec"

# Rust
export RUSTUP_ROOT="/opt/homebrew/opt/rustup"

# Flutter / Go / Rust / Ruby / Obsidian
export PATH=$PATH:$HOME/flutter/bin:${RUSTUP_ROOT}/bin:${GOPATH}/bin:${GOROOT}/bin:/Applications/Obsidian.app/Contents/MacOS

# Ruby (Homebrew + gem bin)
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

    for gem_bin in /opt/homebrew/lib/ruby/gems/*/bin(N); do
        [[ -d "$gem_bin" ]] && export PATH="$gem_bin:$PATH"
    done
    unset gem_bin
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
    if (($+functions[_evalcache])); then
        _evalcache PYENV_EVALCACHE_VERSION="$(pyenv --version)" pyenv init - zsh
    else
        eval "$(pyenv init - zsh)"
    fi
fi

# fnm (Node Version Manager)
if command -v fnm 1>/dev/null 2>&1; then
    if (($+functions[zsh - defer])); then
        zsh-defer -c 'eval "$(fnm env --use-on-cd)"'
    else
        eval "$(fnm env --use-on-cd)"
    fi
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
export TESTCONTAINERS_HOST_OVERRIDE="$(colima ls -j | jq -r '.address')"
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

if [[ $commands[kubectl] ]]; then
    KUBECTL_COMPLETION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/kubectl_completion.zsh"
    mkdir -p "${KUBECTL_COMPLETION_CACHE:h}"

    if [[ ! -f "$KUBECTL_COMPLETION_CACHE" || "$KUBECTL_COMPLETION_CACHE" -ot "$(command -v kubectl)" ]]; then
        kubectl completion zsh >|"$KUBECTL_COMPLETION_CACHE"
    fi

    source "$KUBECTL_COMPLETION_CACHE"
    unset KUBECTL_COMPLETION_CACHE
fi

###############################################
# SDKMAN (must be last)
###############################################

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# >>> aienv >>>
[ -f "$HOME/.aienv/env" ] && source "$HOME/.aienv/env"
# <<< aienv <<<
