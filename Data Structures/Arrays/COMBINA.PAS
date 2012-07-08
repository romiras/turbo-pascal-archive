
const S:string='abc';

procedure Cr(n:integer; s2:string);
var i:integer;
begin
 writeln(s2);
 if n<length(s) then
 for i:=1 to length(s) do Cr(n+1,s2+s[i]);
end;

procedure Combinations (const s: string);
begin
end;

var j:integer;

begin
     for j:=1 to length(s) do Cr(1,s[j]);
     {Combinations(S);}
end.