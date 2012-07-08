;
; Lempel-Ziv Welch Compression routine
;
; Copyright (C) 1994 by Roman Cramar
;
                ideal
                jumps

segment         DATA  'DATA'
extrn MaxCode        : word
extrn RunCode        : word
extrn RunningBits    : word
extrn CodeBuffer     : dword
extrn CurCode        : word
extrn OldCode        : word
extrn CurBuffShift   : word
extrn InputOffs      : word
extrn InputSeg       : word
extrn OutPutOffs     : word
extrn OutPutSeg      : word
extrn Temp           : word
extrn DataSize       : word
extrn OutPutOffs2    : word
extrn CodeTable      : dword
extrn PrefixTable    : dword
extrn SymbolTable    : dword
ends            DATA



segment         CODE
                assume  cs:CODE, ds:DATA

                public  LZWCompr

                p386

macro           _GetByte
                dec     [DataSize]
                jz      LZWComprEnd
                les     si, [dword ptr InputOffs]
                mov     al, [es:si]
                mov     ah, 0
                inc     [InputOffs]
                endm

macro           _ComprCode
local           Rotate2,NoRotate2,CheckFull,NoIncBits
                xor     bx,bx
                mov     cx,[CurBuffShift]
                or      cx,cx
                jz      NoRotate2
Rotate2:        shl     ax,1
                rcl     bx,1
                loop    Rotate2
NoRotate2:      or      [word ptr CodeBuffer+0],ax
                or      [word ptr CodeBuffer+2],bx
                mov     ax,[RunningBits]
                add     [CurBuffShift],ax
CheckFull:      cmp     [CurBuffShift],8
                jc      NoIncBits
                les     di,[dword ptr OutputOffs]
                mov     ax,[word ptr CodeBuffer]
                mov     [es:di],al
                inc     [OutPutOffs]
                rept    8
                shr     [word ptr CodeBuffer+2],1
                rcr     [word ptr CodeBuffer+0],1
                endm
                sub     [CurBuffShift],8
                jmp     CheckFull
NoIncBits:
                endm

macro           _InitCodeTable
                les     di,[CodeTable]
                mov     cx,LZMax
                xor     ax,ax
                cld
                rep stosw
                endm

macro           _ResetCodeBuffer
local Again

Again:
                les     di,[dword ptr OutPutOffs]
                mov     ax,[word ptr CodeBuffer]
                mov     [es:di],al
                inc     [OutPutOffs]
                rept    8
                shr     [word ptr CodeBuffer+2],1
                rcr     [word ptr CodeBuffer+0],1
                endm
                sub     [CurBuffShift],8
                jnc     Again
ResetBuffEnd:   mov     [CurBuffShift],0
                endm

;Constants
ClearCode       equ     100h
EOICode         equ     101h
LZMax           equ     4096

;Pointers
cCodeTable       equ     20h
cPrefixTable     equ     2020h
cSymbolTable     equ     4020h

;Compress - compresses data using Lempel-Ziv Welch method.
;        BX:AX - Pointer to temporary buffer (21K min.)
;        DX:CX - Pointer to compressed data.
;        DI:SI - Pointer to buffer to decompress.
; Exit:  AX - size of compressed data.

proc            LZWCompr  near

                push    bp

                mov     [InputOffs],  cx
                mov     [InputSeg],   dx
                mov     [OutPutOffs], si
                mov     [OutPutOffs2],si
                mov     [OutputSeg],  di

                mov     [word ptr CodeTable+2],bx
                mov     [word ptr PrefixTable+2],bx
                mov     [word ptr SymbolTable+2],bx

                mov     bx, ax
                lea     ax, [cCodeTable+bx]
                mov     [word ptr CodeTable], ax
                lea     ax, [cPrefixTable+bx]
                mov     [word ptr PrefixTable], ax
                lea     ax, [cSymbolTable+bx]
                mov     [word ptr SymbolTable], ax

                inc     [DataSize]

                call    LZWCompress
                mov     ax,[OutPutOffs]
                sub     ax,[OutPutOffs2]
                pop     bp
                ret

endp            LZWCompr

proc            LZWCompress near
               _InitCodeTable
                mov     [RunCode],102h
                mov     [RunningBits],9
                mov     [MaxCode],200h
                xor     ax,ax
                mov     [CurBuffShift],ax
                mov     [CurCode],ax
                mov     [word ptr CodeBuffer+0],ax
                mov     [word ptr CodeBuffer+2],ax
                mov     ax,ClearCode
               _ComprCode
               _GetByte
                mov     [OldCode],ax
NextByte:      _GetByte
                mov     [CurCode],ax
                mov     cl,5
                shl     ax,cl
                xor     ax,[OldCode]
                and     ax,0FFFh
                mov     si,ax
                mov     [Temp],1
SearchLoop:     mov     bx,si
                shl     bx,1

                les     bp, [CodeTable]
                add     bp,bx
                cmp     [word ptr es:bp],0

                jnz     IsInTable
                mov     ax,[OldCode]
               _ComprCode
                mov     bx,si
                shl     bx,1
                mov     ax,[RunCode]
                mov     [Temp],ax
                cmp     ax,LZMax
                jnc     CheckOverflow

                les     bp, [CodeTable]
                add     bp,bx
                mov     [es:bp],ax

                mov     ax,[OldCode]

                les     bp,[PrefixTable]
                add     bp,bx

                mov     [es:bp],ax

                mov     al,[byte ptr ds:CurCode]

                les     bp, [SymbolTable]
                mov     [byte ptr es:bp+si],al

                inc     [RunCode]
CheckOverflow:  mov     ax,[Temp]
                cmp     ax,[MaxCode]
                jnz     ChangeOldCode
                cmp     [byte ptr ds:RunningBits],12
                jnc     SendClearCode
                inc     [byte ptr ds:RunningBits]
                shl     [MaxCode],1
                jmp     ChangeOldCode
SendClearCode:  mov     ax,ClearCode
               _ComprCode
                mov     [RunCode],102h
                mov     [byte ptr ds:RunningBits],9
                mov     [MaxCode],200h
               _InitCodeTable
ChangeOldCode:  mov     al,[byte ptr ds:CurCode]
                mov     ah,0
                mov     [OldCode],ax
                jmp     NextByte
IsInTable:      mov     ax,[OldCode]

                les     bp,[PrefixTable]
                add     bp,bx

                cmp     ax,[es:bp]

                jnz     NotTheSame

                les     bp, [SymbolTable]

                mov     al,[byte ptr es:bp+si]
                cmp     al,[byte ptr ds:CurCode]
                jnz     NotTheSame

                les     bp, [CodeTable]
                add     bp,bx

                mov     ax,[es:bp]

                mov     [OldCode],ax
                jmp     NextByte
NotTheSame:     add     si,[Temp]
                add     [Temp],2
                cmp     si,LZMax
                jc      NoOverflow
                sub     si,LZMax
NoOverflow:     jmp     SearchLoop
LZWComprEnd:    mov     ax,[OldCode]
               _ComprCode
                mov     ax,EOICode
               _ComprCode
               _ResetCodeBuffer
                ret
endp            LZWCompress


ends            CODE
                end
