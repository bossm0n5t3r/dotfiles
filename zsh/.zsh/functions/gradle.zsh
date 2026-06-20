gradle-wrapper() {
    ./gradlew :wrapper --gradle-version "${1:-latest}"
}
