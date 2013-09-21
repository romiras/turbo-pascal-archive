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

unit Histries;

interface
uses Drivers, Objects, Views, MicroEd, ObjType;

type
     PViewRecord = ^TViewRecord;
     TViewRecord = record
       fName: PString;
       fOrigin: TPoint;
       fSize: TPoint;
       fDeskSize: TPoint;
       fViewMode: Integer;
       fPos: LongInt;
       fBufPos: Word;
       fXlateTable: String[8];
       fFilter: Byte;
       fHexEdit: Boolean;
       fWrap: Boolean;
       fXDelta: Integer;
       fHexPos: Integer;
       fCur: TPoint;
     end;

     PEditRecord = ^TEditRecord;
     TEditRecord = record
       fName: PString;
       fOrigin: TPoint;
       fSize: TPoint;
       fDeskSize: TPoint;
       fPos: TPoint;
       fDelta: TPoint;
       fMarks: TPosArray;
       fBlockStart: TPoint;
       fBlockEnd: TPoint;
       fBlockVisible: Boolean;
       fVerticalBlock: Boolean;
       fHighlight: Byte;
       fHiliteColumn: Boolean;
       fHiliteLine: Boolean;
       fAutoIndent: Boolean;
       fAutoJustify: Boolean;
       fAutoBrackets: Boolean;
       fInsMode: Boolean;
       fLeftSide,
       fRightSide,
       fInSide: Integer;
     end;

     PEditHistoryCol = ^TEditHistoryCol;
     TEditHistoryCol = object(TCollection)
        function  IndexOf(P: Pointer): Integer; virtual;
        procedure PutItem(var S: TStream; P: Pointer); virtual;
        function  GetItem(var S: TStream): Pointer; virtual;
        procedure FreeItem(P: Pointer); virtual;
     end;

     PViewHistoryCol = ^TViewHistoryCol;
     TViewHistoryCol = object(TEditHistoryCol)
        procedure PutItem(var S: TStream; P: Pointer); virtual;
        function  GetItem(var S: TStream): Pointer; virtual;
        procedure FreeItem(P: Pointer); virtual;
     end;

procedure AddToDirectoryHistory(S: String);
procedure SaveCommands(var S: TStream);
procedure LoadCommands(var S: TStream);
procedure CmdHistory;
procedure InitCommands;
function  DirHistoryMenu: String;
procedure EditHistoryMenu;
procedure ViewHistoryMenu;
procedure StoreEditInfo(P: Pointer);
procedure StoreViewInfo(P: Pointer);
procedure AddCommand(LastCommand: String);
function  GetCommand(Idx: Integer): String;


const
      MaxDirHistorySize = 40;
      MaxEditHistorySize = 20;

      CmdStrings: PCollection = nil;
      DirHistory: PCollection = nil;
      EditHistory: PCollection = nil;
      ViewHistory: PCollection = nil;

      REditHistoryCol: TStreamRec = (
      ObjType: otEditHistoryCol;
      VmtLink: Ofs( TypeOf( TEditHistoryCol)^ );
      Load: @TEditHistoryCol.Load;
      Store: @TEditHistoryCol.Store );

      RViewHistoryCol: TStreamRec = (
      ObjType: otViewHistoryCol;
      VmtLink: Ofs( TypeOf( TViewHistoryCol)^ );
      Load: @TViewHistoryCol.Load;
      Store: @TViewHistoryCol.Store );

implementation
 uses Dos, Commands, DNApp, DNStdDlg, Dialogs, Advance,
      Startup, RStrings, xTime, Messages, Idlers, DNUtil,
      FViewer, CmdLine;

procedure FreeLastUnmarked(C: PCollection);

 var I: Integer;

  function IsThat(P: PEditRecord): Boolean; far;
  begin
    Dec(I);
    IsThat := (P^.fName^[1] = ' ');
  end;

begin
  if (C = nil) or (C^.Count < 1) then Exit;
  I := C^.Count;
  if C^.LastThat(@IsThat) <> nil then C^.AtFree(I);
end;


function  TEditHistoryCol.IndexOf;
  var S: String;
      I: Integer;
