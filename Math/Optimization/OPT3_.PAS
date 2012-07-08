{$F+}{$N+}{$G+}
Uses Crt,Graph;
Type MyFunction = function(x1,x2:extended):extended;
Var z : extended;
    Message : string;
    a0,b0,k : extended;
    f:text;
    c:char;
    dl,eps,aAxe,bAxe,cAxe,dAxe : extended;
    betta1,betta2,savex1,savex2,dx11,dx21,dx12,dx22,x01,x02,x11,x12,x21,x22:extended;
    alfaAxe : word;
    i:integer;

procedure _EGAVGA_driver;external;
{$L egavga.obj}
Procedure InitGraphics;
var GraphDriver,GraphMode: integer;
begin
  if registerBGIdriver(@_EGAVGA_driver)<0 then
      begin writeln(' No graphic detected ');halt(1) end;
  DetectGraph(GraphDriver,GraphMode);
  if GraphDriver<EGA then begin
    writeln('Необходим графический адаптер не ниже EGA');  halt;
  end;
  GraphDriver:=EGA;
  InitGraph(GraphDriver,GraphMode,'');
  if GraphResult <> grOk then exit;
end;

Function Ellipse(x1,x2:extended):extended;
Begin
 Ellipse := sqr(((x1-aAxe)*cos(alfaAxe*pi/180)+(x2-bAxe)*sin(alfaAxe*pi/180))/cAxe)+
        sqr(((x2-bAxe)*cos(alfaAxe*pi/180)-(x1-aAxe)*sin(alfaAxe*pi/180))/dAxe);
End;

Function Rozenbrouk(x1,x2 : extended):extended;
Begin
 Rozenbrouk := sqr(x2-x1*x1)+sqr(1-x1);
End;
function grad1(x1,x2:extended;f0:MyFunction):extended;
Var
   f1,f2,Delta    : extended;
Begin
     Delta := 1E-13;
     f1 := (f0(X1+Delta,X2)-f0(X1,X2))/Delta;
     repeat
       Delta := Delta/2;
       f2 := f1;
       f1 := (f0(X1+Delta,X2)-f0(X1,X2))/Delta;
     until Abs(f1-f2)<>0;
     grad1 := f1;
End;

function grad2(x1,x2:extended;f0:MyFunction):extended;
Var
   f1,f2,Delta    : extended;
Begin
     Delta := 1E-13;
     f1 := (f0(X1,X2+Delta)-f0(X1,X2))/Delta;
     repeat
       Delta := Delta/2;
       f2 := f1;
       f1 := (f0(X1,X2+Delta)-f0(X1,X2))/Delta;
     until Abs(f1-f2)<>0;
     grad2 := f1;
End;

Procedure local(var x01,x02,x11,x12:extended;f0:MyFunction);
var f1,f2,dx1,dx2 : extended;
Begin
  dx1 := x11-x01;
  dx2 := x12-x02;
  repeat
    x11 := x11+dx1;
    x12 := x12+dx2;
  until f0(x11,x12)>f0(x01,x02);
End;

Procedure min(var x01,x02,x11,x12:extended;f0:MyFunction);
Var f1,f2,x21,x22,x31,x32,dx1,dx2 : extended;
Begin
  if x01<>x11 then
   begin
     dx1 := abs(cos(Arctan((x12-x02)/(x11-x01))));
     dx2 := abs(sin(Arctan((x12-x02)/(x11-x01))));
   end
  else
   begin
     dx1 := 0;
     dx2 := 1;
   end;
     if (x11 > x01) and (x12 < x02) then dx2:=-dx2
     else
      if x11 < x01 then
       begin
         dx1:=-dx1;
         if x12 <x02 then dx2:=-dx2;
       end;
  x21 := x01+dx1*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
  x22 := x02+dx2*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
  x31 := x11-dx1*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
  x32 := x12-dx2*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
  f1 := f0(x21,x22);
  f2 := f0(x31,x32);
  repeat
    if f1>f2 then
     begin
       x01 := x21;
       x02 := x22;
       x21 := x31;
       x22 := x32;
       f1 := f2;
       x31 := x11-dx1*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
       x32 := x12-dx2*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
       f2 := f0(x31,x32);
     end
    else
     begin
       x11 := x31;
       x12 := x32;
       x31 := x21;
       x32 := x22;
       f2 := f1;
       x21 := x01+dx1*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
       x22 := x02+dx2*sqrt(sqr(x01-x11)+sqr(x02-x12))*(3-sqrt(5))/2;
       f1 := f0(x21,x22);
     end;
  until sqrt(sqr(x01-x11)+sqr(x02-x12))<eps;
