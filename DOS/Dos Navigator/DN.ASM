;/////////////////////////////////////////////////////////////////////////
;/
;/  Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs
;/
;/  This programs is free for commercial and non-commercial use as long as
;/  the following conditions are aheared to.
;/
;/  Copyright remains RIT Research Labs, and as such any Copyright notices
;/  in the code are not to be removed. If this package is used in a
;/  product, RIT Research Labs should be given attribution as the RIT Research
;/  Labs of the parts of the library used. This can be in the form of a textual
;/  message at program startup or in documentation (online or textual)
;/  provided with the package.
;/
;/  Redistribution and use in source and binary forms, with or without
;/  modification, are permitted provided that the following conditions are
;/  met:
;/
;/  1. Redistributions of source code must retain the copyright
;/     notice, this list of conditions and the following disclaimer.
;/  2. Redistributions in binary form must reproduce the above copyright
;/     notice, this list of conditions and the following disclaimer in the
;/     documentation and/or other materials provided with the distribution.
;/  3. All advertising materials mentioning features or use of this software
;/     must display the following acknowledgement:
;/     "Based on Dos Navigator by RIT Research Labs."
;/
;/  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
;/  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;/  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;/  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
;/  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;/  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;/  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;/  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
;/  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;/  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
;/  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;/
;/  The licence and distribution terms for any publically available
;/  version or derivative of this code cannot be changed. i.e. this code
;/  cannot simply be copied and put under another distribution licence
;/  (including the GNU Public Licence).
;/
;//////////////////////////////////////////////////////////////////////////

; Interface data:
;     Note that command line must be in PASCAL format and contain 0Dh at
;     line end. 0Dh mustn't be included in string length.
;
; 2F func 99h
;     sbf's     0  return info
;               1  return pointer 2 commandline
;               2  set 'true' DN's errorlevel
;               3  set how2run
;               4  set timer
;               5  get timer
;               6  get/set misc info

; ClearKeyboard   EQU    1

EPB             struc
Environment     dw     0
CMD_Offset      dw     80h
CMD_Seg         dw     0
FCB1_Offset     dw     5Ch
FCB1_Seg        dw     0
FCB2_Offset     dw     6Ch
FCB2_Seg        dw     0
EPBLength       db     0Eh
EPB             ends

                .model tiny
                .code
                org    100h

Start:          jmp    @Begin
                db     63 dup ('s')

Int2Fentry:     cmp    ah,99h
                je     @@MyCall
@@Old:          db     0EAh
OldInt2F:       dw     0,0
@@MyCall:       cmp    al, 6                 ; supported function
                ja     @@Old
                jz     @@My6                 ;
                cmp    al, 5
                jz     @@My5                 ;
                cmp    al, 4
                jz     @@My4
                or     al,al                 ; get info
                jnz    @@My1                 ; al-NumRun
                mov    ax,word ptr cs:NumRun ; ah-FirstRun
                mov    cl,byte ptr cs:ExecErrl;cl-child errorlevel
                mov    bx,'DN'               ;
                mov    dx,2151h              ; version num II - 1.51
                iret
@@My1:          dec    al
                jnz    @@my2                 ; return pointer
                mov    ax,cs                 ; to cmd line
                mov    es,ax                 ; ES:BX
                mov    bx,offset CmdLine     ;
                iret
@@My2:          dec    al                    ; set 'true'
                jnz    @@my3                 ; errorlevel
                mov    al,cl                 ; of DN.PRG
                mov    ah,1                  ; in cl...
                mov    word ptr CS:_DN_Errl,ax
                iret
@@My3:          mov    byte ptr cs:How2run,Cl; How2run? dos/or 2Eh??
                iret
@@My4:          mov    word ptr CS:DNTimer, cx
                mov    word ptr CS:DNTimer+2, dx
                iret
@@My5:          mov    cx, word ptr CS:DNTimer
                mov    dx, word ptr CS:DNTimer+2
                xor    ax, ax
                mov    word ptr CS:DNTimer, ax
                mov    word ptr CS:DNTimer+2, ax
                iret
