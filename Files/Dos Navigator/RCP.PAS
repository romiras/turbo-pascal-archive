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


PROGRAM RCP;

{                                     }
{  Dos Navigator's Resource Compiler  }
{                                     }

USES
  Dos, Objects, Advance, RStrings, GetConst, Drivers, Menus, Commands, Setups,
  DNHelp, Views, DNApp, Startup, Dialogs, ColorSel, Validate, IniFiles, Scroller;

CONST
  tidCommands = 'cm'#0'cd'#0;
  tidHelpCtx = 'hc'#0;
  tidHistory = 'hs'#0;
  tidKbdconst = 'kb'#0;
  tidOptions = 'of'#0;
  tidDLGs = 'TDlgIdx';
  tidDLs = 'TStrIdx';

VAR
  Types: PValuesHolder;
  LngFileName: String;
  OutLngFileName: String;
  DlgFileName: String;
  OutDlgFileName: String;
  OutDir: String;
  DLStream: TBufStream;

PROCEDURE Error( S: String );
begin
  WriteLn( #13, S );
  Halt( 1 );
end;

FUNCTION RemoveLeadSpaces(S: String ): String;
begin
  DelLeft(S); RemoveLeadSpaces := S;
end;

const BreakChars = [ #9, #10, #13, #12, ' ', #0 ];

function wSkipBlank( const S: String; I: Integer ): Integer; near;
var
  L: Byte absolute S;
begin
  While ( I <= L ) and ( S[ I ] in BreakChars ) do Inc( I );
  wSkipBlank := I;
end;

function wSkipText( const S: String; I: Integer ): Integer; near;
var
  L: Byte absolute S;
begin
  While ( I <= L ) and not ( S[ I ] in BreakChars ) do Inc( I );
  wSkipText := I;
end;

FUNCTION  SeekWord( const S: String; No: Integer): Integer; { Pos of word #No in S }
var
  I: Integer;
  L: Byte absolute S;
begin
  I := 1; SeekWord := 0;
  If No >= 1 then
    repeat
      I := wSkipBlank( S, I ); If I > L then Break;
      Dec( No );
      If No <= 0 then begin
        SeekWord := I;
        Break;
      end;
      I := wSkipText( S, I ); If I > L then Break;
    until False;
end;

FUNCTION  GetWord( S: String; No: Integer): String;   { Word #No of S }
var
  I: Integer;
  L: Byte absolute S;
begin
  I := SeekWord( S, No );
  If I > 0 then begin
    If I > 1 then begin
      Dec( L, I - 1 );
      Move( S[ I ], S[ 1 ], L );
    end;
    L := wSkipText( S, 1 ) - 1;
    GetWord := S;
  end else
    GetWord := '';
end;

PROCEDURE ProcessDLs( Enable: Boolean );
var
  DLs: PTypeHolder;
  SLM: PStrListMaker;
  Fail: Boolean;
  F: Text;
  S, S1: String;
  P: PLngWord;
  function DoSeekID( P: PLngWord ): boolean; far;
  begin
    DoSeekID := P^.Name = S1
  end;
  procedure DoTest( P: PLngWord ); far;
  begin
    If P^.Mark = 0 then begin
      WriteLn( 'Unresolved identifier "' + P^.Name + '"' );
      Fail := True;
    end;
  end;
  function MakeStr( S: String ): String;
  label 1;
  var
    A,M: String;
    I,J: Integer;
    B: Boolean;
    NotFlag: Boolean;
  begin
    MakeStr := '';
    DelLeft(S);
    if S = '' then Exit;
    I := 0;
    B := Off;
    A := '';
  1:
    while I < Length(S) do
      begin
        Inc(I);
        case S[I] of
          '''': if (S[I+1] = '''') and B and (I < Length(S)) then
                                       begin Inc(I); AddStr(A, '''') end
                   else B := not B;
          '^': if B then AddStr(A, S[I])
                 else begin
                        Inc(I);
                        AddStr(A, Char(Byte(UpCase(S[I]))-64));
                      end;
          '#': if B then AddStr(A, S[I])
                 else begin
                        J := 1; M := '';
                        repeat
                          Inc(I);
                          AddStr(M, S[I]);
                        until not (S[I+1] in ['0'..'9']) or (I >= Length(S));
                        AddStr(A, Char(StoI(M)));
                      end;
            else if B then AddStr(A, S[I]);
        end;
      end;
   if S[Length(S)] = '+' then
        begin
          ReadLn(F, S);
          DelLeft(S);
          I := 0;
          Goto 1;
        end;
   If Pos( ^Z, UpStrg( A )) = 1
     then A := RemoveLeadSpaces( Copy( A, 2, 255 ));
   MakeStr := A;
  end;
begin
  If Enable then begin
    DLs := Types^.GetType( tidDLs );
    New(SLM, Init($FFF0,$280));
    Assign( F, LngFileName ); Reset( F );
    If IOResult <> 0 then Error( 'Cannot open file ' + LngFileName );
    WriteLn( 'Reading ', LngFileName );
    While not EOF( F ) do begin
      ReadLn( F, S );
      S := RemoveLeadSpaces( S );
      S1 := GetWord( UpStrg( S ), 1 );
      While ( S1[ Length( S1 )] = ',' ) and ( S1 <> '' ) do Dec( S1[ 0 ] );
      If ( S1 = '' ) or ( S1[ 1 ] = ';' ) then Continue;
      P := DLs^.FirstThat( @DoSeekID );
      If P = NIL then Error( 'Unknown identifier "' + GetWord( S, 1 ) + '"' );
      If P^.Mark = 1 then Error( 'Duplicate identifier "' + GetWord( S, 1 ) + '"' );
      SLM^.Put( P^.L, MakeStr( S ));
      P^.Mark := 1;
    end;
    Close( F );
    Fail := False; DLs^.ForEach( @DoTest ); If Fail then Halt( 1 );
    DLStream.Init( OutLngFileName, stCreate, 512 );
    If DLStream.Status <> stOK then Error( 'Cannot create file ' + OutLngFileName );
    WriteLn( 'Writing ', OutLngFileName );
    DLStream.Put( SLM );
    If DLStream.Status <> stOK then begin
      DLStream.Done;
      EraseFile( OutLngFileName );
      Error( 'Error writing file ' + OutLngFileName );
    end else
      DLStream.Done;
    Dispose( SLM, Done );
  end;
  ReRegisterType( RStringList );
  DLStream.Init( OutLngFileName, stOpenRead, 512 );
  LStringList := PStringList( DLStream.Get );
  If LStringList = NIL then begin
    DLStream.Done;
    EraseFile( OutLngFileName );
    Error( 'Error reading file ' + OutLngFileName );
  end;
end;

type
  TEditCommand = record
    C,C1,C2: Word;
    CC1, CC2: Array[1..2] of Char;
  end;

{                            Resource Processing
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
VAR
  S: String;
  F: Text;
  Line: LongInt;
  IDs: PTypeHolder;
  DLGs: PTypeHolder;

CONST
  idSubMenu      =  'SUBMENU ';
  idMenuItem     =  'MENUITEM ';
  idMenuLine     =  'MENULINE';
  idMenu         =  'MENU ';
  idEND          =  'END';
  idStatusDef    =  'STATUSDEF ';
  idStatusItem   =  'STATUSITEM ';
  idStatusLine   =  'STATUSLINE';
  idDialog       =  'DIALOG ';
  idLabel        =  'LABEL ';
  idInputLine    =  'INPUTLINE ';
  idButton       =  'BUTTON ';
  idCheckBoxes   =  'CHECKBOXES ';
  idRadioButtons =  'RADIOBUTTONS ';
  idHistory      =  'HISTORY ';
  idItem         =  'ITEM ';
  idHelpCtx      =  'HELPCTX ';
  idStaticText   =  'STATICTEXT ';
  idListBox      =  'LISTBOX ';
  idScrollBar    =  'SCROLLBAR ';
  idMScrollBar   =  'MOUSESCROLLBAR ';
  idParamText    =  'PARAMTEXT ';
  idColorGroup   =  'COLORGROUP ';
  idColorItem    =  'COLORITEM ';
  idColorDialog  =  'COLORDIALOG';
  idUpperTable   =  'UPPERTABLE ';
  idSelectBack   =  'SELECTBACK';
  idSelectForward=  'SELECTFORWARD';
  idCommand      =  'COMMAND ';
  idEditorCommands = 'EDITOR COMMANDS';
  idDriveCheckBox  = 'DRIVECHECKBOXES ';

  TheRF: PIdxMaker = nil;

VAR
  D: PColorDialog;
  PL, PP: PColorGroup;
  PI: PColorItem;
  I: Integer;
  NumCommands: Integer;

const
  MaxCommands = 100;

var
  EditCommands : Array [1..MaxCommands] of TEditCommand;

type
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

constructor TEditSaver.Load(var S: TStream);
begin
  S.Read(NumCommands, SizeOf(NumCommands));
  S.Read(EditCommands, SizeOf(EditCommands));
end;

procedure TEditSaver.Store(var S: TStream);
begin
  S.Write(NumCommands, SizeOf(NumCommands));
  S.Write(EditCommands, SizeOf(EditCommands));
end;

FUNCTION FSetExt( F: String; NewExt: String ): String;
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
begin
  FSplit( F, Dir, Name, Ext );
  FSetExt := Dir + Name + NewExt;
end;

procedure StoreResource( P: PObject; ID: TDlgIdx );
var W: PLngWord;
  function HaveThisID( P: PLngWord ): boolean; far;
  begin
    HaveThisID := TDlgIdx( P^.L ) = ID
  end;
begin
  W := DLGs^.FirstThat( @HaveThisID );
  If W = NIL then Error( '*ERROR*: Index #' + ItoS( Word( ID )) + ' out of range.' );
  If ( TheRF^.Empty( TDlgIdx( ID ))) and ( W^.Mark = 0 )
    then TheRF^.Put( P, TDlgIdx( ID ))
    else Error( #13'*ERROR*: Duplicate definition for "' + W^.Name + '"' );
  W^.Mark := 1;
end;

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
       if I > 0 then
         Error('Unknown identifier ('+FreeStr+') in line '+ItoS(Line));
       GetID := L;
     end;
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
         ',': if not B or Cmd then Break else AddStr( A, S[Pos] );
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

procedure MakeGroup;
 var P: PColorGroup;
begin
  I := Length(idColorGroup);
  P := ColorGroup(Token(S, I), nil, nil);
  if PL = nil then PP := P
              else PL^.Next := P;
  PL := P;
  PI := nil;
end;

procedure MakeItem;
  var P: PColorItem;
begin
   if PL = nil then Error('Color group should be defined first');
   I := Length(idColorItem);
   P := ColorItem(Token(S, I), GetID(Token(S, I)), nil);
   if PI = nil then PL^.Items := P
               else PI^.Next := P;
   PI := P;
end;

procedure MakeColorDialog;
begin
  PI := nil; PL := nil; PP := nil;
  while not EOF(F) do
   begin
     ReadLn(F, S);
     Inc(Line);
     DelLeft(S);
     FreeStr := UpStrg(S);
     if (S <> '') and (S[1] <> ';') then
       if Copy(FreeStr, 1, Length(idColorGroup)) = idColorGroup then MakeGroup else
       if Copy(FreeStr, 1, Length(idColorItem)) = idColorItem then MakeItem else
       if Copy(FreeStr, 1, Length(idEND)) = idEND then Break
        else
          Error('Unknown identifier in line '+ItoS(Line));
   end;
 New(D, Init(PP));
 D^.HelpCtx := hcColorDialog;
 StoreResource(D, dlgColors);
 Dispose(D, Done);
end;

procedure MakeEditorCommands;
  var I,J: Integer;
      T: ^TEditSaver;

  procedure MakeCommand;
  begin
    if NumCommands = MaxCommands then
      Error('Editor Commands top limit ('+ItoS(MaxCommands)+') reached');
    Inc(NumCommands);
    I := Length(idCommand);
    with EditCommands[NumCommands] do
      begin
        C := GetID(Token(S, I));
        C1 := GetID(Token(S, I));
        C2 := GetID(Token(S, I));
        FreeStr := Token(S, I)+#0#0;
        Move(FreeStr[1], CC1, 2);
        FreeStr := Token(S, I)+#0#0;
        Move(FreeStr[1], CC2, 2);
      end;
  end;

begin
  FillChar(EditCommands, SizeOf(EditCommands), 0);
  NumCommands := 0;
  while not EOF(F) do
    begin
      ReadLn(F, S);
      Inc(Line);
      DelLeft(S);
      FreeStr := UpStrg(S);
      if (S <> '') and (S[1] <> ';') then
        if Copy(FreeStr, 1, Length(idCommand)) = idCommand then MakeCommand else
        if Copy(FreeStr, 1, Length(idEND)) = idEND then Break
         else Error('Unknown identifier in line '+ItoS(Line));
    end;
   New(T, Init);
   StoreResource( T, dlgEditorCommands );
   T^.Free;
end;

PROCEDURE ProcessDLGs;
var
  tP: PTypeHolder;
  St: PStream;
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
         if I > 0 then Error('Unknown identifier ('+FreeStr+') in line '+ItoS(Line));
         GetID := L;
       end;
  end;
  PROCEDURE SetSavers;
    var D: PDialog;
  begin
    D := MakeSaversDialog;
    StoreResource( D, dlgSaversSetup );
    Dispose( D, Done );
  end;

  function CompileStatus: PStatusDef;
    var
        PM, PL: PStatusItem;
        DM, DL: PStatusDef;
        I,J: Integer;
        S: String;

     procedure MakeStatusDef;
      var P: PStatusDef;
     begin
       I := Length(idStatusDef);
       P := NewStatusDef(GetID(Token(S, I)), GetID(Token(S, I)), nil, nil);
       if DL = nil then DM := P
                   else DL^.Next := P;
       DL := P;
       PL := nil;
     end;

     procedure MakeStatusItem;
       var P: PStatusItem;
     begin
        if DL = nil then Error('Could not make Status Item without Status Definition');
        I := Length(idStatusItem);
        P := NewStatusKey(Token(S, I), GetID(Token(S, I)), GetID(Token(S, I)), nil);
        if PL = nil then DL^.Items := P
                    else PL^.Next := P;
        PL := P;
     end;


  begin
    DM := nil; DL := nil;
    PM := nil; PL := nil;
    while not EOF(F) do
      begin
        ReadLn(F, S);
        Inc(Line);
        DelLeft(S);
        if (S <> '') and (S[1] <> ';') then
         if UpStrg(Copy(S, 1, Length(idStatusDef))) = idStatusDef then MakeStatusDef else
            if UpStrg(Copy(S, 1, Length(idStatusItem))) = idStatusItem then MakeStatusItem else
              if UpStrg(Copy(S, 1, Length(idEND))) = idEND then
                begin
                  Break;
                end else
                 if (S <> '') and (S[1] <> ';') then
                    Error('Unknown identifier in line '+ItoS(Line));
      end;
    CompileStatus := DM;
  end;

  procedure MakeStatus;
   var PM: PStatusDef;
       R: TRect;
  begin
    PM := CompileStatus;
    R.Assign(0,0,80,1);
    StatusLine := New(PStatusLine, Init(R, PM));
    StoreResource(StatusLine, dlgStatusLine);
    Dispose(StatusLine, Done);
    StatusLine := nil;
  end;

  function CompileMenu(S: String): PMenu;
    var PM, PL: PMenuItem;
        S1, S2: String[80];
        I, J: Integer;

    procedure AddItem(P: Pointer);
    begin
      if PM = nil then PM := P
                  else PL^.Next := P;
      PL := P;
    end;

    procedure MakeSubMenu;
    begin
      I := Length(idSubMenu);
      S1 := Token(S, I);
      S2 := Token(S, I);
      AddItem(NewSubMenu(S1, GetID(S2), CompileMenu(S), nil));
    end;

    procedure MakeMenuItem;
      var HK, Cmd, Ctx: Word;
    begin
      I := Length(idMenuItem);
      AddItem(NewItem(Token(S, I), Token(S, I), GetID(Token(S, I)),
                 GetID(Token(S, I)), GetID(Token(S, I)), nil));
    end;

    procedure MakeMenuLine;
    begin
      AddItem(NewLine(nil));
    end;

  begin
    CompileMenu := nil;
    PL := nil; PM := nil;
    while not EOF(F) do
      begin
         ReadLn(F, S);
         Inc(Line);
         DelLeft(S);
         if (S <> '') and (S[1] <> ';') then
           if UpStrg(Copy(S, 1, Length(idSubMenu))) = idSubmenu then MakeSubMenu else
             if UpStrg(Copy(S, 1, Length(idMenuItem))) = idMenuItem then MakeMenuItem else
              if UpStrg(Copy(S, 1, Length(idMenuLine))) = idMenuLine then MakeMenuLine else
                 if UpStrg(S) = idEND then Break else
                   if (S <> '') and (S[1] <> ';') then
                      Error('Unknown identifier in line '+ItoS(Line));
      end;
    CompileMenu := NewMenu(PM);
  end;

  procedure MakeMenu(S: String);
    var ID: TDlgIdx;
        T: TLngWord;
        R: TRect;
        D: PMenuBar;
        I,J: Integer;
  begin
    I := Length(idMenu);
    FreeStr := Token(S, I);
    T.Init(0, FreeStr);
    if not DLGs^.Search(@T, J) then Error('Unknown Resource ID - ' + T.Name);
    ID := TDlgIdx(PLngWord(DLGs^.At(J))^.L);
    New(D, Init(R, CompileMenu(S)));
    StoreResource(D, ID);
    Dispose(D, Done);
  end;

  procedure CompileDialog(S: String);
    var D: PDialog;
        R: TRect;
        I,J: Integer;
        PV: PView;
        LastSB: PScrollBar;


    function IsThis(const S: String): Boolean;
    begin
      I := Length(S);
      IsThis := Copy(FreeStr, 1, I) = S;
    end;

    procedure MakeInputLine;
      var P: PHistory;
    begin
      R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
      R.B.Y := R.A.Y + 1;
      PV := New(PInputLine, Init(R, GetID(Token(S, I))));
      D^.Insert(PV);
      J := GetID(Token(S, I));
      if J > 0 then
        begin
          R.A.X := R.B.X; R.B.X := R.A.X + 3;
          New(P, Init(R, PInputLine(PV), J));
          D^.Insert(P);
        end;
    end;

    procedure MakeLabel;
      var B: String;
          P: PLabel;
    begin
      R.A.X := GetID(Token(S, I));
      R.A.Y := GetID(Token(S, I)); R.B.Y := R.A.Y + 1;
      B := Token(S, I);
      R.B.X := R.A.X + 2 + CStrLen(B);
      New(P, Init(R, B, PV));
      D^.Insert(P);
      while I < Length(S) do
             P^.Options := P^.Options or GetID(Token(S, I));
    end;

    procedure MakeHistory;
      var B: String;
          P: PHistory;
    begin
      R.A.X := GetID(Token(S, I)); R.B.X := R.A.X + 3;
      R.A.Y := GetID(Token(S, I)); R.B.Y := R.A.Y + 1;
      New(P, Init(R, PInputLine(PV), GetID(Token(S, I))));
      D^.Insert(P);
      while I < Length(S) do
             P^.Options := P^.Options or GetID(Token(S, I));
    end;

    function GetItems: PSItem;
      var P,PP: PSItem;
          S: String;
          K: Integer;
    begin
       PP := nil; K := I;
       while not EOF(F) do
        begin
          ReadLn(F, S);
          Inc(Line);
          while (S[1] = ' ') and (S <> '') do Delete(S, 1, 1);
          DelRight(S); FreeStr := S; UpStr(FreeStr);
          if IsThis(idItem) then
            begin
             if PP = nil then begin P := NewSItem(Token(S, I), nil); PP := P end
                         else begin P^.Next := NewSItem(Token(S, I), nil); P := P^.Next end;
            end else if IsThis(idEND) then Break
             else if (S <> '') and (S[1] <> ';') then
                  Error('Unknown identifier in line '+ItoS(Line));
        end;
       GetItems := PP;
       I := K;
    end;

    procedure MakeCheckBoxes;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       PV := New(PCheckBoxes, Init(R, GetItems));
       D^.Insert(PV);
    end;

    procedure MakeDriveCheckBoxes;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       PV := New(PCurrDriveInfo, Init(R, GetItems));
       D^.Insert(PV);
       with PV^ do
        begin
           Options := Options or ofPostProcess;
           EventMask := evBroadcast + evCommand + evKeyDown + evMouseDown;
        end;
    end;

    procedure MakeRadioButtons;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       PV := New(PRadioButtons, Init(R, GetItems));
       D^.Insert(PV);
    end;

    procedure MakeButton;
      var B,K: String;
          Flags, Options: Word;
          CmD: Word;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       K := Token(S, I); Cmd := GetID(Token(S, I)); Flags := 0; Options := 0;
       while I < Length(S) do
          begin
              B := Token(S, I); UpStr(B);
              if B = 'BFDEFAULT' then Flags := Flags or bfDefault else
              if B = 'BFNORMAL' then Flags := Flags or bfNormal else
              if B = 'BFBROADCAST' then Flags := Flags or bfBroadcast else
              if B = 'BFLEFTJUST' then Flags := Flags or bfLeftJust else
              if B = 'BFGRABFOCUS' then Flags := Flags or bfGrabFocus else
                Options := Options or GetID(B);
          end;
       PV := New(PButton, Init(R, K, Cmd, Flags)); PV^.Options := PV^.Options or Options;
       D^.Insert(PV);
    end;

    procedure MakeScrollBar(Mouse: Boolean);
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       if Mouse then LastSB := New(PMouseBar, Init(R))
                else LastSB := New(PScrollBar, Init(R));
       D^.Insert(LastSB);
    end;

    procedure MakeListBox;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       PV := New(PListBox, Init(R, GetID(Token(S, I)), LastSB));
       D^.Insert(PV);
    end;

    procedure MakeStaticText;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       PV := New(PStaticText, Init(R, Token(S, I)));
       D^.Insert(PV);
    end;

    procedure MakeUpperTable;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       PV := New(PUpperTable, Init(R));
       D^.Insert(PV);
    end;

    procedure MakeParamText;
    begin
       R.Assign(GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)), GetID(Token(S, I)));
       PV := New(PParamText, Init(R, Token(S, I), GetID(Token(S, I))));
       D^.Insert(PV);
    end;

    var ID: TDlgIdx;
        T: TLngWord;

    const
        DData: TSysData = (
            Options: 0;
            Mode1: '';
            Mode2: '';
            Drives: ( List: NIL; Focus: 0 );
            Current: 0;
            Temp: ''
          );


  begin
    I := Length(idDialog); PV := nil; LastSB := nil;
    FreeStr := Token(S, I);
    T.Init(0, FreeStr);
    if not DLGs^.Search(@T, J) then Error('Unknown Resource ID: ' + T.Name);
    ID := TDlgIdx(PLngWord(DLGs^.At(J))^.L);
    R.Assign(0, 0, GetID(Token(S, I)), GetID(Token(S, I)));
    if ID = dlgSystemSetup then begin
                                  D := New(PSysDialog, Init(R, Token(S, I)));
                                  D^.Awaken;
                                end else New(D, Init(R, Token(S, I)));
    D^.Options := D^.Options or ofCentered;
     while not EOF(F) do
      begin
        ReadLn(F, S);
        Inc(Line);
        while (S[1] = ' ') and (S <> '') do Delete(S, 1, 1);
        FreeStr := UpStrg(S);
        if (S <> '') and (S[1] <> ';') then
         begin
          if IsThis(idInputLine) then MakeInputLine else
           if IsThis(idHelpCtx) then
            begin
               if PV = nil then D^.HelpCtx := GetId(Token(S, I))
                           else PV^.HelpCtx := GetId(Token(S, I))
            end else
             if IsThis(idLabel) then MakeLabel else
             if IsThis(idStaticText) then MakeStaticText else
             if IsThis(idParamText) then MakeParamText else
             if IsThis(idListBox) then MakeListBox else
             if IsThis(idScrollBar) then MakeScrollBar(Off) else
             if IsThis(idMScrollBar) then MakeScrollBar(On) else
             if IsThis(idUpperTable) then MakeUpperTable else
             if IsThis(idCheckBoxes) then MakeCheckBoxes else
             if IsThis(idDriveCheckBox) then MakeDriveCheckBoxes else
             if IsThis(idSelectForward) then D^.SelectNext(Off) else
             if IsThis(idSelectBack) then D^.SelectNext(On) else
             if IsThis(idRadioButtons) then MakeRadioButtons else
             if IsThis(idButton) then MakeButton else
             if IsThis(idHistory) then MakeHistory else
             if IsThis(idEND) then Break else
             if (S <> '') and (S[1] <> ';') then
               Error('Unknown identifier in line '+ItoS(Line));
          while I < Length(S) do
             PV^.Options := PV^.Options or GetID(Token(S, I));
         end;
      end;
    D^.SelectNext(False);
    StoreResource(D, ID);
    if ID = dlgSystemSetup then
      begin
        New( PCollection( DData.Drives.List ), Init( 0, 10 ));
        D^.SetData( DData );
      end;
    Dispose(D, Done);
  end;

  procedure DoInsert( P: PLngWord ); far;
  begin
    IDs^.Insert( P );
  end;

  function FailCheck: boolean;
    procedure DoCheck( P: PLngWord ); far;
    begin
      If P^.Mark <> 1 then begin
        WriteLn( 'Unresolved identifier "', P^.Name, '"' );
        FailCheck := True;
      end;
    end;
  begin
    FailCheck := False;
    DLGs^.ForEach( @DoCheck );
  end;

begin
  DLGs := Types^.GetType( tidDLGs );
  New( IDs, Init( '', tmConst ));
  tP := Types^.GetType( tidCommands ); tP^.ForEach( @DoInsert );
  tP := Types^.GetType( tidHelpCtx ); tP^.ForEach( @DoInsert );
  tP := Types^.GetType( tidHistory ); tP^.ForEach( @DoInsert );
  tP := Types^.GetType( tidKbdconst ); tP^.ForEach( @DoInsert );
  tP := Types^.GetType( tidOptions ); tP^.ForEach( @DoInsert );

  WriteLn( 'Reading ', DlgFileName );
  Assign( F, DlgFileName ); ClrIO; Reset(F);
  Line := 0;
  if IOResult <> 0 then Error( 'Could not open input file' );
  St := New( PBufStream, Init( OutDlgFileName, stCreate, 512 ));
  if St^.Status <> stOK then begin
    Close(F);
    Dispose( St, Done );
    EraseFile( OutDlgFileName );
    Error('Could not create output file ' + OutDlgFileName );
  end;

  TheRF := New(PIdxMaker, Init(St));
  while not EOF(F) do
    begin
      ReadLn(F, S);
      Inc(Line);
      Write(#13'(', Line, ')');
      while (S[1] = ' ') and (S <> '') do Delete(S, 1, 1);
      FreeStr := UpStrg(S);
      if (S <> '') and (S[1] <> ';') then
        if Copy(FreeStr, 1, Length(idColorDialog)) = idColorDialog then MakeColorDialog else
        if Copy(FreeStr, 1, Length(idDialog)) = idDialog then CompileDialog(S) else
        if Copy(FreeStr, 1, Length(idMenu)) = idMenu then MakeMenu(S) else
        if Copy(FreeStr, 1, Length(idStatusLine)) = idStatusLine then MakeStatus else
        if Copy(FreeStr, 1, Length(idEditorCommands)) = idEditorCommands then MakeEditorCommands
        else Error('Unknown identifier in line '+ItoS(Line));
    end;

  Close(F);
  SetSavers;
  If FailCheck then Halt( 1 );

  WriteLn( #13'Writing ', OutDlgFileName );
  Dispose( TheRF, Done );

  IDs^.DeleteAll;
  Dispose( IDs, Done );
end;

FUNCTION GetName( S: String ): String;
var P, N, E: String;
begin
  FSplit( S, P, N, E );
  GetName := N;
end;

PROCEDURE CleanupTypes;
  procedure DoClean( P: PTypeHolder ); far;
    procedure DoUnmark( P: PLngWord ); far;
    begin
      P^.Mark := 0
    end;
  begin
    P^.ForEach( @DoUnmark );
  end;
begin
  Types^.ForEach( @DoClean );
end;

function ReplaceChar(A,B: Char; S: string): string;
begin
  Replace(A,B,S); ReplaceChar := S;
end;

VAR
  INI: TIniFile;
  INIs: Integer;
  Lng: String;
  LList: String;

  procedure InitParser;
  var
    Sec: PIniSection;
    I: Integer;
    K, S: String;
  begin
    Sec := INI.GetSection( 'Parser' );
    If Sec <> NIL then begin
      For I := 0 to Sec^.Count - 1 do begin
        K := UpStrg( Sec^.GetKeyAt( I ));
        If K <> ''then begin
          S := Sec^.GetValueAt( I ); DelDoubles( '  ', S );
          If K = 'CONST' then Types^.Insert( New( PTypeHolder, Init( ReplaceChar( ' ', #0, S + ' ' ), tmConst )))
          else
          If K = 'TYPE' then Types^.Insert( New( PTypeHolder, Init( S, tmEnum )))
          else
          Error( 'Undefined keyword "' + K + '" in [Parser] section' );
        end;
      end;
    end;
  end;

FUNCTION  CutWord( const S: String; No: Integer): String;   { S without word #No }
var
  I, K: Integer;
  L: Byte absolute S;
label
  Same;
begin
  If No < 1 then goto Same;
  I := SeekWord( S, No );
  If I > 0
    then CutWord := Copy( S, 1, I - 1 ) + Copy( S, wSkipBlank( S, wSkipText( S, I )), 255 )
    else Same: CutWord := S;
end;

BEGIN
  WriteLn( #13'Resource Compiler for Dos Navigator 1.49  Version 1.05' );
  WriteLn(    'Copyright(C) 1994,95 RIT Research Labs');
  WriteLn(    'Copyright(C) 1995 AxoN(R)Soft');

  INI.Init( 'RCP.INI', INIs );
  If INIs <> stOK then begin
    INI.Done;
    INI.Init( FSetExt( ParamStr( 0 ), '.INI' ), INIs );
    If INIs <> stOK then Error( 'File RCP.INI not found.' );
  end;

  RegisterType( RStrListMaker );

 {Views}
  RegisterType(RView);
  RegisterType(RFrame);
  RegisterType(RScrollBar);
  RegisterType(RGroup);
  RegisterType(RWindow);

  RegisterType( RScroller );
  RegisterType( RListViewer );
  RegisterType(RDialog);
  RegisterType(RInputLine);
  RegisterType(RButton);
  RegisterType(RCluster);
  RegisterType(RRadioButtons);
  RegisterType(RCheckBoxes);
  RegisterType(RMultiCheckBoxes);
  RegisterType(RListBox);
  RegisterType(RStaticText);
  RegisterType(RLabel);
  RegisterType(RHistory);
  RegisterType(RParamText);
  RegisterType(RMenuBar);
  RegisterType(RMenuBox);
  RegisterType(RStatusLine);
  RegisterType(RMenuPopup);

  RegisterType(RFilterValidator);
  RegisterType(RRangeValidator);

  RegisterType(RColorSelector);
  RegisterType(RMonoSelector);
  RegisterType(RColorDisplay);
  RegisterType(RColorGroupList);
  RegisterType(RColorItemList);
  RegisterType(RColorDialog);
  RegisterType(R_BWSelector);

  RegisterType(RSysDialog);
  RegisterType(RCurrDriveInfo);
  RegisterType(RMouseDialog);
  RegisterType(RMouseBar);
  RegisterType(RSaversDialog);
  RegisterType(RSaversListBox);
  RegisterType(RUpperTable);
  RegisterType(REditSaver);

  New( Types, Init( 10, 10 ));
  InitParser;

  LList := INI.Get( 'Controls', 'Indexes' );
  repeat
    Lng := GetWord( LList, 1 );
    If Lng <> '' then begin
      ProcessFile( Lng, Types );
      LList := CutWord( LList, 1 );
    end else
      Break
  until False;

  LList := INI.Get( 'Controls', 'Languages' );
  repeat
    Lng := GetWord( LList, 1 );
    If Lng <> '' then begin
      LngFileName := INI.Get( Lng, 'LngInput' );
      If LngFileName = '' then Error( 'No LNG input file defined for language "' + Lng +'".' );
      OutLngFileName := INI.Get( Lng, 'LngOutput' );
      If OutLngFileName = '' then Error( 'No LNG output file defined for language "' + Lng +'".' );
      DlgFileName := INI.Get( Lng, 'DlgInput' );
      If DlgFileName = '' then Error( 'No DLG input file defined for language "' + Lng +'".' );
      OutDlgFileName := INI.Get( Lng, 'DlgOutput' );
      If OutDlgFileName = '' then Error( 'No DLG output file defined for language "' + Lng +'".' );
      ProcessDLs( UpStrg( INI.Get( Lng, 'ProcessDLs' )) = 'YES' );
      ProcessDLGs;
      If LStringList <> NIL then
      begin
        FreeObject(LStringList);
        FreeObject(StringCache);
      end;
      DLStream.Done;
      ReRegisterType( RStrListMaker );
      CleanupTypes;
      LList := CutWord( LList, 1 );
    end else
      Break;
  until False;
  Dispose( Types, Done );
END.

