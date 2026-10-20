# Testes do BrowserNro

Este documento registra **o que foi de fato executado e verificado** neste
projeto, distinguindo claramente de resultados herdados (reportados pelo
autor da engine, não reproduzidos por nós) e de testes ainda pendentes.
Nenhuma linha aqui afirma um teste que não foi executado.

## 1. O que foi testado neste repositório

| Teste | Ambiente | Resultado | Como reproduzir |
|---|---|---|---|
| Clone e build da imagem Docker `lkl-gx` | WSL2 Ubuntu + Docker Desktop 29.3.1 (integração WSL2) | ✅ PASS — `chromium-shell:arm64 155.0.8059.79-1~deb12u1` e `chromium-headless-shell:arm64` instalados com sucesso | `bash scripts/build.sh` |
| Build do kernel LKL (cross aarch64-linux-gnu) | container `lkl-gx` | ✅ PASS — `tools/lkl/liblkl.a` gerado (240.325.076 bytes) | etapa 4 de BUILD.md |
| `hello` (teste de PC, qemu-aarch64) | container `lkl-gx` | ✅ PASS | etapa 5 |
| `threads` (teste de PC, qemu-aarch64) | container `lkl-gx` | ✅ PASS | etapa 5 |
| `dl` (teste de PC, qemu-aarch64) | container `lkl-gx` | ✅ PASS | etapa 5 |
| `timers` (teste de PC, qemu-aarch64) | container `lkl-gx` | ✅ PASS | etapa 5 |
| `gles` (teste de PC, qemu-aarch64 + Mesa arm64) | container `lkl-gx` | ✅ PASS | etapa 5 |
| `net` (teste de PC, qemu-aarch64) | container `lkl-gx` | ✅ PASS | etapa 5 |
| `curl-http` (`curl http://example.com/` através do NAT do gx) | container `lkl-gx` | ✅ PASS | etapa 5 |
| `curl-https` (`curl https://example.com/` através do NAT do gx) | container `lkl-gx` | ✅ PASS | etapa 5 |
| Renderização real de página pelo Chromium (`build-chromium.sh`, modo `browse`) | container `lkl-gx`, qemu-aarch64 | ✅ PASS — a página de teste (`gx page`, com um `<script>` que gera `[1,2,3].map(x=>x*x)`) foi carregada e seu JS executou de verdade: o DOM capturado mostra `<p id="js">JS: 1,4,9</p>` | etapa 6 de BUILD.md |
| Montagem da imagem `chromium-switch.ext4` a partir do `chromium-shell` arm64 da Debian | container `lkl-gx` | ✅ PASS — `chromium.ext4` gerado (344.981.504 bytes) | etapa 6 de BUILD.md |
| Cross-build do kernel + `gx` para o Switch (devkitA64) | container `lkl-gx-nx` | ✅ PASS — `chromium-nx.nro` gerado (26.465.758 bytes) | etapa 8 de BUILD.md |
| Build do Homebrew Loader de 39 bits | container `lkl-gx-nx` | ✅ PASS — `hbl.nsp` gerado (40.956 bytes) | etapa 9 de BUILD.md |
| Rebatismo de NACP/ícone (`BrowserNro.nro`) | script local (`scripts/rebrand.sh`) | ✅ PASS — `BrowserNro.nro` gerado (26.472.450 bytes) | `scripts/rebrand.sh` |
| Validação estrutural do `.nro` (`tests/validate_nro.py`) | host (Windows, Python 3.12) | ✅ PASS — cabeçalho `NRO0` válido, seção `ASET` presente, **NACP confirma nome='BrowserNro' autor='BrowserNro'** (não mais "Chromium NX"/"shodowlo") | `python3 tests/validate_nro.py dist/BrowserNro.nro` |
| Empacotamento (`scripts/package.sh`) | host | ✅ PASS — `dist/BrowserNro.zip` gerado (150.010.710 bytes) com a estrutura `/switch/BrowserNro/` completa (nro, chromium.ext4, assets, config, cache/downloads/data/logs com placeholders, programs.txt apontando para `https://www.google.com/`) e o Homebrew Loader opcional isolado em `ATMOSPHERE-HBL-OPCIONAL-LEIA-ANTES/` | `scripts/package.sh` |

