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

unit Messages;

interface

uses Objects, Commands, RStrings, Dos;

const

{ Message box classes }

  mfWarning      = $0000;       { Display a Warning box }
  mfError        = $0001;       { Dispaly a Error box }
  mfInformation  = $0002;       { Display an Information Box }
  mfConfirmation = $0003;       { Display a Confirmation Box }
  mfQuery        = $0004;
  mfAbout        = $0005;
{ Message box button flags }

  mfYesButton    = $0100;       { Put a Yes button into the dialog }
  mfOKButton     = $0200;       { Put an OK button into the dialog }
  mfNoButton     = $0400;       { Put a No button into the dialog }
  mfCancelButton = $8000;       { Put a Cancel button into the dialog }
  mfNextDButton  = $0800;
  mfAppendButton = $1000;
  mf2YesButton   = $2000;
  mfAllButton    = $4000;

  mfYesNoCancel  = mfYesButton + mfNoButton + mfCancelButton;
                                { Standard Yes, No, Cancel dialog }
  mfYesNoConfirm = mfYesButton + mfNoButton + mfConfirmation;
                                { Standard Yes, No  confirmation }
  mfOKCancel     = mfOKButton + mfCancelButton;
                                { Standard OK, Cancel dialog }

{ MessageBox displays the given string in a standard sized      }
{ dialog box. Before the dialog is displayed the Msg and Params }
{ are passed to FormatStr.  The resulting string is displayed   }
{ as a TStaticText view in the dialog.                          }

function MessageBox( Msg: String; Params: Pointer; AOptions: Word ): Word;


{ MessageBoxRec allows the specification of a TRect for the     }
{ message box to occupy.                                        }

function MessageBox2( Msg1,Msg2: String; Params1,Params2: Pointer; AOptions: Word ): Word;


function MessageBoxRect( var R: TRect; Msg: String; Params: Pointer;
  AOptions: Word ): Word;

function MessageBox2Rect(var R: TRect;
                             Msg1,Msg2: String;
                             Lines1: byte;
                             Params1,Params2 : Pointer;
                             AOptions: Word ): Word;

{ InputBox displays a simple dialog that allows the user to     }
{ type in a string.                                             }

function InputBox(Title: String; ALabel: String; var S: String;
  Limit: Byte; HistoryID: Word): Word;

{ InputBoxRect is like InputBox but allows the specification of }
{ a rectangle.                                                  }

function InputBoxRect(var Bounds: TRect; Title: String; ALabel: String;
  var S: String;  Limit: Byte; HistoryID: Word): Word;


function Msg( Index: TStrIdx; Params: Pointer; AOptions: Word ): Word;

function Msg2( Index1,Index2: TStrIdx;
               Params1,Params2 : Pointer ;
               AOptions: Word ): Word;

procedure ErrMsg(Index: TStrIdx);

procedure CantWrite(const FName: PathStr);

function FmtFile(const Fmt: string; const FName: string; Len: Integer): string;
function FmtStr(const Fmt: string; const S: string): string;
function FmtStrId(Id: TStrIdx; const S: string): string;
function FmtFileId(Id: TStrIdx; const FName: string): string;


const MsgActive : Boolean = False;

implementation

uses Drivers, Views, Dialogs, DNApp, DNHelp, Advance, {Tree, }Drives, Startup;

procedure ErrMsg(Index: TStrIdx); begin Msg(Index, nil, mfError + mfOkButton) end;

procedure CantWrite(const FName: PathStr);
var
  a: string[30];
  PP: Pointer;
begin
  A := Cut(FName, 30); PP := @A;
  Msg(dlCannotWrite, @PP, mfError+mfOKButton);
end;

function Msg;
begin
  Msg := MessageBox( GetString( Index ), Params, AOptions );
end;

function Msg2;
begin
  Msg2 := MessageBox2( GetString( Index1 ),
                       GetString( Index2 ),
                       Params1,
                       Params2,
                       AOptions );
end;

function MessageBox;
var
  R: TRect;
  i,j,k,l : Byte;
begin
  i:=0;l:=0;k:=0;
  for j:=1 to Length(Msg) do
      begin
       if Msg[j]=#13 then begin Inc(i);if k>l then l:=k;k:=0;end;
       if Msg[j]>#31 then Inc(k);
       if k > 70 then k := 70;
      end;
  if k>l then l:=k;if l<36 then l:=36;
  K := 0;
  for J := 0 to 7 do if AOptions and ($0100 shl J) <> 0 then Inc(K);
  if K*13 > l+6 then L := K*13 - 6;
  R.Assign(0, 0, l+6, i+7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);

  MessageBox := MessageBoxRect(R, Msg, Params, AOptions);
