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

unit CellsCol;

interface

uses  Objects, ObjType;

type
     PCellRec =^TCellRec;
     TCellRec = record
      Col: Byte;
      Row: Integer;
      Options: Word;
      Decimals: Byte;
      Value: Real;
      S: String;
     end;

     PCellCollection = ^TCellCollection;
     TCellCollection = object(TSortedCollection)
      procedure FreeItem(Item: Pointer); virtual;
      function NewItem(Col: Byte; Row: Integer; S: String): PCellRec;
      function ReplaceItem(Col: Byte; Row: Integer; S: String): PCellRec;
      function Get(Col: Byte; Row: Integer): PCellRec;
      procedure SetValue(Col: Byte; Row: Integer; AValue: Real);
      procedure DelItem(Col: Byte; Row: Integer);
      procedure PutItem(var S: TStream; Item: Pointer); virtual;
      function GetItem(var S: TStream): Pointer; virtual;
      function MakeFormatString(AValue: Real): String;
      function Compare(K1, K2: Pointer): Integer; virtual;
     end;

const
    RCellCollection: TStreamRec = (
       ObjType: otCellCollection;
       VmtLink: Ofs(TypeOf(TCellCollection)^);
       Load:    @TCellCollection.Load;
       Store:   @TCellCollection.Store
      );

    MaxCellY = 4096;


    LenDataRec = Sizeof(Byte) + SizeOf(Integer) + SizeOf(Word) +
                 SizeOf(Byte) + sizeof(Real) + SizeOf(Char);

