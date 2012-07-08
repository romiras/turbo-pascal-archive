program deck_dyn;
uses CRT;

type pt = ^elem;
     elem = record
           info : byte;
           next,prev : pt;
     end;

function getelem:byte;
var s:byte;
begin
	write('Введите число : ');
	readln(s);
	getelem:=s;
end;

procedure pushbegin(var root,tail:pt;info:byte);
var newelem:pt;
begin
	new(newelem);          (* Создать в памяти новый элемент *)
	newelem^.info:=info;
	newelem^.next:=root;   (* Присоединить очередь к этому элементу *)
	newelem^.prev:=NIL;
	if (root<>NIL) then			(* Если очередь не пуста *)
		root^.prev:=newelem			(* Присоединить этот элемент к началу очереди *)
	else						(* Иначе *)
		tail:=newelem;				(* Создать новую очередь *)
	root:=newelem;          
end;

procedure popbegin(var root,tail:pt);
var temp:pt;
begin
	if (root<>NIL) then			(* Если очередь не пуста *)
		begin						
			temp:=root;				(* Сохранить адрес первого элемента *)
			root:=root^.next;		(* Отрезать первый элемент от очереди *)
			if (root=NIL) then		
				tail:=NIL		
			else
				root^.prev:=NIL;
			writeln('Извлечённое значение : ',temp^.info); (* Вывести на экран значение последнего элемента *)
			dispose(temp);			(* Убрать первый элемент из памяти *)
		end
	else						(* Иначе, если очередь пуста *)
		Writeln('Дек пуст');
end;

procedure pushend(var root,tail:pt;info:byte);
var newelem:pt;
begin
	new(newelem);          (* Создать в памяти новый элемент *)
	newelem^.info:=info;
	newelem^.next:=NIL;   (* Присоединить этот элемент к очереди *)
	newelem^.prev:=tail;
	if (tail<>NIL) then			(* Если очередь не пуста *)
		tail^.next:=newelem			(* Присоединить этот элемент к началу очереди *)
	else						(* Иначе *)
		root:=newelem;				(* Создать новую очередь *)
	tail:=newelem;
end;

procedure popend(var root,tail:pt);
var temp:pt;
begin
	if (tail<>NIL) then			(* Если очередь не пуста *)
		begin						
			temp:=tail;				(* Сохранить адрес последнего элемента *)
			tail:=tail^.prev;		(* Отрезать последний элемент от очереди *)
			if (tail=NIL) then		
				root:=NIL		
			else
				tail^.next:=NIL;
			writeln('Извлечённое значение : ',temp^.info); (* Вывести на экран значение последнего элемента *)
			dispose(temp);			(* Убрать последний элемент из памяти *)
		end
	else						(* Иначе, если очередь пуста *)
		Writeln('Дек пуст');
end;

procedure showmenu;
begin
	Writeln (' 1) Push в начало');
	Writeln (' 2) Pop из начала');
	Writeln (' 3) Push в конец');
	Writeln (' 4) Pop из конца');
	Writeln (' 5) Выход ');
	Write(' -> ');
end;

var root,tail: pt;
	selection : byte;

begin
	Writeln ('Дек. Динамическая реализация ');
	root:=NIL;
	repeat				
		showmenu;
		readln(selection);	
		case selection of
			1: pushbegin(root,tail,getelem);
			2: popbegin(root,tail);
			3: pushend(root,tail,getelem);
			4: popend(root,tail);
			5: clrscr;
		end;
	until selection=5;	
end.
