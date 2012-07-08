
uses CRT;
var    x,y:real;
       a,b,c,d,i:integer;
begin
       b:=1;
       x:=1;
       write('Enter number of octave (1..9): '); readln(a);
       write('Enter duration (ms): '); readln(d);
       for i:=0 to a do b:=2*b;
       for i:=1 to 12 do
       begin
               y:=16.3516075*b*x;
               writeln('Frequency: ',y:8:2,' Hz');
               sound(trunc(y),d);
               x:=1.059464*x;
       end;
end.
