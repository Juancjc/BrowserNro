# third_party/

Propositalmente vazio no controle de versão.

A engine real do BrowserNro ([chromium-nx](https://github.com/shodowlo/chromium-nx)
e suas dependências — LKL, Chromium arm64 da Debian) **não é vendorada
neste repositório**. Ela é buscada em tempo de build para `build/engine/`
(gitignored) por `scripts/build.sh`.

Motivo: `chromium-nx` e `lkl-switch` não declaram licença no GitHub — veja
[`LICENSING.md`](../LICENSING.md) na raiz do repositório antes de mudar essa
decisão (por exemplo, para vendorar código aqui de verdade).

Este diretório existe para manter a estrutura de projeto padrão e para
receber, no futuro, qualquer dependência de terceiros que **tenha** uma
licença compatível e vença a análise de `LICENSING.md`.
