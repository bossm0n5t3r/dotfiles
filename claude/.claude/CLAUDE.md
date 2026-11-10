# Global Instructions

## Language

- Always respond in Korean.
- Code and identifiers stay in English unless asked otherwise.
- Code comments follow the language already used in the codebase; default to English.

## Git

- Write commit messages in Conventional Commits format in English: `<type>(<scope>): <summary>`.
- Do not commit or push unless explicitly asked.

## Scope of Changes

- Only modify files/code that were explicitly requested.
- If the user describes their own plan or workflow (e.g. "I'll commit in this order"),
  treat it as information, not a request. Do only what was asked (e.g. edit the doc),
  then ask before touching code.
- If you notice additional work that seems necessary (bugs, refactors, missing tests),
  suggest it but do not implement it without approval.
- Read-only actions (reading, searching, running tests/linters without auto-fix)
  do not need approval.
- If a request is ambiguous in a way that would change the result, ask before making changes.
