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
//     "Based on TinyWeb Server by RIT Research Labs."
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

{$IFDEF DN}
{$I STDEFINE.INC}
{$ENDIF}

unit UUCode;

interface

{$IFDEF UUDECODE}
   procedure UuDecode(const FName: String);
{$ENDIF}

{$IFDEF UUENCODE}
   procedure UuEncode(const FName: String);
{$ENDIF}

implementation

uses Dos
{$IFDEF DN}
     ,Objects, Advance, Views, StartUp, Dialogs, xTime,
     DNApp, Drivers, Gauge, Messages, Commands, RStrings, FileCopy,
     HistList, DNStdDlg, DNUtil
{$ENDIF};

function longmul(X, Y: Word): Longint; inline($5A/$58/$f7/$E2);


const
  TmpExt = 'UUS';

function MaxAvail: LongInt;
begin
  MaxAvail := {$IFDEF DN}MemAdjust{$ENDIF}(System.MaxAvail);
end;


{$IFDEF DN}
var Timer: TEventTimer;

function ApplicationIdle(Info: PWhileView): Boolean;
   var C: Boolean;
   begin
     C := Off;
     ApplicationIdle := off;
     DispatchEvents(Info, C);
     C:= C or CtrlBreakHit;
     if C then
      begin
        ApplicationIdle := Msg(dlQueryAbort, nil, mfYesNoConfirm) = cmYes;
        NewTimer(Timer, 0);
      end;
     CtrlBreakHit := Off;
   end;

procedure RereadGlobal(OutputDir:PathStr);
begin
 GlobalMessage(evCommand, cmPanelReread, @OutputDir);
 GlobalMessage(evCommand, cmRereadTree,  @OutputDir);
end;

{$ENDIF}

const
      LoHexChar  : array[0..$F] of char='0123456789abcdef';
      HexChar : array[1..16] of char='0123456789ABCDEF';


{$IFDEF UUDECODE}

function UU_Decode(const InputFileName,OutputDir:PathStr;ChkOvr,DispErr,RecoverBrokenUUE:Boolean):Boolean;

var
        PI: PWhileView;
        R: TRect;
var
        ErrorNumber: Integer;
        GoodNumber : Integer;
const
        Digits  : set of char = ['0'..'9'];
        OutBufSize = $1000;
type
        TDskBufArr      = array[1..$FFFF] of byte;
        PDskBufArr      = ^TDskBufArr;
        PSection = ^TSection;
        TSection = record
                     Number    : word;
                     TmpFileId : LongInt;
                     Size      : LongInt;
                   end;

        TSectArr = array[1..990] of TSection;
        PSectArr = ^TSectArr;

        TSectInfo= record
                     MaxSectKnw : Boolean;
                     TotSect    : word;
                   end;

        PFile    = ^TFile;
        TFile    = record
                     FName      : string[12];
                     EndFound   : Boolean;
                     CrcKnown   : Boolean;
                     ForceSkp   : Boolean;
                     Flushed    : Boolean;
                     RealSize   : LongInt;
                     Size       : LongInt;
                     RealCRC    : word;
                     Crc        : word;
                     s          : TSectInfo;
                     FileTime   : LongInt;
                     NSect      : word;
                     Sect       : PSectArr;
                     Broken     : Boolean;
                   end;

        TFileArr = array[1..1500] of TFile;
        PFileArr = ^TFileArr;

function  Min(a1,a2:integer):integer;inline($58/$5B/$3B/$C3/$7C/$01/$93);
function  Max(a1,a2:integer):integer;inline($58/$5B/$3B/$C3/$7F/$01/$93);

const
        GrowStep=16;

var
        BackSize        : byte;
        KickBack        : Boolean;
        BackCRC         : word;
        BackBuf         : string;
        FileArr         : PFileArr;
        NFileArr        : word;
        TmpCRC          : word;
        SectCRC         : word;
        SectSSz         : LongInt;
        InputStream     : PTextReader;
        TmpInFile       : file;
        OutFile         : file;
        CurFileName     : string[12];
        OrgT            : string;
        OrgTLen         : byte absolute OrgT;
        StrT            : string;
        AuxT            : string;
        OutFName        : PathStr;
        InFName         : PathStr;
        StrL            : byte absolute StrT;
        AuxL            : byte absolute AuxT;
        CurPSection     : PSection;
        CurPFile        : PFile;
        UUfound,
        BadSection,
        ForceSkip,
        SectionGo,
        exTable,
        exBegin,
        exSUM,
        exFileTime,
        exEnd,
        FileNameKnown,
        FileTimeKnown,
        NumSectKnown,
        PrevTmp,
        ForceEOF,
        MaxSectKnown    : Boolean;
        MaxSectNum,
        CurSectNo       : word;
        NumErr          : word;
        SubPos          : byte;
        WholeSectCRC    : word;
        ErrorFName      : PathStr;
        ErrorFCode      : Byte;
        OutBufPos       : word;
        POutBuf         : PDskBufArr;
        CurSectSize,
        CurFileTime,
        LastFSize,
        HeapBegin,
        HeapEnd         : LongInt;



 procedure FReadLn;
 begin
   OrgT := InputStream^.GetStr;
 end;


function  ExistFile(const FName : PathStr) : Boolean;
var DirInfo:SearchRec;
begin
 FindFirst(FName,Archive+ReadOnly+Hidden+SysFile,DirInfo);
 if DosError=0 then
 begin
  ExistFile:=True;
  LastFSize:=DirInfo.Size;
 end else
 begin
  ExistFile:=False;
  ErrorFCode:=DosError;
  ErrorFName:=FName
 end;
end;

procedure EraseFile(const FName : PathStr);
var f:file;begin Assign(f,FName);Erase(f) end;

procedure RenameFile(const Name1,Name2:PathStr);
var f:file; begin Assign(f,Name1);Rename(f,Name2) end;

function GetASCIIZ(var Buf):PathStr;assembler;
asm
        push    ds
        les     di,@Result
        lds     si,Buf
        mov     ah,0
  @@L:  lodsb
        cmp     al,0
        jz      @@END
        stosb
        inc     ah
        jnz     @@L
 @@END: mov     di,word ptr @Result
        mov     es:[di],ah
        pop     ds
end;

procedure PrepareWrite;
begin OutBufPos:=65535;GetMem(POutBuf,OutBufSize) end;

procedure FileRewrite(const FName:PathStr);
begin
 Assign(OutFile,FName);
 Rewrite(OutFile,1);ErrorFCode:=IOResult;
 if ErrorFCode=0 then PrepareWrite else ErrorFName:=FName;
end;

procedure BWrite(var Buf;Sz:word);
var a:word;
begin
 BlockWrite(OutFile,Buf,Sz,a);
 if a<>Sz then ErrorFCode:=101 else ErrorFCode:=IOResult;
 if ErrorFCode>0 then ErrorFName:=FileNameOf(OutFile)
end;

procedure PutBlock(var OutBuf;Sz:word);
var Buf:TDskBufArr absolute OutBuf;
begin
 if Sz=0 then Exit;
 if OutBufPos=65535 then
 begin
  Move(Buf,POutBuf^,Sz);
  OutBufPos:=Sz;
 end else
 if OutBufPos+Sz>=OutBufSize then
 begin
  if OutBufPos+Sz=OutBufSize then
  begin
   Move(Buf,POutBuf^[OutBufPos+1],Sz);
   BWrite(POutBuf^,OutBufSize);
   if ErrorFCode>0 then Exit;
   OutBufPos:=0;
  end else
  begin
   Move(Buf,POutBuf^[OutBufPos+1],OutBufSize-OutBufPos);
   BWrite(POutBuf^,OutBufSize);
   if ErrorFCode>0 then Exit;
   Move(Buf[OutBufSize-OutBufPos+1],POutBuf^,Sz-(OutBufSize-OutBufPos));
   OutBufPos:=Sz-(OutBufSize-OutBufPos);
  end;
 end else begin Move(Buf,POutBuf^[OutBufPos+1],Sz);Inc(OutBufPos,Sz) end;
