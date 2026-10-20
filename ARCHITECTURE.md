# Arquitetura do BrowserNro

## Visão geral

```
┌─ BrowserNro.nro ───────────────────────────────────────────────────────┐
│  Camada BrowserNro (este repositório)                                  │
│   - metadados .nacp (nome, autor, versão) e ícone próprios             │
│   - config/ (página inicial, favoritos padrão, idioma pt-BR)           │
│   - scripts de empacotamento e mapeamento de controles                 │
│  ┌─ Engine "gx" (chromium-nx, de terceiros — veja LICENSING.md) ─────┐ │
│  │  host_nx.c    lado Horizon: memória, threads, tela, pad, som,     │ │
│  │               cartão SD como disco, rede                          │ │
│  │  ┌─ LKL: Linux como biblioteca (sem MMU) ───────────────────────┐ │ │
│  │  │  arquivos (imagem ext4, tmpfs), sockets, pipes, epoll...     │ │ │
│  │  └────────────────────────────────────────────────────────────┘ │ │
│  │  gelf.c/gmem.c/gsys.c/tramp.S   executa binários Linux ELF      │ │
│  │  wl.c        compositor Wayland (a janela do Chromium)          │ │
│  │  cdp.c       Chrome DevTools Protocol (foco em campos de texto) │ │
│  │  nat.c       NAT em modo usuário entre a rede do LKL e o        │ │
│  │              socket do Horizon                                  │ │
│  │  ┌─ guest: chromium-shell (Debian arm64), glibc ───────────────┐│ │
│  │  │  libEGL/libGLESv2/libasound: finos, chamam os drivers do    ││ │
│  │  │  host (GPU e áudio reais do console)                        ││ │
│  │  └──────────────────────────────────────────────────────────────┘│ │
│  └────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

O binário arm64 roda **nativamente** no Tegra X1 (também arm64) — não há
emulação de CPU. O que um Linux de verdade faria pelo processo guest é
dividido entre o LKL (arquivos, rede) e o `gx` (memória, threads, tempo).

## Por que não "Chromium do zero"

Compilar o Chromium completo para Horizon OS do zero — com seu próprio
toolchain Clang, GN/Ninja, V8, Blink, ANGLE, todas as sandboxes e serviços —
é um esforço de engenharia de anos-pessoa mesmo para equipes grandes, e
exigiria portar centenas de abstrações de SO (processos, sandboxing,
IPC, drivers gráficos) que o Horizon simplesmente não tem. A estratégia
comprovada publicamente (chromium-nx) contorna isso:

1. Usa o **binário arm64 oficial do Chromium já compilado pela Debian**
   (`chromium-shell`/`chromium-headless-shell`), sem recompilar uma linha
   do Chromium.
2. Fornece a esse binário um ambiente Linux mínimo via **LKL** (kernel real,
   rodando como biblioteca, sem MMU — porque o processo nunca troca de
   espaço de endereço, só o `gx` o executa).
3. Faz a ponte das chamadas de sistema e da GPU/áudio para APIs nativas do
   libnx.

Isso foi **confirmado funcionando em hardware real** pelo autor do
chromium-nx: Google, Wikipedia e YouTube carregam; JIT e renderização por GPU
funcionam; toque, rolagem, entrada de texto com o teclado do sistema e foco
por D-pad funcionam.

Avaliamos as alternativas pedidas (netsurf-switch, Brewser) — veja a
comparação abaixo — mas nenhuma chega perto do nível de compatibilidade web
real (JS moderno, HTTPS robusto, layout CSS atual) que o Chromium via LKL já
demonstra ter em hardware. Por isso o BrowserNro prioriza essa rota, como
pedido.

## Comparação técnica de motores avaliados

| Motor | Compatibilidade web | JS | HTTPS | Estado no Switch | Observação |
|---|---|---|---|---|---|
| **Chromium (via LKL, chromium-nx)** | Alta (motor real de 2024+) | V8 completo, com JIT | Sim (NSS real) | **Confirmado em hardware** pelo autor | Caminho escolhido |
| NetSurf (netsurf-switch) | Baixa/média — motor leve, próprio, sem V8 | Interpretador próprio, JS limitado | Parcial | Portado, mas engine muito mais simples | Útil como fallback leve, não como motor principal |
| Brewser | Depende da engine subjacente usada no port | Variável | Variável | Projeto menor, menos documentado/testado | Estudado como referência de UI, não adotado como motor |
| BrowseNX | Exploratório | — | — | Protótipo | Referência de estrutura de projeto apenas |

Conclusão: **Chromium via a engine `gx`/LKL permanece a opção certa** enquanto
tiver um caminho de build executável — o que este repositório confirma ter.

## Camadas que o BrowserNro adiciona sobre a engine

A engine `gx` já entrega o motor de navegação funcionando (ver tabela de
funcionalidades no README). O BrowserNro adiciona:

1. **Identidade e empacotamento**: `.nacp` com nome "BrowserNro", autor,
   versão e TitleID próprios; ícone e logotipo próprios (`assets/`); gerados
   sem copiar marcas de navegadores existentes.
2. **Localização pt-BR**: textos de configuração, página inicial e
   mensagens de erro amigáveis ficam em português brasileiro
   (`source/l10n/pt-BR.json`).
3. **Configuração padrão de navegação**: página inicial configurável
   (`source/config/homepage.json`), lista inicial de favoritos
   (`source/config/bookmarks.json`).
4. **Mapeamento de controles explícito**: `source/input/controls.json`
   documenta e aplica o mapeamento A/B/X/Y/L/R/+/-/analógicos descrito no
   README, construído sobre os eventos de pad que a engine já expõe via
   libnx (`hidGetNpadStates*`) e consumidos antes de serem repassados ao
   compositor Wayland da engine (`gx/wl.c`) como eventos de teclado/toque
   sintéticos ou como atalhos nativos do `gx` quando disponíveis
   (D-pad/A/B/X/Y/L/R/sticks já são lidos nativamente pelo `gx`, conforme
   seu próprio README).
5. **Scripts de build reprodutíveis**: `scripts/build.sh` automatiza os dois
   contêineres Docker (`lkl-gx` para PC/Chromium, `lkl-gx-nx` para o `.nro`
   final) exatamente como documentado pelo chromium-nx, sem exigir que quem
   compila entenda os detalhes internos do LKL.
6. **Empacotamento de distribuição**: `scripts/package.sh` monta a estrutura
   `/switch/BrowserNro/` (app, assets, config, cache, downloads, data, logs)
   em `dist/BrowserNro.zip`.

## Entrada

A engine `gx` (ver seu `README`) já lê nativamente, via libnx:

- D-pad: move o foco entre links.
- A: segue o link focado / abre o teclado em um campo de texto.
- B / X: voltar / recarregar.
- Y: abre o teclado na barra de endereço.
- L / R: backspace / enter (no teclado do sistema).
- Analógicos: rolagem.
- Touchscreen: toque, arraste, rolagem; tocar em um campo de texto abre o
  teclado do sistema.

O mapeamento do BrowserNro (tabela do README) **reaproveita exatamente essas
primitivas** e as rotula de forma consistente com o resto da interface
(ex.: "Y = barra de endereço" já é o comportamento nativo; "L/R = aba
anterior/próxima aba" é a extensão do BrowserNro para quando o suporte a
múltiplas abas estiver disponível — ver KNOWN_ISSUES.md sobre o estado atual
de abas).

## Memória e modos de execução

- **Application Mode** (Homebrew Menu aberto segurando R ao iniciar um
  jogo) é priorizado, pois libera mais memória ao processo — essencial para
  caber o Chromium. Documentado em BUILD.md/README.md.
- **Applet Mode** (Homebrew Menu normal, sem segurar R) tem memória mais
  restrita e não é a forma recomendada de rodar o BrowserNro.
- O `gx` usa um Homebrew Loader customizado (`build-hbl.sh`, 39-bit de
  espaço de endereço) para caber os alocadores do Chromium — isso substitui
  `atmosphere/hbl.nsp` no cartão SD. O instalador do BrowserNro mantém uma
  cópia do `hbl.nsp` original antes de substituir (ver BUILD.md).
