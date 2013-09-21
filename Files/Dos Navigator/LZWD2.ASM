;
; Lempel-Ziv Welch Decompression routine
;
; Copyright (C) 1994 by Roman Cramar
;
                .186
                jumps


OutByte         macro
                mov     es,OutputSeg
                mov     byte ptr es:[bp],al
                inc     bp
                endm

DATA            segment 'DATA'

extrn InputOffs  : word
extrn InputSeg   : word
extrn Temp_offs  : word
extrn Temp_seg   : word
extrn OutPutSeg  : word

extrn le6A       : word
extrn le6C       : word
extrn le6E       : word
extrn le70       : word
extrn le72       : word
extrn le74       : word
extrn le78       : word
extrn le7A_0     : word
extrn le7A_2     : word
extrn le7A_4     : word
extrn le7A_6     : word
extrn le82a      : word
extrn le82b      : word
extrn OutPutOffs2: word

extrn le76       : byte
extrn le77       : byte

DATA            ends

CODE            segment
                assume  cs:CODE, ds:DATA

                public  LZWDecompr

;Decompress - decompresses data compressed by Lempel-Ziv Welch method.
;        BX:AX - Pointer to temporary buffer (17K min.).
;        DX:CX - Pointer to compressed data.
;        DI:SI - Pointer to buffer to decompress.
; Exit: AX - size of decompressed data.

LZWDecompr      proc    near
                push    bp

                mov     Temp_offs,  ax
                mov     Temp_seg,   bx
                mov     InputOffs,  cx
                mov     InputSeg,   dx
                mov     bp,         si
                mov     OutPutOffs2,si
                mov     OutputSeg,  di

                call    LZWDecomp

                mov     ax,bp
                sub     ax,OutPutOffs2
                pop     bp

                ret
LZWDecompr      endp

LZWDecomp       proc    near
                push    si
                push    di
                mov     le72,0
                mov     le78,9
                mov     le70,102h
                mov     le74,200h
                xor     ax,ax
                mov     le6a,ax
                mov     le6c,ax
                mov     le6e,ax
                mov     le76,al
                mov     le77,al
                mov     le82a,ax
                mov     le82b,ax
                mov     le7a_0,1FFh
                mov     le7a_2,3FFh
                mov     le7a_4,7FFh
                mov     le7a_6,0FFFh
le58b:          call    GetNextCode
                cmp     ax,101h
                jnz     le596
                jmp     le63b
le596:          cmp     ax,100h
                jnz     le5b5
                call    InitTable
                call    GetNextCode
                mov     le6a,ax
                mov     le6c,ax
                mov     le77,al
                mov     le76,al
                mov     al,le77
                OutByte
                jmp     le58b
le5b5:          mov     le6a,ax
                mov     le6e,ax
                cmp     ax,le70
                jb      t2
                mov     ax,le6c
                mov     le6a,ax
                mov     al,le76
                push    ax
                inc     le72
t2:             cmp     le6a,0ffh
                jbe     le5f6
                les     si,dword ptr temp_offs
                mov     bx,le6a
                shl     bx,1
                add     bx,le6a
                mov     al,es:[bx+si+2]
                push    ax
                inc     le72
                mov     ax,es:[bx+si]
                mov     le6a,ax
                jmp     t2
le5f6:          mov     ax,le6a
                mov     le76,al
                mov     le77,al
                push    ax
                inc     le72
                mov     cx,le72
                jcxz    le610
t1:             pop     ax
                OutByte
                loop    t1
le610:          mov     le72,0
                call    AddInTable
                mov     ax,le6e
                mov     le6c,ax
                mov     bx,le70
                cmp     bx,le74
                jl      le638
                cmp     byte ptr ds:le78,0ch
                jz      le638
                inc     byte ptr ds:le78
                shl     le74,1
le638:          jmp     le58b
le63b:          pop     di
                pop     si
                ret

InitTable       proc    near
                mov     byte ptr ds:le78,9
                mov     le74,200h
                mov     le70,102h
                ret
InitTable       endp

GetNextCode     proc    near
                mov     bx,le82a
                mov     ax,le82b
                add     bx,le78
                adc     ax,0
                xchg    bx,le82a
                xchg    ax,Le82b
                mov     cx,bx
                and     cx,7     ;!!!!!
                shr     ax,1
                rcr     bx,1
                shr     ax,1
                rcr     bx,1
                shr     ax,1
                rcr     bx,1
                les     si,dword ptr InputOffs
                mov     ax,es:[bx+si]
                mov     dl,es:[bx+si+2]
                or      cx,cx
                jz      GetCode2
GetCode1:       shr     dl,1
                rcr     ax,1
                loop    GetCode1
GetCode2:       mov     bx,le78
                sub     bx,9
                shl     bx,1
                and     ax,[bx+le7a_0]
                ret
GetNextCode     endp

AddInTable      proc    near
                push    si
                mov     bx,le70
                shl     bx,1
                add     bx,le70
                les     si,dword ptr temp_offs
                mov     al,le77
                mov     es:[bx+si+2],al
                mov     ax,le6c
                mov     es:[bx+si],ax
                inc     le70
                pop     si
                ret
AddInTable      endp

LZWDecomp       endp

CODE            ends
                end
