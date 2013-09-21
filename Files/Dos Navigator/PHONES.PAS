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

{$I STDEFINE.INC}
{$I DN.DEF}

unit Phones;

interface

uses xTime, Objects, DNApp, Drivers, Dialogs, Menus, Views, DNStdDlg, RStrings
     ,DNHelp, Advance, Messages, ObjType;

type {TMyApp = object(TApplication)
       procedure Idle; virtual;
       procedure HandleEvent(var Event: TEvent); virtual;
     end;}

     PPhoneCollection = ^TPhoneCollection;
     TPhoneCollection = object(TSortedCollection)
      constructor Init(ALimit, ADelta: Integer);
      constructor Load(var S: TStream);
      function Compare(P1, P2: Pointer): Integer; virtual;
      procedure FreeItem(Item: Pointer); virtual;
     end;

     PPhoneDir = ^TPhoneDir;
     TPhoneDir = object(TObject)
       Name: String[30];
       Memo1: PString;
       Memo2: PString;
       Password: String[15];
       Phones: PCollection;
       Encrypted: Boolean;
       constructor Init(const APassword, AName, AMemo1, AMemo2: String);
       constructor Load(var S: TStream);
       procedure Store(var S: TStream);
       destructor Done; virtual;
     end;

     PPhone = ^TPhone;
     TPhone = object(TObject)
      Name: String[30];
      Memo1: PString;
      Memo2: PString;
      Number: PString;
      constructor Init(const ANumber, AName, AMemo1, AMemo2: String);
      constructor Load(var S: TStream);
      procedure Store(var S: TStream);
      destructor Done; virtual;
     end;

     PDStringView = ^TDStringView;
     TDStringView = object(TView)
      S1, S2: String[50];
      function GetPalette: PPalette; virtual;
      procedure Draw; virtual;
     end;

     PDialBox = ^TDialBox;
     TDialBox = object(TListBox)
        function GetText(Item: Integer; MaxLen: Integer): String; virtual;
{        destructor Done; virtual;}
     end;

     PPhoneBox = ^TPhoneBox;
     TPhoneBox = object(TSortedListBox)
      GroupLabel, ItemLabel: PLabel;
      AlphaMode, SearchMode: Boolean;
      Phones: PCollection;
      Active: PPhoneDir;
      Info: PDStringView;
      destructor Done; virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      function GetText(Item: Integer; MaxLen: Integer): String; virtual;
      function GetKey(var S: String): Pointer; virtual;
      procedure SetList(Alpha: Boolean);
{      procedure SetState(AState: Word; Enable: Boolean); virtual;}
     end;

{$IFDEF Modem}
     PAutoDialer = ^TAutoDialer;
     TAutoDialer = object(TDialog)
      HoldButton,UnholdButton: PButton;

      List: PListBox;
      Trm: PDStringView;
      Phones: PPhoneCollection;
      Phone, Name: String;
      ModemS: String;
      SPosX: Integer;
      Static, Hold, Pause: Boolean;
      PauseTimer: TEventTimer;
      UpdTimer: TEventTimer;
      isValid: Boolean;
      L: Array [1..2] of Pointer;
      constructor Init(AName, APhone: String);
      procedure SetPhone(NewName, NewPhone: String);
      procedure HandleEvent(var Event: TEvent); virtual;
      function Valid(C: Word): Boolean; virtual;
      procedure Update; virtual;
      constructor Load(var S: TStream);
      procedure Store(var S: TStream);
      destructor Done; virtual;
     end;
{$ENDIF}

procedure PhoneBook(Manual: Boolean);

{$IFDEF Modem}

const
      Dialer: PAutoDialer = nil;

      RAutoDialer: TStreamRec = (
       ObjType: otAutoDialer;
       VmtLink: Ofs(TypeOf(TAutoDialer)^);
       Load: @TAutoDialer.Load;
       Store: @TAutoDialer.Store);
{$ENDIF}

const
      RDialBox: TStreamRec = (
       ObjType: otDialBox;
       VmtLink: Ofs(TypeOf(TDialBox)^);
       Load: @TDialBox.Load;
       Store: @TDialBox.Store);

      RDStringView: TStreamRec = (
       ObjType: otDStringView;
       VmtLink: Ofs(TypeOf(TDStringView)^);
       Load: @TDStringView.Load;
       Store: @TDStringView.Store);

      RPhone: TStreamRec = (
       ObjType: otPhone;
       VmtLink: Ofs(TypeOf(TPhone)^);
       Load: @TPhone.Load;
       Store: @TPhone.Store);

      RPhoneDir: TStreamRec = (
       ObjType: otPhoneDir;
       VmtLink: Ofs(TypeOf(TPhoneDir)^);
       Load: @TPhoneDir.Load;
       Store: @TPhoneDir.Store);

      RPhoneCollection: TStreamRec = (
       ObjType: otPhoneCollection;
       VmtLink: Ofs(TypeOf(TPhoneCollection)^);
       Load: @TPhoneCollection.Load;
       Store: @TPhoneCollection.Store);


implementation
uses StartUp, Commands {$IFDEF Modem}, ModemIO, Terminal{$ENDIF};

const cmHold   = 11304;
      cmUnhold = 11005;
var   EnterButton, ReturnButton: PButton;

function CryptWith(Pass, S: String): String;
 var I : Integer;
begin
  if Pass <> '' then
    begin
      for I := 1 to Length(S) do
        S[I] := Char(Byte(S[I]) xor Byte(Pass[1 + I mod Length(Pass)]) xor (I xor $AA));
    end;
 CryptWith := S;
end;

procedure TDStringView.Draw;
 var B: TDrawBuffer;
     C: Word;
