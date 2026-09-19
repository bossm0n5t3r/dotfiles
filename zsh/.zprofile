# Homebrew environment for the fixed Apple Silicon prefix.
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_CELLAR=/opt/homebrew/Cellar
export HOMEBREW_REPOSITORY=/opt/homebrew
typeset -U path PATH
path=(/opt/homebrew/bin /opt/homebrew/sbin $path)

if [[ -n ${MANPATH-} ]]; then
    export MANPATH="${MANPATH%"${MANPATH##*[!:]}"}"
    export MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"
fi

if [[ ":${INFOPATH:-}:" != *:/opt/homebrew/share/info:* ]]; then
    INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi
export INFOPATH

# >>> coursier install directory >>>
export PATH="$PATH:$HOME/Library/Application Support/Coursier/bin"
# <<< coursier install directory <<<

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
