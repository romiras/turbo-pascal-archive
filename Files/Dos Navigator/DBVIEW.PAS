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

{$ifndef db}
unit DBView;

interface
uses DBWatch, Objects, Views, Drivers, Dos, Memory, Dialogs, RStrings, FViewer, Commands, ObjType;
{$else}

uses DBWatch, Objects, Views, Drivers, Dos, Memory, Menus, Messages,
     Advance, Startup, FViewer, Dialogs, Commands, DNApp, DNStdDlg;

{$endif}

type
{$ifdef db}
    TMyApp = object(TApplication)
     procedure HandleEvent(var Event: TEvent); virtual;
     procedure InitStatusLine; virtual;
    end;
{$endif}


    PDBIndicator = ^TDBIndicator;
    PDBViewer = ^TDBViewer;
    TDBViewer = object(TView)
     FileName: PString;
     DBFile: PDBFile;
     IsValid, KillAfterUse: Boolean;
     Buf: Pointer;
     SearchString: PString;
     StartRec: LongInt;
     NumRec: Word;
     Indicator: PDBIndicator;
     Delta, Pos: record X: Integer; Y: LongInt; end;
     constructor Init(R: TRect; FName: PathStr);
     function Valid(Command: Word): Boolean; virtual;
     function GetRecord(N: LongInt): Pointer;
     procedure GetInfo(StrIdx: TStrIdx);
     procedure HandleEvent(var Event: TEvent); virtual;
     destructor Done; virtual;
     procedure Draw; virtual;
     function GetPalette: PPalette; virtual;
     Constructor Load(var S : Tstream);
     Procedure Store(var S : TStream);
     function Failed: Boolean;
    end;

    PMemoStream = ^TMemoStream;
    TMemoStream = object(TStream)
     StartPos: LongInt;
     Length: LongInt;
     BaseStream: PStream;
     constructor Init(AStream: PStream; Start, Len: LongInt);
     destructor Done; virtual;
     function GetPos: Longint; virtual;
     function GetSize: Longint; virtual;
     procedure Read(var Buf; Count: Word); virtual;
     procedure Seek(Pos: Longint); virtual;
     procedure Truncate; virtual;
     procedure Write(var Buf; Count: Word); virtual;
    end;

    TDBIndicator = object(TView)
     DBViewer: PDBViewer;
     procedure Draw; virtual;
     {Constructor Load(var S : Tstream);
       Procedure Store(var S : TStream);}
    end;

    PFieldListBox = ^TFieldListBox;
    TFieldListBox = object(TListBox)
     function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    end;

    PDBWindow = ^TDBWindow;
    TDBWindow = object(TFileWindow)
       P: PDBViewer;
      P1: PDBIndicator;
     constructor Init(FName: String);
     function GetPalette: PPalette; virtual;
     Constructor Load(var S : Tstream);
       Procedure Store(var S : TStream);
    end;


 const CDBWindow = #166#167#168#169#170#171;
       CDBViewer = #4#5#6;

  RDBWindow: TStreamRec = (
  ObjType: otDBWindow;
  VmtLink: Ofs( TypeOf( TDBWindow )^ );
  Load: @TDBWindow.Load;
  Store: @TDBWindow.Store );

  RDBViewer: TStreamRec = (
  ObjType: otDBViewer;
  VmtLink: Ofs( TypeOf( TDBViewer )^ );
  Load: @TDBViewer.Load;
  Store: @TDBViewer.Store );

  RDBIndicator: TStreamRec = (
  ObjType: otDBIndicator;
  VmtLink: Ofs( TypeOf( TDBIndicator )^ );
  Load: @TDBIndicator.Load;
  Store: @TDBIndicator.Store );

  RTFieldListBox: TStreamRec = (
  ObjType: otFieldListBox;
  VmtLink: Ofs( TypeOf( TFieldListBox )^ );
  Load: @TFieldListBox.Load;
  Store: @TFieldListBox.Store );


{$ifndef db}
implementation
uses Advance, Startup, DNHelp, DNApp, Messages;
{$endif}

