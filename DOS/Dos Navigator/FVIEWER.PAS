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
//     "Based on Dos Navigator by RIT Research Labs."
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

unit FViewer;

interface

uses Objects, Views, Dos, Drivers, HideView, Commands, DNHelp, ObjType;

type

  { TViewScroll }

  PViewScroll = ^TViewScroll;
  TViewScroll = object(TView)
   MaxV, Value: LongInt;
   function GetPalette: PPalette; virtual;
   procedure HandleEvent(var Event: TEvent); virtual;
   function GetPartCode: LongInt;
   procedure Draw; virtual;
   function GetSize: Integer;
   procedure DrawPos(Pos: Integer);
  end;

  { TFileViewer }

  PFileViewer = ^TFileViewer;
  TFileViewer = object(THideView)
    RdOnly: Boolean;
    NoEdit: Boolean;
    FileName: PathStr;
    Buf: PByteArray;
    Fl: PStream;
    XDelta, ViewMode, HexPos: Integer;
    SearchActive: Boolean;
    SearchX: LongInt;
    SB: PView;
    Wrap: Boolean;
    Lines: Array[0..200] of record Pos: LongInt; Len: Byte; end;
    FilePos, FileSize, NumLines: LongInt;
    Cur: TPoint;
    Info: PView;
    BufPos: Word;
    BufSize: LongInt;
    BufLines, MaxLines: Integer;
    KillAfterUse, IsValid, QuickView, Loaded, HexEdit, BufModified: Boolean;
    Filter: Byte;
    XLAT: Array [Char] of Char;
    UseXLAT: Boolean;
    XLatFile: String[8];
    constructor Init(var Bounds: TRect; AStream: PStream;
                     AFileName: PathStr; ASB: PView; Quick, Hex: Boolean);
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    destructor Done; virtual;
    procedure ShowView; virtual;
    procedure HideView; virtual;
    procedure Draw; virtual;
    procedure SetXlatFile(const aFName: String);
    procedure ReadFile(FName: PathStr; NewStream: Boolean);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function  WriteModify: Boolean;
    procedure CountDown(ANumber: Integer); virtual;
    procedure CountUp(ANumber: Integer); virtual;
    procedure Seek(APos: LongInt);
    procedure MakeLines; virtual;
    function Valid(Command: Word): Boolean; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetPalette: PPalette; virtual;
  private
    procedure AdjustBufSize;
  end;

  PHFileViewer = ^THFileViewer;
  THFileViewer = object(TFileViewer)
   procedure ChangeBounds(var Bounds: TRect); virtual;
   function GetPalette: PPalette; virtual;
  end;

  PNFileViewer = ^TNFileViewer;
  TNFileViewer = object(TFileViewer)
   function GetPalette: PPalette; virtual;
  end;

  PFileWindow = ^TFileWindow;
  TFileWindow = object(TStdWindow)
    constructor Init(const FileName: PathStr; Hex: Boolean);
    function GetPalette: PPalette; virtual;
    function  ReactOnCmd: Boolean; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
  end;

  PViewInfo = ^TViewInfo;
  TViewInfo = object(TView)
    Viewer: PFileViewer;
    constructor Init(var R: TRect; AViewer: PFileViewer);
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

const

  RFileViewer: TStreamRec = (
     ObjType: otFileViewer;
     VmtLink: Ofs(TypeOf(TFileViewer)^);
     Load:    @TFileViewer.Load;
     Store:   @TFileViewer.Store
  );
  RFileWindow: TStreamRec = (
     ObjType: otFileWindow;
     VmtLink: Ofs(TypeOf(TFileWindow)^);
     Load:    @TFileWindow.Load;
     Store:   @TFileWindow.Store
  );
  RViewScroll: TStreamRec = (
     ObjType: otViewScroll;
     VmtLink: Ofs(TypeOf(TViewScroll)^);
     Load:    @TViewScroll.Load;
     Store:   @TViewScroll.Store
  );
  RHFileViewer: TStreamRec = (
     ObjType: otHFileViewer;
     VmtLink: Ofs(TypeOf(THFileViewer)^);
     Load:    @THFileViewer.Load;
     Store:   @THFileViewer.Store
  );
  RViewInfo  : TStreamRec = (
     ObjType: otViewInfo;
     VmtLink: Ofs(TypeOf(TViewInfo)^);
     Load:    @TViewInfo.Load;
     Store:   @TViewInfo.Store
   );

  CHViewer = #13#14;
  CViewer  = #6#7;
  CViewWindow = #112#113#114#115#116#117#118;

type
  TViewSearch = record What: String[250]; Opts: Word; Dir: Word end;

const
  cmChangeValue = 9990;
  SearchString: TViewSearch = (What:''; Opts: 0; Dir: 0);

var
  LastViewerBounds: TRect;

const
  LastViewerDeskSize: TPoint = (X:0;Y:0);
  LastEditDeskSize: TPoint = (X:0;Y:0);

function SearchFileStr(F: PStream; What: String; Pos: LongInt;
                          CaseSensitive, Display, WholeWords, Back: Boolean): LongInt;

implementation

uses Memory, Messages, DNApp, Advance, Startup, Dialogs, RStrings,
     Gauge, Microed, DNStdDlg, Histries, xTime, Drives;

function MaxAvail: LongInt;
begin
  MaxAvail := MemAdjust(System.MaxAvail);
end;

const
  ViewerBufSize = $8000{8192};

function SearchFileStr;
 label 1, LExit;
 var Buf: PByteArray;
     Count: LongInt;
     BufLen, BufPos, BPos, T, StPos, StDelta: Word;
     I, L, J, OldPos, NextPos: LongInt;
     CancelSearch: Boolean;
     Info: PWhileView;
     R: Trect;
     Tmr: TEventTimer;
     Inserted: Boolean;
begin
 Info := nil;
 SearchFileStr := -1; Count := 0; ClrIO;
 OldPos := F^.GetPos; L := F^.GetSize; if L = 0 then goto LExit;
 F^.Seek (Pos);
 BufLen := $7000;
 if LongInt(BufLen) > L then  BufLen := L;
 if BufLen > MaxAvail then BufLen := MaxAvail;
 if BufLen < Length(What)*2 then begin F^.Seek(OldPos); goto LExit; end;
 StPos := 0;
 if Display then
  begin
   R.Assign(1,1,30,9);
   New(Info, Init(R));
   Info^.Top := GetString(dlSearchProgress);
   NewTimer(Tmr, 2); Inserted := False;
  end;
 GetMem(Buf, BufLen); I := Pos; BPos := 0; CancelSearch := Off;
 repeat
   if Back then
     begin
       NextPos := I - BufLen + BPos;
       if NextPos < 0 then begin NextPos := 0; BPos := 0; end;
       J := I - NextPos;
       if J <= 0 then Break;
     end else
       begin
         NextPos := F^.GetPos;
         J := L - I + BPos; if J > BufLen then J := BufLen; ClrIO;
       end;
   if Display then
    begin
     Info^.Write(1, StrGrd(L, I, 30));
     Info^.Write(2, ItoS(Percent(L, I))+'%');
     if (not Inserted) and TimerExpired(Tmr) then
     begin
       Desktop^.Insert(Info);
       Inserted := True;
     end;
     if Inserted then DispatchEvents(Info, CancelSearch);
    end;
   F^.Seek(NextPos);
   F^.Read(Buf^[BPos], J-BPos); T := J-BPos;
 1:
   if J <= 0 then BufPos := 0 else
   if Back then BufPos := BackSearchFor(What, Buf^[StPos], J-StPos, CaseSensitive)
           else BufPos := SearchFor(What, Buf^[StPos], J-StPos, CaseSensitive);
   if BufPos > 0 then
    begin
     if WholeWords and not (((BufPos = 1) or (Char(Buf^[BufPos-2+StPos]) in BreakChars)) and
         (Char(Buf^[BufPos+Length(What)-1+StPos]) in BreakChars)) then
           begin
             if Back then Dec(J, StPos-BufPos)
                     else Inc(StPos, BufPos);
             Goto 1;
           end;
     FreeMem(Buf, BufLen); F^.Seek(OldPos);
     SearchFileStr := NextPos - LongInt(BPos) + LongInt(BufPos) - 1 + StPos;
     goto LExit;
    end;
   if Back then
     begin
       Dec(I,T);
       if I < -T then Break;
       if I < 0 then I := 0;
     end else Inc(I,T);
   StPos := 1;
   BPos := Length(What)+1;
   if I < L then Move(Buf^[J-BPos], Buf^[0], BPos);
 until  Back and (I < 0) or
        not Back and ((I >= L) or (T <= 0) or CancelSearch or (F^.GetPos >= F^.GetSize));
 if CancelSearch then SearchFileStr := -2;
 FreeMem(Buf, BufLen); F^.Seek(OldPos);
