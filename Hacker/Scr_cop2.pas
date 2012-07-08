
uses Crt;

Type
     TCharAttr = packed record
       ch : Char;
       attr : Byte;
     end;
     PConsoleBuf = ^TConsoleBuf;
     TConsoleBuf = Array[0..ConsoleMaxX*ConsoleMaxY-1] of TCharAttr;

Const
      ScreenSize = SizeOf (TConsoleBuf);
      PageSize: word = 80*25*2;
      VSize   : Word = $1000;  { Full page size }

Type
     TArrByte = array [1..ScreenSize] Of byte;
     PArrByte = ^TArrByte;


Var
     Buf: pointer;

Begin
  ClrScr;
  writeln ('Copy screen to buffer test.');

  GetMem(Buf, PageSize);
  If Buf = Nil Then
    Begin
      Writeln('Not enough memory for Screen buf');
      Halt;
    End;

  Writeln('This sample for text direct copy');
  Move (ConsoleBuf^, Buf^, ScreenSize);
  readln;

  ClrScr;
  writeln ('Screen comes back...');
  readln;

  Move (Buf^, ConsoleBuf^, ScreenSize);
  readln;

  FreeMem(Buf, PageSize);
End.
