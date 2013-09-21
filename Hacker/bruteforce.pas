
type
  Tcharset = set of char;

const
  psw : string[30] = 'topsecret';
  abc_ : string[30] = 'abcdefghijklmnopqrstuvwxyz';
  abc : string[30] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  digits : string[10] = '0123456789';
  special : string[30] = ' _@.';
  special_plus : string[30] = ',-[]<>!?#*=~$%^&';

var
  SDict: string;  { словарь, состоящий из перебираемых символов}
 
  procedure BruteForce(S: string; n: integer); {процедура, которая будет составлять пароли}
  var
   i: integer;
  begin
   for i := 1 to Length (SDict) do
   begin
     s[n] := SDict[i];
     if n = 1 then
     begin
      if s = psw then
       writeln ('Found! psw: ', s)
     end
     else
       BruteForce(s, n - 1);
   end;
  end;

var
     SBase: string;
begin
     SBase := 'aaaaaaaaaaa';    {задаешь длину пароля}
     SDict := abc_ + special;  {набор символов(из чего перебор состоять будет)}
     BruteForce (SBase, Length(SBase)); {вызов процедуры, котоая составляет пассы}
end.
