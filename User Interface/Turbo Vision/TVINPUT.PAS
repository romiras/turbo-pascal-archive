{*
*
*   Copyright (c) 1992,93 by Richard W. Hansen
*
*
*}
UNIT TvInput;
{$B+}
{$X+}
{$V-}
{$N+}

{$I TVDEFS.INC}

INTERFACE


USES
  Dos, UpCs,
  App, Dialogs, Drivers, Objects, Views, MsgBoxr,
  TvConst, TVDialog, TvString, TvType;


Procedure SetDateDefaults;


CONST
  dfRequired      = $0001;  { Field entry is required         }
  dfRJustify      = $0002;  { Trim and Right justify result   }
  dfLJustify      = $0004;  { Trim and Left justify result    }
  dfTrim          = $0008;  { Trim all pad chars from result  }
  dfHide          = $0010;  { Password input                  }
  dfDefaults      = $0020;  { Use default values if available }

CONST
  HideChar  : Char = '*';   { character used for passwords      }
  DecimalPt = '.';          { character used for decimal points }
  Left      = True;
  Right     = False;

CONST
  AnyChar     = 'X';        { any character                        }
  ForceUp     = 'U';        { any character, force upper case      }
  ForceLo     = 'L';        { any character, force lower case      }
  AlphaOnly   = 'a';        { alpha numeric only                   }
  UpperAlpha  = 'u';        { alpha numeric only, force upper case }
  LowerAlpha  = 'l';        { alpha numeric only, force lower case }
  NumberOnly  = '#';        { numbers, minus                       }
  DigitOnly   = '9';        { numbers only                         }
  HexOnly     = '&';        { hexadecimal numbers                  }
  DateOnly    = '@';        { dates                                }

CONST
  EditMaskChars : TCharSet = [AnyChar, ForceUp, ForceLo, AlphaOnly,
			      UpperAlpha, LowerAlpha, NumberOnly,
			      DigitOnly, HexOnly, DateOnly];
