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

Unit FmtUnit;

Interface

const
     DetectDrive : Boolean = True;
     SystemDisk  : Boolean = False;
     Uncondition : Boolean = False;
     Interleave  : Byte    = 1;
     TCylinders  : Byte    = 80;
     SecPerT     : Byte    = 15;
     CurDrive    : Byte    = 0;
     FormatMode  : Byte    = 0;
type
     PArrOfByte  = ^TArrOfByte;
     TArrOfByte  = array[0..65000] of byte;
     PParaType   = ^TParaType;
     TParaType   = array[0..10] of Byte;
     BPBType     = record
                    BPerSect   : Word;
                    ClustSize  : Byte;
                    ReservdSec : Word;
                    FATCount   : Byte;
                    RootSize   : Word;
                    TotalSec   : Word;
                    Media      : Byte;
                    FATSize    : Word;
                    SecPerTrk  : Word;
                    Heads      : Word;
                    HiddenSec  : LongInt;
                    Reserved   : array[0..9] of Byte;
                    Length     : Byte;
                   end;
     IOCTLPacket = record
                    SpecFunc   : Byte;
                    DeviceType : Byte;
                    DeviceAttr : Word;
                    NumOfCyl   : Word;
                    MediaType  : Byte;
                    DeviceBPB  : BPBType;
                   end;
     SecDescript = record
                    C,H,N,S    : Byte;
                   end;
     AllDescript = array[1..25] of SecDescript;

var  IOCTL               : IOCTLPacket;
     BadSp,SysSp,FreeSp  : Word;
     Cylinder,NumOfDrives,Side,
     MediaDescr,DriveType,
     SecPerFAT,SecPerCluster,
     RootEntries,IOError : Byte;
     SerialNo            : LongInt;
     SecDescr            : ^AllDescript;
     Old1E               : Pointer;
     dFAT                : PArrOfByte;
     VolumeLabel         : String[11];

     Procedure BOOTsector;
     Procedure GetIOCTL;
     Function  PrepareFormat : Boolean;
     Procedure EndFormat;
     Procedure ReadSector (SecNo : Word; var Buf);
     Procedure WriteSector(SecNo : Word; var Buf);
     Procedure FormatTrack;
     Procedure VerifyTrack;
     Function  Verify(SectNo : Byte) : Boolean;

Implementation
uses Dos;

const
     Para08   : TParaType =($DF,$02,$25,$02,08,$02,$FF,$58,$DA,$0F,$08);
     Para09   : TParaType =($DF,$02,$25,$02,09,$02,$FF,$50,$DA,$0F,$08);
     Para10   : TParaType =($DF,$02,$25,$02,10,$02,$FF,$2E,$DA,$0F,$08);
     Para11   : TParaType =($DF,$02,$25,$02,11,$02,$FF,$02,$DA,$0F,$08);
     Para15   : TParaType =($DF,$02,$25,$02,15,$02,$FF,$54,$DA,$0F,$08);
     Para17   : TParaType =($DF,$02,$25,$02,17,$02,$FF,$23,$DA,$0F,$08);
     Para18   : TParaType =($DF,$02,$25,$02,18,$02,$FF,$6C,$DA,$0F,$08);
     Para20   : TParaType =($DF,$02,$25,$02,20,$02,$FF,$2A,$DA,$0F,$08);
     Para21   : TParaType =($DF,$02,$25,$02,21,$02,$FF,$0C,$DA,$0F,$08);
     Para22   : TParaType =($DF,$02,$25,$02,22,$02,$FF,$01,$DA,$0F,$08);
var  DPB      : TParaType;