end;

procedure FlushOutBuf;
var Dummy:byte;
begin
 if OutBufPos>0 then BWrite(POutBuf^,OutBufPos);FreeMem(POutBuf,OutBufSize);
 Close(OutFile);Dummy:=IOResult;POutBuf:=NIL;
end;

procedure PutByte(b:byte);begin PutBlock(b,1) end;

procedure CancelOutFile;
var Dummy:byte;
begin
 Close(OutFile);Dummy:=IOResult;
 if POutBuf<>NIL then FreeMem(POutBuf,OutBufSize);
 POutBuf:=NIL;
end;

function RExpand(s:string;n:byte):string;
begin while Length(s)<n do s:=s+' ';RExpand:=s end;

function FFExpand(s:string):string;
var D:DirStr;N:NameStr;E:ExtStr;
begin
 FSplit(LowStrg(s),D,N,E);
 s:=RExpand(RExpand(N,8)+E,12);
 s[9]:=' ';FFExpand:=s;
end;

procedure GrArr(var p;var Index:word;Sz:word);
var a1:pointer;
     a:pointer absolute p;
  BufS:word;
begin
 if Index mod GrowStep=0 then
 begin
  GetMem(a1,(Index+GrowStep)*Sz);
  if Index>0 then
  begin
   BufS:=Index*Sz;
   Move(a^,a1^,BufS);
   FreeMem(a,BufS);
  end;
  a:=a1;
 end;
 Inc(Index);
end;

procedure CalcBufCRC(var Buf;Size:word;var PrevSum:word);assembler;
asm
        mov     cx,Size
        jcxz    @@End
        push    ds
        lds     si,Buf
        les     di,PrevSum
        mov     dx,word ptr [es:di]
        xor     ax,ax
 @@1:   lodsb
        ror     dx,1
        add     dx,ax
        loop    @@1
        pop     ds
        mov     word ptr es:[di],dx
 @@End:
end;

function SmartDIV(L:LongInt;W:Word):Word;assembler;
asm      mov     ax,word ptr [L+0]
         mov     dx,word ptr [L+2]
         div     W
         or      dx,dx
         jz      @@Exit
         inc     ax
@@Exit:
end;

procedure FreeArr(var pp;Index,Sz:word);
var p : pointer absolute pp;
begin
 FreeMem(p,SmartDiv(Index,GrowStep)*GrowStep*Sz);
end;


function  SSStr(a:LongInt;n:Byte;ch:Char):string;
var s:string;i:Byte;
begin
 Str(a:n,s);for i:=1 to n do if s[i]=' ' then s[i]:=ch else break;
 SSStr:=s;
end;

procedure DelSpaces(var s:string);
begin DelLeft(s);DelRight(s) end;

function EndOfFile:Boolean;
begin
 if ForceEOF then begin EndOfFile:=On; Exit end;
 EndOfFile:=InputStream^.Eof;
end;

function UUString(var s:string;var CRC:word):Boolean;assembler;
asm
        cld
        push    ds
        lds     si,CRC
        mov     dx,ds:[si]
        lds     si,s
        mov     ah,0
        mov     ch,0
        lodsb
        mov     cl,al

        push    cx
        les     di,s
        add     di,cx
        inc     di
        mov     al,0
        mov     cx,70
        rep     stosb
        pop     cx

        lodsb
        ror     dx,1
        add     dx,ax
        cmp     al,'!'
        jb      @@NonUU
        cmp     al,'`'
        ja      @@NonUU
        sub     al,' '
        and     al,3Fh
        mov     ds:[si-1],al
        dec     cl
 @@L:   lodsb
        cmp     al,0
        jz      @@UU
        ror     dx,1
        add     dx,ax
        cmp     al,' '
        jb      @@NonUU
        cmp     al,'`'
        ja      @@NonUU
        sub     al,' '
        and     al,3Fh
        mov     ds:[si-1],al
        loop    @@L
        jmp     @@UU
@@NonUU:mov     al,0
        jmp     @@End
@@UU:   lds     si,CRC
        ror     dx,1
        add     dx,0Ah
        mov     ds:[si],dx
        mov     al,1
@@End:  pop     ds
end;

function MemEqu(var A,B; Size : Word) : Boolean; assembler;
asm      push  ds
         cld
         mov   cx,Size
         lds   si,A
         les   di,B
         repe  cmpsb
         mov   al,1
         je    @@EQ
         dec   al
@@EQ:    pop   ds
end;

procedure DelTBeg(b:byte);begin Delete(StrT,1,b) end;

procedure FindStr(const s:string); begin SubPos:=Pos(s,StrT) end;

function StrTBegins(s:string):Boolean;
var sl:byte absolute s;b:boolean;
begin
 b:=MemEqu(StrT[1],s[1],sl) and (StrL>=sl);
 StrTBegins:=b;
 if b then DelTBeg(sl);
 DelLeft(StrT);
end;

procedure GetW(var s,w:string);
var sl:byte absolute s;
begin
 w:='';
 DelSpaces(s); if s='' then Exit;
 while (sl>0) and (s[1]<>' ') do
 begin w:=w+s[1];DelFC(s) end;
 DelFC(s);
end;

procedure GetN(var s,w:string);
var sl:byte absolute s;
begin
 w:='';
 DelSpaces(s); if s='' then Exit;
 while (sl>0) and (s[1] in Digits) do
 begin w:=w+s[1];DelFC(s) end;
 DelFC(s);
end;

procedure GetWord; begin GetW(StrT,AuxT) end;

function ValidWNumber(var Num:word):Boolean;
begin Val(AuxT,Num,NumErr);ValidWNumber:=NumErr=0 end;

function ValidLNumber(var Num:LongInt):Boolean;
begin Val(AuxT,Num,NumErr);ValidLNumber:=NumErr=0 end;

procedure ClearEX;
begin
 NumSectKnown:=Off;
 MaxSectKnown:=Off;
 FileNameKnown:=Off;
 SectionGo:=Off;
 FileTimeKnown:=Off;
 exFileTime:=Off;
 exEnd:=Off;
 exBegin:=On;
 exTable:=Off;
end;

function Complete__File:Boolean;
begin
 Complete__File:=Off;
 if not CurPFile^.s.MaxSectKnw then Exit;
 if CurPFile^.s.TotSect<>CurPFile^.NSect then Exit;
 Complete__File:=On;
end;

procedure Local_Error(const s:string; Severe: Boolean);

procedure MB(const ss: string);
begin
  MessageBox(ss,nil,mfError+mfOkButton);
  NewTimer(Timer, 0);
end;

begin
 if DispErr then MB(s);
 Inc(ErrorNumber);
 if PI<>nil then PI^.Write(6,GetString(dlUUDecodeErrors)+SSStr(ErrorNumber,3,' '));
 if (Severe) and (CurPFile <> nil) then with CurPFile^ do
 begin
   if not Broken then
   begin
     Broken := True;
     if (not RecoverBrokenUUE) and (DispErr) then MB(GetString(dlleFailedFinal)+' '+CurPFile^.FName);
   end;
 end;
end;

procedure LocalError(const s:string);
begin
  Local_Error(s, True);
end;

procedure LocalWarning(const s:string);
begin
  Local_Error(s, False);
end;

procedure CheckFileSize(Listed,Calculated:LongInt);
begin
 if Listed<>Calculated then
  LocalError(GetString(dlleFileSizeMismatch)+' '+CurPFile^.FName+
            ', '+GetString(dlleListed)+'='+ItoS(Listed)+', '+
                 GetString(dlleCalculated)+'='+ItoS(Calculated));
end;

