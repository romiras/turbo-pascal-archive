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

unit LinkUtil;

{$A+}

{$I LINK.INC} interface uses
         {$IFDEF DN}  Advance, Messages, Dos,{$ENDIF}
         {$IFDEF OS2} ObjOS2 {$ELSE} Objects {$ENDIF},
                     LinkTyp
          ;

function  CL_UnpackStr(const AP; l: Byte): string;

{$IFDEF DN}
procedure CL_UnpackDriveSet(L: LongInt; var D: CharSet);
{$ENDIF}

procedure CL_RequestRemoteDrives;

procedure CL_RequestMkDir         (const ADir: string);
procedure CL_RequestEraseFile     (const ADir: string);
procedure CL_RequestEraseDir      (const ADir: string);
procedure CL_RequestRemoteDirInfo (const ADir: string);
procedure CL_RequestValidateDir   (const ADir: string);

procedure CL_RequestRemoteDir     (ReqP: Pointer; ReqS: Word);

procedure CL_RequestFile(const FName: string);

function  CL_CollectInData: Boolean;

function  CL_CanProcInCmds: Boolean;

procedure CL_ClearAll;

procedure CL_PostDriveSet;
procedure CL_PostDirEntries (const ADir: PathStr; const Mask: string; var Rec: TCL_DirReq);
procedure CL_PostDirNfo     (const ADir: string);
procedure CL_PostDirValid   (const ADir: string);

function CL_InitLink: Boolean;
procedure CL_DoneLink;

function CL_OutQueueFree: Boolean;

procedure FreeCL_DirNfo(var P: PCL_DirNfo);

function CL_Abort: Boolean;

procedure CL_PostFileNfo(const ANfo: TCL_FileNfo; const FName: string);
procedure CL_PostFileBlock(ABuf: Pointer; ASz: LongInt);

function CL_FillFileNfo(var AF: File; var ANfo: TCL_FileNfo; Abrt: Boolean): Word;

function CL_FreeToFSend: Boolean;

procedure CL_EraseFile(const AFile: string);
procedure CL_EraseDir(const ADir: string);

procedure CL_MakeDirectory(const ADir: string);

procedure CL_GetLinkNfo(var Nfo: TCL_StatusInfo);

