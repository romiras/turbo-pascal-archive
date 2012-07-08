UNIT CCalc;

interface

uses Advance, Par, RStrings, DNApp, Dialogs, Views, Objects,
     Drivers, Commands, HistList, DNHelp, ObjType;

type
     Real  =  Extended;
     PReal = ^Real;

     PCalcLine = ^TCalcLine;
     TCalcLine = object(TInputLine)
        ResultSelected: Boolean;
        procedure HandleEvent(var Event: TEvent); virtual;
        procedure SetData(var B); virtual;
        procedure SetValues(SetSelf: Boolean);
        procedure Awaken; virtual;
        destructor Done; virtual;
     end;

     PIndicator = ^TIndicator;
     TIndicator = object(TView)
       Error: Boolean;
       Value: Real;
       constructor Init(var R: TRect);
       procedure HandleEvent(var Event: TEvent); virtual;
       procedure Draw; virtual;
       function GetPalette: PPalette; virtual;
     end;

const
      RCalcLine: TStreamRec = (
       ObjType: otCalcLine;
       VmtLink: Ofs(TypeOf(TCalcLine)^);
       Load: @TCalcLine.Load;
       Store: @TCalcLine.Store);

      RIndicator: TStreamRec = (
       ObjType: otIndicator;
       VmtLink: Ofs(TypeOf(TIndicator)^);
       Load: @TIndicator.Load;
       Store: @TIndicator.Store);


procedure InsertCalc;

implementation

var Error: Boolean;
    Calc: PView;

procedure CalcError(NError: TStrIdx);
begin
  Error := True;
end;

function GetCellValue(S: String): Real;
 var C: Char;
     L: LongInt;
     B: Byte absolute S;

 procedure GetValue(N: Integer);
  var I: Integer;
      C: Char;
      K,M: LongInt;
 begin
   L := 0; M := 1;
   for I := 0 to B-1 do
    begin
      C := S[B-I];
      if (C>='0') and (C<='9') then K := Byte(C)-48 else
        if (C>='A') and (C<='F') then K := Byte(C)-55 else
          begin Error := On; Exit; end;
      if K > N - 1 then begin Error := On; Exit; end;
      L := L + K * M;
      M := M * N;
    end;
 end;

begin
 UpStr(S);
 if S = 'PI' then
   begin GetCellValue := PI; Exit end;
 if (S[1] = '@') and (B > 2) and (S[2] in ['H','B','O']) then
   begin
      C := UpCase(S[2]); Delete(S, 1, 2);
      case C of
        'H': GetValue(16);
        'B': GetValue(2);
        'O': GetValue(8);
      end;
      GetCellValue := L;
   end else Error := True;
end;

Function CalcFormulaTree(P: FPtr) : Real;

   Function GetFuncValue(P: FPtr) : Real;
    var I: Integer;
        R, R1: Real;
        S: String;
   begin
    S := UpCaseStr(P^.Name); GetFuncValue := 0;
    if S = 'IF' then
     begin
      if (P^.ParamsNum < 2) or (P^.ParamsNum > 3) then
       begin CalcError(erInvalidIF); Exit; end;
      R := 0; R1 := CalcFormulaTree(P^.Params^[1]); if Error then Exit;
      if (P^.ParamsNum = 2) then begin if R1 <> 0 then R := CalcFormulaTree(P^.Params^[2]) end
       else if R1 <> 0 then R := CalcFormulaTree(P^.Params^[2])
                       else R := CalcFormulaTree(P^.Params^[3]);
      GetFuncValue := R; Exit
     end;
    if P^.ParamsNum = 1 then
     begin
      R := CalcFormulaTree(P^.Params^[1]);
      if not Error then
      begin
        If S='RAD' then begin GetFuncValue:=(R*180)/PI; Exit end;
        If S='GRAD' then begin GetFuncValue:=(R*PI)/180; Exit end;
        If S='COS' then begin GetFuncValue:=Cos(R); Exit end;
        If S='SIN' then begin GetFuncValue:=Sin(R); Exit end;
        If S='SQR' then begin GetFuncValue:=R * R; Exit end;
        If (S='SQRT') then
         begin if (R >= 0) then GetFuncValue:=Sqrt(R) else Error := On; Exit end;
        If (S='LN') then
         begin if (R > 0) then GetFuncValue:=Ln(R) else Error := On; Exit end;
        If (S='LG') then
         begin if (R > 0) then GetFuncValue:=Ln(R)/Ln(10) else Error := On; Exit end;
        If ((S='TAN') or (S='TG')) then
         begin if (cos(R) <> 0) then GetFuncValue:=Sin(R)/Cos(R) else Error := On; Exit end;
        If S='ARCTAN' then begin GetFuncValue:=ArcTan(R); Exit end;
        If (S='EXP') then
        begin
          if (Abs(R) < 88.0) then GetFuncValue:=Exp(R) else Error := On;
          Exit;
        end;
        If (S='CTAN') or (S='CTG') or (S='COTAN') then
         begin if (Sin(R) <> 0) then GetFuncValue:=Cos(R)/Sin(R) else Error := On; Exit end;
        If S='SIGN' then
         begin if R = 0 then GetFuncValue:=0 else
               if R < 0 then GetFuncValue := -1
                        else GetFuncValue := 1; Exit end;
       end;
      end;
    CalcError(erInvalidFunction);
   end;


 var   R,R1 : Real;
       J, Y1, Y2: Integer;
       X1, X2: Byte;
       BB: Boolean;

 procedure FormulaError;
 begin
  {CalcError(erInvalidFormula)}
   Error := True;
 end;

