        ideal
        p8086
        jumps
        smart
        model   tPascal

        CodeSeg

public  Prepare1Str
public  XLatStr
public  GetUUxlt
public  GetLnCrc
public  cCrc
public  Crc64
public  Clear64

proc    Prepare1Str near
        uses    ds
        local   Loc:byte
        arg     Sou:dword,Dst:dword
        cld
        lds     si,[Sou]
        les     di,[Dst]
        mov     bx,offset UUxlt
        mov     [Loc],15
 @@L:   mov     al,[ds:si+2]
        mov     dh,al
        and     al,00111111b
        mov     cl,6
        shr     dh,cl
  SegCS xlat
        mov     [es:di+3],al
        mov     al,[ds:si+1]
        mov     dl,al
        mov     cl,2
        shl     al,cl
        and     al,00111100b
        mov     cl,4
        shr     dl,cl
        or      al,dh
  SegCS xlat
        mov     [es:di+2],al
        mov     al,[ds:si]
        add     si,3
        mov     dh,al
        shl     al,cl
        and     al,00110000b
        mov     cl,2
        shr     dh,cl
        or      al,dl
  SegCS xlat
        mov     [es:di+1],al
        mov     al,dh
  SegCS xlat
        mov     [es:di],al
        add     di,4
        dec     [Loc]
        jnz     @@L
        ret
        endp

proc    XLatStr near
        arg     s:dword
        cld
        les     di,[s]
        mov     bx,offset UUxlt
        mov     cl,[es:di]
        inc     di
        mov     ch,0
  @@L:  mov     al,[es:di]
  SegCS xlat
        stosb
        loop    @@L
        ret
        endp

proc    GetUUxlt near
        arg     a:byte
        mov     al,[a]
        mov     bx,offset UUxlt
  SegCS xlat
        ret
        endp


proc    cCrc    near
        arg     Buf:dword,Sz:word,PrevSum:dword
        cld
        mov     cx,[Sz]
        jcxz    @@End
        push    ds
        lds     si,[Buf]
        les     di,[PrevSum]
        mov     dx,[word ptr es:di]
        xor     ax,ax
 @@1:   lodsb
        ror     dx,1
        add     dx,ax
        loop    @@1
        pop     ds
        mov     [word ptr es:di],dx
 @@End: ret
        endp

proc    AddByte near
        add     [es:di+0],ax
        mov     al,0
        adc     [es:di+2],ax
        adc     [es:di+4],ax
        adc     [es:di+6],ax
        shl     [word ptr es:di+0],1
        rcl     [word ptr es:di+2],1
        rcl     [word ptr es:di+4],1
        rcl     [word ptr es:di+6],1
        adc     [es:di+0],ax
        ret
        endp

proc    Crc64   near
        arg     Buf:dword,Sz:word,PrevSum:dword,PrevCnt:dword
        cld
        mov     cx,[Sz]                 ; CX    ออ Block Size
        jcxz    @@End
        push    ds
        lds     si,[Buf]                ; DS:SI ฤ> InBuf
        les     di,[PrevCnt]
        mov     dx,[es:di]              ; DX    ออ Counter
        les     di,[PrevSum]            ; ES:DI ฤ> CheckSum
        mov     bx,offset Poly64        ; BX    ฤ> Poly64
        xor     ax,ax
 @@1:   lodsb
        call    AddByte
        mov     al,dl
        call    AddByte
        inc     dx
        loop    @@1
        pop     ds
        les     di,[PrevCnt]
        mov     [es:di],dx
 @@End: ret
        endp

proc    Clear64 near
        arg     n:dword
        cld
        les     di,[n]
        mov     si,offset Poly64+64
        mov     cx,4
SegCS   rep     movsw
        ret
        endp

proc    GetLnCrc near
        arg     Buf:dword,Sz:word
        cld
        mov     cx,[Sz]
        jcxz    @@End
        push    ds
        lds     si,[Buf]
        xor     ax,ax
        xor     dx,dx
 @@1:   lodsb
        sub     al,20h
        and     al,3Fh
        add     dx,ax
        loop    @@1
        pop     ds
        mov     ax,dx
        and     al,3Fh
        mov     bx,offset UUxlt
 SegCS  xlat
@@End:  ret
        endp

UUxlt   db '`!"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_'
Poly64  db      158,253,28,193,115,109,43,231,98,5,102,194,72,235,155,133
        db      157,186,180,252,77,81,53,61,3,13,198,128,96,132,78,229
        db      195,35,115,28,147,68,137,57,49,164,51,26,1,66,83,47
        db      60,27,1,151,106,72,167,204,188,104,131,99,170,112,31,146
        db      137,57,139,122,249,109,97,124,101,163,230,2,248,224,206,138
        db      180,184,117,225,153,196,140,216,9,62,157,224,207,224,215,81
        db      125,103,5,94,11,81,172,227,216,170,164,150,146,34,185,81
        db      141,154,26,112,157,243,166,135,127,217,100,227,77,178,172,143
        db      162,23,213,237,102,95,115,4,91,37,101,20,232,230,82,34
        db      195,12,79,121,108,6,203,96,168,70,252,124,88,73,102,157
        db      109,248,67,241,220,11,214,217,177,66,248,223,201,145,109,130
        db      198,159,197,218,49,49,225,80,0,87,91,226,215,138,101,176
        db      201,251,236,215,112,203,8,192,143,245,255,125,182,10,115,215
        db      122,40,133,18,75,173,232,167,248,162,77,108,103,223,153,226
        db      20,88,192,177,91,27,79,123,162,245,237,154,228,191,95,109
        db      56,191,230,68,75,184,239,25,246,128,114,151,86,55,137,48

        end