begin
 C := GetColor(1);
 MoveChar(B, ' ', C, Size.X);
 MoveStr(B, S1, C);
 WriteLine(0, 0, Size.X, Size.Y, B);
 MoveChar(B, ' ', C, Size.X);
 MoveStr(B, S2, C);
 WriteLine(0, 1, Size.X, Size.Y, B);
end;

function TDStringView.GetPalette;
 const S: String[1] = #30;
begin
 GetPalette := @S;
end;

var PPH: PPhone;

procedure PhoneBook(Manual: Boolean);
 var D: PDialog;
     R: TRect;
     PV: PView;
     PL: PPhoneBox;
     PC: PCollection;
     S: TBufStream;
     DT: record C: PCollection; N: Word; end;
     W: PWindow;
     I: Integer;
    SS: string;

  procedure DoSearchButton( P: PView ); far;
   begin
     If ( TypeOf( P^ ) = TypeOf( TButton )) then
      if PButton(P)^.Command=cmOk then EnterButton:=PButton(P)
       else if PButton(P)^.Command=cmNo then ReturnButton:=PButton(P);
   end;

begin
  PPh := nil;
  SS := '';
  if Manual then begin
    If ( ExecResource( dlgManualDial, SS ) <> cmOK ) or ( DelSpaces(SS) = '' ) then Exit;
    New(PPh, Init(SS, GetString(dlMD_Manual)+SS, '', ''));
  end else
  begin
    D := PDialog( LoadResource( dlgPhoneBook ));
    D^.ForEach(@DoSearchButton);
    ReturnButton^.Hide;
    PV := D^.StandardScrollBar(sbVertical+sbHandleKeyboard);
    R.Assign(D^.Size.X-3,3,D^.Size.X-2,12);
    PV^.Locate(R);

    R.Assign(2,3,D^.Size.X-3,12);
    PL := New(PPhoneBox, Init(R, 1, PScrollBar(PV)));
    PL^.Options := PL^.Options or ofPostProcess;
    S.Init(SourceDir+'DN.PHN', stOpenRead, 1024);
    PC := PCollection(S.Get);
    S.Done;
    if PC = nil then PC := New(PPhoneCollection, Init(10,10));
    PC^.Pack;
    PL^.Phones := PC;
    PL^.Active := nil;
    PL^.AlphaMode := Off;
    PL^.SearchMode := Off;
    PL^.NewList(PC);

    D^.Insert(PL);
    R.Assign(2,2,53,3);

{    PV := New(PLabel, Init(R, GetString(dlPhonesLabel),PL));}
    PL^.GroupLabel:=New(PLabel, Init(R, GetString(dlPhonesLabelGroup), PL));
    D^.Insert(PL^.GroupLabel);

    PL^.ItemLabel:=New(PLabel, Init(R, GetString(dlPhonesLabelPhones), PL));
    PL^.ItemLabel^.Hide;
    D^.Insert(PL^.ItemLabel);



    D^.Insert(PL);
    {D^.Insert(PV);}
    R.Assign(2,12,D^.Size.X-2,14);
    PV := New(PDStringView, Init(R));
    PDStringView(PV)^.S1 := '';
    PDStringView(PV)^.S2 := '';
    D^.Insert(PV);
    PL^.Info := PDStringView(PV);

    R.A.X := Desktop^.ExecView(D);
    D^.GetData(DT);
    Dispose(D, Done);
    if R.A.X <> cmDialPhone then Exit;
  end;
  if PPh = nil then Exit;
{$IFDEF Modem}
  if Dialer = nil then begin
    W := New(PAutoDialer, Init(PPh^.Name,PPh^.Number^));
    Application^.InsertWindow(W);
  end else
    Dialer^.SetPhone(PPh^.Name,PPh^.Number^);
{$ENDIF}
  Dispose(PPh, Done);
end;

function TPhoneBox.GetKey;
 const B: Byte = 0;
       ST: String[30] = '';
begin
 ST := UpStrg(S);
 GetKey := @B;
end;

{procedure TPhoneBox.SetState(AState: Word; Enable: Boolean);
begin
 Inherited SetState(AState, Enable);
 if (Active <> nil) and ((State And sfFocused)<>0) then
   if (Focused=0) then DisableCommands([cmDialPhone, cmImportPhones])
                  else EnableCommands([cmDialPhone, cmImportPhones])
end;
 }
procedure TPhoneBox.SetList;
  var PC: PPhoneCollection;
      S: TBufStream;

  procedure DoPhones(Ph: PPhoneDir); far;

    procedure InsertPhone(P: PPhone); far;
      var PP: PPhoneDir;
          I: Integer;
    begin
      if P <> nil then
       begin
         FreeStr:=UpCaseStr(P^.Name);
         If (Length(FreeStr)=2) and (FreeStr='..') then Exit;
         PP := New(PPhoneDir, Init('', FreeStr[1], '', ''));
         if PC^.Search(PP, I) then
          begin
            Dispose(PP, Done);
            PP := PC^.At(I);
          end else PC^.AtInsert(I, PP);
         if PP^.Phones = nil then PP^.Phones := New(PPhoneCollection, Init(10,10));
         PSortedCollection(PP^.Phones)^.Duplicates := On;
         PP^.Phones^.Insert(P);
        end;
    end;

  begin
    if (Ph <> nil) and (Ph^.Phones <> nil)  and ((Ph^.Password = '') or (Ph^.Encrypted))
       then Ph^.Phones^.ForEach(@InsertPhone);
    Ph^.Phones^.DeleteAll;
  end;

begin
 if Phones = nil then Exit;
 if (AlphaMode xor Alpha) then
   begin
     if Alpha then
      begin
        PC := New(PPhoneCollection, Init(10,10));
        Phones^.ForEach(@DoPhones);
      end else
      begin
        S.Init(SourceDir+'DN.PHN', stOpenRead, 1024);
        PC := PPhoneCollection(S.Get);
        S.Done;
        if PC = nil then PC := New(PPhoneCollection, Init(10,10));
      end;
      Dispose(Phones, Done);
      Phones := PC;
   end;
  AlphaMode := Alpha;
  List := nil;
  NewList(Phones);
