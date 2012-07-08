program treework;
uses CRT,Graph;

const
    PathToDriver = '..\..\bgi'; { путь к граф. драйверу [egavga.]bgi }

type PTree = ^TTree;
	 TTree = record
	 	info:byte;
		left,right: PTree;
	end;

function getint(ident:string):byte;
var s:byte;
begin
	write('Введите ',ident,' : ');
	readln(s);
	getint:=s;
end;

procedure addelem(var root:PTree;info:byte);
var elem:PTree;
begin
	if (root=NIL) then (* Если дерево пустое, то *)
		begin
			new(elem); (* Создать новый лист *)
			elem^.left:=NIL; 
			elem^.right:=NIL;
			elem^.info:=info; (* Записать туда значение требуемого элемента *)
			root:=elem; (* Присоединить новый лист вместо пустого дерева *)
		end 
	else  (* Иначе *)
		begin
			if (info<root^.info) then  (* Если добавляемое значение меньше текущего узла, то *)
				addelem(root^.left,info) (* Добавить его в левое поддерево *)
			else (* Иначе *) 
				addelem(root^.right,info); (* Добавить его в правое поддерево *)
		end;
end;


procedure printLKP(root:PTree);
begin
	if (root<>NIL) then  (* Если дерево не пустое *)
		begin
			printLKP(root^.left);  (* Распечатать левое поддерево *)
			write(root^.info,' '); (* Распечатать корень дерева *)
			printLKP(root^.right); (* Распечать правое поддерево *)
		end;
end;

procedure printLKP_wrapper(root:PTree);
begin
	clrscr;
	if (root=NIL) then (* Если дерево пустое *)
		writeln('Дерево пусто!') (* Сообщить об этом *)
	else (* Иначе *)
		PrintLKP(root); (* Распечатать  дерево *)
	writeln;
	writeln('Нажмите любую клавишу для выхода в главное меню');
	readkey;
end;

procedure printKLP(root:PTree);
begin
	if (root<>NIL) then (* Если дерево не пустое *)
		begin
			write(root^.info,' '); (* Распечатать корень дерево *)
			printKLP(root^.left); (* Распечатать левое поддерево *)
			printKLP(root^.right);(* Распечатать правое поддерево *)
		end;
end;

procedure printKLP_wrapper(root:PTree);
begin
	clrscr;
	if (root=NIL) then (* Если дерево пустое *)
		writeln('Дерево пусто!') (* Сообщить об этом *)
	else  (* Иначе *)
		PrintKLP(root); (* Распечатать дерево *)
	writeln;
	writeln('Нажмите любую клавишу для выхода в главное меню');
	readkey;
end;

procedure printLPK(root:PTree);
begin
	if (root<>NIL) then (* Если дерево не пустое *)
		begin
			printLPK(root^.left); (* Распечатать левое поддерево *)
			printLPK(root^.right); (* Распечатать правое поддерево *)
			write(root^.info,' '); (* Распечатать корень дерева *)
		end; 
end;

procedure printLPK_wrapper(root:PTree);
begin
	clrscr;
	if (root=NIL) then (* Если дерево пустое *)
		writeln('Дерево пусто!') (* Сообщить об этом *)
	else (* Иначе *)
		PrintLPK(root); (* Распечатать дерево *)
	writeln;
	writeln('Нажмите любую клавишу для выхода в главное меню');
	readkey;
end;

function countels(root:PTree):integer;
begin
	if (root<>NIL) then (* Если дерево не пустое , то *)
		countels:=1+countels(root^.left)+countels(root^.right) (* Число его узлов - сумма числа узлов левой и правой ветвей +1 *)
	else (* Иначе, если дерево пустое *)
		countels:=0; (* Число его узлов = 0 *)
end;

procedure countels_wrapper(root:PTree);
begin
	writeln('Число вершин дерева : ',countels(root));
	writeln('Нажмите любую клавишу');
	writeln;
	readkey;
end;

function countleafs(root:PTree):integer;
begin
	if (root<>NIL) then (* Если дерево не пустое, то *)
		if (root^.left=NIL) and (root^.right<>NIL) then  (* Если оно - лист,то *)
			countleafs:=1 (* Количество листов в нём = 1 *)
		else (* Иначе *)
			countleafs:=countleafs(root^.left)+countleafs(root^.right) (* Количество листов = сумме листов левой и правой ветвей *)
	else (* Иначе, если дерево пустое , *)
		countleafs:=0; (* Количество листов в нём = 0 *)
