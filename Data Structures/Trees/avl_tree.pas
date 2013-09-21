{ сбалансированные деревья 
программа поиска и вставки узла}

Type node =   Record
                  Key:   integer;
                  Left, right:   ref;
                  Bal:   -1..1;
End;

Procedure search(x: integer; Var p: ref; Var h: boolean);

Var 
    p1, p2:   ref; {h = false}
Begin
    If p = Nil Then
        Begin {узла нет в дереве; включить его}
            new(p);
            h := true;
            With p^ Do
                Begin
                    key := x;
                    count := 1;
                    left := Nil;
                    right := Nil;
                    bal := 0;
                End
        End
    Else
        If x < p^.key Then
            Begin
                search(x, p^.left, h);
                If h Then {выросла левая ветвь}
                    Case p^.bal Of
                        1:
                             Begin
                                 p^.bal := 0;
                                 h := false
                             End ;
                        0:   p^.bal := -1;
                        -1:
                              Begin {балансировка}
                                  p1 := p^.left;
                                  If p1^.bal = -1 Then
                                      Begin {однократный правый поворот}
                                          p^.left := p1^.right;
                                          p1^.right := p;
                                          p^.bal := 0;
                                          p := p1
                                      End
                                  Else
                                      Begin {двукратный правый - левый поворот}
                                          p2 := p1^.right;
                                          p1^.right := p2^.left;
                                          p2^.left := p1;
                                          p^.left := p2^.right;
                                          p2^. right := p;
                                          If p2^.bal =-1 Then p^.bal := 1
                                          Else p^.bal := 0;
                                          it p2^.bal =   1 Then p1^.bal := -1
                                                         Else p1.^bal := 0;
                                          p := p2;
                                      End;
                                  p^.bal := 0;
                                  h := false;
                              End
                    End
            End
    Else
        If x > p^.key Then
            Begin
                search(x, p^.right, h);
                If h Then {выросла правая ветвь}
                    Case p^.bal Of
                        -1:
                              Begin
                                  p^.bal := 0;
                                  h := false;
                              End ;
                        0:   p^.bal := 1;
                        1:
                             Begin {балансировка}
                                 p1 := p^.right;
                                 If р1^.bal =1 Then
                                     Begin {однократный левый поворот}
                                         p^.right := p1^.left;
                                         p1^.left := p;
                                         p^.bal := 0;
                                         p := p1;
                                     End
                                 Else
                                     Begin {двукратный левый - правый поворот}
                                         p2 := p1^.left;
                                         p1^.left := p2^.right;
                                         p2^.right := p1;
                                         p^.right := p2^.left;
                                         p2^.left := p;
                                         If p2^.bal = 1 Then p^.bal := -1
                                         Else p^.bal := 0;
                                         If p2^.bal = -1 Then p1^.bal := 1
                                         Else p1^.bal:   =   0;
                                         p := p2;
                                     End ;
                                 p^.bal := 0;
                                 h := false;
                             End
                    End
            End
    Else
        Begin
            p^.count := p^.count + 1;
            h := false;
        End
End.
