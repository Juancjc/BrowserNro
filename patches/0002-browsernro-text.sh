#!/bin/bash
# Replaces the engine's remaining user-visible "Chromium NX" strings with
# "BrowserNro" (the console title text and the on-screen 39-bit address
# space warning). Purely cosmetic — does not change behavior. See
# patches/README.md and 0001-browsernro-dir.sh for the directory/log patch.
# Usage: 0002-browsernro-text.sh <path to chromium-nx checkout>
set -eu
ENGINE="${1:?usage: 0002-browsernro-text.sh <chromium-nx checkout path>}"
FILE="$ENGINE/gx/host_nx.c"

[ -f "$FILE" ] || { echo "not found: $FILE" >&2; exit 1; }

grep -q 'printf("Chromium NX' "$FILE" || {
	echo "'Chromium NX' marker not found in $FILE — engine source may have changed upstream; review patches/README.md" >&2
	exit 1
}

sed -i 's/printf("Chromium NX\\n\\n");/printf("BrowserNro\\n\\n");/' "$FILE"
sed -i 's/printf("Chromium NX\\n\\n"$/printf("BrowserNro\\n\\n"/' "$FILE"
sed -i 's/"Install Chromium NX as a forwarder with Sphaira, choosing a\\n"/"Install BrowserNro as a forwarder with Sphaira, choosing a\\n"/' "$FILE"

! grep -q '"Chromium NX' "$FILE" || { echo "some 'Chromium NX' strings were not replaced" >&2; exit 1; }
grep -n 'BrowserNro' "$FILE" | grep -E 'printf|Install'
echo "patched: $FILE"
