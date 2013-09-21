{$A+,B-,D-,E-,F-,I-,L-,N-,O-,R-,S-,V+}
{$M 8192,0,655360}
Program CompFile;
{ This is a simple minded test program which uses COMPMARK to compress a file.
  This is intended as a demonstration of the objects in COMPMARK, not as a
  serious file compression program.  See the comments in COMPMARK for
  information on appropriate use of these objects. }
Uses CompMark, Dos, Crt;
Const
  BufferSize = 20000; { Input buffer size }
  BufferPad = 5000;   { Output buffer is this much bigger than input buffer }
  DefaultBits = 6;    { If COMPBITS not specified, start with 6 }
  ReadMode = $20;     { Deny Write, Read access for input file }
Var
  InBuffer : Pointer;
  InFile : File;
  OutFile : CompFileOut;
  InName, OutName : String;

Procedure Initialize;
Var
  MaxMemory : LongInt;
  i, j : Word;
  ch : Char;
  Bits : Byte;
  OldMode : Byte;
  s : String[3];
Begin
  MaxMemory := MaxAvail - 2 * BufferSize - BufferPad;
  Bits := DefaultBits;
  s := GetEnv('COMPBITS');
  If s <> '' Then Begin
    Val(s, i, j);
    If (j = 0) And (i <= 8) Then Bits := i;
  End;
  While (Bits > 0) And (WorkAreaSize(Bits) > MaxMemory) Do Dec(Bits);
  WriteLn('Using ', Bits, ' Bits, work area size is ', WorkAreaSize(Bits));
  InitCompress(Bits);
  GetMem(InBuffer, BufferSize);
  {$I-}
  If ParamCount > 0 Then InName := ParamStr(1) Else Begin
    Write('Enter input file name: ');
    ReadLn(InName);
  End;
  OldMode := FileMode;
  FileMode := ReadMode;
  Assign(InFile, InName);
  Reset(InFile, 1);
  FileMode := OldMode;
  {$I+}
  If IoResult <> 0 Then Begin
    WriteLn('Unable to open input file ', InName);
    Halt(1);
  End;
  If ParamCount > 1 Then OutName := ParamStr(2) Else Begin
    Write('Enter output file name: ');
    ReadLn(OutName);
  End;
  WriteLn('COMPFILE will compress ', InName, ' to ', OutName);
  Write('OK? (Y/N): ');
  ch := UpCase(ReadKey);
  Write(ch, ' ');
  If ch <> 'Y' Then Begin
    WriteLn('Program terminated');
    Halt(1);
  End;
  OutFile.Init(OutName, BufferSize + BufferPad);
  WriteLn(MemAvail, ' bytes free space remains');
  Write('Working');
End;

Procedure WriteCompressedBuffer;
Var
  Len : LongInt;
Begin
  Len := FileSize(InFile) - FilePos(InFile);
  If Len > BufferSize Then Len := BufferSize;
  BlockRead(InFile, InBuffer^, Len);
  OutFile.PutRecord(InBuffer^, Len);
  Write('.');
End;

Begin
  Initialize;
  While Not Eof(InFile) Do WriteCompressedBuffer;
  WriteLn;
  OutFile.Flush;
  WriteLn(InName, ' Compressed (',
    (FileSize(InFile) - FileSize(OutFile.CompFile)) * 100
      Div FileSize(InFile), '%)');
  OutFile.Done;
  Close(InFile);
  WriteLn('Compression done');
End.