type
   PCL_InCmd = ^TCL_InCmd; TCL_InCmd = object(TObject) Typ: TInCmdTyp; constructor Init(ATyp: TInCmdTyp); end;

   TCL_AbstractStrCmd = object(TCL_InCmd)
     S: string;
   end;

   PCL_StrCmd = ^TCL_StrCmd;
   TCL_StrCmd = object(TCL_AbstractStrCmd)
     constructor Init(ATyp: TInCmdTyp; AP: Pointer; l: Byte);
   end;

   PCL_FileNfoCmd  = ^TCL_FileNfoCmd;
   TCL_FileNfoCmd  = object(TCL_AbstractStrCmd)
     Nfo: TCL_FileNfo;
     constructor Init(AP: Pointer; l: Byte);
   end;

   PCL_DirReqCmd = ^TCL_DirReqCmd;
   TCL_DirReqCmd = object(TCL_InCmd)
     Dir: PathStr;
     Mask: string;
     R: TCL_DirReq;
     constructor Init(AP: Pointer; ASz: Word);
   end;

   PCL_PtrCmd = ^TCL_PtrCmd;
   TCL_PtrCmd = object(TCL_InCmd)
     CmdP : Pointer; CmdS : Word;
     constructor Init(ATyp: TInCmdTyp; AP: Pointer; ASz: Word);
     destructor Done; virtual;
   end;

   {$IFDEF CL_MASTER}

   PCL_InDat = ^TCL_InDat; TCL_InDat = object(TObject) Typ: TInDatTyp; constructor Init(ATyp: TInDatTyp); end;

   PCL_InIOstat = ^TCL_InIOstat;
   TCL_InIOstat = object(TCL_InDat)
     Stat: TCL_IOstat;
     constructor Init(AP: Pointer);
   end;

   PCL_PtrData = ^TCL_PtrData;
   TCL_PtrData = object(TCL_InDat)
     DatP : Pointer; DatS : Word;
     constructor Init(ATyp: TInDatTyp; AP: Pointer; ASz: Word);
     destructor Done; virtual;
   end;

   PCL_DriveData = ^TCL_DriveData;
   TCL_DriveData = object(TCL_InDat)
     DriveSet: LongInt;
     constructor Init(P: Pointer);
   end;

   PCL_FileNfoData = ^TCL_FileNfoData;
   TCL_FileNfoData = object(TCL_InDat)
     Nfo: TCL_FileNfo;
     constructor Init(P: Pointer);
   end;

   {$ENDIF}

   PCL_SlaveJob = ^TCL_SlaveJob;
   TCL_SlaveJob = object(TObject)
     function Next: Boolean; virtual;
     function InfoStr: string; virtual;
   end;

   PCL_SlaveFileJob = ^TCL_SlaveFileJob;
   TCL_SlaveFileJob = object(TObject)
     F: TCL_File;
     Opened: Boolean;
     procedure fReset;
     procedure fRewrite;
     procedure fClose;
     procedure fBlockRead(var Buf; Sz: Word);
     procedure fBlockWrite(var Buf; Sz: Word);
     constructor Init(const FName: string; AId: Byte);
     destructor Done; virtual;
     procedure ReportError;
   end;

   PCL_SlaveFileSend = ^TCL_SlaveFileSend;
   TCL_SlaveFileSend = object(TCL_SlaveFileJob)
     constructor Init(const FName: string; AId: Byte);
     function Next: Boolean; virtual;
     function InfoStr: string; virtual;
   end;

   PCL_SlaveFileRece = ^TCL_SlaveFileRece;
   TCL_SlaveFileRece = object(TCL_SlaveFileJob)
     constructor Init(const Nfo: TCL_FileNfo; const FName: string; AId: Byte);
     function Next: Boolean; virtual;
     function InfoStr: string; virtual;
   end;

implementation uses
                   {$IFDEF DN}
                     DiskInfo,
                     DnApp,
                     Commands,
                     Startup,
                     Drivers,
                     FileCopy,
                     Tree,
                     FilesCol,
                     Drives,
                   {$ENDIF}
                   {$IFDEF OS2}
                     DosOS2,
                   {$ENDIF}
                     ComLnk;


procedure __Halt;
begin
  RunError(223);
end;

function CL_Abort; begin CL_Abort := not CL_OK end;

function CL_FillFileNfo;
var
  sr: SearchRec;
  er: Word;
begin
  FillChar(ANfo, SizeOf(ANfo), 0); ClrIO;
  if Abrt then NeedAbort := True;
  ANfo.Size := FileSize(AF);
  er := IOResult; if er <> 0 then begin CL_FillFileNfo := er; Exit end;
  if Abrt then NeedAbort := True;
  FindFirst(FileNameOf(AF), ReadOnly+Archive+Hidden+SysFile, sr);
  if Abrt then NeedAbort := False;
  er := DosError; if er <> 0 then begin CL_FillFileNfo := er; Exit end;
  with ANfo do
  begin
    Time := sr.Time;
    Attr := sr.Attr;
  end;
  CL_FillFileNfo := 0;
end;

function TCL_SlaveJob.Next;begin end;
function TCL_SlaveJob.InfoStr;begin end;

constructor TCL_SlaveFileJob.Init;
begin inherited Init; Assign(F.Handle, FName); F.Id := AId; ClrIO end;

destructor TCL_SlaveFileJob.Done;
begin ClrIO; if Opened then fClose; ClrIO; inherited Done end;

procedure CL_PostError(AId: Byte; AErr: Word);
var
  st : TCL_IOstat;
begin
  if AErr = 0 then st.Status := CL_stOK else st.Status := CL_stError;
  st.Error := AErr;
  st.Id    := AId;
  CL_PostBlock(@st, SizeOf(st), b_IOstatus);
end;

procedure TCL_SlaveFileJob.ReportError;
begin
  CL_PostError(F.Id, F.Error);
end;