CONST
  AnyCharSet    : TCharSet = [#32..#255];
CONST
  AlphaOnlySet  : TCharSet = ['0'..'9', 'A'..'Z', 'a'..'z', ' '];
CONST
  DigitOnlySet  : TCharSet = ['0'..'9'];
CONST
  NumberOnlySet : TCharSet = ['0'..'9', '-'];
CONST
  HexOnlySet    : TCharSet = ['0'..'9', 'A'..'F', 'a'..'f', '$'];
CONST
  DateOnlySet   : TCharSet = ['0'..'9', ' '];


CONST
  DefaultDay    : Word = 0;
  DefaultYear   : Word = 0;
  DefaultMonth  : Word = 0;


TYPE
  PbxEditLine = ^TbxEditLine;
  TbxEditLine = Object(TInputLine)
    PadChar   : Char;   { blank place holder char }
    XPos      : Byte;   { insert position         }
    First     : Byte;   { first editable position }
    Mask      : PString;{ edit mask               }
    ID        : Word;
    LLabel    : PLabel;
    EditFlags : Word;

    Constructor Init(var Bounds : TRect;
			 AMask  : String);
    Constructor Load(var S: TStream);
    Destructor  Done;                                     Virtual;
    Procedure   AddLabel(ALabel : Pointer);
    Function    DataSize: Word;                           Virtual;
    Procedure   Draw;                                     Virtual;
    Function    EditToMaskPos(Pos : Integer): Integer;
    Function    Empty: Boolean;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Function    GetFieldName: String;                     Virtual;
    Function    GetID: Word;                              Virtual;
    Procedure   HandleEvent(var Event : TEvent);          Virtual;
    Function    HomePos: Integer;                         Virtual;
    Procedure   InsertChar(Ch : Char);                    Virtual;
    Function    MaskToEditPos(Pos : Integer): Integer;
    Procedure   Lock;
    Procedure   Merge(var St      : String;
			  Justify : Boolean);             Virtual;
    Function    NextPos(Pos : Integer): Integer;          Virtual;
    Function    PrevPos(Pos : Integer): Integer;          Virtual;
    Function    Remove(const St : String): String;
    Procedure   SetData(var Rec);                         Virtual;
    Procedure   SetEditFlag(AFlag : Word;
			    Enable: Boolean);             Virtual;
    Procedure   SetID(AFieldID : Word);
    Procedure   SetState(AState : Word;
			 Enable : Boolean);               Virtual;
    Procedure   Store(var S: TStream);
    Procedure   UnLock;
    Function    Valid(Command : Word): Boolean;           Virtual;

    private
    Function    CanScroll(ScrollLeft : Boolean): Boolean;
    Procedure   DeleteMarked;
    Procedure   SelectAll(Enable : Boolean);
  END;

  PBXDateEdit = ^TBXDateEdit;
  TBXDateEdit = OBJECT(TBXEditLine)
    Date    : PBXDate;
    DatePic : TbxDateSt;

    Constructor Init(var Bounds : TRect;
			 ADatePic : TbxDateSt);
    Constructor Load(var S: TStream);
    Destructor  Done;                                     Virtual;
    Function    DataSize: Word;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Procedure   SetData(var Rec);                         Virtual;
    Procedure   Store(var S: TStream);
    Function    Valid(Command : Word): Boolean;           Virtual;
  end;


  PbxNumericEdit  = ^TbxNumericEdit;
  TbxNumericEdit  = Object(TbxEditLine)
    ErrCode : Integer;    { string to numeric conversion error  }

    Procedure   HandleEvent(var Event: TEvent);           Virtual;
    Function    OutOfRange: Boolean;                      Virtual;
    Function    OutOfRangeMsg: String;                    Virtual;
    Function    Valid(Command : Word): Boolean;           Virtual;
  end;


  PBXLongEdit = ^TBXLongEdit;
  TBXLongEdit = OBJECT(TBXNumericEdit)
    Min   : LongInt;
    Max   : LongInt;
    Constructor Init(var Bounds  : TRect;
		     const AMask : String;
			 AMin    : LongInt;
			 AMax    : LongInt);
    Constructor Load(var S: TStream);
    Function    DataSize: Word;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Function    OutOfRange: Boolean;                      Virtual;
    Function    OutOfRangeMsg: String;                    Virtual;
    Procedure   SetData(var Rec);                         Virtual;
    Procedure   Store(var S: TStream);
  end;


  PbxHexEdit  = ^TbxHexEdit;
  TbxHexEdit  = Object(TbxLongEdit)
    Function    OutOfRangeMsg: String;                    Virtual;
    Procedure   SetData(var Rec);                         Virtual;
  end;


  PbxIntegerEdit = ^TbxIntegerEdit;
  TbxIntegerEdit = Object(TbxLongEdit)
    Constructor Init(var Bounds  : TRect;
                     const AMask : String;
                         AMin    : Integer;
                         AMax    : Integer);
    Function    DataSize: Word;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Procedure   SetData(var Rec);                         Virtual;
  end;


  PbxWordEdit = ^TbxWordEdit;
  TbxWordEdit = Object(TbxLongEdit)
    Constructor Init(var Bounds  : TRect;
                     const AMask : String;
                         AMin    : Word;
                         AMax    : Word);
    Function    DataSize: Word;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Procedure   SetData(var Rec);                         Virtual;
  end;


  PbxByteEdit = ^TbxByteEdit;
  TbxByteEdit = Object(TbxLongEdit)
    Constructor Init(var Bounds  : TRect;
                     const AMask : String;
                         AMin    : Byte;
                         AMax    : Byte);
    Function    DataSize: Word;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Procedure   SetData(var Rec);                         Virtual;
  end;


  PbxFloatEdit = ^TbxFloatEdit;
  TbxFloatEdit = Object(TbxNumericEdit)
    DP  : Byte;   { number of decimal places  }

    Constructor Init(var Bounds  : TRect;
                     const AMask : String);
    Constructor Load(var S: TStream);
    Procedure   HandleEvent(var Event: TEvent);           Virtual;
    Procedure   Store(var S: TStream);
  end;


  {$IFOPT N+}
  PbxDoubleEdit = ^TbxDoubleEdit;
  TbxDoubleEdit = Object(TbxFloatEdit)
    Min : Double;
    Max : Double;

    Constructor Init(var Bounds  : TRect;
                     const AMask : String;
                         AMin    : Double;
                         AMax    : Double);
    Constructor Load(var S: TStream);
    Function    DataSize: Word;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Function    OutOfRange: Boolean;                      Virtual;
    Function    OutOfRangeMsg: String;                    Virtual;
    Procedure   SetData(var Rec);                         Virtual;
    Procedure   Store(var S: TStream);
  end;
  {$ENDIF}


  PbxRealEdit = ^TbxRealEdit;
  TbxRealEdit = Object(TbxFloatEdit)
    Min : Real;
    Max : Real;

    Constructor Init(var Bounds  : TRect;
                     const AMask : String;
                         AMin    : Real;
                         AMax    : Real);
    Constructor Load(var S: TStream);
    Function    DataSize: Word;                           Virtual;
    Procedure   GetData(var Rec);                         Virtual;
    Function    OutOfRange: Boolean;                      Virtual;
    Function    OutOfRangeMsg: String;                    Virtual;
    Procedure   SetData(var Rec);                         Virtual;
    Procedure   Store(var S: TStream);
  end;


  PbxCheckBoxes = ^TbxCheckBoxes;
  TbxCheckBoxes = Object(TCheckBoxes)
    ID        : Word;
    LLabel    : PLabel;
    EditFlags : Word;

    Constructor Init(var Bounds  : TRect;
                         AStrings: PSItem);
    Constructor Load(var S: TStream);
    Procedure   AddLabel(ALabel : Pointer);
    Function    Empty: Boolean;                           Virtual;
    Function    GetID: Word;
    Function    GetFieldName: String;                     Virtual;
    Procedure   HandleEvent(var Event : TEvent);          Virtual;
    Procedure   Lock;
    Procedure   SetEditFlag(AFlag : Word;
                            Enable: Boolean);             Virtual;
    Procedure   SetID(AFieldID : Word);
    Procedure   SetState(AState : Word;
                         Enable : Boolean);               Virtual;
    Procedure   Store(var S: TStream);
    Procedure   UnLock;
    Function    Valid(Command: Word): Boolean;            Virtual;
  end;


  PbxRadioButtons = ^TbxRadioButtons;
  TbxRadioButtons = Object(TRadioButtons)
    ID        : Word;
    LLabel    : PLabel;
    EditFlags : Word;

    Constructor Init(var Bounds  : TRect;
                         AStrings: PSItem);
    Constructor Load(var S: TStream);
    Procedure   AddLabel(ALabel : Pointer);
    Function    GetFieldName: String;                     Virtual;
    Function    GetID: Word;
    Procedure   HandleEvent(var Event : TEvent);          Virtual;
    Procedure   Lock;
    Procedure   SetEditFlag(AFlag : Word;
                            Enable: Boolean);             Virtual;
    Procedure   SetID(AFieldID : Word);
    Procedure   SetState(AState : Word;
                         Enable : Boolean);               Virtual;
    Procedure   Store(var S: TStream);
    Procedure   UnLock;
  end;


  PbxSlider = ^TbxSlider;
  TbxSlider = Object(TGroup)
    Scrollbar : PScrollbar;
    ID        : Word;
    LLabel    : PLabel;
    EditFlags : Word;

    Constructor Init(var Bounds : TRect;
                         AMin   : Integer;
                         AMax   : Integer;
                     const AMinLabel : String;
                     const AMaxLabel : String);
    Constructor Load(var S : TStream);
    Procedure   AddLabel(ALabel : Pointer);
    Procedure   GetData(var Rec);                         Virtual;
    Function    GetID: Word;
    Function    GetFieldName: String;                     Virtual;
    Procedure   HandleEvent(var Event : TEvent);          Virtual;
    Procedure   Lock;
    Procedure   SetData(var Rec);                         Virtual;
    Procedure   SetEditFlag(AFlag : Word;
                            Enable: Boolean);             Virtual;
    Procedure   SetID(AFieldID : Word);
    Procedure   SetState(AState : Word;
                         Enable : Boolean);               Virtual;
    Procedure   Store(var S:  TStream);
    Procedure   UnLock;
  end;


  PbxSpinEdit = ^TbxSpinEdit;

  TbxSpinChars  = Array[1..2] of Char;

  PbxSpinBar  = ^TbxSpinBar;
  TbxSpinBar  = Object(TScrollBar)
    Chars : TbxSpinChars;
    SpinEdit : PbxSpinEdit;

    Constructor Init(var Bounds : TRect);
    Constructor Load(var S : TStream);
    Procedure   Draw;                                     Virtual;
    Procedure   HandleEvent(var Event : TEvent);          Virtual;
    Procedure   Store(var S : TStream);
  end;


  TbxSpinEdit = Object(TbxIntegerEdit)
    SpinBar   : PbxSpinBar;

    Constructor Init(var Bounds  : TRect;
                     const AMask : String;
                         ASpinBar: PbxSpinBar);
    Constructor Load(var S : TStream);
    Procedure   HandleEvent(var Event : TEvent);          Virtual;
    Procedure   SetData(var Rec);                         Virtual;
    Procedure   Store(var S : TStream);
    Procedure   SetState(AState : Word;
                         Enable : Boolean);               Virtual;
    Function    Valid(Command : Word): Boolean;           Virtual;
  end;


  PbxEntryDialog  = ^TbxEntryDialog;
  TbxEntryDialog  = Object(TDialog)
    NextId : Word;

    Constructor Init(var Bounds : TRect;
                         ATitle : TTitleStr);
    Constructor Load(var S : TStream);
    Function    FindField(ID : Word): Pointer;
    Procedure   HandleEvent(var Event : TEvent);          Virtual;
    Procedure   Insert(P : PView);                        Virtual;
    Procedure   LockField(ID     : Word;
                          Enable : Boolean);
    Procedure   Store(var S : TStream);
  end;


{ TVInput registration procedure }

Procedure RegisterTVInput;

{ Stream Registration Records }

CONST
  RbxEditLine: TStreamRec = (
    ObjType : 5300;
    VmtLink : Ofs(TypeOf(TbxEditLine)^);
    Load    : @TbxEditLine.Load;
    Store   : @TbxEditLine.Store
  );

CONST
  RbxDateEdit: TStreamRec = (
    ObjType : 5301;
    VmtLink : Ofs(TypeOf(TbxDateEdit)^);
    Load    : @TbxDateEdit.Load;
    Store   : @TbxDateEdit.Store
  );

CONST
  RbxLongEdit: TStreamRec = (
    ObjType : 5302;
    VmtLink : Ofs(TypeOf(TbxLongEdit)^);
    Load    : @TbxLongEdit.Load;
    Store   : @TbxLongEdit.Store
  );

CONST
  RbxHexEdit: TStreamRec = (
    ObjType : 5303;
    VmtLink : Ofs(TypeOf(TbxHexEdit)^);
    Load    : @TbxHexEdit.Load;
    Store   : @TbxHexEdit.Store
  );

CONST
  RbxIntegerEdit: TStreamRec = (
    ObjType : 5304;
    VmtLink : Ofs(TypeOf(TbxIntegerEdit)^);
    Load    : @TbxIntegerEdit.Load;
    Store   : @TbxIntegerEdit.Store
  );

CONST
  RbxWordEdit: TStreamRec = (
    ObjType : 5305;
    VmtLink : Ofs(TypeOf(TbxWordEdit)^);
    Load    : @TbxWordEdit.Load;
    Store   : @TbxWordEdit.Store
  );

CONST
  RbxByteEdit: TStreamRec = (
    ObjType : 5306;
    VmtLink : Ofs(TypeOf(TbxByteEdit)^);
    Load    : @TbxByteEdit.Load;
    Store   : @TbxByteEdit.Store
  );

{$IFOPT N+}
CONST
  RbxDoubleEdit: TStreamRec = (
    ObjType : 5307;
    VmtLink : Ofs(TypeOf(TbxDoubleEdit)^);
    Load    : @TbxDoubleEdit.Load;
    Store   : @TbxDoubleEdit.Store
  );
{$ENDIF}

CONST
  RbxRealEdit: TStreamRec = (
    ObjType : 5308;
    VmtLink : Ofs(TypeOf(TbxRealEdit)^);
    Load    : @TbxRealEdit.Load;
    Store   : @TbxRealEdit.Store
  );

CONST
  RbxEntryDialog: TStreamRec = (
    ObjType : 5309;
    VmtLink : Ofs(TypeOf(TbxEntryDialog)^);
    Load    : @TbxEntryDialog.Load;
    Store   : @TbxEntryDialog.Store
  );

CONST
  RbxCheckBoxes: TStreamRec = (
    ObjType : 5310;
    VmtLink : Ofs(TypeOf(TbxCheckBoxes)^);
    Load    : @TbxCheckBoxes.Load;
    Store   : @TbxCheckBoxes.Store
  );

CONST
  RbxRadioButtons: TStreamRec = (
    ObjType : 5311;
    VmtLink : Ofs(TypeOf(TbxRadioButtons)^);
    Load    : @TbxRadioButtons.Load;
    Store   : @TbxRadioButtons.Store
  );

CONST
  RbxSlider: TStreamRec = (
    ObjType : 5312;
    VmtLink : Ofs(TypeOf(TbxSlider)^);
    Load    : @TbxSlider.Load;
    Store   : @TbxSlider.Store
  );

CONST
  RbxSpinBar: TStreamRec = (
    ObjType : 5313;
    VmtLink : Ofs(TypeOf(TbxSpinBar)^);
    Load    : @TbxSpinBar.Load;
    Store   : @TbxSpinBar.Store
  );

CONST
  RbxSpinEdit: TStreamRec = (
    ObjType : 5314;
    VmtLink : Ofs(TypeOf(TbxSpinEdit)^);
    Load    : @TbxSpinEdit.Load;
    Store   : @TbxSpinEdit.Store
  );

implementation

procedure SetDateDefaults;
var
  DayOfWeek: Word;
begin
  GetDate(DefaultYear, DefaultMonth, DefaultDay, DayOfWeek);
end;

function LoCase(Chr: Char): Char;
begin
  asm
        MOV     AL, Chr
        CMP     AL, 'A'
        JB      @1
        CMP     AL, 'Z'
        JA      @1
        ADD     AL, 'a' - 'A'
@1:     MOV     @Result, AL
  end;
end;

constructor TbxEditLine.Init(var Bounds: TRect; AMask: string);
var
  I: Byte;
  X: Byte;
begin
  X := 0;
  if (AMask = '') then AMask := 'X';
  for I := 1 to Byte(AMask[0]) do
    if (AMask[I] in EditMaskChars) then Inc(X);
  inherited Init(Bounds, X);
  Mask := NewStr(AMask);
  First := 1;
  PadChar := ' ';
  while (First <= Byte(Mask^[0])) and not (AMask[First] in EditMaskChars) do
    Inc(First);
  LLabel := nil;
  Id := 0;
  EditFlags := 0;
  EventMask := EventMask or evBroadcast;
end;

destructor TbxEditLine.Done;
begin
  inherited Done;
  DisposeStr(Mask);
end;

constructor TbxEditLine.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(PadChar, SizeOf(Char));
  S.Read(XPos, SizeOf(Byte));
  S.Read(First, SizeOf(First));
  Mask := S.ReadStr;
  S.Read(Id, SizeOf(Byte));
  GetPeerViewPtr(S, LLabel);
  S.Read(EditFlags, SizeOf(Word));
end;

procedure TbxEditLine.AddLabel(ALabel: Pointer);
begin
  LLabel := ALabel;
end;

function TbxEditLine.CanScroll(ScrollLeft: Boolean): Boolean;
begin
  if ((EditFlags and dfRJustify) <> 0) then CanScroll := False
  else if ScrollLeft then CanScroll := (FirstPos > 1) else
    CanScroll := ((Length(Mask^) - FirstPos + 1) > (Size.X - 2));
end;

function TbxEditLine.DataSize: Word;
begin
  DataSize := Length(Mask^) + 1;
end;

procedure TbxEditLine.DeleteMarked;
begin
  if (SelStart <> SelEnd) then
  begin
    Delete(Data^, SelStart, SelEnd - SelStart + 1);
    XPos := SelStart;
    CurPos := EditToMaskPos(XPos);
  end;
end;

procedure TbxEditLine.Draw;
var
  S: string;
  Color: Byte;
  B: TDrawBuffer;
  L, R: Integer;
begin
  Merge(S, (State and sfSelected = 0));
  if (State and sfFocused = 0) then
    Color := GetColor(1) else
    Color := GetColor(2);
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B[1], Copy(S, FirstPos, Size.X - 2), Color);
  if CanScroll(Right) then MoveChar(B[Size.X-1], #16, GetColor(4), 1);
  if (State and sfSelected <> 0) then
  begin
    if CanScroll(Left) then MoveChar(B[0], #17, GetColor(4), 1);
    L := SelStart - FirstPos + 1;
    if (L < 1) then L := 1;
    R := SelEnd - FirstPos + 1;
    if (R > Size.X - 1) then R := Size.X - 1;
    if (L < R) then MoveChar(B[L], #0, GetColor(3), R - L + 1);
  end;
  WriteLine(0, 0, Size.X, Size.Y, B);
  SetCursor(CurPos - FirstPos + 1, 0);
end;

function TbxEditLine.EditToMaskPos(Pos: Integer): Integer;
var
  X: Integer;
  Count: Integer;
begin
  Count := 0;
  for X := 1 to Pos do
    repeat
      Inc(Count);
    until (Mask^[Count] in EditMaskChars);
  EditToMaskPos := Count;
end;

function TbxEditLine.Empty: Boolean;
begin
  Empty := AllBlanks(Data^);
end;

procedure TbxEditLine.GetData(var Rec);
var
  S: string;
  SaveFlags: Word;
begin
  SaveFlags := EditFlags;
  EditFlags := EditFlags and not dfHide;
  Merge(S, True);
  EditFlags := SaveFlags;
  Move(S, Rec, DataSize);
end;

function TbxEditLine.GetFieldName: string;
var
  Name: string;
begin
  if (LLabel <> nil) then
  begin
    Name := PLabel(LLabel)^.Text^;
    Strip(Name, ['~']);
  end else Name := '';
  GetFieldName := Name;
end;

function TbxEditLine.GetId: Word;
begin
  GetId := Id;
end;

procedure TbxEditLine.HandleEvent(var Event: TEvent);

function MouseDelta(var Dir: Boolean): Boolean;
var
  Mouse: TPoint;
begin
  MakeLocal(Event.Where, Mouse);
  if (Mouse.X <= 0) then
  begin
    MouseDelta := True;
    Dir := Left;
  end else if (Mouse.X >= Size.X - 1) then
  begin
    MouseDelta := True;
    Dir := Right;
  end else
  begin
    MouseDelta := False;
  end;
end;

function MousePos: Integer;
var
  Pos: Integer;
  Mouse: TPoint;
begin
  MakeLocal(Event.Where, Mouse);
  if (Mouse.X < 1) then Mouse.X := 1;
  Pos := Mouse.X + FirstPos - 1;
  if (Pos < 1) then Pos := 1
  else if (Pos > EditToMaskPos(Length(Data^))) then
    Pos := EditToMaskPos(Length(Data^));
  if not (Mask^[Pos] in EditMaskChars) then Pos := NextPos(Pos);
  if not (Mask^[Pos] in EditMaskChars) then Pos := PrevPos(Pos);
  MousePos := Pos;
end;

procedure Scroll(Dir: Boolean);
begin
  if CanScroll(Dir) then
  begin
    if (Dir = Left) then
    begin
      Dec(XPos);
      Dec(FirstPos);
      CurPos := PrevPos(CurPos);
    end else
    begin
      Inc(XPos);
      Inc(FirstPos);
      CurPos := NextPos(CurPos);
    end;
  end;
end;

var
  Anchor: Integer;
  X: Integer;
  ValidChar: Boolean;
  Delta: Boolean;
  S: string;
begin
  TView.HandleEvent(Event);
  case Event.What of
    evMouseDown:
      begin
        if (State and sfSelected <> 0) then
        begin
          if MouseDelta(Delta) then
          begin
            repeat
              Scroll(Delta);
              DrawView;
            until not MouseEvent(Event, evMouseAuto);
          end else if Event.Double then
          begin
            SelectAll(True);
          end else
          begin
            Anchor := MousePos;
            repeat
              if (Event.What = evMouseAuto) then
              begin
                if MouseDelta(Delta) then Scroll(Delta);
              end else
              begin
                CurPos := MousePos;
                XPos := MaskToEditPos(CurPos);
              end;
              if (CurPos < Anchor) then
              begin
                SelStart := CurPos;
                SelEnd := Anchor;
              end else
              begin
                SelStart := Anchor;
                SelEnd := CurPos;
              end;
              DrawView;
            until not MouseEvent(Event, evMouseMove + evMouseAuto);
          end;
        end;
        ClearEvent(Event);
      end;
    evKeyDown:
      begin
        case CtrlToArrow(Event.KeyCode) of
          kbLeft:
            begin
              if (XPos > 1) then
              begin
                Dec(XPos);
                CurPos := PrevPos(CurPos);
              end;
            end;
          kbRight:
            begin
              if (XPos <= Length(Data^)) then
                if (XPos <= MaxLen) then
                begin
                  Inc(XPos);
                  CurPos := NextPos(CurPos);
                end;
            end;
          kbHome:
            begin
              XPos := 1;
              CurPos := HomePos;
            end;
          kbEnd:
            begin
              XPos := Length(Data^);
              CurPos := NextPos(EditToMaskPos(XPos));
              Inc(XPos);
            end;
          kbBack:
            begin
              if (XPos > 1) then
              begin
                Dec(XPos);
                CurPos := PrevPos(CurPos);
                Delete(Data^, XPos, 1);
                if (FirstPos > 1) then Dec(FirstPos);
              end;
            end;
          kbDel:
            begin
              if (SelStart = SelEnd) then
                Delete(Data^, XPos, 1) else
                DeleteMarked;
            end;
          kbIns:
            begin
              SetState(sfCursorIns, State and sfCursorIns = 0);
            end;
        else
          case Event.CharCode of
            ' ' .. #255:
              begin
                case (Mask^[CurPos]) of
                  DateOnly:
                    begin
                      ValidChar := Event.CharCode in DateOnlySet;
                    end;
                  HexOnly:
                    begin
                      ValidChar := Event.CharCode in HexOnlySet;
                    end;
                  DigitOnly:
                    begin
                      ValidChar := Event.CharCode in DigitOnlySet;
                    end;
                  AnyChar:
                    begin
                      ValidChar := True;
                    end;
                  ForceUp:
                    begin
                      Event.CharCode := UpCase(Event.CharCode);
                      ValidChar := True;
                    end;
                  ForceLo:
                    begin
                      Event.CharCode := LoCase(Event.CharCode);
                      ValidChar := True;
                    end;
                  AlphaOnly:
                    begin
                      ValidChar := Event.CharCode in AlphaOnlySet;
                    end;
                  UpperAlpha:
                    begin
                      Event.CharCode := UpCase(Event.CharCode);
                      ValidChar := Event.CharCode in AlphaOnlySet;
                    end;
                  LowerAlpha:
                    begin
                      Event.CharCode := LoCase(Event.CharCode);
                      ValidChar := Event.CharCode in AlphaOnlySet;
                    end;
                  NumberOnly:
                    begin
                      ValidChar := Event.CharCode in NumberOnlySet;
                    end;
                else ValidChar := False;
                end;
                if ValidChar then
                begin
                  InsertChar(Event.CharCode);
                end;
              end;
            ^Y:
              begin
                Data^ := '';
                XPos := 1;
                CurPos := HomePos;
              end;
          else Exit;
          end;
        end;
        SelStart := 1;
        SelEnd := 1;
        if (FirstPos > CurPos) then
        begin
          if (CurPos = HomePos) then FirstPos := 1 else FirstPos := CurPos;
        end;
        X := CurPos - Size.X + 2;
        if (FirstPos < X) then FirstPos := X;
        DrawView;
        ClearEvent(Event);
      end;
    evBroadcast:
      begin
        case Event.Command of
          cmSetId:
            begin
              SetId(Event.InfoWord);
              ClearEvent(Event);
              Event.InfoPtr := @Self;
            end;
          cmIdentify:
            if (Event.InfoWord = Id) then
            begin
              ClearEvent(Event);
              Event.InfoPtr := @Self;
            end;
        end;
      end;
  end;
end;

function TbxEditLine.HomePos: Integer;
begin
  HomePos := First;
end;

procedure TbxEditLine.InsertChar(Ch: Char);
begin
  if (State and sfCursorIns <> 0) then
    Delete(Data^, XPos, 1) else
    DeleteMarked;
  if (Length(Data^) < MaxLen) then
  begin
    if (FirstPos > CurPos) then FirstPos := CurPos;
    Insert(Ch, Data^, XPos);
    if (XPos <= MaxLen) then
    begin
      Inc(XPos);
      CurPos := NextPos(CurPos);
    end;
  end;
end;

procedure TbxEditLine.Lock;
begin
  SetState(sfDisabled, True);
end;

function TbxEditLine.MaskToEditPos(Pos: Integer): Integer;
var
  X: Integer;
  Count: Integer;
begin
  Count := 0;
  for X := 1 to Pos do
    if (Mask^[X] in EditMaskChars) then Inc(Count);
  MaskToEditPos := Count;
end;

procedure TbxEditLine.Merge(var St: string; Justify: Boolean);
var
  I, J: Byte;
  S: string;
begin
  J := 0;
  for I := 1 to Byte(Mask^[0]) do
  begin
    if (Mask^[I] in EditMaskChars) then
    begin
      if (J < Byte(Data^[0])) then
      begin
        Inc(J);
        if ((EditFlags and dfHide) <> 0) then
          St[I] := HideChar else
          St[I] := Data^[J];
      end else
      begin
        St[I] := PadChar;
      end;
    end else
    begin
      St[I] := Mask^[I];
    end;
  end;
  Byte(St[0]) := I;
  if Justify then
  begin
    if ((EditFlags and dfRJustify) <> 0) then
    begin
      TrimCh(St, PadChar);
      LeftPadCh(St, MaxLen, PadChar);
    end else if ((EditFlags and dfLJustify) <> 0) then
    begin
      TrimCh(St, PadChar);
      PadCh(St, MaxLen, PadChar);
    end else if ((EditFlags and dfTrim) <> 0) then
      TrimCh(St, PadChar) else
      PadCh(St, MaxLen, PadChar);
  end;
end;

function TbxEditLine.NextPos(Pos: Integer): Integer;
var
  X: Integer;
begin
  X := Pos + 1;
  while (X <= Byte(Mask^[0])) and not (Mask^[X] in EditMaskChars) do Inc(X);
  if (X <= Byte(Mask^[0]) + 1) then NextPos := X else NextPos := Pos;
end;

function TbxEditLine.PrevPos(Pos: Integer): Integer;
var
  X: Integer;
begin
  X := Pos - 1;
  while (X > 0) and not (Mask^[X] in EditMaskChars) do Dec(X);
  if (X > 0) then PrevPos := X else PrevPos := Pos;
end;

function TbxEditLine.Remove(const St: string): string;
var
  I, J: Byte;
  S: string;
begin
  J := 0;
  FillChar(S, SizeOf(S), 0);
  for I := 1 to Byte(St[0]) do
  begin
    if (Mask^[I] in EditMaskChars) then
    begin
      Inc(J);
      S[J] := St[I];
    end
  end;
  Byte(S[0]) := J;
  Remove := S;
end;

procedure TbxEditLine.SelectAll(Enable: Boolean);
begin
  CurPos := HomePos;
  XPos := MaskToEditPos(CurPos);
  FirstPos := 1;
  SelStart := 1;
  if (Enable and (Byte(Data^[0]) > 0)) then
    SelEnd := Byte(Mask^[0]) else
    SelEnd := 1;
  DrawView;
end;

procedure TbxEditLine.SetData(var Rec);
begin
  Data^ := FTrimCh(Remove(string(Rec)), PadChar);
  SelectAll(True);
end;

procedure TbxEditLine.SetEditFlag(AFlag: Word; Enable: Boolean);
begin
  if Enable then
    EditFlags := EditFlags or AFlag else
    EditFlags := EditFlags and not AFlag;
  if Enable and (AFlag and (dfRequired or dfDefaults) <> 0) then
    Options := Options or ofValidate;
end;

procedure TbxEditLine.SetId(AFieldId: Word);
begin
  Id := AFieldId;
end;

procedure TbxEditLine.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  if (AState = sfSelected) or
    ((AState = sfActive) and (State and sfSelected <> 0)) then
    SelectAll(Enable)
  else if (AState and sfDisabled <> 0) then
    if (LLabel <> nil) then LLabel^.SetState(sfDisabled, Enable);
end;

procedure TbxEditLine.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(PadChar, SizeOf(Char));
  S.Write(XPos, SizeOf(Byte));
  S.Write(First, SizeOf(Byte));
  S.WriteStr(Mask);
  S.Write(Id, SizeOf(Byte));
  PutPeerViewPtr(S, LLabel);
  S.Write(EditFlags, SizeOf(Word));
end;

procedure TbxEditLine.Unlock;
begin
  SetState(sfDisabled, False);
end;

function TbxEditLine.Valid(Command: Word): Boolean;
var
  Mes: string;
begin
  if (Command <> cmCancel) and (Command <> cmValid)
    and ((EditFlags and dfRequired) <> 0) and Empty then
  begin
    Mes := 'В поле "' + GetFieldName + '" должны быть данные!';
    Message(Owner, evBroadcast, cmFieldError, @Mes);
    Valid := False;
    Select;
  end else Valid := inherited Valid(Command);
end;

constructor TbxDateEdit.Init(var Bounds: TRect; ADatePic: TbxDateSt);
var
  Picture: TbxDateSt;
  I: Byte;
begin
  Picture := ADatePic;
  for I := 1 to Length(Picture) do
    case Picture[I] of
      'm', 'M', 'd', 'D', 'y', 'Y':
	Picture[I] := '@';
    end;
  inherited Init(Bounds, Picture);
  DatePic := ADatePic;
  Date := New(PbxDate, Init(0, 0, 0));
end;

constructor TbxDateEdit.Load(var S: TStream);
begin
  INHERITED Load(S);
  S.Read(DatePic, SizeOf(TbxDateSt));
  Date := New(PbxDate, Load(S));
end;

function TbxDateEdit.DataSize: Word;
begin
  DataSize := SizeOf(TbxDateRec);
end;

PROCEDURE TBXDateEdit.GetData(VAR Rec);
BEGIN
  Date^.GetData(Rec);
END;

procedure TbxDateEdit.SetData(var Rec);
begin
  Date^.SetData(Rec);
  Data^ := Remove(Date^.DateString(DatePic));
  SelectAll(True);
end;

procedure TbxDateEdit.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(DatePic, SizeOf(TbxDateSt));
  Date^.Store(S);
end;

function TbxDateEdit.Valid(Command: Word): Boolean;
var
  HasDay: Boolean;
  HasMonth: Boolean;
  ValidMonth: Boolean;
  Picture: TbxDateSt;
  Mes: string;
begin
  if (Command <> cmCancel) and (Command <> cmValid) and not Empty then
  begin
    Valid := True;
    Merge(Picture, False);
    Date^.ExtractDate(DatePic, Picture);
    HasDay := (Pos('d', DatePic) <> 0) or (Pos('D', DatePic) <> 0);
    HasMonth := (Pos('m', DatePic) <> 0) or (Pos('M', DatePic) <> 0);
    if (EditFlags and dfDefaults <> 0) then
    begin
      HasMonth := True;
      HasDay := True;
      if (Date^.Year = 0) or (Date^.Day = 0) or (Date^.Month = 0) then
      begin
        if (Date^.Year = 0) then Date^.Year := DefaultYear;
        if (Date^.Day = 0) then Date^.Day := DefaultDay;
        if (Date^.Month = 0) then Date^.Month := DefaultMonth;
        Data^ := Remove(Date^.DateString(DatePic));
        DrawView;
      end;
    end;
    if (HasMonth and HasDay) then ValidMonth := Date^.Valid
    else if HasMonth then
      ValidMonth := (Date^.Month > 0) and (Date^.Month < 13)
    else ValidMonth := True;
    if not ValidMonth then
    begin
      Valid := False;
      Select;
      Mes := GetFieldName + 'Неправильная дата.'+ ^M +
        'Вводите дату в формате: '+ DatePic + '.';
      Message(Owner, evBroadcast, cmFieldError, @Mes);
    end;
  end
  else Valid := inherited Valid(Command);
end;

destructor TbxDateEdit.Done;
begin
  Dispose(Date, Done);
  inherited Done;
end;

procedure TbxNumericEdit.HandleEvent(var Event: TEvent);
var
  ValidChar: Boolean;
begin
  if (Event.What = evKeyDown) then
  begin
    case Event.CharCode of
      ' ' .. #255:
        begin
          case (Mask^[CurPos]) of
            DigitOnly:
              ValidChar := (Event.CharCode in DigitOnlySet);
            NumberOnly:
              ValidChar := (Event.CharCode in NumberOnlySet);
            HexOnly:
              ValidChar := (Event.CharCode in HexOnlySet);
          else ValidChar := False;
          end;
          if not ValidChar then
            ClearEvent (Event)
          else case Event.CharCode of
            '-', '$':
              begin
                if (Byte(Data^[0]) > 0) then
                begin
                  if (Data^[1] <> Event.CharCode)
                    and (Byte(Data^[0]) < MaxLen) then
                  begin
                    Insert(Event.CharCode, Data^, 1);
                    CurPos := NextPos(CurPos);
                  end else if (Data^[1] = Event.CharCode) then
                  begin
                    Delete(Data^, 1, 1);
                    CurPos := PrevPos(CurPos);
                  end;
                  XPos := MaskToEditPos(CurPos);
                  DrawView;
                  ClearEvent(Event);
                end;
              end;
          end;
        end;
    end;
  end;
  inherited HandleEvent(Event);
end;

function TbxNumericEdit.OutOfRangeMsg: string;
begin
  OutOfRangeMsg := 'Entry is not in valid range';
end;

function TbxNumericEdit.OutOfRange: Boolean;
begin
  OutOfRange := False;
end;

function TbxNumericEdit.Valid(Command: Word): Boolean;
var
  Mes: string;
begin
  Valid := True;
  if (Command <> cmCancel) and (Command <> cmValid) and OutOfRange then
  begin
    Valid := False;
    Select;
    Mes := GetFieldName + ^M + OutOfRangeMsg;
    Message(Owner, evBroadcast, cmFieldError, @Mes);
  end else Valid := inherited Valid(Command);
end;

constructor TbxLongEdit.Init(var Bounds: TRect; const AMask: string;
  AMin: Longint; AMax: Longint);
begin
  inherited Init(Bounds, AMask);
  if (AMin <= AMax) then
  begin
    Min := AMin;
    Max := AMax;
  end else
  begin
    Min := AMax;
    Max := AMin;
  end;
end;

constructor TbxLongEdit.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Min, SizeOf(Longint));
  S.Read(Max, SizeOf(Longint));
end;

function TbxLongEdit.DataSize: Word;
begin
  DataSize := SizeOf(Longint);
end;

procedure TbxLongEdit.GetData(var Rec);
begin
  if (Data^ = '') or (Data^ = '$') or (Data^ = '-') then Data^ := '0';
  Val(Data^, Longint(Rec), ErrCode);
  if (ErrCode <> 0) then Longint(Rec) := 0;
end;

function TbxLongEdit.OutOfRange: Boolean;
var
  Value: Longint;
begin
  OutOfRange := False;
  if (Min <> 0) or (Max <> 0) then
  begin
    TbxLongEdit.GetData(Value);
    if (ErrCode = 0) then OutOfRange := ((Value < Min) or (Value > Max));
  end;
end;

function TbxLongEdit.OutOfRangeMsg: string;
var
  MinStr, MaxStr: string[11];
begin
  Str(Min, MinStr);
  Str(Max, MaxStr);
  Trim(MinStr);
  Trim(MaxStr);
  OutOfRangeMsg := 'Valid Range is ' + MinStr + ' to '+ MaxStr;
end;

procedure TbxLongEdit.SetData(var Rec);
begin
  if (Min <> 0) or (Max <> 0) then
    if (Longint(Rec) < Min) then Longint(Rec) := Min
    else if (Longint(Rec) > Max) then Longint(Rec) := Max;
  Str(Longint(Rec), Data^);
  Trim(Data^);
  SelectAll(True);
end;

procedure TbxLongEdit.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Min, SizeOf(Longint));
  S.Write(Max, SizeOf(Longint));
end;

function TbxHexEdit.OutOfRangeMsg: string;
var
  MinStr, MaxStr: string[16];
begin
  OutOfRangeMsg := 'Range is '+ HexString(Min) + ' to ' + HexString(Max);
end;

procedure TbxHexEdit.SetData(var Rec);
var
  Picture: string[9];
begin
  Picture := HexString(Longint(Rec));
  while (Byte(Picture[0]) > MaxLen) and (Picture[2] = '0') do
    Delete(Picture, 2, 1);
  TruncateStr(Picture, MaxLen);
  Data^ := Picture;
  SelectAll(True);
end;

constructor TbxIntegerEdit.Init(var Bounds: TRect; const AMask: string;
  AMin:Integer; AMax: Integer);
begin
  inherited Init(Bounds, AMask, AMin, AMax);
end;

function TbxIntegerEdit.DataSize: Word;
begin
  DataSize := SizeOf(Integer);
end;

procedure TbxIntegerEdit.GetData(var Rec);
var
  L: Longint;
begin
  TbxLongEdit.GetData(L);
  Integer(Rec) := L;
end;

procedure TbxIntegerEdit.SetData(var Rec);
var
  L: Longint;
begin
  L := Integer(Rec);
  TbxLongEdit.SetData(L);
end;

constructor TbxWordEdit.Init(var Bounds: TRect;const AMask: string;
  AMin: Word; AMax: Word);
begin
  inherited Init(Bounds, AMask, AMin, AMax);
end;

function TbxWordEdit.DataSize: Word;
begin
  DataSize := SizeOf(Word);
end;

procedure TbxWordEdit.GetData(var Rec);
var
  L: Longint;
begin
  TbxLongEdit.GetData(L);
  Word(Rec) := L;
end;

procedure TbxWordEdit.SetData(var Rec);
var
  L: Longint;
begin
  L := Word(Rec);
  TbxLongEdit.SetData(L);
end;

constructor TbxByteEdit.Init(var Bounds: TRect; const AMask: string;
  AMin: Byte; AMax: Byte);
begin
  TbxLongEdit.Init(Bounds, AMask, AMin, AMax);
end;

function TbxByteEdit.DataSize: Word;
begin
  DataSize := SizeOf(Byte);
end;

procedure TbxByteEdit.GetData(var Rec);
var
  L: Longint;
begin
  TbxLongEdit.GetData(L);
  Byte(Rec) := L;
end;

procedure TbxByteEdit.SetData(var Rec);
var
  L: Longint;
begin
  L := Byte(Rec);
  TbxLongEdit.SetData(L);
end;

constructor TbxFloatEdit.Init(var Bounds: TRect; const AMask: string);
var
  X: Byte;
  I: Byte;
  Picture: string;
begin
  Picture := AMask;
  X := Pos(DECIMALPT, Picture);
  if (X <> 0) then
  begin
    I := 0;
    repeat Inc(I); until (Picture[I] in EditMaskChars);
    Picture[X] := Picture[I];
  end;
  inherited Init(Bounds, Picture);
  if (X <> 0) then DP := Length(Picture) - X else DP := 0;
end;

constructor TbxFloatEdit.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(DP, SizeOf(Byte));
end;

procedure TbxFloatEdit.HandleEvent(var Event: TEvent);
var
  X: Byte;
begin
  case Event.What of
    evKeyDown:
      begin
        case CtrlToArrow(Event.KeyCode) of
          kbBack:
            begin
              if (XPos > 1) then
                if (Data^[XPos-1] = DecimalPt) then ClearEvent(Event);
            end;
          kbDel:
            begin
              if (XPos <= Length(Data^)) then
                if (Data^[XPos] = DecimalPt) then ClearEvent(Event);
            end;
        else
          case Event.CharCode of
            DecimalPt:
              begin
                if (DP = 0) then
                begin
                  ClearEvent(Event);
                end else if (Pos(DecimalPt, Data^) <> 0) then
                begin
                  XPos := Pos(DecimalPt, Data^);
                  CurPos := NextPos(EditToMaskPos(XPos));
                  Inc(XPos);
                  ClearEvent(Event);
                  DrawView;
                end else
                begin
                  InsertChar(DecimalPt);
                  ClearEvent(Event);
                  DrawView;
                end;
              end;
            '0' .. '9':
              begin
                if (DP <> 0) then
                begin
                  X := Pos(DecimalPt, Data^);
                  if (X <> 0) then
                    if (XPos > X) then
                      if ((Length(Data^) - X) = DP) then ClearEvent(Event);
                end;
              end;
          end;
        end;
      end;
  end;
  inherited HandleEvent(Event);
end;

procedure TbxFloatEdit.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(DP, SizeOf(Byte));
end;

{$IFOPT N+}
constructor TbxDoubleEdit.Init(var Bounds: TRect; const AMask: string;
  AMin: Double; AMax: Double);
begin
  inherited Init(Bounds, AMask);
  if (AMin <= AMax) then
  begin
    Min := AMin;
    Max := AMax;
  end else
  begin
    Min := AMax;
    Max := AMin;
  end;
end;

constructor TbxDoubleEdit.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Min, SizeOf(Double));
  S.Read(Max, SizeOf(Double));
