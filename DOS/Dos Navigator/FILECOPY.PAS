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

unit FileCopy;

interface
uses Advance, Objects, Views, Dialogs, Drivers, FilesCol, Dos;

type
    PCopyRec = ^TCopyRec;
    TCopyRec = record
     FC: PFilesCollection;
     Owner: PView;
     Where: TPoint;
    end;

const
     SkipCopyDialog: Boolean = Off;
     CopyDirName:    PathStr = '';

function GetFileAttr(const S: String): Word;
function  SetFileAttr(const S: String; Attr: Word):Word;
procedure CopyFiles(Files: PCollection; Owner: PView; MoveMode: Boolean; FromTemp: Byte);
function SelectDialog(Select: Boolean; var St: String; var XORSelect: Boolean): Boolean;
procedure MakeListFile(APP: Pointer; Files: PCollection);
function CreateDirInheritance(var S: String; Confirm: Boolean): Byte;
procedure SetDescription(PF: PFileRec; DIZOwner: PathStr);
procedure BeepAfterCopy;
function GetDIZOwner(const Path, LastOwner: String; Add: Boolean): String;
function CalcDPath(P: PDIZ; Owen: PString): PathStr;
procedure DeleteDIZ(const DPath: PathStr; Name: Str12);
function CopyDialog( var CopyDir: PathStr; var Mask: Str12;
                     var CopyOpt: Word; var CopyMode: Word;
                     var CopyPrn: Boolean; {var Inheread: Byte;}
                     MoveMode: Boolean; Files: PCollection;
                     FromTemp: Byte; Owner: PView; Link: Boolean): Boolean;

implementation
uses DNApp, Startup, ExtraMemory, Memory, Messages, HistList, Commands,
     DiskTool, xTime, Validate, 
    {$IFDEF MODEM}
     NavyLink, 
    {$ENDIF}
     Gauge, FileFind,
     DNUtil, RStrings, Tree, Archiver, Drives, DiskInfo;

const
      cpmOverwrite = 0;
      cpmAppend    = 1;
      cpmAskOver   = 2;
      cpmSkipAll   = 3;
      cpmRefresh   = 4;

      cpoCheckFree = $01;
      cpoVerify    = $02;
      cpoDesc      = $04;
      cpoMove      = $08;
      cpoFromTemp  = $80;
      cpoCopyDesc  = $40;
      cpoDirEmpty  = $20;


var  { SR: SearchRec;}
      AppendInstalled: Boolean;
      AppendState: Word;
      SeekPos: LongInt;


type
      PDir = ^TDir;
      TDir = record
        Created: (sNone, sCreated, sErased);
        XName,Name: PString;
      end;

      Str80 = String[80];

      PFileCopyRec = ^TFileCopyRec;
      TFileCopyRec = record
       Name: String[12];
       Attr: Byte;
       Size: LongInt;
       Dir: PDir;
       Owner: PFileRec;
       DIZ: PDIZ;
      end;

      PCopyCollection = ^TCopyCollection;
      TCopyCollection = object(TCollection)
       procedure FreeItem(P: Pointer); virtual;
      end;

      PDirCollection = ^TDirCollection;
      TDirCollection = object(TSortedCollection)
       procedure FreeItem(P: Pointer); virtual;
       function Compare(P1, P2: Pointer): Integer; virtual;
      end;


function MemAvail: LongInt;
begin
  MemAvail := MemAdjust(System.MemAvail);
end;

function MaxAvail: LongInt;
begin
  MaxAvail := MemAdjust(System.MaxAvail);
end;

procedure GetFTimeSizeAttr(const A: string; var ATime, ASize: LongInt; AAttr: Word);
var
  SR: SearchRec;
begin
  ClrIO; FindFirst(A, $FF, SR);
  ATime := SR.Time;
  ASize := SR.Size;
  AAttr := SR.Attr;
end;

function SetFileAttr(const S: String; Attr: Word) : Word; assembler;
asm
  push ds
  lds  dx, S
  inc  dx
  mov  cx, Attr
  mov  ax, 4301h
  int  21h
  jc   @@1
  sub  ax,ax
@@1:
  pop  ds
end;

function GetFileAttr(const S: String): Word; assembler;
asm
  push ds
  lds  dx, S
  inc  dx
  mov  ax, 4300h
  int  21h
  pop  ds
  mov  ax, cx
end;


function CorrectFile(const N: String): Boolean;
   var I: Integer;
