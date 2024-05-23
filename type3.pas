program type2 (input, output);
type banana  = integer;
   laranja = integer;
var b : banana;
   l  :  laranja;
   x  : integer;
begin
   x := 10;
   l := x;
   b:=1;
   while b<=10 do
   begin
      l:=b;     (* Deve acusar erro aqui *) 
      x:=x+1;
      write (x);
      b:=b+1
   end
end.
