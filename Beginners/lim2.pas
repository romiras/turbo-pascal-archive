const
  eps = 1e-3;

var
  n: integer;
  k, l, sign, newsum, oldsum: real;

begin
  n := 1; // индекс, кол-во слагаемых
  sign := 1.0; // чередование знаков
  newsum := 0;

  k := 1;
  repeat
    l := 1;
    repeat
          oldsum := newsum;
          newsum := newsum + sign * k * l / sqr (k + l);
          l := l + 1;
          n := n + 1;
    until  abs (newsum - oldsum) < eps;
    k := k + 1;
    sign := -sign;
  until abs (newsum - oldsum) < eps;

  writeln ('Serie sum = ', newsum:8:5);
  writeln ('Number of serie components = ', n);
end.
