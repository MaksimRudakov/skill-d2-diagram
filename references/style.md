# Palette

One palette for every diagram, so all diagrams look alike. Copy the whole `classes` block into a new
diagram and delete the classes you do not use (unknown classes are silently ignored by d2 — run
`scripts/class-check.sh` after editing).

Principles: zones are muted backgrounds, content is light fills with a darker stroke of the same hue,
anything outside the perimeter or not yet real is dashed, each flow type has its own color, process and
state classes also carry their conventional shape (oval start/end, diamond decision, parallelogram I/O).
Every class differs from the others by color and/or dash, so a legend can always tell them apart.
Tuned for the default light theme.

```d2
classes: {
  # zones / perimeters (containers)
  zone: {style: {fill: "#eef4fb"; stroke: "#4a78a8"}}          # cluster, data center, VPC
  partner: {style: {fill: "#f3ecf9"; stroke: "#7a4a9e"}}       # partner / third-party perimeter
  outside: {style: {fill: "#f7f7f2"; stroke: "#8a8a70"}}       # internet, everything outside
  mgmt: {style: {fill: "#eeeeee"; stroke: "#666666"}}          # management network / tooling

  # nodes
  app: {style: {fill: "#dcebd8"; stroke: "#5b8c51"}}           # applications, workloads, data sources
  service: {style: {fill: "#fdeeda"; stroke: "#b8863b"}}       # platform services and tools
  store: {style: {fill: "#e0f2f1"; stroke: "#00796b"}}         # databases, object and backup storage
  lb: {style: {fill: "#fff8e1"; stroke: "#d4a017"}}            # load balancers, ingress, API gateways
  fw: {style: {fill: "#fde8e8"; stroke: "#c0392b"}}            # firewalls, WAF
  net: {style: {fill: "#eceff1"; stroke: "#546e7a"}}           # routers, switches, network core
  external: {style: {fill: "#f5f5f5"; stroke: "#9e9e9e"; stroke-dash: 3}}              # external systems
  legacy: {style: {fill: "#fafafa"; stroke: "#bdbdbd"; stroke-dash: 3; font-color: "#757575"}}  # to be decommissioned
  planned: {style: {fill: "#fffde7"; stroke: "#fbc02d"; stroke-dash: 5}}                # planned, not built yet

  # processes and state machines (the class sets the shape too)
  start: {shape: oval; style: {fill: "#d3f9d8"; stroke: "#2b8a3e"}}                     # process start
  end: {shape: oval; style: {fill: "#e9ecef"; stroke: "#495057"}}                       # process end
  step: {style: {fill: "#e7f5ff"; stroke: "#1c7ed6"}}                                   # action / task
  decision: {shape: diamond; style: {fill: "#fff3bf"; stroke: "#f59f00"}}               # question with yes/no edges
  io: {shape: parallelogram; style: {fill: "#f3f0ff"; stroke: "#6741d9"}}               # input / output, form, request
  document: {shape: page; style: {fill: "#ffffff"; stroke: "#868e96"}}                  # document, report, ticket
  state: {style: {fill: "#e7f5ff"; stroke: "#1c7ed6"; border-radius: 12}}               # state in a state machine
  initial: {shape: circle; width: 18; height: 18; style: {fill: "#212529"; stroke: "#212529"}}                       # initial pseudo-state
  final: {shape: circle; width: 18; height: 18; style: {fill: "#ffffff"; stroke: "#212529"; stroke-width: 3; double-border: true}}   # final state

  # edges by flow type
  metrics: {style: {stroke: "#3b5bdb"; font-color: "#3b5bdb"}}                   # blue
  logs: {style: {stroke: "#e8590c"; font-color: "#c2410c"}}                      # orange
  alerts: {style: {stroke: "#c92a2a"; font-color: "#c92a2a"}}                    # red
  control: {style: {stroke: "#0b7285"; font-color: "#0b7285"}}                   # teal: control plane, sync, BGP/OSPF
  vpn: {style: {stroke: "#7048e8"; font-color: "#7048e8"; stroke-dash: 3}}       # violet, dashed
  backup: {style: {stroke: "#2b8a3e"; font-color: "#2b8a3e"}}                    # green
  public: {style: {stroke: "#ae3ec9"; font-color: "#ae3ec9"; stroke-width: 3}}   # magenta, thick: public traffic
  warn: {style: {stroke: "#c92a2a"; font-color: "#c92a2a"; stroke-dash: 3}}      # red dashed: note → object
}
```

Other conventions:

- **do not apply these classes to `sql_table` and `class` shapes** — d2 paints their rows with the class
  `stroke` color and the text becomes unreadable; leave those shapes with their default look;
- sequence diagrams keep the default look as well (see [diagram-types.md](diagram-types.md));
- initial/final pseudo-states need an empty label: `init: "" {class: initial}`; a `grid-columns` cell
  stretches them to the row and column size, so keep them outside grids;
- people — `{shape: person}`; notes and legends — `{shape: text}`;
- a warning is a `{shape: text}` note plus a `warn` edge to the object it refers to;
- a legend is required when a diagram uses more than two flow types.

See [examples/palette.d2](../examples/palette.d2) for every class rendered side by side.
