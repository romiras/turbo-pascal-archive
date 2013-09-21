program deck_st;
uses CRT;

const decksize=10;

type TDeck = array[1..Decksize] of byte;

function getelem:byte;
var s:byte;
begin
	write('Введите число : ');
	readln(s);
	getelem:=s;
end;

procedure pushbegin (var Deck:TDeck; var root,tail:integer;info:byte);
begin
	if (tail=root) and (root<>0) then (* Если указатели корня и хвоста совпадают и дек не пуст, то *)
		writeln('Дек переполнен') (* Дек переполнен, сообщить *)
	else  (* Иначе *)
		begin
			if (tail=0) then  (* Если дек пуст *)
				begin
					root:=decksize;  (* Создать новый дек *)
					tail:=decksize;
				end;
			dec(root);			(* Сдвинуть указатель корня на 1 влево *)
			if (root<1) then  (* Если указатель вышел за начало массива, *)
				root:=decksize;  (* Переставить его в конец *)
			deck[root]:=info;  (* Записать элемент в дек *)
		end;
end;

procedure pushend (var Deck:TDeck;var root,tail:integer;info:byte);
begin
	if ((tail=root) and (tail<>0)) then (* Если указатели корня и хвоста совпадают и дек не пуст, то *)
		writeln('Дек переполнен') (* Дек переполнен, сообщить *)
	else (* Иначе *)
		begin
			if (tail=0) then  (* Если дек пуст *)
				begin
					root:=1;    (* Создать новый дек *)
					tail:=1;
				end;
			deck[tail]:=info;  (* Записать элемент в дек *)
			inc(tail);	(* Сдвинуть указатель хвоста на 1 вправо *)
			if (tail>decksize) then  (* Если указатель вышел за конец массива *)
				tail:=1;   (* Переставить его в начало массива *)
		end;
end;

procedure popbegin(var Deck:TDeck;var root,tail:integer);
begin
	if (tail=0) then	(* Если дек пуст, *)
		writeln('Дек пуст') (* Сообщить об этом *)
	else (* Иначе *)
		begin
			writeln('Извлечённое число : ',Deck[root]);  (* Извлечь число из дека *)
			inc(root); 	(* Сдвинуть на 1 вправо указатель корня *)
			if (root>DeckSize) then (* Если указатель корня вышел за конец массива *)
				root:=1; (* Переставить его в начало *)
			if (root=tail) then  (* Если из дека извлечён последний элемент *)
				begin
					root:=0; 	(* "Уничтожить" дек *)
					tail:=0;
				end;
		end;
end;

procedure popend(var Deck:TDeck;var root,tail:integer);
begin
	if (tail=0) then   (* Если дек пуст, то *)
		writeln('Дек пуст') (* Сообщить об этом *)
	else	(* Иначе *)
		begin
			dec(tail); (* Сдвинуть указатель хвоста на 1 влево *)
			if (tail<1) then	(* Если указатель вышел за начало дека, *)
				tail:=DeckSize;	 (* Переставить его в конец *)
			writeln('Извлечённое число : ',Deck[tail]); (* Извлечь из дека число *)
			if (root=tail) then (* Если из дека извлечён последний элемент *)
				begin
					root:=0;   (* "Уничтожить" дек *)
					tail:=0;
				end;
		end;
end;

procedure showmenu;
begin
	Writeln(' 1) Push в начало');
	Writeln(' 2) Pop из начала');
	Writeln(' 3) Push в конец');
	Writeln(' 4) Pop из конца');
	Writeln(' 5) Выход');
	Write(' -> ');
end;

var root,tail:integer;
	Deck:TDeck;
	selection:integer;

begin
	root:=0;
	tail:=0;
	Writeln('Дек. Статическая реализация.');
	repeat			
		showmenu;			(* Показать меню *)
		readln(selection);		(* Ввести с клавиатуры пункт меню *)
		case selection of		(* Выполнить действие, затребованное пользователем *)
			1: pushbegin(Deck,root,tail,getelem); 
			2: popbegin(Deck,root,tail);
			3: pushend(Deck,root,tail,getelem); 
			4: popend(Deck,root,tail);
			5: clrscr;
		end;
	until selection=5;		(* Если пользователь выбрал не выход, повторить *)
end.
