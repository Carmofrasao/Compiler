program StressTest(input, output);

var
  x, y, z: integer;
  flag: boolean;

procedure WithoutParameters;
begin
  write(0);
end;

procedure WithParameters(a, b: integer);
begin
  write((a + b) div 30);
end;

procedure NestedProcedure;  
  procedure InnerProcedure;
  begin
    write(3);
  end;
begin
  write(2);
  
  InnerProcedure;
end;

begin
  x := 10;
  y := 20;
  z := 0;
  flag := true;

  WithoutParameters;
  WithParameters(1+x-1, y);
  
  NestedProcedure;
  
  if x > y then
    write(999)
  else
    write(4);
  
  while z < 5 do
  begin
    write(z);
    z := z + 1;
  end;
end.
