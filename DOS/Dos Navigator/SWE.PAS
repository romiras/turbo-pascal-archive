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
//     "Based on TinyWeb Server by RIT Research Labs."
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

Unit Swe;

Interface

uses Drivers, Objects, Views, Dialogs;

type
     TDate = record
       Year : Word;
       Month,Day : Byte;
      end;

const
      maxByte    : Byte    = $FF;
      minByte    : Byte    = $00;
      maxWord    : Word    = $FFFF;
      minWord    : Word    = $0000;
      minInteger : Integer = -1*maxInt;
      minLongInt : LongInt = -1*maxLongInt;
      maxReal              = 1.7e38;
      minReal              = -1*maxReal;
      maxDate : TDate = (Year : 9999;
                         Month: 12;
                         Day  : 31
                        );
      minDate : TDate = (Year : 1000;
                         Month: 1;
                         Day  : 1
                        );

     Procedure AssignDate(Year : Word;Month,Day : Byte; Var D : TDate);
     Procedure CopyDate(S : TDate; var D : TDate);
     Function MoreThat(D1, D2 : TDate): Boolean;
     Function LessThat(D1, D2 : TDate): Boolean;
     Procedure SetInLimits(var D : TDate; Min, Max : TDate);
     Function DateInStr(D : TDate):String;

type
     PInpLine = ^TInpLine;
     TInpLine = object(TInputLine)
      function GetPalette: PPalette; virtual;
     end;

     PInputByte = ^TInputByte;
     TInputByte = Object(TInpLine)
       MinValue,MaxValue,Value : Byte;
       EndView: Word;
       Constructor Init(var Bounds: TRect; AMinValue,AMaxValue : Byte);
       function Execute: Word; virtual;
       Function DataSize:Word;virtual;
       Procedure GetData(var Rec);virtual;
       Procedure SetData(var Rec);virtual;
       Procedure HandleEvent(var Event: TEvent);virtual;
      end;

     PInputWord = ^TInputWord;
     TInputWord = Object(TInpLine)
       MinValue,MaxValue,Value : Word;
       EndView: Word;
       Constructor Init(var Bounds: TRect; AMinValue,AMaxValue : Word);
       function Execute: Word; virtual;
       Function DataSize:Word;virtual;
       Procedure GetData(var Rec);virtual;
       Procedure SetData(var Rec);virtual;
       Procedure HandleEvent(var Event: TEvent);virtual;
      end;

     PInputInteger = ^TInputInteger;
     TInputInteger = Object(TInpLine)
       MinValue,MaxValue,Value : Integer;
       EndView: Word;
       Constructor Init(var Bounds: TRect; AMinValue,AMaxValue : Integer);
       function Execute: Word; virtual;
       Function DataSize:Word;virtual;
       Procedure GetData(var Rec);virtual;
       Procedure SetData(var Rec);virtual;
       Procedure HandleEvent(var Event: TEvent);virtual;
      end;

     PInputLongInt = ^TInputLongInt;
     TInputLongInt = Object(TInpLine)
       MinValue,MaxValue,Value : LongInt;
       EndView: Word;
       Constructor Init(var Bounds: TRect; AMinValue,AMaxValue : LongInt);
       function Execute: Word; virtual;
       Function DataSize:Word;virtual;
       Procedure GetData(var Rec);virtual;
       Procedure SetData(var Rec);virtual;
       Procedure HandleEvent(var Event: TEvent);virtual;
      end;

     PInputDate = ^TInputDate;
     TInputDate = Object(TInpLine)
       MinValue,MaxValue,Value : TDate;
       EndView: Word;
       Constructor Init(var Bounds: TRect; AMinValue,AMaxValue : TDate);
       function Execute: Word; virtual;
       Function DataSize:Word;virtual;
       Procedure GetData(var Rec);virtual;
       Procedure SetData(var Rec);virtual;
       Procedure HandleEvent(var Event: TEvent);virtual;
      end;

     PInputReal = ^TInputReal;
     TInputReal = Object(TInpLine)
       MinValue,MaxValue,Value : Real;
       Decimals : Byte;
       EndView: Word;
       Constructor Init(var Bounds: TRect; AMinValue,AMaxValue : Real; D : Byte);
       function Execute: Word; virtual;
       Function DataSize:Word;virtual;
       Procedure GetData(var Rec);virtual;
       Procedure SetData(var Rec);virtual;
       Procedure HandleEvent(var Event: TEvent);virtual;
      end;

     PInputString = ^TInputString;
     TInputString = Object(TInpLine)
       EndView: Word;
       function Execute: Word; virtual;
       Procedure HandleEvent(var Event: TEvent);virtual;
      end;

     PInputFName = ^TInputFName;
     TInputFName = object(TInputString)
       procedure HandleEvent(var Event: TEvent);virtual;
     end;

