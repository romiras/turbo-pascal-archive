program hash_dbl;

Const MaxWordLength = 10;

Type TWord = string[MaxWordLength];

Const FirstHashS = 997;
Const SecondHashS = 101;

Const HashSize = FirstHashS+SecondHashS-1;

Const EmptyElem:TWord='';

Type THash = file of TWord;

Function InitHash(var Hash:THash):boolean;
var i:integer;
begin
	assign(Hash,'hash.tmp');
	{$I-}
		rewrite(hash);
	{$I+}
	if IOResult<>0 then
		begin
			InitHash:=false;
		end
	else
		begin
			InitHash:=true;
			for i:=0 to HashSize-1 do
				write(hash,EmptyElem);
		end;
end;

Procedure DeInitHash(var Hash:THash);
begin
	close(Hash);
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
			mul:=mul*5;
		end;
	FHash:=t mod FirstHashS;
end;

Function FHash2(s:TWord):integer;
var i:integer;
	t,mul:longint;
begin
	t:=0;
	mul:=1;
	for i:=length(s) downto 1 do
		begin
			t:=t + (ord(s[i])*mul);
			mul:=mul*5;
		end;
	FHash2:=FHash(s) + (t mod SecondHashS);
end;

procedure add2hash (var hash:THash;elem:TWord);
var posit:integer;
	temp:TWord;
begin
	posit:=fhash(elem);
	seek(hash,posit);
	read(hash,temp);
	if (temp=emptyelem) then
		begin
			seek(hash,posit);
			write(hash,elem);
		end
	else
	  begin
	  	posit:=fhash2(elem);
		seek(hash,posit);
		repeat
			inc(posit);
			if (posit>hashSize) then
				begin
					seek(Hash,0);
					posit:=1;
				end;
			read(Hash,temp);	
		until (temp=EmptyElem);
		seek(hash,posit-1);
		write(hash,elem);
	  end;
end;

procedure searchhashelem (var hash:THash;elem:TWord);
var f:integer;
	temp:TWord;
begin
	writeln;
	f:=fhash(elem);
	seek(hash,f);
	read(hash,temp);
	if (temp=elem) then
		writeln('Элемент существует в хеше')
	else
		begin
			f:=fhash2(elem);
			seek(hash,f);
			repeat
				if eof(hash) then
					seek(Hash,0);
				read(hash,temp)
			until (temp=EmptyElem) or (temp=elem);
			if (temp=elem) then
				writeln('Элемент существует в хеше.')
			else
				writeln('Элемент не существует в хеше.');
		end;
end;

Procedure Showmenu;
begin
	Writeln;
	Writeln('Хеш с линейным разрешением коллизий и двойной хеш-функцией');
	Writeln('1) Добавить элемент в хеш');
	Writeln('2) Поиск элемента в хеше');
	Writeln('3) Выход');
	Writeln;
	Write(' Ваш выбор : ');
end;

Var Hash:THash;
	selection:integer;

begin
	Writeln('Инициализация хеша...');
	if (not (InitHash(Hash))) then
		writeln('Не могу инициализировать хеш!')
	else
		begin
			repeat
				showmenu;
				readln(selection);
				writeln;
				case selection of
					1: add2hash(Hash,getelem('слово для добавления'));
					2: searchhashelem(Hash,getelem('слово для поиска'));
				end;
			until selection=3;
			DeInitHash(Hash);
		end;
end.