end;

function TbxDoubleEdit.DataSize: Word;
begin
  DataSize := SizeOf(Double);
end;

procedure TbxDoubleEdit.GetData(var Rec);
begin
  Strip(Data^, ['$']);
  if (Data^ = '') or (Data^ = '-') then Data^ := '0';
  Val(Data^, Double(Rec), ErrCode);
  if (ErrCode <> 0) then Double(Rec) := 0.0;
end;

function TbxDoubleEdit.OutOfRange: Boolean;
var
  Value: Double;
begin
  OutOfRange := False;
  if (Min <> 0.0) or (Max <> 0.0) then
  begin
    GetData(Value);
    if (ErrCode = 0) then OutOfRange := (Value < Min) or (Value > Max);
  end;
end;

function TbxDoubleEdit.OutOfRangeMsg: string;
var
  MinStr, MaxStr: string[20];
  Precision: Byte;
begin
  if (Dp > 0) then Precision := 20 - Dp - 1 else Precision := 20;
  Str (Min: Precision: Dp, MinStr);
  Str (Max: Precision: Dp, MaxStr);
  Trim(MinStr);
  Trim(MaxStr);
  OutOfRangeMsg := 'Valid Range is ' + MinStr + ' to '+ MaxStr;
end;

procedure TbxDoubleEdit.SetData(var Rec);
var
  Precision: Byte;
