unit vga256;

interface

  uses
    Crt,Dos;

  type
    ColorValue = record Rvalue,Gvalue,Bvalue: byte; end;
    vgaPaletteType = array [0..255] of ColorValue;

  procedure InitVGA256;
  procedure CloseVGA256;
  procedure vgaPutPixel(x,y: integer; c: byte);
  function vgaGetPixel(x,y: integer): byte;
  procedure vgaSetAllPalette(var p: vgaPaletteType);

implementation

  procedure InitVGA256;
  begin { procedure InitVGA256 }
    Inline($B8/$13/0/$CD/$10);
  end; { procedure InitVGA256 }

  procedure CloseVGA256;
  begin { procedure CloseVGA256 }
    TextMode(LastMode);
  end; { procedure CloseVGA256 }

  procedure vgaPutPixel(x,y: integer; c: byte);
  begin { procedure vgaPutPixel }
    Mem[$A000:word(320*y+x)]:=c;
  end; { procedure vgaPutPixel }

  function vgaGetPixel(x,y: integer): byte;
  begin { function vgaGetPixel }
    vgaGetPixel:=Mem[$A000:word(320*y+x)];
  end; { function vgaGetPixel }

  procedure vgaSetAllPalette(var p: vgaPaletteType);
    var regs: Registers;
  begin { procedure vgaSetAllPalette }
    with regs do
      begin
        AX:=$1012;
        BX:=0;
        CX:=256;
        ES:=Seg(p);
        DX:=Ofs(p);
      end;
    Intr($10,regs);
  end; { procedure vgaSetAllPalette }

end.