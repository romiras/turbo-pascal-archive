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

{$F+}

unit Terminal;

interface

uses Objects, Views, Scroller, Drivers, Dos, Memory, Menus, Messages,
     Advance, Commands, DNApp, OOCOM, DNStdDlg, apPort, DNHelp,
     OOZModem, OOXModem, OOYModem, OOKermit, OOAbsPcl, Dialogs, xTime,
     ObjType;

type
    PTerminalWindow = ^TTerminalWindow;
    TTerminalWindow = object(TWindow)
      Zooming: Boolean;
      constructor Init;
      procedure Zoom; virtual;
      procedure SizeLimits(var Min, Max: TPoint); virtual;
      procedure CalcBounds(var Bounds: TRect; Delta: TPoint); virtual;
    function  ReactOnCmd: Boolean; virtual;
    end;

    PTerminal = ^TTerminal;
    TTerminal = object(TScroller)
     Buffer: PWordArray;
     CurPos, SavePos: TPoint;
     BufSize: TPoint;
     isValid, ScrollBack: Boolean;
     OutAttr: Byte;
     Log: PStream;
     Emulator: Word;
     TOptions: Word;
     ANSIParams: Array[1..128] of Integer;
     TabStops: Array[0..200] of Boolean;
     ParamCount: Integer;
     TextAttr: Byte;
     Inverse, Intense: Boolean;
     MaskBlinkOnInverse: Boolean;
     TextFg, TextBk: Byte;
     CutRect, OldCutRect: TRect;
     ScrollTop, ScrollBot: Byte;
     UpdTimer: TEventTimer;
     constructor Init(var R: TRect; AHScroll, AVScroll: PScrollBar);
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     procedure Draw; virtual;
     procedure HandleEvent(var Event: TEvent); virtual;
     procedure PutChar(C: Char);
     procedure ZModemDload;
     procedure Update; virtual;
     function Valid(Command: Word): Boolean; virtual;
     procedure ChangeBounds(var Bounds: TRect); virtual;
     procedure SendModem(const S: String);
     procedure ScrollUp(N: Byte);
     procedure ChangeBufSize(NX, NY: Integer);
     destructor Done; virtual;
    end;

    PPortInfo = ^TPortInfo;
    TPortInfo = object(TView)
     BBB: Byte;
     constructor Init(var R: TRect);
     procedure HandleEvent(var Event: TEvent); virtual;
     procedure Draw; virtual;
    end;

const Term: PTerminal = nil;
      ModemActive: Boolean = False;

const
     ANSIStr: String = '';
     AvatarStr: String = '';
     LastCommand: String[80] = '';

      RTerminalWindow: TStreamRec = (
       ObjType: otTerminalWindow;
       VmtLink: Ofs(TypeOf(TTerminalWindow)^);
       Load: @TTerminalWindow.Load;
       Store: @TTerminalWindow.Store);

      RTerminal: TStreamRec = (
       ObjType: otTerminal;
       VmtLink: Ofs(TypeOf(TTerminal)^);
       Load: @TTerminal.Load;
       Store: @TTerminal.Store);

      RPortInfo: TStreamRec = (
       ObjType: otPortInfo;
       VmtLink: Ofs(TypeOf(TPortInfo)^);
       Load: @TPortInfo.Load;
       Store: @TPortInfo.Store);

const {COMPort:  AbstractPortPtr = nil;
      Modem:    AbstractModemPtr = nil;}
      Protocol: AbstractProtocolPtr = nil;
      CommandsHistory: PCollection = nil;

{function InitModem: Boolean;}

implementation

uses Phones, RStrings, Startup, Microed, Gauge, ScrollBk,
     WinClp, ModemIO, FileCopy;


{function InitModem;
begin
 InitModem := True;
 if COMPort <> nil then Exit;
 COMPort := New(UARTPortPtr, InitFast(COM4, 1200));
 if COMPort = nil then begin InitModem := False; Exit; end;
 Modem := New(HayesModemPtr, Init(COMPort));
 Modem^.SetDialPulse;
end;}

constructor TPortInfo.Init;
begin
 inherited Init(R);
 if COMPort <> nil then BBB := COMPort^.GetModemStatus;
 EventMask := evBroadcast;
end;

procedure TPortInfo.HandleEvent;
begin
 inherited HandleEvent(Event);
 if (Event.What = evBroadcast) and (Event.Command = cmOK) then
  begin BBB := BBB xor Event.InfoByte; DrawView; end;
end;

procedure TPortInfo.Draw;
 var B: TDrawBuffer;
     Baud: LongInt;
     Parity: ParityType;
     DataBits: DataBitType;
     StopBits: StopBitType;
     DTR, RTS: Boolean;
     S: String[80];
begin
 MoveChar(B, ' ', $70, Size.X);
 if COMPort <> nil then
  begin
   COMPort^.GetLine(Baud, Parity, DataBits, StopBits, Off);
   S := SStr(DataBits,4,' ')+N_O_E_M_S[Byte(Parity)+1]+Char(48+StopBits)+'~   ';
   COMPort^.GetModem(DTR, RTS);
   BBB := COMPort^.GetModemStatus;
   if BBB and DCDMask <> 0 then S := S + ' CD' else S := S + ' ~CD~';
   if BBB and DSRMask <> 0 then S := S + ' DSR' else S := S + ' ~DSR~';
   if BBB and CTSMask <> 0 then S := S + ' CTS' else S := S + ' ~CTS~';
   if DTR then S := S + ' DTR' else S := S + ' ~DTR~';
   if RTS then S := S + ' RTS' else S := S + ' ~RTS~';
   MoveCStr(B, '~'+ItoS(Baud) + S, $787F);
  end;
 WriteLine(0,0,Size.X, Size.Y, B);
end;

constructor TTerminalWindow.Init;
 var R: TRect;
     P: PView;
     PT: PTerminal;
begin
 if InitModem = moInitFail then Fail;
 Desktop^.GetExtent(R); R.Grow(1,1);
 HelpCtx := hcTerminal;
 inherited Init(R, GetString(dlTerminalTitle), 0);

 GetExtent(R);
 R.Grow(-1,-1); Dec(R.B.Y);
 PT := New(PTerminal, Init(R, StandardScrollBar(sbHorizontal + sbHandleKeyBoard),
                               StandardScrollBar(sbVertical + sbHandleKeyBoard)));
 Insert(PT);
 GetExtent(R);
 R.Grow(-1,-1); R.A.Y := R.B.Y - 1;
 P := New(PPortInfo, Init(R));
 P^.GrowMode := gfGrowHiX+gfGrowLoY+gfGrowHiY;
 Insert(P);
end;

procedure TTerminalWindow.Zoom;
var
  R: TRect;
  Max, Min: TPoint;
begin
  Zooming := True;
  SizeLimits(Min, Max);
  if Longint(Size) <> Longint(Max) then
  begin
    GetBounds(ZoomRect);
    Longint(R.A) := 0;  Dec(R.A.X); Dec(R.A.Y);
    R.B := Max;         Inc(R.B.X);
    Locate(R);
  end else Locate(ZoomRect);
  Zooming := False;
end;

procedure TTerminalWindow.SizeLimits(var Min, Max: TPoint);
begin
   Longint(Min) := 0;
   Min := MinWinSize;
   if Owner <> nil then
        begin
           Max.X := Owner^.Size.X+2;
           Max.Y := Owner^.Size.Y+2;
        end else Longint(Max) := $7FFF7FFF;
end;

procedure TTerminalWindow.CalcBounds;
  var OldSz: TPoint;
begin
  OldSz := Size;
  inherited CalcBounds(Bounds, Delta);
  Bounds.B.X := Bounds.A.X + OldSz.X+Delta.X;
  Bounds.B.Y := Bounds.A.Y + OldSz.Y+Delta.Y;
end;

function TTerminalWindow.ReactOnCmd; begin ReactOnCmd := On end;

constructor TTerminal.Init;
 var I: Integer;