begin
  IndexOf := -1;
  S := Copy(CnvString(PEditRecord(P)^.fName), 2, 255); UpStr(S);
  for I := 0 to Count-1 do
    begin
      if Copy(CnvString(PEditRecord(Items^[I])^.fName), 2, 255) = S then
        begin IndexOf := I; Exit end;
    end;
end;

procedure TEditHistoryCol.PutItem;
begin
  S.WriteStr(PEditRecord(P)^.fName);
  S.Write(PEditRecord(P)^.fOrigin, SizeOf(TEditRecord)-SizeOf(PString));
end;

function  TEditHistoryCol.GetItem;
  var R: PEditRecord;
begin
  New(R); GetItem := R;
  R^.fName := S.ReadStr;
  S.Read(R^.fOrigin, SizeOf(TEditRecord)-SizeOf(PString));
end;

procedure TEditHistoryCol.FreeItem;
begin
  if P <> nil then
    begin
      DisposeStr(PEditRecord(P)^.fName);
      Dispose(PEditRecord(P));
    end;
end;

procedure TViewHistoryCol.PutItem;
begin
  S.WriteStr(PViewRecord(P)^.fName);
  S.Write(PViewRecord(P)^.fOrigin, SizeOf(TViewRecord)-SizeOf(PString));
end;

function  TViewHistoryCol.GetItem;
  var R: PViewRecord;
begin
  New(R); GetItem := R;
  R^.fName := S.ReadStr;
  S.Read(R^.fOrigin, SizeOf(TViewRecord)-SizeOf(PString));
end;

procedure TViewHistoryCol.FreeItem;
begin
  if P <> nil then
    begin
      DisposeStr(PViewRecord(P)^.fName);
      Dispose(PViewRecord(P));
    end;
end;

procedure StoreViewInfo(P: Pointer);
  var Viewer: PFileWindow absolute P;
      R: PViewRecord;
      I: Integer;
begin
  if InterfaceData.Options and ouiTrackViewers = 0 then Exit;
  if ViewHistory = nil then ViewHistory := New(PViewHistoryCol, Init(30, 30));
  New(R);
  with PFileViewer(Viewer^.Current)^, R^ do
    begin
       fName       := NewStr(' '+UpStrg(FileName));
       fOrigin     := Viewer^.Origin;
       fSize       := Viewer^.Size;
       fDeskSize   := Desktop^.Size;
       fViewMode   := ViewMode;
       fPos        := FilePos;
       fBufPos     := BufPos;
       fXlateTable := XlatFile;
       fFilter     := Filter;
       fHexEdit    := HexEdit;
       fWrap       := Wrap;
       fXDelta     := XDelta;
       fHexPos     := HexPos;
       fCur        := Cur;
    end;
  I := ViewHistory^.IndexOf(R);
  if I >= 0 then begin
                   R^.fName^[1] := PViewRecord(ViewHistory^.At(I))^.fName^[1];
                   ViewHistory^.AtFree(I);
                 end;
  ViewHistory^.AtInsert(0, R);
  if ViewHistory^.Count > MaxEditHistorySize then FreeLastUnmarked(ViewHistory);
end;

procedure StoreEditInfo(P: Pointer);
  var E: PEditWindow absolute P;
      I: Integer;
      R: PEditRecord;
      PP: PEditRecord;

begin
  if InterfaceData.Options and ouiTrackEditors = 0 then Exit;
  if EditHistory = nil then EditHistory := New(PEditHistoryCol, Init(30, 30));
  New(R);
  with PFileEditor(E^.Intern)^, R^ do
    begin
       fName          := NewStr(' '+UpStrg(EditName));
       fOrigin        := Owner^.Origin;
       fSize          := Owner^.Size;
       fDeskSize      := Desktop^.Size;
       fMarks         := MarkPos;
       fBlockStart    := Mark.A;
       fBlockEnd      := Mark.B;
       fPos           := Pos;
       fDelta         := Delta;
       fBlockVisible  := BlockVisible;
       fVerticalBlock := VertBlock;
       fHighlight     := Hilite;
       fHiliteColumn  := HiliteColumn;
       fHiliteLine    := HiliteLine;
       fAutoIndent    := AutoIndent;
       fAutoJustify   := AutoJustify;
       fAutoBrackets  := AutoBrackets;
       fLeftSide      := LeftSide;
       fRightSide     := RightSide;
       fInSide        := InSide;
       fInsMode       := InsertMode;
    end;
  I := EditHistory^.IndexOf(R);
  if I >= 0 then begin
                   R^.fName^[1] := PViewRecord(EditHistory^.At(I))^.fName^[1];
                   EditHistory^.AtFree(I);
                 end;
  EditHistory^.AtInsert(0, R);
  if EditHistory^.Count > MaxEditHistorySize then FreeLastUnmarked(EditHistory);