end;

procedure TPhoneBox.HandleEvent;
 var  Dt: record Name: String[30]; Number: String[100]; Memo1, Memo2: String[50]; end;
      C: PCollection;
      Stream: TBufStream;
      Ph: PPhone;

 function CheckPassword(Ph: PPhoneDir): Boolean;
   var S: String;
 begin
   CheckPassword := True;
   if (Ph^.Password = '') or Ph^.Encrypted then Exit;
   repeat
      S := '';
      if ExecResource(dlgSetPassword, S) = cmCancel then
         begin CheckPassword := False; Exit end;
   until Ph^.Password = S;
   Ph^.Encrypted := True;
 end;

 procedure EditDirectory(Append: Boolean);
  var D: PDialog;
      Dt: record Name: String[30]; Password: String[15]; Memo1, Memo2: String[50]; end;
      R: TRect;
      P: PView;
      Idx: TDlgIdx;
      Ph: PPhoneDir;
{      PC: PCollection;}
 begin
  FillChar(DT, SizeOf(DT), 0);
  if not Append then
   begin
    Ph := List^.At(Focused);
    if not CheckPassword(Ph) then Exit;
    DT.Name := Ph^.Name;
    DT.Password := Ph^.Password;
    if Ph^.Memo1 <> nil then DT.Memo1 := Ph^.Memo1^;
    if Ph^.Memo2 <> nil then DT.Memo2 := Ph^.Memo2^;
    Idx := dlgEditDirectory;
   end else
    Idx := dlgAppendDirectory;

  if ExecResource( Idx, DT) <> cmOK then Exit;

  C := List; if C = nil then C := New(PPhoneCollection, Init(10,10));
  List := nil; R.A.X := Focused;
  if Append then C^.Insert(New(PPhoneDir, Init(Dt.Password, Dt.Name, Dt.Memo1, Dt.Memo2)))
     else begin
            PH^.Name := DT.Name;
            PH^.Password := DT.Password;
            DisposeStr(PH^.Memo1);
            PH^.Memo1 := NewStr(DT.Memo1);
            DisposeStr(PH^.Memo2);
            PH^.Memo2 := NewStr(DT.Memo2);
          end;
  Owner^.Lock; NewList(C); FocusItem(R.A.X); Owner^.UnLock;
  Stream.Init(SourceDir+'DN.PHN', stCreate, 1024);
  Phones := C;
  Stream.Put(C);
  Stream.Done;
 end;

 procedure EditNumber(Append: Boolean);
  var D: PDialog;
      R: TRect;
      P: PView;
      Idx: TDlgIdx;
 begin
  if Active = nil then
   begin EditDirectory(Append); Exit end;
  FillChar(DT, SizeOf(DT), 0);
  if not Append then
   begin
    Ph := List^.At(Focused);
    DT.Name := Ph^.Name;
    if Ph^.Number <> nil then DT.Number := Ph^.Number^;
    if Ph^.Memo1 <> nil then DT.Memo1 := Ph^.Memo1^;
    if Ph^.Memo2 <> nil then DT.Memo2 := Ph^.Memo2^;
    Idx := dlgEditNumber;
   end else
    Idx := dlgAppendNumber;

  repeat
    if ExecResource(Idx, DT) <> cmOK then Exit;
  until (DT.Number <> '');

  if (DT.Number = '') or (DT.Name='..') {or (DT.Name='')} then Exit;
  C := List; if C = nil then C := New(PPhoneCollection, Init(10,10));
  List := nil; R.A.X := Focused;
  if not Append and (C^.Count > Focused) then C^.AtFree(Focused);
  C^.Insert(New(PPhone, Init(Dt.Number, Dt.Name, Dt.Memo1, Dt.Memo2)));
  Owner^.Lock; NewList(C); FocusItem(R.A.X); Owner^.UnLock;
  Active^.Phones := C;
  Stream.Init(SourceDir+'DN.PHN', stCreate, 1024);
  Stream.Put(Phones);
  Stream.Done;
 end;

 procedure CopyDirectory;
  var Dt: record Name: String[30]; Password: String[15]; Memo1, Memo2: String[50]; end;
      Ph,P1: PPhoneDir;
      I : Integer;
 begin
    if (List = nil) or (Focused >= List^.Count) then Exit;
    FillChar(DT, SizeOf(DT), 0);
    Ph := List^.At(Focused); if Ph = nil then Exit;
    if not CheckPassword(Ph) then Exit;
    DT.Name := Ph^.Name;
    DT.Password := Ph^.Password;
    if Ph^.Memo1 <> nil then DT.Memo1 := Ph^.Memo1^;
    if Ph^.Memo2 <> nil then DT.Memo2 := Ph^.Memo2^;

  C := List; if C = nil then C := New(PPhoneCollection, Init(10,10));
  List := nil; I := Focused;

  P1 :=New(PPhoneDir, Init(DT.Password, Dt.Name, Dt.Memo1, Dt.Memo2));
  P1^.Encrypted := Off;
  C^.Insert(P1);
  Owner^.Lock; NewList(C); FocusItem(I); Owner^.UnLock;
  Stream.Init(SourceDir+'DN.PHN', stCreate, 1024);
  Phones := C;
  Stream.Put(C);
  Stream.Done;
 end;


 procedure CopyPhones;
 var I: Integer;
 begin
    if (List = nil) or (Focused >= List^.Count) then Exit;
    if Active = nil then  begin CopyDirectory; Exit end;
    FillChar(DT, SizeOf(DT), 0);
    Ph := List^.At(Focused); if Ph = nil then Exit;
    DT.Name := Ph^.Name;
    if Ph^.Number <> nil then DT.Number := Ph^.Number^;
    if Ph^.Memo1 <> nil then DT.Memo1 := Ph^.Memo1^;
    if Ph^.Memo2 <> nil then DT.Memo2 := Ph^.Memo2^;

  C := List; if C = nil then C := New(PPhoneCollection, Init(10,10));
  List := nil; I := Focused;
  C^.Insert(New(PPhone, Init(Dt.Number, Dt.Name, Dt.Memo1, Dt.Memo2)));
  Owner^.Lock; NewList(C); FocusItem(I); Owner^.UnLock;
  Active^.Phones := C;
  Stream.Init(SourceDir+'DN.PHN', stCreate, 1024);
  Stream.Put(Phones);
  Stream.Done;
 end;

 procedure CE; begin ClearEvent(Event) end;

 procedure DialPhone;
  var P: PPhone;
      W: PWindow;
 begin
   CE;
   if Focused=0 then Exit;
   if (Active = nil) or (List = nil) or (List^.Count = 0) then Exit;
   P := List^.At(Focused);
   New(PPh, Init(P^.Number^, P^.Name, '', ''));
   Owner^.EndModal(cmDialPhone);
 end;


 procedure EnterDir;
   var I: Integer;
       S: String;
       PD: PPhoneDir;
       P: PPhone;
 begin
   if Active = nil then
    begin
      if List^.Count = 0 then Exit;

      PD := List^.At(Focused);
      if not CheckPassword(PD) then Exit;


      DisableCommands([cmDialPhone, cmImportPhones]);
      GroupLabel^.Hide;
      ItemLabel^.Show;
      EnterButton^.Hide;
      ReturnButton^.Show;


 (*     if{ SearchMode and} (List <> nil) then
       begin
        List^.DeleteAll;
        Dispose(List, Done)
       end;
  *)
      Active := PD;
      List := nil;
      NewList(PD^.Phones);
      if (List=nil) then
       begin
         C := New(PPhoneCollection, Init(10,10));
         C^.Insert(New(PPhone, Init(' ','..',GetString(dlPhonesUpDir),'')));
         Owner^.Lock; NewList(C); Owner^.UnLock;
         Active^.Phones := C;
         Stream.Init(SourceDir+'DN.PHN', stCreate, 1024);
         Stream.Put(Phones);
         Stream.Done;
         DrawView;
         Exit;
       end;
      if (PPhone(List^.At(0))^.Name<>'..') and (List^.Count>0) then
       begin
        P:=New(PPhone, Init(' ','..',GetString(dlPhonesUpDir),''));
        List^.AtInsert(0, P);
        SetRange(List^.Count);
        DrawView;
       end;
      {HideCursor;}
    end else
    begin
      GroupLabel^.Show;
      ItemLabel^.Hide;
      EnterButton^.Show;
      ReturnButton^.Hide;
      if focused > 0 then begin DialPhone; Exit; End;

      if SearchMode and (List <> nil) then
       begin
        List^.DeleteAll;
        Dispose(List, Done)
       end;
      SearchMode := Off;
      List := nil;
      NewList(Phones);
      FocusItem(Phones^.IndexOf(Active));
      Active := nil;
      {HideCursor;}
    end;
   Message(@self, evBroadcast, cmValid, nil);
 end;

 procedure SearchPhone;
   var PC: PPhoneCollection;
       S: String;

    procedure SearchDir(Ph: PPhoneDir); far;
     procedure DoPhone(P: PPhone); far;
      var I: Integer;
     begin
       if (P <> nil) and ((Pos(S, UpCaseStr(P^.Name)) <> 0) or (Pos(S, UpCaseStr(P^.Number^)) <> 0)) then PC^.Insert(P);
     end;
    begin
     if (Ph <> nil) and (Ph^.Phones <> nil) and ((Ph^.Password = '') or (Ph^.Encrypted))
         then Ph^.Phones^.ForEach(@DoPhone);
    end;

 begin
   if (Phones = nil) or (Phones^.Count = 0) then Exit;
   S := '';
   if InputBox(GetString(dlPB_SearchPhone), GetString(dlPB_S_earchString), S, 30, 0) <> cmOK then Exit;
   S := UpCaseStr(S);
   New(PC, Init(10,10));
   PC^.Duplicates := On;
   Phones^.ForEach(@SearchDir);
   if PC^.Count = 0 then
    begin
      MessageBox(GetString(dlPB_Nofind), nil, mfError+mfOKButton);
      Exit;
    end;
   if SearchMode then begin List^.DeleteAll; Dispose(List, Done) end;
   SearchMode := True;
   List := nil;
   if Active = nil then Active := Phones^.At(Focused);
   PC^.AtInsert(0,New(PPhone, Init(' ','..',GetString(dlPhonesUpDir),'')));
   NewList(PC);
   HideCursor;
   EnterButton^.Hide;
   ReturnButton^.Show;
   GroupLabel^.Hide;
   ItemLabel^.Show;
 end;

 procedure ImportPhones;
   var F: PTextReader;
       S: String;
       P: String;
       Ph: PPhone;
       C: Char;
       I, J, K, M: Integer;
       PV: PView;
       Fr: Boolean;
       Template: String;

 procedure MakePhone;
   var I, J, K: Integer;
 begin
    for I := 2 to Length(S) do
     if (S[I] >= '0') and (S[I] <= '9') and (S[I-1]=' ') then
     begin
       P := ''; K := I; J := I;
       while (J <= Length(S)) and (S[J] in ['0'..'9','W','w','-',',','(',')']) do
        begin P := P + S[J]; Inc(J) end;
       if Length(P) < 3 then Continue;
       S := Copy(S, 1, K-1);
       DelLeft(S); DelRight(S);
       if S <> '' then
        begin
           New(Ph, Init(P, S, '', ''));
           if Active^.Phones = nil then Active^.Phones := New(PPhoneCollection, Init(10,10));
           Active^.Phones^.Insert(Ph);
           Inc(M);
        end;
       Break;
     end;
 end;

 procedure MakeTPhone;
 begin
   MakePhone;
 end;

 begin
   M := 0;
   if (Active = nil) or AlphaMode or SearchMode then Exit;
   S := GetFileNameDialog(x_x, GetString(dlPB_ImportPhones),
                                 GetString(dlFileName), fdOKButton + fdHelpButton, hsImportPhones);
   if S = '' then Exit;
   F := New(PTextReader, Init(S));
   if F=nil then
    begin MessageBox(GetString(dlFBBNoOpen)+S, nil, mfError+mfOKButton); Exit end;
   PV := WriteMsg(GetString(dlPB_Working));
   Fr := On;
   while not F^.EOF do
    begin
      UpdateWriteView(PV);
      S := F^.GetStr;
      if S <> '' then
        begin
          if Fr and (S[1] = '|') then
            begin
             Fr := Off;
             Template := S;
             Continue;
            end;
          if Template = '' then MakePhone
                           else MakeTPhone;
        end;
    end;
   if PV <> nil then PV^.Free;
   MessageBox(^C+ItoS(M)+GetString(dlPB_CnvReport), nil, mfInformation+mfOKButton);
   List := nil;
   NewList(Active^.Phones);
   Dispose(F, Done);
   Stream.Init(SourceDir+'DN.PHN', stCreate, 1024);
   Stream.Put(Phones);
   Stream.Done;
 end;

