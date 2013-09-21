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

{ TEditWindow palette layout
  1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
  ³ ³ ³ ³ ³ ³ ³ ³ ³ ³  ³  ³  ³  ³  ÀÄÄ 78 Dragging frame
  ³ ³ ³ ³ ³ ³ ³ ³ ³ ³  ³  ³  ³  ÀÄÄÄÄÄ 77 Selected text
  ³ ³ ³ ³ ³ ³ ³ ³ ³ ³  ³  ³  ÀÄÄÄÄÄÄÄÄ 76 Text normal
  ³ ³ ³ ³ ³ ³ ³ ³ ³ ³  ³  ÀÄÄÄÄÄÄÄÄÄÄÄ 75 Scroll bar Icons
  ³ ³ ³ ³ ³ ³ ³ ³ ³ ³  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 74 Scroll bar Page
  ³ ³ ³ ³ ³ ³ ³ ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 73 Frame title
  ³ ³ ³ ³ ³ ³ ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 72 Frame icon
  ³ ³ ³ ³ ³ ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 71 Frame active
  ³ ³ ³ ³ ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 69 Menu selected Shortcut
  ³ ³ ³ ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 68 Menu selected Disabled
  ³ ³ ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 67 Menu selected Normal
  ³ ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 66 Menu text Shortcut
  ³ ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 65 Menu text Disabled
  ³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 64 Menu text Normal
  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 70 Frame passive
}

unit MicroEd;
interface
uses
  Dos, Objects, Drivers, Memory, Views, Messages, DNApp, Advance, Startup,
  Menus, DNStdDlg, Dialogs, Commands, UniWin, RStrings, DNHelp, SBlocks,
  ObjType;


  { TUndoCollection }

const
      maxUndo    = 50;

      udDelChar  = 1;
      udInsChar  = 2;
      udDelLine  = 3;
      udInsLine  = 4;
      udDelBlock = 5;
      udInsBlock = 6;
      udBackDel  = 7;
      udSubDel   = 8;
      udSubDelLine = 9;
      udIndentBlock = 10;
      udUnindentBlock = 11;
      udInsVertBlock  = 12;
      udReplace       = 13;
      udReplaceChar   = 14;
      udReplaceBlock  = 15;
      udClearBlock    = 16;
      udStrModified   = 17;
      udDupeLine      = 18;
      udFormatBlock   = 19;

      Clipboard   : PCollection = nil;

      CFileEditor = #13#14#16#17#18#19#20#21#22#23;

type

  TPosArray = Array ['1'..'9'] of TPoint;

  PUndoRec = ^TUndoRec;
  TUndoRec = record
   What: Word;
   Where: TPoint;
   case Word of
    udDelChar: (Str: PString);
    udInsChar: (Count, Width: Integer; Block: TRect);
    udDelLine: (Lines: PCollection; Vertical: Boolean);
  end;

  PUndoCollection = ^TUndoCollection;
  TUndoCollection = object(TCollection)
    procedure FreeItem(P: Pointer); virtual;
  end;

  TForceCRLF = (cfNone, cfCRLF, cfCR, cfLF);

  { TFileEditor }

  PFileEditor = ^TFileEditor;
  TFileEditor = object(TView)
    HScroll, VScroll: PScrollBar;
    ReplaceAll: Boolean;
    Delta: TPoint;
    EditName: PathStr;
    FileLines: PCollector;
    IsValid,Marking: Boolean;
    SmartPad: Boolean;
    OptMenu: PMenu;
    Mark,Sel: TRect;
    LeftSide, RightSide, InSide: Integer;
    Pos, LastPos,BlockPos: TPoint;
    MarkPos: TPosArray;
    LastLine, DrawMode: Integer;
    WorkString,LastShape: String;
    OldBlockValid, SearchOnDisplay,
    InsertMode,AutoIndent,VertBlock,Modified,WorkModified,
    BlockVisible,SpecChar,WasDelete,BackIndent,MouseMark, UnMark,
    AutoWrap,LineMarking,AutoJustify,OptimalFill,RulerVisible,EnableMarking,
    HiliteColumn, HiliteLine, AutoBrackets,
    SearchActive: Boolean;
    UndoInfo: PCollection;
    UndoTimes: LongInt;
    HiLite: Integer;
    KeyWords1,KeyWords2: String;
    NumCommentStrings: Byte;
    CommentStrings: Array [1..5] of String[4];
    NumCommentChars: Byte;
    CommentChars: Array [1..5] of Char;
    NumCommentStartChars: Byte;
    CommentStartChars: Array [1..5] of Char;
    StrongKeywords: Boolean;
    CommentsOnly: Boolean;
    C_Comments: Boolean;
    Pas_Comments: Boolean;
    X_Comments: Boolean;
    ChPosition: Boolean;
    Macros: PCollection;
    Locker: PStream;
    LastDir: Integer;
    MemEnough: Boolean;
    ForcedCRLF: TForceCRLF;
    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
      var FileName: PathStr);
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    procedure Awaken; virtual;
    destructor Done; virtual;
    procedure InitHighLight(const FName: String);
    function  ReadBlock(var FileName: PathStr; RetCollector: Boolean): Pointer;
    procedure HandleEvent(var Event : TEvent);virtual;
    procedure Draw; virtual;
    function  Valid(Command: Word): Boolean; virtual;
    function  GetPalette : PPalette;virtual;
    function  GetLine(Index : Integer) : String;
    function  GetSelection : PCollection;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    function  ValidBlock: Boolean;
    procedure CalcMenu;
    function Search: Boolean;
    procedure LoadFile(Name : String);
    procedure OpenFile;
    procedure LockFile;
    procedure UnLockFile;
    procedure SaveFile;
    procedure SaveFileAs;
    procedure InsertBlock(ABlock: PCollection; SaveUndo: Boolean);
    procedure ModifyLine(Index : Integer; S : String; DelSpaces: Boolean);
    procedure SetLimits;
    procedure ChangeBounds(var R: TRect); virtual;
    procedure ScrollTo(DeltaX, DeltaY: Integer);
    procedure StoreUndoInfo(What: Word; Where: TPoint; var Info);
    procedure DoHighlite(var B; S: String; Y: Integer;
                         Comments, Keywords1C, KeyWords2C,
                         Symbols, Strings, Numbers: Byte);
    function HandleCommand(var Event: TEvent): Boolean; virtual;
  end;

  { TInfoLine }

  PInfoLine = ^TInfoLine;
  TInfoLine = object(TView)
     constructor Init(var R: TRect);
     procedure Draw; virtual;
     procedure HandleEvent(var Event: TEvent);virtual;
  end;

  { TEditWindow }

  PEditWindow = ^TEditWindow;
  TEditWindow = object(TUniWindow)
    AInfo: PInfoLine;
    Intern: PFileEditor;
    MenuBar: PMenuBar;
    UpMenu: PMenu;
    ModalEnd: Boolean;
    constructor Init(R: TRect; FileName: PathStr);
    constructor Load(var S: TStream);
    procedure ChangeBounds(var R: TRect); virtual;
    procedure Store(var S: TStream);
    function Execute: Word; virtual;
  end;

function CapCaseStr(S: String): String;
procedure OpenEditor;
procedure OpenSmartpad;
procedure FileChanged(const Name: PathStr);

const
      HighLighted: Boolean = False;

      RFileEditor: TStreamRec = (
       ObjType: otFileEditor;
       VmtLink: Ofs(TypeOf(TFileEditor)^);
       Load: @TFileEditor.Load;
       Store: @TFileEditor.Store);

      RInfoLine: TStreamRec = (
       ObjType: otInfoLine;
       VmtLink: Ofs(TypeOf(TInfoLine)^);
       Load: @TInfoLine.Load;
       Store: @TInfoLine.Store);

      REditWindow: TStreamRec = (
       ObjType: otEditWindow;
       VmtLink: Ofs(TypeOf(TEditWindow)^);
       Load: @TEditWindow.Load;
       Store: @TEditWindow.Store);

      REditScrollBar: TStreamRec = (
       ObjType: otEditScrollBar;
       VmtLink: Ofs(TypeOf(TEditScrollBar)^);
       Load: @TEditScrollBar.Load;
       Store: @TEditScrollBar.Store);

      REditFrame: TStreamRec = (
       ObjType: otEditFrame;
       VmtLink: Ofs(TypeOf(TEditFrame)^);
       Load: @TEditFrame.Load;
       Store: @TEditFrame.Store);

      RLineCollection: TStreamRec = (
       ObjType: otLineCollection;
       VmtLink: Ofs(TypeOf(TLineCollection)^);
       Load: @TLineCollection.Load;
       Store: @TLineCollection.Store);

type
    TSearchData = record
                 Options: Word;
                 Dir: Word;
                 Scope: Word;
                 Origin: Word;
                 Line, What: String[250];
                end;

const
      SearchData: TSearchData = (Options:4; Dir: 0; Scope:0; Origin:0; Line:''; What:'');

implementation

uses Gauge, FViewer, Histlist, Macro, Editor, WinClp, DNUtil, Histries,
     xTime, FileCopy;

const
    On          = True;
    Off         = False;
    cmNoCommand = 4000;
    TabStep     : Integer = 8;
    SmartWindow : PEditWindow = nil;

type
     TEditCommand = record
      C,C1,C2: Word;
      CC1, CC2: Array[1..2] of Char;
     end;

var B: Array[0..500] of Word;

const
      MaxCommands: Integer = 0;

var
      EditCommands : Array [1..100] of TEditCommand;

type
       PEditSaver = ^TEditSaver;
       TEditSaver = object(TObject)
          constructor Load(var S: TStream);
          procedure Store(var S: TStream);
       end;

const
      REditSaver: TStreamRec = (
       ObjType: 12335;
       VmtLink: Ofs(TypeOf(TEditSaver)^);
       Load: @TEditSaver.Load;
       Store: @TEditSaver.Store);

       Registered: Boolean = Off;


function ESC_Pressed: Boolean; var E: TEvent;
begin
  Application^.Idle;
  GetKeyEvent(E); ESC_Pressed := (E.What = evKeyDown) and (E.KeyCode = kbEsc)
end;

function MemAvail: LongInt; begin MemAvail := MemAdjust(System.MemAvail) end;


constructor TEditSaver.Load(var S: TStream);
begin
  S.Read(MaxCommands, SizeOf(MaxCommands));
  S.Read(EditCommands, SizeOf(EditCommands));
end;

procedure TEditSaver.Store(var S: TStream);
begin
  S.Write(MaxCommands, SizeOf(MaxCommands));
  S.Write(EditCommands, SizeOf(EditCommands));
end;

procedure LoadCommands;
  var P: PEditSaver;
begin
  if MaxCommands = 0 then
    begin
      if not Registered then RegisterType(REditSaver);
      Registered := On;
      P := PEditSaver(LoadResource(dlgEditorCommands));
      P^.Free;
    end;
end;

  const LoCaseMaked: Boolean = False;

  var
        LoCaseArray: Array[char] of char;

{
function SysUpCase(A: Char): Char; assembler;
 var MP: Record A: Byte; P: Pointer; end;
asm
   mov  al,A
   cmp  al,65
   jc   @Done
   cmp  al,91
   jnc  @NoLow
   xor  al,$20
   jmp  @Done
@NoLow:
   cmp  al, $80
   jb   @Done
   push ds
   pop  es
   lea  di, CountryInfo
   push bp
   call ES:[DI].TCountryInfo.CaseTbl
   pop  bp
@Done:

end;

}
{
procedure MakeLoCase;
  var C, I: Char;
begin
  Move(LowCaseArray, LoCaseArray, 128);
  for I := #128 to #255 do
    begin
      if System.UpCase(I) = I then
        begin
          for C := #128 to #255 do
            if System.UpCase(C) = I then
             begin LoCaseArray[I] := C; Break; end;
        end else LoCaseArray[I] := I;
    end;
  LoCaseMaked := On;
end;


function LoCase(a: Char): Char;
begin
  if not LoCaseMaked then MakeLoCase;
  LoCase := LoCaseArray[a];
end;

function LowerStr(S: String): String;
begin
  if not LoCaseMaked then MakeLoCase;
 asm
  lea si, LoCaseArray
  lea di, S
  mov cl, ss:[di]
  xor ch, ch
  xor bh, bh
  or  cl, cl
  jz  @Exit
@@1:
  inc di
  mov al, ss:[di]
  or al, al
  jz @@2
  mov bl, al
  mov al, ds:[bx+si]
  mov ss:[di], al
@@2:
  loop @@1
@Exit:
 end;
 LowerStr := S;
end;

function UpperStr(S: String): String;
 var I: Integer;
begin
  for I := 1 to Length(S) do
    S[I] := System.UpCase(S[I]);
  UpperStr := S;
end;
}

function CapCaseStr(S: String): String;
 var I: Integer;
