---
name: git-commit
description: Generate a Conventional Commits message from currently staged git changes, ask for confirmation or regeneration, and commit only after explicit user approval. Use when invoked directly or when the user wants to commit staged changes with a generated conventional commit message.
---

# Conventional Commit Staged Changes

Use this skill when the current working directory is expected to be a git repository and the user wants a Conventional Commits message for already staged changes. If the user asks to commit, commit only after explicit approval of the final message.

If this skill is invoked directly with no additional user text, treat that as a request to inspect the currently staged changes and propose a Conventional Commit message. Still commit only after explicit user approval.

## Workflow

1. Verify the current directory is inside a git work tree:

   ```bash
   git rev-parse --is-inside-work-tree
   ```

   - If this fails or does not print `true`, stop and tell the user the current folder is not a git repository.

2. Verify there are staged changes:

   ```bash
   git diff --cached --quiet; echo $?
   ```

   - Exit code `1` means staged changes exist.
   - Exit code `0` means there are no staged changes; stop and ask the user to stage files first.

3. Inspect only staged changes. Do not include unstaged or untracked changes in the generated message.
   Recommended commands:

   ```bash
   git diff --cached --name-status
   git diff --cached --stat
   git diff --cached
   ```

   If the diff is large, use `--name-status`, `--stat`, and the relevant hunks needed to infer intent.

4. Generate one Conventional Commits message for the staged changes.
   - Format: `<type>(<scope>): <subject>`
   - Allowed types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `ci`, `build`, `perf`, `style`
   - Use a concise imperative subject in English.
   - Keep the subject at or below 72 characters.
   - Prefer intent and user/developer impact over listing changed files.
   - Avoid file names in the subject unless they are essential context.
   - Add a body only when it materially improves clarity.
   - If adding a body, leave one blank line after the subject and use bullet points.
   - Add `BREAKING CHANGE:` footer when the staged diff includes a breaking change.
   - Do not include backticks or code fences in the commit message.

5. Present the generated message to the user and ask for confirmation.
   Always use this exact fixed confirmation prompt, without paraphrasing:

   ```text
   다음 커밋 메시지로 커밋할까요? 답변: yes / regenerate / edit / cancel
   ```

   - Confirm: commit with this exact message if the user asked to commit.
   - Regenerate: create a new candidate message from the same staged diff, then ask again.
   - Edit/custom request: adjust the message accordingly, then ask again.
   - Cancel: do not commit.

6. If the user confirms a commit, re-check the staged file list before committing:

   ```bash
   git diff --cached --name-status
   ```

   If the staged changes appear different from the diff used for the proposal, warn the user and ask for confirmation again before committing.

7. Commit only after explicit confirmation from the user.
   Use a safe multi-line commit command:

   ```bash
   git commit -m "<subject>" -m "<body if any>"
   ```

   For complex messages, write the message to a temporary file and run:

   ```bash
   git commit -F /tmp/pi-commit-message.txt
   ```

8. After committing, show the short commit hash and final commit subject:
   ```bash
   git log -1 --pretty=format:'%h %s'
   ```

## Important Rules

- Never stage files as part of this skill unless the user explicitly asks.
- Never commit without explicit user confirmation of the final generated message.
- If the user only asks for a commit message, generate the message but do not commit.
- Regeneration must not commit; it only proposes a new message and asks again.
- Do not amend, squash, push, or create tags unless the user explicitly asks.
