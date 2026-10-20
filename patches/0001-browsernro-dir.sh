#!/bin/bash
# Applies the BrowserNro directory/log rename to a local chromium-nx clone.
# Usage: 0001-browsernro-dir.sh <path to chromium-nx checkout>
# See patches/README.md.
set -eu
ENGINE="${1:?usage: 0001-browsernro-dir.sh <chromium-nx checkout path>}"
FILE="$ENGINE/gx/host_nx.c"

[ -f "$FILE" ] || { echo "not found: $FILE" >&2; exit 1; }

grep -q 'sdmc:/switch/chromium-nx' "$FILE" || {
	echo "GX_DIR marker not found in $FILE — engine source may have changed upstream; review patches/README.md" >&2
	exit 1
}

sed -i 's#sdmc:/switch/chromium-nx#sdmc:/switch/BrowserNro#' "$FILE"
sed -i 's#/chromium-nx\.log#/BrowserNro.log#' "$FILE"

grep -n 'GX_DIR "sdmc:/switch/BrowserNro"\|BrowserNro\.log' "$FILE"
echo "patched: $FILE"
