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

unit PrintManager;

interface

uses Objects, Views, Drivers, DNApp, Advance, Dialogs, DOS, Messages,
     Commands, ObjType;

 type
      PStringCol =  ^TStringCol;
      TStringCol = object(TCollection)
       procedure FreeItem(P: Pointer); virtual;
       procedure PutItem(var S: TStream;P: Pointer); virtual;
       function GetItem(var S: TStream): Pointer; virtual;
      end;

      PPrintManager = ^TPrintManager;
      TPrintManager = object(TListBox)
        isValid: Boolean;
        OutName: PString;
        LockUpdate: Byte;
        Paused: Boolean;
        FileLen: LongInt;
        FilePos: LongInt;
        Status: PView;
        PrintStream: PStream;
        Buffer: PByteArray;
        BufSize: Word;
        BufCount: Word;
        PrintDevice: PDOSStream;
        constructor Init(var Bounds: TRect; AStatus: PView; AScrollBar: PScrollBar);
        constructor Load(var S: TStream);
        procedure Store(var S: TStream);
        function PrintBuffer(Num: Word): Boolean;
        procedure HandleEvent(var Event: TEvent); virtual;
        procedure PrintFile(FileName: String);
        function SetDestination: Boolean;
        function GetStatus: Byte;
        procedure InitPrinter;
        function Valid(C: Word): Boolean; virtual;
        procedure Update; virtual;
        destructor Done; virtual;
      end;

      PPrintStatus = ^TPrintStatus;
      TPrintStatus = object(TView)
        Print: PPrintManager;
        procedure Draw; virtual;
        constructor Load(var S: TStream);
        procedure Store(var S: TStream);
      end;

      PPMWindow = ^TPMWindow;
      TPMWindow = object(TDialog)
        constructor Init(R: TRect);
      end;

const Printer: PPrintManager = nil;
      MaxBufCount = 128;

      RStringCol: TStreamRec = (
       ObjType: otStringCol;
       VmtLink: Ofs(TypeOf(TStringCol)^);
       Load: @TStringCol.Load;
       Store: @TStringCol.Store);

      RPrintManager: TStreamRec = (
       ObjType: otPrintManager;
       VmtLink: Ofs(TypeOf(TPrintManager)^);
       Load: @TPrintManager.Load;
       Store: @TPrintManager.Store);

      RPrintStatus: TStreamRec = (
       ObjType: otPrintStatus;
       VmtLink: Ofs(TypeOf(TPrintStatus)^);
       Load: @TPrintStatus.Load;
       Store: @TPrintStatus.Store);

      RPMWindow: TStreamRec = (
       ObjType: otPMWindow;
       VmtLink: Ofs(TypeOf(TPMWindow)^);
       Load: @TPMWindow.Load;
       Store: @TPMWindow.Store);

procedure SetupPrinter;

implementation

uses
  RStrings, Startup, DNHelp;

procedure TStringCol.FreeItem;
begin
  DisposeStr(P);
end;

procedure TStringCol.PutItem;
begin
  S.WriteStr(P);
end;

function TStringCol.GetItem;
begin
  GetItem := S.ReadStr;
end;

constructor TPMWindow.Init;
 var P: PView;
     S: PView;
begin
 Inherited Init(R, GetString(dlPManagerTitle));
 R.Assign(Size.X - 13,1,Size.X - 12, Size.Y - 4);
 P := New(PScrollBar, Init(R));
 Insert(P);
 R.Assign(2,Size.Y - 4,Size.X - 14, Size.Y - 2);
 S := New(PPrintStatus, Init(R));
 Insert(S);
 R.Assign(2,1,Size.X - 13, Size.Y - 4);
 P := New(PPrintManager, Init(R, S, PScrollBar(P)));
 Insert(P);
 R.Assign(Size.X - 12, 2, Size.X - 2, 4);
 Insert(New(PButton, Init(R, GetString(dlDeleteButton), cmOK, 0)));
 R.Assign(Size.X - 12, 4, Size.X - 2, 6);
 Insert(New(PButton, Init(R, GetString(dlCloseButton), cmClose, 0)));
 R.Assign(Size.X - 12, 6, Size.X - 2, 8);
 Insert(New(PButton, Init(R, GetString(dlPauseButton), cmNo, 0)));
 SelectNext(False);
 HelpCtx := hcPrintManager;
