---
name: mise-bump commit conventions
description: Use when creating commits that update tool versions in .tool-versions. Provides the exact subject and body format used by this repository, with real examples from git history.
---

# .tool-versions Commit Conventions

## Rule: One Tool Per Commit

Every `.tool-versions` bump is a **single commit per tool**. Never mix tools in one commit (the one exception being simultaneous uv+python bumps when uv drives the python version).

## Subject Format

The subject always starts with `.tool-versions(<tool>)` followed by a version description.

### Single-version tools (just, poetry, uv, golang, erlang)

| Tool | Format | Example |
|------|--------|---------|
| go | `.tool-versions(go) OLD -> NEW` | `.tool-versions(go) 1.25.5 -> 1.25.6` |
| just | `.tool-versions(just) OLD -> NEW` | `.tool-versions(just) 1.45.0 -> 1.46.0` |
| poetry | `.tool-versions(poetry) OLD -> NEW` | `.tool-versions(poetry) 2.1.4 -> 2.2.1` |
| uv | `.tool-versions(uv) uv OLD -> NEW` | `.tool-versions(uv) uv 0.9.26 -> 0.10.2` |
| erlang | `.tool-versions(erlang) OLD -> NEW` | `.tool-versions(erlang) 25.0.4 -> 25.1.2` |

Note: **uv** includes the tool name prefix in the version (`uv 0.9.26`), while **go**, **just**, **poetry**, and **erlang** use bare version numbers.

### Multi-version tools (python, nodejs)

When updating multiple pinned versions of the same tool:

```
.tool-versions(python) python 3.14.0, 3.13.8 and others
```

When updating a single version entry of a multi-version tool:

```
.tool-versions(nodejs) 25.2.0 -> 25.2.1
```

### Special subjects

| Action | Example |
|--------|---------|
| Add new version | `.tool-versions(nodejs) Add nodejs 25.2.0` |
| Remove version | `.tool-versions(python) Remove 3.9.x` |

## Body Format

The body contains changelog/release links, grouped by tool.

### Single-tool body with "See also:" prefix

```
See also:
- https://github.com/casey/just/blob/1.46.0/CHANGELOG.md
- https://github.com/casey/just/releases/tag/1.46.0
```

### Single-tool body with inline "See also:"

```
See also: https://nodejs.org/en/blog/release/v24.11.0
```

### Tool-grouped body (for multi-tool commits or uv)

```
See also:
- uv:
  - https://github.com/astral-sh/uv/releases/tag/0.9.18
  - https://github.com/astral-sh/uv/blob/0.9.18/CHANGELOG.md
```

### Multi-tool body

```
See also:
- uv:
  - https://github.com/astral-sh/uv/releases/tag/0.9.15
  - https://github.com/astral-sh/uv/blob/0.9.15/CHANGELOG.md
- python:
  - https://docs.python.org/release/3.14.2/whatsnew/changelog.html#python-3-14-2
  - https://peps.python.org/pep-0745/
```

## Complete Examples From History

### Example 1: uv bump

```
.tool-versions(uv) uv 0.9.26 -> 0.10.2

- uv:
  - https://github.com/astral-sh/uv/releases/tag/0.10.2
  - https://github.com/astral-sh/uv/blob/0.10.2/CHANGELOG.md
```

### Example 2: go bump

```
.tool-versions(go) 1.25.5 -> 1.25.6

See also:
- https://go.dev/blog/go1.25
- https://tip.golang.org/doc/go1.25
```

### Example 3: just bump

```
.tool-versions(just) 1.45.0 -> 1.46.0

See also:
- https://github.com/casey/just/blob/1.46.0/CHANGELOG.md
- https://github.com/casey/just/releases/tag/1.46.0
```

### Example 4: poetry bump

```
.tool-versions(poetry) 2.1.4 -> 2.2.1

See also:
- https://github.com/python-poetry/poetry/blob/2.2.1/CHANGELOG.md
```

### Example 5: python multi-version bump

```
.tool-versions(python) python 3.14.0, 3.13.8 and others

See also:
- python:
  - https://docs.python.org/release/3.14.0/whatsnew/changelog.html#python-3-14-0
  - https://devguide.python.org/versions/
```

### Example 6: nodejs bump

```
.tool-versions(nodejs) 24.10.0 -> 22.11.0

See also: https://nodejs.org/en/blog/release/v24.11.0
```

### Example 7: poetry major bump

```
.tool-versions(poetry) 1.8.3 -> 2.1.4

See also:
- https://github.com/python-poetry/poetry/blob/main/CHANGELOG.md
```

Note: Major version bumps may link to `main` branch CHANGELOG since the tag might not have the full history.
