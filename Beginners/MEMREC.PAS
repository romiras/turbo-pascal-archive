type
  TRec = record
    Name: string[40];
    Price: integer;
  end;
  PRec = ^TRec;

var
  F: file of TRec;
  Rec: PRec;
  CreateDB: boolean;
  qnt: word;


procedure Init;
begin
  Assign (F, 'input.dat');
  {$I-}
  Reset (F);
  {$I+}
  CreateDB := IOresult <> 0;
  if CreateDB then
  begin
       Rewrite (F);

       write ('Enter quantity of products: '); readln (qnt);
  end;
end;

procedure Output;
begin
     writeln;
     writeln ('- Product': 40, '- Price':10);
     while not EOF (F) do
     with Rec^ do
     begin
          read (F, Rec^);
          writeln (Name: 40, Price: 10);
     end;
end;

procedure Create;
var
  i: word;

begin
  for i := 1 to qnt do
  with Rec^ do
  begin
       writeln;
       write ('Enter product name (up to 40 chars): '); readln (Name);
       write ('Enter price of product: '); readln (Price);

       write (F, Rec^);
  end
end;

begin
  Init;

  New (Rec);

  if CreateDB then
     Create
  else
     Output;

  Dispose (Rec);

  Close (F);
end.