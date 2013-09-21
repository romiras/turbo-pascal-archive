{$A+,B-,D-,E-,F-,I-,L-,N-,O-,R-,S-,V+}
{$M 8192,0,655360}
Program ExpFile;
{ This is a simple minded test program which uses COMPMARK to expand a file
  created by COMPFILE.  This program is intended as part of a demonstration
  of the objects in COMPMARK, not as a serious file compression program.
  See the comments in COMPMARK for information on appropriate use of these
  objects. }
Uses CompMark, Dos, Crt;
Const
  BufferSize = 20000; { Output buffer size }
  BufferPad = 5000;   { Input buffer is this much bigger than output buffer }
  WriteMode = $11;    { Exclusive, Write access for output file }
Var
  OutBuffer : Pointer;
  OutFile : File;
  InFile : CompFileIn;
  InName, OutName : String;

Procedure Initialize;
Var
  ch : Char;
  OldMode : Byte;
Begin
  GetMem(OutBuffer, BufferSize);
  If ParamCount > 0 Then InName := ParamStr(1) Else Begin
    Write('Enter input file name: ');
    ReadLn(InName);
  End;
  InFile.Init(InName, BufferSize + BufferPad);
  If Not InFile.CompOpen Then Begin
    WriteLn('Unable to open input file ', InName);
    Halt(1);
  End;
  WriteLn('Length of original file was ', InFile.CompTotal, ' bytes');
  If ParamCount > 1 Then OutName := ParamStr(2) Else Begin
    Write('Enter output file name: ');
    ReadLn(OutName);
  End;
  WriteLn('EXPFILE will expand ', InName, ' to ', OutName);
  Write('OK? (Y/N): ');
  ch := UpCase(ReadKey);
  WriteLn(ch, ' ');
  If ch <> 'Y' Then Begin
    WriteLn('Program terminated');
    Halt(1);
  End;
  {$I-}
  OldMode := FileMode;
  FileMode := WriteMode;
  Assign(OutFile, OutName);
  ReWrite(OutFile, 1);
  FileMode := OldMode;
  If IoResult <> 0 Then Begin
    WriteLn('Unable to open output file ', OutName);
    Halt(1);
  End;
  {$I+}
  Write('Working');
End;

Procedure WriteExpandedBuffer;
Var
  Len : Word;
Begin
  Len := InFile.RecLength;
  If Len > BufferSize Then Begin
    WriteLn('Record longer than buffer, expansion terminated');
    WriteLn('Record: ', Len );
    WriteLn('Buffer: ', BufferSize);
    Halt(1);
  End;
  InFile.GetRecord(OutBuffer^, BufferSize);
  BlockWrite(OutFile, OutBuffer^, Len);
  Write('.');
End;

Begin
  Initialize;
  While Not InFile.Eof Do WriteExpandedBuffer;
  WriteLn;
  InFile.Done;
  Close(OutFile);
  WriteLn(InName, ' expanded to ', OutName);
End.