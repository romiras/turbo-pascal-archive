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

unit Macro;

interface
uses Advance, Objects, Views;

type
     PEditMacros = ^TEditMacros;
     TEditMacros = object(TObject)
       Name: PString;
       Commands: PCollection;
       constructor Init(S: String; var F: PTextReader);
       procedure Play(Editor: PView);
       destructor Done; virtual;
     end;

     PMacroCommand = ^TMacroCommand;
     TMacroCommand = object(TObject)
       Command: Integer;
       Repetitions: Integer;
       constructor Init(ACommand, ARepetitions: Word);
       procedure ExecCommand(Editor: PView); virtual;
     end;

     PMacroGoto = ^TMacroGoto;
     TMacroGoto = object(TMacroCommand)
       procedure ExecCommand(Editor: PView); virtual;
     end;

     PMacroMark = ^TMacroMark;
     TMacroMark = object(TMacroCommand)
       Mark: Boolean;
       constructor Init(AN: Integer; AMark: Boolean);
       procedure ExecCommand(Editor: PView); virtual;
     end;

     PMacroString = ^TMacroString;
     TMacroString = object(TMacroCommand)
       S: PString;
       constructor Init(const AString: String; ARepetitions: Word);
       procedure ExecCommand(Editor: PView); virtual;
       destructor Done; virtual;
     end;

      PIDCollection = ^TIDCollection;
      TIDCollection = object(TSortedCollection)
        function Compare(P1, P2: Pointer): Integer; virtual;
      end;


procedure EditDOSEvironment(Env: PByteArray);
procedure InitEditorHighLight(const FName: String; Editor: PView);

implementation
uses Messages, Microed, Drivers, Dialogs, Commands, DNHelp, DNApp,
     RStrings, Startup;


type
      PLngWord = ^TLngWord;
      TLngWord = object(TObject)
        Name: String[30];
        L: Word;
        constructor Init(AL: Word; const AName: String);
      end;


function Token(const S: String; var Pos: Integer): String;
  var A: String;
      B, Cmd: Boolean;
      M: String;
      J: Integer;