begin
 inherited Init(R, AHScroll, AVScroll);
 BufSize.X := ScreenWidth; BufSize.Y := ScreenHeight;
 ScrollTop := 0; ScrollBot := BufSize.Y-1;
 LongInt(CurPos) := 0;
 Emulator := TerminalDefaults.Emulation;
 TOptions := TerminalDefaults.Options;
 Buffer := MemAlloc(BufSize.X*BufSize.Y*2);
 for I := 0 to BufSize.X*BufSize.Y-1 do Buffer^[I] := $0700;
 SetLimit(BufSize.X, BufSize.Y);
 GrowMode := gfGrowHiX+gfGrowHiY;
 CutRect.Assign(0,0,0,0);
 OldCutRect.Assign(10,5,15,6);
 ANSIStr := '';
 AvatarStr := '';
 ParamCount := 0;
 Term := @Self;
 isValid := True;
 ScrollBack := Off;
 OutAttr := $07;
 HelpCtx := hcTerminal;
 for I := 0 to 200 do TabStops[I] := I mod 8 = 0;
 RegisterToPrior(@Self);
end;

constructor TTerminal.Load;
 var I,J: Word;
     RR: TRect;
begin
 inherited Load(S);
 Log := nil;
 S.Read(OutAttr, SizeOf(OutAttr));
 S.Read(ScrollTop, 2*SizeOf(Byte));
 S.Read(CurPos, 3*Sizeof(TPoint)+SizeOf(Boolean));
 Buffer := MemAlloc(BufSize.X*BufSize.Y*2);
 isValid := (Buffer <> nil){ and (InitModem <> moInitFail)};
 if Buffer <> nil then S.Read(Buffer^,BufSize.X*BufSize.Y*2)
                  else for I := 1 to BufSize.X*BufSize.Y do S.Read(J, 2);
 Term := @Self;
 ParamCount := 0;
 ANSIStr := '';
 AvatarStr := '';
 GetBounds(RR); ChangeBounds(RR);
 isValid := isValid and (InitModem <> moInitFail) and (COMPort <> nil);
 if Dialer <> nil then Deregister(Dialer);
 RegisterToPrior(@Self);
 if Dialer <> nil then RegisterToPrior(Dialer);
end;

destructor TTerminal.Done;
begin
 if Buffer <> nil then FreeMem(Buffer, BufSize.X*BufSize.Y*2);
 if Log <> nil then Dispose(Log, Done);
 Term := nil;
 inherited Done;
end;

procedure TTerminal.Store;
 var I,J: Word;
begin
 inherited Store(S);
 S.Write(OutAttr, SizeOf(OutAttr));
 S.Write(ScrollTop, 2*SizeOf(Byte));
 S.Write(CurPos, 3*Sizeof(TPoint)+SizeOf(Boolean));
 S.Write(Buffer^,BufSize.X*BufSize.Y*2);
end;

function TTerminal.Valid;
begin
 Valid := inherited Valid(Command) and isValid;
 if ((Command = cmClose) or (Command = cmQuit)) and (Protocol <> nil) then Valid := False;
end;

procedure TTerminal.Draw;
 var I,J,K: Integer;
     B: Array[0..200] of Word;
     Blk,BlkM: Boolean;
begin
 Blk := CutRect.A.X <> CutRect.B.X;
 if Blk then
   with CutRect do
   begin
     BlkM := Off;
     if A.X < 0 then CutRect.Move(-A.X,0);
     if A.Y < 0 then CutRect.Move(0,-A.Y);
     if B.X - A.X > Size.X then B.X := A.X + Size.X;
     if B.Y - A.Y > Size.Y then B.Y := A.Y + Size.Y;
     if B.X > BufSize.X then CutRect.Move(BufSize.X-B.X, 0);
     if B.Y > BufSize.Y then CutRect.Move(0, BufSize.Y-B.Y);
     if A.X < Delta.X then
       begin Delta.X := A.X; BlkM := On; end;
     if CutRect.A.Y < Delta.Y then
       begin Delta.Y := A.Y; BlkM := On; end;
     if B.X - Delta.X > Size.X then
       begin Delta.X := B.X - Size.X; BlkM := On; end;
     if B.Y - Delta.Y > Size.Y then
       begin Delta.Y := B.Y - Size.Y; BlkM := On; end;
     if BlkM then ScrollTo(Delta.X, Delta.Y);
   end;
 for I := 0 to Size.Y - 1 do
  begin
   MoveChar(B, ' ', $07, 200);
   if Delta.Y + I < BufSize.Y then Move(Buffer^[(I+Delta.Y) * BufSize.X], B, BufSize.X * 2);
   if Blk and (I+Delta.Y >= CutRect.A.Y) and (I+Delta.Y < CutRect.B.Y) then
     begin
       J := CutRect.A.X;
       K := CutRect.B.X - J;
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
   WriteLine(0, I, Size.X, 1, B[Delta.X]);
  end;
 ShowCursor; NormalCursor;
 SetCursor(CurPos.X - Delta.X, CurPos.Y - Delta.Y);
