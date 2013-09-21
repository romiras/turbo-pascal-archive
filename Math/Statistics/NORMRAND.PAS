{ Распределение по нормальному закону }

function NormRand (Mx, S : Real) : Real;
{ Mx - мат.ожидание, S - среднеквадр.отклонение }
var
  A,B,R,SQ : Real;
begin
  repeat
    A := 2 * Random - 1;
    B := 2 * Random - 1;
    R := Sqr(A) + Sqr(B)
  until (R < 1);
  SQ := Sqrt(-2 * Ln(R) / R);
  NormRand := Mx + S * A * SQ
end;

