---
name: git-commit-push
description: >
  Use this skill whenever the user wants to commit code, stage changes, write a commit
  message, or push to a remote. Trigger on: "commit this", "commit and push", "git commit",
  "push my changes", "create a commit", "stage and commit", "what should my commit message be",
  "help me commit", "push to origin", "commit everything", "save my changes to git".
  Also trigger automatically whenever you are about to run `git commit` or `git add` + `git commit`
  — apply this convention without waiting for the user to ask. The commit message MUST follow
  the convention defined in this skill every single time.
allowed-tools: Bash(git *)
---

# git-commit-push

Produces correctly formatted commit messages and guides the full stage → commit → push workflow.

---

## Commit message format

```
<type>(<scope>): <subject>

<body>

<footer>
```

Only `type` and `subject` are required. `scope`, body, and footer are optional.

---

## Types

| Type       | When to use                                      |
|------------|--------------------------------------------------|
| `feat`     | A new feature                                    |
| `fix`      | A bug fix                                        |
| `docs`     | Documentation only                               |
| `style`    | Formatting, whitespace, missing semicolons       |
| `refactor` | Code restructuring without behaviour change      |
| `perf`     | Performance improvements                         |
| `test`     | Adding or updating tests                         |
| `chore`    | Dependency updates, build config, maintenance    |
| `ci`       | CI/CD pipeline changes                           |
| `revert`   | Reverting a previous commit                      |

---

## Scope (optional)

Identifies the module changed — never prefix with the project name (each project has its own repo).

| Stack           | Common scopes                                                     |
|-----------------|-------------------------------------------------------------------|
| Python/Backend  | `auth`, `api`, `database`, `models`, `services`, `utils`, `config` |
| React/Frontend  | `auth`, `components`, `pages`, `hooks`, `router`, `api`, `ui`, `styles` |
| General         | `deps`, `ci`, `docs`, `tests`, `config`                          |

---

## Subject line rules

1. Imperative present tense — "add" not "added" or "adds"
2. Lowercase first letter
3. No trailing period
4. Max 50 characters
5. One sentence only — no "and" chaining (split into separate commits instead)

**Good examples:**
```
feat(auth): add password reset functionality
fix(api): handle null response from external service
docs: update installation instructions
chore(deps): upgrade eslint to v9
```

**Bad examples:**
```
feat(auth): Added password reset    ← past tense
Fix(api): Handle null response.     ← capitalized, has period
docs: updates                       ← too vague
feat: made changes to auth system   ← too long, vague
fix(ui): update button and fix nav  ← "and" chains two changes
```

---

## Body (optional)

Include when the subject alone doesn't explain the motivation.

- Imperative present tense
- Explains *what* and *why*, not *how*
- Wrap lines at 72 characters

**Example:**
```
refactor(api): simplify error handling logic

Replace multiple try-catch blocks with centralized error handler.
This makes the code more maintainable and reduces duplication
across endpoint handlers.
```

---

## Footer (optional)

```
Closes #123
Fixes #456
Related to #101

BREAKING CHANGE: describe what changed and why clients must update
```

**Important:** Do NOT add `Co-authored-by:`, `Author:`, or any attribution lines. Git tracks authorship automatically.

---

## Branch naming convention

```
<type>/<ticket-id>-<short-description>
```

Rules: lowercase, kebab-case, include ticket ID when available.

```
feature/PROJ-123-add-user-authentication
bugfix/PROJ-456-fix-database-connection-leak
hotfix/patch-critical-error
refactor/restructure-auth-module
```

Branch types: `feature/`, `bugfix/`, `hotfix/`, `refactor/`, `docs/`, `test/`, `chore/`, `experiment/`

---

## Workflow

### 1 — Understand what changed

Run `git status` and `git diff` to understand the full scope of changes before writing anything.

### 2 — Stage changes

Stage the relevant files. Prefer naming specific files over `git add -A` or `git add .` to avoid accidentally including untracked secrets or binaries.

If the diff contains logically separate concerns (e.g., a bug fix alongside a refactor), suggest splitting into multiple commits — one concern per commit.

### 3 — Write the commit message

Construct the message following the format above. Apply the checklist:

- [ ] Type is one of the ten valid types
- [ ] Subject is lowercase, imperative, no period, ≤ 50 chars
- [ ] Scope names the module, not the project
- [ ] Body explains *why* (if included)
- [ ] Issue referenced in footer (if applicable)
- [ ] `BREAKING CHANGE:` noted (if applicable)
- [ ] No "and" chaining in the subject
- [ ] No attribution lines in the footer

### 4 — Commit

Pass the commit message via a heredoc to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
type(scope): subject

Optional body here.

Optional footer here.
EOF
)"
```

### 5 — Push (if requested)

If the user asked to push, run `git push`. If the branch has no upstream yet, run `git push -u origin <branch-name>`.

---

## Multi-commit feature development

Use a consistent scope across related commits:

```
feat(auth): initialize authentication module
feat(auth): add login endpoint
feat(auth): add token validation middleware
test(auth): add authentication test suite
docs(auth): document authentication flow
```
