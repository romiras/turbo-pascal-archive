{SWAG=OOP.SWG,Simple Collection Demo;<www.prog.cz/swag/swag>}
Program CollectingStuff;
Uses Objects;
Type
	Stuff	 = byte;
	StuffPtr = ^Stuff;
	StuffCollection = Object(TCollection)
		procedure FreeItem(Item:Pointer); virtual;
		procedure PutItem(var S:TStream;Item:Pointer); virtual;
		Function GetItem(var S:TStream):Pointer; virtual;
	end;
  StuffCollectionPtr = ^StuffCollection;
Const
	RStuffCollection : TStreamRec =
	(ObjType : $424B;
	 VMTLink : Ofs(TypeOf(StuffCollection)^);
	 Load	 : @StuffCollection.Load;
	 Store	 : @StuffCollection.Store);

Var
  StuffArray : StuffCollectionPtr;

procedure StuffCollection.FreeItem(Item:Pointer);
begin
     dispose(StuffPtr(Item));
end;
procedure StuffCollection.PutItem(var S:TStream;Item:Pointer);
begin
     S.Write(StuffPtr(Item)^,SizeOf(Stuff));
end;
Function StuffCollection.GetItem(var S:TStream):Pointer;
var p:StuffPtr;
Begin
     new(p);
     S.Read(p^,SizeOf(Stuff));
     GetItem := p;
End;

Function SayWhat:Char;
var s:String;
Begin
     Writeln;
     if   StuffArray <> Nil
     then Writeln('Current Array has ',StuffArray^.Count,' elements');
     Writeln('[1] add stuff    [2] remove stuff   ',
	     '[3] load stuff   [4] store stuff ');
     Writeln('[5] view stuff   [6] view all stuff ',
	     '[7] match stuff  (anything else exits))');
     Readln(s);
     if s <> '' then SayWhat := s[1] else SayWhat := #0;
End;

Procedure AddToStuff;
var sp:StuffPtr;
	b:byte;
Begin
     if   StuffArray = Nil
     then New(StuffArray,init(1,1));
     repeat
       write('enter a byte : ');
       Readln(b);
     until ioresult = 0;
     new(sp); sp^ := b;
     StuffArray^.insert(sp);
End;

Procedure DelFromStuff;
var w:word;
Begin
     if (StuffArray = nil) or (StuffArray^.count = 0) then exit;
     repeat
       write('enter element number to delete : ');
       readln(w);
    until (ioresult = 0) and (w < StuffArray^.count);
    StuffArray^.AtFree(w);
End;

Procedure NewStuff;
var s:string;
    f:PDosStream;
Begin
     write('Enter the stuff''s file name : ');
     readln(s);
     new(f,init(s,StOpenRead));
     if   f^.status = StOk
     then begin
	    if StuffArray <> nil then dispose(StuffArray,done);
	    new(StuffArray,load(f^));
	  end;
     dispose(f,done);
End;

Procedure SaveStuff;
var s:string;
       f:PDosStream;
Begin
     write('Enter the stuff''s file name : ');
     readln(s);
     new(f,init(s,StCreate));
     if   f^.status = StOk
     then begin
	    if	 StuffArray <> nil
	    then StuffArray^.store(f^);
	  end;
     dispose(f,done);
End;

Procedure ShowStuff;
var w:word;
Begin
     if (StuffArray = nil) or (StuffArray^.count = 0) then exit;
     repeat
       write('enter element number to view : ');
       readln(w);
    until (ioresult = 0) and (w < StuffArray^.count);
    writeln('Element # ',w,' = ',byte(StuffArray^.at(w)^));
End;

Procedure AllStuff;
   Procedure ShowEm(p:StuffPtr); far;
      begin
	writeln('Stuff Element = [',byte(p^),']');
      end;
Begin
     if   (StuffArray <> Nil) and (StuffArray^.count > 0)
     then StuffArray^.ForEach(@ShowEm);
End;

Procedure MatchStuff;
var b:byte;
       p:StuffPtr;
 Function Matches(pb:StuffPtr):boolean; far;
 Begin
      Matches := pb^ = b;
 End;
Begin
     if (StuffArray = Nil) or (StuffArray^.count = 0) then exit;
     repeat
       write('enter a byte to match : ');
       readln(b);
     until ioresult = 0;
     p := StuffArray^.FirstThat(@Matches);
     if   p <> nil
     then writeln('Element ',StuffArray^.indexof(p),
		  ' matches [',byte(p^),']')
     else writeln('no matches');
End;

Procedure DoStuff;
var stop:boolean;
Begin
     stop := false;
     While not stop do
     Case SayWhat of
	'1' : AddToStuff;
	'2' : DelFromStuff;
	'3' : NewStuff;
	'4' : SaveStuff;
	'5' : ShowStuff;
	'6' : AllStuff;
	'7' : MatchStuff;
	else stop := true;
      end;
End;

var m:longint;
begin
  m := memavail;
  registerType(RStuffCollection);
  StuffArray := Nil;
  DoStuff;
  if StuffArray <> Nil then Dispose(StuffArray,Done);
  if m <> memavail then writeln('heap ''a trouble');
end.