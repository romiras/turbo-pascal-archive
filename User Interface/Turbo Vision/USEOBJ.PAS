uses objects;
var PSC: PStringCollection;
    str:string[20];
    i:byte;
begin
     PSC := New(PStringCollection, Init(5,0));
     writeln('Enter a string');
     for i:=0 to 4 do
     begin
	   readln(str);
	   PSC^.Insert(NewStr(Str));
     end;
     writeln;
     for i:=0 to 4 do
	 writeln(i+1,' ',PString(PSC^.at(i))^);
     Dispose(PSC);
end.