Procedure BOOTsector; assembler;
asm db 235, 60,144, 68, 78, 32, 49, 46, 48, 32, 32,  0,  2,  0,  1,  0
    db   2,  0,  0,  0,  0,  0,  0,  0,  0,  0,  2,  0,  0,  0,  0,  0
    db   0,  0,  0,  0,  0,  0, 41,  0,  0,  0,  0, 32, 32, 32, 32, 32
    db  32, 32, 32, 32, 32, 32, 70, 65, 84, 49, 50, 32, 32, 32,250, 51
    db 192,142,208,188,  0,124, 22,  7,187,120,  0, 54,197, 55, 30, 86
    db  22, 83,191, 62,124,185, 11,  0,252,243,164,  6, 31,198, 69,254
    db  15,139, 14, 24,124,136, 77,249,137, 71,  2,199,  7, 62,124,251
    db 205, 19,114,121, 51,192, 57,  6, 19,124,116,  8,139, 14, 19,124
    db 137, 14, 32,124,160, 16,124,247, 38, 22,124,  3,  6, 28,124, 19
    db  22, 30,124,  3,  6, 14,124,131,210,  0,163, 80,124,137, 22, 82
    db 124,163, 73,124,137, 22, 75,124,184, 32,  0,247, 38, 17,124,139
    db  30, 11,124,  3,195, 72,247,243,  1,  6, 73,124,131, 22, 75,124
    db   0,187,  0,  5,139, 22, 82,124,161, 80,124,232,146,  0,114, 29
    db 176,  1,232,172,  0,114, 22,139,251,185, 11,  0,190,230,125,243
    db 166,117, 10,141,127, 32,185, 11,  0,243,166,116, 24,190,158,125
    db 232, 95,  0, 51,192,205, 22, 94, 31,143,  4,143, 68,  2,205, 25
    db  88, 88, 88,235,232,139, 71, 26, 72, 72,138, 30, 13,124, 50,255
    db 247,227,  3,  6, 73,124, 19, 22, 75,124,187,  0,  7,185,  3,  0
    db  80, 82, 81,232, 58,  0,114,216,176,  1,232, 84,  0, 89, 90, 88
    db 114,187,  5,  1,  0,131,210,  0,  3, 30, 11,124,226,226,138, 46
    db  21,124,138, 22, 36,124,139, 30, 73,124,161, 75,124,234,  0,  0
    db 112,  0,172, 10,192,116, 41,180, 14,187,  7,  0,205, 16,235,242
    db  59, 22, 24,124,115, 25,247, 54, 24,124,254,194,136, 22, 79,124
    db  51,210,247, 54, 26,124,136, 22, 37,124,163, 77,124,248,195,249
    db 195,180,  2,139, 22, 77,124,177,  6,210,230, 10, 54, 79,124,139
    db 202,134,233,138, 22, 36,124,138, 54, 37,124,205, 19,195, 13, 10
    db  78,111,110, 45, 83,121,115,116,101,109, 32,100,105,115,107, 32
    db 111,114, 32,100,105,115,107, 32,101,114,114,111,114, 13, 10, 82
    db 101,112,108, 97, 99,101, 32, 97,110,100, 32,112,114,101,115,115
    db  32, 97,110,121, 32,107,101,121, 32,119,104,101,110, 32,114,101
    db  97,100,121, 13, 10,  0, 73, 79, 32, 32, 32, 32, 32, 32, 83, 89
    db  83, 77, 83, 68, 79, 83, 32, 32, 32, 83, 89, 83,  0,  0, 85,170
end;

Procedure GetIOCTL; assembler;
asm     mov  ax,$440D
        mov  cx,$0860
        mov  bl,CurDrive
        inc  bl
        mov  bh,0
        lea  dx,IOCTL
        mov  byte ptr IOCTL,0
        mov  IOCTL.SpecFunc,0
        int  $21
        jnc  @Exit
        mov  IOError,al
@Exit:
end;

Procedure CheckDStep; assembler;
asm     push ax
        xor  ax,ax
        mov  es,ax
        mov  al,CurDrive
        mov  ah,0
        mov  si,ax
        or   byte ptr es:[490h+si],$10
        cmp  DriveType,1
        je   @Check
        cmp  DriveType,7
        jne  @Exit
@Check: cmp  TCylinders,43
        ja   @Reset
@Set:   or   byte ptr es:[490h+si],$20
        jmp  @Exit
