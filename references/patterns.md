# Patterns and gotchas

Every gotcha below is reproduced by `tests/test.sh` against the pinned d2 version, so this page
fails CI when d2 behavior changes. Verified with d2 v0.7.1 and v0.9.0, layout engine ELK.
Per-type advice (flowcharts, sequence, ER, UML, state machines): [diagram-types.md](diagram-types.md).

## 1. Zones, flows, legend

```d2
direction: down
classes: {
  zone: {style: {fill: "#eef4fb"; stroke: "#4a78a8"}}
  service: {style: {fill: "#fdeeda"; stroke: "#b8863b"}}
  store: {style: {fill: "#e0f2f1"; stroke: "#00796b"}}
  metrics: {style: {stroke: "#3b5bdb"; font-color: "#3b5bdb"}}
  logs: {style: {stroke: "#e8590c"; font-color: "#c2410c"}}
}
infra: "Platform cluster" {
  class: zone
  prom: "Prometheus" {class: service}
  mimir: "Mimir (long-term metrics)" {class: service}
  prom -> mimir: remote_write {class: metrics}
}
s3: "Object storage (S3-compatible)" {class: store}
infra.mimir -> s3: "S3 API" {class: logs}
legend: "Legend: blue — metrics · orange — logs" {shape: text; near: bottom-center}
```

## 2. Stack perimeters vertically (ELK puts sibling containers in a row)

A diagram that comes out 10000×2000 is unreadable in a document. Chain the containers with an
invisible edge — ELK then stacks them:

```d2
direction: down
prod: "Production" {style: {stroke-dash: 5; fill: transparent}; a1; a2; a1 -> a2}
dev: "Development" {style: {stroke-dash: 5; fill: transparent}; b1; b2; b1 -> b2}
prod -> dev: {style.opacity: 0}
```

Measured on the test fixture: 875×504 without the edge, 529×876 with it.

For catalog-like content (all services of a perimeter, no edges into them) use a grid instead:
`container: {grid-columns: 4; ...}` — works with ELK, see [examples/palette.d2](../examples/palette.d2).
Do not connect edges to grid cells from outside: they are drawn as straight diagonal lines across
the whole diagram instead of routed ones.

## 3. External and internal versions

- `network.d2` — for people outside the team: neutral names ("Firewall cluster (HA)", "Network core"),
  segment names instead of VLAN ids, no addresses except explicitly agreed public ones.
  Must pass `scripts/anonymity-check.sh`.
- `network-internal.d2` — same topology with vendors, addresses, VLAN ids. First line:
  `# Internal: do not share outside the team`.
- Neutral wording in English and Russian: [terms.md](terms.md).

## 4. Gotchas

| Symptom | Cause | Do this |
|---|---|---|
| Label silently cut: `port #8443 open` renders as `port` | `#` starts a comment even inside an unquoted label | quote labels that contain `#`: `a: "port #8443 open"` |
| A `#protected` member or a column vanishes from a `class` / `sql_table` | same `#` comment rule | quote the key: `"#recalculate()": void` |
| Table or class rows filled with a dark color, text unreadable | a palette class applied to `sql_table` / `class` paints rows with its `stroke` | no palette classes on these shapes |
| A small circle becomes a tall or wide ellipse | a `grid-columns` cell stretches its shape to the row height and column width, ignoring `width`/`height` | keep fixed-size nodes outside grids, or wrap the shape in a transparent container cell |
| Class style not applied, no error, exit code 0 | a class name that is not defined (typo) is silently ignored | run `scripts/class-check.sh file.d2` |
| `d2 validate` says "valid", render fails | `validate` checks syntax only; layout-specific and keyword errors appear at compile time | validate by rendering: `d2 --layout elk file.d2 file.svg` |
| `layout engine "elk" only supports constant values for "near"` | `near: other_object` is unsupported in ELK | position with containers and invisible edges; constants (`near: bottom-center`) are fine |
| `"style" expected to be set to a map of key-values` | a reserved keyword (`style`, …) used as an object id | rename the object (`style_guide`) |
| Ten boxes for ten VMs, spaghetti edges | one node per list item | one node with a multi-line label: `vms: "web-1\nweb-2\nweb-3"` |

Not gotchas (checked, both work): an unquoted `:` inside a label (`a: Text: details`), an unquoted `\n`,
`class` next to children in a one-line container body (`z: Z {class: c; x: X}`).

## 5. Final checklist

- [ ] rendered `.svg` and `.png` with `--layout elk`, looked at the PNG
- [ ] aspect ratio no wider than ~3:1
- [ ] `scripts/class-check.sh` — no unknown classes
- [ ] external diagram: `scripts/anonymity-check.sh` clean (with a deny file for project-specific names)
- [ ] header comment: purpose, classification if any, render command
- [ ] legend present when more than two flow types are used
