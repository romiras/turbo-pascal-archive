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

{$DEFINE bFMTDBG}
{$DEFINE nFAST}
{$IFnDEF FMTDBG}

 Unit Format;

   interface
{$ENDIF}

 uses  Objects,DOS,advance;

 Const

        cmStatusUpdate  = 1990;

        stInit          = 0;
        stAnalyze       = 1;
        stFormat        = 2;
        stQuick         = 3;
        stVerify        = 4;
        stSystem        = 5;
        stBoot          = 6;
        stNone          = 255;

        fdInsertNewDisk = 0;
        fdUserInterrupt = 1;
        fdHardwareError = 2;
        fdNoDiskInDrive = 3;
        fdDiskProtected = 4;
        fdNonDosFormat  = 5;
        fdNQuickFormat  = 6;
        fdNoSystemFiles = 7;
        fdTrack0Bad     = 8;
        fdBadInterleave = 9;
        fdErrorSysAreas =10;
        fdDiskFormatted =11;


        fdContinue      = 0;
        fdAbort         = 1;

        fmFastFormat    = 0;
        fmDosFormat     = 1;
        fmSafeFormat    = 2;
        fmQuickFormat   = 3;
        fmNonDos        = 4;

        foSystemDisk    = 1;
        foUncond        = 2;
        foMarkTrack     = 4;
        fooptimize      = 8;


        iosys     :  string[10] = 'IBMBIO.COM' ;
        mdos      :  string[10] = 'IBMDOS.COM' ;

        iosys1    :  string[6]  = 'IO.SYS' ;
        mdos1     :  string[9]  = 'MSDOS.SYS' ;

        flFormat  :  String[6]  = 'Format' ;
        flVerify  :  String[6]  = 'Verify' ;
        flWrite   :  String[6]  = 'Write' ;
        flRead    :  String[6]  = 'Read' ;

        flMode    : array [0..4] of String[5] = ('Fast','DOS','Safe','Quick','User');

                                           {360,720,1200,1400,2800 floppy}
const   StdTracks : array [1..5] of byte = (40,80,80,80,80);
        StdSect   : array [1..5] of byte = ( 9,10,15,18,36);

        (*
        Old8      :   Pointer = Nil;
        In13      :   boolean = False ;
         *)
var
        Timer     : Longint Absolute $40:$6C ;

 type
{        erAction = (cmCancel,cmOk);}

        Barray = array [0..$F000] of byte;
        pBArray = ^BArray;


        BootArray = array [28..511] of byte ;


        IOpar = record

{_______IOCtl parameter block___ }
        ioctlb : byte ;  {}
        iodev  : byte ;  {device type   = 360K drive}
        ioatr  : word ;  {attributes}
        iocil  : word ;  {cils on drive = 40 tracks}
        iomed  : byte ;  {mdia type}
{_______BPB }
        iobps  : word ;  { bytes per sector }
        ioclu  : byte ; { cluster size }
        iobsz  : word ; { BOOT size    }
        iofcp  : byte ; { FAT copyes   }
        iorsz  : word ; { ROOT entries }
        iotsc  : word ; { total sectors}
        iomds  : byte ; { media descriptor  }
        iofat  : word ; { sectors per FAT   }
        iosec  : word ; { sectors per track }
        iohed  : word ; { heads number      }
        shara  : array [0..$FF] of byte ;
     end;


{_______BOOT sector record______ }

       BootSector  = record
        bootd  : array [1..3] of byte;
        blabel : array [1..8] of char;
        ssize  : word           ; { sector size }
        csize  : byte           ; { cluster size }
        bsize  : word           ; { sectors before 1st fat }
        fsize  : byte           ; { FAT copyes }
        rsize  : word           ; { root size }
        topsec : word           ; { top sector number }
        media  : byte           ; { media descriptor }
        fatsz  : word           ; { total sectors in one FAT }
        tsect  : word           ; { sectors per track }
        headc  : word           ; { heads }
        Boot_code : BootArray;
        {shara  : array [1..374] of byte ;}
      end;


       DiskBaseTable = record
        dbt    : byte           ; { disk base table. head unload, SRT }
        sh001  : byte           ; { head load time, DMA transfer method }
        sh002  : byte           ; { motor wait }
        secsiz : byte           ; { sector size }
        eot    : byte           ; { max. sector number }
        dgap   : byte           ; { data GAP length }
        sh004  : byte           ; { DTL }
        fgap   : byte           ; { format GAP length }
        fillb  : byte           ; { fill byte }
        sh005  : byte           ; { head settle time }
        sh006  : byte           ; { motor start time }
        dnsign : array [1..16]  of byte ;
       end;

      TrackDescriptors = array [1..40,1..4] of byte;
      {
        c01,h01,n01,s01  : byte;
        sh000            : array [0..$1FF] of byte;
       end;
      }


      DirEntrie  =  record
          FileName      :     array [0..10] of byte;
          Attr          :     byte;
          SHARA         :     array [0..9] of byte;
          DateTime      :     longint;
          Cluster       :     word;
          Size          :     longint;
      end;

      DirSector  = Array [1..16] of DirEntrie ;


      SysFile  = record
          Path : string[80];
          Name : string[12];
          Size : longint ;
      end;


 type  Pfmt = ^Tfmt;
       Tfmt = object(Tobject)

               DBT          :   DiskBaseTable;
               OldDbt       :   Pointer;
{               Old15        :   Pointer; }
               regs         :   registers  ;

               c_Terminate  :   boolean ;


               {_______work data_______________}



               bsectd       :   byte    ;  { start sector}
               btrack       :   word    ;  { start track }
               tracks       :   word    ;  {  0054h           ; tracks count}
             (*  trackb       : byte ; { absolute tracks ; } *)
               heads        :   byte    ;  { heads count }
               drvNum       :   byte    ;  { drive number }
               drvSave      :   byte    ;  { saved drive number }
              { sectors      :   byte    ; }

               interl       :   byte    ;  { interleave num }
               shifts       :   byte    ;  { sectors shift factor }
               shiftt       :   byte    ;  { tracks  shift factor }
               shifth       :   byte    ;  { heads   shift factor }

               t_start      :   longint ;  { timer start }
               t_elaps      :   longint ;  { timer elaps }
               t_estim      :   longint ;  { estimated timer }

               {   Information  block  - used for output    }
               {   status information                       }

               i_size       :   longint ;
               i_formatted  :   longint ;
               i_bads       :   longint ;  { bad sectors }
               i_operation  :   String[12] ;
               i_track      :   longint ;
               i_head       :   longint ;
               I_SysSpace   :   longint ;
               I_Serial     :   longint ;
               IO_error     :   word    ;

               U_ClustSz    :   byte    ;  { User - defined }
               U_Roots      :   byte    ;  { User - defined }


               fatkey       :   byte    ;  { cluster selection key            }
               oldclu       :   byte    ;  { trapped track descriptor         }
               fatcvf       :   byte    ;  { sectors count buffer             }
              { clsize       :  byte    ;   clusters size                    }
               medias       :   byte    ;  { media descriptor                 }
               set8b        :   byte    ;  { low level BIOS info              }
               set8f        :   byte    ;
               set90        :   byte    ;
               set92        :   byte    ;
               fgap1        :   byte    ;

               roots        :   word    ;
               dataStart    :   word    ;  { 1st sector of data sector }
               TotalClusters:   word    ;

               {_______Mode Control_____}

               bfkey1       :   char    ;  {  direct set bios call }
               bfkey2       :   char    ;  {  format type }
               Verify       :   char    ;

               fMode        :   word    ;  { format type }
               fOptions     :   word    ;  { options     }

               fVlabel      :   string[11] ;

               {_______BOOT SECTOR______}

               BootS,Boot1  :   BootSector;
               Trdsc        :   TrackDescriptors;

               FAT          :   pBArray;
               FATsize      :   word;
             {
               FAT          :   array [0..$11F] of byte;
             }

               {_______System Files_____}

               S_IOSYS , S_MSDOS, S_COMMAND : SysFile;


               constructor init;

               procedure   SetStatus( Status : integer );virtual;
               procedure   UpdateParams;virtual;
               function    ScanEvents : boolean ;virtual;
               function    UserInterrupt : boolean;


               function    FormatDialog( Code : integer ):integer;virtual;
               procedure   SetData ;virtual;
               procedure   SetAdditionalData ;virtual;

               (*
               procedure   set360k;
               procedure   set720k;
               procedure   set12m;
               procedure   set14m;
               *)

               procedure   set28m;


               function    CheckIOError : byte;
               function    CheckErrors  : boolean;

               function    GetErrorString( Code : byte ):String;
               function    GetStatusString( Code : byte ):String;

               function    GetLimit:longint;

               procedure   initBoot(var Data);          { Fill boot with std params }
               procedure   initDBT(var Data);           { Copy DBT from constants area }

               procedure   Interleave(trk,head : byte);  { make interleave for sectors }
               Function    Cluster(Sector: Word):Word;  { Sector from cluster }


               procedure   InitFAT;                  { Init fat by BPB params }
               procedure   DoneFAT;                  { Disposes fat }
               procedure   SetupHardware;            { Prepare 4 format }

               function    SameType : boolean ;      { Compare BootS & Boot }
               function    IsDos    : boolean ;      { IS Boot1 DOS- disk ? }
               procedure   CopyQuickBoot ;           { Copy BPB form Boot1 2 Boots }


               procedure   AddFile(Name : string); virtual ;
               function    CheckFilesOnDisk : boolean ; virtual ;




               function    formatTrack(trk,head : byte):byte;
               function    VerifyTrack(trk,head,sec,secnum : byte):byte;
               function    ReadTrack(trk,head,sec,secnum : byte; var Buf):byte;
               function    MarkBadSectors(trk,head : byte):word;
               function    FormatMedia:boolean;
               function    WriteBootFatRoot : boolean;
               procedure   CalculateBootFatRoot;


               function    FindSystemFiles:boolean;
               procedure   TransferSystem;          { Copy system files }


               {function     getdrv(drv : byte):boolean;}      { Actual Drive type 0..5 }

               function    runFormat:integer;       { MAin format proc }


               {procedure   Int15;}
               destructor  done;virtual;

              end;

              function    drvtype(drv:byte) : byte;

