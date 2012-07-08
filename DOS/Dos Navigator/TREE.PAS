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
//     "Based on TinyWeb Server by RIT Research Labs."
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

unit Tree;

interface
uses Drivers, Objects, DiskTool, Memory, Advance, Startup,
     Dialogs, Views, DOS, FilesCol, HideView, DNHelp, ObjType;

type
    PTreeWindow = ^TTreeWindow;
    TTreeWindow = object(TStdWindow)
     constructor Init(var Bounds: TRect);
     function GetPalette: PPalette; virtual;
     procedure HandleEvent(var Event: TEvent); virtual;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
    end;

    PTreeReader = ^TTreeReader;
    TTreeReader = object(TView)
     procedure HandleEvent(var Event: TEvent); virtual;
    end;

    PTreeDialog = ^TTreeDialog;
    TTreeDialog = object(TDialog)
     Tree: PView;
     IsValid: Boolean;
     constructor Init(R: TRect; ATitle: String; ADrive: Byte);
     {procedure HandleEvent(var Event: TEvent); virtual;}
     function GetPalette: PPalette; virtual;
     function Valid(Command: Word): Boolean; virtual;
    end;

    PDirRec = ^TDirRec;
    TDirRec = record
     Name: String[12];
     Level: Byte;
     Cluster: Word;
     Size: LongInt;
     Attr: Byte;
     NumFiles: LongInt;
     Date: LongInt;
     Number: Integer;
    end;

    PTreeView = ^TTreeView;
    TTreeView = object(THideView)
     ScrollBar: PScrollBar;
     CurPtr: PDirRec;
     isValid, QuickSearch: Boolean;
     Drive, SearchPos: Byte;
     SearchMask: String[12];
     CurPath, LastPath: PathStr;
     DC, Dirs: PCollection;
     Delta: TPoint;
     CurNum: Integer;
     Parital, DrawDisabled,
     LocateEnabled, MouseTracking, WasChanged: Boolean;
     constructor Init(R: TRect; ADrive: Integer; ParitalView: Boolean;
                      ScrBar: PScrollBar);
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     function Valid(Command: Word): Boolean; virtual;
     function Expanded(P: PDirRec; I: Integer): Boolean;
     procedure SetState(AState: Word; Enable: Boolean); virtual;
     procedure ReadTree(CountLen: Boolean);
     procedure Reread(CountLen: Boolean);
     procedure HandleEvent(var Event: TEvent); virtual;
     procedure HandleCommand(var Event: TEvent);
     function  GetDirName(N: Integer): String;
     procedure SetData(var Rec); virtual;
     procedure GetData(var Rec); virtual;
     procedure CollapseBranch(N: Integer);
     function  DataSize: Word; virtual;
     function  FindDir(Dir: PathStr): Integer;
     procedure ReadAfterLoad;
     function GetPalette: PPalette; virtual;
     procedure Draw; virtual;
     destructor Done; virtual;
    end;

    PTreePanel = ^TTreePanel;
    TTreePanel = object(TTreeView)
     procedure HandleEvent(var Event: TEvent); virtual;
    end;

    PTreeInfoView = ^TTreeInfoView;
    TTreeInfoView = object(THideView)
      Tree: PTreeView;
      Down: String;
      Loaded: Boolean;
      constructor Init(R: TRect; ATree: PTreeView);
      procedure Draw; virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure MakeDown;
      constructor Load(var S: TStream);
      procedure Store(var S: TStream);
     function GetPalette: PPalette; virtual;
    end;

    PDTreeInfoView = ^TDTreeInfoView;
    TDTreeInfoView = object(TTreeInfoView)
     function GetPalette: PPalette; virtual;
    end;

    PHTreeView = ^THTreeView;
    THTreeView = object(TTreePanel)
     Info: PView;
     constructor Init(R: TRect; ADrive: Integer; ParitalView: Boolean;
                      ScrBar: PScrollBar);
     procedure ChangeBounds(var Bounds: TRect); virtual;
     procedure HideView; virtual;
     procedure ShowView; virtual;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     function GetPalette: PPalette; virtual;
    end;

    PDirCollection = ^TDirCollection;
    TDirCollection = object(TCollection)
     procedure FreeItem(P: Pointer); virtual;
     function GetItem(var S: TStream): Pointer; virtual;
     procedure PutItem(var S: TStream; Item: Pointer); virtual;
    end;


function  ChangeDir(ATitle: TTitleStr; Drv: Byte): PathStr;
procedure CreateDirectory(S: String; Del: Boolean);
procedure MakeDirectory;
procedure FreeTree(C: Char);
function  GetDirLen(Dir: PathStr): LongInt;


const CreatedDir: String = '';
      TreeError: Boolean = False;
      SaveTrees: Boolean = True;

      RTreeView: TStreamRec = (
       ObjType: otTreeView;
       VmtLink: Ofs(TypeOf(TTreeView)^);
       Load: @TTreeView.Load;
       Store: @TTreeView.Store);

      RTreeReader: TStreamRec = (
       ObjType: otTreeReader;
       VmtLink: Ofs(TypeOf(TTreeReader)^);
       Load: @TTreeReader.Load;
       Store: @TTreeReader.Store);

      RTreeWindow: TStreamRec = (
       ObjType: otTreeWindow;
       VmtLink: Ofs(TypeOf(TTreeWindow)^);
       Load: @TTreeWindow.Load;
       Store: @TTreeWindow.Store);

      RTreePanel: TStreamRec = (
       ObjType: otTreePanel;
       VmtLink: Ofs(TypeOf(TTreePanel)^);
       Load: @TTreePanel.Load;
       Store: @TTreePanel.Store);

      RTreeDialog: TStreamRec = (
       ObjType: otTreeDialog;
       VmtLink: Ofs(TypeOf(TTreeDialog)^);
       Load: @TTreeDialog.Load;
       Store: @TTreeDialog.Store);

      RTreeInfoView: TStreamRec = (
       ObjType: otTreeInfoView;
       VmtLink: Ofs(TypeOf(TTreeInfoView)^);
       Load: @TTreeInfoView.Load;
       Store: @TTreeInfoView.Store);

      RHTreeView: TStreamRec = (
       ObjType: otHTreeView;
       VmtLink: Ofs(TypeOf(THTreeView)^);
       Load: @THTreeView.Load;
       Store: @THTreeView.Store);

      RDirCollection: TStreamRec = (
       ObjType: otDirCollection;
       VmtLink: Ofs(TypeOf(TDirCollection)^);
       Load: @TDirCollection.Load;
       Store: @TDirCollection.Store);

      CHTreeView = #15#16#17#18#19#20#21;
      CTreeInfoView = #22;
      CDTreeInfoView = #30;
      CTreeView = #35#36#37#38#39#40#41;
      CTreeDialog = CDialog+#104#105#106#107#108#109#110;

var   DrvTrees: Array['A'..'Z'] of record C: PCollection; Len: Boolean; end;

const NotRegister: Boolean = False;


implementation
uses  FlPanelX, DNApp, Messages, Commands, Drives, Eraser, Menus, RStrings,
      xTime, FileCopy ;

const
      trExpanded   = $02;
      trHasBranch  = $04;
      cmRevert     = 200;
      cmDirChanged = 201;

function ESC_Pressed: Boolean; var E: TEvent;
begin
  Application^.Idle;
  GetKeyEvent(E); ESC_Pressed := (E.What = evKeyDown) and (E.KeyCode = kbEsc)
end;

function NotStr(S: String): String;
 var I: Integer;
begin
  for I := 1 to Length(S) do S[I] := Char(not Byte(S[I]) xor I);
  NotStr := S;
end;


