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

unit FlPanel;

interface
uses Objects, Views, Drivers, Dos, Eraser, FilesCol, HideView,
     Drives, FLPanelX, DNHelp, ObjType;

type
    PSeparator=^TSeparator;
    TSeparator = object(THideView)
     OldX, OldW: Integer;
     constructor Init(R: TRect; AH: Integer);
     procedure HandleEvent(var Event: TEvent); virtual;
     procedure Draw; virtual;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
    end;

    PFilePanel = ^TFilePanel;
    TFilePanel = object(TFilePanelRoot)
     procedure Draw; virtual;
     procedure SetState(AState: Word; Enable: Boolean); virtual;
     procedure HandleEvent(var Event: TEvent); virtual;
     function GetPalette: PPalette; virtual;
     procedure GetFull(var B; P: PFileRec; C: Word); virtual;
     procedure DrawTop(var B); virtual;
    end;

    PInfoView = ^TInfoView;
    TInfoView = object(THideView)
     Panel: PFilePanel;
     constructor Init(R: TRect);
     procedure Draw; virtual;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     function GetPalette: PPalette; virtual;
     procedure HandleEvent(var Event: TEvent); virtual;
    end;

    PTopView = ^TTopView;
    TTopView = object(THideView)
     Panel: PFilePanel;
     procedure HandleEvent(var Event: TEvent); virtual;
     procedure Draw; virtual;
     constructor Load(var S: TStream);
     function GetPalette: PPalette; virtual;
     procedure Store(var S: TStream);
    end;

    PSpecScroll = ^TSpecScroll;
    TSpecScroll = object(TScrollBar)
     procedure HandleEvent(var Event: TEvent); virtual;
    end;

    PDriveLine = ^TDriveLine;
    TDriveLine = object(THideView)
      Panel: PFilePanel;
      DriveLine: String[29];
      constructor Init(var R: TRect; APanel: PFilePanel);
      procedure MakeDriveLine;
      function GetPalette: PPalette; virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure Draw; virtual;
      constructor Load(var S: TStream);
      procedure Store(var S: TStream);
    end;

const
      RFilePanel: TStreamRec = (
       ObjType: otFilePanel;
       VmtLink: Ofs(TypeOf(TFilePanel)^);
       Load: @TFilePanel.Load;
       Store: @TFilePanel.Store);

      RInfoView: TStreamRec = (
       ObjType: otFlPInfoView;
       VmtLink: Ofs(TypeOf(TInfoView)^);
       Load: @TInfoView.Load;
       Store: @TInfoView.Store);

      RTopView: TStreamRec = (
       ObjType: otTopView;
       VmtLink: Ofs(TypeOf(TTopView)^);
       Load: @TTopView.Load;
       Store: @TTopView.Store);

      RSeparator: TStreamRec = (
       ObjType: otSeparator;
       VmtLink: Ofs(TypeOf(TSeparator)^);
       Load: @TSeparator.Load;
       Store: @TSeparator.Store);

      RSpecScroll: TStreamRec = (
       ObjType: otSpecScroll;
       VmtLink: Ofs(TypeOf(TSpecScroll)^);
       Load: @TSpecScroll.Load;
       Store: @TSpecScroll.Store);

      RDriveLine: TStreamRec = (
       ObjType: otDriveLine;
       VmtLink: Ofs(TypeOf(TDriveLine)^);
       Load: @TDriveLine.Load;
       Store: @TDriveLine.Store);

       CPanel = #6#7#8#9#10#32#33#34#35#36#37#38#39#40;
       CTopView = #11#12;
       CInfoView  = #25#26#27#28#29#30#31;
       CDriveLine = #41#42#43;

VAR
  ActivePanel: Pointer absolute FlPanelX.ActivePanel;
  CtrlWas: Boolean absolute FlPanelX.CtrlWas;
  DirsToChange: Array [0..9] of PString absolute FlPanelX.DirsToChange;

VAR
  CurrentDirectory: PathStr absolute FLPanelX.CurrentDirectory;

implementation

uses DNApp, Advance, Startup, Memory, FileCopy, Messages, Menus, DiskInfo,
     Dialogs, Commands, HistList, Tree, FBB, RStrings, UUCode,
     ArcView, CmdLine, Histries, Archiver, Gauges, Gauge, FileFind, FlTools;

const
    chTempDrive = '*';

procedure TSpecScroll.HandleEvent;
begin
 if (Event.What = evKeyDown) and
    ((Event.CharCode in [^E,^S,^D,^X]) or
     (Event.CharCode = #0) and ((mem[0:$417] and 3 <> 0) xor
     (FMSetup.Options and fmoUseArrows = 0) and
     ((Event.KeyCode = kbRight) or (Event.KeyCode = kbLeft) or
      (Event.KeyCode = kbHome) or (Event.KeyCode = kbEnd)
     )))
     then Exit;
 inherited HandleEvent(Event);
end;

constructor TDriveLine.Init;
begin
  inherited Init(R);
  Panel := APanel;
  EventMask := evMouse or evBroadcast;
  MakeDriveLine;
end;

constructor TDriveLine.Load(var S: TStream);
begin
  inherited Load(S);
  MakeDriveLine;
  GetPeerViewPtr(S, Panel);
end;

procedure TDriveLine.MakeDriveLine;
 var C: Char;
     I: Byte;
begin
  DriveLine := '';
  for C := 'A' to 'Z' do
    if ValidDrive(C) then DriveLine :=  DriveLine+ C;
  DriveLine := DriveLine + chTempDrive;
end;

function TDriveLine.GetPalette;
 const S: String[Length(CDriveLine)] = CDriveLine;
begin
 GetPalette := @S;
end;

procedure TDriveLine.Draw;
  var B: TDrawBuffer;
      S: String;
      M: Byte absolute DriveLine;
      I: Integer;
