program escopoProx(input, output);
    procedure p;
        procedure q;
            procedure r;
                begin (* r *)  write(1); end;
            procedure s;
                begin (* s *) write(2); end;
        begin (* q *) r; s; end;
    begin (* p *) q; end;
    procedure t;
        procedure u;
            begin (* u *) write(3); end;
        procedure v;
            begin (* v *) write(4); end;
    begin (* t *) u; v; end;
begin (* principal *) p; t; end.