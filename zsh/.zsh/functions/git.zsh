# Color definitions
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# Usage: move-commit [days_before=1] [time=23:00:00] [target=1]
#   target: which commit to retime, counted from HEAD (1 = HEAD, 2 = HEAD~1, ...)
move-commit() {
    the_day_before=${1:-1}
    time=${2:-"23:00:00"}
    target=${3:-1}

    # return, not exit: exit would close the shell that called this function.
    is_git_repository=$(git rev-parse --is-inside-work-tree 2>/dev/null)
    if [[ ! $is_git_repository ]]; then
        printf "${RED}This directory is not a git repository.${NC}\n"
        return 1
    fi

    # Pop at the end only what this call stashed. "git stash" on a clean tree saves nothing,
    # and a plain "git stash pop" would then pop an older, unrelated stash.
    printf "${GREEN}RUN: git stash${NC}\n"
    stash_count_before=$(git stash list | wc -l)
    git stash
    stashed=0
    if (($(git stash list | wc -l) > stash_count_before)); then
        stashed=1
    fi

    target_date_command="date -v-${the_day_before}d"
    month_and_date=$(eval "${target_date_command} '+%b %d'")
    year=$(eval "${target_date_command} '+%Y'")
    modified_time_string="${month_and_date} ${time} ${year} +0900"

    printf "\n"
    printf "${GREEN}RUN: git rebase (edit HEAD~$((target - 1)))${NC}\n"
    # Mark only the first (oldest) commit of the range as "edit", without opening an editor.
    # --committer-date-is-author-date keeps the committer date of the commits after it,
    # which the rebase would otherwise reset to now.
    # Stop here if the rebase did not start (e.g. HEAD~${target} does not exist); amending now
    # would retime whatever HEAD is instead of the target commit.
    if ! GIT_SEQUENCE_EDITOR="sed -i '' '1s/^pick/edit/'" \
        git rebase -i --committer-date-is-author-date "HEAD~${target}"; then
        printf "${RED}git rebase failed. Nothing was changed.${NC}\n"
        if [[ -d "$(git rev-parse --git-path rebase-merge)" ]]; then
            git rebase --abort
        fi
        if ((stashed)); then
            git stash pop
        fi
        return 1
    fi

    printf "\n"
    printf "${GREEN}RUN: Edit git committer date${NC}\n"
    printf "${YELLOW}modified_time_string: ${modified_time_string}${NC}\n"
    printf "\n"

    if ! eval "GIT_COMMITTER_DATE=\"${modified_time_string}\" git commit --amend --no-edit --date \"${modified_time_string}\""; then
        printf "${RED}git commit --amend failed. Aborting the rebase.${NC}\n"
        git rebase --abort
        if ((stashed)); then
            git stash pop
        fi
        return 1
    fi

    printf "\n"
    printf "${GREEN}RUN: git rebase --continue${NC}\n"
    if ! git rebase --continue; then
        # Leave the rebase and the stash as they are so that nothing is lost; finish by hand.
        printf "${RED}git rebase --continue failed. Resolve it, then run: git rebase --continue${NC}\n"
        if ((stashed)); then
            printf "${RED}Your changes are still in the stash. Run git stash pop after the rebase.${NC}\n"
        fi
        return 1
    fi

    printf "\n"
    if ((stashed)); then
        printf "${GREEN}RUN: git stash pop${NC}\n"
        git stash pop
    else
        printf "${GREEN}Nothing was stashed, so nothing to pop.${NC}\n"
    fi
}
