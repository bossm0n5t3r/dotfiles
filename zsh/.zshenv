# Prefer the SDKMAN default JDK so non-interactive shells (which skip sdkman-init in .zshrc)
# use the same JDK as `java` on PATH. Fall back to the macOS-registered JDK otherwise.
# Keep an inherited JAVA_HOME (e.g. from `sdk use`) so child zsh processes don't reset it.
if [[ -z "$JAVA_HOME" ]]; then
    if [[ -d "${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/current" ]]; then
        export JAVA_HOME="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/current"
    else
        export JAVA_HOME=$(/usr/libexec/java_home)
    fi
fi
. "$HOME/.cargo/env"
