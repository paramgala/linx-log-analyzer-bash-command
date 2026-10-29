#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
out="$(bash ./linux_log_analyzer.sh sample.log)"
grep -q 'Lines analyzed: 11' <<< "$out"
grep -q 'Connection timed out (3)' <<< "$out"
filtered="$(bash ./linux_log_analyzer.sh sample.log --level ERROR)"
grep -q 'Lines analyzed: 4' <<< "$filtered"
top="$(bash ./linux_log_analyzer.sh sample.log --top 1)"
grep -q 'Connection timed out (3)' <<< "$top"
if bash ./linux_log_analyzer.sh missing-file.log >/dev/null 2>&1; then exit 1; fi
echo "PASS: basic analysis"
echo "PASS: severity filter"
echo "PASS: top-N option"
echo "PASS: missing-file handling"
echo "All tests passed."
