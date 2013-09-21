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

unit FlTools;

interface

procedure CM_AdvancedFilter(AFP: Pointer);
function  GetSelection(AFP: Pointer; Single: Boolean): Pointer;
function  SelectFiles(AFP: Pointer; Select,XORs: Boolean): Boolean;
procedure CM_CopyFiles(AFP: Pointer; MoveMode, Single: Boolean);
procedure InvertSelection(AFP: Pointer; Dr: Boolean);
procedure CM_CompareDirs(AFP, IP: Pointer);
procedure CM_EraseFiles(AFP: Pointer; Single: Boolean);
procedure CM_MakeList(AFP: Pointer);
procedure CM_SetAttributes(AFP: Pointer; Single: Boolean; CurPos: Integer);
procedure CM_SetShowParms(AFP: Pointer);
procedure CM_CopyTemp(AFP: Pointer);
procedure CM_ArchiveFiles(AFP: Pointer);
procedure CM_Print(AFP: Pointer);
procedure CM_ToggleDescriptions(AFP: Pointer);
procedure CM_ToggleShowMode(AFP: Pointer);
procedure CM_DragDropper(AFP: Pointer; CurPos: Integer; Ev: Pointer);
procedure CM_Dropped(AFP, EI: Pointer);
procedure DragMover(AP: Pointer; Text: String; AFC, AC: Pointer);
procedure CM_RenameSingle(AFP, PEV: Pointer);
procedure CM_SortBy(AFP: Pointer);
function  CM_ChangeDirectory(AFP: Pointer): string;
procedure CM_MakeDir(AFP: Pointer);
procedure CM_LongCopy(AFP: Pointer);
procedure CM_Branch(AFP: Pointer);


implementation
uses Advance, Dos, Objects, Dialogs, FilesCol, Views, DnApp,
     Commands, Drivers, FlPanel, FlPanelX, Drives, FileCopy, Gauge, Gauges,
     Archiver, Startup, SWE, Validate, Messages, Menus, DnHelp, FileFind,
     Tree, FBB, DnUtil;

type
    PSelectList = ^TSelectList;
    TSelectList = object(TListBox)
       function IsSelected(I: Integer): Boolean; virtual;
       procedure HandleEvent(var Event: TEvent); virtual;
    end;

procedure DrawViews(P: PFilePanelRoot);
begin
  P^.DrawView;
  if P^.InfoView <> nil then P^.InfoView^.DrawView;
end;

function TSelectList.IsSelected(I: Integer): Boolean;
begin
  IsSelected := (List <> nil) and (Copy(CnvString(List^.At(I)),1,1)= 'þ');
end;

procedure TSelectList.HandleEvent(var Event: TEvent);
  var P: PString;

procedure CE; begin ClearEvent(Event); DrawView; end;

procedure Invert;
begin
  if (List <> nil) and (Focused < List^.Count) then P := List^.At(Focused)
                              else P := nil;
  if P <> nil then
     if P^[1] = ' ' then P^[1] := #254
                    else P^[1] := ' ';
  CE
end;

procedure DoSelect(P: PString); far;
begin
 if P <> nil then
   case Event.CharCode of
    '*': if P^[1] = ' ' then P^[1] := #254
                        else P^[1] := ' ';
    '+': P^[1] := #254;
    '-': P^[1] := ' ';
   end;
end;

begin
  case Event.What of
    evMouseDown: if Event.Buttons and mbRightButton <> 0 then begin
                   inherited HandleEvent(Event);
                   Invert;
                 end;
    evKeyDown: case Event.CharCode of
                ' ': begin Event.KeyCode := kbDown; PutEvent(Event); Invert; end;
                '+','*','-': if List <> nil then begin List^.ForEach(@DoSelect); CE end;
                  else if Event.KeyCode = kbIns then
                         begin Event.KeyCode := kbDown; PutEvent(Event); Invert; end;
               end;
  end;
  if Event.What <> evNothing then inherited HandleEvent(Event);
end;

const
  AdvFWPos : TPoint = (X:-1;Y:-1);

procedure CM_AdvancedFilter;
var
   P: PFilePanelRoot absolute AFP;
   i: Byte;
   C: PStringCollection;
   ClrPlus, ClrMinus : Boolean;
   S, FileMask: string;
   FItem: Integer;


