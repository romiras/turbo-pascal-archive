PROGRAM binary_tree_sort;
USES dos,CRT;

CONST TWordLength = 10;
  
TYPE TWord = STRING [TWordLength];
  
TYPE PTree = ^TTree;
  TTree = RECORD
            info : TWord;
            num : INTEGER;
            Left, Right : PTree;
          END;
  
TYPE tinfile = text;

PROCEDURE readword (VAR infile : tinfile; VAR s : TWord);
VAR letter : string[1];
BEGIN
  REPEAT
    if eoln(infile) then
       readln(infile)
    else
        READ (infile, letter);
  UNTIL ( (letter > ' ') OR (EOF (infile) ) );

  IF (NOT (EOF (infile) ) ) THEN
     BEGIN
     s := letter;
     WHILE ( (letter > ' ') AND (NOT EOF (infile) ) AND (LENGTH (s) < TWordLength) and (not eoln(infile))) DO
           BEGIN
           READ (infile, letter);
           IF (letter > ' ') THEN
              s := s + letter;
           END;
     END
  ELSE
     s := '';
END;

PROCEDURE addelem (VAR root : PTree; info : TWord);
VAR elem : PTree;
BEGIN
  IF (root = NIL) THEN (* Если дерево пустое, то *)
     BEGIN
     NEW (elem);	(* Создать новый лист *)
     elem^.Left := NIL;
     elem^.Right := NIL;
     elem^.num := 1;
     elem^.info := info; (* Записать в него нужный элемент *)
     root := elem;	(* Поключить его вместо пустого дерева *)
     END
  ELSE
     IF (root^.info = info) THEN (* Если текущий узел равен добавляемому элементу *)
        INC (root^.num) (* Увеличить число появлений данного элемента *)
     ELSE (* Иначе *)
        BEGIN
        IF (info < root^.info) THEN (* Если добавляемый элемент меньше тек.узла, то *)
           addelem (root^.Left, info)	(* Добавить элемент в левое поддерево *)
        ELSE	(* Иначе *)
           addelem (root^.Right, info); (* Добавить элемент в правое поддерево *)
        END;
END;

PROCEDURE readfile (VAR infile : tinfile; VAR tree : PTree);
VAR s : TWord;
BEGIN
  WHILE (NOT (EOF (infile) ) ) DO	(* Пока файл не закончился *)
        BEGIN
        readword (infile, s); (* Считать из него слово *)
        IF (s <> '') THEN (* Если слово не пустое *)
           addelem (tree, s);	(* Добавить его в дерево *)
        END;

END;

PROCEDURE writefile (VAR outfile : TEXT; VAR root : PTree);
BEGIN
  IF (root <> NIL) THEN (* Если дерево не пустое, то *)
     BEGIN
     writefile (outfile, root^.Left); (* Записать в файл его левую ветвь *)
     WRITELN (outfile, root^.info, '-', root^.num); (* Записать в файл его корень *)
     writefile (outfile, root^.Right); (* Записать в файл его правую ветвь *)
     END;
END;

VAR tree : PTree;
  infname, outfname : STRING;
  infile : tinfile;
  outfile : TEXT;
  IOR : INTEGER;
  h1,m1,s1,decs1 : word;
  h2,m2,s2,decs2 : word;
  wtime:longint;

BEGIN
  tree := NIL;
  WRITELN ('Сортировка файла бинарным деревом.');
  REPEAT
    WRITE ('Введите имя входного файла : ');
    READLN (infname); (* Считать с клавиатуры имя входного файла *)
    ASSIGN (infile, infname);
    {$I-}
    RESET (infile); (* Открыть входной файл *)
    {$I+}
    IOR := IORESULT;
    IF (IOR <> 0) THEN
       WRITELN ('Не могу открыть входной файл!');
  UNTIL (IOR = 0);
  REPEAT
    WRITE ('Введите имя выходного файла : ');
    READLN (outfname); (* Считать с клавиатуры имя выходного файла *)
    ASSIGN (outfile, outfname);
    {$I-}
    REWRITE (outfile); (* Открыть выходной файл *)
    {$I+}
    IOR := IORESULT;
    IF (IOR <> 0) THEN
       WRITELN ('Не могу открыть выходной файл!');
  UNTIL (IOR = 0);

  gettime(h1,m1,s1,decs1);
  readfile (infile, tree); (* Считать входной файл в дерево *)
  writefile (outfile, tree); (* Записать дерево в виде ЛКП в выходной файл *)
  gettime(h2,m2,s2,decs2);
  wtime:=(decs2+s2*100+m2*6000+h2*360000)-(decs1+s1*100+m1*6000+h1*360000);
  writeln('Время работы : ',(wtime/100):2:2);

  CLOSE (outfile); (* Закрыть выходной файл *)
  CLOSE (infile); (* Закрыть входной файл *)
END.