function MaxAvail: LongInt;
begin
  MaxAvail := MemAdjust(System.MaxAvail);
end;

function TFieldListBox.GetText;
 var P: PFieldRec;
     S: String;
     S1, S2, S3, S4: String[20];
     M: Array [1..5] of Pointer;
begin
 P := List^.At(Item);
 M[1] := @P^.Name;
 M[2] := @S1;
 M[3] := @S2;
 M[4] := @S3;
 case P^.Who of
  'N': S1 := GetString(dlDBNumeric);
  'C': S1 := GetString(dlDBCharacter);
  'M': S1 := GetString(dlDBMemo);
  'L': S1 := GetString(dlDBLogical);
  'D': S1 := GetString(dlDBDate);
  'F': S1 := GetString(dlDBFloat);
  'P': S1 := GetString(dlDBPicture);
 end;
 S2 := ItoS(P^.Len);
 if (P^.Who = 'N') or (P^.Who = 'F') then S3 := ItoS(P^.Dec) else S3 := '';
 FormatStr(S, ' %-12s%-13s%-11s%-8s', M);
 GetText := S;
end;

constructor TMemoStream.Init;
begin
 StartPos := Start;
 Length := Len;
 BaseStream := AStream;
 if AStream^.Status = stOK then AStream^.Seek(StartPos);
 ErrorInfo := BaseStream^.ErrorInfo;
 Status := BaseStream^.Status;
end;

destructor TMemoStream.Done;
begin
 Dispose(BaseStream, Done);
 inherited Done;
end;

function TMemoStream.GetPos: Longint;
 var L: LongInt;
begin
 L := BaseStream^.GetPos - StartPos;
 if L < 0 then begin BaseStream^.Seek(StartPos); L := 0; end;
 GetPos := L;
 ErrorInfo := BaseStream^.ErrorInfo;
 Status := BaseStream^.Status;
end;

function TMemoStream.GetSize: Longint;
begin
 GetSize := Length;
end;

procedure TMemoStream.Read(var Buf; Count: Word);
begin
 BaseStream^.Read(Buf, Count);
 ErrorInfo := BaseStream^.ErrorInfo;
 Status := BaseStream^.Status;
end;

procedure TMemoStream.Seek(Pos: Longint);
 var L: LongInt;
begin
 L := Pos + StartPos;
 BaseStream^.Seek(L);
 ErrorInfo := BaseStream^.ErrorInfo;
 Status := BaseStream^.Status;
end;

procedure TMemoStream.Truncate;
begin
 BaseStream^.Truncate;
 ErrorInfo := BaseStream^.ErrorInfo;
 Status := BaseStream^.Status;
end;

procedure TMemoStream.Write(var Buf; Count: Word);
begin
 BaseStream^.Write(Buf, Count);
 ErrorInfo := BaseStream^.ErrorInfo;
 Status := BaseStream^.Status;

 {Move(AStream^, Self, sizeof(TStream));}
end;

constructor TDBViewer.Init;
 var I: Word;
     F: File;
begin
  inherited Init(R);
  KillAfterUse := TempFile <> '';
  Options := Options or ofSelectable;
  GrowMode := gfGrowHiX + gfGrowHiY;
  EventMask := $FFFF;
  SearchString := nil;
  HelpCtx := hcDBView;
  Buf := nil; FileName := NewStr(DelSpaces(FExpand(FName)));
  if Failed then Fail;
  if isValid then TempFile := '';
end;

Procedure TDBViewer.Store ;
 begin
   Inherited Store( S );
    S.Write( KillAfterUse, SizeOf ( KillAfterUse ) );
    S.WriteStr( SearchString );
    S.WriteStr( FileName );
    S.Write( Delta , SizeOf(Delta));
    S.Write( Pos , SizeOf( Pos ));
    {S.Write( NumRec , SizeOf ( NumRec ) );}
 end;


function DateToHuman(const D: String): String;
  var I: Integer;
      C: Char;
      BB: Byte;
      S: String[20];
