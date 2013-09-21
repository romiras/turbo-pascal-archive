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

unit Archiver;

interface uses Views, Objects, DOS, ObjType;

type
     TStr4 = String[4];

    PArcFile   = ^TArcFile;
    TArcFile   = Record
                  FName  : PString;
                  Select : boolean;
                  Attr   : Byte;
                  USize,PSize,
                  Date   : Longint;
                 end;

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

     PARJArchive = ^TARJArchive;
     TARJArchive = object(TObject)
        Packer,
        UnPacker,
        Extract,
        ExtractWP,
        Add,Move,Garble,
        Delete,
        Test,
        IncludePaths,
        ExcludePaths,
        ForceMode,
        NormalCompression,
        FastCompression,
        UltraCompression: PString;
        ListChar: Char;
        Swap: Boolean;
        PutTempBefore: Byte;
        constructor Load(var S: TStream);
        procedure Store(var S: TStream);
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
     end;

    PZIPArchive = ^TZIPArchive;
    TZIPArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PLHAArchive = ^TLHAArchive;
    TLHAArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PARCArchive = ^TARCArchive;
    TARCArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PBSAArchive = ^TBSAArchive;
    TBSAArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PBS2Archive = ^TBS2Archive;
    TBS2Archive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PSQZArchive = ^TSQZArchive;
    TSQZArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PLIMArchive = ^TLIMArchive;
    TLIMArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PCHZArchive = ^TCHZArchive;
    TCHZArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PHYPArchive = ^THYPArchive;
    THYPArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PHAPArchive = ^THAPArchive;
    THAPArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PHAArchive = ^THAArchive;
    THAArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PUC2Archive = ^TUC2Archive;
    TUC2Archive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PZOOArchive = ^TZOOArchive;
    TZOOArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PHPKArchive = ^THPKArchive;
    THPKArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PRARArchive = ^TRARArchive;
    TRARArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PTARArchive = ^TTARArchive;
    TTARArchive = object(TARJArchive)
        constructor Init;
        function Detect: Boolean; virtual;
        procedure GetFile; virtual;
        function GetID: Byte; virtual;
        function GetSign: TStr4; virtual;
    end;

    PArchiveCollection = ^TArchiveCollection;
    TArchiveCollection = object(TSortedCollection)
      function Compare(P1, P2: Pointer): Integer; virtual;
    end;

    PFileInfo    = ^TFileInfo;
    TFileInfo    = object(TSortedCollection)
                    function   Compare(P1, P2: Pointer): Integer; virtual;
                    Procedure  FreeItem(Item : Pointer); virtual;
                    Procedure  PutItem(var S: TStream; Item: Pointer); virtual;
                    function   GetItem(var S: TStream): Pointer; virtual;
                   end;

    PUserSaver = ^TUserSaver;
    TUserSaver = object(TView)
      Screen: Pointer;
      SSize, SWidth: Integer;
      CShape, CPos: Word;
      CheckIO: Boolean;
      isValid: Boolean;
      constructor Init(ACheck: Boolean);
      destructor Done; virtual;
      constructor Load(var S: TStream);
      procedure Store(var S: TStream);
      function Valid(Command: Word): Boolean; virtual;
    end;

const
    CurrentArchive: PARJArchive = nil;
    Archives: PSortedCollection = nil;

    arcARC  = 0;
    arcARJ  = 1;
    arcBSA  = 2;
    arcBS2  = 3;
    arcCHZ  = 4;
    arcHA   = 5;
    arcHAP  = 6;
    arcHPK  = 7;
    arcHYP  = 8;
    arcLHA  = 9;
    arcLIM  = 10;
    arcRAR  = 11;
    arcSQZ  = 12;
    arcTAR  = 13;
    arcUC2  = 14;
    arcZIP  = 15;
    arcZOO  = 16;


    DefaultArchiver: Word = arcARJ;
    DefaultArcMode: Word = 256;


var ArcFile    : TBufStream;
    FileInfo   : TFInfo;
    ArcPos     : LongInt;

const
    ArcFileName: PathStr = '';
    PReader: PView = nil;

      RARJArchiver: TStreamRec = (
       ObjType: otARJArchiver;
       VmtLink: Ofs(TypeOf(TARJArchive)^);
       Load: @TARJArchive.Load;
       Store: @TARJArchive.Store);

      RZIPArchiver: TStreamRec = (
       ObjType: otZIPArchiver;
       VmtLink: Ofs(TypeOf(TZIPArchive)^);
       Load: @TZIPArchive.Load;
       Store: @TZIPArchive.Store);

      RARCArchiver: TStreamRec = (
       ObjType: otARCArchiver;
       VmtLink: Ofs(TypeOf(TARCArchive)^);
       Load: @TARCArchive.Load;
       Store: @TARCArchive.Store);

      RHYPArchiver: TStreamRec = (
       ObjType: otHYPArchiver;
       VmtLink: Ofs(TypeOf(THYPArchive)^);
       Load: @THYPArchive.Load;
       Store: @THYPArchive.Store);

      RRARArchiver: TStreamRec = (
       ObjType: otRARArchiver;
       VmtLink: Ofs(TypeOf(TRARArchive)^);
       Load: @TRARArchive.Load;
       Store: @TRARArchive.Store);

      RHAPArchiver: TStreamRec = (
       ObjType: otHAPArchiver;
       VmtLink: Ofs(TypeOf(THAPArchive)^);
       Load: @THAPArchive.Load;
       Store: @THAPArchive.Store);

      RHAArchiver: TStreamRec = (
       ObjType: otHAArchiver;
       VmtLink: Ofs(TypeOf(THAArchive)^);
       Load: @THAArchive.Load;
       Store: @THAArchive.Store);

      RSQZArchiver: TStreamRec = (
       ObjType: otSQZArchiver;
       VmtLink: Ofs(TypeOf(TSQZArchive)^);
       Load: @TSQZArchive.Load;
       Store: @TSQZArchive.Store);

      RBSAArchiver: TStreamRec = (
       ObjType: otBSAArchiver;
       VmtLink: Ofs(TypeOf(TBSAArchive)^);
       Load: @TBSAArchive.Load;
       Store: @TBSAArchive.Store);

      RBS2Archiver: TStreamRec = (
       ObjType: otBS2Archiver;
       VmtLink: Ofs(TypeOf(TBS2Archive)^);
       Load: @TBS2Archive.Load;
       Store: @TBS2Archive.Store);

      RCHZArchiver: TStreamRec = (
       ObjType: otCHZArchiver;
       VmtLink: Ofs(TypeOf(TCHZArchive)^);
       Load: @TCHZArchive.Load;
       Store: @TCHZArchive.Store);

      RLHAArchiver: TStreamRec = (
       ObjType: otLHAArchiver;
       VmtLink: Ofs(TypeOf(TLHAArchive)^);
       Load: @TLHAArchive.Load;
       Store: @TLHAArchive.Store);

      RZOOArchiver: TStreamRec = (
       ObjType: otZOOArchiver;
       VmtLink: Ofs(TypeOf(TZOOArchive)^);
       Load: @TZOOArchive.Load;
       Store: @TZOOArchive.Store);

      RUC2Archiver: TStreamRec = (
       ObjType: otUC2Archiver;
       VmtLink: Ofs(TypeOf(TUC2Archive)^);
       Load: @TUC2Archive.Load;
       Store: @TUC2Archive.Store);

      RLIMArchiver: TStreamRec = (
       ObjType: otLIMArchiver;
       VmtLink: Ofs(TypeOf(TLIMArchive)^);
       Load: @TLIMArchive.Load;
       Store: @TLIMArchive.Store);

      RHPKArchiver: TStreamRec = (
       ObjType: otHPKArchiver;
       VmtLink: Ofs(TypeOf(THPKArchive)^);
       Load: @THPKArchive.Load;
       Store: @THPKArchive.Store);

      RTARArchiver: TStreamRec = (
       ObjType: otTARArchiver;
       VmtLink: Ofs(TypeOf(TTARArchive)^);
       Load: @TTARArchive.Load;
       Store: @TTARArchive.Store);

      RArchiveCollection: TStreamRec = (
       ObjType: otArchiveCollection;
       VmtLink: Ofs(TypeOf(TArchiveCollection)^);
       Load: @TArchiveCollection.Load;
       Store: @TArchiveCollection.Store);


procedure LoadArchiveSet;
Procedure ReadArcList;
Function  DetectArchive: PArjArchive;
Procedure SetupArchive(ArchCommand: Word);
Function  ArchiveFiles(const S: String; Files: PCollection; MoveMode: Boolean; Owner: Pointer): Boolean;
procedure MakeArchive(S: String; Files: PCollection; MoveMode: Boolean; Owner: Pointer);
procedure UnarchiveFiles(const FName: String);
procedure InsertUserSaver(ACheck: Boolean);


implementation

 uses Advance, DNApp, Drivers, Commands, Dialogs, FilesCol, FViewer,
      StartUp, RStrings, Memory, Messages, ArcView, FileCopy, HistList,
      FStorage, Menus;

 const CDir: String = '';

{ ------------------------------- Collections ----------------------------- }

function TArchiveCollection.Compare;
begin
  if PARJArchive(P1)^.GetID < PARJArchive(P2)^.GetID then Compare := -1 else
    if PARJArchive(P1)^.GetID > PARJArchive(P2)^.GetID then Compare := 1 else
      Compare := 0;
end;

Procedure TFileInfo.FreeItem;
begin
  if Item <> nil then
   begin
    DisposeStr(PArcFile(Item)^.FName);
    Dispose(PArcFile(Item));
   end;
end;

function TFileInfo.Compare;
 var F1: PArcFile absolute P1;
     F2: PArcFile absolute P2;
begin
  if F1^.FName^ = F2^.FName^ then Compare := 0
    else Compare := 1 - 2*Integer(F1^.FName^ > F2^.FName^);
end;

Procedure TFileInfo.PutItem;
begin
 S.WriteStr(PArcFile(Item)^.FName);
 S.Write(PArcFile(Item)^.Select, 1*2+3*4);
end;

function TFileInfo.GetItem;
 var P: PArcFile;
     PS: PString;
begin
 New(P);
 P^.FName := S.ReadStr;
 S.Read(P^.Select, 1*2+3*4);
 GetItem := P;
end;

{ --------------------------- All archives -------------------------------- }

constructor TARJArchive.Load;
begin
  Packer    := S.ReadStr;
  UnPacker  := S.ReadStr;
  Extract   := S.ReadStr;
  ExtractWP := S.ReadStr;
  Add       := S.ReadStr;
  Move      := S.ReadStr;
  Delete    := S.ReadStr;
  Garble    := S.ReadStr;
  Test      := S.ReadStr;
  IncludePaths      := S.ReadStr;
  ExcludePaths      := S.ReadStr;
  ForceMode         := S.ReadStr;
  NormalCompression := S.ReadStr;
  FastCompression   := S.ReadStr;
  UltraCompression  := S.ReadStr;
  PutTempBefore := 3;
  S.Read(ListChar, SizeOf(ListChar) +
                   SizeOf(Swap));
