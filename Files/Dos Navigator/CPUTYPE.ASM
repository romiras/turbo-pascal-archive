;
; Function: determines CPU & NDP type.
;
; Caller:   Turbo C:
;           int processors(void);
;
; Returns:  AL = central processor type (see below) and
;       AL bit 7 set if protected mode (AL & 80h != 0)
;       AH = coprocessor type (if any - see below)
;
; References:
; 1) Source algorithm by Bob Felts, PC Tech Journal, November 1987
;    Printed: "Dr.Dobb's Tollbook of 80286/80386 programming,
;    M&T publishing, Inc. Redwood City, California
; 2) SI-System Information, Advanced Edition 4.50, (C) 1987-88, Peter Norton
; 3) PC Tools Deluxe R4.21
;    (C)Copyright 1985,1986,1987,1988 Central Point Software, Inc.
; 4) CHKCOP, Intel's Math CoProcessor Test Program ver 2.10
;    Copyright(c) Intel Corp. 1987-1990.
; 5) HelpPC 2.10 Quick Reference Utility Copyright (c) 1991, David Jurgens
;
; Adapted & enhanced R.I.Akhmarov & T.V.Shaporev
; Computer Center MTO MFTI
;
; Added CPUID detectiion
; Pentium and higher detection by Slava Filimonov
;

CPU8086         EQU 0
CPU8088         EQU 1
CPUNEC20        EQU 2
CPUNEC30        EQU 3
CPU186          EQU 4
CPU188          EQU 5
CPU286          EQU 6
CPU386          EQU 7
CPU386SX        EQU 8
CPU386DX        EQU 9
CPU486          EQU 10
CPU486SX        EQU 11
CPU586          EQU 12


NDPNONE         EQU 0
NDP8087         EQU 1
NDP287          EQU 2
NDP287XL        EQU 3
NDP387          EQU 4
NDP387SX        EQU 5
NDP387DX        EQU 6

OPND32 MACRO op_code, op_erand
        db      66h     ; Force 32-bit operand size
  IFNB <op_code>
        db      op_code
    IFNB <op_erand>
        dd      op_erand; 32-bit immediate value
    ENDIF
  ENDIF
ENDM

CPUID MACRO
        db      0fh     ; Hardcoded opcode for CPUID instruction
        db      0a2h
ENDM


.486p

_TEXT           SEGMENT byte use16 public 'CODE'
                ASSUME  cs:_TEXT

                PUBLIC  _processors
_processors     PROC    far

                push    bp
                mov     bp,sp

; At first determine central processor type
                mov     ax,sp           ; 86/186 or 286/386
                push    sp              ; 86/186 will push sp-2
                pop     cx              ; others will push sp
                cmp     ax,cx
                je      short cpu_2386  ; if 80286/80386

;   Place 'inc ax' command to make the code re-enterable
                mov     byte ptr cs:critical,40h

                mov     dl,CPU186       ; Prepare to 8018x
                mov     ax,0FFFFh       ; distinguish between 86 and 186
                mov     cl,33           ; 8086 will shift 32 bits
                shl     ax,cl           ; 80186 will shift 0 bits
                jnz     short cpu_x808x ; NZ implies 186
;   Now distinguish Intel from NEC.
                mov     dl,CPUNEC20
                mov     cx,0FFFFh
                push    si
                xor     si,si
                mov     es,si           ; for the God's sake
                sti
                db      0F3h,026h,0ACh  ; LODSB REP ES:
                pop     si
                jcxz    short cpu_x808x
                mov     dl,CPU8086

cpu_x808x:      push    di
                push    es
                push    cs
                pop     es
                lea     di,lenconv
                mov     ax,90h          ; nop code
                mov     cx,4
                std
                cli
                rep     stosb
                cld
                nop
                nop
                nop
critical:       inc     ax
                nop
                nop
lenconv:        nop
                sti
                pop     es
                pop     di
                cmp     al,90h
                jne     short jump_cpu_ok
                add     dl,CPU8088-CPU8086
jump_cpu_ok:    jmp     cpu_ok

cpu_2386:       mov     dl,CPU286
                pushf                   ; 286/386 - 32 or 16 bit operand?
                mov     cx,sp           ; if pushf pushed 2 bytes
                mov     sp,bp           ; then 16 bit operand size
                inc     cx              ; assume 2 bytes
                inc     cx
                sub     cx,ax
                jnz     short generic_386
;   Either 286 or 386 with 16 bit oper
                db      83h,0C4h,0FAh   ; add sp,-6 = allocate room for SGDT
                sgdt    [bp-6]
                inc     byte ptr [bp-1] ; 286 stores -1,
                mov     sp,bp           ; 386 stores 0 or 1
                jz      short cpu_ok    ; go check for protected mode
generic_386:                            ; 386 in 16 or 32 bit code segment
                mov     dl,CPU386
                smsw    ax              ; check for protected mode
                test    al,1            ; if protection enable,
;                jnz     short cpu_ok    ; the following is impossible
                mov     dl,CPU486       ; now check for i486
                db      83h,0E4h,0FCh   ; and sp,-4 = align to 4-byte boundary
                jcxz    cpu_16_bit
                                        ; 386 in 32 bit code segment
                pushf                   ; 32-bit flags
                pop     ax              ; pop eax
                mov     cx,ax           ; mov ecx,eax = save original flags
                btc     ax,18           ; btc eax,18  = toggle bit 18
                push    ax              ; push eax
                popf                    ; 32-bit flags
                pushf                   ; 32-bit flags
                pop     ax              ; pop  eax
                push    cx              ; push ecx
                popf                    ; restore original eflags
                mov     sp,bp           ; restore stack pointer
                cmp     ax,cx           ; can 18th bit be changed?
                jne     short cpu_ok    ; yes, it's i486
                jmp     short test_SX_cpu
