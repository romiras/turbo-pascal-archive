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

UNIT
  FLPanelX;


INTERFACE

USES
  Advance, Objects, Views, Drivers, Dos, FilesCol, HideView, Drives;

TYPE
  PFilePanelRoot = ^TFilePanelRoot;
  TFilePanelRoot = object(THideView)
   isValid, MSelect, SelectFlag, Loaded, ChangeLocked: Boolean;
   InfoView, DirView, DriveLine: PHideView;
   Delta, OldDelta, OldPos, DeltaX: Integer;
   Files: PFilesCollection;
   SortMode: Byte;
   DirectoryName, OldDirectory: PathStr;
   FileMask: String;
   SearchMask: String[12];
   ScrollBar: PScrollBar;
   DrawDisableLvl, SelNum, LineLength: Integer;
   SelectedLen, PackedLen: TSize;
   WasActive, PosChanged, CommandEnabling,
   QuickSearch, ViewEnabled: Boolean;
   TotalInfo, FreeSpace: String[50];
   PanelFlags, ShowFlags: Word;
   SearchX: Integer;
   LastDriveFlags: Word;
   Drive: PDrive;
   ForceReading: Boolean;
   DriveState: Word;
   LastCurPos: TPoint;

   constructor Init(var Bounds: TRect; ADrive: Integer; AScrBar: PScrollBar);
   constructor Load(var S: TStream);
   procedure Store(var S: TStream);
   destructor Done; virtual;
   procedure Awaken; virtual;
   procedure ChDirName;
   procedure ShowView; virtual;
   procedure HideView; virtual;
   procedure CommandHandle(var Event: TEvent);
   procedure ChangeBounds(var Bounds: TRect); virtual;
   function  Valid(Command: Word): Boolean; virtual;
   procedure GetUserParams(var FName, List: String);
   procedure ReadDirectory;
   procedure RereadDir;
   procedure SetDirName; virtual;
   procedure SendLocated;
   procedure IncDrawDisabled;
   procedure DecDrawDisabled;
   procedure ChkNoMem;
  end;

{                                                                        }
{ WARNING: The following vars are mirrored in FLPANEL.PAS via ABSOLUTEs! }
{                                                                        }

CONST
  ActivePanel: Pointer = NIL;
  CtrlWas: Boolean = False;
  DirsToChange: Array [0..9] of PString = (nil,nil,nil,nil,nil,nil,nil,nil,nil,nil);
  CurFileActive: PString = nil;
  CurFilePassive: PString = nil;


VAR
  CurrentDirectory: PathStr;
  PShootState: Word;


IMPLEMENTATION

uses
{$IFDEF DEBUG} DEBUG, {$ENDIF}
  Messages, DnApp, DnHelp, Startup, Commands, Histries, HistList, FlTools,
  FileFind, 

  {$IFDEF MODEM}
  NavyLink, 
  {$ENDIF}

  CmdLine, ArcView, Archiver, UUcode, DiskImg, DiskInfo,
  FileCopy, DnUtil
  {DNApp, Startup, Memory, FileCopy, Messages, Menus, DiskInfo, Validate,
  Dialogs, Commands, HistList, Tree, FBB, RStrings, UUCode, Swe,
  ArcView, CmdLine, Histries, Archiver, Gauges, Gauge, FileFind, FlPanel,
  NavyLink, DiskImg, FlTools};

procedure TFilePanelRoot.IncDrawDisabled;
begin
  Inc(DrawDisableLvl);
end;

procedure TFilePanelRoot.DecDrawDisabled;
begin
  Dec(DrawDisableLvl);
  ChkNoMem;
end;

procedure TFilePanelRoot.ChkNoMem;
begin
  if Drive^.NoMemory and (DrawDisableLvl = 0) then
  begin
    Application^.OutOfMemory;
    Drive^.NoMemory := False;
  end;
end;

constructor TFilePanelRoot.Init;
begin
 inherited Init(Bounds);
 ForceReading := Off;
 CommandEnabling := On;
 ChangeLocked := Off;
 Abort := Off;
 HelpCtx := hcFilePanel;
 GrowMode := gfGrowHiY + gfGrowHiX;
 Options := Options or ofSelectable or ofTopSelect or ofFirstClick;
 PanelFlags := PanelDefaults.Show;

 EventMask := $FFFF;

 ScrollBar := AScrBar; Loaded := Off; OldDelta := -1; PosChanged := Off;
 isValid := On;

 if (ADrive <= 0) or not ValidDrive(Char(ADrive+64)) then ADrive := 0;
 Drive := New(PDrive, Init(ADrive, @Self, -1));
 DeltaX := 0;

 if Abort then begin IsValid := False; Exit end;
 {GetDir(ADrive, DirectoryName);}

 {Drive^.Owner := @Self;}
 FileMask := x_x; Files := nil;

 if PanelDefaults.Sort < 4 then SortMode := PanelDefaults.Sort + 1 else
   if PanelDefaults.Sort = 4 then SortMode := 30
                             else SortMode := 0;
 IncDrawDisabled; MSelect := Off;
 QuickSearch := Off; ViewEnabled := Off;
 if not Abort then ReadDirectory;
 isValid := isValid and not Abort; DecDrawDisabled;
end;

constructor TFilePanelRoot.Load;
 var I: Integer;
begin
 inherited Load(S);
 ChangeLocked := Off;
 GetPeerViewPtr(S, ScrollBar);
 GetPeerViewPtr(S, DirView);
 GetPeerViewPtr(S, InfoView);
 GetPeerViewPtr(S, DriveLine);
 Drive := PDrive(S.Get);
 if Drive = nil then New(Drive, Init(0, @Self, -1));
 DeltaX := 0;
 Drive^.RereadDirectory('');
 {Drive^.Owner := @Self;}
 if Drive <> nil then DirectoryName := Drive^.GetDir;
 S.Read(FileMask[0], 1); S.Read(FileMask[1], Length(FileMask));
 S.Read(SortMode, 1);
 S.Read(ShowFlags, 2);
 Drive^.Flags := ShowFlags;
 S.Read(PanelFlags, 2);
 S.Read(Delta, 2); OldDelta := -1; PosChanged := Off;
 S.Read(ForceReading, 1);
 Files := PFilesCollection(S.Get);
 if Files <> nil then
  for I := 0 to Files^.Count-1 do PFileRec(Files^.At(I))^.Owner := @Drive^.CurDir;
 Loaded := On; MSelect := Off; isValid := True; QuickSearch := Off; ViewEnabled := Off;
 CommandEnabling := On;
end;

procedure TFilePanelRoot.Awaken;
begin
 if (Size.X > 0) and (GetState(sfVisible)) then RereadDir;
 if (DriveLine <> nil) then
   if (FMSetup.Show and fmsDriveLine <> 0) then
     begin
       if not DriveLine^.GetState(sfVisible) then DriveLine^.Show;
     end else
          if DriveLine^.GetState(sfVisible) then DriveLine^.Hide;
end;

procedure TFilePanelRoot.Store;
begin
 inherited Store(S);
 PutPeerViewPtr(S, ScrollBar);
 PutPeerViewPtr(S, DirView);
 PutPeerViewPtr(S, InfoView);
 PutPeerViewPtr(S, DriveLine);
 if (ActivePanel <> @Self) or (Drive^.DriveType <> dtDisk)
    or (StartupData.UnLoad and osuPreserveDir <> 0) then S.Put(Drive) else S.Put(nil);
 S.Write(FileMask, 1 + Length(FileMask));
 S.Write(SortMode, 1);
 S.Write(ShowFlags, 2);
 S.Write(PanelFlags, 2);
 S.Write(Delta, 2);
 S.Write(ForceReading, 1);
 PFilesCollection(Files)^.Selected := ScrollBar^.Value;
 S.Put(Files);
end;

function TFilePanelRoot.Valid;
begin
 Valid := isValid;
 if (Command = cmClose) then Valid := Drive^.Disposable;
end;

destructor TFilePanelRoot.Done;
 var P: PDrive;
begin
 if Files <> nil then Dispose(Files, Done);
 if Drive <> nil then Dispose(Drive, Done);
 inherited Done;
end;

