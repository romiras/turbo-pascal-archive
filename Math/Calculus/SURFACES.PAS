uses calculus;

var answer,xx,yy : real;
{$F+}			    { WARNING!	YOU NEED "FAR" FUNCTIONS! }
Function y(x : real) : real;
begin
  y:=10-sqrt(x);
end;

begin
  writeln('Function: y = 10-sqrt(x)');
  writeln;

  answer := Length(1, 2, 0.001, @y);
  writeln('Length: ', answer:1:3);

  answer := Surface(1, 2, 0.001, @y);
  writeln('Surface: ', answer:1:3);

  answer := Volume(1, 2, 0.001, @y);
  writeln('Volume: ', answer:1:3);

  CenterTr(1, 2, 0.001, @y, xx, yy);
  writeln('Center of trapezoid: (', xx:1:3,', ', yy:1:3,')');

end.