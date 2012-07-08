{SWAG=OOP.SWG,KEN BURROWS,OBJ-DESC.PAS,OBJ,DESC,PAS}
{
KEN BURROWS

Well, here I go again. There have been a few messages here and there regarding
collections and Objects and streams. I've been trying to grapple With how
things work, and sometimes I win and sometimes I lose. The following code is my
rendition of a useful TObject Descendent. It is completely collectable and
streamable. Feel free to dismiss it offhand if you like.
}

Unit TBase3;  {BP 7.0}
	      {released to the public domain by ken burrows}
Interface
Uses
  Objects, memory;
Type
  TBase = Object(TObject)
	    Data : Pointer;
	    Constructor Init(Var Buf;n:LongInt);
	    Constructor Load(Var S:TStream);
	    Procedure Store(Var S:TStream); virtual;
	    Destructor Done; virtual;
	    Private
	    Size : LongInt;
	  end;
  PBase = ^TBase;

Const
  RBaseRec : TStreamRec = (ObjType : 19560;
			   VMTLink : Ofs(TypeOf(TBase)^);
			   Load    : @TBase.Load;
			   Store   : @TBase.Store);

Procedure RegisterTBase;

Implementation

Constructor TBase.Init(Var Buf; n : LongInt);
begin
  Data := MemAlloc(n);
  if Data <> Nil then
  begin
    size := n;
    move(Buf,Data^,size);
  end
  else
    size := 0;
end;

Constructor TBase.Load(Var S : TStream);
begin
  size := 0;
  S.Read(size,4);
  if (S.Status = StOk) and (size <> 0) then
  begin
    Data := MemAlloc(size);
    if Data <> Nil then
    begin
      S.read(Data^,size);
      if S.Status <> StOk then
      begin
	FreeMem(Data,size);
	size := 0;
      end;
    end
    else
      size := 0;
  end
  else
    Data := Nil;
end;

Procedure TBase.Store(Var S : TStream);
begin
  S.Write(size, 4);
  if Data <> Nil then
    S.Write(Data^, Size);
end;

Destructor TBase.Done;
begin
  if Data <> Nil then
    FreeMem(Data, size);
end;

Procedure RegisterTBase;
begin
  RegisterType(RBaseRec);
end;

end.



Program TestTBase3; {bare bones make/store/load/display a collection}
		    {collected Type defined locally to the Program}

Uses
  Objects, tbase3;

Procedure ShowStuff(P : PCollection);

  Procedure ShowIt(Pb : PBase); Far;
  begin
    if Pb^.Data <> Nil then
      Writeln(PString(Pb^.Data)^);
  end;

begin
  P^.ForEach(@ShowIt);
end;

Var
  A_Collection : PCollection;
  A_Stream     : TDosStream;
  S	       : String;
  m	       : LongInt;

begin
  m := memavail;
  RegisterTBase;
  New(A_Collection,init(5,2));
  Repeat
    Writeln;
    Write('enter some String : ');
    Readln(S);
    if S <> '' then
      A_Collection^.insert(New(PBase,init(S,Length(S)+1)));
  Until S = '';
  Writeln;
  Writeln('Storing the collection...');
  A_Stream.init('Test.TB3',stCreate);
  A_Collection^.Store(A_Stream);
  Writeln;
  Writeln('Storing Done. ');
  dispose(A_Collection,done);
  A_Stream.done;
  Writeln;
  Writeln('Disposing of Stream and Collection ...');
  if m = memavail then
    Writeln('memory fully released')
  else
    Writeln('memory not fully released');
  Write('Press [ENTER] to [continue] ...');
  readln;
  Writeln;
  Writeln('Constructing a new collection using the LOAD Constructor');
  A_Stream.init('Test.TB3',stOpenRead);
  New(A_Collection,Load(A_Stream));
  A_Stream.done;
  Writeln;
  ShowStuff(A_Collection);
  Writeln;
  Writeln('Disposing of Stream and Collection ...');
  dispose(A_Collection,done);
  if m = memavail then
    Writeln('memory fully released')
  else
    Writeln('memory not fully released');
  Write('Press [ENTER] to [EXIT] ...');
  readln;
end.

{
The above code has been tested and works just fine. By defining what I put into
the Object and Typecasting it when I take it out, I can collect and store and
load just about anything Without ever haveing to descend either the
TCollection, TBase or the TDosStream Objects. In the Case of the above Program,
I elected to collect simple Strings. It might just as well have been any other
Type of complex Record structure.

This Program was written solely For the purpose of discovering how the Objects
behave and possibly to even learn something. Any comments, discussions or
flames are always welcome.
}