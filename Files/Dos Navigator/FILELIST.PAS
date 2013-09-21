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

unit FileList;

interface
  uses Drives, Drivers, Views, Objects, FilesCol, DOS, Advance, RStrings;

  const DIZFilter: String = 'files.bbs;*.diz';


type
       PDesc = ^TDesc;
       TDesc = record
         Name: String[12];
         DIZ: PString;
       end;

       PDIZCol = ^TDIZCol;
       TDIZCol = object(TSortedCollection)
         procedure FreeItem(P: Pointer); virtual;
         function Compare(P1, P2: Pointer): Integer; virtual;
       end;

       PListDrive = ^TListDrive;
       TListDrive = object(TDrive)
          Descriptions: PSortedCollection;
          function GetDirectory(SortMode, PanelFlags: Integer; const FileMask: String;
                                var FreeSpace, TotalInfo: String ): PCollection; virtual;
          destructor Done; virtual;
          procedure GetFull(var B; P: PFileRec; C, Flags: Word); virtual;
          procedure GetEmpty(var B; C, Flags: Word); virtual;
          function CalcLength(Flags: Word): Integer; virtual;
          procedure MakeTop(var S: String; Flags: Word); virtual;
       end;


implementation
uses FLPanel, Memory, Tree, DNApp;

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

destructor TListDrive.Done;
begin
  if Descriptions <> nil then Dispose(Descriptions, Done);
  inherited Done;
end;

function TListDrive.GetDirectory;
 var Files: PFilesCollection;
     SR: SearchRec;
     P: PFileRec;
     D: DateTime;
     I,J: Integer;
     DrNm: PathStr;
     AllFiles: Boolean;
     FreeSpc, TotalLen: LongInt;
     S: String;
     Hilite: Boolean;
     PD: PDesc;

  procedure ReadList;
   var T: Text;
       S: String;
       S1: String[12];
       I: Integer;
  begin
    ClrIO;
    Assign(T, MakeNormName(CurDir, SR.Name));
    Reset(T);
    if (IOResult <> 0) or  Abort then Exit;
    While not SeekEOF(T) do
      begin
        ReadLn(T,S);
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
           if not Descriptions^.Search(PD, I) then Descriptions^.AtInsert(I, PD)
            else Descriptions^.FreeItem(PD);
         end;
      end;
    Close(T);
  end;

