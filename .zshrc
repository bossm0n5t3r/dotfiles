# Start configuration added by Zim install {{{
#
# User configuration sourced by interactive shells
#

# -----------------
# Zsh configuration
# -----------------

#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -e

# Prompt for spelling correction of commands.
#setopt CORRECT

# Customize spelling correction prompt.
#SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# -----------------
# Zim configuration
# -----------------

# Use degit instead of git as the default tool to install and update modules.
#zstyle ':zim:zmodule' use 'degit'

# --------------------
# Module configuration
# --------------------

#
# git
#

# Set a custom prefix for the generated aliases. The default prefix is 'G'.
#zstyle ':zim:git' aliases-prefix 'g'

#
# input
#

# Append `../` to your input for each `.` you type after an initial `..`
#zstyle ':zim:input' double-dot-expand yes

#
# termtitle
#

# Set a custom terminal title format using prompt expansion escape sequences.
# See http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Simple-Prompt-Escapes
# If none is provided, the default '%n@%m: %~' is used.
#zstyle ':zim:termtitle' format '%1~'

#
# zsh-autosuggestions
#

# Disable automatic widget re-binding on each precmd. This can be set when
# zsh-users/zsh-autosuggestions is the last module in your ~/.zimrc.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Customize the style that the suggestions are shown with.
# See https://github.com/zsh-users/zsh-autosuggestions/blob/master/README.md#suggestion-highlight-style
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'

#
# zsh-syntax-highlighting
#

# Set what highlighters will be used.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Customize the main highlighter styles.
# See https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md#how-to-tweak-it
#typeset -A ZSH_HIGHLIGHT_STYLES
#ZSH_HIGHLIGHT_STYLES[comment]='fg=242'

# ------------------
# Initialize modules
# ------------------

ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  if (( ${+commands[curl]} )); then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  else
    mkdir -p ${ZIM_HOME} && wget -nv -O ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
fi
# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi
# Initialize modules.
source ${ZIM_HOME}/init.zsh

# ------------------------------
# Post-init module configuration
# ------------------------------

#
# zsh-history-substring-search
#

zmodload -F zsh/terminfo +p:terminfo
# Bind ^[[A/^[[B manually so up/down works both before and after zle-line-init
for key ('^[[A' '^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
for key ('^[[B' '^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
for key ('k') bindkey -M vicmd ${key} history-substring-search-up
for key ('j') bindkey -M vicmd ${key} history-substring-search-down
unset key
# }}} End configuration added by Zim install

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Go
export GOPATH=$HOME/go

### Original export GOROOT
### export GOROOT="$(brew --prefix golang)/libexec"

### Optimized export GOROOT
export GOROOT="/opt/homebrew/opt/go/libexec"

# Rustup ROOT
export RUSTUP_ROOT="/opt/homebrew/opt/rustup"

# flutter, Rust, Go
export PATH=$PATH:$HOME/flutter/bin:${RUSTUP_ROOT}/bin:${GOPATH}/bin:${GOROOT}/bin

# Ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=$(gem environment gemdir)/bin:$PATH
fi

# Path to your oh-my-zsh installation.
# export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="agnoster"
plugins=(git)

# source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

export EDITOR='vim'

# Functions

oapp() {
  open -a $1
}

qapp() {
  pkill -x $1
}

reset-launchpad() {
  defaults write com.apple.dock ResetLaunchPad -bool true && killall Dock
}

back-up-brew() {
  brew bundle dump && mv Brewfile ~/gitFolders/dotfiles
}

brew-upgrade-all() {
  brew update-reset && brew update && brew upgrade --greedy && brew autoremove && brew cleanup && brew doctor
}

move-commit() {
  # git stash
  echo "RUN: git stash"
  git stash

  the_day_before=1
  time="23:00:00"
  if [[ $# -eq 2 ]]; then
    the_day_before=$1
    time=$2
  elif [[ $# -eq 1 ]]; then
    the_day_before=$1
  fi

  is_git_repository=$(git rev-parse --is-inside-work-tree)
  if [[ ! $is_git_repository ]]; then
    echo "This directory is not a git repository."
    exit 0
  fi

  target_date_command="date -v-${the_day_before}d"
  month_and_date=$(eval "${target_date_command} '+%b %d'")
  year=$(eval "${target_date_command} '+%Y'")

  # git rebase
  echo "RUN: git rebase"
  git rebase HEAD^ -i

  # Edit git committer date
  echo
  echo
  echo "RUN: Edit git committer date"
  modified_time_string="${month_and_date} ${time} ${year} +0900"
  echo
  echo "modified_time_string: ${modified_time_string}"
  echo
  modified_git_committer_date="GIT_COMMITTER_DATE=\"${modified_time_string}\" git commit --amend --no-edit --date \"${modified_time_string}\""
  eval "$modified_git_committer_date"

  # git rebase --continue
  echo
  echo
  echo "RUN: git rebase --continue"
  git rebase --continue

  # git stash pop
  echo
  echo
  echo "RUN: git stash pop"
  git stash pop
}

## fzf settings
set rtp+=/opt/homebrew/opt/fzf

# pyenv settings
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# jenv
export PATH="$HOME/.jenv/bin:$PATH"
if command -v jenv 1>/dev/null 2>&1; then
  eval "$(jenv init -)"
fi

# fnm
eval "$(fnm env --use-on-cd)"

# Colima
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export DOCKER_HOST="unix://${HOME}/.colima/docker.sock"

# lazy*
alias lg='lazygit'
alias lzd='lazydocker'

### zsh-syntax-highlighting

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

### powerlevel10k

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
