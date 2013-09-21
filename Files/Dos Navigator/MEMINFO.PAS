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

UNIT MemInfo;

{$F+,A+}

INTERFACE

USES
  Startup;

CONST
    cmMemInfo = 100;

    PROCEDURE MemoryInfo;
    PROCEDURE SystemInfo;

IMPLEMENTATION

USES
  Dos,
  Objects,
  Views,
  DNApp,
  Drivers,
  Commands,
  RStrings,
  Messages,
  Dialogs,
  ExtraMemory,
  DNHelp,
  Advance;

type
    PTextColl    = ^TTextColl;
    TTextColl    = object(TCollection)
                    Procedure   AddStr(s : String);
                    Procedure   FreeItem(Item : Pointer);        virtual;
                   end;

Procedure TTextColl.AddStr;
begin Insert(NewStr(s)); end;

Procedure TTextColl.FreeItem;
begin DisposeStr(Item); end;


var TSR : PTextColl;

Procedure AddTSRs; far;
var CurMCB,DevMCB,i,j : Word;
    s,s1              : String;
    LastMCB           : Boolean;
    isUMB             : Boolean;
    HiDosMem          : Word;

function aaa: string;
begin
  aaa := s+Strg(' ',9-Length(s))+'³ ';
end;

begin
 asm mov ah,52h
     int $21
     mov ax,es:[bx-2]
     mov CurMCB,ax
     int 12h
     mov cl,6
     shl ax,cl
     mov word ptr HiDosMem,ax
 end;
 isUMB := ExistUMBMem;
 j:=mem[CurMCB:3];DevMCB:=CurMCB+1;
 While DevMCB<CurMCB+memw[CurMCB:3]+1 do
       begin
        j:=memw[DevMCB:3];
        if j<$18C0 then s1:=Sstr(LongInt(j)*16,6,' ')+'b'
                   else s1:=Sstr(LongInt(j) div 64,6,' ')+'k';
        s:='Sys area';
        case char(mem[DevMCB:0]) of
         'T','D'
             : begin
                s:='';i:=8;
                While (i<16) and (mem[DevMCB:i]<>0) do
                      begin s:=s+Char(mem[DevMCB:i]);Inc(i);end;
                s:=aaa;
                if char(mem[DevMCB:0])='T'
                   then s:=s+'Install'
                   else s:=s+'Driver ';
               end;
         'F' : s:=aaa+'Files  ';
         'B' : s:=aaa+'Buffers';
         'X' : s:=aaa+'FCBs   ';
         'L' : s:=aaa+'LastDrv';
         'S' : s:=aaa+'Stacks ';
         'I' : s:=aaa+'IFS    ';
         'E' : s:=aaa+'Buffs/X';
         else s:='';
        end;
        if s<>'' then TSR^.AddStr(s+' ³ '+Hex4(DevMCB+1)+' ³'+s1+
                      ' '+Char(DevMCB)+Char(DevMCB shr 8));
        DevMCB:=(DevMCB+1+memw[DevMCB:3]);
       end;
 LastMCB:=False;
 While (not LastMCB) and (CurMCB<$FF00) do begin
   if (memw[CurMCB+1:0]=$20CD) and (memw[CurMCB:1]<>0) then begin
     s:='';i:=8;
     While (i<16) and (mem[CurMCB:i]<>0) do begin
       s:=s+Char(mem[CurMCB:i]);
       Inc(i);
     end;
     j:=memw[CurMCB:3];
     if j<$18C0
       then s1:=Sstr(LongInt(j)*16,6,' ')+'b'
       else s1:=Sstr(LongInt(j) div 64,6,' ')+'k';
     s:=aaa+'Program ³ '+Hex4(CurMCB+1)+' ³'+s1;
     TSR^.AddStr(s+' '+Char(CurMCB)+Char(CurMCB shr 8));
   end;
   {
     Exit if:
       MCB = HiDosMem
       ( MCB > HiDosMem or MCB = 'Z' ) and no UMB
       ( MCB = 'Z' and MCB > HiDosMem )
       MCB >= 0xFF00
   }
   LastMCB := ( CurMCB = HiDosMem ) or
              (( CurMCB > HiDosMem ) or ( Char(mem[CurMCB:0])='Z' )) and not isUMB or
              (( CurMCB > HiDosMem ) and ( Char(mem[CurMCB:0])='Z' ));
   CurMCB:=(CurMCB+1+memw[CurMCB:3]);
 end;
