(********************************************************************)
(*
 * process generic declaration section
 *   dispatches to const, type, var, proc, func
 *   enter with tok=section type
 *   exit with tok=next section type
 *
 *)

procedure psection;
begin
   if recovery then
   begin
      while toktype <> keyword do
	 gettok;
      {warning('Error recovery (psection)');}
      recovery := false;
   end;

   if debug_parse then write(' <section>');

   if (tok = 'EXTERNAL')  or (tok = 'OVERLAY') or
      (tok = 'PROCEDURE') or (tok = 'FUNCTION') then
      punit
   else

   if tok = 'INTERFACE' then
      pinterface
   else

   if tok = 'IMPLEMENTATION' then
      pimplementation
   else

   if tok = 'USES' then
   begin
      puses;
      if tok[1] = ';' then
	 gettok;
   end
   else

   if tok = 'UNIT' then
      comment_statement
   else

   if tok = 'CONST' then
      pconst
   else

   if tok = 'TYPE' then
      ptype
   else

   if tok = 'VAR' then
      pvar
   else

   if tok = 'LABEL' then
      plabel
   else

   if tok[1] = '{' then
      pblock
   else

   if (tok[1] = '.') or (tok[1] = '}') then
   begin
      tok := '.';
      exit;
   end
   else
      syntax('Section header expected (psection)');
end;


(********************************************************************)
(*
 * process argument declarations to
 *    program, procedure, function
 *
 * enter with header as tok
 * exits with tok as ; or :
 *
 *)

const
   extern = true;

procedure punitheader(is_external: boolean);
var
   proc:    string40;
   proclit: string40;
   vars:    paramlist;
   types:   paramlist;
   bases:   array [1..maxparam] of integer;
   i:	    integer;
   ii:	    integer;
   rtype:   string40;
   varval:  integer;
   varon:   boolean;
   locvar:  integer;
   iptr:    integer;