LExit: FreeObject(Info);
end;

constructor TViewInfo.Init(var R: TRect; AViewer: PFileViewer);
begin
 inherited Init(R);
 Viewer := AViewer;
 GrowMode := gfGrowHiY + gfGrowLoY;
 EventMask := evMouse;
end;

constructor TViewInfo.Load(var S: TStream);
begin
 inherited Load(S);
 GetPeerViewPtr(S, Viewer);
end;

procedure TViewInfo.Store(var S: TStream);
begin
 inherited Store(S);
 PutPeerViewPtr(S, Viewer);
end;

procedure TViewInfo.Draw;
 var B: TDrawBuffer;
     S: String;
     I,J: Integer;
begin
 if Viewer = nil then begin inherited Draw; Exit; end;
 With Viewer^ do
  begin
    if ViewMode <> 1 then
      begin
        if Wrap then S := '>=<][' else S := '<=>][';
        if (Lines[Size.Y].Pos < 0) and (FilePos+BufSize >= FileSize)
                  or (FileSize = 0) then S := S + '100'
          else S := S + ItoS(Percent(FileSize, FilePos+BufPos));
        S := S + '% of ' + FStr(Viewer^.FileSize) + ' Bytes';
      end else
      begin
        S := Hex8(Cur.X div (1+Byte(HexEdit))+Cur.Y*HexPos+BufPos+FilePos)+' ';
        J := (FilePos+BufPos) mod max(1,HexPos);
        for I := 0 to HexPos - 1 do
          S := S+Hex2(I+J)+'Ä';
        Dec(S[0]);
      end;
    Insert('[', S, 1);
    case Filter of
      0: AddStr(S, ']');
      1: Insert(']{ASCII}', S, Length(S)+1);
       else Insert(']{32-255}', S, Length(S)+1);
    end;
    if UseXlat then Insert('(X)', S, Length(S)+1);

  end;
 if Byte(S[0]) <> Size.X then GrowTo(Byte(S[0]), 1);
 MoveStr(B, S, Owner^.GetColor(2));
 WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TViewInfo.HandleEvent;
  var P: TPoint;
begin
  if (Event.What = evMouseDown) and Event.Double and (Viewer^.ViewMode = 0) then
    begin
      MakeLocal(Event.Where, P);
      if P.X < 5 then Message(Viewer, evCommand, cmUnwrap, nil);
      ClearEvent(Event);
    end;
end;


function TFileViewer.WriteModify;
 var B: Boolean;
     I: LongInt;
     S: TDOSStream;
begin
 B := BufModified; WriteModify := Off;
 if (Buf = nil) or (Fl = nil) or (Fl^.Status <> stOK) or not B then Exit;
 I := MessageBox(GetString(dlViewQuery), nil, mfWarning+mfYesNoCancel);
 WriteModify := I = cmCancel;
 if I <> cmCancel then BufModified := Off;
 if I = cmNo then begin Seek(FilePos); DrawView; end;
 if I <> cmYes then Exit;
 if (TypeOf(Fl^)=TypeOf(TDOSStream)) or (TypeOf(Fl^)=TypeOf(TBufStream)) then
  begin
    Dispose(Fl, Done);
    Fl := New(PDosStream, Init(FileName, stOpen));
    if (Fl^.Status <> stOk) or (Abort) then
       begin
         Dispose(Fl, Done); Fl := New(PDosStream, Init(FileName, stOpenRead));
         MessageBox(GetString(dlFBBNoWrite)+FileName, nil, mfError + mfOKButton);
         Exit;
       end;
  end;
  Fl^.Seek(FilePos); Fl^.Write(Buf^, BufSize);
  RereadDirectory(GetPath(FileName));
end;

const SCViewer: String[Length(CViewer)] = CViewer;
      SCHViewer: String[Length(CHViewer)] = CHViewer;
      SCNViewer: String[Length(CInputLine)] = CInputLine;
      SCViewWindow: String[Length(CViewWindow)] = CViewWindow;


function TFileViewer.GetPalette;
begin
 GetPalette := @SCViewer;
end;

function TNFileViewer.GetPalette;
begin
 GetPalette := @SCNViewer;
end;

function THFileViewer.GetPalette;
begin
 GetPalette := @SCHViewer;
end;

function TFileWindow.GetPalette;
begin
 GetPalette := @SCViewWindow;
end;

{TViewScroll}

function TViewScroll.GetSize: Integer;
var
  S: Integer;
begin
  if Size.X = 1 then S := Size.Y else S := Size.X;

  if S < 3 then GetSize := 3 else GetSize := S;
end;

procedure TViewScroll.DrawPos(Pos: Integer);
var
  S: Integer;
  B: TDrawBuffer;