end;


function MessageBox2;
var
  R: TRect;
  i,j,k,l,
  i1,j1,k1,l1 : Byte;
begin

  i:=0;l:=0;k:=0;
  for j:=1 to Length(Msg1) do
      begin
       if Msg1[j]=#13 then begin Inc(i);if k>l then l:=k;k:=0;end;
       if Msg1[j]>#31 then Inc(k);
       if k > 70 then k := 70;
      end;
  if k>l then l:=k;
  if l<36 then l:=36;


  i1:=0;l1:=0;k1:=0;
  for j1:=1 to Length(Msg2) do
      begin
       if Msg2[j1]=#13 then begin Inc(i1);if k1>l then l1:=k1;k1:=0;end;
       if Msg2[j1]>#31 then Inc(k1);
       if k1 > 70 then k1 := 70;
      end;
  if k1>l then l1:=k1;
  if l1<36 then l1:=36;


  if L1>L then L := L1;
  K1 := I ;
  Inc( I , I1 );

  K := 0;
  for J := 0 to 7 do if AOptions and ($0100 shl J) <> 0 then Inc(K);

  if K*13 > l+6 then L := K*13 - 6;

  R.Assign(0, 0, l+6, i+7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);

  MessageBox2 := MessageBox2Rect(R, Msg1, Msg2,K1,Params1,Params2, AOptions);
end;

function MessageBoxRect;
const
  Cmds: array [0..7] of word =
    (cmYes, cmOK, cmNo, cmOk, cmOK, cmYes, cmOK, cmCancel);
var
  I, X, ButtonCount: Integer;
  Dialog: PDialog;
  Control: PView;
  T: TRect;
  ButtonList: array[0..4] of PView;
  S: String;
  PP: TPoint;
  Event: TEvent;

procedure AddButton;
var
  s: string;
begin
  s := GetString(TStrIdx(Integer(dlYesButton)+I));
  R.Assign(0, 0, Max(10, CStrLen(s)+4), 2);
  Control := New(PButton, Init(R, s, Cmds[i], bfNormal));
  Inc(X, Control^.Size.X + 2);
  ButtonList[ButtonCount] := Control;
  Inc(ButtonCount);
end;



begin
  Dialog := New(PDialog,
    Init(R, GetString(TStrIdx(Integer(dlMsgWarning)+AOptions and $7))));
  If AOptions and $7 = mfAbout
    then Dialog^.HelpCtx := hcAboutDialog
    else
  If AOptions and mfAllButton <> 0
    then Dialog^.HelpCtx := hcAllContainingDialog
    else
  If AOptions and ( mfYesButton + mf2YesButton ) <> 0
    then Dialog^.HelpCtx := hcYesNoDialog + Byte( AOptions and mfCancelButton <> 0 )
    else Dialog^.HelpCtx := hcWarningDialog + ( AOptions and $7 );
  with Dialog^ do
  begin
    R.Assign(3, 2, Size.X - 2, Size.Y - 3);
    FormatStr(S, Msg, Params^);
    Control := New(PStaticText, Init(R, S));
    Insert(Control);
    X := -2;
    ButtonCount := 0;
    for I := 0 to 7 do
      if AOptions and ($0100 shl I) <> 0 then AddButton;
    X := (Size.X - X) shr 1;
    for I := 0 to ButtonCount - 1 do
    begin
      Control := ButtonList[I];
      Insert(Control);
      Control^.MoveTo(X, Size.Y - 3);
      Inc(X, Control^.Size.X + 2);
    end;
    SelectNext(False);
    SelectNext(True);
    SelectNext(False);
  end;
  MsgActive:=True;
  {PP.X := 0; PP.Y := 0;
  Dialog^.MakeGlobal(PP, PP);
  Event.What := evMouseDown; Event.Double := False;
  Event.Buttons := 1; Event.Where := PP;
  Application^.PutEvent(Event);}
  MessageBoxRect := DeskTop^.ExecView(Dialog);
  Dispose(Dialog, Done);
  MsgActive:=False;
end;

function MessageBox2Rect;
const
  Cmds: array [0..7] of word =
    (cmYes, cmOK, cmNo, cmOk, cmOK, cmYes, cmOK, cmCancel);
var
  I, X, ButtonCount: Integer;
  Dialog: PDialog;
  Control: PView;
  T: TRect;
  ButtonList: array[0..4] of PView;
  S: String;
  PP: TPoint;
  Event: TEvent;
