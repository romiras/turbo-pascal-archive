{$A+,B-,D+,E-,F-,G-,I+,L+,N-,O-,R-,S-,V-,X-}
{$M 16384,0,655360}
{******************************************}
{  SIXPACK.C -- Data compression program   }
{  Written by Philip G. Gage, April 1991   }
{  Translated into Pascal Nov. 1991        }
{   by Douglas Webb                        }
{******************************************}

CONST
  TEXTSEARCH = 1000;   { Max strings to search in text file - smaller -> Faster compression}
  BINSEARCH  =  200;   { Max strings to search in binary file }
  TEXTNEXT   =   50;   { Max search at next character in text file - Smaller -> better compression }
  BINNEXT    =   20;   { Max search at next character in binary file }
  MAXFREQ    = 2000;   { Max frequency count before table reset }
  MINCOPY    =    3;   { Shortest string COPYING length }
  MAXCOPY    =   64;   { Longest string COPYING length }
  SHORTRANGE =    3;   { Max distance range for shortest length COPYING }
  COPYRANGES =    6;   { Number of string COPYING distance bit ranges @@@}
  CopyBits : Array[0..PRED(COPYRANGES)] OF INTEGER = (4,6,8,10,12,14);   { Distance bits }
  CODESPERRANGE = (MAXCOPY - MINCOPY + 1);

  NUL = -1;                    { End of linked list marker }
  HASHSIZE = 16384;            { Number of entries in hash table }
  HASHMASK = (HASHSIZE - 1);   { Mask for hash key wrap }

{ Adaptive Huffman variables }
  TERMINATE = 256;             { EOF code }
  FIRSTCODE = 257;             { First code for COPYING lengths }
  MAXCHAR = (FIRSTCODE+COPYRANGES*CODESPERRANGE-1);
  SUCCMAX = (MAXCHAR+1);
  TWICEMAX = (2*MAXCHAR+1);
  ROOT = 1;
  MAXBUF = 4096;

{** Bit packing routines **}
  Input_Bit_Count : WORD = 0;                { Input bits buffered }
  Input_Bit_Buffer: WORD = 0;                   { Input buffer }
  Output_Bit_Count: WORD = 0;                   { Output bits buffered }
  Output_Bit_Buffer : WORD = 0;                 { Output buffer }
  Bytes_Out : Longint = 0;                      { File size counters }
  Bytes_In : LongINT = 0;

  OutBufCount : INTEGER = 0;
  InBufCount  : INTEGER = 0;


TYPE
  Copy_Type = Array[0..PRED(CopyRanges)] OF Integer;


CONST
  CopyMin : Copy_Type = (0,16,80,336,1360,5456);
  CopyMax : Copy_Type = (15,79,335,1359,5455,21839);
  MaxDistance : Integer = CopyMax[PRED(COPYRANGES)];
  MaxSize = 21839 + MAXCOPY;   { @@@ }


TYPE
  HashType = Array[0..PRED(HashSize)] OF Integer;
  Hash_Ptr = ^HashType;
  ListType = Array[0..MaxSize] OF Integer;
  List_Ptr = ^ListType;
  Buffer_Type = Array[0..MaxSize] OF BYTE;            { Convenient typecast. }
  Buffer_Ptr = ^Buffer_Type;
  HTree_Type = Array[0..MaxChar] OF WORD;
  THTree_Type = Array[0..TwiceMax] OF WORD;
  BufType = Array[0..PRED(MAXBUF)] OF BYTE;
  BufPtr = ^BufType;
  WDBufType = Array[0..PRED(MAXBUF)] OF WORD;
  WDBufPtr = ^WDBufType;


VAR
  Head, Tail : Hash_Ptr;         { Hash table }
  Next, Prev : List_Ptr;       { Doubly linked lists }
  Buffer : Buffer_Ptr;           { Text buffer }
  Distance, Insrt, DictFile, Binary : Integer;
  LeftC, RightC : HTree_Type;  { Huffman tree }
  Parent,Freq : THTree_Type;
  InBuf,OutBuf : BufPtr;
  WDBuf : WDBufPtr;
  InFIle,OutFile : FILE;



