{ Сортировка слов в предложении методом пузырьковой сортировки }
program bubblesort;

function prevspace(s:string;from:integer):integer;
begin
	repeat
		dec(from);		
	until (copy(s,from,1)=' ') or (from=1);
	while (copy(s,from-1,1)=' ') and (from>1) do
		dec(from);
	if (from=1) then
		dec(from);
	prevspace:=from;
end;

function nextspace(s:string;from:integer):integer;
begin
	repeat
		inc(from);		
	until (copy(s,from,1)=' ') or (from=length(s));
	while(copy(s,from+1,1)=' ') and (from<length(s)) do
		inc(from);
	if (from=length(s)) then
		inc(from);
	nextspace:=from;
end;

function strcmp(s1,s2:string):boolean;
begin
	strcmp:=s1>s2;
end;

procedure bsort(var s:string);
var i,j,nw,nnw:integer;
	forswap:string;
begin
	i:=length(s)+1;
	while (i>nextspace(s,1)) do (* Пока i не дойдёт с последнего слова до первого *)
		begin
			j:=0;
			while (j<prevspace(s,i)) do (* Перебирать все слова с j-того до i-1-го : *)
				begin
					nw:=nextspace(s,j);
					nnw:=nextspace(s,nw);
					if strcmp(copy(s,j+1,nw-j-1),copy(s,nw+1,nnw-nw-1)) then (* Если текущее слово больше следующего, то *)
						begin
							forswap:=copy(s,nw,nnw-nw); (* Вырезать следующее слово из строки с пробелом перед ним *)
							delete(s,nw,nnw-nw); 
							if (j=0) then  (* Если вставляем в начало строки *)
								begin
									delete(forswap,1,1); (* Перестить пробел из начала слова в его конец *)
									forswap:=forswap+' ';
								end;
							insert(forswap,s,j); (* Вставить слово в строку перед текущим *)
						end;
					j:=nextspace(s,j); 
				end;
			i:=prevspace(s,i);
		end;
end;

var s:string;

begin
	writeln('Введите строку для пузырьковой сортировки : ');
	readln(s); 	(* Ввести строку для сортировки *)
	bsort(s); (* Отсортировать её *)
	writeln('Отсортированная строка : ');
	writeln(s); (* Вывести её на экран *)
end.
