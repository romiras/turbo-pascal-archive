program AVLtreework;
uses CRT,Graph;

type PTree = ^TTree;
	 TTree = record
	 	info:byte;
		balance: integer;
		left,right: PTree;
	end;

function max(v1,v2:integer):integer;
begin
     if (v1>v2) then
        max:=v1
     else
         max:=v2;
end;

function getint(ident:string):byte;
var s:byte;
begin
	write('Введите ',ident,' : ');
	readln(s);
	getint:=s;
end;

procedure RotateSingleLL(var root:PTree);
Var LBranch:PTree;
begin
	LBranch:=root^.left;
        if (LBranch^.balance=-1) then
         begin
           LBranch^.balance:=0;
           root^.balance:=0;
         end
        else
          begin
            LBranch^.balance:=1;
            root^.balance:=-1;
          end;

	root^.left:=LBranch^.right;
	Lbranch^.right:=root;
	root:=LBRanch;
end;

procedure RotateSingleRR(var root:PTree);
var RBranch:PTree;
begin
	RBranch:=root^.right;

        if (RBranch^.balance=1) then
          begin
           RBranch^.balance:=0;
           root^.balance:=0;
          end
        else
          begin
            RBranch^.balance:=-1;
            root^.balance:=1;
          end;

	root^.right:=RBranch^.left;
	RBranch^.left:=root;
	root:=RBRanch;
end;

procedure RotateDoubleLR(var root:PTree);
Var LBranch,LRBranch:PTree;
begin
	Lbranch:=root^.left;
	LRbranch:=Lbranch^.right;
        if (LRbranch^.balance = 1) then
           lbranch^.balance:=-1
        else
            lbranch^.balance:=0;

        if (LRBranch^.balance = -1) then
           root^.balance:=1
        else
            root^.balance:=0;

        lrbranch^.balance:=0;

	root^.left:=LRbranch^.right;
	Lbranch^.right:=LRbranch^.left;
	LRbranch^.left:=Lbranch;
	LRBranch^.right:=root;

	root:=LRbranch;
end;

procedure RotateDoubleRL (var root:PTree);
Var Rbranch,RLbranch:PTree;
begin
	Rbranch:=root^.right;
	RLbranch:=RBranch^.left;

        if (RLBranch^.balance = -1) then
           rbranch^.balance:=1
        else
            rbranch^.balance:=0;

        if (RLBranch^.balance=1) then
           root^.balance:=-1
        else
            root^.balance:=0;

        rlbranch^.balance:=0;

	root^.right:=RLbranch^.left;
	Rbranch^.left:=RLbranch^.right;
	RLbranch^.right:=Rbranch;
	RLbranch^.left:=root;

	root:=RLbranch;
end;

procedure RebalanceTree(var root:PTree;var rebalance:boolean);
var branch:PTree;
begin
     if (root^.balance=-1) then
        begin
	     branch:=root^.left;
	     if (branch^.balance=-1) or (branch^.balance=0) then
	        begin
		     RotateSingleLL(root);
		     rebalance:=false;
		end
	     else
	     if (branch^.balance=1) then
	     begin
	          RotateDoubleLR(root);
		  rebalance:=false;
	     end;
	end
     else
         if (root^.balance=1) then
	    begin
	         branch:=root^.right;
		 if (branch^.balance=1) or (branch^.balance=0) then
		    begin
		         RotateSingleRR(root);
			 rebalance:=false;
		    end
		 else
		 if (branch^.balance=-1)  then
		    begin
		         RotateDoubleRL(root);
			 rebalance:=false;
		    end;
	    end;
end;

Procedure HeavyLeft(var root:PTree;var rebalance:boolean);
begin
     case root^.balance of
          -1 : begin
	            RebalanceTree(root,rebalance);
	       end;
	  0 : begin
	           root^.balance:=-1;
		   rebalance:=true;
	      end;
	  1 : begin
	           root^.balance:=0;
		   rebalance:=false;
	      end;
	  end;
end;

Procedure HeavyRight(var root:PTree;var rebalance:boolean);
begin
     case root^.balance of
          -1 : begin
	            root^.balance:=0;
		    rebalance:=false;
               end;
	  0 : begin
	           root^.balance:=1;
		   rebalance:=true;
	      end;
	  1: begin
	          RebalanceTree(root,rebalance);
	     end;
     end;
end;

procedure addelem(var root:PTree;info:byte;var rebalance:boolean);
var elem:PTree;
	rebalancethiselem:boolean;
begin
     if (root=NIL) then
        begin
	     new(elem);
	     elem^.left:=NIL;
	     elem^.right:=NIL;
	     elem^.info:=info;
	     elem^.balance:=0;
	     rebalance:=TRUE;
	     root:=elem;
	end
     else
         begin
	      if (info<root^.info) then
	         begin
		      addelem(root^.left,info,RebalanceThisElem);
		      if (RebalanceThisElem) then
                         HeavyLeft(root,rebalance)
		      else
		          rebalance:=false;
		 end
	      else
		  begin
		       addelem(root^.right,info,rebalancethiselem);
		       if (rebalancethiselem) then
		          begin
                               HeavyRight(root,rebalance)
			  end
		       else
		           rebalance:=false;
		  end;
	 end;
