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

unit Arvid;

interface
uses Advance, Objects, DOS, Drives, FilesCol, Views, DiskInfo, ObjType;

type
   TArvidHeader = record
      FileTableOfs: LongInt;
      DirTableOfs: LongInt;
      PosTableOfs: LongInt;

      FileTableLen: LongInt;
      DirTableLen: LongInt;
      PosTableLen: LongInt;

      TapeFmt: Word;
      TapeID: Word;
      TapeLen: Word;
      RecordLen: Word;
      NewRecordPos: LongInt;

      DescTableOfs: LongInt;
      Res01: Array [1..16] of Byte;
      DescTableLen: LongInt;
      Res02: Array [1..16] of Byte;
      NewRecSector: LongInt;
      Res03: Array [1..36] of Byte;
   end;

   PArvidFile = ^TArvidFile;
   TArvidFile = record
      Name: Array[1..11] of Char;
      Attr: Byte;
      StartSector: LongInt;
      Description: LongInt;
      Res: Word;
      Time: LongInt;
      Cluster: Word;
      Size: LongInt;
   end;

   TDirRecord = record
      Level: Word;
      Name: Array[1..11] of Char;
      Attr: Byte;
      StartSector: LongInt;
      Description: LongInt;
      Res: Word;
      Time: LongInt;
      Cluster: Word;
      Size: LongInt;

      Files: Word;
      LastFile: Word;
      NumFiles: Word;

   end;


   PArvidDrive = ^TArvidDrive;
   TArvidDrive = object(TDrive)
      D: TArvidHeader;
      Name: PString;
      Stream: PStream;
      CurFile: LongInt;
      CurDirPos: LongInt;
      CurFileNum: Word;
      CurLevel: Word;
      CurDate: LongInt;
      KillAfterUse: Boolean;
      constructor Init(const AName: String);
      procedure ChDir(ADir: PathStr); virtual;
      function GetDir: PathStr; virtual;
      function GetDirectory(SortMode, PanelFlags: Integer; const FileMask: String;
                            var FreeSpace, TotalInfo: String ): PCollection; virtual;
      constructor Load(var S: TStream);
      procedure Store(var S: TStream);
      procedure RereadDirectory(S: PathStr); virtual;
      procedure KillUse; virtual;
      procedure UseFile(P: PFileRec; Command: Word); virtual;
      procedure CopyFiles(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
      procedure CopyFilesInto(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
      procedure EraseFiles(AFiles: PCollection); virtual;
      function  GetRealName: String; virtual;
      procedure HandleCommand(Command: Word; InfoPtr: Pointer); virtual;
      procedure MakeDir; virtual;
      function  isUp: Boolean; virtual;
      procedure ChangeUp(var S: String); virtual;
      procedure ChangeRoot; virtual;
      procedure GetFreeSpace(var S: String); virtual;
      procedure GetDirInfo(var B: TDiskInfoRec); virtual;
      procedure EditDescription(PF: PFileRec); virtual;
      procedure GetDirLength(PF: PFileRec); virtual;
      destructor Done; virtual;
    private
      procedure SeekDirectory;
      procedure Kill;
   end;


const
  RArvidDrive: TStreamRec = (
    ObjType: otArvidDrive;
    VmtLink: Ofs(TypeOf(TArvidDrive)^);
    Load: @TArvidDrive.Load;
    Store: @TArvidDrive.Store);


implementation
uses FlPanel, Commands, Startup, DNApp, Drivers, Messages,
     Dialogs, Memory, FileFind, DnUtil;


constructor TArvidDrive.Init;
begin
  TObject.Init;
  Flags := ColumnsDefaults.Arvid;
  Stream := New(PBufStream, Init(AName, stOpenRead, 2048));
  if Stream^.Status <> stOK then begin Dispose(Stream, Done); Fail end;
  Stream^.Read(D, SizeOf(D));
  if Stream^.Status <> stOK then begin Dispose(Stream, Done); Fail end;
  Name := NewStr(Advance.FExpand(AName));
  DriveType := dtArvid;
  KillAfterUse := TempFile <> '';
  TempFile := '';
  CurDir := '\';
  SeekDirectory;
end;

procedure TArvidDrive.SeekDirectory;
 var
      I,J: LongInt;
      Lv: Integer;
      DD: TDirRecord;
      S: String;
      SS: String[12];
begin
  Stream^.Status := stOK;
  Stream^.Seek(D.DirTableOfs);
  Stream^.Read(DD, SizeOf(DD));
  CurDirPos := Stream^.GetPos;
  S := CurDir; CurLevel := 0; CurDir := ''; Lv := 1;
  if S[1] = '\' then DelFC(S);
  while S <> '' do
    begin
      SS := '';
      while (S[1] <> '\') and (S <> '') do
        begin
          AddStr(SS, S[1]);
          DelFC(S);
          if SS[0] = #12 then Break;
        end;
      DelFC(S);
      SS := Norm12(SS); UpStr(SS);
      Delete(SS, 9, 1);
      repeat
        Stream^.Read(DD, SizeOf(DD));
      until (UpStrg(Copy(DD.Name, 1, 11)) = SS) and (DD.Level = Lv) or (DD.Level < Lv);
      if (DD.Level < Lv) or (DD.Level = 0) then Break;
      Insert('.', SS, 9);
      if (CurDir[Length(CurDir)] <> '\') and
         (CurDir <> '') then AddStr(CurDir, '\');
      CurDir := CurDir + MakeFileName(SS);
      CurDirPos := Stream^.GetPos;
      CurLevel := Lv;
      Inc(Lv);
    end;

  CurDate := DD.Time;
  CurFile := DD.Files;
  CurFileNum := DD.NumFiles;

end;

procedure TArvidDrive.Kill;
begin
  if not KillAfterUse then Exit;
  if Stream <> nil then Dispose(Stream, Done); Stream := nil;
  EraseFile(Name^);
end;

function TArvidDrive.GetDirectory;
  var
      I, J, SeekPos, TotFiles: LongInt;
      TotLen: TSize;
      FF: TArvidFile;
      DD: TDirRecord;
      P: PString;
      FC: PFilesCollection;
      DT: DateTime;
      F: PFileRec;
      AllFiles, ShowD: Boolean;

  procedure AddFile;
  var
    S: Str12;
  begin
    S := FF.Name;
    Insert('.', S, 9);
    if not ((CurDir = '') and (FF.Attr and SysFile <> 0) and InMask(S, 'AVD?????.???')) and
       (AllFiles or (FF.Attr and Directory <> 0) or InFilter(S, FileMask)) then
        begin
          F := NewFileRec(S, FF.Size, FF.Time, FF.Attr, @CurDir);
          if ShowD then
          begin
            New(F^.DIZ);
            F^.DIZ^.Owner := nil;
            F^.DIZ^.isDisposable := On;
            F^.DIZ^.Line := SeekPos;
            if FF.Description <> 0 then
              begin
                 J := Stream^.GetPos;
                 Stream^.Seek(D.DescTableOfs+FF.Description-1);
                 Stream^.Read(FreeStr, 2);
                 Stream^.Read(FreeStr[1], Length(FreeStr));
                 Stream^.Seek(J);
                 F^.DIZ^.DIZ := NewStr(FreeStr);
              end else F^.DIZ^.DIZ := nil;
          end else F^.Diz := nil;

          if FF.Attr and Directory = 0 then
            begin
              Inc(TotFiles);
              TotLen := TotLen + FF.Size;
            end;

          FC^.Insert(F);
        end;

  end;

begin
  Stream^.Status := stOK;
  New(FC, Init($80, $40));
  FC^.SortMode := SortMode;

  GetFreeSpace(FreeSpace); TotalInfo := ''; TotFiles := 0; TotLen := 0;

  GetDirectory := FC;
  ShowD := (Flags and psShowDescript <> 0);
  AllFiles := FileMask = x_x;

  Stream^.Seek(CurDirPos);
  repeat
    SeekPos := Stream^.GetPos+2;
    Stream^.Read(DD, SizeOf(DD));
    if DD.Level = CurLevel+1 then
      begin
        Move(DD.Name, FF, SizeOf(FF));
        FF.Attr := FF.Attr or Directory;
        AddFile;
      end;
  until (DD.Level = 0) or (DD.Level <= CurLevel);

  Stream^.Status := stOK;
  Stream^.Seek(D.FileTableOfs + CurFile*SizeOf(TArvidFile));

  FC^.SetLimit(FC^.Count + CurFileNum);

  for I := 1 to CurFileNum do
    begin
      SeekPos := Stream^.GetPos;
      Stream^.Read(FF, SizeOf(FF));
      AddFile;
    end;

  if CurDir = '' then P := Name else P := @CurDir;

  TotalInfo := CalcTotalInfo(FC^.Count, TotFiles, TotLen);

  FC^.AtInsert(0, NewFileRec('..',0,CurDate,Directory,P));

end;

destructor TArvidDrive.Done;
begin
  if Stream <> nil then Dispose(Stream, Done);
  DisposeStr(Name);
  inherited Done;
end;

procedure TArvidDrive.ChDir;
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
 SeekDirectory;
 While (PosChar(CurDir[Length(CurDir)], ' .\') > 0) do Dec(CurDir[0]);
end;

function TArvidDrive.GetDir;
 var Dr: String;
     Nm,M: NameStr;
     Xt: ExtStr;
begin
 FSplit(Name^, Dr, Nm, Xt);
 GetDir := 'TDR:'+Nm+'\'+CurDir;
end;

constructor TArvidDrive.Load;
  label 1;
begin
  TObject.Init;
  inherited Load(S);
  DriveType := dtArvid;
  S.Read(KillAfterUse, 1);
  Name := S.ReadStr;
  Stream := New(PBufStream, Init(Name^, stOpenRead, 2048));
  if Stream^.Status <> stOK then
    begin
1:
      Dispose(Stream, Done);
      Done;
      Fail;
    end;
  Stream^.Read(D, SizeOf(D));
  if Stream^.Status <> stOK then Goto 1;
  SeekDirectory;
end;

procedure TArvidDrive.Store;
begin
  inherited Store(S);
  S.Write(KillAfterUse, 1);
  S.WriteStr(Name);
end;

procedure TArvidDrive.RereadDirectory;
begin
  if Prev <> nil then Prev^.RereadDirectory(S);
end;

procedure TArvidDrive.KillUse;
begin
  if Prev <> nil then Prev^.KillUse;
  Kill;
end;

procedure TArvidDrive.UseFile;
begin
end;

procedure TArvidDrive.CopyFiles;
begin
{ CopyFiles(AFiles: PCollection; Own: PView; MoveMode: Boolean); virtual;
  }
   asm
    mov ax,0
   end

end;

procedure TArvidDrive.CopyFilesInto;
begin
end;

procedure TArvidDrive.EraseFiles;
begin
end;

procedure TArvidDrive.MakeDir;
begin
end;

function TArvidDrive.isUp;
begin
  isUp := True;
end;

procedure TArvidDrive.ChangeUp;
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
   end;
  PFilePanel(Owner)^.Drive := Prev;
  Prev^.ChDir(Prev^.CurDir);
  if (Prev^.DriveType = dtDisk) and
     (PView(Owner)^.GetState(sfSelected+sfActive)) then
      ActivePanel := Owner;
  GlobalMessage(evCommand, cmRereadInfo, nil);
  Prev := nil;
  S := GetName(Name^);
  Kill;
  Dispose(PDrive(@Self), Done);
end;

procedure TArvidDrive.ChangeRoot;
begin
  CurDir := '';
  SeekDirectory;
end;

procedure TArvidDrive.GetFreeSpace;
  var M: LongInt;
      L: Array [1..2] of LongInt;
begin
  case D.TapeFmt of
    2,4: M := 100;
      else M := 200;
  end;

  L[1] := Max(0, (LongInt(D.TapeLen) - D.RecordLen) div 60); L[2] := (L[1] * 60 * M) div 1024;
  FormatStr(S, GetString(dlArvid_TimeLeft), L);
end;

function TArvidDrive.GetRealName;
begin
  GetRealName := 'TDR:'+Name^;
end;

procedure TArvidDrive.GetDirInfo;
  var L: Array [1..2] of LongInt;
      S,NF,Sz: LongInt;
      S1, S2: String[30];
begin
  B.Title := NewStr( GetString( dlArvid_Title ));
  FreeStr := GetName(Name^); FreeStr[0] := Char(PosChar('.', FreeStr)-1);
  B.Dir := NewStr(FreeStr);

  Case D.TapeFmt of
    2: begin S := 100; B.VolumeID := NewStr(GetString(dlArvid_Type)+'~100~ Kb/s, CRC-16') end;
    4: begin S := 100; B.VolumeID := NewStr(GetString(dlArvid_Type)+'~100~ Kb/s, CRC-32') end;
    8: begin S := 100; B.VolumeID := NewStr(GetString(dlArvid_Type)+'~200~ Kb/s, CRC-32') end;
  end;

  Sz := D.RecordLen * S;
  Nf := D.FileTableLen div SizeOf(TArvidFile);

  if NF = 0 then B.Files := NewStr(GetString(dlDINoFiles))
   else
    begin
     if NF = 1 then S1 := GetString(dlDIFile) else S1 := GetString(dlDIFiles);
     S2 := GetString(dlDIBytes);
     B.Files := NewStr('~'+FStr(NF)+'~ '+S1+GetString(dlDIWith)+'~'+FStr(Sz)+'~K '+S2);
    end;

  L[1] := LongInt(D.TapeLen) div 60; L[2] := (D.TapeLen * S) div 1024;
  FormatStr(FreeStr, GetString(dlArvid_TimeUsed), L);
  B.Total := NewStr( FreeStr );
  L[1] := Max(0, (LongInt(D.TapeLen) - D.RecordLen) div 60); L[2] := (L[1] * 60 * S) div 1024;
  FormatStr(FreeStr, GetString(dlArvid_TimeLeft), L);
  B.Free  := NewStr( FreeStr );

end;

procedure TArvidDrive.EditDescription;
  label 1;
  var S: String;
      I, J: LongInt;
      FF: TArvidFile;

   procedure ExpandStream;
     var B: Array [1..512] of Byte;
         I,J: LongInt;
         L: Word;
   begin
     J := Stream^.GetSize;
     repeat
       I := J-512;
       if I < D.PosTableOfs then I := D.PosTableOfs;
       L := J - I;
       Stream^.Seek(I);
       Stream^.Read(B, L);
       Stream^.Seek(I+512);
       Stream^.Write(B, L);
       J := I;
     until J <= D.PosTableOfs;
     FillChar(B, 512, 0);
     Stream^.Seek(I);
     Stream^.Write(B, 512);
     Inc(D.PosTableOfs, 512);
   end;

var
   RealAttr, Attrb: Word;

procedure GetAttr;
var F: file; begin Assign(F, Name^); GetFAttr(F, Attrb) end;

procedure SetAttr(A: Word);
var F: file; begin Assign(F, Name^); SetFAttr(F, A) end;

procedure Err;
begin CantWrite(Name^) end;

begin
  if (PF^.DIZ = nil) then Exit;

  S := CnvString(PF^.Diz^.Diz);
  if InputBox(GetString(dlEditDesc),GetString(dl_D_escription), S, 255, hsEditDesc) <> cmOK then Exit;

  FreeObject(Stream); RealAttr := $FFFF;
  ClrIO; Abort := Off;
  GetAttr; if Attrb and ReadOnly <> 0 then
  begin
    SetAttr(Archive);
    if Abort or (IOResult <> 0 ) then begin Err; Goto 1 end;
    RealAttr := Attrb or Archive;
  end;

  Stream := New(PBufStream, Init(Name^, stOpen, 2048));
  if Abort or (Stream^.Status <> stOK) then begin Err; Goto 1 end;

  Stream^.Seek(PF^.DIZ^.Line);
  Stream^.Read(FF, SizeOf(FF));

  if Length(S) <= Length(CnvString(PF^.DIZ^.DIZ)) then
    begin
      if S = '' then
        begin
          FF.Description := 0;
          Stream^.Seek(PF^.DIZ^.Line);
          Stream^.Write(FF, SizeOf(FF));
        end else
        begin
          Stream^.Seek(D.DescTableOfs+FF.Description-1);
          Stream^.Write(S[0],1);
          I := 0;
          Stream^.Write(I, 1);
          Stream^.Write(S[1], Length(S));
        end;
      Goto 1;
    end else
    begin
      if D.PosTableOfs - D.DescTableOfs - D.DescTableLen < 2 + Length(S)
         then ExpandStream;
      FF.Description := D.DescTableLen;
      Stream^.Seek(PF^.DIZ^.Line);
      Stream^.Write(FF, SizeOf(FF));
      Inc(D.DescTableLen, Length(S)+2);
      Stream^.Seek(D.DescTableOfs+FF.Description-1);
      Stream^.Write(S[0],1);
      I := 0;
      Stream^.Write(I, 1);
      Stream^.Write(S[1], Length(S));
      Stream^.Seek(0);
      Stream^.Write(D, SizeOf(D));
    end;

1: ClrIO; Abort := False;
  FreeObject(Stream);
  if RealAttr <> $FFFF then SetAttr(RealAttr);
  Stream := New(PBufStream, Init(Name^, stOpenRead, 2048));
  if Owner <> nil then Message(Owner, evCommand, cmPanelReread, nil);
end;


type
     PFindObject = ^TFindObject;
     TFindObject = Object(TObject)
        Text: PString;
        TT: (ttTape, ttDir, ttFile);
        constructor Init(const S: String);
        function GetText: String; virtual;
        destructor Done; virtual;
     end;

     PFindDir = ^TFindDir;
     TFindDir = object(TFindObject)
        Pos: LongInt;
        constructor Init(const S: String; APos: LongInt);
        function GetText: String; virtual;
     end;

     PFindFile = ^TFindFile;
     TFindFile = object(TFindObject)
        Name: String[12];
        Size: LongInt;
        Time: LongInt;
        constructor Init(const S: String; ASize, ATime: LongInt);
        function GetText: String; virtual;
     end;

     PFindBox = ^TFindBox;
     TFindBox = object(TListBox)
        function GetText(Item: Integer; MaxLen: Integer): String; virtual;
        function IsSelected(Item: Integer): Boolean; virtual;
     end;

constructor TFindObject.Init;
begin
  inherited Init;
  Text := NewStr(S);
  TT := ttTape;
end;

function TFindObject.GetText;
begin
  GetText := GetString(dlArvid_TapeDir)+CnvString(Text);
end;

destructor TFindObject.Done;
begin
  DisposeStr(Text);
end;

constructor TFindDir.Init;
begin
   inherited Init(S);
   Pos := APos;
   TT := ttDir;
end;

function TFindDir.GetText;
begin
  GetText := GetString(dlDirectory)+' '+CnvString(Text);
end;

constructor TFindFile.Init;
begin
   inherited Init('');
   Name := S;
   Size := ASize;
   Time := ATime;
   TT := ttFile;
end;

function TFindFile.GetText;
  var DT: DateTime;
      S: String[30];
begin
  UnPackTime(Time, DT);
  MakeDate(DateMode, DT.Day, DT.Month, DT.Year mod 100, DT.Hour, DT.Min, S);
  GetText := '  '+AddSpace(Name, 13)+PredSpace(FStr(Size), 13)+' '+S;
end;


function TFindBox.GetText;
  var P: PFindObject;
begin
  P := List^.At(Item);
  if P <> nil then GetText := P^.GetText
              else GetText := '';
end;

function TFindBox.IsSelected;
  var P: PFindObject;
begin
  P := List^.At(Item);
  IsSelected := (P <> nil) and (P^.TT = ttTape);
end;


const
      FindList: PCollection = nil;


procedure TArvidDrive.HandleCommand;
  var DT: record
            Mask: String[80];
            Text: String[200];
            O: Word;
          end;
      SDesc: Boolean;
      P: PView;
      DateAfter,
      DateBefore,
      SizeGreat,
      SizeLess: LongInt;
      Attr: Byte;
      OOM: Boolean;

  label 1;

  procedure SearchInStream(St: PStream; var D: TArvidHeader; const Name: String);
    var Dr: PathStr;
        DD: TDirRecord;
        FF: TArvidFile;
        LP, I, J: LongInt;
        WasTape: Boolean;
        WasDir, Lv0: Boolean;
        LastLv: Integer;
        SS: String[12];

     procedure Add(P: Pointer);
     begin
       if FindList = nil then New(FindList, Init($100, $100));
       if OOM or (not MemOK) or (MaxAvail < (FindList^.Count+$200)*4) then
       begin
         FreeObject(P);
         OOM := True;
         Exit;
       end;
       if not WasTape then FindList^.Insert(New(PFindObject, Init(Name)));
       if not WasDir then FindList^.Insert(New(PFindDir, Init(Dr, LP)));
       WasTape := On; WasDir := On;
       FindList^.Insert(P);
     end;

  begin
    WasTape := Off; Lv0 := Off; LastLv := 0;
    Dr := '\';
    LP := D.DirTableOfs;
    repeat
      St^.Seek(LP);
      St^.Read(DD, SizeOf(DD));
      if DD.Level = 0 then
         if Lv0 then Break
                else Lv0 := On;
      SS := DD.Name; Insert('.', SS, 9);
      if DD.Level > LastLv then Dr := MakeNormName(Dr, MakeFileName(SS))
         else if DD.Level <= LastLv then
                begin
                  repeat
                    while (Dr[Length(Dr)] <> '\') and (Dr <> '') do Dec(Dr[0]);
                    if Dr <> '' then Dec(Dr[0]);
                    Dec(LastLv);
                  until DD.Level > LastLv;
                  if Dr = '' then Dr := '\';
                  Dr := MakeNormName(Dr, MakeFileName(SS))
                end;
      LastLv := DD.Level;
      WasDir := Off;
      if InSpaceFilter(SS, DT.Mask) then
        begin
          if SDesc and (DD.Description <> 0) then
             begin
               St^.Seek(D.DescTableOfs+DD.Description-1);
               St^.Read(FreeStr, 2);
               St^.Read(FreeStr[1], Length(FreeStr));
               FreeStr := UpCaseStr(FreeStr);
             end else FreeStr := '';
          if (not SDesc or (Pos(DT.Text, FreeStr) > 0)) and
                 ((DT.O and 1 =0) or
                  (FF.Time <= DateBefore) and  (FF.Time >= DateAfter) and
                  (FF.Size >= SizeGreat) and (FF.Size <=SizeLess) and
                  ((Attr = 0) or (FF.Attr and Attr <> 0))) then
              begin
                WasDir := On;
                Add(New(PFindDir, Init(Dr, LP)));
              end;
        end;
      if not OOM then
      begin
        St^.Seek(D.FileTableOfs + LongInt(DD.Files)*SizeOf(TArvidFile));
        for I := 1 to DD.NumFiles do
          begin
            St^.Read(FF, SizeOf(FF));
            SS := FF.Name; Insert('.', SS, 9);
            if InSpaceFilter(SS, DT.Mask) then
              begin
                if SDesc and (FF.Description <> 0) then
                   begin
                     J := St^.GetPos;
                     St^.Seek(D.DescTableOfs+FF.Description-1);
                     St^.Read(FreeStr, 2);
                     St^.Read(FreeStr[1], Length(FreeStr));
                     St^.Seek(J);
                     FreeStr := UpCaseStr(FreeStr);
                   end else FreeStr := '';
                if (not SDesc or (Pos(DT.Text, FreeStr) > 0)) and
                   ((DT.O and 1 =0) or
                    (FF.Time <= DateBefore) and  (FF.Time >= DateAfter) and
                    (FF.Size >= SizeGreat) and (FF.Size <=SizeLess) and
                    ((Attr = 0) or (FF.Attr and Attr <> 0)))
                 then
                    begin
                      Add(New(PFindFile, Init(MakeFileName(SS), FF.Size, FF.Time)));
                    end;
              end;
          end;
      end;
      Inc(LP, SizeOf(DD));
    until (LP > D.DirTableOfs + D.DirTableLen) or OOM;
    if OOM then Application^.OutOfMemory;
  end;

  procedure SearchInAllFiles;
    var SR: SearchRec;
        St: PBufStream;
        D: TArvidHeader;
  begin
    ClrIO;
    FindFirst(MakeNormName(GetPath(Name^), '*.TDR'), Archive+Byte(Security)*Hidden+ReadOnly+SysFile, SR);
    while (DOSError = 0) and not Abort and not LowMemory do
      begin
        New(St, Init(MakeNormName(GetPath(Name^), SR.Name), stOpenRead, 2048));
        if St^.Status = stOK then
          begin
            St^.Read(D, SizeOf(D));
            if St^.Status = stOK then SearchInStream(St, D, SR.Name);
          end;
        Dispose(St, Done);
        ClrIO;
        FindNext(SR);
      end;
  end;

  procedure ExecuteFindDialog;
    label 1;
    var D: PDialog;
        R: TRect;
        PL: PFindBox;
        P: PView;
        F: PFindObject;

      procedure DoCount(P: PFindObject); far;
      begin
        Inc(R.A.X, Byte(P^.TT = ttFile));
      end;

  begin

     D := PDialog(LoadResource(dlgArvidFindResults));
     if D = nil then Exit;

     R.Assign(58, 1, 59, 13);
     P := New(PScrollBar, Init(R));
     D^.Insert(P);

     R.Assign(2,1,58,13);
     New(PL, Init(R, 1, PScrollBar(P)));
     PL^.NewLisT(FindList);
     D^.Insert(PL);

     R.A.X := 0;
     if (FindList <> nil) then FindList^.ForEach(@DoCount);

     FreeStr := FStr(R.A.X) + GetString(dlFilesFound);
     R.Assign(1, 13, 1+Length(FreeStr), 14);
     P := New(PStaticText, Init(R, FreeStr));
     P^.Options := P^.Options or ofCenterX;
     D^.Insert(P);

     PL^.Select;
     R.A.X := Desktop^.ExecView(D);
     R.A.Y := PL^.Focused;

     PL^.List := nil;

     Dispose(D, Done);

     if R.A.X = cmNo then
       begin
         Dispose(FindList, Done);
         FindList := nil;
       end;

     if (R.A.X = cmOK) and (FindList <> nil) and (FindList^.Count > 0) then
       begin
         F := FindList^.At(R.A.Y);
         if F = nil then Exit;
         FreeStr := '';
         for R.B.X := R.A.Y downto 0 do
           begin
             F := FindList^.At(R.B.X);
             if (F^.TT = ttDir) and (FreeStr = '') then
                   FreeStr := CnvString(F^.Text);
             if (F^.TT = ttTape) then Break;
           end;
         if UpStrg(F^.Text^) <> UpStrg(GetName(Name^)) then
            begin
              Dispose(Stream, Done); Stream := nil;
              CurDir := FreeStr;
              FreeStr := MakeNormName(GetPath(Name^), F^.Text^);
              DisposeStr(Name);
              Name := NewStr(FreeStr);
              Stream := New(PBufStream, Init(FreeStr, stOpenRead, 2048));
              FreeStr := CurDir;
              CurDir := '';
              if Stream^.Status <> stOK then
                begin
1:
                  ChangeUp(FreeStr);
                  Exit;
                end;
              Stream^.Read(Self.D, SizeOf(Self.D));
              if Stream^.Status <> stOK then Goto 1;
            end;
         CurDir := FreeStr;
         if CurDir[1] = '\' then DelFC(CurDir);
         SeekDirectory;
         F := FindList^.At(R.A.Y);
         if F^.TT = ttFile then FreeStr := MakeNormName(FreeStr, PFindFile(F)^.Name);
         Message(Owner, evCommand, cmFindGotoFile, @FreeStr);
       end;

  end;

begin
   OOM := False;
   if Command = cmFindFile then
     begin
       DT.Mask := '';
       DT.Text := '';
       DT.O := 0;
       if ExecResource(dlgArvidFileFind, DT) <> cmOK then Goto 1;
       if DT.O and 1 <> 0 then
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
       if DT.Mask = '' then DT.Mask := x_x;
       SDesc := DT.Text <> '';
       DT.Text := UpcaseStr(DT.Text);
       FreeObject(FindList);
       P := WriteMsg(GetString(dlPleaseStandBy));
       if DT.O and 2 <> 0 then SearchInAllFiles
                          else SearchInStream(Stream, D, GetName(Name^));
       P^.Free;
       if FindList = nil then
          begin
            ErrMsg(dlNoFilesFound);
            Exit;
          end;
1:
       if FindList <> nil then ExecuteFindDialog;
     end;
  FreeObject(FindList);
end;

procedure TArvidDrive.GetDirLength(PF: PFileRec);
  var SaveDir: String;
      LL: TSize;
      DD: TDirRecord;
      SPos: LongInt;

  procedure CountDirectory(DD, Num: LongInt);
   var FF: TArvidFile;
       I: Integer;
  begin
    Stream^.Status := stOK;
    Stream^.Seek(D.FileTableOfs + DD*SizeOf(TArvidFile));
    for I := 1 to Num do
      begin
        Stream^.Read(FF, SizeOf(FF));
        LL := LL + FF.Size;
      end;
  end;


begin
  if (PF^.Attr and $80 <> 0) or (PF^.Attr and Directory = 0) then Exit;
  SaveDir := CurDir;
  LL := 0;
  CurDir := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));
  SeekDirectory;
  SPos := CurDirPos;
  repeat
    Stream^.Seek(SPos);
    Stream^.Read(DD, SizeOf(DD));
    SPos := Stream^.GetPos;
    if DD.Level > CurLevel then CountDirectory(DD.Files, DD.NumFiles);
  until (DD.Level = 0) or (DD.Level <= CurLevel);
  CountDirectory(CurFile, CurFileNum);
  if LL<MaxLongInt then
  begin
    PF^.Size := Round(LL);
    PF^.Attr := PF^.Attr or $80;
  end;
  CurDir := SaveDir;
  SeekDirectory;
end;



end.