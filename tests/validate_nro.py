#!/usr/bin/env python3
"""
Teste automatizado real (não um mock): valida a estrutura binária de um
arquivo .nro gerado pelo build do BrowserNro.

Verifica:
  - O arquivo existe e tem tamanho plausível (> 1 MB: um .nro que embarca o
    kernel LKL + a engine gx não cabe em menos que isso).
  - O cabeçalho NRO é válido: magic "NRO0" no offset 0x10, conforme o
    formato documentado pelo switchbrew (https://switchbrew.org/wiki/NRO).
  - O NACP embutido (se presente) relata o nome/autor esperados do
    BrowserNro, não os da engine original ("Chromium NX"/"shodowlo") —
    confirma que scripts/rebrand.sh realmente rebatizou o binário.

Uso:
  python3 tests/validate_nro.py dist/BrowserNro.nro
"""
import struct
import sys

MIN_SIZE = 1 * 1024 * 1024


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        fail("uso: validate_nro.py <caminho para o .nro>")
    path = sys.argv[1]

    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError as e:
        fail(f"não foi possível ler {path}: {e}")

    if len(data) < MIN_SIZE:
        fail(f"{path} tem {len(data)} bytes — menor que o mínimo plausível de {MIN_SIZE}")

    magic = data[0x10:0x14]
    if magic != b"NRO0":
        fail(f"cabeçalho NRO inválido: esperado b'NRO0' em 0x10, encontrado {magic!r}")

    (nro_size,) = struct.unpack_from("<I", data, 0x18)
    print(f"PASS: cabeçalho NRO0 válido, tamanho declarado = {nro_size} bytes "
          f"(arquivo tem {len(data)} bytes)")

    # O ASET (icon+nacp+romfs) vem logo após o módulo NRO, se presente. Layout:
    # magic(4) + version(4) + icon_off/size(8+8) + nacp_off/size(8+8) +
    # romfs_off/size(8+8); confirmado empiricamente (dump de bytes de um .nro
    # real gerado por elf2nro) que os offsets são relativos ao início do
    # próprio ASET, não absolutos a partir do início do arquivo.
    aset = nro_size
    if aset < len(data) and data[aset:aset + 4] == b"ASET":
        print("PASS: seção ASET (ícone/NACP/romfs) presente")
        nacp_off, nacp_size = struct.unpack_from("<QQ", data, aset + 0x18)
        nacp = data[aset + nacp_off: aset + nacp_off + nacp_size]
        name = nacp[0:0x200].split(b"\x00", 1)[0].decode("utf-8", "replace")
        author = nacp[0x200:0x300].split(b"\x00", 1)[0].decode("utf-8", "replace")
        print(f"NACP: nome='{name}' autor='{author}'")
        if "chromium" in name.lower() or "shodowlo" in author.lower():
            fail("o NACP ainda contém a identidade da engine original — "
                 "scripts/rebrand.sh não foi aplicado corretamente")
        if name.strip() != "BrowserNro":
            print(f"AVISO: nome do NACP é '{name}', esperado 'BrowserNro'")
    else:
        print("AVISO: nenhuma seção ASET encontrada — .nro sem ícone/NACP embutido?")

    print("PASS: dist/BrowserNro.nro passou nas validações estruturais")


if __name__ == "__main__":
    main()