procedure CopyItem;
var S: String[230];
 begin
{  FillChar(S[1], 230, 0);
  S[0]:=#230;
  FillChar(S[1], 30, 0);
  Ph := List^.At(Focused);
  Ph^.Name;              30
  Ph^.Number^;           100
  Ph^.Memo1^;            50
  Ph^.Memo2^;            50
  Message(Application, evCommand, cmPutInClipboard, @Str);}
 end;


 var WasBroad: Boolean;

 function Registered : bOOLEAN ;
  begin
    Registered := TRUE ;
  end;

begin
 WasBroad := Event.What = evBroadcast;
 case Event.What of
  evMouseDown:if Event.Double then
               begin
                 if Event.Buttons and mbRightButton = 0 then
                  Message(Owner, evKeyDown, kbEnter, nil) else
                  Message(Owner, evKeyDown, kbSpace, nil);
                 CE;
               end;
  evCommand: case Event.KeyCode of
              cmCopyPhone: begin CE; if Registered then CopyPhones; Ce; end;
              cmImportPhones: begin CE; if Registered then ImportPhones; ce; end;
              cmDialPhone: begin CE; DialPhone end;
              cmSearchPhone: begin CE; if Registered then SearchPhone; Ce; end;
              cmOK,cmNo: begin
                      if (EnterButton^.State and sfVisible) = 0 then Focused:=0;
                      EnterDir; CE
                    end;
              cmInsertPhone: begin if not AlphaMode or SearchMode then EditNumber(On); CE end;
              cmEditPhone: begin if List^.Count > 0 then if not AlphaMode or SearchMode then
                                if not((Active <> nil) and ( focused=0 )) then EditNumber(Off); CE end;
              cmPhoneBookMode: begin  if Registered then SetList(not AlphaMode); CE end;
              cmDeletePhone: begin
                        CE;
                        if AlphaMode or SearchMode then Exit;
                        if (Active <> nil) and ( focused=0 ) then Exit;
                        if Active = nil then
                         begin
                          if Msg(dlPhoneDirDelete, nil, mf2YesButton + mfNoButton + mfConfirmation) <> cmYes then Exit;
                          if not CheckPassword(List^.At(Focused)) then Exit;
                         end else
                         if (List^.Count > 0) and
                            (MessageBox(GetString(dlPhoneDeleteQuery), nil,
                                        mfYesButton + mfNoButton + mfConfirmation ) <> cmYes) then Exit;
                        if (List <> nil) and (Focused < List^.Count) then
                          begin List^.AtFree(Focused); SetRange(List^.Count); DrawView; end;
                        Stream.Init(SourceDir+'DN.PHN', stCreate, 1024);
                        Stream.Put(Phones);
                        Stream.Done;
                     end;
             end;
   evKeyDown:
   if Event.CharCode = ' ' then DialPhone
     else if (Active <> nil) then
      Case Event.KeyCode  of
      kbCtrlIns: CopyItem;
       kbCtrlPgUp,kbCtrlSlash:
                   begin
                    Focused:=0;
                    EnterDir;
                    CE; Exit;
                   end;
       kbEnter: begin  EnterDir; CE end;
      end;
 end;
 inherited HandleEvent(Event);
 if WasBroad then begin
                    if (Info <> nil) and (List <> nil) and (List^.Count > 0) then
                       begin
                        Ph := List^.At(Focused);
                        if Ph^.Memo1 <> nil then Info^.S1 := Ph^.Memo1^ else Info^.S1 := '';
                        if Ph^.Memo2 <> nil then Info^.S2 := Ph^.Memo2^ else Info^.S2 := '';
                        Info^.DrawView;
                       end else if Info <> nil then
                                   begin
                                     Info^.S1 := '';
                                     Info^.S2 := '';
                                     Info^.DrawView;
                                   end;
                  end;
 if Active = nil then
   begin
    DisableCommands([cmDialPhone, cmImportPhones]);
    EnableCommands([cmPhoneBookMode,cmCopyPhone]);
    Owner^.Redraw
   end else
   begin
    DisableCommands([cmPhoneBookMode]);
    EnableCommands([cmImportPhones]);
    if focused=0 then DisableCommands([cmDialPhone,cmCopyPhone])
                 else EnableCommands([cmDialPhone,cmCopyPhone]);
    Owner^.Redraw
   end;

 if SearchMode then DisableCommands([cmInsertPhone, cmDeletePhone, cmEditPhone,cmImportPhones])
              else EnableCommands([cmInsertPhone, cmDeletePhone, cmEditPhone]);

