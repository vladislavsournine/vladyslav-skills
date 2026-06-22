#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$HERE"/test-*.sh; do
    echo "=== $t ==="
    bash "$t" || rc=1
done
exit $rc