end;

procedure TARJArchive.Store;
begin
  S.WriteStr(Packer);
  S.WriteStr(UnPacker);
  S.WriteStr(Extract);
  S.WriteStr(ExtractWP);
  S.WriteStr(Add);
  S.WriteStr(Move);
  S.WriteStr(Delete);
  S.WriteStr(Garble);
  S.WriteStr(Test);
  S.WriteStr(IncludePaths);
  S.WriteStr(ExcludePaths);
  S.WriteStr(ForceMode);
  S.WriteStr(NormalCompression);
  S.WriteStr(FastCompression);
  S.WriteStr(UltraCompression);
  S.Write(ListChar, SizeOf(ListChar) +
                    SizeOf(Swap));
end;

{ ----------------------------- ARJ ------------------------------------}

constructor TARJArchive.Init;
begin
  inherited Init;
  Packer    := NewStr('ARJ.EXE');
  UnPacker  := NewStr('ARJ.EXE');
  Extract   := NewStr('e');
  ExtractWP := NewStr('x');
  Add       := NewStr('a');
  Move      := NewStr('m');
  Delete    := NewStr('d');
  Garble    := NewStr('-g');
  Test      := NewStr('t');
  IncludePaths      := NewStr('');
  ExcludePaths      := NewStr('-e');
  ForceMode         := NewStr('-y');
  NormalCompression := NewStr('-m1');
  FastCompression   := NewStr('-m3');
  UltraCompression  := NewStr('-jm');
  ListChar  := '!';
  PutTempBefore := 0;
  Swap := True;
end;

function TARJArchive.GetID;
begin
  GetID := arcARJ;
end;

function TARJArchive.GetSign;
begin
  GetSign := 'ARJ:';
end;

function TARJArchive.Detect;
var I,J: Word;
    L: LongInt;
    S: String;
begin
 ArcFile.Read(I, 2);
 if (I <> 60000) and (ArcPos > 0) then ArcFile.Read(I, 2);
 L := ArcFile.GetPos;
 Detect:=(I=60000);
 if i=60000
    then begin
      {** here must be comment reading **}
          ArcFile.Read(I,2);
          ArcFile.Seek(L + I + 8);
         end
    else
      begin
        ArcFile.Seek(ArcPos);
      end;
end;

procedure TARJArchive.GetFile;
const
   GARBLED_FLAG      = $01;
   OLD_SECURED_FLAG  = $02;
   VOLUME_FLAG       = $04;
   EXTFILE_FLAG      = $08;
   PATHSYM_FLAG      = $10;
   BACKUP_FLAG       = $20;
   SECURED_FLAG      = $40;

var HS,i : Word;
    FP   : Longint;
    s    : PathStr;
    C    : Char;
    Extr : LongInt;
    h    : record
             First_Hdr_Size  : Byte;
             Version         : Byte;
             MinVer          : Byte;
             Host_OS         : Byte;
             ARJ_Flags       : Byte;
             Method          : Byte;
             File_Type       : Byte;
             Reserved        : Byte;
             Date_Time       : LongInt;
             Compressed_Size : LongInt;
             Original_Size   : LongInt;
             Original_CRC    : LongInt;
             Filespec_Pos    : Word;
             File_Acs_Mode   : Word;
             Host_Data       : Word;
           end;

begin
   ArcFile.Read(i,2);
   if (i<>60000) or (ArcFile.Status <> 0) then begin FileInfo.Last:=2;Exit;end;
   ArcFile.Read(HS,2);
   if (HS=0) then begin FileInfo.Last:=1;Exit;end;
   FP := ArcFile.GetPos;

   ArcFile.Read(h, SizeOf(h));

   with FileInfo do
   begin
     Date   := h.Date_Time;
     PSize  := h.Compressed_Size;
     USize  := h.Original_Size;
     if (h.ARJ_Flags and
       ((OLD_SECURED_FLAG or GARBLED_FLAG or SECURED_FLAG)))=0
         then Attr := 0 else Attr := Hidden;
     if h.File_Type = 3 then Attr := Attr or Directory;
   end;

   if h.ARJ_Flags and EXTFILE_FLAG<>0 then
   begin
     ArcFile.Read(Extr, 4);
     if Extr<>0 then with FileInfo do Attr := Attr or SysFile;
   end else Extr := 0;

   S := '';
   repeat ArcFile.Read(C,1); if C <> #0 then S := S + C else Break
   until ArcFile.Status <> stOK;
   While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
   if (ArcFile.Status <> stOK) then begin FileInfo.Last:=2;Exit;end;
   FileInfo.FName := S; FileInfo.Last := 0;
   ArcFile.Seek(FP+HS+4);
   Repeat
    ArcFile.Read(i,2);
    if i>0 then ArcFile.Seek(ArcFile.GetPos+i+4);
   Until (i=0) or (ArcFile.Status <> stOK);
   ArcFile.Seek(ArcFile.GetPos+Fileinfo.PSize);
end;

{ ----------------------------- ZIP ------------------------------------}

constructor TZIPArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('PKZIP.EXE');
  UnPacker  := NewStr('PKUNZIP.EXE');
  Extract   := NewStr(' ');
  ExtractWP := NewStr('-d');
  Add       := NewStr('-r');
  Move      := NewStr('-mr');
  Delete    := NewStr('-d');
  Garble    := NewStr('-s');
  Test      := NewStr('-t');
  IncludePaths      := NewStr('-P');
  ExcludePaths      := NewStr('');
  ForceMode         := NewStr('');
  NormalCompression := NewStr('-en');
  FastCompression   := NewStr('-ef');
  UltraCompression  := NewStr('-ex');
  ListChar  := '@';
  PutTempBefore := 1;
  Swap := False;
end;

function TZIPArchive.GetID;
begin
  GetID := arcZIP;
end;

function TZIPArchive.GetSign;
begin
  GetSign := 'ZIP:';
end;

function TZIPArchive.Detect;
  var i: LongInt;
begin
  ArcFile.Read(i,4);
  Detect:=(i=$04034b50);
  ArcFile.Seek(ArcPos);
end;

type
    TZIPLocalHdr = record
     ID: LongInt;
     Extract: Word;
     GeneralPurpose: Word;
     Method: Word;
     LastModDate: LongInt;
     CRC32: LongInt;
     CompressedSize: LongInt;
     OriginalSize: LongInt;
     FNameLength: Word;
     ExtraField: Word;
    end;

Procedure TZIPArchive.GetFile;
label 1;
var HS, I: Word;
    FP,FPP: Longint;
    P: TZIPLocalHdr;
    s: String;
begin
   FP := ArcFile.GetPos;
