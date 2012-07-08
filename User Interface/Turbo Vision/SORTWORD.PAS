
program Sorting_of_Words;
uses Objects;
var F,FF: text;
    PSC: PStringCollection;
    str: string[20];
    erc: integer;
    i,countline: word;
const Fname='sortword.dat';

begin
     assign(F, Fname);
     {$I-}
     reset(F); { Read file with array of words that you want arrange by name }
     {$I+}
     if IOresult<>0 then
     begin
	  writeln('File ', Fname,' not found');
	  halt(1);
     end;
     countline:=0;
     if not EOF(F) then
     begin
	  readln(F,str);
	  val(str,countline,erc);
	  if erc>0 then
	  begin
	       writeln('First line doesn''t contain number of strings');
	       close(F);
	       halt;
	  end;
     end;
     if countline<2 then
     begin
	   close(F);
	   halt;
     end;
     PSC := New(PStringCollection, Init( CountLine,0 ));
     while not EOF(F) do
     begin
	  readln(F,str);
	  PSC^.Insert(NewStr(Str));
     end;

     assign(FF, 'sortword.srt');
     rewrite(FF);
     for i:=0 to CountLine-1 do
	  writeln(FF,PString(PSC^.at(i))^);
     Close(FF);
     Close(F);

     Dispose(PSC);
end.