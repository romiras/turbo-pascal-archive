
(*
 * get the value of an environment variable
 *
 * (C) 1987 Samuel H. Smith, 14-Dec-87 (rev. 27-Jan-88)
 *
 * example:  path := get_environment_var('PATH=');
 *
 *)

function get_environment_var(id: string): string;
var
   envseg:  integer;
   i:       integer;
   env:     string;

begin
   envseg := memw[PrefixSeg:$2c];
   i := 0;

   repeat
      env := '';
      while mem[envseg:i] <> 0 do
      begin
         env := env + chr(mem[envseg:i]);
         i := i + 1;
      end;

      if copy(env,1,length(id)) = id then
      begin
         get_environment_var := copy(env,length(id)+1,255);
         exit;
      end;

      i := i + 1;
   until mem[envseg:i] = 0;

(* not found *)
   get_environment_var := '';
end;

