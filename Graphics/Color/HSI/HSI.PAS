program HSI; { by Bret Mulvey }

{ illustrates conversion of Hue-Saturation-Intensity to Red-Green-Blue }

  uses
    Crt,VGA256;

  procedure hsi2rgb(h,s,i: real; var C: ColorValue);
    var
      t: real;
      rv,gv,bv: real;
  begin { procedure hsi2rgb }
    t:=2*pi*h;
    rv:=1+s*sin(t-2*pi/3);
    gv:=1+s*sin(t);
    bv:=1+s*sin(t+2*pi/3);
    t:=63.999*i/2;
    C.Rvalue:=trunc(rv*t);
    C.Gvalue:=trunc(gv*t);
    C.Bvalue:=trunc(bv*t);
  end; { procedure hsi2rgb }

  var
    h,s,i: real;
    x,y,z: integer;
    C: ColorValue;
    p: vgaPaletteType;
    ch: char;
    xx,yy: integer;
    ii,jj: integer;
    K: integer;
    t: Real;

begin

{ create grey scale }
  for z:=0 to 15 do with p[z] do begin Rvalue:=z*4; Gvalue:=z*4; Bvalue:=z*4; end;

{ create HSI spectrum }
  for x:=0 to 3 do { four different intensities }
  for y:=0 to 2 do { three different saturations }
  for z:=0 to 19 do { twenty different hues }
    begin
{ determine H,S,I between 0 and 1 }
      h:=z/20;
      s:=(y+1)/3;
      i:=(x+1)/4;
{ calculate and store R,G,B values }
      hsi2rgb(h,s,i,C);
      p[16+z+20*y+60*x]:=C;
    end;

  InitVGA256;
  vgaSetAllPalette(p);

{ draw grey scale }
  for x:=0 to 15 do
    begin
      xx:=200; yy:=x*8;
      for ii:=0 to 7 do
      for jj:=0 to 7 do
        vgaPutPixel(xx+ii,yy+jj,15-x);
    end;

{ draw spectrum }
  for z:=0 to 19 do
  for x:=0 to 3 do
  for y:=0 to 2 do
    begin
      K:=16+z+20*y+60*x;
      xx:=8*x+40*(z mod 5);
      yy:=8*y+32*(z div 5);
      for ii:=0 to 7 do
      for jj:=0 to 7 do
        vgaPutPixel(xx+ii,yy+jj,K);
    end;

  ch:=ReadKey; if ch=#0 then ch:=ReadKey;
  CloseVGA256;
end.