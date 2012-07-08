{
Дано натур. число N. Определить кол-во 8 значных чисел,
у которых сумма цифр в цифровой записи числа меньше, чем N.
Если таких чисел нет, выводим НЕТ.
}

program _8digits;

function SumOfDigits (x: longint): integer;
var
  rem,
  sum: integer;
begin
	sum := 0;
	While X <> 0 Do
	Begin
		rem := X Mod 10;
		inc (sum, rem);
		X:=X Div 10;
	End;
	SumOfDigits := sum;
end;

var
  n, count: integer;
  i : longint;

begin
  write ('Enter 1 <= n <= 72 : '); readln (n);
  count := 0;

  for i := 10000000 to 99999999 do
  begin
        if i mod 10000 = 0 then
           writeln (i);
	if SumOfDigits (i) < N then
		inc(count);
  end;
  
  if count = 0 then 
	writeln('none')
  else
	writeln('count = ', count);
  readln;
end.
  