begin
  Dialog := New(PDialog,
    Init(R, GetString(TStrIdx(Integer(dlMsgWarning)+AOptions and $7))));
  if AOptions and $7 = mfAbout then Dialog^.HelpCtx := hcAboutDialog;
  with Dialog^ do
  begin

    R.Assign(3, 2, Size.X - 2, 2 + Lines1  );
    FormatStr(S, Msg1, Params1^);
    Control := New(PStaticText, Init(R, S));
    Insert(Control);

    R.A.Y := R.B.Y;
    R.B.Y := Size.Y - 3 ;
    FormatStr(S, Msg2, Params2^);
    Control := New(PStaticText, Init(R, S));
    Insert(Control);


    X := -2;
    ButtonCount := 0;
    for I := 0 to 7 do
      if AOptions and ($0100 shl I) <> 0 then
      begin
        R.Assign(0, 0, 10, 2);
        Control := New(PButton, Init(R, GetString(TStrIdx(Integer(dlYesButton)+I)), Cmds[i], bfNormal));
        Inc(X, Control^.Size.X + 2);
        ButtonList[ButtonCount] := Control;
        Inc(ButtonCount);
      end;
    X := (Size.X - X) shr 1;
    for I := 0 to ButtonCount - 1 do
    begin
      Control := ButtonList[I];
      Insert(Control);
      Control^.MoveTo(X, Size.Y - 3);
      Inc(X, Control^.Size.X + 2);
    end;
    SelectNext(False);
    SelectNext(True);
    SelectNext(False);
  end;
  MsgActive:=True;
  {PP.X := 0; PP.Y := 0;
  Dialog^.MakeGlobal(PP, PP);
  Event.What := evMouseDown; Event.Double := False;
  Event.Buttons := 1; Event.Where := PP;
  Application^.PutEvent(Event);}
  MessageBox2Rect := DeskTop^.ExecView(Dialog);
  Dispose(Dialog, Done);
  MsgActive:=False;
end;


function InputBox;
var
  R: TRect;
begin
  R.Assign(0, 0, 60, 7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);
  InputBox := InputBoxRect(R, Title, ALabel, S, Limit, HistoryID);
end;

function InputBoxRect;
var
  Dialog: PDialog;
  Control: PView;
  R: TRect;
  C: Word;
begin
  Dialog := New(PDialog, Init(Bounds, Title));
  with Dialog^ do
  begin
    R.Assign(4 + CStrLen(ALabel), 2, Size.X - 3 - 3 * Byte(HistoryID <> 0), 3);
    Control := New(PInputLine, Init(R, Limit));
    Insert(Control);
    if HistoryID <> 0 then
     begin
       R.Assign(Size.X - 6, 2, Size.X - 3, 3);
       Insert(New(PHistory, Init(R, PInputLine(Control), HistoryID)));
     end;
    R.Assign(2, 2, 3 + CStrLen(ALabel), 3);
    Insert(New(PLabel, Init(R, ALabel, Control)));
    R.Assign(Size.X - 45, Size.Y - 3, Size.X - 35, Size.Y - 1);
    Insert(New(PButton, Init(R, GetString(dlOKButton), cmOk, bfDefault)));
    Inc(R.A.X, 10); Inc(R.B.X, 10);
    {Insert(New(PButton, Init(R, '~T~ree', cmTree, 0)));
    Inc(R.A.X, 10); Inc(R.B.X, 10);}
    Insert(New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal)));
    Inc(R.A.X, 10); Inc(R.B.X, 10);
    Insert(New(PButton, Init(R, GetString(dlHelpButton), cmHelp, bfNormal)));
    Inc(R.A.X, 10); Inc(R.B.X, 10);
    SelectNext(False);
  end;
  Dialog^.SetData(S);
  Dialog^.HelpCtx := hcInputBox;
  C := DeskTop^.ExecView(Dialog);
  if C <> cmCancel then Dialog^.GetData(S);
  Dispose(Dialog, Done);
  InputBoxRect := C;
end;

function FmtFile;
var
  s,f: string;
  P: PString;
begin
  if Len = MaxInt then f := FName else f := Cut(FName, Len);
  P := @f;
  FormatStr(s, Fmt, P);
  FmtFile := s;
end;

function FmtStr(const Fmt: string; const S: string): string;
begin
  FmtStr := FmtFile(Fmt, S, MaxInt);
end;

function FmtStrId(Id: TStrIdx; const S: string): string;
begin
  FmtStrId := FmtStr(GetString(Id), S);
end;

function FmtFileId;
begin
  FmtFileId := FmtFile(GetString(Id), FName, 40);
end;




end.

