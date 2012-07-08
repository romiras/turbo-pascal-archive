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

{$I STDEFINE.INC}
{$I DN.DEF}

unit FilesCol;

interface
 uses Objects, Memory, DOS, Startup, DNHelp, Advance, ObjType;

type
    PDIZ = ^TDIZ;
    TDIZ = record
      Owner: PString;
      DIZ: PString;
      Line: LongInt;
      isDisposable: Boolean;
    end;

    PFileRec = ^TFileRec;
    TFileRec = record
     Size: LongInt;
     PSize: LongInt;
     Owner: PString;
     Diz: PDIZ;
     Name: Str12;
     Yr: Word;
     TType: Byte;
     Attr: Byte;
     Second: Byte;
     Selected: Boolean;
     case Boolean of
       True : (FDate: LongInt);
       False: (Minute, Hour, Day, Month: Byte);
    end;

    TMakeListRec = record
     FileName: String[79];
     Action: String[255];
     Options: Word;
    end;

    PUserParams = ^TUserParams;
    TUserParams = record
      Active, Passive: PathStr;
      ActiveList, PassiveList: PathStr;
    end;

    PLineCollection = PTextCollection;
    TLineCollection = TTextCollection;

    PFilesCollection = ^TFilesCollection;
    TFilesCollection = object(TSortedCollection)
     SortMode: Byte;
     Selected: Integer;
     Owner: Pointer;
     procedure FreeItem(Item: Pointer); virtual;
     function Compare(Key1, Key2: Pointer): Integer; virtual;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
    end;

const
      cmlPathNames     = 1;
      cmlAutoDetermine = 2;

      RFilesCollection: TStreamRec = (
       ObjType: otFilesCollection;
       VmtLink: Ofs(TypeOf(TFilesCollection)^);
       Load: @TFilesCollection.Load;
       Store: @TFilesCollection.Store);

function SelectDrive(X, Y: Integer; Default: Char; IncludeTemp: Boolean): String;
function CopyFileRec(FR: PFileRec): PFileRec;
function NewFileRec(const Name: String; Size, Date: LongInt; Attr: Byte; AOwner: PString): PFileRec;
function PackedDate(P: PFileRec): LongInt;

 const Archives = #0'arc'#0'bsa'#0'bs2'#0'zip'#0'arj'#0'lzh'#0'hyp'#0'chz'#0+
                  'ha'#0'sqz'#0'zoo'#0'hap'#0'ice'#0'pak'#0'lim'#0'rar'#0'ha '#0+
                  'uc2'#0'ain'#0'lha'#0'tar'#0'tdr'#0;
       Executables: String[21] = #0'exe'#0'bat'#0'com'#0;

implementation
uses DNApp, Menus, Drivers, Views, FlPanel, Drives,
     Commands, DiskTool
     {$IFDEF MODEM}
     ,NavyLink
     {$ENDIF}

;

const
    pfrPacked   = $80;
    pfrSelect   = $40;

type
    TPackedFileRec = record
      Time: LongInt;
      Attr: Byte;
      NLen: Byte;
    end;


function CopyFileRec;
 var P: PFileRec;
begin
 New(P);
 P^ := FR^;
 CopyFileRec := P;
 if P^.DIZ <> nil then P^.DIZ^.isDisposable := Off;
end;

constructor TFilesCollection.Load;
 var I: Integer;
     P: PFileRec;
     R: TPackedFileRec;
     Nm: Str12;
     Pck: Boolean;
     Sel: Boolean;
     Sz: LongInt;
begin
 S.Read(Count, SizeOf(Integer)*3);
 I := Limit;
 Limit := 0;
 SetLimit(I);
 for I := 1 to Count do
  begin
   S.Read(R, SizeOf(R));
   with R do
   begin
     Pck := NLen and pfrPacked <> 0; if Pck then NLen := NLen and not pfrPacked;
     Sel := NLen and pfrSelect <> 0; if Sel then NLen := NLen and not pfrSelect;
     if NLen > 12 then RunError(201);
     Nm[0] := Char(NLen); if NLen > 0 then S.Read(Nm[1], NLen);
   end;
   if R.Attr and Directory = 0 then S.Read(Sz, SizeOf(Sz)) else Sz := 0;
   P := NewFileRec(Nm, Sz, R.Time, R.Attr, nil);
   if Pck then S.Read(P^.PSize, SizeOf(P^.PSize));
   if Sel then P^.Selected := True;
   AtPut(I-1, P);
  end;
 S.Read(Selected, SizeOf(Selected));
