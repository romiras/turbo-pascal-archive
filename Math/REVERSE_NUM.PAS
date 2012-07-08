program reverse;
Var
    X, Y: Integer;

begin
    write('Enter integer number: '); readln(X);
    Y := 0;
    While X > 0 do
    begin
      Y := (Y * 10) + (X mod 10);
      X := X div 10;
    end;
    writeln(Y);
end.