@Reset: and  byte ptr es:[490h+si],not $20
@Exit:  pop  ax
end;

Procedure ReadSector; assembler;
asm     mov  ax,SecNo
        div  byte ptr SecPerT
        mov  dh,0
        shr  al,1
        jnc  @NoChg
        inc  dh
@NoChg: mov  cl,ah
        inc  cl
        mov  ch,al
        call CheckDStep
        mov  dl,CurDrive
        mov  ax,$0201
        les  bx,Buf
        int  $13
        jc   @Exit
        xor  ah,ah
@Exit:  mov  IOError,ah
end;

Procedure WriteSector; assembler;
asm     mov  ax,SecNo
        div  byte ptr SecPerT
        mov  dh,0
        shr  al,1
        jnc  @NoChg
        inc  dh
@NoChg: mov  cl,ah
        inc  cl
        mov  ch,al
        call CheckDStep
        mov  dl,CurDrive
        mov  ax,$0301
        les  bx,Buf
        int  $13
        jc   @Exit
        xor  ah,ah
@Exit:  mov  IOError,ah
end;

Procedure SetDrive(MediaByte,Parm : Byte);
begin
 asm mov ah,17;mov dl,CurDrive;mov al,Parm; int $13;end;
 mem[0:$490+CurDrive]:=MediaByte;
end;

Function PrepareFormat : Boolean;
label BadPar;
var i,j,k : Byte;
    p     : PArrOfByte;
    w1,w2 : Byte;
begin
 PrepareFormat:=False;IOError:=0;SecDescr:=NIL;
 SecPerCluster:=1+Byte(TCylinders<44);
 GetIOCTL;DriveType:=IOCTL.DeviceType;
 if FormatMode=2 then
    begin
     SetIntVec($1E, Old1E); GetMem(p,512); FillChar(p^,512,1);
     ReadSector(SecPerT*2,p^); ReadSector(0,p^);
     w1:=SecPerT;w2:=TCylinders;
     if IOError=0 then
        begin
         SecPerT:=p^[$18];SecPerCluster:=p^[$0D];
         TCylinders:=(p^[$13] or Word(p^[$14]) shl 8) div p^[$1A] div SecPerT;
         SecPerFAT:=(((TCylinders*SecPerT*2 div SecPerCluster)*3 div 2)+511) div 512;
        end;
     if (IOError>0) or ((p^[$B] or Word(p^[$C]) shl 8)<>$200)
        or (p^[$10]<>2) or (p^[$1A]<>2) or ((p^[$16]
        or Word(p^[$17]) shl 8)<>SecPerFAT) or (p^[$E]<>1) or
        (TCylinders>85) then begin
                              SecPerT:=w1;TCylinders:=w2;
                              FreeMem(p,512);Exit;
                             end;
     FreeMem(p,512);
    end;
 if DetectDrive and (TCylinders>43) then
    if (IOCTL.DeviceType=0) or (TCylinders>85) then Exit;
 if (Interleave>=SecPerT) or (Interleave=0) then Exit;
 PrepareFormat:=True;
 New(SecDescr);j:=1;
 SecPerFAT:=(((TCylinders*SecPerT*2 div SecPerCluster)*3 div 2)+511) div 512;
 FillChar(SecDescr^,SizeOf(SecDescr^),0);
 for i:=1 to SecPerT do
     begin
      While (SecDescr^[j].N<>0) or (j>SecPerT) do
            begin Inc(j);if j>SecPerT then j:=1;end;
      SecDescr^[j].N:=i; SecDescr^[i].S:=2;
      Inc(j,Interleave);
     end;
 DPB[0]:=0;
 case SecPerT of
  8      : DPB:=Para08;
  9      : DPB:=Para09;
  10     : DPB:=Para10;
  11     : if DriveType<>7 then Goto BadPar else DPB:=Para11;
  12..16 : DPB:=Para15;
  17     : DPB:=Para17;
  18,19  : case IOCTL.DeviceType of
            1 : begin PrepareFormat:=False;EndFormat;Exit;end;
            7 : DPB:=Para18;
           end;
  20     : if DriveType<>7 then Goto BadPar else DPB:=Para20;
  21     : if DriveType<>7 then Goto BadPar else DPB:=Para21;
  22     : if DriveType<>7 then Goto BadPar else DPB:=Para22;
  else begin