end;

Procedure ShowInfo(Segm : Word); far;
label Unkn,BadCmdL;
var i,j,k : Word;
    s,q,w : String;
    l,b,e : LongInt;
begin
 s:='';
 case Char(mem[Segm:0]) of
  'F','B','X','L',
  'S','I','E' : begin
                 s:= GetString(dlMI_ResArea);
                 case Char(mem[Segm:0]) of
                  'F' : s:=s+GetString(dlMI_Files);
                  'B' : s:=s+GetString(dlMI_Buffers);
                  'X' : s:=s+GetString(dlMI_FCBs);
                  'L' : s:=s+GetString(dlMI_Drives);
                  'S' : s:=s+GetString(dlMI_Stacks);
                  'I' : s:=s+GetString(dlMI_IFS);
                  'E' : s:=s+GetString(dlMI_XBuffers);
                 end;
                end;
  'D'         : begin
                 s:=GetString(dlMI_DeviceFlags)+Hex4(memw[Segm:$14])+#13#3;
                 if memw[Segm:$14] and $8000>0
                    then begin
                          s:=s+GetString(dlMI_DeviceName);
                          for i:=0 to 7 do s:=s+char(mem[Segm:$1A+i]);
                          While s[Byte(s[0])]<#33 do Dec(Byte(s[0]));
                         end
                    else s:=s+GetString(dlMI_DeviceHandle1)+SStr(mem[Segm:$1A],0,' ')+GetString(dlMI_DeviceHandle2);
                end;
  'T','M','Z' : begin
                 q:='';i:=8;
                 While (i<16) and (mem[Segm:i]<>0) do
                       begin q:=q+Char(mem[Segm:i]);Inc(i);end;
                 i:=memw[Segm:$3C];
                 w:=GetString(dlMI_PgmPath);
                 if i<>0
                    then begin
                          s:='';j:=0;
                          While ((mem[i:j]<>0) or (mem[i:j+1]<>0))
                                and (j<$8000) do Inc(j);
                          Inc(j,4);
                          While mem[i:j]<>0 do
                                begin s:=s+Char(mem[i:j]);Inc(j);end;
                          If Pos(q,s)=0 then GoTo Unkn;
                          s:=w+s;
                         end
                    else Unkn: s:=w+GetString(dlUnknown);
                 s:=s+GetString(dlMI_CmdLine);
                 i:=mem[Segm:$90];
                 if i<$80
                    then begin
                          if i=0 then s:=s+GetString(dlDINone)
                                 else begin
                                       q:='"';
                                       For i:=$91 to $90+i do
                                           if (mem[Segm:i]>31)
                                              then q:=q+char(mem[Segm:i])
                                              else GoTo BadCmdL;
                                       s:=s+q+'"';
                                      end;
                         end
                    else BadCmdL: s:=s+GetString(dlUnknown);
                end;
 end;
 case Char(mem[Segm:0]) of
  'M','Z','T','D' : begin
                     s:=s+GetString(dlHookVectors);
                     q:='';
                     for i:=0 to $FF do
                         begin
                          j:=memw[0:i*4];
                          k:=memw[0:i*4+2];
                          l:=LongInt(k)*16+j;
                          b:=LongInt(Segm)*16;
                          e:=b+LongInt(memw[Segm:3])*16+16;
                          if (l>=b) and (l<=e) then q:=q+Hex2(i)+',';
                         end;
                     if q<>''
                        then begin
                              Dec(Byte(q[0]));
                              s:=s+q
                             end
                        else s:=s+GetString(dlDINone);
                    end;
 end;
 if s<>'' then MessageBox(s,NIL,mfOkButton or mfInformation);
end;

Procedure MemoryInfo;
var
  R        : TRect;
  PD       : PDialog;
  i,j      : Integer;
  VS       : PScrollBar;
  ListData : TListBoxRec;
  TSRlist  : PListBox;
  w        : Word;
  Ps       : PString;

