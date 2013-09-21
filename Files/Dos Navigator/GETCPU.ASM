;°±²ÛßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßÛ²±°
;°±²Û   Subroutine to detect processor type                               Û²±°
;°±²Û   Steve Grant                                                       Û²±°
;°±²Û   Jersey City, NJ                                                   Û²±°
;°±²Û   April 7, 1990                                                     Û²±°
;°±²Û   V20 detection bug fixed by FRIENDS software 1992.                 Û²±°
;°±²ÛÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÛ²±°

.486P
.387

;--------------------------------------------------------------------
; Macro definitions

; On some Intel chips interrupts are enabled after a POPF instruction
; even if IF is clear.

POPF2           macro
                local   a1,a2
                jmp     short a2
a1:             iret
a2:             push    cs
                call    a1
endm

;--------------------------------------------------------------------

CODE            segment word use16

                public  CPUID

CPUID           proc    near

                assume  cs:CODE, ds:DATA

;       On entry:
;
;               BP
;       SP =>   near return address
;               offset  of a cpu_info_t record
;               segment "  "     "        "
;
;       On exit, the cpu_info_t record has been filled in as follows:
;
;               byte    = CPU type
;               word    = Machine Status Word
;               6 bytes = Global Descriptor Table
;               6 bytes = Interrupt Descriptor Table
;               boolean = segment register change/interrupt flag
;               boolean = 80386 flag word size (0 => 16)
;               boolean = 80386 multiplication bug flag
;               byte    = NDP type
;               word    = NDP control word

cpu_info        equ     [bp + 4]

mCPU            equ     byte ptr [bx]
mMSW            equ     [bx + 1]
mGDT            equ     [bx + 3]
mIDT            equ     [bx + 9]
mchkint         equ     byte ptr [bx + 15]
mopsize         equ     byte ptr [bx + 16]
mmult           equ     byte ptr [bx + 17]
mNDP            equ     byte ptr [bx + 18]
mNDPCW          equ     [bx + 19]

f8088           equ     0
f8086           equ     1
fV20            equ     2
fV30            equ     3
f80188          equ     4
f80186          equ     5
f80286          equ     6
f80386          equ     7
; f80386SX      equ     8
f80486          equ     9

funk            =       0FFH

false   equ     0
true    equ     1

trapflag        equ     01H

                push    bp
                mov     bp, sp
                push    ds
                lds     bx, cpu_info
                call    cpu
                ;call    ndp
                pop     ds
                pop     bp
                ret     4

;--------------------------------------------------------------------

CPU             proc    near

; The 8088 and 8086 do not handle interrupts of multi-prefix string
; instructions correctly; they resume processing after the interrupt
; with only the last prefix in effect.  The 8088 has a 4-byte
; prefetch instruction queue; the 8086, a 6-byte queue.

                sti                             ; timer tick will interrupt us
                mov     dx,10
TryAgain:       mov     cx, 0FFFFH
                rep     lods byte ptr es:[si]
                cmp     cx,0
                jne     Is808x
                dec     dx
                jne     TryAgain
                jmp     short cpu_03

Is808x:         call    piq
                cmp     dx, 4
                jne     short cpu_01

                mov     mCPU, f8088
                call    chkint
                ret

cpu_01:         cmp     dx, 6
                jne     short cpu_02

                mov     mCPU, f8086
                call    chkint
                ret

cpu_02:         mov     mCPU, funk
                ret

cpu_03:

; The V20 and V30 use the entire displacement register in processing
; bit shift instructions.  The V20 has a 4-byte prefetch instruction
; queue; the V30, a 6-byte queue.

                mov     al, 0FFh
                mov     cl, 21h
                shr     al, cl
                jne     short cpu_06

                call    piq
                cmp     dx, 4
                ja      short cpu_04

                mov     mCPU, fV20
                ret

cpu_04:         cmp     dx, 6
                jne     short cpu_05

                mov     mCPU, fV30
                ret

cpu_05:         mov     mCPU, funk
                ret

cpu_06:

; The 80188, 80186, 80286, 80386, 80386SX, and 80486 all trap invalid
; opcodes via INT 6.  The handler itself sets CX to 1 and adjusts the
; return address to point to the instruction following the invalid
; opcode.

