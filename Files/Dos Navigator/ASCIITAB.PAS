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

unit ASCIITab;

interface

uses Objects, DNApp, Views, Drivers, RStrings, ObjType;

type
  PTable = ^TTable;
  TTable = object(TView)
    procedure Draw; virtual;
    procedure HandleEvent(var Event:TEvent); virtual;
    function DataSize: Word; virtual;
    procedure GetData(var Data); virtual;
    procedure SetData(var Data); virtual;
  end;

  PReport = ^TReport;
  TReport = object(TView)
    ASCIIChar: LongInt;
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure HandleEvent(var Event:TEvent); virtual;
    procedure Store(var S: TStream);
  end;

  PASCIIChart = ^TASCIIChart;
  TASCIIChart = object(TWindow)
    constructor Init(var R: TRect);
    function Execute: Word; virtual;
  end;

const
  AsciiTableCommandBase: Word = 910;

  RTable: TStreamRec = (
     ObjType: otTable;
     VmtLink: Ofs(TypeOf(TTable)^);
     Load:    @TTable.Load;
     Store:   @TTable.Store
  );
  RReport: TStreamRec = (
     ObjType: otReport;
     VmtLink: Ofs(TypeOf(TReport)^);
     Load:    @TReport.Load;
     Store:   @TReport.Store
  );
  RASCIIChart: TStreamRec = (
     ObjType: otASCIIChart;
     VmtLink: Ofs(TypeOf(TASCIIChart)^);
     Load:    @TASCIIChart.Load;
     Store:   @TASCIIChart.Store
  );

procedure RegisterASCIITab;

function InputASCIIChar(var R: TRect; var C: Char): Boolean;

implementation

uses
  Commands, DNHelp;

const
  cmCharacterFocused = 0;

function InputASCIIChar(var R: TRect; var C: Char): Boolean;
 const QQQChar: Char = #115;
 var P: PWindow;
     W: Word;
     E: TEvent;
     RR: TRect;
begin
 C := QQQChar;
 P := New(PASCIIChart, Init(RR));
 R.B.X := R.A.X + P^.Size.X;
 R.B.Y := R.A.Y + P^.Size.Y;
 if R.A.Y < 0 then R.Move(0,-R.A.Y);
 if R.A.X < 0 then R.Move(-R.A.X,0);
 if R.B.X > Desktop^.Size.X-3 then R.Move(Desktop^.Size.X-3-R.B.X, 0);
 if R.B.Y > Desktop^.Size.Y-1 then R.Move(0,Desktop^.Size.Y-1-R.B.Y);
 P^.MoveTo(R.A.X, R.A.Y);
 {P^.Options := P^.Options and not ofSelectable;}
 P^.SetData(C);
 {InsertWindow(P);}
 InputASCIIChar := Desktop^.ExecView(P) = cmOK;
 P^.GetData(C);
 QQQChar := C;
 Dispose(P, Done);
end;



procedure TTable.Draw;
var
  Buf: TDrawBuffer;
  X, Y: Integer;
  Color: Byte;
begin
  Color := GetColor(6);
  for Y := 0 to Size.Y - 1 do
  begin
    MoveChar(Buf, ' ', Color, Size.X);
    for X := 0 to Size.X - 1 do
      MoveChar(Buf[x], Chr(32 * y + x), Color, 1);
    WriteLine(0, y, Size.X, 1, Buf);
  end;
  ShowCursor;
end;

procedure TTable.HandleEvent(var Event:TEvent);
var
  CurrentSpot: TPoint;
  C: Char;

procedure CharFocused;
begin
  Message(Owner, evBroadcast, AsciiTableCommandBase + cmCharacterFocused,
    Pointer(Cursor.X + 32 * Cursor.Y));
end;

