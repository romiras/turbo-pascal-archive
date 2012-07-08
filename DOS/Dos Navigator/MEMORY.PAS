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

unit Memory;

{-----------------------------------------------------}
{ This module is based on Turbo Vision Memry Unit     }
{ Copyright (c) 1990 by Borland International         }
{-----------------------------------------------------}


interface

const
  MaxHeapSize: Word = 655360 div 16;    { 640K }
  LowMemSize: Word = 4096;              {   4K }
  MaxBufMem: Word = 65536 div 16;       {  64K }

procedure InitMemory;
procedure DoneMemory;
procedure InitDosMem;
procedure DoneDosMem;
function LowMemory: Boolean;
function MemAlloc(Size: Word): Pointer;
function MemAllocSeg(Size: Word): Pointer;
procedure NewCache(var P: Pointer; Size: Word);
procedure DisposeCache(P: Pointer);
procedure NewBuffer(var P: Pointer; Size: Word);
procedure DisposeBuffer(P: Pointer);
function GetBufferSize(P: Pointer): Word;
function SetBufferSize(P: Pointer; Size: Word): Boolean;

{$IFNDEF DPMI}

procedure GetBufMem(var P: Pointer; Size: Word);
procedure FreeBufMem(P: Pointer);
procedure SetMemTop(MemTop: Pointer);

{$ENDIF}

implementation

type
  PtrRec = record
    Ofs, Seg: Word;
  end;

{$IFDEF DPMI}

type
  PCache = ^TCache;
  TCache = record
    Next: PCache;
    Master: ^Pointer;
    Data: record end;
  end;

const
  CacheList: PCache = nil;
  SafetyPool: Pointer = nil;
  SafetyPoolSize: Word = 8192;
  DisablePool: Boolean = False;

function MemAllocateBlock(HeapHandle, Size, Attributes: Word;
  EventProc: Pointer; var Selector: Word): Integer; far;
external 'RTM' index $0005;

function MemFreeBlock(Selector: Word): Integer; far;
external 'RTM' index $0006;

function MemResizeBlock(Selector: Word; Size: Word): Integer; far;
external 'RTM' index $0007;

function MemGetBlockSize(Selector: Word; var Size: Longint): Integer; far;
external 'RTM' index $0014;

function FreeCache: Boolean;
begin
  FreeCache := False;
  if CacheList <> nil then
  begin
    DisposeCache(CacheList^.Next^.Master^);
    FreeCache := True;
  end;
end;

function FreeSafetyPool: Boolean;
begin
  FreeSafetyPool := False;
  if SafetyPool <> nil then
  begin
    FreeMem(SafetyPool, SafetyPoolSize);
    SafetyPool := nil;
    FreeSafetyPool := True;
  end;
end;

function HeapNotify(Size: Word): Integer; far;
begin
  if FreeCache then HeapNotify := 2 else
    if DisablePool then HeapNotify := 1 else
      if FreeSafetyPool then HeapNotify := 2 else HeapNotify := 0;
end;

procedure InitMemory;
begin
  HeapError := @HeapNotify;
  SafetyPoolSize := LowMemSize * 16;
  LowMemory;
end;

procedure DoneMemory;
begin
  while FreeCache do;
  FreeSafetyPool;
end;

procedure InitDosMem;
begin
end;

procedure DoneDosMem;
begin
end;

function LowMemory: Boolean;
begin
  LowMemory := False;
  if SafetyPool = nil then
  begin
    SafetyPool := MemAlloc(SafetyPoolSize);
    if SafetyPool = nil then LowMemory := True;
  end;
end;

function MemAlloc(Size: Word): Pointer;
var
  P: Pointer;
begin
  DisablePool := True;
  GetMem(P, Size);
  DisablePool := False;
  MemAlloc := P;
end;

function MemAllocSeg(Size: Word): Pointer;
var
  Selector: Word;
begin
  Selector := 0;
  if Size <> 0 then
    repeat
      if MemAllocateBlock(0, Size, 2, nil, Selector) <> 0 then
        Selector := 0;
    until (Selector <> 0) or not FreeCache;
  MemAllocSeg := Ptr(Selector, 0);