begin
 R.Assign(0,0,52,14);
 New(PD,Init(R,GetString(dlMemoryInfo)));
 PD^.Options := PD^.Options or ofCentered;
 PD^.HelpCtx := hcMemoryInfo;

 R.Assign(38,2,39,12);
 New(VS,Init(R));
 PD^.Insert(VS);
 R.Assign(2,2,38,12);
 New(TSRlist,Init(R,1,VS));
 New(TSR,Init(8,8));
 AddTSRs;
 ListData.Focus:=0;
 ListData.List:=TSR;
 TSRlist^.SetData(ListData);
 PD^.Insert(TSRlist);
 R.Assign(2,1,31,2);
 PD^.Insert(New(PLabel,Init(R, GetString(dlTSRTitle),TSRlist)));

 R.Assign(40,2,50,4);
 PD^.Insert(New(PButton, Init(R, GetString(dlDetailButton), cmOK, bfDefault)));
 Inc(R.A.Y,2);Inc(R.B.Y,2);
 PD^.Insert(New(PButton, Init(R, GetString(dlOKButton), cmCancel, bfNormal)));
 PD^.SelectNext(False);
 repeat
  w:=DeskTop^.ExecView(PD);
  if w<>cmCancel then
     begin
      TSRlist^.GetData(ListData);
      PS:=TSR^.At(ListData.Focus);
      ShowInfo(memw[Seg(PS^[36]):Ofs(PS^[36])]);
     end;
 until (w=cmCancel);
 Dispose(TSR,Done);
 Dispose(PD,Done);
end;


Type TCPUinfo = record
                 cpu_type : byte;
                 MSW      : word;
                 GDT      : array[1..6] of byte;
                 IDT      : array[1..6] of byte;
                 chkint   : boolean;
                 opsize   : boolean;
                 mult     : boolean;
                 ndp_type : byte;
                 ndp_cw   : word
                end;

 Var CPUtype : byte ;
     PCmodel,PCsubModel : byte ;


Function Speed : LongInt;
var a,w,qq : Word;
begin
 Port[$43]:=$36;Port[$40]:=$0;Port[$40]:=$0;
 w:=memw[0:$46C];While w=memw[0:$46C] do ;
 w:=memw[0:$46C];a:=0; qq := 0;
 while w=memw[0:$46C] do
       asm   mul cx
             mov ax,ds
             mov bx,ax
             xor dx,dx
             div bx
             inc a
             jnz @1
             inc qq
           @1:
       end;
 Speed:=LongInt(a)+LongInt(qq)*65536;
end;

function _Processors: Word; far; external;
{$L CPUType}

Procedure GetCPUinfo(var Name, CoProc: String);
var s: String;
    i,y: Word;
begin
 {FillChar(CPUnfo,SizeOf(CPUnfo),0);}
 I := _Processors and $FF7F;

 CPUtype := I and $7F ;

if I and $7F >= 6 then
 begin
 asm
    db 0Fh,1,0E0h { SMSW AX }
    test al,1
    jz  @@1
    or I.byte ,80h
 @@1:
 end;
  end;

 case I and $7F of
   00 : s:='8086';
   01 : s:='8088';
   02 : s:='NEC V20';
   03 : s:='NEC V30';
   04 : s:='80186';
   05 : s:='80188';
   06 : s:='80286';
   07 : s:='80386';
   08 : s:='80386SX';
   09 : s:='80386DX';
   10 : s:='80486';
   11 : s:='80486SX';
   12 : s:='Pentium(tm)';
   13 : s:='Sixtium???';
   else s:='Unknown';
 end;

 if I and $80 <> 0 then S := S + ', V86 mode';
 Name := S;

 case I shr 8 of
  $00 : S := GetString(dlSI_None);
  $01 : S := '8087';
  $02 : S := '80287';
  $03 : S := '80287XL';
  $04 : S := '80387';
  $05 : S := '80387SX';
  $06 : S := '80387DX';
  { $FF : S := 'Weitek';}
  else  S := 'Unknown';
 end;
 if (I and $F >= 10) then S := GetString(dlSI_BuiltIn);
 asm
  int 11H
  mov i, ax
 end;
 {if i and 2 = 0 then S := 'None' else S := 'Installed'};
 CoProc := S;
end;

Function _MHz   : Word; far; external;
{Function _Speed : Word; far; external;}
{$L _MHZ.OBJ}

function GetSpeed(var S: String): LongInt;
 var W: LongInt;
     A: Real;
