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
    local reset='\e[0m'
    local bold_blue='\e[1;34m'

    echo
    printf '%b\n' "${bold_blue}Running: sdk selfupdate${reset}"
    sdk selfupdate

    echo
    printf '%b\n' "${bold_blue}Running: sdk upgrade${reset}"
    sdk upgrade

    echo
    printf '%b\n' "${bold_blue}Running: sdk-cleanup${reset}"
    sdk-cleanup
}

sdk-cleanup() {
    local dry_run=0
    local keep_count=""
    local usage="Usage: sdk-cleanup [--dry-run] [versions-to-keep]"

    local sdkman_dir="${SDKMAN_DIR:-$HOME/.sdkman}"
    local candidates_dir="$sdkman_dir/candidates"

    local candidate_dir candidate current version answer version_dir
    local current_link
    local i

    local -a version_sort
    local -a version_dirs versions kept removable

    while (($# > 0)); do
        case "$1" in
        --dry-run | -n)
            dry_run=1
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "$usage" >&2
            return 1
            ;;
        *)
            if [[ -z "$keep_count" ]]; then
                keep_count="$1"
                shift
            else
                echo "$usage" >&2
                return 1
            fi
            ;;
        esac
    done

    keep_count="${keep_count:-3}"

    if [[ ! "$keep_count" =~ ^[0-9]+$ ]] || ((keep_count < 1)); then
        echo "$usage" >&2
        return 1
    fi

    if [[ ! -d "$candidates_dir" ]]; then
        echo "SDKMAN candidates directory not found: $candidates_dir" >&2
        return 1
    fi

    if command -v gsort >/dev/null 2>&1; then
        version_sort=(gsort -Vr)
    elif sort -V </dev/null >/dev/null 2>&1; then
        version_sort=(sort -Vr)
    else
        echo "Version-aware sort is unavailable." >&2
        echo "Install GNU coreutils with: brew install coreutils" >&2
        return 1
    fi

    for candidate_dir in "$candidates_dir"/*(/N); do
        candidate="${candidate_dir:t}"

        # Java는 메이저 버전별 유지 정책이 필요하므로 자동 정리에서 제외
        if [[ "$candidate" == "java" ]]; then
            echo
            echo "[java]"
            echo "  skipped: Java requires cleanup by major version"
            continue
        fi

        version_dirs=("$candidate_dir"/*(/N))
        versions=()

        for version_dir in "${version_dirs[@]}"; do
            version="${version_dir:t}"

            [[ "$version" == "current" ]] && continue
            versions+=("$version")
        done

        ((${#versions} == 0)) && continue

        versions=(
            "${(@f)$(
                printf '%s\n' "${versions[@]}" |
                    "${version_sort[@]}"
            )}"
        )

        if [[ ! -L "$candidate_dir/current" ]]; then
            {
                echo
                echo "[$candidate]"
                echo "  skipped: current version link was not found"
            } >&2
            continue
        fi

        if ! current_link="$(readlink "$candidate_dir/current")"; then
            {
                echo
                echo "[$candidate]"
                echo "  skipped: failed to resolve current version"
            } >&2
            continue
        fi

        current="${current_link:t}"

        if ((${versions[(Ie)$current]} == 0)); then
            {
                echo
                echo "[$candidate]"
                echo "  skipped: current version '$current' was not found"
            } >&2
            continue
        fi

        kept=()
        removable=()

        for ((i = 1; i <= ${#versions}; i++)); do
            version="${versions[$i]}"

            if ((i <= keep_count)) || [[ "$version" == "$current" ]]; then
                kept+=("$version")
            else
                removable+=("$version")
            fi
        done

        echo
        echo "[$candidate]"
        echo "  current: $current"
        echo "  keep:    ${kept[*]:-none}"
        echo "  remove:  ${removable[*]:-none}"

        if ((${#removable} == 0)); then
            echo "  nothing to remove"
            continue
        fi

        if ((dry_run)); then
            echo "  [dry-run] no changes made"
            continue
        fi

        printf "Remove these %d version(s) of %s? [y/N] " \
            "${#removable}" \
            "$candidate"

        read -r answer

        case "${answer:l}" in
        y | yes)
            for version in "${removable[@]}"; do
                if ! sdk uninstall "$candidate" "$version"; then
                    echo "  failed to uninstall $candidate $version" >&2
                fi
            done
            ;;
        *)
            echo "Skipped $candidate."
            ;;
        esac
    done
}
