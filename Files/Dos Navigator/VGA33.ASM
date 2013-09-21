
.model tiny
.code
outb  macro v1,v2
       mov   al,v1
       out   dx,al
       mov   al,v2
       inc   dx
       out   dx,al
       dec   dx
endm

outv    macro   v
        mov     al,v
        out     dx,al
endm

      org       100h
b:    cli
      mov       dx,3C4h
      outb      0,1

      mov       dx,3D4h
      outv      23
      inc       dx
      in        al,dx
      and       al,127
      out       dx,al
      dec       dx

      outv      17
      inc       dx
      in        al,dx
      and       al,127
      out       dx,al

      mov       dx,3CCh
      in        al,dx
      or        al,192
      mov       dx,3C2h
      out       dx,al

      mov       dx,3D4h

      outb      6,11
      outb      7,62
      outb      9,79
      outb      16,234
      outb      17,140
      outb      18,223
      outb      21,231
      outb      22,4

      outv      17
      inc       dx
      in        al,dx
      or        al,128
      out       dx,al
      dec       dx

      outv      23
      inc       dx
      in        al,dx
      or        al,128
      out       dx,al
      mov       dx,3C4h
      outb      0,3

      sti
      mov ax,40h
      mov ds,ax
      mov byte ptr ds:[84h],29
      retn

end   b

