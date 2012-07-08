
Unit PCX256; { Show & Save PCX on 320x200x256 mode }

Interface
{Uses Dos,CRT;}

Procedure Load_PCX256(Dx, Dy : Word; Name : String);
Procedure Save_PCX256(FN : String);

Implementation
Uses VGA256;

Type
        ArrayPal  =array [0..15, 0..2] of byte; { 16 colors of (R,G,B) }
Const
        PALETTEMAP: ArrayPal=
{ R    G    B }
((0   ,0   ,0  ),
 (216 ,152 ,56 ),
 (120 ,116 ,4  ),
 (112 ,108 ,4  ),
 (236 ,172 ,76 ),
 (248 ,196 ,128),
 (64  ,36  ,36 ),
 (36  ,40  ,20 ),
 (248 ,188 ,104),
 (212 ,144 ,156),
 (60  ,36  ,36 ),
 (116 ,112 ,8  ),
 (120 ,116 ,8  ),
 (124 ,120 ,8  ),
 (52  ,48  ,4  ),
 (240 ,196 ,136));

type
        Pcx_Header=record
         Manufacturer: byte; { Always 10 for PCX file }
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

var F: File;
Header: PCX_header;

Procedure Write_Header;
Begin
       with Header do
       begin
               Manufacturer :=10;
               Version :=5;
               Encoding:=1;
               Bits_per_pixel:=8;
               Xmin:=0;
               Ymin:=0;
               Xmax:=319;
               Ymax:=199;
               Hdpi:=320;
               Vdpi:=200;
               ColorMap:=PALETTEMAP;
               Reserved:=0;
               Nplanes :=1; { Red, Green, Blue, Intensity }
               Bytes_per_line_per_plane:=320;
               PaletteInfo:=0;
               HscreenSize:=0;
               VscreenSize:=0;
               fillchar(Filler, SizeOf(Filler), 0);
       end;
       BlockWrite(F,Header,SizeOf(Header));
End;

Procedure Save_PCX256(FN : String);
Var  Ln : Byte;
{--------------------}
Procedure Encode_Line (Ln : Byte);
Var
  Buf: record b,bp:byte end;
  I,J,T: Word;
  A: Byte;
  P: Array [0..319] of Byte;
Begin
      J:= 0;
      T:= 0;
      { Scan next line & place it to P }
      Move (Mem [Vseg:Ln * 320],P,320);
      While T < Header.Xmax+1 Do
      Begin
            I:= 0;
            While ((P[T+I] = P[T+I+1]) And ((T+I) < 320) And (I < 63)) Do
                  Inc (I);
            If I > 0 Then
            Begin
                  Buf.B:=I Or $C0;
                  Buf.BP:=P[T];
                  BlockWrite(F,Buf,SizeOf(Buf));
                  Inc (T,I);
                  Inc (J,2);
            End
            Else
            Begin
                  If (((P [T]) And $C0) = $C0) Then
                  Begin
                        A:= $C1;
                        BlockWrite(F,A,1);
                        Inc(J);
                  End;
                  BlockWrite (F,P[T],1);
                  Inc(T);
                  Inc(J);
            End;
      End;
End;
{--------------------}
Procedure Write_Palette;
Var i,L : Byte;
    RGB:array[0..2] of byte;
Begin
  L := 12;
  BlockWrite (F,L,1);
  For L := 0 to 255 Do
  Begin
    GetPal (L,RGB[0],RGB[1],RGB[2]);
    for i:=0 to 2 do RGB[i]:=RGB[i] shl 2;
    BlockWrite (F,RGB,3);
  End;
End;
{--------------------}
Begin
  Assign (F,FN);
{$I-}
  Rewrite (F,1);
{$I+}
  Write_Header;
  For Ln := 0 to Header.Ymax Do Encode_Line (Ln);
  Write_Palette;
  Close (F);
End;

PROCEDURE Load_PCX256(dx, dy : WORD; name : STRING);
VAR q            : FILE;
    b            : ARRAY[0..2047] OF BYTE;
    anz, pos, c,
    w, h, e,pack : WORD;

LABEL _exit;
{--------------------}
Procedure ReadPalette;
const PalSize=3 shl 8;
var I: word;
begin
        SEEK(q, FILESIZE(q)-PalSize-1);
        BLOCKREAD(q, b, PalSize+1);
        IF b[0]=12 THEN
           FOR i:= 1 TO PalSize+1 DO
               b[i]:= b[i] SHR 2;
        FOR i := 0 TO 255 DO
            SetPal(i,b[i*3+1],b[i*3+2],b[i*3+3]);
end;
{--------------------}
BEGIN
        ASSIGN(q, name); {$I-} RESET(q, 1);{$I+}
        IF IORESULT <> 0 THEN GOTO _exit;

        BlockRead(q, Header, SizeOf(Header));
        with Header do
        begin
             if (Manufacturer<>10) or (Bits_per_pixel<>8) THEN GOTO _exit;
             w:=Xmax-Xmin+1;
             h:=Ymax-Ymin+1;
        end;
        pack:=0; c:=0; e:=dy + h;
        REPEAT
              BLOCKREAD(q, b, 2048, anz);
              pos:=0;
              WHILE (pos < anz) AND (dy < e) DO
              BEGIN
                   IF pack <> 0 THEN
                   BEGIN
                        FOR c:=c TO c+pack DO putpixel(dx+c,dy,b[pos]);
                        pack := 0;
                   END
                   ELSE
                   IF (b[pos] AND $C0) = $C0 THEN
                      pack := b[pos] AND $3F
                   ELSE
                   BEGIN
                        putpixel(dx+c,dy,b[pos]);
                        INC(c);
                   END;
                   INC(pos);
                   IF c = w THEN
                   BEGIN
                        c := 0;
                        INC(dy);
                   END;
              END;
        UNTIL (anz = 0) OR (dy = e);
        ReadPalette;
_exit:  CLOSE(q);
END;

END.