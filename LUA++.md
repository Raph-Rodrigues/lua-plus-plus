# Lua++

Dialeto experimental construído sobre o **Lua 5.5.1** (pasta `src/`).

Mudanças implementadas:

1. **Ponto e vírgula obrigatório** no fim de comandos simples.
2. **Operadores compostos**: `+= -= *= /= //= %= ^= &= |= <<= >>= ..=`
3. **Incremento**: `++` (prefixo e posfixo, como comando **e como expressão**).
4. **Tipagem**: anotações de tipo com **checagem em tempo de execução** e erros de
   compilação para literais incompatíveis; anotações em variáveis de `for`,
   campos de tabela, parâmetros, retornos, upvalues e globais.

---

## Compilar e testar

```sh
make
./src/lua++ test_luaplusplus.lua     # suíte de testes do Lua++
```

Os binários ficam em `src/lua++` (interpretador do fork), `src/lua`
(mesmo interpretador, nome compatível com o Lua) e `src/luac` (compilador).
`make clean` remove todos.

### Instalação no Arch Linux

O projeto é publicado em
<https://github.com/Raph-Rodrigues/lua-plus-plus>, com releases automáticas
contendo o pacote `.pkg.tar.zst`, o `PKGBUILD` e o `SRCINFO`:

```sh
sudo pacman -U lua++-5.5.1-1-x86_64.pkg.tar.zst
```

Para compilar o pacote localmente:

```sh
makepkg -si
```

---

## 1. Ponto e vírgula obrigatório

Em Lua++ todo comando simples precisa terminar com `;`:

```lua
local x = 1;
x = x + 1;
print(x);            -- 2
return x;            -- o ';' é obrigatório
```

A regra segue o estilo de C/JavaScript:

| Comando | Precisa de `;`? |
|---------|-----------------|
| `local x = 1`, `x = 2`, chamada de função | sim |
| `return`, `break`, `goto`, `global nome` | sim |
| `if ... end`, `while ... end`, `for ... end`, `do ... end` | não (já terminam em `end`) |
| `repeat ... until cond` | não |
| `function f() ... end`, `local function f() ... end` | não |
| rótulo `::nome::` | não |
| `;` sozinho (comando vazio) | — |

```lua
if x > 0 then
  x += 1;            -- comandos internos continuam precisando de ';'
end                  -- 'end' já termina o 'if'

local function soma(a, b)
  return a + b;      -- 'return' exige ';'
end
```

O erro é detectado na compilação:

```
lua: arquivo.lua:1: ';' expected at end of statement near 'x'
```

`;` extras continuam permitidos (`if ... end;`), pois são comandos vazios.

---

## 2. Operadores compostos

| Operador | Equivalente |
|----------|-------------|
| `x += e`  | `x = x + e`  |
| `x -= e`  | `x = x - e`  |
| `x *= e`  | `x = x * e`  |
| `x /= e`  | `x = x / e`  |
| `x //= e` | `x = x // e` |
| `x %= e`  | `x = x % e`  |
| `x ^= e`  | `x = x ^ e`  |
| `x &= e`  | `x = x & e`  |
| `x \|= e` | `x = x \| e` |
| `x <<= e` | `x = x << e` |
| `x >>= e` | `x = x >> e` |
| `x ..= e` | `x = x .. e` |

Funciona com locais, globais, upvalues, campos de tabela e índices:

```lua
n += 10;
t.count *= 2;
t[key] -= 1;
obj.field ..= "!";
```

O lado esquerdo é avaliado **uma única vez** (tabela e índice não são
reavaliados), e o valor antigo é lido uma única vez:

```lua
local calls = 0;
local function idx() calls += 1; return 1; end
local a = { 10 };
a[idx()] += 5;
print(a[1], calls)   --> 15  1
```

Semântica: `t[i] += e` equivale a
`local tmp, k = t, i; tmp[k] = tmp[k] + e`, com `e` avaliado depois da leitura.
Metamétodos (`__add`, `__concat`, ...) são respeitados.

