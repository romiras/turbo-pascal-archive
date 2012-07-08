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

unit DiskInfo;
interface
uses Objects, Drivers, Views, Dialogs, Dos, HideView, RStrings, Advance, ObjType;

type
     PDiskInfoRec = ^TDiskInfoRec;
     TDiskInfoRec = record
       Title: PString;
       Dir: PString;
       Files: PString;
       Free: PString;
       Total: PString;
       VolumeID: PString;
       DirInfo: PCollection;
       InfoFile: Byte;
     end;

     PDiskInfo = ^TDiskInfo;
     TDiskInfo = object(THideView)
      Dir: PathStr;
      FreeSpace, TotalSpace, DirLen: LongInt;
      FreeMemory, TotalMemory: LongInt;
      VolumeLabel: String[12];
      NumFiles: Integer;
      Info: TDiskInfoRec;
      constructor Init(R: TRect);
      constructor Load(var S: TStream);
      procedure ReadData(Loc: Boolean);
      procedure ShowView; virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      function GetPalette: PPalette; virtual;
      procedure Draw; virtual;
      destructor Done; virtual;
     end;

 function CountDirLen(Dir: PathStr; Recurse: Boolean;
                      var ClusterLen: LongInt; var NumFiles: Integer): LongInt;
 procedure GetDrInfo(Drv: Byte);
 procedure ReadDiskInfo(const Dr: String; var B: TDiskInfoRec; ShowFlags: Integer);
 function  GetVolumeLabel: string;
 function Disk_Free(Drive: Byte): TSize;

const
      RDiskInfo: TStreamRec = (
       ObjType: otDiskInfo;
       VmtLink: Ofs(TypeOf(TDiskInfo)^);
       Load: @TDiskInfo.Load;
       Store: @TDiskInfo.Store);

       CDiskInfo     = #23#24;
       ifDirInfo     = 0;
       ifFileID      = 1;
       ifDescription = 2;

       sDirinfo      = 'DirInfo';
       sFileID       = 'File_ID.DIZ';

type
     PTeamView = ^TTeamView;
     TTeamView = object(TView)
       LastTick: LongInt;
       Strings: Array [1..20] of Integer;
       constructor Init(var R: TRect);
       procedure Draw; virtual;
       procedure Update; virtual;
       destructor Done; virtual;
     end;

const TeamView: PTeamView = nil;
function GetRndBytes(B, Rnd: LongInt): LongInt;

var
   FreeSpc, TotalSpc: TSize;
   BytePerClu: LongInt;
   TotClu,
   SecPerClu,
   FreeClu,
   BytPerSec: Word;

implementation
uses Startup, ExtraMemory, DNApp, Commands, DNHelp, Tree, xTime;

const MaxTeam = 93;

function ESC_Pressed: Boolean; var E: TEvent;
begin
  Application^.Idle;
  GetKeyEvent(E); ESC_Pressed := (E.What = evKeyDown) and (E.KeyCode = kbEsc)
end;

function GetVolumeLabel;
var
  sr: SearchRec;
  VolumeLabel: string;

begin
  DOSError := 0;
  FindFirst('\*.*',VolumeID,sr);
  if DosError=0 then VolumeLabel:=sr.Name
                else VolumeLabel:=GetString(dlDINone);
  while PosChar('.',VolumeLabel) > 0 do Delete(VolumeLabel,PosChar('.',VolumeLabel),1);
  GetVolumeLabel := VolumeLabel;
end;

function GetRndBytes(B, Rnd: LongInt): LongInt;
begin
  GetRndBytes := (B div Rnd) * Rnd + Rnd * LongInt(B mod Rnd <> 0);
end;


constructor TTeamView.Init;
begin
  inherited Init(R);
  UpdTicks := 9;
  RegisterToBackground(@Self);
end;

procedure TTeamView.Draw;
  var B: TDrawBuffer;
      S: String;
      I: Integer;
      C: Word;
begin
  C := Owner^.GetColor($0807);
  MoveChar(B, ' ', C, Size.X);
  S := GetString(dlTeam000);
  MoveCStr(B[(Size.X-CStrLen(S)) div 2], S, C);
  WriteLine(0,0,Size.X,1,B);
  for I := 1 to Size.Y-1 do
    begin
      MoveChar(B, ' ', C, Size.X);
      if (Strings[I] > 0) and (Strings[I] < MaxTeam) then
        begin
          S := GetString(TStrIdx(Integer(dlTeam000)+Strings[I]));
          MoveCStr(B[(Size.X-CStrLen(S)) div 2], S, C);
        end;
      WriteLine(0,I,Size.X,1,B);
    end;
end;

procedure TTeamView.Update;
 var
     L, I: LongInt;