begin
  Strip(Data^, ['$']);
  if (Dp > 0) then Precision := MaxLen - Dp - 1 else Precision := MaxLen;
  if (Min <> 0.0) or (Max <> 0.0) then
    if (Double(Rec) < Min) then Double(Rec) := Min
    else if (Double (Rec) > Max) then Double(Rec) := Max;
  Str(Double(Rec): Precision: Dp, Data^);
  Trim(Data^);
  SelectAll(True);
end;

procedure TbxDoubleEdit.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Min, SizeOf(Double));
  S.Write(Max, SizeOf(Double));
end;
{$ENDIF}

constructor TbxRealEdit.Init(var Bounds: TRect; const AMask: string;
  AMin: Real; AMax: Real);
begin
  inherited Init(Bounds, AMask);
  if (AMin <= AMax) then
  begin
    Min := AMin;
    Max := AMax;
  end else
  begin
    Min := AMax;
    Max := AMin;
  end;
end;

constructor TbxRealEdit.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Min, SizeOf(Real));
  S.Read(Max, SizeOf(Real));
end;

function TbxRealEdit.DataSize: Word;
begin
  DataSize := SizeOf(Real);
end;

procedure TbxRealEdit.GetData(var Rec);
begin
  Strip(Data^, ['$']);
  if (Data^ = '') or (Data^ = '-') then Data^ := '0';
  Val(Data^, Real(Rec), ErrCode);
  if (ErrCode <> 0) then Real(Rec) := 0.0;