end;

procedure addelem_wrapper(var root:PTree;info:byte);
var rebalance:boolean;
begin
	rebalance:=false;
	addelem(root,info,rebalance);
end;

procedure printLKP(root:PTree);
begin
	if (root<>NIL) then
		begin
			printLKP(root^.left);
			write(root^.info,' ');
			printLKP(root^.right);
		end;
end;

procedure printLKP_wrapper(root:PTree);
begin
	clrscr;
	if (root=NIL) then
		writeln('Дерево пусто!')
	else
		PrintLKP(root);
	writeln;
	writeln('Нажмите любую клавишу для выхода в главное меню');
	readkey;
end;

procedure printKLP(root:PTree);
begin
	if (root<>NIL) then
		begin
			write(root^.info,' ');
			printKLP(root^.left);
			printKLP(root^.right);
		end;
end;

procedure printKLP_wrapper(root:PTree);
begin
	clrscr;
	if (root=NIL) then
		writeln('Дерево пусто!')
	else
		PrintKLP(root);
	writeln;
	writeln('Нажмите любую клавишу для выхода в главное меню');
	readkey;
end;

procedure printLPK(root:PTree);
begin
	if (root<>NIL) then
		begin
			printLPK(root^.left);
			printLPK(root^.right);
			write(root^.info,' ');
		end;
end;

procedure printLPK_wrapper(root:PTree);
begin
	clrscr;
	if (root=NIL) then
		writeln('Дерево пусто!')
	else
		PrintLPK(root);
	writeln;
	writeln('Нажмите любую клавишу для выхода в главное меню');
	readkey;
end;

function countels(root:PTree):integer;
begin
	if (root<>NIL) then
		countels:=1+countels(root^.left)+countels(root^.right)
	else
		countels:=0;
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
	if (root<>NIL) then
		if (root^.left=NIL) and (root^.right=NIL) then
			countleafs:=1
		else
			countleafs:=countleafs(root^.left)+countleafs(root^.right)
	else
		countleafs:=0;
end;

procedure countleafs_wrapper(root:PTree);
begin
	writeln('Число листов дерева : ',countleafs(root));
	writeln;
	writeln('Нажмите любую клавишу');
	readkey;
end;

function countdepth(root:PTree;level:integer):integer;
var dr,dl:integer;
begin
	if (root=NIL) then
		countdepth:=level-1
	else
            countdepth:=max(countdepth(root^.left,level+1),countdepth(root^.right,level+1));

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

function getmostright(root:PTree):byte;
begin
	if (root^.right=NIL) then
		getmostright:=root^.info
	else
		getmostright:=getmostright(root^.right);

end;
procedure DelRebalanceTree(var root:PTree;var rebalance:boolean);
var branch:PTree;
begin
     if (root^.balance=-1) then
        begin
	     branch:=root^.left;
	     if (branch^.balance=-1) or (branch^.balance=0) then
	        begin
		     RotateSingleLL(root);
		     rebalance:=false;
		end
	     else
	     if (branch^.balance=1) then
	     begin
	          RotateDoubleLR(root);
		  rebalance:=false;
	     end;
	end
     else
         if (root^.balance=1) then
	    begin
	         branch:=root^.right;
		 if (branch^.balance=1) or (branch^.balance=0) then
		    begin
		         RotateSingleRR(root);
			 rebalance:=false;
		    end
		 else
		 if (branch^.balance=-1) then
		    begin
		         RotateDoubleRL(root);
			 rebalance:=false;
		    end;
	    end;
end;

Procedure LightLeft(var root:PTree;var rebalance:boolean);
begin
     case root^.balance of
          1 : begin
	            DelRebalanceTree(root,rebalance);
	       end;
	  0 : begin
	           root^.balance:=1;
		   rebalance:=false;
	      end;
	  -1 : begin
	           root^.balance:=0;
		   rebalance:=true;
	      end;
	  end;
end;

Procedure LightRight(var root:PTree;var rebalance:boolean);
begin
     case root^.balance of
          1 : begin
	            root^.balance:=0;
		    rebalance:=true;
               end;
	  0 : begin
	           root^.balance:=-1;
		   rebalance:=false;
	      end;
	  -1: begin
	          DelRebalanceTree(root,rebalance);
	     end;
     end;
end;

procedure delelem(var root:PTree;info:byte;var rebalance:boolean);
var temp:PTree;
    RebalanceThisElem:boolean;
    OldRebalance:boolean;
    OldDepthL,OldDepthR:integer;
    DepthL,DepthR:integer;