begin
   Move(Strings[2], Strings[1], (Size.Y-2) * SizeOf(Integer));
   if Strings[Size.Y-1] > MaxTeam - 1 then Strings[Size.Y-1] := MaxTeam * Byte(Strings[1]<MaxTeam-1)
     else Inc(Strings[Size.Y-1]);
   DrawView;
end;

destructor TTeamView.Done;
begin
  TeamView := nil;
  inherited Done;
end;


constructor TDiskInfo.Load;
begin
  TObject.Init;
  inherited Load(S);
end;

constructor TDiskInfo.Init;
begin
 TView.Init(R);
 HelpCtx := hcDiskInfo;
 EventMask := evCommand;
 Options := Options or ofSelectable or ofTopSelect;
end;

destructor TDiskInfo.Done;
begin
  DisposeStr(Info.Title);
  DisposeStr(Info.Dir);
  DisposeStr(Info.Files);
  DisposeStr(Info.Free);
  DisposeStr(Info.Total);
  DisposeStr(Info.VolumeID);
  if Info.DirInfo <> nil then Dispose(Info.DirInfo, Done);
  inherited Done;
end;

procedure TDiskInfo.ShowView;
begin
 ReadData(Off);
 inherited ShowView;
end;

function TDiskInfo.GetPalette;
 const S: String[Length(CDiskInfo)] =  CDiskInfo;
begin
 GetPalette := @S;
end;

procedure TDiskInfo.ReadData;
 var
     MemBlocks, I: Word;
begin
 Abort:=Off;
 asm
  int $12
  mov word ptr memBlocks,ax
 end;
 TotalMemory := Longint(LongInt(MemBlocks) shl 10);
 FreeMemory := TotalMemory-Longint(PrefixSeg) shl 4;
 DisposeStr(Info.Title);
 DisposeStr(Info.Dir);
 DisposeStr(Info.Files);
 DisposeStr(Info.Free);
 DisposeStr(Info.Total);
 DisposeStr(Info.VolumeID);
 if Info.DirInfo <> nil then Dispose(Info.DirInfo, Done);
 FillChar(Info, SizeOf(Info), 0);
 Message(Owner, evCommand, cmGetDirInfo, @Info);
end;

procedure TDiskInfo.HandleEvent;
var S: PathStr;

 procedure ReadInfoBBS;
   var F: PTextReader;
       I: Integer;
       Nm: String[12];
       DZ: string;


 begin
   if (Info.DirInfo = nil) then Info.DirInfo := New(PStringCollection , Init(20, 10)) else
     Info.DirInfo^.FreeAll;
   Info.InfoFile := ifDescription;
   I := -1;
   F := nil;
   DZ := FMSetup.DIZ;
   while (I<>0) and (F=nil) do
   begin
     I := Pos(';',DZ);
     if I = 0 then FreeStr := DZ else
     begin
       FreeStr := Copy(DZ, 1, I-1);
       Delete(DZ, 1, I);
     end;
     F := New(PTextReader, Init(GetPath(S)+FreeStr));
   end;
   if F = nil then Exit;
   Nm := GetName(S); UpStr(Nm);
   while (IOResult = 0) and not F^.EOF do
     begin
       FreeStr := F^.GetStr;
       if (FreeStr[1] <> ' ') then
         begin
           I := PosChar(' ', FreeStr);
           if I = 0 then Continue;
           if UpStrg(Copy(FreeStr, 1, I-1)) = Nm then
            begin
              Delete(FreeStr, 1, I);
              repeat
                DelLeft(FreeStr);
                Info.DirInfo^.AtInsert(Info.DirInfo^.Count, NewStr(FreeStr));
                FreeStr := F^.GetStr;
              until F^.EOF or (Info.DirInfo^.Count >= 100) or (FreeStr = '') or (FreeStr[1] <> ' ');
              Break;
            end;
         end;
     end;
   ClrIO; Dispose(F, Done);
 end;

begin
 inherited HandleEvent(Event);
 if (Event.What = evCommand) then
  case Event.Command of
   cmEditFile: begin
                 ClearEvent(Event);
                 case Info.InfoFile of
                   ifFileID: S := sFileID;
                   ifDirInfo: S := sDirInfo;
                     else Exit;
                 end;
                 S := MakeNormName(Dir, S);
                 Message(Application, evCommand, cmFileEdit, @S);
               end;
   cmInfoPresent: begin ClearEvent(Event); Event.InfoPtr := Owner end;
   cmRereadInfo: begin
                   ReadData(Off); DrawView; ClearEvent(Event);
                 end;
   cmLocalReread: begin
                   ReadData(On); DrawView; ClearEvent(Event);
                  end;
   cmLoadViewFile: begin
                     S := PString(Event.InfoPtr)^;
                     ReadInfoBBS; DrawView; ClearEvent(Event);
                   end;
  end;