procedure CheckFileCRC(Listed,Calculated:Word);
begin
 if Listed<>Calculated then
  LocalError(GetString(dlleFileCRCMismatch)+' '+CurPFile^.FName+
            ', '+GetString(dlleListed)+'='+ItoS(Listed)+', '+
                 GetString(dlleCalculated)+'='+ItoS(Calculated));
end;

procedure CompileFile;
var i,j               : word;
    PA,FA             : word;
    MissS             : string;
    SingleMiss        : Boolean;

procedure MoveSection(var a:TSection);

procedure BufCopy;
const BufSize=1024;
var   Buf : array[1..BufSize] of byte;

procedure Mve(Sz:word);
begin
 BlockRead(TmpInFile,Buf,Sz);
 CalcBufCRC(Buf,Sz,CurPFile^.CRC);
 PutBlock(Buf,Sz);
end;

var   c,i : word;
      l   : longint;
      s   : string;
begin
 i:=a.Size div BufSize;
 for c:=1 to i do Mve(BufSize);
 i:=a.Size mod BufSize;
 if i>0 then Mve(i);
end;

begin
 InFName := CalcTmpFName(a.TmpFileId, TmpExt);
 Assign(TmpInFile,InFName);FileMode:=$40;Reset(TmpInFile,1);
 if IOResult<>0 then LocalError(GetString(dlleErrorOpenTMP));
 BufCopy;
 Close(TmpInFile);
 EraseFile(InFName);
 Inc(CurPFile^.Size,a.Size);
end;

procedure ClearFAPA; begin PA:=0;FA:=0 end;

procedure SetMiss;
begin
 if MissS<>'' then MissS:=MissS+', ';
 if pa=fa then
 MissS:=MissS+ItoS(FA)
 else
  begin
   MissS:=MissS+ItoS(FA)+'-'+ItoS(PA);
  end;
 ClearFAPA;
end;

procedure CheckPresence;
var ii,jj:word;
begin
 jj:=0;
 for ii:=1 to CurPFile^.NSect do if CurPFile^.Sect^[ii].Number=i then
 begin jj:=ii;Break end;
 if jj>0 then
 begin
  if FA>0 then SetMiss;
  Inc(j);
  MoveSection(CurPFile^.Sect^[jj]);
  Exit;
 end else
 begin
  if FA=0 then
  begin
   FA:=i;
   PA:=i;
  end else
  begin
   if PA+1=i then Inc(pa) else SetMiss;
  end;
 end;
end;

procedure CheckC(var T:TFile);
begin
 with t do
 begin
  CheckFileSize(RealSize,Size);
  CheckFileCRC(RealCRC,CRC);
 end;
end;

procedure SetFileTime(ft:LongInt);
var f:file;
begin
 if ft=0 then Exit;
 Assign(f,OutputDir+OutFName);FileMode:=$40;Reset(f,1);SetFTime(f,ft);Close(f);
end;

procedure ReportMiss;
var s:string;
begin
 s:=' '+MissS+' '+GetString(dlleOfFile)+' '+OutFName+' ('+ItoS(CurPFile^.s.TotSect)+') ';
 SingleMiss:=(pos('-',MissS)=0) and (pos(',',MissS)=0);
 if SingleMiss then
  LocalError(GetString(dlleSection)+s+GetString(dlleIsAbsent)) else
  LocalError(GetString(dlleSections)+s+GetString(dlleAreAbsent));
end;

begin
 ClearFAPA;MissS:='';SingleMiss:=On;
 OutFName:=CurPFile^.FName;CurPFile^.Flushed:=On;
 FileRewrite(OutputDir+OutFName);
 if ErrorFCode<>0 then
 begin
  LocalError(GetString(dlleCantCreate)+' '+OutFName);
  Exit;
 end;
 j:=0; for i:=1 to CurPFile^.s.TotSect do CheckPresence;
 FlushOutBuf;
 if CurPFile^.s.TotSect=CurPFile^.NSect then
 begin
  SetFileTime(CurPFile^.FileTime);
  if CurPFile^.EndFound then
    Inc(GoodNumber)
  else
    LocalError(GetString(dlleNoTerm)+' ('+OutFName+')');
  if CurPFile^.CrcKnown then CheckC(CurPFile^);
 end else
 begin
  if FA>0 then SetMiss;
  ReportMiss;
  LocalError(GetString(dlleFailedToDecode)+' '+OutFName);
 end;
 FreeArr(CurPFile^.Sect,CurPFile^.NSect,SizeOf(TSection));
 CurFileName:='';
end;

procedure TerminateSection;

procedure TerminateSmth;
begin
 CurPSection^.Size:=CurSectSize;
 if Complete__File then CompileFile;
end;

begin
 KickBack:=Off;
 if BadSection then
 begin
  CancelOutFile;Exit;
 end;
 FlushOutBuf;
 if NumSectKnown then TerminateSmth;
end;

procedure ClearCRC;
begin
 SectSSz:=0;
 SectCRC:=0;
 CurSectSize:=0;
 WholeSectCRC:=0;
end;

procedure SetFN;
var D:DirStr;N:NameStr;E:ExtStr;nl:byte absolute n;el:byte absolute E;
begin
 UpStr(AuxT);FSplit(AuxT,D,N,E); nl:=Min(nl,8);el:=Min(el,4);
 AuxT:=N+E;
end;

procedure OutString; forward;

procedure Get_String;

function SetSection:Boolean;

procedure SetCurFName;
begin
 GetWord;SetFN;CurFileName:=AuxT;SetSection:=On;FileNameKnown:=On;
 exFileTime:=On;
end;

begin
 SetSection:=Off;
 if StrT='' then Exit;
 GetWord;
 if StrT='' then Exit;
 if not ValidWNumber(CurSectNo) then Exit;
 GetWord;
 if StrT='' then Exit;
 if AuxT<>'of' then Exit;
 GetWord;
 if StrT='' then Exit;
 if not ValidWNumber(MaxSectNum) then MaxSectNum:=0 else GetWord;
 if StrT='' then Exit;
 if AuxT='file' then
 begin
  NumSectKnown:=On;
  SetCurFName;
  Exit;
 end;
 FindStr('file');
 DelTBeg(SubPos-1);
 GetWord;
 if StrT='' then Exit;
 SetCurFName;
 NumSectKnown:=On;
 if MaxSectNum>0 then MaxSectKnown:=On;
end;

procedure SetBegin;
begin
 GetWord;
 if StrT='' then begin LocalError(GetString(dlleFileNameExp));Exit end;
 GetWord;
 SetFN;
 if (AuxT<>CurFileName) and FileNameKnown then LocalError(GetString(dlleFileNamesMismatch));
 CurFileName:=AuxT;FileNameKnown:=On;
 exFileTime:=Off;
end;

function SetFileTime:Boolean;
begin
 SetFileTime:=Off;
 if StrT='' then begin LocalError(GetString(dlleFileTimeExp));Exit end;
 GetWord;
 if not ValidLNumber(CurFileTime) then begin LocalError(GetString(dlleInvFileTimeNum));Exit end;
 FileTimeKnown:=On;
end;

procedure CalcLnCRC(var Strng:string;var CRC:word);assembler;
asm
        cld
        xor     cx,cx
        push    ds
        lds     si,Strng
        lodsb
        mov     cl,al
        jcxz    @@End
        les     di,CRC
        mov     dx,word ptr [es:di]
        xor     ax,ax
 @@1:   lodsb
        ror     dx,1
        add     dx,ax
        loop    @@1
        ror     dx,1
        add     dx,0Ah
        mov     word ptr es:[di],dx
 @@End: pop     ds
end;


procedure CheckSum;
var Num:string;