{      Options :
          x x x x x x x
          ≥ ≥ ≥ ≥ ≥ ≥ ¿ø
          ≥ ≥ ≥ ≥ ≥ ¿ƒƒ¡ƒ Cell format (Text, Formula, Value)
          ≥ ≥ ≥ ≥ ¿ƒƒƒƒø
          ≥ ≥ ≥ ¿ƒƒƒƒƒƒ¡ƒ Justify options (Right, Left, Center)
          ≥ ≥ ¿ƒƒƒƒƒƒƒƒø
          ≥ ¿ƒƒƒƒƒƒƒƒƒƒ¥
          ¿ƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒ Display format(As is, Dec, Comma, Exp, Currency,
                                            Logic, Don't display)
}
    coText         = $0000;
    coFormula      = $0001;
    coValue        = $0002;
    coLeft         = $0004;
    coCenter       = $0008;
    coRight        = $000C;
    coDec          = $0010;
    coComma        = $0020;
    coExp          = $0030;
    coBool         = $0040;
    coCurrency     = $0050;
    coDONT         = $0060;

    CommaChar : Char = ',';
    SeparatorChar: Char = '|';

 procedure RegisterCellCollection;
 function MakeComma(S: String): String;
 function GetCellCoord(S: String; var X: Byte;var Y:Integer): Boolean;
 function GetCellName(X, Y: Integer): String;
{ function StoI(S: String): LongInt;
 function ItoS(L: LongInt): String;
 function UpCaseStr(S: String): String;
 function DelSpaces(S: String): String;}

implementation

uses Memory, Advance;

procedure TCellCollection.FreeItem;
begin
 FreeMem(Item, LenDataRec + Length(PCellRec(Item)^.S));
end;

function TCellCollection.MakeFormatString;
 var S: String;
begin
 Str(AValue:20:2, S);
 DelLeft(S);
 MakeFormatString := S;
end;

function TCellCollection.NewItem;
 var P: PCellRec;
begin
 P := MemAlloc(LenDataRec + Length(S));
 P^.Row := Row; P^.Col := Col;
 P^.S := S;
 P^.Options := 0;
 P^.Decimals := 0;
 P^.Value := 0;
 Insert(P);
 NewItem := P;
end;

procedure TCellCollection.DelItem;
 var I: Integer;
     P: PCellRec;
begin
 for I := 1 to Count do
  begin
   P := At(I - 1);
   if (P^.Row = Row) and (P^.Col = Col) then
    begin
     AtFree(I - 1); Exit;
    end;
  end;
end;

procedure TCellCollection.SetValue;
 var I: Integer;
     P: PCellRec;
begin
 for I := 1 to Count do
  begin
   P := At(I - 1);
   if (P^.Row = Row) and (P^.Col = Col) then
    begin
     P^.Value := AValue;
     Exit;
    end;
  end;
end;

function TCellCollection.ReplaceItem;
 var I, D, O: Integer;
     P: PCellRec;
begin
 for I := 1 to Count do
  begin
   P := At(I - 1);
   if (P^.Row = Row) and (P^.Col = Col) then
    begin
     O := P^.Options; D := P^.Decimals;
     FreeItem(P);
     P := MemAlloc(LenDataRec + Length(S));
     P^.Row := Row; P^.Col := Col;
     P^.S := S; AtPut(I - 1, P);
     P^.Options := O; P^.Decimals := D;
     ReplaceItem := P;
     Exit;
    end;
  end;
  ReplaceItem := NewItem(Col, Row, S);
end;

procedure TCellCollection.PutItem;
 var P: PCellRec;
begin
 P := Item;
 S.Write(P^, LenDataRec + Length(P^.S));
end;

function TCellCollection.GetItem;
 var R: TCellRec;
     P: PCellRec;
begin
 S.Read(R, LenDataRec);
 S.Read(R.S[1], Byte(R.S[0]));
 P := MemAlloc(LenDataRec + Byte(R.S[0]));
 Move(R, P^, LenDataRec + Byte(R.S[0]));
 GetItem := P;
end;

function TCellCollection.Get;
 var I: Integer;
     P: PCellRec;
begin
 Get := nil;
 for I := 1 to Count do
  begin
   P := At(I - 1);
   if (P^.Row = Row) and (P^.Col = Col) then
    begin Get := P; Exit end;
  end;
end;

function TCellCollection.Compare;
 var Key1, Key2: PCellRec;
begin
 Compare := 0;
 Key1 := K1; Key2 := K2;
 if Key1 = Key2 then Compare := 0 else
  if Key1 = nil then Compare := -1
   else if Key2 = nil then Compare := 1
    else if Key1^.Row < Key2^.Row then Compare := -1
     else if Key1^.Row > Key2^.Row then Compare := 1
      else if Key1^.Col < Key2^.Col then Compare := -1
       else if Key1^.Col > Key2^.Col then Compare := 1;
end;

{-----------------------------------------------------------------------}

function GetCellCoord(S: String; var X: Byte;var Y:Integer): Boolean;
 var S1: String[5];
     I: Integer;
begin
 UpStr(S);
 S1:=''; I := 1;
 if S[I] = '@' then Inc(I);
 While (I <= Length(S)) and (S[I]>='A') and (S[I]<='Z') do Inc(I);
 S1 := Copy(S, I+Byte(S[I]='@'), 100); S[0] := Char(I-1);
 Val(S1, Y, I); Dec(Y);
 GetCellCoord := not ((S[0]>#2) or (S='') or (S[0]=#2) and
                 (S[1]>'IV') or (Y<0) or (Y>MaxCellY));
 if S[0] = #1 then X := Byte(S[1]) - 65 else X := (Byte(S[1]) - 64) * 26 + Byte(S[2]) - 65;
end;

function GetCellName(X, Y: Integer): String;
 const Dig : String [26] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
 var S: String[10];
begin
  Str(Y + 1, S);
  if X < 26 then S := Dig[X + 1] + S
      else begin S := Dig[X div 26] + Dig[X mod 26 + 1] + S end;
  GetCellName := S;
end;

function MakeComma(S: String): String;
 var S1: String;
     I: Integer;
 label Quit;
begin
 S1 := S;
 asm
  lea di, S
  mov cl, ss:[di]
  xor dx, dx
  jcxz Quit
  mov al, '.'
@@1:
  inc dl
  inc di
  cmp al, ss:[di]
  jz @@2
  dec cl
  jnz @@1
  inc dl
@@2:
  mov al, dl
  cmp al, 5
  jc  Quit
  dec al
  jz Quit
  mov bl, 3
  xor ah, ah
  div bl
  mov cl, al
  or ah, ah
  jnz @@6
  dec cl
@@6:
  xor ch, ch
  mov dl, al
  lea di, S
  lea si, S1
  add cl, ss:[di]
  mov ss:[si], cl
  mov bl, ah
  or bl, bl
  jnz @@3
  mov bl, 3
  dec dl
@@3:
  inc si
  or bl, bl
  jnz @@4
  mov al, CommaChar
  mov ss:[si], al
  mov bl, 3
  dec dl
  jnz @@5
  mov bl, 255
  jmp @@5
@@4:
  inc di
  mov al, ss:[di]
  dec bl
@@5:
  mov ss:[si], al
  loop @@3
 end;
Quit: MakeComma := S1;
end;

function ItoS(L: LongInt): String;
 var S: String;
begin
 Str(L, S);
 ItoS := S;
end;

function StoI(S: String): LongInt;
 var I: LongInt;
     J: Integer;
begin
 Val(S, I, J);
 StoI := I;
end;

procedure RegisterCellCollection;
begin
 RegisterType(RCellCollection);
end;

(*
const UpcaseChars : String =
                    ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`'+
                    'ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~'+
                    'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü'+
                    'AÅBÉÑEÜáàâKãMHOè∞±≤≥¥µ∂∑∏π∫ªºΩæ'+
                    'ø¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ'+
                    'PCTìîXñóòôöõúùûüÒÚÛÙıˆ˜¯˘˙˚¸˝˛'#255;

function DelSpaces(S: String): String;
begin
 asm
  lea bx, S
  mov di, bx
  mov si, bx
  xor ch, ch
  mov cl, ss:[bx]
  or  cl, cl
  jz  @Exit
@@1:
  inc si
  mov al, ss:[si]
  cmp al, ' '
  jz @@2
  inc di
  mov ss:[di], al
  jmp @@3
@@2:
  dec byte ptr ss:[bx]
@@3:
  loop @@1
@Exit:
  end;
 DelSpaces := S;
end;
*)
end.