end;

procedure TDiskInfo.Draw;
 var B: TDrawBuffer;
     C,Y,X: Word;
     S1,S2: String[20];
     CC: Boolean;

procedure Wrt(S: String);
 var I: Integer;
begin
 MoveChar(B, ' ', C, Size.X);
 I := (Size.X-CStrLen(S)) div 2;
 if (I < 0) or CC then I := 0;
 MoveCStr(B[I], S, C);
 WriteLine(0,Y,Size.X, 1, B);
 Inc(Y);
end;

  procedure XWrt(P: PString; Flag: Word);
  begin
    if (P <> nil) and (DriveInfoData and Flag <> 0) then Wrt(P^);
  end;

begin
 C := (GetColor(1) shl 8) or (GetColor(2) and 255); Y := 0; CC := Off;
 if ((Info.Title <> Info.Dir) or (Info.Title <> Info.Dir)) and
    (DriveInfoData and (fdiTitle+fdiTotals) <> 0) then
   begin
     XWrt(Info.Title, fdiTitle);
     if (Info.Dir <> nil) and (DriveInfoData and fdiTitle <> 0) then Wrt('~'+Info.Dir^+'~');
     XWrt(Info.Files, fdiTotals);
     Wrt('');
   end;
 if ((Info.Total <> Info.Free) or (Info.Total <> Info.VolumeID)) and
    (DriveInfoData and (fdiVolumeSize+fdiVolumeFree+fdiVolumeLabel) <> 0) then
   begin
     XWrt(Info.Total, fdiVolumeSize);
     XWrt(Info.Free, fdiVolumeFree);
     XWrt(Info.VolumeID, fdiVolumeLabel);
     Wrt('');
   end;
 if DriveInfoData and fdiLowMemory <> 0 then
   Wrt('~'+FStr(TotalMemory shr 10)+GetString(dlDIMemoryTotal));
 if DriveInfoData and fdiAvailLowMemory <> 0 then
   Wrt('~'+FStr(FreeMemory)+GetString(dlDIMemoryForUser));
 if DriveInfoData and fdiMemAvail <> 0 then
   Wrt('~'+FStr(MemAvail)+GetString(dlDIMemoryForDN));
 if (EMSFound or XMSFound) and (Y > 0)
   and (DriveInfoData and (fdiEMSFree+fdiXMSFree) <> 0) then Wrt('컴컴컴컴컴컴컴컴');
 if (DriveInfoData and fdiEMSFree <> 0) and EMSFound then
  begin
    Wrt('EMS: ~'+ItoS(EMSSize)+GetString(dlDIEMS1)+ItoS(EMSFreePages * 16)+GetString(dlDIEMS2));
  end;
 if (DriveInfoData and fdiXMSFree <> 0) and XMSFound then Wrt('~'+ItoS(XMSFree)+GetString(dlDIXMSFree));
 if (Y > 0) and (DriveInfoData and fdiDIZ <> 0) and
   (Info.DirInfo <> nil) and (Info.DirInfo^.Count > 0) then
   begin
     if Owner <> nil then C := Owner^.GetColor(1+Byte(Owner^.GetState(sfActive)));
     FillChar(FreeStr[1], Size.X, 196); FreeStr[0] := Char(Size.X);
     case Info.InfoFile of
       ifDirInfo: S1 := ' '+sDirInfo+' ';
       ifFileID: S1 := ' '+sFileID+' ';
         else S1 := '';
     end;
     X := (Size.X - Length(S1)) div 2; if X < 0 then X := 0;
     Move(S1[1], FreeStr[X+1], Length(S1));
     Wrt(FreeStr);
     C := (GetColor(1) shl 8) or (GetColor(2) and 255);
     CC := On;
     for X := 0 to Info.DirInfo^.Count - 1 do
       begin
         Wrt(CnvString(Info.DirInfo^.At(X)));
         if Y > Size.Y then Break;
       end;
   end;
 MoveChar(B, ' ', C, Size.X);
 if Y <= Size.Y - 1 then WriteLine(0, Y, Size.X, Size.Y - Y + 1, B);
end;

function CountDirLen;
var
  Tmr: TEventTimer;

function Count_DirLen(Dir: PathStr; Recurse: Boolean;
                      var ClusterLen: LongInt; var NumFiles: Integer): LongInt;
 var L: LongInt;
     SR: SearchRec;
