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

unit Editor;

interface
uses Views, Objects, Drivers, MicroEd, ObjType;

type
     PXFileEditor = ^TXFileEditor;
     TXFileEditor = object(TFileEditor)
       function HandleCommand(var Event: TEvent): Boolean; virtual;
     end;

const
      RXFileEditor: TStreamRec = (
       ObjType: otXFileEditor;
       VmtLink: Ofs(TypeOf(TXFileEditor)^);
       Load: @TXFileEditor.Load;
       Store: @TXFileEditor.Store);

implementation
uses Advance, DOS, Dialogs, DNApp, RStrings, SBlocks, Memory, Gauge,
     Startup, WinClp, Messages, Commands, Macro, xTime;

type
     PSortCollection = ^TSortCollection;
     TSortCollection = object(TSortedCollection)
       function Compare(Key1, Key2: Pointer): Integer; virtual;
     end;

var BoundStart, BoundEnd: Word;

function TSortCollection.Compare;
  var P1: PString absolute Key1;
      P2: PString absolute Key2;
begin
   if P1 = nil then Compare := -1 else
     if P2 = nil then Compare := 1 else
       if Copy(P1^, 3, 255) > Copy(P2^, 3, 255) then Compare := 1
          else Compare := -1
end;



function TXFileEditor.HandleCommand;

