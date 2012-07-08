{ This include file is a slightly modified version of XMSSTRM.PAS, by Stefan
  Boether, included here with his kind permission. -djm }

  (*****************************************************************************)
  (*                                                                           *)
  (*        Filename        : XMSSTRM.INC                                      *)
  (*        Autor           : Stefan Boether / Compuserve Id : 100023,275      *)
  (*        System          : TURBO 6.00 / MS-DOS 3.2 / Netzwerk               *)
  (*        Aenderung       :                                                  *)
  (*        wann     was                                                wer    *)
  (*---------------------------------------------------------------------------*)
  (*        22.03.92 Error fixed with NewBlock and UsedBlocks           Stefc  *)
  (*        28.04.92 Size field added, BlockSize made constant          DJM    *)
  (*        15.10.92 Off-by-one bug fixed in Seek method                DJM    *)
  (*****************************************************************************)
  (*        Beschreibung:  Object for an Stream in XMS-Memory                  *)
  (*****************************************************************************)
  {Header-End}

{!!!!!!!!!!!!!!!
 program Test;

 uses objects, XmsStrm;

 var T : TXmsStream;
     P : PString;

begin
   writeln( xms_MaxAvail, ' ', xms_MemAvail );
   T.Init(  20, 20 );
   T.WriteStr( NewStr( 'Hello' ));
   T.WriteStr( NewStr( 'World' ));
   T.Seek( 0 );
   P := T.ReadStr;
   writeln( P^ );
   P := T.ReadStr;
   writeln( P^ );
   T.Done;
end.

!!!!!!!!!!!!!!!!}

var xms_IOsts : Byte;
  xms_Addr : Pointer;