begin
   CorrectFile := Off;
   for I := 1 to Length(N) do
       if N[I] in [#0..#31,'+','-','[',']','>','/','\',':','>','<','|'] then Exit;
   CorrectFile := On;
end;

function GetPossibleDizOwner(N: Integer): String;
  var DIZ: String;
      I: Integer;
begin
  GetPossibleDizOwner := '';
  DIZ := FMSetup.DIZ;
  while (N > 0) and (Diz <> '') do
    begin
     I := PosChar(';', DIZ); if I = 0 then I := Length(DIZ)+1;
     if CorrectFile(Copy(DIZ,1,I-1)) then
        begin
          Dec(N);
          if N = 0 then
           begin
             GetPossibleDizOwner := Copy(DIZ,1,I-1);
             Exit;
           end;
        end;
     Delete(DIZ, 1, I);
    end;
end;

function GetDIZOwner;
  var SR: SearchRec;
      I: Integer;
      lAdd: Boolean;

  procedure Prepare;
    var F: File;
        C: Char;
        I,J: Word;
  begin
     if lAdd then Exit;
     Assign(F, MakeNormName(Path, SR.Name)); ClrIO;
     FileMode := $42;
     Reset(F, 1);
     if IOResult <> 0 then Exit;
     System.Seek(F, FileSize(F)-1);
     BlockRead(F, C, 1, J);
     if (IOResult = 0) and (C <> #13) and (C <> #10) then
       begin
         C := #13; BlockWrite(F, C, 1, J);
         C := #10; BlockWrite(F, C, 1, J);
       end;
     ClrIO; Close(F); ClrIO;
  end;

begin
  lAdd := Add; SR.Name := LastOwner; Add := False;
  I := 1;
  if LastOwner = '' then GetDIZOwner := '' else
    begin
      GetDIZOwner := MakeNormName(Path, LastOwner);
      FindFirst(MakeNormName(Path, LastOwner), Archive+ReadOnly+Hidden+SysFile, SR);
      if DOSError = 0 then begin Prepare; Exit; end;
      I := 1;
    end;
  repeat
    SR.Name := GetPossibleDizOwner(I); Inc(I);
    if SR.Name = '' then Exit;
    FindFirst(MakeNormName(Path, SR.Name), Archive+ReadOnly+Hidden+SysFile, SR);
    if DOSError = 0 then begin Prepare; GetDIZOwner := MakeNormName(Path, SR.Name); Exit end;
  until False;
end;

procedure ReplaceT(P: PTextReader; var F: Text);
var
  I: Integer;
  FName: PathStr;
begin
  FName := P^.FileName;
  Dispose(P,Done); ClrIO;
  Close(F); ClrIO;
  EraseByName(FName);
  I := IOResult; ClrIO;
  System.Rename(F, FName);
  if (IOResult <> 0) then
  begin
    if (I<>0) then System.Erase(F);
    CantWrite(FName);
  end;
  ClrIO;
end;


procedure SetDescription;
  var DIZ: String;
      I: Integer;
      F1: PTextReader;
      F2: Text;
      Name,NM: Str12;
      MM: Boolean;
      SSS: string;
begin
  FileMode := $40;
  if (PF = nil){or (PF^.Attr and Directory <> 0)} then Exit;
  if DIZOwner = '' then
    begin
      Diz := GetPossibleDizOwner(1);
      if DIZ = '' then
        begin
          MessageBox(GetString(dlNoPossibleName), nil, mfError);
          Exit;
        end;
      DIZOwner := DIZ;
    end else DIZOwner := GetName(DizOwner);
  DIZOwner := GetDizOwner(PF^.Owner^, DizOwner, Off);
  if (PF^.DIZ = nil) or (PF^.DIZ^.DIZ = nil) then DIZ := ''
                                             else DIZ := PF^.DIZ^.DIZ^;
  if InputBox(GetString(dlEditDesc),GetString(dl_D_escription), DIZ, 255, hsEditDesc) <> cmOK then Exit;
  DelLeft(DIZ);
  {Assign(F1, DIZOwner); ClrIO;}
  if PF^.DIZ <> nil then
    begin
       Name := MakeFileName(PF^.Name); LowStr(Name);
       FileMode := $40;
       F1 := New(PTextReader, Init(DIZOwner)); if F1 = nil then Exit;

       Assign(F2, GetPath(DIZOwner) + '$DN'+ItoS(DNNumber)+'$.DIZ');
       Rewrite(F2); if IOResult <> 0 then begin Dispose(F1, Done); Exit; end;
       MM := Off;
       repeat
         SSS := F1^.GetStr;
         if MM or (SSS = '') or (SSS[1] = ' ') then
         begin
           if not F1^.EOF then WriteLn(F2, SSS);
         end else
         begin
           I := 1;
           While (I <= Length(SSS)) and (I <= 12) and (SSS[I] <> ' ') do Inc(I);
           NM := Copy(SSS, 1, I-1); LowStr(NM);
           if (NM = Name) or (NM = Name+'.') then
            begin
               if DIZ <> '' then WriteLn(F2, UpStrg(AddSpace(MakeFileName(UpStrg(PF^.Name)),13)), DIZ);
               MM := On;
            end else WriteLn(F2, SSS);
         end;
       until F1^.EOF or (IOResult <> 0);
       ReplaceT(F1, F2);
    end else
    begin
      ClrIO; Assign(F2, DIZOwner);
      Append(F2); if Abort then Exit;
      if IOResult <> 0 then Rewrite(F2);
      if IOResult <> 0 then
        begin
          CantWrite(DIZOwner);
          Exit;
        end;
      WriteLn(F2, UpStrg(AddSpace(MakeFileName(PF^.Name),13)), DIZ);
      Close(F2);
    end;
  RereadDirectory(PF^.Owner^);
end;

procedure TCopyCollection.FreeItem;
begin
 if P <> nil then Dispose(PFileCopyRec(P));
end;

procedure TDirCollection.FreeItem;
begin
 if P <> nil then
  with PDir(P)^ do
   begin
    DisposeStr(XName);
    DisposeStr(Name);
    Dispose(PDir(P));
   end;
end;

function TDirCollection.Compare;
 var S1, S2: String;
begin
 Compare := 1;
 if PDir(P1)^.Name <> nil then S1 := PDir(P1)^.Name^ else S1 := '';
 if PDir(P2)^.Name <> nil then S2 := PDir(P2)^.Name^ else S2 := '';
 if S1 < S2 then Compare := -1
  else if S1 = S2 then
    begin
     if PDir(P1)^.XName <> nil then S1 := PDir(P1)^.XName^ else S1 := '';
     if PDir(P2)^.XName <> nil then S2 := PDir(P2)^.XName^ else S2 := '';
     if S1 < S2 then Compare := -1
        else if S1 = S2 then Compare := 0
    end
end;

procedure BeepAfterCopy;
  var C: Char;
begin
  DelayTics(1);
  for C := 'A' to 'D' do
    begin
       Sound(1259);
       DelayTics(1);
       Sound(1400);
       DelayTics(1);
    end;
   Sound(1259);
   DelayTics(2);
   NoSound;
end;


procedure MakeListFile;
 label AddrError;
 var I, J, K: Integer;
     D, Dr, SR, Sn: PathStr;
     P: PFileRec;
     S: TMakeListRec;
     T: Text;
     Nm: NameStr;
     Xt: ExtStr;
     FidoMode: Boolean;
     SS: String;
     PP: PString;
     ZZ, NN, ND, PT: Word;
     BB: Boolean;
     FLD, Dr_: PathStr;

  procedure MakeStr(D: String);
  label Fail;
    var Drr: Boolean;
  begin
  { BB means "Is filename occurs in Action?" }
    Replace('!!', #0, D);
    Sn := P^.Name; Replace( '!', #0, Sn ); { Fix for .!!! extension }
    If ( S.Options and 2 = 2 ) and ( SR <> Dr ) and
       ( Pos( '!\', D ) = 0 ) and
       ( Pos( '!/', D ) = 0 ) and
       ( Pos( '!:', D ) = 0 ) then begin { Need to force insert !\ }
         K := Pos( '.!', D );
         If K = 0 then begin
           K := PosChar( '!', D );
           If K = 0 then goto Fail;
         end else
         If ( K <> 1 ) and ( D[ K - 1 ] = '!' )
           then Dec( K )
           else goto Fail;
      Insert( '!\', D, K );
    end;
  Fail: { Cannot find place to insert !\ }
    if SR[Length(SR)] <> '\' then AddStr(SR, '\');
    BB := Replace('!\',SR, D) or BB;
    BB := Replace('!/',Copy(SR,1,Length(SR)-1),D) or BB;
    BB := Replace('!:',Copy(SR,1,2),D) or BB;
    BB := Replace('.!', '.' + Copy(Sn, 10, 3), D) or BB;
    BB := Replace('!', DelSpaces(Copy(Sn, 1, 8)), D) or BB;
    Replace(#0, '!', D);
    Replace(#1, ';', D);
    if not BB then
    begin
      Dr_ := SR;
      SR := MakeFileName(P^.Name);
      if (S.Options and 1 = 1) or (S.Options and 2 <> 0)
         and (Dr_ <> Dr) then
      begin
        SR := MakeNormName(DelSpaces(P^.Owner^),DelSpaces(SR));
      end;
      D := S.Action + SR;
    end;
    WriteLn(T, D);
  end;

begin
 if Files^.Count = 0 then Exit;
 FillChar(S, SizeOf(S), 0);
 S.FileName := HistoryStr(hsMakeList, 0);
 if S.FileName = '' then S.FileName := 'DNLIST.BAT';
 S.Action := HistoryStr(hsExecDOSCmd, 0);
 S.Options := MakeListFileOptions;
 if S.Options and cmlPathNames <> 0 then
 begin
   BB := Off;
   for I := 1 to Files^.Count - 1 do
   begin
     BB := BB or (PFileRec(Files^.At(I-1))^.Owner <> PFileRec(Files^.At(I))^.Owner);
     if BB then Break;
   end;
   if BB then S.Options := S.Options or cmlPathNames
         else S.Options := S.Options and not cmlPathNames;
 end;
 if (ExecResource(dlgMakeList, S) <> cmOK) then Exit;
 MakeListFileOptions := S.Options;
 while S.Action[Length(S.Action)] = ' ' do Dec(S.Action[0]);
 if S.Action <> '' then S.Action := S.Action + ' '; FileMode := 2;
 Abort := Off;
 if S.FileName[1] in ['+', '%', '/'] then
   begin
     FidoMode := True;
     SS := FMSetup.DIZ;
     I := SearchFor('/FIDO=', SS[1], Length(SS), Off);
     if I = 1 then
       begin
AddrError:
          Msg(dlNoFTNset, nil, mfError+mfOKButton);
          Exit;
       end;
     Delete(SS, 1, I+5);
     I := PosChar(';', SS); if I = 0 then I := Length(SS)+1; SS[0] := Char(I-1);
     I := PosChar(',', SS); if I = 0 then Goto AddrError;
     ParseAddress(Copy(SS, 1, I-1), ZZ, NN, ND, PT); K := ZZ;
     ParseAddress(Copy(S.FileName, 2, 255), ZZ, NN, ND, PT);
     Delete(SS, 1, I); if SS[Length(SS)] = '\' then Dec(SS[0]);
     FSplit(SS, Dr, Nm, Xt);
     if K <> ZZ then Xt := '.'+Copy(Hex4(ZZ), 2, 3);
     SS := Dr+Nm+Xt;
     if PT = 0 then Nm := Hex4(NN)+Hex4(ND)
        else begin
               SS := MakeNormName(SS , Hex4(NN) + Hex4(ND) + '.PNT\');
               Nm := Hex8(PT);
             end;
     Xt := '.hlo';
     case S.FileName[1] of
       '+': Xt[2] := 'c';
       '%': Xt[2] := 'f';
     end;
     SS := MakeNormName(SS, Nm + Xt);
     S.FileName := SS;
     S.Options := S.Options or cmlPathNames;
   end;
 D := Advance.FExpand(S.FileName); FSplit(D, Dr, Nm, Xt); ClrIO;
 FLD := Dr;
 CreateDirInheritance(Dr, Off);
 if Abort then Exit;
 Assign(T, D); ClrIO;
 Reset(T);
 if IOResult = 0 then
   begin
     Close(T);
     PP := @SS; SS := Cut(D, 40);
     if FidoMode then I := cmOK
                 else I := MessageBox(GetString(dlED_OverQuery)
                                      , @PP, mfYesButton+mfCancelButton+mfAppendButton+mfWarning);
     case I of
       cmOK: Append(T);
       cmYes: Rewrite(T);
         else Exit;
     end;
   end else Rewrite(T);
 if Abort then Exit;
 if IOResult<>0 then
  begin
   MessageBox(GetString(dlFBBNoOpen)+S.FileName, nil, mfError + mfOKButton);
   Exit;
  end;
 for I := 1 to Files^.Count do
  begin
    P := Files^.At(I-1);
    Message(APP, evCommand, cmCopyUnselect, P);
    BB := False;
    SR := P^.Owner^;
    Replace('!', #0, SR);
    if SR[Byte(Sr[0])] <> '\' then SR := SR +'\';
    SS := S.Action;
    if SS <> '' then
      begin
        Replace(';;', #1, SS);
        while SS <> '' do
          begin
            J := PosChar(';', SS);
            if J = 0 then J := Length(SS)+1;
            MakeStr(Copy(SS, 1, J-1));
            Delete(SS, 1, J);
          end;
      end else
    If (S.Options and cmlPathNames <> 0) or (S.Options and 2 <> 0) and (SR <> FLD)
      then MakeStr( '!\!.!' )
      else MakeStr('!.!');
  end;
 Close(T);
 RereadDirectory(Dr);
 GlobalMessage(evCommand, cmRereadInfo, nil);
 GlobalMessage(evCommand, cmRereadTree, @Dr);
end;

function SelectDialog;
var
  I: Integer;
  XorSel: Boolean;
  S: String[12];
  Idx: TDlgIdx;
  D: PDialog;
  V, V1: PView;
  R: TRect;

  function FindLine(P: PView): Boolean; far;
  begin
    FindLine := (P <> nil) and (P^.DataSize > 5);
  end;

begin
  XORSel := XORSelect;
  SelectDialog := False;
  if LowMemory then Exit;
  if Select then Idx := dlgSelect else Idx := dlgUnselect;
  D := PDialog(Application^.ValidView(PDialog(LoadResource(Idx))));
  if D = nil then Exit;
  S := HistoryStr(hsSelectBox, 0);
  if S = '' then S := x_x;
  V := D^.FirstThat(@FindLine);
  if V <> nil then PInputLine(V)^.SetValidator(New(PFilterValidator,
                                               Init([#32..#255]-
                                                    ['+','|','>','<',']','['])));
  D^.SetData(S);
  if Desktop^.ExecView(D) = cmCancel then begin Dispose(D, Done); HistoryAdd(hsSelectBox, S); Exit; end;
  SelectDialog := True;
  D^.GetData(S);
  Dispose(D, Done);
  S := UpStrg(Norm12(S));
  S[9] := ' '; St := S;
  XORSelect := XORSel;
end;

function CreateDirInheritance;
 var I, J: Integer;
     SR: SearchRec;
     LS: Byte absolute S;
     M: PathStr;
     BB: Boolean;
begin
  CreateDirInheritance := 0; BB := On;
  ClrIO; S := Advance.FExpand(S); if Abort then Exit;
  I := PosChar(':',S);
  if I = 0 then Exit;
  Inc(I);
  while I < LS do
   begin
     J := I;
     repeat Inc(I); if I > LS then Exit until (S[I] = '\') or (I = LS);
     M := Copy(S, 1, I-Byte(S[I] = '\'));
     ClrIO; FindFirst(M, $3F xor VolumeID, SR);
     if Abort then Exit;
     if DOSError <> 0 then
      begin
        if BB and (S[I] = '\') then
          begin CreateDirInheritance := J-1; BB := Off end;
        if Confirm and ( Confirms and cfCreateSubDir <> 0) then
           begin
             if (S[0] > #3) and (S[Length(S)] = '\') then Dec(S[0]);
             if (MessageBox(GetString(dlQueryCreateDir)+Cut(S, 40)+' ?', nil, mfYesNoConfirm) <> cmYes)
                 then Exit;
            end;
        ClrIO; MkDir(M);
        if Abort or (IOResult <> 0) then
         begin
           MessageBox(GetString(dlFCNoCreateDir) + S, nil, mfError + mfOKButton);
           Exit;
         end;
        CreateDirectory(M, Off);
      end;
   end;
end;


type
    TBlock = record
      Len : Word;
      Time: LongInt;
      EOF : Boolean;
      Last: Boolean;
    end;

const
      eoStart  = $01;
      eoEnd    = $02;
      eoAppend = $04;
      eoDir    = $08;
      eoCheck  = $10;

  MemStream: PMemoryStream = nil;
  EMSStream: PEMSStream = nil;
  NoUseEMS: Boolean = Off;
  XMSStream: PXMSStream = nil;
  NoUseXMS: Boolean = Off;

var
   ToDo: LongInt;

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

  PDirName = ^TDirName;
  TDirName = object(TObject)
    OldName, NewName: PString;
    Check: Boolean;
    CopyIt: Boolean;
    Own: Pointer;
    Attr: Byte;
    constructor Init(const AOld, ANew: String; ACopy: Boolean; AnOwn: Pointer; AnAttr: Byte);
    function Old: String;
    function New: String;
    destructor Done; virtual;
  end;

{ TDirName }

constructor TDirName.Init;
begin
  inherited Init;
  OldName := NewStr(AOld);
  NewName := NewStr(ANew);
  CopyIt := ACopy;
  Own := AnOwn;
  Attr := AnAttr;
end;

function TDirName.New;
begin
  if NewName = nil then New := '' else New := NewName^;
end;

function TDirName.Old;
begin
  if OldName = nil then Old := '' else Old := OldName^;
end;

destructor TDirName.Done;
begin
  DisposeStr(OldName);
  DisposeStr(NewName);
end;

{ TLine }

constructor TLine.Init;
begin
  inherited Init;
  if MaxAvail < 2048 then Fail;
  Len := ALen; EOF := AEOF; Attr := AAttr; Date := ADate; Size := ASize;
  if Len <> 0 then
    begin
      PrepareToWrite;
      if Len <= 0 then Fail;
      ALen := Len;
    end else EOF := eoStart + eoEnd;
  Owner := AOwner;
  if EOF and (eoStart or eoEnd) <> 0 then
     OldName := NewStr(AOldName);
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
  if (XMSStream <> nil) or (EMSStream <> nil) then begin Len := 0; Exit; end;
  if MemStream = nil then
    begin
      Pos := MaxAvail-$4000;
      if Pos < $E000 then Pos := MaxAvail - $3000;
      if Pos < $A000 then Pos := MaxAvail - $2000;
      if Pos < $8000 then Pos := MaxAvail - $1000;
      if Pos < $1000 then begin Len := 0; Exit end;
      New(MemStream, Init(Pos, 2048));
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
  if not EMSFound or NoUseEMS or (XMSStream <> nil) then begin Len := 0; Exit; end;
  if EMSStream = nil then
    begin
      Pos := LongInt(EMSFreePages);
      if Pos < 32 then begin NoUseEMS := True; Len := 0; Exit end;
      if Pos > 512 then Pos := 512;
      Pos := (Pos-1) * LongInt(16384);
      if Pos > ToDo+10240 then Pos := ToDo+10240;
      New(EMSStream, Init(Pos, Pos));
      if EMSStream^.Status <> stOK then
        begin
          Dispose(EMSStream, Done);
          EMSStream := nil;
          Len := 0;
          NoUseEMS := On;
          Exit;
        end;
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
  if not XMSFound or NoUseXMS then begin Len := 0; Exit; end;
  if XMSStream = nil then
    begin
      Pos := LongInt(XMSFree);
      if Pos < 512 then begin NoUseXMS := On; Len := 0; Exit end;
      if Pos > 8192 then Pos := 8192;
      Pos := LongInt(Pos-1) shl 10;
      if Pos > ToDo+10240 then Pos := ToDo+10240;
      New(XMSStream, Init(Pos, Pos));
      if XMSStream^.Status <> stOK then
        begin
          Dispose(XMSStream, Done);
          XMSStream := nil;
          NoUseXMS := On;
          Len := 0;
          Exit;
        end;
    end;
  Pos := Stream^.GetPos;
  if Pos + Len > Stream^.GetSize then Len := Stream^.GetSize - Pos;
end;

function TXMSLine.Stream: PStream;
begin
  Stream := XMSStream;
end;

{ ----------------------------- File Copy ------------------------------ }

function CDRomInstalled : Boolean;
var
  R : Registers;
begin
  FillChar(R, SizeOf(R), 0);
  with R do begin
    AX := $1500;
    Intr($2F, R);
    CDRomInstalled := (BX <> 0);
  end;
end;

procedure DisableAppend;
begin
 if AppendInstalled then
   asm
     mov ax, $B707
     mov bx, AppendState
     and bx, $FFFE
     push  bp
     int $2F
     pop bp
   end
end;

procedure DeleteDIZ(const DPath: PathStr; Name: Str12);
var F1: PTextReader;
    F2: Text;
    WB: Boolean;
    I: Integer;
    NM: Str12;
    S: string;
begin
  Name := MakeFileName(Name); LowStr(Name);
  FileMode := $40; DisableAppend;
  F1 := New(PTextReader, Init(DPath)); if F1 = nil then Exit;
  Assign(F2, GetPath(DPath) + '$DN'+ItoS(DNNumber)+'$.DIZ');
  DisableAppend;
  Rewrite(F2); if IOResult <> 0 then begin Dispose(F1, Done); Exit; end;
  WB := Off;
  repeat
    S := F1^.GetStr;
    if WB or (S = '') or (S[1] = ' ') then WriteLn(F2, S)
      else begin
             I := 1;
             While (I <= Length(S)) and (I <= 12) and (S[I] <> ' ') do Inc(I);
             NM := Copy(S, 1, I-1); LowStr(NM);
             if (NM = Name) or (NM = Name+'.') then
               begin
                WB := On;
                repeat
                  S := F1^.GetStr;
                until F1^.EOF or (S = '') or not (S[1] in [' ','.']) or (IOResult <> 0);
               end;
             WriteLn(F2, S);
           end;
  until F1^.EOF or (IOResult <> 0);
  ReplaceT(F1, F2);
end;

function CalcDPath(P: PDIZ; Owen: PString): PathStr;
var
  I: Integer;
  DPath: PathStr;
  SR: SearchRec;
begin
  if (P = nil) or (P^.Owner = nil) then
  begin
    for I := 1 to 128 do
    begin
      DPath := GetPossibleDizOwner(I);
      if DPath = '' then Exit;
      DPath := MakeNormName(CnvString(Owen), DPath);
      FindFirst(DPath, Archive+ReadOnly+Hidden, SR);
      if DOSError = 0 then Break;
    end;
  end else DPath := P^.Owner^;
  CalcDPath := DPath;
end;

procedure FilesCopy(Files: PCollection; Owner: PView;
                    const CopyDir, Mask: String; CopyMode, CopyOptions: Word; CopyPrn: Boolean);

var  ReadStream:  file;
     WriteStream: file;
     ReadPos: LongInt;
     CopyCancel: Boolean;
     B: Pointer;
     BSize: Word;
     TRead, TWrite,
     ToRead, ToWrite: LongInt;
     CopyQueue, Dirs: PCollection;
     Info: PWhileView;
     SoftMode: Boolean;
     R: TRect;
     Drv, InhR: Byte;
     ReD: set of Char;
     C: Char;
     SS: string[1];
     Timer: TEventTimer;
     CD_Drives: set of Char;
     AdvCopy, Use40: Boolean;
     _Tmr: TEventTimer;
     IOR: Integer;
     SSS: string;

   function GetPercent(N: Longint): Str12;
   var
     T: LongInt;
   begin
     if ToDo = 0 then N := 100 else
     begin
       T := ToDo; LowPrec(T, N);
       N := (N*100) div T;
     end;
     GetPercent := ' ('+ItoS(N)+'%)';
   end;

   function MkName(Nm: Str12): Str12;
     var I: Integer;
   begin
     for I := 1 to 12 do if Mask[I] <> '?' then Nm[I] := Mask[I];
     Nm[9] := '.';
     LowStr(Nm);
     MkName := MakeFileName(Nm);
   end;

   var
     GrdClick: Boolean;

   procedure Dispatch;
     var C: Boolean;
   procedure DE; begin GrdClick := True; DispatchEvents(Info, C) end;

   begin
     C := Off;
     if CopyCancel then begin DE; Exit end;
     if TimerExpired(_Tmr) then
     begin
       DE;
       CopyCancel := (C or CtrlBreakHit) and (MessageBox(GetString(dlQueryAbort), nil, mfYesNoConfirm) = cmYes);
       CtrlBreakHit := Off;
       NewTimer(_Tmr, 1);
     end;
   end;

   procedure ForceDispatch;
   begin
     NewTimer(_Tmr, 0); Dispatch;
   end;

   var Wrote: LongInt;
       FreeDisk: LongInt;

    procedure DoImportDIZ(const DPath: PathStr; const Name, NewName: Str12);
    var
      S: string;
      F1: PTextReader;
      F2: Text;
      I: Integer;
      NM: Str12;
    begin
      DisableAppend;
      F1 := New(PTextReader, Init(DPath)); if F1 = nil then Exit;
      S := DPath; I := Length(S);
      While (I > 0) and (S[I] <> '\') do Dec(I);
      if I > 0 then Delete(S, 1, I);
      Assign(F2, GetDIZOwner(CopyDir,S,Off)); ClrIO; {GetFAttr(F2, OldAttr);}
      DisableAppend;
      Append(F2); if Abort then begin Dispose(F1,Done); Exit; end;
      DisableAppend;
      if IOResult <> 0 then Rewrite(F2); ClrIO;
      if Abort or (IOResult <> 0) then begin Dispose(F1,Done); Exit; end;
      NM := '';
      repeat
        S := F1^.GetStr;
        if (S = '') or (S[1] in [' ','.']) then Continue;
        I := 1;
        While (I <= Length(S)) and (I <= 12) and (S[I] <> ' ') do Inc(I);
        NM := Copy(S, 1, I-1); LowStr(NM);
        if (NM = Name) or (NM = Name+'.') then Break;
      until F1^.EOF or Abort or (IOResult <> 0);
      if (NM = Name) or (NM = Name+'.') then
        begin
           I := 1;
           While (I <= Length(S)) and (I <= 12) and (S[I] <> ' ') do Inc(I);
           While (I <= Length(S)) and (I <= 12) and (S[I] = ' ') do Inc(I);
           if I > 0 then Delete(S, 1, I-1);
           DelLeft(S);
           WriteLn(F2, UpStrg(AddSpace(NewName, 13)), S);
           repeat
             S := F1^.GetStr;
             if (S <> '') and (S[1] in [' ','.']) then WriteLn(F2, S)
                                                              else Break;
           until F1^.EOF;
        end;
      Dispose(F1, Done);
      Close(F2);
    end;

    procedure ImportDIZ(Name, NewName: Str12; P: PDIZ; Owen: PString);
    var
      DizPath: PathStr;
    begin
      Name := MakeFileName(Name);
      DizPath := CalcDPath(P, Owen);
      DoImportDIZ(DizPath, Name, NewName);
      if (CopyOptions and cpoMove <> 0) and
         (FMSetup.Options and fmoPreserveDesc = 0) then DeleteDIZ(DizPath, Norm12(Name));
    end;

   procedure RemoveFromTemp(P: PFileRec);
     var I: Integer;
   begin
     if (P <> nil) and (TempFiles <> nil) then TempFiles^.DeleteFile(P);
   end;


     function Overwrite(const NName: String; OldS, NewS, OldT, NewT: LongInt): Word;
      var
          AcceptAll : word ;
          I: Word;
          D: PDialog;
          P: PView;
          R: TRect;
          S: String;
          D1, D2,
          L1, L2: String[30];
          PP: Array [1..4] of Pointer;
          {F: File;}
          DD: LongInt;
          DT: DateTime;
     begin
      AcceptAll := 0;
      Overwrite := cmSkip;
      UnPackTime(OldT, DT);
      MakeDate(DateMode, DT.Day, DT.Month, DT.Year mod 100, DT.Hour, DT.Min, D2);
      L2 := FStr(OldS);

      UnPackTime(NewT, DT);
      MakeDate(DateMode, DT.Day, DT.Month, DT.Year mod 100, DT.Hour, DT.Min, D1);
      L1 := FStr(NewS);
      If Length( L1 ) < Length( L2 )
        then L1 := PredSpace( L1, Length( L2 ))
        else L2 := PredSpace( L2, Length( L1 ));
      R.Assign(1,1,60,14);
      { New(D, Init(R, GetString(dlWarning))); }
      D := PDialog( LoadResource( dlgOverwriteQuery ));
      D^.GetExtent(R); R.Grow(-1, -1); Inc(R.A.Y);
      D^.Options := D^.Options or ofCentered;
      DelRight(D1);
      DelRight(D2);

      D1[9] := '('; AddStr( D1, ')' );
      D2[9] := '('; AddStr( D2, ')' );

      PP[1] := @D1;
      PP[2] := @L1;
      PP[3] := @D2;
      PP[4] := @L2;
      FormatStr(S, GetString(dlFCOver), PP);
      Dec( R.B.Y, 5 );
      P := New(PStaticText, Init(R,^C+GetString(dlFile)+' '+Cut(NName, 40)+S));
      D^.Insert(P);

      {
      R.Assign(6, 8, 54, 9);
      D^.Insert(New(PCheckBoxes, Init(R, NewSItem(GetString(dlYesForAll), nil))));

      R.Assign(3, 10, 16, 12);
      P := New(PButton, Init(R, GetString(dlOverwriteButton), cmYes, bfDefault));
      D^.Insert(P);
      R.Assign(16, 10, 26, 12);
      P := New(PButton, Init(R, GetString(dlAppendButton), cmNo, 0));
      D^.Insert(P);
      R.Assign(26, 10, 36, 12);
      P := New(PButton, Init(R, GetString(dlRenameButton), cmOK, 0));
      D^.Insert(P);
      R.Assign(36, 10, 46, 12);
      P := New(PButton, Init(R, GetString(dlSkipButton), cmSkip, 0));
      D^.Insert(P);
      R.Assign(46, 10, 56, 12);
      P := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, 0));
      D^.Insert(P);

      D^.SelectNext(False);
      D^.SelectNext(False);
      }

      MsgActive := On;
      D^.SetData(AcceptAll);
      I := Desktop^.ExecView(D);
      MsgActive := Off;
      NewTimer(Timer, 0);

      if I <> cmCancel then
        begin
          D^.GetData(AcceptAll);
          if (AcceptAll and 1 = 1) then
           case I of
             cmYes: CopyMode := cpmOverwrite;
             cmSkip: CopyMode := cpmSkipAll;
             cmNo: CopyMode := cpmAppend;
           end;
          OverWrite := I;
        end else Overwrite := cmSkip;

      Dispose(D, Done);

      CopyCancel := I = cmCancel;
     end;

 var SkipRequested: Boolean;
     ExAttr: Word;

   procedure MaxWrite;
     label DoRewrite, DoAppend, 1, 2, lbStartWrite, lbStartCheck, DoNotUse40;
     var I: Integer;
         J: Word;
         P: PLine;
         A,BB: LongInt;
         F: File;
         PS: Array[1..2] of Pointer;
         S1: PathStr;
         BufCrc : word ;
         Created: Boolean;
         Opened: Integer;

      procedure TryToReset;
        var F: FileRec absolute WriteStream;
            P: Pointer;
            o,Action,FileHandle: Word;
      begin
        if CopyMode = cpmOverwrite then Action := $0012
                                   else Action := $0011;
        P := @F.Name;
        asm
          push bp
          push ds
          lds  si, P
          mov  AX, $6C00    { DOS 4.0+ Extended open/create }
          mov  BX, $0042    { Extended mode flags (RTFM) }
          mov  CX, Archive  { File attribute }
          mov  DX, Action
          int  $21
          jc   @@1
          mov  FileHandle, AX
          mov  Action, CX
          mov  o, 0
          jmp  @@@

@@1:      mov  o, AX
@@@:      pop  ds
          pop  bp
        end;
        if Action > 3 then Use40 := Off else
        if o=0 then
          begin
            Created := (Action = 2) or (Action = 3);
            F.Handle := FileHandle;
            F.RecSize := 1;
            F.Mode := (F.Mode and $FFFC) or 3;
          end;
        Opened := o;
      end;

      procedure DoSkip;
      begin
        While (I < CopyQueue^.Count - 1)
              and (PLine(CopyQueue^.At(I))^.EOF and eoEnd = 0) do Inc(I);
        SkipRequested := I >= CopyQueue^.Count - 1;
      end;

    Function CheckI24Abort : boolean ;
      begin
        CheckI24Abort := Abort ;
        if not Abort then Exit ;
        CopyCancel := On ;
      end;
const
  CrcTable: array[0..255] of Word = (
    $0000,  $1021,  $2042,  $3063,  $4084,  $50a5,  $60c6,  $70e7,
    $8108,  $9129,  $a14a,  $b16b,  $c18c,  $d1ad,  $e1ce,  $f1ef,
    $1231,  $0210,  $3273,  $2252,  $52b5,  $4294,  $72f7,  $62d6,
    $9339,  $8318,  $b37b,  $a35a,  $d3bd,  $c39c,  $f3ff,  $e3de,
    $2462,  $3443,  $0420,  $1401,  $64e6,  $74c7,  $44a4,  $5485,
    $a56a,  $b54b,  $8528,  $9509,  $e5ee,  $f5cf,  $c5ac,  $d58d,
    $3653,  $2672,  $1611,  $0630,  $76d7,  $66f6,  $5695,  $46b4,
    $b75b,  $a77a,  $9719,  $8738,  $f7df,  $e7fe,  $d79d,  $c7bc,
    $48c4,  $58e5,  $6886,  $78a7,  $0840,  $1861,  $2802,  $3823,
    $c9cc,  $d9ed,  $e98e,  $f9af,  $8948,  $9969,  $a90a,  $b92b,
    $5af5,  $4ad4,  $7ab7,  $6a96,  $1a71,  $0a50,  $3a33,  $2a12,
    $dbfd,  $cbdc,  $fbbf,  $eb9e,  $9b79,  $8b58,  $bb3b,  $ab1a,
    $6ca6,  $7c87,  $4ce4,  $5cc5,  $2c22,  $3c03,  $0c60,  $1c41,
    $edae,  $fd8f,  $cdec,  $ddcd,  $ad2a,  $bd0b,  $8d68,  $9d49,
    $7e97,  $6eb6,  $5ed5,  $4ef4,  $3e13,  $2e32,  $1e51,  $0e70,
    $ff9f,  $efbe,  $dfdd,  $cffc,  $bf1b,  $af3a,  $9f59,  $8f78,
    $9188,  $81a9,  $b1ca,  $a1eb,  $d10c,  $c12d,  $f14e,  $e16f,
    $1080,  $00a1,  $30c2,  $20e3,  $5004,  $4025,  $7046,  $6067,
    $83b9,  $9398,  $a3fb,  $b3da,  $c33d,  $d31c,  $e37f,  $f35e,
    $02b1,  $1290,  $22f3,  $32d2,  $4235,  $5214,  $6277,  $7256,
    $b5ea,  $a5cb,  $95a8,  $8589,  $f56e,  $e54f,  $d52c,  $c50d,
    $34e2,  $24c3,  $14a0,  $0481,  $7466,  $6447,  $5424,  $4405,
    $a7db,  $b7fa,  $8799,  $97b8,  $e75f,  $f77e,  $c71d,  $d73c,
    $26d3,  $36f2,  $0691,  $16b0,  $6657,  $7676,  $4615,  $5634,
    $d94c,  $c96d,  $f90e,  $e92f,  $99c8,  $89e9,  $b98a,  $a9ab,
    $5844,  $4865,  $7806,  $6827,  $18c0,  $08e1,  $3882,  $28a3,
    $cb7d,  $db5c,  $eb3f,  $fb1e,  $8bf9,  $9bd8,  $abbb,  $bb9a,
    $4a75,  $5a54,  $6a37,  $7a16,  $0af1,  $1ad0,  $2ab3,  $3a92,
    $fd2e,  $ed0f,  $dd6c,  $cd4d,  $bdaa,  $ad8b,  $9de8,  $8dc9,
    $7c26,  $6c07,  $5c64,  $4c45,  $3ca2,  $2c83,  $1ce0,  $0cc1,
    $ef1f,  $ff3e,  $cf5d,  $df7c,  $af9b,  $bfba,  $8fd9,  $9ff8,
    $6e17,  $7e36,  $4e55,  $5e74,  $2e93,  $3eb2,  $0ed1,  $1ef0
  );


  function UpdateCrc(CurByte : Byte; CurCrc : Word) : Word;
    {-Returns an updated CRC16}
  begin
    UpdateCrc := CrcTable[((CurCrc shr 8) and 255)] xor
                 (CurCrc shl 8) xor CurByte;
  end;


    Function GetCrc(var Buf ; BfLen : word ): word;
     var Data : array [0..$FFF] of byte absolute Buf ;
         I : word;
         Crc : word ;
        begin
         GetCrc := 0;
         CRC := $1972 ;
         if BfLen=0 then Exit ;
         for I:=0 to Pred(BfLen) do
         CRC := UpdateCrc( Data[I] , CRC );
         GetCrc := CRC ;
        end;


   procedure NoWrite;
   begin
     CopyCancel := On;
     ForceDispatch;
     CantWrite(CnvString(P^.NewName));
   end;

   function WriteCount: string;
   begin
     WriteCount := FStr(ToWrite)+GetString(dlBytes)+GetPercent(ToWrite)+GetString(dlFC_Written);
   end;

   procedure TrySetArch;
   begin
     if (ExAttr and (ReadOnly+SysFile+Hidden) <> 0) then
     begin
       DisableAppend;
       SetFAttr(WriteStream, Archive); ClrIO;
     end;
   end;

   var WPWas: Boolean;

   procedure WriteProgress;
   begin
     Info^.Write(6, StrGrd(P^.Size, Wrote, Info^.Size.X - 6));
     Info^.Write(7, WriteCount);
   end;

   { **************** }
   { *** FileCopy *** }
   { **************** }

   begin
     SkipRequested := Off; I := -1; WPWas := False;
     if not Abort or not CopyCancel then
         while True do
           begin
1:            Inc(I); if I = CopyQueue^.Count then
              begin
                if WPWas then WriteProgress;
                Break;
              end;
              P := CopyQueue^.At(I);
              if P^.Attr and Directory <> 0 then
                begin
                  SSS := CnvString(P^.OldName);
                  if SSS[Length(SSS)] = '\' then Dec(SSS[0]);
                  ClrIO;
                  if CopyOptions and cpoMove <> 0 then RmDir(SSS);
                  if (P^.Owner <> nil) then
                    begin
                      if IOResult = 0 then
                           PFileRec(P^.Owner)^.Attr := PFileRec(P^.Owner)^.Attr or $80;
                      if (Owner <> nil) then
                         Message(Owner, evCommand, cmCopyUnselect, P^.Owner);
                    end;
                  Continue;
                end;
              if P^.EOF and eoStart <> 0 then
                begin
2:
                  ExAttr := $FFFF;
                  Wrote := 0;
                  Info^.Write(5, GetString(dlFC_Writing)+Cut(P^.NewName^, 40)+' ');
                  Info^.Write(6, Strg(#177, Info^.Size.X - 6));
                  Info^.Write(7, WriteCount);
                  Dispatch; GrdClick := False;
                  Assign(WriteStream, CnvString(P^.NewName)); ClrIO;
                  FileMode := $42;

                  if (CopyOptions and cpoCheckFree <> 0) and (Disk_Free(Drv) < P^.Size) then
                   begin
                     Byte(PS[1]) := Drv+64;
                     PS[2] := P^.OldName;
                     Assign(WriteStream, '');
                     ForceDispatch;
                     CopyCancel := Msg(erNotDiskSpace1, @PS, mfError+mfYesButton+mfNoButton) <> cmYes;
                     NewTimer(Timer, 0);
                     DoSkip;
                     if not SkipRequested then Goto 1;
                     if (not CopyCancel) then Continue;
                     Break;
                   end;

                  if P^.EOF and eoCheck <> 0 then
                    begin
                       DisableAppend;
                       if Dos40 and Use40 then
                         begin
                           TryToReset;
                           if not Use40 then goto DoNotUse40;
                           {
                              begin
                                 Use40 := FileSize(WriteStream) = 0;
                                 Close(WriteStream); ClrIO;
                                 if Use40 then Erase(WriteStream);
                                 ClrIO; Use40 := Off;
                                 Goto DoNotUse40;
                              end;
                           }
                           case Opened of
                             0 : begin
                                   if Created then Goto lbStartWrite else
                                                   Goto lbStartCheck;
                                 end;
                             5 : goto lbStartCheck;
                            else begin
                                   NoWrite;
                                   Break;
                                 end;
                           end;
                         end else
                         begin
DoNotUse40:
                           ClrIO; FileMode := $40;
                           Reset(WriteStream, 1);
                         end;

                       if InOutRes = 0 then
                         begin
lbStartCheck:
                            case CopyMode of
                              cpmOverwrite: Goto DoRewrite;
                              cpmAppend: Goto DoAppend;
                              cpmSkipAll: begin
                                             Info^.Write(2, GetString(dlFC_Exists));
                                             Close(WriteStream);
                                             DoSkip;
                                             if not SkipRequested then Goto 1;
                                             Break;
                                          end;
                              cpmRefresh: begin
                                            GetFTime(WriteStream, A);
                                            if A >= P^.Date then
                                              begin
                                                Info^.Write(2, GetString(dlFC_Older));
                                                Close(WriteStream);
                                                DoSkip;
                                                if not SkipRequested then Goto 1;
                                                Break;
                                              end;
                                          end;
                              else begin
                                      ClrIO; Close(WriteStream); ClrIO;
                                      GetFTimeSizeAttr(CnvString(P^.NewName), A, BB, ExAttr);
                                      if DosError <> 0 then
                                      begin
                                        NoWrite;
                                        Break;
                                      end;
                                      case Overwrite(CnvString(P^.NewName), BB, P^.Size, A, P^.Date) of
                                         cmSkip: begin
                                                   DoSkip;
                                                   if not SkipRequested then Goto 1;
                                                   Break;
                                                 end;
                                         cmOK: begin
                                                 S1 := CnvString(P^.NewName);
                                                 J := InputBox(GetString(dlFCRename), GetString(dlFCRenameNew),
                                                           S1, 79, 0);
                                                 if (J <> cmOK) or (S1 = '')  then
                                                   begin
                                                      DoSkip;
                                                      if not SkipRequested then Goto 1;
                                                      Break;
                                                   end;
                                                 DisposeStr(P^.NewName);
                                                 P^.NewName := NewStr(S1);
                                                 NewTimer(Timer, 0);
                                                 Goto 2;
                                               end;
                                         cmNo: Goto doAppend;
                                         cmYes: Goto doRewrite;
                                           else begin
                                                  CopyCancel := On;
                                                  Break;
                                                end;
                                      end;
                                   end;
                            end;
                         end;
                    end;
                  if P^.EOF and eoAppend <> 0 then
                    begin
DoAppend:
                      DisableAppend;
                      FileMode := $42;
                      Reset(WriteStream, 1);
                      J := IOResult;
                      case J of
                        0 : begin
                              ExAttr := $FD00;
                              Seek(WriteStream, FileSize(WriteStream));
                            end;
                        2 : Goto DoRewrite;
                        5 : begin
                              if ExAttr = $FFFF then
                              begin
                                ClrIO;
                                DisableAppend;
                                GetFAttr(WriteStream, ExAttr);
                                if IOResult = 0 then TrySetArch
                              end else TrySetArch;
                              if CheckI24Abort then Break ;
                              ExAttr := ExAttr or $FE00;
                              DisableAppend;
                              Reset(WriteStream, 1);
                              if IOResult = 0 then Seek(WriteStream, FileSize(WriteStream));
                            end;
                       end;
                    end else
                          begin
DoRewrite:
                             ClrIo;
                             DisableAppend;
                             Rewrite(WriteStream, 1);
                             if CheckI24Abort then Break ;
                             if (InOutRes = 5) then
                             begin
                                ClrIO;
                                if ExAttr = $FFFF then
                                begin
                                  DisableAppend;
                                  GetFAttr(WriteStream, ExAttr);
                                  if IOResult = 0 then TrySetArch;
                                end else TrySetArch;
                                if CheckI24Abort then Break ;
                                DisableAppend;
                                Rewrite(WriteStream, 1);
                             end;
                          end;

                  if CheckI24Abort then Break ;
                  if IOResult <> 0 then
                    begin
                      NoWrite;
                      Break;
                    end;
                end;
lbStartWrite:
              P^.Read(B^);
              ClrIO;
              Dispatch;
              if CopyCancel then Break;
              if  CopyOptions and cpoVerify <> 0 then SeekPos := FilePos(WriteStream);
              BlockWrite(WriteStream, B^, P^.Len, J); IOR := IOResult;

              if not Abort and (CopyOptions and cpoVerify <> 0)  and (J > 0) then begin
                   asm
                     mov ah,0dh
                     int 21h
                   end;

                   BufCRC := GetCrc( B^ , P^.Len );

                   Seek( WriteStream, SeekPos ); ClrIO;
                   BlockRead(WriteStream, B^, P^.Len, J);

                   if CheckI24Abort then Break ;

                   if (IoResult <> 0) or
                      (J <> P^.Len ) or
                      ( GetCrc( B^ , P^.Len ) <> BufCrc )
                      then
                      begin
                       ForceDispatch;
                       MessageBox(GetString(dlFCVerifyFailed), nil, mfError+mfOKButton);
                       CopyCancel := On ;
                       Break ;
                      end;
                 end;

              Dispatch;
              if Abort or CopyCancel then Break;
              Inc(Wrote, J);
              Inc(ToWrite, J);

              if GrdClick then
              begin
                WriteProgress;
                GrdClick := False;
                WPWas := False
              end else WPWas := True;

              if ( J <> P^.Len ) or ( IOR <> 0 ) then begin
                CopyCancel := On;
                ForceDispatch;
                if (CopyPrn) or
                   (IOR = 5) or
                   (Disk_Free(Drv) > P^.Size)
                 then NoWrite else ErrMsg(dlFBBDiskFull2);
                Break;
              end;

              if P^.EOF and eoEnd <> 0 then
                begin
                  case ExAttr shr 8 of
                    $FD, $FE : ;
                    else SetFTime(WriteStream, P^.Date);
                  end;
                  WriteProgress; WPWas := False;
                  Close(WriteStream);
                  DisableAppend;
                  case ExAttr shr 8 of
                    $FF : { Set Source Attribute, if Necessary }
                      if P^.Attr <> Archive then
                               SetFAttr(WriteStream, P^.Attr);
                    $FE : { Set Dest' Attribute }
                               SetFAttr(WriteStream, ExAttr and $FF);
                    $FD : { Don't Set any attribute } ;
                   else   { Set Source Attribute, Force }
                               SetFAttr(WriteStream, P^.Attr);
                  end;
                  if (P^.Owner <> nil) then
                    begin
                      PFileRec(P^.Owner)^.Attr := PFileRec(P^.Owner)^.Attr or $80;
                      if (Owner <> nil) then Message(Owner, evCommand, cmCopyUnselect, P^.Owner);
                      if (PFileRec(P^.Owner)^.DIZ <> nil) or (CopyOptions and cpoDesc <> 0) then
                         begin
                            Info^.Write(6, GetString(dlExportingDIZ));
                            ImportDIZ(PFileRec(P^.Owner)^.Name,
                                      GetName(P^.NewName^),
                                      PFileRec(P^.Owner)^.DIZ, PFileRec(P^.Owner)^.Owner);
                         end;
                    end;
                  if CopyOptions and cpoFromTemp <> 0 then RemoveFromTemp(P^.Owner);
                  if CopyOptions and cpoMove <> 0 then
                    begin
                      Info^.Write(6, GetString(dlDeletingSource));
                      EraseFile( CnvString( P^.OldName ));
                    end;
                end;
           end;
     FreeDisk := -1;
     CopyQueue^.FreeAll;
     if MemStream <> nil then MemStream^.Seek(0);
     if EMSStream <> nil then EMSStream^.Seek(0);
     if XMSStream <> nil then XMSStream^.Seek(0);
   end;

   procedure MakeBuffer;
     var I: LongInt;
   begin
      I := MemAvail - $4000;
      if I > MaxAvail-$2000 then I := MaxAvail-$2000;
      if I < 512 then Exit;
      if I > $E000 then I := $C000 else
      if I > $C000 then I := $A000 else
      if I > $8000 then I := $6000 else
      if I > $4000 then I := $2000 else
      if I > $1000 then I := $800 else I := 0;
      B := MemAlloc(I);
      BSize := I;
   end;

   var DOSErrorCode: Word;

   procedure RnFl(n1,n2 : PathStr);
    var p1,p2 : Pointer;
        DOSE: Word;
   begin
    p1:=@n1;p2:=@n2;
    n1[Byte(n1[0])+1]:=#0;
    n2[Byte(n2[0])+1]:=#0;
    asm
     push ds
     push ss
     les  di,p2
     inc  di
     lds  dx,p1
     inc  dx
     mov  ah,$56
     int  $21
     jc   @@1
     xor  ax, ax
    @@1:
     mov  DOSE, ax
     pop  ss
     pop  ds
    end;
    DOSErrorCode := DOSE;
   end;

   procedure CopyFile(const FName, AddDir: PathStr; Own: Pointer; Ln, Dtt: LongInt; Attr: Word);
     label 1;
     var P: PLine;
         Rd, WW, A, BB: LongInt;
         I, J: Word;
         FFF: Boolean;
         Was: LongInt;
         EOF: Byte;
         NName,S1,S2: PathStr;
         SR: SearchRec;
         PS: Array [1..2] of Pointer;

     procedure RenameFile;
      var
          F: File;
          W: Word;
     begin
      DOSErrorCode := 0;
      RnFl(S1, S2);
      Assign(f, S2);
      if DOSErrorCode = 5 then
        begin ClrIO; SetFAttr(F, Archive); ClrIO; Erase(F); RnFl(S1, S2); end;
      if DOSErrorCode = 5 then
        begin
          Assign(F, S1); GetFAttr(F, W); ClrIO; SetFAttr(F, Archive); ClrIO;
          RnFl(S1, S2); SetFAttr(F, W); ClrIO;
        end;
      if not (DOSErrorCode in [0,18]) then
        begin
          ForceDispatch;
          MessageBox(GetString(dlFCNoRename1)+GetString(dlDIFile)+^M^C+Cut(S1,40)
                    +GetString(dlFCNoRename2)+Cut(S2,40), nil, mfError+mfOKButton);
          CopyCancel := On;
        end;
     end;

     procedure DoRename;
       var A: Array [0..10] of PString;
           I,J: Integer;
     begin
       for I := 0 to Min(10, Info^.Lines^.Count-1) do
        begin
          A[I] := Info^.Lines^.At(I);
          Info^.Lines^.AtPut(I, nil);
        end;
       Info^.Write(2, Cut(FName,40));
       Info^.Write(4, GetString(dlFC_To));
       Info^.Write(6, Cut(NName,40));
       Dispatch;
       if not CopyCancel then RenameFile;
       if not CopyCancel and (Own <> nil) then
         begin
          {
          if SoftMode and (TempFiles <> nil) then J := 1
                                             else J := -1;
          }
          PFileRec(Own)^.Attr := PFileRec(Own)^.Attr or $80;
          if (PFileRec(Own)^.DIZ <> nil) or (CopyOptions and cpoDesc <> 0) then
             begin
                Info^.Write(6, GetString(dlExportingDIZ));
                ImportDIZ(PFileRec(Own)^.Name,
                          GetName(NName),
                          PFileRec(Own)^.DIZ, PFileRec(Own)^.Owner);
             end;
          PFileRec(Own)^.Name := Norm12(GetName(NName));
          PFileRec(Own)^.Name[9] := ' ';
          {if J > 0 then PFileRec(TempFiles^.At(J))^.Name := PFileRec(Own)^.Name;}
          if (Owner <> nil) then Message(Owner, evCommand, cmCopyUnselect, Own);
          Inc(ToWrite, Ln);
          Inc(ToRead, Ln);
         end;
       Info^.DrawView;
       for I := 0 to Min(10, Info^.Lines^.Count-1) do
          Info^.Lines^.AtReplace(I, A[I]);
     end;

   label NoRename;

   function ReadCount: string;
   begin
     ReadCount := FStr(ToRead)+GetString(dlBytes)+GetPercent(ToRead)+GetString(dlFC_WasRead);
   end;

   procedure ReadProgress;
   begin
     Info^.Write(2, StrGrd(Ln, ReadPos, Info^.Size.X - 6));
     Info^.Write(3, ReadCount);
   end;

   begin

      if CopyPrn then
      begin
        NName := CopyDir;
        while NName[Length(NName)]='\' do dec(NName[0]);
      end else
      begin
        if SoftMode then
          NName := MakeNormName(GetPath(FName), MkName(Norm12(GetName(FName)))) else

        if AddDir = '' then NName := MkName(Norm12(GetName(FName)))
                       else NName := AddDir+'\'+GetName(FName);

        NName := MakeNormName(CopyDir, NName);
     1:
        S1 := Advance.FExpand(FName);
        S2 := Advance.FExpand(NName);
        if S1 = S2 then
           begin
             if CopyOptions and cpoMove = 0 then
              begin
                if CopyQueue^.Count > 0 then MaxWrite; if CopyCancel then Exit;
                ForceDispatch;
                MessageBox(^C+GetString(dlFile)+' '+FName + GetString(dlFCItself), nil,
                   mfError + mfOKButton);
                CopyCancel := On;
              end;
             Exit;
           end;
      end;

      Was := 0;
      ClrIO; Assign(ReadStream, FName);
      if S1[1] in CD_Drives then Attr := Attr and not ReadOnly;

      {
      if DosError <> 0 then
        begin
           ClrIO;
           if CopyQueue^.Count > 0 then MaxWrite; if CopyCancel then Exit;
           ForceDispatch;
           MessageBox(GetString(dlFBBNoOpen)+FName, nil, mfError+mfOKButton);
           CopyCancel := On;
           Exit;
        end;
      }

      FileMode := $40;
      DisableAppend;
      Reset(ReadStream, 1); ReadPos := 0;

      if Abort then
      begin
         ClrIO;
         if CopyQueue^.Count > 0 then MaxWrite;
         CopyCancel := On;
         Exit;
      end;

      if IOResult <> 0 then
        begin
           ClrIO;
           if CopyQueue^.Count > 0 then MaxWrite; if CopyCancel then Exit;
           ForceDispatch;
           MessageBox(GetString(dlFBBNoOpen)+FName, nil, mfError+mfOKButton);
           CopyCancel := On;
           Exit;
        end;
      Rd := 0;
      EOF := eoStart or eoCheck * Byte(CopyMode >= cpmAppend);
      if (CopyMode >= cpmAppend) and (CopyOptions and cpoMove <> 0)  and
         (S1[1] = S2[1]) then
        begin
           ClrIO; EOF := eoStart or eoCheck;
           FindFirst(S2, $3F xor VolumeID, SR);
           if DOSError = 0 then

             begin
               EOF := eoStart;
               Was := SR.Size;
               if SR.Attr and Directory <> 0 then
                   begin
                      if CopyQueue^.Count > 0 then MaxWrite; if CopyCancel then Exit;
                      ForceDispatch;
                      MessageBox(GetString(dlFCNotOverDir)+Cut(S2,40), nil, mfError+mfOKButton);
                      Exit;
                   end;
               case CopyMode of
                 cpmAskOver: NoRename:
                             case Overwrite(NName, SR.Size, Ln, SR.Time, Dtt) of
                               cmSkip: begin Close(ReadStream); Exit; end;
                               cmOK: begin
                                       if InputBox(GetString(dlFCRename), GetString(dlFCRenameNew),
                                            NName, 79, 0) <> cmOK then goto NoRename;
                                       NewTimer(Timer, 0);
                                       Goto 1;
                                     end;
                               cmNo: EOF := EOF or eoAppend;
                             end;
                 cpmRefresh: if Dtt <= SR.Time then
                               begin
                                 Info^.Write(1, GetString(dlFC_Reading)+Cut(FName, 40));
                                 Info^.Write(2, GetString(dlFC_Older));
                                 Close(ReadStream);
                                 Exit;
                               end;
                 cpmSkipAll: begin
                               Info^.Write(1, GetString(dlFC_Reading)+Cut(FName, 40));
                               Info^.Write(2, GetString(dlFC_Exists));
                               Close(ReadStream);
                               Exit;
                             end;
                 cpmAppend: EOF := EOF or eoAppend;
               end;
             end;
        end;
      if (CopyOptions and cpoMove <> 0) and (EOF and eoAppend = 0) and
         (S1[1] = S2[1]) then
         begin
           Close(ReadStream);
           DoRename;
           Exit
         end;
      (* !!!
      if CopyOptions and cpoCheckFree <> 0 then
        begin
          if FreeDisk < 0 then
           begin
            GetDrInfo(Drv);
            FreeDisk := FreeSpc;
           end;
          Inc(FreeDisk, LongInt(EOF and eoAppend = 0)*GetRndBytes(Was, BytePerClu));
          Byte(PS[1]) := Drv+64;
          PS[2] := @FName;
          if FreeDisk < Ln then
            begin
              Close(ReadStream);
              CopyCancel := Msg(erNotDiskSpace1, @PS, mfError+mfYesButton+mfNoButton) <> cmYes;
              NewTimer(Timer, 0);
              Exit;
            end;
          Dec(FreeDisk, GetRndBytes(Ln, BytePerClu));
        end;
      *)
      if B = nil then MakeBuffer;
      if B = nil then
         begin
           CopyCancel := On;
           Application^.OutOfMemory;
           Close(ReadStream);
           Exit;
         end;
      Info^.Write(1, GetString(dlFC_Reading)+Cut(FName, 40)+' ');
      Info^.Write(2, Strg(#177, Info^.Size.X - 6));
      Info^.Write(3, ReadCount);
      Dispatch; GrdClick := False;
      {Info^.DrawView;}
      repeat
        SkipRequested := Off;
        WW := Ln - Rd;
        if WW > BSize then WW := BSize;
        P := nil;

        if AdvCopy then
        begin
          P := New(PXMSLine, Init( WW,  Own, FName, NName, Ln, Dtt, Attr, EOF));
          if P = nil then P := New(PEMSLine, Init( WW,  Own, FName, NName, Ln, Dtt, Attr, EOF));
        end;

        if P = nil then P := New(PLine, Init( WW,  Own, FName, NName, Ln, Dtt, Attr, EOF));
        if P = nil then
          begin
            if CopyQueue^.Count = 0 then
               begin
                 Close(ReadStream);
                 CopyCancel := On;
                 if B <> nil then FreeMem(B, BSize);
                 B := nil;
                 Application^.OutOfMemory;
                 Exit;
               end;
            ReadProgress;
            MaxWrite;
            if SkipRequested then Break;
            Continue
          end;
        J := 0;
        Dispatch;
        if WW > 0 then BlockRead(ReadStream, B^, WW, J); Inc(ReadPos, J);
        Dispatch;
        if CopyCancel then Break;
        if Abort then
          begin
             ClrIO;
             if CopyQueue^.Count > 0 then MaxWrite;
             CopyCancel := On;
             Break;
          end;
        if ReadPos >= Ln then
          begin
            EOF := EOF or eoEnd;
            if P^.OldName = nil then P^.OldName := NewStr(FName);
          end;
        P^.EOF := EOF;
        if WW <> J then
          begin
            CopyCancel := On;
            Break;
          end;

        Inc(ToRead, J);

        Dispatch;
        if GrdClick then
        begin
          ReadProgress;
          GrdClick := False;
        end;

        P^.Write(B^);
        CopyQueue^.Insert(P);
        if Abort or CopyCancel then Break;
        EOF := EOF and not eoStart;
        Inc(Rd, WW);
        if CopyQueue^.Count > 400 then MaxWrite;
      until CopyCancel or Abort or (Rd = Ln) or SkipRequested;
      SkipRequested := Off;
      ClrIO;
      ReadProgress;
      Close(ReadStream);
      if not AdvCopy then MaxWrite;
   end;

   procedure CopyDirectory(const DirName, AddDir: PathStr; Own: Pointer);
     var SR: SearchRec;
         P: PLine;
         L: LongInt;
   begin
     ClrIO;
     FindFirst(DirName+'\*.*', $3F xor VolumeID, SR);
     while (DOSError = 0) and not Abort and not CopyCancel do
       begin
         SSS := AddDir+'\'+SR.Name;
         if SR.Attr and Directory = 0 then
           begin
              LowStr(SR.Name);
              CopyFile(UpStrg(DirName)+'\'+SR.Name, Copy(AddDir,Length(CopyDir)+1,255), nil, SR.Size, SR.Time, SR.Attr);
           end;
         if CopyCancel or Abort then Exit;
         ClrIO;
         FindNext(SR);
       end;
     if CopyCancel or Abort then Exit;
     L := 0;
     P := New(PLine, Init( L,  Own, DirName, '', 0, 0, Directory, eoStart+eoDir));
     if P <> nil then CopyQueue^.Insert(P);
   end;

   procedure MaxRead;
     var I: Integer;
         P: PFileRec;
         S: PathStr;

     procedure DoCopyDirectory(P: PDirName); far;
     begin
       if P^.CopyIt then CopyDirectory(P^.Old, P^.New, P^.Own);
     end;

   begin
     for I := 0 to Files^.Count - 1 do
       begin
         P := Files^.At(I);
         S := MakeNormName(P^.Owner^, MakeFileName(P^.Name));
         if P^.Attr and Directory = 0 then CopyFile(S,'',P, P^.Size, PackedDate(P), P^.Attr);
         if Abort or CopyCancel then Exit;
       end;
     if Abort or CopyCancel then Exit;
     if Dirs <> nil then Dirs^.ForEach(@DoCopyDirectory);
     MaxWrite;
   end;

  procedure DoneStreams;
  begin
    if MemStream <> nil then
      begin
         MemStream^.Seek(0);
         MemStream^.Read(SSS,1);
         Dispose(MemStream,Done);
         MemStream := nil;
      end;
    if EMSStream <> nil then
      begin
         EMSStream^.Seek(0);
         EMSStream^.Read(SSS,1);
         EMSCurHandle := $FFFF;
         EMSCurPage := $FFFF;
         Dispose(EMSStream,Done);
         EMSStream := nil;
         EMSCurHandle := $FFFF;
         EMSCurPage := $FFFF;
      end;
    if XMSStream <> nil then
      begin
         Dispose(XMSStream,Done);
         XMSStream := nil;
      end;
  end;

  procedure MakeDirectories;
    var P: PFileRec;
        PD: PDirName;
        I: Integer;
        S: PathStr;
        FrPos: Integer;

    procedure CopyI(Dest, Source: String;
                    Name: Str12;
                    O: PFileRec; CopyIt: Boolean;
                    Attr: Byte);
      label 1, 2;
      var JJ: Integer;
    begin
      Info^.Write(5, GetString(dlFCCheckingDirs)); UpStr(Name);
      if (not CopyPrn) and (Dest <> '') and (Dest[Length(Dest)] <> '\') then AddStr(Dest, '\');
      if O = nil then
         begin
           {if CopyOptions and cpoRecurse = 0 then
             begin
               if (Dest <> '') and (Dest[Length(Dest)-1] <> ':') then Dec(Dest[0], 2);
               Name := '';
             end;}
           Goto 1;
         end;
      if CopyCancel then Goto 2;
      ClrIO;
      SSS := Source;
      SSS := SSS+Copy('\',1,Byte(SSS[Length(SSS)] <> '\'));
      UpStr(SSS);
      if SSS = Copy(S, 1, Length(SSS)) then
        begin
          ForceDispatch;
          MessageBox(^C + GetString(dlDirectory) + ' ' + Cut(Source, 40) +
                     GetString(erIntoItself), nil, mfError+mfOKButton);
          CopyCancel := On;
          Exit;
        end;
      {if CopyOptions and cpoRecurse <> 0 then}
        begin
          Dec(SSS[0]);
          if (O <> nil) and (CopyOptions and cpoMove <> 0) and (GetPath(SSS)=S) then
            begin
              CopyIt := Off;
              O^.Attr := O^.Attr or $C0;
              Info^.Write(5, '');
              Info^.Write(2, Cut(SSS,40));
              Info^.Write(4, GetString(dlFC_To));
              Source := Advance.FExpand(Dest+Name);
              Info^.Write(6, Cut(Source,40));
              ClrIO;
              RnFl(SSS, Dest+Name);
              if DOSErrorCode = 5 then
                begin
                  GetDir(0, ActiveDir);
                  Advance.ChDir(GetPath(SSS));
                  RnFl(GetName(SSS), Name);
                  ChDir(ActiveDir);
                end;
              if Abort then begin CopyCancel := On; Goto 2; end;
              if DOSErrorCode <> 0 then
                begin
                  ForceDispatch;
                  MessageBox(GetString(dlNotRenameDir)+Source, nil,
                               mfError + mfOKButton);
                  CopyCancel := On;
                  Goto 2;
                end;
              CreateDirectory(Dest+Name, Off);
              CreateDirectory(SSS, On);
              Info^.Write(2, ''); Info^.Write(4, ''); Info^.Write(6, '');
              Info^.Write(5, GetString(dlFCCheckingDirs));
              O^.Name := UpStrg(Norm12(Name));
              O^.Name[9] := ' ';
              if Owner <> nil then Message(Owner, evCommand, cmCopyUnselect, O);
              O^.Attr := O^.Attr or VolumeID;
              Goto 1;
            end else
                 begin
                   ClrIO;
                   if not CopyPrn then
                   begin
                     MkDir(Dest+Name);
                     if IOResult = 0 then
                        SetFileAttr(Dest+Name+#0, Attr and not Directory)
                   end;
                 end;
          if Abort then begin CopyCancel := On; Goto 2; end;
          if not CopyPrn then CreateDirectory(Dest+Name, Off);
        end;
  1:
     if CopyPrn then
     begin
       if Dest = '' then SSS := Name else SSS := Dest;
     end else SSS := Dest + Name;
     Dirs^.AtInsert(FrPos, New(PDirName, Init(Source, SSS, CopyIt, O, Attr)));
     Inc(FrPos);
  2:
    end;

    procedure CopyF(Dest, Source: String; CopyIt: Boolean; Attr: Byte);
      var SR: SearchRec;
    begin
      if Dest[Length(Dest)] = '\' then Dec(Dest[0]);
      ClrIO;
      if not CopyPrn then
      begin
        MkDir(Dest);
        if IOResult = 0 then
          begin
             SetFileAttr(Dest+#0, Attr and not Directory);
             CreateDirectory(Dest, Off);
          end;
        ClrIO;
      end;
      FindFirst(Source+'\*.*', $3F xor VolumeID, SR);
      while (DOSError = 0) and not Abort and not CopyCancel do
        begin
          if (SR.Attr and Directory <> 0) and (SR.Name[1] <> '.') then
          begin
            CopyI(Dest, Source+'\'+SR.Name, SR.Name, nil, CopyIt, SR.Attr)
          end else Inc(ToDo, SR.Size);
          ClrIO;
          Dispatch;
          if not CopyCancel then FindNext(SR);
        end;
    end;

    label 1;

    function NoCheck(P: PDirName): Boolean; far;
    begin
      Inc(FrPos);
      NoCheck := not P^.Check;
    end;


  begin
    New(Dirs, Init(10, 10));

    if not CopyPrn then
    begin
      S := CopyDir;
      Inhr := CreateDirInheritance(S, On);
      if Inhr = 0 then Inhr := Length(S);
      Drv := Byte(S[1])-64; ReD := [S[1]];
      if SystemData.Drives[S[1]] and ossVerify <> 0 then CopyOptions := CopyOptions or cpoVerify;
    end;
    for I := 0 to Files^.Count - 1 do
      begin
        P := Files^.At(I);
        if P^.Attr and Directory <> 0 then
         begin
            FrPos := Dirs^.Count;
            CopyI(CopyDir, MakeNormName(P^.Owner^, MakeFileName(P^.Name)),
                   MkName(P^.Name),P, On, P^.Attr and $3F);
            if not (Abort or CopyCancel) and
               (P^.DIZ <> nil) or (CopyOptions and cpoDesc <> 0) then
                ImportDIZ(LowStrg(P^.Name), MkName(P^.Name), P^.DIZ, P^.Owner);
         end else Inc(ToDo, P^.Size);
        if CopyCancel then Break;
      end;
1:  repeat
      FrPos := -1;
      PD := Dirs^.FirstThat(@NoCheck);
      if PD = nil then Break;
      CopyF(PD^.New, PD^.Old, PD^.CopyIt, PD^.Attr and $3F);
      PD^.Check := On;
    until False;
    Info^.Write(5, '');
  end;

 procedure __Remove;
 var
   RRC: PStringCollection;

 procedure DoRemove(P: PFileRec); far;

   procedure MakeMark(P: PFileRec); far;
   begin
     if (Copy(P^.Owner^,1,Length(SSS))=SSS) then
          P^.Attr := P^.Attr or $40;
   end;

 begin


    if (P^.Attr and $80 <> 0) then
      begin
        if P^.Attr and (Directory+VolumeID) = Directory then
           begin
            CreateDirectory(MakeNormName(P^.Owner^, MakeFileName(P^.Name)), On);
           end;
        if P^.Attr and $40 = 0 then
          begin
            SSS := CnvString(P^.Owner);
            if SSS[Length(SSS)] = '\' then Dec(SSS[0]);
            if Copy(CopyDir, 1, Length(SSS))=SSS then Inhr := 0;
            RRC^.Insert(NewStr(SSS));
            if P^.Attr and Directory <> 0 then ReD := ReD + [UpCase(SSS[1])];
            Files^.ForEach(@MakeMark);
          end;
      end;
 end;

 procedure DoReread(P: PString); far;
 begin
   RereadDirectory(P^);
 end;

 begin
   RRC := New(PStringCollection, Init($10, $8));
   Files^.ForEach(@DoRemove);
   RRC^.ForEach(@DoReread);
   FreeObject(RRC);
 end;


 procedure DoReset(P: PFileRec); far;
 begin
    P^.Attr := P^.Attr and $3F;
    CD_Drives := CD_Drives + [UpCase(P^.Owner^[1])];
 end;

 label 1;

var
  Flush: Boolean;

begin
  Dirs := nil;
  AdvCopy := (not CopyPrn) and (SystemData.Options and ossAdvCopy <> 0);
  Use40 := Dos40 and AdvCopy;
  SoftMode := (CopyOptions and cpoDirEmpty <> 0) and
              (CopyOptions and (cpoMove+cpoFromTemp) = (cpoMove+cpoFromTemp));
  NewTimer(Timer, 0);
  NewTimer(_Tmr, 0); GrdClick := True;
  FreeDisk := -1;
  CopyCancel := Off;
  ReD := [];
  CD_Drives := [];
  AppendInstalled := Off;
  if Dos40 then
    asm
      mov  ax, $B700
      push bp
      int  $2F
      pop  bp
      or   al, al
      jz   @@1
      inc  AppendInstalled
      mov  ax, $B706
      push bp
      int  $2F
      pop  bp
      mov  AppendState, BX
@@1:
    end;
  ToRead := 0; ToWrite := 0; ToDo := 0;
  R.Assign(0,0,40,13);
  New(Info, Init(R));
  if CopyOptions and cpoMove <> 0 then Info^.Top := GetString(dlFCMove)
                              else Info^.Top := GetString(dlFCCopy);
  Desktop^.Insert(Info);
  Files^.ForEach(@DoReset);
  if (SystemData.Options and ossRemoveCD_RO <> 0) and CDRomInstalled then
    begin
       for SSS[1] := 'A' to 'Z' do
        if (SSS[1] in CD_Drives) and not IsDriveCDROM(SSS[1]) then
           CD_Drives := CD_Drives - [SSS[1]];
    end else CD_Drives := [];
  MakeDirectories;
  if CopyCancel then Goto 1;
  MemStream := nil;
  EMSStream := nil; NoUseEMS := Off;
  XMSStream := nil; NoUseXMS := Off;
  B := nil;
  New(CopyQueue, Init(250, 100));
  Info^.Bottom := GetString(dlFC_Total)+FStr(ToDo) +GetString(dlBytes);
  Info^.DrawView;
  MaxRead;
  if Abort or CopyCancel then
    begin
      ClrIO;
      Close(ReadStream);
      ClrIO;
      Close(WriteStream);
      if IOResult = 0 then Erase(WriteStream);
    end else if (FMSetup.Options and fmoBeep <> 0)
    {and
                (ElapsedTimeInSecs(Timer) > 30)} then BeepAfterCopy;
  if B <> nil then FreeMem(B, BSize);
  Dispose(CopyQueue, Done);
  DoneStreams;
1:
  Flush := (SystemData.Options and ossFlushDsk <> 0);
  if Flush then
  begin
    Info^.ClearInterior;
    Info^.Write(5, GetString(dlFlushingBuffers)+'...');
  end else FreeObject(Info);

  if AppendInstalled then
    asm
      mov ax, $B708
      mov bx, AppendState
      push bp
      int  $2F
      pop  bp
    end;
  if Dirs <> nil then Dispose(Dirs, Done);
  if CopyOptions and cpoMove <> 0 then __Remove;
  for C := 'A' to 'Z' do
    if C in ReD then
      begin
        SSS := C;
        GlobalMessage(evCommand, cmRereadTree, @SSS);
      end;
  SSS := Copy(Advance.FExpand(CopyDir), 1, Inhr);
  if (Inhr <> 0) then RereadDirectory(SSS);
  Message(Owner, evCommand, cmRecountDirs, nil);
  if Flush then
  begin
    asm
      mov ah,0dh
      int 21h
    end;
    FreeObject(Info);
  end;
end;

const ccCopyMode: Byte = 2;
      ccCopyOpt: Byte = 0;


function CopyDialog;

  var
    PF: PFileRec;
    D: PDialog;
    P, P1: PView;
    R: TRect;
    S,S1,S4: String;
    DT: Record
     S3: String[70];
     WW: Word;
     WW1: Word;
    end;
    Nm: NameStr;
    Xt: ExtStr;
    SR: SearchRec;
    Idx: TDlgIdx;
    I: Integer;
    SSS: string;
begin
   CopyDialog := Off;
   If MoveMode
     then Idx := dlgRenameDialog
     else Idx := dlgCopyDialog;
   DT.WW := ccCopyMode; DT.WW1 := ccCopyOpt;
   DT.WW1 := DT.WW1 and not cpoMove;
   if MoveMode and (FromTemp <> 1) then DT.WW1 := DT.WW1 or cpoMove;
   if LowMemory then Exit;
   D := PDialog(Application^.ValidView(PView(LoadResource(Idx))));
   if D = nil then Exit;
   R.Assign(2,1,D^.Size.X-1,2);
   if MoveMode then S := GetString(dlFCMoveTo) else S := GetString(dlFCCopyTo);
   Replace('~',#0,S); S := #0+S;
   DT.S3 := '';
   if Files^.Count = 1 then
    begin
     PF := Files^.At(0);
     S1 := MakeFileName(PF^.Name); {Replace('~',#0,S1); Replace(#0,'~~',S1);}
     S1 := #0+S1+#0;
     if MoveMode then DT.S3 := S1;
     if PF^.Attr and Directory = 0 then S1 := ' '+GetString(dlDIFile)+' '
       +S1 else S1 := ' '+GetString(dlDirectory)+' '+S1;
    end
    else S1 := ' '#0+ItoS(Files^.Count)+' '+GetString(dlDIFiles) + #0' ';
   System.Insert(S1,S, PosChar(' ',S));
   if MoveMode then S := GetString(dlFCMoveOr) + S;
   P1 := New(PLabel, Init(R, S, D^.Current));
   D^.Insert(P1);

   if MoveMode and (Files^.Count = 1)
     then DT.S3 := MakeFileName(PFileRec(Files^.At(0))^.Name)
     else GlobalMessage(evCommand, cmPushName, Pointer(hsFileCopyName));
   S4 := '';
   if Owner <> nil then Message(Owner^.Owner, evCommand, cmPushFirstName, @S4);
   if CopyDirName <> '' then S4 := CopyDirName;
   CopyDirName := '';
   if S4 <> '' then
    begin
      if (Files^.Count = 1) and (S4[2] = ':') and (S4[0] > #2) and
         (PFileRec(Files^.At(0))^.Attr and Directory = 0) then
         S4 := MakeNormName(S4, MakeFileName(PFileRec(Files^.At(0))^.Name));
         HistoryAdd(hsFileCopyName,GetName(S4));
      DT.S3 := S4;
    end;
   D^.SetData(DT);

   if not SkipCopyDialog then
    if Desktop^.ExecView(D) = cmCancel then
     begin Dispose(D, Done); Exit end;

   SkipCopyDialog := Off;

   D^.GetData(DT); S := DT.S3; CopyMode := DT.WW; CopyOpt := DT.WW1;
   S := UpStrg(DT.S3);
   ccCopyMode := DT.WW; ccCopyOpt := DT.WW1;
   Dispose(D, Done);
   FSplit(S, CopyDir, Nm, Xt);
   if S = '' then Exit;
   if not Link then
      begin
        if ArchiveFiles(S, Files, MoveMode, Owner) then Exit;
        if Copy(S, 1, PosChar(':', S)) = cTEMP_ then
         begin
           CopyToTempDrive(Files, Owner);
           Exit;
         end;
        {$IFDEF MODEM}
        if (Copy(S, 1, PosChar(':', S)) = cLINK_) then
           begin
             Mask := Nm+Xt;
             if (PosChar('*', Mask) = 0) and (PosChar('?', Mask) = 0) then
                begin CopyDir := CopyDir + Mask; Mask := '' end;
             Delete(CopyDir, 1, 5);
             CopyToLinkDrive(Files, Owner, CopyDir, Mask);
             Exit;
           end;
       {$ENDIF}
      end;
   SSS := Advance.FExpand(S); if Abort then Exit;
   Mask := Nm+Xt;
   if (Mask = '') then Mask := x_x else
   if (PosChar('*', Mask) = 0) and (PosChar('?', Mask) = 0) then
    begin
      ClrIO;
      if SSS[0] = #3 then begin CopyDir := S+'\'; Mask := x_x end else
      begin
        FindFirst(SSS, $3E xor VolumeID, SR);
        if Abort then Exit;
        if (DOSError = 0) and (SR.Attr and Directory <> 0) then
           begin CopyDir := S+'\'; Mask := x_x end
      end;
    end;
   S := #0'NUL'#0'PRN'#0'LPT1'#0'LPT2'#0'LPT3'#0'LPT4'#0'COM1'#0'COM2'#0'COM3'#0'COM4';
   I := Pos(#0+Nm+#0, S);
   if (I <> 0) then
     begin
       CopyMode := cpmOverwrite;
       CopyDir := Mask;
       Mask := '';
       CopyPrn := On;
     end
     else begin
            if (CopyDir = '') then CopyOpt := CopyOpt or cpoDirEmpty;
            CopyDir := Advance.FExpand(CopyDir);
            if CopyDir[Length(CopyDir)] <> '\' then AddStr(CopyDir, '\');
            Mask := Norm12(Mask);
            CopyPrn := Off;
          end;
   CopyDialog := True;
end;



procedure CopyFiles;

 var CopyDir: PathStr;
     Mask: String[12];
     CopyOpt: Word;
     CopyMode: Word;
     CopyPrn: Boolean;
     {Inheread: Byte;}

begin
   CtrlBreakHit := Off;
   Files^.Pack; if Files^.Count <= 0 then Exit;
   if not CopyDialog(CopyDir, Mask, CopyOpt, CopyMode, CopyPrn, {Inheread,}
                     MoveMode, Files, FromTemp, Owner, Off) then Exit;
   if (CopyDir[Length(CopyDir)] <> '\') and (CopyDir <> '') then CopyDir := CopyDir+'\';
   if (FromTemp > 0) and MoveMode then
     begin
       CopyOpt := CopyOpt or cpoFromTemp;
       if CopyOpt and cpoDirEmpty <> 0 then CopyDir := '';
     end;
   CopyOpt := CopyOpt or cpoCopyDesc;
   Inc(SkyEnabled);
   FilesCopy(Files, Owner, CopyDir, Mask, CopyMode, CopyOpt, CopyPrn);
   Dec(SkyEnabled);
end;

end.