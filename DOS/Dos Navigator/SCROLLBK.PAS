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

unit ScrollBk;

interface
uses Objects, Drivers, Views, Scroller, ObjType;

const
      ScrollBackBuffer: PCollection = nil;
      ScrollBack: PScroller = nil;

type
      PScrollRec = ^TScrollRec;
      TScrollRec = object(TObject)
        Len: Word;
        Start: LongInt;
        constructor Init(var B; ALen: Integer);
        procedure Read(var B; Ofs, ALen: Word);
      end;

     PScrollBack = ^TScrollBack;
     TScrollBack = object(TScroller)
       CutRect, OldCut: TRect;
       constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
       constructor Load(var S: TStream);
       procedure Store(var S: TStream);
       procedure HandleEvent(var Event: TEvent); virtual;
       procedure Draw; virtual;
       destructor Done; virtual;
     end;

     PScrollBackWindow = ^TScrollBackWindow;
     TScrollBackWindow = object(TWindow)
       constructor Init(var Bounds: TRect);
       procedure Zoom; virtual;
       procedure SizeLimits(var Min, Max: TPoint); virtual;
       function  ReactOnCmd: Boolean; virtual;
     end;


procedure NewBackRec(var B; Len: Integer);

function StoreFile(const Mask, Title: String; AddLF: Boolean): PStream;
procedure SaveAnsi(St: PStream; var B; Len: Integer; var Attr: Byte);
procedure SaveAvatar(St: PStream; var B; Len: Integer; var Attr: Byte);
procedure DeallocateScrollbk ;


const
      RScrollBackWindow: TStreamRec = (
       ObjType: otScrollBackWindow;
       VmtLink: Ofs(TypeOf(TScrollBackWindow)^);
       Load: @TScrollBackWindow.Load;
       Store: @TScrollBackWindow.Store);

      RScrollBack: TStreamRec = (
       ObjType: otScrollBack;
       VmtLink: Ofs(TypeOf(TScrollBack)^);
       Load: @TScrollBack.Load;
       Store: @TScrollBack.Store);




implementation
uses Advance,Memory,Terminal,Commands,RStrings, DNHelp,
     HistList,Messages,DNStdDlg,DNApp,MicroEd,Menus,ExtraMemory;


const  BackStream: PStream = nil;
       SBackEnd:   LongInt = 0;


function MaxAvail: LongInt;
begin
  MaxAvail := MemAdjust(System.MaxAvail);
end;


procedure AllocateStream;
  var Size, Pos: LongInt;
begin
  if BackStream <> nil then Dispose(BackStream, Done);
  BackStream := nil; SBackEnd := 0;

  Size := 16384;

  if XMSFound and (XMSFree >= Size shr 10) then
    begin
      BackStream := New(PXMSStream, Init(Size, Size));
      PXMSStream(BackStream)^.Size := 0;
      if BackStream^.Status <> stOK then
        begin Dispose(BackStream, Done); BackStream := nil end
      else Exit;
    end;

  if EMSFound and (EMSFreePages >= Size div 16384) then
    begin
      EMSCurPage  := $FFFF;
      EmsCurHandle := $FFFF;
      BackStream := New(PEMSStream, Init(Size, Size));
      PEMSStream(BackStream)^.Size := 0;
      if BackStream^.Status <> stOK then
        begin
           Dispose(BackStream, Done);
           BackStream := nil;
           EMSCurPage  := $FFFF;
           EmsCurHandle := $FFFF;
        end else Exit
    end;

  Size := Min(Size, MaxAvail - 16384);

  BackStream := New(PMemoryStream, Init(Size, 2048));
  PMemoryStream(BackStream)^.Size := 0;
  if BackStream^.Status <> stOK then
     begin Dispose(BackStream, Done); BackStream := nil end
end;


Procedure  DeallocateScrollBk ;
   begin
     EMSCurPage  := $FFFF;
     EmsCurHandle := $FFFF;
     if BackStream <> nil then
       begin
         Dispose(BackStream, Done);
         BackStream := nil;
       end;
     EMSCurPage  := $FFFF;
     EmsCurHandle := $FFFF;
   end;