Restrições: apenas **um** alvo por comando (`a, b += 1` é erro) e o operador
composto só vale como comando (não é uma expressão).

---

## 3. Incremento (`++`)

```lua
local i = 0;
i++;      -- posfixo, como comando
++i;      -- prefixo, como comando
t.n++;    -- campo de tabela
```

`x++` e `++x` são equivalentes quando usados como **comando**; ambos somam 1.

Como **expressão**, o valor produzido difere:

* `x++` (posfixo) devolve o valor **antigo** e depois incrementa;
* `++x` (prefixo) incrementa e devolve o valor **novo**.

```lua
local x = 10;
local y = x++;       -- y = 10, x = 11
local z = ++x;       -- z = 12, x = 12
local p, q = x++, x++;   -- p = 12, q = 13, x = 14
print(("valor=%d"):format(x++));  -- imprime 14, x passa a 15
```

Funciona com locais, upvalues, globais, campos e índices:

```lua
local old = obj.count++;
local first = t[i++]++;
global g: number = 1;
local before = g++;
```

> **`--` continua sendo comentário.** Por isso não existe operador `--` de
> decremento. Use `x -= 1` (e `x += 1` se preferir simetria).
>
> Consequência da gramática: `f()` seguido de `++x` na linha seguinte é lido
> como duas instruções — a chamada e depois o incremento prefixo.

---

## 4. Tipagem

### Sintaxe

```lua
local x: number = 10;
local a: number, b: string = 1, "texto";

local function soma(a: number, b: number): number
  return a + b;
end

function obj:metodo(n: integer): integer
  self.total += n;
  return self.total;
end

global contador: number = 0;

-- variáveis de laço
for i: integer = 1, 10 do
  print(i);
end
for k: string, v: number in pairs(t) do
  print(k, v);
end

-- campos de construtor de tabela
local ponto = { x: number = 1, y: number = 2.5 };
local registro = { ["nome"]: string = "Ana", idade: integer = 30 };
```

A anotação é opcional em cada variável/parâmetro. O tipo de retorno vem depois
do `)` da lista de parâmetros.

A anotação de campo (`{ x: number = 1 }`) vale **apenas para aquele campo
naquele construtor**: ela não cria um tipo para a tabela nem passa a checar
atribuições posteriores como `ponto.x = "texto"`. Use a anotação de campo para
documentar e validar o valor inicial.

### Tipos disponíveis

| Tipo       | Significado em runtime |
|------------|------------------------|
| `any`      | qualquer valor (sem checagem) |
| `nil`      | somente `nil` |
| `boolean`  | `true` / `false` |
| `number`   | inteiro ou float |
| `integer`  | somente inteiro (subtipo de `number`) |
| `string`   | qualquer string |
| `char`     | string com exatamente 1 byte |
| `table`    | tabela |
| `function` | função |
| `thread`   | corrotina |
| `userdata` | userdata (completo ou leve) |

`char` é um refinamento de `string`: todo `char` é aceito por uma variável
`string`, mas o contrário não. `typeof` reporta `"char"` para strings de 1 byte:

```lua
typeof("x")   --> "char"
typeof("xy")  --> "string"
typeof(1)     --> "number"
typeof({})    --> "table"
```

`typeof` foi adicionado à biblioteca básica; `type` continua com o
comportamento original do Lua.

Nenhum tipo novo virou palavra reservada: `table`, `string`, `number`, `char`
etc. continuam podendo ser usados como identificadores. A anotação é
reconhecida apenas na posição `nome: tipo`.

### Onde a checagem acontece

**Em tempo de execução** (novo opcode `OP_TYPECHECK`):

* inicialização de local/global anotado que recebe valor;
* atribuição a local, upvalue ou global declarado com tipo (`x = ...`);
* **atribuições múltiplas**: cada alvo anotado é checado, inclusive os que
  recebem `nil` por falta de expressões (`local a: number, b: string = 1;`
  falha porque `b` recebe `nil`);
