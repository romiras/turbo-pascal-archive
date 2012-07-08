const MAXSIZE = 3;
type
	vector = array [1..MAXSIZE] of integer;
	digits = set of 1..MAXSIZE;

procedure print_vector (a: vector);
var i: integer;
begin
	for i := 1 to MAXSIZE do
	  write (a[i], ' ');
	writeln;
end;

procedure permutation_s (var a: vector; var b: digits; n : integer);
var i: integer;
begin
	if n <= MAXSIZE then
	begin
		for i := 1 to MAXSIZE do
		if NOT (i in b) then
		begin
			a[n] := i;
			b := b + [i];
			permutation_s (a, b, n+1);
			b := b - [i];
		end
	end
	else
	print_vector (a);
end;

procedure permutation;
var a: vector; b: digits;
begin
	b := [];
	permutation_s (a, ,b 1);
end;
		