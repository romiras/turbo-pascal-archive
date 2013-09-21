{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on TinyWeb Server by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}

unit qStarSky;

interface

 procedure StartSky(N: Integer);
 procedure Sky;

implementation
uses Objects, Drivers, Advance, DNApp, Memory;

const
 maxviewwidth = 200;
 skydelay = 1;
const MaxWormLen   = 40;

type             PWorm     = ^Worm;
                 Worm      = object(TObject)
                   WormLen,Dir : Byte;
                   WormColor   : Byte;
                   WC          : array[1..MaxWormLen] of TPoint;
                   Bounds      : TRect;
                   Constructor Init(B : TRect);
                   Procedure   NextMove;
                  end;

var VSeg,OSS : Word;

Constructor Worm.Init;
var i,j,k : Byte;
begin
 Bounds:=B;
 repeat WormLen:=Random(MaxWormLen) until WormLen > 3;
 repeat WormColor:=Random(8) until WormColor > 0;
 if VSeg = $B000 then WormColor := 7;
 Dir:=Random(4);
 i:=Random(Bounds.B.X-Bounds.A.X)+Bounds.A.X;
 j:=Random(Bounds.B.Y-Bounds.A.Y)+Bounds.A.Y;
 for k:=1 to WormLen do begin WC[k].X:=i;WC[k].Y:=j;end;
end;

Procedure Worm.NextMove;
label ChDir;
var k,l : Byte;
    w   : Word;

Function MoveTo(x,y : Word) : Boolean;
var i : Byte;
begin
 MoveTo:=True;k:=1;
 if (x<Bounds.A.X) or (x>Bounds.B.X-1) or
    (y<Bounds.A.Y) or (y>Bounds.B.Y-1) then exit;
 if mem[VSeg:OSS+Y*ScreenWidth*2+X*2+1]<>0 then Exit;
 MoveTo:=False;k:=0;
 WC[1].X:=x;WC[1].Y:=y;
end;

begin
 k:=0;
 mem[VSeg:OSS+WC[WormLen].Y*ScreenWidth*2+WC[WormLen].X*2+1]:=0;
 Move(WC[1],WC[2],(WormLen-1)*SizeOf(TPoint));l:=0;
ChDir:
 Inc(l);
 if (k<>0) or (Random(20)=1) then Dir:=Random(4);
 if l>10 then Exit;
 case Dir of
  0 : if MoveTo (WC[1].X,WC[1].Y-1) then GoTo ChDir;
  1 : if MoveTo (WC[1].X+1,WC[1].Y) then GoTo ChDir;
  2 : if MoveTo (WC[1].X,WC[1].Y+1) then GoTo ChDir;
  3 : if MoveTo (WC[1].X-1,WC[1].Y) then GoTo ChDir;
 end;
 w:=OSS+WC[1].Y*ScreenWidth*2+WC[1].X*2;
 mem[VSeg:w+1]:=WormColor or 8;if mem[VSeg:w]=32 then mem[VSeg:w]:=4;
 mem[VSeg:OSS+WC[2].Y*ScreenWidth*2+WC[2].X*2+1]:=WormColor;
end;

Procedure ClearRect(Bounds : TRect);
var i,j   : Byte;
begin
 for i:=Bounds.A.X to Bounds.B.X-1 do
     begin
      for j:=Bounds.A.Y to Bounds.B.Y-1 do
          case j and 1 of
           0 : mem[VSeg:OSS+j*ScreenWidth*2+i*2+1]:=0;
           1 : mem[VSeg:OSS+j*ScreenWidth*2+(ScreenWidth-i-1)*2+1]:=0;
          end;
      Delay(SkyDelay*5);
     end;
end;

Procedure Worms(Bounds : TRect);
var w    : array[1..20] of PWorm;
    i,nw : Byte;
    Event: TEvent;
    ks1: Word;
begin
 repeat nw:=Random(15)+5; until (nw > 5) and (nw < 20);
 ks1 := ShiftState;
 for i:=1 to nw do New(w[i], init(Bounds));
 repeat
  for i:=1 to nw do w[i]^.NextMove;
  Delay(SkyDelay*100);
  Application^.GetEvent(Event);
  asm int 28h end;
 until (Event.What and (evMouse or evKeyDown) <> 0) or (ShiftState <> ks1);
 for i:=1 to nw do Dispose(w[i], Done);
end;