end;

procedure AddCommand(LastCommand: String);
  var I: Integer;
      P: PString;
  label 1;
begin
  if LastCommand <> '' then
    begin
      if CmdStrings = nil then
        CmdStrings := New(PLineCollection, Init(40,40));
      for I := 0 to CmdStrings^.Count - 1 do
        begin
          P := CmdStrings^.At(I);
          if Copy(CnvString(P),2,255) = LastCommand then
            begin
              CmdStrings^.AtDelete(I);
              CmdStrings^.Insert(P);
              Goto 1;
            end;
        end;
      Insert(' ', LastCommand, 1);
      CmdStrings^.Insert(NewStr(LastCommand));
1:
      I := 0;
      while (CmdStrings^.Count > 50) and
            (I < CmdStrings^.Count) do
         begin
            FreeStr := CnvString(CmdStrings^.At(I));
            if FreeStr[1] <> '+' then
              begin
                {if LastTHistPos > I then Dec(LastTHistPos);}
                CmdStrings^.AtFree(I);
              end
              else Inc(I);
         end;
      LastCommand := '';
    end;
end;

procedure InitCommands;
begin
 if CmdStrings <> nil then Dispose(CmdStrings, Done);
 CmdStrings := New(PLineCollection, Init(40, 10));
 StrModified := False;
 CurString := 0;
end;

procedure SaveCommands(var S: TStream);
 var I, J: Integer;
     S1,S2: String;
     M: PCollection;
begin
 Message(CommandLine, evCommand, cmExecCommandLine, nil);
 if (CmdStrings <> nil) and (CmdStrings^.Count >= 50) then
   begin
     M := New(PLineCollection, Init(50, 10));
     for I := 1 to 40 do
      begin
        if CmdStrings^.Count <= 0 then Break;
        M^.AtInsert(0, CmdStrings^.At(CmdStrings^.Count-1));
        CmdStrings^.AtDelete(CmdStrings^.Count-1);
      end;
     Dispose(CmdStrings, Done);
     CmdStrings := M;
   end;
 S.Put(CmdStrings);
 if InterfaceData.Options and ouiTrackDirs <> 0 then S.Put(DirHistory) else S.Put(nil);
 if InterfaceData.Options and ouiTrackEditors <> 0 then S.Put(EditHistory) else S.Put(nil);
 if InterfaceData.Options and ouiTrackViewers <> 0 then S.Put(ViewHistory) else S.Put(nil);
end;

procedure LoadCommands(var S: TStream);
 var I: Integer;
begin
 CmdStrings := PCollection(S.Get);
 DirHistory := PCollection(S.Get);
 EditHistory := PCollection(S.Get);
 ViewHistory := PCollection(S.Get);

 CurString := CmdStrings^.Count;
 StrModified := False;
 if CommandLine <> nil then CommandLine^.DrawView;
 Str := '';
end;

function GetCommand(Idx: Integer): String;
begin
  GetCommand := '';
  if (CmdStrings = nil) or (CmdStrings^.Count <= Idx) or (CmdStrings^.At(Idx) = nil) then Exit;
  GetCommand := Copy(PString(CmdStrings^.At(Idx))^,2,255);
end;


type
     PTHistList = ^TTHistList;
     TTHistList = object(TListBox)
       EVHistory, CommandHistory: Boolean;
       function ItemStr(I: Integer): PString;
       function IsSelected(I: Integer): Boolean; virtual;
       function GetText(Item: Integer; MaxLen: Integer): String; virtual;
       procedure SelectItem(Item: Integer); virtual;
       procedure HandleEvent(var Event: TEvent); virtual;
       destructor Done; virtual;
     end;

function TTHistList.IsSelected;
  var P: PString;
begin
  P := List^.At(I);
  IsSelected := (P <> nil) and (P^[1] = '+');
end;

