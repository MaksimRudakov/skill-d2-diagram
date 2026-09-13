# CLAUDE.md — contributing to d2-diagram

> This file is for **changing the skill**. If you are using the skill to draw a diagram,
> ignore it and follow [SKILL.md](SKILL.md).

## Layout

| Path | Loaded by the agent | Notes |
|---|---|---|
| `SKILL.md` | every time the skill triggers | keep it short; details go to `references/` |
| `references/*.md` | on demand, via links from `SKILL.md` | diagram types, palette, patterns, terms |
| `scripts/*.sh` | executed by the agent | no network, read-only |
| `examples/` | by people (README gallery) and tests | fictional, anonymized |
| `tests/test.sh` | CI and contributors | |

## Rules

- **English** in all skill files. Russian lives only in `README.ru.md`, the Russian column of
  `references/terms.md` and the Russian example. The output language rule is in `SKILL.md` §1.
- **Nothing personal or company-specific**: no internal tool names, repositories, domains, people or paths.
  Tests grep for known ones; do not rely on that alone.
- **Scope**: any box-and-arrow diagram. Rules for real systems (facts, audience, anonymization) stay in
  `SKILL.md` §3 and must not leak into generic types as mandatory steps.
- **Every snippet in `references/*.md` renders** (tested) and passes `class-check.sh`; a new diagram type needs a
  snippet in `diagram-types.md`, an example in `examples/` and a look at its PNG.
- **Only verified claims about D2.** Every gotcha in `references/patterns.md` must have a test in the
  "documented gotchas" section of `tests/test.sh` that reproduces it against the pinned d2. A claim
  that cannot be reproduced is removed, not softened.
- **Palette**: `references/style.md` and `examples/palette.d2` must stay identical (tested); every class
  must differ from the others by color and/or dash (tested).
- **Examples** are fictional. External examples must pass `anonymity-check.sh`; `*-internal.d2` must fail it
  and may use only documentation address ranges (RFC 5737, RFC 3849) and the `.internal` / `example.*` names.
  After editing an example, re-render its SVG with the pinned d2 and look at the PNG before committing.
- **Scripts**: bash 3.2 compatible (the macOS CI job runs `/bin/bash` 3.2 with BSD tools), POSIX awk without
  interval expressions (`{n,m}` breaks old mawk) and without newlines in `-v` values (BSD awk on macOS fails with
  "newline in string"), `grep -E` for regexes. In `grep -o` patterns never add a
  trailing boundary group: it consumes the separator and the next adjacent match is lost. Exit codes are an
  interface: `0` ok, `1` findings, `2` usage.
- **Versions** are pinned in `.github/workflows/ci.yml` (`D2_VERSION`, `GITLEAKS_VERSION`) and mentioned in
  `SKILL.md` and both READMEs — bump them together and record the change in `CHANGELOG.md`.

## Before a pull request

```bash
REQUIRE_D2=1 bash tests/test.sh
shellcheck scripts/*.sh tests/*.sh
```

For changes in `SKILL.md`, also try the skill in a fresh Claude Code session on one English and one
Russian request and check that the agent renders, views the PNG and runs both scripts.
