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

oapp() {
    open -a $1
}

qapp() {
    pkill -x $1
}

# pyenv settings
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# zsh-syntax-highlighting
# It must be sourced at the end of the .zshrc file
source /Users/bossm0n5t3r/gitFolders/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# jenv
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# Ruby
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi

# Colima
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export DOCKER_HOST="unix://${HOME}/.colima/docker.sock"

