# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

move-commit() {
    printf "${GREEN}RUN: git stash${NC}\n"
    git stash

    the_day_before=${1:-1}
    time=${2:-"23:00:00"}

    is_git_repository=$(git rev-parse --is-inside-work-tree)
    if [[ ! $is_git_repository ]]; then
        printf "${RED}This directory is not a git repository.${NC}\n"
        exit 0
    fi

    target_date_command="date -v-${the_day_before}d"
    month_and_date=$(eval "${target_date_command} '+%b %d'")
    year=$(eval "${target_date_command} '+%Y'")
    modified_time_string="${month_and_date} ${time} ${year} +0900"

    printf "\n"
    printf "${GREEN}RUN: git rebase${NC}\n"
    git rebase HEAD^ -i

    printf "\n"
    printf "${GREEN}RUN: Edit git committer date${NC}\n"
    printf "${YELLOW}modified_time_string: ${modified_time_string}${NC}\n"
    printf "\n"

    eval "GIT_COMMITTER_DATE=\"${modified_time_string}\" git commit --amend --no-edit --date \"${modified_time_string}\""

    printf "\n"
    printf "${GREEN}RUN: git rebase --continue${NC}\n"
    git rebase --continue

    printf "\n"
    printf "${GREEN}RUN: git stash pop${NC}\n"
    git stash pop
}