1:
   ArcFile.Read(P.ID,4);
   if (P.ID and $FFFF <> $4B50) or (ArcFile.Status <> stOK) then
    begin
      FPP := FP;
      FP := SearchFileStr(@ArcFile, 'PK'#03#04, FP, On, Off, Off, Off);
      if FP > 0 then begin ArcFile.Seek(FP); Goto 1 end;
      FP := SearchFileStr(@ArcFile, 'PK'#01#02, FPP, On, Off, Off, Off);
      if FP > 0 then begin ArcFile.Seek(FP); Goto 1 end;
      FP := SearchFileStr(@ArcFile, 'PK'#05#06, FPP, On, Off, Off, Off);
      FileInfo.Last:=2;Exit;
    end;
   if (P.ID = $06054B50) or (P.ID = $02014b50) then begin FileInfo.Last:=1;Exit;end;
   ArcFile.Read(P.Extract,SizeOf(P)-4);
   if (ArcFile.Status <> stOK) or (P.FNameLength > 255) then
    begin FileInfo.Last:=2;Exit;end;
   ArcFile.Read(S[1], P.FNameLength); S[0] := Char(P.FNameLength);
   While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
   FileInfo.FName := S; FileInfo.Last := 0;
   FileInfo.Attr := P.GeneralPurpose and 1;
   FileInfo.USize := P.OriginalSize;
   FileInfo.PSize := P.CompressedSize;
   FileInfo.Date := P.LastModDate;
   ArcFile.Seek(ArcFile.GetPos + P.ExtraField + P.CompressedSize);
end;

{ ----------------------------- LHA ------------------------------------}

constructor TLHAArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('LHA.EXE');
  UnPacker  := NewStr('LHA.EXE');
  Extract   := NewStr('e');
  ExtractWP := NewStr('x');
  Add       := NewStr('a -r -x');
  Move      := NewStr('m -r -x');
  Delete    := NewStr(' ');
  Garble    := NewStr('p');
  Test      := NewStr('t');
  IncludePaths      := NewStr('-x');
  ExcludePaths      := NewStr('');
  ForceMode         := NewStr('-m');
  NormalCompression := NewStr('');
  FastCompression   := NewStr('-z');
  UltraCompression  := NewStr('');
  ListChar  := '@';
  PutTempBefore := 0;
  Swap := False;
end;

function TLHAArchive.GetID;
begin
  GetID := arcLHA;
end;

function TLHAArchive.GetSign;
begin
  GetSign := 'LHA:';
end;

type LHAHdr = record
      Size: Byte;
      SUM: Byte;
      MethodID: Array[1..5] of Char;
      PackedSize: LongInt;
      OriginSize: LongInt;
      Date: LongInt;
      Attr: Byte;
      Level: Byte;
      Name: Array[0..255] of Char;
     end;

function TLHAArchive.Detect;
var i: LongInt;
    P: LHAHdr;
begin
 ArcFile.Read(P,SizeOf(P)-256);
 Detect:=False;
 if (Pos(P.MethodID, '-lh1--lh0--lh2--lh3--lh4--lh5--lzs--lz4--lz5--lhd-')+4) mod 5 = 0
    then begin
          Detect:=True;
          ArcFile.Seek(ArcPos);
         end
    else ArcFile.Seek(ArcPos);
end;

Procedure TLHAArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : LHAHdr;
    s    : String;
begin
 ArcFile.Read(P.Size,1);
 if P.Size > 1 then ArcFile.Read(P.Sum,P.Size-1);
 if (P.Size = 0) then begin FileInfo.Last:=1;Exit;end;
 if (ArcFile.Status <> stOK) then begin FileInfo.Last:=2;Exit;end;
 System.Move(P.Name, S, Byte(P.Name[0])+1);
 Replace('/', '\', S);
 FileInfo.FName := S; FileInfo.Last := 0;
 FileInfo.Attr := P.Attr;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date := P.Date;
 ArcFile.Read(HS, 2);
 FP := ArcFile.GetPos;
 if P.Level <> 0 then
   begin
     ArcFile.Read(P.Name, Min(255, HS));
     if (P.Name[0] = #2) then
      begin
         I := 1; S := '';
         while (I < Min(255,HS)) and (P.Name[I] > #31) do
           begin AddStr(S, P.Name[I]); Inc(I) end;
         Replace(#255, '\', S);
         Replace('/', '\', S);
         System.Insert(S, FileInfo.FName, 1);
      end;
   end;
 ArcFile.Seek(FP + P.PackedSize);
end;

{ ----------------------------- ARC ------------------------------------}

constructor TARCArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('PAK.EXE');
  UnPacker  := NewStr('PAK.EXE');
  Extract   := NewStr('E');
  ExtractWP := NewStr('E /WA');
  Add       := NewStr('A');
  Move      := NewStr('A /M');
  Delete    := NewStr('D');
  Garble    := NewStr('/G');
  Test      := NewStr('T');
  ListChar  := '@';
  PutTempBefore := 2;
  Swap := True;
end;

function TARCArchive.GetID;
begin
  GetID := arcARC;
end;

function TARCArchive.GetSign;
begin
  GetSign := 'ARC:';
end;

type
     ARCHdr = record
      Mark: Char;
      Version: Byte;
      Name: Array[1..13] of Char;
      PackedSize: LongInt;
      Date: LongInt;
      CRC: Word;
      OriginSize: LongInt;
     end;

function TARCArchive.Detect;
var P: ARCHdr;

procedure More;
var i: byte;
    c: char;
begin
  i := 0;
  while i<13 do
  begin
    Inc(i);
    c := P.Name[i];
    if c = #0 then Break;
    if c <#32 then Exit;
  end;
  if i <= 2 then Exit;
  if P.PackedSize<0 then Exit;
  if P.OriginSize<0 then Exit;
  Detect := True;
end;

begin
 ArcFile.Read(P,SizeOf(P));
 Detect := False;
 if (ArcFile.Status = stOK) and (P.Mark = ^Z) and (P.Version < 20) then More;
 ArcFile.Seek(ArcPos);
end;

Procedure TARCArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : ARCHdr;
    s    : String;
begin
 ArcFile.Read(P,2);
 if (P.Mark = ^Z) and (P.Version <> 0) and (ArcFile.Status = stOK) then ArcFile.Read(P.Name,SizeOf(P)-2);
 if (P.Version = 0) then begin FileInfo.Last:=1;Exit;end;
 if (ArcFile.Status <> stOK) then begin FileInfo.Last:=2;Exit;end;
 i := 1; S := ' ';
 While (I < 14) and (P.Name[I] <> #0) do
  begin S := S + P.Name[I]; Inc(I); end;
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 FileInfo.FName := S;
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date := (P.Date shr 16) or (P.Date shl 16);
 ArcFile.Seek(ArcFile.GetPos + P.PackedSize);
end;

{ ----------------------------- HA ------------------------------------}

constructor THAArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('HA.EXE');
  UnPacker  := NewStr('HA.EXE');
  Extract   := NewStr('ey');
  ExtractWP := NewStr('xy');
  Add       := NewStr('a');
  Move      := NewStr('am');
  Delete    := NewStr('d');
  Garble    := NewStr(' ');
  Test      := NewStr('t');
  IncludePaths      := NewStr('');
  ExcludePaths      := NewStr('+e');
  ForceMode         := NewStr('+y');
  NormalCompression := NewStr('+1');
  FastCompression   := NewStr('+0');
  UltraCompression  := NewStr('+2');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function THAArchive.GetID;
begin
  GetID := arcHA;
end;

function THAArchive.GetSign;
begin
  GetSign := 'HA:';
end;

type
     HAHdr = record
      Method: Byte;
      PackedSize: LongInt;
      OriginSize: LongInt;
      CRC: LongInt;
      Date: LongInt;
     end;

Function THAArchive.Detect;
var
    S: Array[1..2] of Char;
    P: HAHdr;
begin
 ArcFile.Read(S, 2);
 Detect:=False;
 if (ArcFile.Status = stOK) and (S = 'HA')
    then begin
          Detect:=True;
          ArcFile.Seek(ArcPos+4);
         end
    else ArcFile.Seek(ArcPos);
end;

Procedure THAArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : HAHdr;
    S    : String;
    C    : Char;
    DT   : DateTime;
begin
 ArcFile.Read(P,SizeOf(P));
 if (ArcFile.Status <> stOK) then begin FileInfo.Last:=1;Exit;end;
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 GetUNIXDate(P.Date - 14400, DT.Year, DT.Month, DT.Day, DT.Hour, DT.Min, DT.Sec);
 PackTime(DT, FileInfo.Date);
 i := 1;
 S[0] := #0;
 repeat ArcFile.Read(C, 1); if C <> #0 then S := S + C; until (C = #0) or (Length(S) > 77);
 repeat ArcFile.Read(C, 1); if C <> #0 then S := S + C; until (C = #0) or (Length(S) > 78);
 if Length(S) > 79 then begin FileInfo.Last := 2; Exit; end;
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := S; S[0] := #2;
 ArcFile.Read(S[1], 3);
 if S <> #$02#$01 then begin FileInfo.Last := 2; Exit; end;
 ArcFile.Seek(ArcFile.GetPos + P.PackedSize);
end;


{ ----------------------------- SQZ ------------------------------------}

constructor TSQZArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('SQZ.EXE');
  UnPacker  := NewStr('SQZ.EXE');
  Extract   := NewStr('e');
  ExtractWP := NewStr('x');
  Add       := NewStr('a');
  Move      := NewStr('a');
  Delete    := NewStr('d');
  Garble    := NewStr(' ');
  Test      := NewStr('t');
  IncludePaths      := NewStr('');
  ExcludePaths      := NewStr('');
  ForceMode         := NewStr('');
  NormalCompression := NewStr('');
  FastCompression   := NewStr('');
  UltraCompression  := NewStr('');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function TSQZArchive.GetID;
begin
  GetID := arcSQZ;
end;

function TSQZArchive.GetSign;
begin
  GetSign := 'SQZ:';
end;

type
     SQZHdr = record
      Size: Byte;
      SUM: Byte;
      Method: Byte;
      PackedSize: LongInt;
      OriginSize: LongInt;
      Date: LongInt;
      Attr: Byte;
      CRC: LongInt;
      Name: Array[0..127] of Char;
     end;

function TSQZArchive.Detect: Boolean;
var
    S: Array[0..4] of Char;
begin
 ArcFile.Read(S, 5);
 Detect := False;
 if (ArcFile.Status = stOK) and (S = 'HLSQZ')
    then begin
          Detect := True;
          ArcFile.Seek(ArcPos+8);
         end
    else ArcFile.Seek(ArcPos);
end;

Procedure TSQZArchive.GetFile;
label 1;
var
    HS,i : Word;
    FP   : Longint;
    P    : SQZHdr;
    S    : String;
    C    : Char;
begin
1:
 ArcFile.Read(P,1);
 if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2; Exit; end;
 if (P.Size = 0) then begin FileInfo.Last := 1; Exit;end;
 if P.Size < $19 then
  begin
   ArcFile.Read(I, 2);
   ArcFile.Seek(ArcFile.GetPos + I);
   Goto 1;
  end;
 ArcFile.Read(P.SUM, P.Size + 1);
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := P.Attr;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date := P.Date;
 i := 1;
 S[0] := Char(P.Size - 18); System.Move(P.Name, S[1], P.Size - 18);
 if Length(S) > 79 then begin FileInfo.Last := 2; Exit; end;
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 FileInfo.FName := S;
 ArcFile.Seek(ArcFile.GetPos + P.PackedSize);
end;


{ ----------------------------- HAP ------------------------------------}

constructor THAPArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('HAP3.EXE');
  UnPacker  := NewStr('PAH3.EXE');
  Extract   := NewStr('e');
  ExtractWP := NewStr('x');
  Add       := NewStr('a');
  Move      := NewStr('a');
  Delete    := NewStr('d');
  Garble    := NewStr(' ');
  Test      := NewStr('t');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function THAPArchive.GetID;
begin
  GetID := arcHAP;
end;

function THAPArchive.GetSign;
begin
  GetSign := 'HAP:';
end;

type
     HAPHdr = record
      C: Char;
      ID: Array[1..4] of Char;
      PackedSize: LongInt;
      Reserved: Array[1..9] of Byte;
      Attr: Byte;
      Date: LongInt;
      OriginSize: LongInt;
     end;

Function THAPArchive.Detect: Boolean;
var
    S: Array[1..4] of Char;
    P: HAHdr;
begin
 ArcFile.Read(S, 4);
 Detect:=False;
 if (ArcFile.Status = stOK) and (S = '‘3HF')
    then begin Detect:=True; ArcFile.Seek(ArcPos+14) end
    else ArcFile.Seek(ArcPos);
end;

Procedure THAPArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : HAPHdr;
    S    : String;
    C    : Char;
begin
 ArcFile.Read(P,1);
 if (ArcFile.GetPos = ArcFile.GetSize)
   then begin FileInfo.Last := 1;Exit;end;
 ArcFile.Read(P.ID,SizeOf(P)-1);
 if (ArcFile.Status <> stOK) or (P.ID <> 'ŽhJW')
   then begin FileInfo.Last := 2;Exit;end;
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := P.Attr;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date := P.Date;
 i := 1;
 S[0] := #0;
 repeat ArcFile.Read(C, 1); if C <> #0 then S := S + C; until (C = #0) or (Length(S) > 77);
 repeat ArcFile.Read(C, 1); until (C in [#$15,#$16]) or (ArcFile.Status <> stOK);
 if (ArcFile.Status <> stOK) or (Length(S) > 79) then
  begin FileInfo.Last := 2; Exit; end;
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := S;
 ArcFile.Seek(ArcFile.GetPos + P.PackedSize-1);
end;


{ ----------------------------- ZOO ------------------------------------}

constructor TZOOArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('ZOO.EXE');
  UnPacker  := NewStr('ZOO.EXE');
  Extract   := NewStr('eo');
  ExtractWP := NewStr('xo');
  Add       := NewStr('a');
  Move      := NewStr('aE');
  Delete    := NewStr('D');
  Garble    := NewStr(' ');
  Test      := NewStr('eN');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function TZOOArchive.GetID;
begin
  GetID := arcZOO;
end;

function TZOOArchive.GetSign;
begin
  GetSign := 'ZOO:';
end;

type
     ZOOHdr = record
      ID: LongInt;
      Info: Word;
      NextHDR: LongInt;
      CurStart: LongInt;
      Date: LongInt;
      W: Word;
      OriginSize: LongInt;
      PackedSize: LongInt;
      C: Char;
      Reserved: Array[1..9] of Byte;
     end;

     ZOOPHdr = record
      Date: LongInt;
      Reserved: Array[1..16] of Byte;
      ID: Array[1..5] of Char;
     end;

const ZOOID = $FDC4A7DC;

Function TZOOArchive.Detect;
label 1;
var
    S: Array[1..3] of Char;
    C: Char;
    L: LongInt;
begin
 ArcFile.Read(S, 3);
 Detect:=False;
 if (ArcFile.Status = stOK) and (S = 'ZOO')
    then
     begin
      L := 0;
      repeat Inc(L); ArcFile.Read(C, 1) until (C = ^Z) or (L = 1024);
      ArcFile.Read(L,2);
      ArcFile.Read(L,4);
      if L <> ZOOID then Goto 1;
      Detect := True;
      ArcFile.Read(L,4);
      ArcFile.Seek(L);
      Exit;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure TZOOArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : ZOOHdr;
    Q    : Array [1..40] of Char absolute P;
    P1   : ZOOPHdr;
    S    : String;
    C    : Char;
begin
{ if (ArcFile.GetPos = ArcFile.GetSize)
   then begin FileInfo.Last := 1;Exit;end;}
 ArcFile.Read(P, 4);
 if (ArcFile.Status <> stOK) or (P.ID <> ZOOID)
  then begin FileInfo.Last := 2;Exit;end;
 ArcFile.Read(P.Info, 2);
 if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
 {if (P.Info = $0002) then begin FileInfo.Last := 1;Exit;end;}
 ArcFile.Read(P.NextHDR, SizeOf(P)-6);
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date  := (P.Date shl 16) or (P.Date shr 16);
 i := 1;
 S[0] := #0;
 repeat ArcFile.Read(C, 1); if C <> #0 then S := S + C; until (C = #0) or (Length(S) > 77);
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := S;
 if S = '' then begin FileInfo.Last := 1;Exit;end;
 ArcFile.Seek(P.NextHdr);
end;


{ ----------------------------- CHZ ------------------------------------}

constructor TCHZArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('CHZ.EXE');
  UnPacker  := NewStr('CHZ.EXE');
  Extract   := NewStr('-e -y');
  ExtractWP := NewStr('-e -y');
  Add       := NewStr('-a');
  Move      := NewStr('-a -m');
  Delete    := NewStr('-D');
  Garble    := NewStr(' ');
  Test      := NewStr('eN');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function TCHZArchive.GetID;
begin
  GetID := arcCHZ;
end;

function TCHZArchive.GetSign;
begin
  GetSign := 'CHZ:';
end;

type
     CHZHdr = record
      ID: Array [1..4] of Char;
      PackedSize: LongInt;
      OriginSize: LongInt;
      Data: Array[1..4] of Byte;
      Date: LongInt;
      QQQ: Word;
      NameLen: Word;
     end;

Function TCHZArchive.Detect: Boolean;
label 1;
var
    M: Array[1..3] of Char;
    C: Char;
    L: LongInt;
    S: String;
begin
 Detect:=False;
 if ArcPos > 0 then
   begin
    S[0] := #128;
    ArcFile.Read(S[1],128);
    L := Pos('SChF', S);
    if L = 0 then L := Pos('SChD', S);
    if L = 0 then Goto 1;
    Inc(ArcPos, L-1);
    ArcFile.Seek(ArcPos);
   end;
 ArcFile.Read(M, 3);
 if (ArcFile.Status = stOK) and (M = 'SCh')
    then
     begin
      Detect := True;
      CDir := '';
      ArcFile.Seek(ArcPos);
      Exit;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure TCHZArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : CHZHdr;
    Q    : Array [1..40] of Char absolute P;
    P1   : ZOOPHdr;
    S    : String;
    C    : Char;
    label 1;
begin
1:
 FP := ArcFile.GetPos;
 if FP = ArcFile.GetSize then begin FileInfo.Last := 1; Exit;end;
 ArcFile.Read(P, 4);
 if (ArcFile.Status <> stOK) or (Copy(P.ID,1,3) <> 'SCh')
  then begin FileInfo.Last := 2;Exit;end;
 if P.ID[4] = 'D' then
  begin
   ArcFile.Seek(FP+4+5);
   ArcFile.Read(S[0],1);
   ArcFile.Read(S[1],Length(S));
   CDir := CDir + S+'\';
   Goto 1;
  end else if P.ID[4] = 'd' then
   begin
    if CDir <> '' then
     begin
      Dec(CDir[0]);
      while (CDir <> '') and (CDir[Byte(CDir[0])] <> '\') do Dec(CDir[0]);
     end;
    Goto 1;
   end;
 ArcFile.Read(P.PackedSize, Sizeof(P)-4);
 if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date  := P.Date{P.Date shl 16) or (P.Date shr 16)};
 i := 1;
 S[0] := Char(P.NameLen);
 ArcFile.Read(S[1], P.NameLen and 255);
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := CDir + S;
 ArcFile.Seek(FP + P.PackedSize);
end;


{ ----------------------------- BSA ------------------------------------}

constructor TBSAArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('BSARC.EXE');
  UnPacker  := NewStr('BSARC.EXE');
  Extract   := NewStr('-xy');
  ExtractWP := NewStr('-xy');
  Add       := NewStr('-ar');
  Move      := NewStr('-am');
  Delete    := NewStr('-D');
  Garble    := NewStr('-xg');
  Test      := NewStr('-t');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function TBSAArchive.GetID;
begin
  GetID := arcBSA;
end;

function TBSAArchive.GetSign;
begin
  GetSign := 'BSA:';
end;

type
     BSAHdr = record
      ID: Array [1..4] of Char;
      PackedSize: LongInt;
      OriginSize: LongInt;
      Date: LongInt;
      Data: Array[1..6] of Byte;
      NameLen: Byte;
     end;

Function TBSAArchive.Detect: Boolean;
label 1;
var
    M: Array[1..4] of Char;
    C: Char;
    L: LongInt;
    S: String;
begin
 Detect:=False;
 ArcFile.Read(M, 4);
 if (ArcFile.Status = stOK) and (M[4] in [#0,#7]) and (Copy(M,2,2) = #0#$AE)
    then
     begin
      Detect := True;
      ArcFile.Seek(ArcPos);
      Exit;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure TBSAArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : BSAHdr;
    Q    : Array [1..40] of Char absolute P;
    S    : String;
    C    : Char;
    label 1;
begin
1:
 if ArcFile.GetPos = ArcFile.GetSize then begin FileInfo.Last := 1; Exit;end;
 ArcFile.Read(P, 4);
 if (Copy(P.ID,1,2) = #0#0)
  then begin FileInfo.Last := 1;Exit;end;
 if (ArcFile.Status <> stOK) or not ((P.ID[4] in [#0,#7]) and (Copy(P.ID,2,2) = #0#$AE))
  then begin FileInfo.Last := 2;Exit;end;
 ArcFile.Read(P.PackedSize, Sizeof(P)-4);
 if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date  := P.Date{P.Date shl 16) or (P.Date shr 16)};
 i := 1;
 S[0] := Char(P.NameLen);
 ArcFile.Read(S[1], P.NameLen and 255);
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := CDir + S;
 FP := ArcFile.GetPos;
 ArcFile.Seek(FP + P.PackedSize + 1);
end;


{ ----------------------------- BS2 ------------------------------------}

constructor TBS2Archive.Init;
begin
  TObject.Init;
  Packer    := NewStr('BS2.EXE');
  UnPacker  := NewStr('BS2.EXE');
  Extract   := NewStr('-xy');
  ExtractWP := NewStr('-xy');
  Add       := NewStr('-ar');
  Move      := NewStr('-am');
  Delete    := NewStr('-D');
  Garble    := NewStr('-xg');
  Test      := NewStr('-t');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function TBS2Archive.GetID;
begin
  GetID := arcBS2;
end;

function TBS2Archive.GetSign;
begin
  GetSign := 'BS2:';
end;

type
     BSA2Hdr = record
      Unknown: Array [1..12] of Char;
      ID: Array [1..4] of Char;
      Date: LongInt;
      OriginSize: LongInt;
      PackedSize: LongInt;
      Data: Array[1..4] of Byte;
      NameLen: Byte;
     end;

Function TBS2Archive.Detect: Boolean;
label 1;
var
    M: Array[1..4] of Char;
    C: Char;
    L: LongInt;
    S: String;
begin
 Detect:=False;
 ArcFile.Read(M, 4);
 if (ArcFile.Status = stOK) and (M = #$D4#$03'SB')
    then
     begin
      Detect := True;
      ArcFile.Seek(ArcPos);
      Exit;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure TBS2Archive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : BSA2Hdr;
    Q    : Array [1..40] of Char absolute P;
    S    : String;
    C    : Char;
    label 1;
begin
1:
 ArcFile.Read(P, 6);
{ if (Copy(P.ID,1,2) = #0#0)
  then begin FileInfo.Last := 1;Exit;end;}
 if (ArcFile.Status <> stOK)  then begin FileInfo.Last := 2;Exit;end;
 FP := ArcFile.GetPos;
 if FP = ArcFile.GetSize then
  begin FileInfo.Last := 1; Exit;end;
 ArcFile.Read(P.Unknown[7], Sizeof(P)-6);
 if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date  := P.Date{P.Date shl 16) or (P.Date shr 16)};
 i := 1;
 S[0] := Char(P.NameLen);
 ArcFile.Read(S[1], P.NameLen and 255);
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := CDir + S;
 FP := ArcFile.GetPos;
 ArcFile.Seek(FP + P.PackedSize);
end;


{ ----------------------------- HYP ------------------------------------}

constructor THYPArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('HYPER.EXE');
  UnPacker  := NewStr('HYPER.EXE');
  Extract   := NewStr('-xo');
  ExtractWP := NewStr('-xo');
  Add       := NewStr('-a');
  Move      := NewStr('-m');
  Delete    := NewStr('-D');
  Garble    := NewStr(' ');
  Test      := NewStr(' ');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function THYPArchive.GetID;
begin
  GetID := arcHYP;
end;

function THYPArchive.GetSign;
begin
  GetSign := 'HYP:';
end;

type
     HYPHdr = record
      ID: Array [1..4] of Char;
      PackedSize: LongInt;
      OriginSize: LongInt;
      Date: LongInt;
      Data: Array[1..4] of Byte;
      Attr: Byte;
      NameLen: Byte;
     end;

Function THYPArchive.Detect;
label 1;
var
    M: Array[1..4] of Char;
    C: Char;
    L: LongInt;
    S: String;
begin
 Detect:=False;
 ArcFile.Read(M, 4);
 if (ArcFile.Status = stOK) and
    ((M = ^Z'HP%') OR (M = ^Z'ST%'))
    then
     begin
      Detect := True;
      ArcFile.Seek(ArcPos);
      Exit;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure THYPArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : HYPHdr;
    Q    : Array [1..40] of Char absolute P;
    S    : String;
    C    : Char;
    label 1;
begin
1:
 FP := ArcFile.GetPos;
 if FP = ArcFile.GetSize then begin FileInfo.Last := 1; Exit;end;
 ArcFile.Read(P, 4);
 if (Copy(P.ID,1,2) = #0#0)
  then begin FileInfo.Last := 1;Exit;end;
 if (ArcFile.Status <> stOK) or ((P.ID <> ^Z'HP%') and (P.ID <> ^Z'ST%'))
  then begin FileInfo.Last := 2;Exit;end;
 ArcFile.Read(P.PackedSize, Sizeof(P)-4);
 if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date  := P.Date{P.Date shl 16) or (P.Date shr 16)};
 i := 1;
 S[0] := Char(P.NameLen);
 ArcFile.Read(S[1], P.NameLen and 255);
 While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := S;
 FP := ArcFile.GetPos;
 ArcFile.Seek(FP + P.PackedSize);
end;


{ ----------------------------- LIM ------------------------------------}

constructor TLIMArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('LIMIT.EXE');
  UnPacker  := NewStr('LIMIT.EXE');
  Extract   := NewStr('e');
  ExtractWP := NewStr('e -p');
  Add       := NewStr('a');
  Move      := NewStr('a');
  Delete    := NewStr('Del');
  Garble    := NewStr(' ');
  Test      := NewStr('t');
  ListChar  := '@';
  PutTempBefore := 2;
  Swap := True;
end;

function TLIMArchive.GetID;
begin
  GetID := arcLIM;
end;

function TLIMArchive.GetSign;
begin
  GetSign := 'LIM:';
end;

type
     LIMHdr = record
      ID: Array [1..2] of Char;
      Method: Byte;
      ThreeZeros: Array [1..3] of Byte;
      Date: LongInt;
      ThreeSym: Array [1..3] of Byte;
      OriginSize: LongInt;
      PackedSize: LongInt;
      Data: Array[1..4] of Byte;
     end;

Function TLIMArchive.Detect: Boolean;
label 1;
var
    M: Array[1..8] of Char;
    C: Char;
    L: LongInt;
    S: String;
begin
 Detect:=False;
 ArcFile.Read(M, 8);
 if (ArcFile.Status = stOK) and (Copy(M,1,5) = 'LM'#26#8#0)
    then
     begin
      ArcFile.Read(M, 7);
      if Copy(M, 6, 2) = '#ñ' then
       begin
        Detect := True;
        CDir := '';
        ArcFile.Seek(ArcPos+13);
        Exit;
       end;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure TLIMArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : LIMHdr;
    Q    : Array [1..40] of Char absolute P;
    S    : String;
    C    : Char;
    label 1;
begin
1:
 ArcFile.Read(P, 4);
 if (ArcFile.Status = stOK) and (P.ID = #$13#$F8) and (P.Method = 5)
  then begin FileInfo.Last := 1;Exit;end;
 if (ArcFile.Status = stOK) and (P.ID = #$80#$D1)
  then
   begin
    FileInfo.Last := 0;
    i := 1; S := ''; C := #1;
    While (I < 80) and (C <> #0) and not Abort and (ArcFile.Status = stOK) do
     begin ArcFile.Read(C, 1); if C <> #0 then S := S + C; Inc(I); end;
     CDir := S;
    Goto 1;
   end;
 if (ArcFile.Status <> stOK) or (P.ID <> '#ñ')
  then begin FileInfo.Last := 2;Exit;end;
 ArcFile.Read(P.ThreeZeros[2], Sizeof(P)-4);
 if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
 {if (P.Method > 20) then begin FileInfo.Last:=2;Exit;end;}
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 FileInfo.USize := P.OriginSize;
 FileInfo.PSize := P.PackedSize;
 FileInfo.Date  := P.Date{P.Date shl 16) or (P.Date shr 16)};
 i := 1; S := '';
 C := #1;
 While (I < 80) and (C <> #0) and not Abort and (ArcFile.Status = stOK) do
  begin ArcFile.Read(C, 1); if C <> #0 then S := S + C; Inc(I); end;
  While Pos('/', S) > 0 do S[Pos('/', S)] := '\';
 While Pos(#255, S) > 0 do S[Pos(#255, S)] := '\';
 FileInfo.FName := CDir + '\' + S;
 if P.ThreeZeros[3] and Directory <> 0 then Goto 1;
 FP := ArcFile.GetPos;
 ArcFile.Seek(FP + P.PackedSize);
end;


{ ----------------------------- HPK ------------------------------------}

constructor THPKArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('HPACK.EXE');
  UnPacker  := NewStr('HPACK.EXE');
  Extract   := NewStr('X');
  ExtractWP := NewStr('X');
  Add       := NewStr('A');
  Move      := NewStr('A');
  Delete    := NewStr('D');
  Garble    := NewStr('-C');
  Test      := NewStr('T');
  ListChar  := '@';
  PutTempBefore := 2;
  Swap := True;
end;

function THPKArchive.GetID;
begin
  GetID := arcHPK;
end;

function THPKArchive.GetSign;
begin
  GetSign := 'HPK:';
end;

type
     PHPKRec = ^THPKRec;
     THPKRec = record
      PSize, USize: LongInt;
      Date: LongInt;
      Name: PString;
     end;

     PHPKCollection = ^THPKCollection;
     THPKCollection = object(TCollection)
      procedure FreeItem(P: Pointer); virtual;
     end;

var HPKCol : PHPKCollection;

procedure THPKCollection.FreeItem(P: Pointer);
begin
 if P <> nil then
  begin DisposeStr(PHPKRec(P)^.Name); Dispose(PHPKRec(P)); end;
end;

Function THPKArchive.Detect: Boolean;
label 1;
var
    M: Array[1..4] of Char;
    C: Char;
    L,J,I: LongInt;
    W: Word;
    B: Byte;
    S: String;
    P: Record NumFiles, Margin: LongInt; I,n,f: Byte; S: Array[1..4] of Char; end;
    R: PHPKRec;

  function GetLong(Num4: Boolean): LongInt;
   var A: LongInt;
       R: Record A1, A2, A3, A4: Byte end;
  begin
   ArcFile.Read(R, 2 + 2*Byte(Num4));
   if Num4 then A := LongInt(R.A1) shl 24 + LongInt(R.A2) shl 16 +
                     LongInt(R.A3) shl 8 + LongInt(R.A4)
           else A := R.A1 * 256 + R.A2;
   GetLong := A;
  end;

begin
 Detect:=False;
 ArcFile.Read(M, 4);
 if (ArcFile.Status = stOK) and (M = 'HPAK')
    then
     begin
      ArcFile.Seek(ArcFile.GetSize - SizeOf(P));
      P.NumFiles := GetLong(On);
      P.Margin := GetLong(On);
      ArcFile.Read(P.I,7);
      if P.S = 'HPAK' then
       begin
        ArcFile.Seek(ArcFile.GetSize - SizeOf(P) - P.Margin);
        Detect := True;
        New(HPKCol, Init(P.NumFiles,10));
        for I := 1 to P.NumFiles do
         begin
          New(R); R^.Name := nil;
          ArcFile.Read(W,2);
          if W and $10 <> 0 then ArcFile.Read(J,2);
          R^.Date := GetLong(On);
          R^.USize := GetLong(W and $0080 <> 0);
          R^.PSize := GetLong(W and $0040 <> 0);
          HPKCol^.Insert(R);
         end;
        for I := 0 to P.NumFiles - 1 do
         begin
          S := '';
          repeat ArcFile.Read(C, 1); if C <> #0 then S := S + C until C = #0;
          PHPKRec(HPKCol^.At(I))^.Name := NewStr(S);
         end;
        Exit;
       end;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure THPKArchive.GetFile;
var HS,i : Word;
    DT: DateTime;
    R: PHPKRec;
begin
 if HPKCol^.Count = 0 then begin FileInfo.Last := 1; Dispose(HPKCol, Done); Exit; end;
 FileInfo.USize := PHPKRec(HPKCol^.At(0))^.USize;
 FileInfo.PSize := PHPKRec(HPKCol^.At(0))^.PSize;
 GetUNIXDate(PHPKRec(HPKCol^.At(0))^.Date, DT.Year, DT.Month, DT.Day, DT.Hour, DT.Min, DT.Sec);
 PackTime(DT, FileInfo.Date);
 if PHPKRec(HPKCol^.At(0))^.Name <> nil then
   FileInfo.FName := PHPKRec(HPKCol^.At(0))^.Name^ else FileInfo.FName := '';
 FileInfo.Last := 0;
 FileInfo.Attr := 0;
 HPKCol^.AtFree(0);
end;


{ ----------------------------- RAR ------------------------------------}

constructor TRARArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('RAR.EXE');
  UnPacker  := NewStr('RAR.EXE');
  Extract   := NewStr('e');
  ExtractWP := NewStr('x');
  Add       := NewStr('a');
  Move      := NewStr('m');
  Delete    := NewStr('d');
  Garble    := NewStr('-p');
  Test      := NewStr('t');
  IncludePaths := NewStr('');
  ExcludePaths := NewStr('-ep');
  ListChar  := '@';
  PutTempBefore := 2;
  Swap := True;
end;

function TRARArchive.GetID;
begin
  GetID := arcRAR;
end;

function TRARArchive.GetSign;
begin
  GetSign := 'RAR:';
end;

type
     MainRARHdr = record
      ID: Array [1..4] of Char;
      HeadLen: Word;
      HeadFlags: Byte;
     end;

     MainRAR2Hdr = record
       HeadCRC: Word;
       HeadType: Byte;
       HeadFlags: Word;
       HeadLen: Word;
       Reserved1: Word;
       Reserved2: LongInt;
     end;


var RAR2: Boolean;

Function TRARArchive.Detect: Boolean;
label 1;
var
    M2: MainRAR2Hdr;
    K: Array[1..7] of Char absolute M2;
    M: MainRARHdr absolute M2;
    C: Char;
    L: LongInt;
    S: String;
begin
 RAR2 := Off;
 Detect:=False;
 L := ArcFile.GetPos;
 ArcFile.Read(K, SizeOf(K));
 if (ArcFile.Status = stOK) and (M.ID = #$52#$45#$7E#$5E)
    then
     begin
      Detect := True;
      ArcFile.Seek(L + M.HeadLen);
      Exit;
     end;
 if (ArcFile.Status = stOK) and (K = #$52#$61#$72#$21#$1A#$07#$00)
    then
     begin
      RAR2 := On;
      ArcFile.Read(M2, SizeOf(M2));
      if M2.HeadType <> $73 then Goto 1;
      ArcFile.Seek(ArcFile.GetPos + M2.HeadLen - SizeOf(M2));
      Detect := True;
      Exit;
     end;
1:ArcFile.Seek(ArcPos);
end;

type
     LocRarHdr = record
       PSize: LongInt;
       USize: LongInt;
       CRC: Word;
       HdrLen: Word;
       Date: LongInt;
       Attr: Byte;
       Flags: Byte;
       Ver: Byte;
       NameLen: Byte;
       Method: Byte;
       CommLen: Word;
     end;

     LocRar2Hdr = record
       HeadCRC: Word;
       HeadType: Byte;
       HeadFlags: Word;
       HeadSize: Word;
       PSize: LongInt;
       USize: LongInt;
       OSVer: Byte;
       CRC: LongInt;
       Date: LongInt;
       Ver: Byte;
       Method: Byte;
       NameLen: Word;
       Attr: LongInt;
     end;

Procedure TRARArchive.GetFile;
var HS,i : Word;
    FP   : Longint;
    P    : LocRARHdr;
    P2   : LocRAR2Hdr;
    Q    : Array [1..40] of Char absolute P;
    S    : String;
    C    : Char;
    Ps   : Integer;
    label 1;
begin
1: if (ArcFile.GetPos = ArcFile.GetSize) or (ArcFile.GetPos = 0) then
     begin FileInfo.Last := 1; Exit end;
   if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
   if RAR2 then begin
      FP := ArcFile.GetPos;
      ArcFile.Read(P2, 7);
      if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
      if P2.HeadType = $74 then
       begin
         ArcFile.Read(P2.PSize, SizeOf(P2)-7);
         if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
         FileInfo.Last := 0;
         FileInfo.Date := P2.Date;
         FileInfo.PSize := P2.PSize;
         FileInfo.USize := P2.USize;
         FileInfo.Attr := Byte(P2.HeadFlags and $04 <> 0);
         if P2.NameLen > 250 then P2.NameLen := 250;
         ArcFile.Read(S[1], P2.NameLen); S[0] :=Char(P2.NameLen);
         repeat
           Ps := System.Pos('.\', S);
           if Ps = 0 then Break;
           System.Delete(S, Ps, 1);
         until False;
         if P2.Attr and Directory <> 0 then S := S + '\';
         if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit;end;
         FileInfo.FName := S;
         ArcFile.Seek(FP+P2.HeadSize+P2.PSize);
         Exit;
       end;
      if P2.HeadSize = 0 then P2.HeadSize := 7;
      if P2.HeadFlags and $8000 <> 0 then begin ArcFile.Read(FP, 4); Arcfile.Seek(Arcfile.GetPos-4) end
         else FP := 0;
      ArcFile.Seek(ArcFile.GetPos + FP + P2.HeadSize - 7);
      Goto 1;
    end else begin
      ArcFile.Read(P, SizeOf(P)-2);
      if (ArcFile.Status <> stOK) or (P.NameLen = 0) then begin FileInfo.Last := 2;Exit;end;
      FileInfo.Last := 0;
      FileInfo.Date := P.Date;
      FileInfo.PSize := P.PSize;
      FileInfo.USize := P.USize;
      FileInfo.Attr := Byte(P.Flags and $04 <> 0);
      if P.Flags and $08 <> 0 then
       begin
        {ArcFile.Read(P, P.CommLen);}
        ArcFile.Seek(ArcFile.GetPos + P.CommLen);
        if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit; end;
       end;
      Arcfile.Read(S[1], P.NameLen);
      if (ArcFile.Status <> stOK) then begin FileInfo.Last := 2;Exit; end;
      S[0] := Char(P.NameLen);
      FileInfo.FName := S;
      if P.Attr and Directory <> 0 then FileInfo.FName := S + '\';
      FP := ArcFile.GetPos;
      ArcFile.Seek(FP + P.PSize);
   end;
end;


{ ----------------------------- TAR ------------------------------------}

constructor TTARArchive.Init;
begin
  TObject.Init;
  Packer    := NewStr('TAR.EXE');
  UnPacker  := NewStr('TAR.EXE');
  Extract   := NewStr('xf');
  ExtractWP := NewStr('xf');
  Add       := NewStr('cayf');
  Move      := NewStr('cayf');
  Delete    := NewStr('df');
  Garble    := NewStr(' ');
  Test      := NewStr('tf');
  ListChar  := ' ';
  PutTempBefore := 2;
  Swap := True;
end;

function TTARArchive.GetID;
begin
  GetID := arcTAR;
end;

function TTARArchive.GetSign;
begin
  GetSign := 'TAR:';
end;

const MaxTName = 100;
      Txt_Word = 8;
      Txt_Long = 12;
      BLKSIZE  = 512;

type
     TARHdr = record
       FName: Array[1..MaxTName] of Char;
       Mode:  Array[1..TXT_WORD] of Char;
       uid:   Array[1..TXT_WORD] of Char;
       gid:   Array[1..TXT_WORD] of Char;
       size:  Array[1..TXT_LONG] of Char;
       mtime: Array[1..TXT_LONG] of Char;
       chksum: Array[1..TXT_WORD] of Char;
       filetype: Char;
       linkname: Array[1..MAXTNAME] of Char;
       case Byte of
        0: (
            (* old-fashion data & padding *)
             comment: Array[1..BLKSIZE-MAXTNAME-8-8-8-12-12-8-1-MAXTNAME-12-12] of Char;
             srcsum: Array[1..TXT_LONG] of Char;
             srclen: Array[1..TXT_LONG] of Char;
          );
        1: (
             (* System V extensions *)
             extent: Array[1..4] of Char;
             allext: Array[1..4] of Char;
             total: Array[1..TXT_LONG] of Char;
            );
         2: (
            (* P1003 & GNU extensions *)
             magic: Array[1..8] of Char;
             uname: Array[1..32] of Char;
             gname: Array[1..32] of Char;
             devmajor: Array[1..TXT_WORD] of Char;
             devminor: Array[1..TXT_WORD] of Char;
             (* the following fields are added gnu and NOT standard *)
             atime: Array[1..12] of Char;
             ctime: Array[1..12] of Char;
             offset: Array[1..12] of Char;
            );
     end;

Function TTARArchive.Detect: Boolean;
 var Dr: DirStr;
     Nm: NameStr;
     Xt: ExtStr;
begin
 Detect:=False;
 FSplit(ArcFileName, Dr, Nm, Xt);
 Detect := Xt = '.TAR';
 ArcFile.Seek(ArcPos);
end;

function FromOct(S: String): LongInt;
 var I,L: LongInt;
     A: Real;
begin
  L := 0;
  for I := 0 to Length(S)-1 do
      Inc(L, (Byte(S[Length(S)-I])-48) shl (I * 3));
  FromOct := L;
end;

Procedure TTARArchive.GetFile;
  var S: String;
      Buffer: Array [0..BlkSize - 1] of Char;
      Hdr: TARHdr absolute Buffer;
      DT: DateTime;
      R: Real;
      I: Integer;
      L: LongInt;
begin
  L := ArcFile.GetPos;
  if ArcFile.GetPos = ArcFile.GetSize then
     begin FileInfo.Last := 1; Exit end;
  ArcFile.Read(Buffer, BlkSize);
  if ArcFile.Status <> stOK then
     begin FileInfo.Last := 2; Exit end;
  FileInfo.Last := 0;
  S := Hdr.FName + #0; Byte(S[0]) := PosChar(#0, S)-1;
  if S = '' then begin FileInfo.Last := 1; Exit end;
  Replace('/', '\', S);
  if Copy(S,1,2) = '.\' then System.Delete(S,1,2);
  FileInfo.FName := S;
  S := Hdr.Size;
  FileInfo.USize := FromOct(DelSpaces(S));
  FileInfo.PSize := FileInfo.USize;
  S := Hdr.mTime;
  GetUNIXDate(FromOct(DelSpaces(S)), DT.Year, DT.Month, DT.Day, DT.Hour, DT.Min, DT.Sec);
  PackTime(DT, FileInfo.Date);
  L := (FileInfo.PSize div LongInt(BlkSize)) + Byte(FileInfo.PSize mod LongInt(BlkSize) <> 0);
  L := L * BlkSize;
  ArcFile.Seek(ArcFile.GetPos + L);
end;


{ ----------------------------- UC2 ------------------------------------}

constructor TUC2Archive.Init;
begin
  TObject.Init;
  Packer    := NewStr('UC.EXE');
  UnPacker  := NewStr('UC.EXE');
  Extract   := NewStr('E');
  ExtractWP := NewStr('ES');
  Add       := NewStr('A');
  Move      := NewStr('M');
  Delete    := NewStr('D');
  Garble    := NewStr('');
  Test      := NewStr('T');
  IncludePaths      := NewStr('-S');
  ExcludePaths      := NewStr('');
  ForceMode         := NewStr('-F');
  NormalCompression := NewStr('-TN');
  FastCompression   := NewStr('-TF');
  UltraCompression  := NewStr('-TST');
  ListChar  := '@';
  PutTempBefore := 2;
  Swap := True;
end;

function TUC2Archive.GetID;
begin
  GetID := arcUC2;
end;

function TUC2Archive.GetSign;
begin
  GetSign := 'UC2:';
end;

Function TUC2Archive.Detect: Boolean;
label 1;
var
    M: Array[1..4] of Char;
    B: Boolean;
    F: Text;
begin
 Detect:=False;
 ArcFile.Read(M, 4);
 if (ArcFile.Status = stOK) and (M = 'UC2'#26) then
     begin
        Detect:= True;
        Exit;
     end;
1:ArcFile.Seek(ArcPos);
end;

Procedure TUC2Archive.GetFile;
 var S: String;
     P: PView;
begin
  S := UNPACKER^+' ~D '+ArcFileName+' >'+MakeNormName(TempDir,'!!!DN!!!.TMP');
  if PReader <> nil then PReader^.Free;
  P := WriteMsg(' '+GetString(dlPleaseStandBy));
  if UserScreen <> nil then InsertUserSaver(Off);
  TempFile := '[UC2:'+MakeNormName(TempDir,'!!!DN!!!.TMP')+']'+ArcFileName;
  LocateCursor(0,0);
  StartupData.Unload := StartupData.Unload or osuBlinking;
  {P^.Free;}
  Message(Application, evCommand, cmExecString, @S);
  FileInfo.Last := 1;
end;

constructor TUserSaver.Init;
 var R: TRect;
begin
  R.Assign(0,0,0,0);
  inherited Init(R);
  CheckIO := ACheck;
  SetState(sfVisible, Off);
  isValid := On;
  Screen := MemAlloc(UserScreenSize);
  if Screen = nil then Fail;
  Move(UserScreen^, Screen^, UserScreenSize);
  ClsAct := Off;
  SSize := UserScreenSize;
  SWidth := UserScreenWidth;
  CShape := OldCursorShape;
  CPos := OldCursorPos;
end;

function TUserSaver.Valid; begin Valid := isValid end;

constructor TUserSaver.Load;
 var I: Byte;
begin
  inherited Load(S);
  S.Read(SSize, 4*SizeOf(Integer)+SizeOf(Boolean));
  if UserScreen = nil then FreeMem(UserScreen, UserScreenSize);
  UserScreenSize := SSize;
  UserScreenWidth := SWidth;
  UserScreen := MemAlloc(SSize);
  OldCursorShape := CShape;
  OldCursorPos := CPos;
  S.Read(UserScreen^, SSize);
  Screen := nil;
  isValid := False;
  I := 0;
  if CheckIO then
    asm
      mov ax, $9900
      int 2Fh
      cmp bx, 'DN'
      jne @@1
      mov I, cl
    @@1:
    end;
  if I <> 0 then Msg(dlErrorsOccurred, nil, mfWarning+mfOKButton);
end;

destructor TUserSaver.Done;
begin
  if Screen <> nil then FreeMem(Screen, SSize);
  inherited Done;
end;

procedure TUserSaver.Store;
begin
  inherited Store(S);
  S.Write(SSize, 4*SizeOf(Integer)+SizeOf(Boolean));
  S.Write(Screen^, SSize);
end;

procedure UpdateARH;
var
  St: TBufStream;
begin
  St.Init( SourceDir + 'DN.ARH', stCreate, 2048);
  St.Put(Archives);
  St.Write(DefaultArchiver, 2);
  St.Write(DefaultArcMode, 2);
  St.Done;
end;

procedure LoadArchiveSet;
 var S: TBufStream;
     R: Set of Byte;
     Added: Boolean;

  function NotFindArc(ID: Integer): Boolean;
   var I: Integer;
  begin
    NotFindArc := Off;
    for I := 0 to Archives^.Count - 1 do
        if PARJArchive(Archives^.At(I))^.GetID = ID then Exit;
    Added := On;
    NotFindArc := On;
  end;

begin
 if Archives = nil then
  begin
   S.Init( SourceDir + 'DN.ARH', stOpen, 2048);
   if S.Status = stOK then
   begin
     Archives := PSortedCollection(S.Get);
     S.Read(DefaultArchiver, 2);
     S.Read(DefaultArcMode, 2);
   end;
   S.Done;
   if Archives <> nil then CurrentArchive := Archives^.At(0);
  end else Exit;
  if Archives = nil then
   begin
      Archives := New(PArchiveCollection, Init(10,10));
      Archives^.Insert(New(PARJArchive, Init));
      Archives^.Insert(New(PARCArchive, Init));
      Archives^.Insert(New(PZIPArchive, Init));
      Archives^.Insert(New(PHAPArchive, Init));
      Archives^.Insert(New(PSQZArchive, Init));
      Archives^.Insert(New(PLHAArchive, Init));
      Archives^.Insert(New(PLIMArchive, Init));
      Archives^.Insert(New(PHYPArchive, Init));
      Archives^.Insert(New(PHAArchive, Init));
      Archives^.Insert(New(PZOOArchive, Init));
      Archives^.Insert(New(PRARArchive, Init));
      Archives^.Insert(New(PUC2Archive, Init));
      Archives^.Insert(New(PBSAArchive, Init));
      Archives^.Insert(New(PBS2Archive, Init));
      Archives^.Insert(New(PCHZArchive, Init));
      Archives^.Insert(New(PHPKArchive, Init));
      Archives^.Insert(New(PTARArchive, Init));
      CurrentArchive := Archives^.At(0);
   end
      {
      else
        begin
          Added := Off;
          if NotFindArc(arcTAR) then Archives^.Insert(New(PTARArchive, Init));
          if Added then UpdateARH;
        end;
      }
end;

function DetectArchive;
  function FindArc(P: PARJArchive): Boolean; far;
  begin
    FindArc := P^.Detect;
  end;
begin
 LoadArchiveSet;
 ArcFile.Seek(ArcPos);
 DetectArchive := nil;
 if Archives <> nil then DetectArchive := Archives^.FirstThat(@FindArc);
end;


function ArchiveFiles;

  var Arc: PARJArchive;
      AID: Word;
      I: Integer;
      C: String[10];

  function FindNeed(P: PARJArchive): Boolean; far;
  begin
    FindNeed := P^.GetSign = C;
  end;

begin
  ArchiveFiles := Off;
  if PosChar(':',S) < 3 then Exit;
  LoadArchiveSet; if Archives = nil then Exit;
  C := UpStrg(Copy(S,1,PosChar(':', S)));
  Arc := Archives^.FirstThat(@FindNeed);
  if Arc = nil then Exit;
  DefaultArchiver := Arc^.GetID;
  ArchiveFiles := On;
  MakeArchive(Copy(S, PosChar(':',S)+1, 255), Files, MoveMode, Owner);
end;

procedure SetupArchive;
 var D: PDialog;
     P: PView;
     R: TRect;
     Arch: PARJArchive;
     W: Word;

    DT: record
          Pack : String[12]; {Inputline}
          Unpack : String[12]; {Inputline}
          Extract: String[20]; {Inputline}
          ExWP : String[20]; {Inputline}
          Add : String[20]; {Inputline}
          Move : String[20]; {Inputline}
          Delete : String[20]; {Inputline}
          Test : String[20]; {Inputline}
          Force : String[20]; {Inputline}
          IncludeP : String[20]; {Inputline}
          Password : String[20]; {Inputline}
          ExcludeP : String[20]; {Inputline}
          NormC : String[20]; {Inputline}
          FastC : String[20]; {Inputline}
          MaxC : String[20]; {Inputline}
          List: String[1];
          Options : Word; {Checkbox}
        end;

  function FindArchive(id: Integer): PARJArchive;
    function Find(P: PARJArchive): Boolean; far;
    begin
      Find := P^.GetID = id;
    end;
  begin
    FindArchive := Archives^.FirstThat(@Find);
  end;

  function ArcName(ArcN: Byte): string;

    var mi: PMenuItem;

    procedure Scroll(Count: Byte);
    var i: Byte; begin for i := 1 to Count do mi := mi^.Next end;

    var s: string;
        b: Byte;
  begin
    mi := MenuBar^.Menu^.Items; Scroll(6);
    mi := mi^.SubMenu^.Items; Scroll(2);
    mi := mi^.SubMenu^.Items; Scroll(ArcN);
    s := mi^.Name^;
    repeat b := PosChar('~', s); if b=0 then Break else Delete(s, b, 1) until False;
    b := PosChar('-', s); if b>0 then Delete(s, 1, b+1);
    ArcName := s;
  end;

  procedure CndRpl;
  var s: string;
  begin
   s := ArcName(ArchCommand);
   if Length(s)+Length(D^.Title^)+10 < D^.Size.X then s := D^.Title^+' - '+s;
   ReplaceP(D^.Title, s);
  end;

begin
 LoadArchiveSet;
 If ArchCommand >= cmLoConfigArchiver then Dec(ArchCommand, cmLoConfigArchiver);
 Arch := FindArchive(ArchCommand);
 if Arch = nil then Exit;
 with Arch^ do
  begin
    DT.Pack := CnvString(Packer);
    DT.Unpack := CnvString(Unpacker);
    DT.Extract := CnvString(Extract);
    DT.ExWP := CnvString(ExtractWP);
    DT.Add := CnvString(Add);
    DT.Move := CnvString(Move);
    DT.Test := CnvString(Test);
    DT.Delete := CnvString(Delete);
    DT.Password := CnvString(Garble);
    DT.Force := CnvString(ForceMode);
    DT.IncludeP := CnvString(IncludePaths);
    DT.ExcludeP := CnvString(ExcludePaths);
    DT.NormC := CnvString(NormalCompression);
    DT.FastC := CnvString(FastCompression);
    DT.MaxC := CnvString(UltraCompression);
    DT.List := ListChar;
    DT.Options := Byte(Swap);
  end;
 D := PDialog(Application^.ValidView(PDialog(LoadResource(dlgSetupArc))));
 if D = nil then Exit;
 D^.SetData(DT);
 CndRpl;
 W := Desktop^.ExecView(D);
 if W = cmOK then D^.GetData(DT);
 FreeObject(D);
 if W <> cmOK then Exit;
 with Arch^ do
  begin
     DefaultArchiver := ArchCommand;
     Packer := NewStr(DT.Pack);
     Unpacker := NewStr(DT.Unpack);
     Extract := NewStr(DT.Extract);
     ExtractWP := NewStr(DT.ExWP);
     Add := NewStr(DT.Add);
     Move := NewStr(DT.Move);
     Test := NewStr(DT.Test);
     Delete := NewStr(DT.Delete);
     Garble := NewStr(DT.Password);
     ForceMode := NewStr(DT.Force);
     IncludePaths := NewStr(DT.IncludeP);
     ExcludePaths := NewStr(DT.ExcludeP);
     NormalCompression := NewStr(DT.NormC);
     FastCompression := NewStr(DT.FastC);
     UltraCompression := NewStr(DT.MaxC);
     if DT.List <> '' then ListChar := DT.List[1] else ListChar := ' ';
     Byte(Swap) := DT.Options;
  end;
  UpdateARH;
end;

procedure ReadArcList;
 const
   FuckName = 'U$~RESLT.OK';
 var S: String;
     ID: String[4];
     P: PArcFile;
     SR: SearchRec;
     CurDir: String;
     PC: PDirStorage;
     F: PTextReader;
     DT: DateTime;
     I, J, K: Integer;
     Drv: PArcDrive;
 label 1;
begin
 S := TempFile; ID := Copy(S,1,3); Delete(S, 1, 4);
 I := PosChar(']', S); ArcFileName := Copy(S, I+1, 255);
 S[0] := Char(I-1); ClrIO;
 TempFile := '';
 if ID = 'UC2' then
   begin

     if not ExistFile(FuckName) then
      begin
        MessageBox(GetString(dlArcMsg6),NIL,mfOkButton or mfError);
        Exit;
      end;
     EraseFile(FuckName);
     GetDir(0, CurDir);
     GlobalMessage(evCommand, cmRereadDir, @CurDir);
     F := New(PTextReader, Init(S));
     if F = nil then Exit;
     P := nil;
     New(PC, Init);
     While not F^.EOF do
      begin
        S := F^.GetStr;
        DelLeft(S); DelRight(S);
        ID := Copy(S, 1, 4);
        if ID = 'LIST' then
          begin
            I := PosChar('[', S); if I = 0 then Continue;
            Delete(S, 1, I); I := PosChar(']',S);
            if I < 2 then Continue;
            S[0] := Char(I-1);
            CurDir := S;
          end else
           if (ID = 'FILE') or (ID = 'DIR') then
            begin
              if P <> nil then
                begin
                  PackTime(DT, P^.Date);
                  PC^.AddFile(P^.FName^, P^.USize, P^.PSize, P^.Date, P^.Attr);
                  DisposeStr(P^.FName); Dispose(P);
                end;
              New(P);
              P^.FName := nil;
              if ID = 'DIR' then begin P^.Attr := Directory; P^.PSize := 0; P^.USize := 0 end else P^.Attr := 0;
            end else
             if ID = 'END' then
                begin
                 if P <> nil then
                   begin
                     PackTime(DT, P^.Date);
                     PC^.AddFile(P^.FName^, P^.USize, P^.PSize, P^.Date, P^.Attr);
                     DisposeStr(P^.FName); Dispose(P);
                   end;
                 Break
                end else
             begin
               I := PosChar('=', S);
               if I = 0 then Goto 1;
               Delete(S, 1, I);
               if Id = 'NAME' then
                begin
                  I := PosChar('[', S); if I = 0 then Continue;
                  Delete(S, 1, I); I := PosChar(']',S);
                  if I < 2 then Continue;
                  S[0] := Char(I-1);
                  if P^.Attr = Directory then S := S + '\';
                  P^.Attr := 0;
                  P^.FName := NewStr(CurDir + S);
                end else
               if Id = 'DATE' then
                begin
                  DT.Month := StoI(Copy(S,1,2));
                  DT.Day := StoI(Copy(S,4,2));
                  DT.Year := StoI(Copy(S,7,4));
                end else
               if Id = 'TIME' then
                begin
                  DT.Hour := StoI(Copy(S,1,2));
                  DT.Min := StoI(Copy(S,4,2));
                  DT.Sec := StoI(Copy(S,7,4));
                end else
               if Id = 'ATTR' then
                begin
                end else
               if Id = 'SIZE' then
                begin
                  P^.USize := StoI(S);
                  P^.PSize := StoI(S);
                end else
               if Id = 'VERS' then
                begin
                end;
             end;
       1:
      end;
     S := F^.FileName;
     Dispose(F, Done);
     EraseFile(S);
     GlobalMessage(evCommand, cmRereadDir, @TempDir);
     if PC^.Files = 0 then Dispose(PC, Done) else
      begin
        New(Drv, InitCol(PC, ArcFileName));
        if Message(Application, evBroadcast, cmFindForced, Drv) = nil then
        if Message(Application, evCommand, cmInsertDrive, Drv) = nil then
           begin
           end;
      end;
   end;
end;

procedure MakeArchive;

   var
     AID: Word;
     C: String[40];
     CurDir: PathStr;
     Arc: PARJArchive;
     D : record
       Name : String[79];
       Password : String[40];
       Add : String[40];
       Options : Word;
       Archiver : Word;
       Mode : Word;
     end;



  function FindID(P: PARJArchive): Boolean; far;
  begin
    FindID := P^.GetID = AID;
  end;

  function MakeListFile: String;
   var F: Text;
       PF: PFileRec;
       I: Integer;
       S, S1: String[120];
       B: Boolean;

    procedure PutDir(const SS: String);
     var I: Integer;
         S1: String[120];
         SR: SearchRec;
    begin
       ClrIO;
       if B then S := S + ' ' + SS else WriteLn(F, SS);
       ClrIO;
       FindFirst(MakeNormName(SS, x_x), $FF XOR VolumeID, SR);
       While (DOSError = 0) and not Abort and (S[0] < #100) do
        begin
         S1 := UpStrg(MakeNormName(SS,SR.Name));
         if Copy(S1, 1, length(CurDir)) = CurDir then
            Delete(S1, 1, Length(CurDir));
         if (SR.Attr and (Directory + VolumeID) = 0) then
           if B then S := S + ' ' + S1
                else WriteLn(F, S1);
         if (SR.Attr and Directory <> 0) and (SR.Name[1] <> '.') then
            PutDir(MakeNormName(SS,SR.Name));
         DOSError := 0;
         FindNext(SR);
        end;
    end;

  begin
   B := Arc^.ListChar = ' ';
   if B then S := '' else
    begin
     S := SwpDir + '$$$DN$$$.LST';
     Assign(F, S); ClrIO;
     Rewrite(F);
     B := IOResult <> 0;
     if B then S := '' else S := Arc^.ListChar + S;
    end;
   for I := 0 to Files^.Count - 1 do
    begin
     PF := Files^.At(I);
     S1 := UpStrg(MakeNormName(PF^.Owner^, MakeFileName(PF^.Name)));
     if Copy(S1, 1, length(CurDir)) = CurDir then
       Delete(S1, 1, Length(CurDir));
     if PF^.Attr and Directory = 0 then {S1 := S1 + '\*.*';}
     if B then S := S + ' ' + S1 else WriteLn(F, S1)
          else PutDir(S1);
     MakeListFile := S;
     if S[0] > #100 then Exit;
    end;
   MakeListFile := S;
   if not B then Close(F);
  end;

  procedure Unselect(PF: PFileRec); far;
  begin
    Message(Owner, evCommand, cmCopyUnselect, PF);
  end;

  function AddString(P: PString): String;
  begin
   if P = nil then AddString := '' else
    begin
      if Copy(P^,1,1) = '+' then
       if Copy(P^,1,2) <> '++' then AddString := Copy(P^,2,255)
                               else AddString := ' '+Copy(P^,2,255)
       else AddString := ' '+P^;
    end;
  end;

begin
  LoadArchiveSet;
  FillChar(D, SizeOf(D), 0);
  D.Name := S;
  D.Archiver := DefaultArchiver;
  D.Options := (DefaultArcMode shr 8) and not 2 or (Byte(MoveMode)*2);
  D.Mode := DefaultArcMode and 255;
  repeat
    if ExecResource(dlgArchiveFiles, D) <> cmOK then Exit;
    AID := (D.Mode and 255) or (D.Options shl 8);
    if (D.Archiver <> DefaultArchiver) or (AID <> DefaultArcMode) then
     begin
       DefaultArchiver := D.Archiver;
       DefaultArcMode := AID;
       UpdateARH;
     end;
    S := '';
  until (D.Password = '') or
        (ExecResource(dlgReenterPassword, S) = cmOK) and (S = D.Password);
  AID := D.Archiver;
  Arc := Archives^.FirstThat(@FindID);
  if Arc = nil then Exit;
  GetDir(0, CurDir);
  if Abort then Exit;
  if CurDir[Length(CurDir)] <> '\' then CurDir := CurDir + '\';
  {C := AddOptions; if C = '' then Exit;}
  if D.Options and 2 = 2 then C := CnvString(Arc^.Move)
                         else C := CnvString(Arc^.Add);
  if D.Options and 1 = 0 then C := C + AddString(Arc^.ExcludePaths)
                         else C := C + AddString(Arc^.IncludePaths);
  if D.Options and 3 <> 0 then C := C + AddString(Arc^.ForceMode);
  if D.Mode = 0 then C := C + AddString(Arc^.NormalCompression) else
  if D.Mode = 1 then C := C + AddString(Arc^.FastCompression) else
  if D.Mode = 2 then C := C + AddString(Arc^.UltraCompression);


  if D.Password <> '' then C := C + ' '+CnvString(Arc^.Garble)+D.Password;

  S := C + ' ' + D.Add + ' ' + D.Name + ' ' + MakeListFile;
  S := CnvString(Arc^.Packer) + ' ' + S;
  DelDoubles('  ', S);
  GlobalMessage(evCommand, cmMakeForced, nil);
  if Owner <> nil then Files^.ForEach(@Unselect);
  Message(Application, evCommand, cmExecString, @S);
end;

procedure UnarchiveFiles;
  var AType: PARJArchive;
      S: String;
      DT: Record S: String[70]; W: Word; Psw: String[30]; end;
      ExtrDir: PathStr;
      ExtrChar: String[10];
      Dr: DirStr;
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
   FSplit(UpStrg(FName), Dr, Nm, Xt);
   ArcFileName := FName;
   ArcFile.Init(FName, stOpenRead, 512);
   if ArcFile.Status <> stOK then
    begin
      if TempFile <> '' then TEMPFile := '';
      StdMsg(4); ArcFile.Done; Abort := On; Exit;
    end;
   ArcPos := 0;
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
   ArcFile.Done;
   if AType = nil then Exit;
   ExtrDir := '';
   DT.S := '';
   DT.Psw := '';
   DT.W := 1;
   Message(Application, evCommand, cmPushFullName, @DT.S);
   if CopyDirName <> '' then DT.S := CopyDirName;
   if DT.S = cTEMP_ then DT.S := '';
   if DT.S = '' then GlobalMessage(evCommand, cmPushName, Pointer(hsExtract));
   if DT.S = '' then DT.S := HistoryStr(hsExtract, 0);
   if DT.S = cTEMP_ then DT.S := '';
   if (DT.S[0] > #3) and (DT.S[Length(DT.S)] <> '\') then DT.S := DT.S + '\';
   CopyDirName := '';
   if ExecResource( dlgExtract, DT) <> cmOK then Exit;
   if (DT.S = '') or (DT.S = '.') then DT.S := GetPath(FName);
   CreateDirInheritance(DT.S, On);
   ExtrDir := DT.S;
   ExtrChar := CnvString(AType^.ExtractWP);
   if DT.W and 1 = 0 then ExtrChar := CnvString(AType^.Extract);
   if DT.W and 2 <> 0 then ExtrChar := CnvString(AType^.Test);
   S := '';
   if DT.Psw <> '' then S := S + ' ' + DelSpaces(CnvString(AType^.Garble) + DT.Psw) + ' ';
   S := CnvString(AType^.unPacker)+' '+ExtrChar+' '+s+FName;
   System.GetDir(0, DirToChange);
   Advance.ChDir(ExtrDir);
   DelDoubles('  ', S);

   Message(Application, evCommand, cmExecString, @S);
   Advance.ChDir(DirToChange); DirToChange := '';

   {Password := DT.Psw;
   ExtractFiles(AFiles, ExtrDir, Own, DT.W);}
end;

procedure InsertUserSaver;
begin
  Desktop^.Insert(New(PUserSaver, Init(ACheck)));
  FreeMem(UserScreen, UserScreenSize);
  UserScreenSize := ScreenWidth*ScreenHeight*2;
  UserScreenWidth := ScreenWidth;
  OldCursorPos := 0; OldCursorShape := $FFFF;
  HideMouse;
  GetMem(UserScreen, UserScreenSize);
  System.Move(ScreenBuffer^, UserScreen^, UserScreenSize);
  ShowMouse;
end;


end.