end;

procedure countleafs_wrapper(root:PTree);
begin
	writeln('Число листов дерева : ',countels(root));
	writeln;
	writeln('Нажмите любую клавишу');
	readkey;
end;

function getmostright(root:PTree):byte;
begin
	if (root^.right=NIL) then 		(* Если нет правого поддерева *)
		getmostright:=root^.info (* То этот элемент - самый правый в дереве *)
	else (* Иначе *)
		getmostright:=getmostright(root^.right); (* Самый правый элемент этого дерева - самый правый элемент его правого поддерева *)
end;

procedure delelem(var root:PTree;info:byte);
var temp:PTree;
begin
	if (root<>NIL) then (* Если дерево не пустое, то *)
	  begin
		if (info<root^.info) then	(* Если удаляемый элемент меньше тек. узла, то *)
			delelem(root^.left,info)	(* Удалить его из левого поддерева *)
		else		(* Иначе *)
		if (info>root^.info) then (* Если удаляемый элемент больше тек. узла, то *)
			delelem(root^.right,info)	(* Удалить его из правого поддерева *)
		else	(* Иначе тек. узел - удаляемый элемент *)
			begin
				if (root^.left=NIL) and (root^.right=NIL) then (* Если тек. узел - лист, то *)
					begin
						dispose(root); (* Удалить его *)
						root:=NIL;	(* Поставить на его место пустое дерево *)
					end
				else
				if (root^.left=NIL) and (root^.right<>NIL) then (* Если у тек.узла есть только правая ветвь *)
					begin
						temp:=root; 	(* Присоединить её вместо тек. узла *)
						root:=root^.right;
						dispose(temp); (* Удалить тек. узел *)
					end
				else
				if (root^.left<>NIL) and (root^.right=NIL) then  (* Если у тек.узла есть только левая ветвь *)
					begin
						temp:=root;     (* Присоединить её вместо тек. узла *)
						root:=root^.left;
						dispose(temp);  (* Удалить тек. узел *)
					end
				else (* Иначе у узла есть обе ветви *)
					begin
						root^.info:=getmostright(root^.left); (* Вставить на место узла самый правый эл-т левого поддерева *)
						delelem(root^.left,root^.info); (* Удалить самый правый эл-т из левого поддерева *)
					end;
						
			end;
	  end;
end;

procedure printlevel(root:Ptree;level,curlevel:integer);
begin
	if (root<>NIL) then		(* Если дерево не пустое, то *)
		begin
			if (curlevel=level) then	(* Если тек.вершина на нужном уровне, то *)
				write(root^.info,' ')		(* Распечатать её *)
			else	(* Иначе *)
				begin
					printlevel(root^.left,level,curlevel+1); (* Распечатать все вершины треб. уровня в левом поддереве *)
					printlevel(root^.right,level,curlevel+1); (* Распечатать все вершины треб. уровня в правом поддереве *)
				end;
		end;
end;

procedure printlevel_wrapper(root:PTree;level:integer);
begin
	clrscr;
	writeln('Все вершины на уровне ',level,' : ');
	printlevel(root,level,0);
	writeln;
	writeln('Нажмите любую клавишу для выхода в главное меню');
	readkey;
end;

function countdepth(root:PTree;level:integer):integer;
var dr,dl:integer;
begin
	if (root=NIL) then	(* Если дерево пустое, то *)
		countdepth:=level-1	(* Глубина текущей ветви = текущему уровню - 1*)
	else	(* Иначе *)
		begin
			dr:=countdepth(root^.left,level+1);
			dl:=countdepth(root^.right,level+1);
			if (dr>dl) then	(* Глубина текущей ветви равна максимальной из глубин её поддеревьев *)
				countdepth:=dr
			else
				countdepth:=dl;
		end;

end;

procedure countdepth_wrapper(root:PTree);
begin
     if (root<>NIL) then
      begin
	writeln('Глубина дерева : ',countdepth(root,0));
	writeln;
	writeln('Нажмите любую клавишу');
      end
     else
         writeln('Дерево пусто!');
	readln;
end;

procedure drawtree(root:PTree);
var Width,Height:integer;
    CurVPort:ViewPortType;
    s:string;