function GetMaskSelection: String;
  var PC: PStringCollection;
      I: Integer;
      D: PDialog;
      PL: PListBox;

  function MakeDialog : PDialog;
    var
      Dlg : PDialog;
      R : TRect;
      Control, Labl, Histry : PView;
   begin
      Dlg := PDialog( LoadResource( dlgAdvancedFilter ));
      with Dlg^ do begin
        R.Assign( Size.X-4,2,Size.X-3,Size.Y-4);
        Control := New(PScrollbar, Init(R));
        Insert(Control);

        R.Assign(3,2,Size.X-4,Size.Y-4);
        Control := New(PSelectList, Init(R, 3, PScrollbar(Control)));
        PL := PListBox(Control);
        PListBox(PL)^.NewList(PC);
        Insert(Control);
      end;
      MakeDialog := Dlg;
    end;

    procedure DoMake(P: PString); far;
    begin
      if (P <> nil) and (P^[1] <> ' ') then
        begin
          AddStr(FreeStr, ';');
          if I = cmNo then AddStr(FreeStr, '-');
          FreeStr := FreeStr + Copy(P^, 2, 5);
        end;
    end;

    procedure GetMasks;

       procedure DoInsert(P: PFileRec); far;
       begin
         if (P <> nil) and (P^.Attr and Directory = 0) then
           begin
             FreeStr := Copy(P^.Name, 10, 3);
             DelRight(FreeStr); UpStr(FreeStr); Insert(' *.', FreeStr, 1);
             if PC^.IndexOf(@FreeStr) < 0 then PC^.Insert(NewStr(FreeStr));
           end;
       end;

    var
      d: PDrive;
      fs, ti: string;
      fc: PFilesCollection;
    begin
      d := P^.Drive;
      if TypeOf(d^) = TypeOf(TFindDrive) then PFindDrive(d)^.AllowPack := False;
      fc := PFilesCollection(
        d^.GetDirectory(
        P^.SortMode, P^.PanelFlags, x_x, fs, ti));
      if TypeOf(d^) = TypeOf(TFindDrive) then PFindDrive(d)^.AllowPack := True;
      if (fc <> nil) and (not d^.NoMemory) then fc^.ForEach(@DoInsert);
      FreeObject(fc);
    end;

begin
  GetMaskSelection := '';
  PC := New(PStringCollection, Init(20,20));
  GetMasks;
  if (PC^.Count>0) and (not P^.Drive^.NoMemory) then
  begin
    PC^.AtInsert(0, NewStr(' *.*'));
    D := MakeDialog; D^.Options := D^.Options or ofCentered;
    PL^.FocusItem(FItem);

    if AdvFWPos.X <> -1 then
    begin
      D^.MoveTo(AdvFWPos.X, AdvFWPos.Y);
      D^.Options := D^.Options and not ofCentered;
    end;
    I := Desktop^.ExecView(D);
    AdvFWPos.X := D^.Origin.X;  AdvFWPos.Y := D^.Origin.Y;


    if I <> cmCancel then
      begin
        FItem := PL^.Focused;
        FreeStr := '';
        PC^.ForEach(@DoMake);
        if FreeStr = '' then
           begin
             FreeStr := CnvString(PC^.At(FItem));
             if I = cmNo then Insert('-', FreeStr, 1);
           end else DelFC(FreeStr);
        {if (I = cmNo) and (FreeStr <> '- *.*') then Insert('*.*;', FreeStr, 1);}
        DelLeft(FreeStr);
        GetMaskSelection := FreeStr;
      end;
    FreeObject(D);
  end;
  FreeObject(PC);
end;



 procedure Ins(const AAS: string);
 var
   Mns: Boolean;
 begin
   if (AAS = '') then Exit;
   Mns := (Copy(AAS,1,2) = '- ');
   if (ClrMinus and Mns) or
      (ClrPlus and not Mns) or
      (C^.IndexOf(@AAS)<>-1) then Exit;
    C^.Insert(NewStr(AAS));
 end;

 procedure MakeMask(P: PString); far;
 begin
   if FileMask <> '' then AddStr(FileMask,';');
   FileMask := FileMask + P^;
 end;

 begin
  FileMask := P^.FileMask;
  FItem := 0;
  repeat
    S := GetMaskSelection;
    if (P^.Drive^.NoMemory) or (S = '') then Break;
    if (S = '- *.*') or (S = x_x) then FileMask := S else
    begin
      if FileMask = x_x then begin FileMask := ''; FreeStr := S+';' end
        else FreeStr := ';' + FileMask + ';' + S + ';';
      FileMask := S; S := FreeStr;
      ClrMinus := Pos(';- *.*;',S) > 0;
      if ClrMinus then Replace('- *.*','',S);
      ClrPlus  := Pos(';*.*;',S)  > 0;
      if ClrPlus then Replace(x_x,'',S);
      if not (ClrPlus and ClrMinus) then
      begin
        if Copy(FileMask, 1, 2) = '- ' then
           Replace(';'+Copy(FileMask, 3, 5)+';',';',S) else
           Replace(';- '+FileMask+';',';',S);
        C := New(PStringCollection, Init(4,4));
        repeat
          i := PosChar(';',S);
          if i = 0 then
          begin
            Ins(S);
            Break;
          end;
          Ins(Copy(S, 1, i-1));
          Delete(S, 1, i);
        until False;
        FileMask := '';
        C^.ForEach(@MakeMask);
        FreeObject(C);
        if FileMask <> '' then FileMask := ';'+FileMask;
        if ClrPlus then FileMask := x_x + FileMask;
        if ClrMinus then FileMask := '- *.*'+FileMask;
      end;
    end;
    P^.FileMask := FileMask;
    P^.OldDelta := -1;
    P^.RereadDir;
    P^.Delta := -1;
    P^.DrawView;
  until False;
  P^.ChkNoMem;
end;

function GetSelection;
 var FC: PFilesCollection;
     P: PFilePanelRoot absolute AFP;
     I: Integer;
