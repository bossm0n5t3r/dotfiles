# shellcheck shell=bash
gradle-wrapper() {
    if [[ ! -x ./gradlew ]]; then
        printf 'gradle-wrapper: ./gradlew not found or not executable\n' >&2
        return 1
    fi

    ./gradlew :wrapper --gradle-version "${1:-latest}"
}