function CheckS:Boolean;
var c:word;s:LongInt;
begin
 CheckS:=Off;
 GetN(Num,StrT);
 if Num='' then Exit;
 if AuxT='section' then
 begin
  AuxT:=StrT;
  if not ValidWNumber(TmpCRC) then Exit;
  if TmpCRC<>WholeSectCRC then
  begin
   LocalError(GetString(dlleCRC_Err)+' Ä '+CurPFile^.FName+', '+GetString(dlleSection)+' '+ItoS(CurSectNo));
  end;
  AuxT:=Num;
  if not ValidLNumber(s) then Exit;
  if s<>SectSSz then
  begin
   LocalError(GetString(dlleSizeMism)+' Ä '+CurPFile^.FName+', '+GetString(dlleSection)+' '+ItoS(CurSectNo));
  end;
  CheckS:=On;
 end else
 if AuxT='entire' then
 begin
  AuxT:=StrT;
  if not ValidWNumber(c) then Exit;
  AuxT:=Num;
  if not ValidLNumber(s) then Exit;
  CheckS:=On;
  if CurPFile^.Flushed then
  begin
   CheckFileSize(s,CurPFile^.Size);
   CheckFileCRC(c,CurPFile^.CRC);
  end else
  begin
   CurPFile^.RealCRC:=c;
   CurPFile^.RealSize:=s;
   CurPFile^.CrcKnown:=On;
  end;
 end;
end;

begin
 GetWord;
 Num:=AuxT;
 if StrT='' then Exit;
 GetWord;
 if not CheckS then LocalError(GetString(dlleChkSumFmt));
end;

procedure CalcCRC;
begin
 KickBack:=Off;
 CalcLnCRC(OrgT,SectCRC);Inc(SectSSz,OrgTLen+1);
end;

procedure FlushBack;
var s:string;
begin
 if KickBack=On then
 begin
  s:=StrT;StrT:=BackBuf;OutString;StrT:=s;SectCRC:=BackCRC;Inc(SectSSz,BackSize);
  KickBack:=Off;
 end;
end;

function ClearT: Byte;
var
  Idx: Byte;
  c  : char;
