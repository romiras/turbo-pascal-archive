IDEAL
; COMPMARK.ASM - Implements Markov model splay tree compression on top of run
; length encoding.  See COMPMARK.PAS unit for details.
;
; This routine contributed to the public domain by the author:
;
;   Edwin T. Floyd [76067,747]
;   #9 Adams Park Ct.
;   Columbus, GA 31909
;   404-576-3305 (work)
;   404-322-0076 (home)
;
; Please report errors to me and if you create a better performing
; implementation, please post it or send me a copy.
;
; This program was inspired by the Pascal implementation: SPLAY.PAS by
; Kim Kokkenen.
;
; Borland's Turbo Assembler - TASM is required to assemble this program.
;

STRUC    workarea ; parameter from caller
bitstate dw     (?)                ; last compressed byte and bit position
treeds   dw     (?)                ; reg ds for current state tree
statmask db     (?)                ; bit mask to compute next state
filler   db     11 dup (?)         ; fill to end of paragraph
ENDS

STRUC    splaytree ; trees, 1.5K each, follow workarea
left     dw     256 dup (?)        ; left pointers
right    dw     256 dup (?)        ; right pointers
up       db     512 dup (?)        ; up pointers and characters
ENDS

splsize  equ    96                 ; size in paragraphs of each splaytree
work     equ    (workarea PTR si)  ; equates for addressability
tree     equ    (splaytree PTR si)

SEGMENT  code BYTE PUBLIC
         ASSUME cs:code

PROC     Splay NEAR
; Rearrange the splay tree for each succeeding character (passed in al).
; Stomps registers AX,BX,CX,DX
         ASSUME ds:workarea
         push   ds
         push   di
         mov    cl,al              ; Save character
         and    al,[work.statmask] ; Compute tree seg for next state
         mov    ah,splsize
         mul    ah
         mov    bx,ds
         inc    bx
         add    ax,bx
         xchg   ax,[work.treeds]
         mov    ds,ax              ; point to tree for current state
         ASSUME ds:splaytree
         mov    al,cl              ; Restore character
         xor    ah,ah
         add    ax,255             ; A := Plain + MaxChar
@@nextrep:                         ; Repeat
;
; Walk up the tree semi-rotating pairs
;
         mov    bx,ax              ;   C := Up[A];
         mov    cl,[bx+tree.up]
         or     cl,cl              ;   If C <> Root Then Begin
         jz     @@done
         xor    ch,ch              ;   D := Up[C];
         mov    bx,cx
         mov    dl,[bx+tree.up]
         xor    dh,dh
;
; Exchange children of pair
;
         mov    bx,dx              ;   B := Left[D];
         shl    bx,1
         mov    di,[bx+tree.left]
         mov    bx,dx
         shl    bx,1
         cmp    cx,di              ;   If C = B Then Begin
         jnz    @@jmp1
         mov    di,[bx+tree.right] ;     B := Right[D];
         mov    [bx+tree.right],ax ;     Right[D] := A;
         jmp    SHORT @@skip1      ;   End Else
@@jmp1:
         mov    [bx+tree.left],ax  ;     Left[D] := A;
@@skip1:
         mov    bx,cx              ;   If A = Left[C] Then
         shl    bx,1
         cmp    [bx+tree.left],ax
         jnz    @@jmp2
         mov    [bx+tree.left],di  ;     Left[C] := B
         jmp    SHORT @@skip2      ;   Else
@@jmp2:
         mov    [bx+tree.right],di ;     Right[C] := B;
@@skip2:
         mov    bx,ax              ;   Up[A] := D;
         mov    [bx+tree.up],dl
         mov    bx,di              ;   Up[B] := C;
         mov    [bx+tree.up],cl
         mov    ax,dx              ;   A := D;
         or     ax,ax              ; Until A = Root;
         jnz    @@nextrep
@@done:
         pop    di
         pop    ds
         ret
ENDP

PROC     Compress NEAR
; Compress a byte (passed in al; output goes to [ES:DI])
; Stomps register AX
         ASSUME ds:workarea
         push   bx
         push   cx
         push   dx
         push   ax
         push   bp
         mov    bp,ds
         mov    ds,[work.treeds]
         ASSUME ds:splaytree
         xor    ah,ah              ; A := Plain + MaxChar
         add    ax,255
         xor    cx,cx              ; zero bit stack
         xor    dx,dx
;
; Walk up the tree pushing bits onto stack
;
@@nextrep:                         ; Repeat
         mov    bx,ax              ;   U := Up[A];
         mov    bl,[bx+tree.up]
         xor    bh,bh
         shl    bx,1               ;   If Right[U] = A Then
         cmp    [bx+tree.right],ax
         jnz    @@skip1
         or     dl,1               ;     Set 1 bit
@@skip1:                           ;   Else Set 0 bit;
         shr    bx,1
         inc    cx                 ;   Stack bit just set;
         test   cl,0Fh
         jnz    @@skip2
         push   dx
         xor    dx,dx