constructor TScrollRec.Init;
  var P: PScrollRec;
      M,L,K: LongInt;
      I: Integer;
      S: PStream;
      PP: Pointer;
      Sz,J: Word;
  label 1;

  procedure DoAdjustStart(P: PScrollRec); far;
  begin
    Dec(P^.Start, M);
  end;

begin
  inherited Init;
  if ScrollBackBuffer = nil then Fail;
  if BackStream = nil then AllocateStream;
  if BackStream = nil then Fail;
  BackStream^.Status := stOK;
  Start := BackStream^.GetSize; Len := ALen;
  I := 0;
  if (MaxAvail < $8000) or (1000 + 25 <= ScrollBackBuffer^.Count) then
    begin
1:
       BackStream^.Status := stOK;
       P := ScrollBackBuffer^.At(24);
       M := P^.Start+P^.Len; K := 0;
       for J := 1 to 25 do
           ScrollBackBuffer^.AtFree(0);

       ScrollBackBuffer^.ForEach(@DoAdjustStart);

       Sz := Min($8000, MaxAvail div 3) and $FFFFFF00;
       GetMem(PP, Sz);
       while M < BackStream^.GetSize do
         begin
           BackStream^.Seek(M);
           J := Sz;
           if M+J > BackStream^.GetSize then J := BackStream^.GetSize - M;
           BackStream^.Read(PP^, J);
           M := BackStream^.GetPos;
           BackStream^.Seek(K);
           BackStream^.Write(PP^, J);
           K := BackStream^.GetPos;
         end;
       FreeMem(PP, Sz);
       BackStream^.Truncate;
       Start := BackStream^.GetSize;
    end;
  BackStream^.Status := stOK;
  BackStream^.Seek(Start);
  BackStream^.Write(B, Len);
  if BackStream^.Status <> stOK then
    begin
      Inc(I);
      if I = 25 then Fail;
      GoTo 1;
    end;
  SbackEnd := BackStream^.GetPos;
end;


procedure TScrollRec.Read;
begin
  if BackStream <> nil then
    begin
       BackStream^.Seek(Start+Ofs*SizeOf(Word));
       BackStream^.Read(B, ALen);
    end;
end;



procedure SaveAnsi(St: PStream; var B; Len: Integer; var Attr: Byte);
  var I: Integer;
      S: String;
begin
  for I := 0 to Len - 1 do
     begin
       if Hi(TWordArray(B)[I]) <> Attr then
         begin
           Attr := Hi(TWordArray(B)[I]);
           if Attr and 8 <> 0 then S := #27'[1;' else S := #27'[0;';
           case Attr and $07 of
             0: S := S+'30';
             1: S := S+'34';
             2: S := S+'32';
             3: S := S+'36';
             4: S := S+'31';
             5: S := S+'35';
             6: S := S+'33';
             else S := S+'37';
           end;
           if Attr and $80 <> 0 then S := S+';5';
           case (Attr shr 4) and $07 of
             0: S := S+';40';
             1: S := S+';44';
             2: S := S+';42';
             3: S := S+';46';
             4: S := S+';41';
             5: S := S+';45';
             6: S := S+';43';
             else S := S+';47';
           end;
           S := S+'m';
           St^.Write(S[1], Length(S));
         end;
       St^.Write(WordRec(TWordArray(B)[I]).Lo, 1);
     end;
  if (Len <> 80) and (Len <> 132) then
   begin
     S := #13#10;
     St^.Write(S[1], 2);
   end;
end;

procedure SaveAvatar(St: PStream; var B; Len: Integer; var Attr: Byte);
  var I,K: Integer;
      S: String;
      C: Byte;
      J: Integer;
begin
  J := 0; C := Lo(TWordArray(B)[0]);
  for I := 0 to Len - 1 do
     begin
       if Hi(TWordArray(B)[I]) <> Attr then
         begin
           for K := 1 to J do St^.Write(C, 1); J := 0;
           Attr := Hi(TWordArray(B)[I]);
           S := ^V^A+Char(Attr);
           if Attr and $80 <> 0 then S := S + ^V^B;
           St^.Write(S[1], Length(S));
         end;
       if (Lo(TWordArray(B)[I]) <> C) or (J = 255) then
         begin
           if J > 3 then begin S := ^Y+Char(C)+Char(J); St^.Write(S[1], 3) end
                    else for K := 1 to J do St^.Write(C, 1);
           C := Lo(TWordArray(B)[I]); J := 1;
         end else Inc(J);
     end;
  if J > 3 then begin S := ^Y+Char(C)+Char(J); St^.Write(S[1], 3) end
           else for K := 1 to J do St^.Write(C, 1);
  if (Len <> 80) and (Len <> 132) then
   begin
     S := #13#10;
     St^.Write(S[1], 2);
   end;
