(********************************************************************)
(*
 * process pascal data type specifications
 *
 *)

function psimpletype: string80;
   {parse a simple (single keyword and predefined) type; returns the
    translated type specification; sets the current data type}
var
   sym: symptr;

begin
   if debug_parse then write(' <simpletype>');

   sym := locatesym(ltok);
   if sym <> nil then
   begin
      curtype := sym^.symtype;
      if cursuptype = ss_none then
	 cursuptype := sym^.suptype;
      curlimit := sym^.limit;
      curbase := sym^.base;
      curpars := sym^.parcount;
   end;

   psimpletype := usetok;
end;


(********************************************************************)
procedure pdatatype(stoclass: anystring;
		    var vars: paramlist;
		    prefix:   anystring;
		    suffix:   anystring;
		    addsemi:  boolean);
   {parse any full data type specification;  input is a list of variables
    to be declared with this data type; stoclass is a storage class prefix
    (usually 'static ', '', 'typedef ', or 'extern '.  prefix and suffix
    are variable name modifiers used in pointer and subscript translations;
    recursive for complex data types}

const
   forward_typedef: anystring = '';
   forward_undef:   anystring = '';

var
   i:	   integer;
   ts:	   anystring;
   ex:	   anystring;
   sym:    symptr;
   nbase:  integer;
   bbase:  integer;
   nsuper: supertypes;

   procedure pvarlist;
   var
      i:    integer;
      pcnt: integer;

   begin
      ts := '';
      pcnt := -1;

      if tok = 'ABSOLUTE' then
      begin
	 if debug_parse then write(' <abs>');
	 gettok;	{consume the ABSOLUTE}
	 ts := pexpr;	{get the absolute lvalue}

	 if tok[1] = ':' then	 {absolute addressing}
	 begin
	    gettok;
	    ts := ' = MK_FP('+ts+','+pexpr+')';
	 end

	 else		      {variable aliasing}
	 begin
	    if ts[1] = '*' then
	       ts := ' = ' + copy(ts,2,255)
	    else
	       ts := ' = &(' + ts + ')';
	 end;

	 {convert new variable into a pointer if needed}
	 if length(prefix) = 0 then
	    prefix := '*';

	 {force automatic pointer dereference in expressions}
	 pcnt := -2;
      end;

      if cursuptype = ss_none then
	 cursuptype := ss_scalar;

      for i := 1 to vars.n do
      begin
	 newsym(vars.id[i],curtype,cursuptype,pcnt,withlevel,curlimit,nbase);
	 puts(prefix+vars.id[i]+suffix+ts);
	 if i < vars.n then
	    puts(', ');
      end;
   end;


   procedure parray;
   begin
      if debug_parse then write(' <array>');
      gettok;	  {consume the ARRAY}

      repeat
	 gettok;	{consume the [ or ,}

	 ts := pexpr;	{consume the lower subscript expression}
	 if isnumber(ts) then
	    nbase := atoi(ts)
	 else
	    nbase := curbase;

	 if tok = '..' then
	 begin
	    gettok;   {consume the ..}
	    ts := pexpr;

	    subtract_base(ts,nbase-1);
	 end
	 else

	 begin	  {subscript by typename - look up type range}
	    sym := locatesym(ts);
	    if sym <> nil then
	    begin
	       nbase := sym^.base;
	       if (sym^.limit > 0) and (sym^.suptype <> ss_const) then
		  ts := ' /* ' + ts + ' */ ' + itoa(sym^.limit-nbase+1);
	    end;
	 end;

	 suffix := suffix + '[' + ts + ']';

      until tok[1] <> ',';

      gettok;	  {consume the ]}
      gettok;	  {consume the OF}

      cursuptype := ss_array;
   end;


   procedure pstring;
   begin
      if debug_parse then write(' <string>');
      gettok;	  {consume the STRING}

      if tok[1] = '[' then
      begin
	 gettok;     {consume the [}

	 nsuper := cursuptype;
	 ts := pexpr;
	 cursuptype := nsuper;
	 subtract_base(ts,-1);		  {increment string size by one}
	 suffix := suffix + '[' + ts + ']';

	 gettok;     {consume the ]}
      end
      else
	 suffix := suffix + '[STRSIZ]';

      puts(ljust(stoclass+'char',identlen));
      curtype := s_string;
      nbase := 1;
      pvarlist;
   end;


   procedure ptext;
   begin
      if debug_parse then write(' <text>');
      gettok;	  {consume the TEXT}

      if tok[1] = '[' then
      begin
	 gettok;     {consume the [}
	 nsuper := cursuptype;
	 ts := pexpr;
	 cursuptype := nsuper;
	 gettok;     {consume the ]}
      end;

      puts(ljust(stoclass+'text',identlen));
      curtype := s_file;
      pvarlist;
   end;


   procedure pfile;
   begin
      if debug_parse then write(' <file>');
      gettok;	  {consume the FILE}

      if tok = 'OF' then
      begin
	 gettok;     {consume the OF}
	 ts := tok;
	 gettok;     {consume the recordtype}
	 ts := '/* file of '+ts+' */ ';
      end
      else
	 ts := '/* untyped file */ ';

      puts(ljust(stoclass+'int',identlen)+ts);
      curtype := s_file;
      pvarlist;
   end;


   procedure pset;
   begin
      if debug_parse then write(' <set>');
      gettok;	  {consume the SET}
      gettok;	  {consume the OF}

      ts := '/* ';
      if toktype = identifier then
	 ts := ts + usetok
      else

      if tok = '(' then
      begin
	 repeat
	    ts := ts + usetok
	 until (tok[1] = ')') or recovery;
	 ts := ts + usetok;
      end

      else
	 ts := ts + psetof;

      puts(ljust(stoclass+'setrec',identlen)+ts+' */ ');
      curtype := s_struct;
      pvarlist;
   end;


   procedure pvariant;
   begin
      if debug_parse then write(' <variant>');
      gettok;	  {consume the CASE}

      ts := ltok;
      gettok;	  {consume the selector identifier}

      if tok[1] = ':' then
      begin
	 gettok;     {consume the :}
	 puts(ltok+' '+ts+ ';  /* Selector */');
	 gettok;     {consume the selector type}
      end
      else
	 puts(' /* Selector is '+ts+' */');

      gettok;
      puts('union { ');
      newline;

      while (tok <> '}') and not recovery do
      begin
	 ts := pexpr;	   {parse the selector constant}
	 while tok[1] = ',' do
	 begin
	    gettok;
	    ts := pexpr;
	 end;

	 gettok;    {consume the :}

	 puts(' struct {  ');

	 ts := 's' + ts;
	 decl_prefix := 'v.'+ts+'.';
	 pvar;
	 decl_prefix := '';

	 gettok;    {consume the ')'}

	 puts(' } '+ts+';');

	 {arrange for reference translation}
	 newsym(ts,s_void,ss_struct,-1,0,0,0);
	 cursym^.repid := ts;

	 if tok[1] = ';' then
	    gettok;
      end;

      puts(' } v;');
      newline;
   end;


   procedure precord;
   begin
      if debug_parse then write(' <record>');
      puts(stoclass+'struct '+vars.id[1]+' { ');

      inc(withlevel);
      pvar;	{process each record member}

      if tok = 'CASE' then    {process the variant part, if any}
	 pvariant;
      dec(withlevel);

      puttok;	{output the closing brace}
      gettok;	{and consume it}

      curtype := s_struct;
      cursuptype := ss_struct;
      pvarlist; {output any variables of this record type}

      {convert a #define into a typedef in case of a forward pointer decl}
      if length(forward_typedef) > 0 then
      begin
	 puts(';');
	 newline;
	 puts(forward_undef);
	 newline;
	 puts(forward_typedef);
	 forward_typedef := '';
      end;
   end;


   procedure penum;
   var
      members: integer;

   begin
      if debug_parse then write(' <enum>');
      puts(stoclass+'enum {  ');

      gettok;
      members := 0;
      repeat
	 puts(ltok);
	 if toktype = identifier then
	    inc(members);
	 gettok;
      until (tok[1] = ')') or recovery;

      puts(' } ');
      gettok;	{consume the )}

      curtype := s_int;
      curlimit := members-1;
      nbase := 0;
      pvarlist;
   end;


   procedure pintrange;
   begin
      if debug_parse then write(' <int.range>');
      ex := pexpr;   {consume the lower limit expression}
      nbase := atoi(ex);

      if tok <> '..' then
      begin
	 syntax('".." expected');
	 exit;
      end;

      gettok;	     {consume the ..}
      ts := pexpr;   {consume the number}

      sym := locatesym(ts);
      if sym <> nil then
	 if sym^.limit > 0 then
	    ts := itoa(sym^.limit);

      curtype := s_int;
      curlimit := atoi(ts);
      puts(ljust(stoclass+'int',identlen)+'/* '+ex+'..'+ts+' */ ');
      pvarlist;
   end;

   procedure pcharrange;
   begin
      if debug_parse then write(' <char.range>');
      ex := pexpr;   {consume the lower limit expression}
      nbase := ord(ex[2]);

      if tok <> '..' then
      begin
	 syntax('".." expected');
	 exit;
      end;

      gettok;	     {consume the ..}
      ts := pexpr;   {consume the number}

      sym := locatesym(ts);
      if sym <> nil then
	 if sym^.limit > 0 then
	    ts := itoa(sym^.limit);

      curtype := s_char;
      curlimit := ord(ts[2]);
      puts(ljust(stoclass+'char',identlen)+'/* '+ex+'..'+ts+' */ ');
      pvarlist;
   end;

   procedure psimple;
   begin
      ex := psimpletype;
      if cursuptype <> ss_array then
	 nbase := curbase;

      if tok =	'..' then
      begin
	 if debug_parse then write(' <range>');
	 gettok;	{consume the ..}
	 ts := pexpr;	{consume the high limit}

	 sym := locatesym(ts);
	 if sym <> nil then
	    if sym^.limit > 0 then
	       ts := itoa(sym^.limit);

	 curtype := s_int;
	 curlimit := curbase;
	 puts(ljust(stoclass+'int',identlen)+'/* '+ex+'..'+ex+' */ ');
	 pvarlist;
	 exit;
      end;

      {pointer to simpletype?}
      i := pos('^',ex);
      if i <> 0 then
      begin
	 if debug_parse then write(' <pointer>');
	 delete(ex,i,1);
	 prefix := '*';
	 cursuptype := ss_pointer;
      end;

      sym := locatesym(ex);

      {potential forward pointer reference?}
      if (stoclass = 'typedef ') and (vars.n = 1) and
	 (prefix = '*') and (sym = nil) then
      begin
	 if debug_parse then write(' <forward>');
	 newsym(vars.id[1],curtype,cursuptype,-1,0,curlimit,0);
	 puts('#define '+vars.id[1]+'struct '+ex+' *');
	 forward_undef := '#undef '+vars.id[1];
	 forward_typedef := 'typedef struct '+ex+' *'+vars.id[1];
	 addsemi := false;
      end
      else

      {ordinary simple types}
      begin
	 if debug_parse then write(' <simple>');
	 puts(ljust(stoclass+ex,identlen));
	 pvarlist;
      end;
   end;

begin
   cursuptype := ss_none;
   curlimit := 0;
   nbase := 0;

   if tok = 'EXTERNAL' then
   begin
      gettok;	  {consume the EXTERNAL}
      stoclass := 'extern '+stoclass;
   end;

   if tok = 'PACKED' then
      gettok;
   while tok = 'ARRAY' do
      parray;
   if tok = 'PACKED' then
      gettok;

   if tok = 'STRING'	    then pstring
   else if tok = 'TEXT'     then ptext
   else if tok = 'FILE'     then pfile
   else if tok = 'SET'	    then pset
   else if tok = '('	    then penum
   else if tok = 'RECORD'   then precord
   else if toktype = number then pintrange
   else if toktype = chars  then pcharrange
   else psimple;

   if addsemi then
      puts(';');
   puts(' ');

   if tok[1] = ';' then
      gettok;
end;


(********************************************************************)
(*
 * declaration keyword processors
 *   const, type, var, label
 *
 * all enter with tok=section type
 * exit with tok=new section or begin or proc or func
 *
 *)

procedure pconst;
   {parse and translate a constant section}
var
   vars:    paramlist;
   parlev:  integer;
   exp:     string;
   dup:     boolean;

begin
   if debug_parse then write(' <const>');
   gettok;

   while (toktype <> keyword) and not recovery do
   begin
      nospace := false;
      vars.n := 1;
      vars.id[1] := ltok;

      gettok;	 {consume the id}

      if tok[1] = '=' then     {untyped constant}
      begin
	 if debug_parse then write(' <untyped.const>');

	 {$b-} {requires short-circuit evaluation}
	 dup := (unitlevel > 0) and (cursym <> nil) and
		(cursym^.suptype = ss_const);

	 gettok;   {consume the =}

	 exp := pexpr;
	 curtype := cexprtype;
	 if isnumber(exp) then
	    curlimit := atoi(exp);

	 {prefix identifier if needed to prevent conflict with other defines}
	 newsym(vars.id[1],curtype,ss_const,-1,0,curlimit,0);
	 if dup then
	 begin
	    vars.id[1] := procnum + '_' + vars.id[1];
	    cursym^.repid := vars.id[1];
	 end;

	 puts('#define '+vars.id[1]);
	 puts(exp);
	 puts('  ');

	 gettok;   {consume the ;}
      end
      else

      begin		  {typed constants}
	 if debug_parse then write(' <typed.const>');

	 gettok;   {consume the :}

	 pdatatype('',vars,'','',false);

	 if tok[1] <> '=' then
	 begin
	    syntax('"=" expected');
	    exit;
	 end;

	 gettok;   {consume the =}

	 puts(' = ');
	 parlev := 0;

	 repeat
	    if tok[1] = '[' then
	    begin
	       gettok;
	       exp := psetof;
	       gettok;
	       puts(exp);
	    end
	    else

	    if tok[1] = '(' then
	    begin
	       inc(parlev);
	       puts('{');
	       gettok;
	    end
	    else

	    if tok[1] = ')' then
	    begin
	       dec(parlev);
	       puts('}');
	       gettok;
	    end
	    else

	    if tok[1] = ',' then
	    begin
	       puttok;
	       gettok;
	    end
	    else

	    if (parlev > 0) and (tok[1] = ';') then
	    begin
	       puts(',');
	       gettok;
	    end
	    else

	    if tok[1] <> ';' then
	    begin
	       exp := pexpr;
	       if tok[1] = ':' then
		  gettok   {discard 'member-identifier :'}
	       else
		  puts(exp);
	    end;

	 until ((parlev = 0) and (tok[1] = ';')) or recovery;

	 puttok;      {output the final ;}
	 gettok;
      end;
   end;
end;


(********************************************************************)
procedure ptype;
   {parse and translate a type section}
var
   vars: paramlist;

begin
   if debug_parse then write(' <type>');
   gettok;

   while (toktype <> keyword) do
   begin
      vars.n := 1;
      vars.id[1] := usetok;

      if tok = '=' then
	 gettok
      else
      begin
	 syntax('"=" expected');
	 exit;
      end;

      nospace := false;
      pdatatype('typedef ',vars,'','',true);
   end;

end;


(********************************************************************)
procedure pvar;
   {parse and translate a variable section}
var
   vars:  paramlist;
   sto:   string20;
begin
   if debug_parse then write(' <var>');

   if in_interface and (withlevel = 0) then
      sto := 'extern '
   else
      sto := '';

   vars.n := 0;
   gettok;

   while (toktype <> keyword) and (tok[1] <> '}') and (tok[1] <> ')') do
   begin
      nospace := true;

      repeat
	 if tok[1] = ',' then
	    gettok;

	 inc(vars.n);
	 if vars.n > maxparam then
	    fatal('Too many identifiers (pvar)');
	 vars.id[vars.n] := ltok;
	 gettok;
      until tok[1] <> ',';

      if tok[1] <> ':' then
      begin
	 syntax('":" expected');
	 exit;
      end;

      gettok;	{consume the :}
      nospace := false;
      pdatatype(sto,vars,'','',true);
      vars.n := 0;
   end;
end;