begin
 A := _MHz;
 A := A/100;
 Str((A):6:2, S);
 w := Speed;
 W := Trunc(w / 5.5);
 GetSpeed := W;
end;

type PModel = ^TModel;
     TModel = record
      Len: Word;
      Model: Byte;
      SubModel: Byte;
      BIOSRevision: Byte;
     end;

procedure GetMType(var S: String);
 var Model, SubModel: Byte;
     P: PModel;
begin
 asm
  mov ah, $C0
  int 15h
  mov word ptr P, bx
  mov word ptr P+2, es
 end;
 Model := P^.Model;
 if P^.Model = 0 then Model := mem[$F000:$FFFE];
 SubModel := P^.SubModel;

 PCModel    := P^.Model ;
 PCSubModel := P^.SubModel ;

 case Model of
  $FF: S := 'Original IBM PC';
  $FE: S := 'IBM XT or Portable PC';
  $FD: S := 'PC junior';
  $FC: case SubModel of
       { 1: S := 'IBM AT 3x9';}
        2: S := 'IBM XT 286';
        4: S := 'IBM Personal System/2 Model 50';
        5: S := 'IBM Personal System/2 Model 60';
        6: S := 'IBM 7552-XXX "Gearbox"';
        8: S := 'IBM Personal System/2 Model 25';
      $0b: S := 'IBM Personal System/1';
      $20: S := 'Compaq ProLinea';
      $42: S := 'Olivetti M280';
      $45: S := 'Olivetti M380';
      $48: S := 'Olivetti M290';
      $4F: S := 'Olivetti M250';
      $50: S := 'Olivetti M380';
      $51: S := 'Olivetti PCS286';
      $52: S := 'Olivetti M300';
      $94: S := 'Zenith 386';
        else S := 'IBM AT or compatible';
       end;
  $FB,$86: S := 'IBM XT';
  $80: S := 'IBM PC';
  $FA: if SubModel = 1 then S := 'IBM Personal System/2 Model 25'
                       else S := 'IBM Personal System/2 Model 30';
  $F9: S := 'PC Convertible';
  $F8: if SubModel in [4,9,$B]
                            then S := 'IBM Personal System/2 Model 70'
                            else S := 'IBM Personal System/2 Model 80+';
  $B6: S := 'Hewlett Packard 110';
  $9A: S := 'Compaq Plus';
  $2D: S := 'Compaq PC';
  $E1: S := 'PS/2 Model 55-5530 Laptop';
  $30: S := 'Sperry PC';
  else S := 'Unknown machine type. Report to RIT';
 end;
end;


 Function GetBusType:String;
 var  S : String  ;
      Ft1,Ft2,Ft3 : byte ;
      OK : boolean ;
      PCMCIA : boolean ;
      EISA   : boolean ;
      SCSI   : boolean ;
      APM    : boolean ;
   {
      VESA   : boolean ; VESAFLAG : byte ;
      PID    : PString ;
      BB     : array [0..1023] of byte ;
   }
   begin
        S := 'ISA/XT/Classic bus' ;
        GetBusType := S ;
        if CPUtype < 6 then Exit  ;
        if CPUtype = 6 then
             begin
               if PCModel > $FC then Exit ;
               if PCModel = $FC then if
                  PCSubModel < 3 then Exit ; { Exclude XT 286 machine }
             end;
        S := 'ISA/AT/Classic bus' ;
     asm
        mov OK,0
        mov AH,0C0h
        int 15h
        jc  @@1
        cmp ah,0
        jne @@1
        cmp ES:[BX].word,5
        jb  @@1
        mov AL, ES:[BX+5].byte
        mov FT1.byte ,AL
        mov AL, ES:[BX+7].byte
        Mov FT3,AL
        mov OK,1
  @@1:
        mov PCMCIA,0
        mov ah,80h
        mov cx,5353h
        int 1Ah
        jc  @@11
        cmp cx,5353h
        jne @@2
        mov PCMCIA,1
        jmp @@2
  @@11: cmp ah,15h
        jae  @@2
        mov PCMCIA,1

  @@2:
        mov EISA,0
        mov ax,0D804h
        mov cl,0
        int 15h
        jc  @@4
        cmp ah,0
        je  @@3
        cmp ah,80h
        jb  @@4
        cmp ah,8Fh
        ja  @@4
        cmp ah,86h
        je  @@4
  @@3:  mov EISA,1

  @@4:
       {
        mov VESA,0
        push ss
        pop  es
        mov di, offset BB
        mov ax, 4f00h
        int 10h
        cmp aL, 4Fh
        jne @@5
        mov ax,ES:[DI+6]
        mov PID.word,AX
        mov ax,ES:[DI+8]
        mov PID[2].word,AX
        mov al,ES:[DI+0AH]
        mov VESA,1
        mov VESAFLAG,AL
  @@5:
   }
        mov  APM,0
        mov  ax,5300h
        sub  bx,bx
        int  15h
        jnc  @@6
        cmp  ah,86h
        je   @@7
  @@6:  mov  APM,1
  @@7:
      end;
         SCSI  := False ;
        if Ok then begin
         if Ft1 and 2 > 0 then S := 'Micro Channel';
         if Ft1 and 1 > 0 then S := 'MCA and ISA';
            SCSI := (Ft3 and $8> 0) ;
        end;
         if EISA then S := 'EISA';
         if PCMCIA then S:= S + ', PCMCIA';
         if SCSI then S := S + ', onboard SCSI';
         if APM  then S := S + ', APM';
         GetBusType := S ;
  end;