end;

function StoreFile(const Mask, Title: String; AddLF: Boolean): PStream;
  var S: PStream;
      N: String;
      P: Pointer;
      K: Word;
begin
   StoreFile := nil;
   N := GetFileNameDialog(Mask, Title, GetString(dlFileName),
                          fdOKButton + fdHelpButton, 150);
   if N = '' then Exit;
   P := @N;
   S := New(PDosStream, Init(N, stOpenRead));
   K := cmYes;
   if S^.Status = stOK then
       K := MessageBox(DNApp.GetString(dlFileExist), @P, mfWarning+mfYesButton+mfNoButton+mfAppendButton);
  S^.Free;
  if (K <> cmYes) and (K <> cmOK) then Exit;
  if K = cmYes then S := New(PBufStream, Init(N, stCreate, 2000))
               else begin
                       S := New(PBufStream, Init(N, stOpen, 2000));
                       FreeStr := #13#10;
                       S^.Seek(S^.GetSize);
                       if AddLF then S^.Write(FreeStr[1], 2);
                    end;
  if S^.Status <> stOK then
    begin
       S^.Free;
       MessageBox(DNApp.GetString(dlFBBNoWrite)+N, @P, mfError+mfOKButton);
       Exit;
    end;
  StoreFile := S;
end;


constructor TScrollBackWindow.Init;
 var R: TRect;
begin
  inherited Init(Bounds, 'Scrollback Buffer', 0);
  GetExtent(R); R.Grow(-1,-1);
  Insert(New(PScrollBack, Init(R, StandardScrollBar(sbHorizontal+sbHandleKeyboard),
                                  StandardScrollBar(sbVertical+sbHandleKeyboard))));
end;

procedure TScrollBackWindow.Zoom;
var
  R: TRect;
  Max, Min: TPoint;
begin
  SizeLimits(Min, Max);
  if Longint(Size) <> Longint(Max) then
  begin
    GetBounds(ZoomRect);
    Longint(R.A) := 0;  Dec(R.A.X); Dec(R.A.Y);
    R.B := Max;         Inc(R.B.X);
    Locate(R);
  end else Locate(ZoomRect);
end;

procedure TScrollBackWindow.SizeLimits(var Min, Max: TPoint);
begin
   Longint(Min) := 0;
   Min := MinWinSize;
   if Owner <> nil then
        begin
           Max.X := Owner^.Size.X+2;
           Max.Y := Owner^.Size.Y+2;
        end else Longint(Max) := $7FFF7FFF;
end;

function TScrollBackWindow.ReactOnCmd;
begin
  ReactOnCmd := On;
end;

procedure NewBackRec;
  var P: PScrollRec;
      I: Integer;
begin
  if ScrollBackBuffer = nil then ScrollBackBuffer := New(PCollection, Init(40,40));
  New(P, Init(B, Len*2));
  if P <> nil then ScrollBackBuffer^.Insert(P);
end;


constructor TScrollBack.Init;
  var I, W, H: Integer;
  procedure DoCount(P: PScrollRec); far;
  begin
    if (P <> nil) and (P^.Len div 2 > I) then I := P^.Len div 2;
  end;
begin
  inherited Init(Bounds, AHScrollBar, AVScrollBar);
  ScrollBack := @Self;
  HelpCtx := hcScrollBack;
  I := 80;
  if ScrollBackBuffer = nil then ScrollBackBuffer := New(PCollection, Init(40,40));
  ScrollBackBuffer^.ForEach(@DoCount);
  GrowMode := gfGrowHiX + gfGrowHiY;
  SetLimit(I, ScrollBackBuffer^.Count+ScreenHeight);
  W := 0; if Term <> nil then W := Term^.Delta.X;
  H := 0; if Term <> nil then H := Term^.Delta.Y;
  VScrollBar^.SetValue(Limit.Y-ScreenHeight+W);
  Delta.Y := Limit.Y-ScreenHeight+H;
  OldCut.Assign(20,10,30,11);
  CutRect.Assign(0,0,0,0);
