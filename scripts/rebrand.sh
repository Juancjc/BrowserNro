#!/bin/bash
# Rebrands the compiled engine as BrowserNro: regenerates the .nacp (name,
# author, version) and swaps the icon, by re-running devkitA64's own
# nacptool/elf2nro on the already-built gx.elf — it does NOT touch or
# recompile a single line of the engine's source. See BUILD.md step 10 and
# LICENSING.md.
set -eu
set -o pipefail

HERE=$(cd "$(dirname "$0")/.." && pwd)
VERSION=$(cat "$HERE/VERSION" 2>/dev/null || echo "0.1.0")
APP_TITLE="BrowserNro"
APP_AUTHOR="BrowserNro"
ICON_HOST="$HERE/assets/icon/icon.jpg"

if ! docker ps --format '{{.Names}}' | grep -qx lkl-gx-nx; then
	echo "lkl-gx-nx container is not running — run scripts/build.sh through step 9 first" >&2
	exit 1
fi
if [ ! -f "$ICON_HOST" ]; then
	echo "missing $ICON_HOST — run: python assets/generate_identity.py" >&2
	exit 1
fi

echo "== copying BrowserNro icon into the build container"
docker cp "$ICON_HOST" lkl-gx-nx:/tmp/browsernro-icon.jpg

echo "== regenerating .nacp and .nro with BrowserNro identity"
docker exec lkl-gx-nx bash -c "
	set -eu
	export DEVKITPRO=/opt/devkitpro
	export PATH=\$DEVKITPRO/devkitA64/bin:\$DEVKITPRO/tools/bin:\$PATH
	OUT=/work/gx-nx
	[ -e \"\$OUT/gx.elf\" ] || { echo 'gx.elf not found — run build-nx.sh first' >&2; exit 1; }
	nacptool --create '$APP_TITLE' '$APP_AUTHOR' '$VERSION' \"\$OUT/browsernro.nacp\"
	elf2nro \"\$OUT/gx.elf\" \"\$OUT/BrowserNro.nro\" --nacp=\"\$OUT/browsernro.nacp\" --icon=/tmp/browsernro-icon.jpg
	ls -la \"\$OUT/BrowserNro.nro\"
"

mkdir -p "$HERE/dist"
echo "== copying BrowserNro.nro out of the container"
docker cp lkl-gx-nx:/work/gx-nx/BrowserNro.nro "$HERE/dist/BrowserNro.nro"
ls -la "$HERE/dist/BrowserNro.nro"