end;

procedure TFilesCollection.Store;
 var I, J, Sel: Integer;
     R: TPackedFileRec;
     P: PFileRec;
     SS: Str12;
     SL: byte absolute SS;
begin
 J := 0;
 for I := 1 to Count do
  if (I - 1 = Selected) or (PFileRec(At(I-1))^.Selected) then
   begin if I - 1 = Selected then Sel := J; Inc(J) end;
 I := Count; Count := J;
 S.Write(Count, SizeOf(Integer)*3); Count := I;
 for I := 1 to Count do
  if (I - 1 = Selected) or (PFileRec(At(I-1))^.Selected) then
 begin
   P := At(I-1);
   R.Time := PackedDate(P);
   R.Attr := P^.Attr;
   SS := MakeFileName(P^.Name);
   R.NLen := SL;
   if P^.PSize <> P^.Size then R.NLen := R.NLen or pfrPacked;
   if P^.Selected then R.NLen := R.NLen or pfrSelect;
   S.Write(R, SizeOf(R));
   if SL>0 then S.Write(SS[1], SL);
   if P^.Attr and Directory = 0 then S.Write(P^.Size, SizeOf(P^.Size));
   if P^.PSize <> P^.Size then S.Write(P^.PSize, SizeOf(P^.PSize));
 end;

 S.Write(Sel, SizeOf(Sel));
end;

procedure TFilesCollection.FreeItem;
 var P: PFileRec absolute Item;
begin
 if Item <> nil then
   begin
     if (P^.DIZ <> nil) and P^.DIZ^.isDisposable then
      begin
        DisposeStr(P^.DIZ^.DIZ);
        Dispose(P^.DIZ);
      end;
     Dispose(P);
   end;
end;

function TFilesCollection.Compare;
 var T1: TFileRec;
     P2: PFileRec absolute Key2;
     C: Integer;
     SM, I1, I2: Integer;
     P1P, P2P: Boolean;
     PanelFlags: Word;

