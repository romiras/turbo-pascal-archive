{
 To try out the program, some complex constants you can
 use are -1, -0.1+0.8i, 0.3-0.5i, -1.139+0.238i.  ie, when
 asked for the real part, enter 0.3.  For the imaginary,
 enter -.5
}

program julia;
{$N+,E-}
uses crt, Graph;
Type Real = single;
var
     cx, cy,
     xo, yo, x1, y1 : real;
     a, b, i, orb   : word;
     gd, gm: integer;
const
  MX = 640; { the box we want to plot on the screen }
  MY = 480;
{  cx = 0.3;
  cy = -0.5;}

procedure InitGraphics;
begin
  gd := InstallUserDriver('SVGA256', nil);
  if gd = grError then
     Halt (1);
  gm := 2; {640x480x256}
  InitGraph(gd,gm,''); {  SetVMode(2);}
  if GraphResult <> grOk then
     Halt (2);
end;

begin
  write('Real part: ');
  readln(CX);
  write('Imaginary part: ');
  readln(CY);

  InitGraphics;

  FOR B := 0 TO Pred(MY)  do    {X screen coordinate}
    FOR A := 0 TO Pred(MX) do   {Y screen coordinate}
    begin
      XO := -2.0 + A / MX * 4.0; {'X complex plane coordinate}
      YO :=  2.0 - B / MY * 4.0;  {'Y complex plane coordinate}
      Orb := 0;
      FOR I := 1 TO 255 do     {iterations for 255 colors}
      begin
        X1 := Sqr(XO) - Sqr(YO) + CX;
        Y1 := 2.0 * XO * YO + CY;
        IF Sqr(X1) + Sqr(Y1) > 8.0 THEN  {orbit escapes, plot it}
        begin
          Orb := I;
          break;
        END;
        XO := X1;
        YO := Y1;
      end;
      putpixel (round(A), round(B), Orb);  {plot orbit}
    end;

  readln;
  CloseGraph;
end.