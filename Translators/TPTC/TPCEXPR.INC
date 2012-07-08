(*
 * expression parser
 *
 *)
function pterm: string; forward;

function iscall(var lv: string): boolean;
   {see if the given lvalue is a function call or not}
begin
   iscall := lv[length(lv)] = ')';
end;


procedure make_pointer(var expr: string);
   {convert the expression into a pointer constant, if possible}
var
   sym:  symptr;
begin

   case(expr[1]) of
      '*':
      begin
	 delete(expr,1,1);
	 exit;
      end;

      'a'..'z','A'..'Z','_':
      begin	    {pass pointer to strings/arrays}
	 sym := locatesym(expr);
	 if (sym <> nil) and ((sym^.symtype = s_string) or
			      (sym^.suptype = ss_array)) then
	 begin
	    {null}
	 end
	 else

	 if expr[length(expr)-1] = '(' then    {remove () from function calls}
	    dec(expr[0],2)

	 else
	    expr := '&' + expr;
      end;

   end;

end;


function isnumber(var lv: string): boolean;
  {see if the given value is a literal number}
var
   i: integer;
begin
   for i := 1 to length(lv) do
      case lv[i] of
	 '0'..'9','.': ;
	 else
	    isnumber := false;
	    exit;
      end;
   isnumber := true;
end;


procedure subtract_base(var expr: string; base: integer);
   {subtract the specified base from the given expression;
    use constant folding if possible}
begin
   if base <> 0 then
      if isnumber(expr) then
	 expr := itoa(atoi(expr) - base)
      else
      if base > 0 then
	 expr := expr + '-' + itoa(base)
      else
	 expr := expr + '+' + itoa(-base);
end;


function exprtype: char;
   {determine expression type and return the printf code for the type}
var
   xt:	    char;

begin
   case cexprtype of
      s_char:	 xt := 'c';
      s_file:	 xt := '@';
      s_double:  xt := 'f';
      s_string:  xt := 's';
      s_bool:	 xt := 'b';
      s_int:	 xt := 'd';
      s_long:	 xt := 'D'; { calling routine should convert to "ld" }
      else	 xt := '?';
   end;

   exprtype := xt;
end;


function strtype(ty: char): boolean;
   {see if the expression is a string data type or not}
begin
   case ty of
      's','c':	strtype := true;
      else	strtype := false;
   end;
end;



function psetof:  string;
   {parse a literal set; returns the set literal translated into
    the form: setof(.....)}
var
   ex: string;

begin
   ex := 'setof(';
   if tok[1] <> ']' then
      ex := ex + pterm;

   while (tok = '..') or (tok[1] = ',') do
   begin
      if tok = '..' then
	 ex := ex + ',__,'
      else
	 ex := ex + ',';

      gettok;
      ex := ex + pterm;
   end;

   if ex[length(ex)] <> '(' then
      ex := ex + ',';
   ex := ex + '_E)';
   psetof := ex;
end;


function pterm:   string;
   {parse an expression term;  returns the translated expression term;
    detects subexpressions, set literals and lvalues(variable names)}
var
   ex: string;
   builtin: boolean;

