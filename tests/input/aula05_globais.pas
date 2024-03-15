program varsGlobais (input, output);
var a1, a2, a3 : integer;
var b1, b2, b3 : boolean;
begin    
    a1 := 1;
    a2 := 2;
    a3 := 3;

    b1 := true;
    b2 := false;
    b3 := true;

    a1 := a2 + a1 div a3 - a1;
    a1 := (4 + a3) * a1 + 100;
    b1 := b1 and (b3) or b2;
    (* a1 := x < y or x + y and x > y or x >= y and x <= y and y <> y; *)

    write(a1);
    write(b1);
end.

