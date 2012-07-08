{$N+}
Unit Curves;
Interface
Uses Graph;
Procedure Curve (x1, y1, x2, y2, x3, y3: Integer; Segments: Word);
Procedure CubicBezierCurve (x1, y1, x2, y2, x3, y3, x4, y4: Integer; Segments: Word);
Procedure BSpline (NumPoints: Word;
	  Points: array of pointtype; Segments: Word);
Procedure Catmull_Rom_Spline (NumPoints: Word; Points: Array Of pointtype; Segments: Word);
{----------------------------------------------------------------------------}
Implementation
Procedure Curve (x1, y1, x2, y2, x3, y3: Integer; Segments: Word);
{ Draw a curve from (x1,y1) through (x2,y2) to (x3,y3) divided in
  "Segments" segments }
Var
  lsteps, ex, ey, fx, fy: LongInt;
  t1, t2: Integer;

Begin
  x2:=(x2 SHL 1)-((x1+x3) SHR 1);
  y2:=(y2 SHL 1)-((y1+y3) SHR 1);
  lsteps:=Segments;
  If (lsteps<2) then lsteps:=2;
  If (lsteps>128) then lsteps:=128;  { Clamp value to avoid overcalculation }
  ex:=(LongInt (x2-x1) SHL 17) DIV lsteps;
  ey:=(LongInt (y2-y1) SHL 17) DIV lsteps;
  fx:=(LongInt (x3-(2*x2)+x1) SHL 16) DIV (lsteps*lsteps);
  fy:=(LongInt (y3-(2*y2)+y1) SHL 16) DIV (lsteps*lsteps);
  Dec (lsteps);
  While lsteps>0 Do Begin
    t1:=x3;
    t2:=y3;
    x3:=(((fx*lsteps+ex)*lsteps) SHR 16)+x1;
    y3:=(((fy*lsteps+ey)*lsteps) SHR 16)+y1;
    Line (  t1,t2,x3,y3 );
    Dec (lsteps);
  End;
  Line (  x3,y3,x1,y1 );
End;

Procedure CubicBezierCurve (x1, y1, x2, y2, x3, y3, x4, y4: Integer; Segments: Word);
{ Draw a cubic bezier-curve using the basis functions directly }
Var
  tx1, tx2, tx3, ty1, ty2, ty3, mu, mu2, mu3, mudelta: Real;
  xstart, ystart, xend, yend, n: Integer;

Begin
  If (Segments<1) then Exit;
  If Segments>128 then Segments:=128; { Clamp value to avoid overcalculation }

  mudelta:=1/Segments;
  mu:=0;
  tx1:=-x1+3*x2-3*x3+x4; ty1:=-y1+3*y2-3*y3+y4;
  tx2:=3*x1-6*x2+3*x3;	 ty2:=3*y1-6*y2+3*y3;
  tx3:=-3*x1+3*x2;	 ty3:=-3*y1+3*y2;

  xstart:=x1;
  ystart:=y1;
  mu:=mu+mudelta;
  For n:=1 to Segments Do Begin
    mu2:=mu*mu;
    mu3:=mu2*mu;
    xend:=Round (mu3*tx1+mu2*tx2+mu*tx3+x1);
    yend:=Round (mu3*ty1+mu2*ty2+mu*ty3+y1);
    Line (  xstart, ystart, xend, yend );
    mu:=mu+mudelta;
    xstart:=xend;
    ystart:=yend;
  End;
End;

Procedure Catmull_Rom_Spline (NumPoints: Word; Points: Array Of pointtype; Segments: Word);
{ Draw a spline approximating a curve defined by the array of points.	}
{ In contrast to the BSpline this curve will pass through the points	}
{ defining is except the first and the last point. The curve will only	}
{ pass through the first and the last point if these points are given	}
{ twice after eachother, like this:				       }
{ Array of points:						       }
{									}
{  First point defined twice	       Last point defined twice 	}
{   |-----|				   |----------| 		}
{ (0,0),(0,0),(100,100),....,(150,100),(200,200),(200,200)		}
{ the curve defined by these points will pass through all the points.	}
Function Calculate (mu: Real; p0, p1, p2, p3: Integer): Integer;

Var
  mu2, mu3: Real;

Begin
  mu2:=mu*mu;
  mu3:=mu2*mu;
  Calculate:=Round ((1/2)*(mu3*(-p0+3*p1-3*p2+p3)+
			   mu2*(2*p0-5*p1+4*p2-p3)+
			   mu *(-p0+p2)+(2*p1)));
