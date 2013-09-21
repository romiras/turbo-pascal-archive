program list;
uses CRT;

type pt = ^elem;
     elem = record
	       info : byte;
           next : pt;
     end;

function getprelastel (list:pt):pt;
var nextel:pt;
begin
     if (list<>NIL) then (* Если список не пуст *)
        begin
          nextel:=list;
          repeat
                list:=nextel;        (* Перейти к следующему элементу списка *)
	        if (list^.next<>NIL) then
	           nextel:=list^.next;
          until (nextel^.next=NIL);  (* Пока следующий за данным элемент списка не будет последним *)
          getprelastel:=list; (* Вернуть найденый элемент *)
        end
     else       (* Иначе, если список пуст *)
         getprelastel:=NIL; (* Вернуть указатель на пустой список *)
end;

function getlastel (list:pt):pt;
begin
     if (list<>NIL) then (* Если список не пуст, то: *)
        begin
          while (list^.next<>NIL) do      (* Пока текущий элемент списка не последний*)
                list:=list^.next;          (*Перейти к следующему элементу *)
          getlastel:=list;               (* Вернуть найденый элемент *)
        end
     else       (* Иначе *)
         getlastel:=NIL; (* Вернуть указатель на пустой список *)
end;

function searchel (list:pt;info:byte):pt;
begin
     if (list<>NIL) then (* Если список не пуст *)
        begin
          while ((list^.next<>NIL) and (list^.info<>info)) do (* Пока текущий элемент не последний и не искомый *)
	        list:=list^.next; (* Переходить к следующему элементу списка *)
     	  if (list^.info<>info) then (* Если искомый элемент не найден*)
	     searchel:=NIL              (*вернуть указатель на пустой список *)
      	  else             (* Иначе *)
	      searchel:=list;   (* Вернуть указатель на этот элемент *)
        end
     else  (* Иначе *)
        begin
          searchel:=NIL; (* Вернуть указатель на пустой список *)
        end;
end;

function searchpreel (list:pt;info:byte):pt;
var nextel:pt;
begin
     if (list<>NIL) then        (* Если список не пуст *)
     begin
          nextel:=list;
	  repeat
	        list:=nextel; (* Переходить к следующему элементу списка *)
		if (list^.next<>NIL) then
		   nextel:=list^.next;
	  until ((nextel^.next=NIL) or (nextel^.info=info)); (* Пока следующий за текущим элемент- не последний или искомый *)
	  if (nextel^.info<>info) or (nextel=list) then (* Если нужный нам элемент не найден или в списке 1 элемент *)
	     searchpreel:=NIL (* Вернуть указатель на пустой список *)
	  else         (* Иначе *)
	      searchpreel:=list;  (* Вернуть указатель на найденый элемент *)
     end
     else (* Иначе, если список пуст *)
         begin
	      searchpreel:=NIL; (* Вернуть указатель на пустой список *)
	 end;
end;

function getelem(elname:string):byte;
var ret:byte;
begin
	write('Введите ',elname,' : ');
	readln(ret);
        getelem:=ret;
end;

procedure addtobegin (var list:pt;info:byte);
var newelem:pt;
begin
	new(newelem);               (* Создать в памяти новый элемент *)
	newelem^.info:=info;
	newelem^.next:=list;        (* Присоединить к этому элементу список *)
	list:=newelem;              (* Вернуть его, как начало нового списка *)
end;

procedure addafter (listel:pt;info:byte);
var newelem:pt;
begin
     if (listel<>NIL) then (* Если список не пуст *)
        begin
          new(newelem);         (* Создать в памяти новый элемент *)
	  newelem^.info:=info;
	  newelem^.next:=listel^.next; (* Вставить элемент между заданным элементом и следующим *)
	  listel^.next:=newelem;
        end;
end;

procedure addtoend (var list:pt;info:byte);
begin
	if (list=NIL) then				(* Если список пуст *)
           addtobegin(list,info)			(* Добавить элемент в начало, создав новый список *)
	else							(* Иначе *)
	    addafter(getlastel(list),info);	(* Добавить элемент после последнего *)
end;

procedure addbefore (listel:pt;info:byte);
var newelem:pt;
begin
	if (listel<>NIL) then (* Если список не пуст *)
	   begin
	        new(newelem);   (* Создать в памяти новый элемент *)
		newelem^.info:=listel^.info; (* Скопировать в него заданный элемент списка *)
		listel^.info:=info;   (* Записать в заданный элемент списка элемент для добавления *)
		newelem^.next:=listel^.next; (* Вставить заданный элемент списка после добавленного *)
		listel^.next:=newelem;
	   end;
end;

