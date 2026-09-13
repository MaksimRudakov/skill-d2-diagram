#!/usr/bin/env bash
# Reports classes that are used but not defined: d2 silently ignores an unknown class (exit 0, no style).
# Portable: bash 3.2 (macOS), POSIX awk (GNU, BSD, mawk, busybox). No interval expressions.
set -euo pipefail

PROG="class-check.sh"

usage() {
  cat >&2 <<USAGE
Usage: scripts/class-check.sh FILE.d2...

Checks that every "class: name" / "class: [a; b]" refers to a class defined in a "classes: { ... }" block
of the same file. Comments and quoted strings are ignored.
Files with imports (@file / ...@file) are skipped with a warning: their classes may come from the import.

Output (stdout): FILE:LINE: unknown class 'NAME'      Exit: 0 ok, 1 unknown classes, 2 usage error.
USAGE
}

[ $# -ge 1 ] || { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

status=0
for f in "$@"; do
  [ -r "${f}" ] || { printf '%s: cannot read %s\n' "${PROG}" "${f}" >&2; exit 2; }

  out="$(awk -v file="${f}" '
    {
      # 1) code = the line with quoted strings blanked and the comment removed
      code = ""; inq = 0; line = $0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (inq) { if (c == "\\") { i++; code = code " "; continue } if (c == "\"") inq = 0; code = code " "; continue }
        if (c == "\"") { inq = 1; code = code " "; continue }
        if (c == "#") break
        code = code c
      }
      if (code ~ /@/) imports = 1

      # 2) class definitions: keys at the first level inside "classes: {"
      tmp = code
      while (length(tmp) > 0) {
        if (match(tmp, /^[A-Za-z0-9_-]+[ \t]*:/)) {
          key = substr(tmp, 1, RLENGTH); sub(/[ \t]*:$/, "", key)
          if (cdepth > 0 && depth == cdepth) defined[key] = 1
          if (key == "classes") pending = 1
          tmp = substr(tmp, RLENGTH + 1); continue
        }
        c = substr(tmp, 1, 1); tmp = substr(tmp, 2)
        if (c == "{") { depth++; if (pending) { cdepth = depth; pending = 0 } }
        else if (c == "}") { if (depth == cdepth) cdepth = 0; depth-- }
        else if (c !~ /[ \t]/ && c != ";") pending = 0
      }

      # 3) class usages
      tmp = code
      while (match(tmp, /(^|[^A-Za-z0-9_-])class[ \t]*:[ \t]*(\[[^]]*\]|[A-Za-z0-9_-]+)/)) {
        val = substr(tmp, RSTART, RLENGTH); tmp = substr(tmp, RSTART + RLENGTH)
        sub(/^[^:]*:[ \t]*/, "", val); gsub(/[][]/, "", val)
        n = split(val, names, /[ \t]*;[ \t]*/)
        for (k = 1; k <= n; k++) if (names[k] != "") used[++u] = NR SUBSEP names[k]
      }
    }
    END {
      if (imports) { print "WARN"; exit }
      for (j = 1; j <= u; j++) {
        split(used[j], parts, SUBSEP)
        if (!(parts[2] in defined)) printf "%s:%s: unknown class '\''%s'\''\n", file, parts[1], parts[2]
      }
    }
  ' "${f}")"

  if [ "${out}" = "WARN" ]; then
    printf '%s: %s uses imports, skipped\n' "${PROG}" "${f}" >&2
  elif [ -n "${out}" ]; then
    printf '%s\n' "${out}"
    status=1
  fi
done
exit "${status}"