begin
 CalcFormulaTree:=0; if Error then Exit;
 if p=Nil then Exit;
 if (p^.Tp=opFunc)
    then begin
          R:=GetFuncValue(P);
          CalcFormulaTree := R;
          Exit;
         end;
 if (p^.Tp=opValue) then
  begin
   Val(p^.Name,R,J);
   if J>0 then CalcError(erInvalidValue);
   CalcFormulaTree:=R; Exit;
  end;
  if (p^.Tp=opCell) then
   begin
    R := GetCellValue(p^.Name);
    CalcFormulaTree := R; Exit;
   end;
  if (p^.Tp=opSign) then
   begin
    if (p^.Name[0] > #2) or (p^.Name = #0) {or (p^.Right = nil) or
       (not (p^.Name[1] in UnarySigns) and (p^.Left =nil))}  then
     begin FormulaError; Exit end;
    if P^.Right = nil then
      begin
       CalcFormulaTree := CalcFormulaTree(p^.Left);
       Exit;
     end;
    R:=CalcFormulaTree(p^.Left);
    R1:=CalcFormulaTree(p^.Right);
    if Error then Exit;
    if p^.Name[0] = #1 then
    begin
     Case p^.Name[1] of
      '+' : R:=R+R1;
      '-' : R:=R-R1;
      '*' : if (Abs(R) > 1) then
                if (1e38/Abs(R) < Abs(R1)) then FormulaError else R:=R*R1
              else
                if (Abs(R1) > 1) and (1e38/Abs(R1) < Abs(R)) then FormulaError else R:=R*R1;
      '|' : if (Abs(R) <= $7FFFFFFF) and (Abs(R1) <= $7FFFFFFF) then
              R := Trunc(R) or Trunc(R1) else FormulaError;
      '&' : if (Abs(R) <= $7FFFFFFF) and (Abs(R1) <= $7FFFFFFF) then
              R := Trunc(R) and Trunc(R1) else FormulaError;
      '%' : if (Abs(R) <= $7FFFFFFF) and (Abs(R1) <= $7FFFFFFF) and (Trunc(R1) <> 0) then
              R := Trunc(R) mod Trunc(R1) else FormulaError;
      '\' : if (Abs(R) <= $7FFFFFFF) and (Abs(R1) <= $7FFFFFFF) then
              R := Trunc(R) xor Trunc(R1) else FormulaError;
      '~' : if (Abs(R1) <= $7FFFFFFF) then
              R := not Integer(Trunc(R1)) else FormulaError;
      '/' : if R1<>0 then R:=R/R1 else Error := On;
      '^' : if (R<>0) then
              begin
               BB := (Frac(R)=0) and (Frac(R1)=0);
               if (R=1) or(R1 = 0) then R:=1 else
                  begin
                   if Abs(R1) > 1e9 then begin Error := On; Exit; end;
                   J := Trunc(Round(R1));
                   if R>0 then Y1:=1 else Y1:=-1;
                   R:=Abs(R);
                   if (Ln(R)<(70/Abs(R1))) then {if R1 < 0 then R:=Exp(-ln(R)*R1)
                                                     else} R:=Exp(ln(R)*R1)
                                      else Error := On;
                   if Odd(J) then R := R*Y1;
                  end;
                if BB then
                  if Abs(Frac(R)) < 0.5 then
                    begin
                       R := Int(R);
                    end else
                    begin
                      if R < 0 then R := Int(R)-1
                               else R := Int(R)+1;
                    end;
              end else Error := On;
      '>' : R := Byte(R>R1);
      '<' : R := Byte(R<R1);
      '=' : R := Byte(R=R1);
       else FormulaError;
     end;
    end else
     Case p^.Name[1] of
      '=': case p^.Name[2] of
            '=': R := Byte(R=R1);
            '>': R := Byte(R>=R1);
            '<': R := Byte(R<=R1);
             else FormulaError;
           end;
      '&': if p^.Name[2] = '&' then R := Byte((R<>0) and (R1<>0)) else FormulaError;
      '|': if p^.Name[2] = '|' then R := Byte((R<>0) or (R1<>0)) else FormulaError;
      '^': if p^.Name[2] = '^' then R := Byte((R<>0) xor (R1<>0)) else FormulaError;
      '>': if p^.Name[2] = '<' then R := Byte(R<>R1) else
            if p^.Name[2] = '=' then R := Byte(R>=R1) else
              if (p^.Name[2] = '>') and (Abs(R) <= $7FFFFFFF) and (Abs(R1) < $7FFFFFFF)
               then R := Trunc(R) shr Trunc(R1) else FormulaError;
      '<': if p^.Name[2] = '>' then R := Byte(R<>R1) else
            if p^.Name[2] = '=' then R := Byte(R<=R1) else
             if (p^.Name[2] = '<') and (Abs(R) <= $7FFFFFFF) and (Abs(R1) < $7FFFFFFF)
               then R := Trunc(R) shl Trunc(R1) else FormulaError;
       else FormulaError;
     end;
    CalcFormulaTree:=R;
   end;