procedure delfirstel(var list:pt);
var temp:pt;
begin
	if (list<>NIL) then (* Если список не пуст *)
	begin
	     temp:=list; (* Сохранить в памяти адрес первого элемента *)
	     list:=list^.next; (* Отрезать от списка первый элемент *)
	     dispose(temp); (* Убрать первый элемент из памяти *)
	end;
end;

procedure dellastel(var list:pt);
var temp:pt;
begin
	if (list<>NIL) then         (* Если список не пуст, то *)
	   if (list^.next=NIL) then    (* Если в списке один элемент *)
	      delfirstel(list)            (* Удалить его *)
	   else                        (* Иначе *)
	     begin
	       temp:=getprelastel(list);  (* Найти предпоследний элемент списка *)
	       dispose(temp^.next);       (* Удалить следующий за ним *)
	       temp^.next:=NIL;
	     end;
end;

procedure delel(var list:pt;el:pt);
var temp:pt;
begin
	if ((list<>NIL) and (el<>NIL)) then (* Если дан элемент для удаления и список не пуст *)
	   begin
	        if (el^.next=NIL) then  (* Если элемент, который нужно удалить - последний в списке *)
		   if (list^.next=NIL) then    (* И если он ещё и единственный *)
		      delfirstel(list)      (* Удалить его, то есть первый элемент *)
		   else                   (* Иначе, если он не единственный *)
		       dellastel(list)       (* Удалить его, то есть последний элемен *)
		else
		    begin
		         temp:=el^.next;          (* Скопировать в этот элемент следующий за ним *)
			 el^.info:=temp^.info;
			 el^.next:=temp^.next;
			 dispose(temp);       (* Удалить следующий за этим элемент  *)
		    end;
		end;
end;

procedure delbefore(var list:pt;info:byte);
var temp:pt;
begin
	if (list<>NIL) then     (* Если список не пуст *)
	begin
		temp:=searchpreel(list,info); (* Найти элемент, предшествующий искомому *)
		delel(list,temp);  (* И удалить его *)
	end;
end;

procedure delafter(var list:pt;info:byte);
var temp:pt;
begin
     if (list<>NIL) then        (* Если список, не пуст *)
     begin
          temp:=searchel(list,info);  (* Найти искомый элемент *)
	  temp:=temp^.next;             (* И удалить следующий за ним *)
          delel(list,temp)
     end;
end;

procedure printlist (list:pt);
begin
	clrscr;
	if (list=NIL) then      (* Если список пуст *)
	   writeln('Список пуст!') (* Сообщить об этом *)
	else
	    while (list<>NIL) do	(* Пока текущий элемент списка не последний *)
	          begin
		       write(list^.info);     (* Распечатать его *)
		       list:=list^.next;	   (* Перейти к следующему элементу *)
		       if (list<>NIL) then
		          write(',')
		       else
		           write('.');
		       end;
	readkey;
end;

procedure checkel(list:pt;info:byte);
begin
	if (searchel(list,info)<>NIL) then
		writeln('Элемент ',info,' существует.')
	else
		writeln('Элемент ',info,' не существует.');
	readkey;
end;

procedure showmenu;
begin
	clrscr;
	Writeln('1) Добавить элемент в начало списка');
	Writeln('2) Добавить элемент в конец списка');
	Writeln('3) Распечатать список');
	Writeln('4) Удалить первый элемент из списка');
	Writeln('5) Удалить последний элемент из списка');
	Writeln('6) Найти, существует ли указанный элемент в списке');
	Writeln('7) Удалить указанный элемент из списка');
	Writeln('8) Добавить элемент после указанного');
	Writeln('9) Добавить элемент перед указанным');
	Writeln('10) Удалить после указанного');
	Writeln('11) Удалить перед указанным');
	Writeln('12) Выход из программы');
	Writeln;
	Write(' Ваш выбор : ');
end;

var root: pt;
	selection : byte;

begin
	root:=NIL;	(* Создать пустой список *)
	repeat
		showmenu;				(* Показать меню *)
		readln(selection);		(* Ввести с клавиатуры пункт меню *)
		writeln;
		case selection of		(* Выполнить действие, затребованное пользователем *)
			1: addtobegin(root,getelem('значение элемента'));
			2: addtoend(root,getelem('значение элемента'));
			3: printlist(root);
			4: delfirstel(root);
			5: dellastel(root);
			6: checkel(root,getelem('значение искомого элемента'));
			7: delel(root,searchel(root,getelem('значение элемента для удаления')));
			8: addafter(searchel(root,getelem('значение искомого элемента')),getelem('значение элемента для добавления'));
			9: addbefore(searchel(root,getelem('значение искомого элемента')),getelem('значение элемента для добавления'));
			10: delafter(root,getelem('значение искомого элемента'));
			11: delbefore(root,getelem('значение искомого элемента'));
			12: clrscr;
		end;
	until selection=12;		(* Если пользователь выбрал не выход, повторить *)
end.