; save old INT 06H vector

                push    bx
                mov     ax, 3506H
                int     21H
                mov     old_int06_ofs, bx
                mov     old_int06_seg, es
                pop     bx

; redirect INT 06H vector

                push    ds
                mov     ax, 2506H
                mov     dx, seg new_int06
                mov     ds, dx
                mov     dx, offset new_int06
                int     21H
                pop     ds

                xor     cx, cx

; The instruction SMSW DX is invalid on the 80186 and 80188.  The
; 80188 has a 4-byte prefetch instruction queue; the 80186, a 6-byte
; queue.

                smsw    dx
                jcxz    cpu_09

                call    piq
                cmp     dx, 4
                jne     short cpu_07

                mov     mCPU, f80188
                jmp     short cpu_14

cpu_07:         cmp     dx, 6
                jne     short cpu_08

                mov     mCPU, f80186
                jmp     short cpu_14

cpu_08:
                mov     mCPU, funk
                jmp     short cpu_14

cpu_09:
                mov     mMSW, dx
                sgdt    mGDT
                sidt    mIDT

; The instruction MOV EDX,EDX is invalid on the 80286.

                mov     edx,edx
                jcxz    cpu_10

                mov     mCPU,f80286
                jmp     short cpu_14

cpu_10:

; The instruction XADD DX, DX is invalid on the 80386.

                xadd    dx,dx
                jcxz    cpu_13

                mov     mCPU, f80386

; Some early 80386's do not perform 32-bit multiplication correctly.

                mov     eax, 0417A000H
                mov     edx, 81H
                mul     edx
                cmp     edx, 2
                jne     short cpu_11

                cmp     eax, 0FE7A000H
                jne     short cpu_11

                mov     mmult, true
                jmp     short cpu_12

cpu_11:         mov     mmult, false

cpu_12:         call    opsize
                jmp     short cpu_14

; BIX ibm.at/hardware #4663

cpu_13:         mov     mCPU, f80486
                mov     mmult, true
                call    opsize

cpu_14:

; restore old INT 06H vector

                push    ds
                mov     ax, 2506H
                lds     dx, old_int06
                int     21H
                pop     ds
                ret

;--------------------------------------------------------------------

piq             proc    near

;       On exit:
;
;               DX      = length of prefetch instruction queue
;
;       This procedure uses self-modifying code but can nevertheless
;       be run repeatedly in the course of the calling program.

count           =       7
opincdx         equ     42H                     ; inc dx opcode
opnop           equ     90H                     ; nop opcode

                mov     al, opincdx
                mov     cx, count

                push    cs
                pop     es

                mov     di, offset piq_02 - 1
                push    cx

                push    di
                std
                rep     stosb
                mov     al, opnop
                pop     di

                mov     dx, 1                   ; STI
                cli
                mov     cx, offset piq_02 - piq_01
                loop    $                       ; make sure queue is full

piq_01:         pop     cx

                rep     stosb
                sti

                rept    count
                inc     dx
                endm

piq_02:         ret
piq             endp

;--------------------------------------------------------------------

chkint          proc    near

; Some early 8088's and 8086's fail to disable interrupts immediately
; following a segment register load.

; save old INT 01H vector

                push    bx
                mov     ax, 3501H
                int     21H
                mov     old_int01_ofs, bx
                mov     old_int01_seg, es
                pop     bx

; redirect INT 01H vector

                push    ds
                mov     ax, 2501H
                mov     dx, seg new_int01
                mov     ds, dx
                mov     dx, offset new_int01
                int     21H
                pop     ds

; set TF and change SS -- did we trap on following instruction?

                pushf
                pop     ax
                or      ah, trapflag
                push    ax

                cli                             ; so an external interrupt
                                                ; doesn't get single step
                                                ; trapped

                POPF2

                push    ss                      ; CPU may wait one
                                                ; instruction before
                                                ; recognizing single step
                                                ; interrupt
                pop     ss

chkint_01:                                      ; shouldn't ever trap here
                sti                             ; by now TF has been reset by
                                                ; the handler

; restore old INT 01H vector

                push    ds
                mov     ax, 2501H
                lds     dx, old_int01
                int     21H
                pop     ds
                ret
chkint          endp

;--------------------------------------------------------------------

opsize          proc    near