begin
   if debug_parse then write(' <term>');

   if (toktype = identifier) and (cursym <> nil) then
      builtin := cursym^.suptype = ss_builtin
   else
      builtin := false;

   (* process pos(c,str) and pos(str,str) *)
   if builtin and (tok = 'POS') then
   begin
      if debug_parse then write(' <pos>');
      gettok;	{consume the keyword}
      if tok[1] <> '(' then
	 syntax('"(" expected (pterm.pos)');

      gettok;	{consume the (}
      ex := pexpr;
      if exprtype{(ex)} = 'c' then
	 ex := 'cpos(' + ex
      else
	 ex := 'spos(' + ex;

      gettok;	{consume the ,}
      ex := ex + ',' + pexpr;
      gettok;	{consume the )}
      pterm := ex + ')';
      cexprtype := s_int;
   end
   else

   (* process chr(n) *)
   if builtin and (tok = 'CHR') then
   begin
      if debug_parse then write(' <chr>');
      gettok;	{consume the keyword}
      if tok[1] <> '(' then
	 syntax('"(" expected (pterm.chr)');

      gettok;	{consume the (}
      ex := pexpr;
      gettok;	{consume the )}

      if isnumber(ex) then
	 ex := numlit(atoi(ex))
      else
	 ex := 'chr('+ex+')';

      pterm := ex;
      cexprtype := s_char;
   end
   else

   (* translate NOT term into !term *)
   if builtin and (tok = 'NOT') then
   begin
      if debug_parse then write(' <not>');
      gettok;
      pterm := '!' + pterm;
      cexprtype := s_bool;
   end
   else

   (* process port/memory array references *)
   if builtin and ((tok = 'PORT') or (tok = 'PORTW') or
		   (tok = 'MEM')  or (tok = 'MEMW')) then
   begin
      if debug_parse then write(' <port>');
      if tok = 'PORT'  then ex := 'inportb('	else
      if tok = 'PORTW' then ex := 'inport('	else
      if tok = 'MEM'   then ex := 'peekb('	else
			    ex := 'peek(';

      gettok;	  {consume the keyword}
      gettok;	  {consume the [ }

      repeat
	 ex := ex + pexpr;
	 if tok[1] = ':' then
	 begin
	    gettok;
	    ex := ex + ',';
	 end;
      until (tok[1] = ']') or recovery;

      gettok;	  {consume the ] }
      pterm := ex + ')';
      cexprtype := s_int;
   end
   else

   (* translate bitwise not (mt+) *)
   if (tok[1] = '?') or (tok[1] = '~') or (tok[1] = '\') then
   begin
      if debug_parse then write(' <bitnot>');
      gettok;
      pterm := '!' + pterm;	    {what is a bitwise NOT in c?}
   end
   else

   (* process unary minus *)
   if tok = '-' then
   begin
      if debug_parse then write(' <unary>');
      gettok;
      pterm := '-' + pterm;
   end
   else

   (* translate address-of operator *)
   if tok[1] = '@' then
   begin
      if debug_parse then write(' <ref>');
      gettok;  {consume the '@'}
      ex := plvalue;
      make_pointer(ex);
      pterm := ex;
   end
   else

   (* pass numbers *)
   if toktype = number then
   begin
      if debug_parse then write(' <number>');
      pterm := tok;
      gettok;
      cexprtype := s_int;
   end
   else

   (* pass strings *)
   if toktype = strng then
   begin
      if debug_parse then write(' <string>');
      pterm := tok;
      gettok;
      cexprtype := s_string;
   end
   else

   (* pass characters *)
   if toktype = chars then
   begin
      if debug_parse then write(' <char>');
      pterm := tok;
      gettok;
      cexprtype := s_char;
   end
   else

   (* pass sub expressions *)
   if tok[1] = '(' then
   begin
      if debug_parse then write(' <subexp>');
      gettok;
      pterm := '(' + pexpr + ')';
      gettok;
   end
   else

   (* translate literal sets *)
   if tok[1] = '[' then
   begin
      if debug_parse then write(' <setlit>');
      gettok;
      pterm := psetof;
      gettok;
      cexprtype := s_struct;
   end

   (* otherwise the term will be treated as an lvalue *)
   else
      pterm := plvalue;
end;


function pexpr: string;
   {top level expression parser; parse and translate an expression and
    return the translated expr}
var
   ex:	     string;
   ty:	     char;
   ex2:      string;
   ty2:      char;

   procedure relop(newop: string40);
   begin
      if debug_parse then write(' <relop>');
      gettok;	     {consume the operator token}

      ex2 := pterm;  {get the second term}
      ty2 := exprtype;

      {use strcmp if either param is a string}
      if ty = 's' then
      begin
	 if ty2 = 's' then
	    ex := 'strcmp(' + ex + ',' + ex2 + ') ' + newop + ' 0'
	 else
	 if ex2[1] = '''' then
	    ex := 'strcmp(' + ex + ',"' +
		     copy(ex2,2,length(ex2)-2) + '") ' + newop + ' 0'
	 else
	    ex := 'strcmp(' + ex + ',ctos(' + ex2 + ')) ' + newop + ' 0'
      end
      else

      if ty = 'c' then
      begin
	 if ty2 = 's' then
	    ex := 'strcmp(ctos(' + ex + '),' + ex2 + ') ' + newop + ' 0'
	 else {ex := ex+newop+ex2}
	    ex := ex + ' ' + newop + ' ' + ex2
      end
      else {ex := ex+newop+ex2;}
	 ex := ex + ' ' + newop + ' ' + ex2;
      cexprtype := s_bool;
   end;


   procedure addop;

      procedure add_scat;
      var
	 p: integer;

      begin
	 {find end of control string}
	 p := 7;  {position of 'scat("%'}
	 while (ex[p] <> '"') or
	       ((ex[p] = '"') and (ex[p-1] = '\') and (ex[p-2] <> '\')) do
	    p := succ(p);
	 p := succ(p);

	 {add literals to the control string if possible}
	 if (ex2[1] = '''') or (ex2[1] = '"') then
	    ex := copy(ex,1,p-2) +
		  copy(ex2,2,length(ex2)-2) +
		  copy(ex,p-1,length(ex)-p+2)

	 else {add a parameter to the control string}
	    ex := copy(ex,1,p-2) + '%' + ty2 +
		  copy(ex,p-1,length(ex)-p+1) + ',' + ex2 + ')';
      end;

   begin
      if debug_parse then write(' <addop>');
      gettok;	     {consume the operator token}

      ex2 := pterm;  {get the second term}
      ty2 := exprtype;

(* writeln('ex{',ex,'}',ty,' ex2{',ex2,'}',ty2); *)

      {continue adding string params to scat control string}
      if (ex[5] = '(') and (copy(ex,1,4) = 'scat') then
	 add_scat
      else

      {start new scat call if any par is a string}
      if strtype(ty) or strtype(ty2) then
      begin
	 if (ex[1] = '''') or (ex[1] = '"') then
	    ex := 'scat("' + copy(ex,2,length(ex)-2) + '")'
	 else
	    ex := 'scat("%' + ty + '",' + ex + ')';
	 add_scat;
      end
      else
	 ex := ex + ' + ' + ex2;

(* writeln('ex=',ex); *)
   end;

   procedure mulop(newop: string40);
   begin
      if debug_parse then write(' <mulop>');
      gettok;	     {consume the operator token}

      ex2 := pterm;  {get the second term}
      ex := ex + ' ' + newop + ' ' + ex2;
   end;

   procedure andop(newop: char);
   begin
      if debug_parse then write(' <andop>');
      gettok;	     {consume the operator token}

      ex2 := pterm;  {get the second term}
      ty2 := exprtype;

      {boolean and/or?}
      if (ty = 'b') or (ty2 = 'b') then
      begin
	 ex := ex + ' ' + newop + newop + ' ' + ex2;
	 cexprtype := s_bool;
      end
      else  {otherwise bitwise}
	 ex := ex + ' ' + newop + ' ' + ex2;
   end;


begin
   if debug_parse then write(' <expr>');
   ex := pterm;
   ty := exprtype;

   while true do
   begin
      (* process operators *)
	   if tok    = '>='  then relop(tok)
      else if tok    = '<='  then relop(tok)
      else if tok    = '<>'  then relop('!=')
      else if tok[1] = '>'   then relop(tok)
      else if tok[1] = '<'   then relop(tok)
      else if tok[1] = '='   then relop('==')
      else if tok[1] = '+'   then addop
      else if tok[1] = '-'   then mulop(tok)
      else if tok[1] = '*'   then mulop(tok)
      else if tok[1] = '/'   then mulop(tok)
      else if tok[1] = '&'   then mulop(tok)  {mt+}
      else if tok[1] = '!'   then mulop('|')  {mt+}
      else if tok[1] = '|'   then mulop('|')  {mt+}
      else if tok    = 'DIV' then mulop('/')
      else if tok    = 'MOD' then mulop('%')
      else if tok    = 'SHR' then mulop('>>')
      else if tok    = 'SHL' then mulop('<<')
      else if tok    = 'XOR' then mulop('^')
      else if tok    = 'AND' then andop('&')
      else if tok    = 'OR'  then andop('|')
      else

      (* translate the expr IN set operator *)
      if tok = 'IN'  then
      begin
	 gettok;
	 ex := 'inset('+ex+',' + pterm + ')';
      end
      else

      (* ran out of legal expression operators; return what we found *)
      begin
	 pexpr := ex;
	 exit;
      end;
   end;

end;


function plvalue: string;
   {parse and translate an lvalue specification and return the translated
    lvalue as a string}

var
   lv:	     string;
   expr:     string;
   funcid:   string40;
   pref:     string40;
   idok:     boolean;
   sym:      symptr;
   func:     symptr;
   btype:    symtypes;
   cstype:   supertypes;
   bstype:   supertypes;
   pvars:    integer;
   cbase:    integer;
   bbase:    integer;

begin
   if debug_parse then write(' <lvalue>');
   plvalue := 'lvalue';

(* lvalues must begin with an identifier in pascal *)
   if toktype <> identifier then
   begin
      syntax('Identifier expected (plvalue)');
      exit;
   end;

(* assign initial part of the lvalue *)
   idok := false;
   pref := '';
   lv := ltok;
   funcid := tok;
   bstype := ss_scalar;
   bbase := 0;
   cbase := 0;

   sym := cursym;
   if sym <> nil then
   begin
      cstype := sym^.suptype;
      cbase := sym^.base;
      cexprtype := sym^.symtype;
      lv := sym^.repid; 	 {use replacement identifier}

      {dereference VAR paremter pointers}
      if sym^.parcount = -2 then
      begin
	 if debug_parse then write(' <var.deref>');
	 pref := '*';
      end;

      {prefix with pointer if this is a member identifier and a with
       is in effect}
      if (sym^.parcount < 0) and (sym^.pvar > 0) and (withlevel > 0) then
      begin
	 if debug_parse then write(' <with.deref>');
	 pref := 'with'+itoa(withlevel)+'->';
      end;

   end;


(* process a list of qualifiers and modifiers *)
   gettok;

   repeat
      if toktype = identifier then
      begin

	 if cursym <> nil then		     {find record member types}
	 begin
	    sym := cursym;
	    cstype := sym^.suptype;
	    cbase := sym^.base;
	    cexprtype := sym^.symtype;
	    ltok := sym^.repid; 	 {use replacement identifier}
	 end;

      end;

      (* process identifiers (variable or field names) *)
      if idok and (toktype = identifier) then
      begin
	 if debug_parse then write(' <ident>');
	 lv := lv + ltok;
	 gettok;
	 idok := false;
      end
      else

      (* pointers *)
      if tok = '^' then
      begin
	 if debug_parse then write(' <deref>');
	 pref := '*' + pref;
	 gettok;
      end
      else

      (* pointer subscripts *)
      if tok = '^[' then
      begin
	 if debug_parse then write(' <ptr.subs>');
	 lv := lv + '[';
	 gettok;

	 while tok <> ']' do
	 begin
	    lv := lv + pexpr;
	    if tok = ',' then
	    begin
	       lv := lv + '][';
	       gettok;
	    end;
	 end;

	 lv := lv + ']';
	 gettok;
      end
      else

      (* pointer members *)
      if tok = '^.' then
      begin
	 if debug_parse then write(' <ptr.deref>');
	 lv := lv + '->';
	 gettok;
	 idok := true;
      end
      else

      (* record members *)
      if tok = '.' then
      begin
	 if debug_parse then write(' <member>');
	 if pref = '*' then	{translate *id. into id->}
	 begin
	    pref := '';
	    lv := lv + '->';
	 end
	 else
	    lv := lv + '.';
	 idok := true;
	 gettok;
      end
      else

      (* subscripts *)
      if tok[1] = '[' then
      begin
	 if debug_parse then write(' <subs>');
	 btype := cexprtype;
	 bstype := cstype;
	 bbase := cbase;

	 if copy(pref,1,1) = '*' then
	    pref := '';       {replace '*id[' with 'id['}

	 lv := lv + '[';
	 gettok;

	 repeat
	    expr := pexpr;

	    if tok[1] = ',' then
	    begin
	       lv := lv + expr + '][';
	       gettok;
	       bstype := ss_scalar;
	    end;
	 until tok[1] = ']';

	 subtract_base(expr,bbase);
	 lv := lv + expr + ']';

	 if (btype = s_string) and (bstype <> ss_array) then
	 begin
	    btype := s_char;
	    ltok := lv;
	    if expr = '-1' then
	       warning('Dynamic length reference');
	 end;

	 cexprtype := btype;
	 cstype := ss_scalar;
	 cbase := 0;
	 gettok;
      end
      else

      (* function calls *)
      if tok[1] = '(' then
      begin
	 if debug_parse then write(' <func>');
	 func := locatesym(funcid);
	 pvars := 0;
	 if func <> nil then
	 begin
	    pvars := func^.pvar;	  {determine return type}
	    cexprtype := func^.symtype;
	 end;

	 btype := cexprtype;
	 lv := lv + '(';
	 gettok;

	 while tok[1] <> ')' do
	 begin
	    expr := pexpr;
	    if (pvars and 1) = 1 then	  {prefix VAR paremeters}
	       make_pointer(expr);

	    lv := lv + expr;
	    pvars := pvars shr 1;

	    if (tok[1] = ',') or (tok = ':') then
	    begin
	       lv := lv + ',';
	       gettok;
	    end;
	 end;

	 lv := lv + ')';
	 gettok;
	 cexprtype := btype;
      end
      else

(* otherwise just return what was found so far *)
      begin

	 (* add dummy param list to function calls where the proc
	    expects no parameters *)
	 if sym <> nil then
	 begin
	    if (not iscall(lv)) and (sym^.parcount >= 0) then
	       lv := lv + '()';
	 end;

	 plvalue := pref + lv;
	 exit;
      end;

   until recovery;

   plvalue := pref + lv;
end;

