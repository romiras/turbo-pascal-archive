{ DO NOT USE THIS UNIT IF YOU DON'T USE HARDWARE FLOATING POINT.
  For software floating point, use NRAND0.PAS.  With hardware
  floating point, NRAND0 takes twice as long as NRAND1. }

{$N+,E-}
unit nrand1;
{ conventional implementations of exponential, cauchy and normal
  random variate generators }
{ Copyright 1988, by J. W. Rider }

{ Since the normal random generator doesn't use either XRANDOM or
  CRANDOM, they could be eliminated from both the interface and
  the implementation. }

{ Many of the notes that I've included in NRAND0.PAS apply here
  also. }

interface

function xrandom:real;
{ XRANDOM returns an exponentially distributed random variate
  with unit mean and variance.  To get a variate with mean M and
  standard deviation S, use S*XRANDOM+M. }

function crandom(u:real):real;
{ CRANDOM returns a cauchy distributed random variate which don't
  have means or variances in the usual sense.  The probability
  density function is f(x)=1/(pi*(1+sqr(x))).  The probability
  distribution function is F(x)=0.5-arctan(x)/pi.  Obviously, the
  median value returned is 0.  The "u:real" argument is a holdover
  from the A&D implementation in NRAND0.PAS.  The normal calling
  sequence would be "crandom(random)". }

function nrandom:real;
{ NRANDOM returns a normal or gaussian distributed random variate
  with zero mean and unit variance.  To get a variate with mean M
  and standard deviation S, use S*NRANDOM+M. }

implementation
var naf: boolean; nay: real;

function xrandom:real;
var u:real;
begin repeat; u:=random; until u>0; {generally, only one cycle executed}
xrandom:=-ln(u); end;

function crandom(u:real):real;
var t:real;
begin if (u=0) or (u=1) then begin repeat;
   u:=random; until (u>0) and (u<1); end; {generally, never executed}
t:=(u-0.5)*pi; crandom:=sin(t)/cos(t); end;

function nrandom:real;
var u1,u2:real;
begin naf:=not naf; if naf then nrandom:=nay
else begin repeat; u1:=random; until u1>0;
u1:=sqrt(-2*ln(u1)); u2:=random*pi*2;
nay:=u1*cos(u2); nrandom:=u1*sin(u2); end; end;

begin naf:=true; end.
