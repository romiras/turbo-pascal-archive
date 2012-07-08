Type
    Link = ^Node;
    Node = record
        Data: integer;
        Next: Link;
    End;

Var
    Head, z: link;

procedure list_initialize;
begin
    new( head );
new( z );
    head^.next := z;
z^.next := nil;
end;

procedure insert_after( v : integer; t : link );
var
x : link;
begin
    new(x);
    x^.data := v;
x^.next := t^.next;
    t^.next := x;
end;

procedure delete_next( t : link );
var
    del: link;
begin
del := t^.next;
t^.next := t^.next^.next;
dispose(del);
end;