const
  xms_Initialized : Boolean = False;
  { This allows us to avoid a unit initialization section }

  xms_BlockSize = 1024;

  { - Some Xms - Procedures that I need ! -}

  (* /////////////////////////////////////////////////////////////////////// *)

  procedure MoveMem(ToAddress : Pointer; ToHandle : Word;
                    FromAddress : Pointer; FromHandle : Word;
                    Size : LongInt);
  begin
    asm
      mov     byte ptr xms_IOsts,0
      mov     ah,$0B
      lea     si,Size
      push    ds
      pop     es
      push    ss
      pop     ds
      call    es:[xms_Addr]
      push    es
      pop     ds
      or      ax,ax
      jnz     @@1
      mov     byte ptr xms_IOsts,bl
@@1:
    end;
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  function GetByte(Handle : Word; FromAddress : LongInt) : Byte;
  var TempBuf : array[0..1] of Byte;
  begin
    MoveMem(@TempBuf, 0, Pointer(FromAddress and $FFFFFFFE), Handle, 2);
    GetByte := TempBuf[FromAddress and $00000001];
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  procedure SetByte(Handle : Word; ToAddress : LongInt; Value : Byte);
  var TempBuf : array[0..1] of Byte;
  begin
    MoveMem(@TempBuf, 0, Pointer(ToAddress and $FFFFFFFE), Handle, 2);
    TempBuf[ToAddress and $00000001] := Value;
    MoveMem(Pointer(ToAddress and $FFFFFFFE), Handle, @TempBuf, 0, 2);
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  procedure xms_Init;
  begin
    if not xms_Initialized then
    begin
      xms_IOsts := 0;
      xms_Addr := nil;
      asm
        mov     ax,$4300
        int     $2F
        cmp     al,$80
        jne     @@1
        mov     ax,$4310
        int     $2F
        mov     word ptr xms_Addr,bx
        mov     word ptr xms_Addr+2,es
        jmp     @@2
@@1:
        mov     byte ptr xms_IOsts,$80
@@2:
      end;
      if xms_IOsts = 0 then
        xms_Initialized := True;
    end;
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  function xms_GetMem(KB : Word) : Word; Assembler;
  asm
    mov     xms_IOsts,0
    mov     ah,$09
    mov     dx,word ptr KB
    call    [xms_Addr]
    or      ax,ax
    jz      @@1
    mov     ax,dx
    jmp     @@2
@@1:
    mov     byte ptr xms_IOsts,bl
@@2:
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  procedure xms_FreeMem(Handle : Word);
  begin
    asm
      mov     xms_IOsts,0
      mov     ah,$0A
      mov     dx,word ptr Handle
      call    [xms_Addr]
      or      ax,ax
      jnz     @@1
      mov     byte ptr xms_IOsts,bl
@@1:
    end;
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  procedure xms_ResizeMem(Size, Handle : Word);
  begin
    asm
      mov     ah,$0F
      mov     bx,word ptr Size
      mov     dx,word ptr Handle
      call    [xms_Addr]
      or      ax,ax
      jnz     @@1
      mov     byte ptr xms_IOsts,bl
@@1:
    end;
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  procedure xms_MoveFrom(Size, Handle : Word; FromAddress : LongInt;
                         ToAddress : Pointer);
  type ByteArr = array[0..MaxInt] of Byte;
    BytePtr = ^ByteArr;
  begin
    if Size = 0 then Exit;
    if Odd(FromAddress) then begin
      BytePtr(ToAddress)^[0] := GetByte(Handle, FromAddress);
      if xms_IOsts <> 0 then Exit;
      Dec(Size);
      Inc(FromAddress);
      Inc(LongInt(ToAddress));
    end;
    MoveMem(ToAddress, 0, Pointer(FromAddress), Handle, Size and $FFFE);
    if xms_IOsts <> 0 then Exit;
    if Odd(Size)
    then BytePtr(ToAddress)^[Size-1] := GetByte(Handle, FromAddress+Size-1);
    if xms_IOsts <> 0 then Exit;
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  procedure xms_MoveTo(Size, Handle : Word; FromAddress : Pointer;
                       ToAddress : LongInt);
  type ByteArr = array[0..MaxInt] of Byte;
    BytePtr = ^ByteArr;
  begin
    if Size = 0 then Exit;
    if Odd(ToAddress) then begin
      SetByte(Handle, ToAddress, BytePtr(FromAddress)^[0]);
      if xms_IOsts <> 0 then Exit;
      Dec(Size);
      Inc(LongInt(FromAddress));
      Inc(ToAddress);
    end;
    MoveMem(Pointer(ToAddress), Handle, FromAddress, 0, Size and $FFFE);
    if xms_IOsts <> 0 then Exit;
    if Odd(Size)
    then SetByte(Handle, ToAddress+Size-1, BytePtr(FromAddress)^[Size-1]);
    if xms_IOsts <> 0 then Exit;
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  constructor TXMSStream.Init(MinSize, MaxSize : longint);
  var
    MinBlocks,MaxBlocks : word;
  begin
    TStream.Init;
    xms_Init;
    BlocksUsed := 0;
    Size := 0;
    Position := 0;
    Handle := 0;
    MaxSize := MinLong(MaxSize,xms_Maxavail);
    MaxBlocks := (MaxSize + xms_Blocksize -1) div xms_Blocksize;
    MinBlocks := (MinSize + xms_Blocksize -1) div xms_Blocksize;
    if MinBlocks < 1 then
      MinBlocks := 1;
    if MaxBlocks < MinBlocks then
      MaxBlocks := MinBlocks;
    if xms_IOsts <> $00 then
      Error(stInitError, xms_IOsts)
    else
    begin
      Handle := xms_GetMem(MaxBlocks);
      if xms_IOsts <> $00 then
        Error(stInitError, xms_IOsts)
      else
      begin
        xms_ResizeMem(MinBlocks,Handle);
        BlocksUsed := MinBlocks;
        if xms_IOsts <> $00 then
          Error(stInitError, xms_IOsts);
      end;
    end;
  end;

  function TXMSStream.GetPos : LongInt;
  begin
    GetPos := Position;
  end;

  function TXMSStream.GetSize : LongInt;
  begin
    GetSize := Size;
  end;

  procedure TXMSStream.Read(var Buf; Count : Word);
  begin
    if Status = stOK then
      if Position+Count > Size then
        Error(stReaderror, 0)
      else
      begin
        xms_MoveFrom(Count, Handle, Position, @Buf);
        if xms_IOsts <> 0 then
          Error(stReaderror, xms_IOsts)
        else
          Inc(Position, Count);
      end;
  end;

  procedure TXMSStream.Seek(Pos : LongInt);
  begin
    if Status = stOK then
      if Pos > Size then            { 1.4:  bug fix }
        Error(stReaderror, Pos)
      else
        Position := Pos;
  end;

  procedure TXMSStream.Truncate;
  begin
    if Status = stOK then
    begin
      Size := Position;
      while (BlocksUsed > (Size div xms_BlockSize+1)) do FreeBlock;
    end;
  end;

  procedure TXMSStream.Write(var Buf; Count : Word);
  begin
    while (Status = stOK)
    and (Position+Count > LongMul(xms_BlockSize, BlocksUsed)) do
      NewBlock;
    if Status = stOK then
    begin
      xms_MoveTo(Count, Handle, @Buf, Position);
      if xms_IOsts <> 0 then
        Error(stWriteError, xms_IOsts)
      else
        Inc(Position, Count);
      if Position > Size then
        Size := Position;
    end;
  end;

  procedure TXMSStream.NewBlock;
  begin
    xms_ResizeMem(Succ(BlocksUsed), Handle);
    if xms_IOsts <> 0 then
      Error(stWriteError, xms_IOsts)
    else
      Inc(BlocksUsed);
  end;

  procedure TXMSStream.FreeBlock;
  begin
    Dec(BlocksUsed);
    xms_ResizeMem(BlocksUsed, Handle);
  end;

  function xms_MaxAvail : Longint;
  begin
    xms_Init;
    if xms_IOsts = 0 then
    asm
      xor       bx, bx          { for better error checking, since qemm
6.0 leaves bl unchanged on success }
      mov     ah,$08
      call    [xms_Addr]
      or      bl, bl            { extended error checking by MM 22.02.93 }
      jz      @OK
      mov     byte ptr xms_IOsts,bl
      xor     ax,ax
@OK:
      mov     dx,xms_Blocksize
      mul     dx
      mov     word ptr @result,ax
      mov     word ptr @result[2],dx
    end
    else
      xms_MaxAvail := 0;
  end;

  (* /////////////////////////////////////////////////////////////////////// *)

  function xms_MemAvail : Longint;
  begin
    xms_Init;
    if xms_IOsts = 0 then
    asm
      xor       bx, bx          { for better error checking, since qemm
6.0 leaves bl unchanged on success }
      mov     ah,$08
      call    [xms_Addr]
      or      bl, bl            { extended error checking by MM 22.02.93 }
      jz      @OK
      mov     byte ptr xms_IOsts,bl
      xor     dx,dx
@OK:
      mov     ax,dx
      mov     dx,xms_blocksize
      mul     dx
      mov     word ptr @result,ax
      mov     word ptr @result[2],dx
    end
    else
      xms_MemAvail := 0;
  end;

  destructor TXMSStream.Done;
  begin
{    Seek(0);
    Truncate; }
    if xms_Initialized and (BlocksUsed > 0) then
      xms_FreeMem(Handle);
  end;