end;

procedure NewCache(var P: Pointer; Size: Word);
var
  Cache: PCache;
begin
  Inc(Size, SizeOf(TCache));
  PtrRec(Cache).Ofs := 0;
  if MemAllocateBlock(0, Size, 4, nil, PtrRec(Cache).Seg) <> 0 then
    PtrRec(Cache).Seg := 0;
  if Cache <> nil then
  begin
    if CacheList = nil then Cache^.Next := Cache else
    begin
      Cache^.Next := CacheList^.Next;
      CacheList^.Next := Cache;
    end;
    CacheList := Cache;
    Cache^.Master := @P;
    Inc(PtrRec(Cache).Ofs, SizeOf(TCache));
  end;
  P := Cache;
end;

procedure DisposeCache(P: Pointer);
var
  Cache, C: PCache;
begin
  PtrRec(Cache).Ofs := PtrRec(P).Ofs - SizeOf(TCache);
  PtrRec(Cache).Seg := PtrRec(P).Seg;
  C := CacheList;
  while (C^.Next <> Cache) and (C^.Next <> CacheList) do C := C^.Next;
  if C^.Next = Cache then
  begin
    if C = Cache then CacheList := nil else
    begin
      if CacheList = Cache then CacheList := C;
      C^.Next := Cache^.Next;
    end;
    Cache^.Master^ := nil;
    MemFreeBlock(PtrRec(Cache).Seg);
  end;
end;

procedure NewBuffer(var P: Pointer; Size: Word);
begin
  P := MemAllocSeg(Size);
end;

procedure DisposeBuffer(P: Pointer);
begin
  MemFreeBlock(PtrRec(P).Seg);
end;

function GetBufferSize(P: Pointer): Word;
var
  Size: Longint;
begin
  if MemGetBlockSize(PtrRec(P).Seg, Size) <> 0 then Size := 0;
  GetBufferSize := Size;
end;

function SetBufferSize(P: Pointer; Size: Word): Boolean;
begin
  SetBufferSize := MemResizeBlock(PtrRec(P).Seg, Size) = 0;
end;

{$ELSE}

type
  PCache = ^TCache;
  TCache = record
    Size: Word;
    Master: ^Pointer;
    Data: record end;
  end;

type
  PBuffer = ^TBuffer;
  TBuffer = record
    Size: Word;
    Master: ^Word;
  end;

const
  CachePtr: Pointer = nil;
  HeapResult: Integer = 0;
  BufHeapPtr: Word = 0;
  BufHeapEnd: Word = 0;
  SafetyPoolSize = 5120;

function HeapNotify(Size: Word): Integer; far; assembler;
asm
        CMP     Size,0
        JNE     @@3
@@1:    MOV     AX,CachePtr.Word[2]
        CMP     AX,HeapPtr.Word[2]
        JA      @@3
        JB      @@2
        MOV     AX,CachePtr.Word[0]
        CMP     AX,HeapPtr.Word[0]
        JAE     @@3
@@2:    XOR     AX,AX
        PUSH    AX
        PUSH    AX
        CALL    DisposeCache
        JMP     @@1
@@3:    MOV     AX,HeapResult
end;

procedure FreeCacheMem;
begin
  while CachePtr <> HeapEnd do DisposeCache(CachePtr);
end;

procedure InitMemory;
var
  HeapSize: Word;
begin
  HeapError := @HeapNotify;
  if BufHeapPtr = 0 then
  begin
    HeapSize := PtrRec(HeapEnd).Seg - PtrRec(HeapOrg).Seg;
    if HeapSize > MaxHeapSize then HeapSize := MaxHeapSize;
    BufHeapEnd := PtrRec(HeapEnd).Seg;
    PtrRec(HeapEnd).Seg := PtrRec(HeapOrg).Seg + HeapSize;
    BufHeapPtr := PtrRec(HeapEnd).Seg;
  end;
  CachePtr := HeapEnd;
end;

procedure DoneMemory;
begin
  FreeCacheMem;
end;