procedure TFilePanelRoot.ShowView;
begin
 if InfoView <> nil then InfoView^.ShowView;
 if DirView <> nil then DirView^.ShowView;
 if (ScrollBar <> nil) and GetState(sfActive+sfSelected) then
   ScrollBar^.Show;
 if Loaded then RereadDir;
 inherited ShowView;
end;

procedure TFilePanelRoot.HideView;
begin
 if InfoView <> nil then InfoView^.HideView;
 if DirView <> nil then DirView^.HideView;
 if (ScrollBar <> nil) then ScrollBar^.Hide;
 inherited HideView;
end;

procedure TFilePanelRoot.ChangeBounds;
 var R: TRect;
     I: Integer;
begin
 I := Byte(( Drive^.DriveType = dtFind ) or ( Drive^.DriveType = dtTemp ) or ( Drive^.DriveType = dtArc ));
 I := Byte(FMSetup.Show and fmsDivider <> 0) +
      Byte(PanelFlags and fmiCurrent <> 0)*(1 + I) +
      Byte(PanelFlags and fmiSelected <> 0) +
      Byte(PanelFlags and fmiTotals <> 0) +
      Byte(PanelFlags and fmiFree <> 0)*Byte(I=0);
 Dec(Bounds.B.Y, I);
 SetBounds(Bounds);
 R := Bounds; R.B.Y := R.A.Y; Dec(R.A.Y);
 if DirView <> nil then DirView^.SetBounds(R);
 R := Bounds; R.A.Y := R.B.Y; Inc(R.B.Y, I);
 if InfoView <> nil then InfoView^.SetBounds(R);
 if DriveLine <> nil then
   begin
     R.A.Y := R.B.Y + Byte(FMSetup.Show and fmsDriveLine = 0);
     Inc(R.B.Y);
     DriveLine^.SetBounds(R);
     if (FMSetup.Show and fmsDriveLine <> 0) then
       begin
         if not DriveLine^.GetState(sfVisible) then DriveLine^.Show;
       end else
            if DriveLine^.GetState(sfVisible) then DriveLine^.Hide;
   end;
 if ScrollBar <> nil then
  begin R :=Bounds; R.A.X := R.B.X; Inc(R.B.X); ScrollBar^.SetBounds(R) end
end;

procedure TFilePanelRoot.SendLocated;
 var S: String;
     R: Integer;
begin
 if (Files^.Count = 0) or (Drive^.DriveType = dtArc) or
    (State and sfVisible = 0) then Exit;
 R := ScrollBar^.Value; if R >= Files^.Count then Exit;
 if not ViewEnabled and (Drive^.Flags and psShowLongDesc = 0) then Exit;
 S := MakeNormName(PFileRec(Files^.At(R))^.Owner^,
      MakeFileName(PFileRec(Files^.At(R))^.Name));
 if ViewEnabled or (Drive^.Drivetype < dtArc)
    then Message(Owner, evCommand, cmLoadViewFile, @S);
end;


procedure TFilePanelRoot.RereadDir;
 var P,PP,CurP: PFileRec;
     I, J, Pos: Integer;
     FC {,FCC}: PFilesCollection;
     NewDir: PathStr;
     BB: Boolean;
     TF: TFileRec;
     WasLoaded, B: Boolean;


  {
  procedure DoPut(P: PFileRec); far;
  begin
   if P^.Selected or (P = CurP) then FCC^.Insert(P);
  end;
  }

begin
 Abort := Off; OldDelta := Delta; PosChanged := Off; WasLoaded := Loaded;
 if Loaded then begin
  LineLength := Drive^.CalcLength(ShowFlags);;
  ScrollBar^.SetParams(PFilesCollection(Files)^.Selected, 0, Files^.Count - 1,
                      (Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0)) *
                      ((Size.X+1) div LineLength), 1);
  CurrentDirectory := ActiveDir;
  Loaded := Off;
  if WasActive and (ActiveDir <> DirectoryName) then
   begin DirectoryName := ActiveDir; ReadDirectory;
         ScrollBar^.SetValue(0); Exit end;
 end;
 if (Files = nil) or (Files^.Count = 0) then begin OldDelta := -1; Delta := 0 end;
 ClrIO; Loaded := Off; ChDirName;
 if Abort then begin Dispose(Files, Done); New(Files, Init(10, 10)); Abort := Off; Exit; end;
 NewDir := Drive^.GetRealDir;
 if Abort then begin Dispose(Files, Done); New(Files, Init(10, 10)); Abort := Off; Exit; end;
 if GetState(sfFocused) then CurrentDirectory := DirectoryName;
 if Files^.Count = 0 then
  begin  DirectoryName := NewDir; ReadDirectory; ChDirName; Exit end;
 FC := PFilesCollection(Files); Files := nil; IncDrawDisabled;
 Pos := ScrollBar^.Value;
 if NewDir <> DirectoryName then
  begin Pos := 0; DirectoryName := NewDir end;
 I := 0; CurP := FC^.At(Pos);
 while (I < FC^.Count) do
   begin
     P := FC^.Items^[I];
     if (P <> CurP) and (P <> nil) and not P^.Selected then
       begin FC^.Items^[I] := nil; FC^.FreeItem(P) end;
     Inc(I);
   end;
 ReadDirectory;
 B := (Drive^.DriveType <> dtTemp) and (Drive^.DriveType <> dtFind);
 if (FC^.Count > 0) then
  begin

   {New(FCC, Init(SelNum+1,10));
   FCC^.SortMode := 1;
   FC^.ForEach(@DoPut);
   FC^.DeleteAll;
   Dispose(FC, Done);
   FC := FCC;}

   SelNum := 0; SelectedLen := 0; PackedLen := 0; BB := Off;
   for I := 0 to FC^.Count-1 do
    begin
      PP := FC^.At(I);
      if (PP <> nil) and PP^.Selected or (PP = CurP) then
        for J := 0 to Files^.Count - 1 do
         begin
           P := Files^.Items^[J];
           if (P^.Name = PP^.Name) and (WasLoaded or (P^.Owner^ = PP^.Owner^)) then
             begin
              TF := PP^;
              PP^ := P^;
              P^ := TF;
              PP^.Selected := TF.Selected;
              FC^.Items^[I] := P;
              Files^.Items^[J] := PP;
              if PP^.Name[1] = '.' then PP^.Selected := Off;
              if PP^.Selected then
              begin
                SelectedLen := SelectedLen + PP^.Size;
                PackedLen := PackedLen + PP^.PSize;
                Inc(SelNum);
              end;
              Break;
           end;
         end;
    end;
   {for I := 0 to Files^.Count-1 do
    begin
     PP := Files^.At(I);
     if FC^.Search(PP, J) then
      begin
       P := FC^.Items^[J];
       PP^.Selected := P^.Selected;
       P^ := PP^;
       FC^.Items^[J] := PP;
       Files^.Items^[I] := P;
      end;
    end;
   for I := 1 to Files^.Count do
    begin
     P := Files^.At(I-1);
     if not BB and (MakeFileName(PFileRec(CurP)^.Name) = MakeFileName(P^.Name)) then
       begin BB := On; Pos := I - 1; end;
    end;}
   if not BB then
    begin
     for I := 0 to Files^.Count-1 do
      begin
        P := Files^.At(I);
        if (CurP^.Name = P^.Name) and (CurP^.Owner^ = P^.Owner^) then
           begin Pos := I; break; end;
      end;
    end;
  end else Pos := 0;
 Dispose(FC, Done);
 ScrollBar^.SetValue(Pos);
 DecDrawDisabled;
 DirectoryName := NewDir;
 SetDirName;
 if GetState(sfFocused) and (Drive^.DriveType = dtDisk) then
   GlobalMessage(evCommand, cmRereadInfo, nil);
 SendLocated;
end;

procedure TFilePanelRoot.SetDirName;
begin
{ if (ActivePanel = @Self) then
  begin Drive^.ChDir(DirectoryName); if TypeOf(Drive^) = TypeOf(TDrive) then CurrentDirectory := DirectoryName; end;}
 DrawView;
 if InfoView <> nil then InfoView^.DrawView;
 if DirView <> nil then DirView^.DrawView;
