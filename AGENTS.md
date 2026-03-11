# Repository Guidelines

## Project Structure & Module Organization

이 저장소는 macOS 중심 dotfiles 모음입니다. 루트에 주요 설정 파일이 있으며, 앱별 설정은 하위 디렉터리에 분리되어 있습니다.

- `.zshrc`, `.zsh/`: Zsh 기본 설정과 함수
- `.tmux.conf`: Tmux 설정
- `.vim/vimrc`: Vim/Neovim 공용 설정
- `helix/`, `ghostty/`: Helix/Ghostty 설정
- `Brewfile`: Homebrew 의존성 선언
- `install.sh`: 전체 설정 자동 설치 스크립트
- `docker-compose*.yaml`: 로컬 인프라(Postgres/Valkey) 구성

## Build, Test, and Development Commands

이 프로젝트는 빌드 산출물보다 “환경 동기화”가 핵심입니다.

- `./install.sh`: 기본 설치(심볼릭 링크, 플러그인, 선택적 `brew bundle`)
- `./install.sh --dry-run`: 변경 없이 적용 예정 작업 확인
- `brew bundle --file=./Brewfile`: 패키지/앱 동기화
- `docker-compose up -d`: 로컬 DB/캐시 컨테이너 실행

## Coding Style & Naming Conventions

- Shell 스크립트는 Bash 기준, 들여쓰기 4칸을 유지합니다(`install.sh` 스타일 준수).
- 파일/디렉터리명은 기존 규칙을 따릅니다: 설정 파일은 툴 이름 그대로 사용(예: `ghostty/config`, `helix/config.toml`).
- 스크립트 수정 시 `--dry-run` 동작을 깨지 않도록 분기 로직을 함께 점검합니다.
- 포맷터 강제는 없지만, Shell 변경 시 `shellcheck install.sh` 실행을 권장합니다.

## Testing Guidelines

자동 테스트 프레임워크는 현재 없습니다. 아래를 최소 검증 단위로 사용하세요.

- `./install.sh --dry-run`로 링크/설치 플로우 검증
- 실제 적용 후 `source ~/.zshrc`, `vim +PlugInstall +qall`, `nvim +PlugInstall +qall` 확인
- Docker 변경 시 `docker-compose ps`로 서비스 상태 확인

## Commit & Pull Request Guidelines

최근 이력은 Conventional Commits 패턴을 따릅니다.

- 형식: `type(scope): summary` (예: `feat(install.sh): add Ghostty configuration setup`)
- 자주 쓰는 타입: `feat`, `fix`, `docs`
- PR에는 목적, 변경 파일 요약, 로컬 검증 결과를 포함하세요.
- 설정 변경으로 사용자 동작이 달라지면, PR 본문에 마이그레이션/재적용 절차(예: 재링크, 재시작)를 명시하세요.

### Commit Message Generation Rules

Conventional Commits 형식으로 git commit 메시지를 생성할 때 아래 규칙을 따릅니다.

- 첫 줄 제목은 반드시 `<type>(<scope>): <summary>` 형식을 사용합니다.
- 허용 type: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `ci`, `build`, `perf`, `style`
- 제목(subject)은 영어로 작성합니다.
- 제목 길이는 72자를 넘기지 않습니다.
- 제목은 명령형(imperative mood)으로 작성합니다.
- 꼭 필요한 경우가 아니면 파일 이름을 언급하지 않습니다.
- 단순 diff 나열 대신 사용자/개발자 관점의 의도와 효과에 집중합니다.
- 필요할 때만 본문을 추가하며, 제목 다음 한 줄을 비운 뒤 bullet points를 사용합니다.
- backticks와 code fences는 commit message에 포함하지 않습니다.

## Security & Configuration Tips

- 비밀값은 저장소에 커밋하지 말고 `~/.secret_keys` 같은 로컬 파일에서 로드하세요.
- `Brewfile` 업데이트 시 불필요한 전역 도구 추가를 피하고, 이유를 커밋 메시지에 남기세요.
