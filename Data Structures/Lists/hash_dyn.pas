program hash_dyn;

Const MaxWordLength = 10;

Type TWord = string[MaxWordLength];

Type Pt = ^TList;
     TList = record
	 		info:TWord;
			next:Pt;
		end;

Const HashSize = 73;

Type THash = array[1..HashSize] of Pt;

Procedure InitHash(var Hash:THash);
var i:integer;
begin
	for i:=1 to HashSize do
		Hash[i]:=NIL;
end;

function getelem(elname:string):TWord;
var s:TWord;
begin
	write('Введите ',elname,' : ');
	readln(s);
        getelem:=s;
end;

Function FHash(s:TWord):integer;
var i:integer;
    t,mul:longint;

begin
     t:=0;
     mul:=1;
     for i:=length(s) downto 1 do
         begin
	      t:=t + (ord(s[i])*mul);
	      mul:=mul*3;
	 end;
     FHash:=t mod 73;
end;

procedure addtobegin (var list:pt;info:TWord);
var newelem:pt;
begin
	new(newelem);               (* Создать в памяти новый элемент *)
	newelem^.info:=info;
	newelem^.next:=list;        (* Присоединить к этому элементу список *)
	list:=newelem;              (* Вернуть его, как начало нового списка *)
end;


Procedure add2hash(var Hash:THash;s:TWord);
begin
	addtobegin(Hash[fhash(s)],s);
end;

function searchel (list:pt;info:TWord):pt;
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


procedure searchhashelem(var Hash:THash;s:TWord);
begin
        writeln;
	if (searchel(Hash[fhash(s)],s)=NIL) then
		writeln('Слово не найдено')
	else
		writeln('Слово найдено');
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


procedure delelfromhash(var Hash:THash;s:TWord);
var f:integer;
begin
     f:=fhash(s);
     delel(Hash[f],searchel(Hash[f],s));
end;

Procedure Showmenu;
begin
	Writeln;
	Writeln('1) Добавить элемент в хеш');
	Writeln('2) Удалить элемент из хеша');
	Writeln('3) Поиск элемента в хеше');
	Writeln('4) Выход');
	Writeln;
	Write(' Ваш выбор : ');
end;

Var Hash:THash;
    selection:integer;

begin
	Writeln('Хеш с динамическим разрешением коллизий');
	InitHash(Hash); (* Очистить хеш *)
	repeat          (* Повторять *)
	      showmenu;    (* Показать меню *)
	      readln(selection); (* Ввести с клавиатуры пункт меню *)
	      writeln;
	      case selection of (* Выполнить требуемые действия *)
	           1: add2hash(Hash,getelem('слово для добавления'));
		   2: delelfromhash(Hash,getelem('слово для удаления'));
		   3: searchhashelem(Hash,getelem('слово для поиска'));
	      end;
	until selection=4; (* Пока не выберут "выход" *)
end.
