;
; CPU Frequency detection
;
;******************************************************************************
;*              HPL, Copyright (C) 1991,92 Sandy Company, ltd.                *
;*                          All Right Reserved                                *
;******************************************************************************
;File:       _MHZ.ASM
;Comments:   Sorry, it's my style :).

Ideal
Model        Small
CodeSeg
P8086                                       ; For support Intel 8086

i8886        EQU     0                      ; Intel 8086/88
V2030        EQU     1                      ; NEC V20/V30
i188186      EQU     2                      ; Intel 80186/188
i80286       EQU     3                      ; Intel 80286
i80386       EQU     4                      ; Intel 80386/486

Sprite       EQU     08Bh,0C6h,0F7h,0F3h    ; Mov Ax,Si / Div Bx

Public       _mhz                           ; Public name is _mhz

Proc         _mhz    Far                    ; Is far procedure
             PushF                          ; Save Flags
             Push    Di Si                  ; Save Di Si
             Call    Processor              ; Call Processor Procedure
             Call    Speed                  ; Call Speed Procedure
             Pop     Si Di                  ; Restore Si Di
             PopF                           ; Restore Flags
             Ret                            ; Return to Main Programm

Proc         Processor Near                 ; Checking for processors
;Jumps                                       ; Directive for Jz,Jb,Ja e.t.c
             Push    Sp                     ; Save Sp
             Pop     Ax                     ; Restore Sp into Ax
             Cmp     Sp,Ax                  ; If Sp!=Ax then Check Lower FPU
             Jnz     @@Low                  ; Jump to @@Low
             Mov     Ax,7000h               ; Ax=7000h
             Push    Ax                     ; Save Ax into Stack
             PopF                           ; Restore Ax into Flags
             Sti                            ; On Interrupt flag
             PushF                          ; Save Flags
             Pop     Ax                     ; Restore Flags Into Ax
             And     Ax,7000h               ; If highers flags has non zero
             Jnz     @@80386                ; Intel 386/486 is present
             Mov     Dl,i80286              ; Dl=i80286
             Jmp     @@Exit                 ; Jump to @@Exit
@@80386:                                    ;
             Mov     Dl,i80386              ; Dl=80386/486/SXs
             Jmp     @@Exit                 ; Jump to @@Exit

P8086                                       ; For Support Intel 8086
@@Low:
             Mov     Cl,21h                 ; Test for lowest processors
             Mov     Ax,-1                  ; Ax=0FFFFh
             Shl     Ax,Cl                  ; Shift lef on 21h bits
             Jz      @@NEC                  ; If Zero jump to@@NEC
             Mov     Dl,i188186             ; Else Dl=i80188/186
             Jmp     @@Exit                 ; Jump to Exit
@@NEC:
             Mov     Al,40h                 ; Al=40h
             Mul     Al                     ; Ax=Al*Al
             Jnz     @@8088                 ; If Zero then Jump to @@8088
             Mov     Dl,V2030               ; Else Dl=NECv20/v30
             Jmp     @@Exit                 ; Jump to Exit
@@8088:
             Mov     Dl,i8886               ; Dl=i8088/86
@@Exit:
             Mov      Al,Dl                 ; Al=Dl
             Xor      Ah,Ah                 ; Ah=0
             Ret                            ; Return
Endp         Processor                      ; End Of Processors Procedure

Proc         SetTimer Near                  ; SetTimer procedure
             In      Al,61h                 ; Get Al from 61th port
             And     Al,0FCh                ; Zero first bit
             Out     61h,Al                 ; Put Al on 61th port
             Mov     Al,180                 ; Al=Command
             Out     43h,Al                 ; Put AL to Command's port
             Xor     Al,Al                  ; Al=0
             Out     42h,Al                 ; Put low Time to 42th port
             Jmp     $+2                    ; Wait
             Out     42h,Al                 ; Put high Time
             In      Al,61h                 ; Get Al from 61th port
             Or      Al,1                   ; Set First bit
             Cli                            ; Clear Interrupt
             Out     61h,Al                 ; Start Timer
             Ret                            ; Return