{***************** Compression & Decompression *****************}

{ Initialize data for compression or decompression }

Procedure initialize;
VAR
   I, J : Integer;
BEGIN
  { Initialize Huffman frequency tree }
  FOR I := 2 TO TWICEMAX DO
    BEGIN
      Parent[I] := I DIV 2;
      Freq[I] := 1;
    END;
  FOR I := 1 TO MAXCHAR DO
    BEGIN
      LeftC[I] := 2*I;
      RightC[I] := 2*I+1;
    END;
END;




{********************* Compression Routines ***********************}



{ Write one bit to output file }
Procedure Output_Bit(Bit: Integer);

BEGIN
  Output_Bit_Buffer := Output_Bit_Buffer SHL 1;
  IF Boolean(Bit) THEN Output_Bit_Buffer := Output_Bit_Buffer OR 1;
  INC(OutPut_Bit_Count);
  IF (Output_Bit_Count = 16) THEN
    BEGIN
      WdBuf^[OutBufCount] := Output_Bit_Buffer;
      INC(OutBufCount);
      Output_Bit_Count := 0;
      INC(Bytes_Out,2);
      IF OutBufCount = MAXBUF THEN
        BEGIN
          BlockWrite(OutFile,WdBuf^,MAXBUF*2);
          OutBufCount := 0;
        END;
    END;
END;



{ Write multibit code to output file }
Procedure Output_Code(Code, Bits : Integer);
VAR
  I : Integer;
BEGIN
  FOR I := 0 TO PRED(Bits) DO
    BEGIN
      Output_Bit(Code AND $1);
      Code := Code SHR 1;
    END;
END;


{ Flush any remaining bits to output file before closing file }
Procedure Flush_Bits;

BEGIN
  IF (Output_Bit_Count > 0) THEN
    BEGIN
      Output_Bit_Buffer := Output_Bit_Buffer SHL (16-Output_Bit_Count);
      WdBuf^[OutBufCount] := Output_Bit_Buffer;
      INC(OutBufCount);
      Output_Bit_Count := 0;
      INC(Bytes_Out,2);
    END;
  BlockWrite(OutFile,WdBuf^,OutBufCount*2);
END;





{ Update frequency counts from leaf to root }
Procedure Update_Freq(A,B : Integer);
BEGIN
  REPEAT
    Freq[Parent[A]] := Freq[A] + Freq[B];
    A := Parent[A];
    IF (A <> ROOT) THEN
      BEGIN
        IF (LeftC[Parent[A]] = A) THEN
          B := RightC[Parent[A]]
        ELSE B := LeftC[Parent[A]];
      END;
  UNTIL A = ROOT;

  { Periodically scale frequencies down by half to avoid overflow }
  { This also provides some local adaption and better compression }

  IF (Freq[ROOT] = MAXFREQ) THEN
    FOR A := 1 TO TWICEMAX DO
      Freq[a] := Freq[a] SHR 1;
END;



{ Update Huffman model for each character code }
Procedure Update_Model(Code : Integer);
VAR
  A, B, C, Ua, Uua : Integer;

BEGIN
  A := Code + SUCCMAX;
  INC(Freq[A]);
  IF (Parent[A] <> ROOT) THEN
    BEGIN
      ua := Parent[a];
      IF (LeftC[ua] = a) THEN update_freq(a,RightC[ua])
      ELSE update_freq(a,LeftC[ua]);
      REPEAT
        uua := Parent[ua];
        IF (LeftC[uua] = ua) THEN
          b := RightC[uua]
        ELSE b := LeftC[uua];

        { IF high Freq lower in tree, swap nodes }
        IF Freq[a] > Freq[b] THEN
          BEGIN
            IF LeftC[Uua] = ua THEN
              RightC[Uua] := A
            ELSE LeftC[Uua] := A;
            IF (LeftC[ua] = a) THEN
              BEGIN
                LeftC[Ua] := B;
                C := RightC[ua];
              END
            ELSE
              BEGIN
                RightC[Ua] := B;
                C := LeftC[Ua];
              END;
            Parent[b] := Ua;
            Parent[a] := Uua;
            Update_Freq(B,C);
            A := B;
          END;
        A := Parent[A];
        Ua := Parent[A];
      UNTIL Ua = ROOT;
    END;
