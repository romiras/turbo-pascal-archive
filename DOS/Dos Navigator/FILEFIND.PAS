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

unit FileFind;

interface
uses Objects, Views, Dialogs, Drivers, Menus, FileCopy, FilesCol, Eraser,
     Drives, HideView, DOS, Gauge, DiskInfo, FStorage, ObjType;

type
    TFindRec = record
     Mask: String[80];
     What: String[200];
     Options: Word;
     Where: Word;
    end;

    PListItem  = ^TListItem;
    TListItem = record
     Next: PListItem;
     Item: Pointer;
    end;

    TAdvanceSearchData = record
                    After: String[17]; {Inputline}
                    Before: String[17]; {Inputline}
                    Greater : String[12]; {Inputline}
                    Less : String[12]; {Inputline}
                    Attr : Word; {Checkbox}
                  end;

const
     CFindWindow = #126#127#128#129#130#131#132#133#134#135#136#137#138;
     CFileFinder = #6#7#8#9;
     CFindInfo   = #10#11#12#13;

     ffoAdvanced    = 1;
     ffoCaseSens    = 2;
     ffoRecursive   = 4;

     FindRec: TFindRec = ( Mask : '*.*';
                           What : '';
                           Options : 4;
                           Where : 0);


    AdvanceSearchData : TAdvanceSearchData =
                    (After: '';
                     Before: '';
                     Greater: '';
                     Less: '';
                     Attr: 0
                     );

{    TempStored: Boolean = False;}


procedure FindFile;
function FindFiles(var Files: PDirStorage; var Directories: PCollection;var FindRec: TFindRec; PInfo: PWhileView): Boolean;
function ReadList(AName: String; var DC: PSortedCollection; var FC: PDirStorage): Boolean;
function OpenDirectory(const Dir: String): PDrive;
function ParseTime(S: String): LongInt;

