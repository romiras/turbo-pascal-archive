Program LZss;

{
;
;  LZSS.ASM     Compress and uncompress program using LZ77 algorithm
;
;  Assembler Programmer : Andy Tam
;  Pascal Conversion : Douglas Webb
}

CONST
  N           = 4096;  { Bigger N -> Better compression on big files only. }
  F           = 18;
  THRESHOLD   = 2;
  NUL         = N * 2;
  DBLARROW    = $AF;

  BUFSIZE = 1024;    { 4k File Buffers }
  InBufPtr  : WORD = BUFSIZE;
  InBufSize : WORD = BUFSIZE;
  OutBufPtr : WORD = 0;


VAR
  infile,  outfile : File;
  printcount, height, matchPos, matchLen, lastLen, printPeriod : WORD;
  opt : BYTE;

  TextBuf : Array[0.. N + F - 2] OF BYTE;     { Start full of spaces ?! }
  Left,Mom:  Array [0..N] OF WORD;
  Right: Array [0..N + 256] OF WORD;
  codeBuf: Array [0..16] of BYTE;

  Inbuf,OutBuf : Array[0..PRED(BUFSIZE)] of BYTE;      { File buffers. }


FUNCTION ReadChunk: WORD;    { Returns #Bytes read. }

VAR
  Actual : WORD;

BEGIN
  BlockRead(InFile,InBuf,BUFSIZE,Actual);
  ReadChunk := Actual;
END;


  Procedure Getc; Assembler;
  ASM
  {
  ; getc : retrun a character from the buffer
  ;
  ;           RETURN : AL = input char
  ;                    Carry set when EOF
  }
              push    bx
              mov     bx, inBufPtr
              cmp     bx, inBufSize
              jb      @getc1
              push    cx
              push    dx
              push    di
              push    si
              call    readchunk
              pop     si
              pop     di
              pop     dx
              pop     cx
              mov     inBufSize, ax
              or      ax, ax
              jz      @getc2               { ; EOF }
              xor     bx, bx
  @getc1:     mov     al, [Offset InBuf + bx]
              inc     bx
              mov     inBufPtr, bx
              pop     bx
              clc                         { ; clear the carry flag }
              jmp     @end
  @getc2:     pop     bx
              stc                         { ; set carry to indicate EOF }
  @end:
 END;



{
  ; writeOut : flush the output buffer to disk
  ;
  ;           Entry : BX = number of byte to write from outBuf
}

Procedure Writeout;
VAR
  Actual : WORD;

BEGIN
  BlockWrite(OutFile,OutBuf,OutBufPtr,Actual);
END;





{
  ; putc : put a character into the output buffer
  ;
  ;           Entry : AL = output char
}

PROCEDURE Putc; Assembler;
ASM
              push    bx
              mov     bx, outBufPtr
              mov     [OFFSet OutBuf + bx], al
              inc     bx
              cmp     bx, BUFSIZE
              jb      @putc1
              mov     OutBufPtr,BUFSIZE   { Just so the flush will work. }
              push    cx
              push    dx
              push    di
              push    si
              call    writeOut
              pop     si
              pop     di
              pop     dx
              pop     cx
              xor     bx, bx
  @putc1:     mov     outBufPtr, bx
              pop     bx
END;



{
  ; initTree : initialize all binary search trees.  There are 256 BST's, one
  ;            for all strings started with a particular character.  The
  ;            parent is tree K is the node N + K + 1 and it has only a
  ;            right child.
  ;
}
PROCEDURE InitTree; Assembler;
ASM
      cld
      push    ds
      pop     es
      mov     di, offset right
      add     di, (N + 1) * 2
      mov     cx, 256
      mov     ax, NUL
      rep     stosw
      mov     di, offset mom
      mov     cx, N
      rep     stosw
END;


{
  ; splay : use splay tree operations to move the node to the 'top' of
  ;         tree.  Note that it will not actual become the root of the tree
  ;         because the root of each tree is a special node.  Instead, it
  ;         will become the right child of this special node.
  ;
  ;           ENTRY : di = the node to be rotated
}
PROCEDURE Splay; Assembler;
ASM
  @Splay1:    mov     si, [Offset Mom + di]
              cmp     si, NUL           { ; exit if its parent is a special node }
              ja      @Splay4
              mov     bx, [Offset Mom + si]
              cmp     bx, NUL           { ; check if its grandparent is special }
              jbe     @Splay5           { ; if not then skip }
              cmp     di, [Offset Left + si] { ; is the current node is a left child ? }
              jne     @Splay2
              mov     dx, [Offset Right + di]    { ; perform a left zig operation }
              mov     [Offset Left + si], dx
              mov     [Offset Right + di], si
              jmp     @Splay3
  @Splay2:    mov     dx, [Offset Left + di]     { ; perform a right zig }
              mov     [Offset Right + si], dx
              mov     [Offset Left + di], si
  @Splay3:    mov     [Offset Right + bx], di
              xchg    bx, dx
              mov     [Offset Mom + bx], si
              mov     [Offset Mom + si], di
              mov     [Offset Mom + di], dx
  @Splay4:    jmp     @end
  @Splay5:    mov     cx, [Offset Mom + bx]
              cmp     di, [Offset Left + si]
              jne     @Splay7
              cmp     si, [Offset Left + bx]
              jne     @Splay6
              mov     dx, [Offset Right + si]    { ; perform a left zig-zig operation }
              mov     [Offset Left + bx], dx
              xchg    bx, dx
              mov     [Offset Mom + bx], dx
              mov     bx, [Offset Right + di]
              mov     [Offset Left +si], bx
              mov     [Offset Mom + bx], si
              mov     bx, dx
              mov     [Offset Right + si], bx
              mov     [Offset Right + di], si
              mov     [Offset Mom + bx], si
              mov     [Offset Mom + si], di
              jmp     @Splay9
  @Splay6:    mov     dx, [Offset Left + di]     { ; perform a left zig-zag operation }
              mov     [Offset Right + bx], dx
              xchg    bx, dx
              mov     [Offset Mom + bx], dx
              mov     bx, [Offset Right + di]
              mov     [Offset Left + si], bx
              mov     [Offset Mom + bx], si
              mov     bx, dx
              mov     [Offset Left + di], bx
              mov     [Offset Right + di], si
              mov     [Offset Mom + si], di
              mov     [Offset Mom + bx], di
              jmp     @Splay9
  @Splay7:    cmp     si, [Offset Right + bx]
              jne     @Splay8
              mov     dx, [Offset Left + si]     { ; perform a right zig-zig }
              mov     [Offset Right + bx], dx
              xchg    bx, dx
              mov     [Offset Mom + bx], dx
              mov     bx, [Offset Left + di]
              mov     [Offset Right + si], bx
              mov     [Offset Mom + bx], si
              mov     bx, dx
              mov     [Offset Left + si], bx
              mov     [Offset Left + di], si
              mov     [Offset Mom + bx], si
              mov     [Offset Mom + si], di
              jmp     @Splay9
  @Splay8:    mov     dx, [Offset Right + di]    { ; perform a right zig-zag }
              mov     [Offset Left + bx], dx
              xchg    bx, dx
              mov     [Offset Mom + bx], dx
              mov     bx, [Offset Left + di]
              mov     [Offset Right + si], bx
              mov     [Offset Mom + bx], si
              mov     bx, dx
              mov     [Offset Right + di], bx
              mov     [Offset Left + di], si
              mov     [Offset Mom + si], di
              mov     [Offset Mom + bx], di
  @Splay9:    mov     si, cx
              cmp     si, NUL
              ja      @Splay10
              cmp     bx, [Offset Left + si]
              jne     @Splay10
              mov     [Offset Left + si], di
              jmp     @Splay11
  @Splay10:   mov     [Offset Right + si], di
  @Splay11:   mov     [Offset Mom + di], si
              jmp     @Splay1
  @end:
END;


{
  ; insertNode : insert the new node to the corresponding tree.  Note that the
  ;              position of a string in the buffer also served as the node
  ;              number.
  ;
  ;           ENTRY : di = position in the buffer
}

PROCEDURE InsertNode; Assembler;
ASM
              push    si
              push    dx
              push    cx
              push    bx
              mov     dx, 1
              xor     ax, ax
              mov     matchLen, ax
              mov     height, ax
              mov     al, byte ptr [Offset TextBuf + di]
              shl     di, 1
              add     ax, N + 1
              shl     ax, 1
              mov     si, ax
              mov     ax, NUL
              mov     word ptr [Offset Right + di], ax
              mov     word ptr [Offset Left + di], ax
  @Ins1:      inc     height
              cmp     dx, 0
              jl      @Ins3
              mov     ax, word ptr [Offset Right + si]
              cmp     ax, NUL
              je      @Ins2
              mov     si, ax
              jmp     @Ins5
  @Ins2:      mov     word ptr [Offset Right + si], di
              mov     word ptr [Offset Mom + di], si
              jmp     @Ins11
  @Ins3:      mov     ax, word ptr [Offset Left + si]
              cmp     ax, NUL
              je      @Ins4
              mov     si, ax
              jmp     @Ins5
  @Ins4:      mov     word ptr [Offset Left + si], di
              mov     word ptr [Offset Mom + di], si
              jmp     @Ins11
  @Ins5:      mov     bx, 1
              shr     si, 1
              shr     di, 1
              xor     ch, ch
              xor     dh, dh
  @Ins6:      mov     dl, byte ptr [Offset Textbuf + di + bx]
              mov     cl, byte ptr [Offset TextBuf + si + bx]
              sub     dx, cx
              jnz     @Ins7
              inc     bx
              cmp     bx, F
              jb      @Ins6
  @Ins7:      shl     si, 1
              shl     di, 1
              cmp     bx, matchLen
              jbe     @Ins1
              mov     ax, si
              shr     ax, 1
              mov     matchPos, ax
              mov     matchLen, bx
              cmp     bx, F
              jb      @Ins1
  @Ins8:      mov     ax, word ptr [Offset Mom + si]
              mov     word ptr [Offset Mom + di], ax
              mov     bx, word ptr [Offset Left + si]
              mov     word ptr [Offset Left + di], bx
              mov     word ptr [Offset Mom + bx], di
              mov     bx, word ptr [Offset Right + si]
              mov     word ptr [Offset Right + di], bx
              mov     word ptr [Offset Mom + bx], di
              mov     bx, word ptr [Offset Mom + si]
              cmp     si, word ptr [Offset Right + bx]
              jne     @Ins9
              mov     word ptr [Offset Right + bx], di
              jmp     @Ins10
  @Ins9:      mov     word ptr [Offset Left + bx], di
  @Ins10:     mov     word ptr [Offset Mom + si], NUL
  @Ins11:     cmp     height, 30
              jb      @Ins12
              call    Splay
  @Ins12:     pop     bx
              pop     cx
              pop     dx
              pop     si
              shr     di, 1
END;


{
  ; deleteNode : delete the node from the tree
  ;
  ;           ENTRY : SI = position in the buffer
}
PROCEDURE DeleteNode; Assembler;
  ASM
              push    di
              push    bx
              shl     si, 1
              cmp     word ptr [Offset Mom + si], NUL   { ; if it has no parent then exit }
              je      @del7
              cmp     word ptr [Offset Right + si], NUL { ; does it have right child ? }
              je      @del8
              mov     di, word ptr [Offset Left + si]   { ; does it have left child ? }
              cmp     di, NUL
              je      @del9
              mov     ax, word ptr [Offset Right + di]  { ; does it have right grandchild ? }
              cmp     ax, NUL
              je      @del2                             { ; if no then skip }
  @del1:      mov     di, ax                            { ; find the rightmost node in }
              mov     ax, word ptr [Offset Right + di]  { ;   the right subtree }
              cmp     ax, NUL
              jne     @del1
              mov     bx, word ptr [Offset Mom + di]    { ; move this node as the root of }
              mov     ax, word ptr [Offset Left + di]   { ;   the subtree }
              mov     word ptr [Offset Right + bx], ax
              xchg    ax, bx
              mov     word ptr [Offset Mom + bx], ax
              mov     bx, word ptr [Offset Left + si]
              mov     word ptr [Offset Left + di], bx
              mov     word ptr [Offset Mom + bx], di
  @del2:      mov     bx, word ptr [Offset Right + si]
              mov     word ptr [Offset Right + di], bx
              mov     word ptr [Offset Mom + bx], di
  @del3:      mov     bx, word ptr [Offset Mom + si]
              mov     word ptr [Offset Mom + di], bx
              cmp     si, word ptr [Offset Right + bx]
              jne     @del4
              mov     word ptr [Offset Right + bx], di
              jmp     @del5
  @del4:      mov     word ptr [Offset Left + bx], di
  @del5:      mov     word ptr [Offset Mom + si], NUL
  @del7:      pop     bx
              pop     di
              shr     si, 1
              jmp     @end;
  @del8:      mov     di, word ptr [Offset Left + si]
              jmp     @del3
  @del9:      mov     di, word ptr [Offset Right + si]
              jmp     @del3
  @end:
  END;


PROCEDURE Encode; Assembler;
  ASM
              call    initTree
              xor     bx, bx
              mov     [Offset CodeBuf + bx], bl
              mov     dx, 1
              mov     ch, dl
              xor     si, si
              mov     di, N - F
  @Encode2:   call    getc
              jc      @Encode3
              mov     byte ptr [Offset TextBuf +di + bx], al
              inc     bx
              cmp     bx, F
              jb      @Encode2
  @Encode3:   or      bx, bx
              jne     @Encode4
              jmp     @Encode19
  @Encode4:   mov     cl, bl
              mov     bx, 1
              push    di
              sub     di, 1
  @Encode5:   call    InsertNode
              inc     bx
              dec     di
              cmp     bx, F
              jbe     @Encode5
              pop     di
              call    insertNode
  @Encode6:   mov     ax, matchLen
              cmp     al, cl
              jbe     @Encode7
              mov     al, cl
              mov     matchLen, ax
  @Encode7:   cmp     al, THRESHOLD
              ja      @Encode8
              mov     matchLen, 1
              or      byte ptr codeBuf, ch
              mov     bx, dx
              mov     al, byte ptr [Offset TextBuf + di]
              mov     byte ptr [Offset CodeBuf + bx], al
              inc     dx
              jmp     @Encode9
  @Encode8:   mov     bx, dx
              mov     al, byte ptr matchPos
              mov     byte ptr [Offset Codebuf + bx], al
              inc     bx
              mov     al, byte ptr (matchPos + 1)
              push    cx
              mov     cl, 4
              shl     al, cl
              pop     cx
              mov     ah, byte ptr matchLen
              sub     ah, THRESHOLD + 1
              add     al, ah
              mov     byte ptr [Offset Codebuf + bx], al
              inc     bx
              mov     dx, bx
  @Encode9:   shl     ch, 1
              jnz     @Encode11
              xor     bx, bx
  @Encode10:  mov     al, byte ptr [Offset CodeBuf + bx]
              call    putc
              inc     bx
              cmp     bx, dx
              jb      @Encode10
              mov     dx, 1
              mov     ch, dl
              mov     byte ptr codeBuf, dh
  @Encode11:  mov     bx, matchLen
              mov     lastLen, bx
              xor     bx, bx
  @Encode12:  call    getc
              jc      @Encode14
              push    ax
              call    deleteNode
              pop     ax
              mov     byte ptr [Offset TextBuf + si], al
              cmp     si, F - 1
              jae     @Encode13
              mov     byte ptr [Offset TextBuf + si + N], al
  @Encode13:  inc     si
              and     si, N - 1
              inc     di
              and     di, N - 1
              call    insertNode
              inc     bx
              cmp     bx, lastLen
              jb      @Encode12
  @Encode14:  sub     printCount, bx
              jnc     @Encode15
              mov     ax, printPeriod
              mov     printCount, ax
(*              push    dx                 { Print out a period as a sign. }
              mov     dl, DBLARROW
              mov     ah, 2
              int     21h
              pop     dx *)
  @Encode15:  cmp     bx, lastLen
              jae     @Encode16
              inc     bx
              call    deleteNode
              inc     si
              and     si, N - 1
              inc     di
              and     di, N - 1
              dec     cl
              jz      @Encode15
              call    insertNode
              jmp     @Encode15
  @Encode16:  cmp     cl, 0
              jbe     @Encode17
              jmp     @Encode6
  @Encode17:  cmp     dx, 1
              jb      @Encode19
              xor     bx, bx
  @Encode18:  mov     al, byte ptr [Offset Codebuf + bx]
              call    putc
              inc     bx
              cmp     bx, dx
              jb      @Encode18
  @Encode19:
END;



PROCEDURE Decode; Assembler;
  ASM
              xor     dx, dx
              mov     di, N - F
  @Decode2:   shr     dx, 1
              or      dh, dh
              jnz     @Decode3
              call    getc
              jc      @Decode9
              mov     dh, 0ffh
              mov     dl, al
  @Decode3:   test    dx, 1
              jz      @Decode4
              call    getc
              jc      @Decode9
              mov     byte ptr [Offset TextBuf + di], al
              inc     di
              and     di, N - 1
              call    putc
              jmp     @Decode2
  @Decode4:   call    getc
              jc      @Decode9
              mov     ch, al
              call    getc
              jc      @Decode9
              mov     bh, al
              mov     cl, 4
              shr     bh, cl
              mov     bl, ch
              mov     cl, al
              and     cl, 0fh
              add     cl, THRESHOLD
              inc     cl
  @Decode5:   and     bx, N - 1
              mov     al, byte ptr [Offset TextBuf + bx]
              mov     byte ptr [Offset TextBuf + di], al
              inc     di
              and     di, N - 1
              call    putc
              inc     bx
              dec     cl
              jnz     @Decode5
              jmp     @Decode2
  @Decode9:
  END;



PROCEDURE LZSSquash;
BEGIN
  InBufPtr    := BUFSIZE;
  InBufSize   := BUFSIZE;
  OutBufPtr   := 0;
  printcount  := 0;
  height      := 0;
  matchPos    := 0;
  matchLen    := 0;
  lastLen     := 0;
  printPeriod := 0;
  opt         := 0;

  FillChar(TextBuf,Sizeof(TextBuf),0);
  FillChar(Left,Sizeof(Left),0);
  FillChar(Mom,Sizeof(Mom),0);
  FillChar(Right,Sizeof(Right),0);
  FillChar(codeBuf,Sizeof(codebuf),0);

  encode;
  writeout;
END;

PROCEDURE LZSSUnSquash;
BEGIN
  InBufPtr  := BUFSIZE;
  InBufSize := BUFSIZE;
  OutBufPtr := 0;
  FillChar(TextBuf,Sizeof(TextBuf),0);

  decode;
  writeout;
END;



BEGIN
  IF (ParamCount < 2) OR (ParamCount > 4) THEN
    BEGIN
      Writeln('Usage: ',ParamStr(0),' inputfile outputfile [decompress]');
      HALT;
    END;
  IF (ParamStr(1) = ParamStr(2)) THEN
    BEGIN
      Writeln('File names must be different');
      HALT;
    END;

  Assign(Infile,ParamStr(1));
{$I-}
  Reset(infile,1);
  IF IOResult <> 0 THEN
    BEGIN
      Writeln('Error opening input file ',ParamStr(1));
      HALT;
    END;

  Assign(OutFile,ParamStr(2));
  ReWrite(outFile,1);
{$I+}
  IF IOResult <> 0 THEN
    BEGIN
      Writeln('Error opening output file ',ParamStr(2));
      HALT;
    END;

   IF (ParamCount <> 3) THEN
     BEGIN
        LZSSquash;
     END
   ELSE
     BEGIN
       LZSSUnSquash;
    END;
  Close(outfile);
  Close(infile);
END.