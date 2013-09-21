{█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█}
{█   Модуль для записи файла в формате BMP   █}
{█───────────────────────────────────────────█}
{█     Copyright (C) 2003 Георгий Земцов     █}
{█         e-mail: george_grg@mail.ru        █}
{█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█}

unit
  BMPWrite;

interface

{ Заголовок файла }
type
  bmpFileHeader = record
    Typ     : Word;        { Сигнатура }
    Size    : Longint;     { Длина файла в байтах }
    Res     : Longint;     { Зарезервировано }
    OffBits : Longint;     { Смещение изображения в байтах (118) }
  end;

{ Информационный заголовок }
type
  bmpInfoHeader = record
    Size         : Longint;     { Длина заголовка в байтах (40) }
    Width        : Longint;     { Ширина изображения (в точках) }
    Height       : Longint;     { Высота изображения (в точках) }
    Planes       : Word;        { Число плоскостей (1) }
    BitCount     : Word;        { Глубина цвета (бит на точку) (8) }
    Compression  : Longint;     { Тип компрессии (0 - нет) }
    SizeImage    : Longint;     { Размер изображения в байтах }
    Xppm         : Longint;     { Горизонтальное разрешение    }
                                {   (точек на метр - обычно 0) }
    Yppm         : Longint;     { Вертикальное разрешение      }
                                {   (точек на метр - обычно 0) }
    ClrUsed      : Longint;     { Число цветов                        }
                                {   (если максимально допустимое - 0) }
    ClrImportant : Longint;     { Число основных цветов }
  end;

{ Полный заголовок файла }
type
  bmpHdrPtr = ^bmpHeader;
  bmpHeader = record
    F: bmpFileHeader;                   { Заголовок файла }
    I: bmpInfoHeader;                   { Информационный заголовок }
    P: array[0..15, 0..3] of Byte;      { Таблица палитры }
  end;

{ Запись заголовка BMP-файла }
procedure WriteBMPHeader(Header: bmpHdrPtr; FileName: String);

{ Запись 4-bit изображения в BMP-файл }
procedure WriteBMPFile(FileName: String);

implementation

uses
  Graph;

procedure Abort(Message: String);
begin
  CloseGraph;
  WriteLn(Message);
  Halt;
end;

procedure WriteBMPHeader(Header: bmpHdrPtr; FileName: String);
var
  bmpFile: File;
begin
  Assign(bmpFile, FileName);
  {$I-} ReWrite(bmpFile, 1); {$I+}
  if IOResult <> 0 then
    Abort('Ошибка при создании BMP-файла');
  BlockWrite(bmpFile, Header^, SizeOf(Header^));
  Close(bmpFile);
end;


procedure WriteBMPFile(FileName: String);
var
  F: File;
  Width, ImgBufSize, LnBufSize, segImgBuf, ofsImgBuf, segLnBuf, ofsLnBuf,
  GlobalOffset, Y, Offset, BitPos: Word;
  ImageBuf, LineBuf: Pointer;
  Pos, bSrc, bDst: Byte;
  PixNum: Word;     { Номер точки (от 0 до N-1) }
  BitNum: Byte;     { Позиция бита в цвете (от 0 до 3) }

procedure UpdateHeader;

{ Палитра }
const
  Palette: array[0..15, 0..2] of Byte = (
    { Black        │  0 │ Черный            } (  0,   0,   0),
    { Blue         │  1 │ Синий             } ( 64,  64,  64),
    { Green        │  2 │ Зеленый           } (  0,   0, 128),
    { Cyan         │  3 │ Циан              } ( 64,  64, 255),
    { Red          │  4 │ Красный           } (  0, 128,   0),
    { Magenta      │  5 │ Фиолетовый        } ( 64, 255,  64),
    { Brown        │  6 │ Коричневый        } (  0,  64, 128),
    { LightGray    │  7 │ Светло-серый      } ( 64, 255, 255),
    { DarkGray     │  8 │ Темно-серый       } (128,   0,   0),
    { LightBlue    │  9 │ Светло-синий      } (255,  64,  64),
    { LightGreen   │ 10 │ Светло-зеленый    } (128,   0, 128),
    { LightCyan    │ 11 │ Светло-циан       } (255,  64, 255),
    { LightRed     │ 12 │ Светло-красный    } (128, 128,   0),
    { LightMagenta │ 13 │ Светло-фиолетовый } (255, 255,  64),
    { Yellow       │ 14 │ Желтый            } (128, 128, 128),
    { White        │ 15 │ Белый             } (255, 255, 255)
  );