End;

procedure Grad(var a0,b0 : extended;eps,h,xBegin,yBegin,k : extended;f0 : MyFunction);
var dx1,dx2,x11,x12,x21,x22:extended;
    i:integer;
    savex1,savex2:extended;
begin
  setcolor(WHITE);
  x21:=a0;
  x22:=b0;
  i:=0;
  writeln(f,'Начальная точка : (',x21:6:3,',',x22:6:3,')');
  repeat
    inc(i);
    x11:=x21;
    x12:=x22;
    dx1:=grad1(x11,x12,f0);
    dx2:=grad2(x11,x12,f0);
    x21:=x11-dx1;
    x22:=x12-dx2;
    savex1:=x11;
    savex2:=x12;
    local(x11,x12,x21,x22,f0);
    min(x11,x12,x21,x22,f0);
    x11:=savex1;
    x12:=savex2;
    line(round(x11*k+xBegin),round(yBegin-x12*k),round(x21*k+xBegin),round(yBegin-x22*k));
    writeln(f,i:3,'-я точка : (',x21:6:3,',',x22:6:3,')');
  until sqrt(dx1*dx1+dx2*dx2)<eps;
  writeln(f,'Число итераций - ',i:3);
end;

procedure Fletcher(var a0,b0 : extended;eps,h,xBegin,yBegin,k : extended;f0 : MyFunction);
Var Message : string;
    betta1,betta2,savex1,savex2,dx11,dx21,dx12,dx22,x01,x02,x11,x12,x21,x22:extended;
    i:integer;
    s1,s2:extended;
begin
  x21:=a0;
  x22:=b0;
  i:=0;
  s1:=0;
  s2:=0;
  betta1:=0;
  dx11:=0;
  dx12:=0;
  setcolor(WHITE);
  writeln(f,'Начальная точка : (',x21:6:3,',',x22:6:3,')');
  repeat
    inc(i);
    x11:=x21;
    x12:=x22;
    dx21:=dx11;
    dx22:=dx12;
    dx11:=-grad1(x11,x12,f0);
    dx12:=-grad2(x11,x12,f0);
    if i <> 1 then betta1:=(dx11*dx11+dx12*dx12)/(dx21*dx21+dx22*dx22);
    s1:=dx11+betta1*s1;
    s2:=dx12+betta1*s2;
    x21:=x11+s1;
    x22:=x12+s2;
    savex1:=x11;
    savex2:=x12;
    local(x11,x12,x21,x22,f0);
    min(x11,x12,x21,x22,f0);
    x11:=savex1;
    x12:=savex2;
    line(round(x11*k+xBegin),round(yBegin-x12*k),round(x21*k+xBegin),round(yBegin-x22*k));
    writeln(f,i:3,'-я точка : (',x21:6:3,',',x22:6:3,')');
  until sqrt(dx11*dx11+dx12*dx12)<eps;
  writeln(f,'Число итераций - ',i:3);
end;

(*
begin
  InitGraphics;
  ClearDevice;
  aAxe := 1;
  bAxe := -5;
  cAxe := 1;
  dAxe := 4;
  alfaAxe := 145;
  eps := 0.001;
  dl  := 1;
  a0:= 0;
  b0:=-2;
  DoEllipses(200,-75,1,-5,1,4,60,145,20,LIGHTGREEN,LIGHTCYAN,CYAN);
  assign(f,'ellipse1.fle');
  rewrite(f);
  Fletcher(a0,b0,eps,0.5,200,-75,60,Ellipse);
  close(f);
end;
  *)
Procedure MyEllipse
(xBegin,yBegin:integer;x0,y0,alfa,a,b,kAxe : extended;Message : string;DrawColor,TextColor: word;
   var MaxX,MaxY,MinX,MinY:extended);
Var sign,i,j : shortint;
    x,y,x1,y1 : extended;
    OldColor : word;
