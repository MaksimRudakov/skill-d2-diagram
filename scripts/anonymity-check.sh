#!/usr/bin/env bash
# Finds data that must not leak into externally shared diagrams.
# Portable: bash 3.2 (macOS), POSIX grep -E / awk / sed (GNU, BSD, busybox). No network.
set -euo pipefail

PROG="anonymity-check.sh"
ALLOW_FILE=""
DENY_FILE=""
SKIP_COMMENTS=0
TAB="$(printf '\t')"

# Real and internal TLDs. Two-letter ccTLDs that collide with file extensions or typical
# diagram ids (sh, md, py, pl, so, tf, rs, lb, fw, sw, db, ui, go) are deliberately left out.
# One line on purpose: BSD awk (macOS) rejects newlines in -v values ("newline in string").
TLDS="com net org io dev app cloud ai co me info biz gov edu mil int tech online site xyz"
TLDS="${TLDS} kz ru uz kg tj tm by ua am az ge de uk us eu fr nl be ch at it es pt se fi no dk pl cz sk hu ro bg gr tr il ae sa qa"
TLDS="${TLDS} cn jp kr in sg hk tw au nz ca mx br ar cl"
TLDS="${TLDS} local internal lan corp home intranet private localdomain localhost svc"

usage() {
  cat >&2 <<USAGE
Usage: scripts/anonymity-check.sh [--allow FILE] [--deny FILE] [--skip-comments] FILE...

Reports data that should not appear in diagrams shared outside the team:
  ipv4      IPv4 addresses and CIDR (octets validated; 1.2.3.4.5 is not an IP)
  ipv6      IPv6 addresses (full or "::"-compressed, at least one hex digit)
  mac       MAC addresses (aa:bb:cc:dd:ee:ff, aa-bb-..., aabb.ccdd.eeff)
  email     e-mail addresses
  hostname  FQDNs ending in a real or internal TLD (.com, .kz, .local, .internal, .svc, ...)
  deny      matches of your own EREs from --deny FILE (vendor names, cluster/kubeconfig names, domains)

--allow FILE     one ERE per line; findings whose matched text matches any of them are ignored
--deny FILE      one ERE per line; every match is reported as "deny"
--skip-comments  ignore D2 comment lines (starting with #); default is to scan everything
Defaults: ./.d2-anonymity-allow and ./.d2-anonymity-deny are used when present.
Blank lines and lines starting with # in allow/deny files are ignored.

Scan .d2 sources: rendered SVG embeds fonts and XML namespaces and is generated from the source.

Output (stdout): FILE:LINE: KIND: MATCH      Exit: 0 clean, 1 findings, 2 usage error.
USAGE
}

die() { printf '%s: %s\n' "${PROG}" "$1" >&2; exit 2; }

# Prints "LINE<TAB>TOKEN" for every ERE match; an optional leading boundary char is kept and stripped by
# the caller (grep -o has no lookbehind). Never add a trailing boundary group: grep -o consumes it and the
# next adjacent token loses its leading boundary, i.e. every second match on a line is missed.
matches() { grep -noE -- "$2" "$1" 2>/dev/null | sed "s/:/${TAB}/" || true; }

strip_boundary() { sed -e "s/${TAB}[^0-9A-Za-z:]*/${TAB}/" -e 's/[^0-9A-Za-z]*$//'; }

# shellcheck disable=SC2129  # one detector per block reads better than a single grouped redirect
scan_file() {
  local file="$1" src="$1"
  if [ "${SKIP_COMMENTS}" -eq 1 ]; then
    src="${WORK}/nocomments"
    # keep line numbers: blank out comment lines instead of deleting them
    sed -e 's/^[[:space:]]*#.*$//' "${file}" > "${src}"
  fi

  # ipv4 / cidr
  matches "${src}" '(^|[^0-9A-Za-z_.-])[0-9]{1,3}(\.[0-9]{1,3}){3,}(/[0-9]{1,3})?' | strip_boundary \
    | awk -F "${TAB}" -v OFS="${TAB}" '{
        tok = $2; mask = ""
        if (index(tok, "/")) { mask = substr(tok, index(tok, "/") + 1); tok = substr(tok, 1, index(tok, "/") - 1) }
        n = split(tok, o, ".")
        if (n != 4) next
        for (i = 1; i <= 4; i++) if (o[i] + 0 > 255) next
        if (mask != "" && mask + 0 > 32) { print $1, "ipv4", tok; next }  # bad mask, the address still leaks
        print $1, "ipv4", $2
      }' >> "${WORK}/found"

  # ipv6: "::" form or 8 groups, groups of up to 4 hex digits, at least one hex digit
  matches "${src}" '(^|[^0-9A-Za-z_:.-])[0-9A-Fa-f]{0,4}(:[0-9A-Fa-f]{0,4}){2,7}(/[0-9]{1,3})?' | strip_boundary \
    | awk -F "${TAB}" -v OFS="${TAB}" '{
        tok = $2; sub(/\/[0-9]+$/, "", tok)
        if (tok !~ /[0-9A-Fa-f]/) next
        dbl = gsub(/::/, "::", tok)
        n = split(tok, g, ":")
        if (dbl > 1) next
        if (dbl == 0 && n != 8) next
        for (i = 1; i <= n; i++) if (length(g[i]) > 4) next
        print $1, "ipv6", $2
      }' >> "${WORK}/found"

  # mac
  matches "${src}" '(^|[^0-9A-Za-z:-])[0-9A-Fa-f]{2}([:-][0-9A-Fa-f]{2}){5}' | strip_boundary \
    | awk -F "${TAB}" -v OFS="${TAB}" '{ print $1, "mac", $2 }' >> "${WORK}/found"
  matches "${src}" '(^|[^0-9A-Za-z.])[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}' | strip_boundary \
    | awk -F "${TAB}" -v OFS="${TAB}" '{ print $1, "mac", $2 }' >> "${WORK}/found"

  # email
  matches "${src}" '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}' \
    | awk -F "${TAB}" -v OFS="${TAB}" '{ print $1, "email", $2 }' >> "${WORK}/found"

  # hostname: labels + TLD from the list; hosts that are part of an e-mail are already reported
  # the whole dotted token is taken, so "backup.ru.d2" ends in "d2" and is not a host
  matches "${src}" '(^|[^0-9A-Za-z_@.-])([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z0-9]{2,24}' | strip_boundary \
    | awk -F "${TAB}" -v OFS="${TAB}" -v tlds="${TLDS}" 'BEGIN { n = split(tlds, t, /[[:space:]]+/); for (i = 1; i <= n; i++) ok[t[i]] = 1 }
      {
        host = $2; sub(/\.$/, "", host)
        k = split(host, p, "."); tld = tolower(p[k])
        if (k >= 2 && tld ~ /^[a-z]+$/ && (tld in ok)) print $1, "hostname", host
      }' >> "${WORK}/found"

  # deny patterns
  if [ -n "${DENY_FILE}" ]; then
    local re
    while IFS= read -r re || [ -n "${re}" ]; do
      case "${re}" in ''|'#'*) continue ;; esac
      matches "${src}" "${re}" | awk -F "${TAB}" -v OFS="${TAB}" '{ print $1, "deny", $2 }' >> "${WORK}/found"
    done < "${DENY_FILE}"
  fi

  # allow patterns, dedupe, print
  local line kind match allowed
  sort -t "${TAB}" -k1,1n -k2,2 -k3,3 -u "${WORK}/found" | while IFS="${TAB}" read -r line kind match; do
    [ -n "${match}" ] || continue
    allowed=0
    if [ -n "${ALLOW_FILE}" ]; then
      while IFS= read -r re || [ -n "${re}" ]; do
        case "${re}" in ''|'#'*) continue ;; esac
        if printf '%s\n' "${match}" | grep -Eq -- "${re}"; then allowed=1; break; fi
      done < "${ALLOW_FILE}"
    fi
    [ "${allowed}" -eq 1 ] || printf '%s:%s: %s: %s\n' "${file}" "${line}" "${kind}" "${match}"
  done
  : > "${WORK}/found"
}

