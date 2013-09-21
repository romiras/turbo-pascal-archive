uses
  Graph, BmpWrite;

procedure Initialize;
var
  GraphDriver, GraphMode: Integer;
begin
  GraphDriver := Detect;
  InitGraph(GraphDriver, GraphMode, '');
end;

var
  BarSizeX, BarSizeY, Color, X: Word;

begin
  Initialize;

  BarSizeX := GetMaxX div 16;
  BarSizeY := GetMaxY;
  for Color := 0 to 15 do
  begin
    SetFillStyle(SolidFill, Color);
    X := BarSizeX * Color;
    Bar(X, 0, X + BarSizeX, BarSizeY);
  end;
  WriteLn('Демонстрация записи изображения в BMP-файл');

  WriteBMPFile('TEST.BMP');

  Write('Для продолжения нажмите клавишу <Enter>...');
  ReadLn;
  CloseGraph;
end.
