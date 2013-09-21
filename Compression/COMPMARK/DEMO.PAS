{$R-,S-}

program Demo;
  {-Demonstrates use of TPALLOC}

uses
  TpAlloc;

type
  LongPtr = ^LongInt;
var
  I, Elements, ErrorCount : LongInt;
  LongArray : LongPtr;
  LongArrayAddr : LongInt;

  function GetElementPtr(I : LongInt) : LongPtr;
    {-Return a pointer to the I'th element of our 0-based array}
  begin
    {Notes:
      1) Subtract 1 from I if array is 1-based.
      2) LongArrayAddr could be replaced with 'Linear(LongArray)', but this
         is much faster.}
    GetElementPtr := LinearToPointer(LongArrayAddr+(I*SizeOf(LongInt)));
  end;

  function GetElement(I : LongInt) : LongInt;
    {-Return the I'th element of our 0-based array}
  begin
    GetElement := GetElementPtr(I)^;
  end;

  procedure PutElement(I, Value : LongInt);
    {-Set the I'th element of our 0-based array to Value}
  begin
    GetElementPtr(I)^ := Value;
  end;

begin
  WriteLn('MaxAvail = ', MaxAvail);

  {allocate as large an array of longints as possible}
  Elements := MaxAvail div SizeOf(LongInt);
  HugeGetMem(LongArray, Elements * SizeOf(LongInt));
  if LongArray = nil then begin
    WriteLn('Unable to allocate array of ', Elements, ' elements');
    Halt(1);
  end;

  {this saves us from recomputing Linear(LongArray) repeatedly}
  LongArrayAddr := Linear(LongArray);

  {show memory status}
  WriteLn('Allocated ', Elements * SizeOf(LongInt), ' bytes');
  WriteLn('MaxAvail = ', MaxAvail);
  WriteLn('Successfully allocated array of ', Elements, ' elements');

  {initialize the array}
  WriteLn('Initializing array...');
  for I := 0 to Elements-1 do
    PutElement(I, I);

  {validate the array contents}
  WriteLn('Validating array contents...');
  ErrorCount := 0;
  for I := 0 to Elements-1 do
    if GetElement(I) <> I then begin
      WriteLn('Error at element ', I, ':  should be ', I, ', is ',
        GetElement(I));
      Inc(ErrorCount);
    end;

  {show status}
  if ErrorCount = 0 then
    WriteLn('No errors found')
  else
    WriteLn(ErrorCount, ' errors found');

  {release the memory}
  WriteLn('Releasing memory...');
  HugeFreeMem(LongArray, Elements * SizeOf(LongInt));
  WriteLn('MaxAvail = ', MaxAvail);
end.
