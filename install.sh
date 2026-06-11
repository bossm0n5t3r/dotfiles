#!/bin/bash

set -e

# 옵션 처리
DRY_RUN=false
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_REQUIRED=false

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dry-run) DRY_RUN=true; shift ;;
        -*) echo "알 수 없는 옵션: $1"; exit 1 ;;
        *) DOTFILES_DIR="$(cd "$1" && pwd)"; shift ;;
    esac
done

# 사용자 입력 요청
echo -n "dotfiles 디렉터리 경로를 입력하세요 (기본값: $DOTFILES_DIR): "
read -r INPUT_DIR

if [ -n "$INPUT_DIR" ]; then
    if [ -d "$INPUT_DIR" ]; then
        DOTFILES_DIR="$(cd "$INPUT_DIR" && pwd)"
    else
        echo -e "${YELLOW}오류: 입력하신 디렉터리가 존재하지 않습니다: $INPUT_DIR${NC}"
        exit 1
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}==> [DRY RUN MODE] 실제 변경사항은 적용되지 않습니다.${NC}"
fi

echo -e "${BLUE}==> dotfiles 설정을 시작합니다...${NC}"
echo -e "${BLUE}==> 위치: $DOTFILES_DIR${NC}"

# 실행 함수 래퍼
run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "    ${YELLOW}[DRY RUN] 실행 예정: $*${NC}"
    else
        "$@"
    fi
}

backup_path() {
    local path=$1
    local backup="${path}.bak"

    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        return
    fi

    if [ -e "$backup" ] || [ -L "$backup" ]; then
        local timestamp
        timestamp="$(date +%Y%m%d%H%M%S)"
        backup="${path}.bak.${timestamp}"
    fi

    BACKUP_REQUIRED=true
    echo -e "    기존의 $path 를 백업합니다 (${backup##*/})"
    run_cmd mv "$path" "$backup"
}

prepare_managed_file() {
    local src=$1
    local rel_path=${src#"$DOTFILES_DIR/$2"/}
    local dest="$HOME/$rel_path"
    local target

    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        return
    fi

    if [ -L "$dest" ]; then
        target="$(cd "$(dirname "$dest")" && realpath "$(readlink "$dest")" 2>/dev/null || true)"
        if [ "$target" = "$src" ]; then
            return
        fi
    fi

    backup_path "$dest"
}

prepare_container_symlink() {
    local path=$1

    if [ -L "$path" ]; then
        backup_path "$path"
    fi
}

# 1. Homebrew 설치 확인 및 bundle 실행
if ! command -v brew &>/dev/null; then
    echo -e "${BLUE}==> Homebrew를 설치합니다...${NC}"
    if [ "$DRY_RUN" = true ]; then
        echo -e "    ${YELLOW}[DRY RUN] Homebrew 설치 스크립트 실행 예정${NC}"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
fi

if command -v brew &>/dev/null; then
    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        echo -n "Homebrew bundle을 실행하시겠습니까? (y/N): "
        read -r RUN_BREW_BUNDLE
        if [[ "$RUN_BREW_BUNDLE" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}==> Brewfile에 정의된 의존성을 설치합니다...${NC}"
            run_cmd brew bundle --file="$DOTFILES_DIR/Brewfile"
        else
            echo -e "    ${YELLOW}Homebrew bundle 실행을 건너뜁니다.${NC}"
        fi
    else
        echo -e "    ${YELLOW}Brewfile이 존재하지 않아 Homebrew bundle을 건너뜁니다.${NC}"
    fi
else
    echo -e "    ${YELLOW}brew 명령어를 찾을 수 없어 Homebrew bundle을 건너뜁니다.${NC}"
fi

if ! command -v stow &>/dev/null; then
    echo -e "${YELLOW}오류: stow 명령어를 찾을 수 없습니다. GNU Stow를 먼저 설치하세요.${NC}"
    echo -e "    ${YELLOW}예: brew install stow${NC}"
    exit 1
fi

# 2. GNU Stow로 심볼릭 링크 설정
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

AVAILABLE_PACKAGES=()
for package in "${STOW_PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$package" ]; then
        AVAILABLE_PACKAGES+=("$package")
    fi
done

if [ "${#AVAILABLE_PACKAGES[@]}" -eq 0 ]; then
    echo -e "${YELLOW}오류: stow 패키지를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo -e "${BLUE}==> stow 패키지를 설정합니다...${NC}"

prepare_container_symlink "$HOME/.zsh"
prepare_container_symlink "$HOME/.vim"
prepare_container_symlink "$HOME/.config/nvim"
prepare_container_symlink "$HOME/.config/helix"
prepare_container_symlink "$HOME/.config/ghostty"
prepare_container_symlink "$HOME/.config/alacritty"
prepare_container_symlink "$HOME/.config/zed"
prepare_container_symlink "$HOME/.vscode"

for package in "${AVAILABLE_PACKAGES[@]}"; do
    while IFS= read -r file; do
        prepare_managed_file "$file" "$package"
    done < <(find "$DOTFILES_DIR/$package" -type f)
done

if [ "$DRY_RUN" = true ]; then
    if [ "$BACKUP_REQUIRED" = true ]; then
        echo -e "    ${YELLOW}[DRY RUN] 백업 예정 경로가 있어 stow 시뮬레이션은 백업 후 실행 가능합니다.${NC}"
        echo -e "    ${YELLOW}[DRY RUN] 실행 예정: stow --simulate --verbose --dir=$DOTFILES_DIR --target=$HOME --no-folding ${AVAILABLE_PACKAGES[*]}${NC}"
    else
        stow --simulate --verbose --dir="$DOTFILES_DIR" --target="$HOME" --no-folding "${AVAILABLE_PACKAGES[@]}"
    fi
else
    run_cmd stow --verbose --dir="$DOTFILES_DIR" --target="$HOME" --no-folding "${AVAILABLE_PACKAGES[@]}"
fi

# 이전 설치 방식에서 사용하던 Vim 단일 파일 링크는 stow 관리 대상이 아니므로 정리합니다.
if [ -L "$HOME/.vimrc" ]; then
    backup_path "$HOME/.vimrc"
fi

# 3. 플러그인 매니저 설치 및 플러그인 설치
echo -e "${BLUE}==> 플러그인 매니저를 설치하고 플러그인을 설정합니다...${NC}"

# vim-plug for Vim
if command -v vim &>/dev/null; then
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        echo -e "    Vim을 위한 vim-plug 설치 중..."
        run_cmd curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    run_cmd vim +PlugInstall +qall
fi

# TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "    TPM(Tmux Plugin Manager) 설치 중..."
    run_cmd git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    if [ "$DRY_RUN" = false ]; then
        echo -e "    ${GREEN}Tmux 내에서 'Prefix + I'를 눌러 플러그인을 설치하세요.${NC}"
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}==> [DRY RUN] 설정 확인이 완료되었습니다.${NC}"
else
    echo -e "${GREEN}==> 모든 설정이 완료되었습니다!${NC}"
    echo -e "새로운 설정을 적용하려면 'source ~/.zshrc'를 실행하거나 터미널을 다시 시작하세요."
fi
