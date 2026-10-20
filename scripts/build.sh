#!/bin/bash
# Build orchestration for BrowserNro.
#
# Drives the upstream chromium-nx (shodowlo/chromium-nx) build pipeline
# inside Docker, exactly as documented in that project's own README, then
# rebrands the resulting binary as BrowserNro (scripts/rebrand.sh) and
# packages it for the SD card (scripts/package.sh).
#
# This script does NOT modify or vendor chromium-nx's source: it clones it
# fresh into build/engine/ (gitignored) as a build-time dependency and only
# invokes its own, unmodified build scripts. See BUILD.md and LICENSING.md.
set -eu
set -o pipefail

# Git Bash on Windows rewrites bare /posix/style paths in argv into Windows
# paths (e.g. /work/linux -> C:/Program Files/Git/work/linux) before they
# ever reach docker.exe, which breaks every `docker exec ... /work/...`
# call below. MSYS_NO_PATHCONV disables that rewriting for this script.
export MSYS_NO_PATHCONV=1

HERE=$(cd "$(dirname "$0")/.." && pwd)
BUILD_DIR="$HERE/build"
ENGINE_DIR="$BUILD_DIR/engine/chromium-nx"
ENGINE_REPO="${ENGINE_REPO:-https://github.com/shodowlo/chromium-nx}"
LOG="$BUILD_DIR/build.log"

mkdir -p "$BUILD_DIR"
exec > >(tee -a "$LOG") 2>&1
echo "===== $(date) : BrowserNro build start ====="

echo "## Step 0: fetch the upstream engine (build-time dependency, not vendored)"
mkdir -p "$BUILD_DIR/engine"
if [ ! -d "$ENGINE_DIR/.git" ]; then
	git clone --depth 1 "$ENGINE_REPO" "$ENGINE_DIR"
fi
git -C "$ENGINE_DIR" log -1 --format="engine commit: %H (%ad)" --date=short

echo "## Step 1: build the lkl-gx image (Debian 12 + arm64 packages)"
docker build -t browsernro/lkl-gx -f "$ENGINE_DIR/gx/docker/Dockerfile" "$ENGINE_DIR"

echo "## Step 2: shared work volume + lkl-gx container"
docker volume create lklwork >/dev/null
docker rm -f lkl-gx >/dev/null 2>&1 || true
docker run -d --name lkl-gx -v "$ENGINE_DIR:/project" -v lklwork:/work browsernro/lkl-gx sleep infinity

echo "## Step 2b: install ffmpeg dev headers (libavcodec/libavutil) for gx/video.c"
# The upstream Dockerfile (gx/docker/Dockerfile) does not declare these, but
# gx/video.c (host-side H.264 decode) and build-pc.sh's link line
# (-lavcodec -lavutil) need them. A real upstream gap, worked around here
# instead of patching their Dockerfile. See KNOWN_ISSUES.md.
docker exec lkl-gx bash -c 'apt-get update && apt-get install -y --no-install-recommends libavcodec-dev:arm64 libavutil-dev:arm64'

echo "## Step 3: clone LKL (Linux kernel as a library, GPL-2.0) into the work volume"
docker exec lkl-gx bash -c '[ -d /work/linux ] || git clone --depth 1 https://github.com/lkl/linux.git /work/linux'

echo "## Step 4: build LKL for the PC test bench"
docker exec lkl-gx bash /project/gx/build-lkl.sh

echo "## Step 5: build gx for PC + sysroot + run PC tests (qemu-aarch64)"
docker exec lkl-gx bash /project/gx/build-pc.sh

echo "## Step 6: build Chromium's root filesystem (Debian arm64 chromium-shell)"
docker exec lkl-gx bash /project/gx/build-chromium.sh

echo "## Step 6b: apply BrowserNro patches (directory/log + user-visible text — see patches/README.md)"
bash "$HERE/patches/0001-browsernro-dir.sh" "$ENGINE_DIR"
bash "$HERE/patches/0002-browsernro-text.sh" "$ENGINE_DIR"

echo "## Step 7: devkitA64-based build image (Dockerfile) + lkl-gx-nx container"
docker build -t browsernro/lkl-gx-nx -f "$HERE/Dockerfile" "$HERE"
docker rm -f lkl-gx-nx >/dev/null 2>&1 || true
docker run -d --name lkl-gx-nx -v "$ENGINE_DIR:/project" -v lklwork:/work browsernro/lkl-gx-nx sleep infinity

echo "## Step 8: cross-build the kernel + gx for the Switch -> gx/dist-nx"
docker exec lkl-gx-nx bash /project/gx/build-nx.sh

echo "## Step 9: build the 39-bit-address-space Homebrew Loader"
docker exec lkl-gx-nx bash /project/gx/build-hbl.sh

echo "## Step 10: rebrand as BrowserNro (NACP + icon, no source changes)"
bash "$HERE/scripts/rebrand.sh"

echo "## Step 11: package for the SD card"
bash "$HERE/scripts/package.sh"

echo "===== $(date) : BrowserNro build complete ====="
echo "Output: $HERE/dist/BrowserNro.nro and $HERE/dist/BrowserNro.zip"
