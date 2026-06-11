#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_STOW=true
VERBOSE=false

YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-stow)
            CHECK_STOW=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [--no-stow] [--verbose]

Validate that this dotfiles repository is linked into \$HOME correctly.

Options:
    --no-stow   Skip GNU Stow simulation checks
    --verbose   Print every valid managed symlink
    --help      Show this help message
EOF
            exit 0
            ;;
        *)
            echo -e "${YELLOW}오류: 알 수 없는 옵션입니다: $1${NC}"
            exit 2
            ;;
    esac
done

STOW_PACKAGES=(
    zsh
    tmux
    vim
    nvim
    helix
    ghostty
    alacritty
    zed
    vscode
)

CONTAINER_PATHS=(
    "$HOME/.zsh"
    "$HOME/.vim"
    "$HOME/.config/nvim"
    "$HOME/.config/helix"
    "$HOME/.config/ghostty"
    "$HOME/.config/alacritty"
    "$HOME/.config/zed"
    "$HOME/.vscode"
)

AVAILABLE_PACKAGES=()
ERRORS=0
WARNINGS=0
CHECKED_LINKS=0

note_ok() {
    if [ "$VERBOSE" = true ]; then
        echo -e "    ${GREEN}OK${NC}: $1"
    fi
}

note_warn() {
    WARNINGS=$((WARNINGS + 1))
    echo -e "    ${YELLOW}WARN${NC}: $1"
}

note_error() {
    ERRORS=$((ERRORS + 1))
    echo -e "    ${RED}FAIL${NC}: $1"
}

resolve_path() {
    local path=$1
    local dir
    local base

    dir=$(dirname "$path")
    base=$(basename "$path")
    cd "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base"
}

resolve_link() {
    local link=$1
    local target

    target=$(readlink "$link")
    case $target in
        /*) printf '%s\n' "$target" ;;
        *) resolve_path "$(dirname "$link")/$target" ;;
    esac
}

check_container_path() {
    local path=$1
    local resolved

    if [ -L "$path" ]; then
        resolved=$(resolve_link "$path" 2>/dev/null || true)
        note_error "$path 는 디렉터리여야 하지만 symlink입니다: $resolved"
        return
    fi

    if [ -e "$path" ] && [ ! -d "$path" ]; then
        note_error "$path 는 디렉터리여야 하지만 일반 파일입니다."
        return
    fi

    if [ -d "$path" ]; then
        note_ok "$path 컨테이너 디렉터리 확인"
    fi
}

check_managed_file() {
    local src=$1
    local package=$2
    local rel_path=${src#"$DOTFILES_DIR/$package"/}
    local dest="$HOME/$rel_path"
    local resolved

    CHECKED_LINKS=$((CHECKED_LINKS + 1))

    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        note_error "$dest 링크가 없습니다. 기대 대상: $src"
        return
    fi

    if [ ! -L "$dest" ]; then
        note_error "$dest 는 symlink가 아닙니다. 기대 대상: $src"
        return
    fi

    resolved=$(resolve_link "$dest" 2>/dev/null || true)
    if [ -z "$resolved" ] || [ ! -e "$resolved" ]; then
        note_error "$dest 는 깨진 symlink입니다: $(readlink "$dest")"
        return
    fi

    if [ "$resolved" != "$src" ]; then
        note_error "$dest 는 다른 대상을 가리킵니다: $resolved (기대: $src)"
        return
    fi

    note_ok "$dest -> $src"
}

run_stow_check() {
    local output
    local cleaned_output
    local status

    if [ "$CHECK_STOW" != true ]; then
        note_warn "GNU Stow 시뮬레이션을 건너뜁니다."
        return
    fi

    if ! command -v stow >/dev/null 2>&1; then
        note_error "stow 명령어를 찾을 수 없습니다. 예: brew install stow"
        return
    fi

    set +e
    output=$(stow --simulate --verbose --dir="$DOTFILES_DIR" --target="$HOME" --no-folding "${AVAILABLE_PACKAGES[@]}" 2>&1)
    status=$?
    set -e

    cleaned_output=$(
        printf '%s\n' "$output" | while IFS= read -r line; do
            if [ "$line" != "WARNING: in simulation mode so not modifying filesystem." ] && [ -n "$line" ]; then
                printf '%s\n' "$line"
            fi
        done
    )

    if [ "$status" -ne 0 ]; then
        note_error "stow 시뮬레이션이 실패했습니다."
        printf '%s\n' "$output" | while IFS= read -r line; do
            [ -n "$line" ] && echo "        $line"
        done
        return
    fi

    if [ -n "$cleaned_output" ]; then
        note_warn "stow 시뮬레이션에 변경 예정 출력이 있습니다."
        printf '%s\n' "$cleaned_output" | while IFS= read -r line; do
            [ -n "$line" ] && echo "        $line"
        done
        return
    fi

    note_ok "stow 시뮬레이션 충돌 없음"
}

for package in "${STOW_PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$package" ]; then
        AVAILABLE_PACKAGES+=("$package")
    else
        note_warn "$DOTFILES_DIR/$package 패키지 디렉터리가 없습니다."
    fi
done

if [ "${#AVAILABLE_PACKAGES[@]}" -eq 0 ]; then
    note_error "검증할 stow 패키지를 찾을 수 없습니다."
    exit 1
fi

echo -e "${BLUE}==> dotfiles symlink 상태를 검증합니다...${NC}"
echo -e "${BLUE}==> 위치: $DOTFILES_DIR${NC}"

echo -e "${BLUE}==> 컨테이너 디렉터리를 확인합니다...${NC}"
for path in "${CONTAINER_PATHS[@]}"; do
    check_container_path "$path"
done

echo -e "${BLUE}==> 관리 대상 파일 링크를 확인합니다...${NC}"
for package in "${AVAILABLE_PACKAGES[@]}"; do
    while IFS= read -r file; do
        check_managed_file "$file" "$package"
    done < <(find "$DOTFILES_DIR/$package" -type f)
done

echo -e "${BLUE}==> GNU Stow 시뮬레이션을 확인합니다...${NC}"
run_stow_check

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}==> 검증 실패: ${ERRORS}개 오류, ${WARNINGS}개 경고, ${CHECKED_LINKS}개 링크 확인${NC}"
    echo -e "${YELLOW}    ./doctor.sh --verbose 로 문제 링크를 확인한 뒤 ./install.sh --dry-run 으로 재적용 경로를 확인하세요.${NC}"
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}==> 검증 완료: 오류 없음, ${WARNINGS}개 경고, ${CHECKED_LINKS}개 링크 확인${NC}"
    exit 0
fi

echo -e "${GREEN}==> 검증 완료: 모든 ${CHECKED_LINKS}개 관리 링크가 올바릅니다.${NC}"