@@skip2:
         shl    dx,1
         mov    ax,bx              ;    A := U;
         or     ax,ax              ;  Until A = Root;
         jnz    @@nextrep
;
; Cx now contains the number of bits pushed.  Pop cx bits off the stack.
;
         mov    ds,bp
         ASSUME ds:workarea
         shr    dx,1               ; Pop off un-set bit position
         mov    ax,[work.bitstate] ; Restore output position
@@nextbit:                         ; Repeat
         test   cl,0Fh             ;   Pop off a bit
         jnz    @@skip3
         pop    dx
@@skip3:
         shr    dx,1
         rcr    al,1
         shl    ah,1
         jnc    @@skip4            ;   If al is full
         stosb                     ;   push it out
         inc    ah
@@skip4:
         loop   @@nextbit          ; Until all bits are popped
         mov    [work.bitstate],ax ; Save output position
         pop    bp
         pop    ax                 ; Restore original character
         call   Splay              ; Twist the tree
         pop    dx
         pop    cx
         pop    bx
         ret
ENDP

PROC     Expand NEAR
; Expand a byte (returned in al, input comes from [ES:DI])
; Stomps register AX
         ASSUME ds:workarea
         push   bx
         push   cx
         push   dx
         push   ds
         mov    ax,[work.bitstate] ; Restore input position
         mov    ds,[work.treeds]
         ASSUME ds:splaytree
         xor    bx,bx              ; A := Root;
;
; Scan the tree to a leaf, which determines the character
;
@@nextbit:                         ; Repeat
         shl    bx,1               ;
         shl    ah,1               ;   If this input character is used up Then
         jnc    @@skip1
         mov    al,[BYTE es:di]    ;     get the next input character
         inc    di                 ;
         inc    ah                 ;     and reset the bit position
@@skip1:
         shr    al,1               ;   Case nextbit Of
         jc     @@skip2
         mov    bx,[bx+tree.left]  ;     0 : A := Left[A];
         jmp    SHORT @@skip3
@@skip2:
         mov    bx,[bx+tree.right] ;     1 : A := Right[A];
@@skip3:                           ;   End;
         cmp    bx,255             ; Until A >= MaxChar;
         jb     @@nextbit

         pop    ds
         ASSUME ds:workarea
         mov    [work.bitstate],ax ; Save input position
         mov    ax,bx
         sub    ax,255             ; A := A - MaxChar;
         push   ax                 ; Save character just found
         call   Splay              ; Twist the tree
         pop    ax                 ; Restore and exit
         pop    dx
         pop    cx
         pop    bx
         ret
ENDP

         MODEL TPASCAL
PUBLIC   InitSplay
PROC     InitSplay NEAR workptr:DWORD,bits:WORD
; Initialize the splay tree[s] - as balanced.
; Stomps registers AX,BX,CX
         push   ds
         lds    si,[workptr]
         ASSUME ds:workarea
         mov    cx,[bits]          ; create state mask and tree count
         xor    ch,ch
         cmp    cl,8
         jbe    @@bitsok
         mov    cl,8
@@bitsok:
         mov    ax,1               ; ax = tree count
         xor    bl,bl              ; bl = state mask
         jcxz   @@skipmask
@@loop1:
         or     bl,al
         shl    ax,1
         loop   @@loop1
@@skipmask:
         mov    cx,ax
         mov    [work.statmask],bl
         mov    ax,ds              ; point to first tree
         inc    ax
         mov    [work.treeds],ax
         mov    ds,ax
         ASSUME ds:splaytree
@@nexttree:                        ; initialize all trees
         push   cx
         mov    cx,512
         xor    bx,bx
@@nextup:
         mov    ax,bx
         dec    ax
         shr    ax,1
         mov    [bx+tree.up],al
         inc    bx
         loop   @@nextup

         mov    cx,256
         xor    ax,ax
         mov    bx,ax
@@nextlr:
         inc    ax
         mov    [bx+tree.left],ax
         inc    ax
         mov    [bx+tree.right],ax
         mov    bx,ax
         loop   @@nextlr
         pop    cx
         mov    ax,ds
         add    ax,splsize
         mov    ds,ax
         loop   @@nexttree
         pop    ds
         ret
ENDP

PUBLIC   CompressBuffer
PROC     CompressBuffer NEAR workptr:DWORD,inbuf:DWORD,inlen:WORD,outbuf:DWORD
; Compress buffer pointed to by [inbuf] for [inlen] characters placing the
; output in the area pointed to by [outbuf].  [workptr] points to a 1.5K work
; area.  Stomps AX,BX,CX,DX,ES,DI,SI.
; Pascal declaration:
;   Function CompressBuffer(Var work; Var inbuf; inlen : Word
;     Var outbuf) : Word; External;
;
         push   ds
         cld
         lds    si,[workptr]
         ASSUME ds:workarea
         mov    cx,[inlen]
         les    di,[outbuf]
         push   di
         xor    ax,ax
         inc    ah
         mov    [work.bitstate],ax
         xor    bx,bx
         mov    dl,' '
         xor    dh,dh
