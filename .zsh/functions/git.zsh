move-commit() {
  echo "RUN: git stash"
  git stash

  the_day_before=${1:-1}
  time=${2:-"23:00:00"}

  is_git_repository=$(git rev-parse --is-inside-work-tree)
  if [[ ! $is_git_repository ]]; then
    echo "This directory is not a git repository."
    exit 0
  fi

  target_date_command="date -v-${the_day_before}d"
  month_and_date=$(eval "${target_date_command} '+%b %d'")
  year=$(eval "${target_date_command} '+%Y'")
  modified_time_string="${month_and_date} ${time} ${year} +0900"

  echo
  echo "RUN: git rebase"
  git rebase HEAD^ -i

  echo
  echo "RUN: Edit git committer date"
  echo "modified_time_string: ${modified_time_string}"
  echo
  eval "GIT_COMMITTER_DATE=\"${modified_time_string}\" git commit --amend --no-edit --date \"${modified_time_string}\""

  echo
  echo "RUN: git rebase --continue"
  git rebase --continue

  echo
  echo "RUN: git stash pop"
  git stash pop
}
