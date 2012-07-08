{
   Code by VanDamM // [WRC]
}

Program Check_Point_In_Poly;
Uses Crt;

Type Point = Record   { тип точка }
      x, y : integer;
     End;

Var  PointXY : Point;                 { проверяемая точка }
     Poly    : array[0..24] of Point; { массив вершин многоугольника }
     C       : integer;               { кол-во вершин многоугольника }
     i, j    : integer;

Function Max( Num1, Num2 : integer ) : integer;
Begin
 If Num1>Num2 then Max:=Num1 else Max:=Num2;
End;

Function Min( Num1, Num2 : integer ) : integer;
Begin
 If Num1<Num2 then Min:=Num1 else Min:=Num2;
End;

Procedure EnterData; { Процедура ввода данных }
Begin
 Write('Enter poly`s vertex number: '); ReadLn ( C );
 For i:=0 to C-1 do
  begin
   Write('X[',i,']: '); ReadLn(Poly[i].x);
   Write('Y[',i,']: '); ReadLn(Poly[i].y);
  end;
End;

Function PointInPoly ( A : Point; P : array of Point; N : integer) : integer;
Var Count : integer;
    T     : real;
Begin
  T:=0;
  Count:=0;
 For i:=0 to N-1 do
  begin
   j:=(i+1) mod N;
   If P[i].y = P[j].y then Continue;
   If (P[i].y > A.y) and (p[j].y > A.y) then Continue;
   If (P[i].y < A.y) and (p[j].y < A.y) then Continue;
   If Max(P[i].y, P[j].y) = A.y then
    Inc(Count)
   else
    If Min(P[i].y, P[j].y) = A.y then
     Continue
    else
     begin
      T := (A.y-P[i].y)/(P[j].y-P[i].y);
      If ((T>0) and (T<1)) and ((P[i].x + T*(P[j].x-P[i].x)) >= A.x) then
       Inc(Count);
     end;
  end;
 PointInPoly:= Count AND 1;
End;

Begin
 ClrScr;

 EnterData;

  repeat
   WriteLn;
   Write('Point X: '); ReadLn(PointXY.x);
   Write('Point Y: '); ReadLn(PointXY.y);

   writeln;

   If PointInPoly(PointXY, Poly, C) = 0 then
      Write('Answer: Point out of poly')
   else
      Write('Answer: Point in poly');
  until PointXY.x = -1;


  readln;
End.
