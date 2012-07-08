
type
	PListObject = ^TListObject;
	TListObject = object
		prev,next: PListObject;
                constructor Init;
		procedure PrintItem; virtual;
	end;

	PIntList = ^TIntList;
	TIntList = object (TListObject)
		data: integer;
                constructor Init;
		procedure PrintItem; virtual;
		procedure AddItem (num: integer);
	end;


var
	top: PIntList;


constructor TListObject.Init;
begin
end;


procedure TListObject.PrintItem;
begin
end;


procedure TIntList.PrintItem;
begin
	write (data: 4);
end;


constructor TIntList.Init;
begin
     Inherited Init
end;

procedure TIntList.AddItem (num: integer);
var newelem: PIntList;
begin
	newelem := new(PIntList, Init);               (* Создать в памяти новый элемент *)
	newelem^.data:=num;
	newelem^.next:=top;        (* Присоединить к этому элементу список *)
	top:=newelem;              (* Вернуть его, как начало нового списка *)
end;


procedure PrintList (List: PListObject);
begin
	if (list=NIL) then      (* Если список пуст *)
	   writeln ('Список пуст!') (* Сообщить об этом *)
	else
	while (list<>NIL) do	(* Пока текущий элемент списка не последний *)
	begin
	        List^.PrintItem;
		list:=list^.next;	   (* Перейти к следующему элементу *)
	end;
end;

var
	IntList : PIntList;
begin
	top := nil;
	IntList := New (PIntList, Init);
	IntList^.AddItem (10);
	IntList^.AddItem (9);
	IntList^.AddItem (8);
	PrintList (top);
	Dispose (Intlist);
	readln;
end.