var
  Header: bmpHdrPtr;
  Color: Byte;

begin
  GetMem(Header, SizeOf(bmpHeader));

  with Header^.F do
  begin
    Typ     := $4D42;
    Size    := $FFFF;
    OffBits := 118;
  end;

  with Header^.I do
  begin
    Size         := 40;
    Width        := 640;
    Height       := 480;
    Planes       := 1;
    BitCount     := 4;
    Compression  := 0;
    SizeImage    := Size - Header^.F.OffBits;
    Xppm         := 0;
    Yppm         := 0;
    ClrUsed      := 0;
    ClrImportant := 0;
  end;

  for Color := 0 to 15 do
  begin
    Header^.P[Color, 0] := Palette[Color, 0];
    Header^.P[Color, 1] := Palette[Color, 1];
    Header^.P[Color, 2] := Palette[Color, 2];
    Header^.P[Color, 3] := 0;
  end;

  WriteBMPHeader(Header, FileName);

  FreeMem(Header, SizeOf(bmpHeader));
end;

{ Проверить, установлен ли в "1" бит в позиции Pos }
function GetBit(B, Pos: Byte): Boolean;
begin
  GetBit := Odd(B shr Pos);
end;

{ Установить бит Pos в "1" }
procedure SetBit(var B: Byte; Pos: Byte);
begin
  B := B or (1 shl Pos);
end;

{ Установить бит Pos в "0" }
procedure ClrBit(var B: Byte; Pos: Byte);
begin
  if GetBit(B, Pos) then
    B := B xor (1 shl Pos);
end;

{ Поменять местами младшие и старшие 4 бита }
function SwapBits(B: Byte): Byte;
var
  Temp, Pos: Byte;
begin
  Temp := 0;
  for Pos := 0 to 3 do
    if GetBit(B, Pos) then
      SetBit(Temp, Pos + 4);
  for Pos := 4 to 7 do
    if GetBit(B, Pos) then
      SetBit(Temp, Pos - 4);
  SwapBits := Temp;
end;

begin
  UpdateHeader;

  Assign(F, FileName);
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then
    Abort('Ошибка при записи изображения в BMP-файл');
  Seek(F, FileSize(F));

  Width := GetMaxX;

  ImgBufSize := ImageSize(0, 0, Width, 0);
  GetMem(ImageBuf, ImgBufSize);
  if ImageBuf = nil then
    Abort('Ошибка распределения памяти - ImageBuf');
  segImgBuf := Seg(ImageBuf^);
  ofsImgBuf := Ofs(ImageBuf^) + 4;

  LnBufSize := Width div 2;
  if Width mod 2 <> 0 then
    Inc(LnBufSize);
  GetMem(LineBuf, LnBufSize);
  if LineBuf = nil then
    Abort('Ошибка распределения памяти - LineBuf');
  segLnBuf := Seg(LineBuf^);
  ofsLnBuf := Ofs(LineBuf^);

  GlobalOffset := ((Width div 8) + 1) * 8;

  for Y := GetMaxY downto 0 do
  begin
    GetImage(0, Y, Width, Y, ImageBuf^);

    Offset := 0;

    Pos := 0;
    for PixNum := 0 to Width do
    begin
      for BitNum := 0 to 3 do
      begin
        BitPos := GlobalOffset * BitNum + PixNum;
        bSrc := Mem[segImgBuf:ofsImgBuf + BitPos div 8];
        if GetBit(bSrc, 7 - BitPos mod 8) then
          SetBit(bDst, Pos)
        else
          ClrBit(bDst, Pos);
        Inc(Pos);
      end;
      if Pos > 7 then
      begin
        Mem[segLnBuf:ofsLnBuf + Offset] := SwapBits(bDst);
        Inc(Offset);
        Pos := 0;
      end;
    end;
    if Pos = 4 then
    begin
      for Pos := 4 to 7 do
        ClrBit(bDst, Pos);
      Mem[segLnBuf:ofsLnBuf + Offset] := SwapBits(bDst);
    end;

    BlockWrite(F, LineBuf^, LnBufSize);
  end;

  FreeMem(ImageBuf, ImgBufSize);
  FreeMem(LineBuf, LnBufSize);

  Close(F);
end;

end.
