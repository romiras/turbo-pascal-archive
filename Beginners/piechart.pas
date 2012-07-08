program PieChart;

{ Программа строит диаграмму, состоящую из процентного соотношения 25% + 60% + 15% }

uses Graph;

const
     Radius = 80;

     p1 = 0.25; { Примечание: проценты в сумме должны давать 1.0 (100%) }
     p2 = 0.6;
     p3 = 0.15;

var
   x, y,
   _From,
   _To : integer;
   Gd, Gm: Integer;

procedure DrawPie (percent: single); { Рисует сектор - процент от круга }
begin
 SetFillStyle(XHatchFill, 1 + Random (14));
{ 1-й параметр устанавливает тип закраски, а второй - случайный цвет в диапазоне от 1 до 14 }

 _To := _From + Round (percent * 360.0); { percent * 360.0  -это процент от круга (360 градусов) }
 PieSlice(x, y, _From, _To, Radius);
 _From := _To; { Как только нарисовали 1 сектор, запоминаем конечный угол предыдущего в начало следующего }
end;

begin
 Randomize;
 Gd := Detect;
 InitGraph(Gd, Gm, '..\bgi');
 if GraphResult <> grOk then
   Halt(1);
 x := GetMaxX div 2;
 y := GetMaxY div 2;

 _From := 0; { Начальный угол сектора равен нулю }
 DrawPie (p1);
 DrawPie (p2);
 DrawPie (p3);

 Readln;
 CloseGraph;
end.