end;

procedure TFilePanelRoot.ChDirName;
begin
 SetDirName;
end;

procedure TFilePanelRoot.ReadDirectory;
 var SR: SearchRec;
     P: PFileRec;
     D: DateTime;
     I: Integer;
     DrNm: PathStr;
     AllFiles: Boolean;
     FreeSpc, TotalLen: LongInt;
     S: String;
begin
 LineLength := Drive^.CalcLength(ShowFlags);
 ShowFlags := Drive^.Flags;
 Drive^.Owner := @Self;
 case Drive^.DriveType of
   dtArc: HelpCtx := hcArchives;
   dtLink: HelpCtx := hcLinkPanel;
    else HelpCtx := hcFilePanel;
 end;
 DOSError := 0;
 PosChanged := Off; Loaded := Off;
 Abort := Off; AllFiles := FileMask = x_x; ClrIO; FreeSpc := 0;
 FreeSpace := ''; TotalInfo := ''; TotalLen := 0;
 if Files <> nil then Dispose(Files, Done);
 Files := PFilesCollection(Drive^.GetDirectory(SortMode, PanelFlags, FileMask, FreeSpace, TotalInfo));
 if Files = nil then Files := New(PFilesCollection, Init(10,10));
 PFilesCollection(Files)^.Owner := @Self;
 SelNum := 0; SelectedLen := 0; PackedLen := 0;
 PFilesCollection(Files)^.SortMode := SortMode;
 if Abort then Exit;

 if DriveState and dsInvalid > 0 then Exit ;

 if Drive^.DriveType = dtDisk then DirectoryName := Drive^.GetRealDir;
   DirectoryName := Drive^.GetDir;
 if GetState(sfSelected) then Message(Owner, evCommand, cmChangeTree, @DirectoryName);

 ScrollBar^.SetParams(ScrollBar^.Value, 0, Files^.Count - 1, (Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0))
                                        * ((Size.X+1) div LineLength), 1);
 {Delta := 0;}
 if (ActivePanel = @Self) and (Drive^.DriveType = dtDisk)
    then CurrentDirectory := DirectoryName
    else ChDir(CurrentDirectory);
 if Drive^.DriveType = dtDisk then Message(CommandLine, evCommand, cmRereadInfo, nil);
 Message(Owner, evCommand, cmRereadInfo, nil);
 if DriveLine <> nil then DriveLine^.DrawView;
 ChkNoMem;
end;

procedure TFilePanelRoot.GetUserParams;
  var PF: PFileRec;
      S: String[1];

 procedure MakeTempList;
  var T: Text;
      I: Integer;
 begin
  Assign(T, List); ClrIO;
  Rewrite(T); if Abort then Exit;
  for I := 1 to Files^.Count do
   begin
    PF := Files^.At(I-1);
    if (PF^.Selected) or (I-1=ScrollBar^.Value) and (SelNum=0) then
       WriteLn(T, MakeFileName(PF^.Name));
   end;
  Close(T);
 end;

begin
  FName := ''; List := '';
  if not GetState(sfVisible) or (Files = nil) or (Files^.Count = 0) then Exit;
  PF := Files^.At(ScrollBar^.Value);
  FName := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));
  if GetState(sfSelected) then S := '$' else S := '';
  List := SwpDir+'$$$dn$$'+S+'.lst';
  MakeTempList;
end;