begin
  if CountryInfo.DateSep <> '' then
    begin
      BB := 1;
      C := CountryInfo.DateSep[1];
      S[3] := C; S[6] := C;
    end else BB := 0;
  case CountryInfo.DateFmt of
    1: begin
         Move(D[7], S[1], 2);
         Move(D[5], S[BB+3], 2);
         Move(D[3], S[2*BB+5], 2);
       end;
    0: begin
         Move(D[5], S[1], 2);
         Move(D[7], S[BB+3], 2);
         Move(D[3], S[2*BB+5], 2);
       end;
    else begin
           Move(D[3], S[1], 2);
           Move(D[5], S[BB+3], 2);
           Move(D[7], S[2*BB+5], 2);
         end;
  end;
  S[0] := Char(6+2*BB); DateToHuman := S;
end;


function TDBViewer.Failed: Boolean;
var I : LongInt ;
begin
  Failed := False;
  New(DBFile, Init(CnvString(FileName)));

  if DBFile <> nil then
  begin
    I := 65520;
    if DBFile^.NumRec = 0 then
    begin
      GetInfo(dlDBEmptyStruc);
      DisposeStr(SearchString);
      Dispose(DBFile, Done);
      TempFile := '';
      if KillAfterUse then EraseFile(CnvString(FileName));
      DisposeStr(FileName);
      Failed := True;
      Exit;
    end;
    if MaxAvail < I then I := MaxAvail;
    if LongInt(I) > DBFile^.NumRec*LongInt(DBFile^.RecLen) then
    I := DBFile^.NumRec*LongInt(DBFile^.RecLen);
    NumRec := I div DBFile^.RecLen;
    I := NumRec * DBFile^.RecLen;
    StartRec := 0;
    if I <> 0 then GetMem(Buf, I);
  end;
  IsValid := (DBFile <> nil) and (Buf <> nil);
  if IsValid then
  begin
    DBFile^.Seek(0);
    DBFile^.Read(Buf^, NumRec);
  end;
end;

Constructor TDBViewer.Load ;
begin
  inherited Load( S );
  S.Read( KillAfterUse, SizeOf ( KillAfterUse ) );
  SearchString := S.ReadStr;
  FileName := S.ReadStr;

  if Failed then Fail;

  S.Read( Delta , SizeOf(Delta));
  S.Read( Pos , SizeOf( Pos ));
end;

destructor TDBViewer.Done;
 var F: File;
begin
 DisposeStr(SearchString);
 if Buf <> nil then FreeMem(Buf, NumRec*DBFile^.RecLen);
 if DBFile <> nil then Dispose(DBFile, Done);
 DisposeStr(FileName);
 inherited Done;
end;

function TDBViewer.GetPalette;
 const S: String[Length(CDBviewer)] = CDBViewer;
begin
 GetPalette := @S;
end;

function TDBWindow.GetPalette;
 const S: String[Length(CDBWindow)] = CDBWindow;
begin
 GetPalette := @S;
end;

function TDBViewer.GetRecord;
 var
     I: Integer;
begin
 GetRecord := nil;
 if N < 0 then N := 0;
 if N >= DBFile^.NumRec then Exit;
 if (N < StartRec) or (N >= StartRec + NumRec) then
  begin
   StartRec := N - (NumRec div 2);
   if StartRec < 0 then StartRec := 0;
   DBFile^.Seek(StartRec);
   DBFile^.Read(Buf^, NumRec);
  end;
 GetRecord := @PByteArray(Buf)^[(N - StartRec)*DBFile^.RecLen];
end;

function TDBViewer.Valid;
begin
 Valid := inherited Valid(Command) and IsValid;
end;

procedure TDBViewer.GetInfo;
 var R: TRect;
     D: PDialog;
     P: PView;
