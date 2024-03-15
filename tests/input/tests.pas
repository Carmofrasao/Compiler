program funcao (input, output);
var x : integer;
function f(a : integer; var b: integer) : integer;
var y : integer;
begin
   y := a + b;
   b := a + 1;
   write(a, b);
   f := y;
end;
function g(k : integer; var j: integer) : integer;
var z : integer;
begin
   z := k - j;
   j := k - 1;
   write(k, j);
   g := z;
end;

begin
   x := 1;
   write(g(g(f(f(g(f(g(1, x), x), x), x), x), x), x));
   write(x);
end.

// g(1, 1)
// g = 1-1 = 0
// x = 1-1 = 0
// write(0, 0) return 0

// f(0, 0)
// f = 0+0 = 0
// x = 0+1 = 1
// write(0, 1) return 0

// g(0, 1)
// 
