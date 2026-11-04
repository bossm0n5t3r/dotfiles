#!/bin/bash

set -e

# 기존 파일을 .bak으로 백업하지 않고 stow --adopt로 패키지를 적용합니다.
# --adopt는 $HOME의 기존 파일을 저장소로 옮긴 뒤 심볼릭 링크를 만들기 때문에,
# 적용 후 git diff로 저장소 파일이 바뀌었는지 확인해야 합니다.

DRY_RUN=false
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=()

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "사용법: $0 [-d|--dry-run] <package>..."
    echo "예: $0 claude"
    echo "    $0 --dry-run zsh git"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -d | --dry-run)
        DRY_RUN=true
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    -*)
        echo "알 수 없는 옵션: $1"
        usage
        exit 1
        ;;
    *)
        PACKAGES+=("${1%/}")
        shift
        ;;
    esac
done

if [ "${#PACKAGES[@]}" -eq 0 ]; then
    echo -e "${YELLOW}오류: 적용할 패키지를 하나 이상 지정하세요.${NC}"
    usage
    exit 1
fi

if ! command -v stow &>/dev/null; then
    echo -e "${YELLOW}오류: stow 명령어를 찾을 수 없습니다. GNU Stow를 먼저 설치하세요.${NC}"
    exit 1
fi

for package in "${PACKAGES[@]}"; do
    if [ ! -d "$DOTFILES_DIR/$package" ]; then
        echo -e "${YELLOW}오류: 패키지를 찾을 수 없습니다: $package${NC}"
        exit 1
    fi
done

# 커밋되지 않은 변경이 있으면 adopt로 덮어쓴 내용과 구분할 수 없으므로 중단합니다.
if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain -- "${PACKAGES[@]}")" ]; then
    echo -e "${YELLOW}오류: 대상 패키지에 커밋되지 않은 변경사항이 있습니다. 먼저 커밋하거나 정리하세요.${NC}"
    git -C "$DOTFILES_DIR" status --short -- "${PACKAGES[@]}"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}==> [DRY RUN MODE] 실제 변경사항은 적용되지 않습니다.${NC}"
    stow --simulate --adopt --verbose --dir="$DOTFILES_DIR" --target="$HOME" --no-folding "${PACKAGES[@]}"
    exit 0
fi

echo -e "${BLUE}==> stow --adopt로 패키지를 적용합니다: ${PACKAGES[*]}${NC}"
stow --adopt --verbose --dir="$DOTFILES_DIR" --target="$HOME" --no-folding "${PACKAGES[@]}"

if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain -- "${PACKAGES[@]}")" ]; then
    echo -e "${YELLOW}==> 기존 파일 내용이 저장소로 옮겨져 아래 파일이 변경되었습니다.${NC}"
    git -C "$DOTFILES_DIR" status --short -- "${PACKAGES[@]}"
    echo -e "    ${YELLOW}git diff로 확인한 뒤, 저장소 버전을 유지하려면 다음을 실행하세요:${NC}"
    echo -e "    ${YELLOW}git -C $DOTFILES_DIR checkout -- ${PACKAGES[*]}${NC}"
else
    echo -e "${GREEN}==> 적용이 완료되었습니다. 저장소 파일 변경은 없습니다.${NC}"
fi
