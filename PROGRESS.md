# Progresso do BrowserNro

Última atualização: 2026-10-20 (sessão de desenvolvimento inicial).

## Decisões de arquitetura tomadas

1. **Motor escolhido: a engine `gx` do [chromium-nx](https://github.com/shodowlo/chromium-nx)**
   (LKL + binário arm64 real do Chromium da Debian, sem recompilar o
   Chromium). Comparado com NetSurf e Brewser — ver ARCHITECTURE.md — e
   confirmado como a única rota com Chromium real e **já comprovada em
   hardware** pelo autor original.
2. **A engine não é vendorada neste repositório.** É clonada em tempo de
   build para `build/engine/` (gitignored). Motivo: `shodowlo/chromium-nx` e
   `mnnobre/lkl-switch` não declaram licença no GitHub (`license: null`,
   verificado via API em 2026-10-20) — ver LICENSING.md. Isso também
   significa: **não publicar `.nro`/`.zip` compilados como release pública
   no GitHub até esclarecer a licença com o autor original.**
3. **Patch mínimo aplicado em build-time** (`patches/0001-browsernro-dir.sh`):
   troca o diretório fixo `sdmc:/switch/chromium-nx` → `sdmc:/switch/BrowserNro`
   e o nome do log, para bater com a estrutura de instalação pedida. Não
   commitamos o arquivo da engine modificado — só o script de patch.
4. **Rebatismo de identidade via pós-processamento** (`scripts/rebrand.sh`):
   reusa `nacptool`/`elf2nro` do devkitA64 sobre o `gx.elf` já compilado, sem
   tocar no código-fonte da engine, para trocar nome/autor/ícone.
5. **Página inicial configurável via `source/config/homepage.json`**,
   aplicada gerando um `programs.txt` de **uma única entrada** (não um menu
   de várias opções) — a engine detecta `command_count` e vai direto para o
   app, sem exigir toque extra do usuário além de ligar o app. Favoritos
   (`bookmarks.json`) e strings pt-BR (`pt-BR.json`) ficam preparados para
   uma futura UI de configurações nativa — ainda não implementada (ver
   KNOWN_ISSUES.md).

## O que está feito

- [x] Pesquisa e comparação de motores (chromium-nx, netsurf-switch,
      Brewser, BrowseNX) — ARCHITECTURE.md.
- [x] Verificação de licenças dos repositórios de referência via API do
      GitHub — LICENSING.md.
- [x] Estrutura completa do repositório (README, ARCHITECTURE, BUILD,
      TESTING, KNOWN_ISSUES, LICENSING, LICENSE, PROGRESS, scripts/,
      source/, patches/, assets/, .github/workflows/).
- [x] Identidade visual própria gerada (ícone 256×256 JPEG exigido pelo
      NACP, logotipo, wordmark) — `assets/generate_identity.py`,
      `assets/icon/icon.jpg`, `assets/logo/*.png`. Conceito: globo/rede +
      janela de navegador + ponteiro de navegação, paleta própria, sem
      reproduzir marcas de navegadores existentes.
- [x] `scripts/build.sh` — orquestração completa via Docker das 11 etapas
      descritas em BUILD.md (imagem lkl-gx → LKL → testes de PC → imagem
      Chromium → patch de diretório → imagem lkl-gx-nx (Dockerfile próprio)
      → build NX → Homebrew Loader 39-bit → rebrand → empacotamento).
- [x] `scripts/rebrand.sh` e `scripts/package.sh` implementados.
- [x] `patches/0001-browsernro-dir.sh`, testado isoladamente contra uma
      cópia do `host_nx.c` real (fora do clone de build) — confirma que
      troca corretamente `GX_DIR` e o nome do arquivo de log.
- [x] Configurações iniciais (`source/config/homepage.json`,
      `bookmarks.json`), mapeamento de controles
      (`source/input/controls.json`) e strings pt-BR reservadas
      (`source/l10n/pt-BR.json`).
- [x] GitHub Actions (`.github/workflows/build.yml`) reproduzindo o
      pipeline de build em runner hospedado (não substitui teste em
      hardware).
- [x] Ambiente local verificado: Docker Desktop 29.3.1 funcional (precisou
      ser iniciado manualmente), 16 núcleos, 32 GB RAM, ~55 GB livres em
      disco no início do build.
- [x] **Build completo executado com sucesso nesta sessão** (20/10/2026),
      via `bash scripts/build.sh` dentro de WSL2/Ubuntu (migrado do Git Bash
      do Windows por bugs de conversão de path — ver nota abaixo). Todas as
      11 etapas do pipeline rodaram até o fim:
      - Imagem `lkl-gx` construída (Debian 12 + `chromium-shell:arm64
        155.0.8059.79-1~deb12u1`).
      - **Kernel LKL cross-compilado** (`liblkl.a`, 240.325.076 bytes).
      - **8/8 testes de PC da própria engine passaram**: hello, threads, dl,
        timers, gles, net, curl-http, curl-https (sob `qemu-aarch64`).
      - **Página de teste renderizada pelo Chromium real**, com o JS da
        página executando de verdade (`[1,2,3].map(x=>x*x)` → `1,4,9` no
        DOM capturado).
      - `chromium.ext4` montado (344.981.504 bytes) com o `chromium-shell`
        arm64 real da Debian.
      - **Cross-build completo para o Switch** via devkitA64:
        `chromium-nx.nro` (26.465.758 bytes) e o Homebrew Loader de 39 bits
        (`hbl.nsp`, 40.956 bytes).
      - **Rebrand bem-sucedido**: `dist/BrowserNro.nro` (26.472.450 bytes)
        — `tests/validate_nro.py` confirma estruturalmente que o NACP
        embutido diz `nome='BrowserNro' autor='BrowserNro'` (não mais
        "Chromium NX"/"shodowlo").
      - **Pacote final gerado**: `dist/BrowserNro.zip` (150.010.710 bytes)
        com a estrutura `/switch/BrowserNro/` completa.
      - Log completo em `build/build.log`; resultados tabulados em
        TESTING.md.
- [x] Dois problemas reais de ambiente encontrados e corrigidos durante o
      build (documentados para não se perderem):
      1. **Git Bash no Windows corrompe paths `/posix/...` passados ao
         Docker** (`/work/linux` virava `C:/Program Files/Git/work/linux`),
         e o git nativo do Windows chegou a abortar (`BUG:
         get_tempfile_fd()`) ao clonar um repositório grande dentro de
         `/mnt/c` via WSL. Solução: rodar o pipeline inteiro de dentro do
         WSL2 (Ubuntu), com o workspace de build no filesystem Linux nativo
         (`~/browsernro`, ext4), não em `/mnt/c`. `scripts/build.sh` também
         ganhou `export MSYS_NO_PATHCONV=1` como proteção extra para quem
         rodar via Git Bash mesmo assim.
      2. **O `Dockerfile` oficial do chromium-nx não declara
         `libavcodec-dev`/`libavutil-dev`**, que `gx/video.c` e o link de
         `build-pc.sh` precisam — corrigido instalando esses pacotes
         manualmente na etapa 2b de `scripts/build.sh` (ver
         KNOWN_ISSUES.md).

## Pendente (continuar daqui em uma nova sessão, se necessário)

- [ ] Decidir, com o usuário, se/quando publicar **binários** no GitHub
      (depende de LICENSING.md — contato com o autor de chromium-nx). O
      código-fonte/scripts podem ir ao GitHub normalmente.
- [ ] Teste em hardware real (Switch V1 físico) — fora do alcance desta
      sessão (sem console físico disponível); roteiro pronto em
      TESTING.md §4. É o item que falta para tirar o rótulo de "versão
      candidata".
- [ ] UI nativa de configurações/favoritos/histórico em pt-BR (hoje são só
      arquivos de configuração, não uma tela dentro do navegador).
- [ ] Investigar suporte real a múltiplas abas (não confirmado na engine
      upstream).
- [ ] Reportar ao autor do chromium-nx a lacuna do Dockerfile
      (libavcodec-dev/libavutil-dev ausentes).

## Como retomar

```bash
cd BrowserNro
cat build/build.log          # ver onde a última execução parou
bash scripts/build.sh        # idempotente: reaproveita cache/volume existentes
```

Se o Docker Desktop não estiver rodando, inicie-o antes
(`"C:\Program Files\Docker\Docker\Docker Desktop.exe"` no Windows).
