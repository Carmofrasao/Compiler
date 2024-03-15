program comandoWhile(input, output);
var a1 : integer;
var b1 : boolean;
begin 
    a1 := 1;
    while(a1 > 0) do
    begin
        write(5);
        while(a1 > 0) do
        begin
            write(4);
            while(a1 > 0) do
            begin
                write(3);
                while(a1 > 0) do
                begin
                    write(2);
                    while(a1 > 0) do
                    begin
                        write(1);
                        a1 := a1 - 1;
                    end;
                end;
            end;
        end;
    end;

    b1 := true;
    if(b1 <> false) then
        if(b1 = true) then
            if(b1 <> true) then 
                write(999)
            else
                if (a1 = 0) then
                    write(1)
                else 
                    write(998)
        else 
            write(997)
    else 
        write(996);

    write(2);

end.

