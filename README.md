# dotfiles

Personal dotfiles and configuration for a productive macOS environment.

## 🚀 Overview

This repository contains my personal configurations for various tools including Zsh, Tmux, Vim/Neovim, Helix, and more.
It is optimized for macOS and uses Homebrew for package management.

## 🛠 Tech Stack

- **Shell:** Zsh with [Zimfw](https://zimfw.sh/) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Editors:** Neovim, Vim, Helix, VS Code
- **Terminal Multiplexer:** Tmux with [TPM](https://github.com/tmux-plugins/tpm)
- **Package Manager:** Homebrew (managed via `Brewfile`)
- **Containerization:** Docker / Colima
- **Languages/Runtimes:** Go, Rust, Ruby, Node.js (fnm), Python (pyenv), Java (SDKMAN)

## 📋 Requirements

- **OS:** macOS (Apple Silicon preferred, based on paths in `.zshrc`)
- **Package Manager:** [Homebrew](https://brew.sh/)
- **Default Shell:** Zsh
- **Directory Structure:** Most configurations assume this repo is cloned into `~/dotfiles`.

## ⚙️ Setup & Installation

### 1. Clone the Repository

```sh
mkdir -p ~/gitFolders
cd ~/gitFolders
git clone https://github.com/bossm0n5t3r/dotfiles.git
cd dotfiles
```

### 2. Run Setup Script

Everything can be set up automatically. By default, it uses `~/` (if it exists) or the directory where the script is located. 실행 시 dotfiles 디렉터리 경로를 입력받으며, 아무것도 입력하지 않으면 기본 설정된 값을 사용합니다. 또한 인자로 경로를 직접 지정할 수도 있습니다:

```sh
# 기본 디렉터리 사용 (~/ 또는 현재 디렉터리)
./install.sh

# 특정 디렉터리를 인자로 지정
./install.sh ~/gitFolders/dotfiles
```

You can also use the dry-run option to see what changes will be made without actually applying them:

```sh
./install.sh --dry-run
# or with a directory
./install.sh ~/gitFolders/dotfiles --dry-run
```

Alternatively, you can follow the manual steps below.

### 3. Manual Installation (Optional)

#### Install Dependencies

```sh
brew bundle
```

#### Apply Configurations

#### Zsh

```sh
# Backup existing .zshrc if necessary
mv ~/.zshrc ~/.zshrc.bak 2>/dev/null

# Symlink configurations
ln -sfn ~/gitFolders/dotfiles/.zshrc ~/.zshrc
ln -sfn ~/gitFolders/dotfiles/.zsh ~/.zsh

# Note: Zimfw and Powerlevel10k are used. Ensure they are installed via Homebrew.
```

#### Neovim / Vim

Both use `vim-plug` for plugin management.

**Neovim:**

```sh
# Install vim-plug for Neovim
curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p ~/.config/nvim
ln -sfn ~/gitFolders/dotfiles/.vim/vimrc ~/.config/nvim/init.vim
nvim +PlugInstall +qall
```

**Vim:**

```sh
# Install vim-plug for Vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

ln -sfn ~/gitFolders/dotfiles/.vim/vimrc ~/.vimrc
vim +PlugInstall +qall
```

#### Tmux

```sh
ln -sfn ~/gitFolders/dotfiles/.tmux.conf ~/.tmux.conf

# Install TPM (Tmux Plugin Manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Press `Prefix + I` (default prefix is Ctrl-a) inside tmux to install plugins.
```

#### Helix

```sh
mkdir -p ~/.config/helix
ln -sfn ~/gitFolders/dotfiles/helix/config.toml ~/.config/helix/config.toml
ln -sfn ~/gitFolders/dotfiles/helix/languages.toml ~/.config/helix/languages.toml
```

## 📜 Custom Scripts & Functions

The `.zsh/functions/` directory contains several utility functions:

- **Homebrew:**
  - `back-up-brew`: Dumps current brew bundle to `Brewfile` in the dotfiles repo.
  - `brew-upgrade-all`: Comprehensive Homebrew update and cleanup.
- **Git:**
  - `move-commit [days] [time]`: Amends the last commit's date to a specified time in the past (default: 1 day ago, 23:
    00).
- **Apps:**
  - `oapp [AppName]`: Opens a macOS application.
  - `qapp [AppName]`: Kills a macOS application.
  - `reset-launchpad`: Resets and restarts the macOS Launchpad.
  - `sdk-upgrade-all`: Updates SDKMAN and its installed candidates.

## 🐳 Docker

Docker Compose files are available for local development:

- `docker-compose.yaml`: Sets up Postgres and Valkey (Redis-compatible).
- `docker-compose-redis-only.yaml`: Sets up only Valkey.

```sh
docker-compose up -d
```

## 📂 Project Structure

```text
.
├── .tmux.conf              # Tmux configuration
├── .vim/                   # Vim related files
│   └── vimrc               # Shared Vim/Neovim config
├── .zsh/                   # Zsh extensions
│   └── functions/          # Custom Zsh functions
├── .zshrc                  # Zsh main configuration
├── Brewfile                # Homebrew dependencies
├── helix/                  # Helix editor configuration
├── docker-compose.yaml     # Local DB/Cache setup
├── LICENSE                 # MIT License
└── README.md               # You are here
```

## 🔐 Environment Variables

Key variables managed in `.zshrc`:

- `EDITOR`: Set to `vim`.
- `GOPATH`, `GOROOT`: Go environment.
- `RUSTUP_ROOT`: Rust environment.
- `ANDROID_HOME`: Android SDK path.
- `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE`, `DOCKER_HOST`: Colima/Docker configuration.

*Note: Sensitive keys should be placed in `~/.secret_keys`, which is automatically sourced.*

## ⚖️ License

Distributed under the [MIT License](LICENSE).
