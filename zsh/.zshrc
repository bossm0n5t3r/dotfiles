###############################################
# IntelliJ Environment Reader Guard
###############################################
# When IntelliJ spawns a shell only to read the environment,
# skip Zim/prompt/plugins to avoid side effects (e.g. noclobber issues).
if [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]]; then
    set +o noclobber 2>/dev/null
    return
fi

# Keep path arrays unique and register Homebrew completions before Zim runs compinit.
typeset -U path PATH fpath
fpath+=(/opt/homebrew/share/zsh/site-functions)

###############################################
# Basic Zsh Configuration
###############################################

# history: keep only the most recent duplicate command
setopt HIST_IGNORE_ALL_DUPS

# keymap: use Emacs-style key bindings
bindkey -e

# Remove / from WORDCHARS to improve path navigation behavior
WORDCHARS=${WORDCHARS//[\/]/}

# GPG: tell pinentry which terminal to use without spawning tty
export GPG_TTY=$TTY

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

# zsh-autosuggestions (Zim module option)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

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
# Functions (~/.zsh/functions/*.{zsh,sh})
###############################################

for f in $HOME/.zsh/functions/*.(zsh|sh)(N); do
    [[ -r "$f" ]] && source "$f"
done

###############################################
# Tools (pyenv, fnm, fzf, Colima, secrets)
###############################################

# pyenv initialization
if (( $+commands[pyenv] )); then
    if (( $+functions[_evalcache] )); then
        # Invalidate evalcache on Homebrew upgrades without spawning pyenv --version.
        _evalcache PYENV_EVALCACHE_VERSION="${commands[pyenv]:A:h:h:t}" \
            pyenv init --no-rehash - zsh
    else
        eval "$(pyenv init --no-rehash - zsh)"
    fi
fi

# fnm (Node Version Manager)
if command -v fnm 1>/dev/null 2>&1; then
    if (($+functions[zsh-defer])); then
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
export DOCKER_HOST="unix://${HOME}/.colima/docker.sock"

# Refresh the Colima address once per daemon lifecycle, then read it from cache.
COLIMA_ADDRESS_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/colima_address"
COLIMA_DAEMON_PID="$HOME/.colima/default/daemon/daemon.pid"

if [[ -s "$COLIMA_ADDRESS_CACHE" && ( ! -e "$COLIMA_DAEMON_PID" || "$COLIMA_ADDRESS_CACHE" -nt "$COLIMA_DAEMON_PID" ) ]]; then
    export TESTCONTAINERS_HOST_OVERRIDE="$(<"$COLIMA_ADDRESS_CACHE")"
elif (( $+commands[colima] && $+commands[jq] )); then
    COLIMA_ADDRESS="$(colima ls -j 2>/dev/null | jq -r '.address // empty')"
    if [[ -n "$COLIMA_ADDRESS" ]]; then
        mkdir -p "${COLIMA_ADDRESS_CACHE:h}"
        print -r -- "$COLIMA_ADDRESS" >|"$COLIMA_ADDRESS_CACHE"
        export TESTCONTAINERS_HOST_OVERRIDE="$COLIMA_ADDRESS"
    fi
    unset COLIMA_ADDRESS
fi

unset COLIMA_ADDRESS_CACHE COLIMA_DAEMON_PID

# Secret keys
[ -f "$HOME/.secret_keys" ] && source "$HOME/.secret_keys"

###############################################
# Pure (Prompt)
###############################################

autoload -U promptinit
promptinit
prompt pure

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
