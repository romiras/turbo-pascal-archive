{SWAG=OOP.SWG,TODD HOLMES,Flexible OOP Array,FLEXIBLE,OOP,ARRAY}
{
From: TODD HOLMES
Heres a flexible OOP array...}

{ $TESTED}

Uses Objects;
Type

  TestRec = Record
    Name: String[20];
    Age : Word;
   end;
   {A TestRecord}

  PAByte = ^TAByte;
  TAByte = Array[0..65519] of byte;
  {General byte array}

{TArray is limited to 65520 bytes of data, and may store any type
of data.}

  PArray = ^TArray;
  TArray = Object(TObject)
    Data    : PAByte;
    DataSize: Word;    {Size of the Data to hold}
    MaxCount: Word;    {Maximum amount of items of DataSize}
    Count   : Word;    {How many items in Array}
   Constructor Init(ADataSize,ACount:Word);
   Constructor Load(Var S:TStream);
   Procedure   Store(VAR S:TStream); Virtual;
   Destructor  Done;Virtual;
   Procedure   GetItem(Index:Word;Var Item);
   Procedure   PutItem(Index:Word;Var Item);
 end;

Constructor TArray.Init(ADataSize,ACount:Word);
 begin
  Inherited Init;  {TP6 Tobject.init}
  DataSize := ADataSize;
  MaxCount := 65520 div ADataSize;   {For Error Checking}
  If Acount > MaxCount then Fail;    {Array is too big}
  Count    := ACount;
  GetMem(Data,Count * DataSize);     {Get Mem for the array}
  FillChar(Data^,Count * DataSize,0);{Clear the Array}
 end;

Constructor TArray.Load(Var S:TStream);
 begin
  With S do begin
   Read(DataSize,SizeOf(DataSize));
   Read(MaxCount,SizeOf(MaxCount));
   Read(Count,SizeOf(MaxCount));
   GetMem(Data,Count * DataSize);
   Read(Data^,Count * DataSize);
  end;
 end;

Procedure TArray.Store(Var S:TStream);
 begin
  With S do Begin
   Write(DataSize,SizeOf(DataSize));
   Write(MaxCount,SizeOf(MaxCount));
   Write(Count,sizeOf(Count));
   Write(Data^,Count * DataSize);
  end;
 end;

Destructor TArray.done;
 begin
  FreeMem(Data,Count*DataSize);
  Inherited Done;
 end;

Procedure TArray.GetItem(Index:Word;Var Item);
 begin
  If Index > count then Exit;
  Move(Data^[(Index - 1) * DataSize],Item,DataSize);
 end;

Procedure TArray.PutItem(Index:Word;Var Item);
 begin
 If Index > count then exit;
  Move(Item,Data^[(Index - 1) * DataSize],DataSize);
 end;

Var
   Flexable:PArray;
   TR:TestRec;
    I:Integer;

begin
 Randomize;
 Flexable := New(PArray,Init(SizeOf(TR),10));
 If Flexable <> Nil then begin; {Array to big}
   For I := 1 to Flexable^.Count do begin
     With TR do begin
      Name := 'Bobby Sue';
      Age  := I;
     end;
     Flexable^.PutItem(I,TR);
    end;
   For I := 1 to FlexAble^.Count do begin
     FlexAble^.GetItem(I,TR);
     With Tr do
       Writeln('Rec ',I:2,' is Name: ',Name:20,' Age: ',Age:8);
    end;
   end;
 Dispose(Flexable,Done);
end.