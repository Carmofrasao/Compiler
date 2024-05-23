program type2 (input, output);
type banana = integer;
var b : banana;
   x  : integer;
begin
   x := 1;
   b:=1;
   while b<=10 do
   begin
      if (x <= b) then
         x:=x+1;
      write(x);
      b:=b+1
   end
end.