begin
  I := 1; S := LowCaseStr(S);
  while I < Length(S) do
   begin
     while (I <= Length(S)) and not (S[I] in ['A'..'Z', 'a'..'z', #128..#255]) do Inc(I);
     if I <= Length(S) then S[I] := UpCaseArray[S[I]];
     while (I <= Length(S)) and (S[I] in ['A'..'Z', 'a'..'z', #128..#255]) do Inc(I);
   end;
   S[1] := UpCaseArray[S[1]];
   CapCaseStr := S;
end;

constructor TEditWindow.Load(var S: TStream);
  var PI: PMenuItem;
begin
 inherited Load(S);
 GetSubViewPtr(S, Intern);
 GetSubViewPtr(S, AInfo);
 GetSubViewPtr(S, MenuBar);
 UpMenu := MenuBar^.Menu;

  PI := MenuBar^.Menu^.Items;
  while (PI <> nil) and (PI^.HelpCtx <> hcedOptions) do
      PI := PI^.Next;
  if (PI <> nil) then PI := Pointer(PI^.SubMenu);
  PFileEditor(Intern)^.OptMenu := Pointer(Pi);

 LoadCommands;
end;

procedure TEditWindow.ChangeBounds;
begin
 inherited ChangeBounds(R);
 Intern^.HScroll^.GrowTo(Size.X - 26, 1);
 if not (Intern^.SmartPad or GetState(sfModal)) then
    begin
      GetBounds(TempBounds);
      LastEditDeskSize := Desktop^.Size;
    end;
end;

function TEditWindow.Execute;
 var Event: TEvent;
begin
  ModalEnd := Off;
  repeat
    GetEvent(Event);
    if Event.What <> evNothing then HandleEvent(Event);
  until ModalEnd;
end;


procedure TEditWindow.Store(var S: TStream);
begin
 inherited Store(S);
 PutSubViewPtr(S, Intern);
 PutSubViewPtr(S, AInfo);
 PutSubViewPtr(S, MenuBar);
end;

constructor TFileEditor.Load(var S: TStream);
 var SS: PString;
begin
 TObject.Init;
 inherited Load(S);
 GetPeerViewPtr(S, HScroll);
 GetPeerViewPtr(S, VScroll);
 SS := S.ReadStr;
 EditName := SS^;
 DisposeStr(SS);
 S.Read(MarkPos, Sizeof(MarkPos));
 S.Read(LeftSide, 6);
 S.Read(Hilite, 1);
 S.Read(HiliteColumn, SizeOf(HiliteColumn));
 S.Read(HiliteLine, SizeOf(HiliteLine));
 S.Read(AutoIndent, SizeOf(AutoIndent));
 S.Read(VertBlock, SizeOf(VertBlock));
 S.Read(BackIndent, SizeOf(BackIndent));
 S.Read(AutoJustify, SizeOf(AutoJustify));
 S.Read(OptimalFill, SizeOf(OptimalFill));
 S.Read(AutoWrap, SizeOf(AutoWrap));
 S.Read(AutoBrackets, SizeOf(AutoBrackets));
 isValid := True;
 Macros := New(PCollection, Init(10,10));
 LastDir := -1;
end;

procedure TFileEditor.Store(var S: TStream);
begin
 inherited Store(S);
 PutPeerViewPtr(S, HScroll);
 PutPeerViewPtr(S, VScroll);
 S.WriteStr(@EditName);
 S.Write(MarkPos, Sizeof(MarkPos));
 S.Write(LeftSide, 6);
 S.Write(Hilite,1);
 S.Write(HiliteColumn, SizeOf(HiliteColumn));
 S.Write(HiliteLine, SizeOf(HiliteLine));
 S.Write(AutoIndent, SizeOf(AutoIndent));
 S.Write(VertBlock, SizeOf(VertBlock));
 S.Write(BackIndent, SizeOf(BackIndent));
 S.Write(AutoJustify, SizeOf(AutoJustify));
 S.Write(OptimalFill, SizeOf(OptimalFill));
 S.Write(AutoWrap, SizeOf(AutoWrap));
 S.Write(AutoBrackets, SizeOf(AutoBrackets));
end;

procedure TFileEditor.Awaken;
 var X, Y: Integer;
     XD: TPoint;
     Hi: Integer;
begin
 X := HScroll^.Value;
 Y := VScroll^.Value;
 XD := Pos;
 Hi := HiLite;
 LoadFile(EditName);
 HiLite := Hi;
 ScrollTo(X,Y);
 Pos := XD;
 ChPosition := Off;
 Owner^.Redraw;
end;

type
  PAttrBufStream=^TAttrBufStream;
  TAttrBufStream=object(TBufStream)
    OldAttr: Word;
    F: File;
    constructor Init(FileName: FNameStr; Mode, Size: Word);
    destructor Done; virtual;
  end;

constructor TAttrBufStream.Init(FileName: FNameStr; Mode, Size: Word);
begin
  inherited Init(FileName, Mode, Size); OldAttr := $FFFF;
end;

destructor TAttrBufStream.Done;
begin
  inherited Done;
  if OldAttr <> $FFFF then SetFAttr(F, OldAttr);
end;

function CheckForOver(Name: PathStr): PStream;
 var S: PAttrBufStream;
     F: File;
     W: Word;
     L: array[0..0] of LongInt;
     Attr: Word;

procedure CreateBackup;
var
  Dr: PathStr;
  Nm: NameStr;
  Xt: ExtStr;
begin
  FSplit(Name, Dr, Nm, Xt); ClrIO;
  EraseFile( Dr+Nm+'.BAK' );
  Assign(F, Name); Rename(F, Dr+Nm+'.BAK'); ClrIO;
end;

procedure OverQuery;
var
   P: PString;
   Dr: string[30];
begin
   P := @Dr; Dr := Cut(Name, 30);
   W := Msg(dlED_OverQuery, @P, mfYesButton+mfCancelButton+mfAppendButton+mfWarning);
end;

begin
 CheckForOver := nil; Abort := Off; S := nil;
 Assign(F, Name); ClrIO; GetFAttr(F, Attr); if Abort then Exit;
 if (IOResult = 0) and (Attr and ReadOnly <> 0 ) then
 begin
   OverQuery; case W of cmYes, cmOK:;else Exit end;
   Pointer(L[0]) := @Name;
   if Msg(dlED_ModifyRO, @L, mfConfirmation+mfOKCancel)<>cmOK then Exit;
   SetFAttr(F, Archive);
   if Abort or (IOResult<>0) then
   begin
     CantWrite(Name);
     Exit;
   end;
 end else begin W := $FFFF; Attr := Archive end;
 New(S, Init(Name, stOpen, 4096)); if S = nil then Exit;
 if Abort or (S^.Status = stOK) then
 begin
   if W = $FFFF then OverQuery;
   case W of
     cmYes, cmOK: begin
                    if Attr and ReadOnly <> 0 then
                    begin
                      S^.OldAttr := Attr;
                      Move(F, S^.F, SizeOf(file));
                    end;
                    case W of
                      cmYes: S^.Truncate;
                      cmOK : S^.Seek(S^.GetSize);
                    end;
                    CheckForOver := S;
                  end;
     else FreeObject(S);
   end;
   Exit;
 end;
 FreeObject(S);
 if Abort then Exit;
 if EditorDefaults.EdOpt and ebfCBF <> 0 then CreateBackup;
 New(S, Init(Name, stCreate, 4096));
 if Abort or (S = nil) or (S^.Status <> stOK) then
 begin
   CantWrite(Name);
   FreeObject(S);
   Exit
 end;
 CheckForOver := S;
end;

procedure WriteBlock(Hint: String; S: PStream; C: PCollector; ForcedCRLF: TForceCRLF; AOptimalFill: Boolean);
 var I: Integer;
     M: LongInt;
     SST: String;
     P: PString;

  procedure CompressString;
   var I, J, K: Integer;
       PP: Pointer;
  begin
   PP := @SST;
   asm
      les bx, PP
      mov cl, es:[bx]
      inc bx
      xor ch, ch
      jcxz @@Ex
      xor di, di
      xor si, si
      mov byte ptr es:[bx-1], ch
    @@1:
      mov ah, 8
      xor dx, dx
    @@2:
      mov al, es:[bx][si]
      mov es:[bx][di], al
      inc si
      cmp si, cx
      ja  @@Ex
      inc di
      inc byte ptr es:[bx-1]
      cmp al, ' '
      jne @@3
      inc dl
      jmp @@4
     @@3:
      xor Dl, dl
     @@4:
      dec ah
      jnz @@2
      or  dl, dl
      jz @@5
      dec dl
      jz @@5
      sub di, dx
      sub byte ptr es:[bx-1], dl
      mov al, 9
      mov es:[bx][di-1], al
     @@5:
      jmp @@1
    @@Ex:
   end;
  end;

  var PP: PView;
      CrLf: String[2];

begin

 if ForcedCRLF = cfCR then CrLf := #13 else
 if ForcedCRLF = cfLF then CrLf := #10 else
 if ForcedCRLF = cfCRLF then CrLf := #13#10 else

 if EditorDefaults.NewLine = 1 then CrLf := #13 else
   if EditorDefaults.NewLine = 2 then CrLf := #10 else
      crlf := #13#10;

 I := 1; if (S = nil) or (C = nil) then Exit;
 PP := WriteMsg(^M^M^C+GetString(dlWritingFile));
 while not Abort and (S^.Status = stOK) and (I < C^.Count) do
  begin
   UpdateWriteView(PP);
   P := C^.At(I-1); if P <> nil then SST := P^ + CrLf else SST := CrLf;
   if AOptimalFill then CompressString;
   S^.Write(SST[1], Length(SST));
   Inc(I);
  end;
  HintString := ''; Application^.Idle;
  P := C^.At(I-1); if P <> nil then SST := P^ else SST := '';
  S^.Write(SST[1], Byte(SST[0]));
  if PP <> nil then PP^.Free;
end;

function TFileEditor.GetPalette;
 const s : String[Length(CFileEditor)] = CFileEditor;
begin
 GetPalette:=@s;
end;

{ TUndoCollection }
procedure TUndoCollection.FreeItem(P: Pointer);
 var T: PUndoRec;
begin
 T := P;
 if P = nil then Exit;
 case T^.What of
  udDelChar, udInsLine, udSubDelLine, udReplace, udReplaceChar, udInsBlock,
  udFormatBlock, udStrModified, udSubDel, udBackDel: DisposeStr(T^.Str);
  udDelLine, udDelBlock, udReplaceBlock,
  udClearBlock: Dispose(T^.Lines, Done);
 end;
 Dispose(T);
end;

{ TInfoLine }

constructor TInfoLine.Init;
begin
   inherited Init(R);
   EventMask := evMouseDown;
end;

procedure TInfoLine.HandleEvent;
  var T: TPoint;
      S: String[40];
      P: PFileEditor;
begin
  inherited HandleEvent(Event);
  if Event.What = evMouseDown then
    begin
       Owner^.MakeLocal(Event.Where, T);
       if T.X >= Owner^.Size.X-2 then
         begin
           PWindow(Owner)^.Frame^.HandleEvent(Event);
           Exit;
         end;
       MakeLocal(Event.Where, T);
       P := PFileEditor(PEditWindow(Owner)^.Intern);
       With P^ do
        begin
          S := 'ÍÍÍ';
          S := S + ItoS(Delta.Y + 1) + ':' + ItoS(Delta.X + 1);
        end;
       Event.What := evCommand;
       if (T.X > 2) and (T.X < Length(S)) then Event.Command := cmGotoLineNumber else
         if (T.X > Length(S)) and (T.X <= Length(S)+5) then Event.Command := cmSpecChar else
           if (T.X > Length(S)+6) and (T.X <= Length(S)+9) then Event.Command := cmSwitchBlock else
             Event.What := evNothing;
       if Event.What <> evNothing then PutEvent(Event);
       ClearEvent(Event);
    end;
end;

procedure TInfoLine.Draw;
 var P: PFileEditor;
     X,Y: Word;
     C: Char;
     S: String[40];
begin
 P := PFileEditor(PEditWindow(Owner)^.Intern);
 With P^ do
  begin
   X := Delta.X + 1;
   Y := Delta.Y + 1;
   if X <= Byte(WorkString[0]) then C := WorkString[X] else C := #0;
  end;
 if P^.Modified then S := #15'ÍÍ' else S := 'ÍÍÍ';
 S := S + ItoS(Y) + ':' + ItoS(X) + ' ['+SStr(Byte(C),3,'0')+'] ';
 if P^.DrawMode = 1 then S := S + '{Å}' else
   if P^.DrawMode = 2 then S := S + '{Î}' else
     if P^.VertBlock then S := S + '('#18')' else S := S + '('#29')';
 if not Owner^.GetState(sfActive) then S[0] := #0;
 if Size.X <> Byte(S[0]) then
    begin GrowTo(Byte(S[0]),Size.Y);  Exit end;
 MoveStr(B, S, Owner^.GetColor(8));
 WriteLine(0, 0, Size.X, 1, B);
end;

{ TEditWindow }
constructor TEditWindow.Init;
var
  pm: PMenu;
  Pi: PMenuItem;
begin
  inherited Init(R, '', 0);
  LoadCommands;
  Options := Options or ofTileable;

  GetExtent(R);
  R.Grow(-1, -1);
  R.B.Y := R.A.Y + 1;
  MenuBar := PMenuBar(LoadResource(dlgEditorMenu));
  if MenuBar <> nil then MenuBar^.Locate(R);
  Insert(MenuBar);

  {MenuBar^.Options := MenuBar^.Options or ofPostProcess;}
  GetExtent(R);
  R.Grow(-1, -1);
  Inc(R.A.Y);

  Intern:=New(PXFileEditor, Init(R,
    MakeScrollBar(sbHorizontal + sbHandleKeyboard),
    MakeScrollBar(sbVertical + sbHandleKeyboard), Filename));

  {FreeObject(Intern);}

  PI := MenuBar^.Menu^.Items;
  while (PI <> nil) and (PI^.HelpCtx <> hcedOptions) do
      PI := PI^.Next;
  if (PI <> nil) then PI := Pointer(PI^.SubMenu);
  PFileEditor(Intern)^.OptMenu := Pointer(Pi);

  Insert(Intern);
  Intern^.LoadFile(FileName);
  if not Intern^.IsValid then
  begin
     Done;
     Fail;
  end;
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  R.A.X := 2;
  R.B.X := 4;
  AInfo := New(PInfoLine, Init(R));
  AInfo^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(AInfo);
end;

{ TFileEditor }
constructor TFileEditor.Init;
var
  FileToView: Text;
  Line: String;
  MaxWidth: Integer;
  p: PString;
  Nm: NameStr;
  Xt: ExtStr;
  I: Integer;
begin
  inherited Init(Bounds);
  LastDir := -1;
  HelpCtx := hcEditor;
  UndoInfo := nil;
  HScroll := AHScrollBar;
  VScroll := AVScrollBar;
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofSelectable;
  SearchActive := Off; UnMark := On;
  EventMask := $FFFF;
  IsValid := True;

  HiliteColumn := EditorDefaults.EdOpt and ebfHCl <> 0;
  HiliteLine   := EditorDefaults.EdOpt and ebfHLn <> 0;
  AutoIndent   := EditorDefaults.EdOpt and ebfAId <> 0;
  VertBlock    := EditorDefaults.EdOpt and ebfVBl <> 0;
  BackIndent   := EditorDefaults.EdOpt and ebfBSU <> 0;
  OptimalFill  := EditorDefaults.EdOpt and ebfOfl <> 0;
  AutoJustify  := EditorDefaults.EdOpt and ebfJwr <> 0;
  AutoBrackets := EditorDefaults.EdOpt and ebfAbr <> 0;
  AutoWrap     := EditorDefaults.EdOpt and ebfAwr <> 0;

  Val(EditorDefaults.RM, RightSide, I); if I <> 0 then RightSide := 76;
  Val(EditorDefaults.LM, LeftSide, I); if I <> 0 then LeftSide := 0;
  Val(EditorDefaults.PM, InSide, I); if I <> 0 then InSide := 5;
  SmartPad := Off;
  FillChar(MarkPos, SizeOf(MarkPos), $FF);
  if FileName = 'SmartPad' then
    begin
      Line := GetEnv('SMARTPAD');
      if (Line = '') then Line := SourceDir;
      if (Line[Length(Line)]<>'\') then Line := Line+'\';
      FileName := Line+Filename+'.DN';
      SmartPad := On;
    end else Line := FileName;
  FileLines := GetCollector(10000, 100);
  Macros := New(PCollection, Init(10,10));
end;

destructor TFileEditor.Done;
begin
  FreeObject(FileLines);
  FreeObject(UndoInfo);
  FreeObject(Macros);
  FreeObject(Locker);
  if SmartPad then SmartWindow := nil;
  inherited Done;
end;

procedure TFileEditor.StoreUndoInfo;
 var P, P1: PUndoRec;
     S: String;
     Bl: Boolean;
begin
  if not MemOK then FreeObject(UndoInfo);
  if UndoInfo = nil then UndoInfo := New(PUndoCollection, Init($100, $80));
  if UndoInfo^.Count > 0 then P1 := UndoInfo^.At(UndoInfo^.Count-1) else P1 := nil;
  if ValidBlock then
  case What of
   udDelChar: if not VertBlock then
              begin
                if (Mark.A.Y = Where.Y) and (Where.X < Mark.A.X) then Dec(Mark.A.X);
                if (Mark.B.Y = Where.Y) and (Where.X < Mark.B.X) then Dec(Mark.B.X);
              end;
   udReplaceChar:;
   udBackDel: if not VertBlock then
              begin
                if (Mark.A.Y = Where.Y) and (Where.X <= Mark.A.X) then Dec(Mark.A.X);
                if (Mark.B.Y = Where.Y) and (Where.X <= Mark.B.X) then Dec(Mark.B.X);
              end;
   udInsChar: if not VertBlock then
              begin
                if (Mark.A.Y = Where.Y) and (Where.X < Mark.A.X) then Inc(Mark.A.X);
                if (Mark.B.Y = Where.Y) and (Where.X < Mark.B.X) then Inc(Mark.B.X);
              end;
   udInsLine, udDupeLine: begin
                 if Mark.A.Y > Where.Y then Inc(Mark.A.Y);
                 if Mark.B.Y > Where.Y then Inc(Mark.B.Y);
                 if (Mark.A.Y = Where.Y) and (Where.X <= Mark.A.X) then
                   begin
                     Inc(Mark.A.Y);
                     if What <> udDupeLine then Mark.A.X := Mark.A.X - Where.X;
                   end;
                 if (Mark.B.Y = Where.Y) and (Where.X < Mark.B.X) then
                   begin
                     Inc(Mark.B.Y);
                     if What <> udDupeLine then Mark.B.X := Mark.B.X - Where.X;
                   end;
               end;
   udSubDel,
   udSubDelLine,
   udDelLine:  begin
                 if (Where.Y = Mark.A.Y) and (Where.Y = Mark.B.Y) and
                    (What = udDelLine) then Mark.A := Mark.B;
                 if Mark.A.Y > Where.Y then
                    begin
                      Dec(Mark.A.Y);
                      if (What <> udDelLine) and not VertBlock and
                         (Mark.A.Y = Where.Y) and (Where.X > Mark.A.X) then Mark.A.X := Where.X;
                    end;
                 if Mark.B.Y > Where.Y then
                    begin
                      Dec(Mark.B.Y);
                      if (What <> udDelLine) and not VertBlock and
                         (Mark.B.Y = Where.Y) and (Where.X > Mark.B.X) then Mark.B.X := Where.X;
                    end;
               end;
  end;

  case What of
   udDelChar: if (P1 <> nil) and (P1^.What = udDelChar) and (P1^.Where.Y = Where.Y) and
                 (P1^.Where.X = Where.X) then
                  begin S := P1^.Str^+Char(Info); DisposeStr(P1^.Str); P1^.Str := NewStr(S); end
                  else begin
                        S := Char(Info); New(P); P^.What := What;
                        P^.Where := Where; P^.Str := NewStr(S);
                        UndoInfo^.Insert(P); Inc(UndoTimes);
                       end;
   udReplaceChar: if (P1 <> nil) and (P1^.What = What) and (P1^.Where.Y = Where.Y) and
                 (Where.X = P1^.Where.X) then
                  begin S := P1^.Str^+Char(Info); Inc(P1^.Where.X);
                        DisposeStr(P1^.Str); P1^.Str := NewStr(S); end
                  else begin
                        S := Char(Info); New(P); P^.What := What;
                        P^.Where := Where; P^.Str := NewStr(S);
                        Inc(P^.Where.X);
                        UndoInfo^.Insert(P); Inc(UndoTimes);
                       end;
   udBackDel: if (P1 <> nil) and (P1^.What = What) and (P1^.Where.Y = Where.Y) and
                 (P1^.Where.X = Where.X) then
                 begin S := Char(Info)+P1^.Str^; Dec(P1^.Where.X);
                       DisposeStr(P1^.Str); P1^.Str := NewStr(S); end
                 else begin
                        S := Char(Info); New(P); P^.What := What;
                        P^.Where := Where; P^.Str := NewStr(S);
                        Dec(P^.Where.X);
                        UndoInfo^.Insert(P); Inc(UndoTimes);
                       end;
   udInsChar: if (P1 <> nil) and (P1^.What = What) and (P1^.Where.Y = Where.Y) and
                 (P1^.Where.X = Where.X) then
                  begin Inc(P1^.Count); Inc(P1^.Where.X) end
                  else begin
                        New(P); P^.What := What;
                        P^.Where := Where; Inc(P^.Where.X);
                        P^.Count := 1;
                        UndoInfo^.Insert(P); Inc(UndoTimes);
                       end;
   udDupeLine: begin
                   New(P); P^.What := What;
                   P^.Where := Where;
                   P^.Count := 1;
                   UndoInfo^.Insert(P); Inc(UndoTimes);
               end;
   udDelLine: if (P1 <> nil) and (P1^.What = What) and (P1^.Where.Y = Where.Y) then
                P1^.Lines^.Insert(NewStr(String(Info))) else
              begin
                New(P); P^.What := What;
                P^.Where := Where;
                P^.Lines := New(PLineCollection, Init(10, 10));
                P^.Lines^.Insert(NewStr(String(Info)));
                UndoInfo^.Insert(P); Inc(UndoTimes);
              end;
   udInsLine, udSubDel, udSubDelLine, udInsBlock, udReplace, udFormatBlock:
              begin
                New(P); P^.What := What;
                P^.Where := Where;
                P^.Str := NewStr(String(Info));
                UndoInfo^.Insert(P); Inc(UndoTimes);
              end;
   udReplaceBlock, udClearBlock:
                   begin
                    New(P); P^.What := What;
                    P^.Where := Where;
                    P^.Lines := PCollection(Info);
                    UndoInfo^.Insert(P); Inc(UndoTimes);
                   end;
   udInsVertBlock: begin
                    New(P); P^.What := What;
                    P^.Where := Where;
                    P^.Count := LongInt(Info) and $FFFF;
                    P^.Width := LongInt(Info) shr 16;
                    UndoInfo^.Insert(P); Inc(UndoTimes);
                   end;
   udDelBlock: begin
                New(P); P^.What := What;
                P^.Where := Where;
                P^.Vertical := VertBlock;
                P^.Lines := PCollection(Info);
                UndoInfo^.Insert(P); Inc(UndoTimes);
               end;
   udIndentBlock, udUnindentBlock
                : if (P1 <> nil) and (P1^.What = What) and (P1^.Block.A.Y = TRect(Info).A.Y) and
                     (P1^.Block.A.Y = TRect(Info).B.Y) then
                  begin Inc(P1^.Count); end else
                  begin
                   New(P); P^.What := What;
                   P^.Where := Where;
                   P^.Block := TRect(Info);
                   P^.Count := 1;
                   UndoInfo^.Insert(P); Inc(UndoTimes);
                  end;
   udStrModified:  begin
                      New(P); P^.What := What;
                      P^.Where := Where; Inc(P^.Where.X);
                      P^.Count := 1;
                      P^.Str := NewStr(String(Info));
                      UndoInfo^.Insert(P); Inc(UndoTimes);
                    end;
  end;
  CalcMenu;
end;

procedure TFileEditor.CalcMenu;
 var GC : TCommandSet;
     MI : PMenuItem;

 Procedure SetM( B : Boolean);
  var G : String;
 begin
  if MI = nil then Exit;
  if B then G := 'On'
       else G := 'Off';
  if MI^.Param^ <> G then
  begin
    DisposeStr(MI^.Param);
    MI^.Param := NewStr(G);
  end;
  MI := MI^.Next;
 end;

 var BlkC: TCommandSet;

begin
  if (Owner = nil) or (PEditWindow(Owner)^.MenuBar = nil) then Exit;
  BlkC := [cmCopy,cmCut,cmClear,cmBlockWrite,cmFJustify, cmCopyBlock, cmMoveBlock,
           cmFRight,cmFLeft,cmFCenter,cmPrintBlock, cmCalcBlock, cmSortBlock,
           cmUpcaseBlock, cmLowcaseBlock, cmCapitalizeBlock,
           cmIndentBlock, cmUnIndentBlock];
  OldBlockValid := (ValidBlock and BlockVisible);
  if OldBlockValid then EnableCommands(BlkC)
                   else DisableCommands(BlkC);
  if (UndoInfo <> nil) and (UndoInfo^.Count > 0)
     then EnableCommands([cmUndo]) else DisableCommands([cmUndo]);
  if (Clipboard <> nil) and (Clipboard^.Count > 0) or (GetWinClipSize)
     then EnableCommands([cmPaste]) else DisableCommands([cmPaste]);
  if OptMenu <> Nil then
  begin
   MI := OptMenu^.Items;
   SetM(BackIndent);
   SetM(AutoBrackets);
   SetM(AutoIndent);
   SetM(AutoWrap);
   SetM(AutoJustify);
   SetM(VertBlock);
   SetM(OptimalFill);
   SetM(HiliteLine);
   SetM(HiliteColumn);
   SetM(HiLite <> 0);
  end;
  GetCommands(GC);
  PEditWindow(Owner)^.MenuBar^. SetCommands(GC);
  SetCommands(GC);
end;

procedure TFileEditor.SetState;
begin
 inherited SetState(AState,Enable);
 if (AState and (sfActive + sfFocused + sfSelected + sfVisible) <> 0)
   or (OldBlockValid xor (ValidBlock and BlockVisible)) then CalcMenu;
  {if not GetState(sfFocused) then CalcMenu;}
 if AState and sfActive <> 0 then
  if GetState(sfActive+sfSelected) then
   begin
    if HScroll <> nil then HScroll^.Show;
    if VScroll <> nil then VScroll^.Show;
    DrawView;
   end else
   begin
    if HScroll <> nil then HScroll^.Hide;
    if VScroll <> nil then VScroll^.Hide;
    DrawView;
   end;
end;

procedure TFileEditor.InitHighLight(const FName: String);
begin
  InitEditorHighLight(FName, @Self);
end;

procedure TFileEditor.LoadFile;
 label 1;
 var S: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
begin
  FreeObject(FileLines);
  FreeObject(UndoInfo);
  UndoTimes := 0; LastDir := -1; DrawMode := 0;
  SearchOnDisplay := Off; ForcedCRLF := cfNone;
1:
  if Name = '' then begin FileLines := GetCollector(10000, 100);;
                          Name := 'Untitled.TXT';
                          FileLines^.Insert(NewStr('')) end else
   begin
    FileLines := ReadBlock(Name, On);
    if not IsValid then Exit;
    if FileLines = nil then begin FileLines := GetCollector(10000, 100);
                                  FileLines^.Insert(NewStr('')) end;
    if Name <> '' then Name := FExpand(Name) else Name := 'Untitled.TXT';
   end;
  SetLimits;
  Pos.X := 0; Pos.Y := 0;
  Delta := Pos;
  InsertMode := On;
  BlockVisible := Off;
  Mark.Assign(0,0,0,0);
  Modified := Off; DrawMode := 0; WorkModified := Off; LastLine:=-1; LastShape := '';
  SpecChar := Off; WasDelete := Off;
  Marking := Off; MouseMark := Off;
  RulerVisible := Off;
  EnableMarking := On;
  WorkString := GetLine(0);
  if Name <> 'Untitled.TXT' then Name := DelSpaces(FExpand(Name));
  EditName := Name; DisposeStr(PWindow(Owner)^.Title);
  if SmartPad then
    begin
      PWindow(Owner)^.Title := NewStr('SmartPad(TM) - ' + EditName);
    end
    else PWindow(Owner)^.Title := NewStr(GetString(dlEditTitle) + EditName);
  LockFile;
  FillChar(MarkPos,0,SizeOf(MarkPos));
  FSplit(EditName, FreeStr, Nm, Xt);
  InitHighLight(Nm+Xt);
end;

procedure TFileEditor.ScrollTo;
begin
 if HScroll <> nil then HScroll^.SetValue(DeltaX);
 if VScroll <> nil then VScroll^.SetValue(DeltaY);
end;

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
  if Desktop^.ExecView(D) <> cmCancel then
    begin
      D^.GetFileName(S);
      HistoryAdd(HistoryID, S);
    end;
  FreeObject(D);
  GetFileNameDialog := S;
end;

procedure TFileEditor.OpenFile;
 var
  FileName: PathStr;
begin
 FileName := GetFileNameDialog(x_x, GetString(dlOpenFile),
                               GetString(dlOpenFileName),
                        fdOpenButton + fdHelpButton, hsEditOpen);
 if FileName <> '' then
    begin
      UnlockFile;
      LoadFile(FExpand(FileName));
      if not isValid then
        begin
          isValid := On;
          Message(Owner, evCommand, cmClose, nil);
          Exit;
        end;
      ScrollTo(0,0);
      Owner^.ReDraw;
    end;
end;

procedure OpenEditor;
 var R: TRect;
     P: PWindow;
     S: String;
begin
 S := GetFileNameDialog(x_x, GetString(dlED_OpenFile),
                               GetString(dlOpenFileName),
                        fdOpenButton + fdHelpButton, hsEditOpen);
 if S = '' then Exit;
 Desktop^.GetExtent(R);
 S := FExpand(S);
 Application^.InsertWindow(New(PEditWindow, Init(R, S)));
end;

procedure FileChanged(const Name: PathStr);
 var Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
begin
 FSplit(Name, Dr, Nm, Xt); Abort := Off;
 GlobalMessage(evCommand, cmRereadDir, @Dr);
 GlobalMessage(evCommand, cmRereadInfo, nil);
 GlobalMessage(evCommand, cmRereadTree, @Dr);
end;

procedure TFileEditor.SaveFileAs;
 var
  FileName: PathStr;
  S: PStream;
begin
 FileName := GetFileNameDialog(x_x, GetString(dlSaveFileAs),
                                   GetString(dlSaveFileAsName),
                               fdOKButton + fdHelpButton, hsEditSave);
  if FileName <> '' then
    begin
      UnlockFile;
      FileName := FExpand(FileName);
      S := CheckForOver(FileName);
      if S = nil then Exit;
      EditName := FExpand(FileName);
      if EditName[Byte(EditName[0])]='.' then Dec(EditName[0]);
      WriteBlock(EditName, S, FileLines, ForcedCRLF, OptimalFill); FreeObject(S);
      FileChanged(EditName);
      DisposeStr(PWindow(Owner)^.Title);
      PWindow(Owner)^.Title := NewStr(GetString(dlEditTitle)+EditName);
      Owner^.Redraw;
      Modified := Off;
      LockFile;
    end;
end;

procedure TFileEditor.ChangeBounds;
begin
 inherited ChangeBounds(R);
 SetLimits;
end;

procedure TFileEditor.SetLimits;
begin
 if HScroll <> nil then HScroll^.SetParams(Delta.X, 0, 255, 1, 1);
 if VScroll <> nil then VScroll^.SetParams(Delta.Y, 0, FileLines^.Count-1, Size.Y, 1);
end;

function TFileEditor.GetSelection;
 var  P: PCollection;
      S: String;
      I: Integer;
begin
 GetSelection := Nil; MemEnough := On ;
 if not (BlockVisible and ValidBlock) or LowMemory then Exit;
 P := New(PLineCollection, Init(Mark.B.Y-Mark.A.Y+1,5));
 for I := Mark.A.Y to Mark.B.Y do
  begin
   S := GetLine(I);
   if VertBlock or (Mark.A.Y = Mark.B.Y) then
     begin
      S := Copy(S, Mark.A.X + 1, Mark.B.X - Mark.A.X);
      if VertBlock and (Mark.B.X - Mark.A.X > Byte(S[0])) then
         S := S + Strg(' ', Mark.B.X - Mark.A.X - Byte(S[0]));
     end
    else if I = Mark.A.Y then S := Copy(S, Mark.A.X + 1, 255)
         else if I = Mark.B.Y then S := Copy(S, 1, Mark.B.X);
   P^.Insert(NewStr(S));
   if LowMemory or not MemOK then begin FreeObject(P);
                                                MemEnough := Off ;
                                                Exit; End;
  end;
 GetSelection := P;
end;

function TFileEditor.Valid(Command: Word): Boolean;
 var I: Word;
     P: Pointer;
     S: String;
     V: Boolean;
begin
  Valid := On; V := On;
  if Command = cmValid then Valid := isValid;
  if SmartPad then
   begin
     if Modified then Message(@Self, evCommand, cmSaveText, nil);
     PEditWindow(Owner)^.ModalEnd := True;
     Exit;
   end;
  if ((Command = cmClose) or (Command = cmQuit)) then
    begin
      if Modified then
        begin
          ModifyLine(Delta.Y, WorkString, On);
          S := Cut(EditName, 30);
          P := @S;
          I := MessageBox(GetString(dlQueryModified), @P, mfWarning+mfYesNoCancel);
          if I = cmYes then
             begin
               Message(@Self, evCommand, cmSaveText, nil);
             end;
          V := not ((I = cmCancel) or (I = cmYes) and Modified);
         end;
      Valid := V;
      if V and not SmartPad and (Owner <> nil) then StoreEditInfo(Owner);
    end;
end;

function TFileEditor.ValidBlock;
begin
 if VertBlock then ValidBlock := ((Mark.A.Y <= Mark.B.Y) and (Mark.A.X < Mark.B.X))
              else ValidBlock := (Mark.A.Y < Mark.B.Y) or
                                 ((Mark.A.Y = Mark.B.Y) and (Mark.A.X < Mark.B.X));
end;


function TFileEditor.Search;
 label 1;
 var I, J, TrX, StX: Integer;
     D,DD: TPoint;
     T: TRect;
     W, S, S1: String;
     F, Prompt: Boolean;
     OldMark: TRect;
     NumRep: LongInt;
     Dir: Integer;
     OldCache: Boolean;
     Tmr: TEventTimer;

procedure _DrawViews;
begin
 DrawView;
 HScroll^.DrawView;
 VScroll^.DrawView;
end;

label
  LExit, _LExit;

begin
 NewTimer(Tmr, 0);
 OldCache := PBlocker(FileLines)^.UseCache;
 Marking := Off;
 OldMark := Mark;
 if (SearchData.Scope = 1) and not (BlockVisible and ValidBlock) then goto LExit;
 Search := Off; F := On; Prompt := SearchData.Options and 4 <> 0;
 D := Delta; W := SearchData.Line; if W = '' then goto LExit;
 if SearchData.Options and 1 = 0 then W := UpCaseStr(W);
 UnMark := Off;
 NumRep := 0;
 Dir := 1 - 2 * SearchData.Dir;
 while (Dir > 0) and (D.Y < FileLines^.Count) or
       (Dir < 0) and (D.Y >= 0) do
    begin
1:   S1 := GetLine(D.Y); TrX := Length(S1); S := S1;
     PBlocker(FileLines)^.UseCache := True;
     if (Dir < 0) then
       begin
        if (D.X > Length(S1)) then D.X := Length(S1);
        StX := 1; TrX := D.X;
        if SearchData.Scope = 1 then
         begin
            Mark := OldMark;
            if D.Y < Mark.A.Y then Break;
            if D.Y > Mark.B.Y then begin Dec(D.Y); D.X := 255; Continue; end;
            if (D.Y = Mark.B.Y) and (D.Y = Mark.A.Y) or VertBlock then
                if StX < Mark.A.X then StX := Mark.A.X + 1;
            if (D.Y = Mark.B.Y) or VertBlock then
               if TrX > Mark.B.X then TrX := Mark.B.X;
         end;
        if TrX < StX then I := 0
                     else I := BackSearchFor(W, S1[StX], TrX - StX + 1, SearchData.Options and 1 <> 0);
       end else
           begin
             StX := D.X + 1;
             if SearchData.Scope = 1 then
              begin
               Mark := OldMark;
               if D.Y < Mark.A.Y then begin Inc(D.Y); D.X := 0; Continue; end;
               if D.Y > Mark.B.Y then Break;
               if (D.Y = Mark.B.Y) and (D.Y = Mark.A.Y) or VertBlock then
                   if StX < Mark.A.X then StX := Mark.A.X + 1;
               if (D.Y = Mark.B.Y) or VertBlock then TrX := Mark.B.X;
              end;
              if TrX < StX then I := 0
                           else I := SearchFor(W, S1[StX], TrX - StX + 1, SearchData.Options and 1 <> 0);
           end;

     if (I > 0) and (SearchData.Options and 2 <> 0) then
         if not (((StX-1+I = 1) or (S1[StX-1+I-1] in BreakChars)) and
            ((StX - 1 + I + Length(W) > Length(S1)) or (S1[StX-1 + I + Length(W)] in BreakChars))) then
              begin
                if Dir > 0 then D.X := StX+I
                           else D.X := StX+I-1;
                Goto 1;
              end;

     if I > 0 then
      begin
       Search := On; F := Off;
       DD.Y := D.Y; DD.X := StX + I - 2; D := DD;
       if Dir > 0 then Inc(D.X, Length(W));
       Delta := D;
       HScroll^.Value := D.X; {HScroll^.DrawView;}
       VScroll^.Value := D.Y;
       if TimerExpired(Tmr) then
       begin
         VScroll^.DrawView;
         NewTimer(Tmr, 1);
       end;
       if (D.Y - Pos.Y > Size.Y) then Pos.Y := D.Y - Size.Y div 2
         else if (D.Y < Pos.Y) then Pos.Y := Max(0, D.Y-5);
       if (D.X - Pos.X > Size.X - 10) then Pos.X := D.X - Size.X div 2
         else if (D.X < Pos.X) then Pos.X := Max(0, D.X-5);
       SearchActive := On;
       if (SearchData.What = #0) or Prompt then _DrawViews
                                           else Inc(NumRep);
       SearchActive := Off;
       if SearchData.What <> #0 then
        begin
         J := cmYes;
         if Prompt then
          begin
           I := 50;
           T.A.Y := Delta.Y - Pos.Y; MakeGlobal(T.A, T.A);
           Desktop^.MakeLocal(T.A, T.A);
           T.A.X := (Desktop^.Size.X - I) div 2; T.B.X := T.A.X + I;
           if {(T.A.Y >= (Desktop^.Size.Y-12) div 2) and}
              (T.A.Y <= (Desktop^.Size.Y{+12}) div 2) then T.A.Y := (Desktop^.Size.Y+4) div 2
                   else T.A.Y := (Desktop^.Size.Y-18) div 2;
           T.B.Y := T.A.Y + 8;
           J := MessageBoxRect(T, GetString(dlQueryReplace), nil,
                    mfQuery+mfYesButton+mfAllButton+mfNoButton+mfCancelButton);
           if J = cmOK then begin J := cmYes; ReplaceAll := On; Prompt := Off end;
          end;
         if J = cmCancel then begin Mark := OldMark; _DrawViews; goto LExit; end;
         if J = cmYes then
          begin
           Modified := On;
           S := Copy(S1, DD.X + 1, Length(W));
           Insert(Char(Length(SearchData.What)), S, 1);
           StoreUndoInfo(udReplace, DD, S);
           Delete(S1, DD.X+1, Length(W));
           Insert(SearchData.What, S1, DD.X+1);
           PBlocker(FileLines)^.UseCache := False;
           ModifyLine(Delta.Y, S1, On); WorkModified := Off;
           if Dir > 0 then Dec(Delta.X, Length(W) - Length(SearchData.What));
           if (SearchData.What = #0) or Prompt then ScrollTo(Delta.X, Delta.Y);
           D := Delta;
           if (SearchData.What = #0) or Prompt then _DrawViews;
          end;
         if ReplaceAll then Goto 1
                       else begin
                              Mark := OldMark;
                              _DrawViews; goto LExit;
                            end;
        end
          else begin Mark := OldMark; LastPos.X := -1; {DrawView; }goto _LExit; end;
      end;
     if Dir > 0 then begin D.X := 0; Inc(D.Y); end
                else begin D.X := 255; Dec(D.Y); end;
  end;
  if F then MessageBox(GetString(dlDBViewSearchNot), nil, mfError+mfOKButton)
    else
      begin
        Mark := OldMark;
        _DrawViews;
      end;
  UnMark := On;
  if NumRep > 0 then
    begin
      MessageBox(GetString(dlReplacesMade), @NumRep, mfOkButton+mfInformation);
      ScrollTo(Delta.X, Delta.Y);
      _DrawViews;
    end;
LExit:
 _DrawViews;
_LExit:
 PBlocker(FileLines)^.UseCache := OldCache;
end;

procedure TFileEditor.InsertBlock;
 var I: Integer;
     S, S1, S2: String;
     P: PString;
     L: LongInt;
     LL: PCollection;
begin
 if (ABlock = nil) or (ABlock^.Count = 0) then Exit;
 Modified := On;
 if SaveUndo then
  begin
    Mark.B := Delta; Mark.A := Delta; BlockVisible := On;
    Inc(Mark.B.Y, Max(0, ABlock^.Count - 1));
  end;
 if VertBlock then
  begin
   P := ABlock^.At(0);
   if P <> nil then S := P^ else S := '';
   I := Byte(S[0]);
   L := LongInt(I);
   L := L shl 16;
   L := L or ABlock^.Count;
   if SaveUndo then
     if InsertMode then StoreUndoInfo(udInsVertBlock, Delta, L)
      else
       begin
        P := ABlock^.At(0); if P = nil then S := '' else S := P^;
        LL := New(PLineCollection, Init(ABlock^.Count, 10));
        if LL <> nil then
         begin
           for I := 0 to ABlock^.Count do
             LL^.Insert(NewStr(AddSpace(Copy(GetLine(I+Delta.Y), Delta.X+1, Length(S)),Length(S))));
           StoreUndoInfo(udReplaceBlock, Delta, LL)
         end;
       end;
   for I := 1 to ABlock^.Count do
    begin
     P := ABlock^.At(I-1); if P <> nil then S1 := P^ else S1 := '';
     if SaveUndo then Mark.B.X := Mark.A.X + Length(S1);
     if I + Delta.Y - 1 = FileLines^.Count then FileLines^.Insert(NewStr(''));
     S2 := GetLine(I+Delta.Y-1);
     if not InsertMode then Delete(S2, Delta.X + 1, Byte(S1[0]));
     if Byte(S2[0]) < Delta.X then S2 := S2 + Strg(' ', Delta.X - Byte(S2[0]));
     Insert(S1, S2, Delta.X + 1);
     ModifyLine(I+Delta.Y-1, S2, On);
    end
   end
   else
  begin
   I := ABlock^.Count;
   S := Char(Lo(I)) + Char(Hi(I)) + GetLine(Delta.Y);
   if SaveUndo then StoreUndoInfo(udInsBlock, Delta, S);
   Delete(S, 1, 2);
   if Delta.X > Byte(S[0]) then S := S + Strg(' ', Delta.X - Byte(S[0]));
   S1 := Copy(S, 1, Delta.X); S2 := Copy(S, Delta.X+1, 255);
   FileLines^.AtFree(Delta.Y);
   for I := 1 to ABlock^.Count do
    begin
     P := ABlock^.At(I-1); if P <> nil then S := P^ else S := '';
     if I = 1 then S := S1 + S;
     if I = ABlock^.Count then
       begin if SaveUndo then Mark.B.X := Length(S); S := S + S2; end;
     FileLines^.AtInsert(Delta.Y + I - 1, NewStr(S));
    end
   end;
 SetLimits;
 if GetState(sfVisible) then DrawView;
end;

procedure TFileEditor.DoHighlite;
 label 1,10,11;
 var LPos,I: Integer;
     LP: Integer;

  procedure SearchComments(const St, En: String);
    var I: Integer;
  begin
     repeat
       LP := System.Pos(St, S);
       if LP > 0 then
         begin
           I := System.Pos(En, Copy(S,LP,Size.X));
           if I = 0 then LPos := Length(S) - LP + 1
                    else LPos := I + Length(En) - 1;
           if LPos < 1 then LPos := 1;
           FillChar(S[LP], LPos, 0);
           Dec(LP, Pos.X);
           if LP <= 0 then begin Inc(LPos, LP-1); LP := 1; end;
           if LPos > 0 then
             MoveColor(TWordArray(B)[LP-1], Min(Size.X+1, LPos), Comments);
         end;
     until LP = 0;
  end;

begin
   S[0] := Char(Min(Size.X+Pos.X, Length(S)));
   LPos := 1;
   asm
     lea di, S
     mov cl, ss:[di]
     xor ch, ch
   @1:
     inc di
     mov al, ss:[di]
     cmp al, ' '
     jnz @2
     inc LPos
     loop @1
   @2:
   end;
   for I := 1 to NumCommentStartChars do
       if S[LPos] = CommentStartChars[I] then Goto 1;
   LPos := 0;
   for I := 1 to NumCommentChars do
     begin
        LP := PosChar(CommentChars[I], S);
        if ((LPos = 0) or (LP < LPos)) and (LP > 0) then LPos := LP;
     end;
   for I := 1 to NumCommentStrings do
     begin
        LP := System.Pos(CommentStrings[I], UpStrg(S));
        if ((LPos = 0) or (LP < LPos)) and (LP > 0) then LPos := LP;
     end;
 1:
   if (LPos > 0) then
    begin
     S[0] := Char(LPos-1);
     Dec(LPos, Pos.X + 1);
     if LPos < 0 then LPos := 0;
     MoveColor(TWordArray(B)[LPos], Size.X, Comments);
    end;
   LP := -Pos.X*2+1;
   if not CommentsOnly then
     asm
       lea  di, S
       les  si, B
       mov  bx, LP
       mov  ch, ss:[di]
       inc  di
       xor  ah, ah
       or   ch, ch
       mov  dh, 0
       jz   @@3
    @@1:
       mov  al, ss:[di]
       cmp  al, ''''
       jz   @StartComm
       cmp  al, '"'
       jz   @StartComm
       or   ah, ah
       jz   @@2
     @@4:
       xor  dx, dx
       mov  ss:[di], dl
       mov  dl, Strings
       mov  es:[si+bx], dl
       jmp  @@6
     @@2:
       push di
       push dx
       lea  di, BreakChars
       xor  dh, dh
       mov  cl, 3
       mov  dl, al
       shr  dl, cl
       add  di, dx
       mov  cl, al
       and  cl, 7
       mov  dl, 1
       shl  dl, cl
       test dl, ds:[di]
       pop  dx
       pop  di
       jz   @@7
       xor  dh,dh
       mov  dl, Symbols
       mov  es:[si+bx], dl
       jmp  @@6
     @@7:
       test dh, 1
       jnz  @@6
       cmp  al, '0'
       jc   @@8
       cmp  al, '9'+1
       jnc  @@8
       mov  dh, 2
     @@11:
       mov  dl, Numbers
       mov  es:[si+bx], dl
       jmp  @@6
     @@8:
       cmp dh, 2
       jnz @@9
       cmp al, 'X'
       jz @@10
       cmp al, 'H'
       jz @@10
       cmp al, 'h'
       jz @@10
       cmp al, 'A'
       jc @@9
       cmp al, 'F'+1
       jc @@10
       cmp al, 'a'
       jc  @@13
       cmp al, 'f'+1
       jc  @@10
    @@13:
       cmp al, 'O'
       jz @@10
       cmp al, 'o'
       jz @@10
       cmp al, 'x'
       jnz @@9
     @@10:
       jmp @@11
     @@9:

       mov dh, 1
     @@6:
       add  bx, 2
       inc  di
       dec  ch
       or   ch, ch
       jnz  @@1
       jmp  @@3
  @StartComm:
       cmp  ah, al
       jnz  @@5
       xor  ah, ah
       jmp  @@4
     @@5:
       or   ah, ah
       jnz  @@4
       mov  ah, al
       jmp  @@4
     @@3:
     end;
   if C_Comments then
     begin
       SearchComments('/*','*/');
     end;
   if X_Comments then
     begin
       SearchComments('<','>');
     end;
   if Pas_Comments then
     begin
       SearchComments('(*','*)');
       SearchComments('{','}');
     end;
end;

procedure TFileEditor.Draw;
var
  C, BC, Comments: Byte;
  CC: Array[1..10] of Byte;
  I, A: Integer;
  S: String;
  P: PString;
  WM, BV: Boolean;
  X1, X2: Integer;
  LPos: Integer;
  Ch: Char;

  procedure DrawBlock;
  begin
   X1 := Mark.A.X - Pos.X; if X1 < 0 then X1 := 0;
   X2 := Mark.B.X - Pos.X; if X2 < 0 then X2 := 0;
   if VertBlock or (Mark.A.Y = Mark.B.Y) then
    begin
      if (X1 = X2) or (X1 > Size.X) then Exit;
      if (X2 > Size.X) then X2 := Size.X;
      MoveColor(B[X1], X2-X1, BC);
    end else
        begin
         if A = Mark.A.Y then begin if X1 < Size.X then MoveColor( B[X1], Size.X - X1, BC) end
                else if A = Mark.B.Y then
                        begin
                         if (X2 > Size.X) then X2 := Size.X;
                         MoveColor(B, X2, BC);
                        end else MoveColor(B, Size.X, BC);
        end;
  end;

  var BB: TPoint;

begin
  BB := Pos;
  SearchOnDisplay := Off;
  if Pos.X < 0 then Pos.X := 0;
  if Pos.Y < 0 then Pos.Y := 0;
  if Delta.X < 0 then Delta.X := 0;
  if Delta.X > 254 then Delta.X := 254;
  if Delta.Y >= FileLines^.Count then Delta.Y := FileLines^.Count - 1;
  if Delta.Y < 0 then Delta.Y := 0;
  if Pos.X > Delta.X then Pos.X := Delta.X;
  if Delta.X - Pos.X >= Size.X then Pos.X := Delta.X - Size.X + 8;
  if Pos.Y > Delta.Y then Pos.Y := Delta.Y;
  if Delta.Y - Pos.Y >= Size.Y then Pos.Y := Delta.Y - Size.Y + 1;
  if (BB.X <> Pos.X) or (BB.Y <> Pos.Y) then ChPosition := Off;
  if Marking then
     begin
       ChPosition := Off;
       Sel.B.X := Delta.X; Sel.B.Y := Delta.Y;
       if LineMarking and (Sel.B.Y < FileLines^.Count - 1) then
        begin
         if Sel.B.Y >= Sel.A.Y then Inc(Sel.B.Y);
         Sel.B.X := 0;
        end;
       Mark := Sel;
       if not VertBlock then
        if (Mark.A.Y > Mark.B.Y) or ((Mark.A.Y = Mark.B.Y) and (Mark.A.X > Mark.B.X))
        then begin Mark.A := Sel.B; Mark.B := Sel.A; end else
        else
        begin
         if Mark.A.X > Mark.B.X then begin Mark.B.X := Mark.A.X; Mark.A.X := Sel.B.X; end;
         if Mark.A.Y > Mark.B.Y then begin Mark.B.Y := Mark.A.Y; Mark.A.Y := Sel.B.Y; end;
        end;
     end;
  BV := BlockVisible and ValidBlock and not SearchActive;
  C := GetColor(1);WM:=not WorkModified;
  BC := GetColor(2);
  for I := 1 to 10 do CC[I] := GetColor(I);
  Comments := GetColor(3);
  for I := 0 to Size.Y - 1 do
  begin
    A := Pos.Y + I;
    if BV and not VertBlock then
     begin
        if (A = Mark.A.Y) then
          begin
            if WorkModified and (Mark.A.Y = Delta.Y) then
             if Mark.A.X > Byte(WorkString[0]) then Mark.A.X := Byte(WorkString[0])
               else else
             if Mark.A.X > Length(GetLine(Mark.A.Y)) then Mark.A.X := Length(GetLine(Mark.A.Y));
          end;
        if (A = Mark.B.Y) then
         begin
           if WorkModified and (Mark.B.Y = Delta.Y) then
            if Mark.B.X > Byte(WorkString[0]) then Mark.B.X := Byte(WorkString[0])
            else else
            if Mark.B.X > Length(GetLine(Mark.B.Y)) then Mark.B.X := Length(GetLine(Mark.B.Y));
         end;
     end;
    if ChPosition and not ((A = Delta.Y) or (A = LastPos.Y)) then Continue;
    if HiliteLine then
    if A = Delta.Y then
     begin
      C := CC[4];
      BC := CC[5];
      Comments := CC[6];
     end else
     begin
      C := CC[1];
      BC := CC[2];
      Comments := CC[3];
     end;
    MoveChar(B, ' ', C, Size.X);
    if A < FileLines^.Count then
    begin
      if WM or (A <> Delta.Y) then S := GetLine(A) else S := WorkString;
      MoveStr(B, Copy(S, Pos.X + 1, Size.X), C);
      if HiLite > 0 then DoHighlite(B, S, A, Comments, $1F, $1A,
                                      (CC[8] and 15) or (C and $F0),
                                      (CC[9] and 15) or (C and $F0),
                                      (CC[10] and 15) or (C and $F0));
      if RulerVisible and (A = Delta.Y)
        then
          begin
             FreeStr := '123456789'; Ch := '1';
             while CStrLen(FreeStr) < Size.X do
               begin
                 FreeStr := FreeStr+'~'+Ch+'~'+Copy(FreeStr, 1, 9);
                 Inc(Ch); if Ch > '9' then Ch := '0';
               end;
             MoveCStr(B[Delta.X-Pos.X],FreeStr, Application^.GetColor($4240));
          end;
    end;
    if BV and (A >= Mark.A.Y) and (A <= Mark.B.Y) then DrawBlock;
    if SearchActive and (A = Delta.Y) then
     begin
      X2 := Length(SearchData.Line);
      X1 := Delta.X - Pos.X;
      if SearchData.Dir = 0 then Dec(X1, X2);
      if X1 < 0 then begin Inc(X2, X1); X1 := 0; end;
      MoveColor(B[X1], X2, BC);
      SearchOnDisplay := On;
     end;
    if HiliteColumn then WordRec(B[Delta.X - Pos.X]).Hi := CC[7];
    WriteLine(0, I, Size.X, 1, B);
  end;
 SetCursor(Delta.X - Pos.X, Delta.Y - Pos.Y);
 if InsertMode xor (InterfaceData.Options and ouiBlockInsertCursor <> 0)
    then NormalCursor else BlockCursor;
 ShowCursor;
 LastPos.X := Delta.X;
 LastPos.Y := Delta.Y;
 if PEditWindow(Owner)^.AInfo <> nil then PEditWindow(Owner)^.AInfo^.Draw;
 ChPosition := Off;
end;

function TFileEditor.GetLine(Index : Integer) : String;
 var p: PString;
begin
 if (Index < FileLines^.Count) and (Index >= 0) then p := FileLines^.At(Index)
                                                else p := Nil;
 if p <> Nil then GetLine := p^ else GetLine := '';
end;

procedure TFileEditor.SaveFile;
 var S: PBufStream;
     I: Integer;
     F: File;
     Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     OldAttr: Word;
     L: array[0..0] of LongInt;
begin
 UnlockFile;
 if EditName = 'Untitled.TXT' then begin SaveFileAs; Exit end;
 Assign(F, EditName); ClrIO;
 GetFAttr(F, OldAttr);
 if (IOResult = 0) and (OldAttr and ReadOnly <> 0) then
 begin
   Pointer(L[0]) := @EditName;
   if Msg(dlED_ModifyRO, @L, mfConfirmation+mfOKCancel)<>cmOK then Exit;
 end;

 ClrIO; if OldAttr <> Archive then SetFAttr(F, Archive); if Abort then Exit;
 if EditorDefaults.EdOpt and ebfCBF <> 0 then
  begin
   FSplit(EditName, Dr, Nm, Xt); ClrIO;
   EraseFile( Dr+Nm+'.BAK' );
   Assign(F, EditName); Rename(F, Dr+Nm+'.BAK'); ClrIO;
  end;
 New(S, Init(EditName, stCreate, 4096));
 if S = nil then Exit;
 if S^.Status <> stOK then
   begin
    CantWrite(EditName);
    FreeObject(S);
    LockFile;
    Exit;
   end;
 WriteBlock(EditName, S, FileLines, ForcedCRLF, OptimalFill); FreeObject(S);
 Assign(F, EditName); ClrIO; if OldAttr <> Archive then SetFAttr(F, OldAttr or Archive); ClrIO;
 LockFile;
 Modified := Off;
 Owner^.Redraw;
 if not SmartPad then FileChanged(EditName);
end;

procedure TFileEditor.ModifyLine;
begin
 if (Index < 0) or (Index >= FileLines^.Count) then Exit;
 if DelSpaces then DelRight(S);
 FileLines^.AtReplace(Index, NewStr(S));
end;

function TFileEditor.HandleCommand;
begin
end;

procedure TFileEditor.HandleEvent;
 label 1,2;
 var ChPos,WM,DelWord,WasMA,WasMB: Boolean;
     P: PString;
     PL: PCollection;
     S: String;
     LastY,LastX,i: Integer;
     WL: Byte absolute WorkString;
     OldDelta,
     T: TPoint;

 procedure BlockOff;
 begin
  UnMark := On; Marking := Off; ChPosition := Off;
  if EditorDefaults.EdOpt and ebfPbl <> 0 then Exit;
  Mark.B := Mark.A; BlockVisible := Off;
 end;

 procedure InsertSpace;
  var P: TPoint;
 begin
  P.X := LastX; P.Y := LastY;
  if InsertMode then
    begin
     if LastX < WL then Insert(' ', WorkString, LastX + 1)
                   else WorkString := WorkString + Strg(' ', LastX - WL + 1);
     StoreUndoInfo(udInsChar, P, P);
    end
     else
      begin
       if LastX< WL then
        begin
         P.X := LastX;
         StoreUndoInfo(udReplaceChar, P, WorkString[LastX + 1]);
         WorkString[LastX + 1] := ' ';
        end;
      end;
  Inc(LastX);
 end;

 procedure WorkModify;
 begin
  if WorkModified then Exit;
  LastLine := Delta.Y;
  LastShape := GetLine(LastLine);
  WorkModified := On; Modified := On; WasDelete := Off;
 end;

 procedure ChangeLine;
  label Ex;
 begin
   if not WorkModified then goto Ex;
   While WorkString[WL] = ' ' do Dec(WL);
   if WorkModified then ModifyLine(LastLine, WorkString,On);
   Modified := Modified or WorkModified;
   WorkModified := Off;
 Ex:
   WorkString := GetLine(Delta.Y);
 end;

 procedure MakeEnter;
  var I, J: Integer;
      OldS,s1,s2: String;
      Bl: Boolean;
      WBY,WAY: Boolean;
 begin
   BlockOff;
   Bl := ValidBlock and not VertBlock;
   if not InsertMode then
   begin
    ChangeLine;
    if Delta.Y = FileLines^.Count - 1 then
      begin
        FileLines^.Insert(nil);
        SetLimits;
      end;
    ScrollTo(0, Delta.Y + 1);
   end else
       begin
        ChangeLine;
        Modified := On;
        WorkModified := Off;
        OldS := WorkString;
        WAY := Bl and (Delta.Y = Mark.A.Y) and (Delta.X <= Mark.A.X);
        WBY := Bl and (Delta.Y = Mark.B.Y) and (Delta.X <= Mark.B.X);
        StoreUndoInfo(udInsLine, Delta, WorkString);
        While WorkString[WL] = ' ' do Dec(WL);
        S1 := WorkString; S2 := Copy(S1, 1, LastX);
        While S2[Byte(S2[0])] = ' ' do Dec(S2[0]);
        WorkString := S2; Delete(S1, 1, LastX);
        ModifyLine(LastY,S2,On);
        WorkString := S1;
        if AutoIndent then
         begin
          I := LastY - 1;
          While (WorkString[1] = ' ') and (WorkString <> '') do
            begin
              DelFC(WorkString);
              if WAY then Dec(Mark.A.X);
              if WBY then Dec(Mark.B.X);
            end;
          if DelSpaces(S2) = '' then S2 := OldS;
          {While (S2 = '') and (I >= 0) do
          if I >= 0 then
           begin S2 := GetLine(I); Dec(I) end;}
          LastX := 0;
          While (S2[LastX + 1] = ' ') and (LastX < Byte(S2[0]))
           do begin
                 Inc(LastX);
                 WorkString := ' ' + WorkString;
                 if WAY then Inc(Mark.A.X);
                 if WBY then Inc(Mark.B.X);
              end;
         end else LastX := 0;
        FileLines^.AtInsert(LastY + 1, NewStr(WorkString));
        SetLimits; Delta.X := LastX; Inc(Delta.Y);
       end;
 end;

 procedure MakeBack;
  var I, J : Byte;
      P: TPoint;
 begin
  WorkModify; BlockOff; Modified := On;
  ClearEvent(Event);
  if LastX = 0 then
   begin
    if (LastY = 0) or not InsertMode then Exit;
    EnableMarking := Off;
    FileLines^.AtFree(LastY);
    S := GetLine(LastY - 1);
    P.X := Length(S); P.Y := Delta.Y - 1;
    StoreUndoInfo(udSubDelLine, P, WorkString);
    WorkString := S + WorkString; ModifyLine(LastY - 1, WorkString, On);
    WorkModified := Off; WorkModify; WorkModified := Off;
    Delta.X := Byte(S[0]);
    ScrollTo(Delta.X, Delta.Y - 1);
    SetLimits;
    ChangeLine;
    DrawView;
    EnableMarking := On;
    Exit;
   end;
  EnableMarking := Off;
  if WL < LastX then WorkString := AddSpace(WorkString, LastX + 1);
  if BackIndent and ((WorkString[LastX + 1] <> ' ') or (DelSpaces(WorkString) = ''))
   and (Copy(WorkString, 1, LastX) = Strg(' ', LastX))
   and (LastY > 0) then
    begin
     for i := LastY-1 downto 0 do
      begin
       s := GetLine(i);
       J := 0; while (S[J+1] = ' ') and (J < Byte(S[0])) do Inc(J);
       if J < LastX then
       if Copy(s, 1, LastX) > Strg(' ', LastX) then
         begin
          T.X := LastX; T.Y := LastY;
          StoreUndoInfo(udSubDel, T, WorkString);
          Delete(WorkString, 1, LastX); LastX := J;
          Insert(Strg(' ', J), WorkString, 1);
          ScrollTo(LastX, Delta.Y);
          ChangeLine;
          DrawView;
          EnableMarking := On;
          Exit;
         end;
      end;
    end;
  T.X := LastX; T.Y := LastY;
  if LastX <= WL then
    if InsertMode then
      begin
        StoreUndoInfo(udBackDel, T, WorkString[LastX]);
        Delete(WorkString, LastX, 1);
      end else
      begin
        T.X := LastX-1;
        StoreUndoInfo(udReplaceChar, T, WorkString[LastX]);
        WorkString[LastX] := ' ';
      end;
  ScrollTo(Delta.X - 1, Delta.Y);
  ChangeLine;
  EnableMarking := On;
 end;

 procedure BlockDelete(ChangePos: Boolean);
  var I: Integer;
      S, S1, S2: String;
 begin
  Modified := On;
  if VertBlock then
   begin
    if ChangePos and InsertMode then
     begin
       if (Delta.Y >= Mark.A.Y) and (Delta.X >= Mark.A.X) and
          (Delta.Y <= Mark.B.Y) then
        begin
          Delta.X := Max(Mark.A.X, Delta.X-(Mark.B.X-Mark.A.X));
        end;
     end;
    for I := Mark.A.Y to Mark.B.Y do
    begin
     S := GetLine(I);
     Delete(S, Mark.A.X + 1, Mark.B.X - Mark.A.X);
     if not InsertMode then Insert(Strg(' ', Mark.B.X - Mark.A.X), S, Mark.A.X + 1);
     ModifyLine(I, S, On);
    end;
   end else
   begin
    if ChangePos then
     begin
       if (Delta.Y = Mark.A.Y)  then
         begin
           if (Delta.X > Mark.A.X) then
           if (Delta.Y = Mark.B.Y) and (Delta.X > Mark.B.X) then
             Dec(Delta.X, Mark.B.X-Mark.A.X) else
             Delta.X := Mark.A.X;
         end else
       if (Delta.Y = Mark.B.Y) then
        begin
          Dec(Delta.X, Mark.B.X);
        end else
        if Delta.Y < Mark.A.Y then else
        if Delta.Y > Mark.B.Y then Dec(Delta.Y, Mark.B.Y - Mark.A.Y)
         else Delta := Mark.A;
     end;
    ModifyLine(Mark.A.Y, Copy(GetLine(Mark.A.Y),1,Mark.A.X) +
                         Copy(GetLine(Mark.B.Y),Mark.B.X+1,255), On);
    for I := Mark.A.Y to Mark.B.Y - 1 do
        FileLines^.AtFree(Mark.A.Y + 1);
   end;
 end;

 procedure MakeSmallBack;
  var T: TPoint;
 begin
  if LastX > 0 then
   begin
    T.X := LastX; T.Y := LastY;
    StoreUndoInfo(udSubDel, T, WorkString);
    Delete(WorkString, LastX, 1);
   end;
  Dec(LastX);
 end;

 procedure DeleteBlock(ChangePos: Boolean);
  var L: PCollection;
  label L1;
 begin
  if not BlockVisible then Exit;
  EnableMarking := Off; Marking := Off;
  ChangeLine;
  L := GetSelection;
     if (L = nil) then
                     begin
                      if MemEnough then Exit;
                      if UndoInfo<>Nil then UndoInfo^.FreeAll;
                      L := GetSelection;
                      if (L = Nil) and ( not MemEnough ) then Goto L1;
                     end;

  if VertBlock and not InsertMode then StoreUndoInfo(udClearBlock, Mark.A, L)
    else StoreUndoInfo(udDelBlock, Mark.A, L);
L1:
  BlockDelete({not ChangePos} On);
  if ChangePos then
    begin
      Delta := Mark.A;
      Mark.A := Mark.B;
    end;
  LastX := Delta.X; LastY := Delta.Y;
  BlockOff;
  SetLimits;
  ScrollTo(LastX, LastY);
  DrawView;
  ChangeLine;
  EnableMarking := On;
 end;

 procedure BMarking;
 begin
  if not EnableMarking then Exit;
  if (mem[0:$417] and 3 <> 0) and not MouseMark then
  begin
   if not Marking then begin Sel.A := LastPos; Sel.B := Delta end
                  else Sel.B := Delta;
   Marking := On;
   BlockVisible := On;
  end else begin Marking := MouseMark; if Marking then Sel.B := Delta; end;
  if not Marking and UnMark then BlockOff;
 end;

 procedure MakeDel;
  var P: TPoint;
      S: String;
 begin
  WorkModify;
  ChangeLine;
  BlockOff;
  Modified := On;
  if LastX < WL then
   begin WorkModify; P.X := LastX; P.Y := LastY;
         StoreUndoInfo(udDelChar, P, WorkString[LastX+1]);
         Delete(WorkString, LastX + 1, 1); Exit end;
  if LastY + 1 >= FileLines^.Count then Exit;
  WorkModify;
  P.X := LastX; P.Y := LastY;
  S := GetLine(LastY + 1);
  if LastY < FileLines^.Count then StoreUndoInfo(udSubDelLine, P, S);
  WorkString := WorkString + Strg(' ', LastX - WL) + S;
  ChangeLine;
  FileLines^.AtFree(LastY + 1);
  SetLimits;
 end;

 procedure PasteBlock;
 begin
  if SystemData.Options and ossUseSysClip <> 0 then SyncClipOut;
  EnableMarking := Off; Marking := Off;
  ChangeLine;
  if EditorDefaults.EdOpt and (ebfPbl+ebfObl)=ebfObl
    then DeleteBlock(On);
  BlockOff;
  InsertBlock(Clipboard, On);
  ChangeLine;
  memw[$40:$1C] := memw[$40:$1A];
  EnableMarking := On;
 end;

 procedure CopyBlock;
  var R: TRect;
 begin
  ChangeLine;
  if (Clipboard <> nil) then Dispose(Clipboard, Done);
  Clipboard := GetSelection;
  if SystemData.Options and ossUseSysClip <> 0 then SyncClipIn;
 end;

 procedure CenterScreen;
 begin
  Pos.X := Delta.X - Size.X div 2;
  Pos.Y := Delta.Y - Size.Y div 2;
  DrawView;
 end;

 procedure DeleteLine;
 begin
  Modified := On;
  T.Y := LastY; T.X := LastX;
  if Delta.Y + 1 = FileLines^.Count then
   begin
    StoreUndoInfo(udSubDel, T, WorkString);
    ModifyLine(Delta.Y, '', On); WL := 0;
   end else
   begin
    StoreUndoInfo(udDelLine, T, WorkString);
    WorkModified := Off; FileLines^.AtFree(Delta.Y); ChangeLine
   end;
  SetLimits; ScrollTo(0, Delta.Y); DrawView; ChangeLine;
 end;

 procedure WordLeft;
 begin
  if LastX > 0 then
   begin
    if LastX > WL then LastX := WL;
    while (LastX >= 0) and (WorkString[LastX] in BreakChars) do Dec(LastX);
    while (LastX > 0) and not (WorkString[LastX] in BreakChars) do Dec(LastX);
    if (LastX >= 0) and not (WorkString[LastX+1] in BreakChars) then Exit;
   end;
  if LastY <= 0 then begin LastX := 0; Exit end;
  Dec(Delta.Y); Dec(LastY); ChangeLine; LastX := WL; Delta.X := WL; WordLeft;
 end;

 procedure WordRight;
  var B: Boolean;
 begin
  B := LastX < WL;
  while (LastX < WL) and not (WorkString[LastX+1] in BreakChars) do Inc(LastX);
  while (LastX < WL) and (WorkString[LastX+1] in BreakChars) do Inc(LastX);
  if (LastX < WL) or B and (LastX = WL) then Exit;
  if LastY + 1 >= FileLines^.Count then begin LastX := WL; Exit end;
  Inc(Delta.Y); Inc(LastY); LastX := 0; Delta.X := 0; ChangeLine;
  if (WL > 0) and not (WorkString[1] in BreakChars) then Exit;
  WordRight;
 end;

 procedure MakeTab;
 begin
  TabStep := StoI(EditorDefaults.TabSize);
  if TabStep = 0 then TabStep := 8;
  WorkModify;
  repeat InsertSpace; until (LastX) mod TabStep = 0;
  ScrollTo(LastX, Delta.Y); DrawView;
 end;

 procedure DoTab;
 begin
  Modified := On;
  if LastY > 0 then s := GetLine(LastY - 1)
               else s := '';
  if (LastY = 0) then MakeTab
   else
   if (LastY > 0) and (LastX < Byte(S[0])) then
   begin
    WorkModify;
    repeat InsertSpace until (s[LastX + 1] = ' ') or (LastX >= Byte(S[0]));
    {WM := (s[LastX + 2] = ' ') and (LastX < Byte(s[0]));}
    While (s[LastX + 2] = ' ') and (LastX < Byte(s[0])) do InsertSpace;
    {if WM then }InsertSpace;
    ScrollTo(LastX, Delta.Y); DrawView;
   end else MakeTab;
 end;

 procedure BlockRead;
  var P: PCollection;
      S: String;
 begin
  ChangeLine;
  S := GetFileNameDialog(x_x, GetString(dlPasteFromTitle),
                             GetString(dlPasteFromLabel),
                               fdOKButton + fdHelpButton, hsEditPasteFrom);
  if S = '' then Exit;
  S := FExpand(S);
  P := ReadBlock(S, Off);
  if not IsValid then begin isValid := On; Exit; end;
  VertBlock := Off;
  if P <> nil then begin InsertBlock(P, On); FreeObject(P) end;
 end;

 procedure BlockWrite;
  var P: PCollection;
      PS: PStdCollector;
      S, SST: String;
      R: PStream;
      I,J,K: Integer;
      CRLF: String[2];
      VB: Boolean;
      PI: PView;
      A: Word;

  procedure CompressString;
   var I, J, K: Integer;
       PP: Pointer;
  begin
   PP := @SST;
   asm
      les bx, PP
      mov cl, es:[bx]
      inc bx
      xor ch, ch
      jcxz @@Ex
      xor di, di
      xor si, si
      mov byte ptr es:[bx-1], ch
    @@1:
      mov ah, 8
      xor dx, dx
    @@2:
      mov al, es:[bx][si]
      mov es:[bx][di], al
      inc si
      cmp si, cx
      ja  @@Ex
      inc di
      inc byte ptr es:[bx-1]
      cmp al, ' '
      jne @@3
      inc dl
      jmp @@4
     @@3:
      xor Dl, dl
     @@4:
      dec ah
      jnz @@2
      or  dl, dl
      jz @@5
      dec dl
      jz @@5
      sub di, dx
      sub byte ptr es:[bx-1], dl
      mov al, 9
      mov es:[bx][di-1], al
     @@5:
      jmp @@1
    @@Ex:
   end;
  end;

 begin
  if not (BlockVisible and ValidBlock) then Exit;
  ChangeLine;
  S := GetFileNameDialog(x_x, GetString(dlCopyTo),
                                GetString(dlFileName),
                               fdOKButton + fdHelpButton, hsEditPasteFrom);
  if S = '' then Exit;
  S := FExpand(S);
  A := GetFileAttr(S+#0);
  R := CheckForOver(S);
  if R = nil then Exit;

  VB := VertBlock or (Mark.A.Y = Mark.B.Y);

  if EditorDefaults.NewLine = 1 then CrLf := #13 else
    if EditorDefaults.NewLine = 2 then CrLf := #10 else
       crlf := #13#10;

  PI := WriteMsg(^M^M^C+GetString(dlWritingFile));

  for I := Mark.A.Y to Mark.B.Y do
    begin
      if VB then SST := Copy(GetLine(I), Mark.A.X+1, Mark.B.X-Mark.A.X)
            else if I = Mark.A.Y then SST := Copy(GetLine(I), Mark.A.X+1, 255)
                   else if I = Mark.B.Y then SST := Copy(GetLine(I), 1, Mark.B.X)
                     else SST := GetLine(I);
      if OptimalFill then CompressString;
      R^.Write(SST[1], Length(SST));
      if I <> Mark.B.Y then R^.Write(CrLf[1], Length(CrLf));
    end;

  Dispose(R, Done);
  if (A <> 0) and (A <> $FFFF) then SetFileAttr(S+#0, A);

  S := GetPath(FExpand(S));
  GlobalMessage(evCommand, cmRereadDir, @S);
 end;

 procedure CE; begin ClearEvent(Event) end;
 procedure CED; begin ClearEvent(Event); DrawView end;

 var CFind: Boolean;
     EvStr: Array[1..2] of Char;
     PP: TPoint;

 procedure SplitString;
  var S: String;
      I,OldX: Integer;
      P: PLineCollection;
      TP: TPoint;
 begin
  ChangeLine;
  S := '';
  While WorkString[WL] = ' ' do
   begin Dec(WL); if WL < LastX + 1 then LastX := WL - 1; end;
  OldX := 0;
  if WL - 1 = LastX then OldX := 1
     else if WL - 1 < LastX then OldX := 0
       else OldX := 1;
  if WL > RightSide then
   begin
    New(P, Init(1,1)); P^.Insert(NewStr(WorkString));
    TP.Y := Delta.Y; TP.X := 0;
    StoreUndoInfo(udDelBlock, TP, P);
    while (WL > 1) and (WL > RightSide) do
     begin S := WorkString[WL] + S; Dec(WL); end;
    while (WL > 1) and not (WorkString[WL] in [' ',',',':','.','?','!','+',';']) do
     begin S := WorkString[WL] + S; Dec(WL); end;
    if DelSpaces(WorkString) = '' then begin WorkString := WorkString + S; S := ''; end else
    OldX := Delta.X - WL + OldX;
    if Delta.X > WL then Delta.X := 255;
    if System.Pos(DelSpaces(WorkString), WorkString) = 0 then
    begin
     While WorkString[WL] = ' ' do Dec(WL);
     I := 1;
     if AutoJustify then
     while WL < RightSide do
      begin
       while (WorkString[I] = ' ') do Inc(I);
       while (WorkString[I] <> ' ') and (I < WL) do Inc(I);
       if (I < WL) then
        begin
         Insert(' ', WorkString, I);
         if I <= Delta.X then Inc(Delta.X);
        end;
        Inc(I); if I > WL then I := 1;
      end;
     end;
    DelLeft(S);
    S := Strg(' ', LeftSide)+S;
   end;
   ModifyLine(LastY, WorkString, On);
   FileLines^.AtInsert(LastY+1, NewStr(S));
   S := #2#0;
   StoreUndoInfo(udFormatBlock, TP, S);
   if Delta.X >= WL then
    begin
     VScroll^.SetParams(LastY+1, 0, FileLines^.Count-1, Size.Y, 1);
     if OldX>0 then HScroll^.SetValue(LeftSide);
     HScroll^.SetValue(LeftSide + OldX);
    end else
     begin
      VScroll^.SetRange(0, FileLines^.Count-1);
      HScroll^.SetValue(Delta.X);
     end;
   DrawView;
 end;

 procedure InputChar;
  var I1, I2, I3: Byte;
      Ch: Char;
      S1: String[2];
 begin
   Ch := Event.CharCode;
   if AutoBrackets and ((LastX >= WL) or (WorkString[LastX+1] = ' ')) then
    case Ch of
      '(': S1 := '()';
      '{': S1 := '{}';
      '[': S1 := '[]';
        else S1 := Ch;
    end else S1 := Ch;
   EnableMarking := Off;
   if EditorDefaults.EdOpt and (ebfPbl+ebfObl)=ebfObl
     then DeleteBlock(On);
   LastY := Delta.Y;
   LastX := Delta.X;
   BlockOff;
   EnableMarking := Off;
   T := Delta; Inc(T.X);
   if LastX < 255 then
    begin
     WorkModify;
     if InsertMode then
      begin
       if LastX <= WL then Insert(S1, WorkString, LastX + 1)
                      else WorkString := WorkString + Strg(' ', LastX - WL) + S1;
       StoreUndoInfo(udInsChar, Delta, Delta);
       if S1[0] = #2 then
         StoreUndoInfo(udInsChar, T, T);
      end else
      begin
       if LastX >= WL then WorkString := WorkString + Strg(' ', LastX - WL + 1);
       StoreUndoInfo(udReplaceChar, Delta, WorkString[LastX+1]);
       WorkString[LastX+1] := Ch
      end;
     if (not AutoWrap or (LastX < RightSide)) and (LastX < 254) then HScroll^.SetValue(LastX + 1)
      else if LastX < 254 then SplitString else
             begin
              ChangeLine;
              FileLines^.AtInsert(LastY+1, nil); SetLimits;
              ScrollTo(0, LastY+1); DrawView;
             end;
    end;
  CE;
  EnableMarking := On;
 end;

 function AskSave: Word;
  var S: Pointer;
      P: String;
 begin
  P := Cut(EditName, 30);
  S := @EditName;
  AskSave := MessageBox(GetString(dlQueryModified), @S, mfWarning+mfYesNoCancel);
 end;

 procedure PasteWinBlock;
 begin
  EnableMarking := Off; Marking := Off;
  ChangeLine;
  if EditorDefaults.EdOpt and (ebfPbl+ebfObl)=ebfObl
    then DeleteBlock(On);
  BlockOff;

  GetWinClip(PLineCollection(Clipboard));
  InsertBlock(Clipboard, On);

  ChangeLine;
  memw[$40:$1C] := memw[$40:$1A];
  EnableMarking := On;
 end;

 procedure DrawLine(Dir: Byte);
   const
      Line00 = '³ÄÀ³³ÚÃÄÙÄÁ¿´ÂÅ';
      Line11 = 'ºÍÈººÉÌÍ¼ÍÊ»¹ËÎ';
      Line01 = '³ÍÔ³³ÕÆÍ¾ÍÏ¸µÑØ';
      Line10 = 'ºÄÓººÖÇÄ½ÄÐ·¶Ò×';

      UpContact1 =   '³ÃÅ´ÚÂ¿ÆØµÕÑ¸';
      UpContact2 =   'ºÌÎ¹ÉË»Ç×¶ÖÒ·';
      DownContact1 = '³ÃÅ´ÀÁÙÆØµÔÏ¾';
      DownContact2 = 'ºÌÎ¹ÈÊ¼Ç×¶ÓÐ½';
      LeftContact1 = 'ÄÃÅÚÀÂÁÇ×ÖÓÒÐ';
      LeftContact2 = 'ÍÌÎÉÈËÊÆØÕÔÑÏ';
      RightContact1 = 'Ä´Å¿ÙÂÁ¶×·½ÒÐ';
      RightContact2 = 'Í¹Î»¼ËÊµØ¸¾ÑÏ';

   var  _Up, _In, _Down: String;
        L_Up, L_In, L_Down: Char;
        VL: String[32];
        A,B: Word;
        I,J,K: Integer;
        ResChar, C: Char;
        DMode: Byte;

   function GetH0: Byte; begin GetH0 := 2*Byte(PosChar(_In[LastX+2], RightContact1)>0)+
                                        8*Byte(PosChar(_In[LastX], LeftContact1)>0) end;

   function GetH1: Byte; begin GetH1 := 2*Byte(PosChar(_In[LastX+2], RightContact2)>0)+
                                        8*Byte(PosChar(_In[LastX], LeftContact2)>0) end;

   function GetV0: Byte; begin GetV0 :=   Byte(PosChar(_Up[LastX+1], UpContact1)>0)+
                                        4*Byte(PosChar(_Down[LastX+1], DownContact1)>0) end;

   function GetV1: Byte; begin GetV1 :=   Byte(PosChar(_Up[LastX+1], UpContact2)>0)+
                                        4*Byte(PosChar(_Down[LastX+1], DownContact2)>0) end;

   function Modify(C: Char; Mask: Byte): Boolean;
     var I: Integer;
   begin
     Modify := Off;
     VL := Line00; I := PosChar(C, VL);
     if I = 0 then begin VL := Line01; I := PosChar(C, VL); end;
     if I = 0 then begin VL := Line10; I := PosChar(C, VL); end;
     if I = 0 then begin VL := Line11; I := PosChar(C, VL); end;
     if not (I in [7,11,13,14,15]) then Exit;
     Mask := I and not Mask; if Mask = I then Exit;
     if Mask > 0 then ResChar := VL[Mask] else ResChar := ' ';
     Modify := On;
   end;

 begin
   ChangeLine;
   if ShiftState and 3 <> 0 then DMode := 1
     else if ShiftState and 4 <> 0 then DMode := 2 else DMode := 0;
   _In := AddSpace(WorkString, LastX+2);         L_In := _In[0]; _In[0] := ' ';
   _Up := AddSpace(GetLine(LastY-1), LastX+2);   L_Up := _Up[0]; _Up[0] := ' ';
   _Down := AddSpace(GetLine(LastY+1), LastX+2); L_Down := _Down[0]; _Down[0] := ' ';
   if DrawMode > 1 then VL := Line00 else VL := Line11;
   if Odd(Dir) then
     begin
       if DrawMode > 1 then
         begin
           A := GetV1; B := GetH1; VL := Line11;
           if A = 0 then begin A := GetV0; if A <> 0 then VL := Line01 end;
         end else
         begin
           A := GetV0; B := GetH0; VL := Line00;
           if A = 0 then begin A := GetV1; if A <> 0 then VL := Line10 end;
         end;
     end else
     begin
       if DrawMode > 1 then
         begin
           A := GetV1; B := GetH1; VL := Line11;
           if B = 0 then begin B := GetH0; if B <> 0 then VL := Line10 end;
         end else
         begin
           A := GetV0; B := GetH0; VL := Line00;
           if B = 0 then begin B := GetH1; if B <> 0 then VL := Line01 end;
         end;
     end;
   if (LastDir <> Dir) then
   case DMode of
    1: begin
         if LastDir >= 0 then A := A or (1 shl LastDir);
         A := A or B or (1 shl Dir);
         C := VL[A];
         WorkModify;
         if LastX >= WL then WorkString := AddSpace(WorkString, LastX + 1);
         StoreUndoInfo(udReplaceChar, Delta, WorkString[LastX+1]);
         WorkString[LastX+1] := C;
       end;
    2: begin
         if LastDir < 0 then LastDir := (Dir + 2) mod 4;
         A := A or B or (1 shl LastDir) or (1 shl Dir);
         WorkModify;
         if LastX >= WL then WorkString := AddSpace(WorkString, LastX + 1);
         if Modify(_Up[LastX+1], 4) then
           begin
             Dec(Delta.Y); _Up[0] := L_Up;
             StoreUndoInfo(udReplaceChar, Delta, _Up[LastX+1]);
             _Up[LastX+1] := ResChar; ModifyLine(Delta.Y, _Up, On);
             Inc(Delta.Y);
           end;
         if Modify(_Down[LastX+1], 1) then
           begin
             Inc(Delta.Y); _Down[0] := L_Down;
             StoreUndoInfo(udReplaceChar, Delta, _Down[LastX+1]);
             _Down[LastX+1] := ResChar; ModifyLine(Delta.Y, _Down, On);
             Dec(Delta.Y);
           end;
         if (LastX > 0) and Modify(WorkString[LastX], 2) then
           begin
             Dec(Delta.X);
             StoreUndoInfo(udReplaceChar, Delta, WorkString[LastX]);
             WorkString[LastX] := ResChar;
             Inc(Delta.X);
           end;
         StoreUndoInfo(udReplaceChar, Delta, WorkString[LastX+1]);
         WorkString[LastX+1] := ' ';
         if (WL > LastX+1) and (Modify(WorkString[LastX+2], 8)) then
           begin
             Inc(Delta.X);
             StoreUndoInfo(udReplaceChar, Delta, WorkString[LastX+2]);
             WorkString[LastX+2] := ResChar;
             Dec(Delta.X);
           end;
       end;
   end;
   EnableMarking := Off;
   case Dir of
     0: ScrollTo(LastX, LastY-1);
     2: begin
          if LastY = FileLines^.Count - 1 then
            begin
              FileLines^.Insert(nil);
              SetLimits;
            end;
          ScrollTo(LastX, LastY+1);
        end;
     1: ScrollTo(LastX+1, LastY);
     3: ScrollTo(LastX-1, LastY);
   end;
   CED;
   if DMode > 0 then LastDir := (Dir + 2) mod 4
                else LastDir := -1;
   EnableMarking := On;
 end;

 var PC: PCollection;
     R: TRect;

begin
 inherited HandleEvent(Event);
 DelWord := Off;
1:
 LastY := Delta.Y;
 LastX := Delta.X;
 i := FileLines^.Count;
 ChPos:=Off;
 case Event.What of
  evCommand: case Event.Command of
              cmMainMenu: begin
                            Message(DNApp.MenuBar, evCommand, cmMenu, nil);
                            CE;
                          end;
              cmDuplicateLine: begin
                                 ChangeLine;
                                 WorkModify;
                                 FileLines^.AtInsert(LastY+1, NewStr(GetLine(LastY)));
                                 StoreUndoInfo(udDupeLine, Delta, S);
                                 SetLimits;
                                 CED;
                               end;
              cmClose: begin
                         if SmartPad then
                           begin
                             ChangeLine;
                             if Modified then SaveFile;
                             if not Owner^.GetState(sfModal) then Exit;
                             CE; Owner^.Redraw;
                             PEditWindow(Owner)^.ModalEnd := On;
                             ClearEvent(Event);
                           end;
                       end;
              cmUpString, cmLowString, cmCapString,
              cmUpWord, cmLowWord, cmCapWord: begin
                 if DelSpaces (WorkString) <> '' then
                  begin
                     WorkModify;
                     While WorkString[WL] = ' ' do Dec(WL);
                     StoreUndoInfo(udStrModified, Delta, WorkString);
                     if (ShiftState and 3 <> 0)
                       or (Event.Command = cmUpString)
                       or (Event.Command = cmLowString)
                       or (Event.Command = cmCapString) then
                     case Event.Command of
                        cmUpWord, cmUpString: WorkString := UpCaseStr(WorkString);
                        cmLowWord, cmLowString: WorkString := LowCaseStr(WorkString);
                        cmCapWord, cmCapString: WorkString := CapCaseStr(WorkString);
                     end else
                     begin
                       While (LastX > 0) and not (WorkString[LastX] in BreakChars) do Dec(LastX);
                       S := '';
                       While (WL > LastX) and not (WorkString[LastX+1] in BreakChars) do
                          begin S := S + WorkString[LastX+1]; Delete(WorkString, LastX+1, 1); end;
                       if S <> '' then
                       case Event.Command of
                         cmUpWord: S := UpCaseStr(S);
                         cmLowWord: S := LowCaseStr(S);
                         cmCapWord: S := CapCaseStr(S);
                       end;
                       System.Insert(S, WorkString, LastX+1);
                     end;
                  end;
                  CED
                end;
              cmMarkWord: begin
                            ChangeLine;
                            if (LastX < WL) and not (WorkString[LastX+1] in BreakChars) and
                              ((LastX=0) or (WorkString[LastX] in BreakChars)) then else
                             Message(@Self, evCommand, cmWordLeft, nil);
                            if (LastY <> Delta.Y) or (Delta.X < WL) and (WorkString[Delta.X+1] in BreakChars)
                              or (Delta.X >= WL) then
                              begin
                                Message(@Self, evCommand, cmWordRight, nil);
                              end;
                            Mark.A := Delta; Mark.B := Delta;
                            ChangeLine;
                            While (Mark.B.X < WL) and not (WorkString[Mark.B.X+1] in BreakChars) do Inc(Mark.B.X);
                            R := Mark;
                            ScrollTo(LastX, LastY);
                            BlockVisible := On;
                            Mark := R;
                            CED;
                          end;
              cmMarkLine: begin
                            Mark.A.X := 0; Mark.A.Y := Delta.Y;
                            if Delta.Y >= FileLines^.Count-1 then
                              begin Mark.B.Y := Delta.Y; Mark.B.X := WL end
                              else begin Mark.B.Y := Delta.Y+1; Mark.B.X := 0 end;
                            BlockVisible := On; CED
                           end;
              cmMoveBlockStart: begin ScrollTo(Mark.A.X, Mark.A.Y); CE end;
              cmMoveBlockEnd: begin ScrollTo(Mark.B.X, Mark.B.Y); CE end;
              cmSwitchHiLine: begin HiliteLine := not HiliteLine; CED end;
              cmSwitchHiColumn: begin HiliteColumn := not HiliteColumn; CED end;
              cmSwitchWrap: begin AutoJustify := not AutoJustify; CE end;
              cmSwitchFill: begin OptimalFill := not OptimalFill; CE end;
              cmSwitchBack: begin BackIndent := not BackIndent; CE end;
              cmIndentOn,cmIndentOff: begin AutoIndent := Event.Command = cmIndentOn; CE end;
              cmSwitchIndent: begin AutoIndent := not AutoIndent; CE end;
              cmSwitchHighLight: begin
                                  if HiLite < 1 then Inc(HiLite) else HiLite := 0;
                                  DrawView;
                                 end;
              cmSwitchBrackets: begin AutoBrackets := not AutoBrackets; CE end;
              cmSwitchSave: begin
                              AutoWrap := not AutoWrap; CE
                            end;
              cmGetName: PString(Event.InfoPtr)^ := PWindow(Owner)^.Title^;
              cmCtrlHome: begin ScrollTo(Delta.X, Pos.Y); CED end;
              cmCtrlEnd: begin ScrollTo(Delta.X, Pos.Y+Size.Y-1); CED end;
              cmDeltoEOLN: begin WorkModify; StoreUndoInfo(udSubDel, Delta, WorkString);
                                 WL := LastX; CED; end;
              cmCopyBlock: begin
                             CE; if not ValidBlock then Exit;
                             ChangeLine;
                             PC := GetSelection;
                             if PC = nil then
                               begin
                                  Message(@Self, evCommand, cmCopy, nil);
                                  Message(@Self, evCommand, cmPaste, nil);
                               end else
                               begin
                                 ChangeLine;
                                 InsertBlock(PC, On);
                                 Dispose(PC, Done);
                               end;
                             ChangeLine;
                           end;
              cmMoveBlock: begin
                             ChangeLine;
                             CE; if not ValidBlock then Exit;
                             PC := GetSelection;
                             if PC = nil then
                               begin
                                  Message(@Self, evCommand, cmCopy, nil);
                                  DeleteBlock(Off);
                                  Message(@Self, evCommand, cmPaste, nil);
                               end else
                               begin
                                 ChangeLine;
                                 DeleteBlock(Off);
                                 InsertBlock(PC, On);
                                 Dispose(PC, Done);
                               end;
                               ChangeLine;
                           end;
              cmReverseSearch: begin
                                 ChangeLine;
                                 SearchData.Dir := SearchData.Dir xor 1;
                                 if SearchOnDisplay then Search;
                                 Search;
                                 SearchData.Dir := SearchData.Dir xor 1;
                                 ChangeLine; CE;
                                 SearchOnDisplay := Off;
                               end;
              cmWindowsPaste: PasteWinBlock;
              cmBracketPair,
              cmPlayMacro,
              cmSelectMacro,
              cmSetMargins,
              cmGotoLineNumber,
              cmSortBlock,
              cmCalcBlock,
              cmInsertDate,
              cmInsertTime,
              cmPrintBlock,
              cmPrintFile,
              cmFRight, cmFLeft, cmFJustify, cmFCenter,
              cmLRight, cmLLeft, cmLJustify, cmLCenter,
              cmIndentBlock,
              cmUnIndentBlock,
              cmUndo,
              cmReplace,
              cmUpcaseBlock,
              cmLowcaseBlock,
              cmCapitalizeBlock,
              cmWindowsCopy,
              cmSyncClipIn,
              cmSyncClipOut,
              cmStartSearch: begin if HandleCommand(Event) then DrawView; CE end;
              cmContSearch: begin ChangeLine; Search; ChangeLine; CE end;
              cmSpecChar,cmAsciiTable: begin
                             ASCIITable;
                             repeat
                               GetEvent(Event);
                             until (Event.What = evKeyDown) or (Event.What = evNothing);
                             if (Event.What <> evNothing) and (Event.CharCode > #0) then InputChar;
                             CE
                          end;
              cmLoadText: begin
                           CE;
                           if Modified then
                            begin
                             I := AskSave;
                             if I = cmYes then Message(@Self, evCommand, cmSaveText, nil);
                             if I = cmCancel then Exit;
                            end;
                           OpenFile;
                           Exit;
                          end;
              cmInsertOn,cmInsertOff: begin InsertMode := Event.Command = cmInsertOn; CE end;
              cmSwitchIns: begin InsertMode := not InsertMode; DrawView; CE end;
              cmSaveAll: begin GlobalMessage(evCommand, cmSaveText, nil); CE end;
              cmSaveText: begin ChangeLine; SaveFile; CE; Owner^.Redraw; end;
              cmSaveTextAs: begin ChangeLine; SaveFileAs; CE; Owner^.Redraw; end;
              cmBlockRead: begin ChangeLine; BlockRead; ChangeLine; CE end;
              cmBlockWrite: begin BlockWrite; CE end;
              cmDelChar: begin
                           if (EditorDefaults.EdOpt and (ebfPbl+ebfObl)=ebfObl)
                             and ValidBlock then DeleteBlock(On) else MakeDel;
                           CED
                         end;
              cmEnter: begin BlockOff; MakeEnter; ScrollTo(Delta.X, Delta.Y); CED end;
              cmEnd: begin UnMark := On; while WorkString[WL] = ' ' do Dec(WL);
                           ScrollTo(WL, Delta.Y); CED end;
              cmInsLine: begin
                          BlockOff;
                          PP := Delta; MakeEnter; Delta := PP;
                          ChangeLine; ScrollTo(PP.X, PP.Y); CED end;
              cmTab: begin BlockOff; DoTab; CE end;
              cmWordRight: begin UnMark := On; WordRight; ScrollTo(LastX, LastY); CED end;
              cmWordLeft: begin UnMark := On; WordLeft; ScrollTo(LastX, LastY); CED end;
              cmDeleteLine: begin BlockOff; DeleteLine; CE end;
              cmSwitchBlock: begin UnMark := On; VertBlock := not VertBlock; DrawView; CE end;
              cmClear: begin UnMark := On; if BlockVisible and ValidBlock then DeleteBlock(On); CE end;
              cmCopy: begin UnMark := On; if BlockVisible and ValidBlock then CopyBlock; CE end;
              cmCut: begin UnMark := On; if BlockVisible and ValidBlock then
                            begin CopyBlock; DeleteBlock(On) end; CE end;
              cmPaste: begin UnMark := On; PasteBlock; CE end;
              cmMoveUp: begin UnMark := On; Event.What := evKeyDown; Event.KeyCode := kbUp end;
              cmPgUp: begin UnMark := On; Dec(Pos.Y, Size.Y); VScroll^.SetValue(Delta.Y-Size.Y); DrawView; CE end;
              cmPgDn: begin UnMark := On; Inc(Pos.Y, Size.Y); VScroll^.SetValue(Delta.Y+Size.Y); DrawView; CE end;
              cmMoveDown: begin UnMark := On; Event.What := evKeyDown; Event.KeyCode := kbDown end;
              cmMoveLeft: begin UnMark := On; Event.What := evKeyDown; Event.KeyCode := kbLeft end;
              cmMoveRight: begin UnMark := On; Event.What := evKeyDown; Event.KeyCode := kbRight end;
              cmHideBlock: begin BlockVisible := not BlockVisible; UnMark := Off; CED end;
              cmScrollUp: if Pos.Y > 0 then
                          begin
                           UnMark := On;
                           if not (Delta.Y - Pos.Y + 1 < Size.Y) then Dec(Delta.Y);
                           Dec(Pos.Y);
                           ScrollTo(Delta.X, Delta.Y);
                           Delta.Y := VScroll^.Value; DrawView;
                          end;
              cmScrollDn: if Pos.Y < FileLines^.Count - 1 then
                          begin
                           UnMark := On;
                           if not (Delta.Y > Pos.Y) then Inc(Delta.Y);
                           Inc(Pos.Y);
                           ScrollTo(Delta.X, Delta.Y);
                           Delta.Y := VScroll^.Value; DrawView;
                          end;
              cmBlockStart: begin UnMark := On; Marking := Off; Mark.A := Delta;
                                  BlockVisible := On; DrawView; CE end;
              cmBlockEnd: begin UnMark := On; Marking := Off; Mark.B := Delta;
                                BlockVisible := On; DrawView; CE end;
              cmPlaceMarker: begin UnMark := On;  MarkPos[Event.InfoChar] := Delta; CE end;
              cmGotoMarker: begin ChangeLine;
                                  UnMark := On;
                                  if LongInt(MarkPos[Event.InfoChar]) >= 0 then
                                    begin
                                      Delta := MarkPos[Event.InfoChar];
                                      Pos.X := Delta.X - Size.X div 2;
                                      Pos.Y := Delta.Y - Size.Y div 2; ChangeLine; {WorkModify := Off;}
                                      ScrollTo(Delta.X, Delta.Y); DrawView; CenterScreen;
                                    end;
                                  CE
                            end;
              cmDelBackChar: begin BlockOff; MakeBack; CE end;
              cmDelWordRight: begin
                               BlockOff;
                               if (LastX >= WL) then
                                begin
                                 MakeDel; While (LastX >= WL) and (LastY + 1 < FileLines^.Count)
                                                or (LastX < WL) and (WorkString[LastX+1] = ' ') do MakeDel;
                                 CED; Exit;
                                end;
                               WorkModify;
                               if (WorkString[LastX+1] in BreakChars-[' ']) then begin MakeDel; CED; Exit; end;
                               if (WorkString[LastX+1] = ' ') then
                                 while (LastX < WL) and (WorkString[LastX+1] = ' ') do MakeDel
                                else begin
                                      While (LastX < WL) and not (WorkString[LastX+1] in BreakChars) do MakeDel;
                                      while (LastX < WL) and (WorkString[LastX+1] = ' ') do MakeDel
                                     end;
                               CED;
                              end;
              cmSwitchDrawMode: begin
                                  DrawMode := (DrawMode + 1) mod 3;
                                  Owner^.Redraw; LastDir := -1; CE;
                                end;
              cmDelWordLeft: begin
                              BlockOff;
                              if LastX = 0 then begin MakeBack; CED; Exit end;
                              if LastX >= WL then if WL > 0 then LastX := WL else
                               begin MakeBack; CED; Exit end;
                              if (WorkString[LastX] in BreakChars-[' ']) then begin MakeBack; CED; Exit; end;
                              WorkModify;
                              if (LastX > 0) and (WorkString[LastX] = ' ') then
                               begin
                                 while (LastX > 0) and (WorkString[LastX] = ' ') do MakeSmallBack;
                               end;
                              While (LastX > 0) and not (WorkString[LastX] in BreakChars) do MakeSmallBack;
                              ScrollTo(LastX, LastY); CED;
                             end;
             end;
  evKeyDown: begin
              if DrawMode > 0 then
                begin
                  case Event.KeyCode of
                     kbRight,kbCtrlD,kbCtrlRight: begin DrawLine(1); Exit end;
                     kbLeft,kbCtrlS,kbCtrlLeft: begin DrawLine(3); Exit end;
                     kbUp,kbCtrlE: begin DrawLine(0); Exit end;
                     kbDown,kbCtrlX: begin DrawLine(2); Exit end;
                  end;
                end;
              if Event.KeyCode = kbCtrlEnter then
                begin BlockOff; MakeEnter; ScrollTo(Delta.X, Delta.Y); CED; Exit end;
              CFind := Off; EvStr := #0#0;
              for I := 1 to MaxCommands do
               with EditCommands[I] do
                begin
                 if (CC1[1] = Event.CharCode) then
                    begin EvStr[1] := CC1[1];
                          if CC1[2]<>#0 then
                           begin KeyEvent(Event); EvStr[2] := Event.CharCode end;
                          Break;
                    end;
                 if (CC2[1] = Event.CharCode) then
                    begin EvStr[1] := CC2[1];
                          if CC2[2]<>#0 then
                           begin KeyEvent(Event); EvStr[2] := Event.CharCode end;
                          Break;
                    end;
                end;
              if EvStr[2] in ['A'..'Z','a'..'z'] then EvStr[2] := Char(Ord(UpCase(EvStr[2]))-64);
              for I := 1 to MaxCommands do
               with EditCommands[I] do
                 if ((C1 = Event.KeyCode) or (C2 = Event.KeyCode)) and (EvStr[2]=#0) or
                    (EvStr<>#0#0) and ((CC1 = EvStr) or (CC2 = EvStr)) then
                     begin CFind := True; Break end;
              if CFind then
               begin CE; Message(Owner, evCommand, EditCommands[I].C, Pointer(EvStr[2])); Exit end;
              if (Event.CharCode>#31) and (Event.CharCode<#255) then InputChar;
   end;
  evBroadcast: case Event.Command of
                cmScrollBarChanged: begin
                                     if HScroll <> nil then Delta.X := HScroll^.Value;
                                     if VScroll <> nil then Delta.Y := VScroll^.Value;
                                     if LastY <> Delta.Y then ChangeLine;
                                     ChPosition := (not HiliteColumn or
                                                   (LastPos.X = Delta.X)) and (LastPos.X >= 0);
                                     BMarking;
                                     DrawView;
                                    end;
                {else CalcMenu;}
               end;
  evMouseDown: begin
                  if MouseButtons = 0 then Exit;
                  LineMarking := False;
                  if Event.Double then
                    begin
                      Message(@Self, evCommand, cmMarkWord, nil);
                      CE; Exit;
                    end;
                  LineMarking := ShiftState and 4 <> 0;
                  ChangeLine;
                  EnableMarking := Off;
                  MakeLocal(Event.Where, Delta);
                  Delta.X := Pos.X + Delta.X;
                  Delta.Y := Pos.Y + Delta.Y;
                  BlockOff;
                  Sel.A := Delta; Sel.B := Delta;
                  ScrollTo(Delta.X, Delta.Y);
                  Sel.A := Delta; Sel.B := Delta;
                  EnableMarking := On;
                  if Event.Buttons and mbLeftButton <> 0 then
                   begin BlockVisible := On; MouseMark := On; end
                    else begin RulerVisible := On; DrawView; end;
                  I := RepeatDelay; RepeatDelay := 0;
                  if LineMarking then
                    begin
                      Sel.A.X := 0; Sel.B.Y := Sel.A.Y+1; Sel.B.X := 0;
                      Mark := Sel;
                      DrawView;
                    end;
                  repeat
                   MakeLocal(Event.Where, T);
                   if MouseInView(Event.Where) then
                    begin
                     Delta.X := Pos.X + T.X;
                     Delta.Y := Pos.Y + T.Y;
                     ScrollTo(Delta.X, Delta.Y);
                     OldDelta := Delta;
                    end else
                    begin
                     if T.X < 0 then Dec(Delta.X) else
                        if (T.X >= Size.X) then Inc(Delta.X);
                     if T.Y < 0 then Dec(Delta.Y) else
                        if (T.Y >= Size.Y) then Inc(Delta.Y);
                     ScrollTo(Delta.X, Delta.Y);
                     OldDelta := Delta;
                    end;
                  until not MouseEvent(Event, evMouseAuto + evMouseMove);
                  MouseMark := Off; RulerVisible := Off;
                  RepeatDelay := I;
                  ScrollTo(Delta.X, Delta.Y);
                  ChangeLine;
                  if LineMarking then
                    begin
                      if (Mark.B.X > 0) and (Mark.B.Y < FileLines^.Count-1)
                        then begin Inc(Mark.B.Y); Mark.A.X := 0 end;
                      if (Mark.A.X > 0) then Mark.A.X := 0;
                      CED;
                      LineMarking := False;
                      Exit;
                    end;
                  CED;
               end;
 end;
end;

type  ByteArray = Array[1..2] of Byte;
      PByteArray = ^ByteArray;
const FBufSize = 4096;

procedure TFileEditor.LockFile;
begin
   if EditorDefaults.EdOpt and ebfLck = 0 then Exit;
   FreeObject(Locker);
   Locker := New(PDOSStream, Init(EditName, $3D00));
end;

procedure TFileEditor.UnLockFile;
begin
   if EditorDefaults.EdOpt and ebfLck = 0 then Exit;
   FreeObject(Locker);
end;


function TFileEditor.ReadBlock;
 var S: PDosStream;
     B: PByteArray;
     I, FFSize: LongInt;
     J, K: Word;
     LCount: Word;
     Lines: PCollector;
     S1, ST, S2: String;
     FF: File absolute S1;
     WasCR: Boolean;

 procedure CountLines;
  var P: Pointer;
      K,L: Word;
 begin
  P := B; K := J; L := LCount;
  asm
    les si, P
    mov cx, K
    mov dx, L
    mov ax, 0A0Dh
@@1:
    cmp al, es:[si]
    jnz  @@2
    cmp  cx, 1
    jz   @@L
    cmp ah, es:[si+1]
    jnz @@3
    dec cx
    inc si
@@3:
    inc  dx
    jmp  @@L
@@2:
    cmp  ah, es:[si]
    je   @@3
@@L:
    inc si
    loop @@1
    mov  L, dx
  end;
  LCount := L;
 end;

 procedure SearchLines;
  label 1,L2;
  var P, P2: Pointer;
      K, L, M: Word;
      QQQ: LongInt;
      WL: Byte absolute ST;
      MMM: String;
      C: Char;
      WC: Boolean;
 begin
  WC := WasCR;
  K := 1; P := B; L := J;
  repeat
   MMM := ST;
   asm
    les di, P
    add di, K
    dec di
    lea bx, MMM
    xor ah, ah
    mov al, ss:[bx]
    inc al
    mov si, ax
   @@1:
    mov al, es:[di]
    cmp al, 10
    je  L2
    cmp al, 13
    jne  @@5
    mov al, es:[di+1]
    cmp al, 10
    jnz L2
    inc K
    jmp L2
  @@5:
    cmp al, 9
    jnz @@3
   @@4:
    mov al, ' '
    mov ss:[bx+si], al
    inc byte ptr ss:[bx]
    inc si
    mov cx, si
    dec cx
    and cx, 7
    jz  @@2
    mov al, ss:[bx]
    cmp al, 254
    je  L2
    jmp @@4
   @@3:
    mov ss:[bx+si], al
    inc si
    inc byte ptr ss:[bx]
    mov al, ss:[bx]
    cmp al, 254
    je  L2
   @@2:
    inc K
    inc di
    mov ax, K
    cmp ax, L
    jng @@1
   end;
   ST := MMM;
   Exit;
L2: ST := MMM;
   while (ST[WL]=' ') do Dec(WL);
   Lines^.AddStr(ST);
   ST := '';
   Inc(K);
  until K > J;
 end;

 var Info: PView;
     ep : Boolean;
     tmr: TEventTimer;
begin
 ReadBlock := nil; Abort := Off;
 if LowMemory then Exit;
 S := New(PBufStream, Init(FileName, stOpenRead,1024));
 if (S^.Status <> stOK) then
    begin
      asm
         mov ax, $5900
         xor bx, bx
         int 21h
         mov K, ax
      end;
      isValid := (K = 2) or (K = 3);
      if (K <> 2) and (K <> 3) then MessageBox(GetString(dlFBBNoOpen)+FileName, nil, mfError + mfOKButton);
      Dispose(S, Done);
      Exit
    end;
 if (S^.GetSize > MemAvail - $4000) and (EditorDefaults.EdOpt and (ebfEMS+ebfXMS) = 0) then
 begin
   Application^.OutOfMemory; Dispose(S, Done); FileName := ''; isValid := Off;
   Exit
 end;
 B := MemAlloc(FBufSize); if B = nil then
 begin
   Dispose(S, Done); FileName := '';
   Exit
 end;
 Info := WriteMsg(^M^M^C+GetString(dlReadingFile));
 I := 0; FFSize := S^.GetSize; LCount := 1;
 if FFSize - I > FBufSize then J := FBufSize else J := FFSize - I;
 ep := False; NewTimer(Tmr,1);
 While I < FFSize do
  begin
   S^.Read(B^[1+Byte(I>0)], J);
   UpdateWriteView(Info);
   if TimerExpired(tmr) then
   begin
     NewTimer(Tmr, 3);
     ep := ESC_Pressed;
   end;
   if (S^.Status <> stOK) or Abort or ep then
    begin
      FreeMem(B, FBufSize); Dispose(S, Done); Info^.Free; FileName := '';
      IsValid := False;
      Exit
    end;
   CountLines;
   B^[1] := B^[J+Byte(I>0)-1]; I := S^.GetPos;
   if FFSize - I > FBufSize-1 then J := FBufSize-1 else J := FFSize - I;
  end;
 if (LCount > 25000) or (MemAvail-$4000 < 4*(LCount+50)+FFSize)
    and (EditorDefaults.EdOpt and (ebfXMS+ebfEMS) = 0) then
  begin
    Application^.OutOfMemory; FreeMem(B, FBufSize); Dispose(S, Done); FileName := ''; Info^.Free; isValid := Off;
    Exit
  end;
 if RetCollector then Lines := GetCollector(LCount*11, LCount+50)
                 else Lines := New(PStdCollector, Init(LCount+50));
 S^.Seek(0);
 I := 0;
 FFSize := S^.GetSize;
 LCount := 1;
 ST := '';
 if FFSize - I > FBufSize then J := FBufSize
                          else J := FFSize - I;
 While I < FFSize do
   begin
     UpdateWriteView(Info);
     S^.Read(B^, J);
     if TimerExpired(tmr) then
     begin
       NewTimer(Tmr, 3);
       ep := ESC_Pressed;
     end;
     if (S^.Status <> stOK) or ep or Abort or (MemAvail < $4000) or LowMemory or
        (Lines^.Count > 29900) then
       begin
         Dispose(Lines, Done);
         FileName := '';
         FreeMem(B, FBufSize);
         Dispose(S, Done);
         Info^.Free;
         Application^.OutOfMemory;
         isValid := Off;
         Exit
       end;
     if (B^[J] = 13) and (S^.GetPos < S^.GetSize) then begin Dec(J); S^.Seek(S^.GetPos-1); end;
     SearchLines;
     I := S^.GetPos;
     if FFSize - I > FBufSize then J := FBufSize
                              else J := FFSize - I;
   end;
  Info^.Free;
  FreeMem(B, FBufSize); Dispose(S, Done);
  if ST[1] = #10 then DelFC(ST);
  while (ST[Byte(ST[0])]=' ') do Dec(ST[0]);
  Lines^.Insert(NewStr(ST));
  if RetCollector then ReadBlock := Lines
                  else begin
                         ReadBlock := PStdCollector(Lines)^.Collection;
                         PStdCollector(Lines)^.Collection := nil;
                         Dispose(Lines, Done);
                       end;
end;


procedure OpenSmartpad;
  var R: TRect;
      PV: Pointer;

 procedure InsertInfo;
 begin
  with SmartWindow^.Intern^ do
   begin
     FileLines^.Insert(NewStr('ÄÄÄÄÄÄ< ' +GetDateTime(Off)+' '+GetDateTime(On)+' >ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'));
     FileLines^.Insert(nil);
     SetLimits;
     ScrollTo(0, FileLines^.Count-1);
     Pos.Y := Delta.Y-1;
     SmartWindow^.Redraw;
   end;

 end;

begin
  if (SmartWindow <> nil) and SmartWindow^.GetState(sfModal) then Exit;
  PV := Application^.TopView;
  Desktop^.GetExtent(R);
  R.Grow(-2,-2);
  if (SmartWindow <> nil) then
    begin
      InsertInfo;
      if (PV <> Application) then
        begin
           {if PView(PV)^.Owner = Pointer(Desktop) then SmartWindow^.MakeFirst;}
           Desktop^.Delete(SmartWindow);
           Desktop^.ExecView(SmartWindow);
           Desktop^.InsertBefore(SmartWindow, Desktop^.Last);
           Desktop^.SetCurrent(PV, EnterSelect);
           {if PView(PV)^.Owner = Pointer(Desktop) then PView(PV)^.MakeFirst;}
        end else SmartWindow^.Select;
      Exit;
    end;
  New(SmartWindow, Init(R, 'SmartPad'));
  InsertInfo;
  if (PV <> Application) then
     begin
       Desktop^.ExecView(SmartWindow);
       SmartWindow^.Free;
       SmartWindow := nil
     end else Desktop^.Insert(SmartWindow);
end;




end.