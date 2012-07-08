uses crt;

var c: char;

Procedure Menu;
 begin
      ClrScr;
      writeln('===  Главное Меню  ===' );
      writeln(' 1. item 1');
      writeln(' 2. item 2');
      writeln(' 3. item 2');
      writeln(' 0. Exit')  ;
      c:=readkey;
 end;

begin
     Menu;

     writeln;
     case c of
     '1': writeln('item 1');
     '2': writeln('item 2');
     '3': writeln('item 3');
     '0': exit;
     end;
end. 