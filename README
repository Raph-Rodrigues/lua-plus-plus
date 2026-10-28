# Lua++

**Lua++** é um fork experimental do [Lua 5.5.1](https://www.lua.org/) que
adiciona recursos inspirados em linguagens como C, JavaScript e TypeScript:

- **ponto e vírgula obrigatório** no fim de comandos simples;
- **operadores compostos**: `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `^=`, `&=`,
  `|=`, `<<=`, `>>=`, `..=`;
- **`++`** como comando e como **expressão** (prefixo e posfixo);
- **tipagem opcional** (`x: number`, `function f(): string`) com checagem em
  tempo de execução via `OP_TYPECHECK`;
- anotações de tipo em **variáveis locais, parâmetros, retornos, upvalues,
  globais, variáveis de `for` e campos de tabela**;
- função `typeof`, que distingue `char` (string de 1 byte) de `string`.

O interpretador é instalado como **`lua++`**. O binário `lua` também é gerado a
partir das mesmas fontes, para compatibilidade de nome.

## Construir

Requisitos: `make` e um compilador C (GCC ou Clang).

```sh
make
./src/lua++ test_luaplusplus.lua
```

Binários gerados:

| Binário | Descrição |
|---|---|
| `src/lua++` | interpretador do Lua++ |
| `src/lua` | mesmo interpretador, nome compatível |
| `src/luac` | compilador de bytecode |

Para instalar em `/usr/local`:

```sh
sudo make install
```

## Instalar no Arch Linux (pacman)

Baixe o pacote `.pkg.tar.zst` mais recente na página de
[releases](https://github.com/Raph-Rodrigues/lua-plus-plus/releases) e instale:

```sh
sudo pacman -U lua++-5.5.1-1-x86_64.pkg.tar.zst
```

Ou compile o pacote localmente:

```sh
makepkg -si
```

O `PKGBUILD` também é publicado como asset de cada release.

## Uso

```sh
./src/lua++ programa.lua
./src/lua++ -e 'local x = 10; print(x++); print(x);'
./src/lua++ -v
# Lua++ 5.5.1  Copyright (C) 1994-2026 Lua.org, PUC-Rio
```

Exemplo:

```lua
local contador: number = 0;

local function incrementa(): number
  contador += 1;
  return contador;
end

for i: integer = 1, 3 do
  print(i, incrementa());
end

local antigo = contador++;
print(antigo, contador);
```

> **Atenção:** por causa do `;` obrigatório, código Lua comum precisa ser
> adaptado. Bytecode gerado pelo Lua 5.5 oficial não é compatível
> (`LUAC_FORMAT` foi alterado).

## Documentação

A referência completa está em [LUA++.md](LUA++.md), incluindo:

- regras de ponto e vírgula;
- semântica dos operadores compostos e de `++`;
- lista de tipos e onde as checagens acontecem;
- limitações e detalhes de implementação.

## Estrutura do projeto

```text
src/                 fontes do interpretador (Lua 5.5.1 + modificações)
LUA++.md             documentação do dialeto
test_luaplusplus.lua suíte de testes
PKGBUILD             receita do pacote Arch Linux
.github/workflows/   CI e automação de releases
```

## Releases automatizadas

Ao enviar uma tag `v*`, o GitHub Actions:

1. compila e executa a suíte de testes;
2. monta um container Arch Linux, gera o pacote `.pkg.tar.zst` com
   `makepkg` e executa a suíte de testes dentro do pacote;
3. publica uma release com o pacote, `PKGBUILD` e `.SRCINFO`.

```sh
git tag -a v5.5.1 -m "Lua++ 5.5.1"
git push origin v5.5.1
```

## Licença

MIT. Lua++ é derivado do Lua 5.5.1; veja [LICENSE](LICENSE).