Const  Chars :  TScrollChars = (#30, #31, #177, #254, #178);
begin
  S := GetSize - 1;
  MoveChar(B[0], Chars[0], GetColor(2), 1);
 { if Max = Min then
    MoveChar(B[1], Chars[4], GetColor(1), S - 1)
  else    }
  begin
    MoveChar(B[1], Chars[2], GetColor(1), S - 1);
    MoveChar(B[Pos], Chars[3], GetColor(3), 1);
  end;
  MoveChar(B[S], Chars[1], GetColor(2), 1);
  WriteBuf(0, 0, Size.X, Size.Y, B);
end;


procedure TViewScroll.HandleEvent;
 var B : Boolean;
     P: TPoint;
     RD,SP: LongInt;

     Extent: TRect;
     Tracking : Boolean;

begin
 TView.HandleEvent(Event);
 case Event.What of
  evCommand: case Event.Command of
              cmChangeValue: begin Value := Event.InfoLong;
                                   DrawView; ClearEvent(Event)
                             end;
{              cmSetMargins: Message(Owner, evCommand, cmGotoLineNumber, Pointer(Value));}
             end;
  evMouseDown: if MaxV>0 then begin

               MakeLocal(Event.Where, P);
               GetExtent(Extent);
               {if LongDiv(LongMul(Value,Size.Y-2),MaxV)+1 = P.Y then}
               if Longint( Longint(Longint(Value) * Longint(Size.Y-2)) div MaxV ) + 1 = P.Y then
                begin
                RD := P.Y;
                repeat
                  MakeLocal(Event.Where, P);
                  Tracking := Extent.Contains(P);
                  if Tracking then
                  begin
                  {  if Size.X = 1 then} SP := P.Y {else I := P.X};
                    if SP <= 0 then SP := 1;
                    if SP >= Size.Y - 1 then SP := Size.Y - 2;
                  end;{ else I := GetPos;}
                  if SP <> RD then
                  begin
                    DrawPos(SP);
                     RD := SP;
                  end;
                until not MouseEvent(Event, evMouseMove+evMouseAuto);
                  if SP = Size.Y - 2  then
                     begin
                        Value := MaxV - (Size.Y-10)*10;
                        if Value > MaxV then Value := MaxV;
                     end
                  else if SP=1 then Value := 0
                 { else Value := LongMul( LongDiv(MaxV,Size.Y-2),SP );}
                  else Value := Longint( Longint( MaxV div Longint(Size.Y-2)) * SP );
                if Size.Y*4 > MaxV then Value:=0;
                DrawView;
                Message(Owner, evCommand, cmScrollBarChanged, Pointer(Value));
               Exit;
               end;


                MakeLocal(Event.Where,P); RD := RepeatDelay; RepeatDelay := 0;
                if Value >= MaxV then SP := Size.Y - 2
                                 else SP := GetPartCode;
                if P.Y = 0 then
                 begin
                  repeat
                   MakeLocal(Event.Where,P);
                   if (P.X>=-1) and (P.X<=1) and (P.Y>=-1) and (P.Y<=1) then
                    Message(Owner, evKeyDown, kbUp, nil);
                  until not MouseEvent(Event, evMouseMove+evMouseAuto);
                 end else
                if P.Y = Size.Y-1 then
                 begin
                  repeat
                   MakeLocal(Event.Where,P);
                   if (P.X>=-1) and (P.X<=1) and (P.Y>=Size.Y-2) and (P.Y<=Size.Y) then
                    Message(Owner, evKeyDown, kbDown, nil);
                  until not MouseEvent(Event, evMouseMove+evMouseAuto);
                 end else
                if P.Y < SP then
                 begin
                  RepeatDelay := RD;
                  repeat
                   if Value >= MaxV then SP := Size.Y - 2
                                    else SP := GetPartCode;
                   MakeLocal(Event.Where,P);
                   if (P.X>=-1) and (P.X<=1) and (P.Y<SP) then
                    Message(Owner, evKeyDown, kbPgUp, nil);
                  until not MouseEvent(Event, evMouseMove+evMouseAuto);
                 end else
                if P.Y > SP then
                 begin
                  RepeatDelay := RD;
                  repeat
                   if Value >= MaxV then SP := Size.Y - 2
                                    else SP := GetPartCode;
                   MakeLocal(Event.Where, P);
                   if (P.X>=-1) and (P.X<=1) and (P.Y>SP) then
                    Message(Owner, evKeyDown, kbPgDn, nil);
                  until not MouseEvent(Event, evMouseMove+evMouseAuto);
                 end;
                RepeatDelay := RD;
               end;
 end;
end;

function TViewScroll.GetPartCode: LongInt;
begin
GetPartCode := 1+((Size.Y-2)*Value) div MaxV;
end;

function TViewScroll.GetPalette;
 const S: String[Length(CScrollBar)] = CScrollBar;
begin
 GetPalette := @S;
end;

procedure TViewScroll.Draw;
 var B: Array[0..128] of record C: Char; B: Byte; end;
     B1: TDrawBuffer Absolute B;
     C1, C2: Byte;
begin
 C1 := GetColor(1); C2 := GetColor(2);
 MoveChar(B, '±', C1, Size.Y);
 if Value >= MaxV then B1[Size.Y-2] := 254+LongInt(C2*256)
                  else B1[GetPartCode] := 254+LongInt(C2*256);
 B1[0] := 30+LongInt(C2*256);
 B1[Size.Y-1] := 31+LongInt(C2*256);
 WriteBuf(0,0,1,Size.Y,B);
end;


{ THFileViewer }

procedure THFileViewer.ChangeBounds;
 var R: TRect;
begin
 SetBounds(Bounds);
 if Wrap then MakeLines;
 if SB <> nil then
  begin R :=Bounds; R.A.X := R.B.X; Inc(R.B.X); SB^.SetBounds(R) end
end;

{ TFileViewer }

procedure TFileViewer.ChangeBounds;
 var R: TRect;
begin
 SetBounds(Bounds);
 if Wrap or (ViewMode = 2) then MakeLines;
 DrawView;
end;

procedure TFileViewer.AdjustBufSize;
begin
  BufSize := ViewerBufSize;
  If BufSize > FileSize then BufSize := FileSize;
  If MaxAvail < BufSize then BufSize := MaxAvail;
end;

constructor TFileViewer.Init;
begin
  inherited Init(Bounds); ViewMode := 0;
  FillChar(Xlat, SizeOf(XLat), 0); UseXLat := Off;
  HelpCtx := hcView;
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofSelectable or (LongInt(Quick)*ofTopSelect);
  EventMask := $FFFF; SB := ASB; QuickView := Quick;
  Buf := nil; IsValid := True; Loaded := Off;
  KillAfterUse := TempFile <> '';
  TempFile := '';
  Wrap := EditorDefaults.ViOpt and 2 <> 0;
  ViewMode := {EditorDefaults.ViOpt and}Byte(Hex);
  Fl := AStream;
  if (AFileName = '') and (Fl = nil) then Exit;
  if Fl = nil then ReadFile(AFileName, On) else
  if (Fl <> nil) and (Fl^.Status = stOK) then ReadFile(' ', Off)
    else IsValid := Off;
end;

destructor TFileViewer.Done;
 var F: File;
begin
  EnableCommands([cmGotoCell,cmUnwrap]);
  if Buf <> nil then FreeMem(Buf, BufSize);
  if Fl <> nil then Dispose(Fl, Done);
  inherited Done;
end;

constructor TFileViewer.Load;
 var I: LongInt;
begin
 inherited Load(S);
 NoEdit := Off;
 BufModified := Off;
 GetPeerViewPtr(S, SB);
 GetPeerViewPtr(S, Info);
 S.Read(FileName[0], 1);
 S.Read(FileName[1], Length(FileName));
 S.Read(I, Sizeof(LongInt));
 S.Read(QuickView, 1);
 S.Read(Wrap, 1);
 S.Read(KillAfterUse, 1);
 S.Read(Filter, 1);
 S.Read(ViewMode, 2);
 S.Read(XlatFile, 9);
 S.Read(XLAT, SizeOf(XLAT));
 S.Read(UseXLAT, SizeOf(UseXLAT));
 Fl := nil; Buf := nil; IsValid := True; Loaded := On;
 if FileName = '' then Exit;
 ReadFile(FileName, On); Seek(I);
end;

procedure TFileViewer.Store;
 var I: LongInt;
begin
 inherited Store(S);
 PutPeerViewPtr(S, SB);
 PutPeerViewPtr(S, Info);
 S.Write(FileName[0], 1 + Length(FileName));
 I := FilePos + LongInt(BufPos);
 S.Write(I, Sizeof(LongInt));
 S.Write(QuickView, 1);
 S.Write(Wrap, 1);
 S.Write(KillAfterUse, 1);
 S.Write(Filter, 1);
 S.Write(ViewMode, 2);
 S.Write(XlatFile, 9);
 S.Write(XLAT, SizeOf(XLAT));
 S.Write(UseXLAT, SizeOf(UseXLAT));
end;

procedure XDumpStr(var S: String; var B; Addr: LongInt; Count: Integer; Filter: Byte);
begin
  S := Hex8(Addr)+' ';
  asm
    les  si, B
    mov  cx, Count
    push ds
    lds  di, S
    mov  bx, 10
    mov  ah, Filter
    jcxz @@3
@@1:
    mov  al, es:[si]
    or   ah, ah
    jz   @@2
    cmp  al, 32
    jnc  @@4
@@5:
    mov  al, 'ú'
    jmp  @@2
@@4:
    cmp  ah, 1
    jnz  @@2
    cmp  al, 128
    jnc  @@5
@@2:
    mov  ds:[di+bx], al
    inc  byte ptr ds:[di]
    inc  si
    inc  bx
    loop @@1
@@3:
    pop  ds
  end;
end;


procedure TFileViewer.Draw;
var
  B: Array[0..256*9] of Word;
  C: Byte;
  I, J, K, M, Src: Integer;
  L: LongInt;
  S: String;

procedure MoveStr(var B, S; C, Flt: Byte); assembler;
 asm
  push ds
  lds  si,B
  les  di,S
  mov  cl, es:[di]
  xor ch,ch
  jcxz @@Exit
  mov bx, 0
  mov ah, C
@@1:
  mov al, es:[di+1]
  cmp al, 9
  jne @@3
  mov al, ' '
@@2:
  mov ds:[si], ax
  add si,2
  inC bx
  mov dx, bx
  and dx, 7
  jnz @@2
  jmp @@4
@@3:
    cmp  Flt, 0
    jz   @@@2
    cmp  al, 32
    jnc  @@@4
@@@5:
    mov  al, 'ú'
    jmp  @@@2
@@@4:
    cmp  Flt, 1
    jnz  @@@2
    cmp  al, 128
    jnc  @@@5
@@@2:
  mov ds:[si], ax
  add si,2
  inc bx
@@4:
  inc di
  loop @@1
@@Exit:
  pop  ds
end;

 procedure XlatBuf(var B; Len: Integer; var XTable); assembler;
 asm
   cmp Len, 0
   jle @@1
   push ds
   mov cx, Len
   lds si, B
   les bx, XTable
   xor ah, ah
   cld
@@Loop:
   lodsb
   mov di, ax
   mov al, es:[bx+di]
   mov ds:[si-1], al
   loop @@Loop
   pop  ds
@@1:
 end;


var W: Integer;

begin
  if Buf = nil then
    begin
      ReadFile(FileName, On);
      BufPos := 0;
      MakeLines;
    end
    else
  if (BufPos < 0) or (BufPos > BufSize + 20000) or
     (BufPos > 65000) then
   begin
    BufPos := 0;
    MakeLines;
   end;
  C := GetColor(1);
  if (FileName = '') or (Buf = nil) then
   begin HideCursor; inherited Draw; Exit end;
 if ViewMode = 1 then
  begin
   EnableCommands([cmGotoCell]);
   DisableCommands([cmUnwrap]);
   HexPos := (Size.X - 12) div 4; if HexPos <= 0 then HexPos := 1;
   XDelta := 0;
   while (LongInt(Cur.Y * HexPos) + BufPos + FilePos >= FileSize) do Dec(Cur.Y);
   while (LongInt(Cur.Y * HexPos) + BufPos + FilePos + Cur.X div (Byte(HexEdit)+1) >= FileSize) do Dec(Cur.X);
   if Cur.Y < 0 then
    begin
     W := -Cur.Y;
     Cur.Y := 0;
     CountUp(W);
     Exit;
    end;
   if Cur.Y >= Size.Y then
    begin
     W := Cur.Y - Size.Y + 1;
     Dec(Cur.Y, W);
     CountDown(W);
     Exit;
    end;
   W := BufPos;
   L := FilePos + LongInt(BufPos);
   if HexEdit then SetCursor(10 + (Cur.X div 2) * 3 + Cur.X and 1, Cur.Y)
              else SetCursor(12 + HexPos * 3 + Cur.X, Cur.Y);
   ShowCursor;
   for I := 0 to Size.Y - 1 do
   begin
     MoveChar(B[XDelta], ' ', C, Size.X);
     if L + LongInt(HexPos) > FileSize then J := FileSize - L else J := HexPos;
     if J > 0 then
      begin
       if J = HexPos then Drivers.MoveStr(B, DumpStr(Buf^[W], L, J, Filter), C)
        else
         begin
          S := DumpStr(Buf^[W], L, J, Filter);
          Drivers.MoveStr(B, Copy(S, 1, J*3+10), C);
          Drivers.MoveStr(B[10+HexPos*3], Copy(S, J*3+11, 255), C);
         end;
       if SearchActive then
         begin
          if (L <= SearchX) and (L+J > SearchX) then
            begin
              Cur.Y := I; Cur.X := (SearchX-L)*2;
              if HexEdit then SetCursor(10 + (Cur.X div 2) * 3 + Cur.X and 1, Cur.Y)
                         else SetCursor(12 + HexPos * 3 + Cur.X, Cur.Y);
              ShowCursor;
              Src := Min(L+J-SearchX, Length(SearchString.What));
              MoveColor(B[10+(SearchX-L)*3], Src*3-1, GetColor(2));
              MoveColor(B[12+HexPos*3+SearchX-L], Src, GetColor(2));
              Src := Length(SearchString.What) - Src;
            end else
            if Src > 0 then
            begin
              K := Min(Src, J);
              MoveColor(B[10], K*3-1, GetColor(2));
              MoveColor(B[12+HexPos*3], K, GetColor(2));
              Dec(Src, J);
            end;
         end;
       Inc(W, J);
       Inc(L, LongInt(J));
      end;
     WriteLine(0, I, Size.X, 1, B[XDelta]);
   end;
  end
 else
 if ViewMode = 2 then
   begin
     EnableCommands([cmGotoCell]);
     DisableCommands([cmUnwrap]);
     HideCursor;
     HexPos := ((Size.X - 9) div 16)*16; if HexPos < 16 then HexPos := 16;
     W := BufPos; L := FilePos + LongInt(BufPos); Src := 0;
     for I := 0 to Size.Y - 1 do
     begin
       MoveChar(B[XDelta], ' ', C, Size.X);
       if L + LongInt(HexPos) > FileSize then J := FileSize - L else J := HexPos;
       if J > 0 then
        begin
          XDumpStr(S, Buf^[W], L, J, Filter);
          if UseXlat then XLatBuf(S[10], Length(S)-9, XLat);
          Drivers.MoveStr(B, S, C);
          if SearchActive then
            begin
             if (L <= SearchX) and (L+J > SearchX) then
               begin
                 Src := Min(L+J-SearchX, Length(SearchString.What));
                 MoveColor(B[9+SearchX-L], Src, GetColor(2));
                 Src := Length(SearchString.What) - Src;
               end else
               if Src > 0 then
               begin
                 MoveColor(B[9], Min(Src, J), GetColor(2));
                 Dec(Src, J);
               end;
            end;
          Inc(W, J);
          Inc(L, LongInt(J));
        end;
       WriteLine(0, I, Size.X, 1, B[XDelta]);
     end;
   end
 else
  begin
    DisableCommands([cmGotoCell]);
    EnableCommands([cmUnwrap]);
    for I := 0 to Size.Y - 1 do
    begin
      HideCursor;
      J := SearchX - FilePos - Lines[I].Pos;
      if SearchActive and (Lines[I].Pos <= SearchX - FilePos) and
         (Lines[I+1].Pos >= SearchX - FilePos) then
          begin
           K := 0; M := Lines[I].Pos;
           While M < J + Lines[I].Pos do
            begin repeat Inc(K) until (Buf^[M] <> 9) or (K and 7 = 0); Inc(M); end;
           if (XDelta + Size.X < K) or (XDelta > K ) then XDelta := K - Size.X div 2;
           if XDelta < 0 then XDelta := 0;
          end;
      MoveChar(B[XDelta], ' ', C, Size.X);
      if (Lines[I].Pos >=0) then
       begin
        Move(Buf^[Lines[I].Pos], S[1], Lines[I].Len); S[0] := Char(Lines[I].Len);
        if UseXlat then XLatBuf(S[1], Length(S), XLat);
        MoveStr(B, S, C, Filter);
       end;
      if SearchActive and (Lines[I].Pos <= SearchX - FilePos) and
         (Lines[I+1].Pos >= SearchX - FilePos) then
          begin
           K := 0; M := Lines[I].Pos;
           While M < J + Lines[I].Pos do
            begin repeat Inc(K) until (Buf^[M] <> 9) or (K and 7 = 0); Inc(M); end;
           MoveColor(B[K], Length(SearchString.What), GetColor(2));
          end;
      WriteLine(0, I, Size.X, 1, B[XDelta]);
    end;
  end;
 if Info <> nil then Info^.DrawView;
end;

procedure TFileViewer.ReadFile;
 var I, J: Integer;
     P: Pointer;
begin
  WriteModify;
  if Buf <> nil then FreeMem(Buf, BufSize); Buf := nil;
  BufModified := Off;
  IsValid := True;
  FileName := FName;
  if NewStream then
   begin
    if Fl <> nil then Dispose(Fl, Done); Fl := nil;
    if FName = '' then Exit;
    Fl := New(PDosStream, Init(FName, stOpenRead));
    RdOnly := Off;
   end;
  if Fl^.Status <> stOK then begin IsValid := False; Exit end;
  FileSize := FL^.GetSize; FilePos := 0; I := 1; NumLines := 1;
  if FileSize < 0 then FileSize := 0;
  AdjustBufSize;
  Buf := MemAlloc(BufSize);
  if SB <> nil then PViewScroll(SB)^.MaxV := FileSize;
  Seek(0); XDelta := 0;
end;

procedure TFileViewer.SetState;
begin
  inherited SetState(AState, Enable);
  if (AState and (sfActive + sfSelected) <> 0) then
   if GetState(sfSelected) and (Owner^.GetState(sfActive)) then
    begin if SB <> nil then begin SB^.Show; SB^.EventMask := $FFFF end; DrawView end
    else if SB <> nil then begin SB^.Hide; SB^.EventMask := 0; end;
end;

procedure TFileViewer.HideView;
 var E: TEvent;
begin
 if SB <> nil then begin SB^.Hide; SB^.EventMask := 0; end;
 Message(Owner, evCommand, cmDisableView, nil);
 inherited HideView;
end;

procedure TFileViewer.ShowView;
 var E: TEvent;
begin
 if SB <> nil then begin SB^.Show; SB^.EventMask := 0; end;
 Message(Owner, evCommand, cmEnableView, nil);
 inherited ShowView;
end;

procedure TFileViewer.Seek;
begin
 if Buf = nil then Exit;
 FileSize := Fl^.GetSize;
 WriteModify;
 if APos < 0 then APos := 0;
 FilePos := APos;
 if FilePos < 0 then FilePos := 0;
 if FilePos = 0 then
  begin
   if Buf <> nil then FreeMem(Buf, BufSize);
   AdjustBufSize;
   GetMem(Buf, BufSize);
   if Buf = nil then Exit;
  end;
 if APos + BufSize >= FileSize then FilePos := FileSize - BufSize;
 Fl^.Seek(FilePos);
 if (FileSize-FilePos < BufSize) then
  begin
   FreeMem(Buf, BufSize); BufSize := FileSize-FilePos;
   if BufSize < 0 then BufSize := 0;
   Buf := MemAlloc(BufSize); if Buf = nil then Exit;
  end;
 BufPos := APos - FilePos; if BufPos < 0 then BufPos := 0;
 if BufPos > BufSize then BufPos := BufSize - 1;
 Fl^.Read(Buf^, BufSize);
 MakeLines;
 Message(SB, evCommand, cmChangeValue, Pointer(FilePos+BufPos));
end;

procedure TFileViewer.MakeLines;
 var P1, P2: Pointer;
     I, J, K, Hx: longInt;
     B: Byte;
     MaxX: longInt;
begin
 if Buf = nil then Exit;
 if Wrap then MaxX := Size.X else MaxX := 255;
 P1 := Buf; P2 := @Lines; J := BufPos; I := BufSize - J;
 MaxLines := 200;
 FillChar(Lines, SizeOf(Lines), 0);
 case ViewMode of
  1, 2: begin
      I := BufPos;
      for K := 0 to MaxLines do
       begin Lines[K].Pos := I; Lines[K].Len := HexPos; Inc(I, HexPos); end;
     end;
  else for K := 0 to MaxLines do
       begin
        I := (BufSize - J);
        Lines[K].Pos := -1;
        Lines[K].Len := 0;
        if I > 0 then
         begin
           Lines[K].Pos := J;
           if I > MaxX then I := MaxX;
           asm
            les di, P1
            add di, word ptr J
            mov cx, word ptr I
            xor dx, dx
            mov bh, 9
            mov ax, $0A0D
            mov bl, 0
       @@1:
            inc di
            cmp es:[di], bh
            jnz @@@1
            add dx, 8
            and dx, $FFF8
            dec dx
            jmp @@5
       @@@1:
            cmp es:[di-1], al
            jnz @@2
            dec cx
            cmp es:[di], ah
            jnz @@3
            dec cx
            jmp @@3
       @@2:
            cmp es:[di-1], ah
            jnz @@5
            dec cx
            jmp @@3
       @@5:
            inc  bl
            inc  dx
            cmp  dx, word ptr I
            jle  @@6
            dec  cx
            jmp  @@3
       @@6:
            loop @@1
       @@3:
            mov B, bl
            sub word ptr I, cx
            mov ax, word ptr J
            add ax, word ptr I
            mov word ptr J, ax
           end;
           Lines[K].Len := B;
         end;
       end;
 end;
end;

procedure TFileViewer.HandleEvent;

 var P: TPoint;
     LR: Integer;
     I: Integer;
     LLR,LFR: LongInt;
     F: File;

 procedure CE; begin ClearEvent(Event) end;

 procedure CM_END;
  var I, J: Integer;
 begin
  if Buf = nil then Exit;
  J := 0;
  CE; for I := 0 to SIze.Y - 1 do if J<Lines[I].Len then J := Lines[I].Len;
  Dec(J, Size.X);

  if J < 0 then XDelta := 0 else XDelta := J;
  DrawView;
 end;

 procedure SeekEOF;
   var I: Integer;
 begin
  if Lines[Size.Y].Pos < 0 then Exit;
  I := (FilePos+BufPos) mod 16;
  Owner^.Lock;
  Seek(FileSize - BufSize); BufPos := BufSize;
  if ViewMode = 1 then
      While (FilePos+BufPos) mod 16 <> I do Inc(BufPos);
  CountUp(Size.Y+3);
  CountDown(3);
  MakeLines;
  if ViewMode = 1 then
    begin
      Cur.X := HexPos*2-2;
      Cur.Y := 0;
      while Lines[Cur.Y+1].Pos >= 0 do Inc(Cur.Y);
    end;
  DrawView;
  if Cur.X and 1 <> 0 then
   begin
     Dec(Cur.X);
     DrawView;
   end;
  Owner^.UnLock;
 end;

 procedure ContinueSearch(Reverse: Boolean);
  var I, J, JJ: Integer;
 begin
  if (SearchString.What = '') then Exit;
  if SearchX < 0 then SearchX := 0;
  if (SearchX < FilePos + Lines[0].Pos) or
     (SearchX > FilePos + Lines[1].Pos+1)
     then SearchX := FilePos+BufPos;
  SearchX := SearchFileStr(Fl, SearchString.What, SearchX,
                               SearchString.Opts and 1 <> 0, On,
                               SearchString.Opts and 2 <> 0, (SearchString.Dir = 1) xor Reverse);
  if SearchX >= 0 then
   begin
    if HexPos > 0 then JJ := (FilePos+BufPos) mod HexPos;
    Seek(SearchX-256);
    J := SearchX - FilePos;
    if ViewMode = 0 then
      begin
        MakeLines;
        for I := 0 to MaxLines do
         if (Lines[I].Pos <= J) and ((Lines[I+1].Pos > J) or (Lines[I+1].Pos < 0)) then
          begin BufPos := Lines[I].Pos; MakeLines; Break end;
      end else
      begin
        BufPos := SearchX - FilePos;
        while (BufPos <> 0) and
          (JJ <> (FilePos + BufPos) mod HexPos) do Dec(BufPos);
      end;
    MakeLines;
    SearchActive := On;
    DrawView;
    Inc(Searchx{, LongInt(Byte(SearchString.What[0]))});
    SearchActive := Off; Inc(SearchX);
   end else if SearchX <> -2 then MessageBox(GetString(dlDBViewSearchNot), nil, mfError + mfOKButton);
 end;

 procedure StartSearch;
  var D: PDialog;
      SR: TViewSearch;
      R: TRect;
      P: PView;
      PP: PInputLine;
      I: Integer;

 begin
  if LowMemory then Exit;

  D := PDialog( LoadResource( dlgViewerFind ));

  With D^ do begin
    Current^.GetBounds( R ); R.Move( 0, 2 ); { Hope Current is InputLine }

    P := New( PHexLine, Init( R, PInputLine( Current )));
    InsertBefore( P, Current );
    R.Move( 0, -1 );
    InsertBefore( New( PLabel, Init( R, GetString( dlHexLabel ), P )), P );
    SelectNext( OFF );

    SetData(SearchString);
  end;

  I := Desktop^.ExecView(D);
  D^.GetData(SR);
  Dispose(D, Done);
  if I = cmCancel then Exit;
  SearchString := SR;
  SearchX := 0;
  ContinueSearch(Off);
 end;

 procedure SaveToFile(FN: String);
   var S: TDosStream;
       P: PView;
       W, L: Word;
       PS: Pointer;
       Xl: Boolean;
       Sz: LongInt;

   label 1, 2;

  procedure XlatBuf(var B; Len: Integer; var XTable); assembler;
  asm
    cmp Len, 0
    jle @@1
    push ds
    mov cx, Len
    lds si, B
    les bx, XTable
    xor ah, ah
    cld
 @@Loop:
    lodsb
    mov di, ax
    mov al, es:[bx+di]
    mov ds:[si-1], al
    loop @@Loop
    pop  ds
 @@1:
  end;


 begin

   Xl := (MaxAvail > 4096) and UseXlat and (MessageBox(GetString(dlViewSaveXlat), nil,
                                            mfYesButton+mfNoButton+mfConfirmation) = cmYes);

   S.Init(FN, stOpen);
   if S.Status = stOK then
     begin
        PS := @FN;
        W := MessageBox(GetString(dlED_OverQuery)
                        , @PS, mfYesButton+mfCancelButton+mfAppendButton+mfWarning);
        if W = cmYes then
          begin
1:
            S.Done;
            S.Init(FN, stCreate);
          end else
           if W = cmOK then S.Seek(S.GetSize) else
             begin S.Done; Exit end;
     end else Goto 1;

   if S.Status <> stOK then
     begin
       S.Done;
       MessageBox(GetString(dlFBBNoWrite)+Cut(FN,40), nil, mfError+mfOKButton);
       Exit
     end;
   P := _WriteMsg(^M^M^C+GetString(dlWritingFile));
   Fl^.Seek(0);
   if Xl then
     begin
       PS := MemAlloc(4096);
       if PS = nil then Goto 2;
       Sz := Fl^.GetSize;
       while Fl^.GetPos < Sz do
         begin
           if Sz - Fl^.GetPos < 4096 then L := Sz - Fl^.GetPos
                                     else L := 4096;
           Fl^.Read(PS^, L);
           XlatBuf(PS^, L, Xlat);
           S.Write(PS^, L);
         end;
       FreeMem(PS, 4096);
     end else 2: S.CopyFrom(Fl^, Fl^.GetSize);
   P^.Free;
   S.Done;
   FN := GetPath(FN); if (FN[0] > #3) and (FN[Length(FN)] = '\') then Dec(FN[0]);
   GlobalMessage(evCommand, cmRereadDir, @FN);
 end;

 procedure LoadXlatTable;
   var FN: String;
 begin
   CE; XlatFile := '';
   if UseXlat then begin UseXlat := Off; DrawView; Exit end;
   FN := GetFileNameDialog(SourceDir+'XLT\*.XLT', GetString(dlSelectXLT),
                                    GetString(dlOpenFileName),
                            fdOKButton + fdHelpButton, hsOpenXLT);
   if FN <> '' then SetXlatFile(FN);
 end;

 label 1,2,DoSave;

begin
 inherited HandleEvent(Event);
 if ViewMode <> 2 then
   begin
     HexPos := (Size.X - 12) div 4;
     if HexPos <= 0 then HexPos := 1;
   end else
   begin

     HexPos := ((Size.X - 9) div 16)*16;
     if HexPos < 16 then HexPos := 16;
   end;
 if Loaded then
  begin
   if SB <> nil then PViewScroll(SB)^.MaxV := FileSize;
   Message(SB, evCommand, cmChangeValue, Pointer(FilePos+BufPos));
   Loaded := Off;
  end;
 case Event.What of
  evBroadcast: case Event.Command of
                 cmReanimator:
DoSave:
                               if (Fl <> nil) and (Fl^.Status = stOK) then
                                 begin
                                   CE;
                                   FreeStr := GetFileNameDialog(x_x, GetString(dlSaveFileAs),
                                                                GetString(dlSaveFileAsName),
                                                                fdOKButton + fdHelpButton, hsEditSave);
                                   if FreeStr <> '' then SaveToFile(FreeStr);
                                 end;
                 cmReleaseFile: begin
                                  if UpStrg(FileName) = PString(Event.InfoPtr)^ then
                                      begin
                                        ReadFile('', On);
                                        {if not QuickView then Message(Owner, evCommand, cmClose, nil);}
                                      end;
                                end;
               end;
  evCommand: case Event.Command of
              cmGotoCell: begin
                            CE;
                            if ViewMode = 0 then Exit; FreeStr := '';
                            if ExecResource(dlgGotoAddress, FreeStr) <> cmOK then Exit;
                            Val('$'+FreeStr, LLR, I);
                            if I = 0 then
                              begin
                                LFR := LLR; LongInt(Cur) := 0;
                                while ((LFR mod HexPos) <> ((BufPos+FilePos) mod HexPos)) and (LFR > 0) do
                                  begin Dec(LFR); Inc(Cur.X,2); end;
                                Seek(LFR); MakeLines;
                                DrawView;
                              end;
                          end;
              cmLoadXlatTable: LoadXlatTable;
              cmAddFilter: begin Filter := (Filter+1) mod 3; DrawView; CE end;
              cmSave: begin WriteModify; CE end;
              cmSaveAll: Goto DoSave;
              cmGetName: if FileName <> '' then PString(Event.InfoPtr)^ := GetString(dlViewFile)+FileName;
              cmLoadViewFile: if QuickView and (FExpand(PString(Event.InfoPtr)^) <> FExpand(FileName)) then
                               begin ReadFile(PString(Event.InfoPtr)^, On);
                                     DrawView; CE end;
              cmClose, cmQuit, cmKillUsed: if WriteModify then CE else
                                 if KillAfterUse and (Event.Command <> cmQuit) then
                                    begin
                                      if Fl <> nil then
                                        begin
                                          Dispose(Fl, Done); Fl := nil;
                                          EraseFile(FileName);
                                          RereadDirectory(GetPath(FileName));
                                        end;
                                      if Event.Command = cmClose then GlobalMessage(evCommand, cmPanelReread, nil);
                                    end;
              cmSearchFor: begin StartSearch; CE end;
              cmReverseSearch,
              cmContinueSearch: begin ContinueSearch(Event.Command = cmReverseSearch); CE end;
              cmHexMode:  begin
                           case ViewMode of
                             0: begin ViewMode := 1; HexEdit := On; end;
                             1: begin ViewMode := 2; end;
                              else begin ViewMode := 0; MakeLines end;
                           end;
                           if ViewMode <> 2 then
                             begin
                               HexPos := (Size.X - 12) div 4;
                               if HexPos <= 0 then HexPos := 1;
                             end else
                             begin
                               HexPos := ((Size.X - 9) div 16)*16;
                               if HexPos < 16 then HexPos := 16;
                               MakeLines
                             end;
                           DrawView; CE
                          end;
              cmUnWrap: begin
                         Wrap := not Wrap;
                         MakeLines;
                         DrawView; CE;
                        end;
              cmScrollBarChanged: begin
                                   Seek(Event.InfoLong);
                                   if ViewMode = 0 then
                                       begin
                                        CountDown(1);
                                        CountUp(1);
                                       end;
                                   MakeLines;
                                   DrawView;
                                  end;
             end;
  evKeyDown: case Event.KeyCode of
               kbCtrlHome: if ViewMode = 1 then
                             begin
                               Cur.Y := 0;
                               DrawView; CE;
                             end else Goto 1;
               kbCtrlEnd: if ViewMode = 1 then
                             begin
                               Cur.Y := Size.Y - 1;
                               DrawView; CE;
                             end else Goto 2;
               kbESC: if not QuickView then begin Message(Application, evCommand, cmClose, nil); CE end;
               kbCtrlLeft: if ViewMode = 0 then
                     begin CE; if XDelta>19 then Dec(XDelta,20) else XDelta:=0; DrawView end
                          else
                             begin
                               if BufPos > 0 then Dec(BufPos) else
                                 if FilePos > 100 then
                                   begin
                                     Owner^.Lock;
                                     Seek(FilePos - 100);
                                     BufPos := 99;
                                     Owner^.UnLock;
                                   end;
                               DrawView; CE
                             end;

               kbCtrlRight: if ViewMode = 0 then
                          begin CE; if XDelta<255*8-Size.X-19 then Inc(XDelta,20); DrawView end
                            else
                             begin
                               if BufPos < BufSize - 1024 then Inc(BufPos) else
                                   begin
                                     Owner^.Lock;
                                     Seek(FilePos + BufPos + 1);
                                     Owner^.UnLock;
                                   end;
                               DrawView; CE
                             end;
               kbTab: begin
                         if ViewMode = 1 then
                          begin
                           if HexEdit then Cur.X := Cur.X div 2
                                      else Cur.X := Cur.X * 2;
                           HexEdit := not HexEdit;
                           DrawView;
                           CE
                          end;
                        end;
               kbCtrlPgUp: begin
1:                            SearchX := 0;
                              CE; Seek(0); LongInt(Cur) := 0; XDelta := 0; DrawView
                           end;
               kbCtrlPgDn: begin
2:                           SearchX :=  FileSize;
                             SeekEOF;
                             CE
                           end;
               kbHome: begin
                         CE; if ViewMode = 1 then Cur.X := 0
                                             else XDelta := 0;
                         DrawView
                       end;
               kbEnd: if ViewMode <> 1 then CM_END
                        else begin
                               Cur.X := HexPos*(Byte(HexEdit)+1)-1;
                               DrawView
                             end;
               kbDown: begin
                      {  if (FilePos+BufSize) >= FileSize then
                        begin with PViewScroll(SB)^ do Value :=MaxV; DrawView; end;}
                        if ViewMode <> 1 then begin CE; CountDown(1) end else
                        begin Inc(Cur.Y); DrawView; CE; end;
                       end;
               kbPgDn: begin CE; CountDown(Size.Y-1) end;
               kbUp: if ViewMode <> 1 then begin CE; CountUp(1) end else
                        begin Dec(Cur.Y); DrawView; CE; end;
               kbPgUp: begin
                          CE;
                          CountUp(Size.Y-1);
                          if BufPos=0 then
                           begin PViewScroll(SB)^.Value :=0; SB^.DrawView;end;
                       end;
               kbLeft: if ViewMode = 0 then begin CE; if XDelta>0 then Dec(XDelta); DrawView end
                        else begin
                              if Cur.X > 0 then Dec(Cur.X)
                                 else begin Cur.X := HexPos*(Byte(HexEdit)+1) - 1; Dec(Cur.Y) end;
                         {     if ViewMode = 1 then
                                 Message(Owner, evCommand, cmSetMargins, nil);}
                              DrawView; CE
                             end;
               kbRight: if ViewMode = 0 then begin CE; if XDelta<255*8-Size.X then Inc(XDelta); DrawView end
                        else begin
                              if Cur.X < HexPos*(Byte(HexEdit)+1)-1 then Inc(Cur.X)
                                         else begin Cur.X := 0; Inc(Cur.Y) end;
                       {       if ViewMode = 1 then SearchX := HexPos;}
                              DrawView; CE
                             end;
               else
                    if (Event.CharCode > #31) and not NoEdit then
                    begin
                     if (ViewMode = 1) and (Buf <> nil) and
                        (Cur.X div (Byte(HexEdit)+1)+Cur.Y*HexPos+BufPos < BufSize) then
                     begin
                      if RdOnly then begin Write(#7); CE; Exit end;
                      if HexEdit then
                       begin
                        Event.CharCode := UpCase(Event.CharCode);
                        if Event.CharCode in ['A'..'F', '0'..'9'] then
                         begin
                          BufModified := On;
                          I := PosChar(Event.CharCode, '0123456789ABCDEF')-1;
                          P.X := Cur.X div 2+Cur.Y*HexPos+BufPos;
                          if Odd(Cur.X) then Buf^[P.X] := (Buf^[P.X] and $F0) or I
                                        else Buf^[P.X] := (Buf^[P.X] and $F) or (I shl 4);
                          Message(@Self, evKeyDown, kbRight, nil);
                         end;
                       end else
                       begin
                        BufModified := On;
                        Char(Buf^[Cur.X+Cur.Y*HexPos+BufPos]) := Event.CharCode;
                        Message(@Self, evKeyDown, kbRight, nil);
                       end;
                     end;
                     CE
                    end;
             end;
  evMouseDown: begin
                LR := RepeatDelay; RepeatDelay := 0;
                repeat
                 MakeLocal(Event.Where, P);
                 if MouseInView(Event.Where) then
                  if P.X < Size.X div 4 then Message(@Self, evKeyDown, kbLeft, nil) else
                   if P.X >= (Size.X*3) div 4 then Message(@Self, evKeyDown, kbRight, nil) else
                    if P.Y < Size.Y div 2 then Message(@Self, evKeyDown, kbUp, nil) else
                     Message(@Self, evKeyDown, kbDown, nil)
                until not MouseEvent(Event, evMouseMove+evMouseAuto);
                RepeatDelay := LR; CE
               end;
 end;
end;

procedure TFileViewer.SetXlatFile;
  var Dr: PathStr;
      Nm: NameStr;
      xt: ExtStr;
      S: TDosStream;
      Table: Array [1..256] of Record A, B: Char end;
      C, CC: Char;
      I,J: Integer;
begin
  XlatFile := '';
  if aFName = '' then begin UseXLat := Off; DrawView; Exit end;
  FSplit(aFName, Dr, Nm, Xt);
  if Dr = '' then begin Dr := SourceDir+'XLT\'; Xt := '.xlt'; end;

   S.Init(Dr+Nm+Xt, stOpenRead);
   if (S.Status = stOK) and (S.GetSize >= 2) then
     begin
       for C := #0 to #255 do XLat[C] := C;
       J := Min(256, S.GetSize div 2);
       S.Read(Table, J * 2);
       for I := 1 to J do XLat[Table[I].A] := Table[I].B;
       UseXlat := S.Status = stOK;
       if UseXlat then XlatFile := Nm;
     end;
   S.Done;
   DrawView;
end;

procedure TFileViewer.CountDown;
begin
 if Buf = nil then Exit;
 if (Lines[Size.Y-1].Pos < 0) and (ViewMode = 0) or
    (FilePos + LongInt(BufPos) + LongInt(HexPos)*LongInt(Size.Y) > FileSize) and
    (ViewMode > 0) then Exit;
 if ViewMode > 0 then
  begin
   while (BufPos + HexPos < BufSize) and (ANumber > 0) do
    begin Inc(BufPos, HexPos); Dec(ANumber) end;
   if BufPos + HexPos*Size.Y > BufSize then
     Seek(FilePos+LongInt(BufPos));
   while (ANumber > 0) do begin Inc(BufPos, HexPos); Dec(ANumber) end;
   DrawView;
   Message(SB, evCommand, cmChangeValue, Pointer(FilePos+BufPos));
   Exit;
  end;
 repeat
  BufPos := Lines[ANumber].Pos;
  Dec(ANumber);
 until (ANumber = 0) or (BufPos >= 0);
 if ANumber+Size.Y+1 < MaxLines then
  begin
   Move(Lines[ANumber+1], Lines[0], sizeof(Lines[0])*(MaxLines-ANumber-1));
   Dec(MaxLines, ANumber+1);
  end else MakeLines;
 if (Lines[Size.Y-1].Pos = - 1) and (FilePos+BufSize < FileSize) then
    Seek(FilePos+Lines[0].Pos);
 DrawView;
 Message(SB, evCommand, cmChangeValue, Pointer(FilePos+BufPos));
end;

procedure TFileViewer.CountUp;
 var I, J: LongInt;

     FP: LongInt;
     OBP: Word;

 procedure ScrollUp;
  var I: Word;
      P: Pointer;
      MaxX: Integer;
 begin
  if J <= 0 then Exit;
  I := J; P := Buf;
  if Wrap then MaxX := Size.X - 1 else MaxX := 254;
  asm
   les di, P
   add di, word ptr I
   mov cx, MaxX
   mov al, 13
   mov bl, 10
   sub di, 1
   sub word ptr I, 1
   js  @Exit
   mov ah, es:[di]
   sub di, 1
   sub word ptr I, 1
   js  @Exit
   cmp ah, 10
   je  @@@
   cmp ah, 13
   jne @@2
@@@:
   cmp es:[di], ah
   je  @Exit
   jmp @@2
@@1:
   mov ah, es:[di]
   cmp ah, al
   jz  @Exit
   cmp ah, bl
   jz  @Exit
@@2:
   dec di
   dec word ptr I
   js  @Exit
   loop @@1
@Exit:

  end;
  J := I + 1;
 end;

 label 1;

var
  a : Word;

begin
 if Buf = nil then Exit;
 if BufPos > 65000 then begin BufPos := 0; MakeLines; end;
1:
 J := BufPos; if (J < 0) and (FilePos <= 0) then Exit;
 for I := 1 to ANumber do
 begin
  if ViewMode = 0 then ScrollUp else Dec(J, HexPos);
  if J <= 0 then if FilePos = 0 then
                  begin
                   if BufPos > 0 then begin BufPos := 0; MakeLines end;
                   BufPos := 0; DrawView; Exit
                  end
                 else
                  begin
                   FP := FilePos;
                   I := BufSize div 2;
                   if FilePos+BufPos < I then begin I := FP; FP := 0; end
                                         else FP := FP - I;
                   BufPos := BufPos + I;
                   OBP := BufPos;
                   FL^.Seek(FP);
                   Fl^.Read(Buf^, BufSize);
                   BufPos := OBP;
                   FilePos := FP;
                   MakeLines;
                   Goto 1;
                  end
           else BufPos := J;
  System.Move(Lines[0], Lines[1], (MaxLines - 1) * sizeof(Lines[0]));
  Lines[0].Pos := J;
  a := 0;
  while (j+a<Lines[1].Pos) and not (Buf^[J+A] in [13, 10]) do Inc(a);
  if a > $FF then
  asm
   nop
  end;
  Lines[0].Len := a;
  if MaxLines < 200 then Inc(MaxLines);
 end;
 if Wrap then MakeLines;
 DrawView;
 Message(SB, evCommand, cmChangeValue, Pointer(FilePos+BufPos));
end;

function TFileViewer.Valid;
begin
  Valid := IsValid or QuickView;
  if (Command = cmClose) or (Command = cmQuit) then
    begin
     if (Owner <> nil) and (not QuickView) and not KillAfterUse then
      begin
        StoreViewInfo(Owner);
      end;
    end;

end;

{ TFileWindow }
constructor TFileWindow.Init;
var

  R: TRect;
  P: PView;
  PV: PFileViewer;
begin
  if LastViewerBounds.Empty or (InterfaceData.Options and ouiStoreViewerPosition = 0)
    then begin Desktop^.GetExtent(LastViewerBounds); LastViewerDeskSize := Desktop^.Size; end;
  R := LastViewerBounds; AdjustToDesktopSize(R, LastViewerDeskSize);
  TWindow.Init(R, Filename, 0);
  Options := Options or ofTileable;
  GetExtent(R);
  R.Grow(-1, -1);
  R.A.X := R.B.X; Inc(R.B.X);
  P := New(PViewScroll, Init(R)); P^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
  Insert(P);
  GetExtent(R);
  R.Grow(-1, -1);
  PV := New(PFileViewer, Init(R, nil, Filename, P, False, Hex));
  Insert(PV);
  GetExtent(R);
  Inc(R.A.X); R.A.Y := R.B.Y - 1; R.B.X := R.A.X + 8;
  P := New(PViewInfo, Init(R, PV));
  Insert(P);
  PV^.Info := P;
end;

procedure TFileWindow.ChangeBounds;
begin
  inherited ChangeBounds(Bounds);
  if not GetState(sfModal) then
    begin
       GetBounds(LastViewerBounds);
       LastViewerDeskSize := Desktop^.Size;
    end;
end;

function TFileWindow.ReactOnCmd; begin ReactOnCmd := On end;

end.