* variáveis de `for` anotadas, a cada iteração;
* campos anotados em construtores de tabela;
* parâmetros, na entrada da função;
* valor de retorno (quando a função declara o tipo de retorno);
* resultado de `++`: o valor incrementado é checado contra o tipo declarado da
  variável, e o resultado de uma atribuição composta (`x += ...`) também;

**Em tempo de compilação** (mensagens `luac`):

* literal incompatível: `local x: number = "não";` / `x = "não";`;
* literal incompatível em campo de tabela: `{ x: number = "não" }`;
* tipo de retorno literal incompatível: `function f(): number return "x" end`;
* `return` sem valor em função declarada para retornar algo diferente de `nil`;
* nome de tipo desconhecido: `local x: foo = 1;`.

```lua
local function pegaString() return "abc"; end

local ok, err = pcall(function()
  local x: number = pegaString();   -- erro em runtime
end);
print(ok, err);
--> false   arquivo.lua:4: type mismatch: expected 'number', got 'string'
```

### Limitações atuais

* Sem análise estática além de literais (não há inferência de tipos).
* `local x: T` sem inicializador não é checado até receber o primeiro valor.
* Em `return`, apenas o **primeiro** valor é checado; se a expressão for uma
  chamada com múltiplos retornos, a otimização de *tail call* é desativada
  para permitir a checagem.
* As anotações em si não são guardadas no bytecode para introspecção; o que
  fica gravado são as checagens já emitidas (`OP_TYPECHECK`).

---

## 5. Compatibilidade com Lua 5.5

* Comentários `--` e `--[[ ... ]]` inalterados.
* `//` continua sendo divisão inteira; `//=` é o novo operador composto.
* Nenhuma palavra reservada nova (inclusive `global` do Lua 5.5 continua igual).
* Código Lua comum continua compilando e executando **desde que os comandos
  simples terminem com `;`**.
* `LUAC_FORMAT` foi alterado para `1` em `src/lundump.h`, porque a numeração dos
  opcodes mudou: bytecode pré-compilado pelo Lua 5.5 oficial é rejeitado (e
  vice-versa). Sempre recompile os `.luac`.

---

## Arquivos alterados

| Arquivo | Mudança |
|---------|---------|
| `src/llex.h`, `src/llex.c` | tokens `++`, `+=`, `-=`, `*=`, `/=`, `//=`, `%=`, `^=`, `&=`, `\|=`, `<<=`, `>>=`, `..=` |
| `src/lparser.h` | enum `LPPType`, campos `vtype` em `Vardesc`, `expdesc` e `FuncState.rettype` |
| `src/lparser.c` | parser das anotações, checagens, `++` (comando e expressão), atribuições compostas e `;` obrigatório |
| `src/lobject.h` | campo `vtype` em `Upvaldesc` |
| `src/lcode.h`, `src/lcode.c` | exportação de `luaK_stringK`, `luaK_storevarreg`, propagação de `vtype` |
| `src/lopcodes.h`, `src/lopcodes.c`, `src/lopnames.h`, `src/ljumptab.h` | opcode `OP_TYPECHECK` |
| `src/lvm.c` | execução de `OP_TYPECHECK` e comparação de tipos |
| `src/luac.c` | listagem do novo opcode |
| `src/lbaselib.c` | função global `typeof` |
| `src/lundump.h` | `LUAC_FORMAT` = 1 |
| `src/lundump.c` | inicialização de `vtype` ao carregar bytecode |
| `src/lua.c` | identificação do fork (`Lua++ 5.5.1`) quando invocado como `lua++` |
| `src/Makefile`, `Makefile` | novo alvo/binário `lua++` (e instalação via `TO_BIN`) |
| `test_luaplusplus.lua` | suíte de testes |