Begin
  OldColor := GetColor;
  sign := 1;
  SetColor(DrawColor);
  if (a<>0) and (b <> 0) then
   begin
     x := -a;
     y := sqrt(1-x*x/(a*a))*b;
     x1 := xBegin+kAxe*(x0+x*cos(alfa*pi/180)-y*sin(alfa*pi/180));
     y1 := yBegin-kAxe*(y0+y*cos(alfa*pi/180)+x*sin(alfa*pi/180));
     MaxX := x1;
     MaxY := y1;
     MinX := x1;
     MinY := y1;
     for j := 1 to 2 do
      begin
        if j = 2 then sign := -1;
           x := -a;
           y := 0;
           x1 := xBegin+kAxe*(x0+x*cos(alfa*pi/180)-y*sin(alfa*pi/180));
           y1 := yBegin-kAxe*(y0+y*cos(alfa*pi/180)+x*sin(alfa*pi/180));
           MoveTo(round(x1),round(y1));
       for i := -99 to 99 do
            begin
              x := a*i/100;
              y := sign*sqrt(1-x*x/(a*a))*b;
              x1 := xBegin+kAxe*(x0+x*cos(alfa*pi/180)-y*sin(alfa*pi/180));
              y1 := yBegin-kAxe*(y0+y*cos(alfa*pi/180)+x*sin(alfa*pi/180));
              if x1 > MaxX then MaxX := x1
               else
                if x1 < MinX then MinX := x1;
              if y1 > MaxY then MaxY := y1
               else
                if y1 < MinY then MinY := y1;
              LineTo(round(x1),round(y1));
            end;
        x := a;
        y := 0;
        x1 := xBegin+kAxe*(x0+x*cos(alfa*pi/180)-y*sin(alfa*pi/180));
        y1 := yBegin-kAxe*(y0+y*cos(alfa*pi/180)+x*sin(alfa*pi/180));
        LineTo(round(x1),round(y1));
      end
   end
   else
  PieSlice(xBegin+round(kAxe*x0),yBegin-round(kAxe*y0),0,360,2);
  SetColor(TextColor);
  SetColor(OldColor);
End;

(*Procedure DoEllipses(xBegin,yBegin:integer;x0,y0,a,b,kAxe,alfa:extended;step,DrawColor,TextColor,NetColor:word);
Var MaxX,MaxY,MinX,MinY : extended;

Procedure DoNet(MaxX,MaxY,MinX,MinY:integer;step,NetColor:word);
Var OldColor : word;
    i,j,dx,dy :extended;
    Message : string;
Begin
  OldColor := GetColor;
  SetLineStyle(3,1,2);
  SetColor(NetColor);
  dx := (MaxX - MinX)/step;
  dy := (MaxY - MinY)/step;
  i := MinX;
  repeat
    j := MinY;
    repeat
      Line(round(i),MinY,round(i),MaxY);
      Str((i-xBegin)/kAxe:5:1,Message);
      SetTextStyle(1,1,1);
      OutTextXY(round(i),MaxY+5,Message);
      Line(MinX,round(j),MaxX,round(j));
      Str((-j+yBegin)/kAxe:5:1,Message);
      SetTextStyle(0,0,0);
      OutTextXY(MinX-50,round(j),Message);
      j := j+dy;
    until(j>=MaxY);
    i := i+dx;
  until(i>=MaxX);
  Rectangle(MaxX,MaxY,MinX,MinY);
  SetTextStyle(0,0,0);
  SetColor(DrawColor);
  Message := 'X2';
  OutTextXY(MinX,MinY-20,Message);
  Message := 'X1';
  OutTextXY(MaxX+20,MaxY,Message);
  SetLineStyle(0,0,0);
  SetColor(OldColor);
  SetViewPort(MaxX,MaxY,MinX,MinY,ClipOn);
End;

Begin
  Message := 'Z=  1.0';
  MyEllipse(xBegin,yBegin,x0,y0,alfa,a,b,kAxe,Message,DrawColor,TextColor,MaxX,MaxY,MinX,MinY);
  DoNet(trunc(MaxX),trunc(MaxY),trunc(MinX),trunc(MinY),step,NetColor);
  for i := 3 to 10 do
   begin
     z := round(Exp(i/10)*10)/10;
     Str(z:5:1,Message);
     Message := 'Z='+Message;
     MyEllipse(xBegin,yBegin,x0,y0,alfa,a/z,b/z,kAxe,Message,DrawColor,TextColor,MaxX,MaxY,MinX,MinY);
   end;
   MyEllipse(xBegin,yBegin,x0,y0,alfa,0,0,kAxe,'',DrawColor,TextColor,MaxX,MaxY,MinX,MinY);
End;
  *)
Procedure MyRozenbrouk
(xBegin,yBegin:integer;f,kAxe : extended;Message : string;DrawColor,TextColor: word);
Var sign,i,j : longint;
    x,y,x1,y1,temp : extended;
    OldColor : word;
    first : boolean;