begin
 R.Assign(1,1,50,18);
 D := New(PDialog, Init(R, GetString(StrIdx)+Cut(FileName^, 20)));
 D^.Options := D^.Options or ofCentered;

 R.Assign(2,2,48,3);
 P := New(PStaticText, Init(R, GetString(dlDBViewInfoString)));
 D^.Insert(P);

 R.Assign(46,3,47,13);
 P := New(PScrollBar, Init(R));
 P^.Options := P^.Options or ofPostProcess;
 D^.Insert(P);

 R.Assign(2,3,46,13);
 P := New(PFieldListBox, Init(R, 1, PScrollBar(P)));
 PListBox(P)^.NewList(DBFile^.Fields);
 D^.Insert(P);

 R.Assign(30, 14, 40, 16);
 P := New(PButton, Init(R, GetString(dlOKButton), cmOK, bfDefault));
 P^.Options := P^.Options or ofCenterX;
 D^.Insert(P);

 D^.SelectNext(False);

 D := PDialog(Application^.ValidView(D));
 if D = nil then Exit;
 Desktop^.ExecView(D);
 Dispose(D, Done);
end;

procedure TDBViewer.HandleEvent;

 procedure ViewMemo;
  var P: PByteArray;
      PFR: PFieldRec;
      S: String;
      L, ML: LongInt;
      I: Integer;
      D: PDialog;
      R: TRect;
      PV: PView;
      MemoStream: PStream;
      Dr: PathStr;
      Nm: NameStr;
      Xt: ExtStr;
 begin
  P := GetRecord(Delta.Y); if P = nil then Exit;
  PFR := DBFile^.GetFieldRec(Delta.X); if PFR = nil then Exit;
  Move(P^[PFR^.Pos], S[1], PFR^.Len); S[0] := Char(PFR^.Len);
  Val(DelSpaces(S), L, I);
  if (PFR^.Who <> 'M') or (L = 0) then Exit;
  FSplit(UpStrg(FileName^), Dr, Nm, Xt);
  if LowMemory then Exit;
  if (XT[0] = #4) and (XT <> '.DBF') then XT[4] := 'T' else XT := '.FPT';
  MemoStream := New(PDosStream, Init(Dr+Nm+XT, stOpenRead));
  if (MemoStream = nil) or (MemoStream^.Status <> stOK) then
   begin
    if MemoStream <> nil then Dispose(MemoStream, Done);
    MemoStream := New(PBufStream, Init(Dr+Nm+'.dbt', stOpenRead, 512));
    L := L * 512;
    MemoStream^.Seek(L); ML := 0;
    repeat MemoStream^.Read(Nm[1], 1); if Nm[1] <> #$1A then Inc(ML) else Break
    until MemoStream^.Status <> stOK;
    if (MemoStream = nil) or (MemoStream^.Status <> stOK) then
     begin
      ErrMsg(dlDBViewNoMemo);
      if MemoStream <> nil then Dispose(MemoStream, Done);
      Exit;
     end;
   end else
   begin
    MemoStream^.Seek(4);
    MemoStream^.Read(ML, 4);
    asm
     mov ax, word ptr ML
     mov bx, word ptr ML+2
     xchg al, ah
     xchg bl, bh
     mov word ptr ML, bx
     mov word ptr ML+2, ax
    end;
    L := L * ML;
    MemoStream^.Seek(L+4);
    ML := MemoStream^.GetPos;
    ML := 0;
    MemoStream^.Read(ML, 4);
    asm
     mov ax, word ptr ML
     mov bx, word ptr ML+2
     xchg al, ah
     xchg bl, bh
     mov word ptr ML, bx
     mov word ptr ML+2, ax
    end;
    Inc(L, 8);
   end;
  MemoStream := New(PMemoStream, Init(MemoStream, L, ML));
  if MemoStream^.Status <> stOK then
   begin Dispose(MemoStream, Done); Exit end;
  Desktop^.GetExtent(R);
  R.Grow(-2,-2);
  R.Assign(1,1,70,20);
  D := New(PDialog, Init(R, GetString(dlDBViewViewMemo)));
  D^.Options := D^.Options or ofCentered;

  R.Assign(D^.Size.X-2, 2, D^.Size.X-1, D^.Size.Y - 4);
  PV := New(PViewScroll, Init(R));
  D^.Insert(PV);
  PV^.GetPalette^ := CScrollBar;

  R.Assign(2, 2, D^.Size.X-2, D^.Size.Y-4);
  PV := New(PNFileViewer, Init(R, MemoStream, '', PV, False, Off));
  D^.Insert(PV);

  R.Assign(30, D^.Size.Y - 3, 40, D^.Size.Y - 1);
  PV := New(PButton, Init(R, GetString(dlOKButton), cmOK, bfDefault));
  PV^.Options := PV^.Options or ofCenterX;
  D^.Insert(PV);

  D^.SelectNext(False);

  D := PDialog(Application^.ValidView(D));
  if D = nil then Exit;
  Desktop^.ExecView(D);
  Dispose(D, Done);
 end;

  const SearchRec : record
     S: String[250]; {Inputline}
     Opt: Word; {Checkbox}
     Scope: Word;  {Radiobuttons}
     Direction: Integer;  {Radiobuttons}
    end = (S:'';Opt:0;Scope:0;Direction:0);

 procedure ContSearch(MY: LongInt);
  var I,J,U,D: LongInt;
      PFR: PFieldRec;
      S, SS: String;
      P: PByteArray;
 begin
  SS := SearchRec.S;
  if SearchRec.Opt and 1 = 0 then SS := UpcaseStr(SS);
  I := Delta.Y+MY; PFR := DBFile^.GetFieldRec(Delta.X);
  if SearchRec.Scope = 0 then begin U := Delta.X; D := Delta.X end
                         else begin U := 0; D := dbFile^.NumFields - 1 end;
  while (I < DBFile^.NumRec) and (SearchRec.Direction <> 1) or
        (SearchRec.Direction = 1) and (I >= 0) do
   begin
    P := GetRecord(I);
    if I = Delta.Y + MY then J := Delta.X - Byte(SearchRec.Direction = 1)
                        else if SearchRec.Direction = 1 then J := U else J := D;
    while (J <= D) and (SearchRec.Direction <> 1) or
          (SearchRec.Direction = 1) and (J >= U) do
      begin
        PFR := DBFile^.GetFieldRec(J);
        Move(P^[PFR^.Pos], S[1], PFR^.Len);
        S[0] := Char(PFR^.Len);
        if SearchRec.Opt and 1 = 0 then UpStr(S);
        if System.Pos(SS, S) > 0 then
         begin
          Delta.Y := I;
          Delta.X := J;
          DrawView;
          Exit;
         end;
       if SearchRec.Direction = 1 then Dec(J) else Inc(J);
      end;
    if SearchRec.Direction = 1 then Dec(I) else Inc(I);
   end;
  ErrMsg(dlDBViewSearchNot);
 end;

 procedure StartSearch;
 begin
  if ExecResource(dlgDbFind, SearchRec) <> cmOK then Exit;
  case SearchRec.Direction of
   0: ContSearch(1);
   1: ContSearch(-1);
    else begin ContSearch(-Delta.Y) end;
  end
 end;

 procedure EditField;
   var P: PChar;
       PFR: PFieldRec;
       S: String;
       R: Real;
       I: Integer;
       MM, DD, YY: Word;
       II, N1, N2, N3: Word;
       LL: Array [0..3] of LongInt;

   procedure StoreField;
   begin
     S := AddSpace(S, PFR^.Len);
     Move(S[1], P[PFR^.Pos], PFR^.Len);
     DBFile^.Seek(Delta.Y);
     DBFile^.BaseFile.Seek(DBFile^.BaseFile.GetPos + PFR^.Pos);
     DBFile^.BaseFile.Write(S[1], PFR^.Len);
   end;

   function GetDig: Word;
     var D: String;
   begin
     D := '';
     while (II <= Length(S)) and ((S[II] < '0') or (S[II] > '9')) do Inc(II);
     while (II <= Length(S)) and ((S[II] >= '0') and (S[II] <= '9')) do
       begin AddStr(D, S[II]); Inc(II); end;
     GetDig := StoI(D);
   end;

 begin
   repeat
     case DBFile^.WriteMode of
       0 : begin
             DBFile^.BaseFile.Done;
             DBFile^.OpenMode(stOpen);
             Inc(DBFile^.WriteMode);
             if DBFile^.BaseFile.Status = stOK then Inc(DBFile^.WriteMode) else DBFile^.OpenMode(stOpenRead);
           end;
       1 : begin ErrMsg(dlDBCantEdit); Exit end;
       2 : Break;
     end;
   until False;
   PFR := DBFile^.GetFieldRec(Delta.X);
   if PFR^.Who = 'M' then Exit;
   P := GetRecord(Delta.Y);
   Move(P[pfr^.pos], S[1], pfr^.Len); S[0] := Char(Pfr^.Len);
   if PFR^.Who <> 'C' then DelLeft(S);
   case PFR^.Who of
     'C','N': if InputBox(GetString(dlDBEditField), GetString(dlDBValue), S, PFR^.Len, hsEditDBF) = cmOK then
                begin
                  if PFR^.Who = 'N' then
                    begin
                      DelSpace(S);
                      Val(S, R, I);
                      Str(R:PFR^.Len:PFR^.Dec, S);
                      S := PredSpace(S, PFR^.Len);
                    end;
                  StoreField;
                end;
         'D': begin
                S := DateToHuman(S);
                if InputBox(GetString(dlDBEditField), GetString(dlDBValue), S, 10, hsEditDBF) = cmOK then
                  begin
                    II := 1;
                    N1 := GetDig; N2 := GetDig; N3 := GetDig;
                    GetDate(II, MM, DD, YY);
                    case CountryInfo.DateFmt of
                      0: begin MM := N1; DD := N2; YY := N3; end;
                      1: begin MM := N2; DD := N1; YY := N3; end;
                        else begin MM := N2; DD := N3; YY := N1; end;
                    end;
                    if YY < 100 then YY := (II div 100) * 100 + YY;
                    LL[0] := YY mod 10000; LL[1] := MM mod 100; LL[2] := DD mod 100;
                    FormatStr(S, '%04d%02d%02d', LL);
                    StoreField;
                  end;
              end;
         'L': begin
                if UpCaseStr(S) = 'T' then S := 'F' else S := 'T';
                StoreField;
              end;
   end;

 end;



 procedure CE; begin ClearEvent(Event) end;
 procedure CED; begin CE; DrawView end;

 var F: File;
     P: TPoint;
     RD: Word;

begin
 inherited HandleEvent(Event);
 case Event.What of
  evCommand: case Event.Command of
              cmClose, cmKillUsed: if KillAfterUse then
                                    begin
                                      if DBFile <> nil then
                                        begin
                                          if Buf <> nil then FreeMem(Buf, NumRec*DBFile^.RecLen);
                                          Dispose(DBFile, Done);
                                          Buf := nil;
                                          dbFile := nil;
                                        end;
                                      EraseFile( FileName^ );
                                      if Event.Command = cmClose then GlobalMessage(evCommand, cmPanelReread, nil);
                                    end;
              cmGetName: PString(Event.InfoPtr)^ := GetString(dlDBViewName) + FileName^;
              cmShowFields: begin GetInfo(dlDBViewInfo); CE end;
              cmShowMemo: begin ViewMemo; CE end;
              cmSearchFor: begin StartSearch; CE; end;
              cmContinueSearch: begin ContSearch(1-2*Integer(SearchRec.Direction = 1)); CE; end;
              cmEditDBField: begin EditField; CED end;
             end;
  evKeyDown: case Event.KeyCode of
              kbEnter: begin if Delta.X < DBFile^.NumFields - 1 then Inc(Delta.X)
                                else begin Inc(Delta.Y); Delta.X := 0; end;
                             CED
                       end;
              kbLeft: begin if Delta.X > 0 then Dec(Delta.X); CED; end;
              kbRight: begin if Delta.X < DBFile^.NumFields - 1 then Inc(Delta.X); CED; end;
              kbHome: begin Delta.X := 0; CED end;
              kbEnd: begin Delta.X := DBFile^.NumFields - 1; CED end;
              kbUp: begin Dec(Delta.Y); CED end;
              kbDown: begin Inc(Delta.Y); CED end;
              kbPgUp: begin Dec(Delta.Y, Size.Y - 2); CED end;
              kbPgDn: begin Inc(Delta.Y, Size.Y - 2); CED end;
              kbCtrlPgUp: begin Delta.Y := 0; CED end;
              kbCtrlPgDn: begin Delta.Y := DBFile^.NumRec - 1; CED end;
              kbESC: begin Message(Owner, evCommand, cmClose, nil); CE end;
             end;
  evMouseDown: begin
                RD := RepeatDelay; RepeatDelay := 0;
                repeat
                 MakeLocal(Event.Where, P);
                 if MouseInView(Event.Where) then
                  if P.X < Size.X div 4 then Message(@Self, evKeyDown, kbLeft, nil) else
                   if P.X >= (Size.X*3) div 4 then Message(@Self, evKeyDown, kbRight, nil) else
                    if P.Y < Size.Y div 2 then Message(@Self, evKeyDown, kbUp, nil) else
                     Message(@Self, evKeyDown, kbDown, nil)
                until not MouseEvent(Event, evMouseMove+evMouseAuto);
                RepeatDelay := RD; CE
               end;
 end;
end;


procedure TDBViewer.Draw;
 var B: Array [0..1024] of record C: Char; A: Byte; end;
     FN: Array [0..132] of PFieldRec;
     C1, C2 ,C3: Word;
     C: Byte;
     I, J, K, NFN: Integer;
     Idx: LongInt;
     PFR: PFieldRec;
     P: PByteArray;
     S: String;
begin
 C1 := GetColor(1); C2 := GetColor(2); C3 := GetColor(3);
 if Delta.Y < 0 then Delta.Y := 0;
 if Delta.Y >= DBFile^.NumRec then Delta.Y := DBFile^.NumRec - 1;
 if Pos.Y > Delta.Y then Pos.Y := Delta.Y;
 if Pos.Y + Size.Y - 2 < Delta.Y then Pos.Y := Delta.Y - Size.Y + 2;
 if Pos.Y < 0 then Pos.Y := 0;
 if Pos.X > Delta.X then Pos.X := Delta.X;
 if Indicator <> nil then Indicator^.Draw;
 repeat
  MoveChar(B, ' ', C1, Size.X);
  J := Pos.X; NFN := 0; I := 1;
  While (I < Size.X) and (J < DBFile^.NumFields) do
   begin
    PFR := DBFile^.GetFieldRec(J);
    FN[NFN] := PFR;
    if PFR <> nil then
     begin
      MoveStr(B[I], PFR^.Name, C1);
      Inc(I, PFR^.Ln+1);
     end;
    if I < Size.X then Inc(NFN);
    Inc(J);
   end;
  if (Delta.X > Pos.X + NFN - 1) and (Pos.X <> Delta.X) then Inc(Pos.X) else Break;
 until False;
 WriteLine(0,0, Size.X, 1, B);
 for K := 1 to Size.Y - 1 do
  begin
   MoveChar(B, ' ', C2, Size.X);
   J := Delta.X; I := 1; Idx := Pos.Y+LongInt(K)-1;
   P := GetRecord(Idx);
   if (NFN = 0) and (P <> nil) then NFN := 1;
   if P <> nil then B[0].C := Char(P^[0]);
   if P <> nil then
   for J := 0 to NFN - 1 do
    begin
     PFR := FN[J];
     if (Delta.Y = Idx) and (Pos.X + J = Delta.X) then C := C3 else C := C2;
     if PFR <> nil then
     if PFR^.Who = 'M' then
     begin
      Move(P^[PFR^.Pos], S[1], PFR^.Len);
      S[0] := Char(PFR^.Len);
      if StoI(S) > 0 then S := '  Memo  ' else S := '  memo  ';
      MoveStr(B[I], S, C);
      Inc(I, PFR^.Ln + 1);
     end else
     if PFR^.Who = 'D' then
     begin
       Move(P^[PFR^.Pos], S[1], PFR^.Len); S[0] := Char(PFR^.Len);
       MoveStr(B[I], DateToHuman(S), C);
       Inc(I, 9);
     end else
     asm
      les di, PFR
      mov cx, es:[di].FieldRec.Len
      mov dx, es:[di].FieldRec.Ln
      mov bx, es:[di].FieldRec.Pos
      lea si, B
      add si, I
      add si, I
      les di, P
      mov ah, byte ptr C
@@1:  mov al, es:[bx][di]
      mov ss:[si], ax
      inc si
      inc si
      inc di
      loop @@1
      inc dx
      add I, dx
     end;
    end;

   WriteLine(0,K,Size.X,1,B);
  end;
end;

procedure TDBIndicator.Draw;
 var B: TDrawBuffer;
     S: String;
     C: Byte;
begin
 if DBViewer^.Delta.Y < 0 then DBViewer^.Delta.Y := 0;
 if Origin.Y <> Owner^.Size.Y - 1 then MoveTo(Origin.X, Owner^.Size.Y - 1);
 S := ItoS(DBViewer^.Delta.Y+1)+'/'+Itos(DBViewer^.DBFile^.NumRec);
 if Byte(S[0]) <> Size.X then begin GrowTo(Byte(S[0]), 1); Exit; end;
 C := Byte(Owner^.GetState(sfActive));
 C := Owner^.GetColor(C+1);
 MoveStr(B, S, C);
 WriteLine(0,0,Size.X,1,B);
end;

constructor TDBWindow.Init;
 var R: TRect;
begin
 DeskTop^.GetExtent(R);
 FName := DelSpaces(FExpand(FName));
 TWindow.Init(R, FName, 0);
 GetExtent(R); R.Grow(-1, -1);
 P := New(PDBViewer, Init(R, FName));
 if P = nil then Fail;
 Insert(P);
 R.A.X := 10; R.B.X := 20; R.A.Y := Size.Y - 1; R.B.Y := Size.Y;
 P1 := New(PDBIndicator, Init(R));
 P1^.DBViewer := P;
 P1^.GrowMode := gfGrowHiY;
 Insert(P1);
 P^.Indicator := P1;
end;

constructor TDBWindow.Load;
 begin
  inherited Load( S );
   GetSubViewPtr( S, P );
   GetSubViewPtr( S, P1 );
   P1^.DBViewer := P;
   P^.Indicator := P1;
   Redraw ;
 end;
Procedure TDBWindow.Store;
 begin
   inherited Store( S );
     PutSubViewPtr( S, P );
     PutSubViewPtr( S, P1 );
   end;

{$ifdef db}
const
     cmOpenDBF = 1000;


procedure TMyApp.InitStatusLine;
 var R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~F3~ Open', kbF3, cmOpenDBF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit, nil)), nil)));
end;

procedure TMyApp.HandleEvent;
 var S: String;
     D: PFileDialog;
begin
 inherited HandleEvent(Event);
 if (Event.What = evCommand) and (Event.Command = cmOpenDBF) then
  begin
   D := PFileDialog(Application^.ValidView(New(PFileDialog,
         Init('*.dbf', '', '', fdOpenButton, 1))));
   if D = nil then Exit;
   if Desktop^.ExecView(D) <> cmCancel then D^.GetFileName(S);
   Dispose(D, Done);
   if S = '' then Exit;
   InsertWindow(New(PDBWindow, Init(S)));
  end;
end;

var MyApp: TMyApp;

begin
 Inc(SkyEnabled);
 MyApp.Init;
 MyApp.Run;
 MyApp.Done;
{$endif}
end.

