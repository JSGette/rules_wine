#!/usr/bin/env bash
set -euo pipefail

if ! grep -q hello-from-wine "$1"; then
    echo "unexpected content in $1: $(cat "$1")" >&2
    exit 1
fi
