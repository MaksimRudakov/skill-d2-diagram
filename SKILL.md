---
name: d2-diagram
description: Draw and update diagrams in D2 — architecture and infrastructure (network, deployment, Kubernetes, monitoring, backup), flowcharts and business processes, sequence diagrams, ER / database schemas, UML class diagrams, state machines, org charts and other box-and-arrow diagrams — with a consistent palette, ELK layout, visual self-review of the rendered PNG and checks for silent D2 errors; diagrams of real systems also get facts from verifiable sources and an anonymization check before they are shared outside the team. Use whenever the user asks to draw, redraw, fix or update a diagram or scheme described in words, in any language (e.g. "draw the login sequence", "нарисуй схему процесса согласования"). Not for data charts or plots.
---

# D2 diagrams

A workflow for diagrams that are correct, readable and safe to share.
Scripts live in `scripts/` next to this file: `S=<skill base directory>/scripts`.

## 0. Tooling

- Renderer: `d2` **v0.7.1 or newer** (tested with v0.9.0), layout engine ELK (bundled with d2).
  Check with `d2 --version`. If missing, tell the user and point to the install section of the
  skill's README; do not install software without being asked.
- Render from the directory of the file, relative paths only inside `.d2`:
  ```bash
  d2 --layout elk X.d2 X.svg && d2 --layout elk X.d2 X.png
  ```
  SVG is the deliverable; PNG is for your own visual review.
- `scripts/*.sh` need bash (macOS, Linux, WSL or Git Bash on Windows).

## 1. Diagram type

Choose the type from what the reader needs to understand — architecture, flowchart, sequence,
ER schema, UML classes, state machine, hierarchy — using the table and snippets in
[references/diagram-types.md](references/diagram-types.md). If the request is really a data chart
(bars, lines, pies) or a dated Gantt chart, say that D2 is the wrong tool instead of forcing it.
Unclear what the reader needs → ask one short question.

## 2. Output language

Instructions here are in English; the diagram is not necessarily. Decide the language of labels,
legend and your replies in this order:

1. An explicit setting in the project or user `CLAUDE.md` (or equivalent memory), e.g.
   `d2-diagram: language: ru` — always wins.
2. Otherwise the language the user writes in ("нарисуй схему сети" → Russian labels).
3. Otherwise English.

Translate everything else, including container titles and edge labels: keep only product names, protocols,
paths and identifiers as they are (`Prometheus`, `BGP`, `S3 API`, `/var/log`) — "Kubernetes cluster" becomes
"Kubernetes-кластер", "container logs" becomes "логи контейнеров". Do not mix languages in one diagram.
Neutral wording for both languages: [references/terms.md](references/terms.md).

## 3. Diagrams of real systems, people or data

Applies to any type that depicts something real: infrastructure and architecture, a production database
schema, a real process with named teams, an org chart. Skip it for illustrative or generic diagrams.

- **Facts first.** Draw only from sources you can check: `kubectl` against the right cluster,
  infrastructure-as-code and config repositories, schema migrations, inventories, current documentation —
  never from memory. When facts contradict the request, say so. Anything unverified is left out or
  marked explicitly (`planned` or a note).
- **Project conventions** (project `CLAUDE.md`, memory, an existing diagrams folder) override this skill:
  naming, what must never be drawn, anonymization rules.
- **Audience → level of detail.**
  - internal — addresses, CIDRs, VLAN ids, vendors, host names, personal names are fine;
  - external (auditors, partners, contractors, public docs) — none of the above: roles instead of products
    and people ("Firewall cluster (HA)", "Platform team"), segment names instead of VLAN ids.

  Both needed → `X.d2` (external) and `X-internal.d2` with the first line
  `# Internal: do not share outside the team`. Credentials, tokens and admin kubeconfig/context names
  never appear on any diagram.

## 4. Writing the .d2

- Header comment: purpose, classification if any, render command.
- `direction: down` for flows and hierarchies, `right` for comparisons and state machines.
- Copy the needed classes from the palette in [references/style.md](references/style.md) — do not invent
  colors; delete unused classes. Sequence diagrams, `sql_table` and `class` shapes keep their default look.
- Architecture: perimeters are containers; flow types are edge classes with a `{shape: text}` legend.
- Fewer edges, more text: lists (VMs, services, fields) are one node with a multi-line label, not ten nodes.
- Quote any label or key containing `#` — unquoted, everything after `#` silently disappears.
- Layout tricks and verified gotchas: [references/patterns.md](references/patterns.md).

## 5. Check and review (mandatory)

1. Render SVG and PNG with `--layout elk`. Do not rely on `d2 validate`: it checks syntax only and
   passes files that fail to render.
2. `$S/class-check.sh X.d2` — must be clean (d2 silently ignores unknown classes).
3. **Look at the PNG** with your image-capable file reading tool: every element and label from your source
   is actually there (silently dropped rows and labels happen), readability, crossing edges, overlaps,
   aspect ratio (wider than ~3:1 is unusable in a document).
4. Too flat or too wide → group related blocks into containers, chain them with an invisible edge
   `a -> b: {style.opacity: 0}`, or use `grid-columns` for catalog-like content without edges into it
   (patterns §2). Re-render, look again.
5. External diagrams of real systems (§3): `$S/anonymity-check.sh X.d2` must print `clean`.
   Project-specific names (vendors, internal domains, cluster names) go into `.d2-anonymity-deny` next to
   the diagram, one ERE per line; agreed exceptions into `.d2-anonymity-allow`. The script complements your
   review, it does not replace it.
6. Result in one folder: `X.d2`, `X.svg`, `X.png` (plus `X-internal.*` if made).

## 6. Iterations

- Apply feedback to the `.d2` and re-render both formats right away, then repeat §5.
- New conventions agreed with the user (naming, what to hide, language) — offer to record them in the
  project `CLAUDE.md` or memory so the next diagram follows them without reminders. Do not write them silently.
