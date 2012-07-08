{ This unit performs calculus operations via basic numerical
  methods : integrals, derivatives, and extrema.

  All functions return real values.  The last parameter in each function is
  a pointer to a "real" function that takes a single "real" parameter:
  for example, y(x). }

Unit Calculus;

Interface
Function Derivative(x, dx : real; f : pointer) : real;
Function Deriv( x, dx : real; f : pointer) : real;
Function Integral(a, b, h : real; f : pointer; typ: byte) : real;
{Function Integral(a, b, h : real; f : pointer) : real;}
Function Length (a, b, h : real; f : pointer) : real;
Function Surface(a, b, h : real; f : pointer) : real;
Function Volume (a, b, h : real; f : pointer) : real;
Procedure CenterTr(a, b, h : real; f : pointer; var xc,yc: real);
Function Extremum(x, dx, tolerance : real; f : pointer) : real;

Implementation

type
  fofx = function(x : real) : real;	{ needed for function-evaluating }

function derivative(x, dx : real; f : pointer) : real;
var y : fofx;
begin		      { Derivative of function at x: delta y over delta x }
  @y := f;					 { You supply x & delta x }
  derivative := (y(x + dx/2) - y(x - dx/2)) / dx;
end;

function Deriv( x, dx : real; f : pointer) : real;
begin
      Deriv:=sqrt( 1+sqr( derivative(x,dx,f) ) );
end;

function integral(a, b, h : real; f : pointer; typ: byte) : real;
var
  x, summation : real;
  y	       : fofx;
begin				      { Integrates function from a to b,  }
  @y := f;			      { by approximating function with	  }
  summation := 0;		      { rectangles of width h. }
  x := a + h/2;
  while x < b do
  begin
  { Answer is sum of rectangle areas, each area being h*y(x).
    X is at the middle of the rectangle. }
       case typ of
       0: summation:= summation+h*y(x);
       1: summation:= summation+h*Deriv(x,h,f);
       2: summation:= summation+h*sqr(y(x));
       3: summation:= summation+h*y(x)*Deriv(x,h,f);
       4: summation:= summation+h*x*y(x);
       5: summation:= summation+h*x*Deriv(x,h,f);
       end;
       x:=x+h;
  end;
  integral := summation;
end;

function Length(a, b, h : real; f : pointer) : real;
begin
       Length:=integral(a,b,h,f,1);
end;

function Surface(a, b, h : real; f : pointer) : real;
begin
       Surface:=2*pi*integral(a,b,h,f,2);
end;

function Volume(a, b, h : real; f : pointer) : real;
begin
       Volume:=pi*integral(a,b,h,f,3);
end;

procedure CenterTr(a, b, h : real; f : pointer; var xc,yc: real);
var squ:real;
begin
       squ:=integral(a,b,h,f,0);
       xc:=integral(a,b,h,f,4)/squ;
       yc:=0.5*integral(a,b,h,f,2)/squ;
end;

function extremum(x, dx, tolerance : real; f : pointer) : real;
{ This function uses DuChez's Method for finding extrema of a function (yes,
  I seem to have invented it): taking three points, finding the parabola
  that connects them, and hoping that an extremum of the function is near
  the vertex of the parabola.  If not, at least you have a new "x" to try...

  X is the initial value to go extremum-hunting at; dx is how far on either
  side of x to look.  "Tolerance" is a parameter: if two consecutive
  iterations provide x-values within "tolerance" of each other, the answer
  is the average of the two. }
var
  y	      : fofx;
  gotanswer,
  increasing,
  decreasing  : boolean;
  oldx	      : real;
  itercnt     : word;
begin
  @y := f;
  gotanswer := false;
  increasing := false;
  decreasing := false;
  itercnt := 1;
  repeat			       { repeat until you have answer }
    oldx := x;
    x := oldx - dx*(y(x+dx) - y(x-dx)) /    { this monster is the new value }
	 (2*(y(x+dx) - 2*y(x) + y(x-dx)));  { of "x" based DuChez's Method }
    if abs(x - oldx) <= tolerance then
      gotanswer := true 		    { within tolerance: got an answer }
    else
    if (x > oldx) then
    begin
      if decreasing then
      begin		 { If "x" is increasing but it }
	decreasing := false;		    { had been decreasing, we're }
	dx := dx/2;			    { oscillating around the answer. }
      end;				  { Cut "dx" in half to home in on }
      increasing := true;		    { the extremum. }
    end
    else
    if (x < oldx) then
    begin
      if increasing then
      begin		 { same thing here, except "x" }
	increasing := false;		    { is now decreasing but had }
	dx := dx/2;			    { been increasing }
      end;
      decreasing := true;
    end;
  until gotanswer;

  extremum := (x + oldx) / 2;		    { spit out answer }
end;

end.