procedure TCL_SlaveFileJob.fReset;
begin
  NeedAbort := True;  Abort := False;
  ClrIO; FileMode := $40; Reset(F.Handle, 1); F.Error := IOResult; if F.Error = 0 then Opened := True;
  NeedAbort := False; Abort := False;
end;


procedure TCL_SlaveFileJob.fRewrite;
var
  S: PathStr;
begin
  NeedAbort := True;  Abort := False;
  S := GetPath(FileNameOf(F.Handle));
  CreateDirInheritance(S, False);
  if Abort then F.Error := 3 else
  begin
    ClrIO; NeedAbort := True; Rewrite(F.Handle, 1);
    F.Error := IOResult; if F.Error = 0 then Opened := True;
  end;
  NeedAbort := False; Abort := False;
end;


procedure TCL_SlaveFileJob.fClose;
begin
  NeedAbort := True;  Abort := False;
  ClrIO; if Opened then Close(F.Handle); F.Error := IOResult; Opened := False;
  NeedAbort := False; Abort := False;
end;


procedure TCL_SlaveFileJob.fBlockRead;
begin
  NeedAbort := True;  Abort := False;
  ClrIO; BlockRead(F.Handle, Buf, Sz); F.Error := IOResult;
  NeedAbort := False; Abort := False;
end;


procedure TCL_SlaveFileJob.fBlockWrite;
begin
  NeedAbort := True;  Abort := False;
  ClrIO; BlockWrite(F.Handle, Buf, Sz); F.Error := IOResult;
  NeedAbort := False; Abort := False;
end;

constructor TCL_SlaveFileSend.Init;
var
  fi: TCL_FileNfo;

procedure DoIt;
begin
  FileMode := $40;
  fReset; if F.Error <> 0 then Exit;
  F.Error := CL_FillFileNfo(F.Handle, fi, True); if F.Error <> 0 then Exit;
  F.CurPos := 0; F.TotSize := fi.Size;
end;


begin
  inherited Init(FName, AId); DoIt;
  if F.Error = 0 then CL_PostBlock(@fi, SizeOf(fi), b_dFileNfo)
                 else begin ReportError; Fail end;
end;

constructor TCL_SlaveFileRece.Init;

procedure DoIt;
begin
  fRewrite; if F.Error <> 0 then Exit;
  F.TotSize := Nfo.Size;
  F.CurPos := 0;
end;

begin
  inherited Init(FName, AId); DoIt;
  ReportError; if F.Error <> 0 then Fail;
end;

function GetSlaveInfo(const ActionIdx: string; var F: file): string;
begin
  GetSlaveInfo := FmtFile(ActionIdx, FileNameOf(F), 2 + CL_StatusStrWdth - Length(ActionIdx));
end;

function TCL_SlaveFileSend.InfoStr;
begin
  InfoStr := GetSlaveInfo(GetString(dlLinkSendingFile), F.Handle);
end;

function TCL_SlaveFileRece.InfoStr;
begin
  InfoStr := GetSlaveInfo(GetString(dlLinkReceivingFile), F.Handle);
end;

function CL_FreeToFSend: Boolean;
begin CL_FreeToFSend := CL_QueueFree(CL_NormBackOutBuf, 3) end;

function TCL_SlaveFileSend.Next;
var
  Left: Boolean;
  P: PByteArray;
  L: LongInt;
  gms: Word;
begin

  {$IFDEF CL_LOG}CL_WLog(' ~   Next');{$ENDIF}

  gms := 0;
  while CL_FreeToFSend do
  begin
    L := F.TotSize - F.CurPos;
    if L = 0 then Break;
    {$IFDEF CL_LOG}CL_WLog(' ~   BlockRead');{$ENDIF}
    if L > CL_FileBuf then L := CL_FileBuf;
    Inc(F.CurPos, L);
    if gms=0 then begin gms := L; GetMem(P, gms) end;
    fBlockRead(P^, L);
    CL_PostBlock(P, L, b_dFileBlk);
  end;
  if gms>0 then FreeMem(P, gms);
  Next := F.CurPos < F.TotSize;
end;

function TCL_SlaveFileRece.Next;
var
  P: PCL_InCmd;
  C,I,Sz: Word;
  Pt: Pointer;

