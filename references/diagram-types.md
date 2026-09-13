# Diagram types

Pick the type from what the reader needs to understand, then use the matching D2 construct.
Every snippet below is rendered by `tests/test.sh` with the pinned d2 (ELK layout).

| The reader needs to see… | Type | D2 construct | Palette |
|---|---|---|---|
| what runs where and how it is connected | architecture / infrastructure | containers + edges | zones, nodes, flow edges ([style.md](style.md)) |
| steps, decisions and outcomes of a process | flowchart | `direction: down`, shapes via classes | `start` `end` `step` `decision` `io` `document` |
| who calls whom, in which order | sequence diagram | `shape: sequence_diagram` | none — default look |
| tables, columns and keys | ER / database schema | `shape: sql_table` | none — default look |
| classes, fields, methods, relations | UML class diagram | `shape: class` | none — default look |
| states of an entity and transitions | state machine | nodes + labeled edges | `state` `initial` `final` |
| reporting lines, ownership, a tree | hierarchy / org chart | `direction: down`, plain edges | `app` / `service` or default |

Not a D2 job: data charts (bars, lines, pies), Gantt charts with real dates, pixel-exact UI mockups —
say so and suggest a better tool instead of forcing a diagram.

Diagrams of **real systems, people or data** (infrastructure, a real database schema, a real org chart)
follow SKILL.md §3 — facts from sources, audience, anonymization — whatever their type.

## Flowchart / business process

```d2
direction: down
classes: {
  start: {shape: oval; style: {fill: "#d3f9d8"; stroke: "#2b8a3e"}}
  end: {shape: oval; style: {fill: "#e9ecef"; stroke: "#495057"}}
  step: {style: {fill: "#e7f5ff"; stroke: "#1c7ed6"}}
  decision: {shape: diamond; style: {fill: "#fff3bf"; stroke: "#f59f00"}}
  io: {shape: parallelogram; style: {fill: "#f3f0ff"; stroke: "#6741d9"}}
}
request: "Access request submitted" {class: io}
approved: "Approved by the owner?" {class: decision}
grant: "Grant access" {class: step}
reject: "Reject with a reason" {class: step}
done: "Notify the requester" {class: end}
begin: "Start" {class: start}
begin -> request -> approved
approved -> grant: "yes"
approved -> reject: "no"
grant -> done
reject -> done
```

- One verb phrase per step, a question per decision; label every edge leaving a decision (`yes` / `no`).
- Roles (swimlanes): one container per role with the steps inside; edges cross containers.
- Long processes: split into sub-processes (one node each) and draw them separately.

## Sequence diagram

```d2
login: "Sign-in with SSO" {
  shape: sequence_diagram
  user: "User"
  app: "Web application"
  idp: "Identity provider"

  user -> app: "open /dashboard"
  app -> app: "no session"
  app."redirect to SSO"
  app -> user: "302 to identity provider"
  user -> idp: "credentials + MFA"

  ok: "credentials valid" {
    idp -> user: "302 back with code"
    user -> app: "code"
    app.t -> idp: "exchange code for tokens"
    idp -> app.t: "ID token"
  }
  fail: "credentials invalid" {
    idp -> user: "error page"
  }
}
```

- Participants appear left to right and messages top to bottom **in declaration order** — declare participants first.
- Self-message: `app -> app: "…"`. Note: `app."text"` — do not add `{shape: text}` to a note, it renders as a clipped box.
- Alternatives and loops: a named group inside the diagram (`ok: "credentials valid" {…}`).
- Activation (span): use the same sub-key on both ends, `app.t -> idp` … `idp -> app.t`.
- Keep the default look: palette classes are for boxes-and-arrows diagrams.

## ER / database schema

```d2
direction: right
users: {
  shape: sql_table
  id: uuid {constraint: primary_key}
  email: varchar {constraint: unique}
  created_at: timestamptz
}
orders: {
  shape: sql_table
  id: uuid {constraint: primary_key}
  user_id: uuid {constraint: foreign_key}
  total: numeric
  status: text
}
order_items: {
  shape: sql_table
  order_id: uuid {constraint: [primary_key; foreign_key]}
  line_no: int {constraint: primary_key}
  sku: text
}
orders.user_id -> users.id
order_items.order_id -> orders.id
```

- Constraints `primary_key`, `foreign_key`, `unique` render as PK / FK / UNQ; several at once: `[primary_key; foreign_key]`.
- Foreign keys are edges between columns: `orders.user_id -> users.id`.
- **No palette classes on `sql_table`** — they paint the rows with the stroke color and hide the text.
- A real production schema is internal data: SKILL.md §3.

## UML class diagram

```d2
direction: down
Customer: {
  shape: class
  +id: UUID
  +email: string
  +placeOrder(items): Order
}
Order: {
  shape: class
  +id: UUID
  -status: Status
  +total(): Money
  "#recalculate()": void
}
Customer -> Order: "places 1..*"
```

- Visibility prefixes `+` public, `-` private, `#` protected; methods end with `(…)`, the part after `:` is the type.
- **Quote protected members**: `"#recalculate()": void` — unquoted, `#` starts a comment and the row silently disappears.
- Relation kind and multiplicity go into the edge label.
- **No palette classes on `class` shapes** (same reason as `sql_table`).

## State machine

```d2
direction: right
classes: {
  state: {style: {fill: "#e7f5ff"; stroke: "#1c7ed6"; border-radius: 12}}
  initial: {shape: circle; width: 18; height: 18; style: {fill: "#212529"; stroke: "#212529"}}
  final: {shape: circle; width: 18; height: 18; style: {fill: "#ffffff"; stroke: "#212529"; stroke-width: 3; double-border: true}}
}
init: "" {class: initial}
open: "Open" {class: state}
progress: "In progress" {class: state}
review: "In review" {class: state}
closed: "Closed" {class: state}
fin: "" {class: final}
init -> open
open -> progress: "start"
progress -> review: "submit"
review -> progress: "changes requested"
review -> closed: "approve"
open -> closed: "cancel"
closed -> fin
```

- Edges are events (`approve`), nodes are states (`In review`); guards in brackets: `"approve [tests green]"`.
- Pseudo-states need an empty label and must stay outside `grid-columns` containers, which stretch them (see [patterns.md](patterns.md)).

## Hierarchy / org chart

```d2
direction: down
classes: {
  service: {style: {fill: "#fdeeda"; stroke: "#b8863b"}}
  app: {style: {fill: "#dcebd8"; stroke: "#5b8c51"}}
}
head: "Head of engineering" {class: service}
platform: "Platform team\n4 engineers" {class: app}
data: "Data team\n3 engineers" {class: app}
sre: "SRE\non-call rotation" {class: app}
head -> platform
head -> data
platform -> sre
```

- Roles and teams rather than personal names in anything shared outside the team (SKILL.md §3).
- Wide trees: group leaves into one multi-line node or split by branch.
