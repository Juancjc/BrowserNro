# Patches aplicados à engine em tempo de build

Estes patches **não vendoram** o código da engine (`chromium-nx`) — eles são
aplicados pelo `scripts/build.sh` com `sed` sobre o clone local em
`build/engine/` (ignorado pelo Git), nunca commitados como cópia do arquivo
inteiro. Isso mantém o repositório livre de código de terceiros de licença
indefinida (veja `LICENSING.md`), ao mesmo tempo em que documenta
exatamente qual mudança é feita e por quê.

## `0001-browsernro-dir.sh`

Troca o diretório fixo que a engine usa no cartão SD de
`sdmc:/switch/chromium-nx` para `sdmc:/switch/BrowserNro`, e o nome do
arquivo de log de `chromium-nx.log` para `BrowserNro.log`. Sem isso, mesmo
rebatizando o `.nacp` e o ícone, o app continuaria lendo/gravando em
`/switch/chromium-nx/` — o que contradiz a estrutura de instalação pedida
para o BrowserNro (`/switch/BrowserNro/`).

Afeta apenas `gx/host_nx.c` (a camada específica do Horizon OS); não toca em
nenhum arquivo usado pelo banco de testes de PC (`host_posix.c`), então pode
ser aplicado com segurança depois das etapas 1–6 de `BUILD.md` e antes da
etapa 8 (cross-build para o Switch).
