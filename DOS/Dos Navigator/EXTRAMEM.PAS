{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on Dos Navigator by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}

UNIT
  ExtraMemory;

INTERFACE uses Objects;

VAR
  EMSFound, XMSFound : Boolean;

CONST
  XMSControl:    Pointer = nil;
  EMSSize:       Word = 0;
  EMSBlockSize:  Word = $C000;

Function EMSPresent: Boolean;
function XMSFree: Word;
Function EMSFreePages: Word;
FUNCTION ExistUMBmem: Boolean;
procedure InitExtraMem;

type

  PXMSStream = ^TXMSStream;
  TXMSStream =
    object(TStream)
      Handle : Word;              { XMS handle }
      BlocksUsed : Word;          { Number of 1K blocks used. Always allocates
                                    at least one byte more than Size. }
      Size : LongInt;             { The current size of the stream }
      Position : LongInt;         { Current position }

      constructor Init(MinSize,MaxSize:longint);
      destructor Done; virtual;

      function GetPos : LongInt; virtual;
      function GetSize : LongInt; virtual;
      procedure Read(var Buf; Count : Word); virtual;
      procedure Seek(Pos : LongInt); virtual;
      procedure Truncate; virtual;
      procedure Write(var Buf; Count : Word); virtual;

      procedure NewBlock;         { Internal method to allocate a block }
      procedure FreeBlock;        { Internal method to free one block }
    end;

function xms_MemAvail : Longint;
  { Returns total of available XMS bytes. }
function xms_MaxAvail : Longint;
  { Returns size of largest available XMS block in bytes. }


IMPLEMENTATION uses Commands, Startup;


function EMSPresent: Boolean; assembler;
asm
 xor ax, ax
 mov byte ptr @Res, al
 jmp @@1
@EMSName:
 db  'EMMXXXX0',0
@Res: db 0
@@1:
 push ds
 push cs
 pop  ds
 lea  dx, @EMSName
 xor  al, al
 mov  ah, 3dH
 int  21H
 pop  ds
 jc   @Exit
 mov  bx, ax
 push bx
 mov  ax, 4407H
 int  21H
 pop  bx
 push ax
 mov  ah, 3eh
 int  21h
 pop  ax
 or   al, al
 jz   @Exit
 mov  ax, 3567h
 int  21h
 mov  ax, es
 or   ax, bx
 jz   @Exit
 mov  ax, 4000h
 int  67h
 or   ah, ah
 jnz  @Exit
 mov  al, 1
 mov  byte ptr @Res, al
@Exit:
 xor ah, ah
 mov al, byte ptr @Res
end;

function EMSFreePages: Word; assembler;
asm
 mov ax, 4200h
 int 67h
 mov ax, bx
end;


procedure DetectXMS; assembler;
asm
     mov     ax,4300h
     int     2Fh
     cmp     al,80h
     jne     @@1
     mov     ax,4310h
     int     2Fh

     mov     word ptr [XMSControl],bx
     mov     word ptr [XMSControl+2],es

     mov     ah,00h
     call    [XMSControl]
     or      ax, ax
     jz      @@1
     cmp     ax, 1
     jz      @@1
     mov     al, 1
     mov     XMSFound, al
@@1:
end;

function XMSFree: Word; assembler;
asm
 mov ah, 08h
 call [XMSControl]
 mov ax, dx
end;


var xms_IOsts : Byte;
    xms_Addr : Pointer;

  function MinLong(x,y:longint):longint;
  begin
    if x<y then
      MinLong := x
    else
      MinLong := y;
  end;

  function MaxLong(x,y:longint):longint;
  begin
    MaxLong := -MinLong(-x,-y);
  end;

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
    xms_IOsts := 0;
    TStream.Init;
    xms_Init;
    BlocksUsed := 0;
    Size := MaxSize;
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

FUNCTION ExistUMBmem : Boolean; assembler;
{ Attempts to allocate an impossibly large UMB.  On failure ax     }
{ contains 0, bl indicates UMB's unimplemented if $80, or $bx      }
{ on other error.  No provision made for success here. Impossible  }
{ to succeed.  Note that the UMB manager doesn't necessarily depend}
{ on existence of XMS manager, but if there is no control call     }
{ vector there is no way to call this UMB function.                }
asm
  xor  dx,dx              { Default to False }
  xor  al,al              { Return FALSE by default }
  cmp  XMSFound,dl        { If NO XMS driver }
  jz   @exit              { then exit }
  dec  dx                 { attempt alloc 0FFFFh }
  mov  ax,1000h           { impossible large block of UMB's }
  Call [XMSControl]       { through driver }
  cmp  bl,0AEh            { BUT all UMB's used up }
  xor  al,al              { Return FALSE by default }
  jb   @exit              { then exit, else }
  mov  al,1               { return True }
@exit:
end;

procedure InitExtraMem;
BEGIN
 if SystemData.Options and ossDisableXMS <> 0 then
 begin
   EMSFound := False; XMSFound := False
 end else
 begin
   EMSFound := EMSPresent;
   if EMSFound then
    asm
     mov ah, 42h
     int 67h
     mov cl, 4
     shl dx, cl
     mov EMSSize, dx
    end;
   DetectXMS;
 end;
end;
 {
 if XMSFound then
  asm
   mov ah, 88h
   int 15h
   mov XMSSize, ax
  end;
 }
END.