Implementation

uses Advance, Commands;

function TInpLine.GetPalette;
 const S: Array [0..1] of String[Length(CInputLine)] =
           (#9#9#10#8, #16#16#16#13);
begin
 GetPalette := @S[DrawShift];
end;

Procedure AssignDate(Year : Word;Month,Day : Byte; Var D : TDate);
begin
 D.Year:=Year;
 D.Month:=Month;
 D.Day:=Day;
end;

Procedure CopyDate(S : TDate; var D : TDate);
begin
D.Year:=S.Year;D.Month:=S.Month;D.Day:=S.Day;
end;

Function MoreThat(D1, D2 : TDate): Boolean;
begin
MoreThat:=False;
If (D1.Year>D2.Year) or
   ((D1.Year=D2.Year) and ((D1.Month>D2.Month) or
                          ((D1.Month=D2.Month) and (D1.Day>D2.Day))))
  then MoreThat := True;
end;

Function LessThat(D1, D2 : TDate): Boolean;
begin
LessThat:=False;
If (D1.Year<D2.Year) or
   ((D1.Year=D2.Year) and ((D1.Month<D2.Month) or
                          ((D1.Month=D2.Month) and (D1.Day<D2.Day))))
  then LessThat := True;
end;

Procedure SetInLimits(var D : TDate; Min, Max : TDate);
begin
 If MoreThat(D,Max) or LessThat(D,Min) then CopyDate(Min,D);
end;

Function DateInStr(D : TDate):String;
var A,B,C : Integer;
    S,S1,S2 : String[10];
begin
 Str(D.Day:2,S);Str(D.Month:2,S1);Str(D.Year:4,S2);
 S:=S+'.'+S1+'.'+S2;
 For A:=1 to 10 do
  If S[A]=' ' then S[A]:='0';
 DateInStr:=S;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  TInputByte  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TInputByte.Init;
begin
 Value:=0;
 MaxLen:=Trunc(ln(AMaxValue)/ln(10))+1;
 TInputLine.Init(Bounds,MaxLen);
 MaxValue:=AMaxValue;
 MinValue:=AMinValue;
 EndView:=0;
end;

function TInputByte.Execute: Word;
var Event : TEvent;
begin
 repeat
  Owner^.GetEvent(Event);
  If Event.What<>evNothing then HandleEvent(Event);
 until EndView<>0;

 ClearEvent(Event);

 Case EndView of
  kbEnter : Execute:=cmOk;
  kbEsc   : Execute:=cmCancel;
  else Execute:=EndView;
 end;
end;

Function TInputByte.DataSize;
begin
DataSize:=SizeOf(Value);
end;

Procedure TInputByte.GetData;
begin
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Move(Value,Rec,DataSize);
end;

Procedure TInputByte.SetData;
begin
Move(Rec,Value,DataSize);
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Str(Value,PString(Data)^);
DrawView;
end;

Procedure TInputByte.HandleEvent;
var C : Integer;
begin
  case Event.What of
    evKeyDown:
     begin
      If
         (Event.KeyCode=kbEnter) or
         (Event.KeyCode=kbEsc) or

         (Event.KeyCode=kbUp) or (Event.KeyCode=kbDown) or
         ((Event.KeyCode=kbLeft) and (CurPos=0)) or
         ((Event.KeyCode=kbRight) and (CurPos=Length(PString(Data)^)))

          then EndView:=Event.KeyCode;

      If (Event.CharCode in [#8,^Y,#0,'0','1'..'9'])
         then begin
               TInputLine.HandleEvent(Event);
              end;
      end;
    evMouseDown:TInputLine.HandleEvent(Event);
  end;
 Val(PString(Data)^,Value,C);
 If C<>0 then Value:=MaxValue;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  TInputWord  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TInputWord.Init;
begin
 Value:=0;
 MaxLen:=Trunc(ln(AMaxValue)/ln(10))+1;
 TInputLine.Init(Bounds,MaxLen);
 MaxValue:=AMaxValue;
 MinValue:=AMinValue;
 EndView:=0;
end;

function TInputWord.Execute: Word;
var Event : TEvent;
begin
 repeat
  Owner^.GetEvent(Event);
  HandleEvent(Event);
 until EndView<>0;

 ClearEvent(Event);

 Case EndView of
  kbEnter : Execute:=cmOk;
  kbEsc   : Execute:=cmCancel;
  else Execute:=EndView;
 end;
end;

Function TInputWord.DataSize;
begin
DataSize:=SizeOf(Value);
end;

Procedure TInputWord.GetData;
begin
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Move(Value,Rec,DataSize);
end;

Procedure TInputWord.SetData;
begin
Move(Rec,Value,DataSize);
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Str(Value,PString(Data)^);
DrawView;
end;

Procedure TInputWord.HandleEvent;
var C : Integer;
begin
  SelStart := SelEnd;
  case Event.What of
    evKeyDown:
     begin
      If
         (Event.KeyCode=kbEnter) or
         (Event.KeyCode=kbEsc) or

         (Event.KeyCode=kbUp) or (Event.KeyCode=kbDown) or
         ((Event.KeyCode=kbLeft) and (CurPos=0)) or
         ((Event.KeyCode=kbRight) and (CurPos=Length(PString(Data)^)))

          then EndView:=Event.KeyCode;

      If (Event.CharCode in [#8,^Y,#0,'0','1'..'9'])
         then begin
               if (Length(Data^) = MaxLen) and (CurPos < MaxLen) then Dec(Data^[0]);
               TInputLine.HandleEvent(Event);
              end;
      end;
    evMouseDown:TInputLine.HandleEvent(Event);
  end;
 Val(PString(Data)^,Value,C);
 If C<>0 then Value:=MaxValue;
end;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  TInputInteger  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TInputInteger.Init;
begin
 Value:=0;
 MaxLen:=Trunc(ln(Abs(AMaxValue))/ln(10))+1+Byte(MinValue<0){-};
 TInputLine.Init(Bounds,MaxLen);
 MaxValue:=AMaxValue;
 MinValue:=AMinValue;
 EndView:=0;
end;

function TInputInteger.Execute: Word;
var Event : TEvent;
begin
 repeat
  Owner^.GetEvent(Event);
  HandleEvent(Event);
 until EndView<>0;

 ClearEvent(Event);

 Case EndView of
  kbEnter : Execute:=cmOk;
  kbEsc   : Execute:=cmCancel;
  else Execute:=EndView;
 end;
end;


Function TInputInteger.DataSize;
begin
DataSize:=SizeOf(Value);
end;

Procedure TInputInteger.GetData;
begin
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Move(Value,Rec,DataSize);
end;

Procedure TInputInteger.SetData;
begin
Move(Rec,Value,DataSize);
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Str(Value,PString(Data)^);
DrawView;
end;

Procedure TInputInteger.HandleEvent;
var C : Integer;
begin
  case Event.What of
    evKeyDown:
     begin
      If
         (Event.KeyCode=kbEnter) or
         (Event.KeyCode=kbEsc) or

         (Event.KeyCode=kbUp) or (Event.KeyCode=kbDown) or
         ((Event.KeyCode=kbLeft) and (CurPos=0)) or
         ((Event.KeyCode=kbRight) and (CurPos=Length(PString(Data)^)))

          then EndView:=Event.KeyCode;
      If (Event.CharCode='-') and (MinValue>=0) then Event.CharCode:='A';
      If ((Event.CharCode in [#8,^Y,#0,'0'..'9']) or
         ((CurPos=0) and (Event.CharCode='-'))) and
          not ((CurPos=0) and (Data^[1]='-') and
              (Event.CharCode in ['0'..'9','-']))
          then TInputLine.HandleEvent(Event);
      end;
    evMouseDown:TInputLine.HandleEvent(Event);
  end;
 Val(PString(Data)^,Value,C);
 If C<>0 then Value:=MinValue;
end;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  TInputLongInt  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TInputLongInt.Init;
begin
 Value:=0;
 MaxLen:=Trunc(ln(AMaxValue)/ln(10))+1;
 TInputLine.Init(Bounds,MaxLen);
 MaxValue:=AMaxValue;
 MinValue:=AMinValue;
 EndView:=0;
end;

function TInputLongInt.Execute: Word;
var Event : TEvent;
begin
 repeat
  Owner^.GetEvent(Event);
  HandleEvent(Event);
 until EndView<>0;

 ClearEvent(Event);

 Case EndView of
  kbEnter : Execute:=cmOk;
  kbEsc   : Execute:=cmCancel;
  else Execute:=EndView;
 end;
end;

Function TInputLongInt.DataSize;
begin
DataSize:=SizeOf(Value);
end;

Procedure TInputLongInt.GetData;
begin
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Move(Value,Rec,DataSize);
end;

Procedure TInputLongInt.SetData;
begin
Move(Rec,Value,DataSize);
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Str(Value,PString(Data)^);
DrawView;
end;

Procedure TInputLongInt.HandleEvent;
var C : Integer;
begin
  SelStart := SelEnd;
  case Event.What of
    evKeyDown:
     begin
      If
         (Event.KeyCode=kbEnter) or
         (Event.KeyCode=kbEsc) or

         (Event.KeyCode=kbUp) or (Event.KeyCode=kbDown) or
         ((Event.KeyCode=kbLeft) and (CurPos=0)) or
         ((Event.KeyCode=kbRight) and (CurPos=Length(PString(Data)^)))

          then EndView:=Event.KeyCode;

      If (Event.CharCode in [#8,^Y,#0,'0','1'..'9'])
         then begin
               if (Length(Data^) = MaxLen) and (CurPos < MaxLen) then Dec(Data^[0]);
               TInputLine.HandleEvent(Event);
              end;
      end;
    evMouseDown:TInputLine.HandleEvent(Event);
  end;
 Val(PString(Data)^,Value,C);
 If C<>0 then Value:=MaxValue;
end;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  TInputDate  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TInputDate.Init;
begin
 AssignDate(1991,1,1,Value);
 TInputLine.Init(Bounds,10);
 MaxValue:=AMaxValue;
 MinValue:=AMinValue;
 EndView:=0;
 BlockCursor;
end;

function TInputDate.Execute: Word;
var Event : TEvent;
begin
 repeat
  Owner^.GetEvent(Event);
  HandleEvent(Event);
 until EndView<>0;

 ClearEvent(Event);

 Case EndView of
  kbEnter : Execute:=cmOk;
  kbEsc   : Execute:=cmCancel;
  else Execute:=EndView;
 end;
end;

Function TInputDate.DataSize;
begin
DataSize:=SizeOf(Value);
end;

Function SStr(Value,C : Word):String;
var S : string;
    I : Integer;
begin
 Str(Value:C,S);
 For I:=1 to C do If S[i]=' ' then S[i]:='0';
 SStr:=S;
end;

Procedure TInputDate.GetData;
begin
SetInLimits(Value,MinValue,MaxValue);
Move(Value,Rec,DataSize);
end;

Procedure TInputDate.SetData;
begin
Move(Rec,Value,DataSize);
SetInLimits(Value,MinValue,MaxValue);
DisposeStr(Data);
Data:=NewStr(SStr(Value.Day,2)+'/'+SStr(Value.Month,2)+'/'+SStr(Value.Year,4));
DrawView;
end;

Procedure TInputDate.HandleEvent;
var C : Integer;
    S : String;
begin
  case Event.What of
    evKeyDown:
     begin
      If
         (Event.KeyCode=kbEnter) or
         (Event.KeyCode=kbEsc) or

         (Event.KeyCode=kbUp) or (Event.KeyCode=kbDown) or
         ((Event.KeyCode=kbLeft) and (CurPos=0)) or
         ((Event.KeyCode=kbRight) and (CurPos=Length(PString(Data)^)-1))

          then EndView:=Event.KeyCode;

      If (Event.KeyCode = kbIns) or (Event.KeyCode = kbDel)
       then ClearEvent(Event);
      If (Event.CharCode in [#0,'0','1'..'9'])
              then begin
               If (Event.KeyCode=kbLeft) and (CurPos in [3,6]) then Dec(CurPos);
               If (Event.KeyCode=kbRight) and (CurPos in [1,4]) then Inc(CurPos);
               TInputLine.HandleEvent(Event);
              end;
     end;
   evMouseDown : TInputLine.HandleEvent(Event);
  end;
 If CurPos in [2,5] then Inc(CurPos);
 If CurPos=10 then Dec(CurPos);

 S:=Copy(PString(Data)^,1,2);
 Val(S,Value.Day,C); If not(Value.Day in [1..31]) then Value.Day:=1;

 S:=Copy(PString(Data)^,4,2);
 Val(S,Value.Month,C); If not(Value.Month in [1..12]) then Value.Month:=1;

 S:=Copy(PString(Data)^,7,4);Val(S,Value.Year,C);

 DisposeStr(Data);
 Data:=NewStr(SStr(Value.Day,2)+'/'+SStr(Value.Month,2)+'/'+SStr(Value.Year,4));
 DrawView;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  TInputReal  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

Constructor TInputReal.Init;
begin
 Value:=0;
 MaxLen:=Trunc(ln(AMaxValue)/ln(10))+1+Byte(AMinValue<0){-}+1{.}+D{Decimals};
 TInputLine.Init(Bounds,MaxLen);
 MaxValue:=AMaxValue;
 MinValue:=AMinValue;
 Decimals:=D;
 EndView:=0;
end;

function TInputReal.Execute: Word;
var Event : TEvent;
begin
 repeat
  Owner^.GetEvent(Event);
  HandleEvent(Event);
 until EndView<>0;

 ClearEvent(Event);

 Case EndView of
  kbEnter : Execute:=cmOk;
  kbEsc   : Execute:=cmCancel;
  else Execute:=EndView;
 end;
end;

Function TInputReal.DataSize;
begin
DataSize:=SizeOf(Value);
end;

Procedure TInputReal.GetData;
begin
If (Value>MaxValue) or (Value<MinValue) Then Value:=MinValue;
Move(Value,Rec,DataSize);
end;

Procedure TInputReal.SetData;
begin
Move(Rec,Value,DataSize);
Str(Value:0:Decimals,PString(Data)^);
end;

Procedure TInputReal.HandleEvent;
var C : Integer;
begin
  case Event.What of
    evKeyDown:
     begin
      If
         (Event.KeyCode=kbEnter) or
         (Event.KeyCode=kbEsc) or

         (Event.KeyCode=kbUp) or (Event.KeyCode=kbDown) or
         ((Event.KeyCode=kbLeft) and (CurPos=0)) or
         ((Event.KeyCode=kbRight) and (CurPos=Length(PString(Data)^)))

          then EndView:=Event.KeyCode;
          

      If (Event.CharCode in [#8,^Y,#0,'0'..'9']) or
         ((CurPos=0) and (Event.CharCode='-') and
                     (PString(Data)^[1]<>'-') and (MinValue<0)) or
         ((Event.CharCode='.') and (Pos('.',PString(Data)^)=0))
         then begin
               TInputLine.HandleEvent(Event);
              end;
     end;
    evMouseDown:TInputLine.HandleEvent(Event);
  end;
 Val(PString(Data)^,Value,C);
 If C<>0 then Value:=MaxValue;
end;

{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ  TInputString  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}

function TInputString.Execute: Word;
var Event : TEvent;
begin
 EndView:=0;
 repeat
  Owner^.GetEvent(Event);
  HandleEvent(Event);
 until EndView<>0;

 ClearEvent(Event);

 Case EndView of
  kbEnter : Execute:=cmOk;
  kbEsc   : Execute:=cmCancel;
  else Execute:=EndView;
 end;
end;

Procedure TInputString.HandleEvent;
var C : Integer;
begin
  SelStart := SelEnd;
  case Event.What of
    evKeyDown:
     begin
      If
         (Event.KeyCode=kbEnter) or
         (Event.KeyCode=kbEsc) or

         (Event.KeyCode=kbUp) or (Event.KeyCode=kbDown) or
         ((Event.KeyCode=kbLeft) and (CurPos=0)) or
         ((Event.KeyCode=kbRight) and (CurPos=Length(PString(Data)^)))

          then EndView:=Event.KeyCode{ else
          if Event.CharCode >= ' ' then
           if (Length(Data^) = MaxLen) and (CurPos < MaxLen) then Dec(Data^[0]);}
     end;
  end;
 TInputLine.HandleEvent(Event);
end;

procedure TInputFName.HandleEvent;
  var Dir, I: Integer;
begin
  Dir := 1;
  if (Event.What = evKeyDown) then
    begin
      if ((Event.KeyCode = kbLeft) or (Event.CharCode = #8)) then Dir := -1;
      if (Event.CharCode = #8) and (CurPos = 9) then Event.KeyCode := kbLeft;
      if (Event.CharCode = '.') then begin CurPos := 9; ClearEvent(Event); DrawView; end;
      {if (Event.KeyCode = kbIns) or (Event.CharCode = ^V) then ClearEvent(Event);
      }
    end;
  inherited HandleEvent(Event);
  I := PosChar('.', Data^);
  if (I <> 9) and (I > 0) then
     begin
       Data^ := AddSpace(Copy(Data^, 1, Min(8,I - 1)), 8) + Copy(Data^, I, 4);
       DrawView;
     end;
  if CurPos = 8 then begin Inc(CurPos, Dir); DrawView end;
end;


end.