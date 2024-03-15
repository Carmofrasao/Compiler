program funcao (input, output);
var  m: integer;
function f(n: integer; var k: integer): integer;
// var p, q: integer;
begin
    n := n + 1;
    k := k + 1;
    f := n + k;
end;
begin
    m := 1;
    while(m < 50) do
    begin
        write(f(1,m));
    end
end.
