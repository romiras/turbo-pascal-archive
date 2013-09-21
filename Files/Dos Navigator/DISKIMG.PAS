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

unit DiskImg;

interface uses FilesCol;

procedure UnpackDiskImages(AOwner: Pointer; Files: PFilesCollection);

implementation

uses Dos, Messages, Views, Commands, Objects, DnApp, Drivers,
     Advance, FileCopy, DiskTool, Gauge, xTime;


function UnpackImage(const FName, DestDir: PathStr; PInfo: PWhileView): Boolean;
var
  F: PBufStream;
  Error, Cancel       : Boolean;
  Tmr: TEventTimer;

procedure CheckCancel;
begin
  if Cancel then Exit;
  if TimerExpired(Tmr) then
  begin
    DispatchEvents(PInfo, Cancel);
    Cancel := (Cancel or CtrlBreakHit) and (MessageBox(GetString(dlQueryAbort), nil, mfYesNoConfirm) = cmYes);
    CtrlBreakHit := Off;
    NewTimer(Tmr, 1);
  end;
end;


procedure DoIt;
var
  BRec: PBootRec;
  FAT: PByteArray absolute BRec;

  Reserved    : Word;
  FatCopies   : Byte;
  SectPerClust: Byte;
  BytesPerClu : Word;
  SectPerFAT  : Word;
  SectLen     : Word;
  FirstClust  : Word;
  RootEntries : Word;
  TotalClu    : Word;
  FATSize     : LongInt;
  NumSectors  : Longint;

  VolumeLabel : string[13];
  fPos        : LongInt;

procedure fSeek(Pos: LongInt);
begin
  if fPos = Pos then Exit;
  fPos := Pos;
  F^.Seek(Pos);
end;

procedure fRead(var Buf; Count: word);
begin
  F^.Read(Buf, Count); Inc(fPos, Count);
end;

function NextFAT(N: Word): Word;
var
  D: Word;
begin
  if Error or (N<2) or (n>TotalClu+2) then begin Error := True; Exit end;
  d:=(n*3) shr 1;
  d:=FAT^[d]+FAT^[d+1] shl 8;
  if N and 1=0 then d:=d and $FFF
               else d:=d shr 4;
  NextFAT := D;
end;

function Fat2Sec(W: Word): LongInt;
begin
  Fat2Sec := LongInt(FirstClust+(W-2)*SectPerClust);
end;

procedure WriteFile(const ADir: PathStr; const ANm: Str12; Clus: Word;
     Len, Date: LongInt; Attr: Byte);
var
  B: PBufStream;
  Dir, FName: string;

procedure Try;
begin
  B := New(PBufStream, Init(FName, stCreate, $8000));
  if B^.Status <> stOK then FreeObject(B);
end;

var
  CpyBuf: PByteArray;

procedure Cpy;
var
  A: Word;
  LocErr: Boolean;
begin
  if Error or Cancel then Exit;
  LocErr := True;
  repeat
    CheckCancel;
    if Cancel then Break;
    if F^.Status <> stOK then Exit;
    fSeek(Fat2Sec(Clus)*SectLen);
    if F^.Status <> stOK then Exit;
    A := Min(Len, BytesPerClu); Dec(Len, A);
    fRead(CpyBuf^, A);  if F^.Status <> stOK then Exit;
    B^.Write(CpyBuf^, A); if B^.Status <> stOK then Exit;
    if Len = 0 then
    begin
      LocErr := False;
      Break;
    end;
    Clus := NextFAT(Clus);
  until Error;
  Error := Error or LocErr;
end;

procedure SetFData;
var
  F: file;
begin
  Assign(F, FName); FileMode := $40; Reset(F, 1);
  SetFTime(F, Date);
  Close(F);
  if Attr <> Archive then SetFAttr(F, Attr);
end;

begin
  if Error then Exit;
  Dir := FmtStr(ADir, VolumeLabel);
  FName := MakeNormName(Dir, ANm);
  PInfo^.Write(3, LowStrg(GetName(FName)));
  Try;
  if B = nil then
  begin
    CreateDirInheritance(Dir, Off);
    Try;
    if B = nil then Exit;
  end;
  GetMem(CpyBuf, BytesPerClu);
  Cpy;
  FreeMem(CpyBuf, BytesPerClu);
  FreeObject(B);
  if Error then EraseFile(FName) else SetFData;
end;


procedure ProcessDir(const Dir: PathStr; Ofst: Word);
var
  _Dir : PByteArray;
  DR   : DirRec;
  I    : Integer;
  Nm   : Str12;


