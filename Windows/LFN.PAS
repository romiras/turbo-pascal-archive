{*************************************************************}
{*                   Unit LFN v1.0                           *}
{*     Long filename support in Windows Dos session          *}
{*************************************************************}

unit lfn;
{$N-}
interface
uses {Win}dos,Strings;

var DosError: integer;
const
  faReadOnly      =  ReadOnly;
  faHidden        =  Hidden;
  faSysFile       =  SysFile;
  faVolumeID      =  VolumeID;
  faDirectory     =  Directory;
  faArchive       =  Archive;
  faAnyFile       =  AnyFile;

type
    TDateTime = DateTime;{}

  PLFNSearchRec = ^TLFNSearchRec;
  TLFNSearchRec = record
    Attr         : longint;
    Creation     : comp;
    LastAccess   : comp;
    LastMod      : comp;
    HighFileSize : longint; { high 32 bits }
    Size         : longint; { low 32 bits  }
    Reserved     : comp;
    Name         : array[0..259] of char;
    ShortName    : array[0..13] of char;
    Handle       : word;
  end;

function SupportsLFN: boolean;

function LFindFirst(FileSpec:pchar; Attr:word; var SRec:TLFNSearchRec):word;
{ Search for files }
function LFindNext(var SRec:TLFNSearchRec):word;
{ Find next file }
function LFindClose(var SRec:TLFNSearchRec):word;
{ Free search handle }
function LTruename(FileName:pchar; Result:pchar):word;
{ Return complete path, if relative uppercased longnames added, }
{ in buffer Result (261 bytes) }
function LGetShortName(FileName:pchar; Result:pchar):word;
{ Return complete short name/path for input file/path in buffer }
{ Result (79 bytes) }
function LGetLongName(FileName:pchar; Result:pchar):word;
{ Return complete long name/path for input file/path in buffer }
{ Result (261 bytes) }
function LFileSystemInfo(RootName:pchar; FSName:pchar; FSNameBufSize:word;
 var Flags,MaxFileNameLen,MaxPathLen:word):word;
{ Return File System Information, for FSName 32 bytes should be sufficient }
{ Rootname is for example 'C:\' }
{ Flags: }
{ bit
{  0   searches are case sensitive }
{  1   preserves case in directory entries }
{  2   uses Unicode characters in file and directory names }
{ 3-13 reserved (0) }
{ 14   supports DOS long filename functions }
{ 15   volume is compressed }

function  LCreateEmpty(fname: PChar): word;

function LRenameFile(OldFilename,NewFilename:pchar):word;

function LEraseFile(Filename:pchar):word;

function LMkDir(Directory:pchar):word;

function LRmDir(Directory:pchar):word;
{ Remove directory }
function LChDir(Directory:pchar):word;

function LGetDir(Drive:byte; Result:pchar):word;
{ Get current drive and directory. Drive: 0=current, 1=A: etc. }
function LGetAttr(Filename:pchar; var Attr:word):word;
{ Get file attributes}
function LSetAttr(Filename:pchar; Attr:word):word;
{ Set file attributes }
function LTimeToDos(var LTime:comp):longint;
{ Convert 64-bit number of 100ns since 01-01-1601 UTC to local DOS format time}
{ (LTime is var to avoid putting it on the stack) }
function DosToLTime(var Time: longint; var LTime: comp): word;
procedure UnpackLTime(var LTime:comp; var DT:TDateTime);
{ Convert 64-bit time to date/time record }
Function LFileExist(FName:PChar):boolean;
{ LongFileName file exists check }
Function LDirExist(DirName:PChar):boolean;
{ LongFileName directory exists check}

implementation

function SupportsLFN: boolean; assembler;
asm
  mov ax, $160a
  int $2f
  cmp ax, 0
  jne @no         { Not running under Windows   }
  cmp bh, 2
  jle @no         { Major version <3            }
  cmp bh, 4
  jge @yes        { Major version >3            }
  cmp bl, 94
  jle @no         { Major version =3, minor <95 }
@yes:
  mov al, true
  jmp @exit
@no:
  mov al, false
@exit:
end;                 { SupportsLFN }

function LFindFirst(FileSpec:pchar; Attr:word; var SRec:TLFNSearchRec):word;
assembler;
{ Search for files }
asm
 push ds
 lds dx,FileSpec
 les di,SRec
 mov cx,Attr
 xor si,si
 mov ax,714eh
 int 21h
 pop ds
 sbb bx,bx
 mov es:[di].TLFNSearchRec.Handle,ax
 and ax,bx
 mov [DosError],ax
end;

function LFindNext(var SRec:TLFNSearchRec):word; assembler;
{ Find next file }
asm
 mov ax,714fh
 xor si,si
 les di,SRec
 mov bx,es:[di].TLFNSearchRec.Handle
 int 21h
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LFindClose(var SRec:TLFNSearchRec):word; assembler;
{ Free search handle }
asm
 mov ax,714fh
 mov bx,es:[di].TLFNSearchRec.Handle
 int 21h
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LTrueName(FileName:pchar; Result:pchar):word; assembler;
{ Return complete path, if relative uppercased longnames added, }
{ in buffer Result (261 bytes) }
asm
 push ds
 mov ax,7160h
 xor cx,cx
 lds si,FileName
 les di,Result
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LGetShortName(FileName:pchar; Result:pchar):word; assembler;
{ Return complete short name/path for input file/path in buffer }
{ Result (79 bytes) }
asm
 push ds
 lds si,FileName
 les di,Result
 mov ax,7160h
 mov cx,1
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;


function LGetLongName(FileName:pchar; Result:pchar):word; assembler;
{ Return complete long name/path for input file/path in buffer }
{ Result (261 bytes) }
asm
 push ds
 lds si,FileName
 les di,Result
 mov ax,7160h
 mov cx,2
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LFileSystemInfo(RootName:pchar; FSName:pchar; FSNameBufSize:word;
 var Flags,MaxFileNameLen,MaxPathLen:word):word; assembler;
{ Return File System Information, for FSName 32 bytes should be sufficient }
asm
 push ds
 lds dx,RootName
 les di,FSName
 mov cx,FSNameBufSize
 mov ax,71a0h
 int 21h
 pop ds
 les di,Flags
 mov es:[di],bx
 les di,MaxFileNameLen
 mov es:[di],cx
 les di,MaxPathLen
 mov es:[di],dx
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LTimeToDos(var LTime:comp):longint; assembler;
{ Convert 64-bit number of 100ns since 01-01-1601 UTC to local DOS format time
}{ (LTime is var to avoid putting it on the stack) }
asm
 push ds
 lds si,LTime
 xor bl,bl
 mov ax,71a7h
 int 21h
 pop ds
 mov ax,cx
 cmc
 sbb cx,cx
 and ax,cx
 and dx,cx
end;

function DosToLTime(var Time: longint; var LTime: comp): word;
{ Convert DOS time to the 64-bit Win95 format }
var
  DosTime,DosDate: word;
  DT: TDateTime;
begin
  UnpackTime(Time,DT); FillChar(LTime,sizeof(LTime),0);
  with DT do
  begin
    DosTime:=(sec div 2) or (min shl 5) or (hour shl 11);
    DosDate:=day or (Month shl 5) or ((Year-1980) shl 9);
  end;
  asm
    mov ax, $71A7
    mov bl, 1
    mov cx, DosTime
    mov dx, DosDate
    mov bh, 0
    les di, LTime
    int $21
    jnc @1
    mov [DosError],ax
@1:
  end;
  DosToLTime:=DosError;
end;

procedure UnpackLTime(var LTime:comp; var DT:TDateTime);
{ Convert 64-bit time to date/time record }
begin
 UnpackTime(LTimeToDos(LTime),DT);
end;

function RedirList(Drive: PChar; Result: PChar; Ind: word): word; assembler;
asm
  push ds
  lds si,Drive
  les di,Result
  mov ax,5f02h
  mov bx,Ind
  mov cx,'NW'
  int 21h
  jc @1
  mov ax,0
@1:
  pop ds
  mov [DosError],ax
end;                 { RedirList }

function LMkDir(Directory:pchar):word; assembler;
asm
 push ds
 lds dx,Directory
 mov ax,7139h
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LRmDir(Directory:pchar):word; assembler;
asm
 push ds
 lds dx,Directory
 mov ax,713ah
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LChDir(Directory:pchar):word; assembler;
asm
 push ds
 lds dx,Directory
 mov ax,713bh
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LGetAttr(Filename:pchar; var Attr:word):word; assembler;
asm
 push ds
 lds dx,Filename
 mov ax,7143h
 xor bl,bl
 int 21h
 pop ds
 les di,Attr
 mov es:[di],cx
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LSetAttr(Filename:pchar; Attr:word):word; assembler;
asm
 push ds
 lds dx,Filename
 mov ax,7143h
 mov bl,1
 mov cx,Attr
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LGetDir(Drive:byte; Result:pchar):word; assembler;
asm
 cld
 les di,Result
 mov al,Drive
 mov dl,al
 dec al
 jns @GotDrive
 mov ah,19h
 int 21h
@GotDrive:
 add al,41h
 mov ah,':'
 stosw
 mov ax,'\'
 stosw
 push ds
 push es
 pop ds
 mov si,di
 dec si
 mov ax,7147h
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LCreateEmpty(fname: PChar): word; assembler;
{ Create an empty file with the given (long) name. }
asm
  push ds
  mov ax, $716C
  mov bx, 000010b     { Open long file name for writing }
  mov cx, 0
  mov dx, 10001b      { Open if exists, create of not.  }
  lds si, fname
  mov di, 0
  int $21
  jc @1               { error creating file }
  mov bx, ax          { ok, close it again  }
  mov ah, $3E
  int $21
  jc @1               { error closing file }
  mov ax, 0           { ok, return zero    }
@1:
  pop ds
  mov [DosError],ax
end;                { LCreateEmpty }

function LEraseFile(Filename:pchar):word; assembler;
asm
 push ds
 lds dx,Filename
 mov ax,7141h
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

function LRenameFile(OldFilename,NewFilename:pchar):word; assembler;
asm
 push ds
 lds dx,OldFilename
 les di,NewFilename
 mov ax,7156h
 int 21h
 pop ds
 sbb bx,bx
 and ax,bx
 mov [DosError],ax
end;

Function LFileExist(FName: PChar): boolean;
var Sr:TLFNSearchRec;
begin
 lFindFirst(FName,faAnyFile-faVolumeID-faDirectory,Sr);
 lFileExist:=(DosError=0);
 lFindClose(Sr);
end;

Function LDirExist(DirName: PChar): boolean;
var Sr:TLFNSearchRec;
begin
  lFindFirst(DirName,faDirectory,Sr);
  lDirExist:=(DosError=0);
  lFindClose(Sr);
end;

end.