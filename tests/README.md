# Testes do BrowserNro

Testes de verdade, executáveis, não simulações. Cada categoria abaixo diz
**o que roda, onde, e o que ainda depende de hardware real** — consistente
com [TESTING.md](../TESTING.md).

| Categoria pedida | Cobertura real hoje | Como rodar |
|---|---|---|
| Compilação | `scripts/build.sh` (pipeline completo) + `tests/validate_nro.py` (valida o binário resultante) | `bash scripts/build.sh && python3 tests/validate_nro.py dist/BrowserNro.nro` |
| Inicialização | Testes de PC da engine (`hello`, `threads`, `dl`, `timers`) sob `qemu-aarch64`, parte de `build-pc.sh` — exercitam o mesmo caminho de inicialização do LKL/gx usado pelo `.nro` | incluído automaticamente em `scripts/build.sh`, etapa 5; log em `build/build.log` |
| HTML / CSS | Página de teste embutida (`usr/share/gx/page.html`, da própria engine) renderizada pelo Chromium real dentro do `chromium.ext4`; validado via `build-chromium.sh` (modo `shot`/`browse`) | `docker exec lkl-gx bash /project/gx/build-chromium.sh shot` (gera `chromium.png`) |
| JavaScript | A mesma página de teste roda um trecho de JS (`[1,2,3].map(...)`) e seu resultado aparece no DOM capturado | mesmo comando acima; resultado no `chromium.png`/dump do DOM |
| HTTPS | Teste `curl-https` da engine (`curl -sS https://example.com/` através do NAT do `gx`) | incluído em `scripts/build.sh`, etapa 5 (requer internet no host de build) |
| Formulários | **Não automatizado** — depende de interação real com uma página com `<form>` em hardware ou em `build-chromium.sh browse` com um script de entrada | pendente — ver TESTING.md §4 |
| Cookies | **Não automatizado** — Chromium gerencia cookies nativamente (perfil em `profile.ext4`), mas não há um teste automatizado de persistência neste repositório ainda | pendente |
| Navegação (voltar/avançar/recarregar) | Mapeamento documentado em `source/input/controls.json`, comportamento nativo da engine (D-pad/A/B/X) | validação manual em hardware — TESTING.md §4 |
| Controles | `source/input/controls.json` documenta o mapeamento; a leitura de pad é nativa da engine (libnx `hidGetNpadStates*`, ver ARCHITECTURE.md) | validação manual em hardware — TESTING.md §4 |
| Armazenamento (LocalStorage/perfil) | O perfil do Chromium persiste em `profile.ext4` (ext4 real, montado pelo `gx`) — mecanismo herdado e não exercitado por um teste automatizado específico aqui | pendente |
| Estabilidade | Nenhuma medição de longa duração feita neste repositório | pendente — roteiro em TESTING.md §4 |

## Rodando o que já é automatizável

```bash
# Pipeline completo + testes de PC da engine (hello/threads/dl/timers/gles/net/curl):
bash scripts/build.sh

# Validação estrutural do .nro final:
python3 tests/validate_nro.py dist/BrowserNro.nro
```

## O que falta para fechar a tabela acima

Testes de formulários, cookies, navegação, controles e estabilidade exigem
ou (a) hardware real, ou (b) scripts de entrada automatizada contra
`build-chromium.sh browse <script> <url>` (a própria engine já tem esse
modo, documentado no README dela) — ainda não escritos neste repositório.
Contribuições bem-vindas; ver PROGRESS.md para o estado atual.
