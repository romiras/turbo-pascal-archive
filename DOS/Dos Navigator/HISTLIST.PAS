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

unit HistList;

{-----------------------------------------------------}
{ This module is based on Turbo Vision HistList Unit  }
{ Copyright (c) 1990 by Borland International         }
{-----------------------------------------------------}


{$O+,F+,X+,I-,S-}

{****************************************************************************
   History buffer structure:

    Byte Byte String          Byte Byte String
    +-------------------------+-------------------------+--...--+
    | 0 | Id | History string | 0 | Id | History string |       |
    +-------------------------+-------------------------+--...--+

 ***************************************************************************}

interface

uses Objects;

const
  HistoryBlock: Pointer = nil;
  HistorySize: Word = 2048;
  HistoryUsed: Word = 0;
  MaxHistorySize: Word = 20;

procedure HistoryAdd(Id: Byte; const Str: String);
function HistoryCount(Id: Byte): Word;
function HistoryStr(Id: Byte; Index: Integer): String;
procedure DeleteHistoryStr(Id: Byte; Index: Integer);
procedure ClearHistory;

procedure InitHistory;
procedure DoneHistory;

procedure StoreHistory(var S: TStream);
procedure LoadHistory(var S: TStream);

var
  CurId: Byte;
  CurString: PString;

implementation
uses Memory;

{ Advance CurString to next string with an ID of CurId }

procedure AdvanceStringPointer; near; assembler;
asm
        PUSH    DS
        MOV     CX,HistoryUsed
        MOV     BL,CurId
        LDS     SI,CurString
        MOV     DX,DS
        MOV     AX,DS
        OR      AX,SI
        JZ      @@3
        CLD
        JMP     @@2
@@1:    LODSW
        CMP     AH,BL { BL = CurId }
        JE      @@3
@@2:    LODSB
        XOR     AH,AH
        ADD     SI,AX
        CMP     SI,CX { CX = HistoryUsed }
        JB      @@1
        XOR     SI,SI
        MOV     DX,SI
@@3:    POP     DS
        MOV     CurString.Word[0],SI
        MOV     CurString.Word[2],DX
end;

{ Deletes the current string from the table }

procedure DeleteString; near; assembler;
asm
        PUSH    DS
        MOV     CX,HistoryUsed
        CLD
        LES     DI,CurString
        MOV     SI,DI
        DEC     DI
        DEC     DI
        PUSH    ES
        POP     DS
        MOV     AL,BYTE PTR [SI]
        XOR     AH,AH
        INC     AX
        ADD     SI,AX
        SUB     CX,SI
        REP     MOVSB
        POP     DS
        MOV     HistoryUsed,DI
end;

{ Insert a string into the table }

procedure InsertString(Id: Byte; const Str: String); near; assembler;
asm
        PUSH    DS
        STD

        { Position ES:DI to the end the buffer  }
        {          ES:DX to beginning of buffer }
        LES     DX,HistoryBlock
        MOV     DI,HistoryUsed
        LDS     SI,Str
        MOV     BL,[SI]
        INC     BL
        INC     BL
        INC     BL
        XOR     BH,BH
        POP     DS
        PUSH    DS
@@1:    MOV     AX,DI
        ADD     AX,BX
        SUB     AX,DX { DX = HistoryBlock.Word[0] }
        CMP     AX,HistorySize
        JB      @@2

        { Drop the last string off the end of the list }
        DEC     DI
        XOR     AL,AL
        MOV     CX,0FFFFH
        REPNE   SCASB
        INC     DI
        JMP     @@1

        { Move the table down the size of the string }
@@2:    MOV     SI,DI
        ADD     DI,BX
        MOV     HistoryUsed,DI
        PUSH    ES
        POP     DS
        MOV     CX,SI
        SUB     CX,DX { DX = HistoryBlock.Word[0] }
        REP     MOVSB

        { Copy the string into the position }
        CLD
        MOV     DI,DX { DX = HistoryBlock.Word[0] }
        INC     DI
        MOV     AH,Id
        XOR     AL,AL
        STOSW
        LDS     SI,Str
        LODSB
        STOSB
        MOV     CL,AL
        XOR     CH,CH
        REP     MOVSB

        POP     DS
