
{ Volvo (c) }

Const maxStack = 100;
Type
  TType = Integer;
  TStack = Record
    stArr: Array[1 .. maxStack] Of TType;
    currTop: Integer;
  End;

Procedure Init(Var s: TStack);
  Begin
    s.currTop := 0
  End;

Procedure Push(Var s: TStack; x: TType);
  Begin
    If s.currTop <> maxStack Then
      Begin
        Inc(s.currTop); s.stArr[s.currTop] := x;
      End;
  End;

Function Pop(Var s: TStack): TType;
  Begin
    If s.currTop <> 0 Then
      Begin
        Pop := s.stArr[s.currTop]; Dec(s.currTop);
      End;
  End;

Function Top(Var s: TStack): TType;
  Begin
    Top := s.stArr[s.currTop];
  End;

Function IsEmpty(Var s: TStack): Boolean;
  Begin
    IsEmpty := (s.currTop = 0)
  End;

Procedure Print(Var s: TStack);
  Var i: Integer;
  Begin
    For i := 1 To s.currTop Do
      Write(s.stArr[i]:4);
    WriteLn
  End;


Const
  n = 10;
  arr: Array[1 .. n] Of TType =
    (1, 2, 4, 5, 2, 6, 7, 0, 9, 2);

Var
  mainStack, resStack, tmpStack: TStack;
  i: integer;

begin
  Init(mainStack);
  Init(resStack);
  Init(tmpStack);

  For i := 1 To n Do
    Push(mainStack, arr[i]);
  Print(mainStack);

  While not IsEmpty(mainStack) Do
    Begin
      If IsEmpty(resStack) or (Top(resStack) < Top(mainStack))
        Then Push(resStack, Pop(mainStack))
        Else
          Begin
            While (Top(resStack) > Top(mainStack)) and
                  (not IsEmpty(resStack)) Do
              Push(tmpStack, Pop(resStack));
            Push(resStack, Pop(mainStack));
            While not IsEmpty(tmpStack) Do
              Push(resStack, Pop(tmpStack))
          End
    End;
  Print(resStack)
end.