begin
   Token := ''; A := ''; B := False; Cmd := Off;
   while (S[Pos] = ' ') and (Length(S) >= Pos) do Inc(Pos);
   while Pos <= Length(S) do
     begin
       case S[Pos] of
         '''': if (S[Pos+1] = '''') and B and (Pos < Length(S)) then
                                      begin Inc(Pos); AddStr(A, '''') end
                  else B := not B;
         ',',' ': if not B or Cmd then Break
                    else if B then AddStr(A, S[Pos]);
         '^': if B then AddStr(A, S[Pos])
                else begin
                       Inc(Pos);
                       AddStr(A, Char(Byte(UpCase(S[Pos]))-64));
                     end;
         '#': if B then AddStr(A, S[Pos])
                else begin
                       J := 1; M := '';
                       repeat
                         Inc(Pos);
                         AddStr(M, S[Pos]);
                       until not (S[Pos+1] in ['0'..'9']) or (Pos >= Length(S));
                       AddStr(A, Char(StoI(M)));
                     end;
           else if B then AddStr(A, S[Pos])
                  else begin
                         B := On; Cmd := On;
                         AddStr(A, S[Pos])
                       end;
       end;
       Inc(Pos);
     end;
   Inc(Pos);
   Token := A;
end;


function TIDCollection.Compare;
begin
   if PLngWord(P1)^.Name > PLngWord(P2)^.Name then Compare := 1 else
     if PLngWord(P1)^.Name < PLngWord(P2)^.Name then Compare := -1 else
       Compare := 0;
end;

constructor TLngWord.Init;
begin
  Name := AName; UpStr(Name);
  L := AL;
end;


constructor TEditMacros.Init;
  var
      I,J: Integer;
      IDs: PIDCollection;
      Error: Boolean;

   function GetId(const S: String): LongInt;
     var T: TLngWord;
         I: Integer;
         L: LongInt;
   begin
     FreeStr := S; DelRight(FreeStr);
     if S[Length(S)] = ',' then Dec(FreeStr[0]);
     DelRight(FreeStr);
     T.Init(0, FreeStr);
     if IDs^.Search(@T, I) then
        begin
          GetID := PLngWord(IDS^.At(I))^.L;
        end else
        begin
          Val(FreeStr, L, I);
          {if I > 0 then MessageBox(^M^C'Unknown identifier ('+FreeStr+')', nil, mfError+mfOKButton);}
          GetID := L;
        end;
   end;

   function Found(const SS: String): Boolean;
   begin
     if UpStrg(Copy(S, 1, Length(SS))) = SS then
       begin
         Found := On;
         Delete(S, 1, Length(SS));
         DelLeft(S);
       end else Found := Off;
   end;

   procedure MakePrint;
   begin
     Commands^.Insert(New(PMacroString, Init(Token(S, I), GetID(Token(S, I)))));
   end;

   procedure MakeGotoXY(X,Y: Integer);
   begin
     Commands^.Insert(New(PMacroGoto, Init(X, Y)));
   end;

  procedure MakeIDs;

    procedure Add(N: Word; const S: String);
    begin IDs^.Insert(New(PLngWord, Init(N, S))) end;

  begin
    Add(cmSaveText            ,'SaveText');
    Add(cmLoadText            ,'LoadText');
    Add(cmSaveTextAs          ,'SaveTextAs');
    Add(cmSwitchBlock         ,'SwitchBlock');
    Add(cmSwitchIndent        ,'SwitchIndent');
    Add(cmSwitchFill          ,'SwitchFill');
    Add(cmSwitchBack          ,'SwitchBack');
    Add(cmSwitchSave          ,'SwitchSave');

    Add(cmWordLeft            ,'WordLeft');
    Add(cmWordRight           ,'WordRight');
    Add(cmDelWordRight        ,'DelWordRight');
    Add(cmDelWordLeft         ,'DelWordLeft');
    Add(cmScrollUp            ,'ScrollUp');
    Add(cmScrollDn            ,'ScrollDn');
    Add(cmCenter              ,'Center');
    Add(cmStartSearch         ,'StartSearch');
    Add(cmContSearch          ,'ContSearch');
    Add(cmDelBackChar         ,'DelBackChar');
    Add(cmDelChar             ,'DelChar');
    Add(cmSwitchIns           ,'SwitchIns');
    Add(cmPgUp                ,'PgUp');
    Add(cmPgDn                ,'PgDn');
    Add(cmMoveUp              ,'MoveUp');
    Add(cmMoveLeft            ,'MoveLeft');
    Add(cmMoveRight           ,'MoveRight');
    Add(cmMoveDown            ,'MoveDown ');
    Add(cmBlockStart          ,'BlockStart');
    Add(cmBlockEnd            ,'BlockEnd');
    Add(cmMarkWord            ,'MarkWord');
    Add(cmMarkLine            ,'MarkLine');
    Add(cmBlockRead           ,'BlockRead');
    Add(cmBlockWrite          ,'BlockWrite');
    Add(cmBlockPrint          ,'BlockPrint');
    Add(cmIndentBlock         ,'IndentBlock');
    Add(cmUnIndentBlock       ,'UnIndentBlock');
    Add(cmTab                 ,'Tab');
    Add(cmPlaceMarker         ,'PlaceMarker');
    Add(cmGoToMarker          ,'GoToMarker');
    Add(cmSpecChar            ,'SpecChar');
    Add(cmReplace             ,'Replace');
    Add(cmEnd                 ,'End');
    Add(cmEnter               ,'Enter');
    Add(cmInsLine             ,'InsLine');
    Add(cmFJustify            ,'FJustify');
    Add(cmFCenter             ,'FCenter');
    Add(cmFLeft               ,'FLeft');
    Add(cmFRight              ,'FRight');
    Add(cmLJustify            ,'LJustify');
    Add(cmLCenter             ,'LCenter');
    Add(cmLLeft               ,'LLeft');
    Add(cmLRight              ,'LRight');
    Add(cmDeltoEOLN           ,'DeltoEOLN');
    Add(cmSetMargins          ,'SetMargins');
    Add(cmCtrlHome            ,'CtrlHome');
    Add(cmCtrlEnd             ,'CtrlEnd');
    Add(cmSwitchHighLight     ,'SwitchHighLight');
    Add(cmGotoLineNumber      ,'GotoLineNumber');
    Add(cmSwitchWrap          ,'SwitchWrap');
    Add(cmSwitchHiLine        ,'SwitchHiLine');
    Add(cmSwitchHiColumn      ,'SwitchHiColumn');
    Add(cmUpString            ,'UpString');
    Add(cmLowString           ,'LowString');
    Add(cmCapString           ,'CapString');
    Add(cmUpcaseBlock         ,'UpBlock');
    Add(cmLowcaseBlock        ,'LowBlock');
    Add(cmCapitalizeBlock     ,'CapBlock');
    Add(cmInsertTime          ,'InsertTime');
    Add(cmInsertDate          ,'InsertDate');
    Add(cmSortBlock           ,'SortBlock');
    Add(cmCalcBlock           ,'CalcBlock');
    Add(cmCopyBlock           ,'CopyBlock');
    Add(cmMoveBlock           ,'MoveBlock');
    Add(cmHideBlock           ,'HideBlock');
    Add(cmMoveBlockStart      ,'MoveBlockStart');
    Add(cmMoveBlockEnd        ,'MoveBlockEnd');
    Add(cmInsertOn            ,'InsertOn');
    Add(cmInsertOff           ,'InsertOff');
    Add(cmIndentOn            ,'IndentOn');
    Add(cmIndentOff           ,'IndentOff');
  end;

begin
  inherited Init;
  New(Commands, Init(10,10));
  New(IDs, Init(100,10));
  MakeIds;
  while (S <> '') and (S[1] = ' ') do Delete(FreeStr, 1, 1);
  if S = '' then S := '0';
  Name := NewStr(S);
  while not F^.EOF do
    begin
      S := F^.GetStr;
      DelRight(S);
      DelLeft(S);
      if (S[1] <> ';') and (S <> '') then
        begin
          I := 1;
          if Found('ENDMACRO') then Break;
            if Found('PRINT ') then MakePrint else
            if Found('GOTOXY ') then MakeGotoXY(GetID(Token(S,I)), GetID(Token(S,I))) else
            if Found('GOTOX ') then MakeGotoXY(GetID(Token(S,I)), -1) else
            if Found('GOTOY ') then MakeGotoXY(-1, GetID(Token(S,I))) else
            if Found('GOTO ') then Commands^.Insert(New(PMacroMark, Init(GetID(Token(S,I)), Off))) else
            if Found('MARK ') then Commands^.Insert(New(PMacroMark, Init(GetID(Token(S,I)), On))) else
              begin
                J := GetId(Token(S,I));
                if J > 0 then
                    Commands^.Insert(New(PMacroCommand, Init(J, GetID(Token(S,I)))));
              end;
        end;
    end;
  Dispose(Ids, Done);
end;

procedure TEditMacros.Play;
  procedure DoPlay(P: PMacroCommand); far;
  begin
    P^.ExecCommand(Editor);
  end;
begin
  Commands^.ForEach(@DoPlay);
end;

destructor TEditMacros.Done;
begin
  DisposeStr(Name);
  Dispose(Commands, Done);
end;

constructor TMacroCommand.Init;
begin
  inherited Init;
  Command := ACommand; Repetitions := ARepetitions;
end;

procedure TMacroCommand.ExecCommand;
  var I: Integer;
begin
  for I := 1 to Max(1, Repetitions) do
    Message(Editor^.Owner, evCommand, Command, nil);
end;

procedure TMacroGoto.ExecCommand;
begin
  if (Command < 0) then PFileEditor(Editor)^.ScrollTo(PFileEditor(Editor)^.Delta.X, Repetitions) else
   if (Repetitions < 0) then PFileEditor(Editor)^.ScrollTo(Command, PFileEditor(Editor)^.Delta.Y) else
     PFileEditor(Editor)^.ScrollTo(Command, Repetitions);
end;


constructor TMacroMark.Init;
begin
  TObject.Init;
  Command := Max(1, Min(AN, 9));
  Mark := AMark;
end;

procedure TMacroMark.ExecCommand;
begin
  if Mark then
   with PFileEditor(Editor)^ do
     MarkPos[Char(Command+48)] := Delta else
   with PFileEditor(Editor)^ do
     ScrollTo(MarkPos[Char(Command+48)].X, MarkPos[Char(Command+48)].Y);
end;

constructor TMacroString.Init;
begin
  TObject.Init;
  S := NewStr(AString);
  Repetitions := ARepetitions;
end;

procedure TMacroString.ExecCommand;
  var I,J: Integer;
begin
  if S = nil then Exit;
  for J := 1 to Max(1, Repetitions) do
    for I := 1 to Length(S^) do
      Message(Application, evKeyDown, Word(S^[I]), nil);
end;

destructor TMacroString.Done;
begin
  DisposeStr(S);
end;

{---------------------------- EditDOSEvironment -----------------------------}

type
     PDOSVar = ^TDOSVar;
     TDOSVar = object(TObject)
       Name,
       Value: PString;
       constructor Init(const S: String);
       procedure SetValue(const S: String);
       destructor Done; virtual;
     end;

     PVarList = ^TVarList;
     TVarList = object(TListBox)
       Line: PInputLine;
       PrevFocused: Integer;
       procedure FocusItem(Item: Integer); virtual;
       function GetText(Item: Integer; MaxLen: Integer): String; virtual;
       procedure HandleEvent(var Event: TEvent); virtual;
     end;

{ TDOSVar }

constructor TDOSVar.Init;
  var I:Integer;
begin
  inherited Init;
  I := PosChar('=', S);
  if I = 0 then I :=Length(S) + 1;
  Name := NewStr(UpStrg(DelSpaces(Copy(S, 1, I-1))));
  Value := NewStr(Copy(S, I+1, 255));
end;

procedure TDOSVar.SetValue;
begin
   if (S = '') and (Value = nil) then Exit;
   if (Value = nil) or (Value^[0] <> S[0]) then
     begin
       DisposeStr(Value);
       Value := NewStr(S);
     end else Value^ := S;
end;

destructor TDOSVar.Done;
begin
  DisposeStr(Name);
  DisposeStr(Value);
  inherited Done;
end;


{ TVarList }

procedure TVarList.FocusItem;
  var P: PDOSVar;
begin
  if Line <> nil then Line^.GetData(FreeStr);
  if (PrevFocused >= 0) and
     (List <> nil) and (Focused < List^.Count) then P := List^.At(Focused)
                                               else P := nil;
  if P <> nil then P^.SetValue(FreeStr);
  PrevFocused := Focused;
  inherited FocusItem(Item);
  if (List <> nil) and (Focused < List^.Count) then P := List^.At(Focused)
                                               else P := nil;
  if (P <> nil) and (P^.Value <> nil) then FreeStr := P^.Value^
                                      else FreeStr := '';
  if (Line <> nil) then
    begin
       Line^.SetData(FreeStr);
       Line^.DrawView;
    end;
end;

function TVarList.GetText;
  var P: PDOSVar;
begin
  P := List^.At(Item);
  if P <> nil then GetText := CnvString(P^.Name)
              else GetText := '';
end;

procedure TVarList.HandleEvent;
  var P: PDOSVar;

  procedure DeleteVar;
  begin
    if (P <> nil) and (MessageBox(GetString(dlEnvDelConfirm),
                                   @P^.Name, mfYesNoConfirm) = cmYes) then
      begin
        PrevFocused := -1;
        List^.AtFree(Focused);
        SetRange(List^.Count);
        FocusItem(Focused);
      end;
    ClearEvent(Event);
    DrawView;
  end;

  procedure AppendVar;
    var S: String;
  begin
    ClearEvent(Event);
    S := '';
    if InputBox(GetString(dlEnvAddTitle), GetString(dlEnvVariable), S, 255, hsNewVariable) <> cmOK then Exit;
    PrevFocused := -1;
    List^.AtInsert(Focused, New(PDosVar, Init(S)));
    SetRange(List^.Count);
    FocusItem(Focused);
    DrawView;
  end;

  procedure RenameVar;
    var S: String;
  begin
    ClearEvent(Event);
    if (P = nil) then Exit;
    S := CnvString(P^.Name);
    FormatStr(FreeStr, GetString(dlEnvRenVar), P^.Name);
    if InputBox(FreeStr, GetString(dlFCRenameNew), S, 255, hsNewVariable) <> cmOK then Exit;
    UpStr(S);
    DisposeStr(P^.Name); P^.Name := NewStr(S);
    DrawView;
  end;


begin
  inherited HandleEvent(Event);
  if (List <> nil) and (Focused < List^.Count) then P := List^.At(Focused)
                                               else P := nil;
  case Event.What of
     evCommand: case Event.Command of
                  cmOK: begin
                           if Line <> nil then Line^.GetData(FreeStr);
                           if P <> nil then P^.SetValue(FreeStr);
                        end;
                  cmAddVariable: AppendVar;
                  cmRenVariable: RenameVar;
                  cmDelVariable: DeleteVar;
                end;
     evBroadcast: case Event.Command of
                    cmOK: AppendVar;
                    cmNo: DeleteVar;
                    cmYes: RenameVar;
                  end;
  end;
end;


procedure EditDOSEvironment;
var D: PDialog;
    P: PView;
    R: TRect;
    PC: PCollection;
    I: Integer;

   procedure MakeDialog;
   var
     R: TRect;
     Control, Labl, Histry : PView;
     PL: PVarList;
     PI: PInputLine;
     function IsInputLine( P: PView ): boolean; far;
     begin
       IsInputLine := TypeOf( P^ ) = TypeOf( TInputLine )
     end;
     function IsButton( P: PView ): boolean; far;
     begin
       IsButton:= TypeOf( P^ ) = TypeOf( TButton )
     end;
   begin
     D := PDialog( LoadResource( dlgEditEnvironment ));
     Control := D^.FirstThat( @IsButton );

     R.A.X := Control^.Origin.X - 1;
     R.B.X := R.A.X + 1;
     R.A.Y := 3;
     R.B.Y := 14;
     Control := New(PScrollbar, Init(R));
     D^.Insert(Control);

     R.B.X := R.A.X;
     R.A.X := 3;

     PL := New( PVarList, Init( R, 1, PScrollbar( Control )));
     D^.Insert( PL );

     PI := PInputLine( D^.FirstThat( @IsInputLine ));

     R.Assign(2,2,43,3);
     Labl := New(PLabel, Init(R, GetString(dlEnvVarLabel), PL));
     D^.Insert(Labl);

     PL^.Options := PL^.Options or ofPostProcess;
     PL^.PrevFocused := -1;
     PL^.Line := PI;
     PL^.NewList(PC);
   end;

   procedure DoPut(P: PDosVar); far;
   var J: Integer;

   procedure Put(C: Char);
   begin
     Env^[I] := Byte(C);
     Inc(I);
   end;

   begin
     if (P^.Name <> nil) and (P^.Value <> nil) then begin
       for J := 1 to Length(P^.Name^) do Put(P^.Name^[J]);
       Put('=');
       for J := 1 to Length(P^.Value^) do Put(P^.Value^[J]);
       Put(#0);
     end;
   end;

begin
  New( PC, Init( 10, 10 ));

  I := 0;
  while Env^[I] <> 0 do begin
    FreeStr := '';
    while Env^[I] <> 0 do begin AddStr(FreeStr, Char(Env^[I])); Inc(I) end;
    PC^.Insert(New(PDosVar, Init(FreeStr)));
    Inc(I);
  end;

  MakeDialog;

  if Desktop^.ExecView(D) = cmOK then begin
    I := 0;
    PC^.ForEach(@DoPut);
    Env^[I] := 0;
    Env^[I+1] := 0;
    Env^[I+2] := 0;
    Env^[I+3] := 0;
    Env^[I+4] := 0;
    Env^[I+5] := 0;
  end;

  Dispose( D, Done );
  Dispose( PC, Done );
end;

procedure InitEditorHighLight;
label 1;
var F: PTextReader; I: Integer;

  function Found(const S: String): Boolean;
  begin
    if Copy(FreeStr, 1, Length(S)) = S then
      begin
        Found := On;
        Delete(FreeStr, 1, Length(S));
        DelLeft(FreeStr);
      end else Found := Off;
  end;

  procedure InsertMacro;
    var P: PEditMacros;
  begin
     New(P, Init(FreeStr, F));
     if (P^.Commands^.Count = 0) or (PFileEditor(Editor)^.Macros^.IndexOf(P)>=0) then Dispose(P, Done)
       else PFileEditor(Editor)^.Macros^.Insert(P);
  end;

  function IsOn: Boolean;
  begin
    IsOn := (FreeStr = 'YES') or (FreeStr = 'ON');
  end;

  procedure MakeValue(var V: Integer);
    var J: Integer;
  begin
     System.Val(FreeStr, J, I);
     if (J >= 0) and (I = 0) then V := J;
  end;

  procedure MakeDefaults;
  begin
    with PFileEditor(Editor)^ do
    While not F^.EOF do
     begin
       FreeStr := F^.GetStr;
       DelRight(FreeStr);
       DelLeft(FreeStr);
       UpStr(FreeStr);
       if (FreeStr <> '') then
          if Found('FILES ') or Found('END') then Break;
          if Found('MACRO ') then InsertMacro else
          if Found('COMMENT ') then
             while (NumCommentChars < 5) and (FreeStr <> '') do
               begin
                 Inc(NumCommentChars);
                 CommentChars[NumCommentChars] := FreeStr[1];
                 DelFC(FreeStr);
               end else
          if Found('COMMENTSTART ') then
             while (NumCommentStartChars < 5) and (FreeStr <> '') do
               begin
                 Inc(NumCommentStartChars);
                 CommentStartChars[NumCommentStartChars] := FreeStr[1];
                 DelFC(FreeStr);
               end else
          if Found('COMMENTSTRING ') then
             while (NumCommentStrings < 5) and (FreeStr <> '') do
               begin
                 Inc(NumCommentStrings);
                 I := PosChar(',', FreeStr); if I < Length(FreeStr) then I := Length(FreeStr)+1;
                 CommentStrings[NumCommentStrings] := Copy(FreeStr,1,I-1);
                 Delete(FreeStr, 1, I);
                 DelLeft(FreeStr);
               end else
          if Found('KEYWORDS1 ') then KeyWords1 := FreeStr else
          if Found('KEYWORDS2 ') then KeyWords2 := FreeStr else
          if Found('STRONG_KEYWORDS') then StrongKeywords := On else
          if Found('COMMENTS_ONLY') then CommentsOnly := On else
          if Found('C_COMMENTS') then C_Comments := On else
          if Found('X_COMMENTS') then X_Comments := On else
          if Found('PAS_COMMENTS') then Pas_Comments := On else
          if Found('HIGHLIGHT ') then HiLite := Byte(IsOn) else
          if Found('AUTOINDENT ') then AutoIndent := IsOn else
          if Found('AUTOBRACKETS ') then AutoBrackets := IsOn else
          if Found('BACKUNINDENTS ') then BackIndent := IsOn else
          if Found('H_LINE ') or Found('H_ROW ') then HiliteLine := IsOn else
          if Found('H_COLUMN ') then HiliteColumn := IsOn else
          if Found('AUTOWRAP ') then AutoJustify := IsOn else
          if Found('WRAPJUSTIFY ') then AutoWrap := IsOn else
          if Found('LEFTMARGIN ') then MakeValue(LeftSide) else
          if Found('RIGHTMARGIN ') then MakeValue(RightSide) else
          if Found('PARAGRAPH ') then MakeValue(InSide) else
          if Found('FORCECRLF ') then ForcedCrLf := cfCRLF else
          if Found('FORCECR ') then ForcedCrLf := cfCR else
          if Found('FORCELF ') then ForcedCrLf := cfLF else
          ;
     end;
  end;

begin
  with PFileEditor(Editor)^ do
    begin
      HiLite := 0;
      Macros^.FreeAll;
      FillChar(KeyWords1, SizeOf(KeyWords1)*2+
                          SizeOf(NumCommentStrings)+
                          SizeOf(CommentStrings)+
                          SizeOf(NumCommentChars)+
                          SizeOf(CommentChars)+
                          SizeOf(CommentsOnly)+
                          SizeOf(NumCommentStartChars)+
                          SizeOf(CommentStartChars)+
                          SizeOf(StrongKeywords)+
                          SizeOf(C_Comments)+
                          SizeOf(Pas_Comments), 0);
      F := New(PTextReader, Init(SourceDir+'DN.HGL'));
      if F = nil then Exit;


      While not F^.EOF do
       begin
         FreeStr := F^.GetStr;
         DelRight(FreeStr);
         DelLeft(FreeStr);
         UpStr(FreeStr);
         if (FreeStr <> '') and (FreeStr[1] <> ';') then
            if Found('FILES ') and InFilter(FName, FreeStr) then
              begin
                HiLite := 1;
                MakeDefaults;
                Break;
              end else
            if Found('DEFAULT') then MakeDefaults;
       end;
      Dispose(F, Done);
    end;
end;





end.