begin
  Idx:=1;
  Inc(OrgTLen); OrgT[OrgTLen] := #0;
  repeat
    c := OrgT[Idx];
    if c = #0 then Break;
    if (c=' ') and (OrgT[Idx+1]>#$7F) then Delete(OrgT, Idx, 2) else Inc(Idx);
  until False;
  ClearT := Idx;
  Dec(OrgTLen);
end;

procedure DoTable;
var i: byte;
begin
  ClearCRC;
  CalcCRC;
  for i:=0 to 1 do begin repeat FReadLn until OrgT<>''; CalcCRC end;
end;

begin
 repeat
  if EndOfFile then Exit;
  FReadLn;
  if (OrgT='') or (OrgTLen>120) or (not (OrgT[1] in [' '..'z'])) then Continue;
  if (ClearT=1) then Continue;
  if OrgT[1]=' ' then Continue;
  FillChar(StrT,70,' ');
  StrT:=OrgT;
  if StrT[1]='M' then
  begin
   TmpCRC:=SectCRC;KickBack:=Off;
   if UUString(StrT,TmpCRC) then
    begin SectCRC:=TmpCRC;Inc(SectSSz,OrgTLen+1);Break end;
  end else
  begin
   if SectionGo then if (StrT='`') or (StrT='``') then
   begin
    if BadSection then
    begin
     ExSUM:=Off;
     ClearEX;
     Continue;
    end else
    begin
     if CurPFile <> nil then
     begin
      CurPFile^.EndFound:=On;
      CurPFile^.s.MaxSectKnw:=On;
      CurPFile^.s.TotSect:=CurSectNo;
     end;
     FlushBack;
     CalcCRC;
     TerminateSection;
     ClearEX;exEnd:=On;
     Continue
    end;
   end ;
   if exSUM     then if StrTBegins('sum -r/size ') then
   begin
    ExEnd:=Off;
    if BadSection then
    begin
     ClearEX;
     Continue;
    end else
    begin
     if WholeSectCRC=0 then WholeSectCRC:=SectCRC;
     if CurPFile<>NIL then CheckSum;
     if SectionGo then begin TerminateSection;ClearEX end;
     ClearCRC;Continue;
    end
   end;
   if exFileTime then if StrTBegins('filetime ') then
   begin
    ClearCRC;
    if SetFileTime then;
    Continue
   end;
   if exBegin then if StrTBegins('begin ') then
   begin
    if SectionGo then begin TerminateSection;ClearEX end;
    if ExTable then exTable:=Off else ClearCRC;
    SetBegin;
    CalcCRC;
    Continue
   end;
   if exEnd     then if StrTBegins('end') then
   begin
    FlushBack;
    CalcCRC;
    WholeSectCRC:=SectCRC;ExEnd:=Off;
    if CurPFile<>NIL then
    if not CurPFile^.EndFound then LocalError(GetString(dlleUnexpEND));
    Continue
   end;
   if StrTBegins('section ') then
   begin
    if SectionGo then begin TerminateSection; ClearEX end;
    if not SetSection then
    begin
     LocalError(GetString(dlleSectionHdr));
     BadSection:=On;
    end else
    begin
     if CurSectNo>1 then exBegin:=Off;
     exTable:=On;
     ClearCRC;
    end;
    Continue;
   end;
   if exTable then if StrT='table' then
   begin
    DoTable;
    Continue;
   end;
   BackCRC:=SectCRC;BackBuf:=StrT; BackSize:=OrgTLen+1;
   if UUString(BackBuf,BackCRC) then
   begin
     if SectionGo then
     begin
       KickBack:=On;continue
     end else
     if FileNameKnown then
     begin
       SectCRC:=BackCRC;Inc(SectSSz,BackSize);
       Move(BackBuf, StrT, BackSize);
       Break;
     end
   end;
  end;
 until Off;
end;

procedure DecodeStr(var Src,Dst);assembler;
var     Cnt:byte;
asm
        cld
        push    ds
        lds     si,Src
        les     di,Dst
        mov     Cnt,15
@@L:    lodsw
        mov     ch,ah
        mov     cl,2
        shl     al,cl
        mov     cl,4
        shr     ah,cl
        or      al,ah
        stosb
        lodsw
        mov     bl,al
        shl     ch,cl
        mov     cl,2
        shr     al,cl
        or      al,ch
        stosb
        mov     al,bl
        mov     cl,6
        shl     al,cl
        or      al,ah
        stosb
        dec     Cnt
        jnz     @@L
        pop     ds
end;

procedure OutString;
var b:array[1..45] of byte;
begin
 if BadSection then Exit;
 DecodeStr(StrT[2],b);
 PutBlock(b,Byte(StrT[1]));
 Inc(CurSectSize,Byte(StrT[1]));
end;

procedure GoSect;
begin exBegin:=On;exEnd:=On;SectionGo:=On end;

procedure OpenOutFile;
begin
 GoSect;
 if BadSection then Exit;
 FileRewrite(OutFName);
 if ErrorFCode<>0 then
 begin
  LocalError(GetString(dlleCantCreate)+' '+OutFName);BadSection:=On;
 end;
end;

procedure CheckExist;
var f: PathStr;
    P: Pointer;
    i,j : word;
begin
 if not ChkOvr then Exit;
 j:=0;
 for i:=1 to NFileArr do
  if FileArr^[i].FName=CurFileName then begin j:=i;Break end;
 if j=0 then
 begin
  f:=OutputDir+CurFileName;
  P:=@F;
  if ExistFile(f) then
  begin
   Case MessageBox(GetString(dlFileExist)+^M, @P, mfQuery+mfYesButton+mfNoButton+mfCancelButton+mfAllButton) of
   { cmYes:;}
    cmOk:begin ChkOvr := Off; end;
    cmNo:begin BadSection:=On; ForceSkip:=On end;
    cmCancel: begin BadSection:=On; ForceEOF:=On end;
    end;
   NewTimer(Timer, 0);
  end;
 end else
 begin
  ForceSkip:=FileArr^[j].ForceSkp;
  BadSection:=ForceSkip;
 end;
end;

procedure DecodeUnheadered;

function CalcUnknownName:string;
var     Num:word;
        u:string;
 procedure CalcMaxUnk(var s:string);
 var v,c:word;
 begin
  if s[1]='.' then DelFC(s);
  Val(s,v,c);
  if c>0 then Exit;
  if v<=Num then Exit;
  Num:=v;
 end;
var Dir:SearchRec;D:DirStr;N:NameStr;E:ExtStr;
begin
 u:='UNKNOWN.';
 Num:=0;
 FindFirst(u+'*', Archive, Dir);
 while DosError = 0 do
 begin
  FSplit(Dir.Name,D,N,E);
  CalcMaxUnk(E);
  FindNext(Dir);
 end;
 CalcUnknownName:=u+SSStr(Num+1,3,'0');
end;

begin
 if FileNameKnown then
 begin
  OutFName:=CurFileName;
  CheckExist
 end else OutFName:=CalcUnknownName;
 OutFName:=OutputDir+OutFName;
 OpenOutFile;
 while SectionGo do
 begin
  OutString;
  Get_String;
  if EndOfFile then Break;
 end;
end;

procedure MakeTmpFile;

procedure MaxSectNumMism;
begin
 LocalError(GetString(dlleMaxSectNumMism));BadSection:=On;
end;

var j:word;
procedure SetTotSect(var s:TSectInfo);
begin
 with s do
 begin
  if MaxSectKnown then
  begin
   if TotSect<>MaxSectNum then begin MaxSectNumMism;Exit end;
  end else
  if MaxSectKnw then
  begin
   if CurSectNo>TotSect then begin MaxSectNumMism;Exit end;
  end else
  begin
   TotSect:=Max(TotSect,CurSectNo);
  end;
 end;
end;

procedure CreateNewSItem(var s:TSection);
begin
 with s do
 begin
  Number:=CurSectNo;
  TmpFileId:=CalcTmpId;
  OutFName := CalcTmpFName(TmpFileId, TmpExt);
 end;
 CurPSection:=@s;
end;

procedure CreateNewFItem(var f:TFile);
begin
 with f do
 begin
  with s do
  begin
   MaxSectKnw:=MaxSectKnown;
   if MaxSectKnown then TotSect:=MaxSectNum else TotSect:=0;
  end;
  SetTotSect(s);
  FName:=CurFileName;
  Size:=0;Crc:=0;NSect:=0;
  Broken:=False;CrcKnown:=Off;EndFound:=Off;ForceSkp:=ForceSkip;Flushed:=ForceSkip;
  if FileTimeKnown then FileTime:=CurFileTime else FileTime:=0;
  CurPFile:=@f;
  if not ForceSkip then
  begin
   GrArr(Sect,NSect,SizeOf(TSection));
   CreateNewSItem(Sect^[NSect]);
  end;
 end;
end;

procedure DuplicateSection;
begin
 LocalWarning(GetString(dlleDuplicateSection)+' '+ItoS(CurSectNo)+' '+GetString(dlleOfFile)+' '+CurFileName);
 BadSection:=On;
end;

procedure AddNewSItem(var f:TFile);
var i:word;
begin
 with f do
 begin
  if ForceSkp then Exit;
  if Flushed then
  begin
   DuplicateSection;
   Exit;
  end;
  SetTotSect(s);if BadSection then Exit;
  if FileTimeKnown then FileTime:=CurFileTime;
  j:=0;
  for i:=1 to NSect do if Sect^[i].Number=CurSectNo then begin j:=i;Break end;
  if j=0 then
  begin
   GrArr(Sect,NSect,SizeOf(TSection));
   CreateNewSItem(Sect^[NSect]);
   CurPFile:=@f;
  end else DuplicateSection;
 end
end;

var i:word;
begin
 if ForceEOF then Exit;
 j:=0;
 for i:=1 to NFileArr do
  if FileArr^[i].FName=CurFileName then begin j:=i;Break end;
 if j=0 then
 begin
  GrArr(FileArr,NFileArr,SizeOf(TFile));
  CreateNewFItem(FileArr^[NFileArr]);
 end else AddNewSItem(FileArr^[j]);
end;

procedure WriteOrphanedSection;
begin
 CheckExist;
 MakeTmpFile;
 OpenOutFile;
 exSum:=On;
 while SectionGo do
 begin
  OutString;
  Get_String;
  if EndOfFile then Break;
 end;
end;

procedure WriteHeadered;
begin
 CheckExist;
 MakeTmpFile;
 OpenOutFile;
 GoSect;
 exSum:=On;
 while SectionGo do
 begin
  OutString;
  Get_String;
  if EndOfFile then Break;
 end;
end;

procedure FlushLeftSections;
var i:word;
begin
 for i:=1 to NFileArr do
 begin
  CurPFile:=@FileArr^[i];if not CurPFile^.Flushed then CompileFile;
  if not RecoverBrokenUUE then
  begin
    if CurPFile^.Broken then EraseFile(OutputDir+OutFName);
  end;
 end;
 FreeArr(FileArr,NFileArr,SizeOf(TFile));
end;

var
    PP,P1 : PView;
    PL : PSortedListBox;
    IdleTimer: TEventTimer;

begin
 if not ExistFile(InputFileName) then
 begin
  Exit;
 end;
 POutBuf:=NIL;NFileArr:=0;BadSection:=Off;KickBack:=Off;
 ForceEOF:=Off;
 UUfound:=Off;CurFileName:='';GoodNumber:=0;ErrorNumber:=0;
 CurPFile:=NIL;PI:=NIL;
 InputStream := New(PTextReader, Init(InputFileName));
 if (InputStream = nil) then Exit;
 ClearEX;ClearCRC;
 Get_String;

 if not EndOfFile then
 begin
   R.Assign(0,0,40,12);
   New(PI, Init(R));
   PI^.Top := GetString(dlUUDecode);

   PI^.Write(1,GetString(dlUUDecodingto)+Cut(InputFileName, 40));
   PI^.Write(2,GetString(dlFC_To)+' '+OutputDir);

   Desktop^.Insert(PI);
 end;

 NewTimer(IdleTimer, 0);
 while not EndOfFile do
 begin
  UUFound := True;
  PI^.Write(3,CurFileName);
  PI^.Write(5,GetString(dlUUDecodeFiles)+SSStr(GoodNumber,3,' '));
  PI^.Write(6,GetString(dlUUDecodeErrors)+SSStr(ErrorNumber,3,' '));
  BadSection:=Off;KickBack:=Off;ForceSkip:=Off;ExSum:=Off;CurPFile:=NIL;

  if not NumSectKnown then DecodeUnheadered else
  begin  {if NumSectKnown}
   if MaxSectKnown then
   begin
    {if (CurSectNo=1) and (MaxSectNum=1) then WriteSingleHeadered
                                        else }WriteHeadered;
   end else
   begin {if not MaxSectKnown}
    WriteOrphanedSection;
   end;
  end;
  if TimerExpired(IdleTimer) then
  begin
    if ApplicationIdle(PI) then Break;
    NewTimer(IdleTimer, 1);
  end;
 end;
 Dispose(InputStream, Done);
 if SectionGo then TerminateSection;
 if NFileArr > 0 then FlushLeftSections;
 FreeObject(PI);
 if not UUfound then
  begin
   ErrMsg(eruuNoStuff);
   NewTimer(Timer, 0);
  end;
 UU_Decode:=ForceEOF;
end;

procedure UuDecode(const FName: String);
var  Dr: Record  S:PathStr; Opt: Word; end;
     BeepDisabled:Boolean;
begin
 Inc(SkyEnabled);
 Dr.S := '';
 Dr.Opt := UUDecodeOptions;
 Message(Application, evCommand, cmPushFirstName, @DR.S);
 GlobalMessage(evCommand, cmPushName, Pointer(hsUUDecode));
 if {(DT.O and uudExtractAll <> 0) or}
    (ExecResource(dlgUUDecode, Dr) = cmOK) then
   begin
     if UUDecodeOptions <> Dr.Opt then ConfigModified := True;
     UUDecodeOptions := Dr.Opt;
     if Dr.S='' then Dr.S :='.\' else if Dr.S[Length(Dr.S)]<>'\' then
       if not ((Length(Dr.S)=2) and (Dr.S[2]=':')) then Dr.S:=Dr.S+'\';
     CreateDirInheritance(Dr.S, Off);
    NewTimer(Timer, 0);
    BeepDisabled := UU_Decode(FName,Dr.S, Dr.Opt and 1 <> 0, Dr.Opt and 2 <> 0, Dr.Opt and 4 <> 0);
     RereadGlobal(Dr.S);
     if not BeepDisabled then
     begin
      if (FMSetup.Options and fmoBeep <> 0) and
      (ElapsedTimeInSecs(Timer) > 5) then BeepAfterCopy;
     end;
   end;
 Dec(SkyEnabled);
end;

{$ENDIF}

{$IFDEF UUENCODE}

type
        T64             = record
                          case Byte of
                           0: (l0,l1       : LongInt);
                           1: (w0,w1,w2,w3 : word);
                          end;

procedure Prepare1Str(var Sou,Dst);near;external;
function  GetUUxlt(b:byte):char;near;external;
function  GetLnCrc(var Buf;Size:word):Char;near;external;
procedure cCrc(var Buf;Size:word;var PrevSum:word);near;external;
procedure Crc64(var Buf;Size:word;var PrevSum;var Cnt:word);near;external;
procedure Clear64(n:T64);near;external;
{$L UUE2INC}

function SmartDIV(L:LongInt;W:Word):Word;assembler;
asm             mov     ax,word ptr [L+0]
                mov     dx,word ptr [L+2]
                div     W
                or      dx,dx
                jz      @@Exit
                inc     ax
@@Exit:
end;

procedure UuEncode(const FName: String);
type
        PDskBufArr       = ^TDskBufArr;
        TDskBufArr       = array[1..65535] of byte;

  const
                SectNZ   = 2000;
                UUETitle = '< uuencode by Dos Navigator >';
  var ST: file;
      GetLnEnd: string[2];
      NLines: LongInt;
      L, FL, CRC, RSize: LongInt;
      S: String;
      I, Start: Integer;
      Nm: NameStr;
      Xt: ExtStr;
      Dr: PathStr;
      P: Pointer;
{$IFDEF DN}
      PI: PWhileView;
      R: TRect;
{$ENDIF}
      Cancel, All: Boolean;

        Sec64Pn,
        SecCRC,
        EntireP64,
        EntireCRC

                   : Word;

        SouTime    : LongInt;
        SouSize    : LongInt;
        WriteError : Boolean;

        MaxSectSize,
        SectSize,
        LastSectSize,
        NumSect                  : LongInt;
        EntireC64                : T64;

        TxtBufSize,
        SecCRCs,
        StrPerLastS,
        SectNo,
        StrPerSect      : LongInt;
        t               : file;
        DskBuf,SouBuf   : PDskBufArr;
        OutBufSize,
        MsgNameNum      : LongInt;
        Sec64Crc        : T64;
        CalcEntireCrc,
        CalcSectCrc,
        CalcLineCrc,
        Calc64Crc       : Boolean;
        OutName         : PathStr;
        SouName         : PathStr;

procedure GetData(var Buf; Count: Word);
begin
 BlockRead(ST, Buf,Count);
 if CalcEntireCrc then cCRC(Buf,Count,EntireCRC);
 if Calc64Crc then Crc64(Buf,Count,EntireC64,EntireP64);
end;

procedure WriteT(const s:string);
var sl:byte absolute s;
begin
 if TxtBufSize + sl > OutBufSize then
 asm
   nop
 end;
 Move(s[1],DskBuf^[TxtBufSize+1],sl);
 Inc(TxtBufSize,sl);
end;

procedure WriteLnT(const s:string);
begin WriteT(s+GetLnEnd) end;

procedure WriteLnCRC(s:string);
var sl:byte;
begin
 if CalcSectCrc then
 begin
  sl:=Byte(s[0]);
  Inc(sl);Inc(SecCRCs,sl);s[sl]:=#10;
  cCrc(s[1],sl,SecCRC);
 end;
 if Calc64Crc then Crc64(s[1],sl,Sec64Crc,Sec64Pn);
 WriteLnT(s);
end;

procedure FlushT;
begin
 Rewrite(t,1);
 if IOResult>0 then begin WriteError:=True; Exit end;
 BlockWrite(t,DskBuf^,TxtBufSize);
 if IOResult>0 then WriteError:=True;
 Close(t);
 if IOResult>0 then WriteError:=True;
end;

procedure WriteEmptyLn;begin WriteLnT('') end;

function ItoS(a:longint):string;
 var s : string[40];
begin
 Str(a,s);
 ItoS:=s;
end;

procedure ClrIO;
begin
 InOutRes := 0;
 DosError := 0;
 {$IFDEF DN}
 Abort    := Off;
 {$ENDIF}
end;


{$IFDEF DN}

procedure InsertStatistics;

procedure WriteInfo(s1:string; const s2:string);
const sll=31;
begin
 while Length(s1)<sll do s1:=' '+s1;
 WriteLnT(s1+' : '+s2);
end;

function SStrPerSect:string;
var s:string;
begin
 if NumSect=0 then s:=ItoS(StrPerLastS) else
 begin
  if StrPerSect=StrPerLastS then s:=ItoS(StrPerSect) else
  s:=ItoS(StrPerSect)+' ('+ItoS(StrPerLastS)+')';
 end;
 SStrPerSect:=s;
end;

function Kb(L:LongInt):string;
begin
 Kb:=ItoS(L)+' ('+ItoS(SmartDiv(L,1024))+'Kb)';
end;

function Kb2(L:LongInt):string;
begin
 Kb2:=ItoS(SmartDiv(L,1024))+'Kb';
end;

function EncSize:string;
begin
 EncSize:=Kb2(LongMul((OutBufSize-SectNZ),NumSect+1));
end;

function GetDecimal(Number:word):string;assembler; {Set 2-b}
asm
        cld
        les     di,@Result
        mov     al,2
        stosb
        mov     ax,Number
        mov     cl,10
        div     cl
        add     ax,3030h
        stosw
end;

function GetMonth(Month:word):string;
begin
 GetMonth:=GetString(TStrIdx(Integer(dlJanuary)+Month-1))
end;

function StdDateTime(Year, Month, Day, Hour, Minute, Second:word):string;
var s:string[6];
   sl:byte absolute s;
begin
 s:=ItoS(Year);while sl>2 do DelFC(s);
 StdDateTime:=GetDecimal(Day)+'-'+GetMonth(Month)+'-'+s+' '+
 GetDecimal(Hour)+':'+GetDecimal(Minute)+':'+GetDecimal(Second);
end;

function CurStdDateTime:string;
var Dummy, Year, Month, Day, Hour, Minute, Second:word;
begin
 GetDate(Year, Month, Day, Dummy);
 GetTime(Hour, Minute, Second, Dummy);
 CurStdDateTime:=StdDateTime(Year, Month, Day, Hour, Minute, Second);
end;

function CrTime:string;
begin
 CrTime:=CurStdDateTime;
end;

function FTime:string;
var
        DT : DateTime;
begin
 UnpackTime(SouTime,DT);
 with DT do FTime:=StdDateTime(Year,Month,Day,Hour,Min,Sec);
end;

begin
 WriteInfo(GetString(dlUUencodeSFN),UpStrg(SouName));
 WriteInfo(GetString(dlUUencodeOS),Kb(SouSize));
 WriteInfo(GetString(dlUUencodeCreated),FTime);
 WriteInfo(GetString(dlUUencodeTime),CrTime);
 WriteInfo(GetString(dlUUencodeSize),EncSize);
 WriteInfo(GetString(dlUUencodeSections),ItoS(NumSect+1));
 WriteInfo(GetString(dlUUencodeLines),SStrPerSect);
 WriteEmptyLn;WriteEmptyLn;
end;

{$ENDIF}

var
  UUEData: TUUEncodeData;

procedure StartSection;
var LocalFreeStr, o:string;
    P: Pointer;
    II: Integer;
begin
 Inc(SectNo);
 if NumSect=0 then LocalFreeStr := Xt
   else if SectNo < 10 then LocalFreeStr := Copy(Xt, 1, 3)+ItoS(SectNo)
     else if SectNo < 100 then LocalFreeStr := Copy(Xt, 1, 2)+ItoS(SectNo)
       else LocalFreeStr := '.'+ItoS(SectNo);

 OutName:=Dr+Nm+LocalFreeStr;
 Assign(t,OutName);
{---------------------------------------------------------------}
if not All then
 begin
   { FileMode:=$40;}
    ClrIO;
    Reset(t,1);
    if IOResult=0 then
       begin
        Close(t);
{$IFDEF DN}
        P := @OutName;
        II := MessageBox(GetString(dlFileExist)+^M, @P, mfQuery+mfYesButton+mfNoButton+mfCancelButton+mfAllButton);
        Case II of
         cmOk: All := On;
         cmCancel,cmNo:
{$ENDIF}
         begin Cancel := True; Exit; end;
{$IFDEF DN}
        end;
        NewTimer(Timer, 0);
{$ENDIF}
       end;
  end;
 {---------------------------------------------------------------}
 TxtBufSize:=0;
 if CalcSectCrc then begin SecCRC:=0;SecCRCs:=0 end;
 if Calc64Crc then begin Clear64(Sec64Crc);Sec64Pn:=0 end;

{$IFDEF DN}
 PI^.Write(3, Cut(OutName, 40));
{$ELSE}
 WriteLn('Writing '+OutName+'...');
{$ENDIF}

 if NumSect>0 then o:=' of '+ItoS(NumSect+1) else o:='';
 o:='section '+ItoS(SectNo)+o+' of file '+SouName+'  '+UUETitle;
 if SectNo=1 then
 begin
{$IFDEF DN}
  if (UUEData.Prefix And ckStatistic)>0 then InsertStatistics;
{$ENDIF}
  WriteLnT(o+GetLnEnd);
{$IFDEF DN}if (UUEData.Prefix And ckFileTime)>0 then{$ENDIF}WriteLnT('filetime '+ItoS(SouTime));
{$IFDEF DN}
  if (UUEData.Prefix And ckMapTable)>0  then
  begin
   WriteLnCRC('table');
   WriteLnCRC('`!"#$%&''()*+,-./0123456789:;<=>?');
   WriteLnCRC('@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_');
  end;
{$ENDIF}
  WriteLnCRC('begin 644 '+SouName);
 end else WriteLnT(o+GetLnEnd);
end;

procedure Hex8Lo(L:longInt;var HexLo);assembler;
asm
        cld
        les     di,[HexLo]
        lea     bx,[LoHexChar]
        mov     dx,[word ptr L+2]
        call    @@OutWord
        mov     dx,[word ptr L+0]
        call    @@OutWord
        jmp     @@End

@@OutWord:      {DX-word}
        mov     ax,dx
        mov     cl,12
        shr     ax,cl
        xlat
        stosb
        mov     al,dh
        and     al,0Fh
        xlat
        stosb
        mov     al,dl
        mov     cl,4
        shr     al,cl
        xlat
        stosb
        mov     al,dl
        and     al,0Fh
        xlat
        stosb
        retn
@@End:
end;


function SS64(n:T64):string;
var s:string;
begin
 s[0]:=#16;
 Hex8Lo(n.l1,s[1]);
 Hex8Lo(n.l0,s[9]);
 SS64:=s;
end;

procedure EndSection;
var f,t:string;

begin
 if SectNo=NumSect+1 then
 begin
  if CalcLineCrc then WriteLnCRC('``') else WriteLnCRC('`');
  WriteLnCRC('end');
 end else
 begin
  WriteLnT('');
 end;
 if CalcSectCrc then
 begin
  if NumSect=0 then begin f:='"begin"';t:='"end"' end else
  if SectNo=1 then begin f:='"begin"';t:='last encoded line' end else
  if SectNo=NumSect+1 then begin f:='first encoded line';t:='"end"' end else
                      begin f:='first';t:='last encoded line' end;
  f:=' section (from '+f+' to '+t+')';

  WriteLnT('sum -r/size '+ItoS(SecCRC)+'/'+ItoS(SecCRCs)+f);
 end;
 t:=' entire input file';
 if CalcEntireCrc then
 begin
  if SectNo=NumSect+1 then WriteLnT('sum -r/size '+ItoS(EntireCRC)+
   '/'+ItoS(SouSize)+t);
 end;

 if Calc64Crc then
 begin
  WriteEmptyLn;
  WriteLnT('crc64 '+SS64(Sec64Crc)+f);
  if SectNo=NumSect+1 then WriteLnT('crc64 '+SS64(EntireC64)+t);
 end;

 WriteEmptyLn;

 FlushT;
end;

procedure WriteStr(var Buf;NumBytes:word);
var d  : string[60];
    dl : byte absolute d;
    s  : array[1..45] of byte;
begin
 Move(Buf,s,NumBytes);
 if NumBytes<45 then FillChar(s[NumBytes+1],45-NumBytes,0);
 Prepare1Str(s,d[1]);
 dl:=SmartDiv((NumBytes),3)*4;
 if CalcLineCrc then
       WriteLnCRC(GetUUxlt(NumBytes)+d+GetLnCrc(d[1],dl)) else
       WriteLnCRC(GetUUxlt(NumBytes)+d);
end;

procedure WriteSection(var Buf;ss:word);
var i:word;Buff:TDskBufArr absolute Buf;
begin
 for i:=0 to ss-1 do WriteStr(Buff[(i)*45+1],45);
end;

procedure WriteCompleteSection(var Buf);
begin WriteSection(Buf,StrPerSect) end;

procedure Write_Section;
begin
 StartSection;
 if Cancel then Exit;  {!! IB}
 GetData(SouBuf^,SectSize);
 WriteCompleteSection(SouBuf^);
 EndSection;
end;

procedure WriteLastSection;
var i:word;
begin
 StartSection;
 if Cancel then Exit;  {!! IB}
 GetData(SouBuf^,LastSectSize);
 i:=StrPerLastS-1;
 if i>0 then WriteSection(SouBuf^,i);
 WriteStr(SouBuf^[(i)*45+1],LastSectSize-(i)*45);
 EndSection;
end;

procedure EncodeSections;
var i:word;
{$IFDEF DN}
  IdleTimer: TEventTimer;
{$ENDIF}
begin
 Cancel:=False;
 All:=False;
 {$IFDEF DN}
 NewTimer(IdleTimer, 0);
 {$ENDIF}
 if CalcEntireCrc then EntireCRC:=0;
 if Calc64Crc then begin Clear64(EntireC64);EntireP64:=0 end;
 for i:=1 to NumSect do
   begin
     Write_Section;
     if WriteError or Cancel then Exit;
{$IFDEF DN}
     if TimerExpired(IdleTimer) then
     begin
       if ApplicationIdle(PI) then Exit;
       NewTimer(IdleTimer, 1);
     end;
{$ENDIF}
   end;
 WriteLastSection;
end;

procedure CalcLSsize;
var ls:LongInt;
begin
 ls:=SouSize-LongMul(SectSize,NumSect);
 while ls<SectSize div 2 do
 begin
  Inc(ls,SectSize);
  Dec(NumSect);
 end;
 while ls>SectSize do
 begin
  Dec(ls,SectSize);
  Inc(NumSect);
 end;
 LastSectSize:=ls;
end;

procedure GetFInfo;
var f:file;
begin
 Assign(f,FName);
 FileMode:=$40;
 ClrIO;
 Reset(f,1);
 if IOResult<>0 then exit;
 GetFTime(f,SouTime);
 Close(f);
end;

FUNCTION MakeNormName(S, S1: string): string;
begin
 While S[Length(S)] = ' ' do Dec(S1[0]);
 While S1[Length(S1)] = ' ' do Dec(S1[0]);
 if S <> '' then
 begin
   if S[Length(S)]='\' then MakeNormName := S + S1
                       else MakeNormName := S + '\' + S1;
 end else MakeNormName := S1;
end;

FUNCTION Min(x,y: LongInt):LongInt; begin if x<y then Min:=X else Min:=Y end;
FUNCTION Max(x,y: LongInt):LongInt; begin if x<y then Max:=Y else Max:=X end;

procedure DoIt;
var sss,Ma:LongInt;
    II : Integer;
    LocalFreeStr, UUEncodeDataName: string;
Label beg;
begin

 WriteError:=False;
{$IFDEF DN}
 UUEData := UUEncodeData;
 UUEData.Name := '';
{$ENDIF}
 FSplit(FName, Dr, Nm, Xt);

 SouName:=Nm+Xt;

 {$IFDEF DN}
 Message(Application, evCommand, cmPushFirstName, @UUEData.Name);
 {$ELSE}
 UUEData.Name := '';
 {$ENDIF}

 {$IFDEF DN}UUEData.Name{$ELSE}UUEncodeDataName{$ENDIF} := MakeNormName(UUEData.Name, Nm+'.UUE');

beg:

{$IFDEF DN}
 if ExecResource(dlgUUEncode, UUEData) <> cmOK then Exit;
 if (UUEData.CheckSum <> UUENcodeData.CheckSum) or
    (UUEData.Prefix   <> UUENcodeData.Prefix) or
    (UUEData.NLines   <> UUENcodeData.NLines) or
    (UUEData.Format   <> UUENcodeData.Format) then
    begin
      UUENcodeData := UUEData;
      UUENcodeData.Name := '';
      ConfigModified:=True;
    end;
{$ENDIF}

 CalcEntireCrc := {$IFDEF DN}UUEData.Checksum >= ckEntire{$ELSE}True  {$ENDIF};
 CalcSectCrc   := {$IFDEF DN}UUEData.Checksum >= ckStd   {$ELSE}True  {$ENDIF};
 CalcLineCrc   := {$IFDEF DN}UUEData.Checksum >= ckEach  {$ELSE}True  {$ENDIF};
 Calc64Crc     := {$IFDEF DN}UUEData.Checksum >= ck64    {$ELSE}False {$ENDIF};

 GetLnEnd := #13#10;
{$IFDEF DN}
 if UUEData.Format=1 then GetLnEnd := #10;
{$ENDIF}

 NLines := 900;

{$IFDEF DN}
 Val(UUEData.NLines, L, I);
 if I = 0 then NLines := Max(10, L);
{$ENDIF}


 FSplit({$IFDEF DN}Advance.{$ENDIF}FExpand({$IFDEF DN}UUEData.Name{$ELSE}UUEncodeDataName{$ENDIF}), S, Nm, Xt);
 if (Xt='') or (Xt='.') then Xt:='.UUE';
 if Nm = '' then
   begin
     FSplit(FName, Dr, Nm, Xt);
     Dr := MakeNormName(S, '');
     Xt := '.UUE';
   end else Dr := S;

{$IFDEF DN}
 CreateDirInheritance(Dr, Off);
{$ENDIF}

 Assign(ST,FName);
 FileMode:=$40;
 ClrIO;
 Reset(ST,1);
 if IOResult <> 0 then
 begin
{$IFDEF DN}
  MessageBox(GetString(dlArcMsg4) + Cut(FName, 40), nil, mfError + mfOKButton);
  NewTimer(Timer, 0);
{$ENDIF}
  Exit
 end;

 SouSize := FileSize(ST);

 if SouSize<3 then
  begin
   Close(ST);
{$IFDEF DN}
   Msg(dlFileIsSmall, nil, mfError+mfOkButton);
   NewTimer(Timer, 0);
{$ENDIF}
   Exit; {Input file is too small}
  end;

 LocalFreeStr:=Dr+Nm+Xt;
 Assign(t,LocalFreeStr);
 FileMode:=$40;
 ClrIO;
 Reset(t,1);
 if IOResult=0 then
    begin
     Close(t);
{$IFDEF DN}
     P := @LocalFreeStr;
     II := MessageBox(GetString(dlFileExist)+^M, @P, mfQuery+mfYesButton+mfNoButton+mfCancelButton+mfAllButton);
     Case II of
      cmOk    :   All := True;

      cmCancel:
{$ENDIF}
                  begin Close(ST); Exit; end;
{$IFDEF DN}
      cmNo    :   begin Close(ST); Goto beg end;
     end;
    NewTimer(Timer, 0);
{$ENDIF}
    end;


 GetFInfo;

 MaxSectSize:=LongMul(NLines,45);
 NumSect:=SmartDIV(SouSize,MaxSectSize)-1;
 SectNo:=0;

 if NumSect=0 then begin LastSectSize:=SouSize;SectSize:=0 end else
 begin
  SectSize:=LongMul(SmartDIV(SmartDIV(SouSize,NumSect+1),45),45);
  CalcLSSize;
 end;

 StrPerSect:=SmartDIV(SectSize, 45);
 StrPerLastS:=SmartDIV(LastSectSize,45);
 OutBufSize:=LongMul(Max(StrPerSect,StrPerLastS),70)+SectNZ;
 sss:=Max(SectSize,LastSectSize);
 SectNo:=0;
 Ma:=MaxAvail-OutBufSize-sss;
 if (Ma<20000) or (OutBufSize>$FFEF) then
 begin
  Close(ST);
{$IFDEF DN}
  if NLines > 900 then
    begin
      ErrMsg(dlMaxFiles);
      NewTimer(Timer, 0);
      Goto beg;
    end;
  ErrMsg(erNotEnoughMemory);
  NewTimer(Timer, 0);
{$ENDIF}
  WriteError:=True;
  Exit;
 end;

 GetMem(DskBuf,OutBufSize);
 GetMem(SouBuf,sss);

{$IFDEF DN}
 R.Assign(0,0,40,9);
 New(PI, Init(R));
 PI^.Top := GetString(dlUUEncode);
 PI^.Write(1,GetString(dlUUEncoding)+Cut(FName, 40));
 PI^.Write(2,GetString(dlFC_To));
 Desktop^.Insert(PI);
 NewTimer(Timer, 0);
{$ELSE}
 WriteLn('Encoding '+FName+'...');
{$ENDIF}

 EncodeSections;
 FreeMem(SouBuf,sss);
 FreeMem(DskBuf,OutBufSize);
 Close(ST);
{$IFDEF DN}
 PI^.Free;
 if WriteError then
  begin
   P:=@OutName;
   Msg(dlCanNotWrite, P, mfError+mfOkButton);
   NewTimer(Timer, 0);
  end;
 RereadGlobal(Dr);
 if (FMSetup.Options and fmoBeep <> 0) and
      (ElapsedTimeInSecs(Timer) > 20) then BeepAfterCopy;
{$ENDIF}
end;

begin
{$IFDEF DN}Inc(SkyEnabled);{$ENDIF}
  DoIt;
{$IFDEF DN}Dec(SkyEnabled);{$ENDIF}
end;

{$ENDIF}


end.