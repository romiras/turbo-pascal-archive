{$A+,B-,D-,E-,F-,I-,L-,N-,O-,R-,S-,V+}
Unit CompMark;
{ COMPMARK.PAS - Adaptive data compression using "Splay" tree with Markov
  model.  This algorithm was originally implemented in Pascal on the IBM PC
  by Kim Kokkonen [72457,2131], TurboPower Software, 8-16-88.  His
  documentation follows:

  "Based on an article by Douglas W. Jones, 'Application of Splay Trees to
  Data Compression', in Communications of the ACM, August 1988, page 996.

  "This is a method somewhat similar to Huffman encoding (SQZ), but which is
  locally adaptive. It therefore requires only a single pass over the
  uncompressed file, and does not require storage of a code tree with the
  compressed file. It is characterized by code simplicity and low data
  overhead. Compression efficiency is not as good as recent ARC
  implementations, especially for large files. However, for small files, the
  efficiency of SPLAY approaches that of ARC's squashing technique."

  I have re-implemented the algorithm in assembler with some changes:

  1. My intended use for this unit is to compress a relatively small data
     buffer as one might wish to do before transmitting it over a
     communications channel or storing it on disk.  Consequently, this unit
     compresses and decompresses an in-memory buffer rather than a file.
     InitCompress initially balances the Splay tree[s] in the work area.
     The work area retains any tree adaptations done during compression or
     expansion until InitCompress is called again.  Therefore, If you wish to
     make each buffer independently expandable, you must call InitCompress
     before each call to CompressData.  ExpandData will detect what you have
     done and automatically call InitCompress where necessary.

  2. I run-length-encode the input before compressing it with the Splay
     tree algorithm.  This improves the compression ratio where the input
     contains long runs of duplicate characters.

  3. Kim's original implementation used a unique trailer character to
     mark the end of data.  I store the pre-compressed data length as
     the first word in the compressed data buffer and do not use a
     unique trailer character.  This permits the uncompressed length to be
     determined by inspection and, because the ExpandBuffer routine stops
     when the output length is achieved, transmission errors will be less
     likely to blow out a buffer on the receiving end.  The "Bits" parameter
     from InitCompress is also stored as the third byte in the buffer.

  4. I have implemented the "Markov modeling" technique outlined in the Jones
     ACM reference.  You may (indirectly) indicate the number of states in
     the InitCompress procedure.  The work area size requirements are outlined
     in the comments on that proc.  InitCompress(0) should reproduce the
     compression behavior of Kim's original SPLAY.PAS.  The work area is
     passed as a parameter to the assembler primatives so they may be fully
     re-entrant.

  5. I have added objects for management of compressed sequential record
     files on disk (see below).

  Cautions:

  1. CompressData and ExpandData both read/write their input/output under the
     constraints of the 8086 segmented archetecture and I do not normalize
     the input/output pointers before starting.  Therefore, you should call
     these routines with normalized pointers, and expect invalid output if the
     input/output length exceeds 64k minus Ofs(Dest).

  2. The compressed output data may actually be longer than the input data
     if the input already has high "entropy".  Compression typically increases
     the data entropy.  Multiple compressions, therefore, are usually a waste
     of time.

  3. As indicated in the ACM reference, this compression technique does not
     perform as well as LZW and its variations on large text files.  It should
     be considered only where working storage is very scarce and/or the data
     to be compressed is expected to contain considerable redundency at the
     character level.  The reference indicates that this algorithm can do
     especially well with image files.

  This program is contributed to the public domain.
  Please report bugs to the author:

  Edwin T. Floyd [76067,747]
  #9 Adams Park Ct.
  Columbus, GA 31909
  404-576-3305 (work)
  404-322-0076 (home)

  History
  --------
  12-27-89 Added compressed sequential file objects
  12-07-89 Added 'cld' to compmark.asm, added auto-init detection logic
  10-15-89 Initial Upload

}
Interface Uses DOS;

