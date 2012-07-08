const
     N = 4;
type
     Matrix = array [1..N,1..N] of integer;

procedure PrintMatrix (M : Matrix);
var
     i, j: integer;
begin
     writeln;
     for i := 1 to N do
     begin
          writeln;
          for j := 1 to N do
               write (M[i,j] : 4);
     end;
end;

var
     M: Matrix;
     i, j: integer;

begin
     randomize;
     for i := 1 to N do
     for j := 1 to N do
          M[i,j] := random (10);

     PrintMatrix (M);

     for i := 1 to N-1 do
     for j := 1+1 to N do
          M[j,i] := M[i,j];

     PrintMatrix (M);

end.