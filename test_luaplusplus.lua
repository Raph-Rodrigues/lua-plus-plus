-- Testes do Lua++ (execute com: ./src/lua++ test_luaplusplus.lua)

local function checkcompile(src, expected)
  local f, err = load(src);
  assert(f == nil, "deveria falhar na compilacao: " .. src);
  assert(err and err:find(expected, 1, true),
         ("mensagem inesperada: %s"):format(tostring(err)));
end

local function checkok(src)
  local f, err = load(src);
  assert(f ~= nil, "deveria compilar: " .. src .. " (" .. tostring(err) .. ")");
  return f;
end

--==========================================================================
-- 1. Ponto e virgula obrigatorio no fim de comandos
--==========================================================================
local a = 1;
a = a + 1;
assert(a == 2);
do ; end;
for i = 1, 3 do ; end;
if a == 2 then a = 3; end;
local function retsemi() return 1, 2; end;
assert(select("#", retsemi()) == 2);

-- sem ponto e virgula: erro
checkcompile("local x = 1", "';' expected");
checkcompile("x = 2", "';' expected");
checkcompile("return 1", "';' expected");
checkcompile("print(1)", "';' expected");
checkcompile("while true do break end", "';' expected");
checkcompile("do goto x end", "';' expected");
checkcompile("for i = 1, 2 do print(i) end", "';' expected");
-- comandos compostos nao precisam de ';' depois de 'end'
checkok("if true then local x = 1; end");
checkok("while false do local x = 1; end");
checkok("repeat local x = 1; until true");
checkok("do local x = 1; end");

--==========================================================================
-- 2. Operadores compostos
--==========================================================================
local n = 10;
n += 5;  assert(n == 15);
n -= 3;  assert(n == 12);
n *= 2;  assert(n == 24);
n /= 4;  assert(n == 6);
n //= 2; assert(n == 3);
n %= 2;  assert(n == 1);
n ^= 3;  assert(n == 1);
n = 6; n &= 3; assert(n == 2);
n |= 4;  assert(n == 6);
n <<= 1; assert(n == 12);
n >>= 2; assert(n == 3);
local str = "a"; str ..= "b"; assert(str == "ab");

-- campos de tabela, globais e upvalues
local t = { v = 1, [2] = 10 };
t.v += 4;  assert(t.v == 5);
t[2] *= 3; assert(t[2] == 30);
t.v++;     assert(t.v == 6);

local up = 0;
local function bumpup() up += 5; return up; end;
assert(bumpup() == 5 and up == 5);

-- a expressao do lado esquerdo e' avaliada uma unica vez
local calls = 0;
local function idx() calls += 1; return 1; end;
local arr = { 10 };
arr[idx()] += 5;
assert(arr[1] == 15 and calls == 1);

--==========================================================================
-- 3. Incremento (++)
--==========================================================================
local i = 0;
i++;   assert(i == 1);
++i;   assert(i == 2);
t.v++; assert(t.v == 7);
++t.v; assert(t.v == 8);

-- agora '++' tambem e' expressao
local x = 10;
local y = x++;
assert(y == 10 and x == 11);
local z = ++x;
assert(z == 12 and x == 12);
local p, q = x++, x++;
assert(p == 12 and q == 13 and x == 14);
local function twice(v) return v * 2; end;
assert(twice(x++) == 28 and x == 15);
assert(twice(++x) == 32 and x == 16);

-- postfix em campos e upvalues
local obj2 = { n = 3 };
local old = obj2.n++;
assert(old == 3 and obj2.n == 4);
local function counter()
  local c = 0;
  return function() return c++; end;
end
local c1 = counter();
assert(c1() == 0 and c1() == 1 and c1() == 2);

-- '--' continua sendo comentario (nao existe decremento '--')
local keep = 1;
keep = keep; -- este e' um comentario
assert(keep == 1);

--==========================================================================
-- 4. Tipagem: anotacoes + checagem em runtime
--==========================================================================
local num: number = 1;
local int: integer = 2;
local txt: string = "abc";
local ch: char = "z";
local boo: boolean = false;
local tab: table = {};
local fn: function = assert;
local co: thread = coroutine.create(function() end);
local ud: userdata = io.stdout;
local ni: nil = nil;
local anyv: any = "livre";

assert(typeof(num) == "number");
assert(typeof(int) == "number");
assert(typeof(txt) == "string");
assert(typeof(ch) == "char");
assert(typeof(boo) == "boolean");
assert(typeof(tab) == "table");
assert(typeof(fn) == "function");
assert(typeof(co) == "thread");
assert(typeof(ud) == "userdata");
assert(typeof(ni) == "nil");
assert(typeof(anyv) == "string");

-- parametros e retorno tipados
local function add(x: number, y: number): number
  return x + y;
end
assert(add(2, 3) == 5);

-- metodo (self + anotacoes)
local obj = { v = 0 };
function obj:inc(k: number): number
  self.v += k;
  return self.v;
