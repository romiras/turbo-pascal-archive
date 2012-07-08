
Program Max_search;

Const m =   10;

Type vector =   array[1..m] Of integer;

Var a:   vector;
    i,j,imax,max,p,d:   integer;
    n:   real;
Begin
    randomize;
    writeln('Nicaaiea ianneaa e aai auaia');
    For i:=1 To m Do
        Begin
            p := random(20);
            a[i] := p-1;
            write(a[i]:3);
        End;
    max := a[1];
    For i:=2 To m Do
        If max<a[i] Then
            Begin
                max := a[i];
                imax := i
            End;
    writeln;
    writeln('cia?aiea iaeneiaeuiiai=',max);
    writeln('Eiaaen iaeneiaeuiiai=',imax);
    
    For i:=1 To m-1 Do
        For j:=i+1 To m Do
            If a[i]>=a[j] Then
                Begin
                    d := a[i];
                    a[i] := a[j];
                    a[j] := d;
                End;
    
    For i:=1 To m Do
        write (a[i]: 3);
    writeln;
End.