begin
  I := M*2+3;
  if (Panel^.Size.X >= I) then
   begin
     if (Size.X <> I) then begin GrowTo(I, 1); Exit; end;
     S := '';
     for I := 1 to Length(DriveLine) do
        S := S + ' ' + DriveLine[I];
     S := '['+ S + ' ]';
   end else
    begin
      I := 2+M;
      if (Size.X <> I) then begin GrowTo(I, 1); Exit; end;
      S := '['+DriveLine + ']';
    end;
  if (Panel^.DirectoryName[2] = ':') or (Panel^.Drive^.DriveType = dtTemp) then
    begin
      if (Panel^.Drive^.DriveType = dtTemp) and (Panel^.DirectoryName = cTEMP_) then I := PosChar(chTempDrive, S)
        else I := PosChar(Panel^.DirectoryName[1], S);
      if I > 0 then
       begin
         System.Insert('~', S, I + 1);
         System.Insert('~', S, I);
       end else
       begin
         MakeDriveLine;
         Draw; Exit;
       end;
    end;
  MoveCStr(B, S, GetColor($0301));
  WordRec(B[0]).Hi := GetColor(2);
  WordRec(B[Size.X-1]).Hi := GetColor(2);
  WriteLine(0,0,Size.X,1,B);
end;

procedure TDriveLine.HandleEvent;
  var S: String;
      M: Byte absolute DriveLine;
      I: Integer;
      P: TPoint;

 procedure MakeDLine;
   var I: Integer;
 begin
    I := M*2+3;
    if (Panel^.Size.X >= I) then
      begin
        S := '';
        for I := 1 to M do
           S := S + ' ' + DriveLine[I];
        S := '['+ S + ' ]';
      end else S := '['+DriveLine + ']';
 end;

begin
  inherited HandleEvent(Event);
  case Event.What of
    evBroadcast: case Event.Command of
                   cmDropped: if MouseInView(PCopyRec(Event.InfoPtr)^.Where) then
                                begin
                                  Event.What := evNothing;
                                  ClrIO;
                                  MakeDLine;
                                  MakeLocal(PCopyRec(Event.InfoPtr)^.Where, P);
                                  case S[P.X+1] of
                                    chTempDrive: S := cTEMP_;
                                    'A'..'Z': S := S[P.X+1]+':';
                                    else Exit;
                                  end;
                                  CopyDirName := S;
                                  SkipCopyDialog := Confirms and cfMouseConfirm = 0;
                                  Message(PCopyRec(Event.InfoPtr)^.Owner, evBroadcast, cmCopyCollection,
                                          PCopyRec(Event.InfoPtr)^.FC);
                                  SkipCopyDialog := Off;
                                end;
                 end;
    evMouseDown: begin
                   ClrIO;
                   MakeDLine;
                   MakeLocal(Event.Where, P);
                   case S[P.X+1] of
                     chTempDrive: begin
                                    S := cTEMP_;
                                    Message(Panel, evCommand, cmChangeDrv, @S);
                                  end;
                     'A'..'Z': begin
                                 S := S[P.X+1]+':';
                                 Message(Panel, evCommand, cmChangeDrv, @S);
                               end;
                     '[': Message(Owner, evCommand, cmHideLeft, nil);
                     ']': Message(Owner, evCommand, cmHideRight, nil);
                   end;
                   While MouseEvent(Event, evMouseMove + evMouseAuto) do;
                   ClearEvent(Event);
                 end;
  end;
end;

procedure TDriveLine.Store(var S: TStream);
begin
  inherited Store(S);
  PutPeerViewPtr(S, Panel);
end;

