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

unit Drives;

interface
uses Dos, Objects, Memory, Views, Drivers, FilesCol, DiskInfo,
     FStorage, Advance, ObjType;

const
     FBoxDir: PathStr = '';

     dsActive      = 0 ;
     dsInvalid     = 1 ;

type
  PDrive = ^TDrive;
  TDrive = object(TObject)
   Owner: Pointer;
   Prev: PDrive;
   DriveType: ( dtUndefined, dtDisk, dtFind, dtTemp, dtList, dtArc, dtLink,  dtArvid );
   CurDir: PathStr;
   DIZOwner: PathStr;
   NoMemory: Boolean;
   Flags: Word;
   constructor Init(ADrive: Byte; AOwner: Pointer; AFlags: Integer);
   constructor Load(var S: TStream);
   procedure Store(var S: TStream);
   procedure KillUse; virtual;
   procedure ChDir(ADir: PathStr); virtual;
   function GetDir: PathStr; virtual;
   function GetDirectory(SortMode, PanelFlags: Integer; const FileMask: String;
                         var FreeSpace, TotalInfo: String ): PCollection; virtual;
   procedure CopyFiles(Files: PCollection; Own: PView; MoveMode: Boolean); virtual;
   procedure CopyFilesInto(Files: PCollection; Own: PView; MoveMode: Boolean); virtual;
   procedure EraseFiles(Files: PCollection); virtual;
   procedure UseFile(P: PFileRec; Command: Word); virtual;
   procedure GetFreeSpace(var S: String); virtual;
   function Disposable: Boolean; virtual;
   function GetRealName: String; virtual;
   procedure GetFull(var B; P: PFileRec; C, AFlags: Word); virtual;
   procedure GetEmpty(var B; C, AFlags: Word); virtual;
   function CalcLength(AFlags: Word): Integer; virtual;
   procedure RereadDirectory(S: PathStr); virtual;
   procedure MakeTop(var S: String; AFlags: Word); virtual;
   procedure GetDown(var B; C: Word; P: PFileRec); virtual;
   procedure HandleCommand(Command: Word; InfoPtr: Pointer); virtual;
   procedure GetDirInfo(var B: TDiskInfoRec); virtual;
   function GetRealDir: String; virtual;
   procedure MakeDir; virtual;
   function isUp: Boolean; virtual;
   procedure ChangeUp(var S: String); virtual;
   procedure ChangeRoot; virtual;
   function GetFullFlags: Word; virtual;
   procedure EditDescription(PF: PFileRec); virtual;
   procedure GetDirLength(PF: PFileRec); virtual;
   destructor Done; virtual;
  end;

procedure RereadDirectory(Dir: String);
function CalcTotalInfo(A, B: Word; C: TSize): string;
function GetFilesColl(
    var TotalLen: TSize;
    var TFiles: Word;
    PanelFlags: Integer;
    CurDir: PString;
    const FileMask: string;
    Owner: Pointer;
    SortMode: Integer
    ): PFilesCollection;


const
  TempDirs: PSortedCollection = nil;
  TempFiles: PDirStorage = nil;

  RDrive: TStreamRec = (
    ObjType: otDrive;
    VmtLink: Ofs(TypeOf(TDrive)^);
    Load: @TDrive.Load;
    Store: @TDrive.Store);

implementation
uses Startup, Tree, DNApp, RStrings, FileCopy, Eraser,
     FlPanel, Commands, Dialogs, FileFind, FlPanelX;

type
       PDesc = ^TDesc;
       TDesc = record
         Name: String[12];
         DIZ: PString;
         Line: LongInt;
       end;

       PDIZCol = ^TDIZCol;
       TDIZCol = object(TSortedCollection)
         procedure FreeItem(P: Pointer); virtual;
         function Compare(P1, P2: Pointer): Integer; virtual;
       end;

procedure TDIZCol.FreeItem;
begin
 if P <> nil then
  begin
    DisposeStr(PDesc(P)^.DIZ);
    Dispose(PDesc(P));
  end;
end;

function TDIZCol.Compare;
begin
  if PDesc(P1)^.Name < PDesc(P2)^.Name then Compare := -1 else
    if PDesc(P1)^.Name = PDesc(P2)^.Name then Compare := 0 else
     Compare := 1;
end;

procedure TDrive.GetFreeSpace;
 var FreeSpc: TSize;
begin
 FreeSpc := Disk_Free(Byte(CurDir[1])-64);
 S := '~'+FStr(FreeSpc)+GetString(dlDIFreeDisk)+Copy(CurDir, 1, 2);