BadPar: PrepareFormat:=False;EndFormat;Exit;
       end;
 end;
 if DPB[0]<>0 then SetIntVec($1E, @DPB);
 case SecPerT of
  8  : MediaDescr:=$FF;
  9  : MediaDescr:=$FD;
  15 : MediaDescr:=$F9;
  else MediaDescr:=$F0;
 end;
 if TCylinders>43 then RootEntries:=224 else RootEntries:=112;
 case DriveType of
   0: SetDrive($53,1);
   1: if (TCylinders>43) and (SecPerT>11)
         then SetDrive($15,3)
         else if (TCylinders>43) and (SecPerT<12)
                 then SetDrive($53,5)
                 else if SecPerT<12
                         then SetDrive($73,2)
                         else SetDrive($34,2);
   2: if (TCylinders>43)
         then SetDrive($97,4)
         else SetDrive($B7,2);
   7: if (TCylinders>43) and (SecPerT>11)
         then SetDrive($14,3)
         else if (TCylinders>43) and (SecPerT<12)
                 then SetDrive($97,5)
                 else if SecPerT<12
                         then SetDrive($B7,2)
                         else SetDrive($34,3);
 end;
 asm mov  ah,0; mov dl,CurDrive; int $13;end;
 if FormatMode=2 then Exit;FormatMode:=0;
 if Uncondition then Exit;
 Side:=1;Cylinder:=TCylinders-3 or 1;VerifyTrack;
 Side:=0;Cylinder:=0;if IOError<>0 then Exit;
 VerifyTrack;if IOError<>0 then Exit;
 Inc(SecPerT);VerifyTrack;Dec(SecPerT);
 if IOError<>0 then FormatMode:=1;
end;

Procedure EndFormat;
begin
 if SecDescr<>NIL then Dispose(SecDescr);
 SetIntVec($1E, Old1E); SecDescr:=NIL;
 asm mov ah, 0h;
     mov dl, CurDrive;
     int 13h
     mov ah, 17h
     mov al, 0
     mov dl, CurDrive
     int 13h
 end;
end;

Procedure FormatTrack; assembler;
asm      call CheckDStep
         mov  cx,22
         les  di,SecDescr
         mov  al,Cylinder
         mov  ah,Side
         cld
@NextSec:stosw
         add  di,2
         loop @NextSec
         xor  ax,ax
         mov  es,ax
         les  bx,es:[$78]
         mov  al,SecPerT
         mov  byte ptr es:[bx+4],al
         mov  ah,5
         mov  dl,CurDrive
         mov  dh,Side
         mov  ch,Cylinder
         les  bx,SecDescr
         int  $13
         jc   @Exit
         xor  ah,ah
 @Exit:  mov  IOError,ah
end;

Function Verify; assembler;
asm      call CheckDStep
         mov  ax,$0401
         mov  dl,CurDrive
         mov  dh,Side
         mov  ch,Cylinder
         mov  cl,SectNo
         int  $13
         mov  al,0
         jnc  @Ex
         inc  al
@Ex:
end;

Procedure VerifyTrack; assembler;
asm      call CheckDStep
         mov  ah,4
         mov  al,SecPerT
         mov  dl,CurDrive
         mov  dh,Side
         mov  ch,Cylinder
         mov  cl,1
         int  $13
         jc   @Ex
         mov  ah,0
@Ex:     mov  IOError,ah
end;

begin
 if mem[$40:$10] and 1>0 then NumOfDrives:=mem[$40:$10] shr 6+1
                         else NumOfDrives:=0;
 GetIntVec($1E, Old1E); VolumeLabel:='';
end.