function AllDone: Boolean;
begin
  AllDone := False;
  if F.CurPos = F.TotSize then
  begin
    fClose;
    Next := False;
    AllDone := True;
  end;
end;

begin
  Next := True;
  if AllDone then Exit; { Handle 0-length files }
  C := CL_InCmd^.Count; if C = 0 then Exit;
  for I := 0 to C-1 do
  begin
    P := CL_InCmd^.At(0);
    if P^.Typ <> ic_FileBlk then __Halt;
    with PCL_PtrCmd(P)^ do begin Pt := CmdP; Sz := CmdS end;
    fBlockWrite(Pt^, Sz);
    CL_InCmd^.AtFree(0);
    Inc(F.CurPos, Sz);
    if AllDone then Exit;
  end;
end;


function CL_OutQueueFree: Boolean; begin CL_OutQueueFree := CL_QueueFree(CL_MaxBackOutBuf, 5) end;

function CStr(AStr: PByteArray; sz: byte): string;
var s: string;
begin
  s[0] := char(sz);
  Move(AStr^, s[1], sz);
  CStr := s
end;

constructor TCL_InCmd.Init; begin inherited Init; Typ := ATyp end;

constructor TCL_StrCmd.Init;
begin inherited Init(ATyp); s := CStr(AP, l); FreeMem(AP,l) end;

constructor TCL_FileNfoCmd.Init;
var
  PArr: PByteArray absolute AP;
begin
  inherited Init(ic_FileNfo);
  Move(AP^, Nfo, SizeOf(Nfo));
  s := CStr(Addr(PArr^[SizeOf(Nfo)]), l-SizeOf(Nfo));
  FreeMem(AP, l);
end;

constructor TCL_DirReqCmd.Init;

var Ofst: Word;
procedure Mve(var Buf; Size: Word);
begin Move(PByteArray(AP)^[Ofst], Buf, Size); Inc(Ofst, Size) end;

begin
  inherited Init(ic_GetDir); Ofst := 0;
  Mve(R, SizeOf(R));
  Mve(Dir[0], 1); Mve(Dir[1], Byte(Dir[0]));
  Mve(Mask[0], 1); Mve(Mask[1], Byte(Mask[0]));
  FreeMem(AP, ASz);
end;


  {$IFDEF CL_MASTER}
constructor TCL_FileNfoData.Init; begin inherited Init(id_FileNfo); Move(P^, Nfo, SizeOf(Nfo)); FreeMem(P,SizeOf(Nfo)) end;

constructor TCL_InDat.Init; begin inherited Init; Typ := ATyp end;

constructor TCL_InIOstat.Init;
begin
  inherited Init(id_IOstat); Move(AP^, Stat, SizeOf(Stat)); FreeMem(AP, SizeOf(Stat))
end;

constructor TCL_PtrData.Init; begin inherited Init(ATyp); DatP := AP; DatS := ASz end;
destructor TCL_PtrData.Done; begin FreeMem(DatP, DatS); inherited Done end;

constructor TCL_DriveData.Init; begin inherited Init(id_Drives); DriveSet := LongInt(P^) end;


  {$ENDIF}

constructor TCL_PtrCmd.Init; begin inherited Init(ATyp); CmdP := AP; CmdS := ASz end;
destructor TCL_PtrCmd.Done; begin FreeMem(CmdP, CmdS); inherited Done end;

function CL_InitLink;
begin
  {$IFDEF CL_LOG}
  Assign(CL_LogF,
    {$IFDEF DN}       SourceDir+'DN_LINK.LOG'  {$ENDIF}
    {$IFDEF NLSLAVE}  'F:\BP\DN\NL_SLAVE.LOG'  {$ENDIF}
    {$IFDEF NLCLIENT} '\NL_CLIEN.LOG'  {$ENDIF}
  );
  Rewrite(CL_LogF,1);
  {$ENDIF}

  {$IFDEF HARD_LOG}Close(CL_LogF);{$ENDIF}

  CL_InitLink := CL_InitComLink(CL_MaxInBufStorage, CL_MaxBlockSize, CL_StartBlockSize);
  CL_InCmd  := New(PCollection, Init(64,64));
  CL_InData := New(PCollection, Init(64,64));
