
function IsPalindrom(S: string): boolean;
var i,len: integer;
    pal: boolean;
begin
     pal:=true;

     len:=length(S);
     for i:=1 to (len div 2) do
         if S[i]<>S[len-i+1] then
         begin
              pal:=false;
              break;
         end;

     IsPalindrom:=pal
end;

var Str: string;
begin
     write('Enter string: ');
     readln(str);
     writeln('Palindrom: ',IsPalindrom(str));
     readln;
end.