{$IFnDEF FMTDBG}
   implementation uses xTime;
{$ENDIF}

     (*
procedure  INT8;interrupt;
    begin
           if In13 then

                    asm
                      push es
                      push ax
                      sub ax,ax
                      mov es,ax

                      push cx

                      mov  cx,2h
                    @@1:
                      push cx
                      pushf
                      call dword ptr ES:[ 28h * 4 ]
                      pop cx
                      loop @@1

                      pop cx

                      pop  ax
                      pop  es
                    end;

               asm

                   sub ax,ax
                   pushf
                   call dword ptr old8

               end;
    end;

      *)

function MaxAvail: LongInt;
begin
  MaxAvail := MemAdjust(System.MaxAvail);
end;


function CopyFile(FFrom,FTo:string):boolean;
var
    FromF, ToF: file;
    NumRead, NumWritten: Word;
    Buf: array[1..4096] of Char;

    FATTR : word;
    FTIME : longint;

   begin
     Assign(FromF, FFrom); { Open input file }

     GetFattr(FromF,FATTR);

     Reset(FromF, 1);  { Record size = 1 }
     Assign(ToF, Fto ); { Open output file }
     Rewrite(ToF, 1);  { Record size = 1 }
     repeat
       BlockRead(FromF, Buf, SizeOf(Buf), NumRead);
       BlockWrite(ToF, Buf, NumRead, NumWritten);
     until (NumRead = 0) or (NumWritten <> NumRead);

     GetFtime(FromF,FTime);
     GetFattr(FromF,FATTR);
     SetFtime(ToF,FTime);


     Close(FromF);
     Close(ToF);

     Assign(ToF, Fto ); { Open output file }
     SetFattr(ToF,FATTR);
   end;

function FileExists(FileName: String): Boolean;
{ Boolean function that returns True if the file exists;otherwise,
 it returns False. Closes the file if it exists. }
   var
    F: file;
   begin
    {$I-}
    Assign(F, FileName);
    FileMode := 0;  { Set file access to read only }
    Reset(F);
    Close(F);
    {$I+}
    FileExists := (IOResult = 0) and (FileName <> '');
   end;  { FileExists }

procedure GetAbsSector(relSector:Word; BootS : BootSector;
                   Var track,head,phsector:byte);
var RelTrk : word;
    begin
    With Boots do
         begin
           PhSector:= Succ(RelSector mod TSect);
           RelTrk  := RelSector div TSect;
           track := RelTrk div headc;
           head  := RelTrk mod headc;
         end;
    end;

Function GetLogSector(Head,Track,Sector : Word;
                        BootS : BootSector ) : Word;
   begin
    with Boots Do
         GetLogSector := Track * headc * tsect +
                                  Head * tsect +
                                  Pred(Sector) ;
   end;


  function MoreDiv(A,B : word):word;
    begin
           MoreDiv := A div B + byte((A mod B) > 0);
    end;


procedure   Tfmt.initDBT;assembler;
    asm
        push    ds
        les     di,DATA
        mov     si,offset @@DBT
        mov     ax,cs
        mov     ds,ax
        mov     cx,9
        cld
        rep     movsw
        pop     ds
        jmp     @@done

@@DBT:  db      0dfh            { disk base table. head unload, SRT   }
        db      002h            { head load time, DMA transfer method }
        db      025h            { motor wait                          }
        db      002h            { sector size                         }
        db      009h            { max. sector number                  }
        db      01bh            { data GAP length                     }
        db      0ffh            { DTL                                 }
        db      002h            { format GAP length                   }
        db      0f6h            { fill byte                           }
        db      00fh            { head settle time                    }
        db      004h            { motor start time                    }
        db      'DN II Par table'
@@done:
     {
      disk10:paratyp=($df,$02,$25,$02,10,$1b,$ff,$2e,$F6,$0f,$04);
      }
   end;


procedure   Tfmt.initBoot;assembler;
    asm
        push    ds
        les     di,data
        mov     si,offset @@Boot
        mov     ax,cs
        mov     ds,ax
        mov     cx,$100
        cld
        rep     movsw
        pop     ds
        jmp     @@done

@@BOOT: db      0EBh,042h,090h
        db      'Vaccined',000h
        db      02h             { sector size         }
        db      02h             { cluster size        }
        dw      00001h          { boot size           }
        db      02h             { sectors per FAT     }
        dw      00070h          { root size           }
        dw      00b40h          { top sector number   }
        db      0f0h            { media descriptor    }
        dw      00009h          { fat size            }
        dw      0012h           { sectors per track   }
        dw      0002h           { heads               }

     db  000h,000h,000h,000h
     db  000h,000h,000h,000h,000h,000h,000h,000h
     db  000h,000h,000h,044h,04Eh,020h,046h,04Fh
     db  052h,04Dh,041h,054h,049h,049h,046h,041h
     db  054h,031h,032h,020h,020h,020h,02Eh,080h
     db  026h,090h,004h,0DFh,0FAh,0FCh,033h,0C0h
     db  08Eh,0D0h,0BCh,000h,07Ch,016h,007h,0BBh
     db  078h,000h,036h,0C5h,037h,01Eh,056h,0BFh
     db  02Bh,07Ch,0B9h,00Bh,000h,0F3h,0A4h,006h
     db  01Fh,0C6h,045h,0FEh,00Fh,0C6h,045h,0F9h
     db  016h,089h,047h,002h,0C7h,007h,02Bh,07Ch
     db  0FBh,0CDh,013h,072h,06Bh,0BAh,000h,0F0h
     db  033h,0EDh,0E8h,0CDh,000h,022h,073h,004h
     db  0C7h,005h,0A5h,0FEh,0E8h,0C3h,000h,026h
     db  073h,004h,0C7h,005h,087h,0E9h,0E8h,0B9h
     db  000h,05Eh,073h,004h,0C7h,005h,0D2h,0EFh
     db  0E8h,0AFh,000h,072h,073h,004h,0C7h,005h
     db  053h,0FFh,0B6h,0C8h,0E8h,0A3h,000h,04Eh
     db  073h,002h,0A5h,0A5h,04Dh,073h,021h,0BEh
     db  0DCh,07Dh,0E8h,08Fh,000h,098h,0CDh,016h
     db  03Ch,06Eh,074h,014h,0B9h,001h,000h,0BAh
     db  000h,000h,0B7h,07Ch,0B8h,001h,003h,00Eh
     db  007h,0CDh,013h,0EAh,0F0h,0FFh,000h,0F0h
     db  0B9h,006h,000h,0BAh,000h,000h,0BBh,000h
     db  005h,0B8h,001h,002h,0CDh,013h,073h,013h
     db  0BEh,09Fh,07Dh,0E8h,05Eh,000h,098h,0CDh
     db  016h,08Fh,006h,078h,000h,08Fh,006h,07Ah
     db  000h,0CDh,019h,080h,07Fh,00Bh,004h,074h
     db  0E7h,0BEh,02Ch,000h,0B7h,007h,0B9h,004h
     db  000h,0B6h,001h,0A1h,018h,07Ch,02Ah,0C1h
     db  040h,03Bh,0F0h,077h,002h,08Bh,0C6h,050h
     db  0B4h,002h,0CDh,013h,058h,072h,0C9h,098h
     db  02Bh,0F0h,076h,014h,002h,0F8h,002h,0F8h
     db  0B1h,001h,0FEh,0C6h,03Ah,036h,01Ah,07Ch
     db  072h,0D9h,0FEh,0C5h,0B6h,000h,0EBh,0D3h
     db  08Ah,02Eh,015h,07Ch,0B2h,000h,0BBh,00Ch
     db  000h,0B8h,000h,000h,0EAh,000h,000h,070h
     db  000h,0E8h,04Fh,000h,0ACh,00Ah,0C0h,075h
     db  0F8h,0C3h,05Eh,0ACh,056h,098h,097h,026h
     db  039h,015h,073h,047h,0BEh,0D1h,07Dh,0E8h
     db  0EAh,0FFh,08Bh,0C7h,0D0h,0E8h,0D0h,0E8h
     db  0E8h,01Fh,000h,0B0h,02Dh,0E8h,02Bh,000h
     db  08Bh,005h,0E8h,00Ch,000h,0B0h,03Ah,0E8h
     db  021h,000h,089h,015h,083h,0EFh,002h,08Bh
     db  005h,08Ah,0E8h,08Ah,0C4h,0E8h,002h,000h
     db  08Ah,0C5h,050h,0B1h,004h,0D2h,0E8h,0E8h
     db  001h,000h,058h,024h,00Fh,004h,090h,027h
     db  014h,040h,027h,033h,0DBh,0B4h,00Eh,0CDh
     db  010h,045h,0F9h,0C3h,000h,000h,000h,00Ah
     db  00Dh,04Eh,06Fh,020h,073h,079h,073h,074h
     db  065h,06Dh,020h,06Fh,072h,020h,064h,069h
     db  073h,06Bh,020h,065h,072h,072h,06Fh,072h
     db  00Ah,00Dh,050h,072h,065h,073h,073h,020h
     db  061h,020h,06Bh,065h,079h,020h,074h,06Fh
     db  020h,072h,065h,074h,072h,079h,00Ah,00Dh
     db  000h,007h,00Ah,00Dh,049h,06Eh,074h,000h
     db  059h,0ECh,000h,0F0h,00Ah,00Dh,056h,069h
     db  072h,075h,073h,020h,073h,074h,065h,072h
     db  069h,06Ch,069h,07Ah,065h,064h,02Eh,020h
     db  043h,075h,072h,065h,020h,042h,04Fh,04Fh
     db  054h,03Fh,00Ah,00Dh,007h,000h,055h,0AAh

