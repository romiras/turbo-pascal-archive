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

unit DNStdDlg;

interface

uses Objects, Drivers, Views, Dialogs, Dos, Memory, Messages, DNApp, ObjType;

const

{ Commands }

  cmFileOpen    = 800;   { Returned from TFileDialog when Open pressed }
  cmFileReplace = 801;   { Returned from TFileDialog when Replace pressed }
  cmFileClear   = 802;   { Returned from TFileDialog when Clear pressed }
  cmFileInit    = 803;   { Used by TFileDialog internally }
  {cmChangeDir   = 804;  { Used by TChDirDialog internally }
  cmRevert      = 805;   { Used by TChDirDialog internally }

{ Messages }

  cmFileFocused = 806;    { A new file was focused in the TFileList }
  cmFileDoubleClicked     { A file was selected in the TFileList }
                = 807;

type

  { TSearchRec }

  {  Record used to store directory information by TFileDialog }

  TSearchRec = record
    Attr: Byte;
    Time: Longint;
    Size: Longint;
    Name: string[12];
  end;


type

  { TFileInputLine is a special input line that is used by      }
  { TFileDialog that will update its contents in response to a  }
  { cmFileFocused command from a TFileList.                     }

  PFileInputLine = ^TFileInputLine;
  TFileInputLine = object(TInputLine)
    constructor Init(var Bounds: TRect; AMaxLen: Integer);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  { TFileCollection is a collection of TSearchRec's.            }

  PFileCollection = ^TFileCollection;
  TFileCollection = object(TSortedCollection)
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  end;

  { TSortedListBox is a TListBox that assumes it has a          }
  { TStoredCollection instead of just a TCollection.  It will   }
  { perform an incremental search on the contents.              }

  PSortedListBox = ^TSortedListBox;
  TSortedListBox = object(TListBox)
    SearchPos: Word;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AScrollBar: PScrollBar);
    procedure HandleEvent(var Event: TEvent); virtual;
    function GetKey(var S: String): Pointer; virtual;
    procedure NewList(AList: PCollection); virtual;
  end;

  { TFileList is a TSortedList box that assumes it contains     }
  { a TFileCollection as its collection.  It also communicates  }
  { through broadcast messages to TFileInput and TInfoPane      }
  { what file is currently selected.                            }

  PFileList = ^TFileList;
  TFileList = object(TSortedListBox)
    constructor Init(var Bounds: TRect; AWildCard: PathStr;
      AScrollBar: PScrollBar);
    destructor Done; virtual;
    function DataSize: Word; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetKey(var S: String): Pointer; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure ReadDirectory(AWildCard: PathStr);
    procedure SetData(var Rec); virtual;
    procedure Select; virtual;
   { procedure GetData(var Rec); virtual;}
  end;

  { TDirectoryList }
  PDirectoryList = ^TDirectoryList;
  TDirectoryList = object(TFileList)
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetKey(var S: String): Pointer; virtual;
    procedure ReadDirectory(AWildCard: PathStr);
  end;

  { TFileInfoPane is a TView that displays the information      }
  { about the currently selected file in the TFileList          }
  { of a TFileDialog.                                           }

  PFileInfoPane = ^TFileInfoPane;
  TFileInfoPane = object(TView)
    S: TSearchRec;
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  { TFileDialog is a standard file name input dialog            }

const
  fdOkButton      = $0001;      { Put an OK button in the dialog }
  fdOpenButton    = $0002;      { Put an Open button in the dialog }
  fdReplaceButton = $0004;      { Put a Replace button in the dialog }
  fdClearButton   = $0008;      { Put a Clear button in the dialog }
  fdHelpButton    = $0010;      { Put a Help button in the dialog }
  fdNoLoadDir     = $0100;      { Do not load the current directory }
                                { contents into the dialog at Init. }
                                { This means you intend to change the }
                                { WildCard by using SetData or store }
                                { the dialog on a stream. }

type

  PFileDialog = ^TFileDialog;
  TFileDialog = object(TDialog)
    FileName: PFileInputLine;
    FileList: PFileList;
    DirList : PDirectoryList;
    WildCard: PathStr;
    Directory: PString;
    constructor Init(AWildCard: PathStr; ATitle: String;
      InputName: String; AOptions: Word; HistoryId: Byte);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure GetData(var Rec); virtual;
    procedure GetFileName(var S: FNameStr);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
  private
    procedure ReadDirectory;
  end;

  { TDirEntry }

  PDirEntry = ^TDirEntry;
  TDirEntry = record
    DisplayText: PString;
    Directory: PString;
  end;

  { TDirCollection is a collection of TDirEntry's used by       }
  { TDirListBox.                                                }

  PDirCollection = ^TDirCollection;
  TDirCollection = object(TCollection)
    function GetItem(var S: TStream): Pointer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  end;


const

  CInfoPane = #30;

  { TStream registration records }

const
  RFileInputLine: TStreamRec = (
     ObjType: otFileInputLine;
     VmtLink: Ofs(TypeOf(TFileInputLine)^);
     Load:    @TFileInputLine.Load;
     Store:   @TFileInputLine.Store
  );

const
  RFileCollection: TStreamRec = (
     ObjType: otFileCollection;
     VmtLink: Ofs(TypeOf(TFileCollection)^);
     Load:    @TFileCollection.Load;
     Store:   @TFileCollection.Store
  );

const
  RFileList: TStreamRec = (
     ObjType: otFileList;
     VmtLink: Ofs(TypeOf(TFileList)^);
     Load:    @TFileList.Load;
     Store:   @TFileList.Store
  );

const
  RFileInfoPane: TStreamRec = (
     ObjType: otFileInfoPane;
     VmtLink: Ofs(TypeOf(TFileInfoPane)^);
     Load:    @TFileInfoPane.Load;
     Store:   @TFileInfoPane.Store
  );

const
  RFileDialog: TStreamRec = (
     ObjType: otFileDialog;
     VmtLink: Ofs(TypeOf(TFileDialog)^);
     Load:    @TFileDialog.Load;
     Store:   @TFileDialog.Store
  );

const
  RSortedListBox: TStreamRec = (
     ObjType: otSortedListBox;
     VmtLink: Ofs(TypeOf(TSortedListBox)^);
     Load:    @TSortedListBox.Load;
     Store:   @TSortedListBox.Store
  );

{procedure RegisterStdDlg;}
function GetFileNameDialog(Mask, Title, Name: PathStr; Buttons, HistoryID: Word): PathStr;


implementation

uses HistList, Advance, RStrings, Commands, Startup, DNHelp;


function PathValid(var Path: FNameStr): Boolean;
var
  ExpPath: FNameStr;
  F: File;
  SR: SearchRec;
begin
  ClrIO; ExpPath := FExpand(Path); if Abort then Exit;
  if Length(ExpPath) <= 3 then PathValid := ValidDrive(ExpPath[1])
  else
  begin
    if ExpPath[Length(ExpPath)] = '\' then Dec(ExpPath[0]);
    FindFirst(ExpPath, Directory+Byte(SystemData.Options and ossShowHidden <> 0)*Hidden, SR);
    PathValid := (DosError = 0) and (SR.Attr and Directory <> 0);
  end;
end;

function ValidFileName(var FileName: FNameStr): Boolean;
const
  IllegalChars = ';,=+<>|"[] \';
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

{ Contains returns true if S1 contains any characters in S2 }
function Contains(S1, S2: String): Boolean; near; assembler;
asm
        PUSH    DS
        CLD
        LDS     SI,S1
        LES     DI,S2
        MOV     DX,DI
        XOR     AH,AH
        LODSB
        MOV     BX,AX
        OR      BX,BX
        JZ      @@2
        MOV     AL,ES:[DI]
        XCHG    AX,CX
@@1:    PUSH    CX
        MOV     DI,DX
        LODSB
        REPNE   SCASB
        POP     CX
        JE      @@3
        DEC     BX
        JNZ     @@1
@@2:    XOR     AL,AL
        JMP     @@4
@@3:    MOV     AL,1
@@4:    POP     DS
end;

begin
  ValidFileName := True;
  FSplit(FileName, Dir, Name, Ext);
  if not ((Dir = '') or PathValid(Dir)) or Contains(Name, IllegalChars) or
    Contains(Dir, IllegalChars) then ValidFileName := False;
end;

function GetCurDir: DirStr;
var
  CurDir: DirStr;
begin
  GetDir(0, CurDir);
  if Length(CurDir) > 3 then
  begin
    Inc(CurDir[0]);
    CurDir[Length(CurDir)] := '\';
  end;
  GetCurDir := CurDir;
end;

type
  PSearchRec = ^TSearchRec;

function IsWild(var S: String): Boolean;
begin
  IsWild := (Pos('?',S) > 0) or (Pos('*',S) > 0);
end;

function IsDir(var S: String): Boolean;
var
  SR: SearchRec;
begin
  FindFirst(S, Directory+Byte(SystemData.Options and ossShowHidden <> 0)*Hidden, SR);
  if DosError = 0 then
    IsDir := SR.Attr and Directory <> 0
  else IsDir := False;
end;

{ TFileInputLine }

constructor TFileInputLine.Init(var Bounds: TRect; AMaxLen: Integer);
begin
  TInputLine.Init(Bounds, AMaxLen);
  EventMask := EventMask or evBroadcast;
end;

procedure TFileInputLine.HandleEvent(var Event: TEvent);
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
begin
  TInputLine.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmFileFocused) and
    (State and sfSelected = 0) then
  begin
     Dir := PSearchRec(Event.InfoPtr)^.Name + '\';
     if Dir[1] = '[' then Dir := Dir[3] + ':';
     if PSearchRec(Event.InfoPtr)^.Attr and Directory <> 0 then
        Data^ := Dir +
          PFileDialog(Owner)^.WildCard
     else Data^ := PSearchRec(Event.InfoPtr)^.Name;
     DrawView;
  end;
end;

{ TFileCollection }

function TFileCollection.Compare(Key1, Key2: Pointer): Integer;
begin
  if PSearchRec(Key1)^.Name = PSearchRec(Key2)^.Name then Compare := 0
  else if (PSearchRec(Key1)^.Name[1] = '[') then Compare := 1
  else if (PSearchRec(Key2)^.Name[1] = '[') then Compare := -1
  else if PSearchRec(Key1)^.Name = '..' then Compare := -1
  else if PSearchRec(Key2)^.Name = '..' then Compare := 1
  else if (PSearchRec(Key1)^.Attr and Directory <> 0) and
     (PSearchRec(Key2)^.Attr and Directory = 0) then Compare := 1
  else if (PSearchRec(Key2)^.Attr and Directory <> 0) and
     (PSearchRec(Key1)^.Attr and Directory = 0) then Compare := -1
  else if PSearchRec(Key1)^.Name > PSearchRec(Key2)^.Name then
    Compare := 1
  else Compare := -1;
end;

procedure TFileCollection.FreeItem(Item: Pointer);
begin
  Dispose(PSearchRec(Item));
end;

function TFileCollection.GetItem(var S: TStream): Pointer;
var
  Item: PSearchRec;
begin
  New(Item);
  S.Read(Item^, SizeOf(TSearchRec));
  GetItem := Item;
end;

procedure TFileCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item^, SizeOf(TSearchRec));
end;



