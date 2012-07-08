
const
     M = 100;
     Msize = 5;

type
     Arr = array [1..M,1..M] of single;

     TPoint = record
          x,y: integer;
     end;
     Stor = array [1..Msize] of TPoint;

var
     A: Arr;
     AMax: Stor;

procedure Fill (var Z: Arr);
var
     i, j: integer;
begin
     randomize;
     for i := 1 to M do
     for j := 1 to M do
          Z[i,j] := int (543.0 * sin (random));
end;

procedure AddMax (P: TPoint; Z: Arr; var S: Stor);

procedure ShiftLeft (q: integer);
var
     m: integer;
begin
     for m := 1 to q-1 do
          S[m] := S[m+1];
end;

var
     i, j, k: integer;
     max, Smax, val, Sval: single;
begin
     val := Z[P.x,P.y];
     max := Z[1,1];
     Smax := max;
     k := Msize;
     while (k > 0) and ( Z [S[k].x, S[k].y] < val) do
     begin
          if val > Z [S[k].x, S[k].y] then
          begin
               ShiftLeft (k);
               S[Msize] := P;
               break;
          end;
          dec (k);
     end;
end;

procedure FindMax (Z: Arr);
var
     i, j, k: integer;
     P: TPoint;
     max, Smax: single;
begin
     max := Z[1,1];

     for i := 1 to M do
     for j := 1 to M do
     if Z[j,j] > max then
     begin
          max := Z[i,j];
          P.x := i; P.y := j;
          AddMax (P, Z, AMax);
     end;
end;

procedure PrintMax (Z: Arr; S: stor);
var
     k: integer;
     sum: single;
begin
     sum := 0;
     for k := 1 to Msize do
     begin
          sum := sum + Z [S[k].x, S[k].y];
          writeln ('A',k,'max =', Z [S[k].x, S[k].y] :8:2, ' A[',S[k].x,',',S[k].y,']');
     end;
     writeln;
     writeln ('S5max =', Sum:8:2);
     readln;
end;

begin
     Fill (A);
     FindMax (A);
     PrintMax (A, AMax);
end.