end;

function TbxRealEdit.OutOfRange: Boolean;
var
  Value: Real;
begin
  OutOfRange := False;
  if (Min <> 0.0) or (Max <> 0.0) then
  begin
    TbxRealEdit.GetData(Value);
    if (ErrCode = 0) then OutOfRange := (Value < Min) or (Value > Max);
  end;
end;

function TbxRealEdit.OutOfRangeMsg: string;
var
  MinStr, MaxStr: string[20];
  Precision: Byte;
begin
  if (Dp > 0) then Precision := 20 - Dp - 1 else Precision := 20;
  Str(Min: Precision: Dp, MinStr);
  Str(Max: Precision: Dp, MaxStr);
  Trim(MinStr);
  Trim(MaxStr);
  OutOfRangeMsg := 'Valid Range is ' + MinStr + ' to ' + MaxStr;
end;

procedure TbxRealEdit.SetData(var Rec);
var
  Precision: Byte;
begin
  Strip(Data^, ['$']);
  if (Dp > 0) then Precision := MaxLen - Dp - 1 else Precision := MaxLen;
  if (Min <> 0.0) or (Max <> 0.0) then
    if (Real(Rec) < Min) then Real(Rec) := Min
    else if (Real(Rec) > Max) then Real(Rec) := Max;
  Str(Real(Rec): Precision: Dp, Data^);
  Trim(Data^);
  SelectAll(True);
