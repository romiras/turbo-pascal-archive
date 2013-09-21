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

unit FStorage;

interface
uses Objects, Advance, DOS, FilesCol, ObjType;

type
   TStoredID = (siUndefined, siEmpty, siDirectory, siFile, siEnd);

   TStored = record
     ID: TStoredID;
     Len: Byte;
   end;

   TStoredFile = record
     T: TStored;
     Name: String[12];
     Size: LongInt;
     CSize: LongInt;
     Date: LongInt;
     Attr: Byte;
   end;

   TStoredDir = record
     T: TStored;
     Name: PathStr;
   end;

   TSwapLevel = (slNone, slXMS, slEMS, slDsk, slCnv, slFail);

   PDirStorage = ^TDirStorage;
   TDirStorage = object(TObject)
     SwapLevel: TSwapLevel;
     Files: LongInt;
     Items: LongInt;
     Stream: PStream;
     FilePtr: LongInt;
     CurFile: TStoredFile;
     Last: Boolean;
     CurDir, LastDir: PathStr;
     CurPos: LongInt;
     TotalLength, TotalCLength: LongInt;
     vSavePos, vSize: LongInt;
     constructor Init;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     destructor Done; virtual;
     procedure AddFile(const FName: String; Size, CSize, Date: LongInt; Attr: Byte);
     procedure ResetPointer(const Dir: String);
     function GetNextFile: Boolean;
     procedure UpdateRecord;
     procedure DosReread;
     procedure DeleteFile(P: PFileRec);
     procedure InitStream(X,E,M: LongInt);
     procedure Truncate(N: LongInt);
     procedure WipeCur;
     procedure vWrite(var Buf; Count: Word);
     procedure vRead(var Buf; Count: Word);
     procedure vSeek(Pos: LongInt);
     procedure vTruncate;
     procedure FixError;
     procedure TryStream(Sz: LongInt);
   end;


const
      RDirStorage: TStreamRec = (
       ObjType: otDirStorage;
       VmtLink: Ofs(TypeOf(TDirStorage)^);
       Load: @TDirStorage.Load;
       Store: @TDirStorage.Store);


implementation
uses ExtraMemory, DNApp, StartUp;

type
  PTempFile = ^TTempFile;
  TTempFile = object(TBufStream)
    FName: string;
    constructor Init;
    destructor Done; virtual;
  end;

constructor TTempFile.Init;
var
  s: string;
begin
  s := CalcTmpFName(CalcTmpId, 'SWD');
  inherited Init(s, stCreate, 4096);
  FName := s;
end;

destructor TTempFile.Done;
var
  s: string;
begin
  s := FName;
  inherited Done;
  EraseFile(s);
end;

procedure __Error;
begin
  RunError(224);
end;

procedure TDirStorage.TryStream;
begin
  repeat
    SwapLevel := Succ(SwapLevel);
    if SwapLevel = slFail then __Error;
    if Sz = -1 then InitStream(4096, 16384, 2048) else InitStream(Sz, Sz, Sz);
  until Stream <> nil;
end;

constructor TDirStorage.Init;
begin
  inherited Init;
  SwapLevel := slNone;

  TryStream(-1);

  TotalLength := 0;
  TotalCLength := 0;
  vSize := 0;
  vSavePos := 0;
end;

procedure TDirStorage.FixError;
label
  LLL;
const
  BufSize = 512;
var
  OldStream: PStream;
  SavePos, Count: LongInt;
  Buffer: array[0..BufSize-1] of Byte;
  N: Word;
begin
  OldStream := Stream; OldStream^.Status := stOK;

LLL:

  TryStream(-1);

  Count := vSize;
  OldStream^.Seek(0);
  while Count > 0 do
  begin
    if Count > BufSize then N := BufSize else N := Count;
    OldStream^.Read(Buffer, N);
    if OldStream^.Status <> stOK then __Error;
    Stream^.Write(Buffer, N);
    if Stream^.Status <> stOK then begin FreeObject(Stream); goto LLL end;
    Dec(Count, N);
  end;
  FreeObject(OldStream);
  Stream^.Seek(vSavePos);
end;


procedure TDirStorage.InitStream;
begin
  Stream := nil;
  Last := True; CurPos := -1;
  case SwapLevel of
    slXMS: if XMSFound then
           begin
             Stream := New(PXMSStream, Init(X, X));
             if Stream^.Status <> stOK then FreeObject(Stream);
           end;
    slEMS: if EMSFound then
           begin
             Stream := New(PEMSStream, Init(E, E));
             if Stream^.Status <> stOK then FreeObject(Stream);
           end;
    slCnv: begin
             Stream := New(PMemoryStream, Init(M, 2048));
             if Stream^.Status <> stOK then FreeObject(Stream);
           end;
    slDsk: begin
             Stream := New(PTempFile, Init);
             if Stream^.Status <> stOK then FreeObject(Stream);
           end;
  end;