PROCEDURE TFilePanelRoot.CommandHandle;
var
  PF: PFileRec;
  CurPos: Integer;
  {S: String;}
  MPos: TPoint;
  LastRDelay: Word;
  {I, J: Integer;
  PDr: PDrive;}

 procedure CE;begin ClearEvent(Event) end;
 procedure CED;begin ClearEvent(Event); DrawView end;

 procedure Rebound;
  var R: TRect;
 begin
  GetBounds(R);
  R.A.Y := 1; R.B.Y := Owner^.Size.Y - 1;
  ChangeBounds(R);
  Owner^.Redraw;
 end;

 procedure GotoSingle(Name: String);
  var A: Integer;
 begin
  Name := MakeFileName(UpStrg(Norm12(Name)));
  A := 0;
  While (A < Files^.Count) and
        (MakeFileName(UpStrg(PFileRec(Files^.At(A))^.Name)) <> Name) do Inc(A);
  if A >= Files^.Count then A := 0; IncDrawDisabled;
  OldDirectory := DirectoryName;
  ScrollBar^.SetValue(A);
  DecDrawDisabled;
  Rebound;
 end;

 function ChangeUp: Boolean;
  var S: String;
 begin
  if ChangeLocked then Exit;
  ChangeUp := Drive^.IsUp;
  DeltaX := 0;
  if Drive^.IsUp then Drive^.ChangeUp(S) else Exit;
  IncDrawDisabled; ReadDirectory; AddToDirectoryHistory(DirectoryName);
  if S <> '' then GotoSingle(UpStrg(S));
  DecDrawDisabled;
  Rebound;
 end;

 procedure GotoFile(FileName: PathStr);
  var Dr: PathStr;
      Nm: NameStr;
      Xt: ExtStr;
      Name: String[12];
      A: Integer;
 begin
  if ChangeLocked then Exit;
  FSplit(FileName, Dr, Nm, Xt);
  if Copy(Dr, 1, 5) = cLINK_ then  Delete(Dr, 1, 5);
  if (Dr[Length(Dr)] = '\') and ((Dr[2] <> ':') or (Dr[0] > #3)) then Dec(Dr[0]);
  While (Dr[Length(Dr)] = '.') or (Dr[Length(Dr)] = ' ') do Dec(Dr[0]);
  if (Dr[2] = ':') and ((Drive^.DriveType <> dtDisk) and (Drive^.DriveType <> dtLink)) then
    begin Dispose(Drive, Done); New(Drive, Init(Byte(Upcase(Dr[1]))-64, @Self, -1)); end;
  {if (Xt = '..') and ChangeUp then Exit;}
  DirectoryName := Dr; IncDrawDisabled; OldDirectory := Dr;
  DeltaX := 0;
  Drive^.ChDir(DirectoryName); DirectoryName := Drive^.GetDir;
  OldDelta := -1; Delta := 0;
  ReadDirectory; AddToDirectoryHistory(DirectoryName);
  DecDrawDisabled;
  if Nm = '' then Name := '..          '
             else Name := Nm+Xt;
  GotoSingle(Name);
 end;

 function  isSeldir : boolean ;
   begin
      isSelDir := False ;
      if Files^.Count = 0 then Exit;
      if CurPos >= Files^.Count then Exit;
      isSelDir := PFileRec(Files^.At(CurPos))^.Attr and Directory <> 0;
   end;

 procedure ViewFile(Command: Word);
  var S: String;
      P: PFileRec;
 begin
  if Files^.Count = 0 then Exit;
  CE; if CurPos >= Files^.Count then Exit;
  P := Files^.At(CurPos);
  if P^.Attr and Directory <> 0 then Exit;
  asm
   mov ax,Command
   cmp ax,cmIntEditFile
   jnz @@1
   mov ax,cmIntFileEdit;
   jmp @@0
@@1:
   cmp ax,cmIntViewFile
   jnz @@2
   mov ax,cmIntFileView;
   jmp @@0
@@2:
   cmp ax,cmEditFile
   jnz @@3
   mov ax,cmFileEdit;
   jmp @@0
@@3:
   mov ax,cmFileView;
@@0:
   mov Command, ax
  end;
  Drive^.UseFile(P, Command);
 end;

 procedure Recount;
  var I: Integer;
      PF: PFileRec;
 begin
  SelectedLen := 0; PackedLen := 0; SelNum := 0;
  for I := 1 to Files^.Count do
   begin
    PF := Files^.At(I-1);
    if PF^.Selected then
    begin
      SelectedLen := SelectedLen + PF^.Size;
      PackedLen := PackedLen + PF^.PSize;
      Inc(SelNum);
    end;
   end;
   DrawView;
   if InfoView <> nil then InfoView^.DrawView;
 end;

 procedure Setup;
  var R: record Sort,Show: Integer; S: String; end;
      BB: TRect;
 begin
  R.Sort := SortMode;
  if R.Sort = 0 then R.Sort := 5 else
    if R.Sort = 30 then R.Sort := 4 else Dec(R.Sort);
  R.Show := PanelFlags;
  R.S := FileMask;
  if ExecResource(dlgPanelSetup, R) <> cmOK then Exit;
  if R.Sort = 5 then R.Sort := 0 else
   if R.Sort = 4 then R.Sort := 30 else Inc(R.Sort);

  if (ActivePanel = @Self) and (Drive^.DriveType = dtDisk)
    then CurrentDirectory := DirectoryName;
  SortMode := R.Sort;
  PanelFlags := R.Show;
  FileMask := R.S; RereadDir;
  Rebound;
  ChDirName;
 end;

 procedure CountLen;

  procedure DoCount(P: PFileRec); far;
  begin
    if (P^.Attr and Directory <> 0) and (P^.Selected) and (not Abort) then Drive^.GetDirLength(P);
  end;

 begin
  CE; if (PF = nil) or ((PF^.Attr and Directory = 0) and (SelNum = 0)) then Exit;
  if PF^.Attr and Directory <> 0 then Drive^.GetDirLength(PF);
  if SelNum > 0 then Files^.ForEach(@DoCount); Abort := False;
  Recount;
  DrawView;
  if InfoView <> nil then InfoView^.DrawView;
 end;

 var WasFull: Boolean;

 procedure InsertDrive;
 begin
  if ChangeLocked then Exit;
  if (PDrive(Event.InfoPtr)^.DriveType = dtTemp) and
     (Drive^.DriveType = dtTemp) then begin CE; Exit end;
  if PDrive(Event.InfoPtr)^.DriveType in [dtDisk, dtLink] then
    begin
      if Drive <> nil then Dispose(Drive, Done); Drive := nil;
    end;
  PDrive(Event.InfoPtr)^.Prev := Drive;
  Drive := Event.InfoPtr;
  if (Drive^.DriveType = dtArc) or (Drive^.DriveType = dtArvid) then Drive^.ChDir(#0);
  {if WasFull then Drive^.Flags := Drive^.GetFullFlags else Drive^.Flags := 0;}
  Drive^.Owner := @Self;
  CE;
  DeltaX := 0;
  ReadDirectory; AddToDirectoryHistory(DirectoryName);
  ScrollBar^.SetValue(0);
  Rebound;
 end;

 procedure EraseGroup;
 begin
   Drive^.EraseFiles(Event.InfoPtr);
   CE;
 end;

 procedure SelecType(S: Boolean);
  procedure Sel(P: PFileRec); far;
  begin
   if (P^.TType = PF^.TType) and (P^.Name[1] <> '.') then P^.Selected := S;
  end;
 begin
  if (CurPos >= Files^.Count) {or (PanelFlags and fmiHiliteFiles = 0)} then Exit;
  PF := Files^.At(CurPos);
  Files^.ForEach(@Sel);
  Recount; Owner^.Redraw;
 end;

 procedure SelectExt(S: Boolean; G1, G2: Integer; Invert: Boolean);
  var SS: NameStr;

  procedure Sel(P: PFileRec); far;
  begin
   if ((SS = Copy(P^.Name, G1, G2)) xor Invert) and (P^.Name[1] <> '.') then P^.Selected := S;
  end;

 begin
  if (CurPos >= Files^.Count) then Exit;
  PF := Files^.At(CurPos);
  SS := Copy(PF^.Name, G1, G2);
  Files^.ForEach(@Sel);
  Recount; Owner^.Redraw;
 end;

 procedure HandleCommand;
  var FC: PCollection;
      W: Word;
 begin
   W := Event.Command; CE; FC := nil;
   case W of
    cmExtractTo, cmArcTest: begin FC := GetSelection(@Self, Off); if FC = nil then Exit; end;
   end;
   Drive^.HandleCommand(W, FC);
   if FC <> nil then
    begin
      FC^.DeleteAll;
      Dispose(FC, Done);
    end;
 end;

 function ReplaceDrive(C: char): Boolean;
 var
   PDr: PDrive;
 begin
    ReplaceDrive := Off;
    New(PDr, Init(Byte(C)-64, @Self, -1));
    if Abort then
     begin Dispose(PDr, Done); Exit; end;
    Dispose(Drive, Done);
    Drive := PDr;
    DeltaX := 0;
    {if WasFull then Drive^.Flags := Drive^.GetFullFlags
               else Drive^.Flags := 0;}
    DirectoryName := Drive^.GetDir;
    if GetState(sfActive+sfSelected) then
       SetState(sfActive+sfSelected, On);
    Rebound;
    ReplaceDrive := On;
 end;

 function MakeFName(Idx: Integer; Mode: Boolean): String;
 begin
   PF := Files^.At(Idx);
   FreeStr := MakeFileName(PF^.Name);
   if PosChar('.', FreeStr) = 0 then AddStr(FreeStr, '.');
   if (Drive^.DriveType <> dtDisk) then FreeStr := MakeNormName(PF^.Owner^, FreeStr);
   if Mode then Insert(' ', FreeStr, 1);
   MakeFName := FreeStr;
 end;

 procedure DoChange(SS: PathStr);
   var SR: SearchRec;
       S: string;
 begin
   S := SS;
   ClrIO;
   FindFirst(SS, $3f xor VolumeID, SR);
   if Abort then Exit;
   if ((DOSError <> 0) or (SR.Attr and Directory = 0)) and
      (Copy(SS,Length(SS)-1,2) <> ':\') then
     Exit;
   if SS = '' then Exit;
   if Drive^.DriveType <> dtDisk then
      begin
        if not ReplaceDrive(S[1]) then Exit;
      end;
   SS := MakeNormName(SS,'..'); OldDelta := -1;
   GotoFile(SS);
   Rebound;
 end;

 procedure DoExcept(P: PFileRec); far;
 begin
   if (P <> nil) and (P^.Attr and Directory = 0) then
     begin
       FreeStr := P^.Name; FreeStr[9] := '.';
       if not InFilter(FreeStr, FileMask) then P^.Size := -100;
     end;
 end;

 procedure _GetFName;
 var
   S: string;
 begin
   GetUserParams(S, PString(Event.InfoPtr)^);
   S := MakeFileName(PF^.Name);
   PString(Event.InfoPtr)^ := S + ' ' + PString(Event.InfoPtr)^;
 end;

 procedure _DoPush(a: Boolean);
 var
   S: string;
   B,C: Boolean;
 begin
   if not GetState(sfVisible) then Exit;
   if a and (Drive^.DriveType<>dtDisk) then PString(Event.InfoPtr)^ := CurrentDirectory
   else
   begin
     S := Drive^.GetRealName;
     if (S <> '') and (S <> CurrentDirectory) then PString(Event.InfoPtr)^ := S;
   end;
 end;

 procedure _DoRereadDir;
 var
   S: string;
   I: Integer;
 begin
   S := PString(Event.InfoPtr)^;
   if (S[0] > #3) and (S[Length(S)] = '\') then Dec(S[0]);
   I := Length(S);
   if (Drive^.DriveType <> dtDisk) or (Copy(PString(Event.InfoPtr)^, 1, I) =
      Copy(DirectoryName, 1, I)) then
       begin
        Drive^.RereadDirectory(S);
        RereadDir;
       end else
        if (Drive^.DriveType = dtDisk) and (S[1] = DirectoryName[1]) then
         begin
           if PanelFlags and fmiFree <> 0 then
              Drive^.GetFreeSpace(FreeSpace);
           if InfoView <> nil then InfoView^.DrawView;
         end;
 end;

 procedure _PushName;
 var
   S: string;
 begin
   S := Drive^.GetRealName;
   if S <> '' then HistoryAdd(Event.InfoByte, S);
 end;

 procedure _ChangeDrive;
 var
   S: string;
 begin
   if ChangeLocked then Exit;
   CE;
   Abort := Off; OldDelta := -1;
   MPos.X := Origin.X + Size.X div 2;
   MPos.Y := Origin.Y+1;
   Owner^.MakeGlobal(MPos, MPos);
   if (DirectoryName[2] = ':') then S[1] := DirectoryName[1]
       else if (Drive^.DriveType = dtLink) then S[1] := '+'
            else S[1] := CurrentDirectory[1];
   S := SelectDrive(MPos.X, MPos.Y, S[1], On);
   if S = cTEMP_ then
   begin
     Event.InfoPtr := New(PTempDrive, Init);
     InsertDrive; Exit;
   end else
   {$IFDEF MODEM}
   if Copy(S,1,1) = '+' then
   begin
     Event.InfoPtr := NewLinkDrive(s[2]);
     InsertDrive; Exit;
   end else
   {$ENDIF}
   if S <> '' then
    begin
     ClrIO;
     if Drive^.DriveType <> dtDisk then
      begin
       if not ReplaceDrive(S[1]) then Exit;
      end else
      begin
        Drive^.ChDir(S);
        if Abort then
         begin  ClrIO; SetDirName; ChDir(CurrentDirectory); Exit; end;
        S := Drive^.GetDir;
      end;
     IncDrawDisabled; DirectoryName := S; ReadDirectory;
     AddToDirectoryHistory(DirectoryName);
     DecDrawDisabled; SetDirName;
    end;
   ChDirName;
 end;

 procedure _ChangeDrv;
 var
   S: string;
 begin
   if ChangeLocked then Exit;
   S := PString(Event.InfoPtr)^; CE;
   if S = cTEMP_ then
   begin
    Event.InfoPtr := New(PTempDrive, Init);
    InsertDrive; Exit;
   end
   {$IFDEF MODEM}
   else if S[1] = '+' then
   begin
     Event.InfoPtr := NewLinkDrive(S[2]);
     InsertDrive; Exit;
   end
   {$ENDIF};
   GetDir(Byte(S[1])-64, S); if Abort then Exit;
   DoChange(S);
 end;

 procedure _DoChangeDirectory;
 var
   S: string;
 begin
   S := PString(Event.InfoPtr)^;
   CE; UpStr(S);
   if Drive^.DriveType <> dtDisk then Exit;
   if (S[0] > #3) and (S[Length(S)] = '\') then Dec(S[0]);
   {if S = DirectoryName then Exit;}
   {S := S + '\..';
   DelDoubles('\\', S); GotoFile(S);}
   Drive^.ChDir(S);
   IncDrawDisabled;
   ReadDirectory;
   AddToDirectoryHistory(DirectoryName);
   ScrollBar^.SetValue(0);
   DecDrawDisabled; DrawView;
   GlobalMessage(evCommand, cmRereadInfo, nil);
   Owner^.Redraw;
 end;

 procedure _DoDirHistory;
 var
   S: string;
 begin
   S := DirHistoryMenu;
   if S <> '' then
   begin
     if Drive^.DriveType <> dtDisk then ReplaceDrive(S[1]);
     Message(@Self, evCommand, cmChangeDirectory, @S);
   end;
   CE;
 end;

 procedure _CloseLinked;
 var
   S: string;
 begin
   if Drive^.DriveType = dtLink then
   begin
     System.GetDir(0, S);
     ReplaceDrive(S[1]);
     RereadDir;
   end;
 end;

 procedure _DoCtrl;
 var
   S: string;
 begin
   if ((ShiftState and 3 <> 0) or (CmdLine.Str = ''))
      and (FMSetup.Show and fmsDriveLine <> 0) then
   begin
     if (DirectoryName = cTEMP_) then DirectoryName[1] := '*';
     if Drive^.DriveType = dtArc then
       begin
          DirectoryName[1] := PArcDrive(Drive)^.ArcName[1];
       end;
     DirectoryName[2] := ':';
     repeat
       if Event.What = evKeyDown then
        begin
          case Event.KeyCode of
            kbCtrlLeft: repeat
                          if DirectoryName[1] > #65 then Dec(DirectoryName[1])
                           else if DirectoryName[1] = #65 then DirectoryName[1] := '*'
                                                    else DirectoryName[1] := 'Z';
                         until ValidDrive(DirectoryName[1]) or (DirectoryName[1] = '*');
            kbCtrlRight: repeat
                           if DirectoryName[1] in ['A'..'Y'] then INC(DirectoryName[1])
                            else if DirectoryName[1] = 'Z' then DirectoryName[1] := '*'
                                                     else DirectoryName[1] := 'A';
                          until ValidDrive(DirectoryName[1]) or (DirectoryName[1] = '*');
          end;
          DriveLine^.DrawView;
        end;
       GetEvent(Event);
     until ShiftState and kbCtrlShift = 0;
     if DirectoryName[1] = '*' then S := cTEMP_
                               else S := DirectoryName[1]+':';
     DirectoryName := S;
     Message(@Self, evCommand, cmChangeDrv, @S);
     DirectoryName := Drive^.GetDir;
     DriveLine^.DrawView;
     Abort := Off;
     DriveLine^.DrawView;
     CE;
   end;
 end;

 procedure _CtrlIns;
 var
   S: string;
   I: Integer;
 begin
   S := ''; CE;
   if (Files = nil) or (Files^.Count <= 0) then Exit;
   if SelNum = 0 then S := MakeFName(CurPos, Off)
     else for I := 0 to Files^.Count-1 do
     if PFileRec(Files^.At(I))^.Selected then S := S + MakeFName(I, I > 0);
    Message(Application, evCommand, cmPutInClipboard, @S);
 end;

 procedure _CtrlEnter;
 var
   S: string;
   PF: PFileRec;
 begin
   CE;
   if Files^.Count = 0 then Exit;
   PF := Files^.At(CurPos);
   if (PF <> nil) then
   begin
    S := MakeFileName(PF^.Name);
    if (PF^.Attr and Directory = 0) and
       (PosChar('.', S) = 0) then AddStr(S, '.');
    if S[1] = '.' then S := PF^.Owner^+'\'
     else if ShiftState and 3 <> 0 then
       S := MakeNormName(PF^.Owner^, S);
    Message(CommandLine, evCommand, cmInsertName, @S);
   end;
 end;

 function _AltEnter: Boolean;
 var
   S: string;
 begin
   if OS210 and (Drive^.DriveType = dtDisk) and (Pos(#0+Copy(PF^.Name,10,3)+#0, Executables) > 0)
      and (ShiftState and (kbCtrlShift or 3) <> 0) then
   begin
     PShootState := ShiftState;
     S := MakeFileName(PF^.Name);
     if ShiftState and kbCtrlShift = 0 then S := '>'+S
                                         else S := '<'+S;
     Message(Application, evCommand, cmExecString, @S);
     CE;
     _AltEnter := True;
   end else
   begin
     PShootState := ShiftState;
     CE;
     _AltEnter := False;
   end;
 end;

 procedure _GotoExt;
 var
   S: string;
 begin
   if (Drive^.DriveType <> dtArvid) and (Drive^.DriveType <> dtArc) then
   begin
      if Drive^.DriveType = dtDisk then S := MakeFileName(PF^.Name)
        else {S := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));}
             begin CE; Exit; end;
      if OS210 and (Copy(PF^.Name,10,3) = 'cmd') then
       begin
          S := 'call "'+S+'"';
          if ShiftState and 3 <> 0 then S := '<'+S else S := '>'+S;
          Message(Application, evCommand, cmExecString, @S);
          Exit;
       end;
      Message(Application, evCommand, cmExecFile, @S);
   end else ViewFile(cmViewFile)
   {else Message(Application, evCommand, cmExecCommandLine, nil);}
 end;

 procedure _CtrlPgUp;
 begin
   CE;
   if ChangeLocked then Exit;
   if not ChangeUp then
     if Drive^.DriveType in [dtDisk, dtLink] then GotoFile(DirectoryName)
 end;

 procedure _CtrlPgDn;
 var
   S: string;
 begin
   CE; if ChangeLocked then Exit;
   if (Files^.Count = 0) then Exit;
   PF := Files^.At(CurPos);
   if PF^.Name[1] = '.' then
   begin
     _CtrlPgUp;
     Exit;
   end;
   if not ( Drive^.DriveType in [ dtFind, dtTemp, dtList ] ) then
    begin
      if PF^.Attr and Directory = 0 then Exit;
      S := MakeNormName(MakeNormName(PF^.Owner^,MakeFileName(PF^.Name)),'..');
      GotoFile(S);
    end else
   if Drive^.DriveType <= dtList then
    begin
      S := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));
      if ShiftState and 3 <> 0 then
        begin
          Message(Owner, evCommand, cmChangeInactive, @S);
          Exit;
        end;
      Dispose(Drive, Done);
      New(Drive, Init(Byte(S[1])-64, @Self, -1));
      {Drive^.Owner := @Self;}
      DeltaX := 0;
      {if WasFull then Drive^.Flags := Drive^.GetFullFlags
                 else Drive^.Flags := 0;}
      GotoFile(S);
      Rebound;
    end;
 end;

 procedure _CheckKB;
 var
   I: Integer;
 begin
   case Event.KeyCode of
    kbAlt1..kbAlt9: begin
                      I := (Event.KeyCode shr 8)-(kbAlt1 shr 8);
                      CE;
                      if ShiftState and 7 <> 0 then
                        begin
                          if Drive^.DriveType <> dtDisk then Exit;
                          if Msg( dlPromptForQDir, nil, mfQuery+mfYesButton+mfNoButton) <> cmYes then Exit;
                          DisposeStr(DirsToChange[I]);
                          DirsToChange[I] := NewStr(DirectoryName);
                          Message(Application, evCommand, cmUpdateConfig, nil);
                        end else begin
                      if DirsToChange[I] <> nil then
                           DoChange(CnvString(DirsToChange[I]));
                      end;
                    end;
    kbAltIns: begin
                if (ShowFlags and psShowDescript <> 0) then
                   Drive^.EditDescription(PF);
                CE;
              end;
    kbBack: if (FMSetup.Options and fmoBackGoesBack <> 0) and
               ((ShiftState and 3 <> 0) or (CmdLine.Str = '')) then
               begin
                 _CtrlPgUp;
                 Exit;
               end;
    kbUp, kbDown: begin
                     CtrlWas := ShiftState and kbCtrlShift <> 0;
                   end;
    kbCtrlR: begin Message(@Self, evCommand, cmForceRescan, nil); CE end;
    kbGrayAst, kbCtrlGAst: begin InvertSelection(@Self, Event.KeyCode = kbCtrlGAst); CE end;
    kbAltGPlus, kbAltGMinus: begin SelectExt(Event.KeyCode = kbAltGPlus, 1, 8,
                                             ShiftState and 3 <> 0); CE end;
    kbCtrlGPlus, kbCtrlGMinus:
       begin
         if ShiftState and 3 = 0 then SelecType(Event.KeyCode = kbCtrlGPlus)
                                   else SelectExt(Event.KeyCode = kbCtrlGPlus, 10, 3, Off); CE
       end;
    kbCtrlBSlsh: begin
                 Drive^.ChangeRoot;
                 {DirectoryName[0] := #3;
                 IncDrawDisabled;}
                 ReadDirectory;
                 AddToDirectoryHistory(DirectoryName);
                 ScrollBar^.SetValue(0);
                 DecDrawDisabled;
                 Owner^.Redraw; CE end;
kbCtrlRight, kbCtrlLeft: _DoCtrl;
kbCtrlDel: if Files^.Count > 0 then
            begin
              I := 0;
              if SelNum = 0 then Files^.AtFree(CurPos) else
                while I < Files^.Count do
                 if PFileRec(Files^.At(I))^.Selected then
                  begin
                    Files^.AtFree(I);
                    if I < CurPos then Dec(CurPos);
                  end else Inc(I);
              ScrollBar^.SetParams(CurPos, 0, Files^.Count - 1,
                                 (Size.Y-Byte(FMSetup.Show and fmsColumnTitles<> 0)) *
                                 ((Size.X+1) div LineLength), 1);
              Recount;
              CE;
            end;
kbCtrlIns: _CtrlIns;
kbCtrlEnter: _CtrlEnter;
    kbLeft: begin
              if Size.X > LineLength then
               begin
                {Dec(Delta, Size.Y - 1);}
                ScrollBar^.SetValue(ScrollBar^.Value - Size.Y + Byte(FMSetup.Show and fmsColumnTitles<> 0));
                CE;
               end
               else if DeltaX > 0 then
                    begin
                     Dec(DeltaX);
                     DrawView;
                     if InfoView <> nil then InfoView^.DrawView;
                     CE;
                    end;
             end;
    kbRight: begin
              if Size.X > LineLength then
               begin
                {Inc(Delta, Size.Y - 1);}
                ScrollBar^.SetValue(ScrollBar^.Value + Size.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0));
                CE;
               end
               else if DeltaX < LineLength - Size.X - 1 then
                    begin
                     Inc(DeltaX);
                     DrawView;
                     if InfoView <> nil then InfoView^.DrawView;
                     CE;
                    end;
             end;
    kbHome: begin CE; DeltaX := 0; OldDelta := -1; ScrollBar^.SetValue(0); DrawView end;
    kbEnd: begin CE; OldDelta := -1; ScrollBar^.SetValue(Files^.Count-1) end;
    kbAltEnter: if _AltEnter then Exit else
    begin
      _GotoExt;
      Exit;
    end;
    kbEnter: if CurPos < Files^.Count then
             begin
               PShootState := ShiftState;
               PF := Files^.At(CurPos);
               if ChangeLocked or (Message(Application, evCommand, cmExecCommandLine, nil) <> nil) then
               begin CE; Exit; end;
               CE;
               FreeStr := 'AUTOEXEC BAT'; FreeStr[9] := PF^.Name[9];
               if (Drive^.DriveType = dtDisk) and
                  (UpStrg(PF^.Name) = FreeStr) and
                  (Msg(dlAutoexecWarning,nil,mfYesNoConfirm) <> cmYes) then Exit;
               if (Drive^.DriveType in [dtFind, dtTemp, dtList]) then
               begin
                if PF^.Name[1] = '.' then _CtrlPgUp else _CtrlPgDn;
                Exit;
               end;
               if (FMSetup.Options and fmoEnterArchives <> 0) and
                  (Event.KeyCode = kbEnter) and (ShiftState and 3 = 0)
                  and (PF^.Attr and Directory = 0) and (Drive^.DriveType <> dtArc )
                  and (Drive^.DriveType <> dtFind ) and (Drive^.DriveType <> dtArvid )
                  and (ArcViewer(MakeNormName(PF^.Owner^, MakeFileName(PF^.Name))))
                  then begin CE; Exit; end;
               if (PF <> nil) then
               if (PF^.Attr and Directory <> 0) then
               begin
                if PF^.Name[1] = '.' then
                    begin
                     if not ChangeUp then GotoFile(PF^.Owner^);
                     end
                   else begin
                         PF^.Name := MakeFileName(PF^.Name);
                         GotoFile(MakeNormName(MakeNormName(PF^.Owner^,PF^.Name),'..'));
                        end;
                Exit;
               end else
               _GotoExt;
             end;
    kbCtrlPgUp: _CtrlPgUp;
    kbCtrlPgDn: _CtrlPgDn;
    kbDel: if ((CmdLine.Str = '') and (FMSetup.Options and fmoDelErase <> 0)) then
              Message(@Self, evCommand, cmPanelErase, nil);
    {
    kbShiftDel: if ((CmdLine.Str = '') and (FMSetup.Options and fmoDelErase <> 0)) then
              Message(@Self, evCommand, cmSingleDel, nil);
    }
    kbIns,kbSpace: if CurPos < Files^.Count then
           begin
            QuickSearch := Off;
            if (Event.CharCode = ' ') and ((CmdLine.Str <> '') or
               (FMSetup.Options and fmoSpaceToggle = 0)) then Exit;
            CE; if Files^.Count = 0 then Exit;
            PF := Files^.At(CurPos);
            if PF^.Name[1] <> '.' then
            begin
             PF^.Selected := not PF^.Selected;
             SelectedLen := SelectedLen - (1-2*Integer(PF^.Selected))*PF^.Size;
             PackedLen := PackedLen - (1-2*Integer(PF^.Selected))*PF^.PSize;
             Dec(SelNum, 1-2*Integer(PF^.Selected));
            end;
            ScrollBar^.SetValue(CurPos + 1);
            if CurPos = ScrollBar^.Value then DrawView;
            if InfoView <> nil then InfoView^.DrawView;
           end;
    kbGrayPlus: begin SelectFiles(@Self, On, ShiftState and 3 <> 0); CE end;
    kbGrayMinus: begin SelectFiles(@Self, Off, ShiftState and 3 <> 0); CE end;
   end;
 end;

procedure _GetCurrentPosFiles;
var
  S: string;
begin
  if (Drive^.DriveType < dtArc) and (PF <> nil) then
    S := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name))
    else S := '';
  if ActivePanel = @Self then CurFileActive := NewStr(S) else
  begin
    CurFilePassive := NewStr(S);
    CE;
  end;