procedure InitDosMem;
begin
  SetMemTop(Ptr(BufHeapEnd, 0));
end;

procedure DoneDosMem;
var
  MemTop: Pointer;
begin
  MemTop := Ptr(BufHeapPtr, 0);
  if BufHeapPtr = PtrRec(HeapEnd).Seg then
  begin
    FreeCacheMem;
    MemTop := HeapPtr;
  end;
  SetMemTop(MemTop);
end;

function LowMemory: Boolean;
begin
  LowMemory := MaxAvail < SafetyPoolSize
end;

function MemAlloc(Size: Word): Pointer;
var
  P: Pointer;
begin
  HeapResult := 1;
  GetMem(P, Size);
  HeapResult := 0;
  if (P <> nil) and LowMemory then
  begin
    FreeMem(P, Size);
    P := nil;
  end;
  MemAlloc := P;
end;

function MemAllocSeg(Size: Word): Pointer;
var
  P, T: Pointer;
begin
  Size := (Size + 7) and $FFF8;
  P := MemAlloc(Size + 8);
  if P <> nil then
  begin
    if PtrRec(P).Ofs = 0 then
    begin
      PtrRec(T).Ofs := Size and 15;
      PtrRec(T).Seg := PtrRec(P).Seg + Size shr 4;
    end else
    begin
      T := P;
      PtrRec(P).Ofs := 0;
      Inc(PtrRec(P).Seg);
    end;
    FreeMem(T, 8);
  end;
  MemAllocSeg := P;
end;

procedure NewCache(var P: Pointer; Size: Word); assembler;
asm
        LES     DI,P
        MOV     AX,Size
        ADD     AX,(TYPE TCache)+15
        MOV     CL,4
        SHR     AX,CL
        MOV     DX,CachePtr.Word[2]
        SUB     DX,AX
        JC      @@1
        CMP     DX,HeapPtr.Word[2]
        JBE     @@1
        MOV     CX,HeapEnd.Word[2]
        SUB     CX,DX
        CMP     CX,MaxBufMem
        JA      @@1
        MOV     CachePtr.Word[2],DX
        PUSH    DS
        MOV     DS,DX
        XOR     SI,SI
        MOV     DS:[SI].TCache.Size,AX
        MOV     DS:[SI].TCache.Master.Word[0],DI
        MOV     DS:[SI].TCache.Master.Word[2],ES
        POP     DS
        MOV     AX,OFFSET TCache.Data
        JMP     @@2
@@1:    XOR     AX,AX
        CWD
@@2:    CLD
        STOSW
        XCHG    AX,DX
        STOSW
end;

procedure DisposeCache(P: Pointer); assembler;
asm
        MOV     AX,CachePtr.Word[2]
        XOR     BX,BX
        XOR     CX,CX
        MOV     DX,P.Word[2]
@@1:    MOV     ES,AX
        CMP     AX,DX
        JE      @@2
        ADD     AX,ES:[BX].TCache.Size
        CMP     AX,HeapEnd.Word[2]
        JE      @@2
        PUSH    ES
        INC     CX
        JMP     @@1
@@2:    PUSH    ES
        LES     DI,ES:[BX].TCache.Master
        XOR     AX,AX
        CLD
        STOSW
        STOSW
        POP     ES
        MOV     AX,ES:[BX].TCache.Size
        JCXZ    @@4
@@3:    POP     DX
        PUSH    DS
        PUSH    CX
        MOV     DS,DX
        ADD     DX,AX
        MOV     ES,DX
        MOV     SI,DS:[BX].TCache.Size
        MOV     CL,3
        SHL     SI,CL
        MOV     CX,SI
        SHL     SI,1
        DEC     SI
        DEC     SI
        MOV     DI,SI
        STD
        REP     MOVSW
        LDS     SI,ES:[BX].TCache.Master
        MOV     DS:[SI].Word[2],ES
        POP     CX
        POP     DS
        LOOP    @@3
@@4:    ADD     CachePtr.Word[2],AX
end;

