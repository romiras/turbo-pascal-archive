
Unit PCX16;
{  The following display modes are supported:
         Mode      TP GraphMode     Resolution    Colors
         ~~~~      ~~~~~~~~~~~~     ~~~~~~~~~~    ~~~~~~
         $04       CGAC0 to C3      320 x 200         4
         $06       CGAHi            640 x 200         2
         $0D        ---             320 x 200        16
         $0E       EGALo/VGALo      640 x 200        16
         $10       EGAHi/VGAMed     640 x 350        16
         $12       VGAHi            640 x 480        16
         $13        ---             320 x 200       256
   Mode $13 is supported only for files containing palette information,
   i.e. not those produced by versions of Paintbrush earlier than 3.0.}

INTERFACE

Procedure Load_PCX16(FN: string);
Procedure Save_PCX16(Name: string);

{========================================================================}
IMPLEMENTATION
Uses Graph;
var    RGBpal: array[0..15,0..2] of byte;
       scratch     : pointer;
       repeatcount : byte;
       page_addr,
       bytes_per_line,
       datalength,
       columncount,
       plane,
       video_index : word;
const  buffsize = 65521;   { Largest possible }
{ ====================== EGA/VGA 16-color files ========================= }
procedure DECODE_16; assembler;
asm
push   bp
{The first section is initialization done on each run
through the input buffer.}
@startproc:
mov    bp, plane           { plane in BP }
mov    es, page_addr       { video display segment }
mov    di, video_index     { index into video segment }
mov    ah, byte ptr bytes_per_line  { line length in AH }
mov    dx, columncount     { column counter }
mov    bx, datalength      { no. of bytes to read }
xor    cx, cx              { clean up CX for loop counter }
mov    cl, repeatcount     { count in CX }
push   ds                  { save DS }
lds    si, scratch         { input buffer pointer in DS:SI }
add    bx, si
cld                        { clear DF for stosb }
cmp    cl, 0               { was last byte a count? }
jne    @multi_data         { yes, so next is data }
jmp    @getbyte            { no, so find out what next is }
{ -------------- Procedure to write EGA/VGA image to video -------------- }
@writebyte:
stosb                      { AL into ES:DI, inc DI }
inc    dl                  { increment column }
cmp    dl, ah              { reached end of scanline? }
je     @doneline           { yes }
loop   @writebyte          { no, do another }
jmp    @getbyte            {   or get more data }
@doneline:
shl    bp, 1               { shift to next plane }
cmp    bp, 8               { done 4 planes? }
jle    @setindex           { no }
mov    bp, 1               { yes, reset plane to 1 but don't reset index }
jmp    @setplane
@setindex:
sub    di, dx              { reset to start of line }
@setplane:
push   ax                  { save AX }
cli                        { no interrupts }
mov    ax, bp              { plane is 1, 2, 4, or 8 }
mov    dx, 3C5h            { sequencer data register }
out    dx, al              { mask out 3 planes }
sti                        { enable interrupts }
pop    ax                  { restore AX }
xor    dx, dx              { reset column count }
loop   @writebyte          { do it again, or fetch more data }
@getbyte:                  { last byte was not a count }
cmp    si, bx              { end of input buffer? }
je     @exit               { yes, quit }
lodsb                      { get a byte from DS:SI into AL, increment SI }
cmp    al, 192             { test high bits }
jb     @one_data           { not set, it's data to be written once }
 { It's a count byte: }
xor    al, 192             { get count from 6 low bits }
mov    cl, al              { store repeat count }
cmp    si, bx              { end of input buffer? }
je     @exit               { yes, quit }
@multi_data:
lodsb                      { get data byte }
jmp    @writebyte          { write it CL times }
@one_data:
mov    cl, 1               { write byte once }
jmp    @writebyte
{ ---------------------- Finished with buffer --------------------------- }
@exit:
pop    ds                  { restore Turbo's data segment }
mov    plane, bp           { save status for next run thru buffer }
mov    repeatcount, cl
mov    columncount, dx
mov    video_index, di
pop    bp
end;  { asm }
{ ============= Main procedure for 16-color files =============== }
procedure Load_PCX16;
var    entry, gun, pcxcode: byte;
       palbuf: array[0..66] of byte;
       pcxfile: file;
       res: word;
begin  { READ_PCX_FILE }
       assign(pcxfile, FN);
{$I-}  reset(pcxfile, 1); {$I+}
       if IOresult<>0 then exit;
       getmem(scratch, buffsize);        { Allocate scratchpad }
       blockread(pcxfile, scratch^, 128, res);{ Get header into scratchpad }
       if res<>128 then exit;
       move(scratch^, palbuf, 67);
       bytes_per_line:= palbuf[66];
       video_index:= 0;
       port[$3C4]:= 2;           { Index to map mask register }
       plane:= 1;                { Initialize plane }
       port[$3C5]:= plane;       { Set sequencer to mask out other planes }
       for entry:= 0 to 15 do
       begin
               for gun:= 0 to 2 do
               begin
                    pcxcode:= palbuf[16 + entry * 3 + gun];
                    { Get primary color value }
                    RGBpal[entry,gun]:=pcxcode shr 2;
               end;
       end;
{ ---------------- Read and decode the image data ----------------------- }
       { Initialize assembler vars. }
       repeatcount:= 0;
       columncount:= 0;
       repeat
               blockread(pcxfile, scratch^, buffsize, datalength);
               Decode_16; { Call assembler routine }
       until EOF(pcxfile);
       close(pcxfile);
       port[$3C5]:= $F; { Reset mask map }
       freemem(scratch,buffsize); { Discard scratchpad }
end;

procedure Save_PCX16;
type
    ArrayPal  =array [0..15, 0..2] of byte; { R, G, B }
const
       MAX_WIDTH =4000; {arbitrary - maximum width (in bytes) of a PCX image }
       INTENSTART= $05;
       BLUESTART = $55;
       GREENSTART= $A5;
       REDSTART  = $F5;
type
{ comments from ZSoft ShowPCX pascal example}
       Pcx_Header=record
       Manufacturer: byte;
{ Always 10 for PCX file }
       Version: byte;
{      2 - old PCX - no palette (not used anymore),
       3 - no palette,
       4 - Microsoft Windows - no palette
        (only in old files, new Windows version uses 3),
       5 - with palette
}
       Encoding: byte;
{ 1 is PCX, it is possible that we may add additional encoding
 methods in the future }
       Bits_per_pixel: byte;
{ Number of bits to represent a pixel (per plane) - 1, 2, 4, or 8 }
       Xmin: integer; { Image window dimensions (inclusive) }
       Ymin: integer; { Xmin, Ymin are usually zero (not always)}
       Xmax: integer;
       Ymax: integer;
       Hdpi: integer; { Resolution of image (dots per inch) }
       Vdpi: integer; { Set to scanner resolution - 300 is default }
       ColorMap: ArrayPal;
{ RGB palette data (16 colors or less) 256 color palette
  is appended to end of file }
       Reserved: byte;
{ (used to contain video mode) now it is ignored - just set to zero }
       Nplanes: byte; { Number of planes }
       Bytes_per_line_per_plane: integer;
{ Number of bytes to allocate for a scanline plane.
  MUST be an an EVEN number! Do NOT calculate from Xmax-Xmin! }
       PaletteInfo: integer;
{ 1=black & white or color image, 2=grayscale image - ignored in PB4,
  PB4+ palette must also be set to shades of gray! }
       HscreenSize: integer;
{ added for PC Paintbrush IV Plus ver 1.0,  }
       VscreenSize: integer;
{ PC Paintbrush IV ver 1.02 (and later)}
{ I know it is tempting to use these fields to determine what video mode
should be used to display the image - but it is NOT recommended since the
fields will probably just contain garbage. It is better to have the user
install for the graphics mode he wants to use... }
       Filler: array [74..127] of byte; { Just set to zeros }
end; {RECORD}

       Array80   =array [1..80] of byte;
       ArrayLnImg=array [1..326] of byte;
{ 6 extra bytes at beginng of line that BGI uses for size info}
       Line_Array=array [0..MAX_WIDTH] of byte;
       ArrayLnPCX=array [1..4] of Array80;
var
       PCXName : File;
       Header  : Pcx_Header;
       ImgLn   : ArrayLnImg;
       PCXLn   : ArrayLnPCX;
       RedLn,
       BlueLn,
       GreenLn,
       IntenLn : Array80;
       Img     : pointer;

Procedure BuildHeader;
const
       PALETTEMAP: ArrayPal=
{  R   G    B  }
(($00, $00, $00),  {  Black       }
 ($00, $00, $AA),  {  Blue        }
 ($00, $AA, $00),  {  Green       }
 ($00, $AA, $AA),  {  Cyan        }
 ($AA, $00, $00),  {  Red         }
 ($AA, $00, $AA),  {  Magenta     }
 ($AA, $55, $00),  {  Brown       }
 ($AA, $AA, $AA),  {  Lightgray    }
 ($55, $55, $55),  {  Darkgray    }
 ($55, $55, $FF),  {  Lightblue    }
 ($55, $FF, $55),  {  Lightgreen   }
 ($55, $FF, $FF),  {  Lightcyan    }
 ($FF, $55, $55),  {  Lightred    }
 ($FF, $55, $FF),  {  Lightmagenta }
 ($FF, $FF, $55),  {  Yellow      }
 ($FF, $FF, $FF) );{  White       }

var i : word;
begin
       with Header do
       begin
               Manufacturer :=10;
               Version :=5;
               Encoding:=1;
               Bits_per_pixel:=1;
               Xmin:=0;
               Ymin:=0;
               Xmax:=639;
               Ymax:=479;
               Hdpi:=640;
               Vdpi:=480;
               ColorMap:=PALETTEMAP;
               Reserved:=0;
               Nplanes :=4; { Red, Green, Blue, Intensity }
               Bytes_per_line_per_plane:=80;
               PaletteInfo:=1;
               HscreenSize:=0;
               VscreenSize:=0;
               for i:=74 to 127 do Filler [i]:=0;
       end;
end;
procedure GetBGIPlane(Start:word; var Plane:Array80);
var i : word;
begin
       for i:= 1 to Header.Bytes_per_line_per_plane do
               Plane [i]:=ImgLn [Start +i -1]
end;
procedure BuildPCXPlane(Start:word; Plane:Array80);
var i : word;
begin
       for i:= 1 to Header.Bytes_per_line_per_plane do
               PCXLn [Start] [i]:=Plane [i];
end;
procedure EncPCXLine(PlaneLine: word); { Encode a PCX line }
var
   This,Last,RunCount: byte;
   i,j: word;
{---------}
procedure EncPut(Byt, Cnt :byte);
const COMPRESS_NUM=$C0; { this is the upper two bits that indicate a count }
var Holder : byte;
begin
       if(Cnt=1) and(COMPRESS_NUM<>(COMPRESS_NUM and Byt)) then
                 blockwrite(PCXName, Byt,1) { single occurance }
       else
       begin
               Holder:=(COMPRESS_NUM or Cnt);
               blockwrite(PCXName, Holder, 1);
{ number of times the following color occurs }
               blockwrite(PCXName, Byt, 1);
       end;
end;
{---------}
begin
       i:=1;         { used in PCXLn }
       RunCount:=1;
       Last:=PCXLn [PlaneLine][i];
       for j:=1 to Header.Bytes_per_line_per_plane -1 do
       begin
               inc(i);
               This:=PCXLn [PlaneLine][i];
               if This=Last then
               begin
                       inc(RunCount);
                       if RunCount=63 then
                       { reached PCX run length limited max yet? }
                       begin
                               EncPut(Last, RunCount);
                               RunCount:=0;
                       end;
               end
               else
               begin
                       if RunCount >= 1 then Encput(Last, RunCount);
                       Last:=This;
                       RunCount:=1;
               end;
       end;
       { any left over ? }
       if RunCount >= 1 then Encput(Last, RunCount);
end;
       { - - -W-R-I-T-E-_-P-C-X- - - - }
const
       XMAX=639;
       YMAX=479;
var    i, j, Size : word;
begin
       BuildHeader;
       assign(PCXName,Name);
{$I-}  rewrite(PCXName,1); {$I+}
       if IOresult<>0 then exit;
       i:=sizeof(Header);
       blockwrite(PCXName,Header,i, size);
       if size<>i then exit;

       setviewport(0,0,XMAX,YMAX, ClipOn);
       Size:=imagesize(0,0,XMAX,0); { size of a single row }
       getmem(Img,Size);
       for i:=0 to YMAX do
       begin
                getimage(0,i,XMAX,i,Img^);
                { Grab 1 line from the screen store in Img buffer  }
                move(Img^,ImgLn,Size); {326}
{                Move (Mem [page_addr: i*(Xmax+1)],ImgLn,sizeOf(ImgLn));}

                GetBGIPlane(INTENSTART, IntenLn);
                GetBGIPlane(BLUESTART,  BlueLn );
                GetBGIPlane(GREENSTART, GreenLn);
                GetBGIPlane(REDSTART,   RedLn  );
                BuildPCXPlane(1, RedLn  );
                BuildPCXPlane(2, GreenLn);
                BuildPCXPlane(3, BlueLn );
                BuildPCXPlane(4, IntenLn);
                { 320 bytes/line uncompressed }
                for j:=1 to Header.NPlanes do EncPCXLine(j);
       end;
       freemem(Img,Size);
       close(PCXName);
end;

BEGIN
       page_addr:= $A000; { EGA/VGA display segment }
END.