# Atalhos de conveniência para o pipeline do BrowserNro. Toda a lógica real
# vive em scripts/ (veja BUILD.md) — este Makefile só encadeia os passos.

.PHONY: all identity build rebrand package test clean distclean

all: build rebrand package test

identity:
	python3 assets/generate_identity.py

build:
	bash scripts/build.sh

rebrand:
	bash scripts/rebrand.sh

package:
	bash scripts/package.sh

test:
	python3 tests/validate_nro.py dist/BrowserNro.nro

# Remove apenas artefatos de build (mantém o clone da engine em build/engine/
# e o volume Docker lklwork, que são caros de refazer).
clean:
	rm -rf dist/*.nro dist/*.zip build/package-stage build/build.log

# Remove tudo, incluindo a engine clonada e os containers/volumes Docker.
distclean: clean
	rm -rf build/engine
	-docker rm -f lkl-gx lkl-gx-nx
	-docker volume rm lklwork
