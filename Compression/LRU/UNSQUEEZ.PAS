{ unsqueeze.p }
PROGRAM main;

Uses Declare,Map,DictNary,Queue,
	 IO_Byte,IO_Ptr,DumpDic,Crt;

Var
	Test1,Test2 : string;

BEGIN

   ClrScr;
   If (ParamCount < 2) then
	   begin
			Write('Input File Name  : ');
			ReadLn(Test1);
			Write('Output File Name : ');
			ReadLn(Test2);
	   end
   Else
	   begin
			Test1 := ParamStr(1);
			Test2 := ParamStr(2);
	   end;

   OpenFiles(Test1,Test2);

   { initialize maxptr and nilptr }

   nilptr := MaxDict - 1;
   maxptr := MaxDict - 2;


   { initialize static portion of the dictionary trie }

   dictsize := 0 ;
   WHILE ( dictsize < StaticSize) DO
	  BEGIN
		 Addleaf( nilptr, Int( dictsize), dictsize) ;
		 dictsize := dictsize + 1 ;
	  END ;

   { initialize LRU queue }

   qin  := Int( nilptr) ;
   qout := Int( nilptr) ;

   { initialize parameters for current match }

   curptr := Int( nilptr) ;
   curlen := 0 ;

   WHILE ( NOT endinput) DO BEGIN


      { set trieptr to next pointer and initialize parameters }

      trieptr := readptr ;

      prevptr := curptr ;
      prevlen := curlen ;
      curptr  := trieptr ;
      curlen  := 0 ;


      { calculate current match by moving up trie as far as possible }

      WHILE ( ext( trieptr) <> nilptr) DO BEGIN
         IF ( ext( trieptr) >= StaticSize) AND ( trieptr <> qin) THEN
            BEGIN
	       dequeue( trieptr) ;
               enqueue( trieptr, qin)
            END ;
		 match[ MaxMatch - curlen] := ctr( trieptr) ;
         curlen := curlen + 1 ;
         trieptr := parent( trieptr) ;
      END ;


      { calculate match start and output the current match }

      mstart := MaxMatch - curlen + 1 ;
      FOR mindex := mstart TO MaxMatch DO
         writebyte( match[ mindex]) ;

	  IF( Ext( prevptr) <> nilptr) THEN
		 BEGIN
			mindex := 0 ;
			WHILE ( mindex < curlen)
			AND   ( mindex < MaxIncrement)
			AND   ( ( prevlen + mindex) < MaxMatch)
			AND   ( Count( prevptr) < MaxChildren)
			AND   ( ( not FreezeFlag )  OR ( dictsize <= maxptr))
			AND   ( ( prevptr <> qout) OR ( dictsize <= maxptr)) DO
		   BEGIN

				  { if can't match, add a new node to the tie [sic] }
			  mval    := match[ mstart + mindex] ;
			  trieptr := Child( prevptr, mval) ;
			  IF ( Ext( trieptr) = nilptr) THEN
				 BEGIN

						{ get a free pointer }
				IF ( dictsize <= maxptr) THEN
				   BEGIN
				  trieptr  := Int( dictsize) ;
				  dictsize := dictsize + 1 ;
				   END
				ELSE
				   BEGIN
				  trieptr  := qout ;
				  Dequeue( trieptr) ;
				  Deleteleaf( trieptr) ;
				   END ;

				{ add new pointer to trie }
				Addleaf( prevptr, trieptr, mval) ;

				{ add new pointer to left of current in LRU queue }
				IF ( Ext( prevptr) < StaticSize) THEN
				   place := qin
				ELSE
				   place := Older( prevptr) ;

				Enqueue( trieptr, place)
				 END ;

			  { move down one level in trie }
			  prevptr := trieptr ;
			  mindex  := mindex + 1 ;
		   END
		 END ;
	  END ;


END.

