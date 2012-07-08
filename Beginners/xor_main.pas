
uses crt;

Const
   BlockSize = 512;

type
   TBuffer = array [0..BlockSize-1] of byte;

var
   buffer: TBuffer;
   f: file;

procedure FillMemo(Buf: TBuffer; Key: word);
var i: word;
    c: char;
begin
     i:=0;
     while i<=SizeOf(Buf) do
     begin
          c := chr(Buf[i] xor Key);
          if c<>#7 then write(c);
          Inc(i);
     end;
     writeln(#13#10,Key)
end;

var
   Key: word;
   Cnt: longint;
begin
     If ParamCount<>1 then exit;
     Assign(F, ParamStr(1));
     {$I-}
     reset(f,1);
     {$I+}
     if IOresult <> 0 then
        halt (3);
     BlockRead(F, Buffer, SizeOf(Buffer), Cnt);
     close(f);

     Key:=0;
     repeat
       clrscr;

       FillMemo(Buffer, Key);
       inc(key);
       if Key=255 then break;
     until Readkey=#27;
end.
