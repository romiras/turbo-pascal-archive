program testcalc;
uses
  calculus;

var
  answer : real;

{$F+}			    { WARNING!	YOU NEED "FAR" FUNCTIONS! }
function y(x : real) : real;
begin
  y := 4 * sqrt(1 - x * x);
end;

begin
  writeln('Function: y = (1 - x^2)^(1/2) (i.e., top half of a circle)');
  writeln;

{ Calc operations here are: }

{ Integrate function from 0 to 1, in increments of 0.001. A quarter circle. }
{ Get slope of function at 0 by evaluating points 0.01 away from each other. }
{ Find extremum of function, starting at 0.4, initially looking at points
  0.1 on either side of 0.4, and not stopping until we have two x-values
  within 0.001 of each other. }

  answer := integral(0, 1, 0.001, @y);
  writeln('Integral: ', answer:13:9);

  answer := derivative (0, 0.01, @y);
  writeln('Derivative: ', answer:13:9);

  answer := extremum(0.4, 0.1, 0.001, @y);
  writeln('Extremum: ', answer:13:9);
end.