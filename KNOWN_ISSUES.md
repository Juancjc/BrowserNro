# Limitações conhecidas

Lista honesta do que não funciona, funciona parcialmente, ou é incerto. Itens
marcados **[herdado]** vêm da engine de terceiros (chromium-nx); itens
**[BrowserNro]** são específicos deste empacotamento.

## Funcionais / estabilidade

- **[herdado] Vídeos do YouTube às vezes travam** durante a reprodução,
  segundo o próprio README do chromium-nx. Não temos, ainda, dados de
  frequência ou causa raiz.
- **[herdado] Um processo único, sem sandbox** (`--single-process
  --no-zygote --no-sandbox`): é o modelo de segurança do processo Chromium
  reduzido ao mínimo para caber no Horizon. Isso significa que uma falha de
  renderização de página pode derrubar o navegador inteiro (não há processo
  de aba isolado para reiniciar sozinho).
- **[herdado] Sem JIT em alguns modos**: a opção padrão mais estável listada
  no menu de desenvolvimento do chromium-nx roda com `--js-flags=--jitless`;
  o modo com JIT (mais rápido) é uma opção à parte, com mais chance de
  esbarrar nas restrições de memória executável do Horizon.
- **[BrowserNro] Build ainda não validado em hardware físico** — veja
  TESTING.md. Trate esta versão como candidata.

## Interface e funcionalidades de navegador "tradicional"

- **[herdado/BrowserNro] Múltiplas abas não têm suporte confirmado.** O modo
  comprovado em hardware pela engine é `chromium-shell` — uma única janela
  Wayland sem a UI completa de abas do Chrome. O modo "navegador inteiro"
  (`chromium`, com UI de abas e barra de endereço nativas) existe no script
  de build do chromium-nx como uma opção experimental ("a trial next to
  chromium-shell"), explicitamente marcada por aquele projeto como menos
  testada. O mapeamento de controles do BrowserNro (L/R = aba
  anterior/próxima) está preparado para quando esse modo for validado, mas
  **hoje não garantimos abas múltiplas funcionais**.
- **[BrowserNro] Histórico, favoritos e gerenciador de downloads com UI
  própria** ainda não têm uma interface nativa construída pelo BrowserNro;
  o que existe hoje é a configuração inicial (`source/config/`) e o que o
  próprio Chromium (modo "navegador inteiro") oferecer nativamente. Uma UI
  de navegador dedicada, fora do Chromium em si, não foi construída neste
  projeto — ver ARCHITECTURE.md sobre por que reaproveitar a UI nativa do
  Chromium é a escolha mais realista em vez de recriar uma.
- **[BrowserNro] Tema claro/escuro, teclado virtual próprio**: o BrowserNro
  não implementa um teclado virtual próprio; usa o teclado do sistema
  Horizon (`swkbd`), que a engine já aciona ao focar campos de texto. Tema
  claro/escuro, quando existente, é o do próprio Chromium/sistema, não uma
  camada de UI própria do BrowserNro.

## Memória e desempenho

- **[herdado] Limites de memória do Horizon exigem um Homebrew Loader
  customizado** (espaço de endereço de 39 bits) — isso substitui
  `atmosphere/hbl.nsp` no cartão SD (ver BUILD.md). Precisa de confirmação
  explícita antes de aplicar em um cartão real.
- **[herdado] Memória compartilhada é escassa no Horizon** (até ~80 objetos
  no console inteiro) — a engine já lida com isso agrupando arquivos
  compartilhados em poucos blocos grandes, mas isso é uma restrição de
  fundo que pode limitar cenários futuros (ex.: múltiplos processos).
- **[BrowserNro] Nenhuma medição própria de uso de RAM/CPU em hardware**
  ainda existe — depende de teste em console real (TESTING.md, seção 4).

## Rede

- **[herdado] HTTPS depende do NAT em modo usuário** (`nat.c`) entre a rede
  do LKL e os sockets do Horizon; redes com portais cativos, proxies
  corporativos ou autenticação Wi-Fi Enterprise não foram verificadas.

## Lacunas encontradas no build do upstream

- **[BrowserNro] O `Dockerfile` oficial do chromium-nx (`gx/docker/Dockerfile`)
  não declara `libavcodec-dev`/`libavutil-dev`**, embora `gx/video.c` (decodificação
  de H.264 pelo host) e o link de `build-pc.sh` (`-lavcodec -lavutil`) dependam
  deles — a compilação de `gx` para o banco de testes de PC falha com
  `fatal error: libavcodec/avcodec.h: No such file or directory` sem esse
  pacote. `scripts/build.sh` instala `libavcodec-dev:arm64`/`libavutil-dev:arm64`
  manualmente como correção local (etapa 2b), sem modificar o Dockerfile do
  upstream. Vale reportar ao autor do chromium-nx.

## Legal / distribuição

- **[BrowserNro] A engine de terceiros não tem licença declarada no
  GitHub** (`license: null` tanto para chromium-nx quanto para lkl-switch).
  Isso bloqueia a distribuição de binários compilados a partir dela até que
  haja esclarecimento do autor original. Veja
  [LICENSING.md](LICENSING.md) — **este é o maior bloqueio para uma release
  pública de `.nro` pronto, não um problema técnico**.
- **[herdado] Downloads ficam em `profile.ext4`**, uma imagem de disco
  dentro do `.nro` — não há, ainda, uma integração direta e documentada com
  pastas comuns do cartão SD (ex.: `/switch/BrowserNro/downloads/`) além da
  estrutura prevista neste repositório; isso precisa de validação em
  hardware.

## O que explicitamente não foi implementado (para não gerar expectativa
   errada)

- Upload de arquivos ponta a ponta testado.
- Sincronização de conta/perfil entre dispositivos.
- Extensões de navegador.
- Qualquer telemetria (deliberadamente — não é um objetivo deste projeto).