function TTHistList.ItemStr;
begin
  if EVHistory then ItemStr := PEditRecord(List^.At(I))^.fName
               else ItemStr := List^.At(I);
end;

function TTHistList.GetText;
begin
  FreeStr := CnvString(ItemStr(Item));
  if FreeStr[1] = '+' then FreeStr[1] := 'þ'
                      else FreeStr[1] := ' ';
  GetText := FreeStr;
end;

procedure TTHistList.SelectItem;
  var P: PString;
begin
  P := ItemStr(Focused);
  if P <> nil then
    if P^[1] <> '+' then P^[1] := '+'
                    else P^[1] := ' ';
  DrawView;
end;

procedure TTHistList.HandleEvent;
  label 1;
  var P: Pointer;

  procedure ScanMarked(D: Integer);
    var P: PString;
        I: Integer;
  begin
    ClearEvent(Event);
    I := Focused;
    repeat
      Inc(I, D);
      if (I < 0) or (I >= List^.Count) or (ItemStr(I)^[1] <> ' ') then Break;
    until False;
    if (I >= 0) and (I < List^.Count) then begin FocusItem(I); DrawView end;
  end;

begin
  if (Event.What = evKeyDown) and (List <> nil) then
    case Event.KeyCode of
      kbDel: Goto 1;
      kbDown: if (ShiftState and 3 <> 0) and (Focused < List^.Count - 1) then
             begin
               P := List^.At(Focused);
               List^.AtDelete(Focused);
               List^.AtInsert(Focused+1, P);
               DrawView;
             end;
      kbUp: if (ShiftState and 3 <> 0) and (Focused > 0) then
             begin
               P := List^.At(Focused-1);
               List^.AtDelete(Focused-1);
               List^.AtInsert(Focused, P);
               DrawView;
             end;
      kbRight: ScanMarked(1);
      kbLeft: ScanMarked(-1);
    end else
  if (Event.What = evBroadcast) then
   case Event.Command of
    cmOK: begin
             ClearEvent(Event);
             if Focused >= List^.Count then Exit;
             FreeStr := Copy(CnvString(List^.At(Focused)), 2, 255);
             if InputBox(GetString(dlEditHistory), GetString(dlFindCellString), FreeStr, 255, hsEditHistory) <> cmOK then Exit;
             Insert(Copy(CnvString(List^.At(Focused)), 1, 1), FreeStr, 1);
             List^.AtReplace(Focused, NewStr(FreeStr));
             DrawView;
          end;
    cmYes:
1:         begin
             ClearEvent(Event);
             if Focused >= List^.Count then Exit;
             if Copy(CnvString(ItemStr(Focused)),1,1) = '+' then
               begin Sound(500); DelayTics(2); NoSound; Exit; end;
             if CommandHistory and (Focused <= CurString) and (CurString > 0) then Dec(CurString);
             List^.AtFree(Focused);
             SetRange(List^.Count);
             DrawView;
           end;
   end;
  inherited HandleEvent(Event);
end;

destructor TTHistList.Done;
begin
  List := nil;
  inherited Done;
end;

procedure AddToDirectoryHistory(S: String);
  var I: Integer;
      P: PString;

  function IsThat(P: PString): Boolean; far;
  begin
    Inc(I);
    IsThat := S = Copy(P^, 2, 255);
  end;

  function IsThis(P: PString): Boolean; far;
  begin
    IsThis := P^[1] = ' ';
  end;

begin
  if InterfaceData.Options and ouiTrackDirs = 0 then Exit;
  if (S = '') or (S[2] <> ':') then Exit;
  if DirHistory = nil then DirHistory := New(PLineCollection, Init(40, 40));
  UpStr(S); if S[Length(S)] <> '\' then AddStr(S, '\');
  I := -1; P := DirHistory^.FirstThat(@IsThat);
  if P <> nil then DirHistory^.AtDelete(I)
              else P := NewStr(' '+S);
  if P <> nil then DirHistory^.AtInsert(0, P);
  if DirHistory^.Count > MaxDirHistorySize then
    begin
      P := DirHistory^.LastThat(@IsThis);
      if P <> nil then DirHistory^.Free(P);
    end;
end;

function GetDialog(Dlg: TDlgIdx; var List: Pointer): PDialog;
var
  D: PDialog;
  P: PView;
  R: TRect;
