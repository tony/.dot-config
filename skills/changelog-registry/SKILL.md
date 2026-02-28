---
name: mise-bump changelog registry
description: Use when constructing changelog and release URLs for tools managed in .tool-versions. Maps each tool to its GitHub repository, tag format, and changelog locations.
---

# Changelog Registry

URL templates for all tools in `.tool-versions`. Use these when constructing commit body links.

## Tool Registry

### just

- **GitHub**: `casey/just`
- **Tag format**: `{version}` (e.g., `1.46.0`)
- **Release URL**: `https://github.com/casey/just/releases/tag/{version}`
- **Changelog URL**: `https://github.com/casey/just/blob/{version}/CHANGELOG.md`

### poetry

- **GitHub**: `python-poetry/poetry`
- **Tag format**: `{version}` (e.g., `2.2.1`)
- **Release URL**: `https://github.com/python-poetry/poetry/releases/tag/{version}`
- **Changelog URL**: `https://github.com/python-poetry/poetry/blob/{version}/CHANGELOG.md`
- **Note**: For major version bumps, may use `main` instead of tag: `https://github.com/python-poetry/poetry/blob/main/CHANGELOG.md`

### uv

- **GitHub**: `astral-sh/uv`
- **Tag format**: `{version}` (e.g., `0.10.2`)
- **Release URL**: `https://github.com/astral-sh/uv/releases/tag/{version}`
- **Changelog URL**: `https://github.com/astral-sh/uv/blob/{version}/CHANGELOG.md`
- **Subject prefix**: Always include `uv` before versions: `uv 0.9.26 -> 0.10.2`

### python

- **GitHub**: `python/cpython`
- **Tag format**: `v{version}` (e.g., `v3.14.2`)
- **Changelog URL**: `https://docs.python.org/release/{version}/whatsnew/changelog.html#python-{version_dashed}`
  - `{version_dashed}` replaces dots with dashes: `3.14.2` → `3-14-2`
- **Version guide**: `https://devguide.python.org/versions/`
- **PEP links**: Each major.minor has a PEP (e.g., PEP 745 for 3.14): `https://peps.python.org/pep-0745/`
- **Multi-version**: python has multiple pinned versions (e.g., `3.14.2 3.13.11 3.12.12 3.11.14 3.10.19`). Patch-bump each series individually using `mise latest python@3.14`, `mise latest python@3.13`, etc.

### nodejs

- **GitHub**: `nodejs/node`
- **Tag format**: `v{version}` (e.g., `v25.2.1`)
- **Blog release URL**: `https://nodejs.org/en/blog/release/v{version}`
- **Note**: Use the blog release URL as primary link (not GitHub releases)
- **Multi-version**: nodejs has multiple pinned versions. Patch-bump each series using `mise latest node@25`, `mise latest node@24`, etc.

### golang

- **GitHub**: `golang/go`
- **Tag format**: `go{version}` (e.g., `go1.25.6`)
- **Primary links** (prefer these over GitHub):
  - `https://go.dev/blog/go{major.minor}` (e.g., `https://go.dev/blog/go1.25`)
  - `https://tip.golang.org/doc/go{major.minor}` (e.g., `https://tip.golang.org/doc/go1.25`)
- **Mise tool name**: `go` (aliased from `golang`)

### java

- **GitHub**: `openjdk/jdk`
- **Tag format**: `jdk-{version}` (e.g., `jdk-22.0.1`)
- **Release notes**: `https://openjdk.org/projects/jdk/{major}/` (e.g., `https://openjdk.org/projects/jdk/22/`)
- **Version prefix**: mise uses `openjdk-` prefix (e.g., `openjdk-22.0.1` in .tool-versions)
- **Strip prefix**: Remove `openjdk-` when constructing URLs

### elixir

- **GitHub**: `elixir-lang/elixir`
- **Tag format**: `v{version_no_otp}` (e.g., `v1.14.2` — strip `-otp-XX` suffix)
- **Release URL**: `https://github.com/elixir-lang/elixir/releases/tag/v{version_no_otp}`
- **Changelog URL**: `https://github.com/elixir-lang/elixir/blob/v{version_no_otp}/CHANGELOG.md`
- **Version suffix**: mise uses `-otp-XX` suffix (e.g., `1.14.2-otp-25`). Strip `-otp-25` for URLs.

### erlang

- **GitHub**: `erlang/otp`
- **Tag format**: `OTP-{version}` (e.g., `OTP-25.1.2`)
- **Release URL**: `https://github.com/erlang/otp/releases/tag/OTP-{version}`
- **Patches page**: `https://www.erlang.org/patches/otp-{major}` (e.g., `https://www.erlang.org/patches/otp-25`)

## Version Transform Rules

When constructing URLs from `.tool-versions` entries:

| Tool | .tool-versions value | Transform | URL version |
|------|---------------------|-----------|-------------|
| just | `1.46.0` | none | `1.46.0` |
| poetry | `2.2.1` | none | `2.2.1` |
| uv | `0.10.2` | none | `0.10.2` |
| python | `3.14.2` | add `v` for tags, dash for anchors | `v3.14.2`, `3-14-2` |
| nodejs | `25.2.1` | add `v` for tags | `v25.2.1` |
| golang | `1.25.6` | add `go` for tags | `go1.25.6` |
| java | `openjdk-22.0.1` | strip `openjdk-`, add `jdk-` for tags | `jdk-22.0.1` |
| elixir | `1.14.2-otp-25` | strip `-otp-XX`, add `v` for tags | `v1.14.2` |
| erlang | `25.1.2` | add `OTP-` for tags | `OTP-25.1.2` |

## Discovering New Tools

If a new tool appears in `.tool-versions` that isn't in this registry:

1. Check `mise plugins ls-remote` for the tool's GitHub backend
2. Look at the tool's GitHub repo for releases and CHANGELOG
3. Identify the tag format from existing releases
4. Use `WebSearch` to find the tool's official changelog/blog URL
5. Add the tool to this registry for future use