end;

constructor TScrollBack.Load;
  var W,I: Word;
      B: Array [0..200] of Word;
begin
  inherited Load(S);
  if ScrollbackBuffer <> nil then
    begin
      Dispose(ScrollbackBuffer, Done);
      DeallocateScrollBk;
    end;
  S.Read(W, SizeOf(W));
  for I := 1 to W do
    begin
      S.Read(W, SizeOf(W));
      S.Read(B, W*SizeOf(Word));
      NewBackRec(B, W);
    end;
end;

procedure TScrollBack.Store;
  var W,I: Word;

  procedure DoWrite(P: PScrollRec); far;
    var B: Array [0..200] of Word;
        I: Word;
  begin
    I := P^.Len;
    P^.Read(B, 0, I);
    S.Write(I, SizeOf(I));
    S.Write(B, I*SizeOf(Word));
  end;

begin
  inherited Store(S);
  W := 0;
  if ScrollbackBuffer = nil then S.Write(W, SizeOf(W))
    else begin
           W := ScrollbackBuffer^.Count;
           S.Write(W, SizeOf(W));
           ScrollbackBuffer^.Pack;
           ScrollbackBuffer^.ForEach(@DoWrite);
         end;
end;

procedure TScrollBack.Draw;
  var I,J,K,M,KK,BY,BX: Integer;
      B: TDrawBuffer;
      P: PScrollRec;
      Blk, BlkM: Boolean;
begin
 Blk := CutRect.A.X <> CutRect.B.X;
 if (Term <> nil) and (Limit.X <> Term^.BufSize.X) then Limit.X := Term^.BufSize.X;
 BY := Term^.BufSize.Y; BX := Term^.BufSize.X;
 if Blk then
   with CutRect do
   begin
     BlkM := Off;
     if A.X < 0 then CutRect.Move(-A.X,0);
     if A.Y < 0 then CutRect.Move(0,-A.Y);
     if B.X - A.X > Size.X then B.X := A.X + Size.X;
     if B.Y - A.Y > Size.Y then B.Y := A.Y + Size.Y;
     if B.X > Limit.X then CutRect.Move(Limit.X-B.X, 0);
     if B.Y > Limit.Y then CutRect.Move(0, Limit.Y-B.Y);
     if A.X < Delta.X then
       begin Delta.X := A.X; BlkM := On; end;
     if CutRect.A.Y < Delta.Y then
       begin Delta.Y := A.Y; BlkM := On; end;
     if B.X - Delta.X > Size.X then
       begin Delta.X := B.X - Size.X; BlkM := On; end;
     if B.Y - Delta.Y > Size.Y then
       begin Delta.Y := B.Y - Size.Y; BlkM := On; end;
     if Delta.X < 0 then Delta.X := 0;
     if Delta.Y < 0 then Delta.Y := 0;
     if BlkM then ScrollTo(Delta.X, Delta.Y);
   end;
  for I := 0 to Size.Y-1 do
    begin
      M := I+Delta.Y;
      MoveChar(B, ' ', $03, Size.X);
      if M < ScrollBackBuffer^.Count then
       begin
         P := PScrollRec(ScrollBackBuffer^.At(M));
         KK := P^.Len div 2;
         if P^.Len > Delta.X then
             P^.Read(B, Delta.X, ((P^.Len div 2)-Delta.X)*SizeOf(Word));
       end else
       if (M-ScrollBackBuffer^.Count < BY) and (BX > Delta.X) and (Term <> nil) then
        begin
           KK := BX;
           Move(Term^.Buffer^[(M-ScrollBackBuffer^.Count)*Term^.BufSize.X+Delta.X], B,
                 (Term^.BufSize.X-Delta.X)*SizeOf(Word));
         end;
       if Blk and (M >= CutRect.A.Y) and (M < CutRect.B.Y) then
         begin
           J := CutRect.A.X;
           K := CutRect.B.X - J;
           {if Delta.X + K > KK then K := KK - Delta.X;}
           asm
             mov cx, K
             lea bx, B
             add bx, J
             add bx, J
            @@1:
             mov ax, word ptr ss:[bx]
             xor ah, $7F
             and ah, $7F
             mov word ptr ss:[bx], ax
             add bx, 2
             loop @@1
           end;
         end;
      WriteLine(0, I, Size.X, 1, B);
    end;
