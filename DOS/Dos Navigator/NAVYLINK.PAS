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

unit NavyLink;

{$I LINK.INC} interface uses
  Advance, Dos, Objects, Views, Drives, Drivers,
  xTime, Gauge, DiskInfo, FilesCol, ObjType;

type
    TLinkMode = (lcmUnknown, lcmLinkToLocal, lcmLocalToLink);

    PLinker = ^TLinker;
    TLinker = object(TView)
      NumErrors: Integer;
      DriveCache: LongInt;
      SlaveJob: PObject;
      constructor Init(var R: TRect);
      constructor Load(var S: TStream);
      procedure HandleEvent(var Event: TEvent); virtual;
      function Valid(C: Word): Boolean; virtual;
      procedure Draw; virtual;
      destructor Done; virtual;
      procedure Update; virtual;
    private
      Pohui: Boolean;
      RefreshWndTimer: TEventTimer;
      MainTimeOut: TEventTimer;
      Grd: PWhileView;
      _Mask: Str12;
      _Name: Str12;
      CopyOpt: Word;
      CopyMode: Word;
      CopyPrn: Boolean;
      CopyFileBuf: Pointer;
      MoveMode: Boolean;
      LinkMode: TLinkMode;
      DirLevel: Byte;
      CopyOwner: PView;
      KillEmAll: Boolean;
      procedure Initialize;
    end;

    PLinkDrive = ^TLinkDrive;
    TLinkDrive = object(TDrive)
       constructor Init(D: Char);
       procedure ChDir(ADir: PathStr); virtual;
       function GetDir: PathStr; virtual;
       function GetDirectory(SortMode, PanelFlags: Integer; const FileMask: String;
                             var FreeSpace, TotalInfo: String ): PCollection; virtual;
       procedure RereadDirectory(S: PathStr); virtual;
       procedure CopyFiles(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
                   { From Link to Local Drive }
       procedure CopyFilesInto(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
       procedure EraseFiles(AFiles: PCollection); virtual;
       function  GetRealName: String; virtual;
       procedure MakeDir; virtual;
       procedure ChangeUp(var S: String); virtual;
       procedure GetFreeSpace(var S: String); virtual;
       procedure GetDirInfo(var B: TDiskInfoRec); virtual;
       procedure UseFile(P: PFileRec; Command: Word); virtual;
    end;


const
      RLinker: TStreamRec = (
       ObjType: otLinker;
       VmtLink: Ofs(TypeOf(TLinker)^);
       Load: @TLinker.Load;
       Store: @TLinker.Store);

      RLinkDrive: TStreamRec = (
       ObjType: otLinkDrive;
       VmtLink: Ofs(TypeOf(TLinkDrive)^);
       Load: @TLinkDrive.Load;
       Store: @TLinkDrive.Store);

procedure StartLink;
procedure CopyToLinkDrive(AFiles: PCollection; AOwner: PView; const RealDest: PathStr; Mask: Str12);
             { From Local to Link Drive }
procedure CopyFromLinkDrive(AFiles: PCollection; AOwner: PView; const RealDest: PathStr);
             { From Link to Local Drive }


procedure CL_GetLinkDrives(var CSet: CharSet);

function NewLinkDrive(C: Char): PDrive;

implementation
uses  {$IFDEF CL_LOG} ComLnk, {$ENDIF}
  Dialogs,
  LinkTyp, FlPanel, Memory, ApPort,
  OOCom, ModemIO, Commands, DNApp, Messages, DnHelp, FileCopy,
  ApMisc, LinkUtil, Startup, Eraser;


function NewLinkDrive;
begin
  NewLinkDrive := New(PLinkDrive, Init(C));
end;

procedure Reread_Dir(const ADir: PathStr);
begin
  Drives.RereadDirectory(ADir);
end;

const MainTimeOutSecs = 60;

procedure InitMainTimeOut; begin NewTimerSecs(PLinker(Linker)^.MainTimeOut,MainTimeOutSecs) end;

function Ask(const Msg: String; Params: Pointer; AOptions: Word ): Word;
begin
  Ask := MessageBox(Msg, Params, AOptions);
  InitMainTimeOut;
end;


function WaitRemote: Boolean; forward;


procedure StartLink;
  var D: PDialog;
      R: TRect;
begin
  if ComPort = nil then InitModem;
  if ComPort = nil then Exit;
  if Linker <> nil then begin PLinker(Linker)^.Owner^.Select; Exit end;
  if (System.MemAvail<80*1024) or (System.MaxAvail<32*1024) then
    begin Application^.OutOfMemory; Exit; end;
  R.Assign(1,2,39,9);
  New(D, Init(R, GetString(dlLinkTitle)));
  D^.HelpCtx := hcLinkStatusWnd;

  D^.GetExtent(R); R.Grow(-1,-1);
  Linker := New(PLinker, Init(R)); D^.Insert(Linker);

  D^.Hide;
  Desktop^.InsertView(D, DeskTop^.Last);
  D^.Show;

  if WaitRemote then Msg(dlLinkStarted, nil, mfInformation+mfOKButton);

end;

procedure CreateGrd(const Title: string);
var
  R: TRect;
begin with PLinker(Linker)^ do begin
  if Grd <> nil then Exit;
  R.Assign(0,0,40,9);
  Grd := New(PWhileView, Init(R));
  PWhileView(Grd)^.Top := Title;
  Desktop^.Insert(Grd);
end end;

procedure DisposeGrd;
begin with PLinker(Linker)^ do begin
  if Grd = nil then Exit;
  Dispose(Grd, Done);
  Grd := nil;
end end;

procedure SetBottom(const S: string);
begin
  with PLinker(Linker)^.Grd^ do begin Bottom := S; DrawView end;
end;

procedure WriteGrd(N: Integer; const S: string);
begin
  PLinker(Linker)^.Grd^.Write(N, S);
end;

procedure DispatchGrd(var B: Boolean);
begin with PLinker(Linker)^ do begin
  B := False; DispatchEvents(PWhileView(Grd), B);
  B := B or CtrlBreakHit;
  CtrlBreakHit := False;
end end;

procedure TLinker.Initialize;
begin
  RegisterToPrior(@Self);
  UpdTicks := 1;
  NewTimer(RefreshWndTimer,0);
  CL_InitLink;
  Inc(SkyEnabled);
  Pohui := False;
end;

constructor TLinker.Init;
begin
  inherited Init(R);
  Options := Options or ofSelectable;
  EventMask := evCommand or evKeyDown;
  HelpCtx := hcLinkStatusWnd;
  Initialize;
end;

constructor TLinker.Load;
begin
  if ComPort = nil then InitModem;
  if ComPort = nil then Fail;
  TObject.Init;
  inherited Load(S);
  Linker := @Self;
  Initialize;
end;

destructor TLinker.Done;
begin
  Dec(SkyEnabled);
  Deregister(@Self);
  CL_DoneLink;
  Linker := nil;
  inherited Done;
end;

procedure TLinker.HandleEvent;
begin
  case Event.What of
    evCommand: if Event.Command = cmGetName then
                 begin
                   PString(Event.InfoPtr)^ := GetString(dlLinkTitle);
                   ClearEvent(Event);
                 end;
    evKeyDown: if Event.KeyCode = kbESC then
                begin
                  Event.What := evCommand;
                  Event.Command := cmClose; Event.InfoPtr := nil;
                end;
  end;
  inherited HandleEvent(Event);
end;


function TLinker.Valid;
begin
  Valid := Pohui; if Pohui then Exit;
  case C of
    cmQuit  : Pohui := (CL_Abort) or (Msg(dlLinkQueryExit, nil, mfYesNoConfirm) = cmYes);
    cmClose : Pohui := Msg(dlLinkClose, nil, mfYesNoConfirm) = cmYes;
   else begin Valid := True; Exit end;
  end;
  if Pohui then GlobalMessage(evCommand, cmCloseLinked, nil);
  Valid := Pohui;
end;

function Nice(s: string): string;
begin
  if s <> '' then while Length(s) < CL_StatusStrWdth do s := ' '+s+' ';
  Nice := s;
end;

procedure TLinker.Draw;
var
  C: Word;
  B: TDrawBuffer;
  R: TRect;
  si: TCL_StatusInfo;

procedure Wrt(Y: Byte; const S: string);
begin
  MoveChar(B, ' ', C, Size.X); MoveStr(B, Nice(S), C);
  WriteLine(0,Y,Size.X,1,B);
end;

function StatusStr: string;
begin
  if not si.ConnectOK then StatusStr := GetString(dlLinkNoRemoteLink) else
    if SlaveJob = nil then StatusStr := GetString(dlLinkWaitingCmd) else
                           StatusStr := PCL_SlaveJob(SlaveJob)^.InfoStr;
end;

begin

  with si do
  begin
    ConnectOK := not CL_Abort;
    ComPort^.GetLine(Speed, ParityType(Parity), DataBitType(DataBits), StopBitType(StopBits), False);
    ComNum := Byte(ComPort^.GetComName)+1;
    ErrStr  := GetString(dlLinkErrors);
    CL_GetLinkNfo(si);
  end;

  C := GetColor(1);
  Wrt(0, '');
  Wrt(1, si.PortStr);
  Wrt(2, StatusStr);
  Wrt(3, si.ErrStr);
  Wrt(4, '');



end;

function ESC_Pressed: Boolean;
var E: TEvent; begin GetKeyEvent(E); ESC_Pressed := (E.What = evKeyDown) and (E.KeyCode = kbEsc) end;

procedure GiveSlice; var ET: TEventTimer;
begin NewTimer(ET, 1); repeat Application^.Idle until TimerExpired(ET) end;

procedure ReportRemoteError(Code: Word);
var
  L: LongInt;
begin
  L := Code;
  Ask(GetString(dlLinkRemoteError), @L, mfError+mfOkButton);
end;

procedure __Halt;
begin
 {$IFDEF CL_LOG}CL_WLog('*** Halted ***');Close(CL_LogF);{$ENDIF}
 RunError(222);
end;

procedure UnExp;
begin
 {$IFDEF CL_LOG}CL_WLog('Unexpected condition');{$ENDIF}
  __Halt;
end;


{$IFNDEF DN}
var SlaveJob: PObject;
{$ENDIF}

procedure SlaveGetFile(const FName: string);
var
  SJ: PCL_SlaveFileJob;
begin
 {$IFDEF NLSLAVE} SlaveInfo('Get file '+FName); {$ENDIF}
 if {$IFDEF DN}PLinker(Linker)^.{$ENDIF}SlaveJob <> nil then __Halt;
 SJ := New(PCL_SlaveFileSend, Init(FName, 0));
 {$IFDEF DN}PLinker(Linker)^.{$ENDIF}SlaveJob := SJ;
end;

procedure WipeObj(var P: PCL_SlaveJob);
begin
  if P = nil then Exit;
  Dispose(P, Done);
  P := nil;
end;

function DoSlaveJob{$IFDEF DN}(var SlaveJob: PObject){$ENDIF}: Boolean;
var
  J: PCL_SlaveJob absolute SlaveJob;
begin
  if J <> nil then
  begin
    if (CL_Abort) or (not J^.Next) then WipeObj(J);
  end;
  DoSlaveJob := {True}J = nil;
end;

procedure SlaveCatchFile(const Nfo: TCL_FileNfo; const FName: string);
var
  SJ: PCL_SlaveFileJob;
begin
 {$IFDEF NLSLAVE} SlaveInfo('Catch file '+FName); {$ENDIF}
 if {$IFDEF DN}PLinker(Linker)^.{$ENDIF}SlaveJob <> nil then __Halt;
 SJ := New(PCL_SlaveFileRece, Init(Nfo, FName, 0));
 {$IFDEF DN}PLinker(Linker)^.{$ENDIF}SlaveJob := SJ;
end;

procedure ProcessInCmd;
var
  P: PCL_InCmd;
begin
  P := CL_InCmd^.At(0);
  case P^.Typ of
    ic_GetDrives   : CL_PostDriveSet;
    ic_FileNfo     : with PCL_FileNfoCmd (P)^ do SlaveCatchFile(Nfo, s);
    ic_GetFile     : with PCL_StrCmd     (P)^ do SlaveGetFile(s);
    ic_EraseFile   : with PCL_StrCmd     (P)^ do CL_EraseFile(s);
    ic_EraseDir    : with PCL_StrCmd     (P)^ do CL_EraseDir(s);
    ic_GetDir      : with PCL_DirReqCmd  (P)^ do CL_PostDirEntries(Dir, Mask, R);
    ic_GetDirNfo   : with PCL_StrCmd     (P)^ do CL_PostDirNfo(s);
    ic_GetDirValid : with PCL_StrCmd     (P)^ do CL_PostDirValid(s);
    ic_MkDir       : with PCL_StrCmd     (P)^ do CL_MakeDirectory(s);
   else UnExp;
  end;
  CL_InCmd^.AtFree(0);
end;

function CollectInData: Boolean;
begin
  CL_CollectInData;
  while DoSlaveJob{$IFDEF DN}(PLinker(Linker)^.SlaveJob){$ENDIF} and CL_CanProcInCmds do ProcessInCmd;
  CollectInData := not CL_Abort;
end;

procedure ClrGrd(const s: string);
begin
  WriteGrd(1,s);
  WriteGrd(2,'');
  WriteGrd(3,'');
  SetBottom('');
end;

function WaitRemote;
var
  C: Boolean;
  A: Boolean;
  T: TEventTimer;
begin
  A := CL_Abort;
  if A then
  begin
    A := False;
    CreateGrd(GetString(dlLinkTitle));
    ClrGrd(GetString(dlLinkRemoteWait));
    NewTimer(T, 20);
    repeat
      if CL_Abort then NewTimer(T, 20);
      GiveSlice;
      C := Off; DispatchGrd(C);
      C := C or CtrlBreakHit;
      CtrlBreakHit := Off;
      if C then begin A := True; break end;
    until (not CL_Abort) and TimerExpired(T);
    DisposeGrd;
  end;
  WaitRemote := not A;
end;

function ApplicationIdle: Boolean;
var
  C: Boolean;
begin
  GiveSlice;
  if PLinker(Linker)^.Grd = nil then C := ESC_Pressed else DispatchGrd(C);
  if C then C := Ask(GetString(dlLinkQueryExit), nil, mfYesNoConfirm) = cmYes;
  if C then
  begin
    CL_ClearAll;
    WipeObj(PCL_SlaveJob(PLinker(Linker)^.SlaveJob));
  end;
  ApplicationIdle := C;
end;

function LoopBreak: Boolean;
var
  B: Boolean;
begin
  B := TimerExpired(PLinker(Linker)^.MainTimeout) or ApplicationIdle;
  if B then CL_ClearAll;
  LoopBreak := B;
end;

function CL_Abort: Boolean;
var
  A: Boolean;
begin
  A := LinkUtil.CL_Abort;
  if A then with PLinker(Linker)^ do
  begin
    DriveCache := 0;
    WipeObj(PCL_SlaveJob(SlaveJob));
  end;
  CL_Abort := A;
end;


function GetDriveSet: LongInt;
var
  P: PCL_InDat;
  Sent: Boolean;
begin
  GetDriveSet := 0; InitMainTimeOut; Sent := False;
  repeat
    if not CollectInData then Exit;
    case Sent of
      False : if CL_OutQueueFree then
        begin
          CL_RequestRemoteDrives;
          Sent := True
        end;
      True : if CL_InData^.Count > 0 then
        begin
          P := CL_InData^.At(0);
          if P^.Typ <> id_Drives then UnExp{Exit};
          GetDriveSet := PCL_DriveData(P)^.DriveSet;
          CL_InData^.AtFree(0);
          Exit;
        end;
    end;
  until LoopBreak;
end;

function NotRoot(const Dir: string): Boolean;
begin
  NotRoot := Length(Dir)>3;
end;

type
  PCL_DirCollection =
  {$IFDEF DN}       PFilesCollection  {$ENDIF}
  {$IFDEF NLCLIENT} PStringCollection {$ENDIF};

function GetRemoteDirCycle(DP: PByteArray; N: Word
      ;Owner: PObject; SortMode: Integer; CurDir: PString;
      TotalInfo, FreeSpace: PString
 ): PCL_DirCollection;
var
  nm,xt: string;
  I: LongInt;
  D: TCL_DirEntry;
  C: PCL_DirCollection;
  TFiles: Word;
  Fs, Ts, TotalLen: TSize;
begin
  TFiles := 0;
  TotalLen := 0;
  C := New(PCL_DirCollection, Init((N div 16+1)*16, 4));

  {$IFDEF DN} C^.Owner := Owner; C^.SortMode := SortMode; {$ENDIF}

  with PCL_DirPrefix(DP)^ do
  begin
    Fs := DrvFree;
    if DrvFree <> -1 then Fs := Fs * 1024;
    Ts := TotalLen;
    Ts := Ts * 1024;
  end;

  if N > 0 then for I:=0 to N-1 do
  begin
    Move(DP^[i*CL_DirRecSz+SizeOf(TCL_DirPrefix)], D, CL_DirRecSz);
    nm := CL_UnpackStr(d.Name,8);
    xt := CL_UnpackStr(d.Ext,3);
    if d.Attr and Directory = 0 then begin Inc(TFiles); TotalLen := TotalLen+d.Size; end;
    C^.Insert(NewFileRec(nm+'.'+xt, d.Size, d.Time, d.Attr {$IFDEF DN},CurDir{$ENDIF}));
  end;

  if TotalInfo <> nil then TotalInfo^ := CalcTotalInfo(N, TFiles, Ts);

  if (FreeSpace <> nil) and (CurDir <> nil) then
  begin
    if Fs = -1 then FreeSpace^ := FmtStrId(dlLinkNoRemote,Copy(CurDir^, 1, 2))
               else FreeSpace^ := '~'+FStr(Fs)+GetString(dlDIFreeDisk)+Copy(CurDir^, 1, 2);
  end;
  GetRemoteDirCycle := C;
end;

function WaitRemoteDirData(ReqP: Pointer; ReqS: Word): PCL_PtrData;
var
      P : PCL_InDat;
   Sent : Boolean;

begin
  WaitRemoteDirData := nil; InitMainTimeOut; Sent := False;

  repeat
    if not CollectInData then Exit;
    case Sent of
      False : if CL_OutQueueFree then
        begin
          CL_RequestRemoteDir(ReqP, ReqS);
          Sent := True
        end;
      True : if CL_InData^.Count > 0 then
        begin
          P := CL_InData^.At(0);
          if P^.Typ <> id_Dir then UnExp {Exit};
          WaitRemoteDirData := PCL_PtrData(P);
          CL_InData^.AtDelete(0);
          Exit;
        end;
    end;
  until LoopBreak;

end;


function GetRemoteDir(
    Owner: PObject; SortMode: Integer;
    CurDir: Pointer;
    ReqP: Pointer;
    ReqS: Word;
    TotalInfo, FreeSpace: PString)
  :PCL_DirCollection;

procedure FreeReq; begin FreeMem(ReqP, ReqS) end;

var
  P: PCL_PtrData;
begin
  if not WaitRemote then begin FreeReq; GetRemoteDir := nil; Exit end;
  P := WaitRemoteDirData(ReqP, ReqS); FreeReq;
  if P = nil then GetRemoteDir := nil else
  begin
     GetRemoteDir := GetRemoteDirCycle(P^.DatP, (P^.DatS-SizeOf(TCL_DirPrefix)) div CL_DirRecSz,
      Owner,SortMode,CurDir,TotalInfo,FreeSpace
    );
    Dispose(P, Done);
  end;
end;

procedure RefreshGauge(var AUpdTmr, AStrtTmr: TEventTimer; ATot, ALeft: LongInt);
var
  etm, Progress: LongInt;
begin
  if not TimerExpired(AUpdTmr) then Exit;
  NewTimer(AUpdTmr,6);
  Progress := ATot-ALeft;
  WriteGrd(2, StrGrd(ATot, Progress, PLinker(Linker)^.Grd^.Size.X - 6));
  etm := ElapsedTime(AStrtTmr);
  WriteGrd(3, FStr(Progress)+GetString(dlBytesOf)+FStr(ATot));
  if (etm>50) and (Progress>0) then SetBottom('CPS: '+ItoS((Progress*18) div etm));
end;

function ReceiveFile(const RemoteName, LocalName: string): Boolean;
var
  StartRece, UpdateGauge: TEventTimer;
  Sent: Boolean;
  P: PCL_InDat;
  Nfo: TCL_FileNfo;
  Left: LongInt;
  F: File;
  BS: Word;
  BP: Pointer;

procedure CDI;
var
  S: string;
begin
  S := GetPath(LocalName);
  CreateDirInheritance(S, True);
end;

begin
  InitMainTimeOut; ReceiveFile := False; Abort := False; Sent := False;

  {$IFDEF DN}
  ClrGrd(FmtFileId(dlLinkWaitFile,LocalName));
  {$ENDIF}

  repeat
   if not CollectInData then Break;
   case Sent of
     False : if CL_OutQueueFree then
       begin
         CL_RequestFile(RemoteName);
         Sent := True
       end;
     True : if CL_InData^.Count > 0 then
       begin
         P := CL_InData^.At(0);
         case P^.Typ of
           id_FileNfo : ;
           id_IOstat  :
             begin
               ReportRemoteError(PCL_InIOstat(P)^.Stat.Error);
               CL_InData^.AtFree(0);
               Break;
             end;
          else UnExp;
         end;
         WriteGrd(1,FmtFileId(dlLinkReceivingFile, LocalName));
         Nfo := PCL_FileNfoData(P)^.Nfo;
         CL_InData^.AtFree(0);
         Left := Nfo.Size;

         CDI; if Abort then Break;
         Assign(F, LocalName); Rewrite(F, 1);

         NewTimer(StartRece,0); NewTimer(UpdateGauge,0);

         while Left > 0 do
         begin
           if not CollectInData then Break;
           RefreshGauge(UpdateGauge, StartRece, Nfo.Size, Left);
           if CL_InData^.Count > 0 then
           begin
             P := CL_InData^.At(0);
             if P^.Typ <> id_FileBlk then UnExp;
             with PCL_PtrData(P)^ do begin BP := DatP; BS := DatS end;
             BlockWrite(F, BP^, BS); InitMainTimeout;
             Dec(Left, BS);
             CL_InData^.AtFree(0);
           end else if LoopBreak then Break;
         end;
         ReceiveFile := Left = 0;
         Close(f);
{         if ReseiveFile then Set File Date}
         Break;
       end;
   end;
 until LoopBreak;
 Abort := False;
 (*

 {$IFDEF DN}MessageBox({$ELSE}WriteLn({$ENDIF}
 'Done for '+ItoS(ElapsedTimeInSecs(StartRece))+' secs'
 {$IFDEF DN},nil,mfOkButton{$ENDIF});
 *)
end;

function GetLinkDiskInfo(const ADir: string): PCL_DirNfo;
var
  P: PCL_InDat;
  Sent: Boolean;
begin
  GetLinkDiskInfo := nil;
  InitMainTimeOut; Sent := False;
  repeat
    CollectInData;
    case Sent of
      False : if CL_OutQueueFree then
        begin
          CL_RequestRemoteDirInfo(ADir);
          Sent := True
        end;
      True : if CL_InData^.Count > 0 then
        begin
          P := CL_InData^.At(0);
          if P^.Typ <> id_DirNfo then UnExp;
          GetLinkDiskInfo := PCL_PtrData(P)^.DatP;
          CL_InData^.AtDelete(0);
          Exit;
        end;
    end;
  until LoopBreak;
end;

function SendFile(const FName, DestFName: string; ABuf: Pointer): Boolean;
var
  StartSend, UpdateGauge: TEventTimer;
  P: PCL_InDat;
  Nfo: TCL_FileNfo;
  L, Left: LongInt;
  F: File;
  BS: Word;
  BP: Pointer;

function StartSending: Boolean;
var
  Sent: Boolean;
begin
  StartSending := False; Sent := False; InitMainTimeOut;
  repeat
    if not CollectInData then
    Break;
    case Sent of
      False : if CL_OutQueueFree then
        begin
          CL_PostFileNfo(Nfo, DestFName);
          Sent := True
        end;
      True : if CL_InData^.Count > 0 then
        begin
          P := CL_InData^.At(0);
          if P^.Typ <> id_IOstat then
          UnExp;
          with PCL_InIOstat(P)^.Stat do
          begin
            case Status of
              CL_stOK    : StartSending := True;
              CL_stError : ReportRemoteError(Error);
             else
             UnExp;
            end;
          end;
          CL_InData^.AtFree(0);
          Break;
        end;
    end;
  until LoopBreak;
end;

function WaitEOF: Boolean;
begin
  InitMainTimeout; WaitEOF := False;
  repeat
    if not CollectInData then Break;
    if CL_InData^.Count > 0 then
    begin
      P := CL_InData^.At(0);
      if P^.Typ <> id_IOstat then UnExp;
      with PCL_InIOstat(P)^.Stat do
      case Status of
        CL_stOK    : WaitEOF := True;
        CL_stError : ReportRemoteError(Error);
       else UnExp;
      end;
      CL_InData^.AtFree(0);
      Break;
    end;
  until LoopBreak;
end;

function AllDone: Boolean;
begin
  AllDone := False;
  if Left = 0 then
  begin
    SendFile := WaitEOF;
    AllDone := True;
  end;
end;

begin
  SendFile := False;
  ClrIO; FileMode := $40; Assign(F, FName); Reset(F, 1); if IOResult <> 0 then Exit;
  CL_FillFileNfo(F, Nfo, False); Left := Nfo.Size;
  ClrGrd(FmtFileId(dlLinkTransmitFile, FName));
  if not StartSending then Exit;
  NewTimer(StartSend, 0); NewTimer(UpdateGauge, 0); InitMainTimeOut;
  repeat
    RefreshGauge(UpdateGauge, StartSend, Nfo.Size, Left);
    if not CollectInData then Break;
    if AllDone then Break;
    if CL_FreeToFSend then
    begin
      L := Left; if L > CL_FileBuf then L := CL_FileBuf;
      BlockRead(F, ABuf^, L); InitMainTimeout;
      CL_PostFileBlock(ABuf, L);
      Dec(Left, L);
      if AllDone then Break;
    end else if LoopBreak then Break;
  until False;
  Close(F);
end;

procedure TLinker.Update;
begin
  CollectInData;
  if TimerExpired(RefreshWndTimer) then
  begin
    NewTimer(RefreshWndTimer,5);
    DrawView;
  end;
end;


procedure CL_GetLinkDrives;
begin with PLinker(Linker)^ do begin
  if not CL_Abort then
  if DriveCache = 0 then DriveCache := GetDriveSet;
  CL_UnpackDriveSet(DriveCache, CSet);
end end;

{---------------------------------- Drive -----------------------------------}



constructor TLinkDrive.Init;
begin
  TObject.Init;
  {HelpCtx := hcLinkPanel;}
  Curdir := D + ':\';
  DriveType := dtLink;
end;

procedure TLinkDrive.ChDir;
 var Dr: DirStr;
     Nm: NameStr;
     Xt: ExtStr;
begin
 if ADir = #0 then Exit;
 FSplit(ADir, Dr, Nm, Xt);
 if Xt = '..' then
  begin
   if Dr <> '' then CurDir := Dr;
   if CurDir[1] <> '\' then Insert('\', CurDir, 1);
   repeat Dec(CurDir[0]) until (CurDir = '') or (CurDir[Length(CurDir)] = '\');
   if CurDir <> '' then Dec(CurDir[0]);
  end else CurDir := ADir;
 While (CurDir[0] > #3) and (PosChar(CurDir[Length(CurDir)], ' .\') > 0) do Dec(CurDir[0]);
end;

function TLinkDrive.GetDir;
begin
 GetDir := cLINK_+CurDir;
end;

procedure CreateDirRequest(
   var P: Pointer;
   var Ofst: Word;
   const CurDir: PathStr;
   const FileMask: string;
   APanelFlags, ASortMode: Integer);

var
  S: string;
  R: TCL_DirReq;
  sl1, fl1: Byte;

procedure Mve(const Buf; Size: Word);
begin Move(Buf, PByteArray(P)^[Ofst], Size); Inc(Ofst, Size) end;

begin
  Ofst := 0;
  S := MakeNormName(CurDir, '');
  sl1 := Length(S)+1; fl1 := Length(FileMask)+1;
  GetMem(P, SizeOf(TCL_DirReq)+sl1+fl1);
  R.PanelFlags := APanelFlags;
  R.SortMode := ASortMode;
  Mve(R, SizeOf(R));
  Mve(S, sl1);
  Mve(FileMask, fl1);
end;


function TLinkDrive.GetDirectory;
var
  Ofst: Word;
  P: Pointer;

var
  PC: PFilesCollection;
begin
  FreeSpace := ''; TotalInfo := '';
  CreateDirRequest(P, Ofst, CurDir, FileMask, PanelFlags, SortMode);
  if WaitRemote then PC := GetRemoteDir(Owner, SortMode, @CurDir, P, Ofst, @TotalInfo, @FreeSpace)
                else PC := nil;
  if PC = nil then
  begin
    {PC := New(PFilesCollection, Init(0, 0));}
    FreeSpace := FmtStrId(dlLinkNoRemote, Copy(CurDir, 1, 2));
  end {else
  begin
    if NotRoot(CurDir) then PC^.AtInsert(0, NewFileRec('..',0,0,Directory,@CurDir));
  end};
  GetDirectory := PC;
end;

procedure TLinkDrive.RereadDirectory;
begin
  if Prev <> nil then Prev^.RereadDirectory(S);
end;


procedure TLinkDrive.CopyFilesInto;
begin
  {CopyToLinkDrive(AFiles,Own,CurDir,'');}
end;

function MkName(Nm: Str12; const Mask: Str12): Str12;
  var I: Integer;
begin
  for I := 1 to 12 do if Mask[I] <> '?' then Nm[I] := Mask[I];
  Nm[9] := '.';
  MkName := MakeFileName(Nm);
end;


function ValidRemoteDir(const ADir: string; var IsValid: Boolean): Boolean;
var
  P: PCL_InDat;
  Sent: Boolean;
begin
  ValidRemoteDir := False; InitMainTimeOut; Sent := False;
  repeat
    if not CollectInData then Exit;
    case Sent of
      False : if CL_OutQueueFree then
        begin
          CL_RequestValidateDir(ADir);
          Sent := True
        end;
      True : if CL_InData^.Count > 0 then
        begin
          P := CL_InData^.At(0);
          if P^.Typ <> id_IOstat then UnExp{Exit};
          with PCL_InIOstat(P)^.Stat do
          begin
            case Status of
              CL_stOK    : IsValid := True;
              CL_stError : IsValid := False;
             else UnExp;
            end;
          end;
          CL_InData^.AtFree(0);
          ValidRemoteDir := True;
          Exit;
        end;
    end;
  until LoopBreak;
end;

function ValidLocalDir(const ADir: string): Boolean;
var
  SR: SearchRec;
begin
  FindFirst(ADir, $3E xor VolumeID, SR);
  ValidLocalDir := (DOSError = 0) and (SR.Attr and Directory <> 0);
end;

function ValidDir(ADir: string; var IsValid: Boolean): Boolean;
begin
  case PLinker(Linker)^.LinkMode of
    lcmLocalToLink : ValidDir := ValidRemoteDir(ADir, IsValid);
    lcmLinkToLocal : begin IsValid := ValidLocalDir(ADir); ValidDir := True end;
   else Unexp
  end
end;

function CalcMasks(var Dest, Mask: string): Boolean;
var
  DirValid: Boolean;
begin
  CalcMasks := False;

  FreeStr := MakeNormName(Advance.FExpand(Dest), Mask);
  if (Mask = '') then Mask := x_x else
  if (PosChar('*', Mask) = 0) and (PosChar('?', Mask) = 0) then
  begin
    ClrIO;
    if FreeStr[0] = #3 then begin Dest := Dest+Mask+'\'; Mask := x_x end else
    begin
      if not ValidDir(FreeStr, DirValid) then Exit;
      if DirValid then begin Dest := Dest+Mask+'\'; Mask := x_x end
    end;
  end;

  Mask := Norm12(Mask);
  CalcMasks := True;
end;

const mfEraseConfirm = mfConfirmation + mfNoButton + mfAllButton+ mf2YesButton + mfCancelButton;

function AskReadOnly(const S: PathStr): Word;
 var I: Integer;
begin
  if Confirms and cfEraseReadonly = 0 then begin AskReadOnly := cmYes; Exit end;
  I := Ask(^C+GetString(dlFile)+' '+S+GetString(dlEraseRO), nil, mfEraseConfirm);
  if I = cmOK then begin PLinker(Linker)^.KillEmAll := True; I := cmYes end;
  AskReadOnly := I;
end;

function AskKillDir(const S: PathStr): Word;
 var I: Integer;
begin
  I := Ask(FmtFileId(dlLinkEraseDirCfm, S), nil, mfEraseConfirm);
  if I = cmOK then begin PLinker(Linker)^.KillEmAll := True; I := cmYes end;
  AskKillDir := I;
end;

function EraseRemote(const FName: PathStr; Attr: Byte): Boolean;
var
  P: PCL_InDat;
  Sent: Boolean;
begin
  EraseRemote := False;

  if not PLinker(Linker)^.KillEmAll then
  begin
    if (Attr and Directory) <> 0 then
    begin
      case AskKillDir(FName) of
          cmYes : ;
          cmNo  : begin EraseRemote := True; Exit end;
        else Exit;
      end;
    end else
    begin
      if (Attr and ReadOnly) <> 0 then
      case AskReadOnly(FName) of
          cmYes : ;
          cmNo  : begin EraseRemote := True; Exit end;
        else Exit;
      end;
    end;
  end;

  InitMainTimeOut; Sent := False;
  WriteGrd(1,FmtFileId(dlLinkErasingFile, FName));
  repeat
    if not CollectInData then Exit;
    case Sent of
      False : if CL_OutQueueFree then
        begin
          if (Attr and Directory) <> 0
            then CL_RequestEraseDir(FName)
            else CL_RequestEraseFile(FName);
          Sent := True
        end;
      True : if CL_InData^.Count > 0 then
        begin
          P := CL_InData^.At(0);
          if P^.Typ <> id_IOstat then UnExp{Exit};
          with PCL_InIOstat(P)^.Stat do
          begin
            case Status of
              CL_stOK    : EraseRemote := True;
              CL_stError : ReportRemoteError(Error);
             else UnExp;
            end;
          end;
          CL_InData^.AtFree(0);
          Exit;
        end;
    end;
  until LoopBreak;
end;

procedure TLinkDrive.EraseFiles;
var
  I: Word;
  P: PFileRec;
begin
  if not ValidErase(AFiles) then Exit;
  CreateGrd(GetString(dlLinkErase));
  PLinker(Linker)^.KillEmAll := False;
  for I := 0 to AFiles^.Count-1 do
  begin
    P := AFiles^.At(I);
    EraseRemote(MakeNormName(P^.Owner^, MakeFileName(P^.Name)), P^.Attr);
  end;
  Reread_Dir(P^.Owner^);
  DisposeGrd;
end;

function  TLinkDrive.GetRealName;
begin
  GetRealName := cLINK_+CurDir;
end;

procedure TLinkDrive.MakeDir;
var
  S: string;
begin
  if LowMemory then Exit; S := '';
  if ExecResource(dlgMkDir, S) <> cmOK then Exit;
  DelLeft(S); DelRight(S);
  if S = '' then Exit;
  CL_RequestMkDir(CurDir+';'+S);
  Reread_Dir(CurDir);
end;

procedure TLinkDrive.ChangeUp;
begin
  if CurDir[0] > #3 then
   begin
     S := GetName(CurDir);
     ChDir('..');
   end;
end;

procedure TLinkDrive.GetFreeSpace;
begin S := '' end;


procedure UnpackCL_DirNfo(A: PCL_DirNfo; var B: TDiskInfoRec; const ACurDir: string);
var
  S1, S2: string;
  DirLn: LongInt;
  NumFls: Integer;
  dTotal : TSize;
  dFree  : TSize;
  dLen   : TSize;
  Drv    : Byte;
  vol    : string[11];
begin
  Drv := Byte(ACurDir[1])-64;

  with A^ do
  begin
    dTotal := DrvTotal; dTotal := dTotal * 1024;
    dFree  := DrvFree;  dFree := dFree * 1024;
    NumFls := NumFiles;
    DirLn  := DirLen;
    vol    := CL_UnpackStr(VolNm,8)+CL_UnpackStr(VolXt,3);
  end;
  B.Title := NewStr(GetString(dlLinkRemoteDirInfo));
  B.Dir := NewStr(ACurDir);
  B.Total := NewStr('~'+FStr(dTotal)+GetString(dlDITotalDisk)+Copy(ACurDir,1,2)+'~');
  B.Free := NewStr('~'+FStr(dFree)+GetString(dlDIFreeDisk)+Copy(ACurDir,1,2)+'~');

  if NumFls = 0 then B.Files := NewStr(GetString(dlDINoFiles))
   else
    begin
     if NumFls = 1 then S1 := GetString(dlDIFile) else S1 := GetString(dlDIFiles);
     if DirLn = 1 then S2 := GetString(dlDIByte) else S2 := GetString(dlDIBytes);
     B.Files := NewStr('~'+FStr(NumFls)+'~ '+S1+GetString(dlDIWith)+'~'+FStr(DirLn)+'~ '+S2);
    end;
  B.VolumeID := NewStr(GetString(dlDIVolumeID) + Char(Drv+64) + ': ' +  vol + '~');
end;

procedure TLinkDrive.GetDirInfo;
var
  D : PCL_DirNfo;
begin
  D := GetLinkDiskInfo(CurDir);
  if D = nil then Exit;
  UnpackCL_DirNfo(D, B, CurDir);
  FreeCL_DirNfo(D);
end;



function TransferFile(P: PFileRec; const Dest, Mask: string): Boolean;
var
  FName, DestFName: PathStr;
begin
  FName     := MakeNormName(P^.Owner^, MakeFileName(P^.Name));
  DestFName := MakeNormName(Dest, MkName(Norm12(GetName(FName)), Mask));
  case PLinker(Linker)^.LinkMode of
    lcmLocalToLink : TransferFile := SendFile(FName, DestFName, PLinker(Linker)^.CopyFileBuf);
    lcmLinkToLocal : TransferFile := ReceiveFile(FName, DestFName);
   else Unexp;
  end;
end;

function InvalidateDest(const ARealDest, AMask: string): PString;
var
  Dest: PathStr;
begin
  InvalidateDest := nil;
  Dest := ARealDest;
  PLinker(Linker)^._Mask := AMask;
  if not CalcMasks(Dest, PLinker(Linker)^._Mask) then Exit;
  InvalidateDest := NewStr(Dest);
end;

function TransferCollection(Dest: PString; AFiles: PCollection): Boolean; forward;

function GetLocalDir(const ADir: string; AOwner: PString): PFilesCollection;
var
  P: PFilesCollection;
  SR: SearchRec;
begin
  P := New(PFilesCollection, Init(16,16));
  FindFirst(ADir, $3E xor VolumeID, SR);
  while DosError = 0 do
  begin
    if SR.Name[1] <> '.' then with SR, P^ do
      AtInsert(Count, NewFileRec(Name, Size, Time, Attr, AOwner));
    FindNext(SR);
  end;
  GetLocalDir := P;
end;

function NewPathMask(const APath: PathStr): PString;
begin
  NewPathMask := NewStr(MakeNormName(APath,x_x));
end;

function TransferDir(Dest: PString; const APath, AName: PathStr): Boolean;
var
  P: PFilesCollection;
  ReqP: Pointer;
  ReqMask: PString absolute ReqP;
  ReqS: Word;
begin

  case PLinker(Linker)^.LinkMode of
    lcmLocalToLink :
      begin
        ReqMask := NewPathMask(APath);
        P := GetLocalDir(ReqMask^, @APath);
        DisposeStr(ReqMask);
      end;
    lcmLinkToLocal :
      begin
        CreateDirRequest(ReqP, ReqS, APath, x_x, -1, -1);
        P := GetRemoteDir(nil, 0, @APath, ReqP, ReqS, nil, nil);
      end;
   else Unexp;
  end;

  if P = nil then TransferDir := False else
  begin
    Inc(PLinker(Linker)^.DirLevel);
    TransferDir := TransferCollection(NewStr(MakeNormName(Dest^,AName)), P);
    Dec(PLinker(Linker)^.DirLevel);
    Dispose(P, Done);
  end;
end;


function TransferCollection;
var
  C: Word;
  P: PFileRec;
begin
  TransferCollection := True;
  if Dest = nil then Exit;
  if AFiles^.Count > 0 then
  begin
    for C := 0 to AFiles^.Count-1 do
    begin
      P := AFiles^.At(C);
      if P^.Attr and Directory <> 0 then
      begin
        PLinker(Linker)^._Name := MakeFileName(P^.Name);
        if PLinker(Linker)^._Name = '..' then Continue else
        begin
          if not TransferDir(Dest, MakeNormName(P^.Owner^, PLinker(Linker)^._Name), PLinker(Linker)^._Name)
            then begin TransferCollection := False; Break end;
        end;
      end else
      begin
        if not TransferFile(P, Dest^, PLinker(Linker)^._Mask)
          then begin TransferCollection := False; Break end;
      end;
      if (PLinker(Linker)^.CopyOwner <> nil) and
         (PLinker(Linker)^.DirLevel = 0)
       then Message(PLinker(Linker)^.CopyOwner, evCommand, cmCopyUnselect, P);
    end;
  end;
  DisposeStr(Dest);
end;


procedure CopyToLinkDrive;
begin
  if AFiles^.Count = 0 then Exit;

  CreateGrd(GetString(dlLinkSend));
  GetMem(PLinker(Linker)^.CopyFileBuf, CL_FileBuf);

  PLinker(Linker)^.LinkMode := lcmLocalToLink;
  PLinker(Linker)^.DirLevel := 0;
  PLinker(Linker)^.CopyOwner := AOwner;

  TransferCollection(InvalidateDest(RealDest, Mask), AFiles);

  FreeMem(PLinker(Linker)^.CopyFileBuf, CL_FileBuf);

  Reread_Dir(RealDest);
  DisposeGrd;

end;

function ExecCopyDialog(var Dest: PathStr; AFiles: PCollection; AOwner: PView): Boolean;
begin
  with PLinker(Linker)^ do ExecCopyDialog :=
    CopyDialog(Dest, _Mask, CopyOpt, CopyMode, CopyPrn,
                     MoveMode, AFiles, 0, AOwner, On);
end;

procedure CopyFromLinkDrive;
begin
  if Pos(cLINK_,RealDest)>0 then Exit;

  if AFiles^.Count = 0 then Exit;

  CreateGrd(GetString(dlLinkRcv));

  PLinker(Linker)^.LinkMode := lcmLinkToLocal;
  PLinker(Linker)^.DirLevel := 0;
  PLinker(Linker)^.CopyOwner := AOwner;
  TransferCollection(NewStr(RealDest), AFiles);
  DisposeGrd;
end;

procedure TLinkDrive.CopyFiles;
var
  Dest, RealDest: PathStr;
begin
  if AFiles^.Count = 0 then Exit;
  if not ExecCopyDialog(Dest, AFiles, Own) then Exit;
  RealDest := Dest;
  PLinker(Linker)^._Mask := MakeFileName(PLinker(Linker)^._Mask);
  PLinker(Linker)^.LinkMode := lcmLinkToLocal;
  if not CalcMasks(Dest, PLinker(Linker)^._Mask) then Exit;
  CopyFromLinkDrive(AFiles, Own, Dest);
  Reread_Dir(RealDest);
end;

procedure TLinkDrive.UseFile;
 var
     PC: PFilesCollection;
begin
   if (Command = cmEditFile) or (Command = cmFileEdit) or
      (Command = cmIntEditFile) or (Command = cmIntFileEdit) then Exit;

   PC := New(PFilesCollection, Init(1,1));
   PC^.Insert(P);
   PLinker(Linker)^._Mask := Norm12(x_x);
   CopyFromLinkDrive(PC, nil, TempDir);
   PC^.DeleteAll;
   Dispose(PC, Done);

   TempFile := MakeNormName(TempDir, MakeFileName(P^.Name));
   Message(Application, evCommand, Command, @TempFile);
end;

end.
comlnk
nlslave
nlclient
linkutil
linktyp
comlnkio
apfossil
slave.inc
master.incc