end;

procedure CL_DoneLink;
begin
  CL_DoneComLink;
  {$IFDEF CL_LOG}{$IFNDEF HARD_LOG}Close(CL_LogF);{$ENDIF}{$ENDIF}
  Dispose(CL_InCmd, Done);
  Dispose(CL_InData, Done);
end;

function CL_CollectInData;
var
  Typ : TCL_BlockType;
  Sz  : Word;
  Ptr : Pointer;

procedure InsD(P: PObject); begin {$IFDEF CL_LOG}CL_WLog('InsD');{$ENDIF}CL_InData^.Insert(P) end;
procedure InsC(P: PObject); begin {$IFDEF CL_LOG}CL_WLog('InsC');{$ENDIF}CL_InCmd^.Insert(P) end;
procedure InsStrC(T: TInCmdTyp); begin InsC(New(PCL_StrCmd, Init(T, Ptr, Sz))) end;

begin

  CL_CollectInData := False;

  repeat

    Typ := CL_InputBlock(Ptr, Sz); if Typ = b_Nothing then Break;
    case Typ of

      {$IFDEF CL_MASTER}
      b_DirNfo    : InsD(New(PCL_PtrData, Init(id_DirNfo, Ptr, Sz)));
      b_Dir       : InsD(New(PCL_PtrData, Init(id_Dir, Ptr, Sz)));
      b_Drives    : InsD(New(PCL_DriveData, Init(Ptr)));
      b_dFileNfo  : InsD(New(PCL_FileNfoData, Init(Ptr)));
      b_dFileBlk  : InsD(New(PCL_PtrData, Init(id_FileBlk, Ptr, Sz)));
      b_IOstatus  : InsD(New(PCL_InIOstat, Init(Ptr)));

      {$ENDIF}
      b_MkDir     : InsStrC(ic_MkDir);
      b_DirValid  : InsStrC(ic_GetDirValid);
      b_GetDir    : InsC(New(PCL_DirReqCmd, Init(Ptr, Sz)));
      b_GetDirNfo : InsStrC(ic_GetDirNfo);
      b_GetFile   : InsStrC(ic_GetFile);
      b_EraseFile : InsStrC(ic_EraseFile);
      b_EraseDir  : InsStrC(ic_EraseDir);
      b_GetFile   : InsStrC(ic_GetFile);
      b_cFileNfo  : InsC(New(PCL_FileNfoCmd, Init(Ptr, Sz)));
      b_cFileBlk  : InsC(New(PCL_PtrCmd, Init(ic_FileBlk, Ptr, Sz)));
      b_GetDrvs   : InsC(New(PCL_InCmd, Init(ic_GetDrives)));
      else
      begin
        {$IFDEF CL_LOG}CL_WLog('CL_CollectInData - unknown typ');{$ENDIF} __Halt;
      end;
    end

  until False;

  CL_CollectInData := True;

end;

function GetDriveSet: LongInt;
var
  C: Char;
  L: LongInt;
begin
  for C := 'A' to 'Z' do begin L := L shl 1; if ValidDrive(C) then Inc(L) end;
  GetDriveSet := L;
end;

procedure CL_PostDriveSet;
var
  L: LongInt;
begin
  {$IFDEF NLSLAVE} SlaveInfo('Post DriveSet'); {$ENDIF}
  L := GetDriveSet;
  CL_PostBlock(@L, SizeOf(L), b_Drives);
end;

procedure CL_PackStr(const S: string; var AP; l: Byte);
var
  sl: byte absolute s;
  P : TByteArray absolute AP;
begin
  FillChar(P[0], l, 0);
  Move(S[1], P[0], sl);
end;

function  CL_UnpackStr(const AP; l: Byte): string;
var
  s : string;
  sl: byte absolute s;
  c : byte;
  P : TByteArray absolute AP;
begin
  sl := 0;
  while sl<l do
  begin
    c := P[sl];
    if c=0 then Break;
    Inc(sl); s[sl] := char(c);
  end;
  CL_UnpackStr := S;
end;


