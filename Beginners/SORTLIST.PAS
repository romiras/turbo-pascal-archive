
uses Objects;

procedure Print(C: PCollection);

procedure PrintWord(P : PString); far;
begin
	Writeln(P^);
end;

begin
	Writeln(#13#10'List of students:'#13#10);
	C^.ForEach(@PrintWord);
end;

const
	FileName = 'students.txt';

var
	WordList: PCollection;
	F: Text;
        str: string;

begin
  Assign(F, FileName);
  {$I-}
  Reset(F);
  {$I+}
  if IOResult <> 0 then
  begin
	writeln('Error: can''t open ',FileName);
	halt(1);
  end;

  WordList := New(PStringCollection, Init(10, 5));
  if WordList=nil then halt(2);

  while Not EOF(F) do
  begin
	readln(F,str);
	WordList^.Insert(NewStr(str));
  end;
  Close(F);

  Print(WordList);
  Dispose(WordList, Done);
end. 