procedure MoveSeg(Source, Dest, Size: Word); near; assembler;
asm
        PUSH    DS
        MOV     AX,Source
        MOV     DX,Dest
        MOV     BX,Size
        CMP     AX,DX
        JB      @@3
        CLD
@@1:    MOV     CX,0FFFH
        CMP     CX,BX
        JB      @@2
        MOV     CX,BX
@@2:    MOV     DS,AX
        MOV     ES,DX
        ADD     AX,CX
        ADD     DX,CX
        SUB     BX,CX
        SHL     CX,1
        SHL     CX,1
        SHL     CX,1
        XOR     SI,SI
        XOR     DI,DI
        REP     MOVSW
        OR      BX,BX
        JNE     @@1
        JMP     @@6
@@3:    ADD     AX,BX
        ADD     DX,BX
        STD
@@4:    MOV     CX,0FFFH
        CMP     CX,BX
        JB      @@5
        MOV     CX,BX
@@5:    SUB     AX,CX
        SUB     DX,CX
        SUB     BX,CX
        MOV     DS,AX
        MOV     ES,DX
        SHL     CX,1
        SHL     CX,1
        SHL     CX,1
        MOV     SI,CX
        DEC     SI
        SHL     SI,1
        MOV     DI,SI
        REP     MOVSW
        OR      BX,BX
        JNE     @@4
@@6:    POP     DS
end;

function GetBufSize(P: PBuffer): Word;
begin
  GetBufSize := (P^.Size + 15) shr 4 + 1;
end;

procedure SetBufSize(P: PBuffer; NewSize: Word);
var
  CurSize: Word;
begin
  CurSize := GetBufSize(P);
  MoveSeg(PtrRec(P).Seg + CurSize, PtrRec(P).Seg + NewSize,
    BufHeapPtr - PtrRec(P).Seg - CurSize);
  Inc(BufHeapPtr, NewSize - CurSize);
  Inc(PtrRec(P).Seg, NewSize);
  while PtrRec(P).Seg < BufHeapPtr do
  begin
    Inc(P^.Master^, NewSize - CurSize);
    Inc(PtrRec(P).Seg, (P^.Size + 15) shr 4 + 1);
  end;
end;

procedure NewBuffer(var P: Pointer; Size: Word);
var
  BufSize: Word;
  Buffer: PBuffer;
begin
  BufSize := (Size + 15) shr 4 + 1;
  if BufHeapPtr + BufSize > BufHeapEnd then P := nil else
  begin
    Buffer := Ptr(BufHeapPtr, 0);
    Buffer^.Size := Size;
    Buffer^.Master := @PtrRec(P).Seg;
    P := Ptr(BufHeapPtr + 1, 0);
    Inc(BufHeapPtr, BufSize);
  end;
end;

procedure DisposeBuffer(P: Pointer);
begin
  Dec(PtrRec(P).Seg);
  SetBufSize(P, 0);
end;

function GetBufferSize(P: Pointer): Word;
begin
  Dec(PtrRec(P).Seg);
  GetBufferSize := PBuffer(P)^.Size;
end;

function SetBufferSize(P: Pointer; Size: Word): Boolean;
var
  NewSize: Word;
begin
  Dec(PtrRec(P).Seg);
  NewSize := (Size + 15) shr 4 + 1;
  SetBufferSize := False;
  if BufHeapPtr + NewSize - GetBufSize(P) <= BufHeapEnd then
  begin
    SetBufSize(P, NewSize);
    PBuffer(P)^.Size := Size;
    SetBufferSize := True;
  end;
end;

procedure GetBufMem(var P: Pointer; Size: Word);
begin
  NewCache(P, Size);
end;

procedure FreeBufMem(P: Pointer);
begin
  DisposeCache(P);
end;

procedure SetMemTop(MemTop: Pointer); assembler;
asm
        MOV     BX,MemTop.Word[0]
        ADD     BX,15
        MOV     CL,4
        SHR     BX,CL
        ADD     BX,MemTop.Word[2]
        MOV     AX,PrefixSeg
        SUB     BX,AX
        MOV     ES,AX
        MOV     AH,4AH
        INT     21H
end;

{$ENDIF}

end.