@@My6:          mov    cx, word ptr CS:DN_Misc
                xor    ax, ax
                test   dx, 8000h
                jz     @@My6_1
                mov    CS:DN_Misc, dx
@@My6_1:        iret

ClearKBD        MACRO
                IFDEF ClearKeyboard
                sub    ax,ax
                mov    es,ax
                mov    ax,es:[41Ah]
                mov    es:[41Ch],ax
                ret
                ENDIF
                ENDM

DNinfo          db     'DN'
NumRun:         db     1
FirstRun        db     1
RunErrl         db     0
_DN_Errl        db     0
_DN_was_Errl    db     0
ExecErrl        db     0
How2Run         db     0    ; by exec or via 2Eh?
DNTimer         dd     0
DN_Misc         dw     0    ; Miscellaneous information

; Run DN.PRG ...
RunDN:          mov    ax,cs
                mov    ds,ax
                mov    es,ax
                mov    DNEPB.CMD_Offset,80h
                mov    DNEPB.CMD_Seg,AX
                mov    ax,cs:[2Ch]
                mov    DNEPB.Environment,ax
                mov    dx,offset DNPath
                mov    bx,offset DNEPB
                mov    ax,4B00h
                int    21h
                jc     ExecError
; Query DN.PRG execution status ...
                mov    cs:FirstRun,0              ; not for first time...
                sub    ax,ax                      ; if DN sets errorllevel
                xchg   ax,word ptr CS:_DN_Errl    ; himself, then
                or     ah,ah                      ; assume this is
                jnz    @@Errl                     ; true, else
                mov    ah,4dh
                int    21h
@@Errl:         cmp    al,1                       ; believe in DOS
                jne    @halt                      ; errorlevel...
; Execute a DOS command ...
@@RunCMd:
                mov    ax,3301h
                mov    dl,1
                int    21h
                mov    ax,cs
                mov    ds,ax
                mov    es,ax
                sub    ax,ax
                xchg   al,How2Run
                cmp    al,1
                jne    @@RunByDos
                mov    SI,offset CMDline
                int    2Eh
                sub    al,al    ; f..d errorlevel!
                jmp    short @@RunDone
@@RunByDOS:
                mov    al,byte ptr CmdLine
                add    al,3
                mov    byte ptr COMMANDparm,al
                mov    byte ptr CmdLine,' '
                mov    bx,offset DNEPB
                mov    DNEPB.CMD_Offset,offset COMMANDparm
                 ; lds    dx,COMSPECptr
                mov    dx,CS:COMSPECptr ; Get Comspec ptr
                mov    ax,4B00h
                int    21h
                mov    ah,4dh                  ; Save errorlevel
                int    21h                     ; of child process
@@RunDone:      mov    byte ptr cs:ExecErrl,al ;
                mov    ax, 3301h        ; Ctrl-Break off...
                xor    dl, dl           ;
                int    21h              ;
; ... and return back to DN ...
;                ClearKbd                ; Clear Keyboard stack
                jmp    RunDN            ; after execution child program

ExecError:      mov    dx,offset CanNotRun
                mov    ah,9
                int    21h
                mov    al,-1
@Halt:          push   ax

                ;mov    ax,CS:OrigEnv    ; restore local enviropment
                ;mov    CS:[2ch],ax      ;

;                ClearKbd                 ; Clear keyboard when exit from DN
                mov    ax,252Fh
                lds    dx,dword ptr cs:OldInt2F
                int    21h
                pop    ax       ; errorlevel
                mov    ah,4ch
                int    21h
COMSPECptr      dw     0
CanNotRun       db     'Not able to run DN.PRG',0dh,0ah,7,'$'
COMMANDparm     db     ' /C'
CmdLine:        db     4,'exit',13,256-9 dup ('ú')
DNEPB:          EPB    <>
DNPath:         db     160 dup (0) ; DN PATH and COMSPEC are here ...
COMSPEC         db     80 dup (0)  ; Temporary comspec here

; DN.COM leave resident only valable part of DNPath to save memory...

