
function L2S(I: Longint): String;
{ Convert any integer type to a string }
var
  S: string[11];
begin
  Str(I, S);
  L2S := S;
 end;

function I2S(I: integer): String;
var
  S: string[6];
begin
  Str(I, S);
  I2S := S;
end;
