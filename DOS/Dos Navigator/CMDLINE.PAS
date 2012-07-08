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

unit CmdLine;
interface
 uses Objects, Views, Drivers;

type
  Str128 = String[127];

     PCommandLine = ^TCommandLine;
     TCommandLine = object(TView)
      Dir: String[80];
      DeltaX, CurX: Integer;
      Overwrite: Boolean;
      LineType: (ltNormal, ltOS2Fullscreen, ltOS2Window, ltTimer);
      constructor Init(R: TRect);
      procedure Draw; virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure SetState(AState: Word; Enable: Boolean); virtual;
      procedure Update; virtual;
      procedure GetDir;
      procedure GetData(var S); virtual;
      function DataSize: Word; virtual;
      procedure SetDirShape;
     end;

(*
     PCmdLine = ^TCmdLine;
     TCmdLine = object(TView)
      procedure Draw; virtual;
     end;

     PCmdWindow = ^TCmdWindow;
     TCmdWindow = object(TWindow)
      constructor Init(R: TRect);
     end;
*)


const Separators = [':','.',',','/','\','[',']','+','>','<','|',';',' '];
      StrModified: Boolean = False;
      DDTimer: LongInt = 0;
      TimerMark: Boolean = False;
      CurString: Integer = 0;
      CmdDisabled: Boolean = False;
      HideCommandLine: Boolean = False;
      Str: Str128 = '';


implementation
 uses Dos, Commands, DNApp, DNStdDlg, Dialogs, Advance,
      Startup, RStrings, xTime, Messages, Idlers, MicroEd, Histries,
      FViewer;


constructor TCommandLine.Init;
begin
 inherited Init(R);
 EventMask := $FFFF;
 Options := Options {or ofSelectable}  or ofPostProcess
                    or ofFirstClick {or ofTopSelect};
 DragMode := dmDragMove;
 GetDir; Str := ''; DeltaX := 0; CurX := 0;
 GrowMode := gfGrowLoY + gfGrowHiX + gfGrowHiY;
 Overwrite := False;
 LineType := ltNormal;
end;

function TCommandLine.DataSize; begin DataSize := sizeof(Str128) end;

procedure TCommandLine.GetData; begin Str128(S) := Str; end;

procedure TCommandLine.GetDir;
var MM: record
         case byte of
          1: (L: LongInt; S: String[1]);
          2: (C: Char);
        end;
     D: PDialog;
begin
 Inc(SkyEnabled);
 repeat
  Abort := Off; NeedAbort := On;
  System.GetDir(0, Dir);
  if Abort then
   begin
    repeat
      MM.L := 0; MM.C := GetCurDrive; MM.S := MM.C;
      D := PDialog(LoadResource(dlgDiskError));
      if D <> nil then
       begin
        D^.SetData(MM);
        Application^.ExecView(D);
        D^.GetData(MM);
        Dispose(D, Done);
       end;
      UpStr(MM.S);
      if ValidDrive(MM.S[1]) then
       begin SetCurDrive(MM.S[1]); Break; end;
    until False;
    Abort := On;
   end;
 until not Abort;
 Dec(SkyEnabled);
 NeedAbort := Off;
 if (Dir[0] > #3) and (Dir[Length(Dir)] = '\') then Dec(Dir[0]);
 ActiveDir := Dir;
 SetDirShape;
end;

procedure TCommandLine.SetDirShape;
begin
  TimerMark := LineType = ltTimer;
  if Dir[1] in ['[','(','{'] then Dir := Copy(Dir,2,Length(Dir)-2)
                             else Dec(Dir[0], Byte(Dir[Length(Dir)]='>'));
  Case LineType of
    ltOS2FullScreen: Dir := '[' + Dir + ']';
    ltOS2Window: Dir := '(' + Dir + ')';
    ltTimer: Dir := '{' + Dir + '}';
     else Dir := Dir + '>';
  end;
end;

procedure TCommandLine.Update;
 var P: TPoint;
     A1,A2: Integer;
     BB: Boolean;
begin
 if GetState(sfDisabled) then Exit;
 asm
   mov ah,3
   xor bx,bx
   int 10h
   mov A1, dx
   mov A2, cx
  end;
  if (SSaver <> nil) or (Size.X = 0) or (Size.Y = 0) or
    (Desktop^.GetState(sfActive) and
    (Desktop^.Current <> nil) and
    (Desktop^.Current^.GetState(sfCursorVis) or Desktop^.Current^.GetState(sfModal)))
      then Exit;
  P.X := CurX - DeltaX + Length(Dir); P.Y := 0;
  MakeGlobal(P, P);
  BB := not Overwrite  xor (InterfaceData.Options and ouiBlockInsertCursor <> 0);
  asm
        MOV     CX,CursorLines
        LES     DI,Self
        CMP     BB, 0
        JNE     @@1
        MOV     CH,0
        OR      CL,CL
        JNE     @@1
        MOV     CL,7
@@1:    MOV     AH,1
        INT     10H
        MOV     AH, 2
        XOR     BX, BX
        MOV     DL, BYTE PTR P
        MOV     DH, BYTE PTR P+2
        INT     10H
  end;
end;

procedure TCommandLine.SetState;
begin
 TView.SetState(AState, Enable);
 if AState and (sfActive or sfFocused) <> 0 then
  begin
   DrawView;
   if Enable then EnableCommands([cmNext, cmPrev]) else DisableCommands([cmNext, cmPrev])
  end;
end;

procedure TCommandLine.Draw;
 var B: Array[0..300] of record C: Char; A: Byte; end;
     C1, C2, C3: Word;
begin
 if CmdDisabled then Exit;
 C3 := $0F;
 C1 := $07; if Overwrite then C2 := $4F else C2 := $70;
 if CurX < 0 then CurX := 0;
 if CurX > Length(Str) then CurX := Length(Str);
 if CurX < DeltaX then DeltaX := CurX;
 if CurX - DeltaX > Size.X - Length(Dir) - 1 then
    DeltaX := CurX - Size.X + Length(Dir) + 1;
 MoveChar(B, ' ', C1, Size.X);
 MoveStr(B, Dir, C3);
 MoveStr(B[Length(Dir)], Copy(Str, DeltaX + 1, 200), C1);
 ShowCursor;
 if Overwrite xor (InterfaceData.Options and ouiBlockInsertCursor <> 0) then BlockCursor
                                                                        else NormalCursor;
 {SetCursor(CurX - DeltaX + Length(Dir),0);
 {if not GetState(sfFocused) then B[CurX - DeltaX + Length(Dir)].A := C2;}
 {Update;}
 WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TCommandLine.HandleEvent;
 procedure CE; begin ClearEvent(Event) end;
 procedure CE2; begin DrawView; ClearEvent(Event) end;

 procedure CheckSize;
 begin
   if not GetState(sfVisible) and (Str <> '') then
      begin
        ToggleCommandLine(On);
      end;
 end;

 var R: TRect;
     P: TPoint;
     S: String;
     Changed: Boolean;
begin
 inherited HandleEvent(Event);
 S := Str; Changed := False;
 case Event.What of
  evMouseDown, evMouseAuto: begin
                if Event.Double then
                 begin
                   Message(Application, evCommand, cmHistoryList, nil); CE
                 end;
                MakeLocal(Event.Where, P);
                if P.X >= Length(Dir) then
                  if Event.Buttons and mbRightButton <> 0 then
                   begin
                     if P.X < (Size.X - Length(Dir)) div 2 then Message(@Self, evKeyDown, kbLeft, nil)
                                                           else Message(@Self, evKeyDown, kbRight, nil);
                     CE2;
                   end else
                   begin
                     CurX := DeltaX + P.X - Length(Dir);
                     CE2
                   end;
               end;
  evCommand: case Event.Command of
              cmRereadInfo: begin GetDir; DrawView; UpDate end;
              cmInsertName: if InterfaceData.Options and ouiHideCmdline = 0 then
                            begin
                             S := String(Event.InfoPtr^)+' ';
                             if S[Length(S)-1] = '\' then Dec(S[0]);
                             if (CurX > 0) and not (Str[CurX] in Separators) then
                                begin Insert(' ', Str, CurX+1); Inc(CurX) end;
                             Insert(S, Str, CurX+1); Inc(CurX, Length(S));
                             CE2; CheckSize;
                            end;
              cmExecCommandLine: if InterfaceData.Options and ouiHideCmdline = 0 then
                                 begin
                                  if DelSpaces(Str) = '' then Exit;
                                  StrModified := True;
                                  Message(@Self, evKeyDown, kbDown, nil);
                                  Message(@Self, evKeyDown, kbUp, nil);
                                 end;
             end;
  evKeyDown: begin
                if InterfaceData.Options and ouiHideCmdline = 0 then
                case Event.CharCode of
                 ^V: begin Overwrite := not Overwrite; CE2 end;
                 ^J: begin Message(@Self, evKeyDown, kbENTER, nil); CE end;
                 ^A: begin Message(@Self, evKeyDown, kbCtrlLeft, nil); CE end;
                 ^F: begin Message(@Self, evKeyDown, kbCtrlRight, nil); CE end;
                 #32..#126,#128..#255:
                   begin
                    if OverWrite then if CurX >= Length(Str) then Str := Str + Event.CharCode
                                                             else Str[CurX+1] := Event.CharCode
                                 else Insert(Event.CharCode, Str, CurX+1);
                    Inc(CurX); StrModified := True; CE2;
                   end;
                 #127: begin
                        While (CurX > 0) and not (Str[CurX] in Separators) do
                         begin Delete(Str, CurX, 1); Dec(CurX) end;
                        While (CurX > 0) and (Str[CurX] in Separators) do
                         begin Delete(Str, CurX, 1); Dec(CurX) end;
                        CE2;
                       end;
                 else
                  case Event.KeyCode of
                   kbAltSlash: begin
                                 if ShiftState and 3 <> 0 then Dec(LineType)
                                                            else Inc(LineType);
                                 if not OS210 and (LineType in [ltOS2Window,ltOS2FullScreen]) then
                                   if ShiftState and 3 <> 0 then Dec(LineType)
                                                              else Inc(LineType);
                                 if not OS210 and (LineType in [ltOS2Window,ltOS2FullScreen]) then
                                   if ShiftState and 3 <> 0 then Dec(LineType)
                                                              else Inc(LineType);
                                 if LineType > ltTimer then LineType := ltNormal;
                                 if LineType < ltNormal then LineType := ltTimer;
                                 SetDirShape;
                                 if (InterfaceData.Options and ouiHideCmdLine = 0) and
                                    not GetState(sfVisible) and (Str = '')
                                      then begin
                                             Str := ' ';
                                             ToggleCommandLine(On);
                                             Str := '';
                                           end;
                                 CE2
                               end;
                   kbESC: begin if (Str = '') and ( InterfaceData.Options and ouiEsc <> 0 )
                                            then Message(Application, evCommand, cmShowUserScreen, nil)
                                            else Str := ''; CurX := 0; DeltaX := 0; CE2 end;
                   kbBack: begin if CurX > 0 then begin Delete(Str, CurX, 1); Dec(CurX); end; CE2 end;
                   kbUp, kbCtrlE: begin
                                  if StrModified then
                                   begin
                                    AddCommand(Str);
                                    CurString := CmdStrings^.Count-1;
                                    StrModified := Off;
                                   end;
                                  if CurString > 0 then Dec(CurString);
                                  Str := GetCommand(CurString);
                                  Changed := True; CurX := Length(Str);
                                  CE2;
                                end;
                   kbDown, kbCtrlX: begin
                                    if StrModified then
                                     begin
                                       AddCommand(Str);
                                       CurString := CmdStrings^.Count;
                                       StrModified := Off;
                                     end;
                                     Str := GetCommand(CurString);
                                     if Str <> '' then Inc(CurString);
                                     Str := GetCommand(CurString);
                                     Changed := True; CurX := Length(Str);
                                     CE2;
                                  end;
                   kbLeft, kbCtrlS: begin if CurX > 0 then Dec(CurX); CE2 end;
                   kbRight, kbCtrlD: begin if CurX < Length(Str) then Inc(CurX); CE2 end;
                   kbCtrlIns: begin
                               Message(Application, evCommand, cmPutInClipboard, @Str);
                               CE;
                              end;
                   kbShiftIns: if ShiftState and 4 = 0 then begin
                                 S := '';
                                 Message(Application, evCommand, cmGetFromClipboard, @S);
                                 if S <> '' then
                                    Message(@Self, evCommand, cmInsertName, @S);
                                 CE2;
                               end else
                               begin
                                 Message(Application, evCommand, cmPutInClipboard, @Str);
                                 CE;
                               end;
                   kbIns: begin Overwrite := not Overwrite; CE2 end;
                   kbDel: begin Delete(Str, CurX + 1, 1); CE2 end;
                   kbEnd, kbCtrlEnd: begin CurX := Length(Str); CE2 end;
                   kbHome, kbCtrlHome: begin CurX := 0; CE2 end;
                   kbCtrlLeft: begin
                                if not (Str[CurX] in Separators) then
                                   While (CurX > 0) and not (Str[CurX] in Separators) do Dec(CurX)

                                  else
                                  begin
                                   While (CurX > 0) and (Str[CurX] in Separators) do Dec(CurX);
                                   While (CurX > 0) and not (Str[CurX] in Separators) do Dec(CurX)
                                  end;
                                CE2;
                               end;
                   kbEnter: Message(Application, evCommand, cmExecCommandLine, nil);
                   kbCtrlRight: begin
                                if not (Str[CurX+1] in Separators) then
                                  begin
                                   While (CurX < Length(Str)) and not (Str[CurX+1] in Separators) do Inc(CurX);
                                   While (CurX < Length(Str)) and (Str[CurX+1] in Separators) do Inc(CurX);
                                  end
                                  else
                                   While (CurX < Length(Str)) and (Str[CurX+1] in Separators) do Inc(CurX);
                                CE2;
                               end;
                  end;
                end;
               CheckSize;
             end;
 end;
 if Changed then StrModified := False else StrModified := (S <> Str);
end;


(*
constructor TCmdWindow.Init;
begin
 inherited Init(R, 'Command Line', 0);
 GetExtent(R);
 Palette := wpCyanWindow;
 R.Grow(-1, -1);
 Insert(New(PCmdLine, Init(R)));
end;

procedure TCmdLine.Draw;
 var B: TDrawBuffer;
     I: Integer;
     S: String;
begin
end;
*)


END.