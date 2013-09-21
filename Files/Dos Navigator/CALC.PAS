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

unit Calc;

interface

uses Objects, Views, CellsCol, Drivers, Dialogs, Par, Messages,
     HistList, UniWin, Commands, DNHelp, RStrings, ObjType;

const
     CellClipboard : PCellCollection = nil;
     ClipRect      : record A, B: TPoint; end = (A:(X:0; Y:0); B:(X:0; Y:0));
     FalseStr      : String[10] = 'False';
     TrueStr       : String[10] = 'True';

type
    PCalcView = ^TCalcView;
    PCalcWindow = ^TCalcWindow;
    TCalcWindow = object(TUniWindow)
     Name: String;
     CalcView: PCalcView;
     constructor Init(Bounds: TRect; AName: String);
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     procedure HandleEvent(var Event: TEvent); virtual;
    end;

    TCalcView = object(TView)

     FocusEvent: TEvent;
     Info, CellInfo: PView;

     HScroll, VScroll: PScrollBar;
     Delta, Cur, Mark: TPoint;
     Cells: PCellCollection;
     NumC: Byte;
     Error, ReError, Marking, BlockDraw, Modified: Boolean;
     CellWidth: Array[Byte] of Byte;
     CurrentCalc, SearchPos, ErrorCell: TPoint;

     constructor Init(Bounds: TRect; AInfo, ACellInfo: PView;
                      AHScroll, AVScroll: PScrollBar);
     destructor Done; virtual;

     constructor Load(var S: TStream);
     procedure Store(var S: TStream);

     procedure Draw; virtual;
     function Valid(Command: Word): Boolean; virtual;
     procedure SetState(AState: Word; Enable: Boolean); virtual;
     function GetPalette: PPalette; virtual;
     procedure HandleEvent(var Event: TEvent); virtual;
     Function GetCellValue( S : String) : Real;
     Function GetFuncValue(P: FPtr) : Real;
     Function CalcFormula( P : FPtr) : Real;
     Function CalcFormulaTree( P : FPtr) : Real;
     procedure CalcError( Index: TStrIdx ); virtual;
     procedure ModifyCell(X, Y: Integer);
     procedure LoadSheet(FName: TTitleStr);
     procedure SaveSheet;
     procedure SaveSheetAs;
     function  AskSave: Boolean;
     procedure Copy; virtual;
     procedure Paste; virtual;
     procedure Clear; virtual;
     procedure ReCalc;
     procedure InsertLineCol(Command: Word); virtual;
     procedure DeleteLineCol(Command: Word); virtual;
     procedure GotoCell(Cell: String);
     procedure SearchCell;
    end;

    PCalcInfo = ^TCalcInfo;
    TCalcInfo = object(TInputLine)
     CalcView: PCalcView;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     function GetPalette: PPalette; virtual;
     procedure HandleEvent(var Event: TEvent); virtual;
    end;

    PInfoView = ^TInfoView;
    TInfoView = object(TView)
      InfoStr: String;
      InfoAttr: Byte;
      constructor Load(var S: TStream);
      procedure Store(var S: TStream);
      procedure SetInfo(S: String; Attr: Byte);
      procedure Draw; virtual;
    end;

function GetFileName(var FileName: String; Mask, Title, ALabel: String; Buttons: Word): Word;


const
      RCalcWindow: TStreamRec = (
       ObjType: otCalcWindow;
       VmtLink: Ofs(TypeOf(TCalcWindow)^);
       Load: @TCalcWindow.Load;
       Store: @TCalcWindow.Store);

      RCalcView: TStreamRec = (
       ObjType: otCalcView;
       VmtLink: Ofs(TypeOf(TCalcView)^);
       Load: @TCalcView.Load;
       Store: @TCalcView.Store);

      RCalcInfo: TStreamRec = (
       ObjType: otCalcInfo;
       VmtLink: Ofs(TypeOf(TCalcInfo)^);
       Load: @TCalcInfo.Load;
       Store: @TCalcInfo.Store);

      RInfoView: TStreamRec = (
       ObjType: otInfoView;
       VmtLink: Ofs(TypeOf(Calc.TInfoView)^);
       Load: @Calc.TInfoView.Load;
       Store: @Calc.TInfoView.Store);


implementation

uses Memory, Dos, DNApp, DNStdDlg, Advance, MicroEd;

const  SearchData: record S: String[240]; CellOptions, TxtOptions: Word; end =
                    (S:''; CellOptions:0; TxtOptions:0);
       ReplaceData: record S, S1: String[240]; CellOptions, TxtOptions: Word; end =
                    (S:''; S1:''; CellOptions:0; TxtOptions:0);
       WasReplace: Boolean = False;
       ContSearch: Boolean = False;
       SearchCanceled: Boolean = False;

function GetFileName(var FileName: String; Mask, Title, ALabel: String; Buttons: Word): Word;
 var S: PathStr;
     D: PFileDialog;
     B: Boolean;
     C: Word;
begin
 S := ''; B := False; if Mask = '' then begin Mask := x_x; B := False end;
 D := PFileDialog(Application^.ValidView(New(PFileDialog,
        Init(Mask, Title, ALabel, Buttons, 211))));
  if D = nil then Exit;
  if B then D^.SetData(S);
  C := Desktop^.ExecView(D);
  if C <> cmCancel then D^.GetFileName(S);
  GetFileName := C;
  Dispose(D, Done);
  FileName := S;
end;

