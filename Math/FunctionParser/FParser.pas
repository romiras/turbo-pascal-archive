unit FParser;

{ Изменен для ТП7, 2004 Romtek

  из FuncParser.pas (Дельфи)
  (c) 2003 Щеглов Илья Александрович, студент факультета ФН
  МГТУ им. Н.Э. Баумана, Москва }

interface

uses
  Math;

const
 Capacity = 100;

type
 TOperation = Array [1..Capacity] of byte; { код операции }

 TOperand = Array [1..2] of Word; { операнды }

 TAoTOperand = Array [1..Capacity] of TOperand;
 TAoSingle = Array [1..Capacity div 2] of Single; { величины }


 TPFRecord = Record
   rb: TAoTOperand;
   ro: TOperation;
   rc: TAoSingle;
   Blength: word;   { =fi }
   Clength: word;   { =ci }
 End; {needed for import/export}


 TParsedFunction = Object

  public
    procedure ParseFunction (s: String; var ErCode: integer);
    function  Compute (x,y,z: single): single;
{    function Compute(const x: single = 0;
                     const y: single = 0;
                     const z: single = 0): single;}
    procedure ExportParsed (var r: TPFRecord);
    procedure ImportParsed (const r: TPFRecord);

  private
    a: TAoSingle;   { elementary blocks }
    b: TAoTOperand; { numbers of el. blocks, envolved in operation}
    o: TOperation;  { code of operation }
    c: TAoSingle;
    { constants, maybe variables or numbers;
      c[1]=x, c[2]=y, c[3]=z, c[4]=PI, c[5]=e, ....}

    fi         : word; { free index, also length of array b }
    ConstIndex : word; { last index for const, starting from 3 }

  End;


implementation

Function  UpStr (US: string): string;
var i: word;
begin
     for i := 1 to Length (US) do
         US[i] := UpCase (US[i]);
     UpStr := US;