END;



{ Compress a character code to output stream }
Procedure Compress(code: Integer);
VAR
  a, sp : Integer;
  Stack : Array[0..49] OF Integer;
BEGIN
  Sp := 0;
  A := Code + SUCCMAX;
  REPEAT
    Stack[Sp] := Integer(RightC[Parent[A]] = A);
    INC(Sp);
    A := Parent[A];
  UNTIL (A = ROOT);

  REPEAT
    DEC(Sp);
    Output_Bit(Stack[Sp]);
  UNTIL sp = 0;
  Update_Model(Code);
END;



{** Hash table linked list string search routines **}

{ Add node to head of list }
Procedure Add_Node(N: Integer);
VAR
  Key :  Integer;

BEGIN
{ Define hash key function using MINCOPY characters of string prefix }
  Key := (Buffer^[N] XOR (Buffer^[(N+1) MOD MaxSize] SHL 4)) XOR
                   (Buffer^[(N+2) MOD Maxsize] SHL 8) AND HASHMASK;
  IF (Head^[Key] = NUL) THEN
    BEGIN
      Tail^[Key] := N;
      Next^[N] := NUL;
    END
  ELSE
    BEGIN
      Next^[N] := Head^[Key];
      Prev^[Head^[Key]] := N;
    END;
  Head^[Key] := N;
  Prev^[N] := NUL;
END;



{ Delete node from tail of list }
Procedure Delete_Node(N : Integer);
VAR
  K : Real;
  Key :  Integer;

BEGIN
{ Define hash key function using MINCOPY characters of string prefix }
  Key := (Buffer^[N] XOR (Buffer^[(N+1) MOD MaxSize] SHL 4)) XOR
                   (Buffer^[(N+2) MOD Maxsize] SHL 8) AND HASHMASK;
  IF (Head^[Key] = Tail^[Key]) THEN
    Head^[Key] := NUL
  ELSE
    BEGIN
      Next^[Prev^[Tail^[Key]]] := NUL;
      Tail^[Key] := Prev^[Tail^[Key]];
    END;
END;



{ Find longest string matching lookahead buffer string }
Function Match(N,Depth: Integer): Integer;
LABEL 1;
VAR
   I, J, Index, Key, Dist, Len, Best, Count  : Integer;
BEGIN
  Best := 0;
  Count := 0;

  IF (N = MaxSize) THEN
    N := 0;

{ Define hash key function using MINCOPY characters of string prefix }
  Key := (Buffer^[N] XOR (Buffer^[(N+1) MOD MaxSize] SHL 4)) XOR
                   (Buffer^[(N+2) MOD Maxsize] SHL 8) AND HASHMASK;
  Index := Head^[Key];
  WHILE (Index <> NUL) DO
    BEGIN
      INC(Count);
      IF (Count > Depth) THEN Goto 1;     { Quit IF depth exceeded }
      IF (Buffer^[(N+Best) MOD MaxSize] = Buffer^[(Index+Best) MOD MaxSize]) THEN
        BEGIN
          Len := 0;
          I := N;
          J := Index;
          WHILE (Buffer^[I] = Buffer^[J]) AND (Len<MAXCOPY) AND ((J<>N) AND (I<>Insrt)) DO
            BEGIN
              INC(Len);
              INC(I);
              IF (I = MaxSize) THEN
                I := 0;
              INC(J);
              IF (J = MaxSize) THEN
                J := 0;
            END;
          Dist := N - Index;
          IF (Dist < 0) THEN
            Dist := Dist + MaxSize;
          Dist := Dist - Len;
      { IF dict file, quit at shortest distance range }
          IF (DictFile AND Dist > CopyMax[0]) THEN Goto 1;
          IF (Len > Best) AND (Dist <= MaxDistance) THEN
            BEGIN     { Update best match }
              IF (Len > MINCOPY) OR (Dist <= CopyMax[SHORTRANGE+Binary]) THEN
                BEGIN
                  Best := Len;
                  Distance := Dist;
                END;
            END;
        END;
      Index := Next^[Index];
    END;