type

     PFindFile = ^TFindFile;
     TFindFile = record
      Name: Array [1..12] of Char;
      Size: LongInt;
      Date: LongInt;
      Attr: Byte;
      Owner: PString;
      Next: PFindFile;
     end;

  PFindDrive = ^TFindDrive;
  TFindDrive = object(TDrive)
   isDisposable: Boolean;
   Files: PDirStorage;
   Dirs: PSortedCollection;
   ListFile: PString;
   UpFile: PFileRec;
   AllowPack: Boolean;
   constructor Load(var S: TStream);
   procedure Store(var S: TStream);
   procedure NewUpFile;
   constructor Init(const AName: String; ADirs: PCollection; AFiles: PDirStorage);
   constructor InitList(const AName: String);
   procedure ChDir(ADir: PathStr); virtual;
   function GetDirectory(SortMode, PanelFlags: Integer; const FileMask: String;
                         var FreeSpace, TotalInfo: String ): PCollection; virtual;
   procedure CopyFilesInto(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
   function Disposable: Boolean; virtual;
   function GetRealName: String; virtual;
   procedure MakeDir; virtual;
   destructor Done; virtual;
   procedure GetFull(var B; P: PFileRec; C, AFlags: Word); virtual;
   procedure GetEmpty(var B; C, AFlags: Word); virtual;
   procedure GetFreeSpace(var S: String); virtual;
   function CalcLength(AFlags: Word): Integer; virtual;
   procedure MakeTop(var S: String; AFlags: Word); virtual;
   function isUp: Boolean; virtual;
   procedure ChangeUp(var S: String); virtual;
   procedure ChangeRoot; virtual;
   procedure RereadDirectory(S: PathStr); virtual;
   function GetFullFlags: Word; virtual;
   procedure GetDirInfo(var B: TDiskInfoRec); virtual;
  end;

  PTempDrive = ^TTempDrive;
  TTempDrive = object(TFindDrive)
   constructor Init;
   constructor Load(var S: TStream);
   procedure   Store(var S: TStream);
   procedure   CopyFilesInto(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
   function    GetRealName: String; virtual;
   procedure   CopyFiles(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
   procedure   EraseFiles(AFiles: PCollection); virtual;
   procedure   GetDirInfo(var B: TDiskInfoRec); virtual;
   destructor  Done; virtual;
  end;

  procedure CopyToTempDrive(AFiles: PCollection; Own: PView);

const
      RFindDrive: TStreamRec = (
       ObjType: otFindDrive;
       VmtLink: Ofs(TypeOf(TFindDrive)^);
       Load: @TFindDrive.Load;
       Store: @TFindDrive.Store);

      RTempDrive: TStreamRec = (
       ObjType: otTempDrive;
       VmtLink: Ofs(TypeOf(TTempDrive)^);
       Load: @TTempDrive.Load;
       Store: @TTempDrive.Store);


implementation
uses DNApp, Advance, Startup, Memory, Messages, HistList, Commands,
     RStrings, FlPanel, FViewer, MicroEd, Tree, xTime, DnUtil;

const
  LowMemSize = $6000;  {Local setting}

var  FAdr   : Word;
     UsM    : Word;
     Rd,Ofs : Word;

function ESC_Pressed: Boolean; var E: TEvent;
begin
  Application^.Idle;
  GetKeyEvent(E); ESC_Pressed := (E.What = evKeyDown) and (E.KeyCode = kbEsc)
end;

function ReadingListMsg: PView; begin ReadingListMsg := WriteMsg(GetString(dlReadingList)) end;

procedure FindFile;
 var R: TRect;
     D: PDialog;
     P1, P2: PView;
     FN: PathStr;
     Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     PInfo: PWhileView;
     Files: PDirStorage;
     Directories: PCollection;
     C: Char;
     CancelSearch: Boolean;
     AMask: PathStr;
     Event: TEvent;
     BB: Boolean;
     II,I,J: Word;
begin
 II := ExecResource(dlgFileFind, FindRec);
 if II = cmCancel then Exit;
 ConfigModified := On;
 FindRec.Mask := DelSpaces(FindRec.Mask);
 if FindRec.Mask = '' then FindRec.Mask := x_x;
 AMask := FindRec.Mask;
 New(Files, Init);
 Directories := New(PStringCollection, Init(30,30));
 R.Assign(1, 1, 25, 8); Inc(SkyEnabled);
 New(PInfo, Init(R)); PInfo^.Options := PInfo^.Options or ofSelectable;
 PInfo^.Top := GetString(dlDBViewSearch);
 PInfo^.Bottom := GetString(dlNoFilesFound);
 Desktop^.Insert(PInfo);
 BB := FindFiles(Files, Directories, FindRec, PInfo);
 Desktop^.Delete(PInfo); Dec(SkyEnabled);
 Dispose(PInfo, Done);
 if not BB then MessageBox(^C+GetString(dlNoFilesFound), nil, mfError + mfOkButton);
end;

function ParseTime(S: String): LongInt;
 label 1, 2;
 var DT: DateTime;
     S1,S2,S3: String[5];
     TM: String[10];
     I, J: Integer;
     M: LongInt;
begin
  ParseTime := 0;
  Dt.Sec := 0; Dt.Hour := 0; Dt.Min := 0;
  I := PosChar(' ', S);
  if I > 0 then
    begin
      Tm := DelSpaces(Copy(S, I+1, 10));
      if Tm <> '' then
        begin
          I := Pos(CountryInfo.TimeSep, Tm);
          if I = 0 then Exit;
          DT.Hour := StoI(Copy(Tm, 1, I-1));
          J := 0;
          2:
          case UpCase(Tm[Length(Tm)]) of
            'M': begin J := 12; Goto 2 end;
            'A': Dec(Tm[0]);
            'P': begin J := 12; Dec(Tm[0]); end;
            '0'..'9':;
            else Goto 1;
          end;
          Inc(DT.Hour, J);
          DT.Min := StoI(Copy(Tm, I+Length(CountryInfo.TimeSep), 10));
        end;
 1: Byte(S[0]) := PosChar(' ', S) - 1;
    end else Tm := '';
  I := Pos(CountryInfo.DateSep, S);
  if I = 0 then Exit;
  S1 := Copy(S, 1, I-1);
  Delete(S, 1, I+Length(CountryInfo.DateSep)-1);
  I := Pos(CountryInfo.DateSep, S);
  if I = 0 then Exit;
  S2 := Copy(S, 1, I-1);
  Delete(S, 1, I+Length(CountryInfo.DateSep)-1);
  case CountryInfo.DateFmt of
    0: begin
         DT.Year := Stoi(S); if DT.Year < 100 then Inc(DT.Year, 1900);
         DT.Day := Stoi(S2); if DT.Day > 31 then Exit;
         DT.Month := Stoi(S1); if DT.Month > 12 then Exit;
       end;
    1: begin
         DT.Year := Stoi(S); if DT.Year < 100 then Inc(DT.Year, 1900);
         DT.Day := Stoi(S1); if DT.Day > 31 then Exit;
         DT.Month := Stoi(S2); if DT.Month > 12 then Exit;
       end;
    2: begin
         DT.Year := Stoi(S1); if DT.Year < 100 then Inc(DT.Year, 1900);
         DT.Day := Stoi(S); if DT.Day > 31 then Exit;
         DT.Month := Stoi(S2); if DT.Month > 12 then Exit;
       end;
  end;
  PackTime(DT, M);
  ParseTime := M;
end;

function FindFiles;
 var FN: PathStr;
     Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     C: Char;
     Drv: PFindDrive;
     Pnl: PView;
     CancelSearch: Boolean;
     DateAfter, DateBefore,
     SizeGreat, SizeLess: LongInt;
     MaskSearch: Boolean;
     Attr: Byte;
     Mask: String[12];
     T: TEventTimer;
     FF: string;

procedure InitPanel;
begin
 Pnl := Message(Desktop, evBroadcast, cmInsertDrive, Drv);
 if Pnl <> nil then PFilePanel(Pnl)^.ChangeLocked := On;
end;

 procedure DispatchEvents;
  var Event: TEvent;
 begin
  if PInfo = nil then Exit;
  Application^.GetEvent(Event);
  if (Event.What = evCommand) and (Event.Command = cmCancel) and
     (Event.InfoPtr = PInfo^.But) then
      begin
       PInfo^.ClearEvent(Event);
       CancelSearch := MessageBox(GetString(dlQueryCancelSearch),nil,mfYesNoConfirm)=cmYes;
      end;
  if (Event.What <> evNothing) and not ((Event.What = evCommand) and (Event.Command = cmQuit))
     then Application^.HandleEvent(Event);
 end;

 procedure SearchData(Path: PathStr);
  label Skip;
  var PDir: PString;
      SR: SearchRec;
      P: PFileRec;
      I: Byte;
      D: DateTime;

 function SearchF: Boolean;
   var S: TDOSStream;
 begin
   PInfo^.Write(1, Cut( Path+SR.Name, 50 ));
   S.Init(Path+SR.Name, stOpenRead);
   SearchF := (S.Status = stOK) and
              ( FViewer.SearchFileStr(@S, FindRec.What, 0,
                                          FindRec.Options and 2 <> 0,
                                          Off,
                                          FindRec.Options and 8 <> 0, Off) >= 0 );
   S.Done;
 end;

 begin
  if CancelSearch or not MemOK then Exit;
  PDir := nil;
  DosError := 0;
  if PInfo <> nil then PInfo^.Write(1, Cut(Path , 50 ));
  FindFirst(Path + Mask, $FF and not VolumeID, SR);

  While (DosError = 0) {and not LowMemory} and not CancelSearch and MemOK do
   begin
    if (SR.Attr and VolumeID = 0) and (SR.Name[1] <> '.') and
     (not Security or (Security and (SR.Attr and Hidden = 0)))
     and (MaskSearch or InSpaceFilter(SR.Name, FindRec.Mask))
     and ((FindRec.Options and ffoAdvanced = 0) or (SR.Time >= DateAfter)
          and (SR.Time <= DateBefore) and (SR.Size >= SizeGreat) and
          (SR.Size <= SizeLess) and ((Attr = 0) or (SR.Attr and Attr <> 0)))
     and ((FindRec.What='') or (SR.Attr and Directory <> 0) and (FindRec.What='')
          or (FindRec.What<>'') and SearchF)
         then
     begin
      if PDir = nil then PDir := NewStr(Path);
      P := NewFileRec(SR.Name, SR.Size, SR.Time, SR.Attr, PDir);
      if Pnl = nil then InitPanel;
      if Pnl <> nil then Message(Pnl, evCommand, cmInsertFile, P);
      Files^.AddFile(PDir^+SR.Name, SR.Size, SR.Size, SR.Time, SR.Attr);
      if PInfo <> nil then
      PInfo^.Bottom := ItoS(Files^.Files) + FF;
      if TimerExpired(T) then
        begin
          DispatchEvents;
          if PInfo <> nil then PInfo^.DrawView;
          NewTimer(T, 1);
        end;
     end;
    if TimerExpired(T) then
      begin
        DispatchEvents;
        NewTimer(T, 1);
      end;
    DosError := 0;
    FindNext(SR);
   end;

  if not MemOK then Drv^.NoMemory := True;

  if TimerExpired(T) then
  begin
    DispatchEvents;
    NewTimer(T, 1);
  end;
  if FindRec.Options and 4 <> 4 then goto Skip;
  DosError := 0;
  FindFirst(Path + x_x, $FF and not VolumeID, SR);
  While (DosError = 0) and not LowMemory and not CancelSearch do
   begin
    if (SR.Attr and VolumeID = 0) and (SR.Name[1] <> '.') and
       (SR.Attr and Directory <> 0) then SearchData(Path + SR.Name + '\');
    FindNext(SR);
   end;
Skip:
  if PDir <> nil then Directories^.Insert(PDir);
  DosError := 0;
  if PInfo <> nil then PInfo^.DrawView;

 end;


function SlowDrive(C: Char): Boolean;
begin
  case C of
     'C'..'Z' : SlowDrive := IsDriveCDROM(C);
    else SlowDrive := True;
  end;
end;

begin
 NewTimer(T, 0);
 FF := GetString(dlFilesFound);
 if FindRec.Options and ffoAdvanced <> 0 then
   begin
     DateAfter := ParseTime(AdvanceSearchData.After);
     DateBefore := ParseTime(AdvanceSearchData.Before);
     if DateBefore = 0 then DateBefore := $7FFFFFFF;
     SizeGreat := Stoi(AdvanceSearchData.Greater);
     SizeLess := Stoi(AdvanceSearchData.Less);
     if SizeLess = 0 then SizeLess := $7FFFFFFF;
     Attr := 0;
     if AdvanceSearchData.Attr and 1 <> 0 then Attr := Archive;
     if AdvanceSearchData.Attr and 2 <> 0 then Attr := Attr or SysFile;
     if AdvanceSearchData.Attr and 4 <> 0 then Attr := Attr or Hidden;
     if AdvanceSearchData.Attr and 8 <> 0 then Attr := Attr or ReadOnly;
   end;
 CancelSearch := Off; FindFiles := On;
 SearchString.What := FindRec.What;
 SearchString.Opts := ((FindRec.Options and 2) shr 1) or
                      ((FindRec.Options and 8) shr 2);
 Microed.SearchData.Line := FindRec.What;
 Microed.SearchData.What := #0;
 Microed.SearchData.Options := SearchString.Opts;
 Microed.SearchData.Scope := 0;
 MaskSearch := Pos(';', FindRec.Mask) = 0;
 if MaskSearch then
   begin
     Mask := Norm12(FindRec.Mask);
     if PosChar('.', FindRec.Mask) = 0 then Replace(' ', '?', Mask);
     Mask[9] := '.';
   end else Mask := x_x;
 New(Drv, Init('Find: ' + FindRec.Mask, Directories, Files));
 Drv^.isDisposable := Off;
 Pnl := nil;
 {FN := DelSpaces(FExpand(FindRec.Mask));
 FSplit(FN, Dr, Nm, Xt);}
 GetDir(0, FN); UpStr(FN);
 if FN[Length(FN)] <> '\' then FN := FN + '\';
 case FindRec.Where of
  1: SearchData(FN);
  2: for C := 'A' to 'Z' do
         if ValidDrive(C) then
           if (C = FN[1]) or (not SlowDrive(C)) then SearchData(C + ':\');
  {3: SearchData(Dr)}
   else SearchData(Copy(FN, 1, 3));
 end;
 if not MemOK then Drv^.NoMemory := True;
 if Pnl <> nil then
  begin
    if Pnl <> nil then PFilePanel(Pnl)^.ChangeLocked := Off;
    Drv^.isDisposable := On;
    Dispose(PFilePanel(Pnl)^.Files, Done);
    PFilePanel(Pnl)^.Files := New(PFilesCollection, Init($100,$80));
    Application^.Redraw;
    Message(Pnl, evCommand, cmPanelReread, nil);
  end;
 if (Files^.Files = 0) or (Pnl = nil) then
  begin
   Dispose(Drv, Done);
   FindFiles := Off;
  end;
end;


function ReadList;
  var F: PTextReader;
      I: Integer;
      S: String;
      Dir: DirStr;
      Nm: NameStr;
      Xt: ExtStr;
      SR: SearchRec;
      Dr: PString;
      P: PFileRec;
      D: DateTime;
      WW: PView;
begin
  ReadList := Off;

  F := New(PTextReader, Init(AName));
  if F = nil then Exit;


  FC := nil; DC := nil;
  WW := ReadingListMsg;
  while not F^.EOF and (IOResult = 0) and not Abort do
   begin
     UpdateWriteView(WW);
     S := F^.GetStr;
     DelLeft(S);
     I := Pos(':\', S);
     if I > 1 then Delete(S, 1, I-2);
     I := PosChar(' ',S);
     if I > 0 then S[0] := Char(I-1);
     if S <> '' then
       begin
         ClrIO;
         FindFirst(S, $3F xor VolumeID, SR);
         if (DOSError = 0) and not Abort then
          begin
            FSplit(FExpand(S), Dir, Nm, Xt);
            if DC = nil then DC := New(PStringCollection, Init(50,50));
            I := DC^.IndexOf(@Dir);
            if I < 0 then
              begin
                if Dir[Length(Dir)] <> '\' then AddStr(Dir, '\');
                Dr := NewStr(Dir);
                DC^.Insert(Dr);
              end else Dr := DC^.At(I);
          end;
         while (DOSError = 0) and not Abort do
          begin
            if SR.Name[1] <> '.' then
             begin
               if FC = nil then New(FC, Init);
               FC^.AddFile(Dr^+SR.Name, SR.Size, SR.Size, SR.Time, SR.Attr);
             end;
            ClrIO;
            FindNext(SR);
          end;
       end;
   end;

  Dispose(F, Done);
  WW^.Free;
  if (FC = nil) or (FC^.Files = 0) or (DC = nil) or (DC^.Count = 0) then
    begin
      if FC <> nil then Dispose(FC, Done);
      if DC <> nil then Dispose(DC, Done);
      MessageBox(^C+GetString(dlNoFilesFound), nil, mfError+mfOKButton);
      Exit
    end;
  ReadList := On;
end;

function OpenDirectory(const Dir: String): PDrive;
  var I: Integer;
      PI: PView;
      PDrv: PDrive;
      Dirs: PStringCollection;
      Files: PDirStorage;
      P: PString;
      tmr: TEventTimer;
      MemReq: LongInt;

  procedure AddDirectory(S: String);
  begin
     if S[Length(S)] <> '\' then AddStr(S, '\'); LowStr(S);
     Dirs^.Insert(NewStr(S));
  end;

  procedure ReadDir(Dr: PString);
    var SR: SearchRec;
        P: PFileRec;
        D: DateTime;
  begin
     ClrIO;
     FindFirst(Dr^+x_x, $3F xor VolumeID, SR);
     while not Abort and (DOSError = 0) do
       begin
         if (SR.Attr and Hidden = 0) or (not Security) then
           if SR.Attr and Directory = 0 then
             begin
               Files^.AddFile(Dr^+SR.Name, SR.Size, SR.Size, SR.Time, SR.Attr);
               Inc(MemReq, SizeOf(TFileRec));
               {if Files^.Count = 2000 then
                begin
                  MessageBox(GetString(dlFindCantKeep), nil, mfError + mfOKButton);
                  Exit;
                end;}
             end else
             if SR.Name[1] <> '.' then AddDirectory(Dr^+SR.Name);
         FindNext(SR);
       end;
  end;

begin
  NewTimer(Tmr,0);
  Dirs := New(PStringCollection, Init($80,$40));

  PI := ReadingListMsg;
  New(Files, Init);

  AddDirectory(FExpand(Dir));
  I := Dirs^.Count-1;
  MemReq := LowMemSize;
  while (I >= 0) and (not Abort) and (System.MemAvail > MemReq) do
    begin
      I := Dirs^.Count-1;
      {if Files^.Count >= 2000 then Break;}
      while (I >= 0) and (not Abort) and (System.MemAvail > MemReq) do
        begin
          UpdateWriteView(PI);
          P := Dirs^.At(I);
          if (P^[1] >= 'a') and (P^[1] <= 'z') then
            begin
              UpStr(P^);
              Dirs^.AtDelete(I);
              Dirs^.Insert(P);
              ReadDir(P);
              if TimerExpired(Tmr) then
              begin
                NewTimer(Tmr, 1);
                if ESC_Pressed then Abort := True;
              end;
              Break;
            end;
          Dec(I);
        end;
    end;
  PI^.Free;
  PDrv := New(PFindDrive, Init(GetString( dlBranch )+Dir, Dirs, Files));
  PDrv^.NoMemory := System.MemAvail <= MemReq;
  OpenDirectory := PDrv;
end;


constructor TFindDrive.Init;
 var S: PString;
     SS: String;
     I: Integer;
     P: PFileRec;
begin
 TObject.Init;
 Flags := ColumnsDefaults.FindDrive;
 AllowPack := True;
 ListFile := nil;
 isDisposable := On;
 DriveType := dtFind;
 CurDir := AName;
 Dirs := PSortedCollection(ADirs);
 Files := AFiles;
 System.GetDir(0, SS); ClrIO;
 S := NewStr(SS);
 I := Dirs^.IndexOf(S);
 if I >= 0 then begin DisposeStr(S); S := Dirs^.At(I); end
           else Dirs^.Insert(S);
 NewUpFile;
 UpFile^.Owner := S;
end;

procedure TFindDrive.NewUpFile;
begin
  UpFile := NewFileRec('..',0,0,Directory,nil);
end;

constructor TFindDrive.Load(var S: TStream);
 var I, J, K: Integer;
     P: PFileRec;
begin
 inherited Load(S);
 AllowPack := True;
 isDisposable := On;
 S.Read(DriveType,SizeOf(DriveType));
 Dirs := PSortedCollection(S.Get);
 S.Read(I, SizeOf(I)); if I < 0 then I := 0;
 if Dirs = nil then Fail;
 Files := PDirStorage(S.Get);
 ListFile := S.ReadStr;
 NewUpFile;
 UpFile^.Owner := Dirs^.At(I);
end;

procedure TFindDrive.Store(var S: TStream);
 var I, J: Integer;
     PF: PFileRec;
begin
  inherited Store(S);
  S.Write(DriveType,SizeOf(DriveType));
  S.Put(Dirs);
  I := Dirs^.IndexOf(UpFile^.Owner);
  S.Write(I, SizeOf(I));
  S.Put(Files);
  S.WriteStr(ListFile);
end;

destructor TFindDrive.Done;
begin
 if Files <> nil then Dispose(Files, Done);
 if Dirs <> nil then Dispose(Dirs, Done);
 if UpFile <> nil then Dispose(UpFile);
 DisposeStr(ListFile);
 inherited Done;
end;

{procedure TFindDrive.EraseFiles;
 var I, J: Integer;
     PF: PFileRec;
begin
 for I := 1 to AFiles^.Count do
  begin
   PF := AFiles^.At(I-1);
   if PSortedCollection(Files)^.Search(PF, J) then Files^.AtFree(J);
  end;
end;}

procedure TFindDrive.MakeDir;
begin
end;

procedure TFindDrive.ChDir;
begin
end;

function TFindDrive.GetDirectory;
 label LLL;
 var AFiles: PFilesCollection;
     SR: SearchRec;
     P: PFileRec;
     D: DateTime;
     I: Integer;
     DrNm: PathStr;
     AllFiles: Boolean;
     FreeSpc, TotalLen: TSize;
     PD: PString;
     OW: Pointer;
     S: PathStr;
     OOM: Boolean;

function CMatches: Boolean;
begin
  OOM := OOM or (MaxAvail < (AFiles^.Count+$200)*4);
  CMatches := not OOM;
end;

begin

LLL:

 OOM := False;
 DOSError := 0;
 Abort := Off; AllFiles := FileMask = x_x; ClrIO; FreeSpc := 0;
 FreeSpace := ''; TotalInfo := ''; TotalLen := 0;

 Files^.ResetPointer('');

 AFiles := New(PFilesCollection, Init($100, $80));
 PFilesCollection(AFiles)^.Owner := Owner;
 AFiles^.Duplicates := True;

 PFilesCollection(AFiles)^.SortMode := SortMode; S := ''; PD := nil;
 ClrIO;
 While not Files^.Last and Files^.GetNextFile and MemOK and CMatches do
  begin

    if (S = Files^.LastDir) then OW := PD else
      if Dirs^.Search(@Files^.LastDir, I) then
      begin
        PD := Dirs^.At(I);
        OW := PD;
        S := PD^
      end else
      begin
        OW := Dirs^.At(0);
      end;


   with Files^.CurFile do P := NewFileRec(Name, Size, Date, Attr, OW);


   if AllFiles or (P^.Attr and Directory <> 0) or InFilter(MakeFileName(P^.Name), FileMask)
    then begin
      with AFiles^ do AtInsert(Count, P);
    end else
    begin
      Dispose(P); Continue
    end;
   TotalLen := TotalLen + P^.Size;
   if P^.Attr and Directory <> 0 then
    begin
       P^.Attr := P^.Attr and $7F;
       P^.Size := 0;
       if PanelFlags and fmiDirLen <> 0 then
        begin
          if SR.Name[1] <> '.' then
             P^.Size := GetDirLen(MakeNormName(P^.Owner^, MakeFileName(P^.Name)));
          if Abort then begin PanelFlags := PanelFlags and (not fmiDirLen); Abort := Off; end;
        end;
    end;
  end;

  if AFiles^.Count > 0 then
  begin
    if (OOM) or (not MemOK) then
    begin
      NoMemory := True;
      if AllowPack then
      begin
        Files^.Truncate(Max((AFiles^.Count-100), 0));
        Dispose(AFiles, Done);
        goto LLL;
      end;
    end;
    AFiles^.QSort;
 end else
 begin
   if (OOM) or (not MemOK) then NoMemory := True;
 end;

 if DriveType <> dtTemp then AFiles^.AtInsert(0, CopyFileRec(UpFile));

 TotalInfo := CalcTotalInfo(AFiles^.Count, AFiles^.Count, TotalLen);

 GetDirectory := AFiles;

end;

function TFindDrive.CalcLength;
begin
 CalcLength := 13 +
               (10 + CountryInfo.TimeFmt) * Byte(AFlags and psShowSize <> 0) +
                9 * Byte(AFlags and psShowDate <> 0) +
               (7 - CountryInfo.TimeFmt) * Byte(AFlags and psShowTime <> 0) +
               80 * Byte(AFlags and psShowDir <> 0)
                ;
end;

procedure TFindDrive.MakeTop;
 var Q: String[80];
begin
 S := GetString(dlTopName);
 if AFlags and psShowSize <> 0 then S := S + Copy(GetString(dlTopSize),2-CountryInfo.TimeFmt, 255);
 if AFlags and psShowDate <> 0 then S := S + GetString(dlTopDate);
 if AFlags and psShowTime <> 0 then S := S + Copy(' '+GetString(dlTopTime), 1+CountryInfo.TimeFmt, 255);
 if Flags and psShowDir <> 0 then
  begin
   Q := GetString(dlTopPath);
   S := S + Q + Strg(' ', 80-Length(Q)) + '~³~';
  end;
end;

procedure TFindDrive.GetFull;
 var X: Byte;
begin
  inherited GetFull(B, P, C, AFlags);
  if AFlags and psShowSize <> 0 then X := 24 else X := 13;
  if AFlags and psShowDate <> 0 then Inc(X, 9);
  if AFlags and psShowTime <> 0 then Inc(X, 6);
  if AFlags and psShowDir <> 0 then
   begin
    MoveStr(TWordArray(B)[X], P^.Owner^, C);
    Inc(X, 80);
   end;
end;

procedure TFindDrive.GetEmpty;
 var
     X: Byte;
begin
  C := C and $0FFF;
  inherited GetEmpty(B, C, AFlags);
  TWordArray(B)[12] := (TWordArray(B)[12] and $F000) or C;
end;

procedure TFindDrive.ChangeUp;
 var P: PDrive;
begin
  if ListFile = nil then S := '' else S := GetName(ListFile^);
  if Owner = nil then Exit;
  if Prev = nil then
   begin
     New(Prev, Init(0, Owner, PFilePanel(Owner)^.ShowFlags));
     if Prev = nil then Exit;
     GlobalMessage(evCommand, cmRereadInfo, nil);
   end;
  PDrive(PFilePanel(Owner)^.Drive) := PDrive(Prev);
  Prev^.ChDir(Prev^.CurDir);
  if (Prev^.DriveType = dtDisk) and
     (PView(Owner)^.GetState(sfSelected+sfActive)) then
      ActivePanel := Owner;
  GlobalMessage(evCommand, cmRereadInfo, nil);
  Prev := nil;
  Dispose(PDrive(@Self), Done);
end;

procedure TFindDrive.ChangeRoot;
  var P: PDrive;
begin
  if Prev <> nil then
    begin
      PDrive(PFilePanel(Owner)^.Drive) := PDrive(Prev);
      Prev^.ChangeRoot;
      GlobalMessage(evCommand, cmRereadInfo, nil);
      Prev := nil;
      Dispose(PDrive(@Self), Done);
      Exit;
    end;
  New(Prev, Init(0, Owner, PFilePanel(Owner)^.ShowFlags));
  if Prev = nil then Exit;
  GlobalMessage(evCommand, cmRereadInfo, nil);
  {Prev^.Owner := Owner;}
  {Prev^.Flags := PFilePanel(Owner)^.ShowFlags;}
  PDrive(PFilePanel(Owner)^.Drive) := PDrive(Prev);
  Prev^.ChangeRoot;
  if (PView(Owner)^.GetState(sfSelected+sfActive)) then
      ActivePanel := Owner;
  GlobalMessage(evCommand, cmRereadInfo, nil);
  Prev := nil;

end;

function TFindDrive.isUp;
begin
 isUp := True;
end;

function TFindDrive.Disposable;
begin
 Disposable := isDisposable;
end;

procedure TFindDrive.RereadDirectory;
var PV: PView;
begin
{ if (Prev <> nil) or (Prev^.Prev = nil) then Exit;}
 PV := ReadingListMsg;
 ForceWriteShow(PV);
 if Prev <> nil then Prev^.RereadDirectory(S);
 Files^.DosReread;
 Dispose(PV, Done);
end;


function TFindDrive.GetRealName;
begin
 GetRealName := '';
end;

procedure NewTemp;
 var S: PString;
     SS: String;
     I: Integer;
     P: PFileRec;
begin
 if TempFiles = nil then New(TempFiles, Init);
end;

procedure CopyToTempDrive;
 var I: Integer;
     PS: PString;
     PF: PFileRec;
     Info: PView;

 procedure AddRec(P: PFileRec); far;
   var Dr: PathStr;
       Nmm: String[12];
       DT: DateTime;
 begin
   UpdateWriteView(Info);
   Dr := P^.Owner^; if Dr[Length(Dr)] <> '\' then AddStr(Dr, '\'); UpStr(Dr);
   TempFiles^.ResetPointer(''); Nmm := MakeFileName(P^.Name); UpStr(Nmm);
   While not TempFiles^.Last and TempFiles^.GetNextFile do
    with TempFiles^ do
      if (CurFile.Name = Nmm) and (LastDir = Dr) then Exit;
   TempFiles^.AddFile(Dr+Nmm, P^.Size, P^.Size, PackedDate(P), P^.Attr);
   if TempDirs = nil then TempDirs := New(PStringCollection, Init(10, 10));
   if TempDirs^.IndexOf(@Dr) < 0 then TempDirs^.Insert(NewStr(Dr));
 end;

begin
 if TempDirs = nil then TempDirs := New(PStringCollection, Init(10, 10));
 if TempFiles = nil then NewTemp;
 Info := WriteMsg(GetString(dlPleaseStandBy));
 AFiles^.ForEach(@AddRec);
 Dispose(Info, Done);
 Drives.RereadDirectory(cTEMP_);
end;

constructor TTempDrive.Init;
  var S: PString;
      I: Integer;
begin
 TObject.Init;
 Flags := ColumnsDefaults.Temp;
 if TempDirs = nil then TempDirs := New(PStringCollection, Init(10, 10));
 if TempFiles = nil then NewTemp;
 isDisposable := On;
 Files := TempFiles;
 Dirs := TempDirs;
 CurDir := cTEMP_;
 DriveType := dtTemp;
 ListFile := nil;
 System.GetDir(0, FreeStr); ClrIO;
 S := NewStr(FreeStr);
 I := Dirs^.IndexOf(S);
 if I >= 0 then begin DisposeStr(S); S := Dirs^.At(I); end
           else Dirs^.Insert(S);
 NewUpFile;
 UpFile^.Owner := S;
end;

{
constructor TFindDrive.Load(var S: TStream);
 var I, J, K: Integer;
     P: PFileRec;
begin
 inherited Load(S);
 AllowPack := True;
 isDisposable := On;
 S.Read(DriveType,SizeOf(DriveType));
 Dirs := PSortedCollection(S.Get);
 S.Read(I, SizeOf(I)); if I < 0 then I := 0;
 if Dirs = nil then Fail;
 Files := PDirStorage(S.Get);
 ListFile := S.ReadStr;
 NewUpFile;
 UpFile^.Owner := Dirs^.At(I);
end;

}

constructor TTempDrive.Load(var S: TStream);
begin
  TDrive.Load(S);
  S.Read(DriveType,SizeOf(DriveType));
  Dirs := PSortedCollection(S.Get);
  Files := PDirStorage(S.Get);
  TempFiles := Files;
  TempDirs := Dirs;
  NewUpFile;
  UpFile^.Owner := S.ReadStr;
end;


procedure TTempDrive.Store;
begin
  TDrive.Store(S);
  S.Write(DriveType,SizeOf(DriveType));
  S.Put(Dirs);
  S.Put(Files);
  S.WriteStr(UpFile^.Owner)
end;

{
 label 1;
 var I, J, K: Integer;
     PF: PFileRec;
     B: Boolean;
     SS: PString;

  procedure DoInit(P: PFileRec); far;
  begin
    P^.Diz := nil;
  end;

begin
 S.Read(B, SizeOf(Boolean));
 if B then
   begin
     SS := S.ReadStr;
     Files := TempFiles;
     if TempDirs <> nil then
       begin
         I := TempDirs^.IndexOf(SS);
         if I < 0 then Goto 1
            else begin DisposeStr(SS); SS := TempDirs^.At(I); end;
       end else
        begin
          TempDirs := New(PStringCollection, Init(10,10));
1:        TempDirs^.Insert(SS);
        end;
      Dirs := TempDirs;
      NewUpFile;
      UpFile^.Owner := SS;
   end else
   begin
     if TempFiles <> nil then Dispose(TempFiles, Done);
     if TempDirs <> nil then Dispose(TempDirs, Done);
     inherited Load(S);
     TempDirs := Dirs;
     TempFiles := Files;
   end;
end;
}
{procedure TTempDrive.Store;
begin
  S.Write(TempStored, SizeOf(Boolean));
  if  TempStored then S.WriteStr(UpFile^.Owner)
                 else inherited Store(S);
  TempStored := True;
end;}

procedure TTempDrive.CopyFilesInto;
begin
 CopyToTempDrive(AFiles, Own);
end;

procedure TTempDrive.EraseFiles;
 var I: Integer;

 procedure Erase(P: PFileRec); far;
 begin
   Files^.DeleteFile(P);
 end;

begin
 AFiles^.ForEach(@Erase);
 Drives.RereadDirectory(cTEMP_);
end;

function TTempDrive.GetRealName;
begin
 GetRealName := cTEMP_;
end;

destructor TTempDrive.Done;
begin
 TDrive.Done;
end;

procedure TFindDrive.GetFreeSpace;
begin
  S := '';
end;

function TFindDrive.GetFullFlags;
begin
 GetFullFlags := psShowSize + psShowDate + psShowTime + psShowDir;
end;

constructor TFindDrive.InitList;
  var FC: PSortedCollection;
      DC: PDirStorage;
begin
  if not ReadList(AName, FC, DC) then Fail;
  Init(AName, PCollection(FC), DC);
  ListFile := NewStr(AName);
end;

procedure TTempDrive.CopyFiles;
begin
 FileCopy.CopyFiles(AFiles, Own, MoveMode, 1);
 {if MoveMode then EraseFiles(AFiles);}
end;

procedure TFindDrive.CopyFilesInto;
begin
end;

procedure TFindDrive.GetDirInfo;
  var Fl: Integer;
      Sz: LongInt;
      S1,S2: String[40];

  procedure DoCount(P: PFileRec); far;
  begin
    if (P <> nil) and (P^.Attr and Directory = 0) then
      begin
        Inc(Fl);
        Inc(Sz, P^.Size);
      end;
  end;

begin
  B.Title := NewStr( GetString( dlDIFileFind ));
  B.Dir := NewStr(GetString( dlDIFFMask )+Copy(CurDir, PosChar(':', CurDir)+1, 255));
  Fl := 0; Sz := 0;
  {!!!if Files <> nil then Files^.ForEach(@DoCount);}

  if Fl = 0 then B.Files := NewStr(GetString(dlDINoFiles))
   else
    begin
     if Fl = 1 then S1 := GetString(dlDIFile) else S1 := GetString(dlDIFiles);
     if Sz = 1 then S2 := GetString(dlDIByte) else S2 := GetString(dlDIBytes);
     B.Files := NewStr('~'+FStr(Fl)+'~ '+S1+GetString(dlDIWith)+'~'+FStr(Sz)+'~ '+S2);
    end;

end;

procedure TTempDrive.GetDirInfo;
  var Fl: Integer;
      Sz: LongInt;
      S1,S2: String[40];

  procedure DoCount(P: PFileRec); far;
  begin
    if (P <> nil) and (P^.Attr and Directory = 0) then
      begin
        Inc(Fl);
        Inc(Sz, P^.Size);
      end;
  end;

begin
  B.Title := NewStr( GetString( dlDITemporary ));
  B.Dir := NewStr(cTEMP_);
  Fl := 0; Sz := 0;
  {!!!
  if Files <> nil then Files^.ForEach(@DoCount);
  }
  if Fl = 0 then B.Files := NewStr(GetString(dlDINoFiles))
   else
    begin
     if Fl = 1 then S1 := GetString(dlDIFile) else S1 := GetString(dlDIFiles);
     if Sz = 1 then S2 := GetString(dlDIByte) else S2 := GetString(dlDIBytes);
     B.Files := NewStr('~'+FStr(Fl)+'~ '+S1+GetString(dlDIWith)+'~'+FStr(Sz)+'~ '+S2);
    end;

end;


end.