Copyright       db     13,'Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs',0Dh,0AH,'$'
DNfound         db     '(*)',0Dh,0Ah,'$'
CanNotFound     db     'No path to main file.',0Dh,0Ah,'$'
CanNotAllocate  db     'Not enough memory.',0Dh,0Ah,'$'
NotFndCOMMAND   db     'Cannot find COMSPEC variable.',0Dh,0Ah,'$'
NotEnoughFiles  db     'WARNING: Not enough file handles. Set at least FILES=20 in your CONFIG.SYS file.',0Dh,0Ah,'$'
FlagCError      db     'Unable to create flag file '
FlagFile        db     80 dup (0)
FlagHandle      dw     0

@Begin:         mov    ah,9
                mov    dx,offset Copyright
                int    21h

          ;  function SystemFiles : word ; assembler ;

                mov    ah,52h
                int    21h
                les    BX, dword ptr ES:[BX+4]
                sub    ax,ax
         @@1:   add    ax,word ptr ES:[BX+4]
                cmp    word ptr ES:[BX],0FFFFH
                je     @@2
                les    BX, dword ptr ES:[BX]
                jmp    @@1
         @@2:
                cmp    AX,20    ; check that we have enough file
                jae    @@3      ; handles

                ; mov    AH , 67h
                ; mov    BX , 30  ; Set 30 file handles
                ; int    21h
                ; jnc    @@3

;Modified by AxoN ************************************************************

                mov    ah,9
                mov    dx,offset NotEnoughFiles
                int    21h

;                mov    ax,4C01h
;                int    21h
         @@3:
                xor    ax, ax
                mov    es, ax
                mov    bx, 4*51
                mov    ax, es:[bx]
                or     ax, es:[bx+2]
                jz     @NoMouse
                xor    ax, ax
                int    33h

@NoMouse:
                mov    ah,99h
                sub    al,al
                int    2fh
                cmp    BX,'DN'
                jne    @NoHere

                mov    dx, offset DNfound
                mov    ah,9
                int    21h
               ; inc    al
               ; mov    byte ptr NumRun,al
@NoHere:
                mov    ax,352Fh
                int    21h
                mov    word ptr OldInt2F,bx
                mov    word ptr OldInt2F+2,es
                mov    dx,offset Int2Fentry
                mov    ah,25h
                int    21h


; Intialize Exec Parameter Block for DN.PRG ...
                mov    ax,cs
                mov    es,ax

                ;mov    DNEPB.CMD_Seg,ax
                mov    DNEPB.FCB1_Seg,ax
                mov    DNEPB.FCB2_Seg,ax
                ;mov    ds:CmdLineOffset,offset CmdLine
                ;mov    ds:[5Ch],cs

; ±±³ Scan ENV for Flag Directory ³±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

                cld
                mov    ax,cs:[2Ch]
                mov    ds,ax
                mov    cx,8000h
                xor    si,si
@@ScanFlg:      push   si
                lodsw              ; DNSWP=
                cmp    ax,'ND'
                jne    @NoFnd
                lodsw
                cmp    ax,'WS'
                je     @DNFnd
                sub    si, 2
                lodsb
                cmp    al, '='
                jne    @NoFnd
                pop    ax
                jmp    @FLGfound
@DNFnd:
                lodsw
                cmp    ax,'=P'
                jne    @NoFnd
                pop    ax
                jmp    @FLGfound
@NoFnd:         pop    si

@NextEnv:       LODSB
                or     al,al
                loopnz @NextEnv
                cmp    byte ptr [SI],0
                je     @EndEnv
                cmp    si,8000h
                jb     @@ScanFlg
@EndEnv:        jmp    @@ScanComsp

@FlgFound:
                mov    di,offset FlagFile
@FL0:           lodsb
                stosb
                or     al,al
                loopnz @FL0
                dec    di
                cmp    byte ptr ES:[DI-1],'\'
                jne    @BKSlash
                dec    di
@BKSlash:
                mov    ax,'D\'
                stosw
                mov    ax,'.N'
                stosw
                mov    ax,'LF'
                stosw
                mov    al,'G'
                mov    ah,0
                stosw

; Scan environment and copy COMSPEC variable

@@ScanComsp:    cld
                mov    ax,cs:[2Ch]
                mov    ds,ax
                mov    cx,8000h
                xor    si,si