end;

constructor TIndicator.Init;
begin
  inherited Init(R);
  EventMask := evBroadcast;
  Error := Off;
  Value := 0;
end;

function TIndicator.GetPalette;
  const S: String[1] = CCluster;
begin
  GetPalette := @S;
end;

  procedure GetNValue(L: LongInt; A: Integer; var S: String);
  begin
    S := '';
    if L = 0 then S := '0' else
    while (L <> 0) do
     begin
       S := HexStr[(L and ((1 shl A) - 1)) + 1] + S;
       L := L shr A;
     end;
  end;


procedure TIndicator.HandleEvent;
 var D: record
         N: Word;
         S: String[250];
        end;

  procedure CE; begin DrawView; ClearEvent(Event); end;

begin
  inherited HandleEvent(Event);
  if (Event.What = evKeyDown) and (Event.KeyCode = kbUp) then CE;
  if (Event.What = evBroadcast) then
    case Event.Command of
       cmSetValue: begin
                     Error := Off;
                     Value := PReal(Event.InfoPtr)^;
                     CE
                   end;
       cmSetError: begin
                     Error := On;
                     CE
                   end;
       cmCancel: begin
                   Event.What := evCommand;
                   Event.Command := cmClose;
                   Event.InfoPtr := nil;
                   PutEvent(Event);
                   CE
                 end;
       cmCopyClip: begin
                  ClearEvent(Event);
                  Owner^.GetData(D);
                  case D.N of
                    0: begin
                         Str(Value:0:20, D.S);
                         While D.S[Length(D.S)] = '0' do Dec(D.S[0]);
                         if D.S[Length(D.S)] = '.' then Dec(D.S[0]);
                       end;
                    1: if Abs(Value) < $7FFFFFFF then GetNValue(Trunc(Value), 4, D.S) else Exit;
                    2: if Abs(Value) < $7FFFFFFF then GetNValue(Trunc(Value), 1, D.S) else Exit;
                    3: if Abs(Value) < $7FFFFFFF then GetNValue(Trunc(Value), 3, D.S) else Exit;
                    4: Str(Value, D.S);
                  end;
                  Message(Application, evCommand, cmPutInClipboard, @D.S);
               end;
    end;
end;

procedure TIndicator.Draw;
  var B: TDrawBuffer;
      S: String[40];
      C: Byte;
      L, LL: LongInt;

  procedure Wrt(N: Integer);
  begin
     MoveChar(B, ' ', C, Size.X);
     MoveStr(B[Size.X - Length(S) - 1], S, C);
     WriteLine(0, N, Size.X, 1, B);
  end;

  procedure WrtN(N, A: Integer);
   var L: LongInt;
  begin
    GetNValue(LL, A, S);
    Wrt(N);
  end;