{ TSortedListBox }

constructor TSortedListBox.Init(var Bounds: TRect; ANumCols: Word;
  AScrollBar: PScrollBar);
begin
  TListBox.Init(Bounds, ANumCols, AScrollBar);
  SearchPos := 0;
  ShowCursor;
  SetCursor(1,0);
end;

procedure TSortedListBox.HandleEvent(var Event: TEvent);
var
  ShiftKeys: Byte absolute $40:$17;
  CurString, NewString: String;
  K: Pointer;
  Value, OldPos, OldValue: Integer;
  T: Boolean;

function Equal(var S1: String; var S2: String; Count: Word): Boolean;
var
  I: Word;
begin
  Equal := False;
  if (Length(S1) < Count) or (Length(S2) < Count) then Exit;
  for I := 1 to Count do
    if UpCase(S1[I]) <> UpCase(S2[I]) then Exit;
  Equal := True;
end;

begin
  OldValue := Focused;
  TListBox.HandleEvent(Event);
  if OldValue <> Focused then SearchPos := 0;
  if Event.What = evKeyDown then
  begin
    if Event.CharCode <> #0 then
    begin
      Value := Focused;
      if Value < Range then CurString := GetText(Value, 255)
      else CurString := '';
      OldPos := SearchPos;
      if Event.KeyCode = kbBack then
      begin
        if SearchPos = 0 then Exit;
        Dec(SearchPos);
        CurString[0] := Char(SearchPos);
      end
      else if (Event.CharCode = '.') then SearchPos := Pos('.',CurString)
      else
      begin
        Inc(SearchPos);
        CurString[0] := Char(SearchPos);
        CurString[SearchPos] := Event.CharCode;
      end;
      K := GetKey(CurString);
      if List <> nil then T := PSortedCollection(List)^.Search(K, Value)
                     else Value := Range;
      if Value < Range then
      begin
        if Value < Range then NewString := GetText(Value, 255)
        else NewString := '';
        if Equal(NewString, CurString, SearchPos) then
        begin
          if Value <> OldValue then
          begin
            FocusItem(Value);
            { Assumes ListControl will set the cursor to the first character }
            { of the sfFocused item }
            SetCursor(Cursor.X+SearchPos, Cursor.Y);
          end
          else SetCursor(Cursor.X+(SearchPos-OldPos), Cursor.Y);
        end
        else SearchPos := OldPos;
      end
      else SearchPos := OldPos;
      if (SearchPos <> OldPos) or (Event.CharCode in ['A'..'Z','a'..'z']) then
        ClearEvent(Event);
    end;
  end;
