Generate commit message for ${target} following the Conventional Commits specification.

- Only respond with the commit message.
- Start directly with the subject line (no preamble).
- The subject line must use the format `<type>(<scope>): <summary>`.
  - Allowed types: feat, fix, refactor, chore, docs, test, ci, build, perf, style.
  - The scope is the affected module, package, or area. Omit it (`<type>: <summary>`) only if no clear scope exists.
  - Write the summary in English, in the imperative mood (e.g. "add", not "added"), lowercase, with no trailing period.
  - For breaking changes, append `!` after the type/scope and add a `BREAKING CHANGE:` footer.
- The header must be less than ${lowLimit} (soft limit) and ${highLimit} (hard limit).
- Avoid mentioning file names unless necessary.
- Focus on the intent and effect of the change rather than listing the diff.
- Add a body only when needed, separated from the subject by a blank line, using bullet points.
- Hard wrap lines at ${guideLine} characters.
- Do not use backticks or code fences in the commit message.
- Don't use the 'generated' footer.
