# source/

Este diretório **não contém o motor de navegação** (ele vem da engine de
terceiros, buscada em tempo de build — veja `third_party/README.md` e
`LICENSING.md`). Contém a camada de configuração e identidade própria do
BrowserNro, consumida pelos scripts em `scripts/`:

- `config/homepage.json` — página inicial padrão; usado por
  `scripts/package.sh` para gerar o `programs.txt` que a engine lê.
- `config/bookmarks.json` — favoritos sugeridos no primeiro uso.
  `scripts/package.sh` transforma cada um num atalho real no menu que a
  própria engine mostra ao abrir o BrowserNro (um item por favorito, além
  da página inicial) — não é uma UI de favoritos dentro do navegador em si
  (isso ainda não existe — ver KNOWN_ISSUES.md), mas já funciona como
  "lançador rápido" de páginas.
- `input/controls.json` — mapeamento de controles do BrowserNro, documentando
  o que já é nativo da engine e o que é extensão planejada (ver
  ARCHITECTURE.md § Entrada).
- `l10n/pt-BR.json` — strings em português reservadas para uma futura UI
  nativa de configurações (ainda não renderizada dentro do navegador).

Por que não há `.c`/`.cpp` aqui: a engine (`gx`) já implementa tudo que um
executável nativo faria (loop principal, entrada, janela, rede). O único
código-fonte que o BrowserNro modifica é um patch de uma linha aplicado em
tempo de build (`patches/0001-browsernro-dir.sh`) — não duplicado aqui para
não vendorar código de licença indefinida.
