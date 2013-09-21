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

Unit ArcView;

Interface uses Dos,Objects,Views,Drivers,FViewer,FlPanel,FilesCol,DiskInfo,
               DblWnd,HistList,HideView,RStrings,Drives,Commands,Archiver,
               FStorage, ObjType, Advance;
const
    DirToChange: PathStr = '';

type
    PArcDrive = ^TArcDrive;
    TArcDrive = object(TDrive)
     ArcName: PathStr;
     AType: PARJArchive;
     Files: PDirStorage;
     KillAfterUse: Boolean;
     ArcDate: LongInt;
     ForceRescan: Boolean;
     Password: String;
     constructor Init(const AName: String);
     constructor InitCol(PC: PDirStorage; const AName: String);
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     procedure RereadDirectory(S: PathStr); virtual;
     procedure KillUse; virtual;
     function ReadArchive: Boolean;
     procedure ChDir(ADir: PathStr); virtual;
     function GetDir: PathStr; virtual;
     function GetDirectory(SortMode, PanelFlags: Integer; const FileMask: String;
                           var FreeSpace, TotalInfo: String ): PCollection; virtual;
     function Exec(Prg, Cmd: String): Boolean;
     procedure UseFile(P: PFileRec; Command: Word); virtual;
     function MakeListFile(PC: PCollection): String;
     procedure CopyFiles(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
     procedure CopyFilesInto(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
     procedure EraseFiles(AFiles: PCollection); virtual;
     {procedure GetDown(var B; C: Word; P: PFileRec); virtual;}
     procedure GetFull(var B; P: PFileRec; C, AFlags: Word); virtual;
     procedure GetEmpty(var B; C, AFlags: Word); virtual;
     function CalcLength(AFlags: Word): Integer; virtual;
     function GetRealName: String; virtual;
     procedure MakeTop(var S: String; AFlags: Word); virtual;
     procedure HandleCommand(Command: Word; InfoPtr: Pointer); virtual;
     procedure MakeDir; virtual;
     function isUp: Boolean; virtual;
     procedure ChangeUp(var S: String); virtual;
     procedure ChangeRoot; virtual;
     procedure ExtractFiles(AFiles: PCollection; ExtrDir: PathStr; Own: PView; Options: Byte);
     procedure GetFreeSpace(var S: String); virtual;
     procedure GetDirInfo(var B: TDiskInfoRec); virtual;
     function  GetFullFlags: Word; virtual;
     procedure GetDirLength(PF: PFileRec); virtual;
     destructor Done; virtual;
     procedure StdMsg4;
    end;

    function ArcViewer(AName : PathStr): Boolean;
    procedure StdMsg(MsgNo: Byte);

const
    ArcPasw    : String[32] = '';

type
    PFInfo     = ^TFInfo;
    TFInfo     = Record
                  FName   : PathStr;
                  USize   : LongInt;
                  PSize   : LongInt;
                  Date    : LongInt;
                  Attr    : Byte;
                  Last    : Byte;
                  { 0 - not last    }
                  { 1 - archive end }
                  { 2 - broken arc  }
                 end;

const
      RFileInfo: TStreamRec = (
       ObjType: otFileInfo;
       VmtLink: Ofs(TypeOf(TFileInfo)^);
       Load: @TFileInfo.Load;
       Store: @TFileInfo.Store);

      RArcDrive: TStreamRec = (
       ObjType: otArcDrive;
       VmtLink: Ofs(TypeOf(TArcDrive)^);
       Load: @TArcDrive.Load;
       Store: @TArcDrive.Store);

      RUserSaver: TStreamRec = (
       ObjType: otUserSaver;
       VmtLink: Ofs(TypeOf(TUserSaver)^);
       Load: @TUserSaver.Load;
       Store: @TUserSaver.Store);

Implementation uses Menus,DnApp,Messages,Dialogs,Gauge,FileCopy,
                    Memory,Startup, Arvid, xTime;

const
  LowMemSize = $4000;  {Local setting}

function MaxAvail: LongInt;
begin
  MaxAvail := MemAdjust(System.MaxAvail);
end;

Procedure StdMsg(MsgNo: Byte);
var
  si: TStrIdx;
begin
 Application^.Redraw;
 case MsgNo of
  4 : MessageBox(GetString(dlArcMsg4)+Cut(ArcFileName,40),NIL,mfOkButton or mfError);
  5 : Msg(dlArcMsg5,NIL,mfOkButton or mfInformation);
  1, 6, 7:
   begin
     case MsgNo of
       1: si := dlArcMsg1;
       6: si := dlArcMsg6;
       7: si := dlArcMsg7;
     end;
     ErrMsg(si);
   end;
 end;
end;

procedure TArcDrive.StdMsg4;
begin
  if TempFile <> '' then TEMPFile := ''; StdMsg(4); Abort := On;
end;


constructor TArcDrive.Init;
 var SR: SearchRec;
     Nm: NameStr;
     Xt: ExtStr;
begin
 TObject.Init;
 Flags := ColumnsDefaults.Arc;
 ArcName := FExpand(AName);
 FSplit(ArcName, FreeStr, Nm, Xt);
 if Xt = '' then AddStr(ArcName, '.');
 FindFirst(ArcName, $3F xor VolumeID, SR);
 if DosError <> 0 then
 begin
   ArcFileName := ArcName;
   StdMsg4;
   Fail
 end;
 ArcDate := SR.Time;
 DriveType := dtArc;
 if not ReadArchive or (Files = nil) then Fail;
 KillAfterUse := TempFile <> '';
 TempFile := '';
 Password := '';
 CurrentArchive := AType;
end;

constructor TArcDrive.InitCol;
 var SR: SearchRec;
 var  Dr: PathStr;
      Nm: NameStr;
      Xt: ExtStr;
      ExeRec: record
               AR: Array[0..1] of Char;
               LastB: Word;
               TotalB: Word;
               Relocations: Word;
               HeaderSize: Word;
              end;
begin
 TObject.Init;
 Flags := ColumnsDefaults.Arc;
 ArcName := FExpand(AName);
 FindFirst(ArcName, $3F xor VolumeID, SR);
 ArcDate := SR.Time;
 DriveType := dtArc;
 Files := PC;
 if (Files = nil) then Fail;
 KillAfterUse := TempFile <> '';
 TempFile := '';
 Password := '';
 FSplit(UpStrg(ArcName), Dr, Nm, Xt);
 ArcFile.Init(ArcName, stOpenRead, 512);
 ArcFileName := ArcName;
 if ArcFile.Status <> stOK then begin
   StdMsg(4);
   ArcFile.Done;
   if Files <> nil then Dispose(Files, Done);
   Fail;
 end;
 ArcPos := 0;
 if XT = '.EXE' then begin
   ArcFile.Read(ExeRec, SizeOf(ExeRec));
   if (ExeRec.AR = 'MZ') or (ExeRec.AR = 'ZM') then begin
     ArcPos := LongInt(ExeRec.TotalB)*512 {+ LongInt(ExeRec.HeaderSize)*16)} -
               512 + LongInt(ExeRec.LastB);
   end;
 end;
 AType := DetectArchive;
 ArcFile.Done;
end;

constructor TArcDrive.Load;
 var  Dr: PathStr;
      Nm: NameStr;
      Xt: ExtStr;
      SR: SearchRec;
      ExeRec: record
               AR: Array[0..1] of Char;
               LastB: Word;
               TotalB: Word;
               Relocations: Word;
               HeaderSize: Word;
              end;
label
  Failure;
begin
 inherited Load(S);
 S.Read(ArcName[0],1);
 S.Read(ArcName[1],Length(ArcName));
 S.Read(KillAfterUse, 1);
 S.Read(Password[0],1);
 S.Read(Password[1],Length(Password));
 Files := PDirStorage(S.Get);
 ForceRescan := Off;
 DriveType := dtArc;
 FSplit(UpStrg(ArcName), Dr, Nm, Xt);
 ArcFileName := ArcName;
 FindFirst(ArcName, $3F xor VolumeID, SR);
 if DosError <> 0 then goto Failure;
 ArcDate := SR.Time;
 ArcFile.Init(ArcName, stOpenRead, 512);
 if ArcFile.Status <> stOK then begin
   ArcFile.Done;
 Failure:
   StdMsg(4);
   if Files <> nil then Dispose(Files, Done);
   S.Read(ForceRescan, 1);
   Fail;
 end;
 ArcPos := 0;
 if XT = '.EXE' then begin
   ArcFile.Read(ExeRec, SizeOf(ExeRec));
   if (ExeRec.AR = 'MZ') or (ExeRec.AR = 'ZM') then begin
     ArcPos := LongInt(ExeRec.TotalB)*512 - 512 + LongInt(ExeRec.LastB);
   end;
 end;
 AType := DetectArchive;
 ArcFile.Done;
 if AType = nil then goto Failure;
 S.Read(ForceRescan, 1);
end;

procedure TArcDrive.KillUse;
begin
 if Prev <> nil then Prev^.KillUse;
 if KillAfterUse then EraseFile(ArcName);
end;

procedure TArcDrive.Store;
begin
 inherited Store(S);
 S.Write(ArcName[0],1 + Length(ArcName));
 S.Write(KillAfterUse, 1);
 S.Write(Password[0],1 + Length(Password));
 S.Put(Files);
 S.Write(ForceRescan, 1);
end;

destructor TArcDrive.Done;
begin
 if Files <> nil then Dispose(Files, Done);
 CurrentArchive := nil;
 inherited Done;
end;

Function TArcDrive.ReadArchive;
var PF : PArcFile;
    i  : Integer;
    ev : TEvent;
    P  : PWhileView;
    R  : TRect;
    Dr: PathStr;
    Nm: NameStr;
    Xt: ExtStr;
    Ln: LongInt;
    Cancel: Boolean;
    T: TEventTimer;
    ExeRec: record
             AR: Array[0..1] of Char;
             LastB: Word;
             TotalB: Word;
             Relocations: Word;
             HeaderSize: Word;
            end;
begin
 ReadArchive:=Off;
 FSplit(UpStrg(ArcName), Dr, Nm, Xt);
 ArcFile.Init(ArcName, stOpenRead, 512);
 ArcFileName := ArcName;
 if ArcFile.Status <> stOK then
  begin
    ArcFile.Done;
    StdMsg4;
    Exit;
  end;
 if Files <> nil then Dispose(Files, Done);
 Files := nil; ArcPos := 0;
 if XT = '.EXE' then
  begin
   ArcFile.Read(ExeRec, SizeOf(ExeRec));
   if (ExeRec.AR = 'MZ') or (ExeRec.AR = 'ZM') then
    begin
     ArcPos := LongInt(ExeRec.TotalB)*512 {+ LongInt(ExeRec.HeaderSize)*16)} -
               512 + LongInt(ExeRec.LastB);
    end;
  end;
 AType := DetectArchive;
 if AType = nil then begin ArcFile.Done; Exit; end;
 New(Files, Init);
 if Files = nil then Exit; P := nil;
 R.Assign(1,1,30,10);
 {P := WriteMsg(GetString(dlArcReadArc));}
 LN := ArcFile.GetSize + 1;
 Cancel := Off; PReader := nil;
 Inc(SkyEnabled);
 NewTimer(T, 3);
 Repeat
  if TimerExpired(T) then
    begin
      if P = nil then
        begin
          New(P, Init(R));
          PReader := P;
          P^.Top := GetString(dlArcReadArc);
          P^.Write(1, GetString(dlPercentComplete));
          Desktop^.Insert(P);
        end;
      P^.Write(2, Copy(Strg(#219, ((ArcFile.GetPos+1)*25) div LN)+Strg(#177, 25), 1, 25));
      P^.Write(3, ItoS(Files^.Files)+GetString(dlFilesFound));
      NewTimer(T, 3);
    end;
  AType^.GetFile;
  if FileInfo.Last=0 then
     begin
      DelLeft(FileInfo.FName);
      if FileInfo.FName[1] <> '\' then FileInfo.FName := '\' + FileInfo.FName;
      Replace('/', '\', FileInfo.FName); UpStr(FileInfo.FName);
      if FileInfo.Attr and 1 <> 0 then FileInfo.Attr := FileInfo.Attr or Hidden;
      Files^.AddFile(FileInfo.FName, FileInfo.USize, FileInfo.PSize,
                     FileInfo.Date, FileInfo.Attr);
      if (P <> nil) and  TimerExpired(T) then
        begin
          DispatchEvents(P, Cancel);
          if Cancel then begin StdMsg(5);FileInfo.Last:=1; end;
        end;
     end;
 until (FileInfo.Last>0) or LowMemory;
 Dec(SkyEnabled);
 if P <> nil then P^.Free;
 ArcFile.Done;
 if FileInfo.Last=2 then StdMsg(6);
 ReadArchive:=On;
 if Files^.Files=0 then begin StdMsg(7);ReadArchive:=Off;end;
end;

procedure TArcDrive.ChDir;
 var Dr: DirStr;
     Nm: NameStr;
     Xt: ExtStr;
begin
 CurrentArchive := AType;
 if ADir = #0 then Exit;
 While (PosChar(CurDir[Length(CurDir)], ' .\') > 0) do Dec(CurDir[0]);
 if ADir[1] = '.' then
  begin
   if CurDir <> '' then While (CurDir <> '') and (CurDir[Length(CurDir)] <> '\') do Dec(CurDir[0])
                   else Advance.ChDir(GetPath(ArcName));
   Exit;
  end;
 FSplit(ADir, Dr, Nm, Xt);
 if Xt = '..' then
  begin
   CurDir := Dr;
   repeat Dec(CurDir[0]) until (CurDir = '') or (CurDir[Length(CurDir)] = '\');
  end else CurDir := ADir;
 While (PosChar(CurDir[Length(CurDir)], ' .\') > 0) do Dec(CurDir[0]);
end;

function TArcDrive.GetDir;
 var Dr: String;
     Nm: NameStr;
     Xt: ExtStr;
begin
 While (PosChar(CurDir[Length(CurDir)], ' .\') > 0) do Dec(CurDir[0]);
 if (Length(CurDir)>0) and (CurDir[1]<>'\') then CurDir := '\' + CurDir;
 FSplit(ArcName, Dr, Nm, Xt);
 GetDir := AType^.GetSign+Copy(Dr,1,2)+Nm+Xt+CurDir;;
end;

function TArcDrive.GetDirectory;
 var F: PFileRec;
     FA: PArcFile;
     I: Integer;
     Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     DT: DateTime;
     AllFiles: Boolean;
     AFiles, FF, FD: PFilesCollection;
     TTL, TPL: TSize;
     _USize, _PSize: LongInt;
     FR: TFileRec;
     OW: Pointer;
     ExeRec: record
              AR: Array[0..1] of Char;
              LastB: Word;
              TotalB: Word;
             end;

begin
 While (PosChar(CurDir[Length(CurDir)], ' .\') > 0) do Dec(CurDir[0]);
 AFiles := New(PFilesCollection, Init(Files^.Files, 10));
 FD := New(PFilesCollection, Init(40, 10));
 PFilesCollection(AFiles)^.Owner := Owner;
 PFilesCollection(AFiles)^.SortMode := Sortmode;
 FreeSpace := ''; TotalInfo := ''; TTL := 0; TPL := 0;
 GetDirectory := AFiles; AllFiles := FileMask = x_x;
 FD^.SortMode := 141;
 AFiles^.Duplicates := True;
 Files^.ResetPointer('');
 While not Files^.Last and Files^.GetNextFile and (MaxAvail > LowMemSize) do
  begin
    _USize := Files^.CurFile.Size;
    _PSize := Files^.CurFile.CSize;
    if (CurDir + '\' = Files^.LastDir) and (AllFiles or InFilter(Files^.CurFile.Name, FileMask)) then
      begin
        if Files^.CurFile.Name = '' then Continue;
        with Files^.CurFile do
        F := NewFileRec(Name, _USize, Date, Attr, @CurDir);
        F^.PSize := _PSize;
        TTL := TTL + _USize;
        TPL := TPL + _PSize;
      end else if (CurDir+'\' = Copy(Files^.LastDir, 1, Length(CurDir)+1)) then
              begin
                Dr := Copy(Files^.LastDir, Length(CurDir)+2, 255);
                I := PosChar('\', Dr); if I = 0 then I := Length(Dr)+1;
                Dr[0] := Char(I-1); UpStr(Dr);
                if Dr = '' then Continue;
                FillChar(FR, SizeOf(FR), 0);
                FR.Name := Norm12(Dr); FR.Name[9] := ' '; FR.Attr := Directory;
                I := FD^.IndexOf(@FR);
                if I >= 0 then
                 with PFileRec(FD^.At(I))^ do
                  begin
                    Inc(Size, _USize);
                    Inc(PSize, _PSize);
                    TTL := TTL + _USize;
                    TPL := TPL + _PSize;
                    Continue;
                  end;
                F := NewFileRec(Dr, _USize, ArcDate, $80 or Directory, @CurDir);
                F^.PSize := _PSize;
                TTL := TTL + _USize;
                TPL := TPL + _PSize;
                FD^.Insert(F);
              end else Continue;
      AFiles^.Insert(F);
  end;
 if MaxAvail <= LowMemSize then
 begin
   Application^.OutOfMemory;
 end;
 FF := AFiles;
 FreeSpace := '';
 TotalInfo := CalcTotalInfo(AFiles^.Count, AFiles^.Count, TTL);

 if CurDir = '' then OW := @ArcName else OW := @CurDir;
 if TTL > MaxLongInt then F := NewFileRec('..',0, ArcDate, Directory, OW) else
 begin
   F := NewFileRec('..',Round(TTL), ArcDate, Directory, OW);
   F^.Attr := $80 or F^.Attr;
 end;
 if TPL < MaxLongInt then F^.PSize := Round(TPL);
 FF^.AtInsert(0, F);
 FD^.DeleteAll; Dispose(FD, Done);
 GetDirectory := FF;
end;

procedure TArcDrive.UseFile;
 var SS, S: String;
     C: Char;
     ExecOK: Boolean;
begin
   if (Command = cmEditFile) or (Command = cmFileEdit) or
      (Command = cmIntEditFile) or (Command = cmIntFileEdit) then Exit;
   case Command of
    cmDBFView: C := '=';
    cmWKZView: C := '>';
    cmTextView: C := '<';
    cmHexView: C := '|';
    cmIntFileView: C := '-';
    else C := '+';
   end;
   {if not CheckPassword(AF) then Exit;}
   S := ' ';
   if P^.Attr and Hidden <> 0 then
    begin
     S := '';
     if ExecResource( dlgSetPassword, S ) <> cmOK then Exit;
     S := ' ' + DelSpaces(CnvString(AType^.Garble) + S) + ' ';
    end;
   SS := MakeNormName(P^.Owner^, MakeFileName(P^.Name));
   if SS[1] = '\' then DelFC(SS);
   S := CnvString(AType^.Extract)+' '+s+ArcName+' '+SS+' ';
   DelDoubles('  ',S);
   SS := MakeFileName(P^.Name);
   TempFile := C + MakeNormName(TempDir , SS);
   System.GetDir(0, DirToChange);
   Advance.ChDir(TempDir);
   ExecOK := Exec(CnvString(AType^.unPacker),s);
   Advance.ChDir(DirToChange); DirToChange := '';
   if ExecOK then
   begin
     TempFile := MakeNormName(TempDir, SS);
     While TempFile[Length(TempFile)] = ' ' do Dec(TempFile[0]);
     Message(Application, evCommand, Command, @TempFile);
   end;
end;

function TArcDrive.Exec;
 var S: String;
     SM: Word;
     DE: Word;

procedure StdMsg8;
var
  L: array[0..1] of LongInt;
begin
  Application^.Redraw;
  Pointer(L[0]) := @S; L[1] := DE;
  Msg(dlArcMsg8, @L, mfOkButton or mfError);
end;

begin
  Exec := True;
  S := Prg+' '+Cmd;
  if AType^.Swap then
  begin
    Exec := Message(Application, evCommand, cmExecString, @S) = nil;
    Exit;
  end;
  DoneSysError;
  DoneEvents;
  DoneVideo;
  FreeMem(UserScreen, UserScreenSize);
  UserScreen := nil;
  ScreenSaved := Off;
  DoneDOSMem;
  DoneMemory;
  asm cld; mov ax,3; int $10; end;
  S := GetEnv('PATH');
  S := FSearch(Prg,S);
  SwapVectors;
  DOS.Exec(S,Cmd); DE := DosError; ClrIO;
  SwapVectors;
  EraseFile(SwpDir+'$$$DN$$$.LST');
  InitDOSMem;
  InitMemory;
  SetVideoMode(ScreenMode); SM := ScreenMode;
  SetBlink(On);
  InitVideo; ScreenMode := SM;
  InitEvents;
  InitSysError;
  case DE of
     0 : Application^.Redraw;
     8 : StdMsg(1);
    else StdMsg8;
  end;
  GlobalMessage(evCommand, cmPanelReread, nil);
  GlobalMessage(evCommand, cmRereadInfo, nil);
end;

function TArcDrive.isUp;
begin
 isUp := {CurDir = ''}True;
end;

procedure TArcDrive.ChangeUp;
begin
  if CurDir <> '' then
   begin
     S := GetName(CurDir);
     ChDir('..');
     Exit
   end;
  if Owner = nil then Exit;
  if Prev = nil then
   begin
     New(Prev, Init(0, Owner, Flags));
     if Prev = nil then Exit;
     {Prev^.Owner := Owner;}
   end;
  PFilePanel(Owner)^.Drive := Prev;
  Prev^.ChDir(Prev^.CurDir);
  if (Prev^.DriveType = dtDisk) and
     (PView(Owner)^.GetState(sfSelected+sfActive)) then
      ActivePanel := Owner;
  GlobalMessage(evCommand, cmRereadInfo, nil);
  Prev := nil;
  S := GetName(ArcName);
  if KillAfterUse then EraseFile(ArcName);
  Dispose(PDrive(@Self), Done);
end;

procedure TArcDrive.ChangeRoot;
begin
 CurDir := '';
end;

function TArcDrive.MakeListFile;
 var F: Text;
     PF: PFileRec;
     PA: PArcFile;
     I: Integer;
     S, S1: String[120];
     B: Boolean;

  procedure PutDir(SS: String);
   var I: Integer;
       S1: String[120];
  begin
   if SS[Length(SS)] <> '\' then AddStr(SS, '\'); UpStr(SS);
   Files^.ResetPointer('');
   while not Files^.Last and Files^.GetNextFile do
     if (SS = Copy(Files^.LastDir, 1, Length(SS))) and (Files^.CurFile.Name <> '') then
      begin
        S1 := Files^.LastDir + Files^.CurFile.Name; if S1[1] = '\' then DelFC(S1);
        if B then S := S + ' ' + S1 else WriteLn(F, S1);
      end;
  end;

begin
 B := AType^.ListChar = ' ';
 if B then S := '' else
  begin
   S := SwpDir + '$$$DN$$$.LST';
   Assign(F, S); ClrIO;
   Rewrite(F);
   B := IOResult <> 0;
   if B then S := '' else S := AType^.ListChar + S;
  end;
 for I := 0 to PC^.Count - 1 do
  begin
   PF := PC^.At(I);
   S1 := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));
   if S1[1] = '\' then DelFC(S1);
   if PF^.Attr and Directory = 0
      then if B then S := S + ' ' + S1 else WriteLn(F, S1)
      else PutDir('\'+S1+'\');
   MakeListFile := S;
   if S[0] > #100 then Exit;
  end;
 MakeListFile := S;
 if not B then Close(F);
end;

procedure TArcDrive.ExtractFiles;
 var SS, S: String[128];
     DT: Record S: String[70]; W: Word; Psw: String[30]; end;
     ExtrChar: String[20];
     Nm: NameStr;
     Xt: ExtStr;
     Pswd: Boolean;

 procedure UnSelect(P: PFileRec); far;
 begin
  Message(Owner, evCommand, cmCopyUnselect, P);
  Pswd := Pswd or (P^.Attr and Hidden <> 0);
 end;

begin
  While ExtrDir[Length(ExtrDir)] = ' ' do Dec(ExtrDir[0]);
  if (ExtrDir = '') or (ExtrDir = '..') then FSplit(ArcName, ExtrDir, Nm, Xt);
  if ExtrDir[Length(ExtrDir)] <> '\' then ExtrDir := ExtrDir + '\';

  SS := MakeListFile(AFiles);
  S := ' '; Pswd := Off;
  AFiles^.ForEach(@Unselect);
  ExtrChar := CnvString(AType^.ExtractWP);
  if Options and 1 = 0 then ExtrChar := CnvString(AType^.Extract);
  if Options and 2 <> 0 then ExtrChar := CnvString(AType^.Test);
  if (Password = '') and Pswd then
    if ExecResource(dlgSetPassword, Password) <> cmOK then Exit;
  if Password <> '' then S := ' ' + DelSpaces(CnvString(AType^.Garble) + Password) + ' ';
  S := ExtrChar+' '+s+ArcName+' '+SS+' ';
  System.GetDir(0, DirToChange);
  CreateDirInheritance(ExtrDir, On);
  Advance.ChDir(ExtrDir);
  DelDoubles('  ', S);
  Exec(CnvString(AType^.unPacker),s);
  Advance.ChDir(DirToChange); DirToChange := '';
end;

procedure TArcDrive.CopyFiles;
 var SS, S: String[128];
     DT: Record S: String[70]; W: Word; Psw: String[30]; end;
     ExtrDir: PathStr;
     ExtrChar: String[20];
     Nm: NameStr;
     Xt: ExtStr;
begin
  S := ' ';
  ExtrDir := '';
  DT.S := '';
  DT.Psw := Password;
  DT.W := 1;
  Message(Application, evCommand, cmPushFirstName, @DT.S);
  if CopyDirName <> '' then DT.S := CopyDirName;
  if DT.S = cTEMP_ then DT.S := '';
  if DT.S = '' then GlobalMessage(evCommand, cmPushName, Pointer(hsExtract));
  if DT.S = '' then DT.S := HistoryStr(hsExtract, 0);
  if DT.S = cTEMP_ then DT.S := '';
  CopyDirName := '';
  if not SkipCopyDialog then
     if ExecResource( dlgExtract, DT) <> cmOK then Exit;
  SkipCopyDialog := Off;
  ExtrDir := DT.S;
  Password := DT.Psw;
  ExtractFiles(AFiles, ExtrDir, Own, DT.W);
end;

procedure TArcDrive.MakeDir;
begin
end;

procedure TArcDrive.EraseFiles;
 var SS, S: String[128];
     PF: PFileRec;
     J, I: Word;
     O: PView;
     P: PString;
begin
  if AFiles^.Count = 0 then Exit;
  if AFiles^.Count = 1 then
   begin PF := AFiles^.At(0);
         S := GetString(dlEraseConfirm1) + MakeFileName(PF^.Name) + ' ?'; end
  else S := GetString(dlEraseConfirms1);
  I := MessageBox(S,nil,mfConfirmation+mfYesButton+mfNoButton{+mfFastButton});
  if (I <> cmYes) then Exit;
  if AFiles^.Count > 1 then
   begin
    S := GetString(dlEraseConfirm2)+ItoS(AFiles^.Count)+' '+GetString(dlDIFiles)+ ' ?';
    J := MessageBox(S,nil,mfConfirmation+mfYesButton+mfNoButton);
    if (J <> cmYes) then Exit;
   end;
  SS := MakeListFile(AFiles);
  S := CnvString(AType^.Delete)+' '+ArcName+' '+SS;
  ForceRescan := True;
  Exec(CnvString(AType^.Packer),s);
  ForceRescan := Off;
  O := Owner;
  if not ReadArchive then
    begin
      CurDir := '';
      S := Cut(ArcName, 40);
      MessageBox(GetString(dlArcMsg4) + S, nil, mfError + mfOKButton);
      ChangeUp(CurDir);
      PFilePanel(O)^.ReadDirectory;
    end else
      PFilePanel(O)^.RereadDir;
end;

function TArcDrive.CalcLength;
begin
 CalcLength := 13 +
               (10 + CountryInfo.TimeFmt) * Byte(AFlags and psShowSize <> 0) +
               11 * Byte(AFlags and psShowPacked <> 0) +
                9 * Byte(AFlags and psShowDate <> 0) +
               (7 - CountryInfo.TimeFmt) * Byte(AFlags and psShowTime <> 0) +
                4 * Byte(AFlags and psShowRatio <> 0);
end;

procedure TArcDrive.MakeTop;
begin
 S := GetString(dlTopName);
 if Flags and psShowSize <> 0 then S := S + Copy(GetString(dlTopOriginal),2-CountryInfo.TimeFmt,255);
 if Flags and psShowPacked <> 0 then S := S + GetString(dlTopPacked);
 if Flags and psShowRatio <> 0 then S := S + GetString(dlTopRatio);
 if Flags and psShowDate <> 0 then S := S + GetString(dlTopDate);
 if Flags and psShowTime <> 0 then S := S + Copy(' '+GetString(dlTopTime),1+CountryInfo.TimeFmt,255);
end;

procedure TArcDrive.GetFull;
var
  S,S1: String[40];
  X: Byte;
begin
  if (P^.Size > 0) or (P^.Attr and Directory = 0)
    then S := FileSizeStr( P^.Size )
    else if P^.Name[1]= '.'
      then S := GetString( dlUpDir )
      else S := GetString( dlSubDir );
  MakeDate(DateMode, P^.Day, P^.Month, P^.Yr, P^.Hour, P^.Minute, S1);
  MoveStr(TWordArray(B), P^.Name, C);
  if AFlags and psShowSize <> 0 then
   begin
    MoveStr(TWordArray(B)[22-Length(S)+CountryInfo.TimeFmt], S, C);
    X := 23+CountryInfo.TimeFmt;
   end else X := 13;
  if AFlags and psShowPacked <> 0 then
   begin
    Inc(X, 11);
    if PosChar('<',S) = 0 then S := FStr(P^.PSize);
    MoveStr(TWordArray(B)[X-Length(S)-1], S, C);
   end;
  if AFlags and psShowRatio <> 0 then
   begin
    Inc(X, 4);
    if PosChar('<',S) = 0 then
     begin
      if P^.Size <> 0 then S := ItoS(Percent(P^.Size, P^.PSize))
                      else S := '100';
      S := PredSpace(S, 3);
     end else S := '';
    MoveStr(TWordArray(B)[X-Length(S)-1], S, C);
   end;
  if AFlags and psShowDate <> 0 then
   begin
    MoveStr(TWordArray(B)[X], Copy(S1,1,8), C);
    Inc(X, 9);
   end;
  if AFlags and psShowTime <> 0 then
   begin
    MoveStr(TWordArray(B)[X], Copy(S1,10,6), C);
    Inc(X, 7+CountryInfo.TimeFmt);
   end;
end;

procedure TArcDrive.GetEmpty;
 var
     X: Byte;
begin
  C := C and $0FFF;
  if AFlags and psShowSize <> 0 then
   begin
    TWordArray(B)[22+CountryInfo.TimeFmt] := (TWordArray(B)[23] and $F000) or C;
    X := 23+CountryInfo.TimeFmt
   end else X := 13;
  if AFlags and psShowPacked <> 0 then
   begin
    TWordArray(B)[X+10] := (TWordArray(B)[X+10] and $F000) or C;
    Inc(X, 11);
   end;
  if AFlags and psShowRatio <> 0 then
   begin
    TWordArray(B)[X+3] := (TWordArray(B)[X+3] and $F000) or C;
    Inc(X, 4);
   end;
  if AFlags and psShowDate <> 0 then
   begin
    TWordArray(B)[X+8] := (TWordArray(B)[X+8] and $F000) or C;
    Inc(X, 9);
   end;
  if AFlags and psShowTime <> 0 then
   begin
    TWordArray(B)[X+6-CountryInfo.TimeFmt] := (TWordArray(B)[X+5] and $F000) or C;
    Inc(X, 7 - CountryInfo.TimeFmt);
   end;
  TWordArray(B)[12] := (TWordArray(B)[12] and $F000) or C;
end;

{procedure TArcDrive.GetDown;
 var FR: TFileRec;
     S,S1: String[80];
begin
    FR := P^; FR.Name[9] := ' ';
    if (FR.Attr and Directory = 0) or (PFilePanel(Owner)^.PanelFlags and pfShowLength <> 0) or
       (FR.Size <> 0) then
     begin
      if (FR.Size < 0) or (FR.Size > 120000000) then S := '?'
                                                else S := FStr(FR.Size);
      if FR.Size = 0 then S1 := '100%' else S1 := ItoS((100*FR.PSize) div FR.Size) + '%';
      S := S + #26 + FStr(FR.PSize) + '(' + S1 + ')';
     end
     else if FR.Name[1]= '.' then S := GetString( dlUpDir )
                             else S := GetString( dlSubDir );
    MakeDate(DateMode, FR.Day, FR.Month, FR.Year, FR.Hour, FR.Min, S1);
    MoveStr(B, FR.Name, C);
    MoveStr(TWordArray(B)[23-Length(S)],S , C);
    MoveStr(TWordArray(B)[14],S+' '+S1, C);
end;}

function TArcDrive.GetRealName;
 var S: String;
begin
 S := GetDir;
 GetRealName := Copy(S, 1, PosChar(':', S)) + ArcName;
end;

procedure TArcDrive.CopyFilesInto;
begin
 ForceRescan := On;
 ArchiveFiles(GetRealName, AFiles, MoveMode, nil);
 ForceRescan := Off;
end;

procedure TArcDrive.HandleCommand;
 var C: PCollection absolute InfoPtr;

 procedure SetPassword;
  var S: String;
 begin
   S := Password;
   if ExecResource( dlgSetPassword, S) <> cmOK then Exit;
   Password := S;
 end;

 procedure TestFiles;
 begin
  ExtractFiles(C, '', Owner, 2);
 end;

 procedure Extract;
 begin
  ExtractFiles(C, '', Owner, 1);
 end;

 var PDr: PDrive;
     S: String;
     O: PView;

begin
 case Command of
   cmSetPassword: SetPassword;
   cmArcTest: TestFiles;
   cmExtractTo: Extract;
   cmMakeForced: ForceRescan := On;
   cmRereadForced: if ForceRescan then
                    begin
                      ForceRescan := Off;
                      if AType^.GetID = arcUC2 then
                        begin
                          PFilePanel(Owner)^.ForceReading := On;
                        end;
                      O := Owner;
                      if not ReadArchive then
                       begin
                         CurDir := '';
                         ChangeUp(CurDir);
                       end;
                       PFilePanel(O)^.RereadDir;
                    end;
 end;
end;

procedure TArcDrive.GetFreeSpace;
begin
  S := '';
end;

function ArcViewer;
 var P: PDrive;
     E: TEvent;
     Dr: DirStr;
     Nm: NameStr;
     Xt: ExtStr;
begin
 ArcViewer := False;
 P := New(PArcDrive, Init(AName));
 if Abort then Exit;
 if P = nil then
   begin
     FSplit(AName, Dr, Nm, Xt);
     if UpStrg(XT) = '.TDR' then P := New(PArvidDrive, Init(AName));
     if P = nil then Exit;
   end;
 E.What := evCommand;
 E.Command := cmInsertDrive;
 E.InfoPtr := P;
 Desktop^.HandleEvent(E);
 if E.What <> evNothing then Dispose(P, Done) else ArcViewer := True;
end;

function TArcDrive.GetFullFlags;
begin
 GetFullFlags := psShowSize + psShowDate + psShowTime + psShowPacked + psShowRatio;
end;

procedure TArcDrive.RereadDirectory;
begin
 if Prev <> nil then Prev^.RereadDirectory(S);
end;

procedure TArcDrive.GetDirInfo;
  var Fl: Integer;
      PSz, USz: LongInt;

  procedure DoCount(P: PArcFile); far;
  begin
    if (P <> nil) and (P^.FName^[Length(P^.FName^)] <> '\') then
      begin
        Inc(Fl);
        Inc(USz, P^.USize);
        Inc(PSz, P^.PSize);
      end;
  end;

begin
  B.Title := NewStr( GetString( dlDICurArchive ));
  B.Dir := NewStr(ArcName);

  Fl := Files^.Files; PSz := Files^.TotalCLength; USz := Files^.TotalLength;
  {
  if Files <> nil then Files^.ForEach(@DoCount);
  }
  B.Files := NewStr( GetString( dlDIArcTotalFiles )+ItoS(Fl)+'~');

  B.Total := NewStr( GetString( dlDIPackedSize )+FStr(PSz)+'~');
  B.Free  := NewStr( GetString( dlDIUnpackedSize )+FStr(USz)+'~');

end;

procedure TArcDrive.GetDirLength(PF: PFileRec);
begin
end;


end.

