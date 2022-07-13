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
    osascript -e "quit app \"$1\""
}

# pyenv settings
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# rbenv settings
eval "$(rbenv init - zsh)"

# zsh-syntax-highlighting
# It must be sourced at the end of the .zshrc file
source /Users/bossm0n5t3r/gitFolders/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# jenv
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