begin
  fSeek(LongInt(Ofst)*SectLen);
  if (F^.Status <> stOK) then Exit;
  GetMem(_Dir,RootEntries*32);
  fRead(_Dir^,RootEntries*32);
  for I := 0 to RootEntries-1 do
  begin
    CheckCancel;
    if Error or Cancel then Break;
    Move(_Dir^[I*SizeOf(DR)], DR, SizeOf(DR));
    case DR.Name[0] of
      #$E5    : Continue;
      #0..' ' : Break;
    end;
    Nm[0] := #12;
    Nm[9] := '.';
    Move(DR.Name[0], Nm[1], 8);
    Move(DR.Name[8], Nm[10], 3);
    Nm := MakeFileName(Nm);
    if DR.Attr and VolumeID <> 0 then
    begin
      Replace(' ','_',Nm);
      VolumeLabel := Nm+'\';
      Continue;
    end;
    if DR.Attr and Directory <> 0 then
    begin
      if Nm[1]<>'.' then ProcessDir(Dir+Nm+'\', Fat2Sec(DR.Clus));
      Continue;
    end;
    WriteFile(Dir, Nm, DR.Clus, DR.Len, DR.Date, DR.Attr);
  end;
  FreeMem(_Dir,RootEntries*32);
end;

procedure ChkValid;
begin
  if Error then Exit;
  Error := True;
  case SectLen of 128, 256, 512, 1024, 2048, 4096:; else Exit end;
  case FatCopies of 1, 2:; else Exit end;
  Error := False;
end;


begin
  VolumeLabel := ''; fPos := 0;
  if F^.Status <> stOK then Exit;
  GetMem(BRec, 4096);
  fRead(BRec^, 4096);
  SectPerFAT  := BRec^.SecFAT;
  SectLen     := BRec^.ByteSec;
  FatCopies   := BRec^.FATCps;
  Reserved    := BRec^.ResSect;
  RootEntries := BRec^.RootEnt;
  SectPerClust:= BRec^.SecClu;
  if BRec^.TotalSc = 0 then NumSectors := BRec^.NumSec
                       else NumSectors := BRec^.TotalSc;
  FreeMem(BRec, 4096); BRec := nil;
  if F^.Status <> stOK then Exit;

  ChkValid; if Error then Exit;

  FATSize    := LongInt(SectPerFAT) * SectLen;

  FirstClust := (SectPerFAT * FatCopies) + Reserved
                + ((LongInt(ROOTentries) * 32) div SectLen);

  BytesPerClu := SectPerClust * SectLen;
  TotalClu := LongInt(NumSectors - FirstClust + 1) div SectPerClust;
  if FATSize > $8000 then Exit;

  fSeek(Reserved*SectLen);
  if F^.Status <> stOK then Exit;

  GetMem(FAT, FatSize);
  fRead(FAT^, FatSize);
  if F^.Status = stOK then ProcessDir(DestDir+'%s',SectPerFAT * FatCopies + Reserved);
  FreeMem(FAT, FatSize);

end;


begin
  PInfo^.Write(1, GetName(FName));
  Error := False; Cancel := False;
  NewTimer(Tmr, 0);
  F := New(PBufStream, Init(FName, stOpenRead, $8000));
  DoIt;
  Error := Error or (F^.Status <> stOK);
  FreeObject(F);
  if Error then MessageBox('Error in image file '+Cut(FName,40), nil, mfError+mfOkButton);
  UnpackImage := not (Error or Cancel);
end;

procedure RereadGlobal(const OutputDir:PathStr);
begin
 GlobalMessage(evCommand, cmPanelReread, @OutputDir);
 GlobalMessage(evCommand, cmRereadTree,  @OutputDir);
end;


procedure DoIt(AOwner: Pointer; AFiles: PFilesCollection; var ADestPath: string);
var
  I: Integer;
  PF: PFileRec;
  PInfo: PWhileView;
  R: TRect;
begin
  if ADestPath = '' then GetDir(0, ADestPath);
  ADestPath := MakeNormName(ADestPath, '');

  R.Assign(1,1,26,10);
  New(PInfo, Init(R));
  PInfo^.Top := 'Image';
  Desktop^.Insert(PInfo);

  CreateDirInheritance(ADestPath, False);
  for I := 0 to AFiles^.Count-1 do
  begin
    PF := AFiles^.At(I);
    if not UnpackImage(MakeNormName(CnvString(PF^.Owner), MakeFileName(PF^.Name)), ADestPath, PInfo) then Break;
    if AOwner <> nil then Message(AOwner, evCommand, cmCopyUnselect, PF);
  end;

  FreeObject(PInfo);
  RereadGlobal(ADestPath);
end;


procedure UnpackDiskImages;
var
  DestPath: string;
begin
  if (Files = nil) or (Files^.Count = 0) then Exit;
  DestPath := '';
  Message(Application, evCommand, cmPushFullName, @DestPath);
  if InputBox('Unpack Diskette Images', '~T~arget directory',DestPath, 78, 0)
    = cmOK then DoIt(AOwner, Files, DestPath);
  Files^.DeleteAll; FreeObject(Files);
end;

end.