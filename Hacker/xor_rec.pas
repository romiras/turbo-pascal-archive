program xor_record;

type
  TRec = record
    f1, f2: Integer;
    f3: String;
  end;

  XX = array [1..SizeOf (TRec)] of byte;
  PX = ^XX;

var
  X: PX;
  Rec: TRec;
  Recsize,
  i: integer;

begin
  readln (Rec.f1);
  readln (Rec.f2);

  X := @Rec;
  Recsize := SizeOf (TRec);

  for i := 1 to Recsize do
   X^[i] := X^[i] xor lo (Recsize);

  readln;
end.