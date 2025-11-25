###############################################
# Zim / 기본 설정 (Zim 설치 시 생성)
###############################################

# -----------------
# History
# -----------------
setopt HIST_IGNORE_ALL_DUPS

# -----------------
# Input/output
# -----------------
bindkey -e
WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# -----------------
# Initialize Zim
# -----------------
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi

if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

source ${ZIM_HOME}/init.zsh

# ------------------------------
# Post-init: history-substring-search
# ------------------------------
zmodload -F zsh/terminfo +p:terminfo
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key


###############################################
# PATH & LANGUAGE
###############################################

export EDITOR='vim'

# Go
export GOPATH=$HOME/go
export GOROOT="/opt/homebrew/opt/go/libexec"

# Rust
export RUSTUP_ROOT="/opt/homebrew/opt/rustup"

# Flutter / Go / Rust / Ruby
export PATH=$PATH:$HOME/flutter/bin:${RUSTUP_ROOT}/bin:${GOPATH}/bin:${GOROOT}/bin

# Ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=$(gem environment gemdir)/bin:$PATH
fi


###############################################
# Aliases
###############################################

alias rtw='printf "\e[8;24;80t"'
alias k=kubectl
alias lg='lazygit'
alias lzd='lazydocker'


###############################################
# Functions
###############################################

oapp() { open -a $1; }
qapp() { pkill -x $1; }

reset-launchpad() {
  rm -rf /private$(getconf DARWIN_USER_DIR)com.apple.dock.launchpad
  killall Dock
}

back-up-brew() {
  brew bundle dump && mv Brewfile ~/gitFolders/dotfiles
}

brew-upgrade-all() {
  brew update-reset && brew update && brew upgrade --greedy \
    && brew autoremove && brew cleanup && brew doctor
}

move-commit() {
  echo "RUN: git stash"
  git stash

  the_day_before=${1:-1}
  time=${2:-"23:00:00"}

  is_git_repository=$(git rev-parse --is-inside-work-tree)
  if [[ ! $is_git_repository ]]; then
    echo "This directory is not a git repository."
    exit 0
  fi

  target_date_command="date -v-${the_day_before}d"
  month_and_date=$(eval "${target_date_command} '+%b %d'")
  year=$(eval "${target_date_command} '+%Y'")
  modified_time_string="${month_and_date} ${time} ${year} +0900"

  echo "RUN: git rebase"
  git rebase HEAD^ -i

  echo "RUN: Edit git committer date"
  eval "GIT_COMMITTER_DATE=\"${modified_time_string}\" git commit --amend --no-edit --date \"${modified_time_string}\""

  echo "RUN: git rebase --continue"
  git rebase --continue

  echo "RUN: git stash pop"
  git stash pop
}


###############################################
# Tools (fzf, pyenv, fnm, Colima, secrets)
###############################################

# fzf
set rtp+=/opt/homebrew/opt/fzf

# pyenv
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# fnm
eval "$(fnm env --use-on-cd)"

# Colima docker
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export DOCKER_HOST="unix://${HOME}/.colima/docker.sock"

# Secret keys
[ -f ~/.secret_keys ] && source ~/.secret_keys


###############################################
# Plugins: Syntax Highlighting / Powerlevel10k
###############################################

# zsh-syntax-highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# powerlevel10k
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh


###############################################
# Kubernetes
###############################################
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)


###############################################
# SDKMAN (must be last)
###############################################
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