begin
  GetSelection := nil;
  if P^.Files^.Count = 0 then Exit;
  if (P^.SelNum = 0) or Single then
  begin
   if PFileRec(P^.Files^.At(P^.ScrollBar^.Value))^.Name[1] = '.' then Exit;
   New(FC, Init(1,1));
   FC^.Insert(P^.Files^.At(P^.ScrollBar^.Value));
  end else
      begin
       New(FC, Init(P^.SelNum,10));
       FC^.SortMode := 200;
       for I := 1 to P^.Files^.Count do
        if PFileRec(P^.Files^.At(I-1))^.Selected then
           FC^.Insert(P^.Files^.At(I-1));
      end;
 GetSelection := FC;
end;

function SelectFiles;
 var S, SN: String[12];
     I: Integer;
     P: PFilePanelRoot absolute AFP;
     PF: PFileRec;

begin
 SelectFiles := False;
 if P^.Files^.Count = 0 then Exit;
 if not SelectDialog(Select, S, XORs) then Exit;
 SelectFiles := True;
 P^.SelNum := 0;
 P^.SelectedLen := 0; P^.PackedLen := 0;
 for I := 1 to P^.Files^.Count do
  begin
   PF := P^.Files^.At(I-1); SN := PF^.Name; SN[9] := ' ';
   if ((PF^.Attr and Directory = 0) or not Select) and
      (InMask(UpStrg(SN), S) xor XORs)
      then PF^.Selected := Select;
   if PF^.Name[1] = '.' then PF^.Selected := Off;
   if PF^.Selected then
   begin
     P^.PackedLen := P^.PackedLen + PF^.PSize;
     P^.SelectedLen := P^.SelectedLen + PF^.Size;
     Inc(P^.SelNum);
   end;
  end;
  DrawViews(P);
end;

procedure CM_CopyFiles;
 var FC: PFilesCollection;
     I: Integer;
     S: PathStr;
     P: PFilePanelRoot absolute AFP;
begin
 CurrentDirectory := P^.Drive^.GetRealName;
 if P^.Files^.Count = 0 then Exit;
 FC := GetSelection(P, Single);
 if FC = nil then Exit;
 P^.Drive^.CopyFiles(FC, P, MoveMode);
 FC^.DeleteAll;
 Dispose(FC, Done);
end;

procedure InvertSelection;
 var I: Integer;
     PF: PFileRec;
     P: PFilePanelRoot absolute AFP;
begin
 P^.SelNum := 0; P^.SelectedLen := 0; P^.PackedLen := 0;
 for I := 1 to P^.Files^.Count do
  begin
   PF := PFileRec(P^.Files^.At(I-1));
   if Dr or (PF^.Attr and Directory = 0) then PF^.Selected := not PF^.Selected;
   if PF^.Name[1] = '.' then PF^.Selected := Off;
   if PF^.Selected then
   begin
     P^.SelectedLen := P^.SelectedLen + PF^.Size;
     P^.PackedLen := P^.PackedLen + PF^.PSize;
     Inc(P^.SelNum);
   end;
  end;
 DrawViews(P);
end;

procedure CM_CompareDirs;
 var DD, InThat: PFilesCollection;
     OSM1, OSM2: Word;
     I, J: Integer;
     PF: PFileRec;
     DT: record O, S: Word; end;
     Info: PView;
     P: PFilePanelRoot absolute AFP;

 procedure Cmp1(PF: PFileRec); far;
   function Cmp(AP: PFileRec): Boolean; far;
   begin
    UpdateWriteView(Info);
    Cmp := (AP^.Attr and Directory = 0) and (P^.Files^.Compare(PF, AP) = 0);
   end;
 begin
  UpdateWriteView(Info);
  if DT.S = 0 then PF^.Selected := Off;
  if (PF^.Attr and Directory = 0) and
     (InThat^.FirstThat(@Cmp) = nil) then PF^.Selected := DT.S = 0;
 end;

 label 1,2;

begin
 DT.O := 3; DT.S := 0;
 if ExecResource( dlgCompareDirs, DT) <> cmOK then Exit;

 DD := IP;
 OSM1 := PFilesCollection(P^.Files)^.SortMode;
 OSM2 := DD^.SortMode;
 PFilesCollection(P^.Files)^.SortMode := 5+DT.O;
 DD^.SortMode := 5+DT.O;

 Info := NIL;
 If DT.O and 8 <> 0 then
 begin
   Info := WriteMsg( GetString( dlComparing ));
 end;

 InThat := DD;
 P^.Files^.ForEach(@Cmp1);
 InThat := P^.Files;
 DD^.ForEach(@Cmp1);

 PFilesCollection(P^.Files)^.SortMode := OSM1;
 DD^.SortMode := OSM2;
 FreeObject(Info);
end;

procedure CM_EraseFiles;
 var FC: PFilesCollection;
     I: Integer;
     P: PFilePanelRoot absolute AFP;
begin
 FC := GetSelection(P, Single);
 if (FC = nil) or (P^.Drive = nil) then Exit;
 P^.Drive^.EraseFiles(FC);
 FC^.DeleteAll;
 Dispose(FC, Done);
 P^.SetDirName;
 P^.SendLocated;
end;