end;

destructor TPhoneBox.Done;
begin
{  if (List <> nil) and (List <> Phones)
    then List^.DeleteAll;}
  if Phones <> nil then Dispose(Phones, Done);
{  if Active <> nil then Dispose(Active, Done);}
  if Info   <> nil then Dispose(Info, Done);

  inherited Done;
end;

function TPhoneBox.GetText;
 var S: String;
     P: PPhone;
begin
 P := List^.At(Item);
 S := AddSpace(P^.Name, 30);
 if TypeOf(P^)=TypeOf(TPhone) then S := S + '  '+AddSpace(P^.Number^,23);
 GetText := S;
end;

function TDialBox.GetText;
 var S: String;
     P: PPhone;
begin
 P := List^.At(Item);
 S := AddSpace(P^.Name, 30);
 if TypeOf(P^)=TypeOf(TPhone) then S := S + ' '+AddSpace(P^.Number^,23);
 GetText := S;
end;

(*
destructor TDialBox.Done;
begin
 Inherited Done;
 if List<>Nil then Dispose(List,Done);
end; *)

constructor TPhoneCollection.Init;
begin
 inherited Init(ALimit, ADelta);
 Duplicates := On;
end;

constructor TPhoneCollection.Load;
begin
 inherited Load(S);
 Duplicates := On;
