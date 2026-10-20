# Imagem de build para o estágio Nintendo Switch (NX) do BrowserNro.
#
# Baseada na imagem oficial do devkitPro (devkitA64 + libnx), com os pacotes
# que o build do kernel LKL cruzado (aarch64-none-elf) e o "gx" precisam.
# Usada por scripts/build.sh para criar o container "lkl-gx-nx".
#
# A outra metade do pipeline (Debian 12 + pacotes arm64 + chromium-shell) usa
# o Dockerfile do próprio chromium-nx (build/engine/chromium-nx/gx/docker/Dockerfile),
# que não duplicamos aqui — veja BUILD.md.
FROM devkitpro/devkita64:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    flex bison bc libelf-dev cpio rsync build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /project