procedure CL_PackFName(const AFName: string; var ANm, AXt);
var
  D : DirStr;
  N : NameStr;
  E : ExtStr;
begin
  FSplit(AFName, D, N, E); if (E<>'') and (E[1]='.') then Delete(E,1,1);
  CL_PackStr(N,ANm,8);
  CL_PackStr(E,AXt,3);
end;

procedure ChkDrvInfo(C: Byte);
begin
  NeedAbort := True;  Abort := False;
  GetDrInfo(C);
  NeedAbort := False;
  if Abort then begin TotalSpc := -1; FreeSpc := -1 end;
end;

procedure CL_PostDirEntries;
var

  I,JJ : Integer;
  CurRec: TCL_DirEntry;
  T : PByteArray;
  Pfx: TCL_DirPrefix;
  Files: PFilesCollection;

  TotalLen: TSize;
  TFiles: Word;
  pf, sm: Integer;
  FR: PFileRec;

begin
 {$IFDEF NLSLAVE} SlaveInfo('Get dir '+ADir); {$ENDIF}

  pf := Rec.PanelFlags; sm := Rec.SortMode;
  if pf = -1 then pf := 0;

  ChkDrvInfo(Byte(ADir[1])-64);

  if Abort then
  begin
    JJ := 0; Files := nil
  end else
  begin
    Files := GetFilesColl(TotalLen, TFiles, pf, @ADir, Mask, nil, sm);
    JJ := Min(Files^.Count, CL_MaxDirEntries);
  end;

  GetMem(T, JJ*CL_DirRecSz+SizeOf(TCL_DirPrefix));

  with PCL_DirPrefix(T)^ do
  begin
    if Abort then
    begin
      DrvFree  := -1;
      TotalLen := 0;
      NumFiles := 0;
    end else
    begin
      TotalLen := Round(TotalSpc/1024);
      DrvFree  := Round(FreeSpc/1024);
      NumFiles := TFiles;
    end;
  end;

  for I := 0 to JJ-1 do
  begin
    FR := Files^.At(I);
    CL_PackFName(MakeFileName(FR^.Name), CurRec.Name, CurRec.Ext);
    CurRec.Attr := FR^.Attr;
    CurRec.Time := PackedDate(FR);
    CurRec.Size := FR^.Size;
    Move(CurRec,T^[I*CL_DirRecSz+SizeOf(TCL_DirPrefix)],CL_DirRecSz);
  end;

  FreeObject(Files);

  CL_PostBlock(T,JJ*CL_DirRecSz+SizeOf(TCL_DirPrefix),b_Dir);
  FreeMem(T, JJ*CL_DirRecSz+SizeOf(TCL_DirPrefix));
  ClrIO;

end;

function CL_CanProcInCmds: Boolean;
begin
  CL_CanProcInCmds := (CL_OutQueueFree) and (CL_InCmd^.Count>0);
end;

{$IFDEF DN}
procedure CL_UnpackDriveSet;
var
  C: Char;
begin
  D := [];
  for C := 'Z' downto 'A' do begin if Odd(L) then D := D + [C]; L := L shr 1 end;
end;
{$ENDIF}

procedure ReqStr(const s: string; ATyp: TCL_BlockType);
begin CL_PostBlock(@s[1], Length(s), ATyp) end;


procedure CL_RequestRemoteDrives; begin CL_PostBlock(nil, 0, b_GetDrvs) end;

procedure CL_RequestMkDir;         begin ReqStr(ADir, b_MkDir)     end;
procedure CL_RequestEraseFile;     begin ReqStr(ADir, b_EraseFile) end;
procedure CL_RequestEraseDir;      begin ReqStr(ADir, b_EraseDir)  end;
procedure CL_RequestRemoteDirInfo; begin ReqStr(ADir, b_GetDirNfo) end;
procedure CL_RequestValidateDir;   begin ReqStr(ADir, b_DirValid) end;

procedure CL_RequestFile;          begin ReqStr(FName, b_GetFile)   end;

procedure CL_RequestRemoteDir;
begin CL_PostBlock(ReqP, ReqS, b_GetDir) end;


