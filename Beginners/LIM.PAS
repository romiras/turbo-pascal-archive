
const
  eps = 1e-8; // точность

function Power (base: double; N: integer): double;
// степень N по основанию base
var k: integer;
    P: double;
begin
     P := 1.0;
     for k := 1 to N do
       P := P * base;

     Power := P;
end;
     
var
  n: integer;
  xold,
  xnew: double;

begin
	xnew := 0.0;
	n := 1;
	repeat
		xold := xnew;
		xnew := Power (1.0 + 1.0/n, n);
		writeln ('limit:', xnew : 20 : 8, '  itteration: ', n);
		inc (n);
	until abs (xnew - xold) < eps;
	
	writeln ('limit is (approximately):', xnew : 20 : 8);
	readln;
end.
