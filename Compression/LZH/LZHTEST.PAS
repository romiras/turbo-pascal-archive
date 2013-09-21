Program LZHTest;


{ This is a demo program to illstrate the use of the LZH unit.
  it implements a very simple 1 file at a time compressor program.


  Author : Douglas P. Webb
}


uses LZH;

CONST
  MaxBuf = 4096;     { Must be bigger than the biggest chunk being asked for. }


Type
  BufType = Array[1..MaxBuf] OF BYTE;
  BufPtr = ^BufType;


VAR
  InBuf,OutBuf : BufPtr;
  infile,Outfile : FILE;
  s : STRING;
  Bytes_Written : LongInt;
  Size : LongInt;
  Temp : WORD;


{$F+}

Procedure GetBlock(VAR Target; NoBytes:Word; VAR Actual_Bytes:Word);
CONST
  Posn : Word = 1;
  Buf : Word = 0;

VAR
  Temp:Word;

BEGIN
  IF (Posn > Buf) OR (Posn + NoBytes > SUCC(Buf)) THEN
    BEGIN
      IF Posn > Buf THEN
        BEGIN
          BlockRead(InFile,InBuf^,MaxBuf,Buf);
          Write('+');
        END
      ELSE
        BEGIN
          Move(InBuf^[Posn],InBuf^[1],Buf-Posn);
          BlockRead(InFile,InBuf^[Buf-Posn],MaxBuf-(Buf-Posn),Temp);
          Buf := Buf-Posn+Temp;
          Write('+');
        END;
      IF Buf = 0 THEN
        BEGIN
          Actual_Bytes := 0;
          Writeln;
          Exit;
        END;
      Posn := 1;
    END;
  Move(InBuf^[Posn],Target,NoBytes);
  INC(Posn,NoBytes);
  IF Posn > SUCC(Buf) THEN
    Actual_Bytes := NoBytes -(Posn-SUCC(Buf))
  ELSE Actual_Bytes := NoBytes;
END;


Procedure PutBlock(VAR Source; NoBytes:Word; VAR Actual_Bytes:Word);
CONST
  Posn : Word= 1;

VAR
  Temp:Word;

BEGIN
  If NoBytes = 0 THEN    { Flush condition }
    BEGIN
      BlockWrite(OutFile,OutBuf^,PRED(Posn),Temp);
      EXIT;
    END;
  IF (Posn > MaxBuf) OR (Posn + NoBytes > SUCC(MaxBuf)) THEN
    BEGIN
      BlockWrite(OutFile,OutBuf^,PRED(Posn),Temp);
      Posn := 1;
    END;
  Move(Source,OutBuf^[Posn],NoBytes);
  INC(Posn,NoBytes);
  Actual_Bytes := NoBytes;
END;


{$F-}

BEGIN
  IF (paramcount <> 3) THEN
    BEGIN
      Writeln('Usage:lzhuf e(compression)|d(uncompression) infile outfile');
      halt(1);
    END;
  s := paramstr(1);
  IF NOT (s[1] IN ['D','E','d','e']) THEN
    Halt(1);
  Assign(infile,paramstr(2));
  reset(infile,1);
  Assign(outfile,Paramstr(3));
  Rewrite(outfile,1);
  New(InBuf);
  New(OutBuf);
  IF (upcase(s[1]) = 'E') THEN
    BEGIN
       Size := Filesize(InFile);
       BlockWrite(OutFile,Size,Sizeof(LongInt));
       LZHPack(Bytes_Written,GetBlock,PutBlock);
       PutBlock(Size,0,Temp);
    END
  ELSE
    BEGIN
      BlockRead(Infile,Size,Sizeof(LongInt));
      LZHUnPack(Size,GetBlock,PutBlock);
      PutBlock(Size,0,Temp);
    END;
  Dispose(OutBuf);
  Dispose(InBuf);
  Close(Infile);
  Close(OutFile);
END.