procedure CL_ClearAll;
begin
  CL_Clear;  CL_InCmd^.FreeAll;  CL_InData^.FreeAll;
end;


procedure ReadDirNfo(const ADir: string; var ANfo: TCL_DirNfo);
var
  Drv: Byte;
  S: string;
  DirLn: LongInt;
  NumFls: Integer;
begin
  ClrIO;
  if ADir = '' then GetDir(0, S) else S := ADir;
  Drv := Byte(S[1])-64;
  ChkDrvInfo(Drv);
  DirLn := 0; NumFls := 0;
  if not Abort then CountDirLen(S, False, DirLn, NumFls);
  with ANfo do
  begin
    FillChar(VolNm, SizeOf(VolNm), 0);
    FillChar(VolXt, SizeOf(VolXt), 0);
    if not Abort then CL_PackFName(GetVolumeLabel, VolNm, VolXt);
    DrvTotal := Round(TotalSpc/1024);
    DrvFree  := Round(FreeSpc/1024);
    DirLen   := DirLn;
    NumFiles := NumFls;
  end;
  Abort := False;
end;

function NewCL_DirNfo(AInfoSize: Word; var BlkSize: Word): PCL_DirNfo;
var
  P: PCL_DirNfo;
begin
  BlkSize := SizeOf(TCL_DirNfo)-1+AInfoSize;
  GetMem(P, BlkSize);
  P^.DifNfoSz := AInfoSize;
  NewCL_DirNfo := P;
end;

procedure FreeCL_DirNfo(var P: PCL_DirNfo);
begin
  FreeMem(P, SizeOf(TCL_DirNfo)-1+P^.DifNfoSz);
end;

procedure CL_PostDirValid;
var
  er: Word;
  SR: SearchRec;
begin
 {$IFDEF NLSLAVE} SlaveInfo('Invalidate dir '+ADir); {$ENDIF}
  NeedAbort := True;  Abort := False;
  FindFirst(ADir, $3E xor VolumeID, SR);
  er := DosError;
  if er = 0 then if SR.Attr and Directory = 0 then er := 18;
  CL_PostError(0, er);
  NeedAbort := False; Abort := False;
end;


procedure CL_PostDirNfo;
var
  P: PCL_DirNfo;
  BS: Word;
begin
 {$IFDEF NLSLAVE} SlaveInfo('Get dirinfo '+ADir); {$ENDIF}
  P := NewCL_DirNfo(0, BS); ReadDirNfo(ADir, P^);
  CL_PostBlock(P, BS, b_DirNfo);
  FreeCL_DirNfo(P);
end;

procedure CL_PostFileNfo(const ANfo: TCL_FileNfo; const FName: string);
var
  P: PByteArray;
begin
  P := CL_GetBufPtr;
  Move(ANfo, P^, SizeOf(ANfo));
  Move(FName[1], P^[SizeOf(ANfo)], Length(FName));
  CL_PostBlock(P, SizeOf(ANfo) + Length(FName), b_cFileNfo);
end;

procedure CL_PostFileBlock(ABuf: Pointer; ASz: LongInt);
begin
  CL_PostBlock(ABuf, ASz, b_cFileBlk);
end;

procedure CL_EraseFile(const AFile: string);
var
  F: file;
  err: Word;
  att: Word;
begin
 {$IFDEF NLSLAVE} SlaveInfo('Erase file '+AFile); {$ENDIF}
  NeedAbort := True;  Abort := False;
  Assign(F, AFile); ClrIO; Erase(F);
  err := IOResult; if err = 5 then
  begin
    GetFAttr(F, att); if (att and (ReadOnly+Hidden+SysFile)) <> 0 then
    begin
      SetFAttr(F, 0); if IOResult = 0 then
      begin
        Erase(F); err := IOResult;
      end;
    end;
  end;
  CL_PostError(0, err);
  NeedAbort := False; Abort := False;
end;

type
  PSearchRec = ^SearchRec;

function EraseLocalFile(const AName: string; Attr: Byte; var Err: Word): Boolean;
var
  F: file;
