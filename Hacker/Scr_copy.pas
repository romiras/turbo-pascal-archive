
uses Crt;

Const TextScreenBuf = SegB000;
      ScreenSize = 80*25*2;
      PageSize: word = 80*25*2;
      VSize   : Word = $1000;  { Full page size }

Type
     TArrByte = array [1..ScreenSize] Of byte;
     PArrByte = ^TArrByte;


Var
     Screen,
     Buf: PArrByte;
     k: word;
     p: PChar;
     s:string;

Begin
  ClrScr;
  writeln ('Copy screen to buffer test.');

  readln;

//  Screen := pointer (SegB800);
//  Screen := ptr (SegB800,0);
  p := $B8000;
  k := 0;
  while k < PageSize do
  begin
        write (chr(Mem[segB800:k]));
        inc (k,2);
  end;
  k:=$1111;
  exit;

(*
  GetMem (Buf, PageSize);
  If Buf = Nil Then
    Begin
      Writeln ('Not enough memory for Screen buf');
      Halt;
    End;

    // MemL[segB800:VSize*page]
    Writeln ('This sample for text direct copy');
    Move (Screen^, Buf^, ScreenSize);
//  MyMove(Screen^,Buf^,ScreenSize);
    readln;

    ClrScr;
    writeln ('Screen comes back...');
    readln;

    Move (Buf^, Screen^, ScreenSize);
    readln;

    FreeMem (Buf, PageSize);
*)
End.