end;

function TPhoneCollection.Compare;
begin
 if PPhone(P1)^.Name = PPhone(P2)^.Name then Compare := 0 else
  if (PPhone(P1)^.Name='..') OR (PPhone(P1)^.Name < PPhone(P2)^.Name) then Compare := -1
                                         else Compare := 1;
end;

procedure TPhoneCollection.FreeItem(Item: Pointer);
var PP: PPhone;
begin
 PP:=Item;
 if Item <> nil then Dispose(PP, Done);
end;

constructor TPhone.Init;
begin
 inherited Init;
 Name := AName;
 Number := NewStr(ANumber);
 Memo1 := NewStr(AMemo1);
 Memo2 := NewStr(AMemo2);
end;

constructor TPhone.Load;
begin
 Number := S.ReadStr;
 S.Read(Name[0],1);
 S.Read(Name[1], Byte(Name[0]));
 Memo1 := S.ReadStr;
 Memo2 := S.ReadStr;
end;

procedure TPhone.Store;
begin
 S.WriteStr(Number);
 S.WriteStr(@Name);
 S.WriteStr(Memo1);
 S.WriteStr(Memo2);
end;

destructor TPhone.Done;
begin
 DisposeStr(Number);
 DisposeStr(Memo1);
 DisposeStr(Memo2);
 inherited Done;
end;

constructor TPhoneDir.Init;
begin
 inherited Init;
 Name := AName;
 Memo1 := NewStr(AMemo1);
 Memo2 := NewStr(AMemo2);
 Password := APassword;
 Phones := nil;
end;

procedure CryptCol(Col: PCollection; Pass: String);
  procedure CryptPhone(P: PPhone); far;
  begin
    if P <> nil then
     with P^ do
     begin
       Name := CryptWith(Pass, Name);
       if Number <> nil then Number^ := CryptWith(Pass, Number^);
       if Memo1 <> nil then Memo1^ := CryptWith(Pass, Memo1^);
       if Memo2 <> nil then Memo2^ := CryptWith(Pass, Memo2^);
     end;
  end;
begin
  if Col <> nil then Col^.ForEach(@CryptPhone);
end;


constructor TPhoneDir.Load;
begin
 S.Read(Name[0],1);
 S.Read(Name[1], Byte(Name[0]));
 Memo1 := S.ReadStr;
 Memo2 := S.ReadStr;
 S.Read(Password, 1);
 S.Read(Password[1], Byte(Password[0]));
 Password := CryptWith('NaViGaToR', Password);
 Phones := PCollection(S.Get);
 if Phones <> nil then CryptCol(Phones, Password);
 Encrypted := False;
end;

procedure TPhoneDir.Store;
begin
 S.WriteStr(@Name);
 S.WriteStr(Memo1);
 S.WriteStr(Memo2);
 Password := CryptWith('NaViGaToR', Password);
 S.Write(Password, 1);
 S.Write(Password[1], Byte(Password[0]));
 Password := CryptWith('NaViGaToR', Password);
 if Phones <> nil then CryptCol(Phones, Password);
 S.Put(Phones);
 if Phones <> nil then CryptCol(Phones, Password);
end;

destructor TPhoneDir.Done;
begin
 DisposeStr(Memo1);
 DisposeStr(Memo2);
 if Phones <> nil then Dispose(Phones, Done);
 inherited Done;
end;

{$IFDEF Modem}
constructor TAutoDialer.Init;
 var P: PView;
     R: TRect;