begin
  EraseLocalFile := False;
  Assign(F, AName);
  if (Attr and (ReadOnly+Hidden+SysFile)) <> 0 then
  begin
    NeedAbort := True; SetFAttr(F, 0);
    Err := IOResult; if Err <> 0 then Exit;
  end;
  NeedAbort := True; Erase(F);
  Err := IOResult; if Err <> 0 then Exit;
  EraseLocalFile := True;
end;

function EraseEmptyDir(const ADir: string; var Err: Word): Boolean;
begin
  NeedAbort := True; RmDir(ADir); Err := IOResult; EraseEmptyDir := Err = 0;
end;

function EraseLocalDir(ADir: string; var Err: Word): Boolean;
var
  SR: PSearchRec;
  Att: Byte;
  ok: Boolean;
begin
  if Length(ADir) > 68 then Exit;
  New(SR); ok := True;
  NeedAbort := True; FindFirst(MakeNormName(ADir, '*.*'), $3E xor VolumeID, SR^);
  while DosError = 0 do
  begin
    with SR^ do begin FreeStr := Name; Att := Attr end;
    if FreeStr[1] <> '.' then
    begin
      FreeStr := MakeNormName(ADir, FreeStr);
      if Att and Directory <> 0
       then ok := EraseLocalDir(FreeStr, Err)
       else ok := EraseLocalFile(FreeStr, Att, Err);

      if not ok then Break;
    end;
    NeedAbort := True; FindNext(SR^);
  end;
  Dispose(SR);
  if ok then
  begin
    Err := DosError; if Err = 18 then Err := 0;
    ok := (Err = 0);
    if ok then ok := EraseEmptyDir(ADir, Err);
  end;
  EraseLocalDir := ok;
end;

procedure CL_EraseDir(const ADir: string);
var
  Err: Word;
begin
 {$IFDEF NLSLAVE} SlaveInfo('Erase dir '+ADir); {$ENDIF}
  Abort := False; ClrIO;
  EraseLocalDir(ADir, Err); CL_PostError(0, Err);
  NeedAbort := False; Abort := False;
end;

procedure CL_MakeDirectory(const ADir: string);
 var SafeDir, S, S1: String;
     Dr: PathStr;
     Nm: NameStr;
     Xt: ExtStr;
     B: Byte;
     I: Integer;
     NdSet: Boolean;
begin
 {$IFDEF NLSLAVE} SlaveInfo('Make dir '+ADir); {$ENDIF}

 NeedAbort := True; Abort := False; CreatedDir := ''; NdSet := False;
 S := ADir;

 while S <> '' do
  begin
    I := Pos(';', S);
    if I = 0 then I := Length(S)+1;
    S1 := Copy(S, 1, I-1); Delete(S, 1, I);
    if S1 = '' then Continue;
    if not NdSet then
    begin
      GetDir(0, SafeDir);
      ChDir(S1);
      NdSet := True;
      Continue;
    end;
    B := CreateDirInheritance(S1, False);
    if Abort or (IOResult <> 0) then Break;
  end;
  NeedAbort := False; Abort := False;
  if NdSet then ChDir(SafeDir);
end;

procedure CL_GetLinkNfo;
var
  errs, BlkSz: Word;
  trs: LongInt;
  L: array[0..10] of LongInt;
  S: string;

procedure CutS; var  SL: Byte absolute S;
begin if SL>CL_StatusStrWdth then SL := CL_StatusStrWdth end;

begin
 CL_FillNfo(Errs, BlkSz, trs);
 with Nfo do begin
  if ConnectOK then FreeStr := '/SREJ2.'+ItoS(BlkSz) else FreeStr := '';
  S := 'COM'+ItoS(ComNum)+' '+ ItoS(Speed)+'/'+
    Char(DataBits+Ord('0'))+N_O_E_M_S[Parity+1]+Char(StopBits+Ord('0'))+FreeStr;
  CutS; PortStr := S;
  FreeStr := FStr(trs div 1024); L[0] := errs; Pointer(L[1]) := @FreeStr;
  FormatStr(S, ErrStr, L);
  CutS; ErrStr := S;
 end
end;

end.
master
slave
linktyp
comlnk
nlslave
comlnkio
nlclient
slave.incc