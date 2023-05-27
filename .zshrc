# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:$HOME/flutter/bin

# Path to your oh-my-zsh installation.
export ZSH="/Users/bossm0n5t3r/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git)

source $ZSH/oh-my-zsh.sh

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

move-commit() {
  the_day_before=1
  time="23:00:00"
  if [[ $# -eq 2 ]]; then
      the_day_before=$1
      time=$2
  elif [[ $# -eq 1 ]]
  then
    the_day_before=$1
  fi

  is_git_repository=$(git rev-parse --is-inside-work-tree)
  if [[ ! $is_git_repository ]]
  then
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

# Ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
    export PATH=/opt/homebrew/opt/ruby/bin:$PATH
    export PATH=`gem environment gemdir`/bin:$PATH
fi

# Colima
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export DOCKER_HOST="unix://${HOME}/.colima/docker.sock"

# lazy*
alias lg='lazygit'
alias lzd='lazydocker'

# go
export GOPATH=$HOME/go

### Original export GOROOT
### export GOROOT="$(brew --prefix golang)/libexec"

### Optimized export GOROOT
export GOROOT="/opt/homebrew/opt/go/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# zsh-syntax-highlighting
# It must be sourced at the end of the .zshrc file
source /Users/bossm0n5t3r/gitFolders/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

