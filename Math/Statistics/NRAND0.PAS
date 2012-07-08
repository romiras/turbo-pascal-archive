{ DO NOT USE THIS UNIT IF YOU INTEND TO USE HARDWARE FLOATING
  POINT.  This unit is "fast" only if you use software floating
  point operations.  With Hardware floating point, use NRAND1.PAS.
  For software floating point, NRAND1 takes 2.3 times as long
  as NRAND0. Recommended directives: N+,E+. }

unit nrand0;
{ fast implementations of exponential, cauchy, and normal
  random variate generators }
{ Copyright, 1988, by J. W. Rider }

{ Based upon algorithms found in J. H. Ahrens and U. Dieter,
  "Efficient Table-Free Sampling Methods for Exponential,
  Cauchy, and Normal Distributions", Communications of the ACM,
  vol 31, no 11, NOV 88, pp 1330-1337. }

{ My "contribution" to this work consists only of translating
  the A&D algorithms into Pascal.  A&D would probably frown upon
  this attempt;  they seem to prefer writing their implementations
  in assembly language. }

{ The normal generator uses the exponential and cauchy generators.
  Those two CANNOT be eliminated from the unit implementation.
  However, the functions could be eliminated from the interface
  for applications where they are not needed. }

interface

function xrandom: real;
{ XRANDOM returns a exponentially distributed random variate.
  The "conventional" practice is to implement it as
  "xrandom:=-log(random);" }

function crandom(u:real): real;
{ CRANDOM returns a cauchy distributed random variate.
  The "conventional" practice is to implement it as
  "x:=pi*(random-0.5); crandom:=sin(x)/cos(x);" }

function nrandom: real;
{ NRANDOM returns a gaussian distributed random variate
  with zero mean and unit variance.  The "conventional"
  practice is to implement a variation of the "Box-Muller"
  or "sine-cosine" algorithm that generates pairs of
  normal variates: "a:=sqrt(-2*log(random)); b:=random*2*pi;
  nrandom:=a*sin(b)" followed by "nrandom:=a*cos(b)".  Here,
  NRANDOM is implemented as a "cauchy-exponential" algorithm:
  "a:=xrandom; b:=crandom; nrandom:=sqrt(a/(1+b*b))" followed
  by "nrandom:=b*sqrt(a/(1+b*b))" with care being taken to
  determine the signs of variates randomly. }

{ The argument in crandom is should be set to a uniformly
  distributed variate between 0 and 1.  The rationale for
  handling it this way is so that the nrandom can use an
  extra bit for determining the sign of its variates.  In
  practice, the call should be "crandom(random)". }

implementation

{ In each of the function bodies, the "step" in the original
  A&D algorithm is referenced at the beginning of the line.
  This should permit easy comparison with the source material. }

var naf:boolean;  { is there not a spare normal variate? }
    nay:real;     { spare normal variate }

function xrandom:real; { A&D algorithm EA }
const ln2 = 0.6931471805599453;
       a1 = 5.7133631526454228;
       b1 = 3.4142135623730950; { A&D article is wrong here ! }
       c  = -1.6734053240284925;
       p  = 0.9802581434685472;
       a2 = 5.6005707569738080;
       b2 = 3.3468106480569850;
       h  = 0.0026106723602095;
       d  = 0.0857864376269050;
var u,g,y,u2:real; begin
{ EA.1 } u:=random; g:=c;
{ EA.2 } u:=u+u; while u<1 do begin
{ EA.3 }    g:=g+ln2;
{ EA.2 }    u:=u+u; end;
{ EA.4 } u:=u-1; if u<=p then
{ EA.5 }    xrandom:=g+a2/(b2-u)
         else begin repeat
{ EA.6 }    u:=random; y:=a1/(b1-u);
{ EA.7 }    u2:=random;
{ EA.7 }    until (u2*h+d)*(b1-u)*(b1-u)<=exp(-y-c);
{ EA.8 }    xrandom:=g+y; end; end;

function crandom(u:real):real; { A&D algorithm CA }
const a1 = 0.6380631366077803;
      b1 = 0.5959486060529070;
      q  = 0.9339962957603656;
      w  = 0.2488702280083841;
      a2 = 0.6366197723675813;
      b2 = 0.5972997593539963;
      h  = 0.0214949004570452;
      p  = 4.9125013953033204;
var t,s,u2,x:real; begin
{ CA.1 } { "u" is assumed to be a uniform random variate 0..1 }
{ CA.1 } t:=u-0.5; s:=w-t*t; if s>0 then
{ CA.2 }    crandom:=t*(a2/s+b2)
         else begin repeat
{ CA.3 }       u:=random; t:=u-0.5; s:=0.25-t*t; x:=t*(a1/s+b1);
{ CA.4 }       u2:=random;
{ CA.4 }       until s*s*((1+x*x)*(h*u2+p)-q)+s <= 0.5;
{ CA.5 }    crandom:=x; end; end;

function nrandom:real; { A&D algorithm NA }
var b:boolean; u,e,s,c,x:real; begin
{ NA.1 } naf:=not naf; if naf then nrandom:=nay
         else begin
{ NA.2 } u:=random; b:=u<0.5;
{ NA.3 } e:=xrandom; s:=e+e;
{ NA.4 } if b then c:=crandom(u+u) else c:=crandom(u+u-1);
{ NA.5 } x:=sqrt(s/(1+c*c)); nay:=c*x;
{ NA.6 } if b then nrandom:=x else nrandom:= -x; end; end;

begin
{ NA.0 } naf:=true;
end.