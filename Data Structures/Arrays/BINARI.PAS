program binari(input,output);

type vector = array[1..10] of integer;
var a: vector;
    result,x: integer;

procedure data(var a: vector);
      var i: integer;
begin
    for i:=1 to 10 do
    begin
        write('[',i,']= ');
        readln(a[i]);
    end;
end;{data}

function find_x(a: vector; x,i,j: integer):integer;
     var k: integer;
begin
    if i = j
       then
       begin
           if x = a[i]
              then find_x:= i
           else find_x:= -1;
       end
    else
    begin
        k:= (i+j) div 2;
        if x < a[k]
           then find_x:= find_x(a,x,i,k-1)
        else if x > a[k]
                then find_x:= find_x(a,x,k+1,j)
             else find_x:= k;
    end;
end;{find_x}
begin
    writeln;
    data(a);
    repeat
    write(' x = ');readln(x);
    result:= find_x(a,x,1,10);
    writeln(result);
    readln;
    until x = 0;
end.