procedure GetHDDInfo(N: Byte; var S: String);
 var NumFD: Byte;
     NumHD, NumCyl, NumSect, NumHeads: Byte;
     NumCylinders: Word;
begin
 asm
  mov ah, 08h
  mov dl, 80h
  add dl, N
  int 13h
  mov NumHD, dl
  mov NumHeads, dh
  mov NumCyl, ch
  mov NumSect, cl
 end;
 NumCylinders := 1+(NumCyl + (NumSect shr 6)*256);
 S := FStr((LongInt(NumCylinders)*(LongInt((NumSect) and $3F))
     *LongInt(1+NumHeads)) div 2048);
 S := S + 'M, ' + ItoS(NumHeads+1)+GetString(dlSI_Heads)+
      ItoS(NumCylinders)+GetString(dlSI_Tracks)+ItoS(NumSect and $3F)+GetString(dlSI_SectTrack);
end;

procedure GetDisks(var FDD: String);
 var NumFD: Byte;
     NumHD, NumCyl, NumSect, NumHeads: Byte;
     S: String;
     NumCylinders: Word;
     I: Byte;
begin
 NumFD := (mem[$40:$10] and 1)*(1+mem[$40:$10] shr 6);
 FDD := '';
 if NumFD = 0 then FDD := GetString(dlSI_NotPresent) else
 for I := 1 to NumFD do
  begin
   asm
    mov ah, 08h
    mov dl, I
    dec dl
    int 13h
    mov NumHD, bl
   end;
   case NumHD of
    1: S := '5.25" 360K';
    2: S := '5.25" 1.2M';
    3: S := '3.5" 720K';
    4: S := '3.5" 1.44M';
    6: S := '3.5" 2.88M';
    else S := 'Unknown disk driver type';
   end;
   if FDD <> '' then FDD := FDD + ', ';
   FDD := FDD + S;
  end;
end;


procedure SystemInfo;
var
    D: PDialog;
    R: TRect;
    P: PView;
    MType,
    Mhz,
    CPU,
    CoCPU,
    stHD,
    ndHD,
    FDDs: String[80];
    Btype: String[30];
    S: String;
    Prc: String[20];
    EQList, Y, XMSSize: Word;
    LL: Array[1..10] of LongInt;