end;

procedure TbxRealEdit.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Min, SizeOf(Real));
  S.Write(Max, SizeOf(Real));
end;

constructor TbxCheckBoxes.Init(var Bounds: TRect; AStrings: PSItem);
begin
  inherited Init(Bounds, AStrings);
  LLabel := nil;
  Id := 0;
  EditFlags := 0;
  EventMask := EventMask or evBroadcast;
end;

constructor TbxCheckBoxes.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Id, SizeOf(Byte));
  GetPeerViewPtr(S, LLabel);
  S.Read(EditFlags, SizeOf(Word));
end;

procedure TbxCheckBoxes.AddLabel(ALabel: Pointer);
begin
  LLabel := ALabel;
end;

function TbxCheckBoxes.Empty: Boolean;
begin
  Empty := (Value = 0);
end;

function TbxCheckBoxes.GetFieldName: string;
var
  Name: string;
begin
  if (LLabel <> nil) then
  begin
    Name := PLabel(LLabel)^.Text^;
    Strip(Name, ['~']);
  end else Name := '';
  GetFieldName := Name;
end;

function TbxCheckBoxes.GetId: Word;
begin
  GetId := Id;
end;

procedure TbxCheckBoxes.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  case Event.What of
    evBroadcast:
      begin
        case Event.Command of
          cmSetId:
            begin
              SetId(Event.InfoWord);
              ClearEvent(Event);
              Event.InfoPtr := @Self;
            end;
          cmIdentify:
            if (Event.InfoWord = Id) then
            begin
              ClearEvent(Event);
              Event.InfoPtr := @Self;
            end;
        end;
      end;
  end;
