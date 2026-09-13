#!/usr/bin/env bash
# Offline tests: skill lint, scripts, examples, and every documented d2 gotcha against the installed d2.
# Portable: bash 3.2 (macOS), GNU/BSD/busybox tools. d2 part is skipped when d2 is missing
# unless REQUIRE_D2=1 (CI). D2=/path/to/d2 overrides the binary.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/d2-diagram-test.XXXXXX")"
trap 'rm -rf "${WORK}"' EXIT
ANON="${ROOT}/scripts/anonymity-check.sh"
CLS="${ROOT}/scripts/class-check.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf '  ok   %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$*"; }
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then pass "${name}"; else fail "${name}"; fi; }
expect_rc() { local want="$1" rc=0; shift; "$@" >/dev/null 2>&1 || rc=$?; [ "${rc}" -eq "${want}" ]; }
section() { printf '\n## %s\n' "$*"; }

utf8_locale() {
  local l
  for l in C.UTF-8 en_US.UTF-8 UTF-8; do
    if [ "$(printf 'й' | LC_ALL="${l}" wc -m 2>/dev/null | tr -d ' ')" = "1" ]; then printf '%s' "${l}"; return 0; fi
  done
  return 1
}

# ---------------------------------------------------------------- skill lint
section "SKILL.md and docs"
SKILL="${ROOT}/SKILL.md"
check "frontmatter starts at line 1" test "$(head -n 1 "${SKILL}")" = "---"
name="$(sed -n 's/^name: *//p' "${SKILL}" | head -n 1)"
desc="$(sed -n 's/^description: *//p' "${SKILL}" | head -n 1)"
check "name is d2-diagram" test "${name}" = "d2-diagram"
check "description not empty" test -n "${desc}"
if loc="$(utf8_locale)"; then
  len="$(printf '%s' "${desc}" | LC_ALL="${loc}" wc -m | tr -d ' ')"
  check "description <= 1024 chars (${len})" test "${len}" -le 1024
fi
check "SKILL.md is English (Cyrillic only inside \"quoted\" examples)" sh -c '! sed "s/\"[^\"]*\"//g" "$1" | LC_ALL=C grep -q "$(printf "\320")"' _ "${SKILL}"

