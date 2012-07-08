{ Поиск всех возможных маршрутов между двумя точками графа }
program all_road;
const
     N=7;{ кол-во вершин графа}
var
     map:array[1..N,1..N] of integer;{ Карта: map[i,j] не 0,
                                       если точки i и j соединены }
     road:array[1..N] of integer;{ Маршрут - номера точек карты }
     incl:array[1..N] of boolean;{ incl[i]=TRUE, если точка }
                                { с номером i включена в road }

     start,finish:integer;{ Начальная и конечная точки }

     i,j:integer;

procedure step(s,f,p:integer);{ s - точка, из которой делается шаг}
                              { f - конечная точка маршрута}
                              { p - номер искомой точки маршрута}
var
     c:integer;{ Номер точки, в которую делается очередной шаг }
begin
     if s=f then begin
          {Точки s и f совпали!}
          write('Путь: ');
          for i:=1 to p-1 do write(road[i],' ');
          writeln;
     end
     else begin
               { Выбираем очередную точку }
               for c:=1 to N do begin { Проверяем все вершины }
                    if(map[s,c]<>0)and(NOT incl[c])
                    { Точка соединена с текущей и не включена }
                    { в маршрут}
                    then begin
                         road[p]:=c;{ Добавим вершину в путь }
                         incl[c]:=TRUE;{ Пометим вершину }
                                       { как включенную }
                         step(c,f,p+1);
                         incl[c]:=FALSE;
                         road[p]:=0;
                    end;
               end;
     end;
end;{ конец процедуры step }

{ Основная программа }
begin
     { Инициализация массивов }
     for i:=1 to N do road[i]:=0;
     for i:=1 to N do incl[i]:=FALSE;
     for i:=1 to N do for j:=1 to N do map[i,j]:=0;
     { Ввод значений элементов карты }
     map[1,2]:=1; map[2,1]:=1;
     map[1,3]:=1; map[3,1]:=1;
     map[1,4]:=1; map[4,1]:=1;
     map[3,4]:=1; map[4,3]:=1;
     map[3,7]:=1; map[7,3]:=1;
     map[4,6]:=1; map[6,4]:=1;
     map[5,6]:=1; map[6,5]:=1;
     map[5,7]:=1; map[7,5]:=1;
     map[6,7]:=1; map[7,6]:=1;
     write('Введите через пробел номера начальной и конечной точек -> ');
     readln(start,finish);
     road[1]:=start;{ Внесем точку в маршрут }
     incl[start]:=TRUE;{ Пометим ее как включенную }

     step(start,finish,2);{Ищем вторую точку маршрута }

     writeln('Для завершения нажмите <Enter>');
     readln;
end.

