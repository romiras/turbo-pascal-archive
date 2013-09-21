
Program SortArray;
Uses Objects;

const
   N = 4; { кол-во элементов в массиве }
   SORT_STR: boolean = true;

type
   PInteger = ^Integer;

   List = array[1..N] of Pointer; { список указателей на ячейки данных }

   { процедурный тип для вызова функции сравнения }
   TSortFunc = function (a,b: pointer): integer;

var
  Data: List;

{$I sortfunc.inc} { подключаем дополнительный код - функция StrCmp }

{ Здесь указываем как будем сортировать данные.
  Данные для сравнения передаём в качестве указателей, будь то строки,
  числа, или даже структуры данных типа Запись }

function CompareNumbers (a,b: pointer): integer; FAR; { дальний тип связи }
begin
     if PInteger (a)^ > PInteger (b)^ then
        CompareNumbers := 1
     else
        if PInteger (a)^ = PInteger (b)^ then
           CompareNumbers := 0
        else
           CompareNumbers := -1
end;

function CompareStrings (a,b: pointer): integer; FAR;
begin
     CompareStrings := strcmp (PString (a)^, PString (b)^)
end;

procedure QuickSort (var A: List; SortFunc: TSortFunc; Lo, Hi: Integer);
{ "Быстрая сортировка". Можно применить любой другой вид сортировки }
var
  i,j: integer;
  x, y: pointer;

procedure Sort (l, r: Integer);
begin
     repeat
           x := A[(l+r) div 2];
           i := l; j := r;
           repeat
                 while SortFunc (A[i], x) < 0 do inc (i);
                 while SortFunc (A[j], x) > 0 do dec (j);
                 if i <= j then
                 begin
                      y := A[i]; A[i] := A[j]; A[j] := y; { поменять указатели местами }
                      inc (i);
                      dec (j);
                 end;
           until i > j;

           if l < j then Sort (l, j);
           l := i;
     until l >= r;
end;

begin
      Sort (Lo,Hi);
end;

procedure Input_Array;
var
  i: Integer;
  S: string;
  Num: PInteger;

begin
     Randomize; { Инициализация генератора случайных чисел }
     writeln (#13#10'*** Data input ***'#13#10);
     if SORT_STR then
     for i := 1 to N do
     begin
          write ('Enter string: ');
          readln (s);
          Data[i] := pointer (NewStr (s)); { резервируем память для строки }
     end
     else
     for i := 1 to N do
     begin
          New (Num); { резервируем память для числа }
          Num^ := random (100); { случайные числа }
          Data[i] := Num;
     end;
end;

procedure View_Array;
var
  i: Integer;
begin
     writeln (#13#10'*** Data output ***'#13#10);

     if SORT_STR then
     for i := 1 to N do
     begin
          writeln (PString (Data[i])^); { вывод строки }
          DisposeStr (PString (Data[i]));
           { освобождаем память, взятую для числа }
     end
     else
     for i := 1 to N do
     begin
          write (PInteger (Data[i])^ : 4); { вывод числа }
          Dispose (Data[i]);
           { освобождаем память, взятую для строки }
     end;

     readln;
end;

begin
     Input_Array; { ввод данных }

     { вызов процедуры сортировки }
     if SORT_STR then
        QuickSort (Data, CompareStrings, 1, N)
         { сортируем массив строк }
     else
        QuickSort (Data, CompareNumbers, 1, N);
         { сортируем массив чисел }

     View_Array; { вывод данных }
end.