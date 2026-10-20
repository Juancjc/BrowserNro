# Licenciamento — leia antes de publicar ou redistribuir binários

Este repositório mistura código original (BrowserNro) com a **engine de
navegação de terceiros** sobre a qual ele é construído. Os dois têm situações
de licença diferentes. Isso é importante para quem for publicar este
repositório ou distribuir um `.nro` compilado.

## Código original do BrowserNro

Tudo em `source/`, `scripts/`, `assets/`, `docs/` e a documentação deste
repositório (exceto onde indicado) é **MIT**, de autoria do projeto
BrowserNro. Veja [LICENSE](LICENSE).

## A engine (chromium-nx)

O motor de navegação real — o executor LKL + Chromium dentro de um `.nro`
("gx") — **não é código deste repositório**. Ele vem de
[`shodowlo/chromium-nx`](https://github.com/shodowlo/chromium-nx), clonado em
tempo de build por `scripts/build.sh` para `build/engine/` (ignorado pelo
Git — nunca é versionado aqui).

**Verificação feita em 2026-10-20 via GitHub API: o repositório
`shodowlo/chromium-nx` não declara nenhuma licença (`"license": null`).**
O mesmo vale para `mnnobre/lkl-switch`, o projeto do qual ele herda o núcleo
LKL↔Horizon.

O próprio README do chromium-nx afirma que:
- O kernel Linux (LKL) é **GPL-2.0** (herdado do kernel real).
- O código original do lkl-switch é **MIT, segundo o autor** (mas sem um
  arquivo `LICENSE` formal no repositório).
- O Chromium e seu logo pertencem à Chromium Authors/Google; o projeto não é
  afiliado a eles.
- O código novo do próprio chromium-nx (`gx/*.c`, `gx/*.S` — o executor de
  ELF, a ponte de syscalls, o compositor Wayland, o NAT, etc.) **não tem uma
  declaração de licença própria**, nem no README nem em um arquivo `LICENSE`.

Sem uma licença explícita, a posição legal padrão é "todos os direitos
reservados": o código é visível publicamente, mas isso não concede permissão
de redistribuição ou de uso em outro projeto.

## O que isso significa na prática para o BrowserNro

1. **Não vendoramos (não copiamos) o código do chromium-nx para dentro deste
   repositório.** `build/engine/` é clonado em tempo de build e está no
   `.gitignore`. O BrowserNro referencia a engine, não a redistribui como
   código-fonte.
2. **Não publicamos binários (`.nro`/`.nsp`/`.zip`) compilados a partir dela
   neste repositório Git.** `dist/*.nro`, `dist/*.zip` etc. estão no
   `.gitignore` por este motivo. Um binário compilado a partir de código sem
   licença ainda é uma obra derivada da engine; distribuí-lo publicamente sem
   autorização do autor original seria uma violação de direitos autorais,
   mesmo que o nosso próprio código de empacotamento seja MIT.
3. **Compilar localmente para uso pessoal é diferente de redistribuir.**
   Seguindo `BUILD.md`, qualquer pessoa pode clonar a engine original
   diretamente do GitHub do autor (nos mesmos termos — ou falta de termos —
   que ele publicou) e compilar seu próprio `.nro` para seu próprio console.
   Isso é o modelo padrão de "construa a partir do código-fonte" usado em
   diversos projetos homebrew que dependem de componentes de licença incerta.
4. **Antes de publicar releases binárias do BrowserNro no GitHub**,
   recomendamos:
   - Abrir uma issue ou contato direto com **shodowlo** pedindo
     esclarecimento/autorização de licença para `chromium-nx`;
   - Se ele adicionar uma licença permissiva (MIT/BSD/Apache), atualizar este
     arquivo e então sim publicar binários/releases;
   - Até lá, manter o GitHub público apenas com código-fonte, scripts de
     build e documentação — não com `.nro` pré-compilado.

## Outras referências pesquisadas

| Repositório | Licença (API GitHub) | Uso neste projeto |
|---|---|---|
| `shodowlo/chromium-nx` | nenhuma declarada | engine principal, referenciada (não vendorada) |
| `mnnobre/lkl-switch` | nenhuma declarada | ancestral do gx; mesma situação |
| `lkl/linux` | GPL-2.0 (kernel Linux) | clonado como dependência de build, GPL de verdade |
| `switchbrew/libnx` | zlib | toolkit padrão de homebrew, sem restrição |
| `switchbrew/nx-hbloader` | — (verificar antes de redistribuir binário) | usado só se `build-hbl.sh` for executado |
| `etonedemid/netsurf-switch` | ver licença própria do NetSurf (MIT) | estudado como alternativa, não usado no motor principal |
| `natureglass/Brewser` | ver repositório | estudado como referência de UI/WebKit |
| `crc-32/BrowseNX` | ver repositório | estudado como referência |

Esta tabela foi preenchida a partir de consultas automatizadas à API pública
do GitHub e da leitura dos READMEs; não substitui uma análise jurídica
formal.
