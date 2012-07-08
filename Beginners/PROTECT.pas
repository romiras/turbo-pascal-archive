Type
  BoolProc = function (s: string): boolean;
  PBoolProc = ^BoolProc;

Const
  HashSum: longint = 3412;
var
  str: string;

Function Hash (Key: string): Longint;
Var
  I,
  Sum:Integer;
Begin
 Sum := 0;
 For I := 1 To Length (Key) Do
  Sum := Sum + (Ord (Key[I]) * (1 shl I));
 Result := Sum;
End;

function Passed (ss: string): boolean;
begin
     Result := (Hash (ss) = HashSum);
end;

procedure TestPsw (f: BoolProc);
var
  b: boolean;
begin
     b := f (str);
     writeln ('Passed test: ', b);
end;

var
  p: boolproc;
  pp: pointer;

begin
     write ('Enter password: ');  readln (str);
     pp := @Passed;
     TestPsw (PP);
end.