begin
 PanelFlags := PFilePanel(Owner)^.PanelFlags;
 Move(Key1^,T1,SizeOf(T1));
 C := 0;
 with P2^ do
   begin
     P1P := T1.Name[1] = '.';
     P2P := Name[1] = '.';

     if P1P and not P2P then begin Compare := -1; Exit; end;
     if P2P and not P1P then begin Compare := +1; Exit; end;

     SM := SortMode;
     if (SM >= 5) and (SM <= 20) then begin
       if (T1.Name = Name) and ((T1.Attr or Attr) and Directory = 0) and
          (((SM-5) and 1 = 0) or (T1.Size = Size)) and
          (((SM-5) and 2 = 0) or (T1.Yr < Yr) or
           ((T1.Yr = Yr) and (T1.FDate <= FDate)) or
           ((T1.Yr = Yr) and (T1.FDate = FDate) and (T1.Second < Second))) and
          (((SM-5) and 4 = 0) or (T1.Attr = Attr)) and
          (((SM-5) and 8 = 0) or
                  CompareFiles(MakeNormName(T1.Owner^, MakeFileName(T1.Name)),
                               MakeNormName(Owner^, MakeFileName(Name))) )
           then C := 0 else if (T1.Name < Name) then C := -1
                                                 else C := 1;
       Compare := C;
       Exit;
     end;

     if (Owner <> nil) and (SM <> 3) and (SM <> 4) then
     begin
       if PanelFlags and fmiExeFirst <> 0 then
       begin
         if ((T1.Attr xor Attr) and Directory = 0) then
         begin
           if (T1.TType = ttExec) and (TType <> ttExec) then begin Compare := -1; Exit; end;
           if (T1.TType <> ttExec) and (TType = ttExec) then begin Compare := 1; Exit; end;
         end;
       end;
       if PanelFlags and fmiArchivesFirst <> 0 then
       begin
         if ((T1.Attr xor Attr) and Directory = 0) then
         begin
           if (T1.TType = ttArc) and (TType <> ttArc) then begin Compare := -1; Exit; end;
           if (T1.TType <> ttArc) and (TType = ttArc) then begin Compare := 1; Exit; end;
         end;
       end;
     end;

     case SM of
      0: if T1.Owner^ = Owner^ then if (T1.Name = Name) then C := 0
                                                          else C := -1
           else if T1.Owner^ < Owner^ then C := -1 else C := 1;
      30: begin
           I1 := T1.TType; I2 := TType;
           if I1 = 0 then I1 := 100;
           if I2 = 0 then I2 := 100;
           if I1 < I2 then C := -1 else
           if I1 > I2 then C := 1 else
              if T1.Name < Name then C := -1
                else if T1.Name > Name then C := 1
                  else if T1.Owner^ < Owner^ then C := -1
                    else if T1.Owner^ > Owner^ then C := 1;
          end;
      1: if (T1.Attr xor Attr) and Directory <> 0 then
          if T1.Attr and Directory <> 0 then C := -1 else C := 1 else
           if T1.Name < Name then C := -1
            else if T1.Name > Name then C := 1
             else if T1.Owner^ < Owner^ then C := -1
               else if T1.Owner^ > Owner^ then C := 1;
     141: if (T1.Attr xor Attr) and Directory <> 0 then
          if T1.Attr and Directory <> 0 then C := -1 else C := 1 else
           if T1.Name < Name then C := -1
            else if T1.Name > Name then C := 1 else C := 0;
      2: if (T1.Attr xor Attr) and Directory <> 0 then
          if T1.Attr and Directory <> 0 then C := -1 else C := 1 else
           if Copy(T1.Name, 10, 3) < Copy(Name, 10, 3) then C := -1 else
            if Copy(Name, 10, 3) < Copy(T1.Name, 10, 3) then C := 1 else
           if T1.Name < Name then C := -1
            else if T1.Name > Name then C := 1
              else if T1.Owner^ < Owner^ then C := -1
                else if T1.Owner^ > Owner^ then C := 1;
      3: if (T1.Attr xor Attr) and Directory <> 0 then
          if T1.Attr and Directory <> 0 then C := -1 else C := 1 else
           if T1.Size > Size then C := -1 else
           if T1.Size < Size then C := 1 else
           if T1.Name < Name then C := -1
            else if T1.Name > Name then C := 1
             else if T1.Owner^ < Owner^ then C := -1
               else if T1.Owner^ > Owner^ then C := 1;
      4: begin
         if (T1.Attr xor Attr) and Directory <> 0 then
          if T1.Attr and Directory <> 0 then C := -1 else C := 1 else
           if (T1.Yr < Yr) then C := 1 else
           if (T1.Yr > Yr) then C := -1 else
           if (T1.FDate < FDate) then C := 1 else
           if (T1.FDate > FDate) then C := -1 else
           if (T1.Second < Second) then C := 1 else
           if (T1.Second > Second) then C := -1 else
           if T1.Name < Name then C := -1
            else if T1.Name > Name then C := 1
             else if T1.Owner^ < Owner^ then C := -1
               else if T1.Owner^ > Owner^ then C := 1;
         end;
      else if (T1.Attr and $3F = Attr and $3F) and (T1.Yr=Yr) and (T1.FDate = FDate) and (T1.Second = Second)
              and (T1.Name=Name) and (T1.Owner^ = Owner^)
               then C := 0 else C := -1;
     end;
   end;
 Compare := C;
end;

function SelectDrive;
 var R: TRect;
     P: PMenuBox;
     Menu: PMenu;
     Items, Lnk: PMenuItem;
     C: Char;
     N: Integer;
     SC: CharSet;
begin
 Items := nil; N := 0; Lnk := nil;

 {$IFDEF MODEM}
 if IncludeTemp and (Linker <> nil) then
   begin
     CL_GetLinkDrives(SC);
     if SC <> [] then
       begin
         for C := 'Z' downto 'A' do
           if C in SC then
             Items := NewItem('  ~'+C+':~  ', '', kbNoKey, 2000 + Byte(C),
                               hcNoContext, Items);
         Items := NewSubMenu(' LINK', hcNoContext, NewMenu(Items), nil);
         Lnk := Items;
       end;
   end;
 {$ENDIF}

 if IncludeTemp then Items := NewItem(' TEMP ', '', kbSpace, 1200,
                                          hcTempList, Items);
 for C := 'Z' downto 'A' do
  if ValidDrive(C) then
   begin
    Items := NewItem('  ~'+C+':~  ', '', kbNoKey, 1000 + Byte(C),
                      hcNoContext, Items);
    Inc(N);
   end;
 if not (Default in ['A'..'Z']) and not ((Default = '+') and (Lnk <> nil)) then
 asm
  mov ah, 19h
  int 21h
  add al, 'A'
  mov C, al
 end else C := Default;
 Menu := NewMenu(Items);
 DeskTop^.GetExtent(R);
 R.A.X := X; R.A.Y := Y;
 if X < 0 then R.A.X := 0 else if X + 8 > R.B.X then R.A.X := R.B.X - 8;
 if Y < 0 then R.A.Y := 0 else if Y + N + 2 > R.B.Y then R.A.Y := R.B.Y - N - 2;
 R.B.X := R.A.X + 8; R.B.Y := R.A.Y + N + 2;
 P := New(PMenuBox, Init(R, Menu, nil));
 if (C='+') then Items := Lnk else Items := P^.FindItem(C);
 if Items <> nil then Menu^.Default := Items;
 P^.HelpCtx := hcSelectDrive + Byte( IncludeTemp = True );

 N := DeskTop^.ExecView(P);
 Dispose(P, Done);
 DisposeMenu(Menu);
 if N > 1000 then SelectDrive := Char(N - 1000)+':' else SelectDrive := '';
 if N = 1200 then SelectDrive := cTEMP_;
 if N > 2000 then SelectDrive := '+' + Char(N - 2000);