end;

function TSortedListBox.GetKey(var S: String): Pointer;
begin
  GetKey := @S;
end;

procedure TSortedListBox.NewList(AList: PCollection);
begin
  TListBox.NewList(AList);
  SearchPos := 0;
end;

{ TFileList }

constructor TFileList.Init(var Bounds: TRect; AWildCard: PathStr;
  AScrollBar: PScrollBar);
begin
  TSortedListBox.Init(Bounds, 1, AScrollBar);
end;

destructor TFileList.Done;
begin
  if List <> nil then Dispose(List, Done);
  TListBox.Done;
end;

procedure TFileList.Select;
var Event: TEvent;
begin
 if List^.Count > 0
  then
     begin
       Event.What := evBroadcast;
       Event.Command := cmFileFocused;
       Event.InfoPtr := List^.At(Focused);
       Owner^.HandleEvent(Event);
       Inherited Select;
     end
  else {Owner^.SelectNext(False)};
end;

function TFileList.DataSize: Word;
begin
  DataSize := 0;
end;

procedure TFileList.FocusItem(Item: Integer);
begin
  TSortedListBox.FocusItem(Item);
  Message(Owner, evBroadcast, cmFileFocused, List^.At(Item));
end;

{procedure TFileList.GetData(var Rec);
begin
end;
}


