#!/bin/bash

set -e

# 옵션 처리
DRY_RUN=false
DOTFILES_DIR="$HOME"

# 인자가 없고 기본 디렉터리가 존재하지 않는 경우 현재 디렉터리 사용
if [ ! -d "$DOTFILES_DIR" ] && [ "$#" -eq 0 ]; then
    DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

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

# 2. 심볼릭 링크 생성 함수
create_symlink() {
    local src=$1
    local dest=$2
    
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$dest" -ef "$src" ]; then
            echo -e "    $dest -> $src (이미 설정됨)"
            return
        fi
        echo -e "    기존의 $dest 를 백업합니다 (.bak)"
        run_cmd mv "$dest" "${dest}.bak"
    fi
    
    run_cmd ln -sfn "$src" "$dest"
    if [ "$DRY_RUN" = true ]; then
        echo -e "    ${YELLOW}[DRY RUN] 생성 예정: $dest -> $src${NC}"
    else
        echo -e "    ${GREEN}생성됨: $dest -> $src${NC}"
    fi
}

echo -e "${BLUE}==> 심볼릭 링크를 설정합니다...${NC}"

# Zsh
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.zsh" "$HOME/.zsh"

# Vim / Neovim
run_cmd mkdir -p "$HOME/.vim"
create_symlink "$DOTFILES_DIR/.vim/vimrc" "$HOME/.vimrc"

run_cmd mkdir -p "$HOME/.config/nvim"
create_symlink "$DOTFILES_DIR/.vim/vimrc" "$HOME/.config/nvim/init.vim"

# Tmux
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Helix
run_cmd mkdir -p "$HOME/.config/helix"
create_symlink "$DOTFILES_DIR/helix/config.toml" "$HOME/.config/helix/config.toml"
create_symlink "$DOTFILES_DIR/helix/languages.toml" "$HOME/.config/helix/languages.toml"

# Ghostty
if [ -d "$DOTFILES_DIR/ghostty" ]; then
    if command -v ghostty &>/dev/null || [ -d "/Applications/Ghostty.app" ]; then
        run_cmd mkdir -p "$HOME/.config/ghostty"
        create_symlink "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
    else
        echo -e "    ${YELLOW}Ghostty 앱이 설치되어 있지 않아 설정을 건너뜁니다.${NC}"
    fi
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

# vim-plug for Neovim
if command -v nvim &>/dev/null; then
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    if [ ! -f "$XDG_DATA_HOME/nvim/site/autoload/plug.vim" ]; then
        echo -e "    Neovim을 위한 vim-plug 설치 중..."
        run_cmd curl -fLo "$XDG_DATA_HOME/nvim/site/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    run_cmd nvim +PlugInstall +qall
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
