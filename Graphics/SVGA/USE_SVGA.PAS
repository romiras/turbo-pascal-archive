
uses Graph,SVGA_,convert;

var MX,MY: integer;

BEGIN
     SetVMode(v1024x768);
     SetColor(GetMaxColor div 3);
     MX:=GetMaxX;
     MY:=GetMaxY;
     line(0,0,MX,MY);
     OutTextXY(MX div 3,MY div 2,i2s(MX)+','+i2s(MY));
     readln;
     CloseGraph;
END.