procedure CM_MakeList;
 var FC: PCollection;
     P: PFilePanelRoot absolute AFP;
begin
 if (P^.Files^.Count = 0) then Exit;
 if (P^.SelNum = 0) then
  while SelectFiles(P, On,Off) do;
 if (P^.SelNum = 0) then Exit;
 if (ActivePanel = P) and (P^.Drive^.DriveType = dtDisk)
   then CurrentDirectory := P^.DirectoryName;
 FC := GetSelection(P, Off); if FC = nil then Exit;
 MakeListFile(P, FC);
 FC^.DeleteAll;
 Dispose(FC, Done);
 P^.SetDirName;
end;

procedure CM_SetAttributes;
 var D: record T: String[8]; D: String[10]; S, C: Word; end;
     I,UU,DD: Integer;
     K: Word;
     S: String;
     F: File;
     R: TRect;
     PInfo: PWhileView;
     DTT, DTT1: LongInt;
     DT, DT1: DateTime;
     DateSet,TimeSet : boolean ;
     Res: Word;
     Dlg: PDialog;
     P: PFilePanelRoot absolute AFP;
     PF: PFileRec;
     ok: Boolean;

  Function CutNumber( var S : String ): word ;
  var S1  : string[10];
      i,j : Integer;
     begin
        if not ok then Exit;
        if S = '' then
        begin
          ok := False;
          Exit;
        end;
        S1 := '';
        while (not (S[1] in ['0'..'9'])) and (S<>'') do DelFC(S);
        while (S[1] in ['0'..'9']) and (S<>'') do
        begin
          AddStr(S1,S[1]);
          DelFC(S);
        end;
        Val(s1,i,j);
        ok := j=0;
        CutNumber := I;
      end ;
  procedure DoHideInputLines( AP: PView ); far;
  begin
    If ( TypeOf( AP^ ) = TypeOf( TInputLine ))
    or ( TypeOf( AP^ ) = TypeOf( TLabel )) then AP^.State := ( AP^.State or sfDisabled ) and not sfVisible;
  end;