var  LastX, LastY: Integer;
     WL: Byte absolute WorkString;
     OldDelta,
     T: TPoint;

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

  procedure StartSearch(Replace: Boolean);
   var D: PDialog;
       P, P1: PView;
       R: TRect;
       Y: Integer;
       S: String;
  begin
   S := '';
   if not (WorkString[LastX + 1] in BreakChars) then
       begin
         While (LastX > 0) and
               not (WorkString[LastX] in BreakChars) do Dec(LastX);
         While not (WorkString[LastX + 1] in BreakChars)
                     and (LastX < WL) do
                      begin
                       S := S + WorkString[LastX + 1];
                       Inc(LastX);
                      end;
       end;
   SearchData.Line := S;
   if not Replace then SearchData.What := #0;
   if Replace then Y := ExecResource(dlgEditorReplace, SearchData)
              else Y := ExecResource(dlgEditorFind, SearchData);
   if Y = cmCancel then Exit;
   ReplaceAll := Replace and (Y = cmYes);
   OldDelta := Delta;
   if SearchData.Origin=0 then
      if SearchData.Dir = 0 then LongInt(Delta) := 0
                            else begin Delta.X := 255; Delta.Y := FileLines^.Count - 1; end;
   if not Search then Delta := OldDelta;
  end;

  procedure MakeUndo;
   var P: PUndoRec;
       S, S1: String;
       V: Boolean;
       I, J: Integer;
       PS: PString;
       RPT: Boolean;
  begin
   repeat
     RPT := On;
     ChangeLine;
     Mark.B := Mark.A; Marking := Off; BlockVisible := Off; UnMark := On;
     if (UndoInfo = nil) or (UndoInfo^.Count = 0) then Exit;
     P := UndoInfo^.At(UndoInfo^.Count - 1);
     if (P^.Where.X <> Delta.X) or (P^.Where.Y <> Delta.Y) then
      begin ScrollTo(P^.Where.X, P^.Where.Y); Exit; end;
     case P^.What of
      udDelBlock: begin
                   V := VertBlock; VertBlock := P^.Vertical;
                   InsertBlock(P^.Lines, Off);
                   VertBlock := V;
                   SetLimits;
                  end;
      udDelChar: begin
                  S := GetLine(P^.Where.Y);
                  if Byte(S[0]) < P^.Where.X + 1 then S := S + Strg(' ', P^.Where.X - Byte(S[0]) + 1);
                  Insert(P^.Str^, S, P^.Where.X + 1);
                  ModifyLine(P^.Where.Y, S, Off);
                 end;
      udInsChar: begin
                  S := GetLine(P^.Where.Y);
                  Delete(S, P^.Where.X - P^.Count + 1, P^.Count);
                  ModifyLine(P^.Where.Y, S, Off);
                  ScrollTo(P^.Where.X - P^.Count, P^.Where.Y);
                 end;
      udInsLine: begin
                  ModifyLine(P^.Where.Y, CnvString(P^.Str), Off);
                  FileLines^.AtFree(P^.Where.Y + 1);
                  SetLimits;
                 end;
      udSubDel: ModifyLine(P^.Where.Y, CnvString(P^.Str), Off);
      udSubDelLine: begin
                      S := GetLine(P^.Where.Y);
                      if P^.Str <> nil then Dec(S[0], Byte(P^.Str^[0]));
                      ModifyLine(P^.Where.Y, S, Off);
                      if P^.Str = nil then S := '' else S := P^.Str^;
                      FileLines^.AtInsert(P^.Where.Y+1, NewStr(S));
                      SetLimits;
                    end;
      udInsVertBlock: begin
                       for I := 1 to P^.Count do
                       begin
                        S := GetLine(I+Delta.Y-1);
                        Delete(S, Delta.X+1, P^.Width);
                        ModifyLine(I+Delta.Y-1, S, Off);
                       end;
                      end;
      udInsBlock, udFormatBlock: begin
                   S := P^.Str^;
                   J := Byte(S[2])*256 + Byte(S[1]);
                   for I := 1 to J do FileLines^.AtFree(Delta.Y);
                   Delete(S, 1, 2);
                   FileLines^.AtInsert(Delta.Y, NewStr(S));
                   SetLimits;
                   RPT := P^.What <> udFormatBlock;
                  end;
      udReplaceChar: begin
                      S := GetLine(P^.Where.Y);
                      Delete(S, P^.Where.X + 1 - Byte(P^.Str^[0]), Byte(P^.Str^[0]));
                      Insert(P^.Str^, S, P^.Where.X + 1 - Byte(P^.Str^[0]));
                      ModifyLine(P^.Where.Y, S, Off);
                     end;
      udBackDel: begin
                      S := AddSpace(GetLine(P^.Where.Y), LastX+1);
                      Insert(P^.Str^, S, P^.Where.X + 1);
                      ModifyLine(P^.Where.Y, S, Off);
                      ScrollTo(P^.Where.X + Byte(P^.Str^[0]), P^.Where.Y);
                 end;
      udIndentBlock: begin
                      for I := P^.Block.A.Y to P^.Block.B.Y-Byte(P^.Block.B.X = 0) do
                       begin
                        S := GetLine(I); Delete(S, 1, P^.Count);
                        ModifyLine(I, S, Off);
                       end;
                     end;
      udUnindentBlock: begin
                      for I := P^.Block.A.Y to P^.Block.B.Y-Byte(P^.Block.B.X = 0) do
                       begin
                        S := Strg(' ', P^.Count)+GetLine(I);
                        ModifyLine(I, S, Off);
                       end;
                     end;
      udReplace: begin
                  S := GetLine(Delta.Y);
                  Delete(S, Delta.X+1, Byte(P^.Str^[1]));
                  Insert(Copy(P^.Str^, 2, 255), S, Delta.X+1);
                  ModifyLine(Delta.Y, S, Off);
                 end;
      udDupeLine: begin
                    FileLines^.AtFree(P^.Where.Y + 1);
                    SetLimits;
                  end;
      udStrModified: begin
                       if P^.Str = nil then S := '' else S := P^.Str^;
                       ModifyLine(Delta.Y, S, Off);
                     end;
      udReplaceBlock, udClearBlock:
                 begin
                  for I := Delta.Y to P^.Lines^.Count + Delta.Y - 1 do
                   begin
                    S := GetLine(I); PS := P^.Lines^.At(I-Delta.Y);
                    if PS <> nil then S1 := PS^ else S1 := '';
                    Delete(S, Delta.X+1, Length(S1));
                    if Length(S) < Delta.X + 1 then
                       S := S + Strg(' ', Delta.X + 1 - Length(S));
                    Insert(S1, S, Delta.X+1);
                    ModifyLine(I, S, Off);
                   end;
                 end;
      udDelLine: begin
                  While P^.Lines^.Count > 0 do
                   begin
                    FileLines^.AtInsert(P^.Where.Y, P^.Lines^.At(P^.Lines^.Count - 1));
                    P^.Lines^.AtDelete(P^.Lines^.Count-1);
                   end;
                  SetLimits;
                 end;
     end;
     WorkModified := Off;
     ChangeLine;
     UndoInfo^.AtFree(UndoInfo^.Count - 1);
     Dec(UndoTimes);
     if UndoTimes = 0 then
       begin
          Modified := Off;
          if PEditWindow(Owner)^.AInfo <> nil then PEditWindow(Owner)^.AInfo^.DrawView;
       end;
   until RPT;
  end;

  procedure UnIndentBlock(Undo: Boolean);
   var I: Integer;
       S: String;
  begin
   Modified := On;
   if not (BlockVisible and ValidBlock) then Exit;
   ChangeLine;
   for I := Mark.A.Y to Mark.B.Y-Integer(Mark.B.X = 0) do
       begin S[1] := ' '; S := GetLine(I);
             if S[1] <> ' ' then Exit; end;
   T.X := 0; T.Y := Mark.A.Y;
   if Undo then StoreUndoInfo(udUnindentBlock, T, Mark);
   for I := Mark.A.Y to Mark.B.Y-Integer(Mark.B.X = 0) do
    begin S := GetLine(I); DelFC(S); ModifyLine(I, S, On) end;
   EnableMarking := Off; Marking := Off; Sel := Mark;
   ScrollTo(0, Mark.A.Y); Mark := Sel; DrawView; ChangeLine;
   EnableMarking := On;
  end;

  procedure IndentBlock(Undo: Boolean);
   var I: Integer;
       S: String;
       M: TRect;
  begin
   Modified := On;
   if not (BlockVisible and ValidBlock) then Exit;
   ChangeLine;
   T.X := 0; T.Y := Mark.A.Y;
   if Undo then StoreUndoInfo(udIndentBlock, T, Mark);
   for I := Mark.A.Y to Mark.B.Y-Integer(Mark.B.X = 0) do
    begin S := ' ' + GetLine(I); ModifyLine(I, S, On) end;
   EnableMarking := Off; Marking := Off; M := Mark;
   ScrollTo(0, Mark.A.Y); Mark := M; DrawView; ChangeLine;
   EnableMarking := On;
  end;

  procedure NextBreak(S: String; var I: Integer);
   var L: Byte absolute S;
  begin
   While (I<=L) and not (S[I] = ' ') do Inc(I);
   While (I<=L) and (S[I] = ' ') do Inc(I);
  end;

  function FirstToken(var S: String): String;
   var SS: String;
       I: Integer;
       L: Byte absolute S;
  begin
   FirstToken := '';
   I := 1; While (S[L] = ' ') do Dec(L); if S = '' then Exit;
   While (S[1]=' ') do DelFC(S);
   NextBreak(S, I);
   SS := Copy(S, 1, I-1); Delete(S, 1, I-1);
   FirstToken := SS;
  end;

  procedure FormatBlock(Command: Word);
   var S, Left, W: String;
       P: PLineCollection;
       PS: PString;
       LS, I, J, LG: Integer;
       Abort, LastLine: Boolean;
       TP: TPoint;

   label 1;

   procedure WriteLeft;
    var I: Integer;
        L: Byte absolute Left;
   begin
    while Left[Byte(Left[0])]=' ' do Dec(Left[0]);
    DelLeft(Left);
    case Command of
     cmFRight, cmLRight:
       begin J := RightSide - Byte(Left[0]);
             if J > 0 then Left := Strg(' ', J) + Left
                      else Left := Strg(' ', LeftSide)+Left end;
     cmFLeft, cmLLeft: Left := Strg(' ', LeftSide) + Left;
     cmFCenter, cmLCenter: begin J := (LS - Byte(Left[0])) div 2; if J < 0 then J := 0;
                      Left := Strg(' ', LeftSide + J)+Left end;
     cmFJustify, cmLJustify: begin
                  I := 1; J := 0;
                  While (L < LS) and (J <> I) and not LastLine do
                   begin Inc(I); J := I; NextBreak(Left, I);
                         if I < L then Insert(' ', Left, I) else
                          if J = 2 then Break else I := 1;
                   end;
                  J := LeftSide; if P^.Count = 0 then J := InSide;
                  Left := Strg(' ', J) + Left;
                 end;
    end;
    PS := NewStr(Left); if PS = nil then begin Abort := On; Exit end;
    P^.Insert(PS); if LowMemory then begin Abort := On; Exit end;
    Left := W; LS := RightSide - LeftSide;
   end;

   procedure CompressLine(N: Integer);
    var MS: String;
   begin
    S := GetLine(N); DelDoubles('  ', S);
    if S[1] = ' ' then DelFC(S);
    if N - 1 < FileLines^.Count then MS := GetLine(N+1) else MS := '';
    DelDoubles('  ', MS); if MS[1] = ' ' then DelFC(MS);
    if (N < LG) and (Byte(S[0]) < RightSide) and (Byte(MS[0]) + Byte(S[0]) < 254) then
     begin S := S + ' ' + MS; Inc(I); end;
   end;

  begin
   Abort := Off; LastLine := Off; Modified := On;
   if not (ValidBlock and BlockVisible) or VertBlock then Exit;
   if LowMemory then Exit; ChangeLine;
   {if UndoInfo <> nil then UndoInfo^.FreeAll; Inc(UndoTimes);}
   New(P, Init((Mark.B.Y-Mark.A.Y+1)*2,10));
   for I := Mark.A.Y to Mark.B.Y - Integer(Mark.B.X = 0) do
       P^.Insert(NewStr(GetLine(I)));
   TP.Y := Mark.A.Y; TP.X := 0;
   StoreUndoInfo(udDelBlock, TP, P);
   New(P, Init((Mark.B.Y-Mark.A.Y+1)*2,10));
   if P = nil then Exit; Left := ''; LS := RightSide - LeftSide; W := '';
   if (Command = cmFJustify) or (Command = cmLJustify) then LS := RightSide - InSide;
   LG := Mark.B.Y - Integer(Mark.B.X = 0);
   I := Mark.A.Y; CompressLine(I);
   repeat
    W := FirstToken(S);
    if W = '' then
     begin Left := Left+' '; if I < LG then CompressLine(I+1); Inc(I); GoTo 1 end;
    J := Integer(Left[Length(Left)] = ' ');
    DelRight(W);
    DelDoubles('  ', W);
    if W[1] = ' ' then DelFC(W);
    if Length(Left)+ Length(W) + J < LS then
      if J = 0 then Left := Left+' '+W else Left := Left+W
      else WriteLeft;
    if Left[1] = ' ' then DelFC(Left);
  1:
   if Abort then begin Dispose(P, Done); Exit end;
   until I > LG+1;
   LastLine := On; WriteLeft;
   if Abort then begin Dispose(P, Done); Exit end;
   Marking := Off; EnableMarking := Off;
   Delta.Y := Mark.A.Y; Delta.X := 0;
   for I := Mark.A.Y to LG do FileLines^.AtFree(Delta.Y);
   Mark.A.X := 0; Mark.B.Y := Mark.A.Y + P^.Count; Mark.B.X := 0;
   S := Char(Lo(P^.Count)) + Char(Hi(P^.Count));
   StoreUndoInfo(udFormatBlock, TP, S);
   while P^.Count > 0 do
    begin FileLines^.AtInsert(Delta.Y, P^.At(P^.Count-1)); P^.AtDelete(P^.Count-1); end;
   SetLimits; DrawView; Dispose(P, Done); ChangeLine;
   EnableMarking := On;
  end;

  procedure Print(Block: Boolean);
   var S: TDOSStream;
       L: PCollector;
       PC: PCollection;
       M: String;
       P: PWhileView;
       I: Integer;
       R: TRect;
       E: TEvent;
       PS: PString;
       Cancel: Boolean;
       LL: Array [1..3] of LongInt;
       SR: SearchRec;
       FName: String;
   label 1;
  begin
   ChangeLine;
   if Block then
     begin
       PC := GetSelection;
       if PC = nil then Exit;
       L := New(PStdCollector, Init(10));
       Dispose(PStdCollector(L)^.Collection, Done);
       PStdCollector(L)^.Collection := PC;
       PStdCollector(L)^.Count := PC^.Count;
     end else L := FileLines;
   LL[1] := L^.Count;
   FormatStr(M, GetString(dlED_PrintQuery), LL);
   if MessageBox(M, nil, mfYesNoConfirm) <> cmYes
    then begin if Block then Dispose(L, Done); Exit; end;
   R.Assign(1,1,30,10);
   New(P,Init(R));
   P^.Top := GetString(dlED_Print);
   Desktop^.Insert(P);
   ClrIO; Cancel := Off;
   for I := 1 to 1000 do
     begin
       FName := SwpDir+'$DN'+SStr(I, 4, '0')+'$.PRN';
       ClrIO;
       FindFirst(FName, Archive, SR);
       if DOSError <> 0 then Break;
     end;
   S.Init(FName, stCreate);
   if S.Status <> stOK then
     begin
       S.Done;
       PS := @FName;
       Msg(erCantCreateFile, @PS, mfError+mfOKButton);
       Goto 1;
     end;
   P^.Write(1, GetString(dlED_Printed));
   for I := 0 to L^.Count - 1 do
    begin
     PS := L^.At(I);
     P^.Write(2, Copy(Strg(#219, ((I+1)*25) div L^.Count)+Strg(#177, 25), 1, 25));
     LL[1] := I+1; LL[2] := L^.Count+1;
     FormatStr(M, GetString(dlED_PrintLine), LL);
     P^.Write(3, M);
     if PS = nil then M := '' else M := PS^;
     M := M + #13#10;
     S.Write(M[1],Length(M));
     DispatchEvents(P, Cancel);
     if Cancel or Abort then Goto 1;
    end;
   M := #12;
   S.Write(M[1], 1);
   S.Done;
   Message(Application, evCommand, cmFilePrint, @FName);
  1:
   P^.Free;
   if Block then Dispose(L, Done);
  end;

  procedure SetFormat;
   var Data: Record S1, S2, S3: String[6]; end;
       I, J: Integer;
  begin
   Data.S1 := ItoS(LeftSide);
   Data.S2 := ItoS(RightSide);
   Data.S3 := ItoS(InSide);

   if ExecResource(dlgEditorFormat, Data) <> cmCancel then
    begin
     Val(Data.S1, I, J); if J = 0 then LeftSide := I;
     Val(Data.S2, I, J); if J = 0 then RightSide := I;
     Val(Data.S3, I, J); if J = 0 then InSide := I;

     if (LeftSide > RightSide) or (LeftSide < 0) then LeftSide := 0;
     if RightSide < 2 then RightSide := 2;
     if (InSide >= RightSide) or (InSide < 0) then InSide := LeftSide;
    end;
  end;

  procedure GotoLine;
   const S: String = '';
   var I, J: Integer;
  begin
   if ExecResource(dlgGotoLine, S) <> cmOK then Exit;
   Val(S, I, J);
   if (J = 0) and (I > 0) then ScrollTo(Delta.X, I-1);
  end;

  procedure SortBlock;
    var {PC: PSortCollection;}
        {I, J, K: Integer;
        B: Boolean;}
        S: string;
        Info: PView;
        Tmr: TEventTimer;
        UC: Boolean;

   procedure QuickSort(L, R: Integer);
   var
     I, J: Integer;

     function Ln(AI: Integer): string;
     begin
       if TimerExpired(Tmr) then
       begin
         UpdateWriteView(Info);
         Application^.Idle;
         NewTimer(Tmr, 3);
       end;
       Ln := Copy(GetLine(AI), BoundStart, BoundEnd);
     end;

   begin
     repeat
       I := L;
       J := R;
       S := Ln((L + R) shr 1);
       repeat
         while Ln(I) < S do Inc(I);
         while Ln(J) > S do Dec(J);
         if I <= J then
         begin
           if I <> J then FileLines^.SwapItems(I, J);
           Inc(I);
           Dec(J);
         end;
       until I > J;
       if L < J then QuickSort(L, J);
       L := I;
     until I >= R;
   end;


  begin
    if not VertBlock then
     begin
       ErrMsg(dlED_VertNeed);
       Exit;
     end;
    UC := PBlocker(FileLines)^.UseCache;
    PBlocker(FileLines)^.UseCache := False;
    Info := WriteMsg(GetString(dlPleaseStandBy));
    NewTimer(Tmr, 2);
    ChangeLine;
    BoundStart := Mark.A.X+1; BoundEnd := Mark.B.X - Mark.A.X;
    QuickSort(Mark.A.Y, Mark.B.Y);
    if UndoInfo <> nil then UndoInfo^.FreeAll; Inc(UndoTimes); Modified := On;
    Dispose(Info, Done);
    PBlocker(FileLines)^.UseCache := UC;
  end;

  procedure CalcBlock;
    var
        I, J: Integer;
        R1, R2: Real;
        S: String[40];
  begin
    if not VertBlock then
     begin
       ErrMsg(dlED_VertNeed);
       Exit;
     end;
    ChangeLine;
    BoundStart := Mark.A.X; BoundEnd := Mark.B.X - Mark.A.X;
    R1 := 0;
    for I := Mark.A.Y to Mark.B.Y do
      begin
        Val(DelSpaces(Copy(GetLine(I), BoundStart+1, BoundEnd)), R2, J);
        R1 := R1 + R2;
      end;
    Str(R1:0:20, S);
    While S[Length(S)] = '0' do Dec(S[0]);
    if S[Length(S)] = '.' then Dec(S[0]);
    Message(Application, evCommand, cmPutInClipboard, @S);
  end;

  procedure WorkModify;
  begin
   if WorkModified then Exit;
   LastLine := Delta.Y;
   LastShape := GetLine(LastLine);
   WorkModified := On; Modified := On; WasDelete := Off;
  end;


  procedure InsertDateTime(Time: Boolean);
   var S: String[30];
       SS: Integer;
  begin
    S := GetDateTime(Time);
    ChangeLine;
    WorkModify;
    WorkString := AddSpace(WorkString, LastX+1);
    System.Insert(S, WorkString, LastX+1);
    for SS := 1 to Length(S) do
      begin
        StoreUndoInfo(udInsChar, Delta, WorkString);
        if Delta.X < 255 then Inc(Delta.X);
      end;
    ScrollTo(Delta.X, Delta.Y);
    ChangeLine; DrawView;
  end;

  procedure PlayMacro;
    var I: Integer;
        P: PEditMacros;

    function DoFind(P: PEditMacros): Boolean; far;
    begin
      if UpStrg(P^.Name^) = UpCase(Event.InfoChar) then
        begin
          P^.Play(@Self);
          DoFind := On;
        end else DoFind := Off;
    end;

  begin
    if Event.InfoChar < #32 then Inc(Event.InfoChar, 64);
    Macros^.FirstThat(@DoFind);
  end;

  procedure SelectMacro;
  begin
  end;

  procedure SearchFwd;
    var I: Integer;
        C: String[2];
  begin
    I := 1; Inc(LastX);
    case WorkString[LastX] of
      '[': C := '[]';
      '{': C := '{}';
      '(': C := '()';
    end;
    FreeStr := WorkString;
    while (LastY < FileLines^.Count) do
     begin
        while LastX < Length(FreeStr) do
         begin
           if FreeStr[LastX+1] = C[1] then Inc(I) else
             if FreeStr[LastX+1] = C[2] then Dec(I);
           if I = 0 then
             begin
               ScrollTo(LastX, LastY);
               HandleCommand := On;
               Exit;
             end;
           Inc(LastX);
         end;
       Inc(LastY); LastX := 0; FreeStr := GetLine(LastY);
     end;
  end;

  procedure SearchBwd;
    var I: Integer;
        C: String[2];
  begin
    I := 1;
    case WorkString[LastX+1] of
      ']': C := '[]';
      '}': C := '{}';
      ')': C := '()';
    end;
    Dec(LastX);
    FreeStr := WorkString;
    while (LastY >= 0) do
     begin
        while LastX >= 0 do
         begin
           if FreeStr[LastX+1] = C[2] then Inc(I) else
             if FreeStr[LastX+1] = C[1] then Dec(I);
           if I = 0 then
             begin
               ScrollTo(LastX, LastY);
               HandleCommand := On;
               Exit;
             end;
           Dec(LastX);
         end;
       Dec(LastY); FreeStr := GetLine(LastY); LastX := Length(FreeStr)-1;
     end;
  end;

  procedure ChangeVertBlockCase(C: Word); forward;

  procedure ChangeBlockCase(C: Word; Show: Boolean);
    var I,J,K,L,SX,EX,SY,EY: Integer;
        S,S1: String;
        A: String[4];
        P: PCollection;
  begin
    if (Mark.A.Y > Mark.B.Y) or (Mark.A.Y = Mark.B.Y) and (Mark.A.X >= Mark.B.X) then Exit;
    ChangeLine;
    S := GetLine(Mark.A.Y);
    while (Mark.A.X > 0) and not (S[Mark.A.X+1] in BreakChars) do Dec(Mark.A.X);
    SY := Mark.A.Y; SX := Mark.A.X+1;
    S1 := Copy(S, 1, SX-1);
    S := GetLine(Mark.B.Y);
    if Mark.B.X = 0 then begin EY := Mark.B.Y-1; EX := 255; end else
     begin
       EY := Mark.B.Y;
       while (Mark.B.X < Length(S)) and not (S[Mark.B.X+1] in BreakChars) do Inc(Mark.B.X);
       EX := Mark.B.X;
     end;
    P := GetSelection;
    WorkModify;
    ChangeLine;
    StoreUndoInfo(udDelBlock, Mark.A, P);
    for I := SY to EY do
      begin
        S := GetLine(I);
        if I = SY then J := SX else J := 1;
        if I = EY then L := EX else L := Length(S);
        case C of
          cmUpcaseBlock: S := Copy(S, 1, J-1)+UpcaseStr(Copy(S, J, L-J+1))+Copy(S,L+1,255);
          cmLowcaseBlock: S := Copy(S, 1, J-1)+LowcaseStr(Copy(S, J, L-J+1))+Copy(S,L+1,255);
          cmCapitalizeBlock: S := Copy(S, 1, J-1)+CapcaseStr(Copy(S, J, L-J+1))+Copy(S,L+1,255);
        end;
        ModifyLine(I, S, Off);
        if I = EY then S := Copy(S, L+1, 255);
      end;
    Insert(Char(Lo(P^.Count))+Char(Hi(P^.Count))+S1, S, 1);
    StoreUndoInfo(udFormatBlock, Mark.A, S);
    ChangeLine;
    if Show then DrawView;
  end;

  procedure ChangeVertBlockCase;
    var OldMark: TRect;
        I: Integer;
  begin
    OldMark := Mark;
    for I := OldMark.A.Y to OldMark.B.Y do
      begin
        Mark.Assign(OldMark.A.X, I, OldMark.B.X, I);
        ChangeBlockCase(C, Off);
      end;
    Mark := OldMark;
    DrawView;
  end;


  procedure CopyWinBlock;
   var R: TRect;
  begin
   ChangeLine;
   if (Clipboard <> nil) then Dispose(Clipboard, Done);
   Clipboard := GetSelection;
   SetWinClip( PLineCollection(Clipboard));
  end;


begin
  LastX := Delta.X; LastY := Delta.Y; HandleCommand := Off;
  case Event.Command of
     cmWindowsCopy: CopyWinBlock;
     cmSyncClipIn: SyncClipIn;
     cmSyncClipOut: SyncClipOut;
     cmUpcaseBlock,
     cmLowcaseBlock,
     cmCapitalizeBlock: if ValidBlock and BlockVisible then
                            if VertBlock then ChangeVertBlockCase(Event.Command)
                                         else ChangeBlockCase(Event.Command, On);
     cmPlayMacro: PlayMacro;
     cmSelectMacro: SelectMacro;
     cmSetMargins: SetFormat;
     cmGotoLineNumber: GotoLine;
     cmSortBlock: begin if ValidBlock then SortBlock; HandleCommand := On; end;
     cmCalcBlock: begin if ValidBlock then CalcBlock; HandleCommand := On; end;
     cmInsertDate, cmInsertTime: InsertDateTime(Event.Command = cmInsertTime);
     cmStartSearch: begin ChangeLine; StartSearch(Off); ChangeLine end;
     cmReplace: begin ChangeLine; StartSearch(On); ChangeLine end;
     cmUndo: begin MakeUndo; HandleCommand := On end;
     cmIndentBlock: begin UnMark := On; IndentBlock(On) end;
     cmUnIndentBlock: begin UnMark := On; UnIndentBlock(On) end;
     cmFRight, cmFLeft, cmFJustify, cmFCenter:
              begin FormatBlock(Event.Command) end;
     cmLRight, cmLLeft, cmLJustify, cmLCenter:
              begin ChangeLine;
                    Mark.A := Delta; Mark.B := Delta;
                    Mark.A.X := 0; Mark.B.X := Length(GetLine(Delta.Y));
                    Sel := Mark; BlockVisible := On;
                    FormatBlock(Event.Command) end;
     cmPrintBlock: Print(On);
     cmPrintFile: Print(Off);
     cmBracketPair: begin
                      ChangeLine;
                      if (LastX < WL) then
                        if (WorkString[LastX+1] in ['[', '{', '(']) then SearchFwd
                             else if (WorkString[LastX+1] in [')', '}', ']']) then SearchBwd;
                    end;
  end;
end;


end.