Begin
  OldColor := GetColor;
  sign := 1;
  SetColor(DrawColor);
  if f <> 0 then
   begin

     for j := 1 to 2 do
      begin
        if j = 2 then sign := -1;
        first := TRUE;
        for i := -2000 to 2000 do
         begin
           x := i/500;
           temp := f-(1-x)*(1-x) ;
           if temp >= 0 then
            begin
              y := sign*sqrt(temp)/10+x*x;
              if (i = 0) and (j=1) then
               begin
                 SetColor(TextColor);
                 SetColor(DrawColor);
               end;
              if not first  then LineTo(xBegin+round(kAxe*x),yBegin-round(kAxe*y))
               else
                begin
                  MoveTo(xBegin+round(kAxe*x),yBegin-round(kAxe*y));
                  first := FALSE;
                end;
            end
            else first := TRUE;
         end;
      end;
   end
   else
   PieSlice(xBegin+round(kAxe),yBegin-round(kAxe),0,360,2);
   SetColor(OldColor);
End;

Procedure DoEllipses(xBegin,yBegin:integer;x0,y0,a,b,kAxe,alfa:extended;step,DrawColor,TextColor,NetColor:word);
Var MaxX,MaxY,MinX,MinY : extended;

Procedure DoNet(MaxX,MaxY,MinX,MinY:integer;step,NetColor:word);
Var OldColor : word;
    i,j,dx,dy :extended;
    Message : string;
Begin
  OldColor := GetColor;
  SetLineStyle(3,1,2);
  SetColor(NetColor);
  dx := (MaxX - MinX)/step;
  dy := (MaxY - MinY)/step;
  i := MinX;
  repeat
    j := MinY;
    repeat
      Line(round(i),MinY,round(i),MaxY);
      Str((i-xBegin)/kAxe:5:1,Message);
      SetTextStyle(1,1,1);
      OutTextXY(round(i),MaxY+5,Message);
      Line(MinX,round(j),MaxX,round(j));
      Str((-j+yBegin)/kAxe:5:1,Message);
      SetTextStyle(0,0,0);
      OutTextXY(MinX-50,round(j),Message);
      j := j+dy;
    until(j>=MaxY);
    i := i+dx;
  until(i>=MaxX);
  Rectangle(MaxX,MaxY,MinX,MinY);
  SetTextStyle(0,0,0);
  SetColor(DrawColor);
  Message := 'X2';
  OutTextXY(MinX,MinY-20,Message);
  Message := 'X1';
  OutTextXY(MaxX+20,MaxY,Message);
  SetLineStyle(0,0,0);
  SetColor(OldColor);
  SetViewPort(MaxX,MaxY,MinX,MinY,ClipOn);
End;

Begin
  Message := 'Z=  1.0';
  MyEllipse(xBegin,yBegin,x0,y0,alfa,a,b,kAxe,Message,DrawColor,TextColor,MaxX,MaxY,MinX,MinY);
  DoNet(trunc(MaxX),trunc(MaxY),trunc(MinX),trunc(MinY),step,NetColor);
  for i := 3 to 10 do
   begin
     z := round(Exp(i/10)*10)/10;
     Str(z:5:1,Message);
     Message := 'Z='+Message;
     MyEllipse(xBegin,yBegin,x0,y0,alfa,a/z,b/z,kAxe,Message,DrawColor,TextColor,MaxX,MaxY,MinX,MinY);
   end;
   MyEllipse(xBegin,yBegin,x0,y0,alfa,0,0,kAxe,'',DrawColor,TextColor,MaxX,MaxY,MinX,MinY);
End;
Procedure DoRozenbrouk(xBegin,yBegin:integer;kAxe:extended;step,DrawColor,TextColor,NetColor:word);
Var MaxX,MaxY,MinX,MinY : extended;

Procedure DoNet(MaxX,MaxY,MinX,MinY:integer;step,NetColor:word);
Var OldColor : word;
    i,j,dx,dy :extended;
    Message : string;
Begin
  OldColor := GetColor;
  SetColor(NetColor);
  SetLineStyle(3,1,2);
  dx := (MaxX - MinX)/step;
  dy := (MaxY - MinY)/step;
  i := MinX;
  repeat
    j := MinY;
    repeat
      Line(round(i),MinY,round(i),MaxY);
      Str(((i-xBegin-MinX)/kAxe):5:1,Message);
      SetTextStyle(1,1,1);
      OutTextXY(round(i),MaxY+5,Message);
      Line(MinX,round(j),MaxX,round(j));
      Str(((yBegin-j+MinY)/kAxe):5:1,Message);
      SetTextStyle(0,0,0);
      OutTextXY(MinX-50,round(j),Message);
      j := j+dy;
    until(j>=MaxY);
    i := i+dx;
  until(i>=MaxX);
  Rectangle(MaxX,MaxY,MinX,MinY);
  SetTextStyle(0,0,0);
  SetColor(DrawColor);
  Message := 'X2';
  OutTextXY(MinX,MinY-20,Message);
  Message := 'X1';
  OutTextXY(MaxX+20,MaxY,Message);
  SetLineStyle(0,0,0);
  SetColor(OldColor);