**Build completo realizado em 20/10/2026**, ambiente: Windows 11 + WSL2
(Ubuntu) + Docker Desktop 29.3.1, commit do chromium-nx
`876daa96a0c0476df15dfa1e3caabbc477630b87`. Log completo em
`build/build.log`.

Os 8 testes de PC acima são os **próprios testes automatizados do
chromium-nx** (não escritos por nós), executados de verdade nesta sessão em
20/10/2026 — log completo da execução em `build/build.log`. Eles confirmam
que o executor de ELF, a ponte de syscalls LKL, a rede (incluindo HTTPS via
`curl-https`) e a renderização GLES funcionam corretamente no ambiente de
build, **antes mesmo de chegar ao hardware do Switch**.

## 2. O que NÃO foi testado por este projeto

- **Hardware real (um Nintendo Switch V1 físico).** Nenhum teste deste
  projeto rodou em um console físico. Tudo até aqui é build + testes em PC
  sob `qemu-aarch64`, que é o próprio banco de testes do chromium-nx para
  desenvolvimento sem tocar hardware.
- Estabilidade em sessões longas de navegação.
- Comportamento em Wi-Fi de diferentes roteadores/redes corporativas com
  proxy ou autenticação.
- Compatibilidade ampla de sites além dos já citados pelo autor da engine
  (Google, Wikipedia, YouTube).
- Múltiplas abas (não há evidência de que a engine suporte isso hoje — ver
  KNOWN_ISSUES.md).
- Download/upload de arquivos de ponta a ponta no console.
- Consumo de memória/RAM real em Application Mode vs. Applet Mode no
  console físico.

## 3. Resultados herdados (reportados pelo autor da engine, não
   reproduzidos por nós)

O README do `chromium-nx` declara, sobre testes no console físico dele:

> Google, Wikipedia e YouTube load and are usable; YouTube videos play but
> sometimes crash. GPU rendering and the JIT [work]. Touch, scrolling, text
> entry with the system keyboard, d-pad focus [work].

Isso é **citado, não verificado por este projeto**. Até que o BrowserNro
seja testado em hardware próprio, trate essas afirmações como prováveis
(a engine é a mesma, sem modificação funcional), mas não confirmadas por
nós.

## 4. Roteiro de teste em hardware real (a ser executado)

Quando houver um Switch V1 desbloqueado disponível para teste:

1. Gravar `dist/BrowserNro.zip` no cartão SD conforme README.md.
2. Abrir o Homebrew Menu em **Application Mode** (segurando R).
3. Iniciar o BrowserNro e verificar:
   - [ ] O app inicia sem crash e mostra uma página (padrão: página de
     teste local, depois página inicial configurada).
   - [ ] Carregar `https://www.wikipedia.org/` com sucesso.
   - [ ] Carregar `https://www.google.com/` e realizar uma busca.
   - [ ] Tocar na tela foca um campo de texto e abre o teclado do sistema.
   - [ ] D-pad move o foco entre links; A segue o link.
   - [ ] B volta, X recarrega.
   - [ ] Y abre a barra de endereço.
   - [ ] Analógicos rolam a página.
   - [ ] Áudio toca em uma página com `<audio>`/`<video>`.
   - [ ] Um vídeo do YouTube reproduz (mesmo que trave eventualmente, como
     relatado pelo autor da engine — registrar aqui o comportamento real).
   - [ ] Medir RAM/estabilidade após 10, 30 e 60 minutos de uso contínuo.
4. Preencher os resultados nesta seção com data, build (hash do commit) e
   observações — substituindo as checkboxes por ✅/❌ e uma nota.

## 5. Ambiente de CI (GitHub Actions)

Veja `.github/workflows/build.yml`. O CI tenta reproduzir o build completo
(steps 1–9 de BUILD.md) em runners Linux hospedados — ele valida que o
pipeline de build não quebrou, mas **não substitui teste em hardware real**,
já que runners de CI não têm um Nintendo Switch nem GPU Tegra X1.