end;

procedure TbxCheckBoxes.Lock;
begin
  SetState(sfDisabled, True);
end;

procedure TbxCheckBoxes.SetEditFlag(AFlag: Word; Enable: Boolean);
begin
  if Enable then
    EditFlags := EditFlags or AFlag else
    EditFlags := EditFlags and not AFlag;
  if Enable and (AFlag and dfRequired <> 0) then
    Options := Options or ofValidate;
end;

procedure TbxCheckBoxes.SetId(AFieldId: Word);
begin
  Id := AFieldId;
end;

procedure TbxCheckBoxes.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfDisabled <> 0) then
    if (LLabel <> nil) then LLabel^.SetState(sfDisabled, Enable);
end;

procedure TbxCheckBoxes.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Id, SizeOf(Byte));
  PutPeerViewPtr(S, LLabel);
  S.Write(EditFlags, SizeOf(Word));
end;

procedure TbxCheckBoxes.Unlock;
begin
  SetState(sfDisabled, False);
end;

function TbxCheckBoxes.Valid(Command: Word): Boolean;
var
  Mes: string;
begin
  if (Command <> cmCancel) and (Command <> cmValid)
    and ((EditFlags and dfRequired) <> 0) and Empty then
  begin
    Mes := GetFieldName + ^M + 'Field is required.';
    Message(Owner, evBroadcast, cmFieldError, @Mes);
    Valid := False;
    Select;
  end else Valid := inherited Valid(Command);
end;

constructor TbxRadioButtons.Init(var Bounds: TRect; AStrings: PSItem);
begin
  inherited Init(Bounds, AStrings);
  LLabel := nil;
  Id := 0;
  EditFlags := 0;
  EventMask := EventMask or evBroadcast;
end;

constructor TbxRadioButtons.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Id, SizeOf(Byte));
  GetPeerViewPtr(S, LLabel);
  S.Read(EditFlags, SizeOf(Word));
end;

procedure TbxRadioButtons.AddLabel(ALabel: Pointer);
begin
  LLabel := ALabel;
end;

function TbxRadioButtons.GetFieldName: string;
var
  Name: string;
begin
  if (LLabel <> nil) then
  begin
    Name := PLabel(LLabel)^.Text^;
    Strip(Name, ['~']);
  end else Name := '';
  GetFieldName := Name;
end;

function TbxRadioButtons.GetId: Word;
begin
  GetId := Id;
end;

procedure TbxRadioButtons.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  case Event.What of
    evBroadcast:
      begin
        case Event.Command of
          cmSetId:
            begin
              SetId(Event.InfoWord);
              ClearEvent(Event);
              Event.InfoPtr := @Self;
            end;
          cmIdentify:
            if (Event.InfoWord = Id) then
            begin
              ClearEvent(Event);
              Event.InfoPtr := @Self;
            end;
        end;
      end;
  end;
end;

procedure TbxRadioButtons.Lock;
begin
  SetState(sfDisabled, True);
end;

procedure TbxRadioButtons.SetEditFlag(AFlag: Word; Enable: Boolean);
begin
  if Enable then
    EditFlags := EditFlags or AFlag else
    EditFlags := EditFlags and not AFlag;
end;

procedure TbxRadioButtons.SetId(AFieldId: Word);
begin
  Id := AFieldId;
end;

procedure TbxRadioButtons.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfDisabled <> 0) then
    if (LLabel <> nil) then LLabel^.SetState(sfDisabled, Enable);
end;

procedure TbxRadioButtons.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Id, SizeOf(Byte));
  PutPeerViewPtr(S, LLabel);
  S.Write(EditFlags, SizeOf(Word));
end;

procedure TbxRadioButtons.Unlock;
begin
  SetState(sfDisabled, False);
end;

constructor TbxSlider.Init(var Bounds: TRect; AMin: Integer; AMax: Integer;
  const AMinLabel: string; const AMaxLabel: string);
var
  R: TRect;
  P: PView;
begin
  inherited Init(Bounds);
  EventMask := EventMask or evBroadcast;
  Options := Options or ofFirstClick;
  LLabel := nil;
  Id := 0;
  EditFlags := 0;
  R.Assign(0, 0, Size.X, Size.Y);
  P := New(PStaticText, Init(R, ' '));
  if (Application^.ValidView(P) = nil) then Fail;
  Insert(P);
  if (AMinLabel <> '') or (AMaxLabel <> '') then
    R.Assign(0, 1, Size.X, Size.Y) else
    R.Assign(0, 0, Size.X, Size.Y);
  ScrollBar := New(PScrollBar, Init(R));
  ScrollBar^.Options := ScrollBar^.Options or ofSelectable;
  if (Application^.ValidView(ScrollBar) = nil) then Fail;
  Insert(ScrollBar);
  ScrollBar^.SetRange(AMin, AMax);
  if (AMinLabel <> '') then
  begin
    R.Assign(0, 0, Length(AMinLabel), 1);
    P := New(PStaticText, Init(R, AMinLabel));
    if (Application^.ValidView(P) = nil) then Fail;
    Insert(P);
  end;
  if (AMaxLabel <> '') then
  begin
    R.Assign(Size.X - Length(AMaxLabel), 0, Size.X, 1);
    P := New(PStaticText, Init(R, AMaxLabel));
    if (Application^.ValidView(P) = nil) then Fail;
    Insert(P);
  end;
end;

constructor TbxSlider.Load(var S: TStream);
begin
  inherited Load(S);
  GetSubViewPtr(S, ScrollBar);
  S.Read(Id, SizeOf(Byte));
  GetPeerViewPtr(S, LLabel);
  S.Read(EditFlags, SizeOf(Word));
end;

procedure TbxSlider.AddLabel(ALabel: Pointer);
begin
  LLabel := ALabel;
end;

procedure TbxSlider.GetData(var Rec);
begin
  Integer(Rec) := ScrollBar^.Value;
end;