begin
  R.Assign(0,1,54,12);
  inherited Init(R, GetString(dlAutoDialer));

  {Options := Options or ofCentered;}
  if (InitModem = moInitFail) or (COMPort = nil) then Fail;
  isValid := On;
  New(Phones, Init(10,10));
  R.Assign(34,2,35,7);
  P := New(PScrollBar, Init(R));
  Insert(P);

  R.Assign(2,2,34,7);
  List := New(PDialBox, Init(R, 1, PScrollBar(P)));
  Insert(List);

  R.Assign(2,1,34,2);
  Insert(New(PLabel, Init(R, GetString(dlAD_Queue), List)));

  R.Assign(2,8,35,10);
  New(Trm, Init(R));
  Insert(Trm);
  R.Assign(2,7,35,8);
  Insert(New(PLabel, Init(R, GetString(dlAD_Status), Trm)));

  List^.NewList(Phones);
  R.Assign(36,2,52,4);
  Insert(New(PButton, Init(R, GetString(dlAD_Redial), cmYes, 0)));
  R.Assign(36,4,52,6);
  Insert(New(PButton, Init(R, GetString(dlAD_ForceDial), cmNo, 0)));
  R.Assign(36,6,52,8);
  Insert(New(PButton, Init(R, GetString(dlAD_Delete), cmOk, 0)));
  R.Assign(36,8,52,10);
  HoldButton := New(PButton, Init(R, GetString(dlAD_Hold), cmHold, 0));
  Insert(HoldButton);
  UnholdButton := New(PButton, Init(R, GetString(dlAD_Unhold), cmUnhold, 0));
  UnholdButton^.Hide;
  Insert(UnholdButton);
  SelectNext(Off);
  SetPhone(AName, APhone);
  Dialer := @Self;
  ModemAnswer := '';
  ModemS := '';
  SPosX := 1;
  RegisterToPrior(@Self);
end;

function TAutoDialer.Valid;
begin
  Valid := inherited Valid(C) and isValid;
end;

constructor TAutoDialer.Load;
begin
   inherited Load(S);
   Phones := PPhoneCollection(S.Get);
   S.Read(Name, 1);
   S.Read(Name[1], Length(Name));
   S.Read(Phone, 1);
   S.Read(Phone[1], Length(Phone));
   S.Read(Hold, 1);
   GetSubViewPtr(S, List);
   GetSubViewPtr(S, Trm);
   GetSubViewPtr(S, HoldButton);
   GetSubViewPtr(S, UnholdButton);
   Trm^.S1 := '';
   Trm^.S2 := '';
   ModemS := '';
   SPosX := 0;
   if List <> nil then List^.NewList(Phones);
   Static := On;
   Dialer := @Self;
   isValid := (InitModem <> moInitFail) and (COMPort <> nil);
   RegisterToPrior( @Self );
end;

procedure TAutoDialer.Store;
begin
   if List <> nil then List^.List := nil;
   inherited Store(S);
   if List <> nil then List^.List := Phones;
   S.Put(Phones);
   S.Write(Name, 1+Length(Name));
   S.Write(Phone, 1+Length(Phone));
   S.Write(Hold, 1);
   PutSubViewPtr(S, List);
   PutSubViewPtr(S, Trm);
   PutSubViewPtr(S, HoldButton);
   PutSubViewPtr(S, UnholdButton);
end;

destructor TAutoDialer.Done;
begin
 Dialer := nil;
 if Trm<>nil then Dispose(Trm, Done);
 if List <> nil then Dispose(List,Done);
 if Phones <> nil then Dispose(Phones, Done);
 inherited Done;
end;

procedure TAutoDialer.SetPhone;
 var I: Integer;
     P: PPhone;
     C: Char;
     T: TEventTimer;
 label 1;
