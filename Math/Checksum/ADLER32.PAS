Unit Adler32;

{
   Written 1995 by Oliver Fromme <fromme@rz.tu-clausthal.de>.
   Donated to the public domain.

   Freely usable, freely distributable.
   Nobody may claim copyright on this code.

   This unit provides an Adler32 check, as specified in the ziplib library.
}

{$A+,B-,D+,I-,l+,T-,V+,X+,Y+,S-,R-,Q-}

{$UNDEF NOASM} {Enable this DEFINE if you want to use Pascal routines
                  instead of fast Assembly routines.}



Interface

Type  tAdler = Record
                  Case Integer Of
                     0 : (Value : LongInt) ; {treated as unsigned 32 bit}
                     1 : (S1,S2 : Word)
               End ;

Procedure  InitAdler32 (Var Adler : tAdler) ;
   {Initializes the given variable for Adler32 calculation.}

Procedure  UpdateAdler32 (Var Adler : tAdler ; Var InBuf ; InLen : Word) ;
   {Updates the given Adler variable.  Checks 'InLen' bytes at 'InBuf'.}

Function  FinalAdler32 (Adler : tAdler) : LongInt ;
   {This returns the actual Adler32 value.
    Note that the actual variable is not changed, so you can continue
    updating it.}

{
   Procedure  Example ;
      Var  my_Adler : tAdler ;
      Begin
         InitAdler (my_Adler) ;
         UpdateAdler32 (my_Adler,data1,SizeOf(data1) ;
         UpdateAdler32 (my_Adler,data2,SizeOf(data2) ;
         UpdateAdler32 (my_Adler,data3,SizeOf(data3) ;
         tAdler := FinalAdler(my_Adler) ;
         WriteLn ('Adler32 of data1-data3 is ',my_Adler)
      End ;
}



Implementation

Const  Adler_BASE = 65521 ; {largest prime smaller than 65536}
       Adler_NMAX = 5552 ; {NMAX is the largest n such that
                            255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1}

Procedure  InitAdler32 (Var Adler : tAdler) ;
   Begin
      Adler.Value := 1 {S1 :=1 ; S2 := 0}
   End {InitAdler32} ;

{$IFDEF NOASM}

Procedure  UpdateAdler32 (Var Adler : tAdler ; Var InBuf ; InLen : Word) ;
   Var  BytePtr   : ^Byte ;
        wcount,i  : Word ;
        Sum1,Sum2 : LongInt ;
   Begin
      Sum1 := Adler.S1 ;
      Sum2 := Adler.S2 ;
      BytePtr := Addr(InBuf) ;
      While InLen<>0 Do Begin
         If InLen<Adler_NMAX Then
            wcount := InLen
         Else
            wcount := Adler_NMAX ;
         For i:=1 To wcount Do Begin
            Inc (Sum1,BytePtr^) ;
            Inc (Sum2,Sum1) ;
            Inc (BytePtr)
         End ;
         Dec (InLen,wcount) ;
         {The following requires ASM because Pascal's LongInt is signed.
          It's also possible to add a constant to Sum1 (or Sum2) if it's
          negative, but that would be slower.}
         Asm
            {Sum1 := Sum1 Mod Adler_BASE ;}
                mov     ax,word ptr Sum1
                mov     dx,word ptr Sum1+2
                mov     bx,Adler_BASE
                div     bx
                mov     word ptr Sum1,dx
                mov     word ptr Sum1+2,0
            {Sum2 := Sum2 Mod Adler_BASE}
                mov     ax,word ptr Sum2
                mov     dx,word ptr Sum2+2
                mov     bx,Adler_BASE
                div     bx
                mov     word ptr Sum2,dx
                mov     word ptr Sum2+2,0
         End ;
      End ;
      Adler.S1 := Sum1;
      Adler.S2 := Sum2;
   End {UpdateAdler32} ;

{$ELSE}

Procedure UpdateAdler32(Var Adler : tAdler ; Var InBuf ; InLen : Word);assembler;
   Asm
                push    ds
                push    bp
                les     di,Adler
                lds     si,InBuf
                mov     cx,InLen
                mov     bx,es:[di]      {dx:bx = S1}
                xor     dx,dx
                mov     bp,es:[di+2]    {di:bp = S2}
                xor     di,di
        {outer While loop}
        @wloop: test    cx,cx
                jz      @wend
                mov     ax,Adler_NMAX
                cmp     cx,ax
                jae     @lab1
                mov     ax,cx
        @lab1:  sub     cx,ax
                push    cx
                mov     cx,ax
                xor     ah,ah
        {inner For loop}
        @floop: lodsb
                add     bx,ax
                adc     dx,0
                add     bp,bx
                adc     di,dx
                dec     cx
                jnz     @floop
        {end of inner For loop}
                mov     cx,Adler_BASE
        {Sum1 := Sum1 Mod Adler_BASE}
                mov     ax,bx
                div     cx
                mov     bx,dx
        {Sum2 := Sum2 Mod Adler_BASE}
                mov     ax,bp
                mov     dx,di
                div     cx
                mov     bp,dx
                xor     dx,dx
                xor     di,di
                pop     cx
                jmp     @wloop
        {end of outer While loop}
        @wend:
                mov     ax,bp
                pop     bp
                mov     di,word ptr Adler
                mov     es:[di],bx
                mov     es:[di+2],ax
                pop     ds
   End {UpdateAdler32} ;

{$ENDIF}

Function  FinalAdler32 (Adler : tAdler) : LongInt ;
   Begin
      FinalAdler32 := Adler.Value
   End {FinalAdler32} ;

End.