{                                 TFilePanel
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function TFilePanel.GetPalette;
 const S: String[Length(CPanel)] = CPanel;
begin
 GetPalette := @S;
end;

var Idx, CurPos, I, J: Integer;
    C, C1, C2, C3, C4, C5, C6, C7: Byte;
    B: Array[0..300] of Word;
    B1: Array[0..200] of record C: Char; A: Byte; end absolute B;

procedure TFilePanel.GetFull;
begin
  Drive^.GetFull(B, P, C, ShowFlags);
end;

procedure TFilePanel.DrawTop;
 var S: String;
     I,J: Integer;
     C: Word;
begin
 Drive^.MakeTop(S, ShowFlags);
 I := 0; C := GetColor($0206);
 J := CStrLen(S);
 While I < Size.X do
  begin
   MoveCStr(TWordArray(B)[I], S, C);
   Inc(I, J);
  end;
end;

procedure TFilePanel.SetState;

  procedure MakeChange;
   var Event: TEvent;
       A: Boolean;
  begin
     CurrentDirectory := DirectoryName; ClrIO;
     NeedAbort := On;
     ChDir(CurrentDirectory);
     A := Abort;
     ActivePanel := @Self;
     {
     if IOresult<>0 then
      begin
        DriveState := dsInvalid ;
        exit;
      end;
     }
     DriveState := dsActive ;

     NeedAbort := Off;
     Message(CommandLine, evCommand, cmRereadInfo, nil);
     if (ActiveDir <> DirectoryName) or A then
      begin
       Drive^.Chdir(ActiveDir);
       ReadDirectory;
       CurrentDirectory := DirectoryName;
       Event.What := evKeyDown;
       Event.KeyCode := kbTab;
       Event.InfoPtr := nil;
       PutEvent(Event);
       PutEvent(Event);
      end;
     Message(Owner, evCommand, cmChangeTree, @DirectoryName);
  end;

var
  DoDraw: Boolean;

begin
  inherited SetState(AState, Enable);
  DoDraw := OFF;
  If QuickSearch and ( AState and ( sfFocused + sfActive + sfVisible + sfSelected ) <> 0 ) and not Enable then begin
    DoDraw := ON;
    QuickSearch := OFF
  end;
  if (AState and sfActive <> 0) then
    if not Enable then begin
      DisableCommands(PanelCommands);
      if not GetState(sfActive + sfSelected) and
         (ScrollBar <> nil) and ScrollBar^.GetState(sfVisible) then
           ScrollBar^.Hide;
      DoDraw := ON;
    end else EnableCommands(PanelCommands); ;
  if (AState and sfFocused and State <> 0) then
    if Enable then begin
      DoDraw := ON;
      if ScrollBar <> nil then begin
        ScrollBar^.Show;
        ScrollBar^.Options := ScrollBar^.Options or ofPostProcess;
      end;
      if InfoView <> nil then InfoView^.DrawView;
      if DirView <> nil then DirView^.DrawView;
      if (Drive^.DriveType = dtDisk) then begin
        ActivePanel := @Self;
        AddToDirectoryHistory(DirectoryName);
        if CurrentDirectory <> DirectoryName
          then MakeChange;
      end else
      if Drive^.DriveType = dtArc
        then Drive^.ChDir(#0);
      EnableCommands(PanelCommands);
    end;
  if GetState(sfFocused) then begin
    if AState and sfFocused <> 0 then DrawView;
    EnableCommands(PanelCommands);
    if (ScrollBar <> nil) and not ScrollBar^.GetState(sfVisible) then begin
      ScrollBar^.Show;
      ScrollBar^.Options := ScrollBar^.Options or ofPostProcess;
    end;
  end;
  if AState and (sfSelected+sfActive) <> 0 then
    if GetState(sfSelected+sfActive) then begin
      if (Drive^.DriveType = dtDisk)
        then MakeChange
        else
      if Drive^.DriveType = dtArc
        then Drive^.ChDir(#0);
      DoDraw := ON;
      EnableCommands(PanelCommands)
    end else begin
      if ScrollBar <> nil then begin
        ScrollBar^.Hide;
        ScrollBar^.Options := ScrollBar^.Options and (not ofPostProcess);
      end;
      DoDraw := ON;
      if InfoView <> nil then InfoView^.DrawView;
      if DirView <> nil then DirView^.DrawView;
    end;
  If DoDraw then begin
    PosChanged := OFF;
    DrawView;
  end;
end;

procedure TFilePanel.Draw;
 label 1;
 var P: PFileRec;
     CW: Word;
     PgS: Word;
     S,S1: String;
     HLC: Array[0..ttCust5] of Byte;
     PB: ^Byte;
     TagC: Char;

 procedure DrawAtIdx;
  var P: PFileRec;
      CC: Byte;
      JJ: Integer;
 begin
   JJ := J*LineLength;
   if (Files <> nil) and (Idx < Files^.Count) then
    begin
      P := Files^.At(Idx);
      CC := HLC[P^.TType];
      if (Idx = CurPos) then begin LastCurPos.X := JJ; LastCurPos.Y := I+1 end;
      asm
       les bx, P
       mov ax, Idx
       cmp ax, CurPos
       jne @@1
       mov al, C4
       cmp es:[bx].TFileRec.Selected, 0
       je  @@2
       mov al, C5
       jmp @@2
     @@1:
       mov al, CC
       cmp es:[bx].TFileRec.Selected, 0
       je  @@2
       mov al, C3
     @@2:
       mov C, al
      end;
      if QuickSearch then if (Idx = CurPos) then
        begin SetCursor(JJ+SearchX, I); ShowCursor; NormalCursor end;
      if LineLength = 13 then
      asm
       les bx, P
       lea di, B
       mov ax, J
       mov cx, 26
       mul cx
       add di, ax
       mov cx, 12
       mov ah, C
       lea bx, [bx].TFileRec.Name+1
     @@3:
       mov al, es:[bx]
       inc bx
       mov ds:[di], ax
       add di,2
       dec cx
       jnz @@3
      end else begin
        MoveChar(B[JJ], ' ', C, LineLength);
        GetFull(B[JJ], P, C);
      end;
      {
      if P^.Attr and Hidden <> 0 then
         if P^.Attr and SysFile = 0 then WordRec(B[JJ+8]).Lo := Byte( '±' )
                                    else WordRec(B[JJ+8]).Lo := Byte( '²' );
      }
      if (FMSetup.Show and fmsTagChar <> 0) and P^.Selected then begin
        WordRec(B[JJ+8]).Lo := Byte( TagC );
        PB := @WordRec(B[JJ+8]).Hi;
        If ( PB^ shr 4 ) <> ( CC and $0F )
          then PB^ := ( PB^ and $F0 ) + ( CC and $0F );
      end
    end else
      MoveChar(B[JJ], ' ', C1, LineLength);
 end;

begin
 if DrawDisableLvl > 0 then Exit;
 if DrawDisableLvl < 0 then DrawDisableLvl := 0;
 LineLength := Drive^.CalcLength(ShowFlags);

 if (DriveState and dsInvalid>0) then
    begin
      C1 := GetColor(1);  { Normal }
     for I := 0 to Pred(Owner^.Size.Y) do
      begin
         MoveChar(B, ' ', C1, Size.X);
         WriteLine(0, I, Owner^.Size.X, 1, B[0]);
      end;
     Exit ;
   end;

 if Size.X > LineLength - 1 then DeltaX := 0;
 if OldDirectory <> DirectoryName then
  begin
   if (OldDirectory[1] <> DirectoryName[1]) and (OldDirectory <> '')
      then ScrollBar^.SetValue(0);
   PosChanged := Off;
   DecDrawDisabled; OldDirectory := DirectoryName;
  end;
 C1 := GetColor(1);  { Normal }
 C2 := GetColor(2);  { Separator }
 C3 := GetColor(3);  { Selected }
 C4 := C1;
 C5 := C3;
 HLC[0] := C1;
 if FMSetup.TagChar <> '' then TagC := FMSetup.TagChar[1]
                          else TagC := 'û';
 if PanelFlags and fmiHiliteFiles <> 0 then
      for I := 1 to ttCust5 do HLC[I] := GetColor(6+I)
    else for I := 1 to ttCust5 do HLC[I] := C1;
 CW := 179+C2 shl 8;
 PgS := (Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0))*((Size.X+1) div LineLength);
 if PgS = 0 then PgS := (Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0));
 ScrollBar^.PgStep := PgS;
 if Delta < 0 then Delta := 0;
 if {GetState(sfSelected) and} (Files^.Count > 0)
  then
   begin
    CurPos := ScrollBar^.Value;
    if CurPos < Delta then Delta := CurPos;
    if CurPos >= Delta + PgS then Delta := CurPos - PgS + 1;
   end else CurPos := -1;
 if GetState(sfFocused) then
  begin
    C4 := GetColor(4);  { Normal cursor }
    C5 := GetColor(5);  { Selected cursor }
  end else if CurPos >= 0 then
   begin
     P := Files^.At(CurPos);
     if PanelFlags and fmiHiliteFiles <> 0 then C4 := HLC[P^.TType];
   end;
 if not QuickSearch then HideCursor;
 if PosChanged and (OldDelta = Delta) then
  begin
   if CurPos <> OldPos then
    begin
     for I := Byte(FMSetup.Show and fmsColumnTitles <> 0) to Size.Y - 1 do
      for J := 0 to Size.X div LineLength do
       begin
        Idx := I - Byte(FMSetup.Show and fmsColumnTitles <> 0) +
               J * (Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0)) + Delta;
        if (Idx = CurPos) or (Idx = OldPos) then
         begin
          MoveChar(B, ' ', C1, Size.X);
          DrawAtIdx;
          Idx := (J+1)*LineLength;
          if LineLength > 13 then Drive^.GetEmpty(B[Idx - LineLength], CW, ShowFlags);
          if Idx < Size.X then B[Idx - 1] := CW;
          Idx := J*LineLength;
          WriteLine(Idx, I, LineLength-1, 1, B[Idx+DeltaX]);
         end;
       end;
    end else Goto 1;
   PosChanged := Off;
   OldDelta := Delta; OldPos := CurPos;
   Exit;
  end;
