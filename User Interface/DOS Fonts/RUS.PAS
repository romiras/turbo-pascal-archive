Unit Rus;

interface

implementation

Procedure SetUpFont(p : pointer);far;Assembler;
Asm
  Mov Ax,1110h
  Mov Bx,1000h
  Mov Cx,100h
  Xor Dx,Dx
  Push Bp
  Les Bp,P
  Int 10h
  Pop Bp
End;

var
   BakExitProc : pointer;

Procedure ResetFonts;far;
begin
  Asm
    Mov Ax,1104h
    Xor Bx,Bx
    Int 10h
  End;
  ExitProc:=BakExitProc;
end;


{$L rus_8x16.obj}
procedure font;external;

begin
   BakExitProc:=ExitProc;
   ExitProc:=@ResetFonts;
   setupfont(@font);
end.
