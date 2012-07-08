program Using_procedural_types;

type
     Proctype = function (x: real): real;

function MyFunc (x: real): real; far;
begin
     MyFunc := x * x
end;

function MyFunc2 (x: real): real; far;
begin
     MyFunc2 := x * x
end;

procedure X (P: pointer);
var F: Proctype;
begin
     @F := P;
     writeln (F (15.1) : 10 : 2)
end;

var F: Proctype;
begin
     writeln;

     F := Myfunc;
     writeln (F (23.7) : 10 : 2);

     x (@Myfunc);
end.