@@nextchar:
; Loop compressing characters.  Input characters are run-length-encoded first.
; Input is segmented into "duplicate" character segments and "non-duplicate"
; segments of not more than 127 bytes each.  Each segment is prefixed by a
; one-byte tag.  The high-order bit in the tag indicates the segment type:
; 1=>non-duplicate, 0=>duplicate.  The remaining bits indicate the length
; of the data.  Non-duplicate segment tags are followed by the segment data;
; duplicate segments indicate a repetition of the last character compressed.
; Register dl contains the last plain-text character examined, and the segment
; tag is constructed in dh.
;
         lds    si,[inbuf]
         test   dh,080h
         jz     @@testdup
;
; we're in a segment of mostly non-duplicate characters
;
         mov    al,[BYTE bx+si]
         inc    bx
         dec    dh
         test   dh,07Fh
         jnz    @@pressit
         xor    dh,dh
         jmp    SHORT @@pressit
@@testdup:
; test for at least three duplicate characters in a row
;
         cmp    [BYTE bx+si],dl
         jnz    @@nondup
         cmp    [BYTE bx+si+1],dl
         jnz    @@nondup
         xor    dh,dh
@@duploop:
; count duplicate characters
;
         inc    dh
         inc    bx
         cmp    dh,07Fh
         jnb    @@dupend
         cmp    [BYTE bx+si],dl
         jne    @@dupend
         loop   @@duploop
         inc    cx
; we've either run out of duplicates or we have 127 of them; compress the tag
;
@@dupend:
         mov    al,dh
         jmp    SHORT @@pressit
@@nondup:
; we have a segment of mostly non-duplicate characters
;
         push   bx
         push   cx
         xor    dh,dh
@@nonloop:
; count the non-duplicates
;
         mov    dl,[BYTE bx+si]
         inc    bx
         inc    dh
         cmp    dh,07Fh
         jnb    @@nonend
         cmp    [BYTE bx+si],dl
         jnz    @@nonnext
         cmp    [BYTE bx+si+1],dl
         jz     @@nonend
@@nonnext:
         loop   @@nonloop
@@nonend:
; we've either hit a duplicate segment, run out of input, or hit the 127
; character limit.  build the tag byte and compress it.
;
         pop    cx
         pop    bx
         inc    cx
         or     dh,080h
         mov    al,dh
@@pressit:
; compress rle character with Splay tree
;
         lds    si,[workptr]
         call   Compress
         loop   @@nextchar
;
; Compression done, flush the last byte if necessary
;
         mov    ax,[work.bitstate]
         cmp    ah,1
         jz     @@skip1
@@loop1:
; right justify last byte
;
         shr    al,1
         shl    ah,1
         jnc    @@loop1
         stosb
@@skip1:
         mov    ax,di
         pop    bx
         sub    ax,bx     ; Length of compressed data is function result in AX
         pop    ds
         ret
ENDP

PUBLIC   ExpandBuffer
PROC     ExpandBuffer NEAR workptr:DWORD,inbuf:DWORD,outbuf:DWORD,outlen:WORD
; Expand buffer pointed to by [inbuf] placing the output in the area pointed
; to by [outbuf] for [outlen] characters.  [workptr] points to a 1.5K work
; area.  Stomps AX,BX,CX,DX,ES,DI,SI.
; Pascal declaration:
;   Procedure ExpandBuffer(Var work; Var inbuf; Var outbuf; outlen : Word)
;   External;
;
         push   ds
         cld
         lds    si,[workptr]
         ASSUME ds:workarea
         mov    cx,[outlen]
         les    di,[inbuf]
         xor    al,al
         mov    ah,080h
         mov    [work.bitstate],ax
         xor    bx,bx
         xor    dh,dh
         mov    dl,' ';
;
; Loop expanding characters
;
@@nextchar:
         test   dh,080h
         jz     @@testdup
;
; We're in the midst of a non-duplicate segment
;
         call   expand
         mov    dl,al
         dec    dh
         test   dh,07Fh
         jnz    @@putit
         xor    dh,dh
         jmp    SHORT @@putit
@@testdup:
         or     dh,dh          ; Are we in a duplicate segment?
         jz     @@nextgroup
         mov    al,dl          ; yes, we already have the character
         dec    dh
         jmp    SHORT @@putit
@@nextgroup:
; The next character is a segment tag; get it
;
         call   expand
         mov    dh,al
         jmp    @@nextchar
@@putit:
; We have a character; put it in the output buffer
;
         lds    si,[outbuf]
         mov    [bx+si],al
         inc    bx
         lds    si,[workptr]
         loop   @@nextchar
;
; Expansion done - restore ds and exit
;
         pop    ds
         ret
ENDP
ENDS
END