1:
 OldDelta := Delta; OldPos := CurPos;
 PosChanged := Off;
 if (FMSetup.Show and fmsColumnTitles <> 0) then
  begin
    DrawTop(B);
    if WordRec(B[Size.X - 1]).Lo = 179 then WordRec(B[Size.X - 1]).Lo := 32;
    WriteLine(0, 0, Size.X, 1, B[DeltaX]);
  end;
 for I := Byte(FMSetup.Show and fmsColumnTitles <> 0) to Size.Y - 1 do
  begin
   MoveChar(B, ' ', C1, Size.X);
   for J := 0 to Size.X div LineLength do
    begin
     Idx := I - Byte(FMSetup.Show and fmsColumnTitles <> 0) +
            J*(Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0)) + Delta;
     DrawAtIdx;
     Idx := (J+1)*LineLength;
     if LineLength > 13 then Drive^.GetEmpty(B[Idx - LineLength], CW, ShowFlags);
     if Idx < Size.X then B[Idx - 1] := CW;
    end;
   if ShowFlags <> 0 then Drive^.GetEmpty(B, CW, ShowFlags);
   WriteLine(0, I, Size.X, 1, B[DeltaX]);
  end;
end;

{                                 TInfoView
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
constructor TInfoView.Init;
begin
 inherited Init(R);
 EventMask := evMouse;
end;

constructor TInfoView.Load;
begin
 inherited Load(S);
 GetPeerViewPtr(S, Panel);
end;

procedure TInfoView.Store;
begin
 inherited Store(S);
 PutPeerViewPtr(S, Panel);
end;

procedure TInfoView.HandleEvent;
 var P: TPoint;
     Y: Integer;
     Mover: PView;
     S: String;
     FC: PFilesCollection;
     C: TCopyRec;

 procedure CE; begin ClearEvent(Event) end;

 procedure DragCurrent;
 begin
  with Panel^ do
   begin
    S:=MakeFileName(PFileRec(Files^.At(ScrollBar^.Value))^.Name);
    if S[1] = '.' then Exit;
   end;
  New(FC, Init(1, 100));
  FC^.Insert(CopyFileRec(Panel^.Files^.At(Panel^.ScrollBar^.Value)));
  if P.X < Length(S) then Dec(P.X);
  MakeGlobal(P, P);
  DragMover(@P, S, FC, @C);
  CE;
 end;

 procedure DragSelected;
  var I: Integer;
      PF: PFileRec;
 begin
  if Panel^.SelNum = 0 then Exit;
  New(FC, Init(Panel^.SelNum, 100));
  for I := 1 to Panel^.Files^.Count do
   begin
    PF := Panel^.Files^.At(I-1);
    if PF^.Selected then FC^.Insert(CopyFileRec(PF));
   end;
  MakeGlobal(P, P);
  DragMover(@P, ItoS(Panel^.SelNum)+GetString(dlSelectedFiles), FC, @C);
  CE;
 end;

 procedure DragTotals;
  var I: Integer;
      PF: PFileRec;
 begin
  New(FC, Init(Panel^.SelNum, 100));
  for I := 1 to Panel^.Files^.Count do
   begin
    PF := Panel^.Files^.At(I-1);
    if PF^.Name[1] <> '.' then FC^.Insert(CopyFileRec(PF));
   end;
  MakeGlobal(P, P);
  DragMover(@P, ItoS(Panel^.Files^.Count)+' '+GetString(dlDIFiles), FC, @C);
  CE;
 end;

begin
 inherited HandleEvent(Event);
 if Event.What and (evMouseDown + evMouseAuto) <> 0 then
  begin
   if Panel^.Files^.Count = 0 then Exit;
   C.Owner := Panel;
   MakeLocal(Event.Where, P); Y := 0;
   if FMSetup.Show and fmsDivider <> 0 then
    begin if Y = P.Y then
            begin
             if Panel^.GetState(sfActive+sfSelected) then
              begin
               with Panel^ do
                begin
                 if Files^.Count = 0 then Exit;
                 MSelect := Event.Buttons and mbRightButton <> 0;
                 if MSelect then
                  begin
                    SelectFlag := not PFileRec(Files^.At(ScrollBar^.Value))^.Selected;
                    Message(Panel, evKeyDown, kbIns, nil);
                  end;
                end;
               RepeatDelay := 0;
               repeat
                Message(Owner, evKeyDown, kbDown, nil);
               until not MouseEvent(Event, evMouseMove + evMouseAuto);
               RepeatDelay := 2; Panel^.MSelect := Off;
              end;
             Exit
            end;
          Inc(Y);
    end;
   if Panel^.PanelFlags and fmiCurrent <> 0 then
    begin if Y = P.Y then begin DragCurrent; Exit end; Inc(Y);end;
   if Panel^.PanelFlags and fmiSelected <> 0 then
    begin if Y = P.Y then begin DragSelected; Exit end; Inc(Y);end;
   if Panel^.PanelFlags and fmiTotals <> 0 then
    begin if Y = P.Y then begin DragTotals; Exit end; Inc(Y);end;
   CE;
  end;
end;

procedure TInfoView.Draw;
 label 1;
 var B: Array [0..600] of Word;
     B1: Array[0..127] of record C: Char; A: Byte; end absolute B;
     I: Integer;
     C1, C2, C3: Word;
     PF, PPF: PFileRec;
     S, S1: String;
     Y: Integer;

 var FR: TFileRec;

begin
 if Panel^.DrawDisableLvl > 0 then Exit;
 C2 := Panel^.GetColor(2); I := Size.X;
 C1 := Panel^.LineLength;
 if I < C1 then I := C1;
 Dec(C1);
 Y := 0;
 if FMSetup.Show and fmsDivider <> 0 then
 begin
  Y := 1;
  asm
   lea di, B
   mov cx, I
   mov ah, byte ptr C2
 @@1:
   mov dl, byte ptr C1
   mov al, 'Ä'
 @@2:
   mov ss:[di], ax
   inc di
   inc di
   dec cx
   jz  @@4
   dec dl
   jnz @@2
   mov al, 'Á'
   cmp cx, 1
   jnz @@3
   mov al, 'Ä'
 @@3:
   mov ss:[di], ax
   inc di
   inc di
   loop @@1
 @@4:
  end;
  I := 0; C2 := (C2 shl 8) or Byte('Á');
  if Panel^.LineLength > 13 then
  While I < Size.X do
   begin
    Panel^.Drive^.GetEmpty(B[I], C2, Panel^.ShowFlags);
    Inc(I, Panel^.LineLength);
   end;
  WriteLine(0,0,Size.X,1,B[Panel^.DeltaX]);
 end;

 C1 := GetColor(1);
 if Panel^.PanelFlags and fmiCurrent <> 0 then
 begin
   if (Panel^.SelNum > 0) and (Panel^.PanelFlags and fmiSelected = 0) then Goto 1;
   MoveChar(B, ' ', C1, Size.X);
   if Panel^.ScrollBar^.Value < Panel^.Files^.Count then
    begin
      PF := Panel^.Files^.At(Panel^.ScrollBar^.Value);
      Panel^.Drive^.GetDown(B, C1, PF);
    end;
   WriteLine(0,Y,Size.X,1,B);
   Inc(Y);
   if (Panel^.Drive^.DriveType = dtFind) or (Panel^.Drive^.DriveType = dtTemp) then
    begin
     MoveChar(B, ' ', C1, Size.X);
     if Panel^.ScrollBar^.Value < Panel^.Files^.Count then MoveStr(B, PF^.Owner^, C1);
     WriteLine(0,Y,Size.X,1,B);
     Inc(Y);
    end else
    if (Panel^.Drive^.DriveType = dtArc) then
     begin
      MoveChar(B, ' ', C1, Size.X);
      C3 := GetColor($0302);
      if PF^.Size = 0 then S := '100%' else S := ItoS(Percent(PF^.Size, PF^.PSize))+'%';
      if Panel^.ScrollBar^.Value < Panel^.Files^.Count then
         MoveCStr(B, GetString(dlArcPSize) + ' ' + AddSpace(FStr(PF^.PSize),14) +
                  GetString(dlArcRatio) + S, C3);
      WriteLine(0,Y,Size.X,1,B);
      Inc(Y);
     end;
 end;

 if Panel^.PanelFlags and fmiSelected <> 0 then
  begin
1:
    C3 := GetColor($0302);
    MoveChar(B, ' ', C3, Size.X);
    if Panel^.SelNum = 0 then S := GetString(dlNoFilesSelected)
     else begin
           if (Panel^.SelectedLen = Panel^.PackedLen) or (Panel^.Drive^.DriveType <> dtArc) then
            S := '~'+FStr(Panel^.SelectedLen)+GetString(dlBytesIn)+
                 +ItoS(Panel^.SelNum)+'~'+ GetString(dlSelectedfiles) else
            S := '~'+FStr(Panel^.SelectedLen)+'('+FStr(Panel^.PackedLen)+')'+GetString(dlBytesIn)+
                +ItoS(Panel^.SelNum)+'~'+ GetString(dlSelectedfiles);
          end;
    I := (Size.X - CStrLen(S)) div 2; if I < 0 then I := 0;
    MoveCStr(B[I], S, C3);
    WriteLine(0,Y,Size.X,1,B);
    Inc(Y);
  end;

 if Panel^.PanelFlags and fmiTotals <> 0 then
  begin
    C3 := GetColor($504);
    MoveChar(B, ' ', C3, Size.X);
    I := (Size.X - CStrLen(Panel^.TotalInfo)) div 2; if I < 0 then I := 0;
    MoveCStr(B[I], Panel^.TotalInfo, C3);
    WriteLine(0,Y,Size.X,1,B);
    Inc(Y);
  end;

 if Panel^.PanelFlags and fmiFree <> 0 then
  begin
    C3 := GetColor($706);
    MoveChar(B, ' ', C3, Size.X);
    I := (Size.X - CStrLen(Panel^.FreeSpace)) div 2; if I < 0 then I := 0;
    MoveCStr(B[I], Panel^.FreeSpace, C3);
    WriteLine(0,Y,Size.X,1,B);
    Inc(Y);
  end;

 MoveChar(B, ' ', C1, Size.X);
 WriteLine(0, Y, Size.X, Size.Y - Y,B);
end;

function TInfoView.GetPalette;
 const S: String[Length(CInfoView)] = CInfoView;
begin
 GetPalette := @S;
end;

{ ---------------------------- TTopView ------------------------------ }

constructor TTopView.Load;
begin
 inherited Load(S);
 GetPeerViewPtr(S, Panel);
end;

procedure TTopView.Store;
begin
 inherited Store(S);
 PutPeerViewPtr(S, Panel);
end;

function TTopView.GetPalette;
 const S: String[Length(CTopView)] = CTopView;
begin
 GetPalette := @S;
end;

procedure TTopView.Draw;
 var C: Word;
     B: TDrawBuffer;
     I: Integer;
     S: String;
     R: TRect;
begin
 C := GetColor(1); if not Panel^.GetState(sfSelected) then C := GetColor(2);
 MoveChar(B, ' ', C, Size.X); S := Panel^.DirectoryName;
 if Length(S) > Panel^.Size.X - 10  then
  begin
   Delete(S, PosChar(':', S) + 2, Length(S) - Panel^.Size.X + 13);
   Insert('...', S, PosChar(':', S) + 2);
  end;
 if Length(S) + 2 <> Size.X then
  if Length(S) < Panel^.Size.X - 2 then
  begin
   R.A := Panel^.Origin; R.B.Y := R.A.Y; Dec(R.A.Y);
   Inc(R.A.X, (Panel^.Size.X - Length(S) - 2) div 2);
   R.B.X := R.A.X + Length(S) + 2;
   Locate(R); Exit;
  end else GrowTo(0, 1);
 if Length(S) > Size.X then I := 0 else I := (Size.X - Length(S)) div 2;
 MoveStr(B[I], S, C);
 WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TTopView.HandleEvent;
 var S: String;
     I: Integer;
     P: TPoint;
begin
 inherited HandleEvent(Event);
 case Event.What of
  evMouseDown: begin
                MakeLocal(Event.Where, P);
                S := Panel^.DirectoryName;
                {if Length(S) > Size.X then
                 begin
                  Delete(S, 4, Length(S) - Size.X + 3);
                  Insert('...', S, 4);
                 end;}
                if Length(S) > Size.X then I := 0 else I := PosChar(':', S);
                { := (Size.X - Length(S)) div 2}
                repeat until not MouseEvent(Event, evMouseAuto + evMouseMove);
                ClearEvent(Event);
                if (P.X <= I)
                 then Message(Panel, evCommand, cmChangeDrive, nil)
                 else Message(Panel, evCommand, cmChangeDir, nil);
               end;
 end;
end;

{ --------------------------- TSeparator ----------------------------- }

constructor TSeparator.Load;
begin
 inherited Load(S);
 S.Read(OldX, 4);
end;

procedure TSeparator.Store;
begin
 inherited Store(S);
 S.Write(OldX, 4);
end;

constructor TSeparator.Init;
begin
 inherited Init(R);
 OldX := Origin.X+1;
 OldW := AH;
 EventMask := $FFFF;
end;

procedure TSeparator.HandleEvent;
 var P: TPoint;
     R: TRect;
     RD: Integer;
     B: Byte;
begin
 inherited HandleEvent(Event);
 case Event.What of
  evMouseDown: begin
                MakeLocal(Event.Where, P); B := P.X;
                RD := RepeatDelay; RepeatDelay := 0;
                repeat
                 Owner^.MakeLocal(Event.Where, P);
                 if (P.X >= 1) and (P.X < Owner^.Size.X-2) then
                  begin
                   OldX := P.X + 1 - B; OldW := Owner^.Size.X;
                   R.A := Owner^.Origin;
                   R.B.X := Owner^.Origin.X + Owner^.Size.X;
                   R.B.Y := Owner^.Origin.Y + Owner^.Size.Y;
                   Owner^.ChangeBounds(R);
                  end;
                until not MouseEvent(Event, evMouseAuto + evMouseMove);
                RepeatDelay := RD;
                ClearEvent(Event);
               end;
 end;
end;

procedure TSeparator.Draw;
 var B: Array[0..128] of record C: Char; B: Byte; end;
     C: Word;
     Ch: Char;
begin
 if Owner^.GetState(sfActive) then C := Owner^.GetColor(2)
                              else C := Owner^.GetColor(1);
 if Owner^.GetState(sfDragging) then C := Owner^.GetColor(3);
 B[0].B := C; B[Size.Y-1].B := C;
 if Owner^.GetState(sfActive) and not Owner^.GetState(sfDragging) then
  begin B[0].C := '»'; Ch := 'º'; B[Size.Y-1].C := '¼'; end
   else begin B[0].C := '¿'; Ch := '³'; B[Size.Y-1].C := 'Ù'; end;
 MoveChar(B[1], Ch, C, Size.Y-2);
 WriteBuf(0,0,1,Size.Y,B);
 if Owner^.GetState(sfActive) and not Owner^.GetState(sfDragging) then
  begin B[0].C := 'É'; B[Size.Y-1].C := 'È'; end
   else begin B[0].C := 'Ú'; B[Size.Y-1].C := 'À'; end;
 WriteBuf(1,0,1,Size.Y,B);
end;

{ FilePanel HandleEvent}

PROCEDURE TFilePanel.HandleEvent;
var
  PF: PFileRec;
  CurPos: Integer;
  PPC: PCollection;
  MPos: TPoint;
  LastRDelay: Word;
  I, J: Integer;
  PDr: PDrive;
  DotSearchMask: Str12;

 procedure CE;begin ClearEvent(Event) end;
 procedure CED;begin ClearEvent(Event); DrawView end;

 procedure CM_CopyUnselect;
  label 1;
  var PF: PFileRec;
      I, OSM: Integer;
 begin
  if (Files^.Count = 0) or (Event.InfoPtr = nil) then Exit;
  OSM := PFilesCollection(Files)^.SortMode;
  PFilesCollection(Files)^.SortMode := 100;
  for I := 0 to Files^.Count - 1 do
   if Files^.Compare(Files^.Items^[I], Event.InfoPtr) = 0 then Goto 1;
  PFilesCollection(Files)^.SortMode := OSM;
  Exit;
 1:
  PFilesCollection(Files)^.SortMode := 100;
  PF := {Event.InfoPtr}Files^.At(I);
  if PF^.Attr and Directory <> 0 then PF^.Size := -1;
  with PF^ do
   if Selected then
   begin
    Selected := Off;
    SelectedLen := SelectedLen - Size;
    PackedLen := PackedLen - PSize;
    Dec(SelNum)
  end;
  DrawView;
  if InfoView <> nil then InfoView^.DrawView;
 end;

 procedure MaskSearch(B: Byte);
 {
 var I, J: Integer;
 begin
  if Files^.Count = 0 then begin QuickSearch := Off; Exit; end;
  for I := CurPos+B to Files^.Count-1 do
   if InMask(PFileRec(Files^.At(I))^.Name, SearchMask) then
    begin ScrollBar^.SetValue(I); Exit end;
  for I := 0 to CurPos-1 do
   if InMask(PFileRec(Files^.At(I))^.Name, SearchMask) then
    begin ScrollBar^.SetValue(I); Exit end;
  I := CurPos;
  if InMask(PFileRec(Files^.At(I))^.Name, SearchMask)
    then begin If SearchX = 8 then Inc( SearchX ) end
    else Message(@Self, evKeyDown, kbBack, nil);
 }
 var
   I: Integer;
 begin
   I := CurPos + B; If I >= Files^.Count then I := 0;
   repeat
     If InMask( PFileRec( Files^.At( I ))^.Name, SearchMask ) then begin
       ScrollBar^.SetValue( I );
       If SearchX = 8 then Inc( SearchX );
       Exit;
     end;
     Inc( I ); If I >= Files^.Count then I := 0;
   until I = CurPos;
   If not InMask( PFileRec( Files^.At( CurPos ))^.Name, SearchMask )
     then Message( @Self, evKeyDown, kbBack, NIL );
 end;

 procedure DoMakeDirs(P: PFileRec); far;
 begin
   if (PF^.Attr and Directory <> 0) and (PF^.Size < 0) then
      begin PF^.Size := 0; PF^.Attr := PF^.Attr and $3F end;
 end;

 label lbMakeUp, GotoExt, GotoKb, lbMakeDown;

begin
 inherited HandleEvent(Event);
 CurPos := ScrollBar^.Value;
 if Files^.Count > CurPos then PF := Files^.At(CurPos) else PF := nil;
{                               }
{ inherited HandleEvent(Event); } { ALREADY CALLED FROM FLPANEL.PAS }
{                               }
 I := ShiftState;
 if (Event.What = evKeyDown) and (I and 3 <> 0) and
    ((Event.KeyCode = kbCtrlRight) or (Event.KeyCode = kbCtrlLeft) or (Event.KeyCode = kbBack))
      then begin CommandHandle(Event); Exit; end;
 if (Event.What = evKeyDown) and (CommandLine <> nil) then
  if ((I and 3 <> 0) and ((Event.KeyCode = kbDown) or (Event.KeyCode = kbUp)
         or (Event.KeyCode = kbCtrlIns) or (Event.KeyCode = kbGrayAst) )) or
    ((Event.ScanCode < (kbAlt1 shr 8)) or (Event.ScanCode > (kbAlt9 shr 8))) and
     (Event.CharCode = #0) and (CmdLine.Str <> '') and
     ((I and 3 <> 0) xor (FMSetup.Options and fmoUseArrows = 0) and
       ((Event.KeyCode = kbRight) or (Event.KeyCode = kbLeft) or
        (Event.KeyCode = kbHome) or (Event.KeyCode = kbEnd)))
      then CommandLine^.HandleEvent(Event);
 if Event.What = evNothing then Exit;
 I := mem[$40:$18];
 case Event.What of
  evCommand: case Event.Command of
              cmDoSendLocated: SendLocated;
              cmGetName: begin
                  if Drive^.DriveType = dtDisk
                    then PString(Event.InfoPtr)^ := DirectoryName
                      else if ScrollBar^.Value < Files^.Count then
                              PString(Event.InfoPtr)^ := PFileRec(Files^.At(ScrollBar^.Value))^.Owner^;
                  ClearEvent( Event );
                end;
              cmKillUsed: Drive^.KillUse;
              cmClose: CommandEnabling := Off;
              cmCopyUnselect: begin CM_CopyUnselect; CE end;
              cmRecountDirs: begin
                               if Files <> nil then files^.ForEach(@DoMakeDirs); CED;
                             end;
             (*
              cmQuickChange1..cmQuickChange9,
              cmPanelMakeList,
              cmPanelArchiveFiles,
              cmExtractArchive,
              cmReboundPanel,
              cmPrintFile,
              cmSetPassword,
              cmExtractTo,
              cmArcTest,
              cmRereadForced,
              cmMakeForced,
              cmEraseGroup,
              cmFindTree,
              cmInsertFile,
              cmViewText,
              cmViewHex,
              cmViewDBF,
              cmViewWKZ,
              cmInsertDrive,
              cmEditFile,
              cmIntViewFile,
              cmIntEditFile,
              cmViewFile,
              cmCountLen,
              cmSingleDel,
              cmGetFileName,
              cmTempCopyFiles,
              cmSortBy,
              cmPanelSetup,
              cmSetupColumns,
              cmTouchFile,
              cmCompareDir,
              cmPushFirstName,
              cmPanelCompare,
              cmPanelSelect,
              cmPanelUnselect,
              cmPanelXSelect,
              cmPanelXUnselect,
              cmCopyFiles,
              cmMoveFiles,
              cmSingleCopy,
              cmSingleRename,
              cmPanelInvertSel,
              cmPanelErase,
              cmPanelMkDir,
              cmRereadDir,
              cmTotalReread,
              cmForceRescan,
              cmPanelReread,
              cmPushName,
              cmMakeList,
              cmChangeDrive,
              cmChangeDrv,
              cmDirBranch,
              cmUUDecodeFile,
              cmUUEncodeFile,
              cmChangeDirectory,
              cmChangeDir,
              cmGetDirInfo,
              cmGetDirName,
              cmSetFAttr,
              cmPanelLongCopy,
              cmEnableView,
              cmDisableView,
              cmLViewFile,
              cmFindGotoFile,
              cmAdvancedFilter:*)
              0..100:;
                else CommandHandle(Event);
             end;
  evKeyDown: if (Event.KeyCode = kbDoubleAlt) and (FMSetup.Quick = pqsAlt) or
                (Event.KeyCode = kbDoubleCtrl) and (FMSetup.Quick = pqsCtrl) or
                (Event.CharCode >= #33) and (Event.CharCode <= #254) and (Event.CharCode <> '\')
                 and ((FMSetup.Quick = pqsCaps) and (I and $40 <> 0) or
                      (Event.CharCode >= #33) and (Event.CharCode <= #254)
                      and (ShiftState and 3 <> 0) and (ShiftState and 4 = 0)
                      and (not CommandLine^.GetState(sfVisible)
                           and (InterfaceData.Options and ouiHideCmdLine <> 0))) then
               begin
                CtrlWas := Off;
                SearchMask := '????????.???';
                QuickSearch := not QuickSearch;
                SearchX := 0;
                if (Event.CharCode >= #33) and (Event.CharCode <= #254) then
                 begin
                   if not ((ShiftState and 3 <> 0) and ( not CommandLine^.GetState(sfVisible))) then
                    begin
                      Mem[$40:$18] := I and $BF;
                      ShiftState := ShiftState and kbCapsState;
                    end else ShiftState := ShiftState and $FC;
                   SearchMask[1] := Event.CharCode;
                   SearchX := 1;
                   if QuickSearch then
                    begin
                     if (FMSetup.Quick = pqsCaps) and (I and kbCapsState <> 0) then
                        ShiftState := ShiftState and not kbCapsState;
                     MaskSearch(0);
                    end;
                 end;
                DrawView; CE;
               end
             else if QuickSearch and ((Event.CharCode > #32) or
                                      (Event.CharCode = #27) or
                                      (Event.CharCode = #10) or
                                      (Event.CharCode = #8) or
                                      (Event.KeyCode = kbIns)) then
                   begin
                    CtrlWas := Off;
                    if (Event.KeyCode = kbGrayPlus) or (Event.KeyCode = kbGrayMinus) or
                       (Event.KeyCode = kbGrayAst) or (Event.KeyCode = kbIns) then Goto GotoKb;
                    case Event.CharCode of
                     #27: begin QuickSearch := Off; CED; Exit end;
                     #8: If SearchX > 0 then repeat
                           If SearchX = 9 then Dec( SearchX );
                           SearchMask[ SearchX ] := '?';
                           Dec( SearchX );
                         until ( SearchX = 0 ) or
                               ( SearchX = 9 ) or
                               ( SearchMask[ SearchX ] <> ' ' );
                     #10: MaskSearch(1);
                     '\': begin
                           Event.What := evCommand;
                           Event.Command := cmChangeDir;
                           Event.InfoPtr := nil;
                           PutEvent(Event);
                           Event.What := evKeyDown;
                           for I := 1 to SearchX do
                            begin
                              Event.CharCode := SearchMask[I];
                              PutEvent(Event);
                            end;
                           CE; QuickSearch := Off; Exit;
                          end;
                     '.': If SearchX < 9 then begin
                            DotSearchMask := SearchMask;
                            repeat
                              Inc( SearchX );
                              If DotSearchMask[ SearchX ] = '?' then
                                DotSearchMask[ SearchX ] := ' ';
                            until SearchX = 9;
                            I := CurPos;
                            repeat
                              If InMask( PFileRec( Files^.At( I ))^.Name, DotSearchMask ) then begin
                                SearchMask := DotSearchMask;
                                ScrollBar^.SetValue( I );
                                Break;
                              end else begin
                                Inc( I );
                                If I >= Files^.Count then I := 0;
                              end;
                            until I = CurPos;
                          end;
                     else
                      begin
                       if SearchX < 12 then Inc(SearchX, 1+Byte(SearchX = 8));
                       SearchMask[SearchX] := Event.CharCode;
                       MaskSearch(0);
                      end;
                     end;
                    CED;
                   end else
                   begin
                    CtrlWas := Off;
                    if QuickSearch then begin QuickSearch := Off; DrawView end;
GotoKB:
                    case Event.KeyCode of
                     kbDel: if ((CmdLine.Str = '') and (FMSetup.Options and fmoDelErase <> 0)) then
                               Message(@Self, evCommand, cmPanelErase, nil);
                     {
                     kbShiftDel: if ((CmdLine.Str = '') and (FMSetup.Options and fmoDelErase <> 0)) then
                               Message(@Self, evCommand, cmSingleDel, nil);
                     }
                     kbHome: begin CE; DeltaX := 0; OldDelta := -1; ScrollBar^.SetValue(0); DrawView end;
                     kbEnd: begin CE; OldDelta := -1; ScrollBar^.SetValue(Files^.Count-1) end;
                     kbUp, kbDown, kbCtrlUp, kbCtrlDown
                          : begin
                               if Event.KeyCode = kbCtrlUp   then Event.KeyCode := kbUp;
                               if Event.KeyCode = kbCtrlDown then Event.KeyCode := kbDown;
                               CtrlWas := ShiftState and kbCtrlShift <> 0;
                            end;
                     kbIns,kbSpace: if CurPos < Files^.Count then
                            begin
                             QuickSearch := Off;
                             if (Event.CharCode = ' ') and ((CmdLine.Str <> '') or
                                (FMSetup.Options and fmoSpaceToggle = 0)) then Exit;
                             CE; if Files^.Count = 0 then Exit;
                             PF := Files^.At(CurPos);
                             if PF^.Name[1] <> '.' then
                             begin
                              PF^.Selected := not PF^.Selected;
                              SelectedLen := SelectedLen - (1-2*Integer(PF^.Selected))*PF^.Size;
                              PackedLen := PackedLen - (1-2*Integer(PF^.Selected))*PF^.PSize;
                              Dec(SelNum, 1-2*Integer(PF^.Selected));
                             end;
                             ScrollBar^.SetValue(CurPos + 1);
                             if CurPos = ScrollBar^.Value then DrawView;
                             if InfoView <> nil then InfoView^.DrawView;
                            end;
                     (*
                     kbAltIns,
                     kbGrayPlus,
                     kbGrayMinus,
                     kbGrayAst, kbCtrlGAst,
                     kbAlt1..kbAlt9,
                     kbAltEnter,
                     $1312,
                     $2B1C,
                     kbCtrlGPlus,
                     kbCtrlGMinus,
                     kbCtrlRight,
                     kbCtrlLeft,
                     kbCtrlDel,
                     kbCtrlIns,
                     kbCtrlEnter,
                     kbLeft,
                     kbRight,
                     kbEnter,
                     kbCtrlPgUp,
                     kbCtrlPgDn:*)
                       else CommandHandle(Event);
                    end;
             end;
  evBroadcast: case Event.Command of
                 cmGetCurrentPosFiles,
                 cmFindForced,
                 cmInsertDrive,
                 cmUnarchive,
                 cmCopyCollection,
                 cmDropped: CommandHandle(Event);

                 cmScrollBarChanged: if ScrollBar = Event.InfoPtr then begin
                                      if MSelect then
                                        begin
                                         CE; if Files^.Count = 0 then Exit;
                                         PF := Files^.At(ScrollBar^.Value);
                                         if (PF^.Name[1] <> '.') and (PF^.Selected xor SelectFlag) then
                                          begin
                                           PF^.Selected := SelectFlag;
                                           if SelectFlag then begin Inc(SelNum); SelectedLen := SelectedLen + PF^.Size;
                                                                    PackedLen := PackedLen + PF^.PSize end
                                                         else begin Dec(SelNum); SelectedLen := SelectedLen - PF^.Size;
                                                                    PackedLen := PackedLen - PF^.PSize end;
                                          end;
                                        end;
                                      PosChanged := On;
                                      if InfoView <> nil then InfoView^.DrawView;
                                      CED; PosChanged := Off;
                                      if (RepeatDelay <> 0) and (ViewEnabled or
                                         (Drive^.Flags and psShowLongDesc <> 0) and
                                         (Drive^.DriveType < dtArc)) then
                                        NeedLocated := GetSTime;
                                     end;
               end;
  evMouseDown: CommandHandle(Event);
 end;
end;


end.