ScanCOMSPEC:    push   si
                lodsw
                cmp    ax,'OC'
                jne    @NoEQ
                lodsw
                cmp    ax,'SM'
                jne    @NoEQ
                lodsw
                cmp    ax,'EP'
                jne    @NoEQ
                lodsw
                cmp    ax,'=C'
                jne    @NoEQ

                mov    DI,offset COMSPEC
@CopyComspec:   lodsb
                stosb
                or     al,al
                loopnz @CopyComspec
                ; mov    word ptr cs:COMSPECptr,si
                ; mov    word ptr cs:COMSPECptr+2,ds
                pop    ax
                dec    si
                jmp    @COMFound
@NoEQ:          pop    si

@NextEnv1:      LODSB
                or     al,al
                loopnz @NextEnv1

                ; inc    si
                cmp    si,8000h
                jb     ScanCOMSPEC
                mov    dx,offset NotFndCOMMAND
                jmp    PrintAndStop
@ERR1:          jmp    @Error1

; Find path of DN.COM and assume that it's also a path to DN.PRG ...
@COMFound:      mov    di,offset DNPath
@L0:            lodsb
                or     al,ds:[si]

                loopnz @L0
                jcxz   @ERR1

                lodsw
                lodsb

@L1:            lodsb
                stosb
                or     al,al
                jne    @L1
                sub    di,4
                mov    ax,'RP'
                stosw
                mov    al,'G'
                stosb

                inc    di

                mov    ax,cs
                mov    ds,ax

                mov    COMSPECptr,DI
                mov    si, offset COMSPEC
@@CopyCMS:      lodsb
                stosb
                or     al,al
                loopnz @@CopyCMS
                inc    di
                push   di        ; save ptr to free space

; Check if we have flag file

                mov    si,offset DNpath
                mov    di,offset FlagFile
                cmp    word ptr ES:[DI],0
                jne    @OpenFlag
                cld
@NextChar:
                lodsb
                stosb
                or     al,al
                jnz    @NextChar
                sub    di,4
                mov    ax,'LF'
                stosw
                mov    al,'G'
                stosb
@OpenFlag:
                mov    dx,offset FlagFile
                mov    ax,3D42h
                int    21h
                mov    FlagHandle,AX
                jnc    @ReadFromFlag
                mov    ah,3Ch
                sub    cx,cx
                int    21h
                mov    FlagHandle,AX
                jnc    @writeToflag
@@FlagError:
                mov    si,offset FlagFile

@@nxx:          lodsb
                or     al,al
                jnz    @@nxx
                mov    word ptr [si-1],0A0Dh
                mov    byte ptr [si+1],'$'
                mov    dx,offset FlagCError
                mov    ah,9
                int    21h
                jmp    @NextStep
@ReadFromFlag:
                mov    bx,FlagHandle
                mov    cx,1
                mov    dx,offset NumRun
                mov    ah,3Fh
                int    21h
                ; jc     @@FlagError

                inc    byte ptr NumRun

@writeToFlag:   mov    bx, FlagHandle
                mov    ax,4200h
                sub    cx,cx
                mov    dx,cx
                int    21h

                mov    bx, FlagHandle
                mov    ah,40h
                mov    dx,offset NumRun
                mov    cx,1
                mov    ah,40h
                int    21h

@CloseFlag:     mov    bx, FlagHandle
                mov    ah,3eh
                int    21h

@NextStep:
                pop    di
; Compute maximal needed offset and free memory ...

                mov    ax,cs                   ; Set stack before
                mov    ss,ax                   ; shrink memory
                mov    sp,offset int2Fentry-2  ; block

                mov    bx,di
                add    bx,16
                mov    cl,4
                shr    bx,cl
                mov    ah,4Ah
                int    21h
                jc     @Error2

; Jump to execution start ...
                jmp    RunDN

@Error1:        mov    dx,offset CanNotFound
                jmp    PrintAndStop
@Error2:        mov    dx,offset CanNotAllocate
PrintAndStop:   mov    ah,9
                int    21h
                mov    ax,252Fh
                lds    dx,dword ptr cs:OldInt2F
                int    21h
                mov    ax,4C01h
                int    21h

                end    Start