end;

 const XferAborted :Boolean = False;
       Info: PWhileView = nil;
       InProc: Boolean = Off;

 var
       XChkTimer: TEventTimer;

 function AbortXfer: Boolean; far;
  var Event: TEvent;
 begin
  if (Info = nil) or (COMPort = nil) then begin AbortXfer := On; Exit end;
  if TimerExpired(XChkTimer) then
    begin
      XferAborted := not COMPort^.CheckDCD and
                   (TerminalDefaults.Options and toCheckDCD <> 0);
      NewTimer(XChkTimer, 18*2);
    end;
  if not InProc then
   begin
    InProc := On;
    Application^.GetEvent(Event);
    if Event.What <> evNothing then
     begin
      Application^.HandleEvent(Event);
      if (Event.What = evCommand) and (Event.Command = cmCancel)
         and (Event.InfoPtr = Info^.But) then XferAborted := On;
     end;
    end;
  InProc := Off;
  AbortXfer := XferAborted;
 end;

 procedure ShowReceInfo(AP : AbstractProtocolPtr; Starting, Ending : Boolean); far;
  var Event: TEvent;
      I, J, K: LongInt;
 begin
  Info^.Write(1, GetString(dlTermProtocol)+ProtocolTypeString[AP^.GetProtocol]);
  Info^.Write(3, GetString(dlTermProtocolFile) +AP^.GetFileName);
  I := AP^.GetBytesTransferred; J := AP^.GetFileSize;
  Info^.Write(4, GetString(dlTermProtocolRece) + FStr(I) + ' of ' + FStr(J));
  if J = 0 then J := 1; K := Info^.Size.X - 4;
  Info^.Write(5, Copy(Strg(#219, (K * I) div J)+Strg(#177, K),1,K));
  K := AP^.GetElapsedTics;
  if K > 0 then K := (I*18) div K else K := 0;
  Info^.Write(6, GetString(dlTermProtocolErrors) + ItoS(AP^.GetTotalErrors) + ',  CPS : '+ItoS(K));
  I := AP^.EstimateTransferSecs(J-I); J := I mod 3600;
  Info^.Bottom := SStr(J div 60,2,'0')+':'+SStr(J mod 60,2,'0');
  if I > J then Info^.Bottom := ItoS(I div 3600) + ':'+Info^.Bottom;
  Info^.Bottom := GetString(dlTermProtocolEstimate) + Info^.Bottom;
  Info^.DrawView;
  repeat
   Application^.GetEvent(Event);
   if Event.What <> evNothing then Application^.HandleEvent(Event) else Exit;
  until False;
 end;

 procedure ShowSendInfo(AP : AbstractProtocolPtr; Starting, Ending : Boolean); far;
  var Event: TEvent;
      I, J, K: LongInt;
 begin
  Info^.Write(1, GetString(dlTermProtocol)+ProtocolTypeString[AP^.GetProtocol]);
  Info^.Write(3, GetString(dlTermProtocolFile)+AP^.GetFileName);
  I := AP^.GetBytesTransferred; J := AP^.GetFileSize;
  Info^.Write(4, GetString(dlTermProtocolSent) + FStr(I) + ' of ' + FStr(J));
  if J = 0 then J := 1; K := Info^.Size.X - 4;
  Info^.Write(5, Copy(Strg(#219, (K * I) div J)+Strg(#177, K),1,K));
  K := AP^.GetElapsedTics;
  if K > 0 then K := (I*18) div K else K := 0;
  Info^.Write(6, GetString(dlTermProtocolErrors) + ItoS(AP^.GetTotalErrors) + ',  CPS : '+ItoS(K));
  I := AP^.EstimateTransferSecs(J-I); J := I mod 3600;
  Info^.Bottom := SStr(J div 60,2,'0')+':'+SStr(J mod 60,2,'0');
  if I > J then Info^.Bottom := ItoS(I div 3600) + ':'+Info^.Bottom;
  Info^.Bottom := GetString(dlTermProtocolEstimate) + Info^.Bottom;
  Info^.DrawView;
  repeat
   Application^.GetEvent(Event);
   if Event.What <> evNothing then Application^.HandleEvent(Event) else Exit;
  until False;
 end;

procedure TTerminal.HandleEvent;

 procedure SetProtocol;
  var P: PMenuBox;
      M: PMenu;
      R: TRect;
      W: Word;
 begin
  if COMPort = nil then Exit;
  M := NewMenu(
               NewItem('~Z~modem','', kbNoKey, 1006, hcNoContext,
               NewItem('~Y~modem (batch)','', kbNoKey, 1004, hcNoContext,
               NewItem('Y~m~odem-g','', kbNoKey, 1005, hcNoContext,
               NewItem('~X~modem','', kbNoKey, 1001, hcNoContext,
               NewItem('Xmodem-~1~K blocks','', kbNoKey, 1002, hcNoContext,
               NewItem('Xmodem-~g~','', kbNoKey, 1003, hcNoContext,
               NewItem('~K~ermit','', kbNoKey, 1007, hcNoContext,
               nil))))))));
  R.Assign(1,1,20,4);
  P := New(PMenuBox, Init(R, M, nil));
  P^.Options := P^.Options or ofCentered;
  W := Application^.ExecView(P);
  Dispose(P);
  DisposeMenu(M);
  if W < 1000 then Exit;
  case W of
   1001: Protocol := New(XModemProtocolPtr, Init(COMPort, Off, Off));
   1002: Protocol := New(XModemProtocolPtr, Init(COMPort, On, Off));
   1003: Protocol := New(XModemProtocolPtr, Init(COMPort, Off, On));
   1004: Protocol := New(YModemProtocolPtr, Init(COMPort, On, Off));
   1005: Protocol := New(YModemProtocolPtr, Init(COMPort, On, On));
   1006: begin
          Protocol := New(ZModemProtocolPtr, Init(COMPort));
          ZModemProtocolPtr(Protocol)^.SetRecoverOption(On);
         end;
   1007: Protocol := New(KermitProtocolPtr, Init(COMPort));
  end;
 end;

 var R: TRect;
     P: Pointer;
     S: String;

 procedure Rece;
  var Dr: PathStr;
      Nm, Xt: NameStr;
      II: PView;
      PA: AbortFunc;
      Timer: TEventTimer;
 begin
   DefProtocolOptions := DefProtocolOptions or apRTSLowForWrite;
   if Protocol <> nil then Exit;
   SetProtocol;
   if Protocol = nil then Exit;
   if (TypeOf(Protocol^) = TypeOf(XModemProtocol)) or
      (TypeOf(Protocol^) = TypeOf(KermitProtocol)) then
    begin
      S := GetFileNameDialog(x_x, GetString(dlTermReceXmodem), GetString(dlFileName),
                          fdOKButton + fdHelpButton, 100);
     if S = '' then begin Dispose(Protocol, Done); Protocol := nil; Exit; end;
     FSplit(FExpand(S), Dr, Nm, Xt);
     Protocol^.SetDestinationDirectory(Dr);
     Protocol^.SetReceiveFileName(Nm+Xt);

    end else
      if TypeOf(Protocol^) = TypeOf(ZModemProtocol) then
           ZModemProtocolPtr(Protocol)^.SetFileMgmtOptions(On, Off, WriteCrc);
   R.Assign(1,1,40,13);
   Info := New(PWhileView, Init(R));
   Info^.Top := GetString(dlTermReceiving);
   Info^.Options := Info^.Options or ofSelectable;
   Info^.Write(3, GetString(dlTermWaitAnswer));
   Desktop^.Insert(Info);
   NewTimer(XChkTimer, 18*2);
   XferAborted := Off;
   PA := COMPort^.PR^.UserAbort;
   COMPort^.SetAbortFunc(AbortXfer);
   Protocol^.SetShowStatusProc(ShowReceInfo);
   Protocol^.SetDestinationDirectory(ModemSetup.Download);
   Inc(SkyEnabled);
   NewTimer(Timer, 0);
   Protocol^.ProtocolReceive;
   XferAborted := Off;
   Dispose(Protocol, Done);
   II := Info;
   Info := nil;
   II^.Free;
   Protocol := nil;
   COMPort^.SetAbortFunc(PA);
   Event.What := evCommand;
   Event.Command := cmValid;
   PutEvent(Event);
   Dec(SkyEnabled);
   if (FMSetup.Options and fmoBeep <> 0) and
      (ElapsedTimeInSecs(Timer) > 30) then BeepAfterCopy;
 end;

 procedure Send;
  var II: PView;
      PA: AbortFunc;
      Timer: TEventTimer;
 begin
   if Protocol <> nil then Exit;
    S := GetFileNameDialog(x_x, GetString(dlTermSendFile), GetString(dlFileName),
                        fdOKButton + fdHelpButton, 100);
   if S = '' then Exit;
   SetProtocol;
   if Protocol = nil then Exit;
   Protocol^.SetFileMask(FExpand(S));
   R.Assign(1,1,40,13);
   Info := New(PWhileView, Init(R));
   Info^.Options := Info^.Options or ofSelectable;
   Info^.Top := GetString(dlTermSending);
   Info^.Write(3, GetString(dlTermWaitAnswer));
   Desktop^.Insert(Info);
   XferAborted := Off;
   NewTimer(XChkTimer, 18*2);
   Inc(SkyEnabled);
   PA := COMPort^.PR^.UserAbort;
   COMPort^.SetAbortFunc(AbortXfer);
   Protocol^.SetShowStatusProc(ShowSendInfo);
   NewTimer(Timer, 0);
   Protocol^.ProtocolTransmit;
   II := Info;
   Info := nil;
   II^.Free;
   Dispose(Protocol, Done);
   XferAborted := Off;
   Protocol := nil;
   COMPort^.SetAbortFunc(PA);
   Event.What := evCommand;
   Event.Command := cmValid;
   PutEvent(Event);
   Dec(SkyEnabled);
   if (FMSetup.Options and fmoBeep <> 0) and
       (ElapsedTimeInSecs(Timer) > 30) then BeepAfterCopy;
 end;

 procedure SendChar(C: Char);
 begin
   if ModemActive then Exit;
   if COMPort <> nil then COMPort^.PutChar(C);
   if TOptions and toLocalEcho <> 0 then PutChar(C);
   ClearEvent(Event);
 end;

 procedure SendString(const S: String);
   var I: Integer;
 begin
   for I := 1 to Length(S) do SendChar(S[I]);
 end;

 procedure SendFile;
  var S: String;
      B: TBufStream;
      I,J: Integer;
      C: Char;
 begin
  if ModemActive then Exit;
  S := GetFileNameDialog(x_x, GetString(dlTermWriteFile), GetString(dlFileName),
                          fdOKButton + fdHelpButton, 100);
  B.Init(S, stOpenRead, 1024);
  while B.Status = stOK do
   begin
    I := 20; if B.GetPos + I > B.GetSize then I := B.GetSize - B.GetPos;
    if I = 0 then Break;
    B.Read(S[1], I);
    for J := 1 to I do {SendChar(S[J]);}PutChar(S[J]);
    GetEvent(Event);
    if GetState(sfActive) and (Event.What = evKeyDown) and (Event.KeyCode = kbESC) then Break
       else Application^.HandleEvent(Event);
   end;
  B.Done;
 end;

 procedure SetLog;
  var S: String;
 begin
  S := GetFileNameDialog(x_x, GetString(dlTermSetLog), GetString(dlFileName),
                          fdOKButton + fdHelpButton, 100);
  if Log <> nil then Dispose(Log, Done);
  Log := New(PBufStream, Init(S, stOpen, 1024));
  if Log = nil then Exit;
  if Log^.Status <> stOK then
   begin
    Dispose(Log, Done);
    Log := New(PBufStream, Init(S, stCreate, 1024));
    if Log^.Status <> stOK then begin Dispose(Log, Done); Log := nil; end;
   end else Log^.Seek(Log^.GetSize);
 end;

 procedure CE; begin ClearEvent(Event); end;

 procedure Setup;
 begin
   ExecResource(dlgSetupTerminal, Emulator);
   CE
 end;

 procedure CmdHistory;
  var PC: PLineCollection;
      D: PDialog;
      P: PView;
      R: TRect;
      I: Integer;
      DT: Record PC: PCollection; I: Integer; end;
      S: String;
 begin
  R.Assign(1,1,60,18);
  New(D, Init(R, GetString(dlTermCommandsHistory)));
  D^.Options := D^.Options or ofCentered;

  R.Assign(56, 2, 57, 13);
  P := New(PScrollBar, Init(R));
  D^.Insert(P);

  R.Assign(2,2,56,13);
  P := New(PListBox, Init(R, 1, PScrollBar(P)));
  New(PC, Init(10,10));
  if CommandsHistory <> nil then
    for I := 0 to CommandsHistory^.Count - 1 do
       PC^.Insert(NewStr(PString(CommandsHistory^.At(I))^));
  PListBox(P)^.NewList(PC);
  if CommandsHistory <> nil then
  if CommandsHistory^.Count > 0 then PListBox(P)^.FocusItem(CommandsHistory^.Count);
  D^.Insert(P);

  R.Assign(10, 14, 20, 16);
  P := New(PButton, Init(R, GetString(dlOKButton), cmOK, bfDefault));
  D^.Insert(P);

  R.Assign(20, 14, 30, 16);
  P := New(PButton, Init(R, GetString(dlDropButton), cmYes, 0));
  D^.Insert(P);

  R.Assign(30, 14, 40, 16);
  P := New(PButton, Init(R, GetString(dlKillButton), cmNo, 0));
  D^.Insert(P);

  R.Assign(40, 14, 50, 16);
  P := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, 0));
  D^.Insert(P);

  D^.SelectNext(False);
  I := Desktop^.ExecView(D);
  D^.GetData(DT);
  Dispose(D, Done);
  Dispose(PC, Done);
  if I = cmCancel then Exit;
  if I = cmNo then begin CommandsHistory^.FreeAll; Exit end;

  S := CnvString(CommandsHistory^.At(DT.I));
  if I = cmOK then S := S + #13;
  SendString(S);
 end;

 procedure CaptureScreen;
  var W: Word;
      R: TRect;
      S: String;
  label Rep;

   function GetTextLine(N: Integer): String;
     var I: Integer;
   begin
     FillChar(S[1],CutRect.B.X - CutRect.A.X, 32);
     S[0] := Char(CutRect.B.X - CutRect.A.X);
     for I := 1 to CutRect.B.X - CutRect.A.X do
       S[I] := Char(WordRec(Buffer^[N*BufSize.X+I-1+CutRect.A.X]).Lo);
   end;

 begin
  CutRect := OldCutRect;
Rep:
  repeat
   DrawView;
   KeyEvent(Event);
   case Event.KeyCode of
    kbLeft: if ShiftState and 3 = 0 then CutRect.Move(-1,0)
               else if CutRect.B.X > CutRect.A.X + 1 then Dec(CutRect.B.X);
    kbRight:if ShiftState and 3 = 0 then CutRect.Move(1,0)
               else if CutRect.B.X - CutRect.A.X < Size.X then Inc(CutRect.B.X);
    kbUp: if ShiftState and 3 = 0 then CutRect.Move(0,-1)
               else if CutRect.B.Y > CutRect.A.Y + 1 then Dec(CutRect.B.Y);
    kbDown:if ShiftState and 3 = 0 then CutRect.Move(0,1)
               else if CutRect.B.Y - CutRect.A.Y < Size.Y then Inc(CutRect.B.Y);
   end;
  until (Event.KeyCode = kbEnter) or (Event.KeyCode = kbEsc);
  if Event.KeyCode = kbEnter then
   begin
     R.A.X := CutRect.A.X - Delta.X;
     R.A.Y := CutRect.A.Y - Delta.Y;
     MakeGlobal(R.A, R.A);
     W := Application^.ExecView(New(PMenuBox, Init(R,
              NewMenu(
                 NewItem(GetString(dlTermCopy_H_istory), '', kbNoKey, 1000, hcNoContext,
                 NewItem(GetString(dlTermCopy_C_lipboard), '', kbNoKey, 1001, hcNoContext,
                     nil))),
              nil)));
     if W < 1000 then Goto Rep;
     case W of
       1000: begin
               for W := CutRect.A.Y to CutRect.B.Y - 1 do
                begin
                  GetTextLine(W);
                  while S[Length(S)] in [#0,' '] do Dec(S[0]);
                  if S <> '' then
                    begin
                      if CommandsHistory = nil then
                        CommandsHistory := New(PLineCollection, Init(10,10));
                      CommandsHistory^.Insert(NewStr(S));
                    end;
                end;
             end;
       1001: begin
               if Clipboard <> nil then Dispose(Clipboard, Done);
               Clipboard := New(PLineCollection, Init(CutRect.B.Y-CutRect.A.Y, 10));
               for W := CutRect.A.Y to CutRect.B.Y - 1 do
                begin
                  GetTextLine(W);
                  Replace(#0, ' ', S);
                  Clipboard^.Insert(NewStr(S));
                end;
               if SystemData.Options and ossUseSysClip <> 0 then SyncClipIn;
             end;
     end;
   end;
  CutRect.Assign(0,0,0,0);
  DrawView;
 end;

 procedure ScrollBackBuf;
   var R: TRect;
 begin
   Owner^.GetBounds(R);
   Desktop^.Insert(New(PScrollBackWindow, Init(R)));
   ClearEvent(Event);
 end;


 var Ch: Char;
     I: Integer;

begin
 inherited HandleEvent(Event);
 case Event.What of
  evBroadcast: case Event.Command of
                 cmSendTerminalString: begin
                                        SendString(PString(Event.InfoPtr)^);
                                        CE;
                                       end;
               end;
  evCommand: case Event.Command of
              cmScrollBack: begin
                              ScrollBackBuf;
                              CE
                            end;
              cmSave: begin CaptureScreen; CE; end;
              cmOpen: begin
                       if SystemData.Options and ossUseSysClip <> 0 then SyncClipOut;
                       if Clipboard <> nil then begin
                          for I := 0 to Clipboard^.Count - 1 do begin
                            SendString(CnvString(Clipboard^.At(I)));
                            if I < Clipboard^.Count - 1 then SendString(#13#10);
                          end;
                        end;
                      end;
              cmHistoryList: begin CmdHistory; CE; end;
              cmShowMemo: Setup;
              cmSendModemBreak: begin if COMPort <> nil then COMPort^.SendBreak; CE end;
              cmSendInitModem: begin
                                  if COMPort <> nil then
                                  begin
                                    COMPort^.FlushInBuffer;
                                    COMPort^.FlushOutBuffer;
                                    COMPort^.SetDTR(Off);
                                    COMPort^.SetDTR(On);
                                    COMPort^.SetDTR(Off);
                                    COMPort^.SetDTR(On);
                                    ModemWrite(ModemSetup.Escape+#13#10);
                                    ModemWrite(ModemSetup.Init);
                                  end;
                                  Owner^.Redraw;
                                  CE
                               end;
              cmClose, cmQuit: if Protocol <> nil then CE;
              cmGetName: PString(Event.InfoPtr)^ := GetString(dlTerminalTitle);
              cmTermWrite: begin SendFile; CE end;
              cmReceiveFile: begin Rece; CE; end;
              cmSendFile: begin Send; CE; end;
              cmTermLog: begin SetLog; CE; end;
              cmTermVisible: begin TOptions := TOptions xor toLocalEcho; CE end;
             end;
  evKeyDown: begin
              {if ShiftState and kbScrollState <> 0 then
               begin SendChar(Event.CharCode); SendChar(Char(Event.ScanCode)); CE end;}
              case Event.KeyCode of
               kbLeft: if ShiftState and 3 = 0 then
                        begin
                          if (Emulator = emANSI) or (Emulator = emANSIBBS) then
                           begin SendString(^['[D'); end;
                          CE
                        end;
               kbRight: if ShiftState and 3 = 0 then
                        begin
                          if (Emulator = emANSI) or (Emulator = emANSIBBS) then
                           begin SendString(^['[C'); end;
                          CE
                        end;
               kbUp: if ShiftState and 3 = 0 then
                        begin
                          if (Emulator = emANSI) or (Emulator = emANSIBBS) then
                           begin SendString(^['[A'); end;
                          CE
                        end else ScrollBackBuf;
               kbDown: if ShiftState and 3 = 0 then
                        begin
                          if (Emulator = emANSI) or (Emulator = emANSIBBS) then
                           begin SendString(^['[B'); end;
                          CE
                        end;
               kbEnter: begin
                          if LastCommand <> '' then
                            begin
                              if CommandsHistory = nil then
                                CommandsHistory := New(PLineCollection, Init(10,10));
                              CommandsHistory^.Insert(NewStr(LastCommand));
                              LastCommand := '';
                            end;
                          SendChar(#13); if TOptions and toENTERLF <> 0 then SendChar(#10); CE
                        end;
                else
                 if (Event.CharCode > #0) then
                    begin
                      Ch := Event.CharCode;
                      LastCommand := LastCommand + Ch;
                      SendChar(Ch);
                    end;
              end;
             end;
 end;
end;

procedure TTerminal.ZmodemDload;
 var R: TRect;
     PA: AbortFunc;
     II: PView;
     Event: TEvent;
     Timer: TEventTimer;
begin
  Protocol := New(ZModemProtocolPtr, Init(COMPort));
  if Protocol = nil then Exit;
  ZModemProtocolPtr(Protocol)^.SetRecoverOption(On);
  ZModemProtocolPtr(Protocol)^.SetBigSubpacketOption(On);
  R.Assign(1,1,40,13);
  Info := New(PWhileView, Init(R));
  Info^.Top := GetString(dlTermReceiving);
  Info^.Options := Info^.Options or ofSelectable;
  Info^.Write(3, GetString(dlTermWaitAnswer));
  Desktop^.Insert(Info);
  XferAborted := Off;
  PA := COMPort^.PR^.UserAbort;
  COMPort^.SetAbortFunc(AbortXfer);
  Protocol^.SetShowStatusProc(ShowReceInfo);
  Protocol^.SetDestinationDirectory(ModemSetup.Download);
  Inc(SkyEnabled);
  NewTimer(Timer, 0);
  Protocol^.ProtocolReceive;
  XferAborted := Off;
  NewTimer(XChkTimer, 18*2);
  Dispose(Protocol, Done);
  II := Info;
  Info := nil;
  II^.Free;
  Protocol := nil;
  COMPort^.SetAbortFunc(PA);
  Event.What := evCommand;
  Event.Command := cmValid;
  PutEvent(Event);
  Dec(SkyEnabled);
  if (FMSetup.Options and fmoBeep <> 0) and
     (ElapsedTimeInSecs(Timer) > 30) then BeepAfterCopy;
end;

procedure TTerminal.ScrollUp(N: Byte);
  var I: Integer;
begin
  if N >= BufSize.Y then
   begin
     for I := 0 to BufSize.Y-1 do
       NewBackRec(Buffer^[I*BufSize.X], BufSize.X);
     FillWord(Buffer^, BufSize.X * BufSize.Y, $0700);
     Exit;
   end;
  for I := ScrollTop to Min(N+ScrollTop,ScrollBot+1)-1 do
     NewBackRec(Buffer^[I*BufSize.X], BufSize.X);
  Move(Buffer^[ (ScrollTop+N) * BufSize.X], Buffer^[ScrollTop*BufSize.X],
                 (ScrollBot + 1  - N - ScrollTop) * BufSize.X * 2);
  FillWord(Buffer^[(ScrollBot + 1 - N) * BufSize.X], N * BufSize.X, $0700);
end;



procedure TTerminal.PutChar;

 procedure LocateCursor(X, Y: Integer);
 begin
   if X < 0 then X := 0;
   CurPos.X := X; CurPos.Y := Y;
   if X >= BufSize.X then
      begin
        {if AutoWrap then} LocateCursor(0, CurPos.Y+1)
                    {else X := BufSize.X-1};
        Exit;
      end;
   if Y > ScrollBot then
      begin
         CurPos.Y := ScrollBot;
         {if Emulator.Scroll then}
           begin ScrollUp(1); DrawView; end;
         Exit
      end;
   if CurPos.Y - Delta.Y >= Size.Y then
    begin
      ScrollTo(Delta.X, CurPos.Y - Size.Y + 1); DrawView; Exit;
    end;
 end;

 procedure ClearScreen;
 begin
   ScrollUp(BufSize.Y); LongInt(CurPos) := 0;
   DrawView;
 end;

 procedure PrintChar(C: Char; MC: Boolean);
  var W,Z,X,Y: Integer;
 begin
   W := (OutAttr shl 8) or Byte(C);
   X := CurPoS.X - Delta.X;
   Y := CurPoS.Y - Delta.Y;
   Z := CurPos.X+CurPos.Y*BufSize.X;
   if TOptions and toInsertMode = 0 then
     begin
       Buffer^[Z] := W;
       WriteLine( X, Y, 1, 1, W);
     end else
     begin
       W := (OutAttr shl 8) or Byte(C);
       Move(Buffer^[Z], Buffer^[Z+1], 2*(BufSize.X - X + Delta.X - 1));
       Buffer^[Z] := W;
       WriteLine(X, Y, Size.X - X, 1, Buffer^[Z]);
     end;
   if MC then
     if CurPos.X < BufSize.X-1 then Inc(CurPos.X)
         else LocateCursor(CurPos.X+1, CurPos.Y);
 end;

 procedure WriteTTY(C: Char);
 begin
   if (TerminalDefaults.Options and toCaptureCtrls = 0) and (Log <> nil) then Log^.Write(C, 1);
   case C of
     #9: while (not TabStops[CurPos.X] and (CurPos.X < BufSize.X-1)) do
            if TOptions and toInsertMode <> 0 then PrintChar(' ', On)
              else Inc(CurPos.X);
     #7: System.Write(#7);
     {#12: {if TOptions and toCTRLCLS <> 0 then ClearScreen else LocateCursor(CurPos.X, CurPos.Y+1);}
     #13,#11,#12: begin
                     LocateCursor(0, CurPos.Y);
                     if TOptions and toENTERLF <> 0 then
                        LocateCursor(CurPos.X, CurPos.Y+1);
                  end;
     #10: LocateCursor(CurPos.X, CurPos.Y+1);
     #8: if CurPos.X > 0 then
          begin
           LocateCursor(CurPos.X - 1, CurPos.Y);
           {if Emulator.EraseBack then}
            begin
              C := Char(TOptions);
              TOptions := TOptions and not toInsertMode;
              PrintChar(' ', Off);
              TOptions := Word(C)
            end;
         end;
     else PrintChar(C, On);
   end;
 end;

 procedure DoMoveCursor(Count, DX, DY: Integer);
  var I: Integer;
      T: TPoint;
 begin
   for I := 1 to Count do
     begin
       T.X := CurPos.X + DX; T.Y := CurPos.Y + DY;
       if T.X < 0 then T.X := 0;
       if T.Y < 0 then T.Y := 0;
       if T.X > BufSize.X then T.X := BufSize.X;
       if T.Y > BufSize.Y-1 then T.Y := BufSize.Y-1;
       CurPos := T;
       {LocateCursor(T.X, T.Y);}
     end;
 end;

 procedure DupChar(C: Char; Count: Integer);
  var I: Integer;
 begin
   for I := 1 to Count do WriteTTY(C);
 end;

 procedure EraseLine(DX, DY: Integer);
 begin
   FillWord(Buffer^[CurPos.X + CurPos.Y * BufSize.X + DX], DY, OutAttr shl 8);
   DrawView;
 end;

 procedure EraseScreen(DX, DY: Integer);
 begin
   FillWord(Buffer^[(CurPos.Y - DX) * BufSize.X], DY * BufSize.X, OutAttr shl 8);
   DrawView;
 end;

 procedure InsertLine(N: Integer);
  var I: Integer;
 begin
   for I := 1 to N do
    begin
      Move(Buffer^[CurPos.Y*BufSize.X], Buffer^[(CurPos.Y+1)*BufSize.X],
           (BufSize.Y - CurPos.Y - 1) * BufSize.X * 2);
      FillWord(Buffer^[CurPos.Y * BufSize.X], BufSize.X, OutAttr shl 8);
    end;
   DrawView;
 end;

 procedure DeleteLine(N: Integer);
  var I: Integer;
 begin
   for I := 1 to N do
    begin
      Move(Buffer^[(CurPos.Y+1)*BufSize.X], Buffer^[CurPos.Y*BufSize.X],
           (BufSize.Y - CurPos.Y - 1) * BufSize.X * 2);
      FillWord(Buffer^[(BufSize.Y - 1) * BufSize.X], BufSize.X, OutAttr shl 8);
    end;
   DrawView;
 end;

 procedure EraseRight(N: Integer);
  var I: Integer;
 begin
   if CurPos.X + N > BufSize.X then N := BufSize.X - CurPos.X;
   MoveColor(WordRec(Buffer^[CurPos.X + CurPos.Y * BufSize.X - 1]).Hi, N, 32);
   DrawView;
 end;

 procedure AreaUp(X1, Y1, X2, Y2, N, Attr: Byte);
 begin
   if X2 >= BufSize.X then X2 := BufSize.X - 1;
   if Y2 >= BufSize.Y then Y2 := BufSize.Y - 1;
   if (X1 > X2) or (Y1 > Y2) then Exit;
   {if N = 0 then}
 end;

 procedure ScrollDown(N: Integer);
 begin
   {if not Emulator.Scroll then Exit;}
   Move(Buffer^, Buffer^[BufSize.X], 2*BufSize.X);
 end;

 procedure UpdateAnsi;
  var I, J: Integer;
      ccc: Char;
      Blink: Boolean;
 begin
   ccc := C;
   if AnsiStr = '' then begin AnsiStr := #27; Exit end;
   if (ANSIStr[1] = 'M') then
     begin
       if (C <> #14) then AddStr(ANSIStr, C)
                 else
                  begin
                    {if Emulator.Music then PlayMusic(Copy(ANSIStr, 2, 255));}
                    ANSIStr := '';
                  end;
       if ANSIStr[0] > #250 then ANSIStr[0] := #0;
       Exit;
     end;
   case C of
     #27: if AnsiStr = #27 then Exit;
     '?','!','"','$': if ANSIStr <> '' then
             begin
               if (ANSIStr[1] in ['0'..'9']) then
                begin
                 Inc(ParamCount);
                 ANSIParams[ParamCount] := StoI(Copy(ANSIStr,2,255));
                end;
                ANSIStr := C;
             end;
     '[': if ANSIStr <> #27 then ANSIStr := '' else ANSIStr[1] := ' ';
     ';': begin
            Inc(ParamCount);
            if ANSIStr <> ' ' then ANSIParams[ParamCount] := StoI(Copy(ANSIStr,2,255))
                              else ANSIParams[ParamCount] := -1;
            ANSIStr := ' ';
          end;
     '0'..'9': if ANSIStr <> '#' then AddStr(ANSIStr, C) else
                 begin ANSIStr := ''; ParamCount := 0; end;
     'M': AnsiStr := 'M';
     else
      begin
        I := StoI(ANSIStr); if I = 0 then I := 1;
        case C of
          'm': begin
                 I := StoI(Copy(ANSIStr,2,255));
                 Inc(ParamCount); ANSIParams[ParamCount] := I;
                 TextAttr := OutAttr;
                 Blink := OutAttr and $80 <> 0;
                 Inverse := False;
                 for I := 1 to ParamCount do
                  begin
                    if Inverse then
                      {Restore inverted TextAttr before continuing}
                      TextAttr := (TextAttr shl 4) or (TextAttr shr 4);

                    {Separate out the forground and background bits}
                    TextFg := TextAttr and $07;
                    TextBk := TextAttr and $70;

                    {Process the color command}
                    case ANSIParams[I] of
                      -1,0: begin
                             TextAttr := $07; {White on black}
                             TextFg := TextAttr and $07;
                             TextBk := TextAttr and $70;
                             Inverse := False;
                             Intense := False;
                             Blink := False;
                           end;
                      1  : begin
                             Intense := True;               {Set intense bit later}
                           end;
                      4  : Intense  := True;               {Subst intense for underline}
                      5  : Blink    := True;               {Set blinking on}
                      7  : begin
                             Inverse  := True;              {Invert TextAttr later}
                             {TextAttr := (TextFg shl 4) or (TextBk shr 4);}
                           end;
                      8  : TextAttr := $00;                {Invisible}
                      22 : Intense  := False;
                      24 : Intense  := False;
                      25 : Blink    := False;
                      27 : Inverse  := False;              {Stop inverting TextAttr}
                      30 : TextAttr := TextBk or $00;      {Black foreground}
                      31 : TextAttr := TextBk or $04;      {Red foreground}
                      32 : TextAttr := TextBk or $02;      {Green foreground}
                      33 : TextAttr := TextBk or $06;      {Yellow forground}
                      34 : TextAttr := TextBk or $01;      {Blue foreground}
                      35 : TextAttr := TextBk or $05;      {Magenta foreground}
                      36 : TextAttr := TextBk or $03;      {Cyan foreground}
                      37 : TextAttr := TextBk or $07;      {White foreground}
                      40 : TextAttr := TextFg;             {Black background}
                      41 : TextAttr := TextFg or $40;      {Red background}
                      42 : TextAttr := TextFg or $20;      {Green background}
                      43 : TextAttr := TextFg or $60;      {Yellow background}
                      44 : TextAttr := TextFg or $10;      {Blue background}
                      45 : TextAttr := TextFg or $50;      {Magenta background}
                      46 : TextAttr := TextFg or $30;      {Cyan background}
                      47 : TextAttr := TextFg or $70;      {White background}
                    end;

                    if Blink then TextAttr := TextAttr or $80;

                    if Intense then
                      TextAttr := TextAttr or $08;

                    {Fix up TextAttr for inverse and intense}
                    if Inverse then begin                                     {!!.02}
                      TextAttr := (TextAttr shl 4) or (TextAttr shr 4);
                         TextAttr := TextAttr and $7F;                         {!!.02}
                    end;                                                      {!!.02}

                  end;
                  OutAttr := TextAttr;
               end;
          'A':  DoMoveCursor(I, 0, -1);
          'B', 'e': DoMoveCursor(I, 0,  1);
          'C', 'a': DoMoveCursor(I, 1,  0);
          'D': DoMoveCursor(I, -1, 0);
          'g': if I = 0 then TabStops[CurPos.X] := Off
                 else if I = 3 then FillChar(TabStops, SizeOf(TabStops), 0);
          '@': begin
                  J := TOptions;
                  TOptions := TOptions or toInsertMode;
                  while I > 0 do begin PrintChar(C, Off); Dec(I) end;
                  TOptions := J;
               end;
         'P': begin
                if CurPos.X + I > BufSize.X then I := BufSize.X - CurPos.X;
                while I > 0 do
                  begin
                    Move(Buffer^[CurPos.X + 1 + CurPos.Y * BufSize.X],
                         Buffer^[CurPos.X + CurPos.Y * BufSize.X],
                         2*Max(BufSize.X-CurPos.X-1,0));
                    WordRec(Buffer^[CurPos.X + (CurPos.Y+1) * BufSize.X - 1]).Lo := 32;
                    Dec(I);
                  end;
                DrawView;
              end;
          'E': begin WriteTTY(#13); DupChar(#10, I); end;
          'F': begin WriteTTY(#13); DoMoveCursor(I, 0, -1); end;
          'G': begin CurPos.X := I - 1; if CurPos.X >= BufSize.X then CurPos.X := BufSize.X-1;
                     LocateCursor(CurPos.X, CurPos.Y) end;
          'd': LocateCursor(CurPos.X, I);
          'h': begin
                 I := Max(1, StoI(Copy(ANSIStr, 2-Byte(AnsiStr[1] in ['0'..'9']), 255)));
                 Inc(ParamCount); ANSIParams[ParamCount] := I;
                 for I := 1 to ParamCount do
                  case ANSIParams[I] of
                     3: if BufSize.X <> 132 then ChangeBufSize(132, BufSize.Y);
                     4: if ANSIStr[1] = ' ' then TOptions := TOptions or toInsertMode;
                    12: if ANSIStr[1] = ' ' then TOptions := TOptions and not toLocalEcho;
                    20: if ANSIStr[1] = ' ' then TOptions := TOptions and not toENTERLF;
                    {}
                  end;
               end;
          'l': begin
                 I := Max(1, StoI(Copy(ANSIStr, 2-Byte(AnsiStr[1] in ['0'..'9']), 255)));
                 Inc(ParamCount); ANSIParams[ParamCount] := I;
                 for I := 1 to ParamCount do
                  case ANSIParams[I] of
                     3: if BufSize.X <> 80 then ChangeBufSize(80, BufSize.Y);
                     4: if ANSIStr[1] = ' ' then TOptions := TOptions and not toInsertMode;
                    12: if ANSIStr[1] = ' ' then TOptions := TOptions or toLocalEcho;
                    20: if ANSIStr[1] = ' ' then TOptions := TOptions or toENTERLF;
                    {}
                  end;
               end;
          'r': begin
                 if ParamCount > 0 then
                   begin
                     ScrollTop := Max(AnsiParams[1]-1, 0);
                     if ANSIStr <> '' then ScrollBot := I-1
                   end else
                   begin
                     ScrollTop := I-1;
                     ScrollBot := BufSize.Y - 1;
                   end;
                 if ScrollBot = ScrollTop then ScrollBot := BufSize.Y - 1;
               end;
          'H', 'f': begin
                 if ParamCount > 0 then
                   begin
                     if AnsiParams[1] > 0 then CurPos.Y := ANSIParams[1] - 1
                         else CurPos.Y := 0;
                     CurPos.X := I - 1;
                   end else begin CurPos.Y := I - 1; CurPos.X := 0; end;
                 if CurPos.X >= BufSize.X then CurPos.X := BufSize.X-1;
                 if CurPos.Y >= BufSize.Y then CurPos.Y := BufSize.Y-1;
                 {LocateCursor(CurPos.X, CurPos.Y)}
               end;
          'I': DupChar(#9, I);
          'K': begin
                 I := StoI(ANSIStr);
                 case I of
                  0: EraseLine(0, BufSize.X - CurPos.X);
                  1: EraseLine(-CurPos.X, CurPos.X + 1);
                  2: EraseLine(-CurPos.X, BufSize.X);
                 end;
               end;
          'J': begin
                 I := StoI(ANSIStr);
                 case I of
                  0: EraseScreen(0, BufSize.Y - CurPos.Y);
                  1: EraseScreen(-CurPos.Y, CurPos.Y + 1);
                  2: begin OutAttr := 7; ClearScreen; end;
                 end;
               end;
         'L': InsertLine(I);
         'M': DeleteLine(I);
         'X': EraseRight(I);
         's': SavePos := CurPos;
         'u': begin CurPos := SavePos; LocateCursor(CurPos.X, CurPos.Y) end;
           {---Device ID--}
         'c': begin
                case Emulator of
                  emVT52: SendModem(#27'/Z');
                  emVT102: SendModem(#27'[?6c');
                    else SendModem(#27'[?1c');
                end;
              end;
         'R': SendModem(#27'['+ItoS(CurPos.Y+1)+';'+ItoS(CurPos.X+1)+'R');
         'n': case I of
               25: SendModem(#27'[?21n');
                5: SendModem(#27'[0n');
               15: SendModem(#27'[?13n');
                6: SendModem(#27'['+ItoS(CurPos.Y+1)+';'+ItoS(CurPos.X+1)+'R');
              end;
         'x': begin

              end;
        end;
        ParamCount := 0;
        ANSIStr := '';
      end;
   end;

 end;


 procedure UpdateAVT;
   var I, J, K: Integer;
       B: Byte absolute AvatarStr;
       LO: Word;
       ccc: Char;
       SIns: Boolean;
       S: String[80];
 begin
   AddStr(AvatarStr, C);
   if AvatarStr[0] > #200 then begin B := 0; Exit end;
   case AvatarStr[1] of
     ^Y: if AvatarStr[0] > #2 then
           begin B := 0; J := TOptions; TOptions := TOptions and not toInsertMode;
                 for I := 1 to Byte(C) do WriteTTY(AvatarStr[2]); TOptions := J end;
     ^V: case AvatarStr[2] of
           ^A: if AvatarStr[0] > #2 then begin OutAttr := Byte(C); B := 0; end;
           ^B: begin OutAttr := OutAttr or $80; B := 0; end;
           ^C: begin DoMoveCursor(1,  0, -1); B := 0; end;
           ^D: begin DoMoveCursor(1,  0,  1); B := 0; end;
           ^E: begin DoMoveCursor(1, -1,  0); B := 0; end;
           ^F: begin DoMoveCursor(1,  1,  0); B := 0; end;
           ^G: begin EraseLine(0, BufSize.X - CurPos.X); B := 0; end;
           ^H: if AvatarStr[0] > #3 then
                begin LocateCursor(Byte(AvatarStr[4]), Byte(AvatarStr[3])); B := 0; end;
           ^Y: if (AvatarStr[0] > #3) and (Length(AvatarStr) > Byte(AvatarStr[3]) + 3) then
                begin
                  Delete(AvatarStr, 1, 3);
                  Dec(B);
                  J := TOptions; TOptions := TOptions and not toInsertMode;
                  S := AvatarStr; K := Byte(C); AvatarStr := '';
                  for I := 1 to K do
                    for J := 1 to Length(S) do PutChar(S[J]);
                  B := 0;
                  TOptions := J;
                end;
         end;
   end;
 end;

 function UpdateVT52: Boolean;
   var CE: Boolean;
 begin
   UpdateVT52 := On;
   CE := On;
   AddStr(ANSIStr, C);
   case ANSIStr[2] of
     '7': SavePos := CurPos;
     '8': begin CurPos := SavePos; LocateCursor(CurPos.X, CurPos.Y) end;
     'A': DoMoveCursor(1, 0, -1);
     'B': DoMoveCursor(1, 0,  1);
     'C': DoMoveCursor(1,  1, 0);
     'D': DoMoveCursor(1, -1, 0);
     'F':;     { ENTER GRAPHICS }
     'G':;
     'H': LocateCursor(0,0);
     'I': if CurPos.Y = 0 then begin ScrollDown(1); DrawView end
                             else LocateCursor(CurPos.X, CurPos.Y-1);
     'J': EraseScreen(0, BufSize.Y - CurPos.Y);
     'K': EraseLine(0, BufSize.X - CurPos.X);
     'V': ;{ PRINT CURSOR LINE}
     'W': ;{ ENTER transparent printing }
     'X': ;{ Exit transparent printing }
     'Y': if Length(ANSIStr) > 3 then LocateCursor(Byte(ANSIStr[4])+CurPos.Y,Byte(ANSIStr[3])+CurPos.X)
                                 else CE := Off;
     'Z': SendModem(#27'/Z');

(*
     '=': ShiftState := Mem[$40:$17] and not $20;
     '>': Mem[$40:$17] := Mem[$40:$17] or $20;
*)
     '<': Emulator := emVT102;
     ']': ; { PrintScreen }
     '^': ; { Printer On }
     '_': ; { Printer Off }
      else UpdateVT52 := Off;
   end;
   if CE then ANSIStr := '';
 end;


 function UpdateVT100:Boolean;
   var CE: Boolean;
 begin
   CE := On;
   if (ANSIStr[0] >= #1) and
      (PosChar(ANSIStr[1],' !?"$')>0) then begin UpdateAnsi; Exit; end;
   AddStr(ANSIStr, C);
   case ANSIStr[2] of
     '[': begin ANSIStr := ' '; Exit end;
     ' ': if ANSIStr < #3 then Exit
           else if C = 'F' then {Emulator.StripHigh := On}
             else if C = 'G' then {Emulator.StripHigh := Off};
     '7': SavePos := CurPos;
     '8': begin CurPos := SavePos; LocateCursor(CurPos.X, CurPos.Y) end;
     'E': LocateCursor(0,CurPos.Y+1);
     'H': TabStops[CurPos.X] := On;
     'D':
           LocateCursor(CurPos.X, CurPos.Y+1);
     'J': EraseScreen(0, BufSize.Y - CurPos.Y);
     'K': EraseLine(0, BufSize.X - CurPos.X);
     'M': if CurPos.Y = 0 then begin ScrollDown(1); DrawView end
                          else LocateCursor(CurPos.X, CurPos.Y-1);
     'Y': if Length(ANSIStr) > 3 then LocateCursor(Byte(ANSIStr[4])+CurPos.Y,Byte(ANSIStr[3])+CurPos.X)
                                 else CE := Off;
     'Z': ;
(*
     '=': ShiftState := Mem[$40:$17] and not $20;
     '>': Mem[$40:$17] := Mem[$40:$17] or $20;
*)
     '<': ;
     ']': ; { PrintScreen }
     '^': ; { Printer On }
     '_': ; { Printer Off }
     '(',')',
     '*','+','-',                                { Character sets }
     '.','/','#': if AnsiStr[0] < #3 then Exit;
   end;
   if CE then ANSIStr := '';
 end;



begin
  if (TerminalDefaults.Options and toCaptureCtrls <> 0) and
     (Log <> nil) then Log^.Write(C, 1);
  {if Emulator.StripHigh then asm mov al, $7F; and al, C; mov C,al end;
  C := InTable[C];}
  case Emulator of
    emVT52: if AnsiStr <> '' then UpdateVT52
                 else if C = #27 then AddStr(ANSIStr, C) else WriteTTY(C);
    emVT102,
    emANSI: if AnsiStr <> '' then UpdateVT100 else
                  case C of
                   #27: ANSIStr := #27;
                   #14:;
                   #15:;
                   {#$84: begin ANSIStr := #27; C := 'D'; end;
                   #$85: begin ANSIStr := #27; C := 'E'; end;
                   #$88: begin ANSIStr := #27; C := 'H'; end;
                   #$8D: begin ANSIStr := #27; C := 'M'; end;
                   #$8e: begin ANSIStr := #27; C := 'N'; end;
                   #$8f: begin ANSIStr := #27; C := 'O'; end;
                   #$90: begin ANSIStr := #27; C := 'P'; end;
                   #$9b: begin ANSIStr := #27; C := '['; end;
                   #$9c: begin ANSIStr := #27; C := '\'; end;
                   #$9d: begin ANSIStr := #27; C := ']'; end;
                   #$9e: begin ANSIStr := #27; C := '^'; end;
                   #$9f: begin ANSIStr := #27; C := '_'; end;}
                                 else WriteTTY(C);
                 end;
    emANSIBBS: if (ANSIStr <> '') then UpdateANSI else
                 if (AvatarStr <> '') then UpdateAVT
               else
                case C of
                  ^L: begin ClearScreen; OutAttr := 3; end;
                  ^Y, ^V: AvatarStr := C;
                  #27: UpdateANSI;
                   else WriteTTY(C);
                end;
    else WriteTTY(C);
  end;
  if (CurPos.Y < Delta.Y) then ScrollTo(0, 0);
  if (CurPos.Y > Delta.Y+Size.Y-1) then ScrollTo(0, CurPos.Y - Size.Y + 1);
end;


procedure TTerminal.Update;
 const S = '**'^X'B00';
 var C: Char;
     B: Byte;
     II: Byte;
begin
 if (Protocol <> nil) or (COMPort = nil) then Exit;
 II := 0;
 while COMPort^.CharReady and (II < 100) do
  begin
   COMPort^.GetChar(C);
   if ModemAnswer[0] > #254 then Delete(ModemAnswer, 1, 50);
   AddStr(ModemAnswer, C);
   if (C = '0') and (TOptions and toAutoZModem <> 0) and
      (Copy(ModemAnswer, Length(ModemAnswer) - Length(S) + 1, Length(S)) = S)
    then begin
          ZmodemDload;
          ModemAnswer := '';
          Break;
         end;
   PutChar(C);
   Inc(II);
  end;
  if II > 0 then
    begin
      ShowCursor;
      NormalCursor;
      SetCursor(CurPos.X - Delta.X, CurPos.Y - Delta.Y);
    end;
  if TimerExpired(UpdTimer) then
    begin
      B := 0;
      if COMPort^.CheckDeltaDCD then B := DCDMask;
      if COMPort^.CheckDeltaCTS then B := B or CTSMask;
      if COMPort^.CheckDeltaDSR then B := B or DSRMask;
      if B <> 0 then Message(Owner, evBroadcast, cmOK, Pointer(B));
      NewTimer(UpdTimer, 18);
    end;
end;

procedure TTerminal.ChangeBounds;
 var I, J, K: Integer;
     BB: PWordArray;
begin
  inherited ChangeBounds(Bounds);
  if (ScreenHeight <> BufSize.Y) then
     begin
       ChangeBufSize(BufSize.X, ScreenHeight);
       ScrollBot := BufSize.Y - 1;
     end;
end;

procedure TTerminal.ChangeBufSize;
  var NSize: TPoint;
      P: PWordArray;
      I: Integer;
begin
  P := MemAlloc(2*NX*NY);
  if P = nil then Exit;
  if NY < BufSize.Y then ScrollUp(BufSize.Y - NY);
  FillWord(P^, NX*NY, (TextAttr shl 8) or 32);
  for I := 0 to Min(NY, BufSize.Y)-1 do
      Move(Buffer^[BufSize.X*I], P^[NX*I], Min(BufSize.X, NX)*2);
  FreeMem(Buffer, 2*BufSize.X*BufSize.Y);
  Buffer := P;
  BufSize.X := NX; BufSize.Y := NY;
  SetLimit(NX, NY);
  DrawView;
end;

procedure TTerminal.SendModem;
begin
  if COMPort <> nil then
     COMPort^.PutString(S);
end;


end.