Type
  { High-level objects for compressed sequential file support. }

  CompFileBase = Object
  { Used by objects below - Don't instantiate this object }
    CompBuff : Pointer; { Pointer to I/O buffer }
    CompTree : Pointer; { Pointer to compression/expansion work area }
    CompTrLen : LongInt;{ Length of compression/expansion work area }
    CompTotal : LongInt;{ Total size of uncompressed data in file }
    CompPosn : Word;    { Current position in I/O buffer }
    CompBufSize : Word; { I/O buffer size }
    CompFile : File;    { Physical file }
    CompName : PathStr; { File name }
    CompOpen : Boolean; { True if file is open }
    CompBits : Byte;    { Current bits value }
    Constructor Init;   { Dummy constructor, aborts program }
    Destructor Done; Virtual; { Close file and release buffer and work area }
  End;

  CompFileIn = Object(CompFileBase)
  { Compressed sequential input file }
    CompBytes : Word;   { Number of bytes currently in buffer }
    Constructor Init(Name : PathStr; BufSize : Word);
      { Name specifies an existing compressed sequential file.  BufSize
        specifies the size of I/O buffer to obtain from the heap.  File is
        initially positioned to the first record. }
    Procedure GetRecord(Var Rec; Len : Word);
      { Uncompress the current record into Rec for a maximum length of Len
        bytes and update the file position to the next record. }
    Function RecLength : Word;
      { Returns the uncompressed length in bytes of the current record (this
        is the length of the record to be returned by the next GetRecord). }
    Function Eof : Boolean;
      { Returns TRUE after the last record has been retrieved by GetRecord. }
    Procedure Rewind;
      { Call this at any time to restart at the first record. }
  End;

  CompFileOut = Object(CompFileBase)
  { Compressed sequential output file }
    CompFlushed : Boolean; { True if output file doesn't need flushing }
    Constructor Init(Name : PathStr; BufSize : Word);
      { Name specifies the compressed sequential file to be created.  BufSize
        specifies the size of buffer to obtain from the heap.  After Init,
        the file is empty and ready to receive the first record.  As a rule,
        BufSize should be AT LEAST 1.25 * SizeOf(Largest_Rec) + 5.  To specify
        the 'Bits' value to be used for compression, call InitCompress
        immediately before the call to this constructor, otherwise Bits=0. }
    Destructor Done; Virtual;
      { Flush any remaining records in the buffer to the file, close the
        the file and release the buffer. }
    Procedure PutRecord(Var Rec; Len : Word);
      { Compress Rec for Len bytes and write to the file. }
    Procedure Flush;
      { Flush any records in the buffer to the file, close the file, re-open,
        and position to end of file. }
  End;

  CompFileAppend = Object(CompFileOut)
  { Append to existing compressed sequential file }
    Constructor Init(Name : PathStr; BufSize : Word);
      { Name and BufSize as above.  After this Init, if the file already
        exists, it is positioned at the end of file ready to receive the next
        record.  If the file doesn't exist, a new file is created, as for
        CompFileOut.  Specify the 'Bits' value as above; bits may be different
        from the value originally specified. }
  End;

{ Low-level routines for buffer compression/expansion. }

Procedure InitCompress(Bits : Byte);
{ Allocate compression/expansion  work area and initialize.  "Bits" refers to
  the number of bits in the current plain-text byte that determine the "state"
  of the Markov model to use for the next byte.  "Bits" may be any value from
  0 to 8.  The size of the work area is determined by the number of states that
  may be specified by the indicated number of bits (plus 16 bytes).  Each state
  is a Splay tree which occupies 1.5K of memory, so e.g, Bits=0 => determines
  1 tree, or 1536+16 for a work area size of 1552 bytes.  Bits=2 determines 4
  trees or 4*1536+16 for a 6160 byte work area.   Bits=8 determines 256 trees
  for a size of 393232 bytes.  In general, the larger the number of states,
  the better the compression.   If InitCompress is not called, CompressData
  will call it with Bits = 0, and ExpandData will call it with the same "Bits"
  setting used on the compressed buffer.  InitCompress allocates its work area
  with HugeGetMem from the public domain TPALLOC unit by Brian Foley of
  TurboPower Software. }

Function WorkAreaSize(Bits : Byte) : LongInt;
{ This function returns the length in bytes of the work area that would be
  allocated by InitCompress with the indicated Bits setting. }

Function CompressData(Var Source; Count : Word; Var Dest) : Word;
{ Compress Count bytes from Source and place the compressed data in Dest.
  The length of the compressed data is returned as the function result. }

Function ExpandData(Var Source; Var Dest) : Word;
{ Expand compressed data from Source and place the expanded data in Dest.
  The length of the expanded data is returned as the function result. }

Function ExpandedLength(Var Source) : Word;
{ Inspect the compressed data in Source and return the length it will have
  when expanded. }

Procedure ExpandDataLimited(Var Source; Var Dest; Len : Word);
{ Expand compressed data from Source and place the expanded data in Dest.
  Truncate the expanded data to no more than Len bytes. }

Implementation
Uses TpAlloc;

Const
  MagicNumber = $4295E8F6;
  { This number marks the beginning of a compressed sequential file. }
  ReadMode = $40;     { Deny None, Read access }
  WriteMode = $42;    { Deny None, Read/Write access }

Type
  BigArray = Array[0..65534] Of Byte;

  BufHeader = Record
    BufLength : Word; { Length of un-compressed data }
    BufBits : Byte;   { 'Bits' value used to compress this buffer }
    BufData : Byte;   { Beginning of compressed data }
  End;

Var
  CompWork : Pointer; { Pointer to compression work area }
  WorkSize : LongInt; { Work area size }
  InitBits : Byte;    { 'Bits' value for current work area }

{$F-}
Procedure InitSplay(Var Work; Bits : Word);
External; { NEAR call }

Function CompressBuffer(Var Work; Var Source; Count : Word; Var Dest) : Word;
External; { NEAR call }

Procedure ExpandBuffer(Var Work; Var Source; Var Dest; Count : Word);
External; { NEAR call }

{$L COMPMARK.OBJ }

Function WorkAreaSize(Bits : Byte) : LongInt;
Begin
  If Bits > 8 Then Bits := 8;
  WorkAreaSize := (LongInt(1) Shl Bits) * 1536 + 16;
End;

Procedure InitCompress(Bits : Byte);
Begin
  Bits := Bits And $7F;
  If Bits > 8 Then Bits := 8;
  If Bits <> (InitBits And $7F) Then Begin
    HugeFreeMem(CompWork, WorkSize);
    WorkSize := WorkAreaSize(Bits);
    HugeGetMem(CompWork, WorkSize);
    If CompWork = Nil Then Begin
      WriteLn('InitCompress is unable to allocate ', WorkSize,
        ' bytes of workarea');
      Halt(1);
    End;
    InitBits := Bits;
  End;
  InitSplay(CompWork^, Bits);
  InitBits := InitBits Or $80;
End;

Function CompressData(Var Source; Count : Word; Var Dest) : Word;
Var
  DestBuf : BufHeader Absolute Dest;
Begin
  If (InitBits And $7F) > 8 Then InitCompress(0);
  With DestBuf Do Begin
    BufLength := Count;
    BufBits := InitBits;
    InitBits := InitBits And $7F;
    If Count > 0 Then
      CompressData := CompressBuffer(CompWork^, Source, Count, BufData) + 3
    Else CompressData := 3;
  End;
End;

Function ExpandData(Var Source; Var Dest) : Word;
Var
  SourceBuf : BufHeader Absolute Source;
Begin
  With SourceBuf Do Begin
    If ((BufBits And $7F) <> (InitBits And $7F))
    Or ((BufBits And $80) <> 0) Then InitCompress(BufBits);
    If BufLength > 0 Then ExpandBuffer(CompWork^, BufData, Dest,
      BufLength);
    InitBits := InitBits And $7F;
    ExpandData := BufLength;
  End;
End;

Procedure ExpandDataLimited(Var Source; Var Dest; Len : Word);
Var
  SourceBuf : BufHeader Absolute Source;
Begin
  With SourceBuf Do Begin
    If ((BufBits And $7F) <> (InitBits And $7F))
    Or ((BufBits And $80) <> 0) Then InitCompress(BufBits);
    If Len > BufLength Then Len := BufLength;
    If Len > 0 Then ExpandBuffer(CompWork^, BufData, Dest, Len);
    InitBits := InitBits And $7F;
  End;
End;

Function ExpandedLength(Var Source) : Word;
Var
  SourceBuf : BufHeader Absolute Source;
Begin
  ExpandedLength := SourceBuf.BufLength;
End;

Constructor CompFileBase.Init;
Begin
  WriteLn('Use CompFileIn or CompFileOut');
  Halt(1);
End;

Destructor CompFileBase.Done;
Begin
  If CompOpen Then Begin
    Close(CompFile);
    CompOpen := False;
  End;
  If CompBufSize > 0 Then Begin
    FreeMem(CompBuff, CompBufSize);
    CompBufSize := 0;
  End;
  If CompTrLen > 0 Then Begin
    HugeFreeMem(CompTree, CompTrLen);
    CompTree := Nil;
    CompTrLen := 0;
    CompBits := 255;
  End;
End;

Constructor CompFileIn.Init(Name : PathStr; BufSize : Word);
Var
  Magic : LongInt;
  OldMode : Byte;
Begin
  CompOpen := False;
  CompBufSize := 0;
  CompBytes := 0;
  CompTree := Nil;
  CompTrLen := 0;
  CompBits := 255;
  CompPosn := 0;
  CompName := FExpand(Name);
  {$I-}
  OldMode := FileMode;
  FileMode := ReadMode;
  Assign(CompFile, CompName);
  Reset(CompFile, 1);
  FileMode := OldMode;
  {$I+}
  If IoResult = 0 Then Begin
    CompBufSize := BufSize;
    GetMem(CompBuff, CompBufSize);
    CompOpen := True;
    BlockRead(CompFile, Magic, SizeOf(Magic));
    BlockRead(CompFile, CompTotal, SizeOf(CompTotal));
    BlockRead(CompFile, CompBuff^, CompBufSize, CompBytes);
    If (Magic <> MagicNumber)
    Or ((CompBytes > 0) And (Word(CompBuff^) + 2 > CompBytes))
    Then Begin
      WriteLn('Invalid compressed file format: ', CompName);
      Halt(1);
    End;
  End;
End;

Procedure CompFileIn.GetRecord(Var Rec; Len : Word);
Var
  SaveWork : Pointer;
  SaveLen : LongInt;
  WorkLen : Word;
  SaveBits : Byte;
Begin
  SaveWork := CompWork;
  SaveLen := WorkSize;
  SaveBits := InitBits;
  CompWork := CompTree;
  WorkSize := CompTrLen;
  InitBits := CompBits;
  If CompBytes > 0 Then Begin
    ExpandDataLimited(BigArray(CompBuff^)[CompPosn+2], Rec, Len);
    Move(BigArray(CompBuff^)[CompPosn], WorkLen, 2);
    CompPosn := CompPosn + WorkLen + 2;
    Move(BigArray(CompBuff^)[CompPosn], WorkLen, 2);
    If (CompPosn >= CompBytes) Or (WorkLen + CompPosn + 2 > CompBytes)
    Then Begin
      If CompPosn < CompBytes Then Begin
        If CompPosn > 0 Then Begin
          CompBytes := CompBytes - CompPosn;
          Move(BigArray(CompBuff^)[CompPosn], CompBuff^, CompBytes);
        End;
      End Else CompBytes := 0;
      CompPosn := 0;
      If FilePos(CompFile) < FileSize(CompFile) Then Begin
        BlockRead(CompFile, BigArray(CompBuff^)[CompBytes],
          CompBufSize - CompBytes, WorkLen);
        CompBytes := CompBytes + WorkLen;
      End;
      If (CompBytes > 0) And (Word(CompBuff^) + 2 > CompBytes) Then Begin
        WriteLn('Invalid file format or buffer too short: ', CompName);
        WriteLn('Expecting ', Word(CompBuff^) + 2, ' bytes');
        WriteLn('Buffer holds ', CompBytes, ' bytes');
        WriteLn(WorkLen, ' bytes from last file read');
        WriteLn('File position is: ', FilePos(CompFile));
        Halt(1);
      End;
    End;
  End;
  CompTree := CompWork;
  CompTrLen := WorkSize;
  CompBits := InitBits;
  CompWork := SaveWork;
  WorkSize := SaveLen;
  InitBits := SaveBits;
End;

Function CompFileIn.RecLength : Word;
Begin
  If CompBytes > 0 Then
    RecLength := ExpandedLength(BigArray(CompBuff^)[CompPosn+2])
  Else RecLength := 0;
End;

Function CompFileIn.Eof : Boolean;
Begin
  Eof := CompBytes = 0;
End;

Procedure CompFileIn.Rewind;
Begin
  If CompOpen Then Begin
    Seek(CompFile, SizeOf(LongInt));
    BlockRead(CompFile, CompTotal, SizeOf(CompTotal));
    BlockRead(CompFile, CompBuff^, CompBufSize, CompBytes);
    CompPosn := 0;
  End;
End;

Constructor CompFileOut.Init(Name : PathStr; BufSize : Word);
Var
  Magic : LongInt;
  OldMode : Byte;
Begin
  CompBufSize := BufSize;
  CompName := FExpand(Name);
  OldMode := FileMode;
  FileMode := WriteMode;
  Assign(CompFile, CompName);
  ReWrite(CompFile, 1);
  FileMode := OldMode;
  Magic := MagicNumber;
  BlockWrite(CompFile, Magic, SizeOf(Magic));
  CompTotal := 0;
  BlockWrite(CompFile, CompTotal, SizeOf(CompTotal));
  CompOpen := True;
  GetMem(CompBuff, CompBufSize);
  CompPosn := 0;
  CompFlushed := True;
  If (InitBits And $80) <> 0 Then Begin
    CompTree := CompWork;
    CompTrLen := WorkSize;
    CompBits := InitBits;
    CompWork := Nil;
    WorkSize := 0;
    InitBits := 255;
  End Else Begin
    CompTree := Nil;
    CompTrLen := 0;
    CompBits := 255;
  End;
End;

Destructor CompFileOut.Done;
Begin
  If CompPosn > 0 Then BlockWrite(CompFile, CompBuff^, CompPosn);
  CompPosn := 0;
  Seek(CompFile, SizeOf(LongInt));
  BlockWrite(CompFile, CompTotal, SizeOf(CompTotal));
  CompFileBase.Done;
End;

Procedure CompFileOut.PutRecord(Var Rec; Len : Word);
Var
  WorkLen, CompLen : Word;
  SaveWork : Pointer;
  SaveLen : LongInt;
  SaveBits : Byte;
Begin
  SaveWork := CompWork;
  SaveLen := WorkSize;
  SaveBits := InitBits;
  CompWork := CompTree;
  WorkSize := CompTrLen;
  InitBits := CompBits;
  WorkLen := CompBufSize - CompPosn;
  If (Len + 5 > WorkLen) Or (Len + 5 > WorkLen - (Len Shr 2)) Then Begin
    BlockWrite(CompFile, CompBuff^, CompPosn);
    CompPosn := 0;
    WorkLen := CompBufSize;
  End;
  CompLen := CompressData(Rec, Len, BigArray(CompBuff^)[CompPosn+2]);
  If CompLen > WorkLen Then Begin
    WriteLn('Fatal error - Buffer overflow');
    Close(CompFile);
    Halt(1);
  End;
  Inc(CompTotal, Len);
  Move(CompLen, BigArray(CompBuff^)[CompPosn], 2);
  CompPosn := CompPosn + CompLen + 2;
  CompFlushed := False;
  CompTree := CompWork;
  CompTrLen := WorkSize;
  CompBits := InitBits;
  CompWork := SaveWork;
  WorkSize := SaveLen;
  InitBits := SaveBits;
End;

Procedure CompFileOut.Flush;
Var
  OldMode : Byte;
Begin
  If Not CompFlushed Then Begin
    If CompPosn > 0 Then BlockWrite(CompFile, CompBuff^, CompPosn);
    CompPosn := 0;
    Seek(CompFile, SizeOf(LongInt));
    BlockWrite(CompFile, CompTotal, SizeOf(CompTotal));
    Close(CompFile);
    OldMode := FileMode;
    FileMode := WriteMode;
    Reset(CompFile, 1);
    FileMode := OldMode;
    Seek(CompFile, FileSize(CompFile));
    CompFlushed := True;
  End;
End;

Constructor CompFileAppend.Init(Name : PathStr; BufSize : Word);
Var
  Magic : LongInt;
  OldMode : Byte;
Begin
  CompName := FExpand(Name);
  {$I-}
  OldMode := FileMode;
  FileMode := WriteMode;
  Assign(CompFile, CompName);
  Reset(CompFile, 1);
  {$I+}
  If IoResult = 0 Then Begin
    BlockRead(CompFile, Magic, SizeOf(Magic));
    If Magic <> MagicNumber Then Begin
      WriteLn('Invalid compressed file format: ', CompName);
      Halt(1);
    End;
    BlockRead(CompFile, CompTotal, SizeOf(CompTotal));
    Seek(CompFile, FileSize(CompFile));
  End Else Begin
    ReWrite(CompFile, 1);
    Magic := MagicNumber;
    BlockWrite(CompFile, Magic, SizeOf(Magic));
    CompTotal := 0;
    BlockWrite(CompFile, CompTotal, SizeOf(CompTotal));
  End;
  FileMode := OldMode;
  CompOpen := True;
  CompBufSize := BufSize;
  GetMem(CompBuff, CompBufSize);
  CompPosn := 0;
  CompFlushed := True;
  If (InitBits And $80) <> 0 Then Begin
    CompTree := CompWork;
    CompTrLen := WorkSize;
    CompBits := InitBits;
    CompWork := Nil;
    WorkSize := 0;
    InitBits := 255;
  End Else Begin
    CompTree := Nil;
    CompTrLen := 0;
    CompBits := 255;
  End;
End;

Begin
  CompWork := Nil;
  WorkSize := 0;
  InitBits := 255;
End.