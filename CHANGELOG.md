# Changelog

## 1.0.0 — 2026-09-13

First public release.

- Scope: any diagram described in words — architecture and infrastructure, flowcharts, sequence, ER, UML class,
  state machines, hierarchies; rules for real systems (facts, audience, anonymization) apply to any type depicting them.
- English `SKILL.md` with an output-language rule (setting in `CLAUDE.md` → language of the request → English).
- `references/`: diagram types with verified snippets; palette with 30 distinguishable classes (zones, nodes, process and
  state shapes, flows); layout patterns and D2 gotchas verified on d2 0.7.1 and 0.9.0; neutral EN/RU wording.
- `scripts/anonymity-check.sh`: IPv4/CIDR, IPv6, MAC, e-mail, hostname detection with deny/allow lists.
- `scripts/class-check.sh`: used-but-undefined classes.
- Examples: network (external and internal), deployment, monitoring, backup (Russian), access-request flowchart,
  SSO sign-in sequence, orders ER schema, ticket lifecycle state machine, palette.
- Tests for docs, palette, scripts, examples and every documented gotcha; CI on Ubuntu and macOS (bash 3.2), shellcheck, gitleaks.
- Corrected earlier internal notes: ELK fails on `near: <object>` (it does not ignore it); quoting `:` and `\n` is not required;
  inline `class` in a container body works; `d2 validate` checks syntax only.
- License: MIT-0.