End;

Begin
  Message := 'Z=  1.0';
  DoNet(600,420,50,20,step,NetColor);
  SetViewPort(50,20,600,420,ClipOn);
  MyRozenbrouk(xBegin,yBegin,0,kAxe,'',DrawColor,TextColor);
  MyRozenbrouk(xBegin,yBegin,1,kAxe,'Z=1',DrawColor,TextColor);
  for i := -1 to 2 do
   begin
     Str(exp(i)*10:5:2,Message);
     Message := 'Z='+Message;
     MyRozenbrouk(xBegin,yBegin,exp(i)*10,kAxe,Message,DrawColor,TextColor);
   end;
End;
begin
  InitGraphics;
  ClearDevice;
  aAxe := 9;
  bAxe := 7;
  cAxe := 1;
  dAxe := 3;
  alfaAxe := 105;
  eps := 0.001;
  dl  := 1;
  a0:= 7;
  b0:= 8;
  DoEllipses(-527,900,aAxe,bAxe,cAxe,dAxe,95,alfaAxe,20,magenta,magenta,magenta);
  assign(f,'Ellipse1.fle');
  rewrite(f);
  Fletcher(a0,b0,eps,dl,-527,900,95,Ellipse);
  close(f);
  SetViewPort(0,0,GetMaxX,GetMaxY,ClipOff);
  readln;
  ClearDevice;
  a0:=11;
  b0:=6;
  DoEllipses(-527,900,aAxe,bAxe,cAxe,dAxe,95,alfaAxe,20,magenta,magenta,magenta);
  assign(f,'Ellipse2.fle');
  rewrite(f);
  Fletcher(a0,b0,eps,dl,-527,900,95,Ellipse);
  close(f);
  SetViewPort(0,0,GetMaxX,GetMaxY,ClipOff);
  readln;
  ClearDevice;
  a0:=-1.2;
  b0:=-1;
  DoRozenbrouk(250,350,100,20,magenta,magenta,magenta);
  assign(f,'rozen1.pau');
  rewrite(f);
  Fletcher(a0,b0,eps,dl,250,350,100,Rozenbrouk);
  close(f);
  readln;
  SetViewPort(0,0,GetMaxX,GetMaxY,ClipOff);
  ClearDevice;
  a0:=-1;
  b0:=0;
  assign(f,'rozen2.pau');
  rewrite(f);
  DoRozenbrouk(250,350,100,20,magenta,magenta,magenta);
  Fletcher(a0,b0,eps,dl,250,350,100,Rozenbrouk);
  close(f);
  readln;
  SetViewPort(0,0,GetMaxX,GetMaxY,ClipOff);
  ClearDevice;
  a0:=7;
  b0:=8;
  DoEllipses(-527,900,aAxe,bAxe,cAxe,dAxe,95,alfaAxe,20,magenta,magenta,magenta);
  assign(f,'ellipse1.gra');
  rewrite(f);
  Grad(a0,b0,eps,0.5,-527,900,95,Ellipse);
  close(f);
  readln;
  SetViewPort(0,0,GetMaxX,GetMaxY,ClipOff);
  ClearDevice;
  a0:=11;
  b0:=6;
  DoEllipses(-527,900,aAxe,bAxe,cAxe,dAxe,95,alfaAxe,20,magenta,magenta,magenta);
  assign(f,'ellipse2.gra');
  rewrite(f);
  Grad(a0,b0,eps,0.5,-527,900,95,Ellipse);
  close(f);
  readln;
  ClearDevice;
  a0:=-1.2;
  b0:=-1;
  DoRozenbrouk(250,350,100,20,magenta,magenta,magenta);
  assign(f,'rozen1.gra');
  rewrite(f);
  Grad(a0,b0,eps,0.5,250,350,100,Rozenbrouk);
  close(f);
  readln;
  SetViewPort(0,0,GetMaxX,GetMaxY,ClipOff);
  ClearDevice;
  a0:=-1;
  b0:=0;
  DoRozenbrouk(250,350,100,20,magenta,magenta,magenta);
  assign(f,'rozen2.gra');
  rewrite(f);
  Grad(a0,b0,eps,0.5,250,350,100,Rozenbrouk);
  close(f);
  readln;
  CloseGraph;
end.