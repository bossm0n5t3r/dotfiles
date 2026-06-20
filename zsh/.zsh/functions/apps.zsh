oapp() {
    open -a "$1"
}

qapp() {
    pkill -x "$1"
}

reset-launchpad() {
    rm -rf /private"$(getconf DARWIN_USER_DIR)"com.apple.dock.launchpad
    killall Dock
}

sdk-upgrade-all() {
    sdk selfupdate && sdk upgrade
}