end;

procedure StartId(Id: Byte); near;
begin
  CurId := Id;
  CurString := HistoryBlock;
end;

function HistoryCount(Id: Byte): Word;
var
  Count: Word;
begin
  StartId(Id);
  Count := 0;
  AdvanceStringPointer;
  while CurString <> nil do
  begin
    Inc(Count);
    AdvanceStringPointer;
  end;
  HistoryCount := Count;
end;

procedure HistoryAdd(Id: Byte; const Str: String);
  var C: Char;
      I,J: Integer;
begin
  if Str = '' then Exit;
  if HistoryUsed < 3 then HistoryUsed := 1;

  I := 0;
  StartId(Id);

  C := ' ';
  { Delete duplicates }
  AdvanceStringPointer;
  while CurString <> nil do
  begin
    if Str = Copy(CurString^, 1, Length(CurString^)-1)  then
      begin
        C := CurString^[Length(CurString^)];
        DeleteString;
        Dec(I);
      end;
    Inc(I);
    AdvanceStringPointer;
  end;

  if I > MaxHistorySize - 1 then
   for J := I-1 downto 0 do
    begin
      HistoryStr(ID, J);
      if CurString = nil then Break;
      if CurString^[Length(CurString^)] <> '+' then
         begin
           DeleteString; Dec(I); Inc(J);
           if I < MaxHistorySize then Break;
         end;
    end;
  {
  if HistoryUsed < Length(Str) + 4 then
    begin
      CurString := HistoryBlock;
      Inc(LongInt(CurString), PtrRec(HistoryBlock).Ofs+1);
      while (LongInt(CurString)-LongInt(HistoryBlock) < HistoryUsed)
            and (HistoryUsed < Length(Str) + 4) do
        begin
          if CurString^[Length(CurString^)] <> '+' then DeleteString;
          Inc(LongInt(CurString), Length(CurString^)+3);
        end;

    end;
 }
  CurString := nil;

  InsertString(Id, Str + C);
end;

function HistoryStr(Id: Byte; Index: Integer): String;
var
  I: Integer;
begin
  StartId(Id);
  for I := 0 to Index do AdvanceStringPointer;
  if CurString <> nil then
    HistoryStr := Copy(CurString^, 1, Length(CurString^)-1) else
    HistoryStr := '';
end;

procedure ClearHistory;
begin
  FillChar(HistoryBlock^, HistorySize, 0);
  PChar(HistoryBlock)^ := #0;
  HistoryUsed := PtrRec(HistoryBlock).Ofs + 1;
end;

procedure StoreHistory(var S: TStream);
var
  Size: Word;
begin
  Size := HistoryUsed - PtrRec(HistoryBlock).Ofs;
  S.Write(Size, SizeOf(Word));
  S.Write(HistoryBlock^, Size);
end;

procedure LoadHistory(var S: TStream);
var
  Size, I: Word;
begin
  S.Read(Size, SizeOf(Word));
  if HistoryBlock = nil then InitHistory;
  if HistorySize < Size then I := Size - HistorySize else I := 0;
  S.Read(HistoryBlock^, Size - I);
  S.Seek(S.GetPos + I);
  HistoryUsed := PtrRec(HistoryBlock).Ofs + Size;
end;

procedure InitHistory;
begin
  HistoryBlock := MemAllocSeg(HistorySize);
  ClearHistory;
end;

procedure DoneHistory;
begin
  FreeMem(HistoryBlock, HistorySize);
end;

procedure DeleteHistoryStr(Id: Byte; Index: Integer);
begin
  HistoryStr(ID, Index);
  if CurString <> nil then DeleteString;
end;

end.

