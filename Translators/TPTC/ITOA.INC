
(*
 * return the string equivelant of an integer value
 *
 *)

function itoa (int:  integer): string;
var
   tstr:  string;
begin
   str(int, tstr);
   itoa := tstr;
end;

function ltoa (int:  longint): string;
var
   tstr:  string;
begin
   str(int, tstr);
   ltoa := tstr;
end;