end;

constructor TPrintStatus.Load;
begin
 inherited Load(S);
 GetPeerViewPtr(S, Print);
end;

procedure TPrintStatus.Store;
begin
 inherited Store(S);
 PutPeerViewPtr(S, Printer);
end;

procedure TPrintStatus.Draw;
 var B: TDrawBuffer;
     C: Word;
     S,S1: String;
begin
  S1 := '';
  C := GetColor($0102);
  MoveChar(B, ' ', C, Size.X);
  if (Print^.Paused) or (Print^.List = nil) or (Print^.List^.Count = 0)
     then S := GetString(dlPrintingPaused)
     else begin
           S := GetString(dlPrinting);
           S := S + Cut(PString(Print^.List^.At(0))^, Size.X - CStrLen(S));
           if Print^.FileLen <> 0 then
            S1 := '~'+Copy(Strg(#219, ((Size.X-6)*Print^.FilePos) div Print^.FileLen)
                       + Strg(#177, Size.X-6), 1, Size.X - 6) + ' ~' +
                       SStr((100*(Print^.FilePos + 1)) div (Print^.FileLen + 1), 2, ' ') + '%';
          end;
  MoveCStr(B, '~'+S+'~', C);
  WriteLine(0,0,Size.X,1,B);
  MoveChar(B, ' ', C, Size.X);
  MoveCStr(B, S1, C);
  WriteLine(0,1,Size.X,1,B);
end;

constructor TPrintManager.Init;
 var S: String;
begin
 inherited Init(Bounds, 1, AScrollBar);
 Options := Options or ofPostProcess;
 Status := AStatus;
 if Status <> nil then PPrintStatus(Status)^.Print := @Self;
 Printer := @Self;
 BufSize := MaxBufCount;
 GetMem(Buffer, BufSize);
 LockUpdate := 0;
 isValid := False;
 Paused := True;
 OutName := nil;
 if not SetDestination then Exit;
 isValid := True;
 Paused := False;
 RegisterToBackground(@Self);
end;

function TPrintManager.SetDestination;
 var S: String;
     P: Boolean;
     OldP: PDOSStream;
begin
 SetDestination := False;
 P := Paused;
 Paused := True;
 case RPrinterSetup.Device of
   0: S := 'LPT1';
   1: S := 'LPT2';
   2: S := 'LPT3';
   3: S := 'LPT4';
   5: S := 'COM1';
   6: S := 'COM2';
   7: S := 'COM3';
   8: S := 'COM4';
   9: S := 'NUL';
   else begin
     S := '';
     if InputBox(GetString(dlPrintOut), GetString(dlFileName), S, 80, hsPrintOut) <> cmOK then Exit;
   end;
 end;
 OldP := PrintDevice;
 PrintDevice := New(PDOSStream, Init(S, stCreate));
 if PrintDevice^.Status <> stOK then
  begin
    PrintDevice := OldP;
    MessageBox(GetString(dlPrintNoInit), nil, mfError + mfOKButton);
    PrintDevice^.Status := 0;
    Exit;
  end;
 if OldP <> nil then Dispose(OldP, Done);
 DisposeStr(OutName);
 OutName := NewStr(S);
 InitPrinter;
 Paused := P;
 SetDestination := True;
end;

constructor TPrintManager.Load;
begin
   inherited Load(S);
   Printer := @Self;
   GetPeerViewPtr(S, Status);
   OutName := S.ReadStr;
   S.Read(Paused, 1);
   S.Read(FilePos, 4);
   PrintDevice := New(PDOSStream, Init(OutName^, stCreate));
   BufSize := MaxBufCount;
   GetMem(Buffer, BufSize);
   isValid := True;
   if PrintDevice^.Status <> stOK then
    begin
      isValid := False;
      MessageBox(GetString(dlPrintNoInit), nil, mfError + mfOKButton);
      PrintDevice^.Status := 0;
      Exit;
    end;
   PrintStream := New(PBufStream, Init(PString(List^.At(0))^, stOpenRead, $400));
   FileLen := PrintStream^.GetSize;
   PrintStream^.Seek(FilePos);
   {PrintStream := nil;}
end;

procedure TPrintManager.Store;
begin
   inherited Store(S);
   PutPeerViewPtr(S, Status);
   S.WriteStr(OutName);
   S.Write(Paused, 1);
   S.Write(FilePos, 4);
end;

destructor TPrintManager.Done;
begin
  if PrintStream <> nil then Dispose(PrintStream, Done);
  if PrintDevice <> nil then Dispose(PrintDevice, Done);
  if Buffer <> nil then FreeMem(Buffer, BufSize);
  DisposeStr(OutName);
  Printer := nil;
  inherited Done;
end;

function TPrintManager.Valid;
begin
 Inc(LockUpdate);
 case C of
  cmValid: Valid := isValid and inherited Valid(C);
  cmClose: if MessageBox(GetString(dlPrintCancelQuery), nil, mfYesNoConfirm) = cmYes then
           begin Valid := True; InitPrinter; end else Valid := False;
 end;
 Dec(LockUpdate);
end;

procedure TPrintManager.HandleEvent;
begin
 inherited HandleEvent(Event);
 case Event.What of
  evCommand: case Event.Command of
              cmGetName: PString(Event.InfoPtr)^ := GetString(dlPManagerTitle);
              cmClose: Event.InfoPtr := nil;
              cmNo: begin
                      Paused := not Paused;
                      if Status <> nil then Status^.DrawView;
                      ClearEvent(Event);
                    end;
              cmOK: begin
                     Inc(LockUpdate);
                     if (List <> nil) and (List^.Count > Focused) and
                        (MessageBox(GetString(dlPDeleteQeury1)+Cut(PString(List^.At(Focused))^,40)+
                                    GetString(dlPDeleteQeury2), nil, mfYesNoConfirm) = cmYes)
                        then begin
                               if (Focused = 0) and (PrintStream <> nil) then
                                begin
                                  Dispose(PrintStream, Done);
                                  InitPrinter;
                                  PrintStream := nil;
                                  Buffer^[0] := 12;
                                  repeat until PrintBuffer(1);
                                end;
                               List^.AtFree(Focused);
                               SetRange(List^.Count);
                               DrawView;
                               if Status <> nil then Status^.DrawView;
                             end;
                     ClearEvent(Event);
                     Dec(LockUpdate);
                    end;
             end;
 end;
end;

procedure TPrintManager.PrintFile;
begin
  if List = nil then List := New(PStringCol, Init(10,10));
  List^.Insert(NewStr(Advance.FExpand(FileName)));
  SetRange(List^.Count);
  DrawView;
  if Status <> nil then Status^.DrawView;
end;

procedure TPrintManager.InitPrinter;
 var  Hndl: Word;
begin
  Hndl := PrintDevice^.Handle;
  asm
    MOV  BX, Hndl
    MOV  AX,4400H   { IOCTL, GET DEV ATTR}
    INT  21H
    JC   @@100
    {MOV  [OLD_PRINTER_ATTR],AL}
    TEST AL,80H  {; 0 - disk}
    JZ   @@100
    MOV  DH,0
    OR   DL,20H  {; BINARY MODE}
    MOV  BX,4
    MOV  AX,4401H     {; IOCTL, SET DEV ATTR}
    INT  21H
   @@100:
 end;
end;

function TPrintManager.GetStatus: Byte; assembler;
asm
    mov ah, 2
    mov al, $90
    mov dx, word ptr RPrinterSetup
    cmp dx, 2
    jnc @@1
    int 17h
    mov al, ah
   @@1:
end;

function TPrintManager.PrintBuffer;
 label 1;
 const TryCount: Byte = 0;
 var B: Byte;
     BB: Boolean;
begin
 PrintBuffer := False;
 B := GetStatus;
 if (B and 8 <> 0) or (B and $10 = 0) then
  begin
   Inc(TryCount);
   PrintBuffer := False;
   Abort := False;
   if TryCount > 20 then
    begin
1:    TryCount := 0;
      Paused := True;
      MessageBox(GetString(dlCantPrint), nil, mfError+mfOKButton);
      PrintBuffer := Num = 1;
    end;
    Exit;
  end;
 if (B and $90 = 0) or (B and 1 <> 0) then Exit;
 PrintBuffer := True;
 {BB := NeedAbort;
 NeedAbort := True; Abort := False;}
 PrintDevice^.Status := 0;
 PrintDevice^.Write(Buffer^, Num);
 PrintDevice^.Status := 0;
 {NeedAbort := BB;}
 if Abort then Goto 1;
end;

procedure TPrintManager.Update;
 var I, L: LongInt;
     S: Byte;

 procedure WriteError;
  var S: String;
 begin
  if List <> nil then S := PString(List^.At(0))^;
  Inc(LockUpdate);
  if (PrintStream^.Status <> stOK) then
     MessageBox(GetString(dlCantPrintFile) + S, nil,
             mfError + mfOKButton);
  Dispose(PrintStream, Done);
  PrintStream := nil;
  if InMask(Norm12(GetName(S)), '$DN????$.PRN') then EraseFile(S);
  List^.AtFree(0);
  SetRange(List^.Count);
  FocusItem(Focused-1);
  DrawView;
  if Status <> nil then Status^.DrawView;
  Dec(LockUpdate);
 end;

begin
  if (List = nil) or Paused or (LockUpdate <> 0) then Exit;
  if (PrintStream = nil) then
   begin
     if (List = nil) or (List^.Count < 1) then
      begin
       if not Owner^.GetState(sfDragging) then Owner^.Free;
       Exit;
      end;
     PrintStream := New(PBufStream, Init(PString(List^.At(0))^, stOpenRead, $400));
     FileLen := 0; FilePos := 0;
     if PrintStream^.Status <> stOK then WriteError else
     begin
        FileLen := PrintStream^.GetSize;
        if RPrinterSetup.InitPrinter = '' then
         begin
           BufCount := MaxBufCount;
           if  BufCount > FileLen then BufCount := FileLen;
           PrintStream^.Read(Buffer^, BufCount);
         end else
         begin
           BufCount := Length(RPrinterSetup.InitPrinter);
           Move(RPrinterSetup.InitPrinter[1], Buffer^, BufCount);
         end;
     end;
   end else
   begin
     if PrintBuffer(BufCount) then
      begin
       FilePos := PrintStream^.GetPos;
       if (FilePos >= FileLen) or (PrintStream^.Status <> stOK) then
        begin
          if RPrinterSetup.AfterFile <> '' then
           begin
             BufCount := Length(RPrinterSetup.AfterFile);
             Move(RPrinterSetup.AfterFile[1], Buffer^, BufCount);
             repeat until PrintBuffer(BufCount);
             if not Paused then WriteError;
           end else if not Paused then WriteError;
        end else
        begin
          BufCount := MaxBufCount;
          if BufCount + FilePos > FileLen then BufCount := FileLen - FilePos;
          PrintStream^.Read(Buffer^, BufCount);
        end;
      end;
   end;
   if Status <> nil then Status^.DrawView;
end;

{
type TMyApp = object(TApplication)
      procedure Idle; virtual;
     end;

procedure TMyApp.Idle;
begin
 inherited Idle;
 if Printer <> nil then Printer^.Update;
end;
}
procedure SetupPrinter;
 var LastDest: Word;
begin
  LastDest := RPrinterSetup.Device;
  if ExecResource(dlgPrinterSetup, RPrinterSetup) = cmOK then
     Message(Application, evCommand, cmUpdateConfig, nil);
  if (LastDest <> RPrinterSetup.Device) and (Printer <> nil) then
     Printer^.SetDestination;
end;

{var App: TMyApp;
    R: TRect;

begin
  App.Init;
  SetupPrinter;
  R.Assign(0,0,50,9);
  App.InsertWindow(New(PPMWindow, Init(R)));
  for R.A.X := 1 to ParamCount do
    Printer^.PrintFile(ParamStr(R.A.X));
  App.Run;
  App.Done;}
end.