@@done:
    end;




procedure   tfmt.SetStatus;
    begin
         { Setup Status }
    end;

function   tfmt.ScanEvents;
    begin
         scanEvents := False;
    end;

procedure   tfmt.UpdateParams;
    begin
         { Params changed }
         { More Bad Sectors, etc }
    end;

function    tfmt.FormatDialog;
    begin
         {  Write(' Error Occured... (A)bort or (C)ontinue'); }
         {  Error := acContinue; }
         {
       case Code of

       end;
         }
    end;

procedure  tfmt.SetAdditionalData;
    begin
           { Update optimize information }
    end;


procedure tfmt.initFat;
    begin
           with BootS do begin

            FATsize := longint(FATSZ)*longint(SSize);

            if  (FATsize> $8000) or (FatSize>MaxAvail) then exit;

            GetMem(FAT,FatSize);
            if FAT <> Nil then
                begin
                  FillChar(FAT^,FatSize,0);
                  FAT^[0] :=  Media;
                  FAT^[1] := $FF;
                  FAT^[2] := $FF;
                end;

           end { with }
    end;

procedure tfmt.DoneFat;
    begin
          if FAT<>Nil then FreeMem(FAT,FATSize);
    end;

(*

procedure   Tfmt.set360k;
    begin
            with BootS do begin
            tracks := 40;       { tracks amount     }
            tsect  := 9;        { sectors / track   }
            rsize  := $70;      { root size         }
            U_ClustSZ := 2;     { sectors / claster }
            medias := $FD;      { media descriptor  }

            bfkey1 := 'd';

           end;
    end;

procedure   Tfmt.set720k;
    begin
      with BootS do begin
            tracks := 80;       { tracks amount     }
            tsect  := 9;        { sectors / track   }
            rsize  := $70;      { root size         }
            U_ClustSZ := 2;     { sectors / claster }
            medias := $F9;      { media descriptor  }

            bfkey1 := 'd';

           end;
    end;

procedure   Tfmt.set12m;
    begin
      with BootS do begin
            tracks := 80;       { tracks amount     }
            tsect  := 15;       { sectors / track   }
            rsize  := $E0;      { root size         }
            U_ClustSZ := 1;     { sectors / claster }
            medias := $F9;      { media descriptor  }

            bfkey1 := 'd';

           end;
    end;

procedure   Tfmt.set14m;
    begin
      with BootS do begin
            tracks := 80;       { tracks amount     }
            tsect  := 18;       { sectors / track   }
            rsize  := $E0;      { root size         }
            U_ClustSZ := 1;     { sectors / claster }
            medias := $F0;      { media descriptor  }

            bfkey1 := 'd';

           end;
    end;
*)

procedure   Tfmt.set28m;
    begin
      with BootS do begin
            tracks := 80;       { tracks amount     }
            tsect  := 36;       { sectors / track   }
            rsize  := $E0;      { root size         }
            U_ClustSZ := 1;     { sectors / claster }
            medias := $F0;      { media descriptor  }
            fgap1  := $74;      { set gap length    }

            bfkey1 := 'd';

           end;
    end;



Constructor Tfmt.init;
   begin
            inherited init;

            { initialize internal structures }

            initBoot(BootS);
            initDBT(DBT);


            { set disk parameter table }

            GetIntVec($1E,olddbt);
            SetIntVec($1E,@DBT);

            (*
            GetIntVec($8,old8);
            SetIntVec($8,Addr(int8));
             *)


            bfkey1   :=   ' ';
            bfkey2   :=   ' ';
            FAT      :=  nil;

            DrvSave  :=  $FF ;

            SetData;

            if not DrvSave in [1..5,$FF] then Fail;

            if DrvSave = $FF then
               DrvSave := DrvType(DrvNum);

   end;

Destructor  Tfmt.done;
   begin
            { restore disk parameter table }


      SetIntVec($1E,olddbt);

(*
     with regs do
      begin
        DL := drvnum;                    { drive }
        DH := Pred(Heads);
        AH := $18;                       { set media type    }
        CH := Lo(Stdtracks[DrvSave]);    { tracks            }
        CL := STdsect[DrvSave];          { sectors per track }
        intr($13,regs);
      end;
 *)
            (*
            SetIntVec($8,old8) ;
             *)



            with regs do
             begin
              {
                 BL := Succ(drvnum);
                 AX := $440F ;
                 intr($21,Regs);
               }
                 DL := drvnum;
                 AX := 0;
                 Intr($13,Regs);

                 BL := Succ(drvnum);
                 AX := $440F ;
                 intr($21,Regs);

             end;

            inherited done;
   end;

function drvtype;
var MaxC : word;
    MaxS : byte;
    Driv : byte;

    Ioctl : Iopar ;

label
    NotOK ;


  function  GetDrv(Drv:Byte):boolean;
    var
         Attr : byte ;
         regs : registers;

    begin

        GetDrv := False ;

       with IoCtl , Regs do begin
         ax:=$4409;
         bl:=Succ(DRV );
         bh:=0;
         intr($21,regs);
        if (FCarry and Flags) <> 0 then  exit;
        if (dx and $9200)<>0 then exit;


        ax:=$440e;
        bl:=Succ(Drv);
        bh:=0;
        intr($21,regs);
        if (FCarry and Flags)<>0 then exit;

        Attr := al;

        ax:=$440f;
        bl:=Succ(Drv);
        bh:=0;
        intr($21,regs);
        if (FCarry and Flags)<>0 then Exit;

        IoCtlB := 0;

        ax:=$440d;
        cx:=$860;
        bl:=Succ( Drv );
        bh:=0;
        dx:=ofs(IoCtlB);
        ds:=seg(IoCtlB);
        intr($21,regs);

        if Not IoDev in [0,1,2,7] then Exit;

        if Attr <> 0 then
         begin
          bh:=0;
          ax:=$440f;
          bl:=Attr;
          intr($21,regs);
         end;

         GetDrv := True ;

      end; { with regs }
    end; { proc }



   begin



           if GetDrv( Drv )
              then
                with IOCtl do
                   begin

                      case IODev of
                      0 : DrvType := 1;
                      1 : DrvType := 3;
                      2 : DrvType := 2;
                      7 : begin
                            if IoSec >= 23
                                Then DrvType := 5
                                else DrvType := 4;
                          end;
                      end; { Case }

                      Exit ;

                   end;  { IOCTL }

        asm
             mov     dl,drv
             mov     ah,08h             {; get disk parameters}
             int     13h                {; call BIOS service  }
             jc      NotOk
             mov     Driv,BL            { only for AT & PS/2  }
             mov     ax,cx
             xchg    ah,al
             mov     ch,cl
             mov     cl,6
             shr     ah,cl
             mov     maxc ,ax
             and     ch,$3F
             mov     maxs ,ch
        end;



        if maxc <= 48 then
           begin        {  360 floppy }
              drvtype := 1; exit;
           end;
       if maxs >= 23 then
           begin        { 288 floppy  }
              drvtype := 5;  exit;
           end;
       if maxs >= 18 then
           begin        { 144 floppy  }
              drvtype := 4;  exit;
           end;
        if maxs >= 13 then
           begin        { 12  floppy }
              drvtype := 3; exit;
           end;
                        { 720 floppy }
              drvtype := 2; exit;

