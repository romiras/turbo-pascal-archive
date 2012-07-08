
{ -------------(standard trigonometry function, also 3D math)----------
  RotateX, RotateY, RotateZ

  Input:
   p - the point to rotate
   ang - the degree angle to rotate by
  Output:
   alters p
  -------------------------------------------------------------------- }
procedure RotateX(var p:point; ang:fp);
begin
 p[1]:=p[1];
 p[2]:=((p[2]*cos(rad(ang)))+(p[3]*sin(rad(ang))));
 p[3]:=((-p[2]*sin(rad(ang)))+(p[3]*cos(rad(ang))));
end;
procedure RotateY(var p:point; ang:fp);
begin
 p[1]:=((p[1]*cos(rad(ang)))+(p[3]*sin(rad(ang))));
 p[2]:=p[2];
 p[3]:=((-p[1]*sin(rad(ang)))+(p[3]*cos(rad(ang))));
end;
procedure RotateZ(var p:point; ang:fp);
begin
 p[1]:=(((p[1])*cos(rad(ang)))+(p[2]*sin(rad(ang))));
 p[2]:=((-p[1]*sin(rad(ang)))+(p[2]*cos(rad(ang))));
 p[3]:=p[3];
end;
{ 3D line with perspective }
line( round(x1/sqrt(sqr(K+z1)+sqr(x1)+sqr(y1))*K,
      round(y1/sqrt(sqr(K+y1)+sqr(y1)+sqr(y1))*K,
      round(x2/sqrt(sqr(K+z2)+sqr(x2)+sqr(y2))*K,
      round(y2/sqrt(sqr(K+y2)+sqr(y2)+sqr(y2))*K);

{ GRAPHICS ROUTINES / Coordinate Systems 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 }
UNIT sp_coord;	{ Author: John Howard }
{ see UNIT coord   below }
{
Define a two-dimensional space representation which is used for Cartesian and
Polar coordinate systems.  A three-dimensional space is for Spherical and
Azimuth-Elevation coordinate systems.
}
{ A vector is a one-dimensional array of real numbers.	A matrix has two
  dimensions m by n with m rows and n columns.	Notice the row number always
  comes first in the dimensions and the indices.  Example square matrix A33 =
	     [ a11  a12  a13 ]	  or generally	A[i, j]; i=rows, j=columns.
	     [ a21  a22  a23 ]
	     [ a31  a32  a33 ]
  A matrix can be operated upon with appropriate column or row vectors.
}
INTERFACE
{.$DEFINE D2}				 {remove period to use 2D}
{$IFNDEF D2}
const N = 3;				 { Cardinality for Three_Vector}
      M = 3;				 { Square matrix for invert routine}
{$ELSE}
const N = 2;				 { Cardinality for Two_Vector}
      M = 2;				 { Square matrix for invert routine}
{$ENDIF}
   Size = M;
type
   Vector = array [1..N] of real;	 { 3D vector is the most common! }
   Matrix = array [1..M, 1..N] of real;  { 3x3 matrix is the most common! }

{Store all the components into a vector}
{$IFNDEF D2}
   procedure Set_Value( var a: Vector; x_value, y_value, z_value: real);
{$ELSE}
   procedure Set_Value( var a: Vector; x_value, y_value: real);
{$ENDIF}

{Retrieve the value of s from the ith element of a vector}
   function Element( var a: Vector; i: integer): real;

{Retrieve the first element from a vector}
   function  X_Component( var a: Vector): real;

{Retrieve the second element from a vector}
   function  Y_Component( var a: Vector): real;

{Retrieve the third element from a vector}
{$IFNDEF D2}
   function  Z_Component( var a: Vector): real;
{$ENDIF}

IMPLEMENTATION

procedure Set_Value;	      { Note: parameter list intentionally left off}
begin
      a[1] := x_value;
      a[2] := y_value;
{$IFNDEF D2}
      a[3] := z_value;
{$ENDIF}
end;

function Element( var a: Vector; i: integer): real;
begin
      Element := a[i];
end;

function  X_Component( var a: Vector): real;
begin
      X_Component := a[1];
end;

function  Y_Component( var a: Vector): real;
begin
      Y_Component := a[2];
end;

{$IFNDEF D2}
function  Z_Component( var a: Vector): real;
begin
      Z_Component := a[3];
end;
{$ENDIF}
BEGIN
END.

(**********
If you do not want to create an actual 3d space, just convert coordinates :

You could use a two dimensional X_Component and Y_Component calculation to get
you to an approximate region based upon Z_Component.  Example:

From point A(x1,y1) to B(x2,y2) you travel a
     distance = sqrt(sqr(x2-x1) + sqr(y2-y1))
at a slope of (y2-y1)/(x2-x1).	That slope is called the Tangent of the angle
of inclination of the line AB.

Now that you know where you are heading and how far away it is you can divide
the total distance into sections say of unit length.  That means a distance of
10 would have ten units.  Every time your spaceship moves one unit in the known
direction you can reverse the calculation to find out where you are at.  When
you reach the final distance, you'd take approximations using the third
component.  This idea is simple but not very accurate in the interum space.

You can use the same idea but implement it with a proper coordinate conversion.
**********)

UNIT coord;
{ Author: John Howard }
{ Original source: Jack Crenshaw, 1992 Embedded Systems Programming }
{ Space Conversion -- Angles are capitalized }
{ All axes are perpendicular to each other }
INTERFACE
const
      Zero = 0.0;
      One  = 1.0;
      TwoPi		  = Two * SYSTEM.Pi;
      Pi_Over_Two	  = SYSTEM.Pi/Two;

{ 1 binary angular measure = 1 pirad = Pi radians = 180 degrees }
      Degrees_Per_Radian  = 180.0/SYSTEM.Pi;
      Radians_Per_Degree  = SYSTEM.Pi/180.0;

{ X-axis points east, y-axis north, and angle Theta is the heading measured
  north of due east.  If Theta is zero that corresponds to a line running
  along the x-axis a radial distance of r.
}
Procedure To_Polar ( x, y: real; Var r, Theta: real);
Procedure From_Polar ( r, Theta: real; Var x, y: real);

{ X-axis points toward you, y-axis right, z-axis upward, angle Phi measures
  directions in the horizontal (x-y plane) from the x-axis, and angle Theta
  measures the direction in the vertical from the z-axis downward.  If Theta
  is zero that corresponds to a line pointed up the z-axis.
}
Procedure To_Spherical ( x, y, z: real; Var r, Phi, Theta: real);
Procedure From_Spherical ( r, Phi, Theta: real; Var x, y, z: real);

{ X-axis points east, y-axis north, z-axis upward, angle Phi corresponds to an
  azimuth measured clockwise from due north, and angle Theta is the elevation
  measured upwards from the horizon (x-y plane).
}
Procedure To_Azimuth_Elevation ( x, y, z: real; Var r, Phi, Theta: real);
Procedure From_Azimuth_Elevation ( r, Phi, Theta: real; Var x, y, z: real);

Function Sign ( x, y: real): real;
Function Degrees ( A: real): real;
Function Radians ( A: real): real;

Function Atan ( x: real): real; 	  {ArcTangent}
Function Atan2 ( s, c: real): real;

IMPLEMENTATION

{ Convert from Cartesian to polar coordinates }
Procedure To_Polar ( x, y: real; Var r, Theta: real);
Begin
  r := Sqrt(Sqr(x) + Sqr(y));
  Theta := Atan2(y, x);
End;

{ Convert from polar to Cartesian coordinates }
Procedure From_Polar ( r, Theta: real; Var x, y: real);
Begin
  x := r * Cos(Theta);
  y := r * Sin(Theta);
End;

{ Convert from Cartesian to spherical polar coordinates }
Procedure To_Spherical ( x, y, z: real; Var r, Phi, Theta: real);
var  temp: real;
Begin
  To_Polar(x, y, temp, Phi);
  To_Polar(z, temp, r, Theta);
End;

{ Convert from spherical polar to Cartesian coordinates }
Procedure From_Spherical ( r, Phi, Theta: real; Var x, y, z: real);
var  temp: real;
Begin
  From_Polar(r, Theta, z, temp);
  From_Polar(temp, Phi, x, y);
End;

{ Convert from Cartesian to Az-El coordinates }
Procedure To_Azimuth_Elevation ( x, y, z: real; Var r, Phi, Theta: real);
var  temp: real;
Begin
  To_Polar(y, x, temp, Phi);
  To_Polar(temp, z, r, Theta);
End;

{ Convert from Az-El to Cartesian coordinates }
Procedure From_Azimuth_Elevation ( r, Phi, Theta: real; Var x, y, z: real);
var  temp: real;
Begin
  From_Polar(r, Theta, temp, z);
  From_Polar(temp, Phi, y, x);
End;

{ Returns Absolute value of x with Sign of y }
Function Sign ( x, y: real): real;
Begin
  if y >= Zero then
     Sign := Abs(x)
  else
     Sign := -Abs(x);
End;

{ Convert angle from radians to degrees }
Function Degrees ( A: real): real;
Begin
  Degrees := Degrees_Per_Radian * A;
End;

{ Convert angle from degrees to radians }
Function Radians ( A: real): real;
Begin
  Radians := Radians_Per_Degree * A;
End;

{ Inverse Trigonometric Tangent Function }
Function Atan ( x: real): real;
{  Arctangent algorithm uses fifth-order rational fraction with optimized
   coefficients
}
   function _Atan ( x: real): real;
   const
     a = 0.999999447;
     b = 0.259455937;
     c = 0.592716128;

   var	y: real;
   begin
      y := x*x;
      _Atan := a*x*( One + b*y) / ( One + c*y);
   end;

var  a, y: real;
Begin
  y := Abs(x);
  if y <= One then
    a := _Atan(y)
  else
    a := Pi_Over_Two - _Atan( One / y);
  if x <= Zero then
    a := -a;
  Atan := a;
End;

{ Four-Quadrant Inverse Trigonometric Tangent Function }
Function Atan2 ( s, c: real): real;
var  s1, c1, Theta: real;
Begin
  s1 := Abs(s);
  c1 := Abs(c);
  if c1 + s1 = Zero then
    Theta := Zero
  else if s1 <= c1 then
	 Theta := ArcTan(s1 / c1)
       else
	 Theta := Pi_Over_Two - ArcTan(c1 / s1);
  if c < Zero then
    Theta := Pi - Theta;
  Atan2 := Sign(Theta, s);
End;
END.(*****END*****)
