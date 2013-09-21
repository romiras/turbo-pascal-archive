Unit IO_Ptr;

Interface

Uses Declare,IO_Byte;

FUNCTION Readptr: TypePointer ;
PROCEDURE Writeptr( ptr: TypePointer) ;
PROCEDURE Flushbits ;



Implementation

var
  ByteBuffer: byte;
  BitsLeft: integer;


function BitsIn(i: TypePointer): integer;
var
  count: integer;

begin
  count:=0;
  while (2 shl count) < i do
    inc(count);
  BitsIn:=count+1;
end;



FUNCTION Readptr: TypePointer ;
VAR
   ptr: integer;
   BitsToRead: integer;
   count: integer;

BEGIN
  { compute how many bits to read }

  IF not PtrType THEN
    BitsToRead := BitsIn(MaxDict)
  ELSE
    BitsToRead := BitsIn(dictsize);

  ptr := 0 ;
  for count:=BitsToRead-1 downto 0 do begin
    if BitsLeft=0 then begin
      ByteBuffer:=ReadByte;
      BitsLeft:=8;
    end;
    dec(BitsLeft);
    ptr:= ptr+ (( (ByteBuffer shr BitsLeft) and 1) shl count);
  end;
  ReadPtr:=ptr;
END { Readptr } ;



PROCEDURE Writeptr( ptr: TypePointer) ;
VAR
  BitsToWrite: integer;
  count: integer;

BEGIN
  IF not PtrType THEN
    BitsToWrite:= BitsIn(MaxDict)
  ELSE
    BitsToWrite := BitsIn(dictsize);

  for count:=BitsToWrite-1 downto 0 do begin
    if BitsLeft=8 then begin
      Writebyte(ByteBuffer);
      ByteBuffer:=0;
      BitsLeft:=0;
    end;
    ByteBuffer:=ByteBuffer shl 1;
    ByteBuffer:=ByteBuffer+((ptr shr count) and 1);
    inc(BitsLeft);
  end;

END { Writeptr } ;



PROCEDURE Flushbits ;
BEGIN
  if BitsLeft<>0 then begin
    ByteBuffer:=ByteBuffer shl (8-BitsLeft);
    WriteByte(ByteBuffer);
    BitsLeft:=0;
  end;
END { Flushbits } ;


begin
  ByteBuffer:=0;
  BitsLeft:=0;
end.