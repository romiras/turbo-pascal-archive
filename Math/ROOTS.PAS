program roots;
uses
 crt;
var
 a,b,c:real;
 procedure test(a,b,c:real);
  var
   d,x1,x2:real;
  begin
   if a=0 then
    writeln('NO ROOTS');
   d:=sqr(b)-4*a*c;
   if d>0 then
    begin
     x1:=(-b+sqrt(d))/(2*a);
     x2:=(-b-sqrt(d))/(2*a);
     writeln('x1=',x1:2:2);
     writeln('x2=',x2:2:2);
    end
   else
   if d<0 then
    write('D<0 than NO ROOTS')
   else
    write('x1=x2=',-b/(2*a));
  end;
begin
 clrscr;
 write('Enter a: ');
 readln(a);
 write('Enter b: ');
 readln(b);
 write('Enter c: ');
 readln(c);
 test(a,b,c);
 readln;
end.
