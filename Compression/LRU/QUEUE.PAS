Unit Queue;

Interface

Uses Declare;

type
  FieldIndex=StaticSize..MaxDict;

var
  qin:  FieldIndex ;  { right end of LRU queue, where things enter }
  qout: FieldIndex ;  { left  end of LRU queue, where things leave }
  place:FieldIndex ;  { used to point into LRU queue }

FUNCTION Older( place: FieldIndex): FieldIndex;
PROCEDURE Dequeue( trieptr: FieldIndex) ;
PROCEDURE Enqueue( trieptr, place:  FieldIndex) ;



Implementation

var
   { LRU queue data structure }
  olderfield: ARRAY [FieldIndex] OF FieldIndex ;  { left  pointer }
  newerfield: ARRAY [FieldIndex] OF FieldIndex ;  { right pointer }


FUNCTION Older( place: FieldIndex): FieldIndex;
BEGIN
  Older := olderfield[ place]
END ;



{
   Remove arg1 from LRU queue;
   assumes queue size > 1 and place not right end
}
PROCEDURE Dequeue( trieptr: FieldIndex) ;
BEGIN
  IF ( trieptr = qout) THEN            { delete from left }
    BEGIN
      qout              := newerfield[ trieptr] ;
      olderfield[ qout] := nilptr
    END
  ELSE                                 { delete from middle }
    BEGIN
      newerfield[ olderfield[ trieptr]] := newerfield[ trieptr] ;
      olderfield[ newerfield[ trieptr]] := olderfield[ trieptr]
    END
END { Dequeue };



{
   Put arg1 after arg2 in LRU queue;
   if arg2 = nilptr, insert at left end
}

PROCEDURE Enqueue( trieptr, place:  FieldIndex) ;
BEGIN
  IF ( qin = nilptr) THEN              { empty queue}
    BEGIN
      olderfield[trieptr]:=nilptr;
      newerfield[trieptr]:=nilptr;
      qin:= trieptr ;
      qout:= trieptr ;
    END
  ELSE IF ( place = nilptr) THEN       { insert at left}
    BEGIN
	    olderfield[ trieptr]   := nilptr  ;
	    newerfield[ trieptr]   := qout    ;
	    olderfield[ qout]      := trieptr ;
	    qout                   := trieptr
    END
  ELSE IF ( place = qin) THEN          { append to right}
    BEGIN
	    olderfield[ trieptr]   := qin     ;
	    newerfield[ trieptr]   := nilptr  ;
	    newerfield[ qin]       := trieptr ;
	    qin                    := trieptr ;
    END
  ELSE                                 { append within the middle}
    BEGIN
	    olderfield[ trieptr]   := place   ;
		newerfield[ trieptr]   := newerfield[ place] ;
	    olderfield[ newerfield[ place]] := trieptr ;
	    newerfield[ place]     := trieptr ;
    END
END { Enqueue } ;

end.