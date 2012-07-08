Unit StrUtil;

INTERFACE

Function  CopyFromTo(source:string; _From,_To: byte):string;
Procedure TruncStr  (var TS:string; From: byte);
Function  LastPos   (c: char; Str: string): byte;
Function  Capitalize(S:String):String; {Capitalize The First Letter Of Each Word}
Function  Center    (S: String; Len: Byte): String;
Function  DelBeg    (s: String):string; { delete all spaces from beginning }
Function  DelEnd    (s: String):string; { delete all spaces from end }
{****************************************************************************}

IMPLEMENTATION
Function  JustifyR  (S: String; Len: Byte): String;
Begin
  JustifyR := S;
  if Length(S) < Len then
     JustifyR := FillStr(' ',(Len - Length(S))) + S;
End;
{---------------}
Function  JustifyL  (S: String; Len: Byte): String;
Begin
  JustifyL := S;
  if Length(S) < Len then
     JustifyL := S + FillStr(' ',(Len - Length(S)));
End;
{---------------}
Function  BreakSum  (R: String; Symb: Char): String;
Var
  i, j: Byte;
  P, K: String;

 Function DelTrash(S: String): String;
 var P: string;
     i:byte;
 Begin
  P := '';
  For i := 1 to Length(S) do
  if (S[i]='.') or IsDigit(S[i]) then
     P := P + S[i];
  DelTrash := P
 End;

 Function Reverse(S: String): String;
 var P: string;
     i:byte;
 Begin
  P := '';
  For i := Length(S) downto 1 do
    P := P + S[i];
 End;

Begin
  P:=Reverse(DelTrash(R));
  K:=LeftEnd(P,'.');
  j := 0;
  For i:=1 to Length(P) do
  Begin
    if j = 3 then
    Begin
      K := K + Symb;
      j := 0;
    End;
    K := K + P[i];
    Inc(j);
  End;
  P:=Reverse(K);
  if CPos('.', P) = 0 then
     P := P + '.00';
  BreakSum := P;
End;
{---------------}
Function DelBeg(s: String):string;
var Len: Byte absolute s;
begin
       While ((s[1]=' ')or(s[len]=#9))and(Len>0) do Delete(s, 1, 1);
       DelBeg:=s;
end;
{---------------}
Function DelEnd(s: String):string;
var Len: Byte absolute s;
begin
       While ((s[len]=' ')or(s[len]=#9)) and (Len>0) do Dec(Len);
       DelEnd:=s;
end;
{---------------}
Function  Center    (S: String; Len: Integer): String;
Begin
  if Len < Length(S) then
     Center:= S
  else
    Center:= FillStr(' ',(Len - Length(S)) shr 1) + S;
End;
{---------------}
Function  Capitalize(S:String):String;
  var I:byte;
begin
      LoStr(S);
      S[1]:=UpCase(S[1]);
      For I:=1 to Length(S)-1 do
      If (S[I]=' ') or (S[I]='.') then
       S[i+1]:=UpCase(S[i+1]);
      Capitalize:=S;
end;

END.