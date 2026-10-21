#!/bin/bash
# Assembles dist/BrowserNro.zip: the SD card layout described in README.md
# (/switch/BrowserNro/...), built from the artifacts produced by
# scripts/build.sh + scripts/rebrand.sh. Does not touch any SD card itself —
# it only produces a zip for the user to copy manually (see BUILD.md on the
# optional Homebrew Loader replacement, which needs explicit confirmation).
set -eu
set -o pipefail

HERE=$(cd "$(dirname "$0")/.." && pwd)
DIST="$HERE/dist"
STAGE="$HERE/build/package-stage"
PYEXE="${PYEXE:-python3}"

[ -f "$DIST/BrowserNro.nro" ] || { echo "missing $DIST/BrowserNro.nro — run scripts/rebrand.sh first" >&2; exit 1; }

rm -rf "$STAGE"
APP="$STAGE/switch/BrowserNro"
mkdir -p "$APP"/{assets,config,cache,downloads,data,logs}

cp "$DIST/BrowserNro.nro" "$APP/BrowserNro.nro"

echo "== copying Chromium's root filesystem image out of the build container"
if docker ps --format '{{.Names}}' | grep -qx lkl-gx; then
	docker cp lkl-gx:/work/gx-out/chromium-switch.ext4 "$APP/chromium.ext4" 2>/dev/null ||
		echo "WARNING: chromium-switch.ext4 not found in lkl-gx:/work/gx-out — run scripts/build.sh through step 6 first" >&2
else
	echo "WARNING: lkl-gx container not running — cannot fetch chromium.ext4; run scripts/build.sh first" >&2
fi

echo "== generating programs.txt from homepage.json + bookmarks.json (one shortcut per entry)"
"$PYEXE" - "$HERE/source/config/homepage.json" "$HERE/source/config/bookmarks.json" "$APP/programs.txt" <<'PYEOF'
import json, sys

homepage_path, bookmarks_path, out_path = sys.argv[1:4]

def command_for(label, url):
	return (
		f"[{label}] -w -b @chromium.ext4 /usr/lib/chromium/chromium-shell --no-sandbox "
		"--single-process --no-zygote --use-gl=angle --use-angle=gles-egl "
		"--ignore-gpu-blocklist --disable-gpu-sandbox --in-process-gpu "
		f"--ozone-platform=wayland --enable-spatial-navigation --remote-debugging-pipe {url}"
	)

home = json.load(open(homepage_path, encoding="utf-8"))
bookmarks = json.load(open(bookmarks_path, encoding="utf-8")).get("bookmarks", [])

lines = [command_for(home.get("label", "BrowserNro"), home["homepage_url"])]
for b in bookmarks:
	# Skip a bookmark that's identical to the homepage, to avoid a duplicate entry.
	if b["url"] == home["homepage_url"]:
		continue
	lines.append(command_for(b["title"], b["url"]))

with open(out_path, "w", encoding="utf-8", newline="\n") as f:
	f.write("# Gerado por scripts/package.sh a partir de source/config/homepage.json e bookmarks.json.\n")
	f.write("# Um item por atalho -- escolha com o d-pad e confirme com A ao abrir o BrowserNro.\n")
	for line in lines:
		f.write(line + "\n")

print(f"programs.txt: {len(lines)} atalho(s)")
for line in lines:
	print(" ", line.split(" ", 1)[0])
PYEOF

cp "$HERE/source/config/homepage.json" "$APP/config/homepage.json"
cp "$HERE/source/config/bookmarks.json" "$APP/config/bookmarks.json"
cp "$HERE/source/input/controls.json" "$APP/config/controls.json"
cp "$HERE/source/l10n/pt-BR.json" "$APP/config/pt-BR.json"
cp -r "$HERE/assets/icon" "$HERE/assets/logo" "$APP/assets/"

for d in cache downloads data logs; do
	cat > "$APP/$d/LEIA-ME.txt" <<EOF
Esta pasta é usada pelo BrowserNro em tempo de execução ($d/).
Criada vazia pelo instalador — nenhum dado de usuário é incluído aqui.
EOF
done

echo "== optional: 39-bit Homebrew Loader (replaces atmosphere/hbl.nsp — NOT applied automatically)"
HBL_DIR="$STAGE/ATMOSPHERE-HBL-OPCIONAL-LEIA-ANTES"
if docker ps --format '{{.Names}}' | grep -qx lkl-gx-nx; then
	mkdir -p "$HBL_DIR/atmosphere"
	if docker cp lkl-gx-nx:/project/gx/dist-hbl/atmosphere/hbl.nsp "$HBL_DIR/atmosphere/hbl.nsp" 2>/dev/null; then
		cat > "$HBL_DIR/LEIA-ME.txt" <<'EOF'
O BrowserNro precisa de mais espaço de endereçamento (39 bits) do que o
Homebrew Loader padrão oferece (36 bits) para caber os alocadores do
Chromium. Este hbl.nsp foi compilado para isso.

ANTES de copiar atmosphere/hbl.nsp para o seu cartão SD:
1. Faça backup do seu atmosphere/hbl.nsp atual (renomeie para hbl.nsp.bak).
2. Só então copie o hbl.nsp desta pasta para atmosphere/hbl.nsp no SD.

Isso é uma mudança de um arquivo crítico do seu setup de CFW — o
BrowserNro NUNCA faz isso automaticamente. Veja BUILD.md.
EOF
	else
		rm -rf "$HBL_DIR"
		echo "WARNING: hbl.nsp not found — run scripts/build.sh through step 9 first" >&2
	fi
fi

mkdir -p "$DIST"
rm -f "$DIST/BrowserNro.zip"
( cd "$STAGE" && python3 -c "
import shutil
shutil.make_archive('$DIST/BrowserNro', 'zip', '.')
" )
echo "== package ready"
ls -la "$DIST"