procedure ReadTree(C: Char; CountLen: Boolean);
label Rep, DRep;
var Drv: PDiskDriver;
    P: PDirRec;
    DCEntry: Integer;
    Idx: Integer;
    D, S: PathStr;
    Lv, I: Integer;
    DSize: Word;
    Dr: Array [1..79] of Integer;
    DC: PDirCollection;
    Dir: ^DirPtr;
    Tmr: TEventTimer;

 procedure ChkESC;
 begin
   if Abort then Exit;
   if TimerExpired(Tmr) then
   begin
     NewTimer(Tmr, 3);
     Abort := ESC_Pressed;
   end;
 end;

 procedure ReadDirectory(PD: PDirRec);
  var
      DirLen: Word;
      DirEnd: Boolean;
      Cl: Word;

  procedure CheckDir;
   var I: Word;
       PP: PDirRec;
  begin
   PP := nil; Idx := DCEntry;
   for I := 0 to DirLen - 1 do
    if Dir^[I].Name[0] <> #0 then
     begin
      if not (Dir^[I].Name[0] in [#$E5,'.']) then
       begin
        if (Dir^[I].Attr and $10 <> 0) then
         begin
          New(P); P^.Size := -1; P^.Name := Dir^[I].Name;
          P^.Date := Dir^[I].Date;
          Insert('.', P^.Name, 9); P^.Name := DelSpaces(P^.Name);
          if P^.Name[Length(P^.Name)] = '.' then Dec(P^.Name[0]);
          P^.Cluster := Dir^[I].Clus; P^.Level := PD^.Level + 1;
          PP := P; DC^.AtInsert(Idx, P); Inc(Idx);
         end else begin
                    Inc(PD^.Size, Dir^[I].Len);
                    Inc(PD^.Numfiles);
                  end;
       end
     end else begin DirEnd := On; Break end;
  end;

 begin
  PD^.Size := 0; PD^.NumFiles := 0;
  Cl := PD^.Cluster;
  DirLen := Drv^.ClusterSize(Cl) div 32;
  DirEnd := Cl = 0;
  repeat
   Drv^.ClusterRead(Dir^, Cl);
   CheckDir;
   if Cl <> 0 then Cl := Drv^.GetFAT(Cl);
  until DirEnd or Abort or
        (Cl >= Drv^.EOFMark) or (Cl = Drv^.BADMark) or (Cl=0);
 end;

 procedure DOSReadDirectory(PD: PDirRec);
  var I: Integer;
      Lv: Integer;
      S: String;
      SR: SearchRec;
      P: PDirRec;
 begin
  I := DC^.IndexOf(PD);
  Lv := PD^.Level;
  PD^.Size := 0; P := PD; S := MakeNormName(PD^.Name,'');
  repeat
   while (I > 0) and (P^.Level <= PDirRec(DC^.At(I))^.Level) do Dec(I);
   if DC^.IndexOf(PD) <> I then
    begin
     P := DC^.At(I);
     S := MakeNormName(P^.Name,S);
    end;
  until I = 0;
  DOSError := 0;
  if Abort then exit;
  I := DC^.IndexOf(PD);
  FindFirst(S+x_x, $3F xor VolumeID, SR);
  while (DOSError = 0) and not Abort do
   begin
    if (SR.Name[1] <> '.') and (SR.Attr and VolumeID = 0) then
     begin
      if SR.Attr and Directory <> 0 then
       begin
        New(P);
        P^.Name := SR.Name; P^.Cluster := 0; P^.NumFiles := 0;
        P^.Size := -1; P^.Level := PD^.Level + 1;
        Inc(I);
        DC^.AtInsert(I,P);
       end else begin
                  Inc(PD^.Size, SR.Size);
                  Inc(PD^.NumFiles);
                end;
     end;
    FindNext(SR);
   end;
  DOSError := 0; ClrIO;
 end;

 var PD: PDirRec;
     RemoteDrive: Boolean;
     Info: PView;
     St: TBufStream;

begin
 NewTimer(Tmr, 1);
 C := UpCase(C); if not (C in ['A'..'Z']) then Exit;
 FreeObject(DrvTrees[C].C);
 TreeError := On;
 if (not CountLen) and (SystemData.Drives[C] and ossTree <> 0) then
  begin
   St.Init(SourceDir+'Drive'+C+'.dir', stOpenRead, 1024);
   if St.Status = stOK then
    begin
     DC := PDirCollection(St.Get);
     if DC <> nil then
      begin
       DC^.Pack;
       for I := 1 to DC^.Count do PDirRec(DC^.At(I-1))^.Number := I-1;
       DrvTrees[C].C := DC; DrvTrees[C].Len := Off;
       TreeError := Off;
       St.Done;
       Exit;
      end;
    end;
    St.Done;
  end;
 if LowMemory then Exit;
 New(DC, Init(10, 10));
 New(P);
 FillChar(P^, SizeOf(P^), 0);
 P^.Name := C + ':\'; P^.Cluster := 0; P^.Level := 0; P^.Size := -1;
 P^.Attr := 0;
 DC^.Insert(P);
 Abort := Off; RemoteDrive := Off;
 if ( SystemData.Drives[ C ] and ossDirectAccess = 0 ) or not CheckDisk(C) then
  begin
   Info := WriteMsg(GetString(dlScanningDirs));
    DrvTrees[C].C := DC; DrvTrees[C].Len := On;
  DRep:
    ChkESC; if not Abort then
    for DCEntry := 1 to DC^.Count do
     begin
      UpdateWriteView(Info);
      P := DC^.At(DCEntry-1);
      if P^.Size < 0 then
       if (not Abort) and (P^.Level < 40) then
        begin DOSReadDirectory(P); Goto DRep end
         else P^.Size := 0;
     end;
   FreeObject(Info);
   if Abort then
   begin
     FreeObject(DC);
     DrvTrees[C].C := nil;
     TreeError := On; Exit;
   end;
  end
  else
  begin
    New(Drv, Init(Byte(C)-64, True));
    if (Drv = nil) or LowMemory then
       begin
         if Drv <> nil then Dispose(Drv, Done);
         DrvTrees[C].C := DC; DrvTrees[C].Len := On;
         Abort := On; Exit
       end;
    Drv^.FreeFAT; Drv^.FAT := nil;
    I := Drv^.ClusterSize(0); DCEntry := Drv^.ClusterSize(2);
    if DCEntry > I then I := DCEntry;
    DSize := I; Dir := MemAlloc(DSize);
    if Dir = nil then
       begin Dispose(Drv, Done); Dispose(DC, Done); Abort := On; Exit end;
    Drv^.SeekFAT(0);
    if Abort or (Drv^.FAT = nil) then
       begin FreeMem(Dir, DSize); Dispose(DC, Done); Dispose(Drv, Done); Abort := On; Exit end;
    DrvTrees[C].C := DC; DrvTrees[C].Len := On;
   Info := WriteMsg(GetString(dlScanningDirs));
   Rep:
    ChkESC; if not Abort then
    for DCEntry := 1 to DC^.Count do
     begin
      UpdateWriteView(Info);
      P := DC^.At(DCEntry-1);
      if P^.Size < 0 then
       if not Abort and (P^.Level < 40) then
        begin ReadDirectory(P); Goto Rep end
         else P^.Size := 0;
     end;
    FreeObject(Info);
    FreeMem(Dir, DSize);
    Dispose(Drv, Done);
    if Abort then
    begin
      DrvTrees[C].C := nil; TreeError := On; Exit;
    end;

  end;
 for I := 1 to DC^.Count do
  begin
   P := DC^.At(I-1); Lv := I;
   P^.Number := I-1; P^.Attr := 0;
   while (Lv < DC^.Count) and (PDirRec(DC^.At(Lv))^.Level > P^.Level) do
     begin PD := DC^.At(Lv); Inc(P^.NumFiles, PD^.NumFiles);
           Inc(P^.Size, PD^.Size); Inc(Lv);
     end;
   if (Lv < DC^.Count) and (PDirRec(DC^.At(Lv))^.Level = P^.Level) then
      P^.Attr := 1;
   if (I < DC^.Count) and (PDirRec(DC^.At(I))^.Level > P^.Level) then
      P^.Attr := P^.Attr or trHasBranch;
  end;
 if (SystemData.Drives[C] and ossTree <> 0) then
  begin
   St.Init(SourceDir+'Drive'+C+'.dir', stCreate, 1024);
   St.Put(DC);
   St.Done;
  end;
 TreeError := Off;
end;

function GetDirCollection(C: Char; CountLen: Boolean): PCollection;
begin
 GetDirCollection := nil;
 C := UpCase(C); if not (C in ['A'..'Z']) then Exit;
 if (DrvTrees[C].C = nil) or (not DrvTrees[C].Len and CountLen)
     then ReadTree(C, CountLen);
 GetDirCollection := DrvTrees[C].C;
end;

function FindDir(DC: PCollection; const Dir: PathStr): Integer;
 var I, Lv: Integer;
     S,D : PathStr;
     P: PDirRec;
begin
 FindDir := -1;
 if DC = nil then Exit;
 D := Dir; Lv := 1; I := 1; Delete(D, 1, 3); if D = '' then begin FindDir := 0; Exit end;
 repeat
  S := '';
  while (D[1] <> '\') and (D <> '') do begin S := S + D[1]; DelFC(D) end;
  DelFC(D);
  if (S <> '') and (I < DC^.Count) then
  begin
   repeat
    if I < DC^.Count then P := DC^.At(I);
    while (I < DC^.Count) and (P^.Level > Lv) do
     begin Inc(I); if I < DC^.Count then P := DC^.At(I); end;
    while (I < DC^.Count) and (P^.Level = Lv) and (P^.Name <> S) do
     begin Inc(I); if I < DC^.Count then P := DC^.At(I); end;
   until (I>=DC^.Count) or ((P^.Name = S) and (P^.Level = Lv)) or (P^.Level < Lv);
  end else if S = '' then I := 1;
  if D <> '' then Inc(I); Inc(Lv);
 until (D = '') or (I >= DC^.Count) or (Lv > 128) { :) };
 if (I >= DC^.Count) or (P^.Name <> S) then FindDir := -1 else FindDir := I;
end;

procedure CreateDirectory;
 var Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     ST: PBufStream;
     DC: PDirCollection;
     I, Lv: Integer;
     P, PD: PDirRec;
 label 1;
begin
 DC := nil; ST := nil;
 if not SaveTrees then Exit;
 S := DelSpaces(Advance.FExpand(S));
 FSplit(S, Dr, Nm, Xt);
 if  (Dr[1] <= 'B') then Exit;
 ST := New(PBufStream, Init(SourceDir+'Drive'+Dr[1]+'.DIR', stOpen, 4096));
 if ST^.Status = stOK then
  begin
   DC := PDirCollection(ST^.Get);
   if DC <> nil then
    begin
     if Dr[0] > #3 then Dec(Dr[0]);
     I := FindDir(DC, S);
     if not Del and (I >= 0) then Goto 1;
     if not Del then I := FindDir(DC, Dr);
     if I >= 0 then
      begin
       if Del then
        begin
         DrvTrees[Dr[1]].Len := Off;
         Lv := PDirRec(DC^.At(I))^.Level; DC^.AtFree(I);
         while (I < DC^.Count) and (PDirRec(DC^.At(I))^.Level > Lv) do DC^.AtFree(I);
        end else
        begin
         New(P);
         FillChar(P^, Sizeof(P^), 0);
         P^.Name := Nm+Xt;
         P^.NumFiles := 0;
         P^.Size := 0;
         P^.Level := PDirRec(DC^.At(I))^.Level+1;
         DC^.AtInsert(I+1, P);
       end;
       for I := 1 to DC^.Count do
        begin
         P := DC^.At(I-1); Lv := I;
         P^.Number := I-1; P^.Attr := 0;
         while (Lv < DC^.Count) and (PDirRec(DC^.At(Lv))^.Level > P^.Level) do
           begin PD := DC^.At(Lv); Inc(Lv);
           end;
         if (Lv < DC^.Count) and (PDirRec(DC^.At(Lv))^.Level = P^.Level) then
            P^.Attr := 1;
         if (I < DC^.Count) and (PDirRec(DC^.At(I))^.Level > P^.Level) then
            P^.Attr := P^.Attr or trHasBranch;
        end;
       ST^.Seek(0); ST^.Truncate;
       ST^.Put(DC);
       FreeObject(DC);
      end;
    end;
  end;
 1:
  FreeObject(DC);
  FreeObject(ST);
end;


(*
procedure CreateDirectory;
 var Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     ST: TBufStream;
     DC: PDirCollection;
     I, Lv: Integer;
     P, PD: PDirRec;
 label 1;
begin
 if not SaveTrees then Exit;
 S := DelSpaces(FExpand(S));
 FSplit(S, Dr, Nm, Xt);
 if (SystemData.Drives[Dr[1]] and ossTree = 0) then Exit;
 ST.Init(SourceDir+'Drive'+Dr[1]+'.DIR', stOpen, 1024);
 if ST.Status = stOK then
  begin
   DC := PDirCollection(ST.Get);
   if DC <> nil then
    begin
     if Dr[0] > #3 then Dec(Dr[0]);
     I := FindDir(DC, S);
     if not Del and (I >= 0) then Goto 1;
     if not Del then I := FindDir(DC, Dr);
     if I >= 0 then
      begin
       if Del then
        begin
         DrvTrees[Dr[1]].Len := Off;
         Lv := PDirRec(DC^.At(I))^.Level; DC^.AtFree(I);
         while (I < DC^.Count) and (PDirRec(DC^.At(I))^.Level > Lv) do DC^.AtFree(I);
        end else
        begin
         New(P);
         FillChar(P^, Sizeof(P^), 0);
         P^.Name := Nm+Xt;
         P^.NumFiles := 0;
         P^.Size := 0;
         P^.Level := PDirRec(DC^.At(I))^.Level+1;
         DC^.AtInsert(I+1, P);
       end;
       for I := 1 to DC^.Count do
        begin
         P := DC^.At(I-1); Lv := I;
         P^.Number := I-1; P^.Attr := 0;
         while (Lv < DC^.Count) and (PDirRec(DC^.At(Lv))^.Level > P^.Level) do
           begin PD := DC^.At(Lv); Inc(Lv);
           end;
         if (Lv < DC^.Count) and (PDirRec(DC^.At(Lv))^.Level = P^.Level) then
            P^.Attr := 1;
         if (I < DC^.Count) and (PDirRec(DC^.At(I))^.Level > P^.Level) then
            P^.Attr := P^.Attr or trHasBranch;
        end;
       ST.Seek(0); ST.Truncate;
       ST.Put(DC);
       Dispose(DC, Done);
      end;
    end;
  end;
 1:ST.Done;
end;
*)

function GetDirLen(Dir: PathStr): LongInt;
 var DC: PCollection;
     I: Integer;
     R: Boolean;

 procedure MakeReread(P: PView); far;
  var Event: TEvent;
 begin
  Event.What := evCommand;
  Event.Command := cmRereadTree;
  Event.InfoPtr := @Dir;
  if P<> nil then P^.HandleEvent(Event);
 end;

begin
 GetDirLen := 0;
 Dir := UpStrg(DelSpaces(Dir));
 R := (DrvTrees[Dir[1]].C <> nil) and not (DrvTrees[Dir[1]].Len);
 DC := GetDirCollection(Dir[1], On); if DC = nil then Exit;
 if R then Desktop^.ForEach(@MakeReread);
 I := FindDir(DC, Dir); if I < 0 then Exit;
 GetDirLen := PDirRec(DC^.At(I))^.Size;
end;

procedure FreeTree(C: Char);
begin
 C := UpCase(C); if not (C in ['A'..'Z']) then Exit;
 FreeObject(DrvTrees[C].C);
end;

procedure TTreeReader.HandleEvent;
 var C: Char;
     S: String;

begin
 inherited HandleEvent(Event);


 if (Event.What = evCommand)
  then
    Case Event.Command of
  cmRereadTree :
  begin
    S := UpStrg(PString(Event.InfoPtr)^);
    C := S[1];
    if (C in ['A'..'Z']) and (DrvTrees[C].C <> nil) then
    begin
      FreeObject(DrvTrees[C].C);
      GlobalMessage(evCommand, cmFindTree, @C);
      if C = #0 then
      begin
        C := S[1];
        ReadTree(C, DrvTrees[C].Len)
      end else DrvTrees[C].Len := Off;
    end;
  end;
 end; { case }

end;

procedure MakeDirectory;
 var S,S1: String;
     Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     B: Byte;
     I: Integer;
begin
 CreatedDir := '';
 if LowMemory then Exit; S := '';
 if ExecResource(dlgMkDir, S) <> cmOK then Exit;
 DelLeft(S); DelRight(S);

 if S = '' then Exit;
 (*
 ClrIO; MkDir(S);
 if IOResult <> 0 then
  begin MessageBox(^C'Could not create the directory'^M^C+S, nil, mfError + mfOKButton);
        Exit;
  end;
 CreateDirectory(S, Off);
 S := DelSpaces(FExpand(S));
 *)
 CreatedDir := '';
 while S <> '' do
  begin
    I := PosChar(';', S);
    if I = 0 then I := Length(S)+1;
    S1 := Copy(S, 1, I-1); Delete(S, 1, I);
    if S1 = '' then Continue;
    B := CreateDirInheritance(S1, Off);
    if Abort or (IOResult <> 0) then Exit;
    if CreatedDir = '' then CreatedDir := S1;
    FSplit(S1, Dr, Nm, Xt);
    if B > 0 then Dr[0] := Char(B) else
     if (Dr[0] > #3) and (Dr[Length(Dr)]='\') then Dec(Dr[0]);
    RereadDirectory(Dr);
    GlobalMessage(evCommand, cmRereadTree, @Dr);
    GlobalMessage(evCommand, cmRereadInfo, nil);
  end;
end;

function ChangeDir;
 var D: PTreeDialog;
     S: String;
     R: TRect;
begin
 R.Assign(1,1,50,18); Abort := Off; ChangeDir := '';
 New(D, Init(R, ATitle, Drv));
 D^.Options := D^.Options or ofCentered;
 S := '';
 D := PTreeDialog(Application^.ValidView(D));
 if D = nil then Exit;
 if Desktop^.ExecView(D) = cmOK then D^.GetData(S);
 FreeObject(D);
 ChangeDir := S;
end;

constructor TTreeInfoView.Init;
begin
 inherited Init(R); Tree := ATree;
 Options := Options or ofPostProcess; EventMask := evBroadcast;
 GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY; MakeDown;
 Loaded := Off;
end;

procedure TTreeInfoView.HandleEvent;
begin
 inherited HandleEvent(Event);
 if (Event.What = evBroadcast) and (Event.Command = cmDirChanged) then
    begin MakeDown; DrawView end;
end;

constructor TTreeInfoView.Load;
begin
 inherited Load(S);
 GetPeerViewPtr(S, Tree);
 Loaded := On;
end;

procedure TTreeInfoView.Store;
begin
 inherited Store(S);
 PutPeerViewPtr(S, Tree);
end;

function TTreeInfoView.GetPalette;
 const S: String[Length(CTreeInfoView)] = CTreeInfoView;
begin
 GetPalette := @S;
end;

function TDTreeInfoView.GetPalette;
 const S: String[Length(CDTreeInfoView)] = CDTreeInfoView;
begin
 GetPalette := @S;
end;

procedure TTreeInfoView.Draw;
 var B: TDrawBuffer;
     C: Byte;
begin
 C := GetColor(1); if Loaded then MakeDown; Loaded := Off;
 MoveChar(B, ' ', C, Size.X);
 MoveStr(B[1], Cut(Tree^.CurPath,Size.X), C);
 WriteLine(0, 0, Size.X, 1, B);
 MoveChar(B, ' ', C, Size.X);
 MoveStr(B[1], Down, C);
 WriteLine(0, 1, Size.X, 1, B);
end;

procedure TTreeInfoView.MakeDown;
 var L: Array [1..5] of Longint;
begin
 L[1] := Tree^.CurPtr^.NumFiles;
 L[2] := Tree^.CurPtr^.Size;
 if L[1] <> 1 then Down := ItoS(L[1]) + GetString(dlTreeFilesWith)
              else Down := GetString(dlTree1FileWith);
 if L[2] <> 1 then Down := Down + FStr(L[2])+' '+GetString(dlDIBytes)
              else Down := Down + ' 1' + GetString(dlDIByte);
end;

constructor TTreeDialog.Init;
var  R1,R2: TRect;
     P:  PView;
begin
 inherited Init(R, ATitle);
 HelpCtx := hcTreeDialog;
 IsValid := On;
 if R.B.X - R.A.X < 24 then R.Grow(24+R.A.X-R.B.X,0);
 if R.B.Y - R.A.Y < 8 then R.B.Y := R.A.Y + 8;
 GetExtent(R); R.Grow(-1,-1);
 R1 := R; Dec(R1.B.X,14);
 P := StandardScrollBar(sbVertical+sbHandleKeyboard);
 Dec(P^.Origin.X, 14); Dec(R1.B.Y);
 Tree := New(PTreeView, Init(R1, ADrive, False, PScrollBar(P)));
 if Tree^.Valid(0) then Insert(Tree) else
 begin
   Dispose(Tree, Done);
   IsValid := Off;
   Exit;
 end;

 R1.A.Y := R1.B.Y; Inc(R1.B.Y);
 P := New(PDTreeInfoView, Init(R1, PTreeView(Tree)));
 Insert(P);


 R1.Assign(R.B.X - 12, R.A.Y + 1, R.B.X -1, R.A.Y + 3);
 P := New(PButton, Init(R1, GetString(dlOkButton), cmOK, bfDefault));
 Insert(P);
 R1.Assign(R.B.X - 12, R.A.Y + 4, R.B.X -1, R.A.Y + 6);
 P := New(PButton, Init(R1, GetString(dlDriveButton), cmChangeDrive, bfBroadcast));
 {P^.Options := P^.Options and not ofSelectable;}
 Insert(P);
 R1.Assign(R.B.X - 12, R.A.Y + 7, R.B.X -1, R.A.Y + 9);
 P := New(PButton, Init(R1, GetString(dlRereadButton), cmPanelReread, bfBroadcast));
 Insert(P);
 R1.Assign(R.B.X - 12, R.A.Y + 10, R.B.X -1, R.A.Y + 12);
 P := New(PButton, Init(R1, GetString(dlMkDirButton), cmPanelMkDir, bfBroadcast));
 Insert(P);
 R1.Assign(R.B.X - 12, R.A.Y + 13, R.B.X -1, R.A.Y + 15);
 P := New(PButton, Init(R1, GetString(dlCancelButton), cmCancel, 0));
 Insert(P);
 SelectNext(False);
 Options := Options or ofTopSelect;
end;

function TTreeDialog.GetPalette;
 const S: String[Length(CTreeDialog)] = CTreeDialog;
begin
 GetPalette := @S;
end;

function TTreeDialog.Valid;
begin Valid := isValid and inherited Valid(Command) end;

(*procedure TTreeDialog.HandleEvent;
begin
 {if Event.What = evCommand then Tree^.HandleEvent(Event);}
 inherited HandleEvent(Event);
end;*)

constructor TTreeWindow.Init;
 var R: TRect;
     P: PView;
     S: PScrollBar;
begin
 inherited Init(Bounds, 'Directory Tree',0);
 GetExtent(R); R.Grow(-1, -1); R.A.X := R.B.X; Inc(R.B.X);
 S := StandardScrollBar(sbVertical+sbHandleKeyboard);
 GetExtent(R); R.Grow(-1, -1); Dec(R.B.Y, 2);
 P := New(PTreePanel, Init(R, 0, On, S));
 Insert(P);

 GetExtent(R); R.Grow(-1, -1); R.A.Y := R.B.Y - 2;
 P := New(PTreeInfoView, Init(R, PTreeView(P)));
 Insert(P);
end;

constructor TTreeWindow.Load;
begin
 inherited Load(S);
 PTreeView(Current)^.ReadAfterLoad;
end;

procedure TTreeWindow.Store;
begin
 inherited Store(S);
end;

function TTreeWindow.GetPalette;
 const S: String[Length(CTreeDialog)] = CTreeDialog;
begin
 GetPalette := @S;
end;

procedure TTreeWindow.HandleEvent(var Event: TEvent);
begin
 case Event.What of
  evKeyDown: if (Event.KeyCode = kbESC) then
               begin Message(Application, evCommand, cmClose, nil); ClearEvent(Event); end;
  evCommand: case Event.Command of
              cmGetName: PString(Event.InfoPtr)^ := 'Directory tree';
             end;
 end;
 inherited HandleEvent(Event);
end;

constructor TTreeView.Init;
 var I,Lv: Integer;
     S,D: String;
     P: PDirRec;
begin
 inherited Init(R); Abort := Off;
 if ParitalView then HelpCtx := hcDirTree;
 EventMask := $FFFF;
 GetDir(ADrive, CurPath); ScrollBar := ScrBar; Drive := ADrive;
 LastPath := CurPath;
 Options := Options or ofSelectable {or ofTopSelect} or ofFirstClick;
 Parital := ParitalView;
 if Parital then Options := Options or ofTopSelect;
 GrowMode := gfGrowHiX + gfGrowHiY; WasChanged := Off;
 Dirs := nil; DC := nil; MouseTracking := Off; LocateEnabled := On;
 if not Abort then ReadTree(Off); QuickSearch := Off; DrawDisabled := Off;
 isValid := not Abort and (ScrollBar <> nil);
end;

destructor TTreeView.Done;
begin
 if DC <> nil then begin DC^.DeleteAll; Dispose(DC, Done) end;
 inherited Done;
end;

function TTreeView.GetPalette;
 const S: String[Length(CTreeView)] = CTreeView;
begin
 GetPalette := @S;
end;

constructor TTreeView.Load;
 var P: Pointer;
begin
 inherited Load(S);
 GetPeerViewPtr(S, ScrollBar);
 S.Read(Parital, 1);
 S.Read(LastPath[0], 1); S.Read(LastPath[1], Length(LastPath));
 CurPath := LastPath; Drive := Byte(LastPath[1])-64;
 QuickSearch := Off; DrawDisabled := Off; LocateEnabled := On;
 Dirs := nil; DC := nil; isValid := True; WasChanged := Off;
 MouseTracking := Off;
end;

procedure TTreeView.ReadAfterLoad;
begin
 Abort := Off; ReadTree(Off);
 isValid := not Abort and (ScrollBar <> nil);
end;

function THTreeView.GetPalette;
 const S: String[Length(CHTreeView)] = CHTreeView;
begin
 GetPalette := @S;
end;

procedure TTreeView.Store;
begin
 inherited Store(S);
 PutPeerViewPtr(S, ScrollBar);
 S.Write(Parital, 1);
 S.Write(LastPath, Length(LastPath)+1);
end;

function TTreeView.Valid; begin Valid := isValid and inherited Valid(Command) end;

procedure TTreeView.SetData; begin end;

procedure TTreeView.GetData;
 var S: PathStr;
begin
 S := GetDirName(ScrollBar^.Value);
 PathStr(Rec) := S;
 LastPath := S;
end;

function TTreeView.GetDirName;
 var S: PathStr;
     I: Integer;
     P: PDirRec;
begin
 I := N;
 P := DC^.At(I); if I = 0 then S := '' else S := P^.Name;
 repeat
  if I > 0 then
   repeat Dec(I) until (I < 0) or (PDirRec(DC^.At(I))^.Level < P^.Level);
  if I >= 0 then P := DC^.At(I); S := MakeNormName(P^.Name, S);
 until I <= 0;
 GetDirName := S;
end;

function TTreeView.DataSize; begin DataSize := 80; end;

procedure TTreeView.CollapseBranch;
 var L, I: Integer;
     P, P1: PDirRec;

 function Find(N: Integer): Integer;
  var I: Integer;
 begin
  Find := -1;
  for I := 1 to DC^.Count do
   if PDirRec(DC^.At(I-1))^.Number = N then begin Find := I-1; Exit end;
 end;

begin
 I := Find(N);
 if (I <= 0) or not Parital then Exit;
 P := DC^.At(I);
 if Expanded(P, I+1) then
  begin
   while (I < DC^.Count - 1) and (P^.Level < PDirRec(DC^.At(I+1))^.Level)
         do DC^.AtDelete(I+1);
  end
  else
  begin
   L := N + 1;
   while (L < Dirs^.Count) and (PDirRec(Dirs^.At(L))^.Level > P^.Level) do
    begin
     if PDirRec(Dirs^.At(L))^.Level = P^.Level + 1 then
      begin DC^.AtInsert(I+1, Dirs^.At(L)); Inc(I); end;
     Inc(L);
    end;
  end;
 ScrollBar^.SetParams(ScrollBar^.Value, 0, DC^.Count - 1, DC^.Count, 1);
end;

procedure TTreeView.HandleEvent;
begin
  if Valid(0) then
  begin
    inherited HandleEvent(Event);
    HandleCommand(Event);
    if not Valid(0) then Message(Owner, evCommand, cmCancel, nil)
  end;
end;

procedure TTreeView.HandleCommand;
 Label NoLoc;
 var CurPos, I: Integer;
     PD: PDirRec;
     C: Char;
     DR: PathStr;
     MP: TPoint;

 procedure CE;begin ClearEvent(Event) end;

 function SearchForMask(Delta: Integer): Boolean;
  var I: Integer;
 begin
  SearchForMask := Off;
  if SearchMask[1] = '\' then
   begin
    ScrollBar^.SetValue(0);
    SearchForMask := On;
    Exit;
   end;
  I := ScrollBar^.Value + Delta; if I = 0 then Inc(I);
  While (I < DC^.Count) and
        not InFilter(PDirRec(DC^.At(I))^.Name, SearchMask) do Inc(I);
  if I >= DC^.Count then
   begin
    I := 0;
    While (I < ScrollBar^.Value) and
          not InFilter(PDirRec(DC^.At(I))^.Name, SearchMask) do Inc(I);
    if I >= ScrollBar^.Value then I := 0;
   end;
  if I > 0 then
   begin
    SearchForMask := On;
    Inc(SearchPos,1-Delta); if SearchPos = 9 then Inc(SearchPos,1-Delta);
    if SearchPos > 12 then SearchPos := 12;
    if I = ScrollBar^.Value then DrawView else ScrollBar^.SetValue(I);
   end;
 end;

 procedure CancelSearch;
 begin
  if not QuickSearch then Exit;
  QuickSearch := Off; DrawView;
 end;

 procedure ChangeDrive;
  var T: TPoint;
      S: String;
 begin
  T.X := Size.X div 2; T.Y := 1; MakeGlobal(T, T); Desktop^.MakeLocal(T,T);
  S := SelectDrive(T.X, T.Y, CurPath[1], Off); if S = '' then Exit;
  ClrIO; GetDir(Byte(S[1])-64, S); if Abort then Exit;
  CurPath := S; LastPath := S;
  if not Abort then
  begin
    ReadTree(Off);
    if IsValid then DrawView;
  end;
 end;

 procedure SendLocated;
 begin
  if LocateEnabled then
    Message(Owner, evCommand, cmChangeDirectory, @CurPath);
 end;

 procedure ExpandBranches;
  var B: Boolean;
      I: Integer;
      S: String;
      P: PDirRec;
 begin
  B := On; GetData(S);
  for I := 1 to DC^.Count do
   begin
    P := DC^.At(I-1);
    B := B and Expanded(P, I);
   end;
  if not B then
   begin
    DC^.DeleteAll;
    for I := 1 to Dirs^.Count do DC^.Insert(Dirs^.At(I-1));
   end
   else Reread(Off);
  if Valid(0) then
  begin
    I := FindDir(S); if I < 0 then I := 0;
    ScrollBar^.SetParams(I, 0, DC^.Count - 1, DC^.Count, 1);
    DrawView;
  end;
 end;

 procedure MkDirectory;
  var OldDir, NewDir: PathStr;
 begin
   GetDir(0, OldDir);
   GetData(NewDir);
   ChDir(NewDir);
   MakeDirectory;
   ChDir(OldDir);
   GlobalMessage(evCommand, cmRereadInfo, nil);
 end;

 procedure EraseDir;
  var FC: PFilesCollection;
      P: PFileRec;
      D: PDirRec;
      S: String;
      OldDir: PathStr;
 begin
  CE; if ScrollBar^.Value < 1 then Exit; GetData(S);
  ClrIO; GetDir(0, OldDir); if Abort then Exit;
  ChDir(GetPath(S));
  While S[Length(S)] <> '\' do Dec(S[0]);
  New(FC, Init(1,1));
  New(P); D := DC^.At(ScrollBar^.Value);
  P^.Name := D^.Name; P^.Attr := Directory; P^.Owner := @S; FC^.Insert(P);
  P^.Diz := nil;
  EraseFiles(FC);
  Dispose(FC, Done);
  ChDir(OldDir); ClrIO;
 end;

 procedure QuickChange(const SS: String);
 begin
   if SS <> '' then Message(@Self, evCommand, cmChangeTree, @SS);
 end;


 var Ev: TEvent;

begin
 CurPos := ScrollBar^.Value;
 {P := DC^.At(CurPos);}
 if QuickSearch and (Event.What = evKeyDown) and (Event.CharCode < #33)
    and (Event.KeyCode <> kbBack) and (Event.KeyCode <> kbCtrlEnter)
     then CancelSearch;
 case Event.What of
  evCommand: case Event.Command of

              cmPanelErase: EraseDir;
              cmDoSendLocated: begin SendLocated; CE end;
              cmPanelMkDir: begin MkDirectory; CE end;
              cmChangeDrive: begin
                               ChangeDrive;
                               CE;
                             end;
              cmFindTree:
                if Char(Event.InfoPtr^) = LastPath[1] then Char(Event.InfoPtr^) := #0;
              cmRevert:
                begin ScrollBar^.SetValue(CurNum);
                      CurPtr := DC^.At(ScrollBar^.Value);
                      Message(Owner, evBroadcast, cmDirChanged, @CurPath); CE
                end;
              cmRereadTree: begin
                             if Dirs = nil then Exit;
                             if CurPath[1] = PString(Event.InfoPtr)^[1] then Reread(Off);
                             if Valid(0) then
                             begin
                               CurPtr := DC^.At(ScrollBar^.Value);
                               Message(Owner, evBroadcast, cmDirChanged, @CurPath);
                             end;
                            end;
              cmPanelReread, cmRereadForced, cmForceRescan
                        : begin
                              Reread(On);
                              if Valid(0) then
                              begin
                                CurPtr := DC^.At(ScrollBar^.Value);
                                Message(Owner, evBroadcast, cmDirChanged, @CurPath);
                                Message(Application, evBroadcast, cmTreeChanged, @CurPath);
                              end;
                             end;
              cmChangeTree: begin
                             if PString(Event.InfoPtr)^[2] <> ':' then
                               begin CE; Exit; end;
                             LocateEnabled := On;
                             LastPath := PString(Event.InfoPtr)^;
                             if Dirs = nil then
                              begin
                                WasChanged := CurPath[1] <> LastPath[1];
                                CurPath := LastPath;
                                Exit;
                              end;
                             LocateEnabled := Off;
                             if ((LastPath[1] <> CurPath[1]) or WasChanged)
                                and (ValidDrive(LastPath[1])) then
                              begin
                                LocateEnabled := Off;
                                WasChanged := Off;
                                CurPath := LastPath; Reread(Off);
                                if Valid(0) then
                                begin
                                  if Dirs = nil then Exit;
                                  CurPtr := DC^.At(ScrollBar^.Value);
                                  Message(Owner, evBroadcast, cmDirChanged, @CurPath);
                                  LocateEnabled := On; CE; Exit;
                                end;
                              end;
                             CurPath := LastPath;
                             CurNum := Tree.FindDir(Dirs, CurPath);
                             I := FindDir(CurPath);
                             if I >= 0 then ScrollBar^.SetValue(I);
                             LocateEnabled := On;
                             CE; DrawView;
                             CurPtr := DC^.At(ScrollBar^.Value);
                             Message(Owner, evBroadcast, cmDirChanged, @CurPath);
                            end;
             end;
  evKeyDown: case Event.KeyCode of
                kbAlt1..kbAlt9: begin QuickChange(CnvString(DirsToChange[Event.ScanCode-(kbAlt1 shr 8)])); CE end;
                kbEnter: if Parital then begin SendLocated; CE end;
                kbDel: if (FMSetup.Options and fmoDelErase <> 0) then EraseDir;
                kbGrayAst: begin
                        if Parital then ExpandBranches;
                        CE;
                       end;
                kbSpace,kbGrayPlus,kbGrayMinus:
                     begin
                       QuickSearch := Off;
                       if Parital then
                         begin
                          CollapseBranch(PDirRec(DC^.At(CurPos))^.Number);
                          DrawView;
                         end;
                         CE;
                       end;
              kbRight: Event.KeyCode := kbDown;
              kbLeft: Event.KeyCode := kbUp;
              kbCtrlEnter: begin
                             if QuickSearch then
                              begin
                                SearchForMask(1); CE;
                              end;
                             Exit;
                           end;
              kbBack: if QuickSearch then
                        if SearchPos = 1 then CancelSearch
                         else begin
                                if SearchPos in [1..8,10..12] then SearchMask[SearchPos] := '?';
                                Dec(SearchPos); DrawView; CE
                              end;
               else
                if Event.CharCode > ' ' then
                begin
                 if QuickSearch then begin
                  if (Event.CharCode = '\') and (SearchPos > 0) then
                    begin
                      CE;
                      PD := DC^.At(CurPos);
                      while (PD^.Attr and trHasBranch = 0) do
                        begin
                           if not SearchForMask(1) then Exit;
                           PD := DC^.At(ScrollBar^.Value);
                        end;
                      ScrollBar^.SetValue(ScrollBar^.Value+1);
                      if Parital and (PD^.Attr and trExpanded = 0) then
                          CollapseBranch(PDirRec(DC^.At(CurPos))^.Number);
                      SearchMask := '????????.???'; SearchPos := 1;
                      DrawView;
                      Exit;
                    end;
                  if Event.CharCode = '.' then begin SearchPos := 9; FillChar(SearchMask[10], 3, '?') end else
                      SearchMask[SearchPos] := UpCase(Event.CharCode);
                  SearchForMask(0);
                 end else
                  begin
                   QuickSearch := On; SearchPos := 1;
                   if Event.CharCode = '.' then begin SearchPos := 9; SearchMask := '????????.???' end
                     else  SearchMask := UpCase(Event.CharCode)+'???????.???';
                   SearchForMask(0);
                  end; CE;
                end else CancelSearch;
             end;
  evBroadcast: case Event.Command of
                cmPanelReread,
                cmPanelMkDir,
                cmChangeDrive: Message(@Self, evCommand, Event.Command, nil);
                cmTreeChanged: begin
                                 if (Dirs <> nil) and (PString(Event.InfoPtr)^[1] = CurPath[1]) then
                                     Reread(Off);
                               end;
                cmDropped: begin
                             MP := PCopyRec(Event.InfoPtr)^.Where;
                             if not MouseInView(MP) then begin CE; Exit; end;
                             MakeLocal(MP, MP);
                             I := Delta.Y + MP.Y;
                             if I >= DC^.Count then begin CE; Exit; end;
                             CopyDirName := GetDirName(I);
                             if PCopyRec(Event.InfoPtr)^.Owner <> nil then
                              begin
                               Ev.What := evBroadcast;
                               Ev.Command := cmUnarchive;
                               Ev.InfoPtr := Event.InfoPtr;
                               PCopyRec(Event.InfoPtr)^.Owner^.HandleEvent(Ev);
                               if Ev.What = evNothing then
                                begin CE; Exit; end;
                              end;
                             CopyFiles(PCopyRec(Event.InfoPtr)^.FC, PCopyRec(Event.InfoPtr)^.Owner,
                                       ShiftState and 3 <> 0, 0);
                             CE;
                           end;
                cmScrollBarChanged: if ScrollBar = Event.InfoPtr then
                                    begin
                                       DrawView; CE; GetData(CurPath);
                                       CurPtr := DC^.At(CurPos);
                                       Message(Owner, evBroadcast, cmDirChanged, @CurPath);
                                       if not MouseTracking and (FMSetup.Options and fmoAutoChangeDir <> 0) then
                                           NeedLocated := GetSTime;
                                    end;
               end;
  evMouseDown: begin
                MakeLocal(Event.Where, MP);
                if MP.Y + Delta.Y < DC^.Count then
                  begin
                   PD := DC^.At(MP.Y + Delta.Y);
                    if (PD^.Level > 0) and
                       (MP.X >= PD^.Level*3 + 1 + Delta.X) and
                       (MP.X <= PD^.Level*3 + 3 + Delta.X) then
                                begin
                                 ScrollBar^.SetValue(MP.Y + Delta.Y);
                                 Message(@Self, evKeyDown, $3920, nil);
                                 while MouseEvent(Event, evMouseAuto + evMouseMove) do;
                                end else
                    {if (MP.X >= P^.Level*3 + 1 + 3*Byte(P^.Level>0) + Delta.X) and
                      (MP.X <= P^.Level*3 + 2 + 3*Byte(P^.Level>0) + Delta.X + Length(P^.Name)) then}
                      begin
                       if Event.Double and not Parital then
                        begin ScrollBar^.SetValue(MP.Y + Delta.Y);
                              Message(Owner, evCommand, cmOK, nil); CE end;
                       CurPos := RepeatDelay; RepeatDelay := 0;
                       MouseTracking := On;
                       repeat
                        MakeLocal(Event.Where, MP);
                        if (MP.X > 0) and (MP.X<Size.X) then ScrollBar^.SetValue(MP.Y + Delta.Y);
                       until not MouseEvent(Event, evMouseAuto + evMouseMove);
                       MouseTracking := Off; SendLocated;
                       RepeatDelay := CurPos;
                      end;
                   CE;
                  end;
               end;
 end;
end;

function TTreeView.Expanded(P: PDirRec; I: Integer): Boolean;
begin
 Expanded := On;
 if (I >= DC^.Count) then
  begin
   if (P^.Number + 1 <> Dirs^.Count) then Expanded := Off;
  end else
  if PDirRec(DC^.At(I))^.Number <> P^.Number + 1 then Expanded := Off;
end;

procedure TTreeView.Draw;
 var Levels: Array [0..79] of Boolean;
     I, J, K, CurPos, Idx: Integer;
     C: Char;
     S: String;
     B: Array[0..199] of Word;
     C1, C2, C3, C4, CC: Byte;
     P: PDirRec;
begin
 if (DrawDisabled) or (DC = nil) then Exit;
 FillChar(Levels, 80, 0);
 C1 := GetColor(1); C2 := GetColor(2); C3 := GetColor(3); C4 := GetColor(4);
 ScrollBar^.PgStep := Size.Y*((Size.X+1) div 13);
 if Owner^.GetState(sfActive) and GetState(sfSelected) then C3 := GetColor(3)
                                                       else C3 := GetColor(6);
 CurPos := ScrollBar^.Value;
 if CurPos < Delta.Y then Delta.Y := CurPos;
 if CurPos >= Delta.Y + Size.Y then Delta.Y := CurPos - Size.Y + 1;
 P := DC^.At(CurPos);
 if (P^.Number = CurNum) and not Parital then
  if Owner^.GetState(sfActive) and GetState(sfSelected) then C3 := GetColor(5)
                                                        else C3 := GetColor(7);
 if P^.Level * 3 + 6 + Length(P^.Name) + Delta.X > Size.X then
   Delta.X := P^.Level * 3 + 6 + Length(P^.Name)- Size.X;
 if P^.Level * 3 - 4 < Delta.X then Delta.X := P^.Level * 3 - 4;
 if Delta.X < 0 then Delta.X := 0;
 for I := 0 to Delta.Y - 1 do
  begin
    P := DC^.At(I);
    Levels[P^.Level] := (P^.Attr and 1 = 1);
  end;
 for I := 1 to Size.Y do
  begin
   MoveChar(B, ' ', C1, 200); Idx := I + Delta.Y - 1;
   if Idx < DC^.Count then
   begin
    P := DC^.At(Idx);
    if P^.Attr and 1 = 1 then C := 'Ã' else C := 'À';
    if P^.Level = 0 then S := '' else
     begin
      {if Parital then S := C + 'Ä[ ] ' else} S := C + 'ÄÄÄ';
      if (P^.Attr and trHasBranch <> 0) and
       (PDirRec(Dirs^.At(P^.Number+1))^.Level > P^.Level) then
        if Parital then if Expanded(P, Idx+1) then S := C + 'Ä[-] '
                                              else S := C + 'Ä[+] '
                   else S[4] := 'Â';
     end; K := 2;
    if P^.Level > 0 then
     for J := 1 to P^.Level-1 do
      begin
       if Levels[J] then MoveChar(B[K], '³', C1, 1);
       Inc(K, 3);
      end;
    Levels[P^.Level] := (P^.Attr and 1 = 1);
    MoveStr(B[K],S,C1);
    if Idx = CurPos then CC := C3 else
     if (P^.Number = CurNum) and not Parital then CC := C4 else CC := C2;
    if CurPos = Idx then
     begin
      MoveStr(B[K+Length(S)-1],' '+P^.Name+' ', CC);
      if QuickSearch then
       begin
        ShowCursor; NormalCursor; SetCursor(K + Length(S)-1 + SearchPos, I-1);
       end else HideCursor;
     end else MoveStr(B[K+Length(S)], P^.Name, CC);
   end;
   WriteLine(0, I-1, Size.X, 1, B[Delta.X]);
  end;
end;

procedure TDirCollection.FreeItem;
begin
 Dispose(PDirRec(P));
end;

procedure TDirCollection.PutItem;
begin
 S.Write(Item^, SizeOf(TDirRec));
end;

function TDirCollection.GetItem;
 var Item: PDirRec;
begin
 New(Item);
 S.Read(Item^, SizeOf(TDirRec));
 if (Item^.NumFiles < 0) or (Item^.Size < 0) then
  begin Item^.NumFiles := 0; Item^.NumFiles := 0; end;
 GetItem := Item;
end;

procedure TTreeView.ReadTree;
label Rep;
var Drv: PDiskDriver;
    P: PDirRec;
    DCEntry: Integer;
    Idx: Integer;
    D, S: PathStr;
    Lv, I: Integer;
    Dr: Array [1..79] of Integer;
    PD: PDirRec;

begin
 Abort := Off;
 if DC <> nil then
 begin
   DC^.DeleteAll;
   FreeObject(DC);
 end;
 DC := GetDirCollection(CurPath[1], CountLen);
 IsValid := not Abort;
 if (DC = nil) then begin Abort := On; IsValid := False; Exit end;
 if DC^.Count = 0 then begin
  New(PD); PD^.Cluster := 0; PD^.Level := 0; PD^.Size := -1;
  PD^.Attr := 0; PD^.Name := Copy(CurPath, 1, 3); DC^.Insert(PD);
 end;
 if LowMemory then begin Abort := On; Exit end;
 if not Abort and (ScrollBar <> nil) and (DC^.Count > 0) then
  begin
   GetDir(Byte(CurPath[1]) - 64, CurPath); if Abort then Exit;
   D := CurPath; Delete(D, 1, 3);
   Dirs := DC;
   DC := New(PDirCollection, Init(Dirs^.Count, 10));
   for I := 1 to Dirs^.Count do DC^.Insert(Dirs^.At(I-1));
   DrawDisabled := On;
   if Parital then
    begin
     I := 1;
     While (I < DC^.Count) do
      begin CollapseBranch(PDirRec(DC^.At(I))^.Number); Inc(I); end;
    end;
   DrawDisabled := Off;
   I := FindDir(CurPath);
   CurNum := I;
   Delta.Y := 0; Delta.X := 0;
   Lv := CurNum;
   ScrollBar^.SetParams(Lv, 0, DC^.Count-1, DC^.Count, 1);
   Lv := ScrollBar^.Value; if Lv < 0 then Lv := 0;
   CurPtr := DC^.At(Lv);
  end else IsValid := Off;
 IsValid := not Abort;
end;

function TTreeView.FindDir;
 var N, I: Integer;

 function Find(N: Integer): Integer;
  var I: Integer;
 begin
  Find := -1;
  for I := 1 to DC^.Count do
   if PDirRec(DC^.At(I-1))^.Number = N then begin Find := I-1; Exit end;
 end;

 procedure ExpandFor(N: Integer);
  var I, Lv, CurLv: Integer;
      Lvs: Array [1..79] of Integer;
 begin
  I := N - 1; CurLv := PDirRec(Dirs^.At(N))^.Level;
  Lvs[CurLv] := N; Lv :=CurLv;
  repeat
   Dec(Lv); While (I >= 0) and (PDirRec(Dirs^.At(I))^.Level > Lv) do Dec(I);
   Lvs[Lv] := I;
  until (I = 0) or (Find(I) >= 0);
  for I := Lv to CurLv - 1 do CollapseBranch(Lvs[I]);
 end;

begin
 N := Tree.FindDir(Dirs, Dir);
 if Parital and (N >= 0) then
  begin
   I := Find(N); FindDir := I; if I >= 0 then Exit;
   ExpandFor(N);
   FindDir := Find(N);
  end
  else FindDir := N;
end;

procedure TTreeView.SetState;
begin
 inherited SetState(AState, Enable);
 if (AState and sfFocused <> 0) and not Enable then
    if Parital then
       DisableCommands([cmCopyFiles, cmPanelErase, cmMoveFiles, cmPanelMkDir,
                                       cmChangeDrive, cmPanelReread]);
 if AState and (sfFocused or sfActive or sfSelected) <> 0 then
  if Owner^.GetState(sfActive) and GetState(sfSelected) then
   begin
    if ScrollBar <> nil then ScrollBar^.Show;
    if Parital then EnableCommands([cmCopyFiles, cmPanelErase, cmMoveFiles, cmPanelReread,
                                    cmPanelMkDir, cmChangeDrive]);
    {EventMask := EventMask or evBroadcast;}
    DrawView
   end
    else
     begin
      if ScrollBar <> nil then ScrollBar^.Hide;
      {EventMask := EventMask and (not evBroadcast);}
      DrawView
     end;
end;

procedure TTreeView.Reread;
 var S: String;
     I, M: Integer;
begin
 DrawDisabled := On; DC^.DeleteAll; FreeObject(DC);
 M := ScrollBar^.Value;
 LocateEnabled := Off;
 ReadTree(CountLen);
 if Valid(0) then
 begin
   I := FindDir(LastPath); if I < 0 then I := M;
   LocateEnabled := On;
   ScrollBar^.SetValue(I);
   DrawDisabled := Off;
   DrawView;
 end;
end;

procedure TTreePanel.HandleEvent;
 procedure CE; begin ClearEvent(Event) end;

 procedure CopyDir;
  var FC: PFilesCollection;
      P: PFileRec;
      D: PDirRec;
      S: String;
      OldDir, NewDir: PathStr;
 begin
   GetDir(0, OldDir);
   GetData(NewDir);
   ChDir(MakeNormName(NewDir,'..'));
   CE; if ScrollBar^.Value < 1 then Exit; GetData(S);
   While S[Length(S)] <> '\' do Dec(S[0]);
   New(FC, Init(1,1));
   New(P); D := DC^.At(ScrollBar^.Value);
   P^.Name := D^.Name; P^.Attr := Directory; P^.Owner := @S; FC^.Insert(P);
   P^.Diz := nil;
   CopyFiles(FC, nil, Event.Command = cmMoveFiles, 0);
   Dispose(FC, Done);
   ChDir(OldDir);
   GlobalMessage(evCommand, cmRereadInfo, nil);
 end;

begin
 inherited HandleEvent(Event);
 case Event.What of
  evCommand: case Event.Command of
              cmMoveFiles,cmCopyFiles: CopyDir;
             end;
 end;
end;

constructor THTreeView.Init;
begin
 inherited Init(R, ADrive, On, ScrBar);
 Info := nil;
end;

constructor THTreeView.Load;
begin
 inherited Load(S);
 GetPeerViewPtr(S, Info);
end;

procedure THTreeView.Store;
begin
 inherited Store(S);
 PutPeerViewPtr(S, Info);
end;

procedure THTreeView.HideView;
begin
 if Info <> nil then PHideView(Info)^.HideView;
 if (ScrollBar <> nil) then ScrollBar^.Hide;
 inherited HideView;
end;

procedure THTreeView.ShowView;
begin
 if Info <> nil then PHideView(Info)^.ShowView;
 if (ScrollBar <> nil) and GetState(sfActive+sfSelected) then ScrollBar^.Show;
 if Dirs = nil then ReadAfterLoad;
 inherited ShowView;
end;

procedure THTreeView.ChangeBounds;
 var R: TRect;
begin
 Dec(Bounds.B.Y, 2);
 SetBounds(Bounds);
 R :=Bounds; R.A.Y := R.B.Y; Inc(R.B.Y, 2);
 if Info <> nil then Info^.SetBounds(R);
 if ScrollBar <> nil then
  begin R :=Bounds; R.A.X := R.B.X; Inc(R.B.X); ScrollBar^.SetBounds(R) end
end;

end.