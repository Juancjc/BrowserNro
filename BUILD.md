# Compilando o BrowserNro

Este documento descreve o processo real usado para gerar `BrowserNro.nro`
neste repositório. Ele automatiza, via Docker, o pipeline de build do
[`chromium-nx`](https://github.com/shodowlo/chromium-nx) (a engine, não
vendorada aqui — veja [LICENSING.md](LICENSING.md)) e depois rebatiza o
resultado com a identidade do BrowserNro.

## Pré-requisitos

| Ferramenta | Por quê | Verificado neste ambiente |
|---|---|---|
| Docker Desktop (com o motor Linux) | roda os dois contêineres de build | ✅ Docker 29.3.1 |
| Git | clonar engine e dependências | ✅ |
| ~20–30 GB de espaço livre em disco | imagens Debian arm64, fontes do kernel, toolchain devkitA64 | verifique antes de iniciar |
| Conexão de internet | baixa pacotes Debian arm64 (`chromium-shell`), o kernel LKL e o devkitA64 | |

Não é necessário instalar devkitPro/devkitA64 no Windows: tudo roda dentro
dos contêineres Docker, exatamente como o chromium-nx documenta.

## Visão geral das etapas

```
scripts/build.sh
 ├─ 0. clona shodowlo/chromium-nx em build/engine/ (gitignored, não vendorado)
 ├─ 1. docker build da imagem lkl-gx (Debian 12 + pacotes arm64, Dockerfile do engine)
 ├─ 2. cria o volume compartilhado "lklwork" e o container lkl-gx
 ├─ 3. clona lkl/linux (GPL-2.0) dentro do volume de trabalho
 ├─ 4. build-lkl.sh      — cross-compila o kernel LKL para o banco de testes em PC
 ├─ 5. build-pc.sh       — compila o "gx" para aarch64 Linux + roda os testes sob qemu-user
 ├─ 6. build-chromium.sh — monta a imagem ext4 com o Chromium arm64 da Debian
 ├─ 7. pull da imagem devkitpro/devkita64 + container lkl-gx-nx
 ├─ 8. build-nx.sh       — cross-compila o kernel LKL e o "gx" para o Switch (gx.nro)
 ├─ 9. build-hbl.sh      — compila um Homebrew Loader com espaço de endereço de 39 bits
 └─ scripts/rebrand.sh   — regrava NACP (nome/autor/versão) e ícone do BrowserNro
                            sobre o gx.elf já compilado, gerando BrowserNro.nro
```

## Executando

```bash
cd BrowserNro
bash scripts/build.sh 2>&1 | tee build/build.log
```

O script é idempotente por etapa: reexecutá-lo reaproveita o que já foi
baixado/compilado (cache do Docker, volume `lklwork`).

Saída esperada ao final:

```
dist/BrowserNro.nro
dist/BrowserNro.zip
```

## Detalhe de cada etapa

### 1. Imagem `lkl-gx` (Debian 12 + arm64)

Construída a partir de `build/engine/chromium-nx/gx/docker/Dockerfile`
(do próprio chromium-nx), que instala toolchain cruzado para aarch64,
`qemu-user-static`, e os **pacotes arm64 oficiais da Debian**
`chromium-headless-shell` e `chromium-shell` — é daí que vem o binário real
do Chromium, sem recompilação.

### 2–6. Build para PC (banco de testes aarch64 + Chromium)

Replica o fluxo do chromium-nx: compila o LKL, compila o `gx` para rodar sob
`qemu-aarch64`, roda a bateria de testes do projeto original (hello,
threads, dl, timers, gles, rede, curl HTTP/HTTPS) e monta a imagem
`chromium-switch.ext4` que o `.nro` final vai montar.

### 7–9. Build para o Switch

Usa a imagem oficial `devkitpro/devkita64`. Cross-compila o kernel LKL para
arm64 (`aarch64-none-elf-`), linka o `gx` com libnx/Mesa portado
(`portlibs/switch`), gera `gx.elf` → `gx.nro` com `elf2nro`, e compila o
Homebrew Loader de 39 bits (`build-hbl.sh`) necessário porque os alocadores
do Chromium não cabem no espaço de 36 bits padrão do loader de homebrew.

### 10. Rebatismo (BrowserNro)

`scripts/rebrand.sh` não recompila nada: ele chama `nacptool` e `elf2nro`
(ferramentas do devkitA64, usadas como pós-processamento) sobre o
`gx.elf`/`gx.nacp` já produzidos, trocando:

- Nome do app: `Chromium NX` → `BrowserNro`
- Autor: `shodowlo` → `BrowserNro`
- Ícone: `nx/icon.jpg` → `assets/icon/icon.jpg` (identidade própria)
- Versão: a deste repositório (`VERSION`)

O binário interno (engine `gx`) permanece o mesmo — só a "casca" de
metadados do `.nro` muda. Isso evita modificar/redistribuir o código-fonte
da engine (ver LICENSING.md).

## Instalando o Homebrew Loader customizado

A etapa 9 gera um `hbl.nsp` com espaço de endereço de 39 bits, exigido pelo
Chromium. **Isso substitui `atmosphere/hbl.nsp` no cartão SD.**
`scripts/package.sh` automaticamente guarda uma cópia do `hbl.nsp` original
(se existir no SD apontado) como `hbl.nsp.original-backup` antes de
sobrescrever — mas confirme você mesmo um backup antes de gravar no cartão
real. Isto é uma mudança fora do workspace e requer sua confirmação antes
de ser aplicada a um cartão físico.

## Problemas conhecidos de build

Veja [KNOWN_ISSUES.md](KNOWN_ISSUES.md) e, após cada execução,
`build/build.log` para o log completo desta execução específica.
