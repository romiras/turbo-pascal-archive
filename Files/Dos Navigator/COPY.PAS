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

uses Objects, ExtraMemory, Advance, Dos, Memory;


const
      eoStart  = 1;
      eoEnd    = 2;
      eoAppend = 4;

  MemStream: PMemoryStream = nil;
  EMSStream: PEMSStream = nil;
  XMSStream: PXMSStream = nil;


type
  PLine = ^TLine;
  TLine = object(TObject)
    Owner: Pointer;
    OldName: Pointer;
    NewName: PString;
    Size, Pos, Date: LongInt;
    Len: Word;
    EOF: Byte;
    Attr: Byte;
    constructor Init(var ALen: LongInt; AOwner: Pointer; const AOldName, ANewName: String;
                      ASize, ADate: LongInt; AAttr: Byte; AEOF: ShortInt);
    procedure PrepareToWrite; virtual;
    function Stream: PStream; virtual;
    procedure Write(var B);
    procedure Read(var B);
    destructor Done; virtual;
  end;

  PEMSLine = ^TEMSLine;
  TEMSLine = object(TLine)
    procedure PrepareToWrite; virtual;
    function Stream: PStream; virtual;
  end;

  PXMSLine = ^TXMSLine;
  TXMSLine = object(TLine)
    procedure PrepareToWrite; virtual;
    function Stream: PStream; virtual;
  end;

{ TLine }

constructor TLine.Init;
begin
  inherited Init;
  {if MaxAvail < 8192 then Fail;}
  Len := ALen; EOF := AEOF; Attr := AAttr; Date := ADate;
  if Len <> 0 then
    begin
      PrepareToWrite;
      if Len <= 0 then Fail;
      ALen := Len;
    end else EOF := eoStart + eoEnd;
  Owner := AOwner;
  if EOF and (eoStart + eoEnd) <> 0 then OldName := NewStr(AOldName);
  NewName := NewStr(ANewName);
end;

procedure TLine.Write;
begin
  if Stream <> nil then Stream^.Write(B, Len);
end;

procedure TLine.Read;
begin
  FillChar(B, Len, 0);
  if Stream <> nil then
    begin
      Stream^.Seek(Pos);
      Stream^.Read(B, Len);
    end;
end;

destructor TLine.Done;
begin
  DisposeStr(NewName);
  DisposeStr(OldName);
  inherited Done;
end;

procedure TLine.PrepareToWrite;
begin
  if MemStream = nil then
    begin
      Pos := MaxAvail-$E000;
      if Pos < $E000 then Pos := MemAvail - $8000;
      if Pos < $8000 then Pos := MemAvail - $4000;
      if Pos < $1000 then begin Len := 0; Exit end;
      New(MemStream, Init(Pos, Pos));
    end;
  Pos := Stream^.GetPos;
  if Pos + Len > Stream^.GetSize then Len := Stream^.GetSize - Pos;
end;

function TLine.Stream: PStream;
begin
  Stream := MemStream;
end;


{ TEMSLine }

procedure TEMSLine.PrepareToWrite;
begin
  if not EMSFound then begin Len := 0; Exit; end;
  if EMSStream = nil then
    begin
      Pos := LongInt(EMSFreePages);
      if Pos <= 0 then begin Len := 0; Exit; end;
      Pos := Pos * 16384;
      New(EMSStream, Init(Pos, Pos));
    end;
  Pos := Stream^.GetPos;
  if Pos + Len > Stream^.GetSize then Len := Stream^.GetSize - Pos;
end;

function TEMSLine.Stream: PStream;
begin
  Stream := EMSStream;
end;


{ TXMSLine }

procedure TXMSLine.PrepareToWrite;
begin
  if not XMSFound then begin Len := 0; Exit; end;
  if XMSStream = nil then
    begin
      Pos := LongInt(XMSFree);
      if Pos <= 0 then begin Len := 0;  Exit end;
      Pos := (Pos-1) shl 10;
      New(XMSStream, Init(Pos, Pos));
    end;
  Pos := Stream^.GetPos;
  if Pos + Len > Stream^.GetSize then Len := Stream^.GetSize - Pos;
end;

