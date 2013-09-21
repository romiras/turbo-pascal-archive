Unit Map;

Interface

Uses Declare;

{
   NOTE:  for this implementation, internal and external pointer
   representations are identical.  Hence, all calls to INT and EXT
   could be removed from the code to reduce overhead.
}

FUNCTION int( extpointer: INTEGER): TypePointer;
FUNCTION ext( intpointer: TypePointer): INTEGER ;


Implementation

FUNCTION int( extpointer: INTEGER): TypePointer;
   BEGIN
      int := extpointer
   END ;

FUNCTION ext( intpointer: TypePointer): INTEGER ;
   BEGIN
      ext := intpointer
   END ;

end.