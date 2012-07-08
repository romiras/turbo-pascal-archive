{$N+,E-}
Unit vga256;

Interface
Type Palette=Array[0..767] of Byte;
     s5=string[5];
Const
       Vseg:word=$A000;
       _Hollow = 0;    _Filled = 1;
       MaxX=319; MaxY=199;

Procedure SetMode(Mode:Byte);
Procedure CCls(col:byte); {Clears the screen in color COL}
Procedure Cls;
Procedure MoveTo(NewCursX,NewCursY:byte);
procedure GetXY(var X,Y:byte);
{Function  GetX: ;
Function  GetY: ;}
Procedure Setpal(Col,R,G,B: byte);
Procedure Getpal(Col: byte; var R,G,B: byte);
Procedure SetPalette(Pal:Palette);
Procedure RotPal(r,g,b:byte;skipR,skipG,skipB:boolean;loops,ms:word);
Procedure Retrace;
Procedure SetColor(col:byte);
Function  GetColor:byte;
Procedure SetBkColor(col:byte);
Function  GetBkColor:byte;
Procedure PutPixel(x,y: word; color: byte);
Function  GetPixel(x,y: word): byte;
Procedure DVL(x,y,Length: Word); { Vertical Line }
Procedure DHL(x,y,Length: Word); { Horizontal Line }
Procedure Line(x,y,x2,y2: word); { No comments }
Procedure Line2(x, y, x2, y2 : integer); {???...!!!}
Procedure LineRel(DiffX,DiffY: integer);
Procedure LineTo(EndX,EndY: word);
Procedure Circle(Control, X, Y, Radius:word);
Procedure Ellipse(mx,my, a,b: integer);
Procedure Rectangle(x1, y1, x2, y2:integer);
Procedure Paint( StartPoint,EndPoint , From, Dest : Word );
Function  Imagesize(X,Y,X0,Y0:Word):Word;
Procedure Getimage(X,Y,X0,Y0:Word;P:Pointer);
Procedure Putimage(X,Y:Word;P:Pointer);
Procedure Flip(source,target:word);
Function  i2s(Num:longint):s5;
Procedure OutChar(S : Char);
Procedure OutText(Text: string);
Procedure OutTextXY(Text: string; posX,posY:byte);

IMPLEMENTATION
uses crtt,dos;
Var   Segment: word;
       color,bkcolor,page: byte;
       CursorX, CursorY: word;

Procedure SetMode; Assembler;
Asm
 xor ax,ax { BIOS Function 00h: Set Video Mode. }
 mov al,Mode
 int 10h
End;

Procedure CCls(col:byte);assembler;
asm
   mov cx,64000
   push 0A000h
   pop es
   xor di,di
   mov al,[col]
   rep stosb
end;

Procedure Cls; begin ccls(0) end;

Procedure Retrace; Assembler;
Asm;
  mov    dx, 03DAh
@1:
  in     al, dx
  and    al, 08h
  jnz    @1
@2:
  in     al, dx
  and    al, 08h
  jz     @2
End;{ repeat until (Port[$03DA] and 8)<>0; }

procedure Setpal;
begin
       port[$3c8] := col;
       port[$3c9] := R;
       port[$3c9] := G;
       port[$3c9] := B;
end;

procedure Getpal;
begin
       Port[$3c7] := Col;
       R := Port[$3c9];
       G := Port[$3c9];
       B := Port[$3c9];
end;
{assembler;
asm
 mov dx,3c7h
 mov al,[Color]
 out dx,al
 inc dx
 inc dx
 in  al,dx
 les di,dword ptr [R]
 mov byte ptr es:[di],al
 in al,dx
 les di,dword ptr [G]
 mov byte ptr es:[di],al
 in al,dx
 les di,dword ptr [B]
 mov byte ptr es:[di],al
end;}

Procedure SetPalette; Assembler;
Asm
 push es
 mov ax,1012h {BIOS function 10h, subfunction 12h.  }
 xor bx,bx    {first color register.               }
 mov cx,20h   {number of color registers.          }
 les dx,Pal   {ES:DX Segment:Offset of color table. }
 Int 10h
 pop es
End;

procedure RotPal;
type
  tcount = record
           r,g,b:real;
         end;
var
  i,c,rr,gg,bb:byte;
  red,blue,green:real;
  current,count:array [0..255] of tcount;