function ContainCell(Cell, Formula: String): Boolean;
 const Signs = ['#','+','-','=','*','&','^','(',')','<','>', ';', ' ',
                '%','[',']','{','}','!','|','/','\',',','?'];
 var S1,S2: String;
     C1,C2: String[5];
     SheetName: String[8];
     X, X1, X2: Byte;
     Y, Y1, Y2: Integer;
     I, J: Integer;
begin
 ContainCell := False;
 repeat I := PosChar('@', Formula); if I > 0 then Delete(Formula, I, 1); until I = 0;
 I := 1; C1 := ''; C2 := ''; SheetName := ''{GetSheetName(Cell)};
 While (I <= Length(Cell)) and (Cell[I] <= 'Z') and (Cell[I] >= 'A') do
  begin C1 := C1 + Cell[I]; Inc(I) end;
 C2 := Copy(Cell, I, 5); Cell := SheetName + C1 + C2;
 if not GetCellCoord(Cell, X, Y) then Exit;
 I := 1;
 repeat
  While (I <= Length(Formula)) and (Formula[I] in Signs) do Inc(I);
  S1 := '';
  While (I <= Length(Formula)) and not (Formula[I] in Signs) do
   begin S1 := S1 + Formula[I]; Inc(I) end;
  if (S1[1] = Cell[1]) and (S1 = Cell) then begin ContainCell := True; Exit end;
  J := Pos(':', S1);
  if J > 0 then
   begin
    S2 := Copy(S1, J + 1, 5);
    S1[0] := Char(J-1);
    if not GetCellCoord(S1, X1, Y1) then Exit;
    if not GetCellCoord(S2, X2, Y2) then Exit;
    if X1 > X2 then
     asm mov AL, X1; mov AH, X2; mov X1, AH; mov X2, AL end;
    if Y1 > Y2 then
     asm mov AX, Y1; mov BX, Y2; mov Y1, BX; mov Y2, AX end;
    if (X1 <= X) and (X <= X2) and (Y1 <= Y) and (Y <= Y2) then
     begin ContainCell := True; Exit end;
   end;
 until I >= Length(Formula)
end;


{-------------------------       TInfoView       -------------------------}

constructor TInfoView.Load;
begin
  inherited Load(S);
end;

procedure TInfoView.Store;
begin
  inherited Store(S);
end;

procedure TInfoView.SetInfo;
begin
 InfoStr := Copy(S, 1, Size.X);
 InfoAttr := Attr;
 DrawView;
end;

procedure TInfoView.Draw;
 var B: TDrawBuffer;
begin
 MoveChar(B, ' ', InfoAttr, Size.X);
 MoveStr(B[Size.X - Length(InfoStr)], InfoStr, InfoAttr);
 WriteLine(0, 0, Size.X, 1, B);
end;

{-------------------------      TCalcWindow      -------------------------}

constructor TCalcWindow.Init;
 var R: TRect;
     P, P1: PView;
begin
 if AName = '' then Name := 'Untitled.WKZ' else Name := FExpand(AName);
 TWindow.Init(Bounds, Name, 0);
 Options := Options or ofTileable;
 if LowMemory then Exit;

 R.A.X := 1; R.A.Y := 5; R.B.X := 7; R.B.Y := Size.Y-1;
 P := New(PStaticText, Init(R, '')); P^.Options := P^.Options or ofFramed;
 P^.GrowMode := gfGrowHiY;
 Insert(P);

 R.A.X := 8; R.A.Y := 2; R.B.X := Size.X-1; R.B.Y := 4;
 P := New(PStaticText, Init(R, '')); P^.Options := P^.Options or ofFramed;
 P^.GrowMode := gfGrowHiX;
 Insert(P);

 GetExtent(R); R.Grow(-1,-1); R.B.Y := R.A.Y + 1;
 P := PView(LoadResource(dlgWkzMenuBar));
 P^.Locate(R);
 P^.GrowMode := gfGrowHiX;
 Insert(P);

 GetExtent(R); R.Grow(-1,-1); Inc(R.A.Y);
 R.B.Y := R.A.Y + 1; Inc(R.A.X, 7);
 P := New(PCalcInfo, Init(R, 240));
 P^.GrowMode := gfGrowHiX;
 P^.Options := P^.Options or ofSelectable;
 Insert(P);

 R.Assign(1, 2, 7, 4);
 P1 := New(PInfoView, Init(R));
 PInfoView(P1)^.InfoStr := '';
 PInfoView(P1)^.InfoAttr := GetColor(9);
 P1^.Options := P1^.Options {or ofFramed};
 Insert(P1);

 GetExtent(R); R.Grow(-1,-1);
 Inc(R.A.Y, 2);
 CalcView := New(PCalcView, Init(R, P, P1,
                  MakeScrollBar(sbHorizontal + sbHandleKeyboard),
                  MakeScrollBar(sbVertical + sbHandleKeyboard)));
 CalcView^.Options := CalcView^.Options;
 Insert(CalcView);
 CalcView^.LoadSheet(Title^);
end;

constructor TCalcWindow.Load;
begin
  inherited Load(S);
  S.Read(Name[0], 1);
  S.Read(Name[1], Length(Name));
  GetSubViewPtr(S, CalcView);
end;

procedure TCalcWindow.Store;
begin
  inherited Store(S);
  S.Write(Name[0], 1);
  S.Write(Name[1], Length(Name));
  PutSubViewPtr(S, CalcView);
end;

procedure TCalcWindow.HandleEvent;
begin
 case Event.What of
  evCommand: case Event.Command of
               cmClose, cmQuit: if not CalcView^.AskSave then ClearEvent(Event);
             end;
 end;
 inherited HandleEvent(Event);
end;

{-----------------------------    TCalcInfo     ---------------------------}

constructor TCalcInfo.Load;
begin
  inherited Load(S);
  GetPeerViewPtr(S, CalcView);
end;

procedure TCalcInfo.Store;
begin
  inherited Store(S);
  PutPeerViewPtr(S, CalcView);
end;

function TCalcInfo.GetPalette;
 const S: String[4] = #13#13#14#13;
begin
 GetPalette := @S;
end;

procedure TCalcInfo.HandleEvent;

 function EndEdit: Boolean;
  label 1,2;
  var S, S1: String;
      P: FPtr;
      Hp: Pointer;
      R: Real;
      I: Integer;
 begin
  GetData(S); EndEdit := True;
  with CalcView^ do
  begin
  Modified := On;
  CurrentCalc.X := Delta.X + Cur.X; CurrentCalc.Y := Delta.Y + Cur.Y;
  While S[Byte(S[0])] = ' ' do Dec(S[0]);
  S1 := S; While (S1[1] = ' ') and (S1 <> '') do Delete(S1, 1, 1);
  While Pos(' ', S1) > 0 do Delete(S1, Pos(' ', S1), 1);
  System.Mark(Hp);
  if (S1[1] = '=') and (S1[0] > #1) then
   begin
    P := GetFormula(System.Copy(S1, 2, 255));
    if ErrOcc then
     begin
      Release(Hp);
      S := ''; CalcView^.CalcError(erInvalidFormula);
      EndEdit := False;
      Goto 1;
     end;
    if not CellOccured then begin R := CalcFormula(P); Str(R:20:2, S);
                                  While S[1] = ' ' do Delete(S, 1, 1);
                                  Release(Hp);
                                  if Error then begin S := ''; EndEdit := False; Goto 1 end;
                                  with Cells^.ReplaceItem(Delta.X + Cur.X, Delta.Y + Cur.Y, S1)^ do
                                   begin
                                    Value := R;
                                    if (Options and 3) = 0 then
                                     begin
                                      Options := coValue or coDec;
                                      Decimals := 2;
                                     end else Options := (Options and $FFFC) or coValue;
                                    if ((Options shr 4) and 7) = 0 then
                                     begin Options := Options or coDec;
                                           Decimals := 2 end;
                                   end;
                                  ModifyCell(Delta.X + Cur.X, Delta.Y + Cur.Y);
                                  EndEdit := not ReError;
                                  Exit;
                            end
                       else begin
                             S := S1;
                             R := CalcFormula(P); Release(Hp);
                             if Error then begin S := ''; EndEdit := False; Goto 1 end;
                             S1 := UpCaseStr(DelSpaces(S));
                             with Cells^.ReplaceItem(Delta.X + Cur.X, Delta.Y + Cur.Y, S1)^ do
                              begin
                               Value := R;
                               if Options and 3 = 0 then
                                begin
                                 Options := coFormula or coDec;
                                 Decimals := 2;
                                 end else Options := (Options and $FFFC) or coFormula;
                                 if ((Options shr 4) and 7) = 0 then
                                  begin Options := Options or coDec;
                                        Decimals := 2 end;
                              end;
                             ModifyCell(Delta.X + Cur.X, Delta.Y + Cur.Y);
                             EndEdit := not ReError;
                             Exit;
                            end;

   end else if S <> '' then
             begin
              Val(S, R, I);
              if I = 0 then
               begin
                with Cells^.ReplaceItem(Delta.X + Cur.X, Delta.Y + Cur.Y, S)^ do
                 begin
                  Value := R;
                  if Options and 3 = 0 then
                   begin
                    Options := coValue or coLeft;
                    Decimals := 2;
                   end else Options := (Options and $FFFC) or coValue;
                 end;
                ModifyCell(Delta.X + Cur.X, Delta.Y + Cur.Y);
                EndEdit := not ReError;
                Exit;
               end;
             end;
1:
    if S = '' then Cells^.DelItem(Delta.X + Cur.X, Delta.Y + Cur.Y)
              else with Cells^.ReplaceItem(Delta.X + Cur.X, Delta.Y + Cur.Y, S)^ do
                    begin
                     Options := Options and $FFFC;
                     Decimals := 0;
                    end;
   end;
 end;

 procedure Transfer;
 begin
  CalcView^.FocusEvent := Event;
  if EndEdit then PWindow(Owner)^.SelectNext(False);
  ClearEvent(Event)
 end;

begin
 case Event.What of
  evKeyDown : case Event.KeyCode of
               kbUp, kbDown, kbPgUp, kbPgDn, kbCtrlPgUp,
               kbCtrlPgDn, kbEnter: Transfer;
               kbLeft: if CurPos = 0 then Transfer;
               kbRight: if CurPos > Length(PString(Data)^) - 1 then Transfer;
               kbTab: if not EndEdit then ClearEvent(Event);
              end;
 end;
 TInputLine.HandleEvent(Event);
end;

{-----------------------------    TCalcView     ---------------------------}

constructor TCalcView.Init;

 var I, J: Integer;
begin
 TView.Init(Bounds);
 HelpCtx := hcSpreadSheet;
 HScroll := AHScroll; VScroll := AVScroll;
 Options := Options or ofSelectable;
 GrowMode := gfGrowHiX + gfGrowHiY;
 EventMask := $FFFF; Info := AInfo; CellInfo := ACellInfo;
 PCalcInfo(Info)^.CalcView := @Self;
 FocusEvent.What := evNothing; FillChar(CellWidth, SizeOf(CellWidth), 11);
 Marking := False; BlockDraw := False; Modified := Off;
 Cells := nil;
 Delta.X := 0; Delta.Y := 0;
 Cur := Delta; Mark  := Cur;
 HScroll^.SetParams(0, 0, 255, 1, 1);
 VScroll^.SetParams(0, 0, MaxCellY - 1, Size.Y - 3, 1);
end;

constructor TCalcView.Load;
begin
  inherited Load(S);
  GetPeerViewPtr(S, Info);
  GetPeerViewPtr(S, CellInfo);
  GetPeerViewPtr(S, HScroll);
  GetPeerViewPtr(S, VScroll);
  S.Read(Delta, SizeOf(Delta)*3);
  S.Read(NumC, 6); {###}
  S.Read(CellWidth, SizeOf(CellWidth));
  S.Read(CurrentCalc, SizeOf(CurrentCalc)*3);
  Cells := PCellCollection(S.Get);
  FocusEvent.What := evNothing;
end;

procedure TCalcView.Store;
begin
  inherited Store(S);
  PutPeerViewPtr(S, Info);
  PutPeerViewPtr(S, CellInfo);
  PutPeerViewPtr(S, HScroll);
  PutPeerViewPtr(S, VScroll);
  S.Write(Delta, SizeOf(Delta)*3);
  S.Write(NumC, 6); {###}
  S.Write(CellWidth, SizeOf(CellWidth));
  S.Write(CurrentCalc, SizeOf(CurrentCalc)*3);
  S.Put(Cells);
end;


function TCalcView.Valid;
begin
 Valid := Cells <> nil;
end;

procedure TCalcView.SetState;
begin
 TView.SetState(AState, Enable);
 if Enable and (AState and sfFocused <> 0) then DrawView;
 if (AState and sfActive <> 0) then
 if Enable then
  begin
   HScroll^.GrowTo(HScroll^.Size.X, 1);
   VScroll^.GrowTo(1, VScroll^.Size.Y);
   EnableCommands([cmUndo, cmCut, cmCopy, cmPaste, cmClear]);
  end else
  begin
   HScroll^.GrowTo(HScroll^.Size.X, 0);
   VScroll^.GrowTo(0, VScroll^.Size.Y);
  end;
end;

function TCalcView.GetPalette;
 const S: String[4] = #8#13#14;
begin
 GetPalette := @S;
end;

type
     TQArray = Array[0..80, 0..60] of Integer;
     PQArray = ^TQArray;

const Q: PQArray = nil;

procedure TCalcView.Draw;
 const Dig : String [26] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

 var
     B, B1: Array[0..511] of Word;
     BC: Array [0..127] of record C: Char; A: Byte; end Absolute B;
     I, J, K, L: Integer;
     C1, C2, C3: Byte;
     S, S1: String;
     P: PCellRec;
     X1, X2, Y1, Y2: Integer;
     CurPos: TPoint;
     StX, EnX, A1, A2 : Byte;

 label 1;

begin
 if BlockDraw then Exit;
 C1 := GetColor(1); C2 := GetColor(2); C3 := GetColor(3);
 if Q = nil then New(Q);
1:
 CurPos.X := Delta.X + Cur.X; CurPos.Y := Delta.Y + Cur.Y;
 if CurPos.X > 255 then Cur.X := 255 - Delta.X;
 if CurPos.Y >= MaxCellY then Cur.Y := MaxCellY - 1 - Delta.Y;
 if Cur.Y < 0 then begin J := Cur.Y; Cur.Y := 0; VScroll^.SetValue(Delta.Y + J); Exit end;
 if Cur.X < 0 then begin J := Cur.X; Cur.X := 0; HScroll^.SetValue(Delta.X + J); Exit end;
 CurPos.X := Delta.X + Cur.X; CurPos.Y := Delta.Y + Cur.Y;
 X1 := CurPos.X; X2 := Mark.X;
 Y1 := CurPos.Y; Y2 := Mark.Y;
 if X1 > X2 then
     asm mov AX, X1; mov BX, X2; mov X1, BX; mov X2, AX end;
 if Y1 > Y2 then
     asm mov AX, Y1; mov BX, Y2; mov Y1, BX; mov Y2, AX end;
 if Y2 > 4095 then Y2 := 4095;
 MoveChar(B, ' ', C1, Size.X);
 BC[6].C := '³';
 MoveChar(B1, 'Ä', C1, Size.X);
 WordRec(B1[6]).Lo := Byte('Å');
 NumC := 0; I := 7; J := Delta.X; StX := I; EnX := Size.X;
 While (I < Size.X) and (J <= HScroll^.Max) do
  begin
   K := CellWidth[J]; L := CellWidth[J + 1];
   FillChar(S, K + 1, 32);
   S[K] := '³';
   if J < 26 then S[1 + K div 2] := Dig[J + 1]
      else begin S[K div 2] := Dig[J div 26];
                 S[K div 2 + 1] := Dig[J mod 26 + 1] end;
   S[0] := Char(K);
   WordRec(B1[I + K - 1]).Lo := Byte('Á');
   MoveStr(B[I], S, C1);
   if J < X1 then Inc(StX, K);
   if (J > X2) and (EnX > I) then EnX := I;
   if (J = HScroll^.Max) and (J <= X2) then EnX := I + K;
   Inc(J);
   if I + K <= Size.X then Inc(NumC);
   Inc(I, K);
  end;
 if NumC = 0 then NumC := 1;
 if Cur.X >= NumC then
  begin
   J := Cur.X - NumC + 1;
   Cur.X := NumC - 1;
   HScroll^.SetValue(Delta.X + J);
   Delta.X := HScroll^.Value;
   Exit;
  end;
 PInfoView(CellInfo)^.SetInfo(GetCellName(CurPos.X, CurPos.Y), Owner^.GetColor(9));
 FillChar(Q^, SizeOf(Q^), 255);
 for I := 1 to Cells^.Count do
  begin
   P := Cells^.At(I - 1);
   if (P^.Row >= Delta.Y) and (P^.Row < Delta.Y + Size.Y - 2) and
      (P^.Col >= Delta.X) and (P^.Col < Delta.X + NumC + 3) then
       Q^[P^.Col - Delta.X, P^.Row - Delta.Y] := I - 1;
  end;
 WriteBuf(6, 0, Size.X, 1, B[6]);
 WriteBuf(0, 1, Size.X, 1, B1);
 for I := 0 to Size.Y - 2 do
  begin
   MoveChar(B, ' ', C2, Size.X);
   if Delta.Y + I <= VScroll^.Max then
    begin
     Str((Delta.Y + I + 1):5, S);
     MoveStr(B, S, C1); L := 7;
     for J := 0 to NumC + 2 do
      begin
       K := CellWidth[Delta.X + J];
       if Q^[J, I] >= 0 then
        begin
         P := Cells^.At(Q^[J, I]);
         if Size.X > L then
          begin
           FillChar(S, Size.X - L + 1, 32);
           S[0] := Char(Size.X - L);
          end;
         case (P^.Options shr 4) and 7 of
          0: S1 := P^.S;
          1: Str(P^.Value:0:P^.Decimals, S1);
          2: begin
              Str(P^.Value:0:20, S1);
              While S1[Length(S1)] = '0' do Dec(S1[0]);
              if S1[Length(S1)] = '.' then Dec(S1[0]);
              S1 := MakeComma(S1);
             end;
          3: begin
              Str(P^.Value, S1);
              A1 := Pos('E', S1);
              if A1 > 0 then
              begin
               A2 := A1 - 1;
               While (S1[A2] = '0') and
                     (S1[A2 - 1] <> '.') do Dec(A2);
               Move(S1[A1], S1[A2 + 1], Length(S1) - A1 + 1);
               Dec(S1[0], A1 - A2 - 1);
              end;
             end;
           4:if P^.Value = 0 then S1 := FalseStr
                             else S1 := TrueStr;
           5:begin
              MakeCurrency(P^.Value, S1);
              {Str(P^.Value:0:2, S1);
              S1 := '$'+MakeComma(S1);}
             end;
           6:begin
              Str((P^.Value*100):0:2, S1);
              S1 := MakeComma(S1)+'%';
             end;
           7:S1 := '';
         end;
         if (P^.Options and $C = 0) or (Length(S1) > K) then Move(S1[1], S[1], Length(S1))
          else if (P^.Options and $C = coLeft) then Move(S1[1],S[1 + K - Length(S1)], Length(S1))
               else Move(S1[1],S[1 + (K - Length(S1)) div 2], Length(S1));
         if L < 0 then L := 0;
         MoveStr(B[L], S, C2);
        end;
       if (Cur.X = J) and (Cur.Y = I) then
        begin
         MoveColor(B[L], K, C3);
         if Q^[J, I] >= 0 then
          begin
           P := Cells^.At(Q^[J, I]);
           S := P^.S;
           case P^.Options and 3 of
            coText: WriteStr(0, 0, '   T  ', 2);
            coValue: WriteStr(0, 0, '   V  ', 2);
            coFormula: WriteStr(0, 0, '   F  ', 2);
           end;
          end else
           begin
            WriteStr(0, 0, GetString(dlWKZ_Empty), 2);
            S := '';
           end;
         PCalcInfo(Info)^.SetData(S);
         Info^.Draw;
        end;
       L := L + K;
      end;
    end;
   BC[6].C := '³'; BC[6].A := C1;
   if (Delta.Y + I >= Y1) and (Delta.Y + I <= Y2) and (StX < EnX)
      then MoveColor(B[StX], EnX - StX, C3);
   WriteBuf(0, I + 2, Size.X, 1, B);
  end;
end;

procedure TCalcView.HandleEvent;
 var Inf: PCalcInfo;
     S: String;
     St: PStream;
     MaxX, MaxY, K, L: Integer;
     P: PCellRec;
     FName: PathStr;
     kbState: Byte absolute $0:$417;
     X1, X2, Y1, Y2: Integer;

 procedure ExportToFile;
  var S, S1: String;
      C: Array[0..255] of Integer;
      P: PCellRec;
      MaxLv, Maxr, I, J, K, L, A1, A2: Integer;
      F: Text;
 begin
   if GetFileName(S, x_x, GetString(dlExportTitle), GetString(dlExportLabel),
                     fdOKButton+fdHelpButton) = cmCancel then Exit;
   Assign(F, S); SetFAttr(F, Archive);
   Rewrite(F);
   MaxLv := 0;
   for I := 1 to Cells^.Count do
    begin
     P := Cells^.At(I-1);
     if MaxLv < P^.Row then MaxLv := P^.Row;
    end;
   for J := 0 to MaxLv do
    begin
     FillChar(C, Sizeof(C), 255); MaxR := 0;
     for I := 1 to Cells^.Count  do
      begin P := Cells^.At(I-1); if J = P^.Row then C[P^.Col] := I-1;
            if MaxR < P^.Col then MaxR := P^.Col; end;
     for I := 0 to MaxR do
      if C[I] >= 0 then
       begin
         P := Cells^.At(C[I]);
         case (P^.Options shr 4) and 7 of
          0: S1 := P^.S;
          1: Str(P^.Value:0:P^.Decimals, S1);
          2: begin
              Str(P^.Value:0:20, S1);
              While S1[Length(S1)] = '0' do Dec(S1[0]);
              if S1[Length(S1)] = '.' then Dec(S1[0]);
              S1 := MakeComma(S1);
             end;
          3: begin
              Str(P^.Value, S1);
              A1 := Pos('E', S1);
              if A1 > 0 then
              begin
               A2 := A1 - 1;
               While (S1[A2] = '0') and
                     (S1[A2 - 1] <> '.') do Dec(A2);
               Move(S1[A1], S1[A2 + 1], Length(S1) - A1 + 1);
               Dec(S1[0], A1 - A2 - 1);
              end;
             end;
           4:if P^.Value = 0 then S1 := FalseStr
                             else S1 := TrueStr;
           5:begin
              MakeCurrency(P^.Value, S1);
{              Str(P^.Value:0:2, S1);
              S1 := '$'+MakeComma(S1);}
             end;
           6:begin
              Str((P^.Value*100):0:2, S1);
              S1 := MakeComma(S1)+'%';
             end;
           7:S1 := '';
         end;
         FillChar(S[1], 255, ' ');
         if (P^.Options and $C = 0) or (Length(S1) >= CellWidth[I]) then Move(S1[1], S[1], Length(S1))
          else if (P^.Options and $C = coLeft) then Move(S1[1],S[1 + CellWidth[I] - Length(S1)], Length(S1))
               else Move(S1[1],S[1 + (CellWidth[I] - Length(S1)) div 2], Length(S1));
         K := CellWidth[I]; S[0] := #255;
         while (I < MaxR) and (C[I+1] < 0) do
          begin Inc(I); Inc(K, CellWidth[I]); end;
         if K < Length(S1) then Write(F, System.Copy(S, 1, K))
         else begin
                 if K > 255 then L := 255 else L := K;
                 Write(F, System.Copy(S,1,L));
                 repeat
                  Dec(K, L); if K > 255 then L := 255 else L := K;
                  if L <= 0 then Break;
                  Write(F, Strg(' ', L));
                 until K <= 0;
              end;
       end else
        begin
          K := CellWidth[I];
          while (I < MaxR) and (C[I+1] < 0) do
           begin Inc(I); Inc(K, CellWidth[I]); end;
          if K > 255 then L := 255 else L := K;
          Write(F, Strg(' ', L));
          repeat
           Dec(K, L); if K > 255 then L := 255 else L := K;
           if L <= 0 then Break;
           Write(F, Strg(' ', L));
          until K <= 0;
        end;
      WriteLn(F);
    end;
   Close(F);
 end;

 procedure SetMark;
 begin
  if Marking then Exit;
  Mark.X := Delta.X + Cur.X;
  Mark.Y := Delta.Y + Cur.Y;
 end;

 procedure CheckMark;
 begin
  Marking := kbState and $3 <> 0
 end;

 procedure EndMarking;
 begin Marking := False; SetMark; DrawView; ClearEvent(Event) end;

 procedure ChangeFormat;
  var R: record Display, Justify: Word; Dec: String[2]; Protect: Word; end;
      I, J, X1, Y1, X2, Y2: Integer;
 begin
  ClearEvent(Event);
  P := Cells^.Get(Delta.X + Cur.X, Delta.Y + Cur.Y);
  if P = nil then begin FillChar(R, sizeof(R), 0); R.Dec := '2' end
  else
   begin
    R.Display := (P^.Options shr 4) and 7;
    R.Justify := (P^.Options shr 2) and 3;
    Str(P^.Decimals, R.Dec);
    R.Protect := (P^.Options shr 7) and 1;
   end;
  if ExecResource(dlgSetCellFormat, R) = cmOK then
  begin
   X1 := Delta.X + Cur.X; X2 := Mark.X;
   Y1 := Delta.Y + Cur.Y; Y2 := Mark.Y;
   if X1 > X2 then
     asm mov AX, X1; mov BX, X2; mov X1, BX; mov X2, AX end;
   if Y1 > Y2 then
     asm mov AX, Y1; mov BX, Y2; mov Y1, BX; mov Y2, AX end;
   Val(R.Dec, J, I);
   for I := 1 to Cells^.Count do
    begin
     P := Cells^.At(I-1);
     if (P^.Col >= X1) and (P^.Col <= X2) and (P^.Row >= Y1) and (P^.Row <= Y2)
      then begin P^.Options := (P^.Options and 3)
                        or ((R.Justify and 3) shl 2)
                        or ((R.Display and 7) shl 4)
                        or ((R.Protect and 1) shl 7);
                 P^.Decimals := J;
           end;
    end;
  end;
  DrawView
 end;

 procedure CE; begin ClearEvent(Event) end;

begin
 Inf := PCalcInfo(Info);
 if GetState(sfFocused) and (FocusEvent.What <> evNothing) then
   begin
    PutEvent(Event); Event := FocusEvent; FocusEvent.What := evNothing;
   end;
 TView.HandleEvent(Event);
 case Event.What of
  evCommand: case Event.Command of
              cmGetName: PString(Event.InfoPtr)^ := 'Speadsheet - '+PWindow(Owner)^.Title^;
              cmImportToFile: begin ExportToFile; ClearEvent(Event) end;
              cmSaveSheetAs: begin
                       SaveSheetAs; CE;
                       Owner^.ReDraw;
                      end;
              cmSave: begin
                       SaveSheet; CE;
                       Owner^.ReDraw;
                      end;
              cmOpen: begin
                        CE;
                        K := GetFileName(FName, '*.WKZ', GetString(dlOpenFile),
                             GetString(dlOpenFileName), fdOpenButton{ + fdReplaceButton{, hsLoadSheet, 0});
                        if K = cmCancel then Exit;
                        LoadSheet(FName);
                      end;
              cmChangeWidth:
                      begin
                       repeat
                        GetKeyEvent(Event);
                        if Event.CharCode = #$e0 then Event.CharCode := #0;
                        case Event.KeyCode of
                         kbLeft: if CellWidth[Delta.X + Cur.X]> 1 then
                                   begin Dec(CellWidth[Delta.X + Cur.X]);
                                         DrawView end;
                        kbRight: if CellWidth[Delta.X + Cur.X]< ScreenWidth then
                                   begin Inc(CellWidth[Delta.X + Cur.X]);
                                         DrawView end;
                        end;
                       until (Event.KeyCode = kbESC) or (Event.KeyCode = kbEnter);
                       CE;
                      end;
              cmChangeFormat: begin ChangeFormat; CE; end;
              cmPaste: begin Paste; EndMarking end;
              cmCopy: begin Copy; EndMarking end;
              cmCut: begin Copy; Clear; EndMarking end;
              cmClear: begin Clear; EndMarking end;
              cmInsertLine, cmInsertColumn:
                begin InsertLineCol(Event.Command); EndMarking end;
              cmDeleteLine, cmDeleteColumn:
                begin DeleteLineCol(Event.Command); EndMarking end;
              cmRecalc: begin Recalc; DrawView; CE end;
              cmGotoCell: begin
                           if HistoryCount(hsGotoCell) = 0 then S := 'A1'
                                 else S := HistoryStr(hsGotoCell, 0);
                           if ExecResource(dlgGotoCellNumber, S) = cmOK
                             then GotoCell(S);
                           ClearEvent(Event); Exit
                          end;
              cmFindCell: begin
                           if ExecResource(dlgFindCell, SearchData) = cmOK then
                            begin
                             SearchPos.X := -1; SearchPos.Y := 0;
                             WasReplace := False;
                             SearchCell;
                            end;
                           CE;
                          end;
              cmSearchAgain: begin
                              SearchCanceled := False;
                              SearchPos.X := Delta.X + Cur.X;
                              SearchPos.Y := Delta.Y + Cur.Y;
                              repeat SearchCell
                              until not WasReplace or not ContSearch or SearchCanceled;
                              CE;
                             end;
              cmReplaceCell: begin
                              L := ExecResource(dlgReplaceCell, ReplaceData);
                              if (L = cmYes) or (L = cmOK) then
                               begin
                                SearchData.S := ReplaceData.S;
                                SearchData.TxtOptions := ReplaceData.TxtOptions;
                                SearchData.CellOptions := ReplaceData.CellOptions;
                                SearchCanceled := False; ContSearch := L = cmYes;
                                SearchPos.X := -1; SearchPos.Y := 0;
                                WasReplace := True;
                                repeat SearchCell
                                 until not WasReplace or not ContSearch or SearchCanceled;
                               end;
                              CE;
                             end;
             end;
  evKeyDown: case Event.KeyCode of
              kbDoubleAlt: CE;
              kbDel: begin Clear; EndMarking end;
              kbLeft: if Cur.X > 0 then
                      begin
                       CheckMark;
                       Dec(Cur.X); SetMark;
                       DrawView;
                       CE; Exit
                      end else Exit;
              kbRight: if (Cur.X < NumC)  then
                      begin
                       CheckMark;
                       if (Delta.X + Cur.X = HScroll^.Max) then
                        begin if Cur.X > 0 then Dec(Cur.X); SetMark; Exit end;
                       Inc(Cur.X); SetMark; DrawView;
                       ClearEvent(Event); Exit
                      end else
                       if (Delta.X + Cur.X = HScroll^.Max) then
                        begin CheckMark; if Cur.X > 0 then Dec(Cur.X); SetMark; Exit end
                         else Exit;
                kbUp: if Cur.Y > 0 then
                      begin
                       CheckMark;
                       Dec(Cur.Y); SetMark; DrawView;
                       ClearEvent(Event); Exit
                      end else Exit;
              kbHome: begin
                       CheckMark;
                       Cur.Y := 0; Cur.X := 0; SetMark;
                       HScroll^.SetValue(0);
                       VScroll^.SetValue(0);
                       DrawView; ClearEvent(Event); Exit
                      end;
              kbEnd: begin
                      CheckMark;
                      MaxX := 0; MaxY := 0; Cur.Y := 0; Cur.X := 0;
                      for L := 1 to Cells^.Count do
                       begin
                        P := Cells^.At(L - 1);
                        if P^.Col > MaxX then MaxX := P^.Col;
                        if P^.Row > MaxY then MaxY := P^.Row;
                       end;
                      if (L + CellWidth[Delta.X + Cur.X] < Size.X) and (MaxX > 0) then
                      begin
                       L := 7;
                       while (L <= Size.X) and (MaxX >= 0) do
                        begin
                         K := CellWidth[Delta.X + Cur.X];
                         if MaxX >= 0 then begin Inc(Cur.X); Dec(MaxX) end;
                         Inc(L, K);
                        end;
                       Dec(Cur.X); Inc(MaxX);
                      end;
                      VScroll^.SetValue(MaxY - Size.Y + 3); Delta.Y := VScroll^.Value;
                      Cur.Y := MaxY - Delta.Y;
                      HScroll^.SetValue(MaxX); Delta.X := HScroll^.Value;
                      SetMark;
                      DrawView; ClearEvent(Event); Exit
                     end;
              kbDown: if (Cur.Y < Size.Y - 3)  then
                      begin
                       CheckMark;
                       if (Delta.Y + Cur.Y >= VScroll^.Max) then
                        begin if Cur.Y > 0 then Dec(Cur.Y); SetMark; Exit end;
                       Inc(Cur.Y); SetMark; DrawView;
                       ClearEvent(Event); Exit
                      end else
                       if (Delta.Y + Cur.Y >= VScroll^.Max) then
                        begin if Cur.Y > 0 then Dec(Cur.Y); SetMark; Exit end
                          else Exit;
               kbEnter: begin
                         Marking := False; SetMark; DrawView;
                         PWindow(Owner)^.SelectNext(False);
                         ClearEvent(Event);
                        end;
               kbTab: begin
                       Marking := False; SetMark; DrawView;
                      end;
               else if Event.CharCode > #31 then
                    begin
                     Marking := False; SetMark; DrawView;
                     PWindow(Owner)^.SelectNext(True);
                     Event.InfoPtr := Info;
                     Info^.PutEvent(Event);
                     ClearEvent(Event)
                    end;
             end;
  evBroadcast: case Event.Command of
                cmScrollBarChanged: if Event.InfoPtr = HScroll then
                                         begin CheckMark; Delta.X := HScroll^.Value; SetMark;
                                               DrawView; Exit end
                               else if Event.InfoPtr = VScroll then
                                         begin CheckMark; Delta.Y := VScroll^.Value; SetMark;
                                               DrawView; Exit end
               end;
 end;
 Marking := False;
end;


function TCalcView.GetCellValue;
 var X: Byte;
     Y, I: Integer;
     P: PCellRec;

 function IsNeeded(PP: PCellRec): Boolean; far;
 begin
  IsNeeded := (PP^.Row = Y) and (PP^.Col = X)
 end;

begin
 if S = 'PI' then begin GetCellValue := PI; Exit end;
 if not GetCellCoord(S, X, Y) then begin CalcError(erInvalidCell); Exit end;
 P := Cells^.FirstThat(@IsNeeded);
 if (P <> nil) and (P^.Options and 3 <> 0) then GetCellValue := P^.Value
                                           else GetCellValue := 0;
end;

Function TCalcView.GetFuncValue;
 label 1;
 var I: Integer;
     R, R1: Real;
     S: String;
     T: FPtr;
     PP: Pointer;

 function GetMul: Real;
   var X1, X2: Byte;
       Y1, Y2: Integer;
       R: Real;
       I,J: Integer;
       CR: PCellRec;
 begin
   GetMul := 0;
   if GetCellCoord(T^.Left^.Name, X1, Y1) and
      GetCellCoord(T^.Right^.Name, X2, Y2) then
     begin
       if X1 > X2 then
        asm mov AL, X1; mov AH, X2; mov X1, AH; mov X2, AL end;
       if Y1 > Y2 then
        asm mov AX, Y1; mov BX, Y2; mov Y1, BX; mov Y2, AX end;
       R := 1;
       for J := 1 to Cells^.Count do
        begin
         CR := Cells^.At(J - 1);
         if (CR^.Options and 3 <> 0) and (CR^.Col >= X1) and (CR^.Col <= X2)
            and (CR^.Row >= Y1) and (CR^.Row <= Y2) then
           if (CR^.Value = 0) or (Abs(1e38 / CR^.Value) > Abs(R)) then R := R * CR^.Value;
        end;
     end else CalcError(erInvalidCell);
   GetMul := R;
 end;


begin
 S := UpCaseStr(P^.Name); GetFuncValue := 0;
 if S = 'SUM' then
  begin
   R := 0;
   for I := 1 to P^.ParamsNum do
     begin R := R + CalcFormulaTree(P^.Params^[I]); if Error then Exit end;
   GetFuncValue := R; Exit
  end;
 if S = 'MUL' then
  begin
   R := 1;
   for I := 1 to P^.ParamsNum do
     begin
       T := P^.Params^[I];
       if T^.Name = ':' then R1 := GetMul
                        else R1 := CalcFormulaTree(P^.Params^[I]);
       if (R1 = 0) or (Abs(1e38 / R1) > Abs(R)) then R := R * R1;
       if Error then Exit
     end;
   GetFuncValue := R;
   Exit
  end;
 if S = 'IF' then
  begin
   if (P^.ParamsNum < 2) or (P^.ParamsNum > 3) then
    begin CalcError(erInvalidIF); Exit; end;
   R := 0; R1 := CalcFormulaTree(P^.Params^[1]); if Error then Exit;
   if (P^.ParamsNum = 2) then begin if R1 <> 0 then R := CalcFormulaTree(P^.Params^[2]) end
    else if R1 <> 0 then R := CalcFormulaTree(P^.Params^[2])
                    else R := CalcFormulaTree(P^.Params^[3]);
   GetFuncValue := R; Exit
  end;
 if P^.ParamsNum = 1 then
  begin
   R := CalcFormulaTree(P^.Params^[1]);
   if not Error then
   begin
     If S='RAD' then begin GetFuncValue:=(R*180)/PI; Exit end;
     If S='GRAD' then begin GetFuncValue:=(R*PI)/180; Exit end;
     If S='COS' then begin GetFuncValue:=Cos(R); Exit end;
     If S='SIN' then begin GetFuncValue:=Sin(R); Exit end;
     If S='SQR' then begin GetFuncValue:=R * R; Exit end;
     If (S='SQRT') then
      begin if (R >= 0) then GetFuncValue:=Sqrt(R) else GetFuncValue := 0; Exit end;
     If (S='LN') then
      begin if (R > 0) then GetFuncValue:=Ln(R) else GetFuncValue := 0; Exit end;
     If (S='LG') then
      begin if (R > 0) then GetFuncValue:=Ln(R)/Ln(10) else GetFuncValue := 0; Exit end;
     If ((S='TAN') or (S='TG')) then
      begin if (cos(R) <> 0) then GetFuncValue:=Sin(R)/Cos(R) else GetFuncValue := 0; Exit end;
     If S='ARCTAN' then begin GetFuncValue:=ArcTan(R); Exit end;
     If (S='EXP') then
      begin if (R < 88.0) then GetFuncValue:=Exp(R) else GetFuncValue := 0; Exit end;
     If (S='CTAN') or (S='CTG') or (S='COTAN') then
      begin if (Sin(R) <> 0) then GetFuncValue:=Cos(R)/Sin(R) else GetFuncValue := 0 end;
     If S='SIGN' then
      begin if R = 0 then GetFuncValue:=0 else
            if R < 0 then GetFuncValue := -1
                     else GetFuncValue := 1; Exit end;
   end;
  end;
 CalcError(erInvalidFunction);
end;

Function TCalcView.CalcFormulaTree;
 var   R,R1 : Real;
       J, Y1, Y2: Integer;
       X1, X2: Byte;
       CR: PCellRec;
       BB: Boolean;

 procedure FormulaError;
 begin
  CalcError(erInvalidFormula)
 end;

begin
 CalcFormulaTree:=0; if Error then Exit;
 if p=Nil then Exit;
 if (p^.Tp=opFunc)
    then begin
          R:=GetFuncValue(P);
          CalcFormulaTree := R;
          Exit;
         end;
 if (p^.Tp=opValue) then
  begin
   Val(p^.Name,R,J);
   if J>0 then CalcError(erInvalidValue);
   CalcFormulaTree:=R; Exit;
  end;
  if (p^.Tp=opCell) then
   begin
    R := GetCellValue(p^.Name);
    CalcFormulaTree := R; Exit;
   end;
  if (p^.Tp=opSign) then
   begin
    if (p^.Name[0] > #2) or (p^.Name = #0) or (p^.Right = nil) {or
       (not (p^.Name[1] in UnarySigns) and (p^.Left =nil))}  then
     begin FormulaError; Exit end;
    R:=CalcFormulaTree(p^.Left);
    R1:=CalcFormulaTree(p^.Right);
    if Error then Exit;
    if p^.Name[0] = #1 then
    begin
     Case p^.Name[1] of
      '+' : R:=R+R1;
      '-' : R:=R-R1;
      '*' : if (Abs(R) > 1) then
                if (1e38/Abs(R) < Abs(R1)) then R := 0 else R:=R*R1
              else
                if (Abs(R1) > 1) and (1e38/Abs(R1) < Abs(R)) then R := 0 else R:=R*R1;
      '/' : if R1<>0 then R:=R/R1 else R:=0;
      '^' : if (R<>0) then
              begin
                BB := (Frac(R)=0) and (Frac(R1)=0);
                if R1 = 0 then R := 1 else
                if (Ln(Abs(R))<(70/R1)) then if R > 0 then R:=Exp(ln(R)*R1)
                                                      else R:=Exp(-ln(R)*R1)
                                        else R := 0;
                if BB then
                  if Abs(Frac(R)) < 0.5 then
                    begin
                       R := Int(R);
                    end else
                    begin
                      if R < 0 then R := Int(R)-1
                               else R := Int(R)+1;
                    end;
              end else R := 0;
      '>' : R := Byte(R>R1);
      '<' : R := Byte(R<R1);
      '=' : R := Byte(R=R1);
      ':' : if (P^.Left <> nil) and (P^.Right <> nil) and
               GetCellCoord(P^.Left^.Name, X1, Y1) and
               GetCellCoord(P^.Right^.Name, X2, Y2) then
              begin
               if X1 > X2 then
                asm mov AL, X1; mov AH, X2; mov X1, AH; mov X2, AL end;
               if Y1 > Y2 then
                asm mov AX, Y1; mov BX, Y2; mov Y1, BX; mov Y2, AX end;
               R := 0;
               for J := 1 to Cells^.Count do
                begin
                 CR := Cells^.At(J - 1);
                 if (CR^.Options and 3 <> 0) and (CR^.Col >= X1) and (CR^.Col <= X2)
                    and (CR^.Row >= Y1) and (CR^.Row <= Y2) then R := R + CR^.Value;
                end;
               CalcFormulaTree:=R;
              end else CalcError(erInvalidCell);
       else FormulaError;
     end;
    end else
     Case p^.Name[1] of
      '=': case p^.Name[2] of
            '=': R := Byte(R=R1);
            '>': R := Byte(R>=R1);
            '<': R := Byte(R<=R1);
             else FormulaError;
           end;
      '&': if p^.Name[2] = '&' then R := Byte((R<>0) and (R1<>0)) else FormulaError;
      '|': if p^.Name[2] = '|' then R := Byte((R<>0) or (R1<>0)) else FormulaError;
      '^': if p^.Name[2] = '^' then R := Byte((R<>0) xor (R1<>0)) else FormulaError;
      '>': if p^.Name[2] = '<' then R := Byte(R<>R1) else
            if p^.Name[2] = '=' then R := Byte(R>=R1) else FormulaError;
      '<': if p^.Name[2] = '>' then R := Byte(R<>R1) else
            if p^.Name[2] = '=' then R := Byte(R<=R1) else FormulaError;
       else FormulaError;
     end;
    CalcFormulaTree:=R;
   end;

end;

function TCalcView.CalcFormula;
begin
 Error := False;
 CalcFormula := CalcFormulaTree(P);
end;

procedure TCalcView.CalcError;
begin
 MessageBox(GetString( Index ) + ' ' + GetCellName(CurrentCalc.X,CurrentCalc.Y), @Self, mfOKButton + mfError);
 Error := True;
end;

procedure TCalcView.ModifyCell(X, Y: Integer);

const MaxRec = 300;

var Hp, Tree: Pointer;
    Err: Boolean;
    P: PCellRec;
    Recurse: Array [1..MaxRec] of record X: Byte; Y: Integer;end;
    NumRec: Integer;

 procedure Modify(AX, AY: Integer);
  var I: Integer;
      S: String[6];
 begin
  if Err or Error then Exit;
  for I := 1 to NumRec do
   if (Recurse[I].X = AX) and (Recurse[I].Y = AY) then
   begin CalcError(erRecurseTooDeep); Err := True; Exit end;
  Inc(NumRec);
  if NumRec > MaxRec then
   begin CalcError(erDeepDependence); Err := True; Exit end;
  Recurse[NumRec].X := AX;
  Recurse[NumRec].Y := AY;
  S := GetCellName(AX, AY);
  for I := 1 to Cells^.Count do
   begin
    if Error or Err then Exit;
    P := Cells^.At(I-1);
    if P^.Options and coFormula <> 0 then
     if ContainCell(S, P^.S) then
      begin
       System.Mark(Hp);
       CurrentCalc.X := P^.Col; CurrentCalc.Y := P^.Row;
       Tree := GetFormula(System.Copy(P^.S, 2, 255));
       P^.Value := CalcFormula(Tree);
       Release(Hp);
       Modify(P^.Col, P^.Row);
      end;
   end;
  Dec(NumRec);
 end;

begin
 {PInfoView(CellInfo)^.SetInfo(' WORK ', Owner^.GetColor(12));}
 Modified := On;
 Err := False; ReError := False; NumRec := 0;
 Modify(X, Y); ReError := Err;
 {DrawView;}
end;

destructor TCalcView.Done;
begin
 Dispose(Cells, Done);
 if Q <> nil then Dispose(Q);
 Q := nil;
 TView.Done;
end;

function TCalcView.AskSave;
 var A: Word;
begin
 AskSave := On; if not Modified then Exit;
 A := MessageBox(GetString(dlWorkSheet)+PWindow(Owner)^.Title^+GetString(dlNotSaved),
                 nil, mfWarning+mfYesNoCancel);
 if A <> cmCancel then Modified := Off;
 if A = cmYes then SaveSheet else AskSave := A <> cmCancel;
end;

procedure TCalcView.LoadSheet;
 var S: PStream;
begin
 if Modified and not AskSave then Exit;
 if Cells <> nil then Dispose(Cells, Done);
 if (FName = '') or (FName = 'Untitled.WKZ') then begin
   DisposeStr(PWindow(Owner)^.Title);
   PWindow(Owner)^.Title := NewStr('Untitled.WKZ'); Owner^.Redraw;
   New(Cells, Init(10,10)); Exit
  end;
 FName := FExpand(FName);
 S := New(PBufStream, Init(FName, stOpenRead, 2048));
 DisposeStr(PWindow(Owner)^.Title);
 PWindow(Owner)^.Title := NewStr(FName);
 if S^.Status <> stOK then
  begin
   Dispose(S, Done);
   Owner^.Redraw;
   New(Cells, Init(10,10)); Exit
  end;
 S^.Read(CellWidth, Sizeof(CellWidth));
 Cells := PCellCollection(S^.Get);
 Dispose(S, Done);
 if Cells = nil then
  begin
   ErrMsg(erInvalidFileFormat);
   if Owner <> nil then
    begin
     DisposeStr(PWindow(Owner)^.Title);
     PWindow(Owner)^.Title := NewStr('Untitled.WKZ');
    end;
   New(Cells, Init(10,10));
   FillChar(CellWidth, Sizeof(CellWidth), 11);
  end;
 Modified := Off;
 Owner^.ReDraw;
end;

procedure TCalcView.SaveSheetAs;
 var S: PStream;
     FName: PathStr;
     W: Word;
     PP: Pointer;
begin
 PP := @FName;
 if GetFileName(FName, '*.WKZ', GetString(dlSaveFileAs),
     GetString(dlSaveFileAs), fdOKButton{, hsSaveSheetAs, 0}) = cmCancel then Exit;
 FName := FExpand(FName);
 S := New(PDosStream, Init(FName, stOpen));
 W := S^.Status;
 Dispose(S, Done);
 if W = 0 then
  begin
   if Msg(dlFileExist, @PP, mfYesButton + mfNoButton + mfWarning) <> cmYes then Exit;
  end;
 DisposeStr(PWindow(Owner)^.Title);
 PWindow(Owner)^.Title := NewStr(FName); Owner^.Redraw;
 {PInfoView(CellInfo)^.SetInfo(' WORK ', Owner^.GetColor(12));}
 S := New(PBufStream, Init(FName, stCreate, 2048));
 S^.Write(CellWidth, Sizeof(CellWidth));
 S^.Put(Cells);
 if S^.Status <> stOK then
  begin
   Msg(dlCanNotWrite, @PP, mfError + mfOKButton);
   Error := True;
  end;
 Modified := Off;
 Dispose(S, Done);
 FileChanged(FName);
end;

procedure TCalcView.SaveSheet;
 var S: PStream;
     SS: String;
     PP: Pointer;
begin
 PP := @SS;
 if PWindow(Owner)^.Title^ = 'Untitled.WKZ' then begin SaveSheetAs; Exit end;
 {PInfoView(CellInfo)^.SetInfo(' WORK ', Owner^.GetColor(12));}
 S := New(PBufStream, Init(PWindow(Owner)^.Title^, stCreate, 2048));
 S^.Write(CellWidth, Sizeof(CellWidth)); S^.Put(Cells);
 SS := PWindow(Owner)^.Title^;
 if S^.Status <> stOK then
  begin
   Msg(dlCanNotWrite, @PP, mfError + mfOKButton);
   Error := True;
  end;
 Modified := Off;
 Dispose(S, Done);
 FileChanged(PWindow(Owner)^.Title^);
end;

procedure TCalcView.Copy;
 var I: Integer;
     X1, Y1, X2, Y2: Integer;
     P: PCellRec;
begin
 X1 := Delta.X + Cur.X; X2 := Mark.X;
 Y1 := Delta.Y + Cur.Y; Y2 := Mark.Y;
 if X1 > X2 then
   asm mov AX, X1; mov BX, X2; mov X1, BX; mov X2, AX end;
 if Y1 > Y2 then
   asm mov AX, Y1; mov BX, Y2; mov Y1, BX; mov Y2, AX end;
 if CellClipboard <> nil then Dispose(CellClipboard, Done);
 New(CellClipboard, Init(10, 10));
 for I := 1 to Cells^.Count do
  begin
   P := Cells^.At(I - 1);
   if (P^.Col >= X1) and (P^.Col <= X2) and (P^.Row >= Y1) and (P^.Row <= Y2) then
       With CellClipboard^.ReplaceItem(P^.Col, P^.Row, P^.S)^ do begin
         Options := P^.Options; Value := P^.Value; Decimals := P^.Decimals
        end;
  end;
 ClipRect.A.X := X1; ClipRect.A.Y := Y1;
 ClipRect.B.X := X2; ClipRect.B.Y := Y2;
end;

function ReformAddr(S1: String; X, Y, RX, RY: Word): String;
 var X1: Byte;
begin
   X1 := 0;
   if S1[1] <> '@' then X := RX else X1 := 1;
   if PosChar('@', System.Copy(S1, Byte(S1[1] = '@')+1, 255)) = 0
    then Y := RY else X1 := X1 or 2;
   S1 := GetCellName(X, Y);
   if X1 and 1 <> 0 then S1 := '@' + S1;
   if X1 and 2 <> 0 then
    begin
     X1 := 1;
     While (X1 < Length(S1)) and ((S1[X1] >= '@') and (S1[X1] <= 'Z')) do Inc(X1);
     Insert('@', S1, X1);
    end;
   ReformAddr := S1
end;

procedure TCalcView.Paste;
 var I, J: Integer;
     P: PCellRec;

 procedure RewriteFormula;
  const Signs = [';','[',']','{','}',#39,':','"','.','<',
                 '>',',','/','?','\','-','=','|','_','(',
                 ')','*','&','^','%','$','!','~','+', ' '];
  var S, S1: String;
      X, X1: Byte;
      I, Y, Y1: Integer;
 begin
  if P^.Options and 3 = coFormula then
   begin
    S := '='; I := 2;
    While (I <= Length(P^.S)) do
     begin
      S1 := '';
      While (P^.S[I] in Signs) and (I <= Length(P^.S)) do
            begin S := S + P^.S[I]; Inc(I) end;
      While not (P^.S[I] in Signs) and (I <= Length(P^.S)) do
            begin S1 := S1 + P^.S[I]; Inc(I) end;
      if GetCellCoord(S1,X,Y) then
         S1 := ReformAddr(S1, X, Y, X - ClipRect.A.X + Delta.X + Cur.X,
                                    Y - ClipRect.A.Y + Delta.Y + Cur.Y);
      S := S + S1;
     end;
    end else S := P^.S;

   With Cells^.ReplaceItem(P^.Col - ClipRect.A.X + Delta.X + Cur.X,
                           P^.Row - ClipRect.A.Y + Delta.Y + Cur.Y, S)^ do
    begin Options := P^.Options; Value := P^.Value; Decimals := P^.Decimals end;

 end;

begin
 if CellClipboard = nil then Exit;
 Mark.X := Delta.X + Cur.X + ClipRect.B.X - ClipRect.A.X;
 Mark.Y := Delta.Y + Cur.Y + ClipRect.B.Y - ClipRect.A.Y;
 Clear;
 for I := 1 to CellClipboard^.Count do
  begin
   P := CellClipboard^.At(I - 1);
   RewriteFormula;
  end;
  for I := Delta.X + Cur.X to Mark.X do
   for J := Delta.Y + Cur.Y to Mark.Y do
     ModifyCell(I, J);
end;

procedure TCalcView.Clear;
 var X1, X2, Y1, Y2, K, L: Integer;
begin
 X1 := Delta.X + Cur.X; X2 := Mark.X;
 Y1 := Delta.Y + Cur.Y; Y2 := Mark.Y;
 if X1 > X2 then
  asm mov AX, X1; mov BX, X2; mov X1, BX; mov X2, AX end;
 if Y1 > Y2 then
  asm mov AX, Y1; mov BX, Y2; mov Y1, BX; mov Y2, AX end;
 for K := X1 to X2 do
  for L := Y1 to Y2 do
   begin
    Cells^.DelItem(K, L);
    ModifyCell(K, L);
   end;
end;

procedure TCalcView.InsertLineCol;
 var I, J, L: Integer;
     P: PCellRec;
     O, D: Integer;
     V: Real;

procedure RewriteFormula;
 const Signs = [';','[',']','{','}',#39,':','"','.','<', ' ',
                '>',',','/','?','\','-','=','|','_','(',
                ')','*','&','^','%','$',' ','!','~','+'];
 var S, S1 : String;
     X: Byte;
     I, Y: Integer;
begin
 S := '='; I := 2;
 While (I <= Length(P^.S)) do
  begin
   S1 := '';
   While (P^.S[I] in Signs) and (I <= Length(P^.S)) do
         begin S := S + P^.S[I]; Inc(I) end;
   While not (P^.S[I] in Signs) and (I <= Length(P^.S)) do
         begin S1 := S1 + P^.S[I]; Inc(I) end;
   if GetCellCoord(S1,X,Y) then
     case Command of
      cmInsertLine: if (Y >= L) then S1 := ReformAddr(S1, X, Y, X, Y + 1);
      cmInsertColumn: if (X >= L) then S1 := ReformAddr(S1, X, Y, X + 1, Y);
     end;
   S := S + S1;
  end;
  O := P^.Options; D := P^.Decimals; V := P^.Value;
  P := Cells^.ReplaceItem(P^.Col, P^.Row, S);
  with P^ do
   begin Options := O; Decimals := D; Value := V end;
end;

begin
 if Command = cmInsertLine then L := Delta.Y + Cur.Y
                           else L := Delta.X + Cur.X;
 for I := 1 to Cells^.Count do
  begin
   P := Cells^.At(I - 1);
   case Command of
    cmInsertLine : begin
                    if P^.Row >= L then Inc(P^.Row);
                    if P^.Row >= VScroll^.Max then Cells^.AtFree(I - 1)
                   end;
  cmInsertColumn : begin
                    if P^.Col >= L then Inc(P^.Col);
                    if P^.Col >= HScroll^.Max then Cells^.AtFree(I - 1)
                   end;
   end;
   if P^.Options and 3 = coFormula then RewriteFormula;
  end;
  ReCalc;
end;

procedure TCalcView.DeleteLineCol;
 var I, J, L: Integer;
     P: PCellRec;
     O, D: Integer;
     V: Real;

 procedure RewriteFormula;
  const Signs = [';','[',']','{','}',#39,':','"','.','<', ' ',
                 '>',',','/','?','\','-','=','|','_','(',
                 ')','*','&','^','%','$',' ','!','~','+'];
  var S, S1 : String;
      X: Byte;
      I, Y: Integer;
 begin
  S := '='; I := 2;
  While (I <= Length(P^.S)) do
   begin
    S1 := '';
    While (P^.S[I] in Signs) and (I <= Length(P^.S)) do
          begin S := S + P^.S[I]; Inc(I) end;
    While not (P^.S[I] in Signs) and (I <= Length(P^.S)) do
          begin S1 := S1 + P^.S[I]; Inc(I) end;
    if GetCellCoord(S1,X,Y) then
      case Command of
       cmDeleteLine: if (Y > L) then S1 := ReformAddr(S1, X, Y, X, Y - 1);
       cmDeleteColumn: if (X > L) then S1 := ReformAddr(S1, X, Y, X - 1, Y);
      end;
    S := S + S1;
   end;
  O := P^.Options; D := P^.Decimals; V := P^.Value;
  P := Cells^.ReplaceItem(P^.Col, P^.Row, S);
  with P^ do
   begin Options := O; Decimals := D; Value := V end;
 end;

begin
 if Command = cmDeleteLine then L := Delta.Y + Cur.Y
                           else L := Delta.X + Cur.X;
 for I := 1 to Cells^.Count do
  begin
   P := Cells^.At(I - 1);
   if P^.Options and 3 = coFormula then RewriteFormula;
   case Command of
    cmDeleteLine:
     if P^.Row = L then begin Cells^.FreeItem(P); Cells^.AtPut(I - 1, nil) end else
      if P^.Row > L then Dec(P^.Row);
    cmDeleteColumn:
     if P^.Col = L then begin Cells^.FreeItem(P); Cells^.AtPut(I - 1, nil) end else
      if P^.Col > L then Dec(P^.Col);
   end;
  end;
 Cells^.Pack;
 ReCalc;
end;

procedure TCalcView.ReCalc;
 var I: Integer;
     P: PCellRec;
     HP: Pointer;
     Tree: FPtr;
begin
 for I := 1 to Cells^.Count do
  begin
   P := Cells^.At(I-1);
   if P^.Options and coFormula <> 0 then
     begin
      System.Mark(Hp);
      CurrentCalc.X := P^.Col; CurrentCalc.Y := P^.Row;
      Tree := GetFormula(System.Copy(P^.S, 2, 255));
      P^.Value := CalcFormula(Tree);
      Release(Hp);
      ModifyCell(P^.Col, P^.Row);
     end;
  end;
end;

procedure TCalcView.GotoCell;
 var X: Byte;
     Y,L: Integer;
begin
 if not GetCellCoord(Cell, X, Y) then
  begin
   ErrMsg(erGotoInvalidNumber);
   Exit;
  end;
 Marking := False;
 BlockDraw := True;
 Delta.X := X;
 Delta.Y := Y - (Size.Y - 2) div 2;
 VScroll^.SetValue(Delta.Y);
 Delta.Y := VScroll^.Value;
 Cur.X := 0; Cur.Y := Y - Delta.Y;
 L := 7;
 repeat
  if Delta.X > 0 then begin Inc(Cur.X); Dec(Delta.X) end;
  Inc(L, CellWidth[Cur.X + Delta.X]);
 until (Delta.X = 0) or (L > Size.X div 2);
 if L > Size.X div 2 then begin Dec(Cur.X); Inc(Delta.X) end;
 HScroll^.SetValue(Delta.X);
 BlockDraw := False;
 Mark.X := Cur.X + Delta.X;
 Mark.Y := Cur.Y + Delta.Y;
 DrawView;
end;

procedure TCalcView.SearchCell;
 const Signs = [#0..#128] - ['A'..'Z','a'..'z','0'..'9','_'];
 var P: PCellRec;
     I, J: Integer;
     V: Real;
     K, L: Byte;
     S,S1: String;

 function Found: Boolean;
 begin
  Found := True;
  SearchPos.Y := P^.Row; SearchPos.X := P^.Col;
  GotoCell(GetCellName(P^.Col, P^.Row));
  if WasReplace then
    begin
     if (SearchData.TxtOptions and 4 <> 0) then
      if (SearchData.CellOptions = 0) then
       begin S := P^.S; Delete(S, K+L, Length(S1));
             Insert(ReplaceData.S1, S, K+L);
             Cells^.ReplaceItem(P^.Col, P^.Row, S); DrawView; Exit
       end else
       begin if P^.Options and 3 = coFormula then
                begin Found := False; Exit end;
             Val(ReplaceData.S1, V, J);
             Cells^.ReplaceItem(P^.Col, P^.Row, ReplaceData.S1)^.Value := V;
             DrawView; Exit
       end;
    end;
 end;

 procedure SearchSign;
 begin
  While (K <= Length(S)) and not (S[K] in Signs) do Inc(K);
  Inc(L, K);
  S := System.Copy(S, K, 255);
 end;

begin
 if SearchData.S = '' then Exit;
 Val(SearchData.S, V, I);
 if SearchData.TxtOptions and 1 = 0 then S1 := UpCaseStr(SearchData.S)
                                    else S1 := SearchData.S;
 For I := 1 to Cells^.Count do
  begin
   P := Cells^.At(I - 1);
   if (P^.Row >= SearchPos.Y) and (P^.Col > SearchPos.X) then
    if (SearchData.CellOptions = 0) then
     begin
      if SearchData.TxtOptions and 1 = 0 then S := UpCaseStr(P^.S)
                                         else S := P^.S;
      K := Pos(S1, S); L := 0;
      if SearchData.TxtOptions and 2 = 0 then
       begin if K > 0 then begin if Found then Exit end end
       else repeat
              K := Pos(S1, S); L := 0;
              if K = 0 then else
              if (K = 1) or (S[0] = S1[0]) then
               begin
                 if (S[0] = S1[0]) or (S[0] <> S1[0]) and (S[Length(S1) + 1] in Signs)
                  then begin if Found then Exit end else SearchSign;
               end else
              if (K = Length(S) - Length(S1) + 1) then
               begin if (S[K - 1] in Signs) then begin if Found then Exit end
                     else SearchSign;
               end else
              if (S[K - 1] in Signs) and (S[Length(S1) + K] in Signs)
               then begin if Found then Exit end else SearchSign;
            until (K = 0) or (S[0] < S1[0]);
     end else
      if (P^.Options and 3 <> 0) and (V = P^.Value) then
       begin if Found then Exit end;
  end;
 if not ContSearch and not WasReplace then
    ErrMsg(erTextNotFound);
 SearchCanceled := True;
end;

end.