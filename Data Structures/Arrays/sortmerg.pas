{
 Слияние двух отсортированных массивов. 
 В результате образуется один отсортированный массив.

 Для Borland Pascal 7.0
 Olegis, 01.2005
}

var
   bufin1, bufin2, bufout: text;
   i: integer;
   in1,in2: integer;

begin
     assign(bufin1, 'inp1.txt'); reset(bufin1);
     assign(bufin2, 'inp2.txt'); reset(bufin2);
     assign(bufout, 'output.txt'); rewrite(bufout);

     readln(bufin1, in1);
     readln(bufin2, in2);

     while (not eof(bufin1)) and (not eof(bufin2)) do
     begin
          if in1<=in2 then
          begin
               writeln(bufout, in1);
               readln(bufin1, in1);
          end
          else
          begin
               writeln(bufout, in2);
               readln(bufin2, in2);
          end;
     end;

     if eof(bufin1) then
     begin
          close(bufin1);
          while not eof(bufin2) do
          begin
               readln(bufin2, in2);
               writeln(bufout, in2);
          end;
          close(bufin2);
     end;

     if eof(bufin2) then
     begin
          close(bufin2);
          while not eof(bufin1) do
          begin
               readln(bufin1, in1);
               writeln(bufout, in1);
          end;
          close(bufin1);
     end;
     close(bufout);
end.