begin
 asm
  int 11h
  mov EQList, ax
 end;
 R.Assign(1,1,70,22);
 New(D, Init(R, GetString(dlSystemInfo)));
 D^.Options := D^.Options or ofCentered;
 D^.HelpCtx := hcSystemInfo;

 GetMType(MType);
 GetCPUInfo(CPU, CoCPU);
 Prc := ItoS(GetSpeed(Mhz)); if Prc[0] > #2 then Insert('.', Prc, Length(Prc)-1);
 BType := GetBusType;
 LL[1] := LongInt(@MType);
 LL[2] := LongInt(@CPU);
 LL[3] := LongInt(@MHz);
 LL[4] := LongInt(@CoCPU);
 LL[5] := LongInt(@Prc);
 LL[6] := LongInt(@Btype);
 FormatStr(S, GetString(dlSI_Main), LL);
 R.Assign(3,2,66,7);
 P := New(PStaticText, Init(R, S));
 P^.Options := P^.Options or ofFramed;
 D^.Insert(P);
 S := GetString(dlSI_MainBoard);
 R.Assign(4,1,6+Length(S),2);
 P := New(PLabel, Init(R, S,P));
 D^.Insert(P);

 Y := 1;
 GetDisks(FDDs); S := GetString(dlSI_FloppyDrives)+FDDs+^M;
 if (mem[$40:$75] <> 0)
     then begin
           GetHDDInfo(0, stHD);
           S := S +  GetString(dlSI_1stHard) + stHD+^M;
           Inc(Y);
          end;
 if Test8086 > 0 then
  begin
   if mem[$40:$75] > 1 then
    begin
     GetHDDInfo(1, ndHD);
     S := S +   GetString(dlSI_2ndHard) + ndHD;
     Inc(Y);
    end;
  end;
 R.Assign(3,9,66,9+Y);
 P := New(PStaticText, Init(R, S));
 P^.Options := P^.Options or ofFramed;
 D^.Insert(P);
 S := GetString(dlSI_DiskDrivers);
 R.Assign(4,8,6+Length(S),9);
 P := New(PLabel, Init(R, S,P));
 D^.Insert(P);

 asm
  int 12h
  mov XMSSize, ax
 end;
                         S :=  GetString(dlSI_Conventional) + ItoS(XMSSize) + 'K'^M;
 XMSSize := 0;
 if Test8086 > 0 then
  begin
   asm
    mov al, $18
    mov dx, $70
    out dx, al
    inc dx
    in  al, dx
    mov ah, al
    dec dx
    mov al, $17
    out dx, al
    inc dx
    in  al, dx
    mov XMSSize, ax
   end;
  end;
 if XMSSize <> 0 then S := S + GetString(dlSI_Extended) + ItoS(XMSSize) + 'K'^M;
 if EMSFound then S := S + GetString(dlSI_Expanded) + ItoS(EMSSize) + 'K';
 R.Assign(3,11+Y,37,14+Y);
 P := New(PStaticText, Init(R, S));
 P^.Options := P^.Options or ofFramed;
 D^.Insert(P);
 S := GetString(dlSI_Memory);
 R.Assign(4,10+Y,6+Length(S),11+Y);
 P := New(PLabel, Init(R, S,P));
 D^.Insert(P);

       S := GetString(dlSI_COM);
 if EQList and $0E00 <> 0 then S := S + ItoS((EQList and $0E00) shr 9) else S := S + GetString( dlSI_NotPresent );
 S := S + GetString(dlSI_Lpt);
 if EQList and $C000 <> 0 then S := S + ItoS((EQList and $C000) shr 14) else S := S + GetString( dlSI_NotPresent );
 {S := S + ^M'   Game port : ';
 if EQList and $1000 <> 0 then S := S + 'Present' else S := S + 'None';}
 S := S + GetString(dlSI_OSVer);
 EQList := DOSVersion;
 if WordRec(EQList).Lo >= 10 then begin
                                    if (WordRec(EQList).Hi = 30) and
                                       (WordRec(EQList).Lo = 20) then S := S+'OS/2 Warp'
                                       else
                                    S := S + 'OS/2 '+ItoS(WordRec(EQList).Lo div 10)+'.'+
                                                     ItoS(WordRec(EQList).Hi)
                                  end
                             else S := S + 'DOS '+ ItoS(WordRec(EQList).Lo)+'.'+
                                                   ItoS(WordRec(EQList).Hi);
 R.Assign(39,11+Y,66,14+Y);
 P := New(PStaticText, Init(R, S));
 P^.Options := P^.Options or ofFramed;
 D^.Insert(P);
 S := GetString(dlSI_Ports);
 R.Assign(41,10+Y,43+Length(S),11+Y);
 P := New(PLabel, Init(R, S,P));
 D^.Insert(P);

 R.Assign(1, 18, 11, 20);
 P := New(PButton, Init(R, GetString(dlOKButton), cmOK, bfDefault));
 P^.Options := P^.Options or ofCenterX;
 D^.Insert(P);
 Desktop^.ExecView(D);

 Dispose(D, Done);
end;

end.