begin
  for c:=0 to 255 do begin
    getpal(c,rr,gg,bb);
    if skipr=false then count[c].r:=(r-rr)/loops;
    if skipg=false then count[c].g:=(g-gg)/loops;
    if skipb=false then count[c].b:=(b-bb)/loops;
    current[c].r:=rr;
    current[c].g:=gg;
    current[c].b:=bb;
  end;
  for i:=1 to loops do begin
    for c:=0 to 255 do begin
      if skipr=false then current[c].r:=count[c].r+current[c].r;
      if skipg=false then current[c].g:=count[c].g+current[c].g;
      if skipb=false then current[c].b:=count[c].b+current[c].b;
      setpal(c,round(current[c].r),round(current[c].g),round(current[c].b));
    end;
    delay(ms);
  end;
end;

Procedure SetColor;
begin Color:=col end;

Function  GetColor:byte;
begin Getcolor:=color end;

Procedure SetBkColor;
begin bkColor:=col end;

Function  GetbkColor:byte;
begin Getbkcolor:=color end;

Procedure MoveTo;
begin
       CursorX:=NewCursX;
       CursorY:=NewCursY;
       Asm
        mov dh,NewCursY
        mov dl,NewCursX
        mov bh,0
        mov ah,02h
        int 10h
       End;
end;

procedure GetXY(var X,Y:byte);
var R:registers;
begin
       asm
        mov ah,3
        mov bh,0
        int 10h
       end;
       X:=R.dl;
       Y:=R.dh;
end;

Procedure PutPixel;
 begin mem[$A000:Y*320+X]:=Color end;

Function GetPixel;
 begin getpixel:=mem[$A000:Y*320+X] end;