Procedure Nibbles(Bounds : TRect);
var ScrBuf : pointer;
begin
{ if Seg(ScreenBuffer^)=$B000 then WormColor:=7;}
 ScrBuf:=MemAlloc(ScreenWidth*ScreenHeight*2);
 if ScrBuf=NIL then Exit; {HideMouse;}
 Move(ScreenBuffer^,ScrBuf^,ScreenWidth*ScreenHeight*2);
 VSeg:=Seg(ScreenBuffer^);OSS:=Ofs(ScreenBuffer^);
 Randomize;
 ClearRect(Bounds);
 Worms(Bounds);
end;

procedure Loop;
 var AX1, AX2: Integer;
     dx, dy: Integer;
     Ball: TPoint;
     Event: TEvent;

procedure InitBall;
begin
 Ball.X := ScreenWidth div 2;
 Ball.Y := ScreenHeight div 2;
 repeat
  dx := Random(4);
  if odd(dx) then dx := -Random(4);
 until dx <> 0;
 repeat
  dy := Random(4);
  if odd(dy) then dy := -Random(4);
 until dy <> 0;
end;

procedure WriteStr(X,Y: Integer; const S: String);
 var B: Array[0..132] of Word;
begin
 MoveStr(B, S, $03);
 Move(B, PWordArray(ScreenBuffer)^[(Y-1)*ScreenWidth+X-1], Length(S)*2);
end;

var ks1: Byte;