end;

constructor TDrive.Init;
begin
 TObject.Init;
 Owner := AOwner;
 if AFlags = -1 then Flags := ColumnsDefaults.DiskDrive else Flags := AFlags;
 ClrIO;
 System.GetDir(ADrive, CurDir);
 DriveType := dtDisk;
 NoMemory := False;
end;

constructor TDrive.Load(var S: TStream);
begin
 Prev := PDrive(S.Get);
 S.Read(CurDir[0], 1);
 S.Read(CurDir[1], Length(CurDir));
 S.Read(Flags, SizeOf(Flags));
 DriveType := dtDisk;
 NoMemory := False;
end;

procedure TDrive.Store(var S: TStream);
begin
 S.Put(Prev);
 S.Write(CurDir, Length(CurDir)+1);
 S.Write(Flags, SizeOf(Flags));
end;

destructor TDrive.Done;
begin
 if Prev <> nil then Dispose(Prev, Done);
 inherited Done;
end;

function TDrive.Disposable;
begin
 Disposable := On;
end;

procedure TDrive.ChangeUp;
begin
 ChDir(MakeNormName(CurDir,'..'));
 if Abort then Exit;
 System.GetDir(0, CurDir);
 if Abort then Exit;
 S := '';
end;

procedure TDrive.ChangeRoot;
begin
 ChDir(Copy(CurDir,1,2) + '\');
 if Abort then Exit;
 System.GetDir(0, CurDir);
 if Abort then Exit;
end;

function TDrive.CalcLength;
 var B: Word;
begin
 B := 13 +
      (10 + CountryInfo.TimeFmt) * Byte(AFlags and psShowSize <> 0) +
      9 * Byte(AFlags and psShowDate <> 0) +
      (7 - CountryInfo.TimeFmt) * Byte(AFlags and psShowTime <> 0);
 if AFlags and psShowDescript <> 0 then CalcLength := MaxViewWidth
                                   else CalcLength := B;
end;

procedure TDrive.MakeTop;
begin
 S := GetString(dlTopName);
 if AFlags and psShowSize <> 0 then S := S + Copy(GetString(dlTopSize),2-CountryInfo.TimeFmt, 255);
 if AFlags and psShowDate <> 0 then S := S + GetString(dlTopDate);
 if AFlags and psShowTime <> 0 then S := S + Copy(' '+GetString(dlTopTime), 1+CountryInfo.TimeFmt, 255);
 if AFlags and psShowDescript <> 0 then S := S+' '+GetString(dlPnlDescription)+' '+Strg(#32,255);
end;

procedure TDrive.GetFull;
 var S: String;
     S1: String[40];
     X: Byte;
begin
  if (P^.Size > 0) or (P^.Attr and Directory = 0) or (P^.Attr and $80 <> 0)
     and (P^.Size >= 0)
    then S := FileSizeStr( P^.Size )
    else if P^.Name[1]= '.'
      then S := GetString( dlUpDir )
      else S := GetString( dlSubDir );
  MakeDate(DateMode, P^.Day, P^.Month, P^.Yr, P^.Hour, P^.Minute, S1);
  MoveStr(TWordArray(B), P^.Name, C);
  if AFlags and psShowSize <> 0 then
   begin
    MoveStr(TWordArray(B)[22 - Length(S) + CountryInfo.TimeFmt], S, C);
    X := 23 + CountryInfo.TimeFmt;
   end else X := 13;
  if AFlags and psShowDate <> 0 then
   begin
    MoveStr(TWordArray(B)[X], Copy(S1,1,8), C);
    Inc(X, 9);
   end;
  if AFlags and psShowTime <> 0 then
   begin
    MoveStr(TWordArray(B)[X], Copy(S1,10,6-CountryInfo.TimeFmt), C);
    Inc(X, 7 - CountryInfo.TimeFmt);
   end;
  if (AFlags and psShowDescript <> 0) and ((DriveType = dtDisk) or
     (DriveType = dtArvid)) then
   begin
    if P^.Diz <> nil then S := Copy(CnvString(P^.DIZ^.DIZ), 1, MaxViewWidth - X - 1) else S := '';
    MoveStr(TWordArray(B)[X], S, C);
    Inc(X, 6);
   end;
end;

procedure TDrive.GetEmpty;
 var
     X: Byte;
begin
  C := C and $0FFF;
  if AFlags and psShowSize <> 0 then
   begin
    TWordArray(B)[22 + CountryInfo.TimeFmt] := (TWordArray(B)[23] and $F000) or C;
    X := 23 + CountryInfo.TimeFmt
   end else X := 13;
  if AFlags and psShowDate <> 0 then
   begin
    TWordArray(B)[X+8] := (TWordArray(B)[X+8] and $F000) or C;
    Inc(X, 9);
   end;
  if AFlags and psShowTime <> 0 then
   begin
    TWordArray(B)[X+6 - CountryInfo.TimeFmt] := (TWordArray(B)[X+6 - CountryInfo.TimeFmt] and $F000) or C;
    Inc(X, 7 - CountryInfo.TimeFmt);
   end;
  TWordArray(B)[12] := (TWordArray(B)[12] and $F000) or C;
end;

procedure TDrive.EraseFiles;
begin
 if Disposable then Eraser.EraseFiles(Files);
end;

procedure TDrive.MakeDir;
begin
 MakeDirectory;
end;

procedure TDrive.CopyFiles;
begin
 if Disposable then FileCopy.CopyFiles(Files, Own, MoveMode, 2*Byte(TypeOf(Self)=TypeOf(TFindDrive)));
end;

procedure TDrive.CopyFilesInto;
begin
 FileCopy.CopyFiles(Files, Own, MoveMode, 0);
end;

procedure TDrive.ChDir;
begin
 ClrIO;
 System.ChDir(ADir);
 if Abort then Exit;
 System.GetDir(0, ADir);
 if Abort then Exit;
 CurDir := ADir;
end;

function TDrive.GetDir;
begin
 GetDir := CurDir;
end;

procedure TDrive.UseFile;
 var S: String;
begin
 S := MakeNormName(P^.Owner^,MakeFileName(P^.Name));
 Message(Application, evCommand, Command, @S);
end;

procedure ReadFileList(
     const CurDir: PathStr;
     const FName: Str12;
     var Descriptions: PDIZCol);

var T: PTextReader;
    S: String;
    S1: Str12;
    I: Integer;
    CurLine: LongInt;
    PD: PDesc;
begin
  ClrIO;
  T := New(PTextReader, Init(MakeNormName(CurDir, FName)));
  if (T = nil) or Abort then Exit;
  CurLine := 0;
  While not T^.EOF and (IOResult = 0) do
    begin
      Inc(CurLine);
      S := T^.GetStr;
      DelLeft(S);
      S1 := '';
      if S <> '' then
       begin
         While (S1[0] < #12) and (S[1] <> ' ') do
           begin S1 := S1 + S[1]; DelFC(S) end;
         DelLeft(S);
         New(PD);
         PD^.Name := LowStrg(Norm12(S1));
         PD^.Name[9] := ' ';
         PD^.DIZ := NewStr(S);
         PD^.Line := CurLine;
         if not Descriptions^.Search(PD, I) then
            Descriptions^.AtInsert(I, PD)
         else
            Descriptions^.FreeItem(PD);
       end;
    end;
  Dispose(T, Done);
end;

procedure PrepareDIZ(
        const CurDir: string;
        var DIZOwner: string;
        var Descriptions: PDIZCol);
var
  S: String;
  FName: Str12;
begin
  ClrIO;
  S := GetDizOwner(CurDir, '', On);
  if S <> '' then
     begin
       FName := GetName(S);
       Descriptions := New(PDIZCol, Init(300,300));
       ReadFileList(CurDir, FName, Descriptions);
       DIZOwner := MakeNormName(CurDir,FName);
     end;
  ClrIO;
end;

procedure TossDescriptions(
    PDizOwner: Pointer;
    Files: PFilesCollection;
    Descriptions: PDIZCol);
var
  I, J: Integer;
  P: PFileRec;
  FName: Str12;
  PD: PDesc;
begin
 for I := 1 to Files^.Count do
  begin
    P := Files^.At(I-1);
    FName := P^.Name;
    if P^.Attr and (Directory+SysFile) <> 0 then LowStr(FName);
    if Descriptions^.Search(@FName, J) then begin
                                        PD := PDesc(Descriptions^.At(J));
                                        New(P^.DIZ);
                                        P^.DIZ^.DIZ := PD^.DIZ;
                                        P^.DIZ^.Owner := PDIZOwner;
                                        P^.DIZ^.Line := PD^.Line;
                                        P^.DIZ^.isDisposable := On;
                                        PD^.DIZ := nil;
                                       end
                                  else P^.DIZ := nil;
  end;
end;


function GetFilesColl;
var
  Files: PFilesCollection;
  SR: SearchRec;
  AllFiles: Boolean;
  P: PFileRec;
  L: LongInt;
begin
  AllFiles := FileMask = x_x;
  Files := New(PFilesCollection, Init($10, $20));
  PFilesCollection(Files)^.Owner := Owner;
  PFilesCollection(Files)^.SortMode := SortMode;
  FindFirst(MakeNormName(CurDir^,x_x), $FF xor VolumeID, SR);
  While (DosError = 0) and not Abort and (IOResult = 0) and MemOK do
  begin
   if (SR.Attr and VolumeID = 0) and (SR.Name <> '.') then
    if (SR.Name[1] = '.') or (not Security or (Security and (SR.Attr and Hidden=0))) then
    if AllFiles or (SR.Attr and Directory <> 0) or (InFilter(SR.Name, FileMask)) then
    if (SR.Attr and Directory = 0) or
       (SR.Name[1] <> '.') or
       (CurDir^[0]>#3) then
    begin
      P := NewFileRec(SR.Name, SR.Size, SR.Time, SR.Attr, CurDir);
      if SR.Attr and Directory = 0 then
       begin
        TotalLen := TotalLen + P^.Size;
        Inc(TFiles);
       end else
       begin
         if PanelFlags and fmiDirLen <> 0 then
          begin
            if SR.Name[1] = '.' then P^.Size := GetDirLen(CurDir^)
                                else P^.Size := GetDirLen(MakeNormName(CurDir^,SR.Name));
            if Abort then begin PanelFlags := PanelFlags and not fmiDirLen end;
            ClrIO;
          end;
        end;
      if SortMode = -1 then with Files^ do AtInsert(Count, P)
       else Files^.Insert(P);
    end;
   DosError := 0;
   FindNext(SR);
  end;
  if (CurDir^[0] > #3) and ((Files^.Count=0) or (MakeFileName(PFileRec(Files^.At(0))^.Name) <> '..')) then
  begin
    if PanelFlags and fmiDirLen <> 0 then
    begin
      L := GetDirLen(CurDir^); if Abort then L := 0;
      ClrIO;
    end else L := 0;
    Files^.Insert(NewFileRec('..',L,0,Directory,CurDir));
  end;
  GetFilesColl := Files;
end;

function TDrive.GetDirectory;
 var Files: PFilesCollection;
     SR: SearchRec;
     P: PFileRec;
     I,J: Integer;
     AllFiles, ShowD: Boolean;
     FreeSpc, TotalLen: TSize;
     TFiles: Word;
     Descriptions: PDIZCol;

  function Get32(S: ExtStr): LongInt;
   var I, J, K: LongInt;
  begin
    J := 0;
    for I := Length(S) downto 1 do
     begin
       if (S[I] >= '0') and (S[I] <= '9') then K := Byte(S[I])-48
                                          else K := Byte(S[I])-55;
       Inc(J, K * LongInt(1 shl (5*(Length(S)-I))));
     end;
     Get32 := J;
  end;

begin
 ClrIO;
 TFiles := 0; DOSError := 0; TotalLen := 0;
 DIZOwner := ''; FreeSpace := ''; TotalInfo := '';
 Descriptions := nil;
 Abort := Off;
 ShowD := (Flags and psShowDescript <> 0);

 if ShowD then PrepareDIZ(CurDir, DIZOwner, Descriptions);

 Files := GetFilesColl(TotalLen, TFiles, PanelFlags, @CurDir, FileMask, Owner, SortMode);

 NoMemory := not MemOK;

 TotalInfo := CalcTotalInfo(Files^.Count, TFiles, TotalLen);

 if PanelFlags and fmiFree <> 0 then GetFreeSpace(FreeSpace);

 if Descriptions <> nil then
 begin
   TossDescriptions(@DizOwner, Files, Descriptions);
   FreeObject(Descriptions)
 end;
 GetDirectory := Files;
end;

function TDrive.isUp;
begin
 isUp := False;
end;

procedure TDrive.RereadDirectory;
begin
 if Prev <> nil then Prev^.RereadDirectory(S);
end;

procedure TDrive.GetDirInfo;
begin
  ReadDiskInfo(CurDir, B, Flags);
end;

procedure TDrive.KillUse;
begin
 if Prev <> nil then Prev^.KillUse;
end;

procedure TDrive.GetDown;
 var FR: TFileRec;
     S,S1: String[80];
begin
    FR := P^; FR.Name[9] := ' ';
    if (FR.Attr and Directory = 0) or (FR.Attr and $80 <> 0) and (FR.Size >= 0)
    or (PFilePanel(Owner)^.PanelFlags and fmiDirLen <> 0)
     {or (FR.Size >= 0)}
      then S := FileSizeStr( FR.Size )
      else if FR.Name[1]= '.'
        then S := GetString( dlUpDir )
        else S := GetString( dlSubDir );
    MakeDate(DateMode, FR.Day, FR.Month, FR.Yr, FR.Hour, FR.Minute, S1);
    MoveStr(B, MakeFileName(FR.Name), C);
    MoveStr(TWordArray(B)[22-Length(S)+CountryInfo.TimeFmt],S , C);
    MoveStr(TWordArray(B)[23+CountryInfo.TimeFmt],S1, C);
end;

function TDrive.GetRealName;
begin
 GetRealName := GetDir;
end;

function TDrive.GetRealDir;
 var S: String;
     C: Char;
     D: PDialog;
var MM: record
         case byte of
          1: (L: LongInt; S: String[1]);
          2: (C: Char);
        end;
begin
 if DriveType = dtDisk then
  begin
   C := GetCurDrive;
   if C = CurDir[1] then
    begin
      ClrIO;
      NeedAbort := On;
      System.GetDir(0,S); if Abort then S := CurrentDirectory;
      NeedAbort := On; System.ChDir(CurDir);
      repeat
       Abort := Off; NeedAbort := On;
       System.GetDir(0, CurDir);
       if Abort then
        begin
         repeat
           MM.L := 0; MM.C := GetCurDrive; MM.S := MM.C;
           D := PDialog(LoadResource(dlgDiskError));
           if D <> nil then
            begin
             D^.SetData(MM);
             Application^.ExecView(D);
             D^.GetData(MM);
             Dispose(D, Done);
            end;
           UpStr(MM.S);
           if ValidDrive(MM.S[1]) then
            begin SetCurDrive(MM.S[1]); Break; end;
         until False;
         Abort := On;
        end;
      until not Abort;
      NeedAbort := Off;
      System.GetDir(0,CurDir);
      System.ChDir(S);
    end else
    begin
      System.ChDir(CurDir);
      if not Abort then
       repeat
        Abort := Off; NeedAbort := On;
        System.GetDir(0, CurDir);
        if Abort then
         begin
          repeat
            MM.L := 0; MM.C := GetCurDrive; MM.S := MM.C;
            D := PDialog(LoadResource(dlgDiskError));
            if D <> nil then
             begin
              D^.SetData(MM);
              Application^.ExecView(D);
              D^.GetData(MM);
              Dispose(D, Done);
             end;
            UpStr(MM.S);
            if ValidDrive(MM.S[1]) then
             begin SetCurDrive(MM.S[1]); Break; end;
          until False;
          Abort := On;
         end;
       until not Abort;
      SetCurDrive(C);
    end;
   GetRealDir := CurDir;
  end else GetRealDir := GetDir;
  NeedAbort := Off;
end;

procedure TDrive.HandleCommand;
begin
end;

function TDrive.GetFullFlags;
begin
 GetFullFlags := psShowSize + psShowDate + psShowTime;
end;

procedure TDrive.EditDescription;
begin
  if (DriveType = dtDisk) and (PF^.Name[1] <> '.') then
    SetDescription(PF, DIZOwner);
end;

procedure TDrive.GetDirLength(PF: PFileRec);
 var S: String;
     I, J: LongInt;
begin
  if (PF^.Attr and $80 <> 0) or (PF^.Attr and Directory = 0) then Exit;
  S := PF^.Owner^;
  if PF^.Name[1] <> '.' then S := MakeNormName(S, MakeFileName(PF^.Name));
  I := 1;
  PF^.Size := CountDirLen(S, On, I, Integer(J));
  if not Abort then PF^.Attr := PF^.Attr or $80;
end;

function CalcTotalInfo;
var
  S: string;
begin
 if A = 0 then S := GetString(dlDINoFiles)
  else begin
        S := GetString(dlTotal);
        if B = 1 then S := S+'1~ '+GetString(dlDIFile)
                            else S := S+ItoS(B)+'~ '+GetString(dlDIFiles);
        S := S + GetString(dlDIWith) + '~';
        if C = 1 then S := S + '1~ '+GetString(dlDIByte)
                        else S := S + FStr(C)+'~ '+GetString(dlDIBytes);
       end;
 CalcTotalInfo := S;
end;

procedure RereadDirectory;
 var Event: TEvent;

 procedure Action(View: PView); far;
 begin
  Event.What := evCommand; Event.Command := cmRereadDir;
  Event.InfoPtr := @Dir;
  View^.HandleEvent(Event);
 end;

begin
 Desktop^.ForEach(@Action);
end;

end.