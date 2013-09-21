Unit Dictnary;
Interface

Uses Declare;

FUNCTION ctr( pntr: TypePointer): CharType;
FUNCTION parent( pntr: TypePointer): TypePointer;
FUNCTION count( pntr: TypePointer): ChildrenRange;
FUNCTION child( pntr: TypePointer;  c  : CharType): TypePointer;
PROCEDURE addleaf( parpntr,pntr : TypePointer;  c : CharType) ;
PROCEDURE deleteleaf( pntr: TypePointer) ;


Implementation
type
   ctrfieldType=ARRAY [TypePointer] OF CharType;       { character }
   parfieldType=ARRAY [TypePointer] OF TypePointer ;  { parent }
   lcfieldType=ARRAY [TypePointer] OF TypePointer ;  { left child }
   countfieldType=ARRAY [TypePointer] OF ChildrenRange;      { number of children }
   rsibfieldType=ARRAY [TypePointer] OF TypePointer ;  { right sibling }
   lsibfieldType=ARRAY [TypePointer] OF TypePointer ;  { left  sibling }

var
  { trie data structure for the dictionary }
  ctrfield: ^ctrFieldType;
  parfield: ^parFieldType;
  lcfield : ^lcfieldType;
  countfield: ^countfieldType;
  rsibfield: ^rsibfieldType;
  lsibfield: ^lsibfieldType;




FUNCTION ctr( pntr: TypePointer):CharType;
BEGIN
  ctr := ctrfield^[pntr]
END;


FUNCTION parent( pntr: TypePointer): TypePointer;
BEGIN
  parent := parfield^[pntr]
END ;


FUNCTION count( pntr: TypePointer):ChildrenRange;
BEGIN
  count := countfield^[pntr]
END ;


FUNCTION child( pntr: TypePointer;  c  : CharType): TypePointer;
BEGIN
  IF ( pntr = nilptr) THEN
    child := c
  ELSE BEGIN
    pntr := lcfield^[pntr] ;
    WHILE ( pntr <> nilptr) AND ( c<> ctrfield^[pntr]) DO
      pntr := rsibfield^[pntr];
    child := pntr ;
  END ;
END { child} ;



PROCEDURE addleaf( parpntr,pntr : TypePointer;  c : CharType) ;
BEGIN
  ctrfield^[pntr] := c ;
  countfield^[pntr] := 0 ;
  parfield^[pntr] := parpntr ;
  lcfield^[pntr] := nilptr ;
  lsibfield^[pntr] := nilptr ;
  IF ( parpntr = nilptr) THEN
    rsibfield^[pntr] := nilptr
  ELSE BEGIN
    rsibfield^[pntr] := lcfield^[parpntr] ;
    IF ( lcfield^[parpntr] <> nilptr) THEN
      lsibfield^[lcfield^[parpntr]] := pntr ;
    lcfield^[parpntr] := pntr ;
    inc(countfield^[ parpntr])
  END ;
END { addleaf} ;



PROCEDURE deleteleaf( pntr: TypePointer) ;
BEGIN
  dec(countfield^[parfield^[pntr]]);
  IF ( lsibfield^[pntr] <> nilptr) THEN
    rsibfield^[lsibfield^[pntr]] := rsibfield^[pntr]
  ELSE
    lcfield^[parfield^[pntr]] := rsibfield^[pntr] ;
  IF ( rsibfield^[pntr] <> nilptr) THEN
    lsibfield^[rsibfield^[pntr]] := lsibfield^[pntr]
END { deleteleaf } ;


begin
  new(ctrfield);
  new(parfield);
  new(lcfield);
  new(countfield);
  new(rsibfield);
  new(lsibfield);
End.