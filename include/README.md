# include/

Reservado para headers C/C++ próprios do BrowserNro, caso uma camada nativa
adicional (ex.: uma UI de configurações/favoritos compilada contra libnx,
fora da engine) venha a ser desenvolvida — ver os itens pendentes em
[`PROGRESS.md`](../PROGRESS.md) e [`KNOWN_ISSUES.md`](../KNOWN_ISSUES.md).

Os headers da engine (`gx/*.h`) vivem em `build/engine/` (buscados em tempo
de build, não vendorados — veja `third_party/README.md` e
`LICENSING.md`) e não são duplicados aqui.
