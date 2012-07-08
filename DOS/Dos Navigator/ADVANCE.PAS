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


{$A-,B-}

UNIT Advance;

INTERFACE

USES Dos;

const
  TextReaderBufSize = $1000;

type
  TTextReaderBuf = array[0..TextReaderBufSize-1] of Char;

   PTextReader = ^TTextReader;
   TTextReader = object
     Eof: Boolean;
     constructor Init(const FName: string);
     function GetStr: string;
     function FileName: string;
     destructor Done; virtual;
   private
     Handle: File;
     BufSz: Integer;
     BufPos: Integer;
     Buf: TTextReaderBuf;
     Skip1: Boolean;
   end;

  { TColorIndexes }

  PColorIndex = ^TColorIndex;
  TColorIndex = record
    GroupIndex: byte;
    ColorSize: byte;
    ColorIndex: array[0..255] of byte;
  end;


  TSize = Comp;
  CharSet = set of Char;
  Str2 = string[2];
  Str3 = string[3];
  Str4 = string[4];
  Str5 = string[5];
  Str8 = string[8];
  Str12 = string[12];
  Str40 = string[40];
  TCharImage = array [0..15] of Byte;
  TDCountryInfo = record
                    DateFmt: Word;
                    Currency: array[1..5] of Char;
                    ThSep: array[1..2] of Char;
                    DecSep: array[1..2] of Char;
                    DateSep: array[1..2] of Char;
                    TimeSep: array[1..2] of Char;
                    CurFmt: Byte;
                    CurDec: Word;
                    TimeFmt: Byte;
                    CaseTbl: Pointer;
                    DataSep: array[1..2] of Char;
                    Zeros: array[1..10] of Byte;
                  end;

    TCountryInfo = record
      DateFmt: Word;  {Radiobuttons}
      TimeFmt: Word;  {Radiobuttons}
      DateSep: string[1]; {Inputline}
      TimeSep: string[1]; {Inputline}
      ThouSep: string[1]; {Inputline}
      DecSep: string[1]; {Inputline}
      DecSign: string[1]; {Inputline}
      Currency: string[4]; {Inputline}
      CurrencyFmt: Word;  {Radiobuttons}
      UpperTable: array[#128..#255] of Char;
    end;


CONST

  ColorIndexes: PColorIndex = nil;

{ Keyboard state and shift masks }

  kbRightShift  = $0001;
  kbLeftShift   = $0002;
  kbCtrlShift   = $0004;
  kbAltShift    = $0008;
  kbScrollState = $0010;
  kbNumState    = $0020;
  kbCapsState   = $0040;
  kbInsState    = $0080;

  On  = True;
  Off = False;

  NumFloppy:      Byte    = 0;
  JustRegistered: Boolean = Off;

function FExpand (Path: PathStr): PathStr;
function StrGrd(AMax, ACur: LongInt; Wide: Byte): string;
function Percent(AMax, ACur: LongInt): LongInt;
procedure LowPrec(var A, B: LongInt);
procedure ResourceAccessError;
function LngId: string;
function  ExistFile(const FName : PathStr) : Boolean;
function MemOK: Boolean;
procedure Hex8Lo(L:longInt;var HexLo);
function CalcTmpFName(Id: LongInt; const AExt: Str3): PathStr;
function CalcTmpId:LongInt;
function HotKey(const S: String): Char;
function IsDriveCDROM(Drive : Char) : Boolean;
function Get100s: LongInt;
function MakeCMDParams(const S, Fl1, Fl2: string): string;
{procedure ParseCMDStr(S: string; var F: Text; var LbNo: Integer;
                      const Fl1, Fl2: string );}
function  GetEnv(S: string): string;
Procedure Sound ( Hz : word );
Procedure Nosound;
Procedure AddStr(var S ; C : char);
procedure DelFC(var s:string);

{---  ' '-related string functions }
FUNCTION  AddSpace(const s:string; N:byte):string;
FUNCTION  PredSpace(s:string; N:byte):string;
Function  DelSpaces(s : string) : string;
procedure DelSpace(var s : string);
Procedure DelRight(var S: string);
procedure DelLeft (var S: string);

function  GetSTime: LongInt;
procedure LocateCursor(X, Y: Byte);
procedure FillWord(var B;Count, W: Word);
procedure ChDir(S: string);
procedure GetUNIXDate(Julian: LongInt; var Year, Month, Day, Hour, Min, Sec: Word);
function  UpCaseStr(S: string): string;
function  LowCaseStr(S: string): string;
procedure EraseByName(const FName: PathStr);
Procedure EraseFile(const N: PathStr);

{
 Function  SearchFileStr(FName, What: string; Pos: LongInt; CaseSensitive: Boolean): LongInt;
 Function  SearchInFile(FName, What: string; CaseSensitive: Boolean): LongInt;
}

Function  BackSearchFor(S: string;var B;L: Word; CaseSensitive: Boolean): Word;
Function  SearchFor(S: string;var B;L: Word; CaseSensitive: Boolean): Word;

Function  DumpStr(var B; Addr: LongInt; Count: Integer; Filter: Byte): string;
Function  ValidDrive(dr : char) : Boolean;
Function  GetDrive : byte;
Procedure SetDrive(a : byte);
Function  Strg(c:char; Num: Byte) : string;
Function  UpStrg(const s : string) : string;
Procedure UpStr(var s : string);
Function  LowStrg(s : string) : string;
Procedure LowStr(var s : string);
Function  LowCase(c : Char) : Char;
Procedure SetBlink(Mode : boolean);
Function  ItoS(a:longint):string;
Function  StoI(s:string):Longint;
Function  SStr(a:longint;b:Byte;c:Char):string;
Function  FStr(a:TSize):string;
Function  FileSizeStr( X: LongInt ): string;
Function  Hex2(a : byte) : Str2;
Function  Hex4(a : word) : Str4;
Function  Hex8(a : LongInt) : Str8;
Function  HexChar(a : byte) : char;
Procedure DefineChar(n : Integer;var a);
Procedure GetDChar(n : Integer;var a);
Procedure ClrIO;
Function  Cut(p : string; len : Byte ) : string;
Procedure GetMask(var m : string);
Procedure DelDoubles(const St : string;var Source : string);
function  GetCurDrive: Char;
procedure SetCurDrive(C: Char);

FUNCTION GetExt(const s:string):string;
FUNCTION Norm12(const s:string):Str12;
FUNCTION InMask(const Name,Mask: string):Boolean;
FUNCTION InFilter(Name,Filter: string):Boolean;
FUNCTION InSpaceMask(Name,Mask: string;ValidSpace: Boolean):Boolean;
FUNCTION InSpaceFilter(Name,Filter: string):Boolean;
FUNCTION GetPath(S: PathStr): PathStr;
FUNCTION GetName(S: PathStr): PathStr;
FUNCTION MakeFileName(S: string): string;
FUNCTION MakeNormName(S, S1: string): string;
FUNCTION Replace(const Pattern, ReplaceString: string; var S: string): Boolean;
function FindArg(const Command: string; var S: string): Boolean;

FUNCTION XDiv1024( X: LongInt ): LongInt;
FUNCTION LongRatio( X, Y: LongInt ): Integer;

FUNCTION XRandom(N: Integer): Integer; { Rnd -N..N }
FUNCTION Min(x,y: LongInt):LongInt;
FUNCTION Max(x,y: LongInt):LongInt;
FUNCTION Sgn(x  : integer):integer;
FUNCTION Real2Str(X: Real; N: Byte): string;
FUNCTION Long2Str(X: Longint; L: Byte): string;
FUNCTION Long0Str(X: Longint; L: Byte): string;
FUNCTION ToHex(I: Word): string;
PROCEDURE DosWrite( S: string );
FUNCTION  PosChar(C: Char; S: string): Byte;
procedure MakeDate(Mode,Day,Month,Year,Hour,Min: Word; var S: string);
procedure MakeCurrency(R: Real; var S: string);
function  KeyPressed: Boolean;
procedure Beep(N: Byte);
function  FindParam(const S: string): Integer;
function  Chk4Dos: Boolean;
function  FileNameOf(var F: file): string;
function  MemAdjust(L: LongInt): LongInt;

const
     UpperString: string =
     #1#2#3#4#5#6#7#8#9#10#11#12#13#14#15#16 +
     #17#18#19#20#21#22#23#24#25#26#27#28#29#30#31#32 +
     '!"#$%&''()*+,-./0123456789:;<=>?@' +
     'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`' +
     'ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~' +
     'AÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü' +
     'AÅÇÉÑÖÜáàâäãåçéè∞±≤≥¥µ∂∑∏π∫ªºΩæø¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ'+
     'êëíìîïñóòôöõúùûüÒÚÛÙıˆ˜¯˘˙˚¸˝˛'#255;
     LowerString: string =
     (#1#2#3#4#5#6#7#8#9#10#11#12#13#14#15#16 +
     #17#18#19#20#21#22#23#24#25#26#27#28#29#30#31#32 +
     '!"#$%&''()*+,-./0123456789:;<=>?@' +
     'abcdefghijklmnopqrstuvwxyz[\]^_`' +
     'abcdefghijklmnopqrstuvwxyz{|}~' +
     'a°¢£§e¶ß®©™´m≠oØpc‚y‰ÂÊÁËÈÍÎÏÌÓÔ' +
     'a°¢£§e¶ß®©™´m≠oØ∞±≤≥¥µ∂∑∏π∫ªºΩæø¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ'+
     'pc‚y‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛'#255);

      BreakChars  : Set of Char = [',',' ','[',']','{','}','(',')',':',';','.','^',
                                   '&','*','!','#','$','/','\','''','"','%','>','<',
                                   '-','+','=','|','?',#13,#10,#9,#26,#12];

      QuickExecExternalStr: string='';
      UpcaseInit : Boolean = Off;
      HexStr     : string[16] = '0123456789ABCDEF';
      LoHexChar  : array[0..$F] of char='0123456789abcdef';
      N_O_E_M_S  : string[5] = 'NOEMS';
         cTEMP_  : string[5] = 'TEMP:';
         cLINK_  : string[5] = 'LINK:';
         x_x     : string[3] = '*.*';

var
    ShiftState: Byte absolute $40:$17;
    Abort : Boolean;
    DOS40 : Boolean;
    OS210 : Boolean;
    FreeStr  : string;
    ActiveDir: PathStr;
    DNNumber: Byte;
    UpCaseArray: array[Char] of Char Absolute UpperString ;
    LowCaseArray: array[Char] of Char Absolute LowerString ;

  StartupDir: PathStr;
  SourceDir: PathStr;
  TempDir: PathStr;
  TempFile: PathStr;
  LngFile: PathStr;
  SwpDir: PathStr;


const
    CL_SafeBuf           = $8000;

    Linker: Pointer      = nil;
    NeedLocated: LongInt = 0;


const
  CountryInfo: TCountryInfo =
    ( DateFmt:1;
      TimeFmt:1;
      DateSep:'-';
      TimeSep:':';
      ThouSep:',';
      DecSep:'.';
      DecSign:'2';
      Currency:'$';
      CurrencyFmt:0;
      UpperTable:'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü' +
                 'ÄÅÇÉÑÖÜáàâäãåçéè∞±≤≥¥µ∂∑∏π∫ªºΩæø' +
                 '¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ' +
                 'êëíìîïñóòôöõúùûüÒÚÛÙıˆ˜¯˘˙˚¸˝˛'#255
    );

{         CountryInfo: record
                        Id: Byte;
                        Size: Word;
                        CoutryID: Word;
                        CodePage: Word;
                        DateFormat: Word;
                        Currency: array[1..5] of Char;
                        thouasands: Word;
                        decimal: Word;
                        DateSep: Word;
                        TimeSep: Word;
                        CurrencyFlags: Word;
                        CurDecimals: Word;
                        TimeForm: Byte;
                        CaseMap: Pointer;
                        DataList: Word;
                        Zeros: array [1..10] of Byte;
                        Length: Word;
                     end;
}
var  DCountryInfo: TDCountryInfo;

type SessionType = (stOS2SYS, stOS2FullScreen, stOS2Windowed, stPMSession,
                    stVDMFullScreen, stWinFullScreen, stWinWindow, stVDMWindow);

procedure StartOS2Session(DataLen: Word; Session: Sessiontype; Background: Boolean;
                          Title, Name, Args, IcoName: string);
procedure RunOS2Command(Command: string; Bckg: Boolean; Session: SessionType);
function  GetDateTime(Time: Boolean): string;

IMPLEMENTATION

uses xTime;


 function GetDateTime(Time: Boolean): string;
  var S: string[30];
      Y,M,D,DW: Word;
      H,Mn,SS,S100: Word;

   function LeadingZero(w: Word): string;
     var s: string;
   begin
     Str(w:0, s);
     LeadingZero := Copy('00', 1, 2 - Length(s)) + s;
   end;

   function FormatTimeStr(H, M, SS: Word): string;
    var N: string[3];
        S: string[20];
   begin
    if (CountryInfo.TimeFmt = 0) and (H > 12) then
     begin
        S := LeadingZero(h-12) + CountryInfo.TimeSep + LeadingZero(m) + CountryInfo.TimeSep + LeadingZero(ss);
        N := 'pm';
      end
    else
      begin
        S := LeadingZero(h)+ CountryInfo.TimeSep + LeadingZero(m) + CountryInfo.TimeSep + LeadingZero(ss);
        if CountryInfo.TimeFmt = 0
           then if (H < 12) then N := 'am' else N := 'pm'
           else N := '';
      end;
    FormatTimeStr := S + N;
   end;

 begin
   GetDate(Y,M,D,DW);
   GetTime(H,Mn,SS,S100);
   MakeDate(0, D, M, Y mod 100, H, Mn, S);
   if Time then S := FormatTimeStr(H, Mn, SS)
           else S[0] := #8;
   GetDateTime := S;
 end;

 procedure Beep;

 procedure Twf(a,b : Word);assembler;
 asm
         cli
         mov dx,60
 @L0:    mov bx,b
 @L1:        mov  al,$4A
             out  $61,al
             mov  cx,dx
             inc  cx
 @RepLoop:   loop @RepLoop
             mov  al,$48
             out  $61,al
             mov  cx,a
             sub  cx,dx
 @Rep2:      loop @Rep2
         dec bx
         jnz @L1
         dec dx
         jnz @L0
         sti
 end;

 begin
  case N of
   1 : begin Twf(800,2);Twf(1000,3);end;
   2 : begin Twf(1200,2);Twf(700,3);Twf(900,4);end;
   3 : begin Twf(1200,1);end;
  end;
 end;



procedure MakeDate;

 procedure GetDig(R: Byte; var S); assembler;
 asm
   les bx, S
{   mov byte ptr es:[bx], 2}
   mov al, R
   xor ah,ah
   mov cx, 10
   div cl
   add al, 48
   add ah, 48
   cmp al, 48
   jnz  @@1
   mov al, '0'
  @@1:
   mov es:[bx], ax
 end;

begin
  Year := Year mod 100;
  FillChar(S, 16, 32);
  S[0] := #15;
  Move(CountryInfo.DateSep[1], S[3], Length(CountryInfo.DateSep));
  Move(CountryInfo.DateSep[1], S[6], Length(CountryInfo.DateSep));
  Move(CountryInfo.TimeSep[1], S[12], Length(CountryInfo.TimeSep));
  case CountryInfo.DateFmt of
    0: begin
         GetDig(Day, S[4]);
         GetDig(Month, S[1]);
         GetDig(Year, S[7]);
       end;
    1: begin
         GetDig(Day, S[1]);
         GetDig(Month, S[4]);
         GetDig(Year, S[7]);
         if S[1] = '0' then S[1] := ' ';
       end;
    2: begin
         GetDig(Day, S[7]);
         GetDig(Month, S[4]);
         GetDig(Year, S[1]);
       end;
  end;
  GetDig(Min, S[13]);
  if CountryInfo.TimeFmt = 0 then
    begin
      if Hour <= 12 then if Hour = 12 then S[15] := 'p' else S[15] := 'a'
                    else begin Dec(Hour, 12); S[15] := 'p' end;
    end else Dec(S[0]);
  GetDig(Hour, S[10]);
  if S[10] = '0' then S[10] := ' ';
end;
(*assembler;
asm
 xor ax,ax
 or  al, Mode
 jnz @mmddyy
@ddmmyy:
 les bx, S
 mov byte ptr es:[bx], 14
 mov al, Day
 xor ah,ah
 mov cx, 10
 div cl
 add al, 48
 add ah, 48
 cmp al, 48
 jnz  @@1
 mov al, ' '
@@1:
 mov es:[bx+1], ax
 mov byte ptr es:[bx+3], '-'
 mov al, Month
 xor ah,ah
 mov cx, 10
 div cl
 add al, 48
 add ah, 48
 mov es:[bx+4], ax
 mov byte ptr es:[bx+6], '-'
 mov al, Year
 xor ah,ah
 mov cx, 10
 div cl
 add al, 48
 add ah, 48
 mov es:[bx+7], ax
 jmp @Exit
@mmddyy:
 cmp al, 1
 jnz @yymmdd
 mov al, Day
 mov ah, Month
 mov Day, ah
 mov Month, al
 jmp @ddmmyy
@yymmdd:
 mov al, Day
 mov ah, Month
 mov Day, ah
 mov Month, al
 jmp @ddmmyy
@Exit:
 mov al, Hour
 xor ah,ah
 mov cx, 10
 div cl
 add al, 48
 add ah, 48
 cmp al, 48
 jnz  @@2
 mov al, ' '
@@2:
 mov byte ptr es:[bx+9], ' '
 mov es:[bx+10], ax
 mov byte ptr es:[bx+12], ':'
 mov al, Min
 xor ah,ah
 mov cx, 10
 div cl
 add al, 48
 add ah, 48
 mov es:[bx+13], ax
end;
*)

FUNCTION GetPath;
var B: Byte;
begin
  B := Length(S); while (B > 0) and (S[B] <> '\') do Dec(B);
  If B=0 then GetPath:=S else GetPath:=Copy(S, 1, B)
end;

FUNCTION GetName;
var B: Byte;
begin
  B:=Length(S);
  For B:=length(S) downto 1 do If S[B]='\'
    then begin GetName:=Copy(S, B+1, 255); Exit end;
  GetName:=S;
end;

FUNCTION XRandom;
begin
  XRandom:=N div 2 - Random(N)
end;

FUNCTION GetExt;
var i:byte;
begin
  i:=PosChar('.',s);
  if i=0
    then GetExt:='.   '
    else GetExt:=Copy(s,i,length(s)-i)
end;

Function LowCase(c : Char) : Char;assembler;
label LocEx;
asm
   mov al,c
   cmp al,65
   jc  LocEx
   cmp al,91
   jnc LocEx
   xor al,$20
LocEx:
end;

Procedure LowStr(var s : string);assembler;
label NextChar,NoLow,LocExit;
asm
   les  bx,s
   mov  ch,0
   mov  cl, [es:bx]
   inc  bx
   jcxz LocExit
NextChar:
   mov  al, [es:bx]
   cmp  al,65
   jc   NoLow
   cmp  al,91
   jnc  NoLow
   xor  al,$20
   mov  [es:bx], al
NoLow:
   inc  bx
   loop NextChar
LocExit:
end;


Function LowStrg(s : string) : string;
begin
 LowStr(s);
 LowStrg:=s;
end;

Procedure UpStr(var s : string);assembler;
label NextChar,NoLow,LocExit;
asm
   les  bx,s
   mov  ch,0
   mov  cl, [es:bx]
   inc  bx
   jcxz LocExit
NextChar:
   mov  al, [es:bx]
   cmp  al,'a'
   jc   NoLow
   cmp  al,'z'+1
   jnc  NoLow
   xor  al,$20
   mov  [es:bx], al
NoLow:
   inc  bx
   loop NextChar
LocExit:
end;

Function UpStrg(const s : string) : string; assembler;
label NextChar,NoLow,LocExit;
asm
   cld
   push ds
   lds  si,s
   les  di, @Result
   lodsb
   stosb
   mov  cl,al
   mov  ch,0
   jcxz LocExit
NextChar:
   lodsb
   cmp  al,'a'
   jc   NoLow
   cmp  al,'z'+1
   jnc  NoLow
   xor  al,$20
NoLow:
   stosb
   loop NextChar
LocExit:
   pop  ds
end;

procedure DelSpace; assembler;
asm
  les bx, S
  xor ch, ch
  mov cl, es:[bx]
  jcxz @@1
  mov  di, 1
  mov  si, 1
  xor  al, al
  mov  es:[bx], al
@@2:
  mov  al, es:[bx][di]
  cmp  al, ' '
  jz   @@3
  cmp  al, 9
  jz   @@3
  mov  es:[bx][si], al
  inc  byte ptr es:[bx]
  inc  si
@@3:
  inc  di
  loop @@2
@@1:
end;


Function DelSpaces;
begin
 DelSpace(S);
 DelSpaces := S;
end;

Function MakeFileName(S: string): string;
 var I: Integer;
     L: Byte absolute S;
begin
 S[9] := '.';
 I := 8;
 While (I > 0) and (S[I] = ' ') do begin Delete(S, I, 1); Dec(I); end;
 While S[L] = ' ' do Dec(L);
 if S[Length(S)] = '.' then Dec(S[0]);
 MakeFileName := S;
end;

Function Strg; assembler;
asm
  les  di, @Result
  mov  al, Num
  stosb
  mov  ch, 0
  mov  cl, al
  mov  al, c
  rep  stosb
end;

Procedure SetBlink(Mode : boolean); assembler;
asm
      MOV  AX,1003H
      MOV  BL,Mode
      push bp
      INT  10h
      pop  bp
end;

Function  ItoS(a:longint):string;
 var s : string[40];
begin
 Str(a,s);
 ItoS:=s;
end;

Function  StoI(s:string):Longint;
 var i : longint;
     j : Integer;
begin
 Val(s,i,j);
 StoI:=i;
end;

Function  SStr(a:longint;b:Byte;c:Char):string;
 var s : string[40];
     i : integer;
begin
 Str(a:b,s);i:=1;
 While i<b do
  begin
   if s[i]=' ' then s[i]:=c else i:=255;
   Inc(i);
  end;
 SStr:=s;
end;

Function  FStr(a:TSize):string;
 var s,s1 : string[40];
     s1l: byte absolute s1;
     i : Integer;
     C: Char;
begin
 Str(A:0:0, S);
 if CountryInfo.ThouSep[0] > #0 then
   begin
      C := CountryInfo.ThouSep[1];
      asm
       lea si, s
       lea di, s1
       mov bx, di
       mov al, ss:[si]
       xor ah, ah
       mov cx, 3
       div cl
       mov byte ptr ss:[bx], 0
       mov cl, ss:[si]
       mov dl, ah
       Mov al, C
       or  dl, dl
       jnz @@1
       mov dl, 3
      @@1:
       or  cl, cl
       jz  @@3
      @@2:
       mov ah, ss:[si+1]
       mov byte ptr ss:[di+1], ah
       inc byte ptr ss:[bx]
       inc di
       inc si
       dec cl
       jz  @@3
       dec dl
       jnz @@2
       mov dl, 3
       mov byte ptr ss:[di+1], al
       inc di
       inc byte ptr ss:[bx]
       jmp @@2
      @@3:
      end;
   end else S1 := S;
 if Length(S1)>12 then
 begin
   Dec(s1l,3);
   s1[s1l] := 'K';
 end;
 FStr:=s1;
end;

Function Hex2;
begin Hex2:=HexChar(a shr 4)+HexChar(a) end;

Function Hex4;
begin
 Hex4:=HexChar(Hi(a) shr 4)+HexChar(Hi(a))+
       HexChar(Lo(a) shr 4)+HexChar(Lo(a));
end;

Function Hex8;
var s: Str8;
begin
 s[0]:=#8; Hex8Lo(a,s[1]); Hex8 := s;
end;

Function HexChar(a : byte) : char; assembler;
label Loc1;
asm
   mov al,a
   and al,0Fh
   add al,'0'
   cmp al,58
   jc  Loc1
   add al,7
Loc1:
end;

Procedure DefineChar(n : Integer;var a);
begin
 PortW[$3C4]:=$0402;
 PortW[$3C4]:=$0704;
 PortW[$3CE]:=$0005;
 PortW[$3CE]:=$0406;
 PortW[$3CE]:=$0204;
 move(a,mem[$A000:n*32],16);
 PortW[$3C4]:=$0302;
 PortW[$3C4]:=$0304;
 PortW[$3CE]:=$1005;
 PortW[$3CE]:=$0E06;
 PortW[$3CE]:=$0004;
end;

Procedure GetDChar(n : Integer;var a);
begin
 PortW[$3C4]:=$0402;
 PortW[$3C4]:=$0704;
 PortW[$3CE]:=$0005;
 PortW[$3CE]:=$0406;
 PortW[$3CE]:=$0204;
 move(mem[$A000:n*32],a,16);
 PortW[$3C4]:=$0302;
 PortW[$3C4]:=$0304;
 PortW[$3CE]:=$1005;
 PortW[$3CE]:=$0E06;
 PortW[$3CE]:=$0004;
end;

Procedure ClrIO;
begin
 InOutRes := 0;
 DosError := 0;
 Abort    := Off;
end;

function Cut;
begin
 Cut:=p; if Len>=Byte(p[0]) then Exit;
 Delete(p,3,Byte(p[0])-Len+4);Insert('...',p,3);
 Cut:=p;
end;

procedure GetMask(var m : string);
 var q : string[12];
     i : Byte;
     b : Boolean;
begin
 q:='????????.???';
 i:=Pos('.',m);
 if i>0 then if i>9 then Delete(m,9,i-9) else Insert(Copy('        ',1,9-i),m,i)
   else m:=Copy(m+Strg(' ',8),1,8)+'.   ';
 i:=1;b:=On;
 while m[i]<>'.' do
 begin
  if b then
   begin
    b:=b and (m[i]<>'*');
    if b then q[i]:=m[i];
   end;
   Inc(i);
 end;
 Delete(m,1,i);
 i:=1;b:=On;
 while (i<=3) and (m[0]>=Char(i)) do
 begin
  if b then
   begin
    b:=b and (m[i]<>'*');
    if b then q[i+9]:=m[i];
   end;
   Inc(i);
 end;
 m:=LowStrg(q);
end;

procedure DelDoubles;
begin
 while Pos(ST,Source)>0 do Delete(Source,Pos(St,Source),1);
end;

FUNCTION Min; begin if x<y then Min:=X else Min:=Y end;
FUNCTION Max; begin if x<y then Max:=Y else Max:=X end;
FUNCTION Sgn; begin if x>0 then Sgn:=1 else if x<0 then Sgn:=-1 else Sgn:=0 end;

PROCEDURE DosWrite;assembler;
asm
  les  di,S
  xor  cx,cx
  mov  cl,byte ptr es:[di]
  jcxz @empty
@loop:
  inc  di
  mov  ah,2
  mov  dl,byte ptr es:[di]
  push es
  push di
  push cx
  int  21h
  pop  cx
  pop  di
  pop  es
  loop @loop
@empty:
end;

FUNCTION  PosChar; assembler;
asm
  les di,S
  xor ch,ch
  mov cl,byte ptr es:[di]
  mov bx,cx
  inc di
  cld
  mov al,C
  repne scasb
  jnz @S
  sub bx,cx
  mov al,bl
  jmp @Q
@S:xor al,al
@Q:
end;


FUNCTION Norm12;
var R: string[12]; I: Byte; L: Byte absolute S;
begin
  {if S[0]=#12 then begin Norm12:=S; Exit end;}
  System.FillChar(R[1],12,' '); R[0]:=#12;
  if s[1]='.' then begin Norm12:=AddSpace(s,12); Exit end;
  R[9]:='.'; i:=PosChar('.',s);
  if i=0 then i:=succ(l) else move(s[succ(i)],r[10],Min(l-i,3));
  if i>8 then i:=8 else dec(i);
  move(s[1],r[1],i);
  i:=1;
  while i<=12 do
    if r[i]='*'
      then while (i<>9) and (i<=12) do begin
        r[i]:='?';
        inc(i)
      end else inc(i);
  Norm12:=R
end;

FUNCTION InMask;
var i:byte;
begin
  i:=13;
  repeat
    dec(i);
    if (Mask[i]<>'?') and (UpCase(Mask[i])<>UpCase(Name[i]))
      and (I <> 9)
      then begin InMask:=Off; Exit end
  until i=0; InMask:=On
end;

FUNCTION InFilter;
var i:byte; l:byte absolute Filter;
    S: string[13];
    B: Boolean;
begin
  InFilter:=On; if Pos(' ',Filter) > 0 then Filter := DelSpaces(Filter);
  UpStr(Filter); UpStr(Name);
  if Filter='' then Exit; Name:=Norm12(Name);
  repeat if Filter[l]=';' then dec(l);
    if l<>0 then begin
      i:=l; while (i>1)and(Filter[pred(i)]<>';') do dec(i);
      S := Copy(Filter,i,succ(l-i)); B := S[1] = '-';
      InFilter := not B;
      if B then DelFC(S);
      DelLeft(S);
      if (S <> '') and InMask(Name, Norm12(S)) then Exit;
      l:=pred(i);
    end
  until l=0; InFilter:=Off
end;

FUNCTION InSpaceMask;
var i:byte;
    j:Boolean;
begin
  i:=13;
  repeat
    dec(i);
    if (Mask[i]='?') or ((Mask[I]=' ') and ValidSpace) or (UpCase(Mask[i])=UpCase(Name[i]))
      or (I = 9) then else begin InSpaceMask:=Off; Exit end
  until i=0; InSpaceMask:=On
end;

FUNCTION InSpaceFilter;
var i:byte; l:byte absolute Filter;
    S: string[13];
    B: Boolean;
begin
  InSpaceFilter:=On; if Pos(' ',Filter) > 0 then Filter := DelSpaces(Filter);
  UpStr(Filter); UpStr(Name);
  if Filter='' then Exit; Name:=Norm12(Name);
  repeat if Filter[l]=';' then dec(l);
    if l<>0 then begin
      i:=l; while (i>1)and(Filter[pred(i)]<>';') do dec(i);
      S := Copy(Filter,i,succ(l-i)); B := S[1] = '-';
      InSpaceFilter := not B;
      if B then DelFC(S);
      DelLeft(S);
      if (S <> '') and InSpaceMask(Name, Norm12(S), On) then Exit;
      l:=pred(i);
    end
  until l=0; InSpaceFilter:=Off
end;



FUNCTION AddSpace(const s:string; N:byte):string; assembler;
asm
   cld
   push  ds
   lds   si, s
   les   di, @Result
   lodsb
   mov   ah, N
   mov   ch, 0
   cmp   al, ah
   jae   @JustCopy
   mov   [es:di], ah
   inc   di
   mov   cl, al
   rep   movsb
   sub   ah, al
   mov   al, ' '
   mov   cl, ah
   rep   stosb
   jmp   @End

@JustCopy:
   stosb
   mov  cl, al
   rep movsb
@End:
   pop  ds
end;

FUNCTION PredSpace;
begin
  If Length(S)>=N then PredSpace:=S else begin
    FillChar(FreeStr[1],255,' ');
    Move(S[1], FreeStr[succ(N-Length(S))], Length(S));
    FreeStr[0]:=char(N); PredSpace:=FreeStr
  end
end;

FUNCTION Real2Str; begin System.Str(X:N, FreeStr); Real2Str:=FreeStr end;
FUNCTION Long2Str; begin Str(x:l,FreeStr); Long2Str:=FreeStr; end;
FUNCTION Long0Str; var I: Byte;
begin Str(x:l, FreeStr); For I:=1 to length(FreeStr) do if FreeStr[I]=' ' then FreeStr[I]:='0'; Long0Str:=FreeStr end;
FUNCTION ToHex; var s:string; c:byte; b:byte;
begin s:=''; for c:=1 to 4 do begin
  s:=char(48 + (i and 15) + byte( (i and 15)>9)*7 )+s; i:=i div 16 end;
  ToHex:=s;
end;

function ValidDrive(dr : char) : Boolean;
var s,s1 : string[40];
    B,B1: Byte;
begin
 ValidDrive := Off;
 if (dr < 'C') then
   begin
     ValidDrive := (NumFloppy >= Byte(dr)-64);
     Exit;
   end;
 B := GetDrive;
 SetDrive(Byte(Dr)-65);
 B1 := GetDrive;
 SetDrive(B);
 if Byte(dr)-65 <> b1 then Exit;
 s:=dr+':\QQP.OBJ'#0;
 asm
    lea  di,s1
    push ss
    pop  es
    lea  si,s+1
    push ds
    push ss
    pop  ds
    mov  ax,2900h
    int  21h
    pop  ds
    cmp  al,0FFh
    mov  al,1
    jnz  @LocEx
    xor  al,al
@LocEx:
    mov  [bp-1],al
 end;
end;

function DumpStr;
 var S: string;

begin
 DumpStr := '';
 if Count <= 0 then Exit;
 S[0] := Char(Count*4+12);
 asm
  les   di, B
  lea   bx, S
  inc   bx
  mov   cx, Count
  mov   al, byte ptr Addr+3
  mov   dx, cx
  mov   ah, al
  mov   cx, 4
  shr   al, cl
  mov   cx, dx
  and   ah,0Fh
  add   al,'0'
  cmp   al,58
  jc    @@01
  add   al,7
@@01:
  add   ah,'0'
  cmp   ah,58
  jc    @@02
  add   ah,7
@@02:
  mov   ss:[bx], ax
  mov   al, byte ptr Addr+2
  mov   dx, cx
  mov   ah, al
  mov   cx, 4
  shr   al, cl
  mov   cx, dx
  and   ah,0Fh
  add   al,'0'
  cmp   al,58
  jc    @@11
  add   al,7
@@11:
  add   ah,'0'
  cmp   ah,58
  jc    @@12
  add   ah,7
@@12:
  mov   ss:[bx+2], ax
  mov   al, byte ptr Addr+1
  mov   dx, cx
  mov   ah, al
  mov   cx, 4
  shr   al, cl
  mov   cx, dx
  and   ah,0Fh
  add   al,'0'
  cmp   al,58
  jc    @@21
  add   al,7
@@21:
  add   ah,'0'
  cmp   ah,58
  jc    @@22
  add   ah,7
@@22:
  mov   ss:[bx+4], ax
  mov   al, byte ptr Addr
  mov   dx, cx
  mov   ah, al
  mov   cx, 4
  shr   al, cl
  mov   cx, dx
  and   ah,0Fh
  add   al,'0'
  cmp   al,58
  jc    @@31
  add   al,7
@@31:
  add   ah,'0'
  cmp   ah,58
  jc    @@32
  add   ah,7
@@32:
  mov   ss:[bx+6], ax
  mov   ax,' :'
  mov   ss:[bx+8], ax
  add   bx, 10
  mov   si, bx
  add   si, cx
  add   si, cx
  add   si, cx
  mov   ax, ' ≥'
  mov   ss:[si], ax
  add   si, 2
@@2:
  mov   al, es:[di]
  mov   dl, al

    cmp  Filter, 0
    jz   @@@2
    cmp  dl, 32
    jnc  @@@4
@@@5:
    mov  dl, '˙'
    jmp  @@@2
@@@4:
    cmp  Filter, 1
    jnz  @@@2
    cmp  dl, 128
    jnc  @@@5
@@@2:


  or    al, al
  jnz   @@3
  mov   dl, '.'
@@3:
  mov   ss:[si], dl
  mov   dx, cx
  mov   ah, al
  mov   cx, 4
  shr   al, cl
  mov   cx, dx
  and   ah,0Fh
  add   al,'0'
  cmp   al,58
  jc    @@41
  add   al,7
@@41:
  add   ah,'0'
  cmp   ah,58
  jc    @@42
  add   ah,7
@@42:
  mov   ss:[bx], ax
  mov   al, ' '
  mov   ss:[bx+2], al
  add   bx, 3
  inc   si
  inc   di
  loop  @@2
 end;
 DumpStr := S;
end;

procedure InitUpcase; near;
 var C: Char;
begin
  UpcaseInit := On;
  Move(CountryInfo.UpperTable, UpcaseArray[#128], 128);
  Move(CountryInfo.UpperTable, LowcaseArray[#128], 128);
  for C := #128 to #255 do
    begin
      if (UpcaseArray[C] <> C) and (UpcaseArray[C] > #127) then
       begin
         LowCaseArray[UpcaseArray[C]] := C;
         LowCaseArray[C] := C;
       end;
    end;
end;

function UpCaseStr(S: string): string;
begin
 asm
  cmp UpcaseInit, 0
  jnz @@@1
  call InitUpcase
@@@1:
  lea si, UpCaseArray
  lea di, S
  mov cl, ss:[di]
  xor ch, ch
  xor bh, bh
  or  cl, cl
  jz  @Exit
@@1:
  inc di
  mov al, ss:[di]
  or al, al
  jz @@2
  mov bl, al
  mov al, ds:[bx+si]
  mov ss:[di], al
@@2:
  loop @@1
@Exit:
 end;
 UpCaseStr := S;
end;

function LowCaseStr(S: string): string;
begin
 asm
  cmp UpcaseInit, 0
  jnz @@@1
  call InitUpcase
@@@1:
  lea si, LowCaseArray
  lea di, S
  mov cl, ss:[di]
  xor ch, ch
  xor bh, bh
  or  cl, cl
  jz  @Exit
@@1:
  inc di
  mov al, ss:[di]
  or al, al
  jz @@2
  mov bl, al
  mov al, ds:[bx+si]
  mov ss:[di], al
@@2:
  loop @@1
@Exit:
 end;
 LowCaseStr := S;
end;

const LastCase: Byte = 2;
var  Tran: array[Char] of Char;

procedure MakeCase(CaseSensitive: Boolean);
begin
 if not UpcaseInit then InitUpcase;
 if Byte(CaseSensitive) <> LastCase then
 if CaseSensitive then
  asm
   lea bx, Tran
   add bx, 255
   mov cx, 256
@@1:
   mov ax, cx
   dec ax
   mov ds:[bx], al
   dec bx
   loop @@1
  end else Move(UpCaseArray, Tran, 256);
  LastCase := Byte(CaseSensitive);
end;

function SearchFor;
 var D: array[Char] of Word;
     ChBuf: array [0..0] of Char absolute B;
     I: Integer;
     BB: Byte;
     M: Word;
     C: Char;
begin
 SearchFor := 0;
 if S = '' then Exit;
 MakeCase(CaseSensitive);
 asm
  lea di, D
  mov ax, ss
  mov es, ax
  mov cx, 256
  lea bx, S
  mov al, ss:[bx]
  xor ah, ah
  cld
  rep stosw
  mov dx, ax
  mov cx, ax
  lea bx, Tran
  lea si, S
@@@2:
  inc si
  mov al, ss:[si]
  push bx
  add bx, ax
  mov al, ds:[bx]
  pop bx
  mov ss:[si], al
  loop @@@2
  mov cx, dx
  lea si, D
  lea bx, S
@@@1:
  inc bx
  dec dx
  mov al, ss:[bx]
  xor ah, ah
  add ax, ax
  push si
  add si, ax
  mov ss:[si], dx
  pop si
  loop @@@1
 end;
 M := Length(S) - 1;
 for I := 1 to Length(S) do S[I] := Tran[S[I]];
 while M < L do
  begin
   C := Tran[ChBuf[M]];
   if C = S[Byte(S[0])] then
    begin
     for I := 0 to Byte(S[0]) - 1 do
      begin
       if Tran[ChBuf[M-I]] <> S[Byte(S[0])-I] then Break;
       if I = Byte(S[0]) - 1 then begin SearchFor := M - I + 1; Exit; end;
      end;
     Inc(M);
    end else Inc(M, D[C]);

  end;
end;

function BackSearchFor;
 var D: array[Char] of Word;
     ChBuf: array [0..0] of Char absolute B;
     I: Integer;
     BB: Byte;
     M: LongInt;
     C: Char;
begin
 BackSearchFor := 0;
 if S = '' then Exit;
 MakeCase(CaseSensitive);
 FillWord(D, 255, Length(S));
 for I := 1 to Length(S) do S[I] := Tran[S[I]];
 for I := Length(S) downto 1 do
   D[S[I]] := I - 1;
 M := L - Length(S);
 while M >= 0 do
  begin
   C := Tran[ChBuf[M]];
   if C = S[1] then
    begin
     for I := 0 to Byte(S[0]) - 1 do
      begin
       if Tran[ChBuf[M+I]] <> S[I+1] then Break;
       if I = Byte(S[0]) - 1 then begin BackSearchFor := M + 1; Exit; end;
      end;
     Dec(M);
    end else Dec(M, D[C]);
  end;
end;


FUNCTION GetDrive : byte; assembler; asm mov ah,$19; int 21h; end;
PROCEDURE SetDrive(a : byte); assembler; asm mov ah,$0E; mov dl,a; int $21; end;

function KeyPressed: Boolean; assembler;
asm
 mov ah, 1
 int 16h
 mov ax,1
 jnz @@1
 xor ax,ax
@@1:
end;


function GetCurDrive; assembler;
asm
 mov ah, 19h
 int 21h
 xor ah, ah
 add al, 65
end;

procedure SetCurDrive; assembler;
asm
 mov ah, 0Eh
 mov dl, C
 sub dl, 65
 int 21h
end;

procedure EraseByName;
var
  F: file;
begin
  Assign(F, FName); Erase(F);
end;

procedure EraseFile;
var F: File;
begin
  ClrIO;
  FileMode := $42;
  Assign(F, N);
  Erase(F);
  case IOResult of
    5 : begin
          SetFAttr(F, Archive);
          Erase(F);
        end;
   19 : asm;
          mov  ah,0dh { Reset Disks }
          int  21h
        end;
  end;
  ClrIO;
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

function Replace;
 var I, J, K: Integer;
begin
 J := 1; K := 1; Replace := False;
 if (Pattern = '') or (S = '') then Exit;
 repeat
  I := Pos(Pattern, Copy(S, J, 255));
  if I > 0 then
   begin
    Delete(S, J+I-1, Byte(Pattern[0]));
    Insert(ReplaceString, S, J+I-1);
    Replace := True;
   end;
  K := I;
  Inc(J, I + Length(ReplaceString) - 1);
 until I = 0;
end;

Function LongRatio;
begin
  While X > ( MaxLongInt div 100 ) do begin
    X := X div 128;
    Y := Y div 128;
  end;
  LongRatio := 100 * X div Y;
end;

Function XDiv1024; assembler;
asm
  mov ax,word ptr X
  mov dx,word ptr X + 2
  mov al,ah
  mov ah,dl
  mov dl,dh
  xor dh,dh
  shr dx,1
  rcr ax,1
  shr dx,1
  rcr ax,1
end;

Function FileSizeStr;
var
  S: string[40];
label K;
begin
  If X >= 0
    then
      If X < 10000000
        then FileSizeStr := FStr( X )
        else goto K
    else
      If X = -1
        then FileSizeStr := '?'
        else K: begin
          Str( XDiv1024( X ), S );
          If Length( S ) > 3 then Insert( ',', S, Length( S )-2 );
          FileSizeStr := S + 'K'
        end;
end;

procedure GetUNIXDate(Julian: LongInt; var Year, Month, Day, Hour, Min, Sec: Word);
  var
    L : LongInt;
    DT: DateTime;
begin
  L := xYMTimeStampToPack(Julian);
  UnpackTime(L, DT);
  Year := DT.Year;
  Month := DT.Month;
  Day := DT.Day;
  Hour := DT.Hour;
  Min := DT.Min;
  Sec := DT.Sec;
end;

procedure ChDir;
begin
   if (S[0] > #3) and (S[Length(S)] = '\') then Dec(S[0]);
   if PosChar(':', S) > 2 then
     begin InOutRes := 666; Exit; end;
   System.ChDir(S);
end;

procedure LocateCursor(X, Y: Byte); assembler;
asm
        MOV     AH, 2
        XOR     BX, BX
        MOV     DL, X
        MOV     DH, Y
        INT     10H
end;

 procedure FillWord(var B;Count, W: Word); assembler;
 asm
    cld
    mov  ax, W
    les  di, B
    mov  cx, Count
    rep  stosw
 end;

function FindArg(const Command: string; var S: string): Boolean;
 var I: Integer;
begin
  FindArg := Off;
  for I := 1 to ParamCount do
    begin
      S := UpStrg(ParamStr(I));
      if Copy(S, 1, Length(Command)) = Command then
       begin
         Delete(S, 1, Length(Command));
         FindArg := On;
         Exit
       end;
    end;
  S := '';
end;

function GetSTime: LongInt;
  var H, M, S, SS: Word;
begin
  GetTime(H, M, S, SS);
  GetSTime := SS + LongInt(S)*100 + LongInt(M)*6000 + LongInt(H)*360000;
end;


{ ------------------------------------ OS/2 API --------------------------- }

procedure StartOS2Session(DataLen: Word; Session: Sessiontype; Background: Boolean;
                          Title, Name, Args, IcoName: string);
 var R: Record
         Size, Relation, FBground, Trace: Word;
         Title: Pointer;
         Name: Pointer;
         Args: Pointer;
         TERMQ: LongInt;
         Env: Pointer;
         Inheritance: Word;
         Session: Word;
         IcoN: Pointer;
    end;

    P: Pointer;
begin
   if not OS210 then Exit;
   R.Size := DataLen;
   R.Relation := 1;
   R.FBground := Byte(Background);
   R.Trace := 0;
   Title := Title + #0;
   Name := Name + #0;
   Args := Args + #0;
   IcoName := IcoName + #0;
   R.Title := @Title[1];
   R.Name := @Name[1];
   R.Args := @Args[1];
   R.Inheritance := 0;
   R.Session := Word(Session);
   R.IcoN := @IcoName[1];
   R.TermQ := 0;
   LongInt(R.Env) := 0;
   P := @R;

   asm
     push ds
     mov ax, $6400
     mov cx, $636C
     mov bx, $0025
     lds si, P
     int 21h
     pop ds
   end;

end;

procedure RunOS2Command;
 var T: Text;
     I: Integer;
     S,M,EX: string;
begin
  if not OS210 then Exit;
  I := 1;
  repeat
    ClrIO;
    EX := SwpDir+'$DN'+Itos(I)+'$.CMD';
    Assign(T, EX);
    Filemode := $40;
    Reset(T);
    if IOResult <> 0 then Break;
    Close(T);
    if InOutRes = 0 then Inc(I);
  until IOResult <> 0;
  ClrIO;
  Assign(T, EX);
  Rewrite(T);
  GetDir(0, S);
  WriteLn(T, '@'+Copy(S,1,2));
  WriteLn(T, '@cd "'+S+'"');
  S := Command;
  if PosChar(';', S) > 0 then
   begin
     Replace(';;', #0, S);
     While (S <> '') and (PosChar(';', S) <> 0) do
      begin
        I := PosChar(';', S);
        M := Copy(S, 1, I-1); Replace(#0, ';', M);
        WriteLn(T, M);
        Delete(S, 1, I);
      end;
     Replace(#0, ';', S);
     WriteLn(T, S);
   end else WriteLn(T, Command);
  if not Bckg and (ShiftState and $20 = 0) then WriteLn(T, '@pause');
  Write(T, '@del "'+EX+'" & exit'^Z);
  Close(T);
  StartOS2Session($20, Session, Bckg, Command, GetEnv('OS2COMSPEC'),
                     '/c '+EX, '');
end;

procedure MakeCurrency;
 var I: Integer;
begin
  with CountryInfo do
   begin
     if (DecSign >= '0') and (DecSign <= '9') then I := Byte(DecSign[1])-48 else I := 2;
     Str(R:0:I, S);
     I := PosChar('.', S);
     if I = 0 then I := Length(S)
              else Move(DecSep[1], S[I], Length(DecSep));
     case CurrencyFmt of
       0: S := Currency + S;
       1: S := S + Currency;
       2: S := Currency + ' ' + S;
       3: S := S + ' ' + Currency;
       4: Insert(Currency, S, I);
     end;
   end;
end;

Procedure AddStr(var S ; C : char);assembler ;
   asm
        cld
        les Di,S
        inc ES:DI.byte
        mov al,ES:DI.byte
        sub ah,ah
        add DI,AX
        mov al,C
        Stosb
   end;

Procedure DelRight;assembler ;
   asm
        les Di,S
        mov bl,ES:DI.byte
        sub bh,bh
        or  BX,BX
        jz  @@3
    @@1:
        mov al, ES:[DI+BX]
        cmp al, ' '
        je  @@D
        cmp al, 9
        jne @@2
   @@D: dec BX
        jnz @@1
    @@2:
        mov ES:DI.byte,bl
    @@3:
   end;

procedure DelLeft(var S: string);
var
  I: Byte;
  SL: byte absolute S;
begin
  I := 1; while (SL>=I) and (S[I] in [#9,' ']) do Inc(I);
  if I>1 then
  begin
    Dec(SL, I-1);
    Move(S[I], S[1], SL);
  end;
end;

Procedure Sound ( Hz : word );assembler;
     asm
        mov     ax,Hz
        cmp     ax,21
        jbe     @@2
        mov     bx,ax
        in      al,061h
        test    al,03
        jnz     @@1
        or      al,03
        out     061h,al
        mov     al,0B6h
        out     043h,al
@@1:    mov     ax,04F38h  {  divider = 144f38h / Hz  }
        mov     dx,014h
        div     bx
        out     042h,al
        mov     al,ah
        out     042h,al
@@2:
    end;

 Procedure Nosound ;assembler;
     asm
        in      al,061h
        and     al,11111100b
        out     061h,al
     end;


  function FindParam(const S: string): Integer;
    var I: Integer;
  begin
     FindParam := 0;
     for I := 1 to ParamCount do
       if S = Copy(UpStrg(ParamStr(I)),1,Length(S)) then
         begin
           FindParam := I;
           Exit
         end;
     if S[1] = '/' then FindParam := FindParam('-'+Copy(S, 2, 255));
  end;

function GetEnv(S: string): string;
begin
  S := DOS.GetEnv(S); DelSpace(S);
  GetEnv := S;
end;

{
procedure ParseCMDStr(S: string; var F: Text; var LbNo: Integer;
                      const Fl1, Fl2: string );
  var I: Integer;
      Dr1, Dr2: DirStr;
      Nm1, Nm2: NameStr;
      Xt1, Xt2: ExtStr;
begin
  FSplit(Fl1, Dr1, Nm1, Xt1);
  FSplit(Fl2, Dr2, Nm2, Xt2);
  repeat
    I := Pos('||', S);
    if I = 0 then I := Length(S)+1;
    FreeStr := Copy(S, 1, I-1); Delete(S, I, 2);
    Replace('%%', #0, FreeStr);
    Replace('%11', Nm2+Xt2, FreeStr);
    Replace('%12', Dr2, FreeStr);
    Replace('%13', Nm2, FreeStr);
    Replace('%14', Xt2, FreeStr);
    Replace('%15', Copy(Dr2, 1, Length(Dr2)-Byte(Length(Dr2)>3)), FreeStr);
    Replace('%16', Copy(Dr2, 1, 2), FreeStr);
    Replace('%1', Nm1+Xt1, FreeStr);
    Replace('%2', Dr1, FreeStr);
    Replace('%3', Nm1, FreeStr);
    Replace('%4', Xt1, FreeStr);
    Replace('%5', Copy(Dr1, 1, Length(Dr1)-Byte(Length(Dr1)>3)), FreeStr);
    Replace('%6', Copy(Dr1, 1, 2), FreeStr);
    Replace(#0, '%', FreeStr);
    WriteLn(F, FreeStr);
  until (S = '') or (I=0);
end;
}

function MakeCMDParams(const S, Fl1, Fl2: string): string;
var
      Dr1, Dr2: DirStr;
      Nm1, Nm2: NameStr;
      Xt1, Xt2: ExtStr;
begin
  FreeStr := S;
  FSplit(Fl1, Dr1, Nm1, Xt1);
  FSplit(Fl2, Dr2, Nm2, Xt2);
  Replace('%%', #0, FreeStr);
  Replace('%11', Nm2+Xt2, FreeStr);
  Replace('%12', Dr2, FreeStr);
  Replace('%13', Nm2, FreeStr);
  Replace('%14', Xt2, FreeStr);
  Replace('%15', Copy(Dr2, 1, Length(Dr2)-Byte(Length(Dr2)>3)), FreeStr);
  Replace('%16', Copy(Dr2, 1, 2), FreeStr);
  Replace('%1', Nm1+Xt1, FreeStr);
  Replace('%2', Dr1, FreeStr);
  Replace('%3', Nm1, FreeStr);
  Replace('%4', Xt1, FreeStr);
  Replace('%5', Copy(Dr1, 1, Length(Dr1)-Byte(Length(Dr1)>3)), FreeStr);
  Replace('%6', Copy(Dr1, 1, 2), FreeStr);
  Replace(#0, '%', FreeStr);
  MakeCMDParams := FreeStr
end;

function Chk4Dos: Boolean; assembler;
  asm
    xor bh, bh
    mov ax, $D44D
    push bp
    int $2F
    pop  bp
    xor bx, bx
    cmp ax, $44DD
    jnz @1
    inc bl
 @1:
    mov ax, bx
  end;



function Get100s: LongInt;
  var DD,MM,YY, HH, Mn, Sc, Sc100: Word;
begin
  GetDate(YY,MM,DD,Sc100);
  GetTime(HH,Mn,Sc,Sc100);
  Get100s := Sc100+LongInt(Sc)*100+LongInt(Mn)*6000+
             LongInt(HH)*360000+LongInt(DD)*8640000;
end;

type
  TFileRec = record
    Handle: Word;
    Mode: Word;
    RecSize: Word;
    Private: array[1..26] of Byte;
    UserData: array[1..16] of Byte;
    Name: array[0..79] of Char;
  end;

function  FileNameOf(var F: file): string;
var
  S: string;
begin
  S := TFileRec(F).Name;
  S[0] := Char(Pos(#0, S)-1);
  FileNameOf := S;
end;

function MemAdjust(L: LongInt): LongInt;
begin
  if Linker <> nil then
  begin
    if L > CL_SafeBuf then L := L - CL_SafeBuf else L := 0;
  end;
  MemAdjust := L;
end;

function IsDriveCDROM(Drive : Char) : Boolean;
var
  R : Registers;
begin
  FillChar(R, SizeOf(R), 0);
  with R do begin
    AX := $150B;
    CX := Ord(Upcase(Drive))-Ord('A');
    Intr($2F, R);
    IsDriveCDRom := (AX <> 0) and (BX = $ADAD);
  end;
end;

function HotKey(const S: String): Char;
var
  P: Word;
begin
  P := Pos('~',S);
  if P <> 0 then HotKey := UpCaseArray[S[P+1]]
  else HotKey := #0;
end;


function  GetTmpId:LongInt;
var
        IdL,lm,ld,lh,lmin      : LongInt;
        y,m,d,dow,h,min,s,hund : Word;
begin
 GetDate(y,m,d,dow);
 GetTime(h,min,s,hund);
 lm:=m and 7;ld:=d;lh:=h;lmin:=min;
 GetTmpId:=       (lm    * 259200000 +
                   ld    * 8640000   +
                   lh    * 360000    +
                   lmin  * 6000      +
                   s     * 100       +
                   hund  + Random(4))+$DEADFACE;
end;

const
   LastTmpId : LongInt = -1;

function CalcTmpId:LongInt;
var Id:LongInt;
    s:string;
begin
 Id:=GetTmpId;
 if (LastTmpId<>-1) and (LastTmpId>=Id) then Id:=LastTmpId+1;
 LastTmpId:=Id;
 CalcTmpId:=Id;
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

function CalcTmpFName; begin CalcTmpFName:=MakeNormName(SwpDir,Hex8(Id)+'.'+AExt) end;

function MemOK: Boolean;
begin
  if (MemAdjust(System.MemAvail) < $8000) or (System.MaxAvail < $4000) then MemOK := False
    else MemOK := True;
end;


constructor TTextReader.Init;
var
  FileSz: LongInt;
  ToRead: Integer;
begin
  ClrIO; FileMode := $40; Assign(Handle, FName); Reset(Handle, 1);
  if (IOResult <> 0) or Abort then Fail;
  FileSz := FileSize(Handle);
  if (IOResult <> 0) or Abort then Fail;
  Eof := FileSz = 0;
  if not Eof then
  begin
    ToRead := Min(FileSz, TextReaderBufSize);
    BlockRead(Handle, Buf, ToRead, BufSz);
    if (IOResult <> 0) or Abort or (ToRead <> BufSz) then
    begin
      ClrIO; Close(Handle); ClrIO;
      Fail;
    end;
  end;
  BufPos := 0;
end;

function TTextReader.FileName: string;
begin
  FileName := FileNameOf(Handle);
end;

function TTextReader.GetStr: string;
var
  CurStr: string;
  CurLen: byte absolute CurStr;
  BufBeg: Integer;
  Was: Boolean;

procedure aStr(D: Integer);
var
  Grow: Integer;
begin
  Grow := Min((BufPos - BufBeg) - D - Byte(Was), 255-CurLen);
  if Grow > 0 then
  begin
    Move(Buf[BufBeg], CurStr[CurLen+1], Grow);
    Inc(CurLen, Grow);
  end;
end;

var
  PrevC: Integer;
  C: Char;

begin
 CurStr := ''; if not Eof then
 begin
  PrevC := -1;
  CurLen := 0; BufBeg := BufPos; Was := False;
  repeat
    if BufPos = BufSz then
    begin
      aStr(0);
      ClrIO; BlockRead(Handle, Buf, TextReaderBufSize, BufSz);
      if BufSz = 0 then
      begin
        Eof := True;
        Break;
      end;
      BufPos := 0;
      BufBeg := 0;
      if Was then begin Skip1 := True; Break end;
    end;
    C := Buf[BufPos]; Inc(BufPos);
    case C of
      #0, #10, #13 :
        begin
          if Skip1 then
          begin
            BufBeg := BufPos;
            Skip1 := False; Continue;
          end;
          if Was then
          begin
            aStr(1);
            Dec(BufPos, Integer(PrevC=Integer(C)));
            Break;
          end else Was := True;
          PrevC := Integer(C);
        end;
      else
      begin
        if Was then
        begin
          aStr(1);
          Dec(BufPos);
          Break;
        end;
        Skip1 := False
      end;
    end;
  until False;
 end;
 GetStr := CurStr;
end;


destructor TTextReader.Done;
begin
  ClrIO; Close(Handle); ClrIO;
end;

function  ExistFile(const FName : PathStr) : Boolean;
var DirInfo:SearchRec;
begin
 FindFirst(FName,Archive+ReadOnly+Hidden+SysFile,DirInfo);
 ExistFile:=DosError=0 ;
end;

function LngId: string; begin LngId := GetEnv('DNLNG') end;

procedure ResourceAccessError;
begin
  RunError(219);
end;

procedure DelFC(var s:string);
var
  sl: byte absolute s;
begin
  if sl>0 then begin Dec(sl); Move(s[2], s[1], sl) end;
end;

procedure LowPrec(var A, B: LongInt);
begin
  while (A > $FFFF) or (B > $FFFF) do
  begin
    A := A shr 2;
    B := B shr 2;
  end;
end;

function Percent(AMax, ACur: LongInt): LongInt;
begin
  LowPrec(AMax, ACur);
  if AMax = 0 then Percent := 0 else Percent := (ACur*100) div AMax;
end;

function StrGrd(AMax, ACur: LongInt; Wide: Byte): string;
var
  A: Byte;
begin
  LowPrec(AMax, ACur);
  if AMax = 0 then A := Wide else A := (ACur*Wide) div AMax;
  StrGrd := Copy(Strg(#219,A)+Strg(#177, Wide), 1, Wide);
end;

function FExpand (Path: PathStr): PathStr;
begin
  if Copy(Path, 1, 2) = '\\' then FExpand := Path else
                                  FExpand := DOS.FExpand(Path);
end;

BEGIN
 asm
  int 11h
  test al, 1
  jz  @@1
  mov cl, 6
  shr al, cl
  inc al
  mov NumFloppy, al
@@1:
 end;
 asm
    mov ax, $3800
    lea dx, DCountryInfo
    xor bx, bx
    int 21h
 end;
 UpcaseArray[#0] := #0;
 LowcaseArray[#0] := #0;
 Dos40 := Lo(DosVersion)>=4;
 OS210 := (Lo(DosVersion)>=20) and (GetEnv('OS2COMSPEC') <> '');
END.