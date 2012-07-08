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

unit Colors;
interface
uses Objects, {ColorSel,} DNApp, Dialogs, Drivers, Views, Memory,
     Commands, DNStdDlg, Advance,DNHelp;

 procedure ChangeColors;
 procedure WindowManager;
 procedure SetHighlightGroups;

type

     PWindowList = ^TWindowList;
     TWindowList = object(TListBox)
      function GetText(Item: Integer; MaxLen: Integer): String; virtual;
     end;

     PWindowCol = ^TWindowCol;
     TWindowCol = object(TCollection)
      procedure FreeItem(Item: Pointer); virtual;
     end;


implementation uses Messages, RStrings, Drives, Startup;

procedure SetHighlightGroups;
 var D: Record S1, S2, S3, S4, S5: String[250]; end;
begin
 With D do
  begin
    S1 := CustomMask1; Replace(#0, ';', S1); DelFC(S1); Dec(S1[0]);
    S2 := CustomMask2; Replace(#0, ';', S2); DelFC(S2); Dec(S2[0]);
    S3 := CustomMask3; Replace(#0, ';', S3); DelFC(S3); Dec(S3[0]);
    S4 := CustomMask4; Replace(#0, ';', S4); DelFC(S4); Dec(S4[0]);
    S5 := CustomMask5; Replace(#0, ';', S5); DelFC(S5); Dec(S5[0]);
    if ExecResource(dlgHighlightGroups, D) <> cmOK then Exit;
    LowStr(S1); LowStr(S2); LowStr(S3); LowStr(S4); LowStr(S5);
    While S1[Length(S1)] in [' ', ';'] do Dec(S1[0]); Replace(';', #0,S1); CustomMask1 := #0+DelSpaces(S1)+#0;
    While S2[Length(S2)] in [' ', ';'] do Dec(S2[0]); Replace(';', #0,S2); CustomMask2 := #0+DelSpaces(S2)+#0;
    While S3[Length(S3)] in [' ', ';'] do Dec(S3[0]); Replace(';', #0,S3); CustomMask3 := #0+DelSpaces(S3)+#0;
    While S4[Length(S4)] in [' ', ';'] do Dec(S4[0]); Replace(';', #0,S4); CustomMask4 := #0+DelSpaces(S4)+#0;
    While S5[Length(S5)] in [' ', ';'] do Dec(S5[0]); Replace(';', #0,S5); CustomMask5 := #0+DelSpaces(S5)+#0;
  end;
 Message(Application, evCommand, cmUpdateConfig, nil);
 GlobalMessage(evCommand, cmPanelReread, nil);
end;

procedure ChangeColors;
 var D: PDialog;
begin
  D := PDialog(LoadResource(dlgColors));
  if Application^.ExecuteDialog(D, Application^.GetPalette) <> cmCancel then
  begin
    DoneMemory;                 { Dispose all group buffers }
    Application^.ReDraw;        { Redraw application with new palette }
  end;
  if VGASystem then GetPalette(VGA_Palette);
end;

procedure TWindowCol.FreeItem;
begin
end;

function TWindowList.GetText;
 var S: String;
     P: PView;
begin
 P := List^.At(Item);
 S := GetString(dlUnknownWindowType);
 Message(P, evCommand, cmGetName, @S);
 GetText := S;
end;

procedure WindowManager;
 label 1;
 var D: PDialog;
     R: TRect;
     PC: PWindowCol;
     PV: PView;
     S: String;
     DT: record P: PCollection; N: Word; end;

  procedure InsView(P: PView); far;
  begin
    if P = nil then Exit;
    S := '';
    if (P^.GetState(sfVisible)) then begin
      Message(P, evCommand, cmGetName, @S);
      if (S <> '') then PC^.Insert(P);
    end;
  end;

begin
  New(PC, Init(10,10));
  Desktop^.ForEach(@InsView);
  if PC^.Count = 0 then begin Dispose(PC, Done); Exit end;

  D := PDialog( LoadResource( dlgWindowManager ));

  R.Assign(D^.Size.X-13,3,D^.Size.X-12,D^.Size.Y-2);
  PV := New(PScrollBar, Init(R));
  PV^.Options := PV^.Options or ofPostProcess or ofSecurity;
  D^.Insert(PV);

  R.Assign(2,3,D^.Size.X-13,D^.Size.Y-2);
  PV := New(PWindowList, Init(R,1,PScrollBar(PV)));
  PV^.Options := PV^.Options or ofPostProcess or ofSecurity;
  PListBox(PV)^.NewList(PC);
  D^.Insert(PV);

  R.Assign(2,2,45,3);
  PV := New(PLabel, Init(R, GetString(dlWindowsLabel), PV));
  D^.Insert(PV);

1:
  R.A.X := Desktop^.ExecView(D);
  D^.GetData(DT);
  if PC^.Count > 0 then begin
    if R.A.X = cmNo then begin
      if PView(DT.P^.At(DT.N))^.Valid( cmClose ) then begin
        PView(DT.P^.At(DT.N))^.Free;
        New(PC, Init(10,10));
        Desktop^.ForEach(@InsView);
        if PC^.Count > 0 then begin
          DT.P^.AtDelete(DT.N);
          DT.P := NIL;
          D^.SetData( DT );
          If ( DT.N > 0 ) and ( DT.N >= PC^.Count ) then Dec( DT.N );
          DT.P := PC;
          D^.SetData( DT );
          goto 1
        end
      end
    end;
    if R.A.X = cmOK then PView(DT.P^.At(DT.N))^.Select;
  end;
  Dispose(D, Done);
  Dispose(PC, Done);
end;

end.