begin
 if TimerExpired(Tmr) then
 begin
   NewTimer(Tmr, 3);
   if ESC_Pressed then
   begin
     Abort := True; Count_DirLen:=0; Exit
   end;
 end;

 L := 0;
 DosError := 0; Abort := Off;
 if Dir[Length(Dir)] <> '\' then Dir := Dir + '\';
 FindFirst(Dir+x_x, $3F xor VolumeID, SR);
 While (DOSError = 0) and not Abort do
 begin
  if (SR.Name[1] <> '.') then
   begin
    Inc(NumFiles);
    if SR.Attr and Directory <> 0 then
      begin
        if Recurse then
        begin
          Inc(L, Count_DirLen(Dir+SR.Name, True, ClusterLen, NumFiles));
          if Abort then Break;
        end;
          end
         else
          begin
           Inc(L, SR.Size);
           if BytePerClu > 0 then
            begin
             Inc(ClusterLen, (SR.Size div BytePerClu)*BytePerClu);
             if SR.Size mod BytePerClu <> 0 then Inc(ClusterLen, BytePerClu);
            end;
          end;
   end;
  FindNext(SR);
 end;
 Count_DirLen := L;
end;

begin
  NewTimer(Tmr, 1);
  CountDirLen := Count_DirLen(Dir, Recurse, ClusterLen, NumFiles);
  if Abort then CountDirLen := 0;
end;

procedure GetSpace(Drive : Char);assembler;
asm
  mov ax,0
  mov BytPerSec,ax
  mov SecPerClu,ax
  mov TotClu,ax
  mov FreeClu,ax
  mov ah,$36
  mov dl,Drive
  sub dl,64
  int $21
  cmp ax,$ffff
  jz  @Ex
  mov BytPerSec,cx
  mov TotClu,dx
  mov FreeClu,bx
  mov SecPerClu,ax
@ex:
end;

procedure GetDrInfo(Drv: Byte);
 var Dr : Char;
begin
 if Drv = 0 then Dr := GetCurDrive else Dr := Char(Drv+64);
 GetSpace(Dr);
 BytePerClu:=SecPerClu;BytePerClu:=BytePerClu*BytPerSec;
 FreeSpc:=BytePerClu;FreeSpc:=FreeSpc*FreeClu;
 TotalSpc:=BytePerClu;TotalSpc:=TotalSpc*TotClu;
end;

function Disk_Free(Drive: Byte): TSize;
begin
  GetDrInfo(Drive);
  Disk_Free := FreeSpc;
end;

procedure ReadDiskInfo;
 var  VolumeLabel: String[12];
      L: Byte absolute VolumeLabel;
      S: String;
      S1, S2: String[30];
      Drv: Byte;
      F: PTextReader;
      DirLen: LongInt;
      NumFiles: Integer;
begin
  ClrIO;
  if Dr = '' then GetDir(0, S)
              else S := Dr;
  if Abort then Exit;
  B.Title := NewStr(GetString(dlDICurDir)+':');
  B.Dir := NewStr(S);
  Drv := Byte(S[1])-64;

  GetDrInfo(Drv);if Abort then Exit;
  BytePerClu:=BytPerSec;BytePerClu:=BytePerClu*SecPerClu;

  DirLen := 0; NumFiles := 0;
  CountDirLen(S, False, DirLen, NumFiles);

  B.Total := NewStr('~'+FStr(TotalSpc)+GetString(dlDITotalDisk)+Copy(S,1,2)+'~');
  B.Free := NewStr('~'+FStr(FreeSpc)+GetString(dlDIFreeDisk)+Copy(S,1,2)+'~');

  if NumFiles = 0 then B.Files := NewStr(GetString(dlDINoFiles))
   else
    begin
     if NumFiles = 1 then S1 := GetString(dlDIFile) else S1 := GetString(dlDIFiles);
     if DirLen = 1 then S2 := GetString(dlDIByte) else S2 := GetString(dlDIBytes);
     B.Files := NewStr('~'+FStr(NumFiles)+'~ '+S1+GetString(dlDIWith)+'~'+FStr(DirLen)+'~ '+S2);
    end;

  B.InfoFile := ifDirInfo;
  if (ShowFlags and psShowLongDesc) <> 0 then
  begin
    B.DirInfo  := nil;
  end else
  begin
    B.DirInfo := New(PStringCollection, Init(100, 10));
    F := New(PTextReader, Init(MakeNormName(S, sDIRINFO)));
    if F = nil then
    begin
      B.InfoFile := ifFileID;
      F := New(PTextReader, Init(MakeNormName(S, sFileID)));
    end;
    if F <> nil then
    begin
      while not F^.EOF and (B.DirInfo^.Count < 100) do
        begin
          S := F^.GetStr;
          B.DirInfo^.AtInsert(B.DirInfo^.Count, NewStr(S));
        end;
      Dispose(F,Done);
    end;
  end;
  VolumeLabel := GetVolumeLabel;
  B.VolumeID := NewStr(GetString(dlDIVolumeID) + Char(Drv+64) + ': ' + VolumeLabel + '~');

end;


end.