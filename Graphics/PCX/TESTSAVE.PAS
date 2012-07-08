program WritePCX;

uses
    Graph, PCX16,crt,dos;
{-------------- DrawHorizBars ----------}
procedure DrawHorizBars;
var   i, Color : word;
begin
     cleardevice;
     Color := 15;
     for i := 0 to 15 do
	 begin
	      setfillstyle (solidfill,Color);
	      bar (0,i*30,639,i*30+30);       { 16*30 = 480 }
	      dec (Color);
	 end;
end;
{-------------- Main -------------------}
var
   NameW : PathStr;
   Gd,Gm : integer;
begin
	writeln;
	if (ParamCount = 0) then
	begin
	     write ('Enter name of PCX picture file to write: ');
	     readln (NameW);
	     writeln;
	end
	else NameW:=paramstr(1);
	if (Pos ('.', NameW) = 0) then
	   NameW := Concat(NameW, '.pcx');

     Gd:=VGA;
     Gm:=VGAhi; {640x480, 16 colors}
     initgraph (Gd,Gm,'..\bgi');  { path to your EGAVGA.BGI }

     DrawHorizBars;

     readln;
     Save_PCX16(NameW);
     closegraph;		    { Close graphics	}
end.  { Write_PCX }