function TbxSlider.GetFieldName: string;
var
  Name: string;
begin
  if (LLabel <> nil) then
  begin
    Name := PLabel(LLabel)^.Text^;
    Strip(Name, ['~']);
  end else Name := '';
  GetFieldName := Name;
end;

function TbxSlider.GetId: Word;
begin
  GetId := Id;
end;

procedure TbxSlider.HandleEvent(var Event: TEvent);

function MatchView(P: PView): Boolean; far;
begin
  MatchView := (P^.State and sfVisible <> 0) and P^.MouseInView(Event.Where);
end;

begin
  if (Event.What = evBroadcast) then
  begin
    case Event.Command of
      cmSetId:
        begin
          SetId (Event.InfoWord);
          ClearEvent(Event);
          Event.InfoPtr := @Self;
        end;
      cmIdentify:
        if (Event.InfoWord = Id) then
        begin
          ClearEvent(Event);
          Event.InfoPtr := @Self;
        end;
    end;
  end else if (Event.What and PositionalEvents <> 0) then
  begin
    if (FirstThat(@MatchView) <> Last) then
      inherited HandleEvent(Event) else
      ClearEvent(Event);
  end else inherited HandleEvent(Event)
end;

procedure TbxSlider.Lock;
begin
  SetState(sfDisabled, True);
end;

procedure TbxSlider.SetData(var Rec);
begin
  if (Integer(Rec) <> ScrollBar^.Value) then
    ScrollBar^.SetValue(Integer(Rec));
end;

procedure TbxSlider.SetEditFlag(AFlag: Word; Enable: Boolean);
begin
  if Enable then
    EditFlags := EditFlags or AFlag else
    EditFlags := EditFlags and not AFlag;
end;

procedure TbxSlider.SetId(AFieldId: Word);
begin
  Id := AFieldId;
end;

procedure TbxSlider.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfDisabled <> 0) then
  begin
    ScrollBar^.SetState(sfDisabled, Enable);
    if (LLabel <> nil) then LLabel^.SetState(sfDisabled, Enable);
  end;
end;

procedure TbxSlider.Store(var S: TStream);
begin
  inherited Store(S);
  PutSubViewPtr(S, ScrollBar);
  S.Write(Id, SizeOf(Byte));
  PutPeerViewPtr(S, LLabel);
  S.Write(EditFlags, SizeOf(Word));
end;

procedure TbxSlider.Unlock;
begin
  SetState(sfDisabled, False);
end;

constructor TbxSpinBar.Init(var Bounds: TRect);
const
  VSpinChars: TbxSpinChars = (#30, #31);
  HSpinChars: TbxSpinChars = (#17, #16);
begin
  inherited Init(Bounds);
  Options := Options or ofFirstClick;
  if Size.X = 1 then Chars := VSpinChars else Chars := HSpinChars;
end;

constructor TbxSpinBar.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Chars, 2 * SizeOf(Char));
end;

procedure TbxSpinBar.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B[0], Chars[1], GetColor(2), 1);
  MoveChar(B[1], Chars[2], GetColor(2), 1);
  WriteBuf(0, 0, Size.X, Size.Y, B);
end;

procedure TbxSpinBar.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  X: Integer;
begin
  TView.HandleEvent(Event);
  case Event.What of
    evMouseDown:
      begin
        SpinEdit^.GetData(X);
        if (X < Min) then X := Min else if (X > Max) then X := Max;
        if (Value <> X) then Value := X;
        repeat
          MakeLocal(Event.Where, Mouse);
          X := 0;
          if (Size.X = 1) then
          begin
            if (Mouse.Y = 0) then X := ArStep
            else if (Mouse.Y = 1) then X := - ArStep;
          end else if (Size.Y = 1) then
          begin
            if (Mouse.X = 1) then X := ArStep
            else if (Mouse.X = 0) then X := - ArStep;
          end;
          if (X <> 0) then SetValue(Value + X);
        until not MouseEvent(Event, evMouseAuto) or not MouseInView(Event.Where);
        ClearEvent(Event);
      end;
  end;
end;

procedure TbxSpinBar.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Chars, 2 * SizeOf(Char));
end;

constructor TbxSpinEdit.Init(var Bounds: TRect; const AMask: string;
  ASpinBar: PbxSpinBar);
begin
  if (ASpinBar = nil) then Fail;
  inherited Init(Bounds, AMask, ASpinBar^.Min, ASpinBar^.Max);
  SpinBar := ASpinBar;
  EventMask := EventMask or evBroadcast;
  Options := Options or ofValidate;
  inherited SetData(SpinBar^.Value);
  SpinBar^.SpinEdit := @Self;
end;

constructor TbxSpinEdit.Load(var S: TStream);
begin
  inherited Load(S);
  GetPeerViewPtr(S, SpinBar);
end;

procedure TbxSpinEdit.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evBroadcast) then
  begin
    case Event.Command of
      cmScrollBarChanged:
        if (Event.InfoPtr = SpinBar) then SetData(SpinBar^.Value);
    end;
  end;
  inherited HandleEvent(Event);
end;

procedure TbxSpinEdit.SetData(var Rec);
var
  X: Integer;
begin
  GetData(X);
  if (Integer(Rec) <> X) then
  begin
    inherited SetData(Rec);
    SpinBar^.SetValue(Integer(Rec));
  end;
end;

procedure TbxSpinEdit.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfDisabled <> 0) then SpinBar^.SetState(sfDisabled, Enable);
end;

procedure TbxSpinEdit.Store(var S: TStream);
begin
  inherited Store(S);
  PutPeerViewPtr(S, SpinBar);
end;

function TbxSpinEdit.Valid(Command: Word): Boolean;
var
  X: Integer;
begin
  GetData(X);
  if (X < SpinBar^.Min) then
  begin
    X := SpinBar^.Min;
    Valid := False;
  end else if (X > SpinBar^.Max) then
  begin
    X := SpinBar^.Max;
    Valid := False;
  end else
  begin
    Valid := True;
  end;
  SetData(X);
end;

constructor TbxEntryDialog.Init(var Bounds: TRect; ATitle: TTitleStr);
begin
  inherited Init(Bounds, ATitle);
  EventMask := EventMask or evBroadcast;
  NextId := 0;
end;

constructor TbxEntryDialog.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(NextId, SizeOf(Word));
end;

function TbxEntryDialog.FindField(Id: Word): Pointer;

function Identify(P: PView): Boolean; far;
var
  E: TEvent;
begin
  E.What := evBroadcast;
  E.Command := cmIdentify;
  E.InfoWord := Id;
  P^.HandleEvent(E);
  Identify := (E.What = evNothing);
end;

begin
  FindField := FirstThat(@Identify);
end;

procedure TbxEntryDialog.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if (Event.What = evBroadcast) then
    if (Event.Command = cmFieldError) then
    begin
      MessageBox(PString(Event.InfoPtr)^, nil, mfError + mfOkButton);
      ClearEvent(Event);
    end;
end;

procedure TbxEntryDialog.Insert(P: PView);
var
  E: TEvent;
begin
  inherited Insert(P);
  ClearEvent(E);
  E.What := evBroadcast;
  E.Command := cmSetId;
  E.InfoWord := NextId + 1;
  P^.HandleEvent(E);
  if (E.InfoPtr <> nil) then Inc(NextId);
end;

procedure TbxEntryDialog.LockField(Id: Word; Enable: Boolean);
var
  P: PView;
begin
  P := FindField(Id);
  if (P <> nil) then P^.SetState(sfDisabled, Enable);
end;

procedure TbxEntryDialog.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(NextId, SizeOf(Word));
end;

procedure RegisterTvInput;
begin
  RegisterType(RbxEditLine);
  RegisterType(RbxDateEdit);
  RegisterType(RbxLongEdit);
  RegisterType(RbxHexEdit);
  RegisterType(RbxIntegerEdit);
  RegisterType(RbxWordEdit);
  RegisterType(RbxByteEdit);
{$IFOPT N+}
  RegisterType(RbxDoubleEdit);
{$ENDIF}
  RegisterType(RbxRealEdit);
  RegisterType(RbxRadioButtons);
  RegisterType(RbxCheckBoxes);
  RegisterType(RbxEntryDialog);
  RegisterType(RbxSlider);
  RegisterType(RbxSpinBar);
  RegisterType(RbxSpinEdit);
end;

end.
