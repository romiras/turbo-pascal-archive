
(*
 * converts ascii string to an integer value
 * (tp3 dies on leading spaces but likes trailing.
 *  tp4 likes leading spaces but dies on trailing!!)
 *
 *)

function atol (asc:  anystring): longint;
var
   i:             integer;
   value:         longint;
   num:           anystring;

begin
   num := '';
   for i := 1 to length(asc) do
      if ((asc[i] >= '0') and (asc[i] <= 'F')) or (asc[i] = '$') then
         num := num + asc[i];
  
   if length(num) = 0 then
      value := 0
   else
      val(num, value, i);

   atol := value;
end;


function atoi (asc:  anystring): integer;
begin
   atoi := integer(atol(asc));
end;

function atow (asc:  anystring): word;
begin
   atow := word(atol(asc) and $FFFF);
end;

function htoi (asc:  anystring): word;
begin
   if copy(asc,1,2) = '0x' then
      asc := '$' + copy(asc,3,99);
   htoi := word(atol(asc) and $FFFF);
end;