function TFileList.GetKey(var S: String): Pointer;
const
  SR: TSearchRec = ();
begin
  SR.Attr := 0;
  SR.Name := S;
  UpStr(SR.Name);
  GetKey := @SR;
end;

function TFileList.GetText(Item: Integer; MaxLen: Integer): String;
var
  SR: PSearchRec;
begin
  SR := PSearchRec(List^.At(Item));
  GetText := SR^.Name;
end;

procedure TFileList.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evMouseDown) and (Event.Double) then
  begin
    Event.What := evCommand;
    Event.Command := cmOK;
    PutEvent(Event);
    ClearEvent(Event);
  end
  else TSortedListBox.HandleEvent(Event);
end;

procedure TFileList.ReadDirectory(AWildCard: PathStr);
const
  FindAttr = ReadOnly + Archive + SysFile;
var
  S: SearchRec;
  P: PSearchRec;
  FileList: PFileCollection;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
  Event : TEvent;
begin
  AWildCard := FExpand(AWildCard);
  FSplit(AWildCard, Dir, Name, Ext);
  FileList := New(PFileCollection, Init(5, 5));
  FindFirst(AWildCard, FindAttr+Byte(SystemData.Options and ossShowHidden <> 0)*Hidden, S);
  P := @P;
  while (P <> nil) and (DosError = 0) do
  begin
    if (S.Attr and Directory = 0) then
    begin
      P := MemAlloc(SizeOf(P^));
      if P <> nil then
      begin
        Move(S.Attr, P^, SizeOf(P^));
        FileList^.Insert(P);
      end;
    end;
    FindNext(S);
  end;
  if P = nil then Msg(dlStdDlgManyFiles, nil, mfOkButton + mfWarning);
  NewList(FileList);
{  if List^.Count = 0 then WriteLn('ãª');
{  if List^.Count > 0 then
  begin
    Event.What := evBroadcast;
    Event.Command := cmFileFocused;
    Event.InfoPtr := List^.At(0);
    Owner^.HandleEvent(Event);
  end;  }
end;

procedure TFileList.SetData(var Rec);
begin
  {with PFileDialog(Owner)^ do}
  ReadDirectory(PFileDialog(Owner)^.Directory^ + PFileDialog(Owner)^.WildCard);
end;

{ TDirectoryList }

function TDirectoryList.GetKey(var S: String): Pointer;
const
  SR: TSearchRec = ();
begin
  SR.Attr := Directory;
  SR.Name := S;
  UpStr(SR.Name);
  GetKey := @SR;
end;

function TDirectoryList.GetText(Item: Integer; MaxLen: Integer): String;
var
  SR: PSearchRec;
begin
  SR := PSearchRec(List^.At(Item));
  if SR^.Name[1] <> '[' then GetText := SR^.Name+'\'
                        else GetText := SR^.Name;
end;

procedure TDirectoryList.ReadDirectory(AWildCard: PathStr);
const
  FindAttr = ReadOnly + Archive + SysFile;
  PrevDir  = '..';
var
  S: SearchRec;
  P: PSearchRec;
  FileList: PFileCollection;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
  Tmp: FNameStr;
  Event: TEvent;
  C: Char;
begin
  AWildCard := FExpand(AWildCard);
  FSplit(AWildCard, Dir, Name, Ext);
  FileList := New(PFileCollection, Init(5, 5));
{  FindFirst(AWildCard, FindAttr, S);}
  P := @P;
  Tmp := Dir + x_x;
  FindFirst(Tmp, Directory+Byte(SystemData.Options and ossShowHidden <> 0)*Hidden, S);
  while (P <> nil) and (DosError = 0) do
  begin
    if (S.Attr and Directory <> 0) and (S.Name[1] <> '.') then
    begin
      P := MemAlloc(SizeOf(P^));
      if P <> nil then
      begin
        Move(S.Attr, P^, SizeOf(P^));
        FileList^.Insert(PObject(P));
      end;
    end;
    FindNext(S);
  end;
  if Length(Dir) > 4 then
  begin
    P := MemAlloc(SizeOf(P^));
    if P <> nil then
    begin
      FindFirst(Tmp, Directory+Byte(SystemData.Options and ossShowHidden <> 0)*Hidden, S);
      FindNext(S);
      if (DosError = 0) and (S.Name = PrevDir) then
        Move(S.Attr, P^, SizeOf(P^))
      else
      begin
        P^.Name := PrevDir;
        P^.Size := 0;
        P^.Time := $210000;
        P^.Attr := Directory;
      end;
      FileList^.Insert(PObject(P));
    end;
  end;
  for C := 'Z' downto 'A' do
   if ValidDrive(C) then
     begin
       P := MemAlloc(SizeOf(P^));
       P^.Name := '[-'+C+'-]';
       P^.Size := 0;
       P^.Time := $210000;
       P^.Attr := Directory;
       FileList^.Insert(PObject(P));
     end;
  if P = nil then Msg(dlStdDlgManyFiles, nil, mfOkButton + mfWarning);
  NewList(FileList);
{  if List^.Count > 0 then
  begin
    Event.What := evBroadcast;
    Event.Command := cmFileFocused;
    Event.InfoPtr := List^.At(0);
    Owner^.HandleEvent(Event);
  end;                               }
end;

{ TFileInfoPane }

constructor TFileInfoPane.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  EventMask := EventMask or evBroadcast;
end;

procedure TFileInfoPane.Draw;
var
  B: TDrawBuffer;
  D: String[10];
  M: String[20];
  PM: Boolean;
  Color: Word;
  Time: DateTime;
  Path: PathStr;
  FmtId: String;
  Params: array[0..7] of LongInt;
  Str: String[80];
const
  sDirectoryLine = ' %-12s %-10s  %sm';
  sFileLine      = ' %-12s %-10d  %sm';
begin
  { Display path }
  Path := FExpand(PFileDialog(Owner)^.Directory^+PFileDialog(Owner)^.WildCard);
  Color := GetColor($01);
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B[1], Path, Color);
  WriteLine(0, 0, Size.X, 1, B);

  { Display file }
  Params[0] := LongInt(@S.Name);
  MoveChar(B, ' ', Color, Size.X);
  Params[0] := LongInt(@S.Name);
  if S.Attr and Directory <> 0 then
  begin
    FmtId := sDirectoryLine;
    if S.Name[1] <> '[' then D := GetString(dlDirectory)
                        else D := GetString(dlDrive);
    Params[1] := LongInt(@D);
  end else
  begin
    FmtId := sFileLine;
    Params[1] := S.Size;
  end;
  UnpackTime(S.Time, Time);
  with Time do
    MakeDate(0, Day, Month, Year mod 100, Hour, Min, M);
{  M := GetString( TStrIdx( Integer( dlJanuary ) + Time.Month - 1 ));}
  Params[2] := LongInt(@M);
{  Params[3] := Time.Day;
  Params[4] := Time.Year;}
{  PM := Time.Hour >= 12;
  Time.Hour := Time.Hour mod 12;
  if Time.Hour = 0 then Time.Hour := 12;
  Params[5] := Time.Hour;
  Params[6] := Time.Min;
  if PM then Params[7] := Byte('p')
  else Params[7] := Byte('a');}
  FormatStr(Str, FmtId, Params);
  if CountryInfo.TimeFmt = 1 then Dec(Str[0]);
  MoveStr(B, Str, Color);
  WriteLine(0, 1, Size.X, 1, B);

  { Fill in rest of rectangle }
  MoveChar(B, ' ', Color, Size.X);
  WriteLine(0, 2, Size.X, Size.Y-2, B);
