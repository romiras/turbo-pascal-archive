{ T0(x)=1, T1(x)=x, Tk(x)=2*x*Tk-1(x)-Tk-2(x) }

function Chebyshev (x: single; k: integer): single;
var
  y: single;
begin
	if k = 0 then Chebyshev := 1.0
	else
	if k = 1 then Chebyshev := x
	else
	begin
		y := 2.0 * x * Chebyshev (x, k-1) - Chebyshev (x, k-2);
		Chebyshev := y;
	end;
end;

begin
	writeln (Chebyshev (2.0, 3) : 10 : 3);
	readln;
end.
