local x:number = 10;
local y:number = x++;

print(x, y);

x += 5;
print(x);

local t = {a: number = 1, b:string = "ok"};
print(t.a, t.b);

for i:integer = 1, 3 do
  print(i);
end

local function soma(a: number, b:number): number
  return a + b;
end

print(soma(2, 3));