cpu_16_bit:                             ; 386 in 16 bit code segment
                pushfd
                pop     eax
                mov     ecx,eax         ; save original flags
                btc     eax,18          ; toggle bit 18
                push    eax
                popfd
                pushfd
                pop     eax
                push    ecx
                popfd                   ; restore original flags
                mov     sp,bp           ; restore stack pointer
                cmp     eax,ecx         ; can 18th bit be changed?
                jne     short cpu_ok    ; yes, it's i486
test_SX_cpu:                            ; let's distinguish SX and DX
                mov     dl,CPU386SX
                mov     eax,cr0
                test    al,10h          ; coprocessor type flag
                jz      short cpu_is_DX
                xor     al,10h          ; clear flag
                mov     cr0,eax
                mov     eax,cr0
                test    al,10h          ; if the flag can be cleared, it is DX
                jnz     short cpu_ok
re_cop_flag:    xor     al,10h
                mov     cr0,eax         ; restore the flag
cpu_is_DX:      mov     dl,CPU386DX
                jmp short cpu_ok
cpu_ok:         cmp     dl,CPU486
                jb      test_fpu

check_80486:

                db      83h,0E4h,0FCh            ; and sp,-4 = align to 4-byte boundary
                push    ecx
                popfd
                mov     eax,ecx
                xor     eax,00200000h
                push    eax
                popfd
                pushfd
                pop     eax
                mov     sp,bp
                cmp     eax,ecx
                jz      test_fpu

                push    dx
                xor     eax, eax                 ; otherwise, use as input to CPUID
                CPUID
                nop
                nop
                cmp     al,1
                jne     go_tfpu
                CPUID
                nop
                nop
                ;jc      go_tfpu
                and     ah,0fh                   ; cpu family
                cmp     ah,5
                jb      go_tfpu
                pop     cx
                mov     dl,ah                   ; set cpu_type with family
                add     dl,CPU586 - 5
                jmp     test_fpu
go_tfpu:        pop     dx
test_fpu:
; At second determine numeric coprocessor generic type
                push    cx                      ; reserve stack
                mov     dh,NDPNONE
                db      0DBh,0E3h               ; fninit; Initialize math uP
                mov     byte ptr [bp-1],0
                db      0D9h,07Eh,0FEh          ; fnstcw word ptr [bp-2]
                cmp     byte ptr [bp-1],3
                jne     short ndp_done
                mov     dh,NDP8087
                and     byte ptr [bp-2],7Fh
                db      09Bh,0D9h,06Eh,0FEh     ; fldcw word ptr [bp-2]
                db      09Bh,0DBh,0E1h          ; fdisi ; Disable Interrupts
                db      09Bh,0D9h,07Eh,0FEh     ; fstcw word ptr [bp-2]
                test    byte ptr [bp-2],80h
                jnz     short ndp_done
                mov     dh,NDP287
                db      09Bh,0DBh,0E3h          ; finit         ; Initialize math uP
                db      09Bh,0D9h,0E8h          ; fld1          ; Push +1.0 to stack
                db      09Bh,0D9h,0EEh          ; fldz          ; Push +0.0 to stack
                db      09Bh,0DEh,0F9h          ; fdivp st(1),st; st(#)=st(#)/st, pop
                db      09Bh,0D9h,0C0h          ; fld   st      ; Push onto stack
                db      09Bh,0D9h,0E0h          ; fchs          ; Change sign in st
                db      09Bh,0DEh,0D9h          ; fcompp        ; Compare st & pop 2
                db      09Bh,0DDh,07Eh,0FEh     ; fstsw word ptr [bp-2]
                wait
                mov     ah,[bp-1]
                sahf
                jz      short ndp_done
                mov     dh,NDP387
                ndp_done:
                pop cx                          ; restore stack

; At last analyse main and co-processor combination
                cmp     dh,NDP387
                jnb     short analyse_hi
                cmp     dl,CPU486
                jb      short cpu_prot
                mov     dl,CPU486SX
                jmp     short cpu_prot
analyse_hi:                                     ; i387 detected
                cmp     dl,CPUNEC30
                jnz     No_V30
                pop     bp
                jmp     CPU_2386
No_V30:
                cmp     dl,CPU286
                ja      short analyse_386
                je      short set_287XL
                jmp     short cpu_prot          ; 387 at 8088? Wonderful!
analyse_386:
                smsw    ax
                test    al,10h                  ; coprocessor type flag
                jnz     short test_SX_DX
set_287XL:      mov     dh,NDP287XL
                jmp     short cpu_prot
test_SX_DX:     cmp     dl,CPU386SX
                jne     short no_SX
                mov     dh,NDP387SX
                jmp     short cpu_prot
no_SX:          cmp     dl,CPU386DX
                jne     short cpu_prot
                mov     dh,NDP387DX
cpu_prot:       cmp     dl,CPU286
                jb      short return
                smsw    ax                      ; check for protected mode
                shl     al,7                    ; if PE = 0 then real mode
                or      dl,al                   ; else indicate protected mode
return:         mov ax,dx
                pop bp
                retf
_processors     ENDP

_TEXT           ENDS

                END