EndP         SetTimer                       ; End of procedure

Proc         GetTimer Near                  ; GetTimer Procedure
             In      Al,61h                 ; Get al from 61th port
             And     Al,0FCh                ; Zero first bit (stop timer)
             Out     61h,Al                 ; Put Al into 61th port.
             In      Al,42h                 ; Get AL from 42th port
             Mov     Ah,Al                  ; Ah=Al
             In      Al,42h                 ; Get Al from 42th port
             Xchg    Al,Ah                  ; Al=Ah ; Ah=Al
             Neg     Ax                     ; Ax=Negative Ax
             Sti                            ; Set interrupt flag
             Ret                            ; Return
EndP         GetTimer                       ; End of GetTimer procedure

Proc         Speed   Near                   ; Speed procedure ( Inp: Al=CPU )
             Push    Ax                     ; Save Ax
             Mov     Si,07AAAh              ; Si=07AAAh (Air value)
             Mov     Bx,05555h              ; Bx=05555h (Air value)
             Mov     Cx,10                  ; Cx=10
             Cmp     Al,i8886               ; If Al<=i8086
             Jbe     @@Test                 ; Jump to Test
             Mov     Cx,50                  ; Cx=50
             Cmp     Al,V2030               ; If Al<=NECv20/v30
             Jbe     @@Test                 ; Jump to Test
             Mov     Cx,100                 ; Cx=100
             Cmp     Al,i188186             ; If Al<=I80188/186
             Jbe     @@Test                 ; Jump to Test
             Mov     Cx,200                 ; Cx=200
@@Test:
             Push    Cx                     ; Save Cx
             Xor     Dx,Dx                  ; Dx=0
             Call    SetTimer               ;
@@PASS_A:    DB      66 DUP(Sprite)         ;
             Dec     Cx                     ; Cx=Cx-1
             Jz      @@Passed_A             ; If Cx=0 the Jump to @@Passed_A
             Jmp     @@PASS_A               ; Jump to @@Pass_A
@@Passed_A:  Call    GetTimer               ;
             Mov     Di,Ax                  ;
             Pop     Cx                     ; Restore Cx
             Xor     Dx,Dx                  ; Dx=0
             Call    SetTimer               ;
@@PASS_B:    DB      2 DUP(Sprite)          ;
             Dec     Cx                     ; Cx=Cx-1
             Jz      @@Passed_B             ;
             Jmp     @@PASS_B               ;
@@Passed_B:  Call    GetTimer               ;
             Sub     Di,Ax                  ; Di=Di-Ax
             Pop     Bx                     ; Restore Ax into Bx
             Shl     Bx,1                   ;
             Shl     Bx,1                   ; Bx=Bx*4
             ADD     Bx,Offset Denom        ; Bx=Bx+&Denom
             Mov     Ax,[Cs:Bx]             ; Dx:Ax=Denom
             Mov     Dx,[Cs:Bx+2]           ;
             Cmp     Di,Dx                  ; If Di<Dx then Ax=9999
             Jb      @@Overflow             ; Go to Overflow
             Div     Di                     ; Ax=Dx:Ax/Di
             Jmp     @@Exit                 ; Jump to @@Exit
@@Overflow:  Mov     Ax,33300               ; Ax=33300
@@Exit:      Ret                            ; Return

Label        Denom   Word                   ; Constants for
             DD      00B6F062h              ; Intel 8088/86
             DD      00B4D716h              ; NEC V20/V30
             DD      01D21634h              ; Intel 80188/186
             DD      022FE1B0h              ; Intel 80286
             DD      02469BC6h              ; Intel 80386/486/SXs
EndP         Speed                          ; End of Speed procedure
EndP         _mhz                           ; End of _mhz procedure

End                                         ; End of File


---- HPL ----