for doc in "${ROOT}/SKILL.md" "${ROOT}"/references/*.md "${ROOT}/README.md" "${ROOT}/README.ru.md" "${ROOT}/CLAUDE.md"; do
  dir="$(dirname "${doc}")"
  { grep -oE '\]\([^)#:]+\)' "${doc}" || true; } | sed -e 's/^](//' -e 's/)$//' | sort -u > "${WORK}/links"
  while read -r link; do
    check "$(basename "${doc}"): link ${link}" test -e "${dir}/${link}"
  done < "${WORK}/links"
done

check "no personal or company context in published files" sh -c '! grep -rniE "kb-save|knowledge-base|projects-config|chocolife|bilim|~/src/|вольт" "$1/SKILL.md" "$1/references" "$1/examples" "$1/scripts" "$1/README.md" "$1/README.ru.md" "$1/CLAUDE.md"' _ "${ROOT}"
check "LICENSE is MIT-0" grep -q "^MIT No Attribution$" "${ROOT}/LICENSE"

section "palette"
normalize() { sed -e 's/[[:space:]]\{1,\}#[^"]*$//' -e 's/[[:space:]]*$//' | grep -v '^[[:space:]]*#' | grep -v '^$'; }
awk '/^```d2$/{f=1;next} /^```$/{f=0} f' "${ROOT}/references/style.md" | normalize > "${WORK}/palette.md"
awk '/^classes: \{/,/^\}/' "${ROOT}/examples/palette.d2" | normalize > "${WORK}/palette.d2"
check "style.md palette == examples/palette.d2 classes" cmp -s "${WORK}/palette.md" "${WORK}/palette.d2"
grep -oE '"#[0-9a-fA-F]{6}"' "${WORK}/palette.md" > "${WORK}/colors" || true
for cls in zone partner outside mgmt app service store lb fw net external legacy planned start end step decision io document state initial final; do
  grep -E "^  ${cls}:" "${WORK}/palette.md" | sed "s/^  ${cls}://" >> "${WORK}/node_styles"
done
check "node classes have unique styles" test "$(sort "${WORK}/node_styles" | uniq -d | wc -l | tr -d ' ')" = "0"
for cls in metrics logs alerts control vpn backup public warn; do
  grep -E "^  ${cls}:" "${WORK}/palette.md" | sed "s/^  ${cls}://" >> "${WORK}/edge_styles"
done
check "edge classes have unique styles" test "$(sort "${WORK}/edge_styles" | uniq -d | wc -l | tr -d ' ')" = "0"

# ---------------------------------------------------------------- anonymity-check.sh
section "anonymity-check.sh: detections"
an() { printf '%s\n' "$1" > "${WORK}/a.d2"; (cd "${WORK}" && "${BASH}" "${ANON}" a.d2 2>/dev/null) || true; }
expect_found() { local kind="$1" match="$2" text="$3"; check "finds ${kind}: ${match}" sh -c 'printf "%s\n" "$1" | grep -qF ": $2: $3"' _ "$(an "${text}")" "${kind}" "${match}"; }
expect_clean() { check "ignores: $1" test -z "$(an "$1")"; }

expect_found ipv4 "10.20.0.1/24" 'core: "Core 10.20.0.1/24"'
expect_found ipv4 "192.168.1.10" 'x: "a,192.168.1.10."'
expect_found ipv4 "10.0.0.1" 'bad mask keeps the address: "10.0.0.1/99"'
expect_found ipv6 "fe80::1" 'gw: "fe80::1"'
expect_found ipv6 "2001:0db8:0000:0000:0000:ff00:0042:8329" 'x: "2001:0db8:0000:0000:0000:ff00:0042:8329"'
expect_found ipv6 "2001:db8::/32" 'x: "2001:db8::/32"'
expect_found mac "aa:bb:cc:dd:ee:ff" 'mac: aa:bb:cc:dd:ee:ff'
expect_found mac "AA-BB-CC-DD-EE-FF" 'mac: AA-BB-CC-DD-EE-FF'
expect_found mac "aabb.ccdd.eeff" 'mac: aabb.ccdd.eeff'
expect_found email "admin@example.kz" 'owner: "admin@example.kz"'
expect_found hostname "api.example.com" 'url: "https://api.example.com/v1"'
expect_found hostname "db01.corp.internal" 'x: db01.corp.internal'
expect_found hostname "nginx.default.svc" 'x: "nginx.default.svc:80"'
expect_found hostname "report.ru" 'x: report.ru'
expect_found hostname "host.kz" 'trailing dot: host.kz.'

section "anonymity-check.sh: no false positives"
expect_clean 'image: "v1.2.3.4"'
expect_clean 'x: "version 1.2.3.4.5"'
expect_clean 'date: "2026/09 and 2026-09-13, time 12:30:45"'
expect_clean 'classes: {fw: {style.fill: "#fde8e8"}}'
expect_clean 'edge.lb -> infra.db: "flow" {style.opacity: 0}'
expect_clean 'infra.mimir -> s3: "S3 API"'
expect_clean 'files: values.yaml run.sh style.md main.tf app.py backup.ru.d2 x.so'
expect_clean 'octets: "999.1.1.1"'
expect_clean 'd2 key: "a: b" and "1::2::3"'
expect_clean 'port: "8443"'

section "anonymity-check.sh: adjacent tokens (grep -o boundary)"
out="$(an 'x: 10.0.0.1 10.0.0.2,10.0.0.3 aa:bb:cc:dd:ee:ff 11:22:33:44:55:66 a.example.com b.example.com')"
check "3 adjacent IPv4" test "$(printf '%s\n' "${out}" | grep -c ': ipv4: ')" = "3"
check "2 adjacent MAC" test "$(printf '%s\n' "${out}" | grep -c ': mac: ')" = "2"
check "2 adjacent hosts" test "$(printf '%s\n' "${out}" | grep -c ': hostname: ')" = "2"

section "anonymity-check.sh: options and exit codes"
printf 'x: "FortiGate 600E at 192.0.2.1 and 203.0.113.5"\n# render note 10.9.9.9\n' > "${WORK}/o.d2"
printf 'FortiGate\n# comment\n\n' > "${WORK}/deny"
printf '^203\\.0\\.113\\.\n' > "${WORK}/allow"
check "findings -> exit 1" expect_rc 1 "${BASH}" "${ANON}" "${WORK}/o.d2"
check "clean -> exit 0" expect_rc 0 "${BASH}" "${ANON}" "${ROOT}/examples/network.d2"
check "no args -> exit 2" expect_rc 2 "${BASH}" "${ANON}"
check "missing file -> exit 2" expect_rc 2 "${BASH}" "${ANON}" "${WORK}/nope.d2"
check "unknown option -> exit 2" expect_rc 2 "${BASH}" "${ANON}" --bogus "${WORK}/o.d2"
"${BASH}" "${ANON}" --deny "${WORK}/deny" --allow "${WORK}/allow" "${WORK}/o.d2" > "${WORK}/o.out" 2>/dev/null || true
check "--deny reports vendor" grep -q ": deny: FortiGate" "${WORK}/o.out"
check "--allow suppresses agreed address" sh -c '! grep -q "203.0.113.5" "$1"' _ "${WORK}/o.out"
check "not allowed address still reported" grep -q "192.0.2.1" "${WORK}/o.out"
check "comments scanned by default" grep -q "10.9.9.9" "${WORK}/o.out"
"${BASH}" "${ANON}" --skip-comments "${WORK}/o.d2" > "${WORK}/o2.out" 2>/dev/null || true
check "--skip-comments ignores comment lines" sh -c '! grep -q "10.9.9.9" "$1"' _ "${WORK}/o2.out"
check "--skip-comments keeps line numbers" grep -q "^${WORK}/o.d2:1: ipv4: 192.0.2.1" "${WORK}/o2.out"
cp "${WORK}/deny" "${WORK}/.d2-anonymity-deny"
check "default ./.d2-anonymity-deny is used" sh -c 'cd "$1" && "$2" "$3" o.d2 2>/dev/null | grep -q ": deny: FortiGate"' _ "${WORK}" "${BASH}" "${ANON}"
rm -f "${WORK}/.d2-anonymity-deny"

# ---------------------------------------------------------------- class-check.sh
section "class-check.sh"
cat > "${WORK}/c.d2" <<'D2'
classes: {
  cluster: {style: {fill: "#eef4fb"; stroke: "#4a78a8"}}
  tool: {style.fill: "#fdeeda"}
  # ghost: {style.fill: "#000"}
}
a: "text with class: nope inside quotes" {class: cluster}
b: B {style.fill: "#eee"; class: tool}
c: C {class: [cluster; tool]}
d: D {class: toool}
e -> f: flow {class: metrics}
g: G {
  class: cluster
  h: H {class: ghost}
}
D2
"${BASH}" "${CLS}" "${WORK}/c.d2" > "${WORK}/c.out" 2>/dev/null || true
check "unknown class (typo) reported" grep -q ":9: unknown class 'toool'" "${WORK}/c.out"
check "unknown edge class reported" grep -q ":10: unknown class 'metrics'" "${WORK}/c.out"
check "class defined only in a comment is unknown" grep -q ":13: unknown class 'ghost'" "${WORK}/c.out"
check "class: inside a quoted label ignored" sh -c '! grep -q "nope" "$1"' _ "${WORK}/c.out"
check "exactly 3 findings" test "$(wc -l < "${WORK}/c.out" | tr -d ' ')" = "3"
check "findings -> exit 1" expect_rc 1 "${BASH}" "${CLS}" "${WORK}/c.d2"
printf 'a: A {class: z}\nclasses: {z: {style.fill: "#fff"}; y: {style.fill: "#000"}}\nb: B {class: y; x: X}\n' > "${WORK}/c2.d2"
check "classes defined after use, one-line block -> exit 0" expect_rc 0 "${BASH}" "${CLS}" "${WORK}/c2.d2"
printf '...@palette.d2\na: A {class: tool}\n' > "${WORK}/c3.d2"
check "imports -> skipped, exit 0" expect_rc 0 "${BASH}" "${CLS}" "${WORK}/c3.d2"
check "no args -> exit 2" expect_rc 2 "${BASH}" "${CLS}"

# ---------------------------------------------------------------- examples
section "examples"
for f in "${ROOT}"/examples/*.d2; do
  b="$(basename "${f}" .d2)"
  check "${b}: classes defined" "${BASH}" "${CLS}" "${f}"
  check "${b}: committed SVG exists" test -s "${ROOT}/examples/${b}.svg"
  case "${b}" in
    *-internal) check "${b}: anonymity-check finds data (internal on purpose)" expect_rc 1 "${BASH}" "${ANON}" "${f}" ;;
    *) check "${b}: anonymity-check clean" "${BASH}" "${ANON}" "${f}" ;;
  esac
  # no -i: case-insensitive matching of Cyrillic fails in the C locale (busybox, CI)
  check "${b}: header has render command" grep -qE '^# *(Render|render|Рендер|рендер):' "${f}"
done
check "a Russian example exists" sh -c 'LC_ALL=C grep -l "$(printf "\320")" "$1"/examples/*.d2 | grep -q .' _ "${ROOT}"

# ---------------------------------------------------------------- d2
D2_BIN="${D2:-d2}"
if command -v "${D2_BIN}" >/dev/null 2>&1; then
  section "d2 $("${D2_BIN}" --version 2>/dev/null | head -n 1): render"
  render() { "${D2_BIN}" --layout elk "$1" "$2" >/dev/null 2>&1; }
  for f in "${ROOT}"/examples/*.d2; do
    check "render $(basename "${f}")" render "${f}" "${WORK}/$(basename "${f}" .d2).svg"
  done
  n=0
  for doc in "${ROOT}"/references/*.md; do
    awk -v out="${WORK}/block_$(basename "${doc}" .md)_" '/^```d2$/{f=1;n++;next} /^```$/{f=0} f{print > (out n ".d2")}' "${doc}"
  done
  for b in "${WORK}"/block_*.d2; do
    [ -f "${b}" ] || continue
    n=$((n + 1))
    check "render doc block $(basename "${b}")" render "${b}" "${b%.d2}.svg"
  done
  check "at least 3 doc blocks rendered" test "${n}" -ge 3

  section "d2: documented gotchas still behave as documented"
  printf 'a: port #8443 open\n' > "${WORK}/hash.d2"
  render "${WORK}/hash.d2" "${WORK}/hash.svg" || true
  check "unquoted # truncates label" sh -c 'grep -q ">port<" "$1" && ! grep -q "8443" "$1"' _ "${WORK}/hash.svg"
  printf 'a: "port #8443 open"\n' > "${WORK}/hashq.d2"
  render "${WORK}/hashq.d2" "${WORK}/hashq.svg" || true
  check "quoted # keeps label" grep -q "8443" "${WORK}/hashq.svg"
  printf 'a -> b: flow {class: nope}\n' > "${WORK}/nocls.d2"
  check "unknown class renders with exit 0" render "${WORK}/nocls.d2" "${WORK}/nocls.svg"
  printf 'style: X\n' > "${WORK}/kw.d2"
  check "d2 validate passes a file that fails to render" sh -c '"$1" validate "$2" >/dev/null 2>&1' _ "${D2_BIN}" "${WORK}/kw.d2"
  check "reserved keyword as id fails to render" expect_rc 1 render "${WORK}/kw.d2" "${WORK}/kw.svg"
  printf 'a: A\nb: B {near: a}\n' > "${WORK}/near.d2"
  check "near: object fails with ELK" expect_rc 1 render "${WORK}/near.d2" "${WORK}/near.svg"
  printf 'a: A\nl: "Legend" {shape: text; near: bottom-center}\n' > "${WORK}/nearc.d2"
  check "near: constant works with ELK" render "${WORK}/nearc.d2" "${WORK}/nearc.svg"
  body='a1; a2; a3; a4; a5; a1 -> a2; a3 -> a4'
  printf 'direction: down\np: "prod" {%s}\ns: "dev" {%s}\n' "${body}" "${body}" > "${WORK}/row.d2"
  printf 'direction: down\np: "prod" {%s}\ns: "dev" {%s}\np -> s: {style.opacity: 0}\n' "${body}" "${body}" > "${WORK}/stack.d2"
  render "${WORK}/row.d2" "${WORK}/row.svg" || true
  render "${WORK}/stack.d2" "${WORK}/stack.svg" || true
  vb() { grep -oE 'viewBox="0 0 [0-9]+ [0-9]+"' "$1" | head -n 1 | sed 's/viewBox="0 0 //; s/"//'; }
  row="$(vb "${WORK}/row.svg")"; stack="$(vb "${WORK}/stack.svg")"
  check "without invisible edge containers are side by side (${row})" test "${row% *}" -gt "${row#* }"
  check "invisible edge stacks containers vertically (${stack})" test "${stack#* }" -gt "${stack% *}"
  printf 'Order: {\n  shape: class\n  +id: UUID\n  #recalculate(): void\n}\n' > "${WORK}/cls_hash.d2"
  printf 'Order: {\n  shape: class\n  +id: UUID\n  "#recalculate()": void\n}\n' > "${WORK}/cls_hashq.d2"
  render "${WORK}/cls_hash.d2" "${WORK}/cls_hash.svg" || true
  render "${WORK}/cls_hashq.d2" "${WORK}/cls_hashq.svg" || true
  check "unquoted #member vanishes from a class shape" sh -c '! grep -q "recalculate" "$1"' _ "${WORK}/cls_hash.svg"
  check "quoted \"#member\" is kept" grep -q "recalculate" "${WORK}/cls_hashq.svg"
  printf 'classes: {store: {style: {fill: "#e0f2f1"; stroke: "#00796b"}}}\nt: {shape: sql_table; class: store; id: int}\n' > "${WORK}/tbl.d2"
  render "${WORK}/tbl.d2" "${WORK}/tbl.svg" || true
  check "palette class on sql_table paints rows with the stroke color" grep -q 'fill="#00796b"' "${WORK}/tbl.svg"
  printf 'g: {grid-columns: 2; a: A; b: "" {shape: circle; width: 18; height: 18}}\n' > "${WORK}/grid.d2"
  printf 'g: {grid-columns: 2; a: A; b: "" {style: {fill: transparent; stroke: transparent}; c: "" {shape: circle; width: 18; height: 18}}}\n' > "${WORK}/gridwrap.d2"
  render "${WORK}/grid.d2" "${WORK}/grid.svg" || true
  render "${WORK}/gridwrap.d2" "${WORK}/gridwrap.svg" || true
  # d2 0.7 writes "9.000000", 0.9 writes "9": normalize
  ellipse() { grep -oE '<ellipse rx="[0-9.]+" ry="[0-9.]+"' "$1" | head -n 1 | sed 's/<ellipse rx="//; s/" ry="/ /; s/"$//' | awk '{ printf "%g %g", $1, $2 }'; }
  g1="$(ellipse "${WORK}/grid.svg")"; g2="$(ellipse "${WORK}/gridwrap.svg")"
  check "grid cell stretches a fixed-size circle (rx ry: ${g1})" test "${g1}" != "9 9"
  check "transparent container cell keeps the size (rx ry: ${g2})" test "${g2}" = "9 9"
  printf 'flow: {\n  shape: sequence_diagram\n  a: A\n  b: B\n  a -> b: hello\n  b."a note"\n}\n' > "${WORK}/seqnote.d2"
  check "sequence note without shape renders" render "${WORK}/seqnote.d2" "${WORK}/seqnote.svg"
  check "sequence note text present" grep -q "a note" "${WORK}/seqnote.svg"
  printf 'a: Text: details\nb: first\\nsecond\nclasses: {c: {style.fill: "#eee"}}\nz: Z {class: c; x: X}\n' > "${WORK}/notgotchas.d2"
  check "not gotchas: unquoted colon, unquoted \\n, inline class" render "${WORK}/notgotchas.d2" "${WORK}/notgotchas.svg"
elif [ "${REQUIRE_D2:-0}" = "1" ]; then
  section "d2"
  fail "d2 not found (REQUIRE_D2=1)"
else
  printf '\n## skip d2 checks (d2 not installed; set REQUIRE_D2=1 to fail instead)\n'
fi

printf '\n%s passed, %s failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
[ "${FAIL}" -eq 0 ]