1: Match := Best;
END;




{** Finite Window compression routines **}

CONST
  IDLE = 0;    { Not processing a COPYING }
  COPYING = 1;    { Currently processing COPYING }

{ Check first buffer for ordered dictionary file }
{ Better compression using short distance copies }

Procedure Dictionary;
VAR
  i, j, k, count : Integer;
BEGIN
  I := 0;
  J := 0;
  Count := 0;

  { Count matching chars at start of adjacent lines }
  INC(J);
  WHILE (J < MINCOPY+MAXCOPY) DO
    BEGIN
      IF (Buffer^[J-1] = 10) THEN
        BEGIN
          K := J;
          WHILE (Buffer^[I] = Buffer^[K]) DO
            BEGIN
              INC(I);
              INC(K);
              INC(count);
            END;
          I := J;
        END;
      INC(J);
    END;
  { IF matching line prefixes > 25% assume dictionary }
  IF (Count > (MINCOPY+MAXCOPY) DIV 4) THEN
    DictFile := 1;
END;





{ Encode file from input to output }
Procedure Encode;
LABEL 1,2;

VAR
  C, I, N, Addpos, Len, Full, State, Nextlen, Result: Integer;

BEGIN
  N := MINCOPY;
  Addpos := 0;
  Len := 0;
  Full := 0;
  State := IDLE;
  C := 0;
  initialize;
  New(InBuf);
  New(WdBuf);
  GetMem(Head,HASHSIZE*Sizeof(INTEGER));
  GetMem(Tail,HASHSIZE*Sizeof(INTEGER));
  GetMem(Next,MaxSize*Sizeof(INTEGER));
  GetMem(Prev,MaxSize*Sizeof(INTEGER));
  GetMem(Buffer,MaxSize*Sizeof(BYTE));
  IF (head=NIL) OR (Tail=NIL) OR (Next=NIL) OR (Prev=NIL) OR (Buffer=NIL) THEN
    BEGIN
      Writeln('Error allocating memory');
      Halt(1);
    END;

  { Initialize hash table to empty }
  FOR I := 0 TO PRED(HASHSIZE) DO
    BEGIN
      Head^[I] := NUL;
    END;

  BlockRead(InFile,InBuf^,MAXBUF,Result);
  { Compress first few characters using Huffman }
  FOR I := 0 TO PRED(MINCOPY) DO
    BEGIN
      C := InBuf^[InBufCount];
      INC(InBufCount);
      IF InBufCount = Result THEN
        BEGIN
          Compress(TERMINATE);
          Flush_bits;
          FreeMem(Head,HASHSIZE*Sizeof(INTEGER));
          FreeMem(Tail,HASHSIZE*Sizeof(INTEGER));
          FreeMem(Next,MaxSize*Sizeof(INTEGER));
          FreeMem(Prev,MaxSize*Sizeof(INTEGER));
          FreeMem(buffer,MaxSize*Sizeof(BYTE));
          Dispose(Wdbuf);
          Dispose(InBuf);
          Exit;
        END;
      Compress(C);
      INC(Bytes_In);
      Buffer^[I] := C;
    END;


  { Preload next few characters into lookahead buffer }
  FOR I := 0 To PRED(MAXCOPY) DO
    BEGIN
      C := InBuf^[InBufCount];
      INC(InBufCount);
      IF InBufCount = Result THEN Goto 1;
      Buffer^[Insrt] := C;
      INC(Insrt);
      INC(Bytes_In);
      IF (C > 127) THEN
        Binary := 1;     { Binary file ? }
    END;