begin
     if (root<>NIL) then	(* Если дерево не пустое, то *)
        begin
             GetViewSettings(CurVPort);	
             width:=CurVPort.x2-CurVPort.x1;
             height:=CurVPort.y2-CurVPort.y1;
             str(root^.info,s);
             OutTextXY(width div 2,0,s);		(* Вывести значение вершины в верх-центр тек. окна *)
             if (root^.left<>NIL) then		(* Если у вершины есть левая ветвь *)
                line(width div 2,8,width div 4,height-3);	(* Нарисовать отрезок прямой к левой ветви *)
             if (root^.right<>NIL) then		(* Если у вершины есть правая ветвь *)
                line(width div 2,8,3*width div 4,height-3);	(* Нарисовать отрезок прямой к правой ветви *)
             with CurVPort do (* Разбить тек. окно по горизонтали пополам, выбрать левую часть, перейти к след. уровню *)
                  setviewport(x1,y2,x1+(width div 2),y2+height,ClipOff);	
             drawtree(root^.left);	 	(* Вывести левое поддерево *)
             with CurVPort do	(* Разбить тек. окно по горизонтали пополам, выбрать правую часть, перейти к след. уровню *)
                  setviewport(x1+(width div 2),y2,x2,y2+height,ClipOff);
             drawtree(root^.right);	(* Вывести правое поддерево *)
        end;
end;

procedure drawtree_wrapper(root:PTree);
Var GraphDevice,GraphMode:integer;
begin
     if (root<>NIL) then	(* Если дерево не пустое *)
        begin
             GraphDevice:=Detect;
             InitGraph(GraphDevice,GraphMode,PathToDriver); (* Инициализировать графику *)
             if (GraphResult<>grOK) then		(* Если инициализация не удалась, то *)
               begin
                  Writeln('Error initializing graphics!');	(* Сообщить об этом *)
                  readkey;
               end
             else (* Иначе *)
               begin
                  SetViewPort(0,0,GetMaxX,(GetMaxY div (countdepth(root,0)+1)),ClipOff); (*Установить окно на всю ширину экрана
                                                                                          и 0й уровень дерева *)
                  SetTextJustify(CenterText,TopText); 
                  drawtree(root); (* Нарисовать дерево *)
                  readkey;
                  closegraph;
               end
        end
     else (* Иначе *)
       begin
         writeln('Дерево пусто!'); (* Сообщить об этом *)
         readkey;
       end;
end;

procedure showmenu;
begin
	clrscr;
	writeln(' Бинарное дерево');
	writeln;
	writeln('  1) Добавить элемент в дерево');
	writeln('  2) Распечатать дерево в виде левая ветвь - корень - правая ветвь (ЛКП)');
	writeln('  3) Распечатать дерево в виде корень - левая ветвь - правая ветвь (КЛП)');
	writeln('  4) Распечатать дерево в виде левая ветвь - правая ветвь - корень (ЛПК)');
	writeln('  5) Вывести число вершин дерева');
	writeln('  6) Вывести число листов дерева');
	writeln('  7) Удалить элемент из дерева');
	writeln('  8) Распечатать все вершины на заданном уровне');
	writeln('  9) Вывести глубину дерева');
	writeln(' 10) Нарисовать дерево');
	writeln(' 11) Выход');
	writeln;
	write('Ваш выбор : ');

end;

Var Tree:PTree;
	selection:integer;

begin
	Tree:=NIL; (* Создать пустое дерево *)
	repeat
		showmenu; (* Вывести на экран меню *)
		readln(selection);  (* Считать с клавиатуры выбор пользователя *)
		writeln;
		case selection of (* Выполнить действия в соответствии с этим выбором *)
			1: addelem(Tree,getint('элемент для добавления'));
			2: printLKP_wrapper(Tree);
			3: printKLP_wrapper(Tree);
			4: printLPK_wrapper(Tree);
			5: countels_wrapper(Tree);
			6: countleafs_wrapper(Tree);
			7: delelem(Tree,getint('элемент для удаления'));
			8: printlevel_wrapper(Tree,getint('уровень, который нужно распечатать'));
			9: countdepth_wrapper(Tree);
            10: drawtree_wrapper(Tree);
			11:clrscr;
		end;
	until selection=11;
end.
