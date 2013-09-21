{ Прямое слияние. Алгоритм Боуза - Нельсона }

Const n = 200;

Type 
  tipkl = word;
  tip = Record
          kl: tipkl;
          z: Array[1..50] Of real
End;

Var 
  A: Array[1..n] Of tip;
  j: word;

Procedure Bose (Var AA; voz:Boolean);

Var 
  m,j: word;
  x: tip; {tip - тип сортируемых записей}
  A: Array [1..65520 div Sizeof(tip)] Of tip Absolute AA;

Procedure Sli(j,r,m: word); { r - расстояние между началами
сливаемых частей, а m - их размер, j - наименьший номер записи}
Begin
  If j+r<=n Then
    If m=1 Then
      Begin
        If voz Xor (A[j].kl < A[j+r].kl) Then
          Begin
            x := A[j];
            A[j] := A[j+r];
            A[j+r] := x
          End
      End
  Else
    Begin
      m := m Div 2;
      Sli(j,r,m); {Слияние "начал"}
      If j+r+m<=n Then
        Sli(j+m,r,m); {Слияние "концов"}
      Sli(j+m,r-m,m)
    End {Слияние в центральной части}
End{блока Sli};
Begin
  m := 1;
  Repeat
    j := 1; {Цикл слияния списков равного размера: }
    While j+m< = n Do
                 Begin
                   Sli(j,m,m);
                   j := j+m+m
                 End;
    m := m+m {Удвоение размера списка перед началом нового прохода}
  Until m >= n {Конец цикла, реализующего все дерево слияний}
End{блока Bose};
Begin
  Randomize;
  For j:=1 To n Do
    Begin
      A[j].kl := Random(65535);
      Write(A[j].kl:8);
    End;
  Readln;
  Bose(A,true);
  For j:=1 To n Do
    Write(A[j].kl:8);
  Readln
End.