1:
  Dictionary;  { Check for dictionary file }

  WHILE (N <> Insrt) Do
    BEGIN
    { Check compression to insure really a dictionary file }
      IF (Boolean(dictfile) AND ((Bytes_In MOD MAXCOPY) = 0)) THEN
        IF (Bytes_In/Bytes_Out < 2) THEN
          Dictfile := 0;     { Oops, not a dictionary file ! }

    { Update nodes in hash table lists }
      IF BOOLEAN(Full)  THEN Delete_Node(Insrt);
      Add_node(Addpos);

    { IF doing COPYING, process character, ELSE check for new COPYING }
      IF (State = COPYING) THEN
        BEGIN
          DEC(Len);
          IF (len = 1) THEN
            State := IDLE;
        END
      ELSE
        BEGIN

      { Get match length at next character and current char }
          IF BOOLEAN(binary) THEN
            BEGIN
              Nextlen := Match(N+1,BINNEXT);
              Len := Match(N,BINSEARCH);
            END
          ELSE
            BEGIN
              Nextlen := Match(N+1,TEXTNEXT);
              Len := Match(N,TEXTSEARCH);
            END;

      { IF long enough and no better match at next char, start COPYING }
          IF (Len >= MINCOPY) AND (len >= NextLen) THEN
            BEGIN
              State := COPYING;

        { Look up minimum bits to encode distance }
              FOR I := 0 To PRED(COPYRANGES) DO
                BEGIN
                  IF (distance <= CopyMax[i]) THEN
                    BEGIN
                      Compress(FIRSTCODE-MINCOPY+Len+I*CODESPERRANGE);
                      Output_code(Distance-CopyMin[I],CopyBits[I]);
                      Goto 2;
                    END;
                END;
2:
            END
          ELSE   { ELSE output single literal character }
            Compress(Buffer^[N]);
        END;

    { Advance buffer pointers }
      INC(N);
      IF (N = MaxSize) THEN
        N := 0;
      INC(Addpos);
      IF (Addpos = MaxSize) THEN
        Addpos := 0;

    { Add next input character to buffer }
      IF InBufCount < Result THEN
        BEGIN
          C := InBuf^[InBufCount];
          INC(InBufCount);
          IF InBufCount = MAXBUF THEN
            BEGIN
              BlockRead(InFile,InBuf^,MAXBUF,Result);
              InBufCount := 0;
            END;
          Buffer^[Insrt] := C;
          Inc(Insrt);
          INC(Bytes_In);
          IF (Insrt = MaxSize) THEN
            BEGIN
              Insrt := 0;
              Full := 1;
            END;
        END
      ELSE Full := 0;
    END;

  { Output EOF code and free memory }
  compress(TERMINATE);
  Flush_Bits;
  FreeMem(Head,HASHSIZE*Sizeof(INTEGER));
  FreeMem(Tail,HASHSIZE*Sizeof(INTEGER));
  FreeMem(Next,MaxSize*Sizeof(INTEGER));
  FreeMem(Prev,MaxSize*Sizeof(INTEGER));
  FreeMem(buffer,MaxSize*Sizeof(BYTE));
  Dispose(WDBuf);
  Dispose(InBuf);
END;





{********************* Decompression Routines ********************}







{ Read multibit code from input file }
Function Input_Code(Bits:Integer): WORD;
CONST
  Bit : Array[1..14] OF WORD = (1,2,4,8,16,32,64,128,256,512,1024,
                                2048,4096,8192);
VAR
  I, Code, Result : WORD;