begin
     if (root<>NIL) then
     begin
          if (info<root^.info) then
             begin
	          delelem(root^.left,info,RebalanceThisElem);
                  if (RebalanceThisElem) then
                     LightLeft(root,rebalance)
                  else
                      rebalance:=false;
             end
	  else
	      if (info>root^.info) then
                 begin
	              delelem(root^.right,info,RebalanceThisElem);
                      if (RebalanceThisElem) then
                         LightRight(root,rebalance)
                      else
                          rebalance:=false;
                 end
	      else
	          begin
		       if (root^.left=NIL) and (root^.right=NIL) then
		          begin
			       dispose(root);
			       root:=NIL;
                               rebalance:=TRUE;
			  end
		       else
		       if (root^.left=NIL) and (root^.right<>NIL) then
		       begin
		            temp:=root;
			    root:=root^.right;
			    dispose(temp);
                            rebalance:=TRUE;
		       end
		       else
		       if (root^.left<>NIL) and (root^.right=NIL) then
		       begin
		            temp:=root;
			    root:=root^.left;
			    dispose(temp);
                            rebalance:=TRUE;
		       end
		       else
		       begin
		            root^.info:=getmostright(root^.left);
                            olddepthl:=countdepth(root^.left,1);
                            olddepthr:=countdepth(root^.right,1);
			    delelem(root^.left,root^.info,RebalanceThisElem);
                            depthl:=countdepth(root^.left,1);
                            depthr:=countdepth(root^.right,1);
                            if (max(olddepthl,olddepthr)<>max(depthl,depthr)) or (abs(depthr-depthl)>1) then
                               LightLeft(root,rebalance)
                            else
                                begin
                                     rebalance:=false;
                                     root^.balance:=depthr-depthl;
                                end;
		       end;
	      end;
	  end
     else
         begin
              rebalance:=false;
         end;
end;

procedure delelem_wrapper(var root:PTree;info:byte);
var rb:boolean;
begin
     rb:=false;
     delelem(root,info,rb);
end;

procedure printlevel(root:Ptree;level,curlevel:integer);
begin
	if (root<>NIL) then
		begin
			if (curlevel=level) then
				write(root^.info,' ')
			else
				begin
					printlevel(root^.left,level,curlevel+1);
					printlevel(root^.right,level,curlevel+1);
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

procedure drawtree(root:PTree);
var Width,Height:integer;
    CurVPort:ViewPortType;
    s,sbal:string;
begin
     if (root<>NIL) then
        begin
             GetViewSettings(CurVPort);
             width:=CurVPort.x2-CurVPort.x1;
             height:=CurVPort.y2-CurVPort.y1;
             str(root^.info,s);
             str(root^.balance,sbal);
             sbal:='('+sbal+')';
             SetColor(15);
             Ellipse(width div 2,11,0,360,20,11);
             SetFillStyle(SolidFill,7);
             FloodFill(width div 2,11,15);
             SetColor(8);
             OutTextXY(width div 2,4,s);
             OutTextXY(width div 2,12,sbal);
             SetColor(15);
             if (root^.left<>NIL) then
                line(width div 2,22,width div 4,height);
             if (root^.right<>NIL) then
                line(width div 2,22,3*width div 4,height);
             with CurVPort do
                  setviewport(x1,y2,x1+(width div 2),y2+height,ClipOff);
             drawtree(root^.left);
             with CurVPort do
                  setviewport(x1+(width div 2),y2,x2,y2+height,ClipOff);
             drawtree(root^.right);
        end;
end;

procedure drawtree_wrapper(root:PTree);
Var GraphDevice,GraphMode:integer;
    PathToDriver:string;
begin
     if (root<>NIL) then
        begin
             GraphDevice:=Detect;
             PathToDriver:='';
             InitGraph(GraphDevice,GraphMode,PathToDriver);
             if (GraphResult<>grOK) then
               begin
                  Writeln('Error initializing graphics!');
                  readkey;
               end
             else
               begin
                  SetColor(White);
		  SetViewPort(15,0,GetMaxX-15,(GetMaxY div (countdepth(root,0)+1)),ClipOff);
                  SetTextJustify(CenterText,TopText);
                  drawtree(root);
                  readkey;
                  closegraph;
               end
        end
     else
       begin
         writeln('Дерево пусто!');
         readkey;
       end;
end;

procedure showmenu;
begin
	clrscr;
	writeln(' AVL-дерево');
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
	Tree:=NIL;

	repeat
		showmenu;
		readln(selection);
		writeln;
		case selection of
			1: addelem_wrapper(Tree,getint('элемент для добавления'));
			2: printLKP_wrapper(Tree);
			3: printKLP_wrapper(Tree);
			4: printLPK_wrapper(Tree);
			5: countels_wrapper(Tree);
			6: countleafs_wrapper(Tree);
			7: delelem_wrapper(Tree,getint('элемент для удаления'));
			8: printlevel_wrapper(Tree,getint('уровень, который нужно распечатать'));
			9: countdepth_wrapper(Tree);
                        10: drawtree_wrapper(Tree);
			11:clrscr;
		end;
	until selection=11;
end.
