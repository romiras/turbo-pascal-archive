program fifo_st;
uses CRT;

const FIFOsize=10;

type TFIFO = array[1..FIFOsize] of byte;

function getelem:byte;
var s:byte;
begin
	write('Введите число : ');
	readln(s);
	getelem:=s;
end;

procedure push (var FIFO:TFifo;var root,tail:integer;info:byte);
begin
	if ((tail=root) and (root<>0)) then	(* Если очередь переполнена *)
		writeln('Очередь переполнена')	(* Сообщить об этом *)
	else	(* Иначе *)
		begin	
			if (root=0) then	(* Если очередь пуста *)
				begin
					root:=1;  (* Создать новую очередь *)
					tail:=1; 
				end;
			fifo[tail]:=info; (* Занести элемент в очередь *)
			inc(tail); (* Передвинуть указатель хвоста очереди на 1 вправо *)
			if (tail>FIFOSize) then	(* Если указатель вышел за конец массива *)
				tail:=1;	(* Перенести его в начало массива *)
		end;
end;

procedure pop(var FIFO:TFifo;var root,tail:integer);
begin
	if (tail=0) then		(* Если очередь пуста *)
		writeln('Очередь пуста') 	(* Сообщить об этом *)
	else	(* Иначе *)	
		begin
			writeln('Извлечённое число : ',FIFO[root]); (* Извлечь число из очереди *)
			inc(root);			(* Сдвинуть указатель корня очереди на 1 вправо *)
			if (root>FIFOSize) then	(* Если корень вышел за пределы массива *)
				root:=1;		(* Вернуть его в начало *)
			if (root=tail) then	 (* Если из очереди извлечён последний элемент *)
				begin
					root:=0;		(* Создать пустую очередь *)
					tail:=0;
				end;
		end;
end;

procedure showmenu;
begin
	Writeln(' 1) Push');
	Writeln(' 2) Pop');
	Writeln(' 3) Выход');
	Write(' -> ');
end;

var root,tail:integer;
	FIFO:TFIFO;
	selection:integer;

begin
	root:=0;
	tail:=0;
	Writeln('Очередь. Статическая реализация.');
	repeat			
		showmenu;			(* Показать меню *)
		readln(selection);		(* Ввести с клавиатуры пункт меню *)
		case selection of		(* Выполнить действие, затребованное пользователем *)
			1: push(FIFO,root,tail,getelem); 
			2: pop(FIFO,root,tail);
			3: clrscr;
		end;
	until selection=3;		(* Если пользователь выбрал не выход, повторить *)
end.