BEGIN
  Code := 0;
  FOR I := 1 TO Bits DO
    BEGIN
      IF (Input_Bit_Count = 0) THEN
        BEGIN
          IF (InBufCount = MAXBUF) THEN
            BEGIN
              BlockRead(InFile,WdBuf^,MAXBUF*2,Result);
              INC(Bytes_In,Result);
              InBufCount := 0;
              IF (Result = 0) THEN
                BEGIN
                  Writeln('UNEXPECTED END OF FILE');
                  HALT(1);
                END;
            END;
          Input_Bit_Buffer := Wdbuf^[InBufCount];
          INC(InBufCount);
          Input_Bit_Count := 15;
        END
      ELSE DEC(Input_Bit_Count);
      IF Input_Bit_Buffer > $7FFF THEN Code := Code OR Bit[I];
      Input_Bit_Buffer :=  Input_Bit_Buffer SHL 1;
    END;
  Input_Code := Code;
END;





{ Uncompress a character code from input stream }
Function Uncompress: WORD;
LABEL
 TOP,AFT,OVER,NOREAD;
VAR
  Result : WORD;
BEGIN
  ASM
    MOV BX, 1
    MOV DX, Input_Bit_Count
    MOV CX, Input_Bit_Buffer
    MOV AX, InBufCount
TOP:                           { REPEAT                               }
    OR   DX, DX                {  IF Input_Bit_Count <> 0 THEN        }
    JNE  AFT                   {    BEGIN                             }
    CMP  AX, MAXBUF            {      IF InBufCount = MAXBUF THEN     }
    JNE  NOREAD                {        BEGIN                         }
    PUSH BX
    PUSH CX
    PUSH DX
  END;
  BlockRead(InFile,WdBuf^,MAXBUF*2,Result);
  INC(Bytes_In,Result);
  IF (Result = 0) THEN
    BEGIN
      Writeln('UNEXPECTED END OF FILE');
      HALT(1);
    END;
  ASM
    POP DX
    POP CX
    POP BX
    XOR AX, AX                 {          InBufCount := 0;            }
NOREAD:                        {        END;                          }
    SHL AX,1                   {      Input_Bit_Buffer := InBuf^[InBufCount];}
    LES DI,[WdBuf]
    ADD DI,AX
    SHR AX,1
    MOV CX,ES:[DI]
    INC AX                     {      INC(InBufCount);                }
    MOV DX,$F                  {      Input_Bit_Count := 15;          }
    JMP OVER                   {    END                               }
AFT:
    DEC DX                     {  ELSE DEC(Input_Bit_Count);          }
OVER:
    CMP CX,$7FFF               {  IF Input_Bit_Buffer > $7FFF THEN    }
    JBE @Less
    MOV DI,BX                  {    A := RightC[A];                   }
    SHL DI,1
    MOV BX,[DI+OFFSET RightC]
    JMP @After
@Less:
    MOV DI,BX                  {  ELSE A := LeftC[A];                 }
    SHL DI,1
    MOV BX,[DI+OFFSET LeftC]
@After:
    SHL  CX,1                  {  Input_BitBuffer := Input_Bit_Buffer SHL 1;}
    CMP  BX, MAXCHAR           { UNTIL A > MAXCHAR;                   }
    JLE  TOP
    SUB  BX, SUCCMAX           { DEC(A,SUCCMAX);                      }
    MOV  Input_Bit_Count, DX
    MOV  Input_Bit_Buffer, CX
    MOV  InBufCount, AX
    PUSH BX
    PUSH BX
    CALL UPDATE_MODEL          { Model_Update(A);                     }
    POP  AX
    MOV  [BP-2],AX             { Uncompress := A;                     }
  END;
END;





{ Decode file from input to output }
Procedure decode;

VAR
  I, J, Dist, Len, Index, K, T : INTEGER;
  N, Result, C : WORD;