begin
   C := GetColor(1);
   if Error then
     begin
        MoveChar(B, ' ', C, Size.X);
        WriteLine(0,0,Size.X,2,B);
        WriteLine(0,3,Size.X,2,B);
        S:=GetString(dlMsgError);
        MoveStr(B[(Size.X - Byte(S[0])) div 2], S, C);
        WriteLine(0,2,Size.X,1,B);
     end else
     begin
       Str(Value:0:20, S);
       While S[Length(S)] = '0' do Dec(S[0]);
       if S[Length(S)] = '.' then Dec(S[0]);
       Wrt(0);
       if Abs(Value) > $7FFFFFFF then
         begin
            S := GetString(dlOverflow);
            Wrt(1); Wrt(2); Wrt(3);
         end
         else begin
                LL := Trunc(Value);
                WrtN(1, 4); WrtN(2, 1); WrtN(3, 3);
              end;
       Str(Value, S);
       Wrt(4);
     end;
end;


procedure TCalcLine.HandleEvent;
 var WasKey: Boolean;
begin
   WasKey := Event.What = evKeyDown;
   if WasKey and ResultSelected then if Not (Event.CharCode in ['0'..'9']) then SelEnd:=0;
   inherited HandleEvent(Event);
   if WasKey then
    begin
     SetValues(Off);
     if Event.KeyCode = kbESC then
      begin
        GetData(FreeStr);
        HistoryAdd(hsCalcLine, FreeStr);
        Event.What := evCommand;
        Event.Command := cmClose;
        Event.InfoPtr := nil;
        PutEvent(Event);
        ClearEvent(Event);
      end;
    end else
    if (Event.What = evCommand) then
      case Event.Command of
        cmCalcValue: SetValues(On);
        cmGetName: PString(Event.InfoPtr)^ := GetString(dlCalculator);
      end;
end;

procedure TCalcLine.SetData;
begin
  inherited SetData(B);
  SetValues(Off);
end;

procedure TCalcLine.Awaken;
begin
  inherited Awaken;
  SetValues(Off);
  Calc := Owner;
end;

destructor TCalcLine.Done;
begin
  Calc := nil;
  inherited Done;
end;


procedure TCalcLine.SetValues;
 var P: Pointer;
     R: Real;
     T: FPtr;
     S: String;
begin
  ResultSelected:=False;
  GetData(S);
  DelSpace(S);
  if S = '' then
   begin R := 0; Message(Owner, evBroadcast, cmSetValue, @R); Exit end;
  Mark(P);
  T := GetFormula(S);
  if ErrOcc then begin Message(Owner, evBroadcast, cmSetError, nil); Release(P); Exit end;
  Error := Off;
  R := CalcFormulaTree(T);
  Release(P);
  if Error then Message(Owner, evBroadcast, cmSetError, nil)
           else begin
                  Message(Owner, evBroadcast, cmSetValue, @R);
                  if SetSelf then
                   begin
                     GetData(S);
                     HistoryAdd(hsCalcLine, S);
                     Str(R:0:20, S);
                     While S[Length(S)] = '0' do Dec(S[0]);
                     if S[Length(S)] = '.' then Dec(S[0]);
                     SetData(S);
                     Message(@Self, evKeyDown, kbEnd, nil);
                     SelStart:=0;
                     SelEnd:=Length(Data^);
                     DrawView;
                     ResultSelected:=True;
                   end;
                end;
end;


procedure InsertCalc;

    function MakeDialog : PDialog;
    var
      Dlg: PDialog;
      R: TRect;
      Control, Labl, Histry: PView;
    begin
       Dlg := PDialog( LoadResource( dlgCalculator )); R.Move(10, 5);

       R.Assign(2,3,Dlg^.Size.X-6,4);
       Control := New(PCalcLine, Init(R, 250));
       Control^.Options := Control^.Options or ofFramed or ofPostProcess;
       Dlg^.Insert(Control);

       R.Assign(Dlg^.Size.X-5,3,Dlg^.Size.X-2,4);
       Histry := New(PHistory, Init(R, PInputline(Control), hsCalcLine));
       Histry^.Options := Histry^.Options or ofFramed;
       Dlg^.Insert(Histry);

       R.Assign(2,2,13,3);
       Labl := New(PLabel, Init(R, GetString(dlCalcEx_p_ression), Control));
       Dlg^.Insert(Labl);

       R.Assign(12,6,Dlg^.Size.X-2,11);
       Control := New(PIndicator, Init(R));
       Control^.Options := Control^.Options or ofFramed;
       Dlg^.Insert(Control);

       MakeDialog := Dlg;
    end;

begin
  if Calc = nil then
    begin
      Calc := MakeDialog;
      Application^.InsertWindow(PWindow(Calc));
    end else Calc^.Select;
end;

END.