NotOK :       drvtype := 0;


   end;



(*

procedure   tfmt.getdrv;


var     ioctlb : IOpar ;
        maxc   : word;
        maxs   : byte;
        ioctl  : byte;

   begin
     With BootS,regs do begin
        { drive }


{_______get drive parms}

        BL := Succ(drv);
        DS := Seg(ioctlb);   { load IOCtl parameter block address }
        DX := ofs(ioctlb);
        CX := $0860;         { get device parms }
        AX := $440D;         { Generic IOCtl    }
        Intr ($21,regs);     { call DOS service   }

     if ( Flags and FCarry = 0 ) then
      begin
        with IOctlB do
         begin

              writeln(iodev);
              writeln(iocil);
              writeln(iosec);
              writeln(iohed);

              {
              tracks  := iocil;
              tsect   := iosec;
              heads   := iohed;
              }
         end;
        if  tsect >= $16 then Set28m;  { prepare to format 2.88M 3.5" disk }
         exit;
      end;

             { no IOCTL available, get from BIOS }

              tracks := StdTracks [ drvtype (drv) ] ;
              tsect  := StdSect   [ drvtype (drv) ] ;
              Heads  := 2;

      end { with }
   end;

*)

function    tfmt.GetLimit;

   begin
         with Boots do

           begin

             GetLimit := Heads * Tracks ;

           end;

   end;


procedure   tfmt.SetData;
   begin

    with BootS do begin

{       drvnum := 1; }

       tracks :=  82;
       tsect  :=  18;
       heads  :=  2;

       verify := 'y';

       shifts := 2;

{
       write(' Tracks  ...');readln(tracks);writeln;
       write(' Sectors ...');readln(tsect);writeln;
}

      { rsize  :=  ; }

      {  set12m;}
    {    tsect := 18 ;}

       { bfkey2 :='h';}

    {   clsize := 8;
       fsize  := 2;
    }

    {   rsize  := 16; }
    {
        rsize := 224;
        clsize := 1;
     }
     {  interl := 2; }

      { shifts := 2; }

    {  bfkey2 := 'h'; }

    {  setup format parameters }

    {
       clsize
       ssize
       fgap1
       heads
       shifts
       shiftt
       shifth
    }
      end;

   end;

function tfmt.ISDos;
var  I , R : byte ;

     Tr : integer ;

   begin

      IsDos := False ;

        If (  Boot1.Boot_Code[511]<>$AA ) or
         (  Boot1.Boot_Code[510]<>$55 )  Then Exit;

        If Boot1.SSize<>512 then Exit;

        if Boot1.TopSec > 6000 then Exit;

        if not Boot1.HeadC in [1..2] then Exit;

      TR := Boot1.TopSec div Boot1.Tsect div Boot1.HeadC ;
      if  TR > 84 then Exit;


      If Boot1.Fsize <> 2 then Exit;
      If Boot1.CSize > 8 then Exit;
      IF Boot1.Rsize > 1024 then Exit;

      IsDos := True ;

   end;

procedure tfmt.CopyQuickBoot;
    begin


    Move(Boot1.SSize,Boots.SSize,17);
 (*
        ssize  : word           ; { sector size }
        csize  : byte           ; { cluster size }
        bsize  : word           ; { sectors before 1st fat }
        fsize  : byte           ; { FAT copyes }
        rsize  : word           ; { root size }
        topsec : word           ; { top sector number }
        media  : byte           ; { media descriptor }
        fatsz  : word           ; { total sectors in one FAT }
        tsect  : word           ; { sectors per track }
        headc  : word           ; { heads }
 *)

      Tracks := Boot1.TopSec div Boot1.Tsect div Boot1.HeadC ;

    end;



function tfmt.SameType;
var  I , R : byte ;

     Tr : integer ;

   begin

      SameType := False ;

        I := 4;
        Repeat
          R := ReadTrack(0,0,1,1,Boot1);
          if R=0 then Break;
          DelayTics(9);
          dec(I);
        Until I = 0;
        if R > 0 then Exit;

        If ( Boot1.Boot_Code[511]<>$AA ) or
         ( Boot1.Boot_Code[510]<>$55 ) Then Exit;

        If Boot1.SSize<>512 then Exit;
        if BootS.SSize <> Boot1.SSize then Exit;
        IF BootS.Tsect <> Boot1.Tsect then Exit;

        if Boot1.TopSec > 6000 then Exit;

        if not Boot1.HeadC in [1..2] then Exit;

      TR := Boot1.TopSec div Boot1.Tsect div Boot1.HeadC ;

      if TR > 84 then Exit;

      if (Tracks>43) and (Tr<43) then Exit;
      if (Tracks<43) and (Tr>43) then Exit;

      if ABS( TR-Tracks ) > 10 then Exit;

      SameType := True ;



   end;



 procedure  tfmt.AddFile;
     begin
             Writeln(Name);
     end;

 function  tfmt.CheckFilesOnDisk;

 var
     DirSectors , DirStart , I , Y , Z : Word ;
     Buf      : DirSector  ;

     Name  : String[13];

     begin

           CheckFilesOnDisk := False ;

           With Boot1 Do
            begin
                DirSectors := ( Rsize * 32 ) div Ssize ;  { root size }
                DirStart   := Bsize + FSize * FatSz ; { 1st root }
            end;

           with regs do

            for I:=1 to DirSectors do
             begin
                GetAbsSector(pred(DirStart + I),Boot1,CH,DH,CL);

                AH := $2;
                AL := 1;
                DL := drvnum;
                ES := Seg(Buf);
                BX := Ofs(Buf);
                intr($13,regs);
                IO_Error := CheckIOError;
                if IO_Error > 0 then Exit;

            For Y := 1 to 16 do
             with buf[y] do
                begin
                   If FileName[0] = 0 then Exit ;          { Not used entry }
                   IF FileName[0] = $E5 then Continue ;    { Deleted file   }
                   if Attr and 8 > 0 then Continue ;   { volume label   }

                   CheckFilesOnDisk := True ;

                   Move(FileName[0],Name[1],11);
                   Name[0] := #11 ;
                   if Attr and $02  = 0
                     then
                        Insert('  ',Name,9)
                     else
                        Insert(' ±',Name,9);

                   if Attr and $10 > 0 then UpStr(Name)
                    else LowStr(Name);

                   AddFile(Name);

                end; { Dir }



            end;  { All sectors }



     end;


procedure tfmt.SetupHardware;

var

          SectorLimit : Byte ;

          Try : byte ;

const

          Gaps35lo : array [7..13] of byte = ($61,$5C,$50,$2A,$21,$1C,$02);

          Gaps360  : array [7..11] of byte = ($5E,$58,$50,$28,$2);
          Media360 : array [7..11] of byte = ($F0,$FE,$FC,$F0,$F0);

          Gaps35hi : array [17..22] of byte = ($73,$6C,$29,$25,$0B,$01);

          Gaps12lo : array [7..11] of byte = ($5E,$58,$50,$28,$2);
          Media12lo: array [7..11] of byte = ($F0,$FE,$FC,$F0,$F0);

          Gaps12hi : array [14..18] of byte = ($59,$54,$23,$1E,$2);
          Media12hi: array [14..18] of byte = ($F0,$F9,$F0,$F0,$F0);


 procedure setLD;
     begin
           if bfkey1='d' then exit;

        with regs do
          begin
            AX := $1702;       { set low density    }
            DL := drvnum;      { call BIOS service  }
            INTR($13,REGS);
          end;

      with BootS,DBT do begin
        Dgap := $2A;

        mem[$0:$48B] :=  mem[$0:$48B] and $F3 or $4;    { data & step rate }
        mem[$0:$490+drvnum] :=
                  mem[$0:$490+drvnum] and $1F or $40; { disk media state }
      end;
     end;


 procedure setHD;
     begin
           if bfkey1='d' then exit;

       with regs do
          begin
            AX := $1703;       { set high density   }
            DL := drvnum;      { call BIOS service  }
            INTR($13,REGS);
          end;

      with BootS,DBT do begin

        mem[$0:$48B] :=  mem[$0:$48B] and $F3    ;    { data & step rate }
        mem[$0:$490+drvnum] :=
                  mem[$0:$490+drvnum] and $1F    ; { disk media state }
      end;
     end;

 procedure set525;
     begin
           if bfkey1='d' then exit;

       with regs do
          begin
            AX := $1702;       { set low  density   }
            DL := drvnum;      { call BIOS service  }
            INTR($13,REGS);
          end;

      with DBT do
        Dgap := $2A;
     end;

 procedure set35;
     begin

       with regs do
          begin
            AX := $1704;       { set 3'5  media     }
            DL := drvnum;      { call BIOS service  }
            INTR($13,REGS);
          end;

      with DBT do
     {   Dgap := $2A; }
     end;

(*
Procedure ATSetDrive(lw:Byte; trk,sec,Disk,SetUp:Byte);assembler;
asm
   mov  ah,18h
   mov  dl,lw
   mov  cl,sec
   mov  ch,trk
   push ds
   push bp
   {pushf}
   cli
   int 13h
   pop  bp
   pop  ds
   jc   @cont
   or   ah,ah
   jz   @exit
@cont:
   mov  ah,17h
   mov  al,setup
   mov  dl,lw
   push ds
   push bp
{   pushf }
   cli
   int 13h
{   call dword ptr int13p }
   pop  bp
   pop  ds
@exit:
   xor  bx,bx
   mov  es,bx
   mov  ah,disk
   or   ah,ah
   jz   @exit1
   mov  bl,lw
   mov  es:[bx+490h],ah
@exit1:
end;


procedure setdrive(drive,track,sectors : byte );
begin
 case drvtype(drive) of
  1,3:
   if (track>43) and (sectors>10) then ATSetDrive(drive,79,15,$0,3) else
   if (track>43) and (sectors<11) then ATSetDrive(drive,79, 9,$54,4) else
   if (track<44) and (sectors<11) then ATSetDrive(drive,39, 9,$0,2);
  2,4,5:
   if (sectors>17) then ATSetDrive(drive,79,18,$0,5) else
   if (sectors<11) then ATSetDrive(drive,79, 9,$0,4);
 end;
end;

  *)

    begin

     with BootS,DBT,Regs do begin

      { init format parameters }

        bsize  := 1;

         case SSize of
               128:  SecSiz := 0;
               256:  SecSiz := 1;
               512:  SecSiz := 2;
              1024:  SecSiz := 3;
                else SecSiz := 2;
           end;

        {s01    := 2;}



      { init media type }


        DL := drvnum;          { drive }
        DH := Pred(Heads);
        AH := $18;             { set media type    }
        CH := Lo(tracks);      { tracks            }
        CL := Tsect;           { sectors per track }
        intr($13,regs);

        DGAP    :=  $1B;

     {
      Writeln(' Current Drive is ...',drvtype(drvnum));
     }

      case drvSave {drvtype( drvnum )} of


      1: begin     { 360 k drive }

               CSize := heads ;  {*** changed from 1 }

               Media := $F0;

               if tsect > 11 then
                begin
                  Media := Media360[11];
                  fgap  := Gaps360 [11];
                end ;

               if tsect < 7  then
                begin
                  Media := Media360[7];
                  fgap  := Gaps360 [7];
                end ;

              if tsect in [7..11] then
                begin
                  Media := Media360[tsect];
                  fgap  := Gaps360 [tsect];
                end;

                Dgap := $2A ;

                  { recal }

                SectorLimit := 9;


           end;     { 360 k }

        4 : begin  { 1440 drive }

              media := $F0;

                if LongInt(SSize * tsect) > 13 * 512 then
                   begin  { 3'5 hi }
                               csize := 1;
                               fgap  := 2;
                               fgap  := Gaps35hi[tsect];

                               SetHD;

                               SectorLimit := 20 ;

                   end    { 3'5 hi }
                     else
                   begin  { 3'5 lo }
                               csize := 1;
                               fgap  := 2;
                                 if tsect < 7 then fgap := Gaps35lo[7]
                                    else
                                    if tsect < 14 then fgap := Gaps35lo[tsect];
                                 if tsect > 10 then  SetLD
                                               else  Set35;

                               SectorLimit := 9 ;

                   end;   { 3'5 lo }
               end;  { 1440 drive }

         2,3: begin  { 1200 drive }
                media := $F0;

                if LongInt(SSize * tsect) > 11 * 512 then
                   begin  { 12  hi }
                               csize := 1;
                               fgap  := 2;
                               fgap  := Gaps12hi[tsect];
                               media := Media12hi[tsect];
                               SetHD;

                               SectorLimit := 15 ;

                   end    { 12  hi }
                     else
                   begin  { 12  lo }

                               csize := 2; {csize := 1;}
                               fgap  := 2;

                                 if tsect in [7..11] then
                                   begin
                                     Media := Media360[tsect];
                                     fgap  := Gaps360 [tsect];
                                   end;

                               if tracks + btrack > 43
                                        then  SetLD
                                        else  Set525;

                               SectorLimit := 9 ;

                   end;   { 12  lo }

            end; { 1200 drive }

           end; { case }

             bfkey1:=' ';

            { Setup direct params only if we cant properly
              detect drive }

        case bfkey2 of
            'l': SetLD;
            'h': SetHD;
            'd': Set525;
            '3': Set35;
        end; { case }

  {______RESET FLOPPY DRIVE_______}
  { and set updated format params }

                DL := drvnum;
                AH := 0;
                intr($13,regs);

                {===========}


        { Setup Standart types for Cluster Size & Root Entries }

        if Heads = 1  then
             begin
                   Csize := 1;
                   rSize := 64;
             end;
        if Tsect >14 then
             begin
                   Csize := 1;
                   rSize := 224;
             end;

        If Tsect <15 then
             begin
                   Csize := 2;
                   rSize := 112;
             end;
       { All standart types will sets correctly }



        if fgap1>0   then fgap := fgap1;    { user gap }

        if U_ClustSZ > 0  then csize := U_ClustSZ ;  { user cluster size }
        if U_Roots   > 0  then rsize := U_Roots;

        if tsect < 10 then  media := media or pred(heads);

                                            { add media for old disk types }

        if medias>0  then media := medias;  { set preselected media }


        if set8B > 0 then
                 mem[$0:$48B] := set8B; { data & step rate }
        if set90 > 0 then
                 mem[$0:$490+drvnum] := set90; { disk media state }
        if set92 > 0 then
                 mem[$0:$492+drvnum] := set92; { disk media state at start }
        if set8F > 0 then
                 mem[$0:$48F] := set8F; { data & step rate }

       if interl=0 then
         {if fgap>=$1D then interl := 1 else interl := 2;}

         if Tsect > SectorLimit
               then
                    Interl := 2
               else
                    Interl := 1;

       {  if fgap > $1C then interl := 1 else interl := 2; }

                { seek to track }

             Try := 3 ;

              repeat
                AH := 0;
                DL := Drvnum;

                 asm
                  sub ax,ax
                  int 28h
                 end;


                intr($13,regs);
                dec(Try);
                if Try = 0 then Break;
              until Flags and Fcarry = 0;

             (*
             Try := 5 ;


              repeat
                AH := $0C;
                DL := drvnum; { drive }
                CH := BTrack; { track }
                DH := 0;      { head  }
                intr($13,regs);
                dec(Try);
                if Try = 0 then Break;
              until Flags and Fcarry = 0;
             *)

     end;
    end;

function   tfmt.GetStatusString;
var S : string[40];
   begin
           case Code of

             stInit:    S := 'Initialize';
             stAnalyze: s := 'Analyzing drive...';
             stFormat:  s := 'Formatting drive...';
             stQuick:   s := 'Quick formatting drive';
             stVerify:  s := 'Verifying drive';
             stSystem:  s := 'Writing system areas...';
             stBoot:    s := 'Transferring system files...';
              else  s :='';

           end;
     GetStatusString := S;

   end;

function   tfmt.GetErrorString;
var S : string[40];
   begin
          case Code of
                0:s:='';
                1:s:='Bad cmd';
                2:s:='Bad adress mark';
                3:s:='Disk is write-protected';
                4:s:='bad sector id';
                5:s:='reset err';
                8:s:='DMA err';
                9:s:='DMA overrun';
               $b:s:='marker of bad trk';
              $10:s:='CRC err';
              $11:s:='CRC corrected';
              $20:s:='controller err';
              $40:s:='bad seek';
              $80:s:='timeout';
              $bb:s:='undef err';
              $ff:s:='sence err';
              else s:='??? err no. '+Itos(Code);
             end;

       GetErrorString := S ;

   end;

function  tfmt.CheckIOError;
    begin
            with regs do
             begin

             CheckIoError := 0;
                  if Flags and Fcarry = 0 then exit;
         {
           with regs do
           Writeln('  ',S,' at Cyl:',CH:2,' Head:',DH:2,' Sec:',CL:2);
         }
             CheckIoError := AH;
             Flags := Flags and (not Fcarry);
    end;
  end;



function    tfmt.VerifyTrack(trk,head,sec,secnum : byte):byte;
{var Buf : array [1..22,0..512] of byte; }
    begin
        with boots,regs do
        begin

        AH := 4; { 4 }
        DL := drvnum ;
        DH := head;
        CH := trk;
        CL := sec;
        AL := secnum;
        ES := Seg(TrDsc);
        BX := Ofs(TrDsc);

        asm int 28h end;
        {in13 := True;}
        intr($13,regs);
        {in13 := False;}
        asm int 28h end;

        { verify track }

       if  Flags and Fcarry <> 0 then
         VerifyTrack := AH
        else
         VerifyTrack := 0;

        end;
    end;


function    tfmt.ReadTrack(trk,head,sec,secnum : byte; var Buf):byte;
    begin

      with regs do
        begin

        AH := 2;
        DL := drvnum ;
        DH := head;
        CH := trk;
        CL := sec;
        AL := secnum;
        ES := Seg(Buf);
        BX := Ofs(Buf);

        asm int 28h end;


        intr($13,regs);

        asm int 28h end;

        { read track }

       if  Flags and Fcarry <> 0 then
         ReadTrack := AH
        else
         ReadTrack := 0;

        end;
    end;


function    tfmt.FormatTrack;
    begin
        with boots,regs do
        begin


        asm int 28h end;

        {interlive(trk,head);}

        AH := 5;
        DL := drvnum ;
        DH := head;
        CH := trk;
        CL := 1;
        AL := 1;
        ES := Seg(trdsc);
        BX := Ofs(trdsc);
         {in13 := True;}
        intr($13,regs);
         {in13 := False;}
        asm int 28h end;

        { format track }

        FormatTrack := CheckIOError;

        end;
    end;

  (*
function    tfmt.FormatTrack;
var I : byte ;
    begin
        with boots,regs do
        begin

        interlive(trk,head);

        AH := 5;
        DL := drvnum ;
        DH := head;
        CH := trk;
        CL := 1;
        AL := 1;
        ES := Seg(trdsc);
        BX := Ofs(trdsc);
        intr($13,regs);

        if Flags and Fcarry > 0 then
          begin
           formattrack := AH; Exit ;
          end;

 {  for I:=1 to Boots.tsect do}

    begin

        AH := 4;
        AL := Boots.Tsect;
        CL := 1;
        intr($13,regs);

        if Flags and Fcarry > 0 then
          begin
           formattrack := AH; Exit ;
          end;

    end;
        { format track }

        FormatTrack := CheckIOError;

        end;
    end;

    *)
procedure   tfmt.Interleave(trk,head : byte);

var I,J,K,NextSector,SHFT : integer;


    begin

    with BootS,DBT do
      begin

        EOT := tsect ;   {   set DBT highest sector number }

     for I:=1 to tsect do
         TrDsc[I,1] := $FF ;  { zero start }

       J:=1;
   for I:=1 to tsect do
     begin

       { prepare sector table }
          NextSector :=  J;

          if  Shifts>1 then
           for K:=1 to Shifts do
             begin
               Dec(NExtSector);
               if NextSector = 0 then
                  NextSector := tsect;
             end;

          TrDsc[NextSector,1] := trk ;
          TrDsc[NextSector,2] := head ;
          TrDsc[NextSector,3] := I + BsectD;

           case SSize of
               128:  TrDsc[NextSector,4] := 0;
               256:  TrDsc[NextSector,4] := 1;
               512:  TrDsc[NextSector,4] := 2;
              1024:  TrDsc[NextSector,4] := 3;
                else TrDsc[NextSector,4] := 2;
           end;



       { next sector }

  {        inc(j); }

  {      if fgap>=$1D then continue; }

         inc(j);
         if interl < 2 then continue ;
         inc(j);
         if J>tsect then j:=2;
    {
      if interl < 1 then continue;

       for K:=1 to interl do
        begin
          inc(j);
          if J>tsect then j:=1;
        end;
     }

     end;
    end;
  end;


    function Tfmt.UserInterrupt;
       var Delta : longint ;
       begin
        UserInterrupt := False;
        if not ScanEvents then Exit ;
          Delta := Timer ;
          UserInterrupt := FormatDialog(fdUserInterrupt) <> fdContinue;
          if Timer - Delta > 0 then
           begin
            Delta := Timer - Delta;
            inc(T_start,Delta);
           end;
       end;


  function tfmt.CheckErrors : boolean;

      begin

        CheckErrors := False;

        if LO(IO_Error) = 0 then Exit;

        case HI(IO_Error)
            of
               0 :  { Standart Code }
                    Exit ;

              $1 :  { Format Erorrs }
                    case LO(IO_Error) of
                         3  : FormatDialog(fdDiskProtected);
                        $80 : FormatDialog(fdNoDiskInDrive);
                           else
                              FormatDialog(fdHArdwareError);
                    end; { Case }

              $2 :  { Verify Erorrs }
                    case LO(IO_Error) of
                         0  : Exit;
                        $81 : FormatDialog(fdTrack0Bad);
                           else
                              Exit ;
                    end; { Case }

              $4 :  { BadSector erors }
                    case LO(IO_Error) of
                         0  : Exit ; { No Actual Verify }
                         3  : Exit ; { Bads Marked }
                         1  : FormatDialog(fdBadInterleave) ;
                           else
                              Exit ;
                    end; { Case }

              $8 :  { Write Sys areas Erorrs }
                    case LO(IO_Error) of
                         0  : Exit;
                           else
                              FormatDialog(fdErrorSysAreas) ;
                    end; { Case }


             $80 :  { User Interrupt }
                          ;

        end; { Case }

        CheckErrors := True;

      end;



function    tfmt.FormatMedia;

   var CurTrk : word ;
       CurSide : byte ;
       szz : word;
       I : byte;
       Progress : longint ;






    Procedure CalcTime ;
       begin
          if timer - t_start < 0 then t_start := timer - t_elaps;
          { prevent from timer overflow during 24h period }
          t_elaps := timer - t_start ;
          if I_formatted = 0 then exit ;
          t_estim := Round( t_elaps / I_formatted * tracks * heads );

       end;




 function   FormatTrackWithVerify(FCurTrk , FCurSide : byte ) : Word;
 var  Counter : byte;
      IO_Err  : Word;
     begin

             I_operation := flFormat ;
             UpdateParams;

             if FCurTrk > 0 then
                   begin
                     IO_Err := FormatTrack(FCurTrk,FCurSide) or $100;
                     FormatTrackWithVerify := IO_Err;
                     if IO_Err = $100 then
                         begin

                           {$IFNDEF FAST}
                           I_operation := flVerify ;
                           UpdateParams;
                           {$ENDIF}

                           {
                           if UserInterrupt then
                                begin
                                  FormatTrackWithVerify := $8001;
                                  Exit;
                                end;
                            }
                           IO_Err := VerifyTrack(FCurTrk,FCurSide,1,Boots.tsect);
                              FormatTrackWithVerify := IO_Err or $200;
                         end;


                     Exit;
                   end;

             Counter := 4 ;

           Repeat
             IO_Err := FormatTrack(FCurTrk,FCurSide);
             if IO_Err > 0
                 then
                  begin
                    FormatTrackWithVerify := IO_Err or $100;
                    Exit ;
                  end;

             I_operation := flVerify ;
             UpdateParams;

             if UserInterrupt then
                                begin
                                  FormatTrackWithVerify := $8001;
                                  Exit;
                                end;

             IO_Err := VerifyTrack(FCurTrk,FCurSide,1,Boots.tsect);

             DEC(Counter);
             if Counter = 0
                  then
                   begin
                    FormatTrackWithVerify := $281;
                    Exit;
                   end;

            { I_operation := flFormat ;
             UpdateParams;
             }

           Until IO_Err = 0 ;

                 FormatTrackWithVerify := $200;

     end;


     procedure NewInterleave;
     var I: byte;
      begin

         for I:=1 to Boots.Tsect do
           begin
             TrDsc[I,1] := CurTrk;
             TrDsc[I,2] := CurSide;
           end;
      end;



   begin




{_______format diskette_________}

{ if quick format then dosprep }


        I_Bads := 0 ;

        c_Terminate := False;  { no Events Available }

        FormatMedia := False ;

        Interleave(0,0) ;      { Build Sectors Descriptors }


        with    Boots,Regs do
          begin
      {
       i_Size := longint(HeadS) *
                 longint(tsect) *
                 longint(tracks) *
                 longint(ssize) ;
       }
        {
           Writeln(' Formatting ',char(65+drvnum),': for ',
             szz :4,'k');
        }


       t_start  := timer ;
       t_elaps  := 0;
       t_estim  := 0;

       I_SysSpace := Longint(DataStart) * SSize ;


       if fOptions and foSystemDisk > 0 then
         begin

           inc( I_SysSpace,
           Longint(MoreDiv(S_IoSYS.Size,CSize * Ssize)) * Csize * Ssize  );

           inc( I_SysSpace,
           Longint(MoreDiv(S_MsDos.Size,CSize * Ssize)) * Csize * Ssize  );

           inc( I_SysSpace,
           Longint(MoreDiv(S_Command.Size,CSize * Ssize)) * Csize * Ssize );

         end;


        for CurTRK := btrack to btrack+Pred(tracks)
          do begin
                {Write(#13,'Track :',curtrk:2,' head:0');}
                I_Formatted := ( CurTrk - Btrack ) * Heads ;
           For CurSide := 0 to Pred(Heads) do

           begin
                NewInterleave;

                I_track     := CurTrk ;
                I_Head      := CurSide ;
                I_operation := flFormat ;

             if fMode in [fmSafeFormat,fmFastFormat] then
                I_operation := flVerify;  { verify only }


             if fMode = fmQuickFormat then

              begin
                I_operation := flVerify ;
                UpdateParams;
                if UserInterrupt then Exit;
              end  {  Quick -format }


               else     { Non - Quick Format }

              begin
                CalcTime;
               { UpdateParams; }

               {$IFNDEF FAST}
                if UserInterrupt then Exit;
               {$ENDIF}

                 case fMode of

                     fmDosFormat,fmNonDos:
                           begin
                           IO_Error := FormatTrackWithVerify(CurTrk,CurSide);
                            if IO_Error and $FF > 0 then
                                   begin
                                       If CheckErrors then Exit;
                                       IO_Error := MarkBadSectors(CurTrk,curSide);
                                       If CheckErrors then Exit;
                                   end;
                               end;


                     fmSafeFormat,fmFastFormat:
                               begin
                                 {$IFNDEF FAST}
                                 UpdateParams;
                                 if UserInterrupt then Exit;
                                 {$ENDIF}

                                 if VerifyTrack(CurTrk,CurSide,1,tsect) > 0 then
                                     begin

                                     IO_Error := FormatTrackWithVerify(CurTrk,CurSide);

                                     If CheckErrors then Exit;

                                     if UserInterrupt then Exit;
                                       if IO_Error > 0  then
                                         begin
                                          IO_Error := MarkBadSectors(CurTrk,curSide);
                                          If CheckErrors then Exit;
                                         end;  { mark bad track }

                                     end;
                               end; { SafeFormat }
                             end; { Case }


                   end; { non - quick mode }

                       inc(I_Formatted);


              Inc ( Shifts , ShiftH );



             end;  { Heads Loop }


             Inc ( Shifts , ShiftT );


               {$IFDEF FMTDBG}
              if keypressed then
               begin
                 asm
                  sub ax,ax
                  int 16h
                 end;
                break;
               end;
               {$ENDIF}


             end;   { tracks loop }
         end;

         FormatMedia := True ;

   end;






 {
  verify ===

    if VerifyTrack <> 0 then

     for I:=1 to tsect do
      if CheckSector then MarkCluster
    CheckStart :=  GetLogSector()

 }



Function Tfmt.Cluster(Sector: Word):Word;
 Var h: byte;
   begin
     Cluster := $FFFF;
     if Sector < DataStart then Exit;

   with BootS do
     Cluster := Word( Sector - DataStart ) div Word ( Csize ) + 2 ;
   {
     Cluster:=((Sector-(bpb.rde shr 4)-(bpb.spf shl 1)-1) div Word(bpb.spc))+2;
   }
   end;



procedure nullcluster( cluster:word ; var FAT );assembler;
      asm
                push    es
                les     di, FAT

                mov     ax,cluster  ;
                cmp     ax,2710h
                jae     @@done

                mov     bx,ax
                shl     bx,1
                add     bx,ax
                shr     bx,1
                test    ax,1
                jnz     @@loc_2
                mov     ax,0F000h
                jmp     @@loc_3
@@loc_2:
                mov     ax,000Fh
@@loc_3:
                and     word ptr ES:[DI+BX],AX
@@done:
                pop     es
      end;

{
procedure markcluster( cluster:word ; var FAT );
var P:pbArray;
      begin

      end;
}
procedure markcluster( cluster:word ; var FAT );assembler;
      asm
                push    es
                les     di, FAT

                mov     ax,cluster  ;
                cmp     ax,2710h
                jae     @@done

                mov     bx,ax
                shl     bx,1
                add     bx,ax
                shr     bx,1
                add     di,bx       { point to cluster }
                test    ax,1
                jnz     @@loc_2
                mov     ax,0FF7h
                jmp     @@loc_3
@@loc_2:
                mov     ax,0FF70h
@@loc_3:
                or      word ptr ES:[DI],AX
@@done:
                pop     es
      end;

function  getcluster ( cluster:word ; var FAT ):word;assembler;
     asm
                push    es
                les     di, FAT

                mov     ax,cluster  ;
                cmp     ax,2710h
                jae     @@done

                mov     bx,ax
                shl     bx,1
                add     bx,ax
                shr     bx,1
                add     di,bx
                mov     dx,word ptr ES:[DI]
                test    ax,1
                jnz     @@loc_4
                and     dx,0FFFh
                jmp     @@loc_5
@@loc_4:
                mov     cl,4
                shr     dx,cl
@@loc_5:
                mov     ax,dx
@@done:
                pop     es
 end;


function    tfmt.MarkBadSectors(trk,head : byte):word;
var CurSector : word ;
    CurLogSector : word ;
    Result : word ;
    begin

         MarkBadSectors := $400 ;  { No Errors }
         Result := $400 ;

            if FAT = nil then exit;


         with BootS,Regs do begin

              CurLogSector :=Pred(GetLogSector(trk,head,1,Boots));

            for CurSector := 1 to Tsect do
             begin
                inc(CurLogSector);

              if CurLogSector < DataStart then Continue;

              if fOptions and foMarkTrack = 0 then
                begin
                  Result := Result or $1 ;
                  if VerifyTrack(trk,head,CurSector,1) = 0 then Continue;
                  Result := Result or $2 ;

                  if CurSector and $3 = 3 then
                      if UserInterrupt then
                          begin
                            MarkBadSectors := $8001 ;
                            exit;
                          end;

                end;


                 if fMode = FmNonDos then
                     begin { NON-DOS }
                        Inc(I_bads)  ;  {  BadSectors Counter }
                        UpdateParams;
                     end   { NON-DOS }
                      else
                     begin { DOS Mode }


                        MarkCluster( Cluster( CurLogSector ) ,FAT^);

                        Inc(I_bads,CSize)  ;  {  BadCluster Counter }

                        UpdateParams;

                        if Csize > 1 then
                            begin { skip all remain sectors
                                    in this bad cluster }
                               inc(CurLogSector,CSize-1);
                               inc(CurSector,Csize-1);
                               if CurSector > tsect  then Break;

                            end;


                   end; { DOS mode }

             end; { all sectors in current track }


             MarkBadSectors := Result ;

                        {
                         $400  no actual verify ;
                         $401   verify , but no bads ;
                         $403   verify , but there is bads ;
                        }


         end;  { with }
    end;


procedure   tfmt.CalculateBootFatRoot;

  var  SecRemain : word ;
       B_Track,B_Head,B_Sector : byte;


 function  GetSerial : longint ;
    var dt:datetime;
        sec100,week:word;
        S : longint ;
    begin
        with dt do begin
           getdate(year,month,day,week);
           gettime(hour,min,sec,sec100);
           packtime(dt,S);
           GetSerial := S ;
        end;
    end;



    begin

{_______prepare system area [boot, FAT, root  }

      with BootS,DBT,regs
        do begin


                HeadC  := {succ(heads);} heads;

                TopSec := HeadC * tsect * tracks ; { total sectors }

                 if fMode = fmNonDos
                    then
                      begin
                       Roots := 0;
                       FatSz := 0;
                       DataStart := 0;
                       TotalClusters := 0;
                       exit;
                      end;

                RootS  := ( Rsize * 32 ) div Ssize ;  { root size }

                SecRemain := (TopSec - Bsize - RootS);  { total remain }

                FatSz := MoreDiv(Succ( (SecRemain div CSize)
                       + MoreDiv(SecRemain,2 * Csize)),SSize);

                      { fat size in sectors }
                      { remain/sectors_in_cluster => total clusters }
                      { clusters * size_in_bytes / bytes_per_sector }

                SecRemain := SecRemain - FSize * FatSZ ;
                FatSz := MoreDiv(Succ( (SecRemain div CSize)
                       + MoreDiv(SecRemain,2 * Csize)),SSize);


                DataStart := Bsize + FSize * FatSz + RootS; { 1st free sector }
                TotalClusters := SecRemain div CSize ;

                Dec( TopSec , SecRemain mod CSize );


                I_Size := Longint(TopSec) * Longint(SSize) ;




                if FVlabel<>'' then
                       Move(FVlabel[1],Boots.Boot_Code[43],11);


                GetAbsSector(DataStart - RootS ,BootS,B_Track,B_Head,B_Sector);
                boot_code[$D1]:=B_Sector;
                boot_code[$D2]:=B_Track;
                boot_code[$D5]:=B_Head;

                GetAbsSector(DataStart,BootS,B_Track,B_Head,B_Sector);
                boot_code[$FF]:=B_Sector;
                boot_code[$100]:=B_Track;
                boot_code[$102]:=B_Head;
                boot_code[$137]:=DataStart;

                if (tsect<11) and (TopSec > 850) then BootD[2]:=$3C;

                I_Serial := GetSerial ;


                {  Set Serial Data  }

                Move(I_Serial,boot_code[$27],SizeOf(I_Serial));


       end; { with }
    end;




 function  tfmt.WriteBootFatRoot : boolean ;

  var  SecRemain : word ;
       buf : array [0..1023] of byte ;
       I : integer;
       CNT  : byte ;
       Quit : boolean;
    begin

{_______prepare system area [boot, FAT, root  }

      with BootS,DBT,regs
        do begin

                WriteBootFatRoot := false ;

                EOT := tsect;

                I_operation := flWrite ;
                UpdateParams;

              { for I:=2 to TotalClusters do
                  begin
                   if (GetCluster(I,FAT^)=$0) then continue;
                   if (GetCluster(I,FAT^)=$FF7) then continue;
                     writeln('!!!!!!! in',I);
                   end; }

                { reset drive }
                DL := drvnum;
                AX := 0;
                intr($13,regs);




              with regs do begin
                {
                write(#13#10' wr boot ...');
                 }

               CNT := 0 ;
               Quit := false;

               repeat

                GetAbsSector(0,BootS,CH,DH,CL);
              (*
                DL := Drvnum;
                AH := $C;
                intr($13,regs);
              *)
                AH := $3;
                AL := 1;
                DL := drvnum;
                ES := Seg(BootS);
                BX := Ofs(BootS);

                 intr($13,Regs);

                if Flags and FCarry <> 0 then
                    begin
                     inc(cnt);
                     if cnt = 3 then Quit := True;
                    end
                     else Quit := True;

              until Quit ;

                 IO_Error := CheckIOError or $800;
                 If CheckErrors then Exit ;

              end;


              GetAbsSector(0,BootS,CH,DH,CL);
                AH := $2;
                AL := 1;
                DL := drvnum;
                ES := Seg(BootS);
                BX := Ofs(BootS);
                intr($13,Regs);

                IO_Error := CheckIOError or $800;
                If CheckErrors then Exit ;


        if FAT<>Nil then

           if fMode = fmQuickFormat Then

              begin

              with regs do
              for I:=1 to FatSz do
                begin
                     GetAbsSector(Pred(Bsize + I),BootS,CH,DH,CL);
                     AH := $2;
                     AL := 1;
                     DL := drvnum;
                     ES := Seg(FAT^);
                     BX := Ofs(FAT^[Pred(I)*Ssize]);
                     intr($13,regs);

                     IO_Error := CheckIOError or $800;
                     If CheckErrors then Exit ;

                end;


              for I:= 2 to TotalClusters do
                 begin
                   if (GetCluster(I,FAT^)=$FF7) then continue;
                      NullCluster(I,FAT^);
                 end;



              end;  { Quick Format Drive }




              with regs do
               for I:=1 to FatSz do
                begin
                  {
                     write(#13#10' wr #1 fat ...#',I:2);
                  }
                     GetAbsSector(Pred(Bsize + I),BootS,CH,DH,CL);

                     AH := $3;
                     AL := 1;
                     DL := drvnum;
                     ES := Seg(FAT^);
                     BX := Ofs(FAT^[Pred(I)*Ssize]);
                     intr($13,regs);

                     IO_Error := CheckIOError or $800;
                     If CheckErrors then Exit ;


                if fsize=2 then
                 begin
                     {
                      write(#13#10' wr #2 fat ...#',I:2);
                     }

                      GetAbsSector(Pred(Bsize + I + FatSz),BootS,CH,DH,CL);
                      AH := $3;
                      AL := 1;
                      DL := drvnum;
                      ES := Seg(FAT^);
                      BX := Ofs(FAT^[Pred(I)*Ssize]);
                      intr($13,regs);

                      IO_Error := CheckIOError or $800;
                      If CheckErrors then Exit ;


                 end;

                end;


               if BSize>1 then
                  begin

                   {
                      fill zero data before fat

                      for I:=1 to (fillsz(pred(bootsz)) shl 1) do
                       fat[I] := 0;
                   }

                   end;

           with regs do
            for I:=1 to RootS do
             begin

                GetAbsSector(pred(Bsize + FatSz * fsize + I),BootS,CH,DH,CL);
                 fillchar(buf,sizeof(buf),0);
                AH := $3;
                AL := 1;
                DL := drvnum;
                ES := Seg(Buf);
                BX := Ofs(Buf);
               {
                write(#13#10' wr root ...#',I:2,'           ');
               }
                intr($13,regs);

                IO_Error := CheckIOError or $800;
                If CheckErrors then Exit ;

             end;

                WriteBootFatRoot := True ;

       end; { with }
    end;



function    tfmt.FindSystemFiles;

var S : string[80] ;

    S1,S2 : Boolean ;

    F : File ;

   begin
         FindSystemFiles := False ;


      with S_Command do
       begin
       S := GetEnv('COMSPEC');
         if os210 then S := 'C:\COMMAND.COM';
         Name := GetName(S);
         Path := GetPath(S);
       If Not FileExists(Path+Name) then Exit ;

        Assign(f, Path + Name );
        Reset(f,1);
        size := FileSize(f);
        close(f);

       end;

       S1 := FileExists('C:\'+IOSYS) ;
       S2 := FileExists('C:\'+IOSYS1);

       If Not (  S1 or S2 )  then Exit ;

       with S_IOSYS do
       begin
        if S1 then Name := IOSYS
              else Name := IOSYS1;
                   Path := 'C:\';
        {If Not FileExists(Path+Name) then Exit ; }

        Assign(f, Path + Name );
        Reset(f,1);
        size := FileSize(f);
        close(f);


       end;

       with S_MSDOS do
       begin
        if S1 then Name := MDOS
              else Name := MDOS1;
                   Path := 'C:\';
       If Not FileExists(Path+Name) then Exit ;

        Assign(f, Path + Name );
        Reset(f,1);
        size := FileSize(f);
        close(f);


       end;

       FindSystemFiles := True ;

   end;


procedure   tfmt.transferSystem;
var

   WH : string[4];

  begin
       WH := char(drvnum+65)+':\';
       With S_IOSYS do
       CopyFile(PATH+Name,WH+Name);
       With S_MSDOS do
       CopyFile(PATH+Name,WH+Name);
       With S_Command do
       CopyFile(PATH+Name,WH+Name);
  end;


function    tfmt.runFormat;


    var R : byte ;

   begin
   {
      write('format in progress... press a key...');
      asm
        sub ax,ax
        int  16h
      end;
     writeln;
    }

         RunFormat := 255 ;

         if fOptions and foUncond = 0 then
         SetStatus(stAnalyze);

          Case fMode of

           fmDosFormat : begin
                          {if unconditional}
                          if fOptions and foUncond = 0 then
                          SameType;
                           end;

           fmSafeFormat,fmFastFormat: begin

                      if (fOptions and foUncond <> 0)
                       or ( not SameType ) then
                              begin
                               fMode := fmDosFormat;
                               SetAdditionalData; { add 'With optimize' text }
                              end;

                           end;
           fmQuickFormat: begin
                           R := 0;
                           repeat
                             if not SameType then Break;
                             if not IsDOS then Break;
                             R := 1; Break;
                           until false;

                           if R=0 then
                            begin
                              SetStatus(stNone);
                              FormatDialog(fdNQuickFormat);
                              Exit;
                            end;

                            CopyQuickBoot;

                          end;

           fmNonDos : begin

                          FormatDialog(fdNonDosFormat);
                          {if unconditional}
                          if fOptions and foUncond = 0 then
                          SameType;

                          fOptions := { Mask all related bits }
                          fOptions  and ( foUncond + foMarkTrack ) ;


                           end;



              end; { case }

          {if unconditional}

          if fOptions and foUncond = 0 then
           if IsDOs then
             if CheckFilesOnDisk then
                begin
                   SetStatus(stNone);
                   Exit ;
                end;


          if fOptions and foSystemDisk > 0 then
                 if Not FindSystemFiles then
                    begin
                     FormatDialog(fdNoSystemFiles);
                     exit;
                    end;



          SetStatus(stInit);
              {
               getdrv(Drvnum);
              }

             {  if FormatDialog(fdInsertNewDisk) <> fdContinue then exit;}

               SetupHardware;

               CalculateBootFatRoot;

            { NON DOS MODE }

           if fMode = fmNonDos then
                begin
                   SetStatus(stNone);
                   if FormatMedia then
                   RunFormat := fdDiskFormatted;
                   exit;
                end;

                initFAT;

          {SetStatus(stFormat);}
           SetStatus(stNone);

            if not FormatMedia then
               begin
                  DoneFAT;
                  exit;
               end;

          SetStatus(stSystem);
               if not WriteBootFatRoot
                   then
                       begin
                         SetStatus(StNone);
                         DoneFAT ;
                         Exit ;
                       end ;

                DoneFAT;

            if fOptions and foSystemdisk > 0 then

             begin
                SetStatus(stBoot);
                TransferSystem;
             end;

          SetStatus(StNone);

      RunFormat := fdDiskFormatted;

   end;


   {$IFDEF FMTDBG}
var FM : PFMT;

 begin
    new(fm,init);
   {  fm^.getdrv(0); }
    fm^.run;
    dispose(fm,done);
  {$ENDIF}
 end.

