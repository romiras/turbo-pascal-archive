{ From : Dmitry Karasik   2:464/46.36     25.04.97
 Subj : Преобразование RGB <-> HLS  
--------------------------------------------------}
{Hue, Luminocity, Saturation}
Procedure RGBToHLS(R, G, B : Word; var H, L, S : integer);
Var
  cr,cg,cb,m1,m2,ir,ig,ib,ih,il,is:real;
Begin
  m1 := MaxWord(MaxWord(r, g), b) / 63;
  m2 := MinWord(MinWord(r, g), b) / 63;
  ir := r / 63;
  ig := g / 63;
  ib := b / 63;
  il := (m1 + m2) / 2;
  if m1 = m2 then begin
    is := 0;
    ih := 0;
  end else begin
    if il <= 0.5 then is := (m1 - m2) / (m1 + m2) else
      is := (m1 - m2) / (2 - m1 - m2);
    cr := (m1 - ir) / (m1 - m2);
    cg := (m1 - ig) / (m1 - m2);
    cb := (m1 - ib) / (m1 - m2);
    if ir = m1 then ih := cb - cg;
    if ig = m1 then ih := 2 + cr - cb;
    if ib = m1 then ih := 4 + cg - cr;
  end;
  h := Round(60 * ih);
  if h < 0 then h := h + 360;
  l := Round(il * 100);
  s := Round(is * 100);
End;

Procedure HLSToRGB(H, L, S : Word; var R, G, B : Integer);

Function XRGB(HH, mm1, mm2 : Real) : Real;
Begin
  if hh < 0 then hh := hh + 360;
  if hh > 360 then hh := hh - 360;
  if hh < 60 then xrgb := mm1 + (mm2 - mm1) * hh / 60 else
    if hh < 180 then xrgb := mm2 else
      if hh < 240 then xrgb := mm1 + (mm2 - mm1) * (240 - hh) / 60 else
        xrgb := mm1;
End;

Var
  cr,cg,cb,m1,m2,ir,ig,ib,ih,il,is : Real;
Begin
  il := l / 100;
  ih := h;
  is := s / 100;
  if il <= 0.5 then m2 := il * (1 + is) else m2 := il + is - il * is;
  m1 :=2 * il - m2;
  if s = 0 then begin
    ir := il;
    ig := il;
    ib := il
  end else begin
    ir := XRGB(ih + 120, m1, m2);
    ig := XRGB(ih , m1, m2);
    ib := XRGB(ih - 120, m1, m2);
  end;
  r := Round(ir * 63);
  g := Round(ig * 63);
  b := Round(ib * 63);
End;



Procedure GetDeviceExtension(Device : Pointer; var Ext : TRect);
Begin
  Ext.A.X := 0;
  Ext.A.Y := 0;
  if Device = Nil then begin
    Ext.B.X := ScreenDriver^.MaximalX;
    Ext.B.Y := ScreenDriver^.MaximalY;
  end else begin
    Ext.B.X := PSImage(Device)^.X - 1;
    Ext.B.Y := PSImage(Device)^.Y - 1;
  end;
End;

Function IsImageStreamed(Image : PImage) : Boolean;
Begin
  IsImageStreamed := (PSImage(Image)^.NBP and imFlatStream) <> 0;
End;

