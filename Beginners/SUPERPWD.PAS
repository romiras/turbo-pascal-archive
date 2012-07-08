Unit SuperPWD;

Interface
Uses Dos;

Type
    TOperation = (Encode, Decode);

Const
    Success = 0;
    Fail    = -1;

Function Encrypt (fn: pathstr): integer; {Returns status Success/Fail}
Function Decrypt (fn: pathstr): integer; {Returns status Success/Fail}

Implementation

procedure XORstr (var z: string);
var
   k: byte;
begin
     for k := 1 to length (z) do
         z[k] := chr( ord (z[k]) xor k);
end;

Procedure FixExtension (Var s: pathstr; h:String);
begin
     s := copy (s, 1, pos ('.', s)) + h;
end;

Function XORfile (fn: pathstr; op: TOperation): integer;
var
  F, F2: text;
  s: string;

begin
     XORfile := Success;

     Assign (F, fn);
     {$I-}
     reset (F);
     {$I+}

     if IOresult = 0 then
     begin
          if op = Decode then
             FixExtension (fn, 'txt')
          else
             FixExtension (fn, 'pwd');

          Assign (F2, fn);
          {$I-}
          rewrite (F2);
          {$I+}
          while Not EOF (F) do
          begin
               readln (F, s);
               XORstr (s);
               {$I-}
               writeln (F2, s);
               {$I+}
               if IOresult <> 0 then
               begin
                    XORfile := Fail;
                    break;
               end;
          end;
          close (F2);
     end;
     close (F);
end;

Function Encrypt (fn: pathstr): integer;
begin
     Encrypt := XORfile (fn, Encode);
end;

Function Decrypt (fn: pathstr): integer;
begin
     Decrypt := XORfile (fn, Decode);
end;

end.