function TXMSLine.Stream: PStream;
begin
  Stream := XMSStream;
end;


type
      PFileRec = ^TFileRec;
      TFileRec = record
        Name: String[12];
        Attr: Byte;
        Owner: PString;
      end;

type
      PFCol = ^TFCol;
      TFCol = object(TCollection)
        procedure FreeItem(P: Pointer);  virtual;
      end;


procedure TFCol.FreeItem;
begin
  Dispose(PFCol(P));
end;


const
      cpmAskOver   = 0;
      cpmOverwrite = 1;
      cpmFresh     = 2;
      cpmSkipAll   = 3;
      cpmRefresh   = 4;

      cpoCheckFree = $01;
      cpoVerify    = $02;
      cpoMove      = $80;


procedure CopyFiles(Files: PCollection; const CopyDir, Mask: String; CopyMode, CopyOptions: Word);

var  ReadStream:  File;
     WriteStream: File;
     CopyCancel: Boolean;
     B: Pointer;
     BSize: Word;
     TRead, TWrite,
     ToRead, ToWrite: LongInt;
     CopyQueue: PCollection;


   function MkName(Nm: Str12): Str12;
     var I: Integer;
   begin
     for I := 1 to 12 do if Mask[I] <> '?' then Nm[I] := Mask[I];
     LowStr(Nm);
     MkName := MakeFileName(Nm);
   end;

   procedure MaxWrite;
     var I: Integer;
         J: Word;
         P: PLine;
   begin
     if not Abort or not CopyCancel then
         for I := 0 to CopyQueue^.Count - 1 do
           begin
              P := CopyQueue^.At(I);
              if P^.EOF and eoStart <> 0 then
                begin
                  WriteLn('Creating file ', CnvString(P^.NewName));
                  Assign(WriteStream, CnvString(P^.NewName));
                  ClrIO; Rewrite(WriteStream, 1);
                  if IOResult <> 0 then
                    begin
                      CopyCancel := On;
                      Break;
                    end;
                end;
              P^.Read(B^);
              ClrIO;
              BlockWrite(WriteStream, B^, P^.Len, J);
              WriteLn('Writing file, position - ', FilePos(WriteStream));
              if J <> P^.Len then
                    begin
                      CopyCancel := On;
                      Break;
                    end;
              if IOResult <> 0 then
                    begin
                      CopyCancel := On;
                      Break;
                    end;
              if P^.EOF and eoEnd <> 0 then
                begin
                  WriteLn('Closing file ', CnvString(P^.NewName));
                  SetFTime(WriteStream, P^.Date);
                  Close(WriteStream);
                  SetFAttr(WriteStream, P^.Attr);
                end;
           end;
     CopyQueue^.FreeAll;
     if MemStream <> nil then MemStream^.Seek(0);
     if EMSStream <> nil then EMSStream^.Seek(0);
     if XMSStream <> nil then XMSStream^.Seek(0);
   end;

   procedure MakeBuffer;
     var I: LongInt;
   begin
      I := MaxAvail - 10000;
      if I < 512 then Exit;
      if I > $E000 then I := $E000 else
      if I > $C000 then I := $C000 else
      if I > $8000 then I := $8000 else
      if I > $4000 then I := $4000 else
      if I > $1000 then I := $1000;
      B := MemAlloc(I);
      BSize := I;
   end;

   procedure CopyFile(const FName, AddDir: String; Own: Pointer);
     var P: PLine;
         Ln, Rd, WW: LongInt;
         Dt: LongInt;
         Attr, I, J: Word;
         FFF: Boolean;
         EOF: Byte;
         NName: String;
   begin
      if B = nil then MakeBuffer;
      if B = nil then
         begin
           CopyCancel := On;
           Exit;
         end;
      WriteLn('Opening file - ', FName);
      Assign(ReadStream, FName);
      GetFAttr(ReadStream, Attr);
      if Abort then Exit;
      if IOResult <> 0 then
        begin
           Abort := On;
           Exit;
        end;
      FileMode := $40;
      Reset(ReadStream, 1);
      if Abort then Exit;
      if IOResult <> 0 then
        begin
           Abort := On;
           Exit;
        end;
      Ln := FileSize(ReadStream);
      GetFTime(ReadStream, Dt);
      Rd := 0;
      EOF := eoStart;
      if AddDir = '' then NName := MkName(Norm12(GetName(FName)))
                     else NName := GetName(FName);
      NName := MakeNormName(CopyDir, NName);
      repeat
        WW := Ln - Rd;
        if WW > BSize then WW := BSize;
        P := New(PXMSLine, Init( WW,  Own, FName, NName, Ln, Dt, Attr, EOF));
        if P = nil then P := New(PEMSLine, Init( WW,  Own, FName, NName, Ln, Dt, Attr, EOF));
        if P = nil then P := New(PLine, Init( WW,  Own, FName, NName, Ln, Dt, Attr, EOF));
        if P = nil then
          begin
            MaxWrite;
            Continue
          end;
        J := 0;
        if WW > 0 then BlockRead(ReadStream, B^, WW, J);
        if FilePos(ReadStream) >= Ln then EOF := EOF or eoEnd;
        P^.EOF := EOF;
        if WW <> J then
          begin
            CopyCancel := On;
            Break;
          end;
        WriteLn('Reading file, position - ', FilePos(ReadStream));
        P^.Write(B^);
        CopyQueue^.Insert(P);
        if Abort or CopyCancel then Break;
        EOF := EOF and not eoStart;
        Inc(Rd, WW);
      until CopyCancel or Abort or (Rd = Ln);
      WriteLn('Closing file ',FName,', position - ', FilePos(WriteStream));
      ClrIO;
      Close(ReadStream);
   end;

   procedure CopyDirectory(const DirName, AddDir: String);
     var SR: SearchRec;
   begin
     ClrIO;
     FindFirst(DirName+'\*.*', $3F xor VolumeID, SR);
     while (DOSError = 0) and not Abort and not CopyCancel do
       begin
         if SR.Attr = 0 then
           begin
              LowStr(SR.Name);
              CopyFile(DirName+'\'+SR.Name, AddDir, nil);
           end else CopyDirectory(DirName+'\'+SR.Name, AddDir+'\'+SR.Name);
         if CopyCancel or Abort then Exit;
         ClrIO;
         FindNext(SR);
       end;
   end;

   procedure MaxRead;
     var I: Integer;
         P: PFileRec;
   begin
     for I := 0 to Files^.Count - 1 do
       begin
         P := Files^.At(I);
         FreeStr := MakeNormName(P^.Owner^, MakeFileName(P^.Name));
         if P^.Attr and Directory = 0 then CopyFile(FreeStr,'',P)
                                      else CopyDirectory(FreeStr,MkName(P^.Name));
         if Abort or CopyCancel then Exit;
       end;
     MaxWrite;
   end;

  procedure DoneStreams;
  begin
    if MemStream <> nil then Dispose(MemStream,Done); MemStream := nil;
    if EMSStream <> nil then Dispose(EMSStream,Done); EMSStream := nil;
    if XMSStream <> nil then Dispose(XMSStream,Done); XMSStream := nil;
  end;

begin
  MemStream := nil;
  EMSStream := nil;
  XMSStream := nil;
  CopyCancel := Off;
  B := nil;
  New(CopyQueue, Init(100, 100));
  MaxRead;
  if B <> nil then FreeMem(B, BSize);
  Dispose(CopyQueue, Done);
  DoneStreams;
end;


procedure TestCopy;
  var PC: PCollection;
      P: PFileRec;
      SR: SearchRec;
      S: String;
begin
  ClrIO;
  PC := New(PFCol, Init(10, 10));
  FindFirst('*.pas', $3F, SR);
  GetDir(0, S);
  while DOSError = 0 do
    begin
      if SR.Attr and Directory = 0 then
        begin
          New(P);
          P^.Name := Norm12(SR.Name);
          P^.Attr := SR.Attr;
          P^.Owner := @S;
          PC^.Insert(P);
        end;
      FindNext(SR);
    end;
  CopyFiles(PC, 'E:\@@\www', Norm12('*.pas'), 0,0);
  Dispose(PC, Done);
end;


begin
  TestCopy;
end.