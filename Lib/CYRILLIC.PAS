(*
Function OemToAnsi(S:String):String;
{ DOS -> WIN }
Function AnsiToOem(S:String):String;
{ WIN -> DOS }
Function OemToKoi(S:String):String;
{ DOS -> KOI8r }
Function KoiToOem(S:String):String;
*)

uses Objects;
const
  XlatTable: array[0..2] of String[66] = (
{DOS}'€‚ƒ„…†‡ˆ‰Š‹Œ‘’“”•–—˜™š›œŸ ¡¢£¤¥¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîïğñ',
{WIN}'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏĞÑÒÓÔÕÖ×ØÙÚÛÜİŞßàáâãäåæçèéêëìíîïğñòóôõö÷øùúûüışÿ¨¸',
{KOI}'áâ÷çäåöúéêëìíîïğòóôõæèãşûıøùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏĞÒÓÔÕÆÈÃŞÛİßÙØÜÀÑåÅ'
  );

{ ID`s of conversion tables }
      xTblDos=0; xTblWin=1; xTblKoi=2;

{--------------------------------------------}
function XltStr(S: String; SourTable,DestTable: Integer): String;
var I, Idx: Integer;
    SourceChars, DestChars: PString;
begin
 if not(SourTable in [0..4]) or not(DestTable in [0..4]) then
  begin XltStr:=S; exit; end;
 SourceChars:= @XlatTable[SourTable];
 DestChars  := @XlatTable[DestTable];
 for I:= 1 to Length(S) do
   begin
     Idx:= Pos(S[I],SourceChars^);
     if Idx <> 0 then S[I]:= DestChars^[Idx];
   end;
 XltStr:= S;
end;
{--------------------------------------------}
Function OemToAnsi(S:String):String;
begin
 OemToAnsi:=XltStr(S,xTblDos,xTblWin);
end;
{--------------------------------------------}
Function AnsiToOem(S:String):String;
begin
 AnsiToOem:=XltStr(S,xTblWin,xTblDos);
end;
{--------------------------------------------}
Function OemToKoi(S:String):String;
begin
 OemToKoi:=XltStr(S,xTblDos,xTblKoi);
end;
{--------------------------------------------}
Function KoiToOem(S:String):String;
begin
 KoiToOem:=XltStr(S,xTblKoi,xTblDos);
end;

begin
     Assign (Output, 'output.txt');
     Rewrite (Output);

     { DOS (OEM) }
     writeln ('Test ’¥áâ');

     { Win (ANSI) }
     writeln (OemToAnsi('Test ’¥áâ'));
     Close (Output);
end.