end
assert(obj:inc(3) == 3);
assert(obj:inc(4) == 7);

-- atribuicao a local anotado
local typed: number = 1;
typed = 2;
typed = 3.5;
assert(typed == 3.5);

-- declaracao sem inicializador: so' e' checada quando receber valor
local later: number;
assert(later == nil);
later = 10;
assert(later == 10);

--==========================================================================
-- 5. Checagem de tipos em atribuicoes (upvalues, globais, multiplas)
--==========================================================================
local function retstr() return "oops"; end;
local retnum = function() return 42; end;

-- upvalue
local uv: number = 1;
local function setuvbad() uv = retstr(); end;
assert(not pcall(setuvbad));
local function setuvok() uv = retnum(); return uv; end;
assert(setuvok() == 42);

-- upvalue encadeado (dois niveis)
local function outer()
  local s: string = "a";
  local function inner()
    local function deep()
      s = retnum();
    end
    return deep;
  end
  return inner();
end
assert(not pcall(outer()));

-- globais tipados
local gchunk = assert(load([[
  global gnum: number = 10;
  global gstr: string = "ok";
  return gnum, gstr;
]]));
local g1, g2 = gchunk();
assert(g1 == 10 and g2 == "ok");
checkcompile("global g: number = 'bad'", "declared as 'number'");

local gchunk2 = assert(load([[
  global *;
  global gn: number = 1;
  local function bad() gn = "x" .. "y"; end;
  return bad;
]]));
local gbad = gchunk2();
assert(not pcall(gbad));

-- atribuicao multipla
local ma: number, mb: string = 1, "x";
assert(ma == 1 and mb == "x");
local function mbad() ma, mb = retstr(), retstr(); end;
assert(not pcall(mbad));
local function mbad2() ma, mb = retnum(), retnum(); end;
assert(not pcall(mbad2));
local function mok() ma, mb = retnum(), "y"; end;
assert(pcall(mok) and ma == 42 and mb == "y");

--==========================================================================
-- 6. Anotacoes em variaveis de 'for'
--==========================================================================
local function gen(_, k)
  k = k + 1;
  if k > 2 then return nil; end;
  return k, k * 10;
end
local seen = 0;
for k: number, v: number in gen, nil, 0 do
  seen += 1;
  assert(typeof(k) == "number" and typeof(v) == "number");
end
assert(seen == 2);

for i: integer = 1, 3 do
  assert(math.type(i) == "integer");
end
for i: number = 1, 2, 0.5 do
  assert(typeof(i) == "number");
end
local function badfor()
  for i: string = 1, 2 do print(i); end
end
assert(not pcall(badfor));
local function badforlist()
  for k: string, v: number in ipairs({ 1, 2 }) do print(k, v); end
end
assert(not pcall(badforlist));

--==========================================================================
-- 7. Anotacoes em campos de tabela
--==========================================================================
local pt = { x: number = 1, y: number = 2.5 };
assert(pt.x == 1 and pt.y == 2.5);
local kt = { ["k"]: string = "v" };
assert(kt.k == "v");
local nested = { inner: table = { a = 1 } };
assert(nested.inner.a == 1);
local it = { [1]: number = 10 };
assert(it[1] == 10);

local function makebad() return { x: number = retstr() }; end;
assert(not pcall(makebad));
checkcompile("local t = { x: number = 'no' }", "table field declared");
checkcompile("local t = { x: char = 'ab' }", "table field declared");

--==========================================================================
-- 8. Erros de compilacao (literais e anotacoes invalidas)
--==========================================================================
checkcompile("local x: number = 'no'", "declared as 'number'");
checkcompile("local x: foo = 1", "unknown type 'foo'");
checkcompile("local c: char = 'ab'", "declared as 'char'");
checkcompile("local x: number; x = 'no'", "assigned a value of type");
checkcompile("function f(): number return end", "returns no value");
checkcompile("function f(): number return 'x' end", "declared to return");
checkcompile("local f: function = 1", "declared as 'function'");
checkcompile("local v: nil = false", "declared as 'nil'");

--==========================================================================
-- 9. Erros em runtime (valores vindos de funcoes)
--==========================================================================
assert(not pcall(function() local v: number = retstr(); end));
assert(not pcall(function() local v: char = "ab" .. "c"; end));
assert(not pcall(function() local v: number = 1; v = retstr(); end));
assert(not pcall(function(): number return retstr(); end));
assert(not pcall(add, 1, "dois"));
assert(not pcall(function() local v: char = "a"; v = "ab" .. "c"; end));

--==========================================================================
-- 10. bytecode: dump/load preserva a checagem de tipos
--==========================================================================
local src = "local x: number = 1; x += 1; local y = x++; return x, y;";
local f = assert(load(src));
local g = assert(load(string.dump(f)));
local rx, ry = g();
assert(rx == 3 and ry == 2);

print("Lua++: todos os testes passaram");