begin
 if (P^.Files^.Count = 0) or (P^.Drive^.DriveType >= dtArc) then Exit;
 FillChar(D, Sizeof(D), 0);
 if (P^.SelNum > 0) and not Single then
  begin if ExecResource( dlgFilesAttr, D) <> cmOK then Exit end
  else
  begin
   Single := On;
   if (P^.SelNum = 0) or Single then PF := P^.Files^.At(CurPos)
    else for I := 1 to P^.Files^.Count do
          begin PF := P^.Files^.At(I-1); if PF^.Selected then Break; end;
   If PF^.Name[ 1 ] = '.' then Exit;
   S := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));
   AddStr(S, #0); Dec(S[0]);
   D.C := GetFileAttr(S);
   Dlg := PDialog( LoadResource( dlgFileAttr ));
   if D.C and Directory = 0 then
     begin
       Assign(F, S);
       FileMode := $40;
       ClrIO; Reset(F);
       if IOResult <> 0 then Exit;
       GetFTime(F, DTT); Close(F);
       UnpackTime(DTT, DT);
       D.T := SStr(DT.Hour, 2, '0')+':'+SStr(DT.Min, 2, '0')+':'+SStr(DT.Sec, 2, '0');
       D.D := ItoS(DT.Day)+'-'+SStr(DT.Month, 2, '0')+'-'+ItoS(DT.Year mod 100);
     end else
       Dlg^.ForEach( @DoHideInputLines );
   if D.C and DOS.Archive <> 0 then D.S := 1;
   if D.C and Hidden <> 0  then D.S := D.S or 2;
   if D.C and ReadOnly <> 0  then D.S := D.S or 4;
   if D.C and SysFile <> 0  then D.S := D.S or 8;
   Dlg^.SetData( D );
   if Desktop^.ExecView( Dlg ) <> cmOK then begin
     Dispose( Dlg, Done );
     Exit;
   end;
   Dlg^.GetData( D );
   Dispose( Dlg, Done );
   D.C := $FF;
  end;

 DTT1 := $FFFFFF;

 DateSet := D.D <>'';
 TimeSet := D.T <>'';

 with DT1 do
  begin
   ok := TimeSet;
   Hour := CutNumber(D.T);
   Min  := CutNumber(D.T);
   if ok then
     begin
       Sec := CutNumber(D.T);
       ok := True;
     end;
   TimeSet := ok and not ((Hour > 24) or (Min>59) or (sec>59));


   ok := DateSet;
   Day  := CutNumber(D.D);
   Month:= CutNumber(D.D);
   Year := CutNumber(D.D);
   DateSet := ok and not ((Day>31 ) or ( Day<1 ) or (Month>12) or (Month<1));

   if DateSet then
     if Year < 80 then Inc(Year,2000)
        else if Year < 100 then Inc(Year,1900) ;

  end;

 R.Assign(1,1,26,8);
 New(PInfo, Init(R));
 PInfo^.Top := GetString(dlSetAttr);
 PInfo^.Bottom := '';
 PInfo^.SetState(sfShadow, On);
 Desktop^.Insert(PInfo);

 if Single then begin UU := CurPos+1; DD := UU end
           else begin UU := 1; DD := P^.Files^.Count end;
 for I := UU to DD do
  begin
   PF := P^.Files^.At(I-1);
   if PF^.Selected or Single then
    begin
     S := MakeFileName(PF^.Name);
     PInfo^.Write(1, S);
     S := MakeNormName(PF^.Owner^, S);
     Assign(F, S);
     AddStr(S, #0); Dec(S[0]);
     K := GetFileAttr(S);

     RES := 0;
     if (K and Directory = 0) and
        (K and ReadOnly > 0) then RES := SetFileAttr(S , 0);

     if RES = 0 then

      begin

     if D.C and 1 <> 0 then K := K and (not DOS.Archive);
     if D.C and 2 <> 0 then K := K and (not Hidden);
     if D.C and 4 <> 0 then K := K and (not ReadOnly);
     if D.C and 8 <> 0 then K := K and (not SysFile);
     if D.S and 1 <> 0 then K := K or DOS.Archive;
     if D.S and 2 <> 0 then K := K or Hidden;
     if D.S and 4 <> 0 then K := K or ReadOnly;
     if D.S and 8 <> 0 then K := K or SysFile;

     if (K and Directory = 0) and TimeSet or DateSet then
      begin
       FileMode := $42 ;
       Reset(F);
       GetFTime(F, DTT);
       UnPackTime(DTT, DT);
       if TimeSet then begin DT.Hour := DT1.Hour; DT.Sec := DT1.Sec; DT.Min := DT1.Min; end;
       if DateSet then begin DT.Year := DT1.Year; DT.Day := DT1.Day; DT.Month := DT1.Month; end;
       PackTime(DT, DTT1);
       DT.Sec := 0;
       UnPackTime(DTT1, DT);
       SetFTime(F, DTT1);
       Close(F);
      end;

     SetFileAttr(S, K and not Directory);

     end;

     if not Single then PF^.Selected := Off;
    end;
  end;
 Desktop^.Delete(PInfo);
 Dispose(PInfo, Done);
 if (ActivePanel = P) and (P^.Drive^.DriveType = dtDisk)
   then CurrentDirectory := P^.DirectoryName;
 RereadDirectory(P^.DirectoryName);
 if P^.Drive^.DriveType = dtDisk then GlobalMessage(evCommand, cmRereadInfo, nil);
 GlobalMessage(evCommand, cmRereadTree, @P^.DirectoryName);
 P^.SetDirName;
end;

procedure CM_SetShowParms;
 var I,J,Old: Word;
     Idx: TDlgIdx;
     P: PFilePanelRoot absolute AFP;
begin
 Old := P^.ShowFlags;
 case P^.Drive^.DriveType of
   dtFind, dtTemp: Idx := dlgFindParms;
   dtArc: Idx := dlgArcParms;
   else Idx := dlgDiskParms;
 end;
 I := P^.ShowFlags;
 J := ExecResource( Idx, I );
 case J of
  cmOK: P^.ShowFlags := I;
  cmNo: P^.ShowFlags := P^.Drive^.GetFullFlags;
  cmYes: P^.ShowFlags := 0;
  else Exit;
 end;
 P^.DeltaX := 0;
 P^.Drive^.Flags := P^.ShowFlags;
 if ((P^.Drive^.DriveType = dtDisk) or (P^.Drive^.DriveType = dtArvid))
     and ((P^.ShowFlags xor Old) and (psShowDescript+psShowLongDesc) <> 0) then P^.RereadDir;
 DrawViews(P);
 P^.SendLocated;
 DrawViews(P);
end;

procedure CM_CopyTemp;
 var FC: PFilesCollection;
     C: TCopyRec;
     P: PFilePanelRoot absolute AFP;
begin
 FC := GetSelection(P, Off);
 C.Owner := P;
 C.FC := FC;
 if FC = nil then Exit;
 GlobalEvent(evBroadcast, cmCopyToTemp, @C);
 FC^.DeleteAll;
 Dispose(FC, Done);
end;


procedure CM_ArchiveFiles;
  var PC: PCollection;
      S: NameStr;
      P: PFilePanelRoot absolute AFP;
begin
  if P^.Drive^.DriveType >= dtArc then Exit;
  PC := GetSelection(P, Off);
  if PC = nil then Exit;
  if PC^.Count = 1 then S := Copy(PFileRec(PC^.At(0))^.Name, 1, 8)
                   else S := Copy(GetName(P^.DirectoryName),1,255*Byte(P^.Drive^.DriveType=dtDisk));
  DelRight(S);
  MakeArchive(S, PC, Off, P);
  PC^.DeleteAll;
end;

procedure CM_Print;
  var N: Integer;
      P: PFilePanelRoot absolute AFP;
begin
  if (P^.Drive^.DriveType  in [ dtDisk, dtFind, dtTemp ] ) then
     PrintFiles(GetSelection(P, False), P);
end;

procedure CM_ToggleDescriptions;
var P: PFilePanelRoot absolute AFP;
begin
  case P^.Drive^.DriveType of
    dtDisk,
    dtArvid: begin
               P^.ShowFlags := P^.ShowFlags xor psShowDescript;
               P^.Drive^.Flags := P^.ShowFlags;
               P^.DeltaX := 0;
               P^.RereadDir;
               DrawViews(P);
             end;
  end;
end;

procedure CM_ToggleShowMode;
var P: PFilePanelRoot absolute AFP;
begin
  P^.DeltaX := 0;
  if P^.ShowFlags <> P^.Drive^.GetFullFlags then
     P^.ShowFlags := P^.Drive^.GetFullFlags else
     P^.ShowFlags := 0;
  P^.Drive^.Flags := P^.ShowFlags;
  P^.RereadDir;
  DrawViews(P);
end;

type
    PDragger = ^TDragger;
    TDragger = object(TView)
     Text: PString;
     constructor Init(R: TRect; AText: String);
     procedure Draw; virtual;
     destructor Done; virtual;
    end;

procedure DragMover;
 var R: TRect;
     Mover: PView;
     Event: TEvent;
     P: PPoint absolute AP;
     FC: PFilesCollection absolute AFC;
     C: PCopyRec absolute AC;

function ContainsMouse(P: PView): Boolean; far;
begin
  ContainsMouse := (P^.State and sfVisible <> 0) and
    P^.MouseInView(R.A);
end;

begin
 Desktop^.MakeLocal(P^, R.A);
 Mover := New(PDragger, Init(R, Text));
 Desktop^.Insert(Mover);
 Desktop^.GetExtent(R);
 Event.Where := P^; Event.What := evMouseDown; Event.Buttons := mbLeftButton;
 Event.Double := False;
 Mover^.DragView(Event, dmDragMove, R, Mover^.Size, Mover^.Size);
 R.A := Mover^.Origin;
 Mover^.Free;
 C^.FC := FC; Desktop^.MakeGlobal(R.A, R.A); C^.Where := R.A;
 Message(Desktop^.FirstThat(@ContainsMouse), evBroadcast, cmDropped, C);
 Dispose(FC, Done);
end;

constructor TDragger.Init;
begin
 AText := ' '+AText+' ';
 R.B.X := R.A.X + Length(AText);
 R.B.Y := R.A.Y + 1;
 inherited Init(R);
 Options := Options or ofTopSelect;
 Text := NewStr(AText);
 SetState(sfShadow, True);
end;

procedure TDragger.Draw;
 var B: TDrawBuffer;
     C: Word;
begin
 C := $3B30;
 MoveStr(B, Text^, C);
 WriteLine(0,0,Size.X, Size.Y, B);
end;

destructor TDragger.Done;
begin
 DisposeStr(Text);
 inherited Done;
end;

procedure CM_DragDropper;
 var C: TCopyRec;
     FC: PFilesCollection;
     I: Integer;
     S: String;
     P: PFilePanelRoot absolute AFP;

begin
 C.Owner := P;
 if (P^.Files^.Count = 0) or (P^.Files^.Count <= CurPos) then Exit;
 if (PFileRec(P^.Files^.At(CurPos))^.Selected) or
    (typeof(P^) <> typeof(TFilePanel))
  then FC := GetSelection(P, Off)
    else if PFileRec(P^.Files^.At(CurPos))^.Name[1] <> '.' then
         begin
          New(FC, Init(10,10));
          FC^.Insert(P^.Files^.At(CurPos));
         end else Exit;
 for I := 1 to FC^.Count do FC^.AtPut(I-1, CopyFileRec(FC^.At(I-1)));
 if FC^.Count = 1 then S := MakeFileName(PFileRec(FC^.At(0))^.Name)
                  else S := ItoS(FC^.Count)+GetString(dlSelectedFiles);
 DragMover(@TEvent(Ev^).Where, S, FC, @C);
end;

procedure CM_Dropped;
var
  P: PFilePanelRoot absolute AFP;
  MPos: TPoint;
  I,J,K: Integer;
  Ev: TEvent;
  S: string;
begin
  MPos := PCopyRec(EI)^.Where;
  P^.MakeLocal(MPos, MPos);
  I := P^.Delta + (MPos.X div P^.LineLength)* (P^.Size.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0))
       + MPos.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0);
  if (PCopyRec(EI)^.Owner = AFP) and
     ((MPos.Y <= 0) or (I < 0) or (I >= P^.Files^.Count) or
      (PFileRec(P^.Files^.At(I))^.Attr and Directory = 0)) then Exit;
  CopyDirName := P^.DirectoryName;
  if PCopyRec(EI)^.Owner <> nil then
  begin
   if (P^.Drive^.DriveType = dtArc) then
       begin
          CopyDirName := P^.Drive^.GetRealName;
          SkipCopyDialog := Confirms and cfMouseConfirm = 0;
          Message(PCopyRec(EI)^.Owner, evBroadcast, cmCopyCollection,
                  PCopyRec(EI)^.FC);
          SkipCopyDialog := Off;
          Exit;
       end;
   Ev.What := evBroadcast;
   Ev.Command := cmUnarchive;
   Ev.InfoPtr := EI;
   PCopyRec(EI)^.Owner^.HandleEvent(Ev);
   if Ev.What = evNothing then Exit;
  end;
  if (I < P^.Files^.Count) and (I >= 0) then
    begin
     S := P^.DirectoryName;
     if (MPos.Y > 0) and (PFileRec(P^.Files^.At(I))^.Attr and Directory <> 0)
          then S := MakeNormName(S, MakeFileName(PFileRec(P^.Files^.At(I))^.Name));
     CopyDirName := S;
    end;
   SkipCopyDialog := Confirms and cfMouseConfirm = 0;
   if SkipCopyDialog then
     begin
       S := CopyDirName; if (S[0] > #3) and (S[Length(S)] = '\') then Dec(S[0]);
       UpStr(S);
       for J := 0 to PCopyRec(EI)^.FC^.Count-1 do
         with PFileRec(PCopyRec(EI)^.FC^.At(J))^ do
           if (Attr and Directory <> 0) and (UpStrg(MakeNormName(Owner^, MakeFileName(Name))) = S) then Exit;
     end;
   P^.Drive^.CopyFilesInto(PCopyRec(EI)^.FC, PCopyRec(EI)^.Owner,
                        ShiftState and 7 <> 0);
   SkipCopyDialog := Off;
end;


procedure CM_RenameSingle;
  var PIF: PInputFName;
      R: TRect;
      S, S2: String[12];
      N1,N2: Array [0..12] of Char;
      DosE: Word;
      SSS: String;
      PF: PFileRec;
      Nm: String[20];
      P: PFilePanelRoot absolute AFP;
      Event: PEvent absolute PEV;
      ScrollBarValue: Integer;

  procedure UpdateDesc;
    var F, F1: Text;
        I: Integer;
        S: String;
        N: String[20];
  begin
    N := MakeFileName(PF^.Name); UpStr(N);
    Assign(F, PF^.DIZ^.Owner^); ClrIO;
    Reset(F);
    if IOResult <> 0 then Exit;
    Assign(F1, GetPath(PF^.DIZ^.Owner^)+'$@$DN$@$.$$$');
    Rewrite(F1);
    if IOResult = 0 then
      begin
        while not EOF(F) do
          begin
            ReadLn(F, S);
            if (S <> '') and (S[1] <> ' ') then
              begin
                I := Pos(' ', S); if I = 0 then I := Length(S)+1;
                if UpStrg(Copy(S, 1, I-1)) = Nm then
                  begin
                    Delete(S, 1, I-1);
                    Insert(N, S, 1);
                  end;
              end;
            WriteLn(F1, S);
          end;
        Close(F1); ClrIO; Close(F);
        Erase(F); Rename(F1, PF^.DIZ^.Owner^);
      end;
    Close(F); ClrIO;
  end;

begin
  if (P^.Files = nil) then Exit;
  ScrollBarValue := P^.ScrollBar^.Value;
  if ScrollBarValue >= P^.Files^.Count then Exit;
  PF := P^.Files^.At(ScrollBarValue);
  if (PF^.Name[1] = '.') or
     not (P^.Drive^.DriveType in [dtDisk, dtTemp, dtFind, dtList]) then Exit;
  Nm := MakeFileName(PF^.Name); UpStr(Nm);
  R.Assign(0,0,12,1);
  R.Move(P^.LastCurPos.X, P^.LastCurPos.Y);
  R.Move(P^.Origin.X, 0);
  S := MakeFileName(PF^.Name); S2 := S;
  New(PIF, Init(R, 12)); PIF^.DrawShift := 0; P^.Owner^.Insert(PIF); S := PF^.Name; S[9] := '.';
  PIF^.SetData(S); PIF^.State := PIF^.State xor sfCursorIns;
  PIF^.SetValidator(New(PFilterValidator, Init([#32..#255]-
                                              ['+','|','>','<',']','[','*','?'])));
  R.A.X := P^.Owner^.ExecView(PIF); PIF^.GetData(S);
  if UpStrg(MakeFileName(S)) = UpStrg(S2) then R.A.X := cmCancel;
  S := MakeFileName(S);
  if R.A.X <> cmCancel then
    begin
      GetDir(0, SSS);
      ChDir(PF^.Owner^);
      FillChar(N1, SizeOf(N1), 0);
      FillChar(N2, SizeOf(N2), 0);
      Move(S[1], N2, Length(S));
      Move(S2[1], N1, Length(S2));
      asm
       push ds
       push bp
       push ss
       mov  ax, ss
       mov  es, ax
       mov  ds, ax
       lea  di,n2
       lea  dx,n1
       mov  ah,$56
       int  $21
       jc   @@1
       xor  ax, ax
      @@1:
       mov  DOSE, ax
       pop  ss
       pop  bp
       pop  ds
      end;
      if DOSE <> 0 then
          MessageBox(GetString(dlFCNoRename1)+GetString(dlDIFile)+^M^C+S2
                     +GetString(dlFCNoRename2)+S, nil, mfError+mfOKButton)
        else begin
               PF^.Name := Norm12(S);
               if PF^.Attr and Directory <> 0 then UpStr(PF^.Name)
                   else begin
                          LowStr(PF^.Name);
                          if PF^.Attr and SysFile <> 0 then PF^.Name[1] := UpCase(PF^.Name[1]);
                        end;
               PF^.Name[9] := ' ';
               if PF^.DIZ <> nil then UpdateDesc;
             end;
      ChDir(SSS);
      P^.Owner^.Delete(PIF);
      Dispose(PIF, Done);
      GlobalMessage(evCommand, cmRereadDir, PF^.Owner);
      if R.A.X <> cmOK then
         begin
           Event^.What := evKeyDown; Event^.KeyCode := R.A.X;
           Event^.InfoPtr := nil; P^.PutEvent(Event^);
         end;
    end else PIF^.Free;
end;

procedure CM_SortBy;
 var S: String[6];
     Menu: PMenu;
     PM: PMenuItem;
     N, W: Word;
     R: TRect;
     PV: PView;
     P: PFilePanelRoot absolute AFP;
begin
  S := GetString(dlPanelSortHotkeys);
  Menu := NewMenu(
    NewItem(GetString(dlSortName),'',kbNoKey,12001,0,
    NewItem(GetString(dlSortExt), '',kbNoKey,12002,0,
    NewItem(GetString(dlSortSize),'',kbNoKey,12003,0,
    NewItem(GetString(dlSortDate),'',kbNoKey,12004,0,
    NewItem(GetString(dlSortType),'',kbNoKey,12030,0,
    NewItem(GetString(dlSortUnsorted),'',kbNoKey,12000,0,
  nil)))))));
  N := 5; W := 15;
  DeskTop^.GetExtent(R);
  R.A := P^.Origin; P^.Owner^.MakeGlobal(R.A, R.A); Desktop^.MakeLocal(R.A, R.A);
  if R.A.X < 0 then R.A.X := 0 else if R.A.X + W > R.B.X then R.A.X := R.B.X - W;
  if R.A.Y < 0 then R.A.Y := 0 else if R.A.Y + N + 2 > R.B.Y then R.A.Y := R.B.Y - N - 2;
  R.B.X := R.A.X + 100; R.B.Y := R.A.Y + 100; {R.B := R.A;}
  PV := New(PMenuBox, Init(R, Menu, nil));
  PV^.HelpCtx := hcSortBy;
  if P^.Sortmode = 30
    then PM := PMenuBox(PV)^.FindItem(S[6])
    else PM := PMenuBox(PV)^.FindItem(S[P^.SortMode+1]);
  Menu^.Default := PM;
  N := DeskTop^.ExecView(PV);
  Dispose(PV, Done);
  DisposeMenu(Menu);
  if ( N >= 12000 ) and ( P^.SortMode + 12000 <> N ) then begin
    P^.SortMode := N-12000;
    P^.RereadDir;
    P^.DrawView;
    P^.SetDirName;
  end
end;

function CM_ChangeDirectory;
var P: PFilePanelRoot absolute AFP;
    S: PathStr;
begin
 CM_ChangeDirectory := '';
 if P^.Drive^.DriveType <> dtDisk then
   begin
     ClrIO;
     GetDir(0, S);
     if Abort then Exit;
   end else S := P^.DirectoryName;
 CM_ChangeDirectory :=
    ChangeDir(GetString(dlChangeDir), Byte(S[1]) - 64);
end;

procedure CM_MakeDir;
 var Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     PF: PFileRec;
     I, J: Integer;
     P: PFilePanelRoot absolute AFP;
begin
 P^.Drive^.MakeDir; if CreatedDir = '' then Exit;
 FSplit(CreatedDir, Dr, Nm, Xt);
 if (Dr[0] > #3) and (Dr[Length(Dr)] = '\') then Dec(Dr[0]);
 if Dr <> P^.DirectoryName then Exit; J := -1;
 for I := 1 to P^.Files^.Count do
  begin PF := P^.Files^.At(I-1);
        if UpStrg(MakeFileName(PF^.Name)) = UpStrg(DelSpaces(Nm+Xt)) then
           begin J := I - 1; Break end;
  end;
 if J >= 0 then P^.ScrollBar^.SetValue(J);
 P^.ChDirName;
end;


procedure CM_LongCopy;
 var S: String;
     P: PFilePanelRoot absolute AFP;
     PF: PFileRec;
begin
 if (P^.Files^.Count = 0) or (P^.Drive^.DriveType >= dtArc) then Exit;
 PF := P^.Files^.At(P^.ScrollBar^.Value);
 if PF^.Attr and Directory <> 0 then Exit;
 S := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));
 LongCopy(S);
 if (ActivePanel = P) and (P^.Drive^.DriveType = dtDisk)
   then CurrentDirectory := P^.DirectoryName;
 RereadDirectory(P^.DirectoryName);
 if P^.Drive^.DriveType = dtDisk then
  begin
   GlobalMessage(evCommand, cmRereadInfo, nil);
   GlobalMessage(evCommand, cmRereadTree, @(P^.DirectoryName));
  end;
end;

procedure CM_Branch;
var PP: Pointer;
    P: PFilePanelRoot absolute AFP;
begin
  if P^.Drive^.DriveType = dtDisk then
    begin
      PP := OpenDirectory(P^.DirectoryName);
      if PP <> nil then Message(P, evCommand, cmInsertDrive, PP);
    end;
end;



end.