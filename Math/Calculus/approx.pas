{$N+}

const Eps=1e-5;

function F(value: double): double;
begin
     F:= value*value - 12.0;
end;

var x,z: double;
    itt: integer;

begin
     write('Enter first approximation: '); readln(z);
     x:=F(z);
     itt:=0;
     repeat
           z:=x;
           x:=F(z);
           inc(itt);
     until abs(x-z)<eps;

     writeln('Root: ',x:1:5, ' (',itt,' itterations)');
end.