BEGIN
  New(WDBuf);
  New(OutBuf);
  N := 0;
  InBufCount := MAXBUF;
  initialize;
  GetMem(Buffer,MaxSize*Sizeof(BYTE));
  IF (Buffer = NIL) THEN
    BEGIN
      Writeln('Error allocating memory');
      HALT(1);
    END;
  C := Uncompress;
  WHILE (C <> TERMINATE) DO
    BEGIN
      IF (C < 256) THEN
        BEGIN     { Single literal character ? }
          OutBuf^[OutBufCount] := C;
          INC(OutBufCount);
          IF OutBufCount = MAXBUF THEN
            BEGIN
              BlockWrite(OutFile,OutBuf^,MAXBUF,Result);
              OutBufCount := 0;
              INC(Bytes_Out,Result);
            END;
          Buffer^[N] := C;
          INC(N);
          IF (N = MaxSize) THEN
            N := 0;
        END
      ELSE
        BEGIN            { ELSE string copy length/distance codes }
          T := C - FIRSTCODE;
          Index := (T) DIV CODESPERRANGE;
          Len := T + MINCOPY - Index*CODESPERRANGE;
          Dist := Input_Code(CopyBits[Index]) + Len + CopyMin[Index];
          J := N;
          K := N - Dist;
          IF (K < 0) THEN
            INC(K,MaxSize);
          FOR i := 0 To PRED(Len) DO
            BEGIN
              OutBuf^[OutBufCount] := Buffer^[K];
              INC(OutBufCount);
              IF OutBufCount = MAXBUF THEN
                BEGIN
                  BlockWrite(OutFile,OutBuf^,MAXBUF,Result);
                  OutBufCount := 0;
                  INC(Bytes_Out,Result);
                END;
              Buffer^[J] := Buffer^[K];
              INC(J);
              INC(K);
              IF (J = Maxsize) THEN J := 0;
              IF (K = Maxsize) THEN K := 0;
            END;
          INC(N,Len);
          IF (N >= Maxsize) THEN
            DEC(N,MaxSize);
        END;
      C := Uncompress;
    END;
  BlockWrite(OutFile,OutBuf^,OutBufCount,Result);
  INC(Bytes_Out, Result);
  FreeMem(buffer,MaxSize*Sizeof(BYTE));
  Dispose(OutBuf);
  Dispose(WdBuf);
END;




{ Main program }
BEGIN
  Insrt := MINCOPY;
  Dictfile := 0;
  Binary := 0;
  Input_Bit_Count := 0;           { Input bits buffered }
  Input_Bit_Buffer := 0;          { Input buffer }
  Output_Bit_Count := 0;          { Output bits buffered }
  Output_Bit_Buffer := 0;         { Output buffer }
  Bytes_In := 0;
  Bytes_Out := 0;                 { File size counters }


  IF (ParamCount < 2) OR (ParamCount > 4) THEN
    BEGIN
      Writeln('Usage: ',ParamStr(0),' inputfile outputfile [decompress]');
      HALT;
    END;
  IF (ParamStr(1) = ParamStr(2)) THEN
    BEGIN
      Writeln('File names must be different');
      HALT;
    END;

  Assign(Infile,ParamStr(1));
{$I-}
  Reset(infile,1);
  IF IOResult <> 0 THEN
    BEGIN
      Writeln('Error opening input file ',ParamStr(1));
      HALT;
    END;

  Assign(OutFile,ParamStr(2));
  ReWrite(outFile,1);
{$I+}
  IF IOResult <> 0 THEN
    BEGIN
      Writeln('Error opening output file ',ParamStr(2));
      HALT;
    END;

   IF (ParamCount <> 3) THEN
     BEGIN
        Encode;
        Writeln('Packed from ',Bytes_In,' bytes to ',Bytes_Out,' bytes');
     END
   ELSE
     BEGIN
       Decode;
       Writeln('Unpacked from ',Bytes_In,' bytes to ',Bytes_out,' bytes');
    END;
  Close(outfile);
  Close(infile);
END.