end;

destructor TDirStorage.Done;
begin
  if Stream <> nil then Dispose(Stream, Done);
end;

procedure TDirStorage.AddFile;
  var Dr: PathStr;
      Nm: NameStr;
      Xt: ExtStr;
      SD: TStoredDir;
      SF: TStoredFile absolute SD;
      TS: TStored absolute SD;
      B: Array[0..512] of Byte;
      L: Word;
begin
  if Stream = nil then Exit;
  Stream^.Status := stOk;
  vSeek(Max(0, (vSize)-SizeOf(TStored)));
  L := 0;
  if FName <> #0 then
  begin
    FSplit(FName, Dr, Nm, Xt);
    if (CurDir <> Dr) then
      begin
        if Dr[Length(Dr)] <> '\' then AddStr(Dr, '\'); UpStr(Dr);
        CurDir := Dr;
        SD.T.ID := siDirectory;
        L := SizeOf(TStored) + 1 + Length(Dr);
        SD.Name := Dr;
        SD.T.Len := L;
        Move(SD, B, L);
        Inc(Items);
      end;
    SF.T.ID := siFile;
    SF.T.Len := SizeOf(SF);
    SF.Name := Nm+Xt;
    SF.Size := Size;
    Inc(TotalLength, Size);
    Inc(TotalCLength, CSize);
    SF.CSize := CSize;
    SF.Date := Date;
    SF.Attr := Attr;
    Move(SF, B[L], SizeOf(SF)); Inc(L, SizeOf(SF));
    Inc(Files); Inc(Items);
  end;

  TS.ID := siEnd;
  TS.Len := SizeOf(TStored);
  Move(TS, B[L], SizeOf(TStored)); Inc(L, SizeOf(TStored));

  vWrite(B, L);
  Last := True;
end;