end;

 procedure _TagUntag;
 var
   I: Integer;
 begin
   if (PF <> nil) and (PF^.Selected xor (Event.Command = cmSingleTag))
    then I := kbIns else I := kbDown;
   Message(Owner, evKeyDown, I, nil);CE;
 end;

 procedure _ForceRescan;
 var
   PDr: PDrive;
 begin
   if Drive^.DriveType = dtArc then
   begin
     if PArcDrive(Drive)^.ReadArchive then RereadDir else
     begin
       PDr := Drive;
       Drive := Drive^.Prev;
       PDr^.Prev := nil;
       Dispose(PDr, Done);
       DeltaX := 0;
       DirectoryName := Drive^.GetDir;
       ReadDirectory;
       AddToDirectoryHistory(DirectoryName);
       Rebound;
     end;
   end else RereadDir;
   CE;
 end;

 procedure _FindForced;
 var
   PDr: PDrive;
 begin
   ForceReading := Off;
   DeltaX := 0;
   PDr := Drive;
   Drive := Event.InfoPtr;
   Drive^.Prev := PDr^.Prev;
   PDr^.Prev := nil;
   Dispose(PDr, Done);
   RereadDir;
   CE;
 end;


begin
 WasFull := Drive^.GetFullFlags = ShowFlags;
 CurPos := ScrollBar^.Value;
 if Files^.Count > CurPos then PF := Files^.At(CurPos) else PF := nil;
 {I := mem[$40:$18];}
 case Event.What of
  evCommand: case Event.Command of
              cmToggleDescriptions: begin CM_ToggleDescriptions(@Self); CE end;
              cmToggleShowMode: begin CM_ToggleShowMode(@Self); CE end;
              cmFastRename: begin CM_RenameSingle(@Self, @Event); CE end;
              cmSingleTag, cmSingleUnTag : _TagUntag;
              cmQuickChange1..cmQuickChange9:
                               begin
                                 DoChange(CnvString(DirsToChange[Event.Command-cmQuickChange1]));
                                 CE;
                               end;
              cmPanelMakeList: begin
                                 Message(@Self, evCommand, cmInsertDrive,
                                        New(PFindDrive, InitList(MakeNormName(PF^.Owner^,MakeFileName(PF^.Name)))));
                                 CE;
                               end;
              cmPanelArcFiles:  begin CM_ArchiveFiles(@Self); CE end;
              cmExtractArchive: begin
                                   if (Drive^.DriveType <> dtArc) and
                                      (Drive^.DriveType <> dtArvid) and
                                      (PF <> nil) and
                                      (PF^.Attr and Directory = 0) then
                                     UnarchiveFiles(MakeNormName(PF^.Owner^, MakeFileName(PF^.Name)));
                                   CE
                                end;
              cmReboundPanel: Rebound;
              cmPrintFile: begin CM_Print(@Self); CE end;
              cmSetPassword, cmExtractTo,
              cmArcTest, cmRereadForced,
              cmMakeForced
              : HandleCommand;
              cmEraseGroup: EraseGroup;
              cmFindTree: if (Drive^.DriveType = dtDisk) and
                             (PanelFlags and fmiDirLen <> 0) and
                             (Char(Event.InfoPtr^) = DirectoryName[1])
                              then Char(Event.InfoPtr^) := #0;
              cmInsertFile: begin
                             Files^.AtInsert(Files^.Count, Event.InfoPtr);
                             ScrollBar^.SetParams(ScrollBar^.Value, 0, Files^.Count - 1,
                                                  (Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0)) *
                                                  ((Size.X+1) div LineLength), 1);
                             DrawView;
                             CE;
                            end;
              cmViewText, cmViewHex, cmViewDBF, cmViewWKZ:
               begin
                 if Files^.Count >= CurPos then Drive^.UseFile(Files^.At(CurPos), 22000 + Event.Command);
                 CE;
               end;
              cmInsertDrive: if Event.InfoPtr <> nil then InsertDrive else CE;

              cmEditFile, cmIntViewFile, cmIntEditFile, cmViewFile:
                         begin
                           if isSelDir then
                             case Event.Command of
                              cmViewFile,cmIntViewFile :  if Drive^.DriveType <> dtArc then CountLen else CE;
                              cmEditFile,cmIntEditFile :  begin CM_SetAttributes(@Self, On, CurPos); CE end;
                             end { case }
                           else
                           begin
                             ViewFile(Event.Command); CE;
                           end;
                         end;
              cmCountLen: if Drive^.DriveType <> dtArc then CountLen else CE;
              cmSingleDel: CM_EraseFiles(@Self, On);
              cmGetFileName: begin _GetFName; CE end;
              cmTempCopyFiles: begin CM_CopyTemp(@Self); CE end;
              cmSortBy: begin CM_SortBy(@Self); CE end;
              cmPanelSetup: begin Setup; CE end;
              cmSetupColumns: begin CM_SetShowParms(@Self); CE end;
              cmTouchFile: begin
                            if (PF <> nil) then
                              if (PF^.Attr and Directory <> 0) then
                                  Message(@Self, evKeyDown, kbCtrlPgDn, nil) else
                                  if (Pos(#0+Copy(PF^.Name,10,3)+#0, Executables) > 0) then
                                      Message(@Self, evKeyDown, kbEnter, nil) else
                                      ViewFile(cmViewFile);
                            CE;
                           end;
              cmCompareDir: begin
                             Message(Owner, evCommand, cmPanelCompare, Files);
                             Recount; CE;
                            end;
              cmPushName: if CurrentDirectory <> Drive^.GetRealName then _PushName;
              cmPushFirstName: _DoPush(False);
              cmPushFullName: _DoPush(True);
              cmPanelCompare: begin CM_CompareDirs(@Self, Event.InfoPtr); Recount; CE end;
              cmPanelSelect: begin SelectFiles(@Self, On,Off); CE end;
              cmPanelUnselect: begin SelectFiles(@Self, Off,Off); CE end;
              cmPanelXSelect: begin SelectFiles(@Self, On,On); CE end;
              cmPanelXUnselect: begin SelectFiles(@Self, Off,On); CE end;
              cmCopyFiles,cmMoveFiles,cmSingleCopy,cmSingleRename:
               begin CM_CopyFiles(@Self, (Event.Command = cmMoveFiles) or (Event.Command = cmSingleRename),
                                  (Event.Command = cmSingleCopy) or (Event.Command = cmSingleRename)); CE end;
              cmPanelInvertSel: begin InvertSelection(@Self, Off); CE end;
              cmPanelErase: begin CM_EraseFiles(@Self, Off); CE end;
              cmPanelMkDir: begin CM_MakeDir(@Self); CE end;
              cmRereadDir: if GetState(sfVisible) then _DoRereadDir;
              cmTotalReread: if GetState(sfVisible) or (Drive^.DriveType <> dtDisk) then
                                begin
                                  Drive^.RereadDirectory('');
                                  RereadDir;
                                end;
              cmForceRescan: _ForceRescan;
              cmPanelReread: begin RereadDir; CE end;
              cmMakeList: begin CM_MakeList(@Self); CE end;
              cmChangeDrive: _ChangeDrive;
              cmChangeDrv: _ChangeDrv;

              cmDirBranch: begin CM_Branch(@Self); CE end;

              cmUUDecodeFile:
                begin
                  if (PF <> nil) and
                     (PF^.Attr and Directory = 0) and
                     (Drive^.DriveType < dtArc) then
                    begin
                      UUDecode(MakeNormName(PF^.Owner^, MakeFileName(PF^.Name)));
                    end;
                  CE;
                end;
                  cmUUEncodeFile: begin
                             if (PF <> nil) and (PF^.Attr and Directory = 0)
                               and (Drive^.DriveType < dtArc) then
                                UUEncode(MakeNormName(PF^.Owner^, MakeFileName(PF^.Name)));
                             CE;
                           end;
                 cmUnpDiskImg:
                         begin
                           if (Drive^.DriveType < dtArc) then
                             UnpackDiskImages(@Self, GetSelection(@Self, False));
                           CE;
                         end;
              cmChangeDirectory: _DoChangeDirectory;
              cmChangeDir: begin
                            FreeStr := CM_ChangeDirectory(@Self);
                            if FreeStr <> '' then GotoFile(MakeNormName(FreeStr,'..'));
                            CE
                           end;
              cmGetDirInfo: if Drive <> nil then
                              begin
                                Drive^.GetDirInfo(PDiskInfoRec(Event.InfoPtr)^);
                                CE;
                              end;
                  cmDirHistory: _DoDirHistory;
              cmCloseLinked: _CloseLinked;
              cmGetDirName: begin PString(Event.InfoPtr)^ := DirectoryName end;
              cmSetFAttr,cmSingleAttr: begin CM_SetAttributes(@Self, Event.Command=cmSingleAttr,CurPos); CE end;
              cmPanelLongCopy: begin CM_LongCopy(@Self); CE end;
              cmEnableView: begin ViewEnabled := On; SendLocated; end;
              cmDisableView: begin ViewEnabled := Off; end;
              cmLViewFile: begin SendLocated; CE end;
              cmFindFile: if Drive^.DriveType = dtArvid then
                            begin Drive^.HandleCommand(cmFindFile, nil); CE end;
              cmFindGotoFile: begin FileMask := x_x;
                                    GotoFile(PString(Event.InfoPtr)^); CE;
                                    Owner^.Select; Select;
                                    GlobalMessage(evCommand, cmRereadInfo, nil);
                              end;
              cmAdvFilter: begin CM_AdvancedFilter(@Self); CE end;
             end;
  evKeyDown: _CheckKB;
  evBroadcast: case Event.Command of
                 cmGetCurrentPosFiles: _GetCurrentPosFiles;
                 cmFindForced: if ForceReading then _FindForced;
                 cmInsertDrive: InsertDrive;
                 cmUnarchive: if Drive^.DriveType = dtArc then begin
                                Drive^.CopyFiles(PCopyRec(Event.InfoPtr)^.FC, @Self, On);
                                CE;
                              end;
                 cmCopyCollection: if Drive^.DriveType < dtArc then begin
                                Drive^.CopyFiles(Event.InfoPtr, @Self, ShiftState and 4 = 0);
                                CE;
                              end;
                 cmDropped: if MouseInView(PCopyRec(Event.InfoPtr)^.Where) then
                            begin
                              case Drive^.DriveType of
                                dtFind :;
                                else CM_Dropped(@Self, Event.InfoPtr);
                              end;
                              CE;
                            end;
                 cmScrollBarChanged: if ScrollBar = Event.InfoPtr then begin
                                      if MSelect then
                                        begin
                                         CE; if Files^.Count = 0 then Exit;
                                         PF := Files^.At(ScrollBar^.Value);
                                         if (PF^.Name[1] <> '.') and (PF^.Selected xor SelectFlag) then
                                          begin
                                           PF^.Selected := SelectFlag;
                                           if SelectFlag then begin Inc(SelNum); SelectedLen := SelectedLen + PF^.Size;
                                                                    PackedLen := PackedLen + PF^.PSize end
                                                         else begin Dec(SelNum); SelectedLen := SelectedLen - PF^.Size;
                                                                    PackedLen := PackedLen - PF^.PSize end;
                                          end;
                                        end;
                                      PosChanged := On;
                                      if InfoView <> nil then InfoView^.DrawView;
                                      CED; PosChanged := Off;
                                      if (RepeatDelay <> 0) and ViewEnabled then
                                        NeedLocated := GetSTime;
                                     end;
               end;
  evMouseDown: begin
                if Files^.Count = 0 then Exit;
                MSelect := Event.Buttons and mbRightButton <> 0;
                MakeLocal(Event.Where, MPos);
                if (MPos.Y = 0) and (FMSetup.Show and fmsColumnTitles <> 0) then
                 begin
                  LastRDelay := RepeatDelay; RepeatDelay := 0;
                  if MSelect then
                   begin
                    PF := Files^.At(CurPos);
                    SelectFlag := not PF^.Selected;
                   end;
                  repeat
                   Message(Owner, evKeyDown, kbUp, nil)
                  until not MouseEvent(Event, evMouseMove + evMouseAuto);
                  RepeatDelay := LastRDelay; CE; MSelect := Off;
                  Exit;
                 end;
                MakeLocal(Event.Where, MPos);
                CurPos := Delta + (MPos.X div LineLength)* (Size.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0))
                          + MPos.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0);
                if Event.Double then
                 begin
                  MSelect := Off;
                  CE; if Files^.Count = 0 then Exit;
                  if CurPos < Files^.Count then
                    begin
                     if ScrollBar^.Value <> CurPos then ScrollBar^.SetValue(CurPos)
                     else
                       begin
                          PF := Files^.At(ScrollBar^.Value);
                          if PF^.Attr and Directory <> 0 then
                           begin Message(@Self, evKeyDown, kbCtrlPgDn, nil); CE; Exit end;
                          if ShiftState and kbCtrlShift <> 0 then Message(@Self, evKeyDown, kbCtrlEnter, nil)
                              else begin
                                      Message(CommandLine, evKeyDown, kbDown, nil);
                                      Message(@Self, evKeyDown, kbEnter, nil);
                                      CE
                                   end;
                       end;
                    end
                 end
                else
                begin
                 LastRDelay := RepeatDelay; RepeatDelay := 0;
                 if MSelect and (CurPos < Files^.Count) then
                  begin
                   CurPos := Delta + (MPos.X div LineLength)* (Size.Y-Byte(FMSetup.Show and fmsColumnTitles <> 0))
                             + MPos.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0);
                   if (CurPos >= Files^.Count) then CurPos := Files^.Count - 1;
                   if (CurPos < 0) then CurPos := 0;
                   PF := Files^.At(CurPos);
                   SelectFlag := not PF^.Selected;
                   ScrollBar^.SetValue(CurPos);
                   Message(@Self, evBroadcast, cmScrollBarChanged, ScrollBar);
                   if PF^.Name[1] = '.' then PF^.Selected := False;
                  end;
                if not MSelect and (FMSetup.Options and fmoDragAndDrop <> 0)
                  then begin
                         MSelect := Off; RepeatDelay := LastRDelay;
                         CurPos := Delta + (MPos.X div LineLength) * (Size.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0))
                                   + MPos.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0);
                         if CurPos < Files^.Count then
                          begin
                           ScrollBar^.SetValue(CurPos);
                           if MouseEvent(Event, evMouseMove) then CM_DragDropper(@Self, CurPos, @Event);
                          end;
                         CE; Exit;
                       end;
                 repeat
                  MakeLocal(Event.Where, MPos);
                  if MouseInView(Event.Where) then
                   begin
                    CurPos := Delta + (MPos.X div LineLength) * (Size.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0))
                              + MPos.Y - Byte(FMSetup.Show and fmsColumnTitles <> 0);
                    if CurPos < Files^.Count then ScrollBar^.SetValue(CurPos);
                   end else
                   begin
                    if MPos.Y < 0 then ScrollBar^.SetValue(ScrollBar^.Value - 1)
                     else if MPos.Y >= (Size.Y - 1) then ScrollBar^.SetValue(ScrollBar^.Value + 1);
                   end;
                 until not MouseEvent(Event, evMouseAuto + evMouseMove + evMouseDown);
                 RepeatDelay := LastRDelay; SendLocated;
                end; CE; MSelect := Off;
               end;
 end;
end;

END.

