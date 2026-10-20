# Referências investigadas

Registro do levantamento feito antes de decidir a arquitetura do
BrowserNro (ARCHITECTURE.md). Datas de verificação: 2026-10-20.

## Engine principal

### shodowlo/chromium-nx

- Commit investigado: `876daa96a0c0476df15dfa1e3caabbc477630b87` (2026-10-13).
- Autor único (`shodow`), projeto ativo e recente.
- Arquitetura: LKL (Linux como biblioteca, sem MMU) + executor de ELF nativo
  aarch64 (`gx`) + binário `chromium-shell` arm64 oficial da Debian, sem
  recompilação do Chromium.
- Renderização: ANGLE dentro do Chromium fala com o driver EGL/GLES real do
  console via thunks finos (`gx/guest/*`).
- Rede: NAT em modo usuário (`gx/nat.c`) entre a pilha de rede do LKL e os
  sockets do Horizon (`bsd:u`).
- Entrada: D-pad, A/B/X/Y, L/R, analógicos e touchscreen lidos nativamente
  via libnx; toque em campo de texto aciona o teclado do sistema (`swkbd`).
- Áudio: `libasound.so.2` próprio, thunk para APIs do host.
- Memória: arena reservada de endereços, "code memory" do Horizon
  (`svcMapProcessCodeMemory`) para W^X; precisa de um Homebrew Loader com
  39 bits de espaço de endereço (`gx/build-hbl.sh`) para caber os
  alocadores do Chromium.
- Build: dois containers Docker (`lkl-gx`: Debian 12 + pacotes arm64 +
  devkitA64 cruzado para o PC bench; `lkl-gx-nx`: devkitA64 para o `.nro`
  final).
- Limitações conhecidas (do próprio README): vídeos do YouTube às vezes
  travam; um processo único sem sandbox; sem suporte documentado a múltiplas
  abas (o modo comprovado em hardware é `chromium-shell`, uma única janela).
- **Licença: não declarada** (`license: null` via API do GitHub, verificado
  em 2026-10-20). Ver LICENSING.md.

### mnnobre/lkl-switch

- Projeto do qual o `gx` herda o núcleo LKL↔Horizon (`nro/source/nx_host.c`,
  `nx_exec.c`, `nx_trampoline.s`).
- Primeiro a rodar um binário Linux real (`busybox`) dentro de um `.nro`,
  sem MMU, com um executor de ELF e ponte de syscalls escritos do zero.
- README do próprio autor descreve o código como MIT, mas **sem um arquivo
  `LICENSE` formal** e `license: null` na API do GitHub.

## Alternativas avaliadas

### etonedemid/netsurf-switch

- Porta do motor [NetSurf](https://www.netsurf-browser.org/) (licença MIT
  do próprio NetSurf) para o Switch.
- Motor leve, próprio, sem V8 — JavaScript limitado/experimental, não
  equivalente a um motor moderno.
- Útil como fallback leve ou para dispositivos sem a arquitetura LKL, mas
  não atinge o nível de compatibilidade web pedido para o BrowserNro
  (HTML5/CSS3 moderno, JS real, HTTPS robusto).

### natureglass/Brewser

- Projeto menor, investigado como referência de estrutura/UI.
- Não foi adotado como motor principal: menos documentado/testado que
  chromium-nx, sem evidência pública equivalente de funcionamento em
  hardware real com HTTPS + JS + GPU.

### crc-32/BrowseNX

- Projeto exploratório, útil como referência de estrutura de repositório.
- Não chega a um navegador funcional comprovado em hardware.

## Infraestrutura homebrew

### switchbrew/libnx

- Toolkit padrão para homebrew do Switch (licença zlib). Usado pela engine
  e por qualquer código nativo adicional do BrowserNro.

### switchbrew/switch-examples

- Exemplos oficiais de libnx — consultados para padrões de uso de
  `hidGetNpadStates*`, `appletMainLoop`, `consoleInit`, etc., usados por
  `gx/host_nx.c`.

### switchbrew/nx-hbloader

- Homebrew Loader padrão; `gx/build-hbl.sh` compila uma variante com espaço
  de endereço de 39 bits (em vez dos 36 bits padrão) — necessário para os
  alocadores do Chromium, conforme comentário do próprio script.

### Lili679280/switch-homebrew

- Repositório de referência geral sobre desenvolvimento de homebrew para
  Switch, consultado para contexto adicional sobre o ecossistema
  (devkitPro, estrutura de projetos, convenções).

## Conclusão

A arquitetura do `chromium-nx` continua sendo, de longe, a única opção
testada publicamente que entrega Chromium real (V8 completo, HTTPS, GPU) em
hardware físico do Switch. O BrowserNro adota essa arquitetura por
referência (não por cópia — ver LICENSING.md) e foca sua contribuição em
identidade, localização, configuração e empacotamento.
