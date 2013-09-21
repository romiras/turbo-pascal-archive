program qsort;
uses crt;

const MaxArrSize = 20;

type TArr = array[1..MaxArrSize] of integer;

procedure GetArray(var arr:Tarr; var arrsize:integer);
var i:integer;
begin
{
	write('Введите размер массива, который нужно отсортировать (',1,'..',MaxArrSize,') : ');
	readln(arrsize);
}
	arrsize:=MaxArrSize;
	for i:=1 to arrsize do
		arr[i]:=-500+random(1001);
end;

Procedure PrintArray(arr:TArr;arrsize:integer);
var i:integer;
begin
	for i:=1 to arrsize-1 do
		write(arr[i],',');
	writeln(arr[arrsize],'.');
end;

procedure eswap(var s1,s2:integer);
var t:integer;
begin
	t:=s1;
	s1:=s2;
	s2:=t;
end;

procedure quicksort(var arr:Tarr;ifrom,ito:integer);
var divider:integer;
	i,j:integer;
begin
	if (ifrom<ito) then
		if (ito-ifrom=1) then
			begin
				if (arr[ito]<arr[ifrom]) then
					eswap(arr[ito],arr[ifrom]);
			end
		else
		begin
			divider:=arr[(ifrom+ito) div 2];
			eswap(arr[(ifrom+ito) div 2],arr[ifrom]);
			i:=ifrom+1;
			j:=ito;
			repeat
					while ((i<=j) and (arr[i]<divider)) do
						inc (i);

					while (arr[j]>divider) do
						dec(j);

					if (i<j) then
						eswap(arr[i],arr[j]);
						
			until (i>=j);

			arr[ifrom]:=arr[j];
			arr[j]:=divider;

			quicksort(arr,ifrom,j-1);
			quicksort(arr,j+1,ito);
		end;
	
end;

var arr:TArr;
	ArrSize:Integer;

begin
	clrscr;
	writeln('Быстрая сортировка массива.');
	GetArray(Arr,ArrSize);
	clrscr;
	writeln('Исходный массив : ');
	PrintArray(Arr,Arrsize);
	quicksort(Arr,1,Arrsize);
	writeln('Отсортированный массив : ');
	PrintArray(Arr,Arrsize);
	writeln('Нажмите любую клавишу для выхода.');
	readkey;
end.
