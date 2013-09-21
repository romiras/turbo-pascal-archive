program fifo_dyn;
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

procedure push(var root,tail:pt;info:byte);
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

procedure pop(var root,tail:pt);
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
		Writeln('Очередь пуста');
end;

procedure showmenu;
begin
	Writeln (' 1) Push ');
	Writeln (' 2) Pop ');
	Writeln (' 3) Выход ');
	Write(' -> ');
end;

var root,tail: pt;
	selection : byte;

begin
	Writeln (' FIFO. Динамическая реализация ');
	root:=NIL;
	repeat				
		showmenu;
		readln(selection);	
		case selection of
			1: push(root,tail,getelem);
			2: pop(root,tail);
			3: clrscr;
		end;
	until selection=3;	
end.
