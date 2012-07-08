
type
	PListObject = ^TListObject;
	TListObject = object
		prev,next: PListObject;
          constructor Init;
		procedure PrintItem; virtual;
	end;

     TData = record
          n: integer;
          s: string;
     end;

	PRecList = ^TRecList;
	TRecList = object (TListObject)
		data: TData;
          constructor Init;
		procedure PrintItem; virtual;
		procedure AddItem (num: integer);
	end;


var
	top: PRecList;


constructor TListObject.Init;
begin
end;


procedure TListObject.PrintItem;
begin
end;


procedure TRecList.PrintItem;
begin
	write (data.n: 4);
end;


constructor TRecList.Init;
begin
     Inherited Init
end;

procedure TRecList.AddItem (num: integer);
var newelem: PRecList;
begin
	newelem := new(PRecList, Init);               (* Создать в памяти новый элемент *)
	newelem^.data.n:=num;
	newelem^.next:=top;        (* Присоединить к этому элементу список *)
	top:=newelem;              (* Вернуть его, как начало нового списка *)
end;

function searchel (data: Tdata): PRecList;
var
     list:PRecList;
begin
     list := top;
     if (list<>NIL) then (* Если список не пуст *)
        begin
          while 
               ((list^.next<>NIL) and 
          (list^.data.n<>data.n)) do (* Пока текущий элемент не последний и не искомый *)
	        list:=list^.next; (* Переходить к следующему элементу списка *)
     	  if (list^.data.n<>data.n) then (* Если искомый элемент не найден*)
	     searchel:=NIL              (*вернуть указатель на пустой список *)
      	  else             (* Иначе *)
	      searchel:=list;   (* Вернуть указатель на этот элемент *)
        end
     else  (* Иначе *)
        begin
          searchel:=NIL; (* Вернуть указатель на пустой список *)
        end;
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
	RecList : PRecList;
begin
	top := nil;
	RecList := New (PRecList, Init);
	RecList^.AddItem (10);
	RecList^.AddItem (9);
	RecList^.AddItem (8);
	PrintList (top);
	Dispose (Reclist);
	readln;
end.
