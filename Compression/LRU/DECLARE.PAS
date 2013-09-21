Unit Declare;

Interface

CONST

  { program parameters }
  { flags }
  FreezeFlag: boolean = false;  { false for LRU queue, true to FREEZE dictionary when full }
  PtrType: boolean=TRUE;  { false for fixed    length pointers,}
			  { true for variable length pointers}

  MaxChildren  =  256 ;  { max number of children allowed per non-root node  }
  MaxDict      = 8192 ;  { max dict size; eg 4096, 8192, 16384, 32768, 65536 }
  MaxIncrement =  256 ;  { maximum increase in length to make a new entry    }
  MaxMatch     =  1024;  { maximum allowable length for a trie string        }
  StaticSize   =  256 ;  { input alphabet is 0 ... ( StaticSize - 1);        }
                         { StaticSize <= 256                                 }


TYPE
  TypePointer  = 0..MaxDict ;  { arrays will be used to store linked structures }
  CharType=0..StaticSize-1;      { character type (input alphabet }
  ChildrenRange=0..MaxChildren;

const
  MaxPtr: TypePointer=MaxDict-2;
  NilPtr: TypePointer=MaxDict-1;

VAR



   dictsize:   TypePointer;  { current size of dictionary }
   trieptr:    TypePointer;  { used to walk up and down trie }


   { previous match data structure }

   prevptr:    TypePointer ;  { used to hold pointer to previous match }
   prevlen:    TypePointer ;  { length of previous match }


   { current match data structure }

   curptr:     TypePointer ;  { used to hold pointer to current match }
   curlen:     0..MaxMatch ;      { length of current match }
   match:      ARRAY [ 1 .. MaxMatch] OF CharType;  { holds current match }
   mstart:     1..MaxMatch; { positions mstart thru mstart+curlength-1 hold match}
   mindex:     0..MaxMatch ;  { used to walk thru match array }
   mval:       CharType; {used by update code to hold current element of match}


   { variables used for input and output }
   inputbyte:  CharType;  { holds current input byte }

Implementation

end.