end;


function TFileInfoPane.GetPalette: PPalette;
const
  P: String[Length(CInfoPane)] = CInfoPane;
begin
  GetPalette := @P;
end;

procedure TFileInfoPane.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmFileFocused) then
  begin
    S := PSearchRec(Event.InfoPtr)^;
    DrawView;
  end;
end;

{ TFileDialog }

constructor TFileDialog.Init;
var
  Control: PView;
  R: TRect;
  S: String;
  Opt: Word;
  ACurDir: FNameStr;
begin
  R.Assign(15,1,62,20);
  TDialog.Init(R, ATitle);
  Options := Options or ofCentered;
  if AOptions and fdOpenButton <> 0
    then HelpCtx := hcOpenFileDialog
    else HelpCtx := hcSelectFileDialog;
  WildCard := AWildCard;

  R.Assign(3,3,31,4);
  FileName := New(PFileInputLine, Init(R, 79));
  FileName^.Data^ := WildCard;
  Insert(FileName);
  R.Assign(2,2,3+CStrLen(InputName),3);
  Control := New(PLabel, Init(R, InputName, FileName));
  Insert(Control);
  R.Assign(31,3,34,4);
  Control := New(PHistory, Init(R, FileName, HistoryId));
  Insert(Control);


  R.Assign(17,6,18,15);
  Control:=New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3,6,17,15);
  FileList := New(PFileList, Init(R, WildCard, PScrollBar(Control)));
  FileList^.HelpCtx := {hcOpen_Files}0;
  Insert(FileList);
  R.Assign(2,5,8,6);
  Control := New(PLabel, Init(R, GetString(dlFiles), FileList));
  Insert(Control);

  R.Assign(34,6,35,15);
  Control:=New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(20,6,34,15);
  DirList := New(PDirectoryList, Init(R, WildCard, PScrollBar(Control)));
  DirList^.HelpCtx := {hcOpen_Director}0;
  Insert(DirList);
  R.Assign(19,5,34,6);
  Control := New(PLabel, Init(R, GetString(dlDirectoriesLabel), DirList));
  Insert(Control);


  R.Assign(35,3,45,5);
  Opt := bfDefault;
  if AOptions and fdOpenButton <> 0 then
  begin
    Control:=New(PButton, Init(R, GetString(dlOpen), cmFileOpen, Opt));
    Control^.HelpCtx:={hcOpenButton}0;
    Insert(Control);
    Opt := bfNormal;
    Inc(R.A.Y,3); Inc(R.B.Y,3);
  end;
  if AOptions and fdOkButton <> 0 then
  begin
    Control:=New(PButton, Init(R, GetString(dlOKButton), cmFileOpen, Opt));
    Control^.HelpCtx:={hcOK}0;
    Insert(Control);
    Opt := bfNormal;
    Inc(R.A.Y,3); Inc(R.B.Y,3);
  end;
  if AOptions and fdReplaceButton <> 0 then
  begin
    Insert(New(PButton, Init(R, GetString(dlReplace),cmFileReplace, Opt)));
    Opt := bfNormal;
    Inc(R.A.Y,3); Inc(R.B.Y,3);
  end;
  if AOptions and fdClearButton <> 0 then
  begin
    Insert(New(PButton, Init(R, GetString(dlClear),cmFileClear, Opt)));
    Opt := bfNormal;
    Inc(R.A.Y,3); Inc(R.B.Y,3);
  end;
  Control:=New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
  Control^.HelpCtx:={hcCancelButton}0;
  Insert(Control);
  Inc(R.A.Y,3); Inc(R.B.Y,3);
  if AOptions and fdHelpButton <> 0 then
  begin
    Control:=New(PButton, Init(R, GetString(dlHelpButton), cmHelp, bfNormal));
    Insert(Control);
    Inc(R.A.Y,3); Inc(R.B.Y,3);
  end;

  R.Assign(1,16,46,18);
  Control := New(PFileInfoPane, Init(R));
  Insert(Control);

  SelectNext(False);

  if AOptions and fdNoLoadDir = 0 then ReadDirectory;