Procedure DHL; Assembler;
Asm
 mov ax,0a000h
 mov es,ax
 mov ax,y
 shl ax,6
 mov di,ax
 shl ax,2
 add di,ax
 add di,x
 mov cx,Length
 mov al,Color
 cld
 rep stosb { I bet I'll get loads of replies which uses stosw instead :) }
End;

Procedure DVL; Assembler;
Asm
 mov ax,0a000h
 mov es,ax
 mov ax,y
 shl ax,6
 mov di,ax
 shl ax,2
 add di,ax
 add di,x
 mov al,Color
 mov cx,Length
@DVL1:
 mov es:[di],al
 add di,320
 dec cx
 jnz @DVL1
End;

Procedure Line;Assembler;
asm
 mov ax,$A000
 mov es,ax
 mov bx,x
 mov ax,y
 mov cx,x2
 mov si,y2
 cmp ax,si
 jbe @NO_SWAP  {always draw downwards}
 xchg bx,cx
 xchg ax,si
@NO_SWAP:
 sub si,ax        {yd (pos)}
 sub cx,bx        {xd (+/-)}
 cld              {set up direction flag}
 jns @H_ABS
 neg cx      {make x positive}
 std
@H_ABS:
 mov di,320
 mul di
 mov di,ax
 add di,bx   {di:adr}
 or si,si
 jnz @NOT_H
{horizontal line}
 cld
 mov al,color
 inc cx
 rep stosb
 jmp @EXIT
@NOT_H:
 or cx,cx
 jnz @NOT_V
{vertical line}
 cld
 mov al,color
 mov cx,si
 inc cx
 mov bx,320-1
@VLINE_LOOP:
 stosb
 add di,bx
 loop @VLINE_LOOP
 jmp @EXIT
@NOT_V:
 cmp cx,si    {which is greater distance?}
 lahf        {then store flags}
 ja @H_IND
 xchg cx,si   {swap for redundant calcs}
@H_IND:
 mov dx,si    {inc2 (adjustment when decision var rolls over)}
 sub dx,cx
 shl dx,1
 shl si,1     {inc1 (step for decision var)}
 mov bx,si    {decision var, tells when we need to go secondary direction}
 sub bx,cx
 inc cx
 push bp      {need another register to hold often-used constant}
 mov bp,320
 mov al,color
 sahf        {restore flags}
 jb @DIAG_V
{mostly-horizontal diagonal line}
 or bx,bx     {set flags initially, set at end of loop for other iterations}
@LH:
 stosb       {plot and move x, doesn't affect flags}
 jns @SH      {decision var rollover in bx?}
 add bx,si
 loop @LH   {doesn't affect flags}
 jmp @X
@SH:
 add di,bp
 add bx,dx
 loop @LH   {doesn't affect flags}
 jmp @X
@DIAG_V:
{mostly-vertical diagonal line}
 or bx,bx    {set flags initially, set at end of loop for other iterations}
@LV:
 mov es:[di],al   {plot, doesn't affect flags}
 jns @SV         {decision var rollover in bx?}
 add di,bp       {update y coord}
 add bx,si
 loop @LV        {doesn't affect flags}
 jmp @X
@SV:
 scasb  {sure this is superfluous but it's a quick way to inc/dec x coord!}
 add di,bp       {update y coord}
 add bx,dx
 loop @LV        {doesn't affect flags}
@X:
 pop bp
@EXIT:
end;

Procedure LineRel;
 begin Line(CursorX, CursorY, CursorX+DiffX, CursorY+DiffY) end;

Procedure LineTo;
 begin Line(CursorX,CursorY,EndX,EndY) end;

Procedure Circle;
var col:word;
begin
     col:=getcolor;
Asm
 MOV AX, Vseg
 MOV ES, AX
 MOV SI, Radius { XI := R }
 MOV DI, 0     { YI := 0 }
 MOV CX, Radius
 SHR CX, 1     { N := XI Div 2 }
 MOV AX, Control
 CMP AX, 1
 JE @Filled
 @Hollow:
 @Loope:
 {putpix}
 MOV BX, 320
 MOV AX, Y
 SUB AX, DI
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, SI
 MOV DX, col
 MOV ES:[BX], DL
 MOV BX, 320
 MOV AX, Y
 SUB AX, SI
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, DI
 MOV DX, col
 MOV ES:[BX], DL
 MOV BX, 320
 MOV AX, Y
 SUB AX, DI
 MUL BX
 MOV BX, AX
 ADD BX, X
 ADD BX, SI
 MOV DX, col
 MOV ES:[BX], DL
 MOV BX, 320
 MOV AX, Y
 SUB AX, SI
 MUL BX
 MOV BX, AX
 ADD BX, X
 ADD BX, DI
 MOV DX, col
 MOV ES:[BX], DL
 MOV BX, 320
 MOV AX, Y
 ADD AX, DI
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, SI
 MOV DX, col
 MOV ES:[BX], DL
 MOV BX, 320
 MOV AX, Y
 ADD AX, SI
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, DI
 MOV DX, col
 MOV ES:[BX], DL
 MOV BX, 320
 MOV AX, Y
 ADD AX, DI
 MUL BX
 MOV BX, AX
 ADD BX, X
 ADD BX, SI
 MOV DX, col
 MOV ES:[BX], DL
 MOV BX, 320
 MOV AX, Y
 ADD AX, SI
 MUL BX
 MOV BX, AX
 ADD BX, X
 ADD BX, DI
 MOV DX, col
 MOV ES:[BX], DL
 {putpix}
 ADD CX, DI  { N := N + YI }
 CMP CX, SI  { If N > XI Then }
 JNG @Skip   { Do This }
 DEC SI       { XI := XI - 1 }
 SUB CX, SI   { N := N - XI }
 @Skip:
 INC DI      { YI := YI + 1 }
 CMP DI, SI
 JNG @Loope
 JMP @End
 @Filled:
 @Loopeb:
 {putpix}
 MOV BX, 320
 MOV AX, Y
 SUB AX, DI
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, SI
 MOV DX, CX          { Part 2 }
 XCHG BX, DI
 MOV AX, col
 MOV CX, SI
 SHL CX, 1
 inc cx
  REP STOSB
 MOV DI, BX
 MOV CX, DX
 MOV BX, 320
 MOV AX, Y
 ADD AX, DI
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, SI
 MOV DX, CX          { Part 3 }
 XCHG BX, DI
 MOV AX, col
 MOV CX, SI
 SHL CX, 1
 inc cx
  REP STOSB
 MOV DI, BX
 MOV CX, DX
 {putpix}
 ADD CX, DI  { N := N + YI }
 CMP CX, SI  { If N > XI Then }
 JNG @Skipb   { Do This }
 DEC SI       { XI := XI - 1 }
 SUB CX, SI   { N := N - XI }
 {putpix}
 MOV BX, 320
 MOV AX, Y
 SUB AX, SI
 dec ax
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, DI
 MOV DX, CX       { Part 1 }
 MOV AX, col
 MOV CX, DI
 SHL CX, 1
 inc cx
 XCHG BX, DI
 REP STOSB
 MOV DI, BX
 MOV CX, DX
 MOV BX, 320
 MOV AX, Y
 ADD AX, SI
 inc ax
 MUL BX
 MOV BX, AX
 ADD BX, X
 SUB BX, DI
 MOV DX, CX
 MOV AX, col   { Part 4 }
 MOV CX, DI
 SHL CX, 1
 inc cx
 XCHG BX, DI
  REP STOSB
 MOV DI, BX
 MOV CX, DX
 {putpix}
 @Skipb:
 INC DI      { YI := YI + 1 }
 CMP DI, SI
 JNG @Loopeb
   @End:
End;
end;

procedure line2(x, y, x2, y2: integer);
var
        d, dx, dy,
        ai, bi,
        xi, yi: integer;
begin
        if (x < x2) then
        begin
              xi:= 1;
              dx:= x2 - x;
        end
        else
        begin
              xi:= - 1;
              dx:= x - x2;
        end;
        if y < y2 then
        begin
              yi:= 1;
              dy:= y2 - y;
        end
        else
       begin
             yi:= - 1;
             dy:= y - y2;
       end;
       if (x>0) and (x<MaxX) and
           (y>0) and (y<MaxY)
           then putpixel(x, y,getcolor);

        if dx > dy then
        begin
              ai:= (dy - dx) shl 1;
              bi:= dy shl 1;
              d := bi - dx;
              repeat
                     if (d >= 0) then
                     begin
                           inc(y, yi);
                           inc(d, ai);

                     end
                    else inc(d, bi);
                     inc(x, xi);
                     if (x>0) and (x<MaxX) and
                        (y>0) and (y<MaxY)
                        then putpixel(x, y,getcolor);
              until (x = x2);
        end
       else
        begin
              ai:= (dx - dy) shl 1;
              bi:= dx * 2;
              d := bi - dy;
              repeat
                    if d >= 0 then
                    begin
                          inc(x, xi);
                          inc(d, ai);
                    end
                    else inc(d, bi);
                    inc(y, yi);
                    if (x>0) and (x<MaxX) and
                       (y>0) and (y<MaxY)
                       then putpixel(x, y,getcolor);
             until y = y2;
       end;
end;

Procedure Ellipse(mx,my, a,b: integer);
var    x,  mx1,mx2,  my1,my2: integer;
       dx,dy, r,rx,ry: longint;
begin
       mx1:=mx-a;   my1:=my;
       mx2:=mx+a;   my2:=my;
       PutPixel(mx2, my,color);
       PutPixel(mx1, my,color);
       dx:=longint(a)*a*2;
       dy:=longint(b)*b*2;
       r :=longint(a)*b*b;
       rx:=2*a*b*b;
       ry:=0;
       x :=a;
       while x > 0 do
       begin
               if r > 0
               then
               begin { y + 1 }
                       inc(my1);   dec (my2);
                       inc(ry, dx); {ry = dx * y}
                       dec(r, ry);  {r = r -dx+y}
               end
               else
               begin  { x - 1 }
                       dec(x);
                       inc(mx1);   dec (mx2);
                       dec(rx, dy); {rx = dy * x}
                       inc(r, rx);  {r = r +dy*x}
               end;
               PutPixel(mx1, my1,color);
               PutPixel(mx1, my2,color);
               PutPixel(mx2, my1,color);
               PutPixel(mx2, my2,color);
       end;
end;

Procedure Rectangle(x1, y1, x2, y2:integer);
begin
       if (x2<x1) or (y2<y1) then exit;
       dhl(x1,y1,x2-x1);
       dvl(x1,y1,y2-y1);
       dhl(x1,y2,x2-x1);
       dvl(x2,y1,y2-y1+1);
end;

PROCEDURE Paint( StartPoint,EndPoint , From, Dest : Word );
Begin
       StartPoint:=StartPoint*320;
       EndPoint:=EndPoint*320-StartPoint;
asm
 push   ds
 mov    ax, From
 mov    es, ax
 mov    ax, Dest
 mov    ds, ax
 mov    di, EndPoint
 mov    Cx, StartPoint
 @Looppi:
 mov    Al, Es:[Di]
 cmp    Al, 0
 jz     @Ohi
 mov    Ds:[di], Al
 @Ohi:
 inc    di
 loop   @Looppi
 pop    ds
end;
END;

Function Imagesize(X,Y,X0,Y0:Word):Word;
var dummy:longint;
    sx,sy:word;
begin
  sx:=(abs(x0-x) div 8)+1;
  sy:=abs(y0-y)+1;
  dummy:=sx*sy*4+10;       {*4 because of 4 bitplanes}
  if dummy<65520 then
    imagesize:=dummy
  else
    imagesize:=0;
end;

Procedure Getimage(X,Y,X0,Y0:Word;P:Pointer);Assembler;
var m:word;
asm
 sti
 push es
 push ds
 cld       {rep adds}
 les di,[p] {x0 <- width, y0 <- height, write to buffer}
 mov ax,x0
 sub ax,x
 shr ax,3   {x0:=x0 div 8}
 mov x0,ax
 mov es:[di],ax
 inc x0
 mov ax,y0
 sub ax,y
 mov y0,ax
 mov es:[di+2],ax
 inc y0
 add di,4      {es:di <- pointer to data}
 shr x,3       {x:=x div 8}
 mov bx,y      {m:=y*80+x - offset in vram}
 mov cx,bx
 shl bx,4
 shl cx,6
 add bx,cx
 add bx,x
 mov m,bx
 mov ax,0a000h {ds:si <- beginning of vram}
 mov ds,ax
 mov bx,y0     {bx - lines counter}
 mov dx,03ceh  {dx - port address}
 mov al,4
 out dx,al
 inc dx
@@1:
 mov ah,4      {ah - 3=1.bit plane, 2=2.bitpl.,1=3.bitpl.,0=4.bitpl.}
@@2:
 mov al,ah
 dec al
 out dx,al     {send number of bitplane to the graphic card}
 mov si,m      {offset in videoram}
 mov cx,x0     {image width to counter}
 rep movsb     {send  cx bytes from DS:SI(vram) to ES:DI(image)}
 dec ah        {decrement al - next bitplane}
 jnz @@2       {is zero ? - no=next bitplane}
 add m,80      {next line in vram}
 dec bx        {decrement lines counter}
 jnz @@1       {last line  ? no=next line}
 dec dx        {set graphic card back to std. modus}
 mov al,3
 out dx,al
 inc dx
 xor al,al
 out dx,al
 pop ds
 pop es
 cli
end;

Procedure Putimage(X,Y:Word;P:Pointer);Assembler;
var sx,sy,m:word;
asm
 sti
 push es
 push ds
 cld       {rep adds}
 shr x,3    {x:=x div 8}
 mov bx,y   {m:=y*80+x - offset in vram}
 mov cx,bx
 shl bx,4
 shl cx,6
 add bx,cx
 add bx,x
 mov m,bx
 lds si,[p] {sx <- width, sy <- height}
 mov ax,word ptr ds:[si]
 inc ax
 mov sx,ax
 mov ax,word ptr ds:[si+2]
 inc ax
 mov sy,ax
 add si,4      {ds:si <- pointer to data}
 mov ax,0a000h {es:di <- beginning of vram}
 mov es,ax
 mov bx,sy     {bx - lines counter}
 mov dx,03c4h  {dx - port address}
 mov al,2
 out dx,al
 inc dx
@@1:
 mov al,8      {al - 8=1.bit plane, 4=2.bitpl.,2=3.bpl.,1=4.bpl.}
@@2:
 out dx,al     {send bitplane number to the graphic card}
 mov di,m      {offset in videoram}
 mov cx,sx     {image width to counter}
 rep movsb     {send cx bytes from DS:SI(image) to ES:DI(vram)}
 shr al,1      {divide al by 2 - next bitplane of 4}
 jnz @@2       {is zero ? - no=next bitplane}
 add m,80      {next line in vram}
 dec bx        {decrement lines counter}
 jnz @@1       {last line ? no=next line}
 dec dx        {set graphic card back to std. modus}
 mov al,2
 out dx,al
 inc dx
 mov al,15
 out dx,al
 pop ds
 pop es
 cli
end;

Procedure Flip(source,target:word);assembler;
asm
 push ds
 mov ax,target
 mov es,ax        {target:=es:[di]}
 mov ax,Source
 mov ds,ax        {sourcre:=ds:[si]}
 xor si,si
 xor di,di
 mov cx,16000
 db $f3,66h,$a5    {rep movsd}
 pop ds
end;

Function  i2s;
var st:string[10];
begin
      str(num,st);
      i2s:=st;
end;

Procedure OutChar(S : Char); Assembler;
Asm
 Mov Ah, 09h
 Mov Al, S
 Mov Bh, BkColor
 Mov Bl, Color
 Mov Cx, 1
 Int 10h
end;

Procedure OutText;
var z, CurX, CurY : byte;
begin
       CurX := CursorX;
       CurY := CursorY;
       for z := 1 to Length(Text) do
       begin
             outchar(Text[z]);
             inc(CurX);
             if CurX>(MaxX div 8) then begin CurX:=0; inc(CurY);end;
             MoveTo(CurX,CurY);
       end;
end;

procedure OutTextXY;
begin
       MoveTo(posX,posY);
       OutText(text);
end;

Begin
      page:=0;
      Color:=15; { White }
      BkColor:=0; { Black }
      CursorX:=0;
      CursorY:=0;
End.