
function LHEXFN (decimal : longint) : string;
  const hexDigit : array [0..15] of char = '0123456789ABCDEF';
  var i : byte;
      s : string;
  begin
    FillChar (s, SizeOf(s), ' ');
    s[0] := chr(8);
    for i := 0 to 7 do
      s[8-i] := HexDigit[(decimal shr (4*i)) and $0F];
    lhexfn := s;
  end;  (* lhexfn *)
  {}

function DecToBCD (x : longint; var ok : boolean) : longint;
  const Digit : array [0..9] of char = '0123456789';
  var hexStr : string;
  var i, k : byte;
      y, d : longint;
  begin
    hexStr := LHEXFN(x);
    y := 0;
    d := 1;
    ok := false;
    for i := 7 downto 0 do begin
      k := Pos (hexStr[i+1], Digit);
      if k = 0 then exit;
      y := y + (k-1) * d;
      if i > 0 then d := 10 * d;
    end; { for }
    ok := true;
    DecToBCD := y;
  end;  (* dectobcd *)

Function Dec2Bin (num: word): String;
var result: string;
    remainder: word;
    c: char;
begin
     result := '';
     while num <> 0 do
     begin
          remainder := num mod 2;
          num := num div 2; { ??? num := num shr 1 }
          c := chr (remainder + ord ('0'));
          result := c + result;
     end;
     Dec2Bin := result
end;

function BCD(X : word) : word;
begin BCD := (X div 10)*16 + (X mod 10) end ;

  var i    : byte;
      x10  : longint;
      xBCD : longint;
      ok   : boolean;
  begin
    x10 := 10;
    writeln ('The ordinary decimal value : ', x10);
    xBCD := DecToBCD (x10, ok);
    if ok then writeln ('is ', xBCD, ' as a binary coded decimal')
      else writeln ('Error in BCD');
    writeln (BCD (x10));
    readln;
  end.