end;


procedure TScrollBack.HandleEvent(var Event: TEvent);

  function GetString(N: Integer): String;
    var B: Array[0..200] of Word;
        S: String;
        P: Pointer;
        L: Integer;
  begin
     if N < ScrollBackBuffer^.Count then
      with PScrollRec(ScrollBackBuffer^.At(N))^ do
         begin  Read(B, 0, Len); P := @B; L := Len end
       else if Term <> nil then begin
              P := @Term^.Buffer^[(N-ScrollBackBuffer^.Count)*Term^.BufSize.X];
              L := ScreenWidth;
            end;
     FillChar(S[1], L, 32);
     S[0] := Char(L);
     asm
       lea  bx, S
       les  di, P
       mov  cx, L
     @@1:
       inc  bx
       mov  al, es:[di]
       or   al, al
       jnz @@2
       mov  al, ' '
     @@2:
       mov  ss:[bx], al
       inc  di
       inc  di
       loop @@1
     end;
    While (S[Length(S)] = ' ') do Dec(S[0]);
    GetString := S;
  end;

  procedure ReturnString;
    var I: Integer;
  begin
    Move(Event.InfoPtr^, I, 2);
    PString(Event.InfoPtr)^ := GetString(I);
    ClearEvent(Event);
  end;

  procedure KillBuffer;
  begin
    if MessageBox(^C'Kill entire buffer?', nil, mfYesNoConfirm) <> cmYes then Exit;
    ScrollBackBuffer^.FreeAll;
    SetLimit(ScreenWidth, ScreenHeight);
    DrawView;
    DeallocateScrollBk;
    SBackEnd := 0;
  end;

  procedure Search;
    const S: String[80] = '';
          LastPos: Integer = 0;
    var I,J,K: Integer;
          M: String;
  begin
    M := S;
    if S = '' then S := HistoryStr(hsViewFind, 0);
    if InputBox('Find Text', '~T~ext', S, 80, hsViewFind) <> cmOK then Exit;
    if S = '' then Exit;
    if (M <> S) or (Delta.Y <> LastPos) then LastPos := Delta.Y else Inc(LastPos);
    UpStr(S);
    for I := LastPos to Limit.Y-1 do
       begin
         J := Pos(S, UpStrg(GetString(I)));
         if J > 0 then
          begin
            LastPos := I;
            ScrollTo(0,I);
            CutRect.Assign(J-1,I,J+Length(S)-1,I+1);
            DrawView;
            CutRect.Assign(0,0,0,0);
            Exit;
          end;
       end;
    CutRect.Assign(0,0,0,0);
    DrawView;
    MessageBox(DNApp.GetString(dlDBViewSearchNot),nil,mfError+mfOKButton);
  end;

  procedure SaveDisk;
    var St: PStream;
        S: String;
        I: Integer;
        P: Pointer;
  begin
    St := StoreFile(x_x, 'Save Scrollback Buffer',On);
    if St = nil then Exit;
    S := Strg('*', Limit.X)+#13#10; St^.Write(S[1], Length(S));
    S := Strg(' ',20) + 'Scrollback buffer saved '+GetDateTime(Off)+' '+GetDateTime(On) + #13#10;
    St^.Write(S[1], Length(S));
    S := Strg('*', Limit.X) + #13#10; St^.Write(S[1], Length(S));
    for I := 0 to Limit.Y-1 do
      begin
        S := GetString(I) + #13#10;
        St^.Write(S[1], Length(S));
      end;
    St^.Free;
  end;

  function MakeGrab: Boolean;
    var W,L: Word;
        R: TRect;
        PC: PLineCollection;
        S: String;

     procedure SaveText;
       var St: PStream;
           I: Integer;
     begin
       St := StoreFile('*.ASC', 'Write to ASCII File',On);
       if St = nil then Exit;
       for I := CutRect.A.Y to CutRect.B.Y-1 do
         begin
           S := Copy(GetString(I),CutRect.A.X+1,L)+#13#10;
           St^.Write(S[1], Length(S));
         end;
       St^.Free;
     end;

     procedure SaveANSI_AVT(AVT: Boolean);
       var St: PStream;
           B: Array[0..200] of Word;
           A: Byte;
           I,X: Integer;
           P: Pointer;
     begin
       if AVT then St := StoreFile('*.AVT', 'Write to Avatar File',On)
              else St := StoreFile('*.ANS', 'Write to ANSI File',On);
       if St = nil then Exit;
       A := 0; X := CutRect.A.X;
       for I := CutRect.A.Y to CutRect.B.Y-1 do
        begin
          if I < ScrollBackBuffer^.Count then
              begin P := @B; PScrollRec(ScrollBackBuffer^.At(I))^.Read(B, X, 2*(Limit.X-X)); end
              else if Term <> nil then P := @Term^.Buffer^[X+(I-ScrollBackBuffer^.Count)*Term^.BufSize.X];
          if AVT then SaveAvatar(St, P^, L, A)
                 else SaveANSI(St, P^, L, A);
        end;
       St^.Free;
     end;
  begin
    MakeGrab := Off;
    L := CutRect.B.X-CutRect.A.X;
    R.A.X := CutRect.A.X - Delta.X;
    R.A.Y := CutRect.A.Y - Delta.Y;
    MakeGlobal(R.A, R.A); R.B.X := R.A.X+40; R.B.Y := R.A.Y + 10;
    W := Application^.ExecView(New(PMenuBox, Init(R,
             NewMenu(
                NewItem('Copy to ~T~erminal', '', kbNoKey, 1000, hcNoContext,
                NewItem('Copy to ~H~istory', '', kbNoKey, 1001, hcNoContext,
                NewItem('Copy to ~C~lipboard', '', kbNoKey, 1002, hcNoContext,
                NewLine(
                NewItem('Save as A~S~CII', '', kbNoKey, 1003, hcNoContext,
                NewItem('Save as ~A~NSI', '',  kbNoKey, 1004, hcNoContext,
                NewItem('Save as A~v~atar', '', kbNoKey, 1005, hcNoContext,
                    nil)))))))),
             nil)));
    if W < 1000 then Exit;
    MakeGrab := On;
    case W of
      1004,1005: SaveANSI_AVT(W=1005);
      1000: begin
              New(PC, Init(CutRect.B.Y-CutRect.A.Y, 10));
              for W := CutRect.A.Y to CutRect.B.Y - 1 do
               begin
                 S := Copy(GetString(W), CutRect.A.X+1, L);
                 PC^.Insert(NewStr(S));
               end;
              for W := 0 to PC^.Count-1 do
                begin
                  S := AddSpace(CnvString(PC^.At(W)), L)+#13#10;
                  Message(Term, evCommand, cmSendTerminalString, @S);
                end;
              Dispose(PC, Done);
            end;
      1001: begin
              for W := CutRect.A.Y to CutRect.B.Y - 1 do
               begin
                 S := Copy(GetString(W), CutRect.A.X+1, L);
                 Replace(#0, '', S);
                 DelRight(S);
                 while S[Length(S)] in [#0,' '] do Dec(S[0]);
                 if S <> '' then
                   begin
                     if CommandsHistory = nil then
                       CommandsHistory := New(PLineCollection, Init(10,10));
                     CommandsHistory^.Insert(NewStr(S));
                   end;
               end;
            end;
      1002: begin
              if Clipboard <> nil then Dispose(Clipboard, Done);
              Clipboard := New(PLineCollection, Init(CutRect.B.Y-CutRect.A.Y, 10));
              for W := CutRect.A.Y to CutRect.B.Y - 1 do
               begin
                 S := AddSpace(Copy(GetString(W), CutRect.A.X+1, L), L);
                 Clipboard^.Insert(NewStr(S));
               end;
            end;
      1003: SaveText;
    end;
    CutRect.Move(-Delta.X,-Delta.Y);
    OldCut := CutRect;
    CutRect.Assign(0,0,0,0);
    DrawView;
  end;


  procedure Grab;

  label Rep;

 begin
  CutRect := OldCut; CutRect.Move(Delta.X,Delta.Y);
Rep:
  repeat
   DrawView;
   KeyEvent(Event);
   case Event.KeyCode of
    kbLeft,kbLeft or $E0: if ShiftState and 3 = 0 then CutRect.Move(-1,0)
               else if CutRect.B.X > CutRect.A.X + 1 then Dec(CutRect.B.X);
    kbRight,kbRight or $E0:if ShiftState and 3 = 0 then CutRect.Move(1,0)
               else if CutRect.B.X - CutRect.A.X < Size.X then Inc(CutRect.B.X);
    kbUp,kbUp or $E0: if ShiftState and 3 = 0 then CutRect.Move(0,-1)
               else if CutRect.B.Y > CutRect.A.Y + 1 then Dec(CutRect.B.Y);
    kbDown,kbDown or $E0:if ShiftState and 3 = 0 then CutRect.Move(0,1)
               else if CutRect.B.Y - CutRect.A.Y < Size.Y then Inc(CutRect.B.Y);
   end;
  until (Event.KeyCode = kbEnter) or (Event.KeyCode = kbEsc);
  if (Event.KeyCode = kbEnter) then
   begin
      if not MakeGrab then Goto Rep
   end else
       begin
         CutRect.Move(-Delta.X,-Delta.Y);
         OldCut := CutRect;
         CutRect.Assign(0,0,0,0);
         DrawView;
       end;
 end;


  var CE: Boolean;
      MP: TPoint;
      I: Integer;

begin
  CE := On;
  inherited HandleEvent(Event);
  case Event.What of
     evMouseDown: begin
                    MP := Event.Where; RepeatDelay := 1000;
                    repeat
                       MakeLocal(MP, CutRect.A);
                       MakeLocal(Event.Where, CutRect.B);
                       CutRect.Move(Delta.X, Delta.Y);
                       if CutRect.A.X > CutRect.B.X then
                         begin I := CutRect.A.X; CutRect.A.X := CutRect.B.X; CutRect.B.X := I end;
                       if CutRect.A.Y > CutRect.B.Y then
                         begin I := CutRect.A.Y; CutRect.A.Y := CutRect.B.Y; CutRect.B.Y := I end;
                       if MP.X <= Event.Where.X then Inc(CutRect.B.X);
                       if MP.Y <= Event.Where.Y then Inc(CutRect.B.Y);
                       DrawView;
                    until not MouseEvent(Event, evMouseMove+evMouseAuto);
                    RepeatDelay := 2;
                    if not ((CutRect.A.X + 1 >= CutRect.B.X) and
                            (CutRect.A.Y + 1 >= CutRect.B.Y)) then MakeGrab;
                    CutRect.Assign(0,0,0,0);
                    DrawView;
                  end;
     evCommand: case Event.Command of
                  cmGetName: PString(Event.InfoPtr)^ := DNApp.GetString(dlScrollBack);
                  cmSearchFor: Search;
                  cmSBBKill: KillBuffer;
                  cmSBBStore: SaveDisk;
                  cmSBBGrab: Grab;
                  else CE := Off;
                end;
     evKeyDown: case Event.KeyCode of
                  kbHome,kbCtrlHome: begin Event.KeyCode := kbCtrlPgUp; CE := Off; end;
                  kbEnd,kbCtrlEnd: begin Event.KeyCode := kbCtrlPgDn; CE := Off; end;
                  kbESC: begin Event.What := evCommand; Event.Command := cmClose; CE := Off; end;
                  {
                  else if Event.CharCode > #32 then
                        begin
                         case Event.CharCode of
                           'K','k': KillBuffer;
                           'F','f': Search;
                           'D','d': SaveDisk;
                           'G','g': Grab;
                         end;
                         ClearEvent(Event);
                        end
                  }
                  else CE := Off;
                end;
     else CE := Off;
  end;
  if CE then ClearEvent(Event);
end;


destructor TScrollBack.Done;
begin
  ScrollBack := nil;
  inherited Done;
end;


end.