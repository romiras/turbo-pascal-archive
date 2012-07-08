      {SWAG=OOP.SWG,LARRY HADLEY,OOP-STRG.PAS,OOP,STRG,PAS}
      {
      LARRY HADLEY

      >Right now, I have an Array of Pointers that point to the beginning
      >of each page.  The entire File is loaded into memory using BlockRead.
      >To jump to a page, it checks the current page number, jumps to that
      >offset (as specified by the Page Array) and dumps the contents
      >to the screen Until it reaches the bottom.

       I think I see. You have a monolithic block of memory...problem!

      > There are a lot of ways to do it. One way would be to store the
      > File as Arrays of *Pointers* to Strings...this would allow 64k of
      > *sentences*, not just 64k of Text. It's a Variation on the old

	 Actually, this is wrong. Since TP use 4 Byte Pointers, you can
	 only  store 16k of sentences in a single Array, but even
	 though that should still be plenty, you can use linked lists to
	 overcome that limitation!

      >I have an Array of Pointers to the offset of each page.	Could you
      >provide a short code fragment?

	 Instead of treating the Pointers as offsets, you should be using
	 them as actual data collections.

      {
       *****************************************************************

       Strings Unit With StrArray Object. Manage linked lists of Strings
       transparently.

       By Larry Hadley - May be used freely, provided credit is given
       wherever this code is used.

       *****************************************************************
      }
      Unit StrArray;

      Interface

      Type
	PString = ^String;

	PStringList = ^StringList;
	StringList  = Record
	  P    : PString;
	  Next : PStringList;
	end;

	pStrArray = ^oStrArray;
	oStrArray = Object
	  Root	 : PStringList;
	  total  : Word;
	  eolist : Boolean; {end of list - only valid after calling At,
			     AtInsert, and AtDelete}
	  Constructor Init;
	  Destructor  Done;

	  Procedure Insert(s : String);
	  Procedure Delete;
	  Function  At(item : Word) : PString;
	  Procedure AtInsert(item : Word; s : String);
	  Procedure AtDelete(item : Word);
	  Function  First : PString;
	  Function  Last  : PString;

	Private
	  Procedure NewNode(N : PStringList);
	  Function  AllocateS(s : String) : PString;
	  Procedure DeallocateS(Var P : PString);
	end;

      Implementation

      Constructor oStrArray.Init;
      begin
	Root   := NIL;
	total  := 0;
	eolist := False;
      end;

      Destructor oStrArray.Done;
      Var
	T : PStringList;
      begin
	While Root <> NIL do
	begin
	  T := Root^.Next;
	  if Root^.P <> NIL then
	    DeallocateS(Root^.P);
	  Dispose(Root);
	  Root := T;
	end;
      end;

      Procedure oStrArray.Insert(s : String);
      Var
	T, T1 : PStringList;
      begin
	NewNode(T1);
	T1^.P := AllocateS(s);
	Inc(total);
	if Root <> NIL then
	begin
	  T := Root;
	  While T^.Next <> NIL do
	     T := T^.Next;
	  T^.Next := T1;
	end
	else
	  Root := T1;
      end;

      Procedure oStrArray.Delete;
      Var
	T, T1 : PStringList;
      begin
	T := Root;
	if T <> NIL then
	While T^.Next <> NIL do
	begin
	   T1 := T;
	   T  := T^.Next;
	end;
	T1^.Next := T^.Next;
	if T^.P <> NIL then
	  DeallocateS(T^.P);
	Dispose(T);
	Dec(total);
      end;

      Function oStrArray.At(item : Word) : PString;
      Var
	count : Word;
	T     : PStringList;
      begin
	if item>total then
	  eolist := True
	else
	  eolist := False;
	count := 1; {1 based offset}
	T := Root;
	While (count < item) and (T^.Next <> NIL) do
	begin
	  T := T^.Next;
	  Inc(count);
	end;
	At := T^.P;
      end;

      Procedure oStrArray.AtInsert(item : Word; s : String);
      Var
	count : Word;
	T, T1 : PStringList;
      begin
	if item > total then
	  eolist := True
	else
	  eolist := False;
	NewNode(T1);
	T1^.P := AllocateS(s);
	Inc(total);
	count := 1;
	if Root <> NIL then
	begin
	  T := Root;
	  While (count < Item) and (T^.Next <> NIL) do
	  begin
	    T := T^.Next;
	    Inc(count);
	  end;
	  T1^.Next := T^.Next;
	  T^.Next  := T1;
	end
	else
	  Root := T1;
      end;

      Procedure oStrArray.AtDelete(item : Word);
      Var
	count : Word;
	T, T1 : PStringList;
      begin
	if item > total then { don't delete if item bigger than list total -
			     explicit only! }
	begin
	  eolist := True;
	  Exit;
	end
	else
	  eolist := False;

	count := 1;
	T     := Root;
	T1    := NIL;

	While (count < item) and (T^.Next <> NIL) do
	begin
	  T1 := T;
	  T  := T^.Next;
	  Inc(count);
	end;
	if T1 = NIL then
	  Root := Root^.Next
	else
	  T1^.Next := T^.Next;
	DeallocateS(T^.P);
	Dispose(T);
	Dec(total);
      end;

      Function oStrArray.First : PString;
      begin
	First := Root^.P;
      end;

      Function oStrArray.Last : PString;
      Var
	T : PStringList;
      begin
	T := Root;
	if T <> NIL then
	While T^.Next <> NIL do
	  T := T^.Next;
	Last := T^.P;
      end;

      Procedure oStrArray.NewNode(N : PStringList);
      Var
	T : PStringList;
      begin
	New(T);
	T^.Next := NIL;
	T^.P := NIL;
	if N = NIL then
	  N := T
	else
	begin
	  T^.Next := N^.Next;
	  N^.Next := T;
	end;
      end;

      Function oStrArray.AllocateS(s : String) : PString;
      Var
	P : PString;
      begin
	GetMem(P, Ord(s[0]) + 1);
	P^ := s;
	AllocateS := P;
      end;

      Procedure oStrArray.DeallocateS(Var P : PString);
      begin
	FreeMem(P, Ord(P^[0]) + 1);
	P := NIL;  {for error checking}
      end;

      end. {Unit StringS}


      {
      Code fragment :

      Var
	TextList : pStrArray;

      ...

	New(TextList, Init);

      ...

	Repeat
	  ReadLn(TextFile, s);
	  TextList^.Insert(s);
	Until Eof(TextFile) or LowMemory;

      ...

	For Loop := 1 to PageLen do
	if Not(TextList^.eolist) then
	  Writeln(TextList^At(PageTop + Loop)^);
      ...

      etc.
      }