begin
 ks1 := ShiftState;
 Ball.X := ScreenWidth div 2;
 Ball.Y := ScreenHeight div 2;
 AX1 := Ball.X - 2;
 AX2 := Ball.X - 2;
 InitBall;
 WriteStr(AX1, 1, '<อออ>');
 WriteStr(AX2, ScreenHeight, '<อออ>');
 repeat
  WriteStr(Ball.X, Ball.Y, ' ');
  Inc(Ball.Y, DY);
  if Ball.Y < 2 then
   begin
    Ball.Y := 2; DY := - DY;
    case Ball.X - AX1 of
       0: DX := -3;
       1: DX := -2;
       2: DX := -DX;
       3: DX := 2;
       4: DX := 3;
    end;
   end;
  if Ball.Y > ScreenHeight - 1 then
   begin
    Ball.Y := ScreenHeight - 1; DY := - DY;
    case Ball.X - AX2 of
       0: DX := -3;
       1: DX := -2;
       2: DX := -DX;
       3: DX := 2;
       4: DX := 3;
    end;
   end;
  Inc(Ball.X, DX);
  if Ball.X < 1 then begin Ball.X := 1; DX := - DX; end;
  if Ball.X > ScreenWidth - 1 then begin Ball.X := ScreenWidth - 1; DX := - DX; end;
  if DY < 0 then
   begin
    WriteStr(AX1, 1, '     ');
    if (Ball.X - 2 < AX1) then Dec(AX1, (1+Random(5))) else Inc(AX1, (1+Random(5)));
    if AX1 < 1 then AX1 := 1; if AX1 > ScreenWidth - 6 then AX1 := ScreenWidth - 6;
    WriteStr(AX1, 1, '<อออ>');
   end else
   begin
    WriteStr(AX2, ScreenHeight, '     ');
    if (Ball.X - 2 < AX2) then Dec(AX2, (1+Random(5))) else Inc(AX2, (1+Random(5)));
    if AX2 < 1 then AX2 := 1; if AX2 > ScreenWidth - 6 then AX2 := ScreenWidth - 6;
    WriteStr(AX2, ScreenHeight, '<อออ>');
   end;
  WriteStr(Ball.X, Ball.Y, #1);
  Delay(50);
  Application^.GetEvent(Event);
  asm int 28h end;
 until (Event.What and (evMouse or evKeyDown) <> 0) or (ShiftState <> ks1);
end;


procedure StartSky(N: Integer);
 var R: TRect;
begin
 R.Assign(0,0,ScreenWidth, ScreenHeight);
 SkyVisible := On;
 case N of
  1: Nibbles(R);
  else Loop;
 end;
 SkyVisible := Off;
end;

procedure Sky;
const
   qwe : String[6]='ฤ๚*';
type
   Lnc = record
          x,y,c : Byte;
          d     : ShortInt;
          s     : Char;
         end;
   TWordArray = Array[0..30000] of Word;
   PWordArray = ^TWordArray;

var
   OldS    : Pointer;
   mx,my   : Word;
   i,j,nl  : integer;
   ks1,ks2 : Byte;
   lc      : array[1..30] of lnc;
   ScrBuf  : PWordArray;
   Event   : TEvent;
   Ad, Os  : Word;
   Base, Bos: Word;
   SMode:   Word;
   OldShape: Word;

 procedure ReallySky;
  var I,j: Integer;
      S: String[3];
 begin
  SkyVisible := On;
  S := #7#8#15;
  repeat
   if (nl<30) and (Random(5)>3) then
      begin
       Inc(nl);
       repeat lc[nl].d:=XRandom(5); until lc[nl].d <> 0;
       if lc[nl].d<0 then lc[nl].x:= ScreenWidth-1
                     else lc[nl].x:= 0;
       lc[nl].y:=Random(ScreenHeight);
       lc[nl].c:=Random(9);
       lc[nl].s:=qwe[Random(6)+1];
      end;
   for i:=1 to nl do
       begin
        memw[ad:(lc[i].x+lc[i].y*ScreenWidth)*2 + Os] := $0020;
        Inc(lc[i].x, lc[i].d);
        if (lc[i].x >= ScreenWidth-1) or (ShortInt(lc[i].x) < 0 ) then
           begin
            repeat lc[i].d:=XRandom(5); until lc[i].d <> 0;
            if lc[i].d < 0 then lc[i].x := ScreenWidth-1
                           else lc[i].x := 0;
            lc[i].y:=Random(ScreenHeight);
            lc[nl].c:=Random(9);
            lc[i].s:=qwe[Random(6)+1];
           end;
         if (Integer(lc[i].x) < ScreenWidth)
          then begin
                mem[ad:(lc[i].x+lc[i].y*ScreenWidth)*2 + Os] := Byte(lc[i].s);
                mem[ad:(lc[i].x+lc[i].y*ScreenWidth)*2 + Os + 1] := lc[i].c;
               end;
       end;
   Delay(30);
   Application^.GetEvent(Event);
   asm int 28h end;
  until (Event.What and (evMouse or evKeyDown) <> 0) or (mem[0:$417] <> ks1);
  SkyVisible := Off;
 end;

begin
 if SkyEnabled > 0 then Exit;
 SMode := SkyMode; if SMode = 3 then SMode := Random(12) mod 3;
 asm
  mov ah, 3
  xor bx, bx
  int 10h
  mov OldShape, cx
  mov cx, $2020
  mov ah, 1
  int 10h
 end;
 if SMode = 2 then begin StartSky(1); Application^.Redraw;
                    asm mov ah,1; mov cx, OldShape; xor bx, bx; int 10h; end; Exit; end;
 {SaveCursor;SetCursor($2020);}ks1:=mem[0:$417];ks2:=mem[0:$418];
 Ad := Seg(ScreenBuffer^); Os := Ofs(ScreenBuffer^);
 nl:=0; ScrBuf := MemAlloc(ScreenWidth*ScreenHeight*2);
 if ScrBuf = nil then Exit; HideMouse;
 SkyVisible := On;
 Base := Seg(ScrBuf^); Bos := Ofs(ScrBuf^);
 Move(ScreenBuffer^, ScrBuf^, ScreenWidth*ScreenHeight*2);
 for i:=1 to ScreenWidth do
     for j:=1 to ScreenHeight do
         if Odd(j) then
            begin
             Move(mem[ad:(i-1) shl 1+(j-1)*ScreenWidth*2+Os],
                  mem[ad:i shl 1+(j-1)*ScreenWidth*2+Os],(ScreenWidth-i) shl 1);
             memw[ad:(i-1) shl 1+(j-1)*ScreenWidth*2+Os]:=$0720;
            end
                   else
            begin
             Move(mem[ad:2+(j-1)*ScreenWidth*2+Os],
                  mem[ad:(j-1)*ScreenWidth*2+Os],(ScreenWidth-i) shl 1);
             memw[ad:(ScreenWidth-i) shl 1+(j-1)*ScreenWidth*2+Os]:=$0720;
            end;
 if SMode = 0 then ReallySky else StartSky(0);
 for i:=1 to ScreenWidth do
     for j:=1 to ScreenHeight do
         if Odd(j) then Move(mem[Base:(ScreenWidth-i)*2+(j-1)*2*ScreenWidth+Bos],
                             mem[ad:(j-1)*2*ScreenWidth+Os],i*2)
                   else Move(mem[Base:(j-1)*2*ScreenWidth+Bos],
                             mem[ad:(ScreenWidth-i)*2+(j-1)*2*ScreenWidth+Os], i*2);

 {RestoreCursor;}
 ShowMouse;
 asm mov ah,1; mov cx, OldShape; xor bx, bx; int 10h; end;
 memw[$40:$1a]:=memw[$40:$1c]; SkyVisible := Off;
end;


end.