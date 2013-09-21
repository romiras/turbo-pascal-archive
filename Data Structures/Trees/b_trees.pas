{ сильноветвящиеся деревья }
{ Красно - черные деревья }

Program PoiskByTree;

Type 
    rec =   Record
                fio:   string [40];
                gr:   string[4];
                kurs:   string[1];
End;

link =   ^l;
l =   Record
          key:   rec;
          red:   boolean;
          l,r:   link;
End;

Var 
    head, w:   link;
    k:   rec;
    st1:   string;
    f:   file Of rec;

Function rotate(v:rec;y:link):   link;

Var 
    c,gs:   link;
Begin
    If v.fio[1]<y^.key.fio[1] Then c := y^.l
    Else c := y^.r;
    If v.fio[1]<c^.key.fio[1] Then
        Begin
            gs := c^.l;
            c^.l := gs^.r;
            gs^.r := c;
        End
    Else
        Begin
            gs := c^.r;
            c^.r := gs^.l;
            gs^.l := c;
        End;
    If v.fio[1]<y^.key.fio[1] Then y^.l := gs
    Else y^.r := gs;
    rotate := gs;
End;

Function split(v : rec; m,p,g,gg : link):   link;{Перекрашивает}
Begin
    m^.red := true;
    m^.l^.red := false;
    m^.r^.red := false;
    If p^.red Then
        Begin
            g^.red := true;
            If (v.fio[1] < g^.key.fio[1]) <> (v.fio[1] < p^.key.fio[1]) Then
                p := rotate(v,g);
            m := rotate(v,gg);
            m^.red := false;
        End;
    head^.r^.red := false;
    split := m;
End;

Function insert(v : rec; n : link):   link;

Var 
    q1,q2,p :   link;
Begin
    p := n;
    q1 := p;
    Repeat
        q2 := q1;
        q1 := p;
        p := n;
        If v.fio[1]<n^.key.fio[1] Then n := n^.l
        Else n := n^.r;
        If n^.l^.red And n^.r^.red Then n := split(v,n,p,q1,q2);
    Until n^.l=n;
    New(n);
    n^.key.fio := v.fio;
    n^.l := n;
    n^.r := n;
    If v.fio[1]<p^.key.fio[1] Then p^.l := n
    Else p^.r := n;
    insert := n;
    n := split(v,n,p,q1,q2);
End;

Procedure search(st:String; x:link; Var z:rec);
Begin
    while st<>x^.key.fio Do
    If st<x^.key.fio Then x := x^.l
    Else x := x^.r;
    z := x^.key;
End;
Begin
    new(head);
    assign(f,'d:\my.dat');
    reset(f);
    while not eof(f) Do
    Begin
        read(f,k);
        w := insert(k,head);
    End;
    readln(st1);
    search(st1,head,k);
End.
