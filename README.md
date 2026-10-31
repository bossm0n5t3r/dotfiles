# dotfiles

Personal dotfiles and configuration for a productive macOS environment.

## 🚀 Overview

This repository contains my personal configurations for various tools including Zsh, Tmux, Vim/Neovim, Helix, and more.
It is optimized for macOS and uses Homebrew plus GNU Stow for package and symlink management.

## 🛠 Tech Stack

- **Shell:** Zsh with [Zimfw](https://zimfw.sh/) and [Pure](https://github.com/sindresorhus/pure)
- **Editors:** Neovim, Vim, Helix, VS Code
- **Terminal Multiplexer:** Tmux with [TPM](https://github.com/tmux-plugins/tpm)
- **Package Manager:** Homebrew (managed via `Brewfile`) and GNU Stow
- **Containerization:** Docker / Colima
- **Languages/Runtimes:** Go, Rust, Ruby, Node.js (fnm), Python (uv), Java (SDKMAN)

## 📋 Requirements

- **OS:** macOS (Apple Silicon preferred, based on paths in `zsh/.zshrc`)
- **Package Manager:** [Homebrew](https://brew.sh/)
- **Symlink Manager:** [GNU Stow](https://www.gnu.org/software/stow/)
- **Default Shell:** Zsh
- **Directory Structure:** Most configurations assume this repo is cloned into `~/code/dotfiles`.

## ⚙️ Setup & Installation

### 1. Clone the Repository

```sh
mkdir -p ~/code
cd ~/code
git clone https://github.com/bossm0n5t3r/dotfiles.git
cd dotfiles
```

### 2. Run Setup Script

Everything can be set up automatically. By default, the script uses the repository directory that contains `install.sh`.
실행 시 dotfiles 디렉터리 경로를 입력받으며, 아무것도 입력하지 않으면 기본 설정된 값을 사용합니다. 또한 인자로 경로를 직접 지정할 수도 있습니다:

```sh
# 기본 디렉터리 사용 (현재 저장소)
./install.sh

# 특정 디렉터리를 인자로 지정
./install.sh ~/code/dotfiles
```

You can also use the dry-run option to see what changes will be made without actually applying them:

```sh
./install.sh --dry-run
# or with a directory
./install.sh ~/code/dotfiles --dry-run
```

You can verify the current symlink state at any time:

```sh
./doctor.sh
```

Alternatively, you can follow the manual steps below.

### 3. Manual Installation (Optional)

#### Install Dependencies

```sh
brew bundle --file=./Brewfile
```

Repository JavaScript tooling uses pnpm 12.11.2, pinned in `package.json`.
Keep `pnpm-lock.yaml` committed; dependency build-script approvals are stored in `pnpm-workspace.yaml`.

```sh
pnpm install --frozen-lockfile
pnpm run format:check
# Apply formatting when needed:
pnpm run format
```

#### Apply Configurations with Stow

Each top-level package mirrors the path that should exist under `$HOME`.

```sh
stow --dir=. --target="$HOME" --no-folding \
    zsh tmux vim nvim helix ghostty alacritty zed vscode
```

To preview changes without creating links:

```sh
stow --simulate --verbose --dir=. --target="$HOME" --no-folding \
    zsh tmux vim nvim helix ghostty alacritty zed vscode
```

Zsh syntax highlighting uses colorblind-friendly styling.
Set `ZSH_SYNTAX_THEME` in `zsh/.zshrc` to select a palette, or `none` to use the plugin's default styles.

To remove a package:

```sh
stow --delete --dir=. --target="$HOME" zsh
```

#### Plugin Managers

Vim uses `vim-plug`; Tmux uses TPM.

```sh
# Vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall

# Tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

#### Zed

The `zed` Stow package links `zed/.config/zed/settings.json` to `~/.config/zed/settings.json`.
Existing links pick up edits without re-running Stow.

- Kotlin uses `kotlin-lsp`; configure JVM/toolchain targets in the project rather than in settings for the inactive
  `kotlin-language-server`.
- Python uses basedpyright for type analysis and Ruff for formatting, import organization, and auto-fixable lint
  corrections on save.
- TypeScript and TSX both use Prettier on save; Zed treats them as separate language settings.

## 📜 Custom Scripts & Functions

The `zsh/.zsh/functions/` directory contains several utility functions:

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

## Python Version Management

Use [uv](https://docs.astral.sh/uv/) to install Python and select versions.

```sh
# Install the latest available Python 3.15 patch as the terminal default.
uv python install 3.15 --default --upgrade

# Set the fallback Python version for uv commands.
uv python pin --global 3.15

# Override the version for a project (writes .python-version).
uv python pin 3.13
uv run python --version
```

Ensure uv's executable directory (`uv python dir --bin`) takes precedence on `PATH`
for the shell's `python` and `python3` commands to use the installed default.
The global pin applies to uv commands when no project or explicit Python version takes precedence.
Use an exact version such as `3.15.2` in both commands if you need a specific patch rather than the latest available
patch.

## 🐳 Docker

Docker Compose files are available for local development:

- `docker-compose.yaml`: Sets up Postgres and Valkey (Redis-compatible).
- `docker-compose-redis-only.yaml`: Sets up only Valkey.

```sh
docker-compose up -d
```

### Docker Cleanup Script

Use `docker_cleanup.sh` to remove unused Docker resources with predictable modes.

- `--help`, `-h`: show usage and examples.
- `MODE=safe` (default): prune stopped containers, dangling images, and old build cache.
- `MODE=aggressive`: prune all unused images and all build cache.
- `PRUNE_VOLUMES=1`: also prune unused volumes (default: `0`).
- `CACHE_UNTIL`: build cache age filter for safe mode (default: `168h`).
- `DRY_RUN=1`: print commands without executing them (default: `0`).

```sh
# Show help
./docker_cleanup.sh --help

# Default safe cleanup
./docker_cleanup.sh

# Safe mode + custom build cache window (48 hours)
CACHE_UNTIL=48h ./docker_cleanup.sh

# Aggressive cleanup including volumes
MODE=aggressive PRUNE_VOLUMES=1 ./docker_cleanup.sh

# Preview only (no changes)
DRY_RUN=1 MODE=aggressive PRUNE_VOLUMES=1 ./docker_cleanup.sh
```

The script validates `MODE`, `PRUNE_VOLUMES`, and `DRY_RUN` values and exits with an error on invalid inputs.

## 📂 Project Structure

```text
.
├── zsh/                     # ~/.zshrc, ~/.zsh, Zimfw and Pure prompt
├── tmux/                    # ~/.tmux.conf
├── vim/                     # ~/.vim/vimrc
├── nvim/                    # ~/.config/nvim
├── helix/                   # ~/.config/helix
├── ghostty/                 # ~/.config/ghostty
├── alacritty/               # ~/.config/alacritty
├── zed/                     # ~/.config/zed
├── vscode/                  # ~/.vscode
├── Brewfile                 # Homebrew dependencies
├── docker-compose.yaml      # Local DB/Cache setup
├── LICENSE                  # MIT License
└── README.md                # You are here
```

## 🔐 Environment Variables

Key variables managed in `zsh/.zshrc`:

- `EDITOR`: Set to `vim`.
- `GOPATH`, `GOROOT`: Go environment.
- `RUSTUP_ROOT`: Rust environment.
- `ANDROID_HOME`: Android SDK path.
- `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE`, `DOCKER_HOST`: Colima/Docker configuration.

**Note: Sensitive keys should be placed in `~/.secret_keys`, which is automatically sourced.**

## ⚖️ License

Distributed under the [MIT License](LICENSE).