End;

Var
  mu, mudelta: Real;
  x1, y1, x2, y2, n, h: Integer;

Begin
  If (NumPoints<4) Or (NumPoints>16383) then Exit;
  mudelta:=1/Segments;
  For n:=3 to NumPoints-1 Do Begin
    mu:=0;
    x1:=Calculate (mu,Points[n-3].x,Points[n-2].x,Points[n-1].x,Points[n].x);
    y1:=Calculate (mu,Points[n-3].y,Points[n-2].y,Points[n-1].y,Points[n].y);
    mu:=mu+mudelta;
    For h:=1 to Segments Do Begin
      x2:=Calculate (mu,Points[n-3].x,Points[n-2].x,Points[n-1].x,Points[n].x);
      y2:=Calculate (mu,Points[n-3].y,Points[n-2].y,Points[n-1].y,Points[n].y);
      Line (  x1, y1, x2, y2 );
      mu:=mu+mudelta;
      x1:=x2;
      y1:=y2;
    End;
  End;
End;
Procedure BSpline (NumPoints: Word;
		   Points: Array of Pointtype; Segments: Word);
type Rmas=array[0..10] of real;
Var i,oldy,oldx,x,y,j:integer;
    part,t,xx,yy,xmin,xmax,sum:real;
    dx,dy,wx,wy,px,py,xp,yp,temp,path,zc,u:Rmas;

Function f(g:real):real;
begin
      f:=g*g*g-g;
end;

Begin
      if NumPoints>10 then exit;
    oldx:=999;
    x:=Points[0].x;
    y:=Points[0].y;
    zc[0]:=0.0;
    for i:=1 to NumPoints do
    begin
       xx:=Points[i-1].x-Points[i].x; yy:=Points[i-1].y-Points[i].y;
       t:=sqrt(xx*xx+yy*yy);
       zc[i]:=zc[i-1]+t;     {establish a proportional linear progression}
    end;

 {Calculate x & y matrix stuff}
    for i:=1 to NumPoints-1 do
    begin
       dx[i]:=2*(zc[i+1]-zc[i-1]);
       dy[i]:=2*(zc[i+1]-zc[i-1]);
    end;
    for i:=0 to NumPoints-1 do
    begin
       u[i]:=zc[i+1]-zc[i];
    end;
    for i:=1 to NumPoints-1 do
    begin
       wy[i]:=6*((Points[i+1].y-Points[i].y)/u[i]-(Points[i].y-Points[i-1].y)/u[i-1]);
       wx[i]:=6*((Points[i+1].x-Points[i].x)/u[i]-(Points[i].x-Points[i-1].x)/u[i-1]);
    end;
    py[0]:=0.0; px[0]:=0.0;    px[1]:=0; py[1]:=0;
    py[NumPoints]:=0.0; px[NumPoints]:=0.0;
    for i:=1 to NumPoints-2 do
    begin
       wy[i+1]:=wy[i+1]-wy[i]*u[i]/dy[i];
       dy[i+1]:=dy[i+1]-u[i]*u[i]/dy[i];
       wx[i+1]:=wx[i+1]-wx[i]*u[i]/dx[i];
       dx[i+1]:=dx[i+1]-u[i]*u[i]/dx[i];
    end;
    for i:=NumPoints-1 downto 1 do
    begin
       py[i]:=(wy[i]-u[i]*py[i+1])/dy[i];
       px[i]:=(wx[i]-u[i]*px[i+1])/dx[i];
    end;

 { Draw spline	}
    for i:=0 to NumPoints-1 do
    begin
       for j:=0 to 30 do
       begin
	  part:=zc[i]-(((zc[i]-zc[i+1])/30)*j);
	  t:=(part-zc[i])/u[i];
	  part:=t*Points[i+1].y+(1-t)*Points[i].y+u[i]*u[i]*(f(t)*py[i+1]+f(1-t)*py[i])/6.0;
	  y:=round(part);
	  part:=zc[i]-(((zc[i]-zc[i+1])/30)*j);
	  t:=(part-zc[i])/u[i];
	  part:=t*Points[i+1].x+(1-t)*Points[i].x+u[i]*u[i]*(f(t)*px[i+1]+f(1-t)*px[i])/6.0;
	  x:=round(part);
	  if oldx<>999 then line(oldx,oldy,x,y);
	  oldx:=x;
	  oldy:=y;
	end;
     end;
  end;
END.