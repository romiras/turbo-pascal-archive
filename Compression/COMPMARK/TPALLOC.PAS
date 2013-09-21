{$S-,R-,I-,V-,B-,D-}

{*********************************************************}
{*                    TPALLOC.PAS 1.0                    *}
{*                By TurboPower Software                 *}
{*********************************************************}

unit TpAlloc;
  {-Routines for allocating/deallocating blocks of memory larger than 64K}

interface

type
  SegOfs =                   {structure of a pointer}
    record
      Ofst, Segm : Word;
    end;

  {----- memory management routines -----}

procedure HugeGetMem(var Pt; Bytes : LongInt);
  {-Allocate a block of memory of size Bytes and store pointer to it in
    Pt. Pt is nil if Bytes > MaxAvail}

procedure HugeFreeMem(var Pt; Bytes : LongInt);
  {-Deallocate a block of memory of size Bytes pointed to by Pt, a pointer
    variable. Pt is set to nil on Exit. Does nothing if Pt is nil.}

  {----- pointer manipulation routines -----}

function Linear(P : Pointer) : LongInt;
  {-Converts a pointer to a linear address to allow differences in addresses
    to be calculated. The pointer must be in the range $0:$0 to $FFFF:$000F.}

function LinearToPointer(L : LongInt) : Pointer;
  {-Return linear address L as a normalized pointer}

function PtrDiff(P1, P2 : Pointer) : LongInt;
  {-Return the number of bytes between P1^ and P2^}

function Normalized(P : Pointer) : Pointer;
  {-Return P as a normalized pointer}
  inline(
    $58/                     {pop ax    ;pop offset into AX}
    $5A/                     {pop dx    ;pop segment into DX}
    $89/$C3/                 {mov bx,ax ;BX = Ofs(P^)}
    $B1/$04/                 {mov cl,4  ;CL = 4}
    $D3/$EB/                 {shr bx,cl ;BX = Ofs(P^) div 16}
    $01/$DA/                 {add dx,bx ;add BX to segment}
    $25/$0F/$00);            {and ax,$F ;mask out unwanted bits in offset}

  {=============================================================}

implementation