end;

  procedure TParsedFunction.ImportParsed;
   var i: word;
   begin
      for i:=1 to r.Blength do
       begin
         o[i]:=r.ro[i];
         b[i]:=r.rb[i];
       end;
      for i:=4 to r.Clength do
         c[i]:=r.rc[i];

      ConstIndex:=r.Clength;
      fi:=r.Blength;
   end;

  procedure TParsedFunction.ExportParsed;
   var i: word;
   begin
      for i:=1 to fi do
       begin
         r.ro[i]:=o[i];
         r.rb[i]:=b[i];
       end;
      for i:=4 to ConstIndex do
         r.rc[i]:=c[i];

      r.Clength:=ConstIndex;
      r.Blength:=fi;

   end;

  Function TParsedFunction.Compute(x,y,z:single):single;
   var i: word;

   begin
     c[1]:=x;
     c[2]:=y;
     c[3]:=z;
     c[4]:=PI;
     c[5]:=exp(1);

     for i:=fi downto 1 do
      case o[i] of
       0 : a[i]:= c[b[i,1]];                  {  Assignment }
       1 : a[i]:= a[b[i,1]] + a[b[i,2]];      {  Summ }
       2 : a[i]:= a[b[i,1]] - a[b[i,2]];      {  Substract }
       3 : a[i]:= a[b[i,1]] * a[b[i,2]];      {  Multiplication }
       4 : a[i]:= a[b[i,1]] / a[b[i,2]];      {  Division }
       5 : a[i]:= sqr(a[b[i,1]]);             {  ^2 }
       6 : a[i]:= sqrt(a[b[i,1]]);            {  square root }
       7 : a[i]:= X_Y(a[b[i,1]],a[b[i,2]]); {  Power }
       8 : a[i]:= sin(a[b[i,1]]);             {  Sin }
       9 : a[i]:= cos(a[b[i,1]]);             {  Cos }
      10 : a[i]:= tg(a[b[i,1]]);             {  Tangence }
      11 : a[i]:= ctg(a[b[i,1]]);           {  Cotangence }
      12 : a[i]:= exp(a[b[i,1]]);             {  exp }
      13 : a[i]:= ln(a[b[i,1]]);              {  ln }
      14 : a[i]:= -a[b[i,1]];                 {  unary - }
      { RESERVED  for possible future use }
      16 : a[i]:= trunc(a[b[i,1]]);           {  whole part }
      17 : a[i]:= round(a[b[i,1]]);           {  round }
      18 : a[i]:= arcsin(a[b[i,1]]);          {  arcsin }
      19 : a[i]:= arccos(a[b[i,1]]);          {  arccos }
      20 : a[i]:= arctan(a[b[i,1]]);          {  arctan }
      21 : a[i]:= arcCtan(a[b[i,1]]);         { arccotan }
      22 : a[i]:= sh(a[b[i,1]]);              {  hyp sin }
      23 : a[i]:= ch(a[b[i,1]]);              {  hyp cos }
      24 : a[i]:= th(a[b[i,1]]);              {  hyp tan }
{      25 : a[i]:= coth(a[b[i,1]]);            { hyp cotan }

     end; { case }

     Compute := a[1];
   end;  { proc }

    procedure TParsedFunction.ParseFunction(s: String; var ErCode: integer);
    const
      letter   : set of Char = ['a'..'z', 'A'..'Z'];
      digit    : set of Char = ['0'..'9'];
      operand  : set of Char = ['-','+','*','/','^'];
{       bracket  : set of Char = ['(',')']; }
{       variable : set of Char = ['x','y','z']; }

    var

      i,j : word; { counters }
      len : word;
      ls: string;

     function MyPos(const ch: char; const start,fin:word):word;
     {searches ch in s OUTSIDE brackets in given interval}

      var i,br: integer;
      begin
        MyPos:=0;
        br:= 0;
        For i:=fin downto start do
         begin
          case s[i] of
            '(' : inc(br);
            ')' : dec(br);
          end;
          if (br=0) and (ch=s[i]) then  MyPos:=i;
         end;

      end;

     procedure ReversePluses(const start,fin:word);
      var i,br: integer;
          ch: char;
      begin
        br:=0;
        for i:=start to fin do
         begin
          case s[i] of
            '(' : inc(br);
            ')' : dec(br);
          end;
          if br=0 then
           begin
            ch:=s[i];
            if s[i]='+' then ch:='-';
            if s[i]='-' then ch:='+';
            s[i]:=ch;
           end;
         end;
      end;

     procedure ReverseDiv(const start,fin:word);
      var i,br: integer;
          ch: char;
      begin
        br:=0;
        for i:=start to fin do
         begin
          case s[i] of
            '(' : inc(br);
            ')' : dec(br);
          end;
          if br=0 then
           begin
            ch:=s[i];
            if s[i]='/' then ch:='*';
            if s[i]='*' then ch:='/';
            s[i]:=ch;
           end;
         end;
      end;

     procedure ReadNumber(const start: word; var num:single);
      var cp : word;
          strnum : string;
          errorcode : integer;
      begin
       cp:=start;
       repeat
         inc(cp);
       until not ((s[cp] in digit) or (s[cp]='.'));
       strnum:= Copy(s, start, cp-start);
       val(strnum,num,errorcode);
      end;

     procedure ParseExpr(start,fin,curfi:word);
     {index of a block is fi}

      var
       cp : word;{ cur position }
       ss,st: string;
       mynum : single;
       i,br:word;
       br_ok : boolean;

      procedure Repproc1;
      begin
           fi:=fi+1;
           b[curfi,1]:=fi;
           ParseExpr(start,cp-1,fi);
      end;
      procedure Repproc2;
      begin
           fi:=fi+1;
           b[curfi,2]:=fi;
           ParseExpr(cp+1,fin,fi);
      end;
      procedure Repproc3;
      begin
           fi:=fi+1;
           b[curfi,1]:=fi;
           ParseExpr(cp, fin,fi);
      end;

     begin

      repeat

       ss:= Copy(s,start,fin-start+1);   { for debug }

       { first get rid of useless enclosing brackets if present }
       {  like here: (sin(x)/cos(y)) }

       If (s[start]='(') and (s[fin]=')') then
        begin

          { If we have any operator within brackets at which }
          { bracket counter (br) = 0, then we MUST NOT remove brackets }
          { If there is none, we CAN do that. }

          br_ok:=true; { we CAN remove by default }
          br:= 0;
          for i:=start to fin do
            Case s[i] of
              '(' : inc(br);
              ')' : dec(br);
              '+','-','*','^','/' :
                    if br=0 then br_ok:=false;
            end;

          if br_ok then
            begin
              inc(start);
              dec(fin);
              continue;
            end;

        end;


        {  seek for + }
        cp:= MyPos('+',start,fin);
        If cp>0 then
         begin
           o[curfi]:=1;
           Repproc1;
{           fi:=fi+1;
           b[curfi,1]:=fi;
           ParseExpr(start,cp-1,fi);}
           Repproc2;
{           fi:=fi+1;
           b[curfi,2]:=fi;
           ParseExpr(cp+1,fin,fi);}
           break;
         end;

        { seek for - }
        cp:= MyPos('-',start,fin);
        If cp>0 then
          begin
            If cp>start then
             begin
              o[curfi]:=2;
              Repproc1;
{              fi:=fi+1;
              b[curfi,1]:=fi;
              ParseExpr(start,cp-1,fi);}
              fi:=fi+1;
              ReversePluses(cp+1,fin);
              { change + for - and vice versa }
              b[curfi,2]:=fi;
              ParseExpr(cp+1,fin,fi);
             end
            else
             begin     { unary - }
              o[curfi]:=14;
              fi:=fi+1;
              b[curfi,1]:=fi;
              ParseExpr(start+1,fin,fi);
             end;
           break;
          end;

        { seek for * }
        cp:= MyPos('*',start,fin);
        if cp>0 then
          begin
            o[curfi]:=3;
            Repproc1;
{            fi:=fi+1;
            b[curfi,1]:=fi;
            ParseExpr(start,cp-1,fi);}
            Repproc2;
{            fi:=fi+1;
            b[curfi,2]:=fi;
            ParseExpr(cp+1,fin,fi);}
            break;
          end;

        { seek for / }
        cp:= MyPos('/',start,fin);
        If cp>0 then
          begin
            o[curfi]:=4;
            Repproc1;
{            fi:=fi+1;
            b[curfi,1]:=fi;
            ParseExpr(start,cp-1,fi);}
            fi:=fi+1;
            b[curfi,2]:=fi;
            ReverseDiv(cp+1,fin);
            { change * for / and vice versa }
            ParseExpr(cp+1,fin,fi);
            break;
          end;

        { seek for ^; }
        cp:= MyPos('^',start,fin);
        if cp>0 then
           begin
             o[curfi]:=7;
             Repproc1;
{             fi:=fi+1;
             b[curfi,1]:=fi;
             ParseExpr(start,cp-1,fi);}
             Repproc2;
{             fi:=fi+1;
             b[curfi,2]:=fi;
             ParseExpr(cp+1,fin,fi);}
             break;
           end;

        { seek for variables and constants }
        case UpCase(s[start]) of
          'X' : begin
                  o[curfi]:=0;
                  b[curfi,1]:=1;
                  break;
                end;
          'Y' : begin
                  o[curfi]:=0;
                  b[curfi,1]:=2;
                  break;
                end;
          'Z' : begin
                  o[curfi]:=0;
                  b[curfi,1]:=3;
                  break;
                end;
     '0'..'9' : begin
                  ReadNumber(start, mynum);
                  o[curfi]:=0;
                  ConstIndex:=ConstIndex+1;
                  b[curfi,1]:=ConstIndex;
                  c[ConstIndex]:=mynum;
                  break;
                end;
        end; { case }

        { we have either function either special char, e.g. PI }
        { check for PI }
        if UpStr(ss)='PI' then
           begin
              o[curfi]:=0;
              b[curfi,1]:=4;
              break;
           end;
        { check for E }
        if UpStr(ss)='E' then
           begin
              o[curfi]:=0;
              b[curfi,1]:=5;
              break;
           end;

        { seek for func, as we have nothing else possible }
        { we have a function. Every func must have arg in brackets }
        { So, read ss until opening bracket: }
        cp:= MyPos('(',start,fin);
        if cp<>0 then
          begin
            st:= Copy(s,start,cp-start);
            st:=UpStr(st);

            if st='SQR' then
               begin
                 o[curfi]:=5;
                 Repproc3;
                 {fi:=fi+1;
                 b[curfi,1]:=fi;
                 ParseExpr(cp, fin,fi);}
                 break;
               end;

            if st='SQRT' then
               begin
                 o[curfi]:=6;
                 Repproc3;
                 break;
               end;

            if st='SIN' then
               begin
                 o[curfi]:=8;
                 Repproc3;
                 break;
               end;

            if st='COS' then
               begin
                 o[curfi]:=9;
                 Repproc3;
                 break;
               end;

            if st='TAN' then
               begin
                 o[curfi]:=10;
                 Repproc3;
                 break;
               end;

            if st='COT' then
               begin
                 o[curfi]:=11;
                 Repproc3;
                 break;
               end;

            if st='EXP' then
               begin
                 o[curfi]:=12;
                 Repproc3;
                 break;
               end;

            if st='LN' then
               begin
                 o[curfi]:=13;
                 Repproc3;
                 break;
               end;

            if st='TRUNC' then
               begin
                 o[curfi]:=16;
                 Repproc3;
                 break;
               end;

            if st='ROUND' then
               begin
                 o[curfi]:=17;
                 Repproc3;
                 break;
              end;

            if st='ASIN' then
               begin
                 o[curfi]:=18;
                 Repproc3;
                 break;
               end;

            if st='ACOS' then
               begin
                 o[curfi]:=19;
                 Repproc3;
                 break;
               end;

            if st='ATAN' then
               begin
                 o[curfi]:=20;
                 Repproc3;
                 break;
               end;

            if st='ACOT' then
               begin
                 o[curfi]:=21;
                 Repproc3;
                 break;
               end;

            if st='SINH' then
               begin
                 o[curfi]:=22;
                 Repproc3;
                 break;
               end;

            if st='COSH' then
               begin
                 o[curfi]:=23;
                 Repproc3;
                 break;
               end;

            if st='TANH' then
               begin
                 o[curfi]:=24;
                 Repproc3;
                 break;
               end;

            if st='COTH' then
               begin
                 o[curfi]:=25;
                 Repproc3;
                 break;
               end;

          end;   { if }

          ErCode:=1;

        until ErCode<>0;

       end; { proc }

    begin

     len:= length(s);
     fi:= 1;
     ConstIndex:= 5;

     { Check for errors first }
     ErCode:=0;
     j:=0;
     for i:=1 to len do
      begin
       if s[i]='(' then inc(j);
       if s[i]=')' then dec(j);
      end;
     if j<>0 then ErCode:=2;

     if ErCode<>2 then
      for i:=1 to len do
       if not ((s[i] in digit) or (s[i] in letter) or (s[i] in operand)
         or (s[i] in [')','(','.',' '])) then ErCode:=3;

     { kill all spaces }

    ls:='';
    for i:=1 to len do
        if s[i]<>' ' then ls:=ls + Copy(s,i,1);

    len:=length(ls);

    { a bit of optimization: kill useless unary pluses }

    if ls[1]<>'+' then s:=s[1] else s:='';
    for i:=2 to len do
        if (ls[i]<>'+') or (ls[i-1]<>'(') then
           s:=s + Copy(ls,i,1);

    len:=length(s);

    if ErCode=0 then ParseExpr(1,len,1);

    end; { func }

end.
