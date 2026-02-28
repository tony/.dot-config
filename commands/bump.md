---
description: Bump tool versions in .tool-versions with changelog-enriched commits
argument-hint: "[tool-name] or 'all' to check everything"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
  - WebSearch
  - WebFetch
  - AskUserQuestion
---

# Context

Current `.tool-versions`:

```
!cat .tool-versions
```

Outdated tools (mise):

```
!mise outdated --bump 2>/dev/null || echo "(mise outdated not available — check manually)"
```

Current branch:

```
!git branch --show-current
```

Recent `.tool-versions` commits (for style reference):

```
!git log --oneline -15 -- .tool-versions
```

# mise-bump: Version Upgrade Workflow

You are upgrading tool versions in `.tool-versions` with properly formatted, changelog-enriched git commits. Follow these 5 phases exactly.

**Before starting**: Load the `commit-conventions` and `changelog-registry` skills — they contain the exact commit format and URL templates you must use.

## Phase 1 — Identify Upgradable Tools

Classify each tool by its upgrade strategy:

### Single-version tools
**just, poetry, uv, golang, erlang** — one version pinned, use `mise upgrade <tool> --bump`.

### Multi-version pinned tools
**python, nodejs** — multiple versions pinned (e.g., `python 3.14.2 3.13.11 3.12.12 ...`).

For these, `mise upgrade --bump` would clobber all entries to the same version. Instead:
- For each pinned major.minor series, run `mise latest <tool>@<major.minor>` to find the latest patch
- Compare with the current pinned version
- Only bump within the same major.minor series (patch upgrades only)

Example for python:
```bash
mise latest python@3.14   # → 3.14.3 (current: 3.14.2 → upgradable)
mise latest python@3.13   # → 3.13.12 (current: 3.13.11 → upgradable)
mise latest python@3.12   # → 3.12.13 (current: 3.12.12 → upgradable)
```

### Prefixed tools
**java** (`openjdk-` prefix), **elixir** (`-otp-XX` suffix) — handle prefix/suffix when constructing URLs and comparing versions.

### Present results

Show a table of upgradable tools:

| Tool | Current | Latest | Type |
|------|---------|--------|------|
| uv | 0.10.2 | 0.10.7 | single |
| python 3.14.x | 3.14.2 | 3.14.3 | multi-version |
| ... | ... | ... | ... |

If the user passed a specific tool name as argument, filter to that tool only.

**STOP — Ask the user which tools to bump.** Use `AskUserQuestion` with the list of upgradable tools.

## Phase 2 — Gather Changelog Info

For each selected tool:

1. **Get old and new versions** from Phase 1
2. **Look up the changelog-registry skill** for URL templates
3. **Construct release and changelog URLs** using the registry's tag format and URL patterns
   - Always point to git tags, never `main` or `master` (exception: major version bumps where tag doesn't have full changelog)
4. **For tools not in the registry**, use `WebSearch` to find the official changelog

### URL construction examples

For uv 0.10.2 → 0.10.7:
- Release: `https://github.com/astral-sh/uv/releases/tag/0.10.7`
- Changelog: `https://github.com/astral-sh/uv/blob/0.10.7/CHANGELOG.md`

For python 3.14.2 → 3.14.3:
- Changelog: `https://docs.python.org/release/3.14.3/whatsnew/changelog.html#python-3-14-3`
- Versions: `https://devguide.python.org/versions/`

For go 1.25.6 → 1.25.7:
- Blog: `https://go.dev/blog/go1.25`
- Docs: `https://tip.golang.org/doc/go1.25`

## Phase 3 — Preview Commits and Confirm

For each tool, show:

1. **Version change**: `uv: 0.10.2 → 0.10.7`
2. **`.tool-versions` line change**: the exact before/after line
3. **Draft commit message**: full subject + body in a code block

Example preview:

```
Subject: .tool-versions(uv) uv 0.10.2 -> 0.10.7

Body:
See also:
- uv:
  - https://github.com/astral-sh/uv/releases/tag/0.10.7
  - https://github.com/astral-sh/uv/blob/0.10.7/CHANGELOG.md
```

**STOP — Ask the user to confirm.** Show all draft commits and wait for approval before making any changes.

## Phase 4 — Execute Upgrades

Process each confirmed tool **one at a time**, in this order:

### For single-version tools (just, poetry, uv, golang, erlang):

```bash
mise upgrade <tool> --bump
```

Then verify: read `.tool-versions` and confirm the version changed correctly.

### For multi-version tools (python, nodejs):

**Do NOT use `mise upgrade --bump`** — it clobbers all entries to a single version.

Instead, edit `.tool-versions` directly:
1. Read the current file
2. Use `Edit` to replace the old version string with the new one on the correct line
3. Verify the edit is correct by reading the file again

### For prefixed tools (java, elixir):

Use `mise upgrade <tool> --bump` if it handles the prefix correctly. Otherwise edit directly.

### After each tool's version is updated:

1. Stage ONLY `.tool-versions`:
   ```bash
   git add .tool-versions
   ```

2. Create the commit using a heredoc (NEVER `--amend`, NEVER `--no-verify`):
   ```bash
   git commit -m "$(cat <<'EOF'
   .tool-versions(toolname) OLD -> NEW

   See also:
   - https://example.com/changelog
   EOF
   )"
   ```

3. Verify:
   ```bash
   git log --oneline -1
   ```

### Safety rules

- **Never** `git add -A` or `git add .` — only stage `.tool-versions`
- **Never** `--amend` an existing commit
- **Never** `--no-verify` to skip hooks
- **Never** `git push` (user decides when to push)
- **Never** mix multiple tools in one commit
- **Always** verify `.tool-versions` content after each edit
- **Always** use heredoc for commit messages

## Phase 5 — Summary

Show a table of all commits created:

| Tool | Version Change | Commit |
|------|---------------|--------|
| uv | 0.10.2 → 0.10.7 | `abc1234` |
| python | 3.14.2 → 3.14.3, 3.13.11 → 3.13.12 | `def5678` |

Then show the full log:
```bash
git log --oneline -N -- .tool-versions
```

(where N = number of commits just created + 3 for context)

Remind the user they can `git push` when ready.
