
uses FParser;

Const
   Expression = 'x * ln(x) - (x + 1)^3';

var
   ExpressionParser: TParsedFunction;
   erc: integer;
   f: single;

begin
     Writeln ('Results of function Y(x) = ',Expression);
     ExpressionParser.ParseFunction (Expression, erc);

     f := 0.2;
     while f < 1.4 do
     begin
          Writeln ('Y(', f:1:2,') = ',
            ExpressionParser.Compute (f, 0, 0) : 4 : 2);
          f := f + 0.2;
     end;
end.