begin
 DriveType := drListDrive;
 if Descriptions <> nil then Dispose(Descriptions, Done);
 Descriptions := nil;
 Hilite := PFilePanel(Owner)^.PanelFlags and pfHiliteFiles <> 0;
 DOSError := 0;
 Abort := Off; AllFiles := FileMask = x_x; ClrIO; FreeSpc := 0;
 FreeSpace := ''; TotalInfo := ''; TotalLen := 0;
 Files := New(PFilesCollection, Init(10, 20));
 PFilesCollection(Files)^.Owner := Owner;
 if PanelFlags and pfFreeSpace <> 0 then FreeSpc := DiskFree(Byte(CurDir[1])-64);

 PFilesCollection(Files)^.SortMode := SortMode;
 DosError := 0; ClrIO; Abort := Off;
 DrNm := MakeNormName(CurDir,x_x);
 FindFirst(DrNm, $3F xor VolumeID, SR);
 While (DosError = 0) and not Abort and (IOResult = 0) and (MemAvail > LowMemSize) do
 begin
  if (SR.Attr and VolumeID = 0) and (SR.Name <> '.') then
   if (SR.Name[1] = '.') or (not Security or (Security and (SR.Attr and Hidden=0))) then
   if AllFiles or (SR.Attr and Directory <> 0) or (InFilter(SR.Name, FileMask)) then
   begin
    New(P);
    if SR.Name[1] <> '.' then
    begin
     I := Pos('.', SR.Name);
     if I = 0 then P^.Name := SR.Name + Strg(32,12)
             else P^.Name := Copy(Copy(SR.Name, 1, I - 1) + '        ', 1, 9) + Copy(SR.Name, I + 1, 3) + '   ';
    end else P^.Name := '..          ';
    UnpackTime(SR.Time, D);
    P^.TType := Byte(Hilite);
    P^.Year := D.Year mod 100;
    P^.Month := D.Month;
    P^.Day := D.Day;
    P^.Hour := D.Hour;
    P^.Min := D.Min;
    P^.Attr := SR.Attr;
    P^.Size := SR.Size;
    P^.DIZ := nil;
    P^.Selected := Off;
    if SR.Attr and Directory = 0 then
     begin
      if (Descriptions = nil) and InFilter(SR.Name, DIZFilter) then
       begin
         Descriptions := New(PDIZCol, Init(10,10));
         ReadList;
       end;
      LowStr(P^.Name);
      if SR.Attr and SysFile <> 0 then P^.Name[1] := UpCase(P^.Name[1]);
     end else
      begin
       P^.Size := 0;
       if PanelFlags and pfShowLength <> 0 then
        begin
          if SR.Name[1] = '.' then P^.Size := GetDirLen(CurDir)
                              else P^.Size := GetDirLen(CurDir+'\'+SR.Name);
          if Abort then begin PanelFlags := PanelFlags and (not pfShowLength); Abort := Off; end;
        end;
      end;
    if P^.Name[1] <> '.' then Inc(TotalLen, P^.Size);
    P^.Owner := @CurDir;
    if P^.Attr and Hidden <> 0 then P^.Name[9] := '±';
    if P^.Attr and SysFile <> 0 then P^.Name[9] := '²';
    if Hilite then P^.TType := GetFileType(P^.Name, P^.Attr) else P^.TType := 0;
    Files^.Insert(P);
   end;
  DosError := 0;
  FindNext(SR);
 end;

 if Files^.Count = 0 then S := GetString(dlDINoFiles)
  else begin
        S := GetString(dlTotal);
        if Files^.Count = 1 then S := S+'1~ '+GetString(dlDIFile)
                            else S := S+ItoS(Files^.Count)+'~ '+GetString(dlDIFiles);
        S := S + GetString(dlDIWith) + '~';
        if TotalLen = 1 then S := S + '1~ '+GetString(dlDIByte)
                        else S := S + FStr(TotalLen)+'~ '+GetString(dlDIBytes);
       end;
 TotalInfo := S;
 FreeSpace := '~'+FStr(FreeSpc)+GetString(dlDIFreeDisk)+Copy(CurDir, 1, 2);
 if (CurDir[0] > #3) and (PFileRec(Files^.At(0))^.Name <> '..          ') then
  begin
    New(P);
    P^.Name := '..          ';
    P^.TType := Byte(Hilite);
    P^.Year := 80;
    P^.Month := 1;
    P^.Day := 1;
    P^.Hour := 0;
    P^.Min := 0;
    P^.Attr := Directory;
    P^.Size := 0;
    P^.DIZ := nil;
    P^.Selected := Off;
    if PanelFlags and pfShowLength <> 0 then
     begin
       P^.Size := GetDirLen(CurDir);
       if Abort then begin PanelFlags := PanelFlags and (not pfShowLength); Abort := Off; end;
     end;
    P^.Owner := @CurDir;
    Files^.Insert(P);
  end;
 if Descriptions <> nil then
   for I := 1 to Files^.Count do
    begin
      P := Files^.At(I-1);
      if Descriptions^.Search(P, J) then P^.DIZ := PDesc(Descriptions^.At(J))^.DIZ
                                    else P^.DIZ := nil;
    end;
 GetDirectory := Files;
end;

procedure TListDrive.GetEmpty;
 var
     X: Byte;
begin
  TWordArray(B)[12] := (TWordArray(B)[12] and $F000) or (C and $0FFF);
end;

procedure TListDrive.MakeTop;
begin
 S := GetString(dlListDriveTop) + Strg(32, 255);
end;

procedure TListDrive.GetFull;
 var S: String;
     X: Byte;
begin
  if P^.DIZ <> nil then S := Copy(P^.DIZ^,1,MaxViewWidth) else S := '';
  MoveStr(TWordArray(B), P^.Name, C);
  MoveStr(TWordArray(B)[13], S, C);
end;

function TListDrive.CalcLength;
begin
  CalcLength := MaxViewWidth;
end;

end.