; check whether operand size is 16 or 32 bits

                pushf
                mov     ax, sp
                popf
                inc     ax
                inc     ax
                cmp     ax, sp
                jnz     short opsize_1

                mov     mopsize, false
                ret

opsize_1:       mov     mopsize, true
                ret
opsize          endp

;--------------------------------------------------------------------

CPU             endp

;--------------------------------------------------------------------

new_int01:

;       INT 01H handler (single step)
;
;       On entry:
;
;       SP =>   IP
;               CS
;               flags
;
;       On exit:
;
;       if trapped on or before POP SS  nothing
;       if trapped immediately after    mchkint = false, TF cleared
;       if trapped later                mchkint = true, TF cleared

                sti
                pop     ax                      ; IP
                cmp     ax, offset chkint_01
                jb      short new_int01_3
                je      short new_int01_1
                mov     mchkint, true
                jmp     short new_int01_2

new_int01_1:    mov     mchkint, false

new_int01_2:    pop     cx                      ; CS
                pop     dx                      ; flags
                and     dh, not trapflag
                push    dx                      ; flags
                push    cx                      ; CS

new_int01_3:    push    ax                      ; IP
                iret

;--------------------------------------------------------------------

new_int06:

;       INT 06H handler (invalid opcode)
;
;       On entry:
;
;       CX = 0
;       SP =>   IP of invalid instruction
;               CS of invalid instruction
;               flags
;
;       On exit:
;
;       CX = 1
;       return address on stack points to instruction following
;       invalid instruction

                sti
                inc     cx
                pop     ax
                add     ax, 3
                push    ax
                iret

;--------------------------------------------------------------------

NDP             proc    near

fnone           equ     0
f8087           equ     1
f80287          equ     2
f80387          equ     3
funk            =       0FFH

                mov     ndp_cw, 0000H
                cli

; The first three 80x87 instructions below cannot carry the WAIT
; prefix, because there may not be an 80x87 for which to wait.  The
; WAIT is therefore emulated with a MOV CX,<value>! LOOP $
; combination.

                                                        ;       CPU     NDP
                fnsave  ndp_save                        ;        14     221
                mov     cx, (221 - 23 + 16) / 17 + 1    ;         4
                loop    $                               ;   17*CX+5
                                                        ;  17*CX+23

                fninit                                  ;         8       8
                mov     cx, (8 - 17 + 16) / 17 + 1      ;         4
                loop    $                               ;   17*CX+5
                                                        ;  17*CX+17

                fnstcw  ndp_cw                          ;        14      24
                mov     cx, (24 - 23 + 16) / 17 + 1     ;         4
                loop    $                               ;   17*CX+5
                                                        ;  17*CX+23

                sti
                mov     ax, ndp_cw
                cmp     ax, 0000H
                jne     short ndp_01

                mov     mNDP, fnone
                ret

ndp_01:         cmp     ax, 03FFH
                jne     short ndp_02

                mov     mNDP, f8087
                jmp     short ndp_04

ndp_02:         cmp     ax, 037FH
                jne     short ndp_05

                fld1
                fldz
                fdiv
                fld1
                fchs
                fldz
                fdiv
                fcom
                fstsw   ndp_sw
                mov     ax, ndp_sw
                and     ah, 41H                 ; C3, C0
                cmp     ah, 40H                 ; ST(0) = ST(1)
                jne     short ndp_03

                mov     mNDP, f80287
                jmp     short ndp_04

ndp_03:         cmp     ah, 01H                 ; ST(0) < ST(1)
                jne     short ndp_05

                mov     mNDP, f80387

ndp_04:         frstor  ndp_save
                fstcw   mNDPCW
                ret

ndp_05:         mov     mNDP, funk
                ret

ndp             endp

;--------------------------------------------------------------------

CPUID           endp
CODE            ends

DATA    segment word use16

; storage for CPUID
; redirected INT 01H, 06H vectors

old_int01       label   dword
old_int01_ofs   dw      ?
old_int01_seg   dw      ?

old_int06       label   dword
old_int06_ofs   dw      ?
old_int06_seg   dw      ?

; storage for NDPID

; 80x87 control word after initialization, status word after divide by zero

ndp_cw          dw      ?
ndp_save        db      94 dup (?)
ndp_sw          dw      ?

DATA            ends

                end
