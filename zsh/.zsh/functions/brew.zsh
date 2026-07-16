# Homebrew 관련 유틸 함수

back-up-brew() {
    brew bundle dump --force --file="$HOME/code/dotfiles/Brewfile"
}

brew-upgrade-all() {
    brew update-reset && brew update && brew upgrade --greedy && brew autoremove && brew cleanup && brew doctor
}
