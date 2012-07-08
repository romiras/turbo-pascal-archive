{$N+}
UNIT AllMaths;

INTERFACE
CONST e = 2.7182818;

Function Prime(N: LongInt): Boolean;
{Determines if argument is prime}
Function Whole(X: Real): Boolean;
Function Deg2Rad(D: Real): Real;
Function Grad2Rad(G: Real): Real;
Function Deg2Grad(D: Real): Real;
Function Rad2Deg(R: Real): Real;
Function Rad2Grad(R: Real): Real;
Function Grad2Deg(G: Real): Real;
Function Csc(R: Real): Real;
Function Sec(R: Real): Real;
Function HypETr(S: Real): Real; { Hypotenuse_Equilateral_Triangle }
Function Hypot(A, B: Real): Real; { Pythagoras }
Function Triangle_Area(B, H: Real): Real;
Function ETArea(S: Real): Real; { Equilateral_Triangle_Area }
Function CrArea(R: Real): Real; { Circle_Area }
Function ElArea(A, B: Real): Real; { Ellipse_Area }
Function SqArea(S: Real): Real; { Square_Area }
Function RecArea(X, Y: Real): Real; { Rectangle_Area }
Function CbSfArea(S: Real): Real; { Cube_Surface_Area }
Function RecPsmSfArea(H, W, L: Real): Real; { Rectangular_Prism_Surface_Area }
Function SpSfArea(R: Real): Real; { Sphere_Surface_Area }
Function ClSfArea(R, H: Real): Real; { Cylinder_Surface_Area }
Function CnSfAreaNoBase(R, H: Real): Real; { Cone_Surface_Area_Without_Base }
Function CnSfAreaAndBase(R, H: Real): Real; { Cone_Surface_Area_With_Base }
Function ScArea(R, A: Real): Real; { Sector_Area }
Function TzArea(A, B, H: Real): Real; { Trapezoid_Area }
Function CrCfer(R: Real): Real; { Circle_Circumference }
Function ElCfer(A, B: Real): Real; { Ellipse_Circumference }
Function CbVol(S: Real): Real; { Cube_Volume }
Function RecVol(X, Y, Z: Real): Real; { Rectangle_Volume }
Function SpVol(R: Real): Real; { Sphere_Volume }
Function ClVol(R, H: Real): Real; { Cylinder_Volume }
Function CnVol(R, H: Real): Real; { Cone_Volume }
Function PsmVol(B, H: Real): Real; { Prism_Volume }
Function Distance(X1, X2, Y1, Y2: Real): Real;
Function Factorial(n: word):longint;
Function GCD(A, B: LongInt): LongInt;
 {finds the Greatest Common Divisor between 2 arguments}
Function LCM(A, B: LongInt): LongInt;
 {finds the Least Common Multiple between 2 arguments}

IMPLEMENTATION

Function Whole;
Begin
  Whole:=INT(X) = X;
End;

Function Deg2Rad;
Begin
  Deg2Rad:=D*Pi/180;
End;

Function Grad2Rad;
Begin
  Grad2Rad:=G*Pi/200;
End;

Function Deg2Grad;
Begin
  Deg2Grad:=D/0.9;
End;

Function Rad2Deg;
Begin
  Rad2Deg:=R*180/Pi;
End;

Function Rad2Grad;
Begin
  Rad2Grad:=R*200/Pi;
End;

Function Grad2Deg;
Begin
  Grad2Deg:=G*0.9;
End;

Function Csc;
Begin
  Csc:=1 / Sin(R);
End;

Function Sec;
Begin
  Sec:=1 / Cos(R);
End;

Function HypETr;
Begin
  HypETr:=( SQRT(3) * S ) / 2;
End;

Function Hypot;
Begin
  Hypot:=Sqrt((A*A)+(B*B));
End;

Function Triangle_Area;
Begin
  Triangle_Area:=0.5 * B * H;
End;

Function ETArea;
Begin
  ETArea:=( SQRT(3) * (S*S) ) / 4;
End;

Function CrArea;
Begin
  CrArea:=Pi*(R*R);
End;

Function ElArea;
Begin
  ElArea:=Pi*A*B;
End;

Function SqArea;
Begin
  SqArea:=(S*S);
End;

Function RecArea;
Begin
  RecArea:=X*Y;
End;

Function CbSfArea;
Begin
  CbSfArea:=6*(S*S);
End;

Function RecPsmSfArea;
Begin
  RecPsmSfArea:=(2*H*W) + (2*H*L) + (2*L*W);
End;

Function SpSfArea;
Begin
  SpSfArea:=4*Pi*(R*R);
End;

Function ClSfArea;
Begin
  ClSfArea:=(2*Pi*R*H) + (2*Pi*(R*R));
End;

Function CnSfAreaNoBase;
Begin
  CnSfAreaNoBase:=Pi*R*Hypot(R,H);
End;

Function CnSfAreaAndBase;
Begin
  CnSfAreaAndBase:=(Pi*R*Hypot(R,H)) + (Pi*(R*R));
End;

Function ScArea;
Begin
  ScArea:=0.5*(R*R)*A;
End;

Function TzArea;
Begin
  TzArea:=(H / 2) * (A + B);
End;

Function CrCfer;
Begin
  CrCfer:=2*Pi*R;
End;

Function ElCfer;
Begin
  ElCfer := (2*Pi) * Hypot(A,B) / 2;
End;

Function CbVol;
Begin
  CbVol:=S*S*S;
End;

Function RecVol;
Begin
  RecVol:=X*Y*Z;
End;

Function SpVol;
Begin
  SpVol:=(4/3)*Pi*(R*R*R);
End;

Function ClVol;
Begin
  ClVol:=Pi*(R*R)*H;
End;

Function CnVol;
Begin
  CnVol:=(Pi*(R*R)*H)/3;
End;

Function PsmVol;
Begin
  PsmVol:=B*H;
End;

Function Distance;
Begin
  Distance:=Sqrt(Sqr(Y2-Y1)+Sqr(X2-X1));
End;

Function Factorial(n: word):longint;
var X,F: word;
Begin
  { if (n<2) then factorial:=1
   else Factorial:=n*Factorial(n-1);}
  if (n<2) then Factorial:=1;
  F:=1;
  for X:=1 to N do F:=F*X;
  Factorial:=N;
End;

Function GCD;
  Var X, High: LongInt;
Begin
	High:=1;
	For X:=2 to A do If (A MOD X = 0)  AND	(B MOD X = 0) then High:=X;
	GCD:=High;
End;

Function LCM;
  Var Itt, Low, High: LongInt;
Begin
	High:=longMax(A,B);
	Low :=longMin(A,B);
	Itt:=High;
	While High MOD Low <> 0 do inc(High,itt);
	LCM:=High;
End;

Function Prime;
var divisor:word;
Begin
      if N = 2 then begin Prime:=TRUE; exit end;
      if (N and 1) = 0 then begin Prime:=FALSE; exit end;
      divisor:=3;
      while divisor<=sqrt(N) do
      begin
	    if N mod divisor = 0 then begin Prime:=FALSE; exit end;
	    inc(divisor,2);
      end;
      Prime:=TRUE;
End;

function pow10(P: byte): word;
var p10: word;
    i: byte;
begin
     p10:=1;
     if P=0 then pow10:=1
     else
     begin
          for i:=1 to P do p10:=p10*10;
          pow10:=p10;
     end;
end;


END.