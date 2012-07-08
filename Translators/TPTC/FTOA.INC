
(*
 * convert floating to ascii
 *
 *)

function ftoa(f: real; width,dec: integer): anystring;
var
   buf: anystring;
begin
   str(f:width:dec,buf);
   ftoa := buf;
end;