end;

 var Q: Str5;

function GetFileType(const S: String; Attr: Byte): Integer;
begin
  if Attr and Directory <> 0 then GetFileType := ttDirectory else
  begin
    GetFileType := 0;
    asm
      cld
      les   si, S
      mov   di, offset Q + 2
      mov   ah, [es:si]
      sub   ah, 9
      ja    @o
   @t:mov   word ptr [Q+0],0003h
      mov   word ptr [Q+2],002Eh {'.'}
      jmp   @e
   @o:add   si,10
   @1:mov   al, [es:si]
      inc   si
      cmp   al, ' '
      je    @S
      mov   ds:[di], al
      inc   di
   @S:dec   ah
      jnz   @1
      mov   byte ptr ds:[di],0
      sub   di, offset Q
      cmp   di,3
      jl    @t
      mov   word ptr Q, di
   @e:
    end;

   if Pos(Q, Executables) <> 0 then GetFileType := ttExec else
    if (Pos(Q, Archives) <> 0) or
          (((Q[2] = 'a') or (Q[2] = 'r'))
            and (Q[3] >= '0') and (Q[4] >= '0')
            and (Q[3] <= '9') and (Q[4] <= '9')) then GetFileType := ttArc
    else if Pos(Q, CustomMask1) <> 0 then GetFileType := ttCust1
    else if Pos(Q, CustomMask2) <> 0 then GetFileType := ttCust2
    else if Pos(Q, CustomMask3) <> 0 then GetFileType := ttCust3
    else if Pos(Q, CustomMask4) <> 0 then GetFileType := ttCust4
    else if Pos(Q, CustomMask5) <> 0 then GetFileType := ttCust5
  end;
end;

function NewFileRec;
  var PR: PFileRec;
      T: TFileRec;
      D: DateTime;
      I: Integer;
begin
  if Name[1] <> '.' then
    begin
      I := PosChar('.', Name);
      T.Name := AddSpace(Name, 12);
      if I > 0 then Insert(Strg(' ', 9 - I), T.Name, I);
    end else T.Name := '..          ';
  T.Name[9] := ' ';
  if Attr and Directory <> 0 then UpStr(T.Name) else LowStr(T.Name);
  if Attr and Hidden <> 0 then T.Name[9] := '±';
  if Attr and SysFile <> 0 then begin T.Name[9] := '²'; T.Name[1] := Upcase(T.Name[1]); end;
  T.Size := Size; T.PSize := Size;
  if Date = 0 then
  begin
    T.Yr     := 1980;
    T.Month  := 1;
    T.Day    := 1;
    T.Hour   := 1;
    T.Minute := 1;
    T.Second := 1;
  end else
  begin
    UnpackTime(Date, D);
    T.Yr := D.Year;
    T.Month := D.Month;
    T.Day := D.Day;
    T.Hour := D.Hour;
    T.Minute := D.Min;
    T.Second := D.Sec;
  end;
  T.Attr := Attr and $7F;
  T.Selected := Off;
  T.DIZ := nil;
  T.TType := GetFileType(T.Name, T.Attr);
  T.Owner := AOwner;
  New(PR); PR^ := T;
  NewFileRec := PR;
end;

function PackedDate(P: PFileRec): LongInt;
var
  DT: DateTime;
  L: LongInt;
begin
  with P^ do
  begin
    DT.Year   := Yr;
    DT.Month  := Month;
    DT.Day    := Day;
    DT.Hour   := Hour;
    DT.Min    := Minute;
    DT.Sec    := Second;
  end;
  PackTime(DT, L);
  PackedDate := L;
end;

end.