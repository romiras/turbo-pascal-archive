
Unit SVGA_;

Interface
Uses Graph;

const
{     Path:string[80]='E:\BP7\BGI';}
     { 256 colors }
     v320x200   : byte = 0;
     v640x480   : byte = 2;
     v800x600   : byte = 3;
     v1024x768  : byte = 4;
     v1280x1024 : byte = 5;

Procedure SetVMode(Mode: byte);

Implementation

procedure SVGA_DRV; external;
{$L svgadrv.obj}

Procedure SetVMode;
Var Gd,Gm: integer;
Begin
     Gd:= InstallUserDriver('SVGA256',nil);
     if Gd= grError { Table full? } then
     begin
          writeln('Error of installing driver.');
          Halt(1);
     end;
     if RegisterBGIdriver(@SVGA_DRV) < 0 then
     begin
          Writeln(GraphErrorMsg(GraphResult));
          halt(2);
     end;
     Gm:=Mode;
     InitGraph(Gd,Gm,'');
End;

END.