begin
 NewTimer(UpdTimer, 18);
 if ComPort^.CheckDCD then
  begin
    Static := On;
    Exit;
  end;
 if Phone <> '' then ModemWrite(ModemSetup.Escape+#13'ATE0'#13);
 NewTimerSecs(T, 1);
 repeat
   while not TimerExpired(T) and COMPort^.CharReady do COMPort^.GetChar(C);
 until TimerExpired(T);
 Phone := NewPhone;
 Name := NewName;
 for I := 1 to Phones^.Count do
  begin
    if PPhone(Phones^.At(I-1))^.Number^ = Phone then
      begin
        P := Phones^.At(I-1);
        Phones^.AtDelete(I-1);
        Phones^.AtInsert(0, P);
        Goto 1;
      end;
  end;
 if Phone <> '' then
  begin
    New(P, Init(Phone, Name, '', ''));
    Phones^.AtInsert(0, P);
  end;
 List^.SetRange(Phones^.Count);
1:
 List^.DrawView;
 if Phone <> '' then
  begin
   if Trm <> nil then
    begin
      Trm^.S1 := GetString(dlAD_Dialing)+Phone;
      ModemS := ''; SPosX := 1;
      Trm^.DrawView;
    end;
   Dial(Phone);
  end else Hold := True;
end;

procedure TAutoDialer.HandleEvent;
 var P, PP: PPhone;

 procedure CE; begin ClearEvent(Event) end;

  Procedure UnHold;
  begin
   with Trm^ do
    begin
      S1 := '';
      S2 := '';
      DrawView;
    end;
   HoldButton^.Show;
   UnholdButton^.Hide;
   DrawView;
  end;

  procedure Redial;
  begin
    UnHold;
    P := Phones^.At(0);
    SetPhone(P^.Name, P^.Number^);
    ModemAnswer := '';
    CE
  end;

Label 1;
begin
 case Event.What of
  evKeyDown: case Event.KeyCode of
               {kbUp: begin MoveTo(Origin.X, Origin.Y-1); CE end;
               kbDown: begin MoveTo(Origin.X, Origin.Y+1); CE end;
               kbLeft: begin MoveTo(Origin.X-1, Origin.Y); CE end;
               kbRight: begin MoveTo(Origin.X+1, Origin.Y); CE end;}
               kbESC: begin
                       Message(Application, evCommand, cmClose, nil);
                       ClearEvent(Event);
                       Exit;
                      end;
             end;
  evBroadcast: case Event.Command of
                 cmCloseDialer: begin CE; Close; Exit end;
               end;
  evCommand: case Event.Command of
               cmGetName: PString(Event.InfoPtr)^ := GetString(dlAD_Name) + Trm^.S1;
               cmYes: Redial;
               cmNo : begin
                        if List^.Focused <> 0 then
                          begin
                             UnHold;
                             PP := Phones^.At(List^.Focused);
                             Phones^.AtDelete(List^.Focused);
                             P := Phones^.At(0);
                             Phones^.AtDelete(0);
                             Phones^.AtInsert(Phones^.Count, P);
                             Phones^.AtInsert(0, PP);
                          end;
                        Redial;
                        List^.FocusItem(0);
                      end;
               cmOK : begin
                        if (Phones <> nil) and (Phones^.Count > 0) then
                         begin
                           Phones^.AtFree(List^.Focused);
                           List^.SetRange(Phones^.Count);
                         end;
                        if Phones^.Count = 0 then
                         begin
                           SetPhone('', '');
                           Message(@Self, evCommand, cmClose, nil);
                           Exit;
                         end;
                        Redial;
                      end;
              cmHold: begin
                        Hold := On;
    1:                  Static := On;
                        Phones^.At(0);
                        with Trm^ do
                         begin
                           P := Phones^.At(List^.Focused);
                           S1 := GetString(dlAD_Holded1) +' '+ P^.Number^;
                           S2 := GetString(dlAD_Holded2);
                           DrawView;
                         end;
                         SetPhone('', '');
                         HoldButton^.Hide;
                         UnholdButton^.Show;
                         DrawView;
                       end;
             cmUnhold: begin
                        if not Hold then Goto 1;
                        Hold := Off;
                        Static := COMPort^.CheckDCD;
                        UnHold;
                        Redial;
                        ModemS := '';
                        CE;
                       end;
             end;
 end;
 inherited HandleEvent(Event);
end;

procedure TAutoDialer.Update;
 const InZdes: Boolean = False;
 var Status: String;
     PP: PView;
     P: PPhone;
     I: Integer;
     C: Char;
     Tmr: TEventTimer;
     Event: TEvent;

  procedure Cheers;
    var I,J: Integer;
  begin
    for J := 1 to 2 do
      begin
        for I := 1 to 5 do
          begin
            Sound(1000);
            DelayTics(1);
            Sound(500);
            DelayTics(1);
          end;
        NoSound;
        Sound(200);
        DelayTics(1);
        NoSound;
      end;
  end;

begin
 if InZdes then Exit;
 if Hold then Exit;
 if Pause then
  begin
    if TimerExpired(PauseTimer) then
      begin
        Pause := False;
        Message(@Self, evCommand, cmYes, nil);
        Exit;
      end else Exit;
  end;
 if Static and not COMPort^.CheckDCD then
   begin
     Static := Off;
     Message(@Self, evCommand, cmYes, nil);
     Exit;
   end;
 I := 0;
 if Static then Exit;
 while (COMPort^.CharReady) and (I < 100) do
  begin
    Inc(I);
    COMPort^.GetChar(C);
    case C of
      #13: SPosX := 1;
      #10: begin
             SPosX := 1; {ModemS := '';}
             Break;
           end;
      #8: if SPosX > 1 then begin Dec(SPosX); System.Delete(ModemS, SPosX, 1) end;
      else begin
             if SPosX = 1 then ModemS := '';
             if SPosX > Length(ModemS) then AddStr(ModemS, C)
                                       else ModemS[SPosX] := C;
             Inc(SPosX);
           end;
    end;
    if ModemS[0] > #230 then System.Delete(ModemS, 1, 50);
  end;
  if (I > 0) then
    begin
     Trm^.S2 := ModemS;
     Trm^.DrawView;
    end;
  if TimerExpired(UpdTimer) and (SPosX = 1) and (ModemS <> '') then
    begin
      NewTimer(UpdTimer, 18);
      if (Pos(maNoCarrier, ModemS) <> 0) or (Pos(maBusy, ModemS) <> 0) or
         (Pos(maNoAnswer, ModemS) <> 0) then
        begin
          Phones^.AtInsert(Phones^.Count, Phones^.At(0));
          Phones^.AtDelete(0);
          Pause := True;
          NewTimerSecs(PauseTimer, Max(2, StoI(ModemSetup.Redial)));
          Trm^.S1 := '';
          Trm^.S2 := '';
          Trm^.DrawView;
          ModemS := '';
          List^.DrawView;
          InZdes := False;
          Exit;
        end else if (Pos(maNoDial, ModemS) <> 0) then
              begin
                 InZdes := On;
                 MessageBox(GetString(dlAD_NoDial), nil, mfError + mfOKButton);
                 InZdes := Off;
                 Message(@Self, evCommand, cmCancel, nil);
                 ModemS := '';
              end else if (Pos(maVoice, ModemS) <> 0) or (Pos(maConnect, ModemS) <> 0) then
                   begin
                     InZdes := On;
                     PP := _WriteMsg(GetString(dlAD_ModemSays)+ModemS);
                     NewTimer(Tmr, 36);
                     if TerminalDefaults.Options and toConnectSnd <> 0 then Cheers;
                     repeat
                        GetEvent(Event);
                     until (Event.What and (evKeyDown or evMouseDown) <> 0) or
                           (TimerExpired(Tmr));
                     InZdes := Off;
                     PP^.Free;
                     Phones^.AtFree(0);
                     List^.SetRange(Phones^.Count);
                     Static := On;
                     if (Pos(maVoice, ModemS) <> 0) then Message(@Self, evCommand, cmCancel, nil);
                     ModemS := '';
                     if Term = nil then Message(Application, evCommand, cmTerminal, nil);
                     if Phones^.Count = 0 then
                       begin
                         Event.What := evBroadcast;
                         Event.Command := cmCloseDialer;
                         Event.InfoPtr := nil;
                         PutEvent(Event);
                       end;
                   end;
    end;
end;
{$ENDIF}

end.