procedure TDirStorage.ResetPointer;
begin
  if Stream = nil then Exit;
  CurPos := 0;
  FilePtr := -1; CurPos := -1;
  Last := vSize = 0;
  vSeek(0);
  FillChar(CurFile, SizeOf(CurFile), 0);
  CurDir := Dir; LastDir := '';
  if (CurDir <> '') and (CurDir[Length(CurDir)] <> '\') then AddStr(CurDir, '\');
end;

function  TDirStorage.GetNextFile;
 var SD: TStoredDir;
     SF: TStoredFile absolute SD;
     Dr: PathStr;
begin
  Dr := LastDir; GetNextFile := False;
  FillChar(CurFile, SizeOf(CurFile), 0); Last := True; CurPos := -1;
  if Stream = nil then Exit;
  while Stream^.Status = stOK do
    begin
      FilePtr := vSavePos;
      vRead(SD, SizeOf(TStored));
      if SD.T.Len > SizeOf(TStored) then vRead(SD.Name, SD.T.Len - SizeOf(TStored));
      case SD.T.ID of
        siDirectory: begin Dr := SD.Name; LastDir := Dr end;
        siEnd: Break;
        siFile: begin
                  CurPos := vSavePos - SD.T.Len;
                  if (CurDir = '') or (Dr = CurDir) then
                    begin
                      CurFile := SF;
                      Last := vSize - vSavePos <= SizeOf(TStored);
                      LastDir := Dr;
                      GetNextFile := True;
                      Break;
                    end;
                end;
      end;
    end;
end;

procedure TDirStorage.UpdateRecord;
begin
  if Stream = nil then Exit;
  if (CurPos > 0) and (CurFile.Name <> '') then
    begin
      Stream^.Status := stOK;
      vSeek(CurPos);
      vWrite(CurFile, SizeOf(CurFile));
    end;
end;

constructor TDirStorage.Load;
  var P, L: LongInt;
begin
  TObject.Init;
  S.Read(Files, SizeOf(Files));
  S.Read(TotalLength, SizeOf(TotalLength));
  S.Read(TotalCLength, SizeOf(TotalCLength));
  S.Read(L, SizeOf(L)); vSize := L;
  TryStream(L);
  P := S.GetPos;
  repeat
    Stream^.CopyFrom(S, L);
    if Stream^.Status = stOK then Break else
    begin
      FreeObject(Stream);
      TryStream(L);
      S.Seek(P);
    end;
  until False;
end;

procedure TDirStorage.Store;
  var L: LongInt;
begin
  AddFile(#0,0,0,0,0);
  S.Write(Files, SizeOf(Files));
  S.Write(TotalLength, SizeOf(TotalLength));
  S.Write(TotalCLength, SizeOf(TotalCLength));
  L := vSize;
  S.Write(L, SizeOf(L));
  vSeek(0); Stream^.Status := stOK;
  S.CopyFrom(Stream^, vSize);
end;


procedure TDirStorage.DosReread;
 var SD: TStoredDir;
     SF: TStoredFile absolute SD;
     ST: TStored absolute SD;
     Dr: PathStr;
     L, B: LongInt;
     SR: SearchRec;
begin
  Last := Off; Dr := '';
  Stream^.Status := stOK;
  vSeek(0);
  while Stream^.Status = stOK do
    begin
      L := vSavePos;
      vRead(SD, SizeOf(TStored));
      if ST.Len > SizeOf(TStored) then vRead(SD.Name, ST.Len - SizeOf(TStored));
      case ST.ID of
        siDirectory: Dr := SD.Name;
        siEnd: Break;
        siFile: begin
                  Abort := Off; DosError := 0;
                  FindFirst(Dr+SF.Name, $3F xor VolumeID, SR);
                  Dec(TotalLength, SF.Size);
                  if (DosError <> 0) or Abort then
                    begin
                      Dec(Files);
                      ST.ID := siEmpty;
                      vSeek(L);
                      vWrite(SF, ST.Len);
                    end else
                    if (SR.Size <> SF.Size) or (SR.Time <> SF.Date) or (SR.Attr <> SF.Attr) then
                    begin
                      Dec(TotalLength, SR.Size);
                      SF.Size := SR.Size;
                      SF.CSize := SR.Size;
                      SF.Date := SR.Time;
                      SF.Attr := SR.Attr;
                      vSeek(L);
                      vWrite(SF, ST.Len);
                    end;
                end;
      end;
    end;
end;


procedure TDirStorage.DeleteFile;
  var Dr: PathStr;
      Nm: String[12];
begin
   Dr := P^.Owner^; if Dr[Length(Dr)] <> '\' then AddStr(Dr, '\'); UpStr(Dr);
   ResetPointer(''); Nm := MakeFileName(P^.Name); UpStr(Nm);
   While not Last and GetNextFile do
      if (CurFile.Name = Nm) and (LastDir = Dr) then WipeCur;
end;

procedure TDirStorage.Truncate(N: LongInt);
var
  ST: TStored;
  L, NF, NI: LongInt;
begin
  ResetPointer('');
  NF := 0; NI := 0;
  while Stream^.Status = stOK do
    begin
      Inc(NI);
      L := vSavePos;
      vRead(ST, SizeOf(TStored));
      if ST.Len > SizeOf(TStored) then vSeek(L + ST.Len);
      case ST.ID of
        siEnd  : Break;
        siFile :
          begin
            Dec(N);
            if N > 0 then
            begin
              Inc(NF);
            end else
            begin
              ST.ID := siEnd;
              ST.Len := SizeOf(TStored);
              vSeek(L);
              vWrite(ST, SizeOf(TStored));
              vTruncate;
              Files := NF;
              Items := NI;
              Break;
            end
          end;
      end;
    end;
end;

procedure TDirStorage.WipeCur;
var
  L: LongInt;
begin
  L := vSavePos;
  Stream^.Status := stOK;
  vSeek(FilePtr);
  CurFile.T.Id := siEmpty;
  vWrite(CurFile, SizeOf(CurFile));
  vSeek(L);
  Dec(Files);
end;

procedure TDirStorage.vWrite;
begin
  repeat
    Stream^.Write(Buf, Count);
    if Stream^.Status = stOK
      then
        begin
          vSize := Max(vSize, vSavePos+Count); Inc(vSavePos, Count);
          Break;
        end
      else FixError;
  until False;
end;

procedure TDirStorage.vSeek;
begin
  Stream^.Seek(Pos); vSavePos := Pos;
end;

procedure TDirStorage.vTruncate;
begin
  Stream^.Truncate;
  if Stream^.Status = stOK
    then begin vSize := Stream^.GetPos; vSavePos := vSize end
    else FixError;
end;

procedure TDirStorage.vRead;
begin
  Stream^.Read(Buf, Count);
  if Stream^.Status = stOK
    then Inc(vSavePos, Count)
    else __Error;
end;

end.