begin
  D := PDialog( LoadResource( Dlg ));

  R.Assign(D^.Size.X-3, 2, D^.Size.X-2, 13);
  P := New(PScrollBar, Init(R));
  D^.Insert(P);

  R.Assign(2, 2, D^.Size.X-3, 13);
  P := New(PTHistList, Init(R, 1, PScrollBar(P)));
  D^.Insert(P); List := P;

  GetDialog := D;
end;

procedure EditHistoryMenu;
  var D: PDialog;
      P: PTHistList;
      I: Integer;
begin
  if InterfaceData.Options and ouiTrackEditors = 0 then
    begin
      Msg(dlSetEditHistory, nil, mfError+mfOKButton);
      Exit;
    end;
  if EditHistory = nil then EditHistory := New(PEditHistoryCol, Init(30, 30));
  if EditHistory^.Count = 0 then Exit;
  D := GetDialog(dlgEditHistory, Pointer(P));
  P^.NewList(EditHistory);
  P^.EVHistory := On;
  if Desktop^.ExecView(D) = cmOK then I := P^.Focused else I := -1;
  Dispose(D, Done);
  if I >= 0 then PDNApplication(Application)^.EditFile(Off, Copy(PViewRecord(EditHistory^.At(I))^.fName^, 2, 255));
end;

procedure ViewHistoryMenu;
  var D: PDialog;
      P: PTHistList;
      I: Integer;
begin
  if InterfaceData.Options and ouiTrackViewers = 0 then
    begin
      Msg(dlSetViewHistory, nil, mfError+mfOKButton);
      Exit;
    end;
  if ViewHistory = nil then ViewHistory := New(PViewHistoryCol, Init(30, 30));
  if ViewHistory^.Count = 0 then Exit;
  D := GetDialog(dlgViewHistory, Pointer(P));
  P^.NewList(ViewHistory);
  P^.EVHistory := On;
  if Desktop^.ExecView(D) = cmOK then I := P^.Focused else I := -1;
  Dispose(D, Done);
  if I >= 0 then PDNApplication(Application)^.ViewFile(Off, Copy(PViewRecord(ViewHistory^.At(I))^.fName^,2,255));
end;

function DirHistoryMenu: String;
var
  PC: PLineCollection;
  D: PDialog;
  P: PView;
  R: TRect;
  I: Integer;
  DT: Record PC: PCollection; I: Integer; end;
begin
  DirHistoryMenu := '';

  if InterfaceData.Options and ouiTrackDirs = 0 then
    begin
      Msg(dlSetDirHistory, nil, mfError+mfOKButton);
      Exit;
    end;

  if DirHistory = nil then DirHistory := New(PLineCollection, Init(40, 40));
  if DirHistory^.Count = 0 then Exit;

  D := GetDialog(dlgDirectoryHistory, Pointer(P));

  PListBox(P)^.NewList(DirHistory);

  I := Desktop^.ExecView(D);

  DT.I := PListBox(P)^.Focused;
  Dispose(D, Done);
  if I = cmOK then DirHistoryMenu := Copy(CnvString(DirHistory^.At(DT.I)),2,255);
end;


procedure CmdHistory;
var
  PC: PLineCollection;
  D: PDialog;
  P: PView;
  R: TRect;
  I: Integer;
  DT: Record PC: PCollection; I: Integer; end;
begin
  if CmdStrings = nil then
    CmdStrings := New(PLineCollection, Init(40,40));

  D := GetDialog(dlgCommandsHistory, Pointer(P));

  PListBox(P)^.NewList(CmdStrings);
  PListBox(P)^.FocusItem(CmdStrings^.Count-1);
  PTHistList(P)^.CommandHistory := On;
  if CmdStrings^.Count > 0 then PListBox(P)^.FocusItem(CmdStrings^.Count - 1);

  I := Desktop^.ExecView(D);

  DT.I := PListBox(P)^.Focused;
  Dispose(D, Done);

  if I = cmCancel then Exit;
  Message(CommandLine, evKeyDown, kbDown, nil);

  CurString := DT.I;
  Str := GetCommand(DT.I);
  CommandLine^.DrawView;
  Message(CommandLine, evKeyDown, kbEnd, nil);
  if I <> cmYes then Message(CommandLine, evKeyDown, kbEnter, nil);
end;






end.