main() {
  local f
  while [ $# -gt 0 ]; do
    case "$1" in
      --allow) [ $# -ge 2 ] || die "--allow needs a file"; ALLOW_FILE="$2"; shift ;;
      --deny) [ $# -ge 2 ] || die "--deny needs a file"; DENY_FILE="$2"; shift ;;
      --skip-comments) SKIP_COMMENTS=1 ;;
      -h|--help) usage; exit 0 ;;
      --) shift; break ;;
      -*) usage; die "unknown option: $1" ;;
      *) break ;;
    esac
    shift
  done
  [ $# -ge 1 ] || { usage; exit 2; }

  [ -n "${ALLOW_FILE}" ] || { [ ! -f .d2-anonymity-allow ] || ALLOW_FILE=".d2-anonymity-allow"; }
  [ -n "${DENY_FILE}" ] || { [ ! -f .d2-anonymity-deny ] || DENY_FILE=".d2-anonymity-deny"; }
  for f in "${ALLOW_FILE}" "${DENY_FILE}"; do
    [ -z "${f}" ] || [ -r "${f}" ] || die "cannot read ${f}"
  done

  WORK="$(mktemp -d "${TMPDIR:-/tmp}/d2-anonymity.XXXXXX")"
  trap 'rm -rf "${WORK}"' EXIT
  : > "${WORK}/found"

  for f in "$@"; do
    [ -r "${f}" ] || die "cannot read ${f}"
    scan_file "${f}" >> "${WORK}/report"
  done

  if [ -s "${WORK}/report" ]; then
    cat "${WORK}/report"
    printf '%s: %s finding(s)\n' "${PROG}" "$(wc -l < "${WORK}/report" | tr -d ' ')" >&2
    exit 1
  fi
  printf '%s: clean\n' "${PROG}" >&2
}

main "$@"
