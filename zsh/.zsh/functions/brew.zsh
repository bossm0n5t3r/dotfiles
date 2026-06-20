# Homebrew 관련 유틸 함수

back-up-brew() {
    brew bundle dump && mv Brewfile "$HOME/code/dotfiles"
}

brew-upgrade-all() {
    brew update-reset && brew update && brew upgrade --greedy && brew autoremove && brew cleanup && brew doctor
}