begin
  if Event.What = evMouseDown then
  begin
    if Event.Double then
     begin
      Event.What := evKeyDown;
      {Event.KeyCode := kbEnter;}
      GetData(C);
      Event.CharCode := C;
      Event.ScanCode := 0;
      PutEvent(Event);
      ClearEvent(Event);
      Exit;
     end;
    repeat
      if MouseInView(Event.Where) then
      begin
        MakeLocal(Event.Where, CurrentSpot);
        SetCursor(CurrentSpot.X, CurrentSpot.Y);
        CharFocused;
      end;
    until not MouseEvent(Event, evMouseMove);
    ClearEvent(Event);
  end
  else if Event.What = evKeyDown then
    with Cursor do begin
      case Event.KeyCode of
        kbHome: SetCursor(0,0);
        kbEnd: SetCursor(Size.X - 1, Size.Y - 1);
        kbUp: if Y > 0 then SetCursor(X, Y - 1);
        kbDown: if Y < Size.Y - 1 then SetCursor(X, Y + 1);
        kbLeft: if X > 0 then SetCursor(X - 1, Y);
        kbRight: if X < Size.X - 1 then SetCursor(X + 1, Y);
      else
        SetCursor(ord(Event.CharCode) mod 32, ord(Event.CharCode) div 32);
      end;
      CharFocused;
      ClearEvent(Event);
    end;
  TView.HandleEvent(Event);
end;

{ TReport }

constructor TReport.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(ASCIIChar, SizeOf(ASCIIChar));
end;

procedure TReport.Draw;
var
  Ch: LongInt;
  Color: Byte;
  Buf: TDrawBuffer;
  TempStr: string;
begin
  FormatStr(TempStr, '  Char: %c Decimal: %0#%3d Hex: %0#%02x  ', ASCIIChar);
  WriteStr(0, 0, TempStr, 6);
end;

procedure TReport.HandleEvent(var Event: TEvent);
var
  Table: PTable;
begin
  TView.HandleEvent(Event);
  if Event.What = evBroadcast then
    if Event.Command = AsciiTableCommandBase + cmCharacterFocused then
    begin
      ASCIIChar := Event.InfoLong;
      DrawView;
    end;
end;

procedure TReport.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(ASCIIChar, SizeOf(ASCIIChar));
end;

function TTable.DataSize;
begin
 DataSize := 1;
end;

procedure TTable.GetData;
begin
 Byte(Data) := Cursor.Y*32 + Cursor.X;
end;

procedure TTable.SetData;
begin
 SetCursor(Byte(Data) mod 32, Byte(Data) div 32);
  Message(Owner, evBroadcast, AsciiTableCommandBase + cmCharacterFocused,
    Pointer(Cursor.X + 32 * Cursor.Y));
 Owner^.ReDraw;
end;

constructor TASCIIChart.Init;
var
  Control: PVIew;
begin
  R.Assign(0, 0, 34, 12);
  TWindow.Init(R, GetString(dlASCIIChart), wnNoNumber);
  Flags := Flags and not (wfGrow + wfZoom);
  HelpCtx := hcAsciiChart;
  Palette := wpGrayWindow;

  R.Grow(-1,-1);
  R.A.Y := R.B.Y - 1;
  Control := New(PReport, Init(R));
  with Control^ do
  begin
    Options := Options or ofFramed;
    EventMask := EventMask or evBroadcast;
  end;
  Insert(Control);

  GetExtent(R);
  R.Grow(-1,-1);
  R.B.Y := R.B.Y - 2;
  Control := New(PTable, Init(R));
  with Control^ do
  begin
    Options := Options or ofFramed or ofSelectable;
    EventMask := $FFFF;
    BlockCursor;
  end;
  Insert(Control);
  Control^.Select;
end;

function TASCIIChart.Execute: Word;
var Event : TEvent;
begin
 repeat
  GetEvent(Event);
  case Event.What of
   evKeyDown: case Event.KeyCode of
               kbESC: begin Event.What := evCommand; Event.Command := cmCancel; end;
               kbEnter, kbCtrlB, kbCtrlP: begin Event.What := evCommand; Event.Command := cmOK; end;
                   else if Event.CharCode > #0 then
                          begin SetData(Event.CharCode); Event.What := evCommand; Event.Command := cmOK; end;
              end;
  end;
  If Event.What<>evNothing then HandleEvent(Event);
 until (Event.What = evCommand) and ((Event.Command < 255) and
        (Event.Command in [cmOK, cmCancel, cmClose]));
 Execute := Event.Command;
end;

procedure RegisterASCIITab;
begin
  RegisterType(RTable);
  RegisterType(RReport);
  RegisterType(RASCIIChart);
end;

end.

