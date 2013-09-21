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

unit Par;

interface

var ErrOcc : Boolean;
    ErrStr : String;
    CellOccured: Boolean;

type


    FPtr = ^FRec;
    FArray = Array[1..50] of FPtr;
    PFArray = ^FArray;
    OpType = (opCell,opFormula,opValue,opFunc,opSign,opSFunc);
    FRec = Record
      Owner: FPtr;
      Name: String;
      Tp: OpType;
      case OpType of
       opCell: (Left, Right: FPtr);
       opFunc: (ParamsNum: Byte; Params: PFArray);
    end;
    OpString           = String[2];


Const
    Signs  : Set of Char = ['+','-','*','/','^','=','|','\','&','%','#','~','>','<',':'];
    FSigns : Set of Char = ['+','-','*','/','^',':'];
    UnarySigns: Set of Char = ['+','-','~'];

    MaxOperations = 26;

    Prior  : Array [1..MaxOperations] of OpString =
      ('||','&&','^^','~','=','<','>','==','>=','=>','<=','=<',
      '<>','><','\','|','+','-','^','>>','<<','&','%','*','/',':');

{procedure GetToken( St : String; Start : Byte; var O : String;var Tp : OpType);
}procedure Error( Message : String);
function IsPrior  (c1,c2 : String) : Boolean;
function GetFormulaTree(St : String) : FPtr;
function GetFormula(const S: String): FPtr;


implementation
uses Advance;


procedure GetToken( St : String; var Start : Integer; var O : String;var Tp : OpType);
 var I,L   : Integer;
     S,S1  : String;
     B: Boolean;
begin
 UpStr(St);
 O:=Copy(St,Start,250);
 if O[1]='(' then Tp:=opFormula
             else if (O[1]>='0') and (O[1]<='9') or (O[1] = '$') or (O[1] = '.')
                     then Tp:=opValue
                     else if (O[1]>='A') and (O[1]<='Z') or (O[1] = '@')
                             then Tp:=opCell
                             else if O[1] in signs
                                     then
                                      begin
                                       S:=O[1];
                                       if (O[2] in signs) and not (O[1] in UnarySigns)
                                           and not (O[2] in UnarySigns)
                                          then S:=S+O[2];
                                       O:=S;
                                       Tp:=opSign;
                                       Inc(Start, Length(S));
                                       Exit;
                                      end
                                     else
                                      begin
                                       Error('Invalid expression was occurred');
                                       Exit;
                                      end;
 L:=1;
 S:='';
 Case Tp of
  opFormula : begin
             i:=1;
             S:=O[1];
             repeat
              Inc(L);
              AddStr(S, O[L]);
              Inc(i,Byte(O[L]='(')-Byte(O[L]=')'));
             until ((i=0) and (O[L]=')')) or (L>Byte(O[0]));
             Inc(Start, Length(S));
            end;
  opValue   : begin
               B := On;
               repeat
                AddStr(S, O[L]); B := B and (O[L] in ['0'..'9','E','.']);
                if B and (L < Length(O)) and (O[L] = 'E') and (O[L+1] in ['+','-'])
                  and (S[1] >= '0') and (S[1] <= '9') then
                  begin S := S + O[L+1]; Inc(L); end;
                Inc(L);
               until not (O[L] in ['0'..'9','X','A'..'F','H','O','.']) or (L>Byte(O[0]));
               Inc(Start, Length(S));
               if S[1] = '.' then Insert('0', S, 1);
               if PosChar('.', S) = 0 then
               if S[Length(S)] = 'H' then
                 begin
                   S := '@H'+Copy(S, 1, Length(S)-1);
                   tp := opCell;
                 end else
               if S[1] = '$' then
                 begin
                   S := '@H'+Copy(S, 2, Length(S)-1);
                   tp := opCell;
                 end else
               if (S[Length(S)] = 'B') and (S[2] in ['0'..'1']) then
                 begin
                   S := '@B'+Copy(S, 1, Length(S)-1);
                   tp := opCell;
                 end else
               if S[Length(S)] = 'O' then
                 begin
                   S := '@O'+Copy(S, 1, Length(S)-1);
                   tp := opCell;
                 end else
                  if (S[1] = '0') and (S[0] > #1) then
                   begin
                     tp := opCell;
                     case S[2] of
                       'X': S := '@H'+Copy(S,3,255);
                       'B': S := '@B'+Copy(S,3,255);
                       else S := '@O'+Copy(S,2,255);
                     end;
                   end
             end;
  opCell    : begin
               repeat
               AddStr(S, O[L]);
               Inc(L);
               if (O[L]='(') and (L <= Length(O)) then
                begin
                 I := L;
                 GetToken(O,L,S1,Tp);
                 L := I;
                 S:=S+S1;
                 Tp:=opFunc;
                end;
               until (O[L] in Signs) or (Tp=opFunc) or (L>Byte(O[0]));
               Inc(Start, Length(S));
              end;
 end;
 O:=S;
 ErrOcc:=False;
end;

procedure Error(Message : String);
begin
 ErrStr:=Message;
 ErrOcc:=True
end;

function IsPrior;
 var i : Byte;
begin
 i:=1;
 While (c1<>Prior[i]) and (c2<>Prior[i]) and (i<=MaxOperations) do Inc(i);
 IsPrior:=c1=Prior[i];
end;

function GetFormulaTree(St : String) : FPtr;

var LastOp,Root,p,
    CurPtr        : FPtr;
    S,S1          : String;
    Tp            : OpType;
    Count         : Integer;

 Procedure NewOperand( S : String);
  var Q, Q1: String;
      A,I: Integer;
 begin
  if tp=opFormula then
    begin
     DelFC(s);Dec(Byte(s[0]));
     p:=GetFormulaTree(s);
    end
    else
    if tp=opFunc then
    begin
     New(p);
     p^.Owner := LastOp;
     p^.Name := Copy(s,1,Pos('(',s)-1);
     p^.Tp := Tp;
     New(p^.Params);
     p^.ParamsNum := 0; p^.Params^[1] := nil;
     Q := Copy(s,Pos('(',s) + 1,200); Dec(Q[0]); I := 1; A := 0;
     While (I <= Length(Q)) do
      begin
       Q1 := '';
       While (I <= Length(Q)) and (Q[I] <> ',') do
        begin
         Q1 := Q1 + Q[I];
         if Q[I] = '(' then Inc(A) else if Q[I] = ')' then Dec(A);
         if A < 0 then begin ErrOcc := True; Exit end;
         Inc(I);
        end;
       if A <> 0 then begin ErrOcc := True; Exit end;
       Inc(p^.ParamsNum); Inc(I);
       p^.Params^[p^.ParamsNum] := GetFormulaTree(Q1);
      end;
    end
    else
    begin
     New(p);
     p^.Owner:=LastOp;
     p^.Left:=Nil;
     p^.Right:=Nil;
     p^.Name:=s;
     p^.Tp:=Tp; CellOccured := CellOccured or (Tp = opCell);
    end;
  if LastOP<>Nil then LastOp^.Right:=p;
  CurPtr:=p;
 end;

 procedure NewSign(S : String);
  Label Loop;
  var q : FPtr;
 begin
  New(p);
  p^.Name:=S;
  p^.Tp:=opSign;
  q:=LastOp;
Loop:
  if q=Nil then
   begin
    Root:=p;
    p^.Left:=CurPtr;
    p^.Right:=Nil;
    p^.Owner:=Nil;
   end
   else
   begin
    if isPrior(s,q^.Name) then
     begin
      While (q<>Nil) and isPrior(s,q^.Name) do q:=q^.Owner;
      CurPtr:=q;
      if q=Nil then CurPtr:=Root;
      GoTo Loop;
     end
     else
     begin
      p^.Owner:=q;
      p^.Left:=q^.Right;
      p^.Right:=Nil;
      q^.Right:=p;
     end
   end;
   LastOp:=p;
   CurPtr:=p;
 end;

begin
 if ErrOcc then Exit;
 LastOp:=Nil;Root:=Nil;CurPtr:=Nil;GetFormulaTree:=Nil;
 Count:=1;
 repeat
  GetToken(St,Count,S,Tp);
  {Inc(Count,Byte(s[0]));}
  if not ErrOcc then
   if Tp=opSign then NewSign(S) else NewOperand(S);
  GetFormulaTree:=Root;
 until (Count>Byte(St[0])) or ErrOcc;
 if (Root=Nil) and not ErrOcc then GetFormulaTree:=CurPtr;

end;

function GetFormula(const S: String): FPtr;
 var A1, A2, I: Integer;
begin
 CellOccured := False; GetFormula := nil;
 ErrOcc := False; A1 := 0; A2 := 0;
 For I := 1 to Length(S) do
  begin
   if S[I] = '(' then Inc(A1) else
      if S[I] = ')' then Dec(A1);
   if A1 < 0 then
    begin ErrOcc := True; Exit end;
  end;
 if A1 > 0 then
    begin ErrOcc := True; Exit end;
 GetFormula := GetFormulaTree(S);
end;


end.