end;

constructor TFileDialog.Load(var S: TStream);
var
  ACurDir: DirStr;
  ViewId: Word;
begin
  TDialog.Load(S);
  S.Read(WildCard, SizeOf(PathStr));
  GetSubViewPtr(S, FileName);
  GetSubViewPtr(S, FileList);

  ReadDirectory;
end;


destructor TFileDialog.Done;
begin
  DisposeStr(Directory);
  TDialog.Done;
end;

procedure TFileDialog.GetData(var Rec);
begin
  GetFilename(FNameStr(Rec));
end;

procedure TFileDialog.GetFileName(var S: FNameStr);
var
  Path: FNameStr;
  Name: NameStr;
  Ext: ExtStr;
  TPath: FNameStr;
  TName: NameStr;
  TExt: NameStr;

function LTrim(S: String): String;
var
  I: Integer;
begin
  I := 1;
  while (I < Length(S)) and (S[I] = ' ') do Inc(I);
  LTrim := Copy(S, I, 255);
end;

function RTrim(S: String): String;
var
  I: Integer;
begin
  while S[Length(S)] = ' ' do Dec(S[0]);
  RTrim := S;
end;

function RelativePath(var S: FNameStr): Boolean;
var
  I,J: Integer;
  P: FNameStr;
begin
  S := LTrim(RTrim(S));
  if (S <> '') and ((S[1] = '\') or (S[2] = ':')) then RelativePath := False
  else RelativePath := True;
end;

function NoWildChars(S: String): String; assembler;
asm
        PUSH    DS
        LDS     SI,S
        XOR     AX,AX
        LODSB
        XCHG    AX,CX
        LES     DI,@Result
        INC     DI
@@1:    LODSB
        CMP     AL,'?'
        JE      @@2
        CMP     AL,'*'
        JE      @@2
        STOSB
@@2:    LOOP    @@1
        XCHG    AX,DI
        MOV     DI,WORD PTR @Result
        SUB     AX,DI
        DEC     AX
        STOSB
        POP     DS
end;

begin
  S := FileName^.Data^; ClrIO;
  if RelativePath(S) then S := FExpand(Directory^ + S)
  else S := FExpand(S);
  if Abort then Exit;
  FSplit(S, Path, Name, Ext);
  if ((Name = '') or (Ext = '')) and not IsDir(S) then
  begin
    FSplit(WildCard, TPath, TName, TExt);
    if ((Name = '') and (Ext = '')) then S := Path + TName + TExt
    else if Name = '' then S := Path + TName + Ext
    else if Ext = '' then
    begin
      if IsWild(Name) then S := Path + Name + TExt
      else S := Path + Name + NoWildChars(TExt);
    end;
  end;
end;

procedure TFileDialog.HandleEvent(var Event: TEvent);

 procedure Go;
   procedure SuperFocus(var List: PCollection; curent: Integer);
   begin
    if List^.Count > 0 then
     begin
       Event.What := evBroadcast;
       Event.Command := cmFileFocused;
       Event.InfoPtr := List^.At(curent);
       Owner^.HandleEvent(Event);
     end;
   end;

 begin
  if (FileList^.State and sfSelected >0) then
       SuperFocus(FileList^.List,FileList^.Focused);
  if (DirList^.State and sfSelected >0)  then
       SuperFocus(DirList^.List,DirList^.Focused);
  ClearEvent(Event);
 end;

begin
  if Event.What = evKeyDown then
   begin
    if (FileName^.State  AND sfSelected)=0 then
     Case Event.KeyCode of
      kbRight:
       begin
        if (Current=PView(FileName))
         then
          if (FileList^.List^.Count=0)
           then DirList^.Select
           else SelectNext(False)
         else SelectNext(False);
        Go;
       end;
      kbShiftTab,kbLeft:
       begin
        if (Current=PView(DirList))
         then
          if (FileList^.List^.Count=0)
           then FileName^.Select
           else SelectNext(True)
         else SelectNext(True);
        Go;
       end;
     end;
    Case Event.KeyCode of
      kbTab:
       begin
        if (Current=PView(FileName))
         then
           if (FileList^.List^.Count=0)
           then DirList^.Select
           else SelectNext(False)
         else SelectNext(False);
        Go;
       end;
     end;

   end;
  TDialog.HandleEvent(Event);

  if Event.What = evCommand then
    case Event.Command of
      cmFileOpen, cmFileReplace, cmFileClear:
        begin
          EndModal(Event.Command);
          ClearEvent(Event);
        end;
    end;
end;

procedure TFileDialog.SetData(var Rec);
begin
  TDialog.SetData(Rec);
  if (FNameStr(Rec) <> '') and (IsWild(PathStr(Rec))) then
  begin
    Valid(cmFileInit);
    FileName^.Select;
  end;
end;

procedure TFileDialog.ReadDirectory;
  var D: DirStr;
      N: NameStr;
      X: ExtStr;
begin
  FileList^.ReadDirectory(WildCard);
  DirList^.ReadDirectory(WildCard);
  FSplit(FExpand(WildCard), D, N, X);
  WildCard := N+X;
  Directory := NewStr(D);
end;

procedure TFileDialog.Store(var S: TStream);
begin
  TDialog.Store(S);
  S.Write(WildCard, SizeOf(PathStr));
  PutSubViewPtr(S, FileName);
  PutSubViewPtr(S, FileList);
end;


function TFileDialog.Valid(Command: Word): Boolean;
var
  T: Boolean;
  FName: FNameStr;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

function CheckDirectory(var S: FNameStr): Boolean;
begin
  if S[1] = '[' then S := S[3]+':';
  if not PathValid(S) then
  begin
    ErrMsg(erInvalidDrive);
    FileName^.Select;
    CheckDirectory := False;
  end else CheckDirectory := True;
end;
var Event: TEvent;
begin
  if Command = 0 then
  begin
    Valid := True;
    Exit;
  end else Valid := False;
  if TDialog.Valid(Command) then
  begin
    if Command = cmCancel then begin Valid := True; Exit; end;
    GetFileName(FName);
    if Abort then begin Valid := False; Exit; end;
    if (Command <> cmCancel) and (Command <> cmFileClear) then
    begin
      if IsWild(FName) then
      begin
        FSplit(FName, Dir, Name, Ext);
        if CheckDirectory(Dir) then
        begin
          DisposeStr(Directory);
          Directory := NewStr(Dir);
          WildCard := Name+Ext;
          DirList^.ReadDirectory(Directory^+WildCard);
          FileList^.ReadDirectory(Directory^+WildCard);
          if Command <> cmFileInit then{ FileList^.Select;}
           if ((DirList^.State and sfSelected)<>0) OR
            (FileList^.List^.Count = 0)
            then
             begin
             { DirList^.Select;
             { if DirList^.List^.Count > 0 then}
              begin
                Event.What := evBroadcast;
                Event.Command := cmFileFocused;
                Event.InfoPtr := Dirlist^.List^.At({Focused}0);
                Owner^.HandleEvent(Event);
              end;
             end
            else FileList^.Select;
        end
      end
      else if IsDir(FName) then
      begin
        if CheckDirectory(FName) then
        begin
          DisposeStr(Directory);
          Directory := NewStr(FName+'\');
          DirList^.ReadDirectory(Directory^+WildCard);
          FileList^.ReadDirectory(Directory^+WildCard);
          if Command <> cmFileInit then  {FileList^.Select;}
           if ((DirList^.State and sfSelected)<>0 ) OR
            (FileList^.List^.Count = 0)
            then
             begin
           {   DirList^.Select;
              if DirList^.List^.Count > 0 then}
              begin
                Event.What := evBroadcast;
                Event.Command := cmFileFocused;
                Event.InfoPtr := DirList^.List^.At({Focused}0);
                Owner^.HandleEvent(Event);
              end;
             end{DirList^.Select}
            else FileList^.Select;

        end
      end else if ValidFileName(FName) then Valid := True
      else
      begin
        ErrMsg(erInvalidFileName);
        Valid := False;
      end
    end
    else Valid := True;
  end;
end;

{ TDirCollection }

procedure TDirCollection.FreeItem(Item: Pointer);
var
  DirItem: PDirEntry absolute Item;
begin
  DisposeStr(DirItem^.DisplayText);
  DisposeStr(DirItem^.Directory);
  Dispose(DirItem);
end;

function TDirCollection.GetItem(var S: TStream): Pointer;
var
  DirItem: PDirEntry;
begin
  New(DirItem);
  DirItem^.DisplayText := S.ReadStr;
  DirItem^.Directory := S.ReadStr;
  GetItem := DirItem;
end;


procedure TDirCollection.PutItem(var S: TStream; Item: Pointer);
var
  DirItem: PDirEntry absolute Item;
begin
  S.WriteStr(DirItem^.DisplayText);
  S.WriteStr(DirItem^.Directory);
end;

{
procedure RegisterStdDlg;
begin
  RegisterType(RFileInputLine);
  RegisterType(RFileCollection);
  RegisterType(RFileList);
  RegisterType(RFileInfoPane);
  RegisterType(RFileDialog);
  RegisterType(RSortedListBox);
end;
}

function GetFileNameDialog(Mask, Title, Name: PathStr; Buttons, HistoryID: Word): PathStr;
 var S: PathStr;
     D: PFileDialog;
     B: Boolean;
begin
  S := ''; B := Off; if Mask = '' then begin Mask := x_x; B := On end;
  D := PFileDialog(Application^.ValidView(New(PFileDialog,
        Init(Mask, Title, Name, Buttons, HistoryID))));
  if D = nil then Exit;
  if B then D^.SetData(S);
  if Desktop^.ExecView(D) <> cmCancel then D^.GetFileName(S);
  Dispose(D, Done);
  if S <> '' then
    begin
       S := FExpand(S);
       HistoryAdd(HistoryID, S);
    end;
  GetFileNameDialog := S
end;


end.

