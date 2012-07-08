{$N+}
type
  fofx = function(x : real) : real;	{ needed for function-evaluating }

function derivative(x, dx : real; f : pointer) : real;
var y : fofx;
begin
  @y := f;
  derivative := (y(x + dx/2) - y(x - dx/2)) / dx;
end;

{ Integrates function from a to b,
  by approximating function with
  rectangles of width h. }
function integral(a, b, h : real; f : pointer) : real;
var
  x, summation : real;
  y	       : fofx;
begin
  @y := f;
  summation := 0;
  x := a + h/2;
  while x < b do
  begin
       summation:= summation + h *
        sqrt( sqr(y(x)) + sqr( derivative(x,h,f) ) ); {Integral Expression}
       x:=x+h;
  end;
  integral := summation;
end;

function Length(a, b, h : real; f : pointer) : real;
begin
       Length:=integral(a,b,h,f);
end;

function F(x : real) : real; FAR;
begin
     F:=1.0-sin(x);
end;

begin
     writeln('Curve length:',Length(-pi/2,-pi/6, 1e-4, @F):8:5);
     readln;
end.