type
  FreeListRec =              {structure of a free list entry}
    record
      OrgPtr : Pointer;      {pointer to the start of the block}
      EndPtr : Pointer;      {pointer to the end of the block}
    end;
  FreeListRecPtr = ^FreeListRec;

  function Linear(P : Pointer) : LongInt;
    {-Converts a pointer to a linear address to allow differences in addresses
      to be calculated. The pointer must be in the range $0:$0 to $FFFF:$000F.}
  begin
    with SegOfs(P) do
      Linear := (LongInt(Segm) shl 4)+LongInt(Ofst);
  end;

  function LinearToPointer(L : LongInt) : Pointer;
    {-Return linear address L as a normalized pointer}
  begin
    LinearToPointer := Ptr(Word(L shr 4), Word(L and $0000000F));
  end;

  function PtrDiff(P1, P2 : Pointer) : LongInt;
    {-Return the number of bytes between P1^ and P2^}
  begin
    PtrDiff := Abs(Linear(P1)-Linear(P2));
  end;

  procedure HugeGetMem(var Pt; Bytes : LongInt);
    {-Allocate a block of memory of size Bytes and store pointer to it in
      Pt. Pt is nil if Bytes > MaxAvail}
  var
    ThisP : Pointer absolute Pt;
    P : FreeListRecPtr;
    Top : Pointer;
    ThisBlock : LongInt;
  begin
    ThisP := nil;

    {point to end of free list}
    P := FreePtr;
    if SegOfs(P).Ofst = 0 then
      Inc(SegOfs(P).Segm, $1000);

    {point to top of free memory}
    if FreeMin = 0 then
      Top := Ptr(SegOfs(FreePtr).Segm+$1000, 0)
    else
      Top := Ptr(SegOfs(FreePtr).Segm, -FreeMin);
    if Linear(P) < Linear(Top) then
      Top := P;

    {check block at HeapPtr^}
    if PtrDiff(Top, HeapPtr) >= Bytes then begin
      {use this block}
      ThisP := HeapPtr;

      {adjust HeapPtr}
      HeapPtr := LinearToPointer(Linear(HeapPtr)+Bytes);
    end
    else while SegOfs(P).Ofst <> 0 do begin
      {search the free list for a memory block that is big enough}
      with P^ do begin
        {calculate the size of the block}
        ThisBlock := PtrDiff(EndPtr, OrgPtr);

        if ThisBlock > Bytes then begin
          {bigger than we need--shrink the size of the block}
          ThisP := OrgPtr;
          OrgPtr := LinearToPointer(Linear(OrgPtr)+Bytes);
          Exit;
        end
        else if ThisBlock = Bytes then begin
          {exact size--remove the record from the free list}
          ThisP := OrgPtr;

          {move the entry at the bottom of the free list up}
          P^ := FreeListRecPtr(FreePtr)^;

          {adjust FreePtr}
          with SegOfs(FreePtr) do
            Inc(Ofst, SizeOf(FreeListRec));

          Exit;
        end;
      end;

      {point to next record on free list}
      Inc(SegOfs(P).Ofst, SizeOf(FreeListRec));
    end;
  end;

  procedure HugeFreeMem(var Pt; Bytes : LongInt);
    {-Deallocate a block of memory of size Bytes pointed to by Pt, a pointer
      variable. Pt is set to nil on Exit. Does nothing if Pt is nil.}
  var
    P : Pointer absolute Pt;
    EndP : Pointer;
    FP, SaveFP, NewFreePtr : FreeListRecPtr;
    I : Word;
    Found : Boolean;
  begin
    {exit if P is nil}
    if (P = nil) then
      Exit;

    {calculate pointer to end of block}
    EndP := LinearToPointer(Linear(P)+Bytes);

    {see if this is just below HeapPtr^}
    if EndP = HeapPtr then
      {just reset HeapPtr}
      HeapPtr := P
    else begin
      {search for a free list entry to combine this block with}
      Found := False;
      FP := FreePtr;
      while (SegOfs(FP).Ofst <> 0) and not Found do begin
        with FP^ do
          {does the end of our block match the start of this one?}
          if OrgPtr = EndP then begin
            OrgPtr := P;
            Found := True;
          end
          {does the start of our block match the end of this one?}
          else if EndPtr = P then begin
            EndPtr := EndP;
            Found := True;
          end;

        {point to next record on free list}
        if not Found then
          Inc(SegOfs(FP).Ofst, SizeOf(FreeListRec));
      end;

      if Found then begin
        {save pointer into free list and get pointers to search for}
        SaveFP := FP;
        with FP^ do begin
          P := OrgPtr;
          EndP := EndPtr;
        end;

        {see if we can combine this block with a second}
        Found := False;
        FP := FreePtr;
        while (SegOfs(FP).Ofst <> 0) and not Found do begin
          with FP^ do
            {does the end of our block match the start of this one?}
            if OrgPtr = EndP then begin
              OrgPtr := P;
              Found := True;
            end
            {does the start of our block match the end of this one?}
            else if EndPtr = P then begin
              EndPtr := EndP;
              Found := True;
            end;

          {point to next record on free list}
          if not Found then
            Inc(SegOfs(FP).Ofst, SizeOf(FreeListRec));
        end;

        if Found then begin
          {we combined two blocks--get rid of the 1st free list entry we found}

          {move the entry at the bottom of the free list up into its place}
          SaveFP^ := FreeListRecPtr(FreePtr)^;

          {adjust FreePtr}
          with SegOfs(FreePtr) do
            Inc(Ofst, SizeOf(FreeListRec));
        end;
      end
      else begin
        {can't combine with anything--add an entry to the free list}

        {calculate new FreePtr}
        with SegOfs(FreePtr) do
          NewFreePtr := Ptr(Segm, Ofst-SizeOf(FreeListRec));

        {make sure the free list isn't full}
        with SegOfs(NewFreePtr) do
          if (Linear(NewFreePtr) < Linear(HeapPtr)) or (Ofst = 0) then begin
            {it's full--let real FreeMem generate a runtime error}
            if Bytes > 65521 then
              I := 65521
            else
              I := Bytes;
            FreeMem(P, I);
            Exit;
          end;

        {fill in the new free list entry}
        with NewFreePtr^ do begin
          OrgPtr := P;
          EndPtr := EndP;
        end;

        {adjust FreePtr}
        FreePtr := NewFreePtr;
      end;

      {set P to nil}
      P := nil;
    end;
  end;

end.
