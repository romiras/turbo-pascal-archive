PROGRAM insertion_sort;
USES CRT,dos;

CONST TWordLength = 10;

TYPE TWord = STRING [TWordLength];

TYPE PList = ^TList;
  TList = RECORD
            info : TWord;
            num : INTEGER;
            next : PList;
          END;

PROCEDURE readword (VAR infile : text;VAR s : TWord);
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

procedure addword (list : PList;s:TWord);
var elem:PList;
begin
	 while (list^.next<>NIL) and (list^.info<s) do
		list:=list^.next;

     if (list^.info=s) then
        begin
             inc(list^.num)
        end
     else
         begin
			  new(elem);
              elem^.next:=list^.next;
			  list^.next:=elem;
			  if (list^.info<s) then	
			  	begin
              		elem^.info:=s;
              		elem^.num:=1
				end
			  else
			  	begin
					elem^.info:=list^.info;
					elem^.num:=list^.num;
					list^.info:=s;
					list^.num:=1;
				end;
         end;
end;

PROCEDURE readfile (VAR infile : text;VAR list : PList);
VAR  s : TWord;
BEGIN
  readword(infile,s);
  new(list);
  list^.next:=NIL;
  list^.info:=s;
  list^.num:=1;
  WHILE (NOT (EOF (infile) ) ) DO (* Пока не конец файла *)
        BEGIN
        readword (infile, s); (* Считать из него слово *)
        IF (s <> '') THEN	(* Если слово - не пустое *)
           BEGIN
                addword(list,s);
           END;
        END;
END;

PROCEDURE writefile (VAR outfile : TEXT; VAR list : PList);
VAR temp : PList;
BEGIN
  REPEAT
    WRITELN (outfile, list^.info, '-', list^.num);
    temp := list;
    list := list^.next;
    DISPOSE (temp);
  UNTIL (list = NIL);
END;

VAR list : PList;
  infname, outfname : STRING;
  infile : text;
  outfile : TEXT;
  IOR : INTEGER;
  h1,m1,s1,decs1 : word;
  h2,m2,s2,decs2 : word;
  wtime:longint;

BEGIN
  list := NIL;	(* Создать пустой список *)
  WRITELN ('Сортировка файла вставкой.');
  REPEAT

    WRITE ('Введите имя входного файла : ');
    READLN (infname); (* Ввести имя входного файла *)
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
    READLN (outfname); (* Ввести имя выходного файла *)
    ASSIGN (outfile, outfname);
    {$I-}
    REWRITE (outfile); (* Открыть выходной файл *)
    {$I+}
    IOR := IORESULT;
    IF (IOR <> 0) THEN
       WRITELN ('Не могу открыть выходной файл!');
  UNTIL (IOR = 0);

  gettime(h1,m1,s1,decs1);
  readfile (infile, list); (* Считать входной файл в память *)
  writefile (outfile, list);	(* Записать выходной файл *)
  gettime(h2,m2,s2,decs2);
  wtime:=(decs2+s2*100+m2*6000+h2*360000)-(decs1+s1*100+m1*6000+h1*360000);
  writeln('Время работы : ',(wtime/100):2:2);

  CLOSE (outfile); (* Закрыть выходной файл *)
  CLOSE (infile); (* Закрыть входной файл *)
END.
