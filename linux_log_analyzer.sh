#!/usr/bin/env bash
set -euo pipefail
usage() { echo "Usage: $0 <log-file> [--level LEVEL] [--top N]"; }
[[ $# -ge 1 ]] || { usage >&2; exit 2; }
log_file="$1"; shift
level=""; top=5
while [[ $# -gt 0 ]]; do
  case "$1" in
    --level) [[ $# -ge 2 ]] || { echo "Missing value for --level" >&2; exit 2; }; level="${2^^}"; shift 2 ;;
    --top) [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || { echo "--top must be a positive integer" >&2; exit 2; }; top="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done
[[ -f "$log_file" ]] || { echo "Error: log file not found: $log_file" >&2; exit 1; }
[[ -r "$log_file" ]] || { echo "Error: log file is not readable: $log_file" >&2; exit 1; }
if [[ -n "$level" ]]; then
  case "$level" in CRITICAL|ERROR|WARNING|INFO|DEBUG) ;; *) echo "Error: invalid level '$level'." >&2; exit 2 ;; esac
  filtered="$(mktemp)"; trap 'rm -f "$filtered"' EXIT
  grep -i "$level" "$log_file" > "$filtered" || true
  target="$filtered"
else target="$log_file"; fi
echo "Linux Log Analyzer"
echo "=================="
echo "Log file: $log_file"
echo "Lines analyzed: $(wc -l < "$target" | tr -d ' ')"
echo
echo "Severity counts:"
for severity in CRITICAL ERROR WARNING INFO DEBUG; do
  count="$(grep -ic "$severity" "$target" || true)"
  printf '  %-8s %s\n' "$severity:" "$count"
done
echo
echo "Top error messages (up to $top):"
grep -iE 'CRITICAL|ERROR' "$target" \
 | sed -E 's/^[^ ]+[[:space:]]+[^ ]+[[:space:]]+[A-Z]+:[[:space:]]*//' \
 | sort | uniq -c | sort -nr | head -n "$top" \
 | awk '{count=$1; $1=""; sub(/^ /,""); printf "  %d. %s (%d)\n", NR, $0, count}'
