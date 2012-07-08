
const
     N = Pred (3);

type
     TMatrix = array [0..N, 0..N] of integer;


function Mult (X, Y: TMatrix): TMatrix;
var
  sum,
  i, j, k: integer;
  Z: TMatrix;
begin
     for i := 0 to N do
       for j := 0 to N do
       begin
          sum := 0;
          for k := 0 to N do
              inc (sum, X[j,k] * Y[k,i]);
              //writeln (Y[k,i]);
          Z[j,i] := sum;
       end;
     Result := Z
end;

procedure GenMatrix (var X: TMatrix);
var
  i, j: integer;
begin
     for i := 0 to N do
       for j := 0 to N do
         X[i,j] := random (2) - 1;
end;


procedure PrintMatrix (X: TMatrix);
var
  i, j: integer;
begin
     for i := 0 to N do
     begin
       writeln;
       for j := 0 to N do
         write (X[i,j] : 4);
     end;
     writeln;
end;


var
     A, B, C: TMatrix;

begin
     randomize;

     GenMatrix (A);
     PrintMatrix (A);

     GenMatrix (B);
     PrintMatrix (B);

     C := Mult (A, B);

     writeln;
     writeln ('Result matrix A * B is');
     PrintMatrix (C);
end.