begin
   gettok;		   {skip unit type}
   proclit := ltok;

   if (unitlevel > 1) and (not in_interface) then
   begin
      {make name unique if it clashes with an existing global}
      if cursym = nil then
	 proc := proclit
      else
	 proc := procnum + '_' + proclit;

      warning('Nested function');

      writeln(ofd[unitlevel-1],^M^J'   /* Nested function: ',proc,' */ ');
      inc(objtotal,2);
   end
   else
      proc := proclit;

   gettok;		   {skip unit identifier}

   vars.n := 0;
   varval := 0;       { 0 bit means value, 1 = var }
   varon  := false;

   (* process param list, if any *)
   if tok[1] = '(' then
   begin
      gettok;

      while (tok[1] <> ')') and not recovery do
      begin

	 ii := vars.n + 1;
	 repeat
	    if tok[1] = ',' then
	       gettok;

	    if tok = 'VAR' then
	    begin
	       gettok;
	       varon := true;
	    end;

	    inc(vars.n);
	    if vars.n > maxparam then
	       fatal('Too many params (punitheader)');
	    vars.id[vars.n] := ltok;
	    gettok;

	 until tok[1] <> ',';

	 if tok[1] = ':' then
	 begin
	    gettok;   {consume the :}

	    {parse the param type}
	    rtype := psimpletype;
	 end
	 else

	 begin	  {untyped variable if ':' is missing}
	    rtype := 'void';
	    curtype := s_void;
	    curbase := 0;
	    cursuptype := ss_scalar; {ss_array?}
	 end;

	 {assign and param types, converting 'var' and 'array' params}
	 iptr := 0;
	 if rtype[1] = '^' then
	    rtype[1] := '*';

	 {flag var parameters; strings and arrays are implicitly var in C}
	 if varon and (curtype <> s_string) and (cursuptype <> ss_array) then
	    iptr := 1 shl (ii - 1);

	 if curtype = s_string then
	    rtype := 'char *'
	 else
	 if cursuptype = ss_array then
	    rtype := typename[curtype] + ' *';

	 {assign data types for each ident}
	 for i := ii to vars.n do
	 begin
	    types.id[i] := rtype;
	    types.stype[i] := curtype;
	    types.sstype[i] := cursuptype;
	    bases[i] := curbase;
	    varval := varval or iptr;
	    iptr := iptr shl 1;
	 end;

	 if tok[1] = ';' then
	 begin
	    gettok;
	    varon := false;
	 end;

      end;   {) seen}

      gettok;	{consume the )}
   end;

   (* process function return type, if any *)
   if tok[1] = ':' then
   begin
      gettok;		 {consume the :}
      rtype := psimpletype;

      if curtype = s_string then
	 rtype := 'char *'
      else
      if cursuptype = ss_array then
	 rtype := typename[curtype] + ' *';
   end
   else

   begin
      rtype := 'void';
      curtype := s_void;
   end;

   putline;

   (* prefix procedure decl's when external *)
   if is_external then
   begin
      putln(ljust('extern '+rtype,identlen)+proc+'();');
      addsym(globals,proc,curtype,ss_func,0,varval,0,9,false);
      exit;
   end;


   (* process 'as NEWNAME' clause, if present (tptc extention to specify
      the replacement name in the symbol table *)
   if tok = 'AS' then
   begin
      gettok;
      proc := usetok;
   end;


   (* output the return type, proc name, formal param list *)
   if in_interface then
      rtype := 'extern '+rtype;
   puts(ljust(rtype,identlen)+proc+'(');

   if vars.n = 0 then
      puts('void');


   (* output the formal param declarations *)
   locvar := varval;
   for i := 1 to vars.n do
   begin
      iptr := -1;

      if (locvar and 1) = 1 then
      begin
	 iptr := -2;
	 types.id[i] := types.id[i] + ' *';
      end;

      puts(ljust(types.id[i],identlen)+vars.id[i]);
      addsym(locals,vars.id[i],types.stype[i],ss_scalar,iptr,0,0,bases[i],true);
      locvar := locvar shr 1;

      if i < vars.n then
      begin
	 putln(',');
	 puts(ljust('',identlen+length(proc)+1));
      end;
   end;

   puts(')');
   nospace := false;

   {enter the procedure in the global symbol table}
   addsym(globals,proclit,curtype,ss_func,vars.n,varval,0,0,false);
   cursym^.repid := proc;
end;


(********************************************************************)
(*
 * process body of program unit
 *   handles all declaration sections
 *   and a single begin...end
 *   recursively handles procedure declarations
 *   ends with tok=}
 *)

procedure punitbody;
begin
   gettok;

   if tok = 'INTERRUPT' then
   begin
      warning('Interrupt handler');
      gettok;
   end;

   if tok = 'FORWARD' then
   begin
      puts(';');
      gettok;
   end
   else

   if tok = 'EXTERNAL' then
   begin
      puts('/* ');
      repeat
	 puttok;
	 gettok;
      until tok[1] = ';';
      puts(' */ ;');
   end
   else

   if tok = 'INLINE' then
   begin
      newline;
      putln('{');
      puts('   ');
      pinline;
      putln('}');
   end
   else

   begin
      puts('{ ');

      repeat
	 if tok[1] = ';' then
	 begin
	    puttok;
	    gettok;
	 end;

	 if tok[1] <> '{' then
	    psection;
      until tok[1] = '{';

      gettok;		      {get first token of first statement}

      while (tok[1] <> '}') and not recovery do
      begin
	 pstatement;		 {process the statement}

	 if tok[1] = ';' then
	 begin
	    puttok;
	    gettok;		 {get first token of next statement}
	 end;
      end;

      puttok;
   end;
end;


(********************************************************************)
procedure enter_procdef;
   {increase output file level and direct output to the new file}
var
   nam:  anystring;
begin
   {increment this procedure number}
   inc(procnum[2]);
   if procnum[2] > 'Z' then
   begin
      inc(procnum[1]);
      procnum[2] := 'A';
   end;

   inc(unitlevel);
   if unitlevel > maxnest then
      fatal('Functions nested too deeply');

   str(unitlevel,nam);
   nam := workdir + nestfile + nam;

   assign(ofd[unitlevel],nam);
   {$i-} rewrite(ofd[unitlevel]); {$i+}

   if ioresult <> 0 then
   begin
      dec(unitlevel);
      ltok := nam;
      fatal('Can''t create tempfile');
   end;

   if maxavail-300 <= inbufsiz then
   begin
      ltok := nam;
      fatal('Out of memory');
   end;

   getmem(outbuf[unitlevel],inbufsiz);
   SetTextBuf(ofd[unitlevel],outbuf[unitlevel]^,inbufsiz);
end;


(********************************************************************)
procedure exit_procdef;
   {copy the outer output file to the next lower level output
    and reduce output level by 1}
var
   line:  string;

begin
   if unitlevel < 1 then
      exit;

   close(ofd[unitlevel]);
   reset(ofd[unitlevel]);
   SetTextBuf(ofd[unitlevel],outbuf[unitlevel]^,inbufsiz);

   while not eof(ofd[unitlevel]) do
   begin
      readln(ofd[unitlevel],line);
      writeln(ofd[0],line);
   end;

   close(ofd[unitlevel]);
   erase(ofd[unitlevel]);
   freemem(outbuf[unitlevel],inbufsiz);
   dec(unitlevel);
end;


(********************************************************************)
(*
 * process program, procedure and function declaration
 *
 * enter with tok=function
 * exit with tok=;
 *
 *)

procedure punit;
var
   top: symptr;
begin
   if debug_parse then write(' <unit>');

   nospace := true;
   top := locals;

   if (tok = 'OVERLAY') then
      gettok;

   if (tok = 'EXTERNAL') then  {mt+}
   begin
      gettok;	   {consume the EXTERNAL}

      if tok[1] = '[' then
      begin
	 gettok;   {consume the '['}

	 puts('/* overlay '+ltok+' */ ');
	 gettok;   {consume the overlay number}

	 gettok;   {consume the ']'}
      end;

      punitheader(extern);
      if tok[1] = ';' then
	 gettok;
      purgetable(locals,top);
   end
   else

   if in_interface then
   begin
      nospace := false;
      punitheader(not extern);

      puts(';');
      if tok[1] = ';' then
	 gettok;

      if tok = 'INLINE' then
      begin
	 pinline;
	 warning('Inline procedure');
      end;

      purgetable(locals,top);
   end
   else

   begin
      {enter a (possibly nested) procedure}
      enter_procdef;

      punitheader(not extern);
      punitbody;
      gettok;
      if tok[1] = ';' then
	 gettok;
      purgetable(locals,top);

      {exit the (possibly nested) procedure, append text to toplevel outfile}
      exit_procdef;
   end;

end;



(********************************************************************)
(*
 * process main program
 *
 *  expects program head
 *  optional declarations
 *  block of main code
 *  .
 *
 *)

procedure pprogram;
begin
{   putline;}
{   putln('#include <stdio.h>');}
   putln('//#include "tptcmac.h"');

   getchar;  {get first char}
   gettok;   {get first token}

   if (tok = 'PROGRAM') or (tok = 'UNIT') then
   begin
      comment_statement;
      gettok;
   end;

   if tok = 'MODULE' then
   begin
      mt_plus := true;	 {shift into pascal/mt+ mode}
      comment_statement;
      gettok;
   end;

   repeat
      if tok[1] = ';' then
      begin
	 puttok;
	 gettok;
      end;

      if tok = 'MODEND' then
	 exit;

      if (tok[1] <> '{') then
	 psection;
   until (tok[1] = '{') or (tok[1] = '.') or recovery;

   {process the main block, if any}
   if tok[1] = '{' then
   begin
      putline;
      putln('void main()');
      puttok;
      gettok;		      {get first token of main block}
      while (tok[1] <> '}') and (tok[1] <> '.') do
      begin
	 pstatement;		    {process the statement}

	 if tok[1] = ';' then
	 begin
	    puttok;
	    gettok;		 {get first token of next statement}
	 end;
      end;

      putln('}');
   end;

   putline;
end;