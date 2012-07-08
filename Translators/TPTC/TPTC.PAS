{ * TPTC - Turbo Pascal to C translator * }
{   S.H.Smith, 9/9/85  (rev. 2/13/88)	}
{$T+}	 {Produce mapfile}
{$R-}	 {Range checking}
{$B-}	 {Boolean complete evaluation}
{$S-}	 {Stack checking}
{$I+}	 {I/O checking}
{$N-}	 {Numeric coprocessor}
{$V-}	 {Relax string rules}
{$M 65500,16384,655360} {stack, minheap, maxhep}

uses Dos;
const
   version1 =	  'TPTC - Translate Pascal to C 			(C) 1988 S.H.Smith';
   version2 =	  'Version 1.8: modified by M.Roman .*2000*';
   minstack =	  4000;       {minimum free stack space needed}
   outbufsiz =	  10000;      {size of top level output file buffer}
   inbufsiz =	  2000;       {size of input file buffers}
   maxparam =	  16;	      {max number of parameters to process}
   maxnest =	  10;	      {maximum procedure nesting-1}
   maxincl =	  2;	      {maximum source file nesting-1}
   statrate =	  5;	      {clock ticks between status displays}
   ticks_per_second = 18.2;
const
   nestfile =	  'p$';       {scratchfile for nested procedures}
type
   anystring =	  string [127];
   string255 =	  string [255];
   string80  =	  string [80];
   string64  =	  string [64];
   string40  =	  string [40];
   string20  =	  string [20];
   string10  =	  string [10];
(* command options *)
const
   debug:	  boolean = false;   {-B   trace scan}
   debug_parse:   boolean = false;   {-BP  trace parse}
   mt_plus:	  boolean = false;   {-M   true if translating Pascal/MT+}
   map_lower:	  boolean = false;   {-L   true to map idents to lower case}
   dumpsymbols:   boolean = false;   {-D   dump tables to object file}
   dumppredef:	  boolean = false;   {-DP  dump predefined system symbols}
   includeinclude:boolean = false;   {-I   include include files in output}
   quietmode:	  boolean = false;   {-Q   disable warnings?}
   identlen:	  integer = 13;      {-Tnn nominal length of identifiers}
   workdir:	  string64 = '';     {-Wd: work/scratch file directory}
   tshell:	  boolean = false;   {-#   pass lines starting with '#'}
   pass_comments: boolean = true;    {-NC  no comments in output}
type
   toktypes =	  (number,	identifier,
		   strng,	keyword,
		   chars,	comment,
		   unknown);

   symtypes =	  (s_int,	s_long,
		   s_double,	s_string,
		   s_char,	s_struct,
		   s_file,	s_bool,
		   s_void		 );

   supertypes =   (ss_scalar,	ss_const,
		   ss_func,	ss_struct,
		   ss_array,	ss_pointer,
		   ss_builtin,	ss_none  );

   symptr =	 ^symrec;
   symrec =	  record
		     symtype:  symtypes;	{ simple type }
		     suptype:  supertypes;	{ scalar,array etc. }
		     id:       string40;	{ name of entry }
		     repid:    string40;	{ replacement ident }
		     parcount: integer; 	{ parameter count,
						  >=0 -- procedure/func pars
						  >=1 -- array level
						   -1 -- simple variable
						   -2 -- implicit deref var }
		     pvar:     word;		{ var/val reference bitmap, or
						  structure member nest level }
		     base:     integer; 	{ base value for subscripts }
		     limit:    word;		{ limiting value for scalars }
		     next:     symptr;		{ link to next symbol in table }
		  end;
   paramlist =	  record
		     n:      integer;
		     id:     array [1..maxparam] of string80;
		     stype:  array [1..maxparam] of symtypes;
		     sstype: array [1..maxparam] of supertypes;
		  end;
const
   (* names of symbol types *)
   typename:  array[symtypes] of string40 =
		  ('int',	'long',
		   'double',	'strptr',
		   'char',	'struct',
		   'file',	'boolean',
		   'void' );

   supertypename:  array[supertypes] of string40 =
		  ('scalar',	'constant',
		   'function',	'structure',
		   'array',	'pointer',
		   'builtin',	'none' );


   (* these words start new statements or program sections *)
   nkeywords = 14;
   keywords:  array[1..nkeywords] of string40 = (
      'PROGRAM',   'PROCEDURE', 'FUNCTION',
      'VAR',	   'CONST',	'TYPE',
      'LABEL',	   'OVERLAY',	'FORWARD',
      'MODULE',    'EXTERNAL',	'CASE',
      'INTERFACE', 'IMPLEMENTATION');
type
   byteptr =	  ^byte;
var
   inbuf:	  array [0..maxincl] of byteptr;
   srcfd:	  array [0..maxincl] of text;
   srclines:	  array [0..maxincl] of integer;
   srcfiles:	  array [0..maxincl] of string64;
   outbuf:	  array [0..maxnest] of byteptr;
   ofd: 	  array [0..maxnest] of text;
   inname:	  string64;	    {source filename}
   outname:	  string64;	    {output filename}
   unitname:	  string64;	    {output filename without extention}
   symdir:	  string64;	    {.UNS symbol search directory}
   ltok:	  string80;	    {lower/upper current token}
   tok: 	  string80;	    {all upper case current token}
   ptok:	  string80;	    {previous token}
   spaces:	  anystring;	    {leading spaces on current line}
   decl_prefix:   anystring;	    {declaration identifier prefix, if any}
const
   starttime:	  longint     = 0;	{time translation was started}
   curtime:	  longint     = 0;	{current time}
   statustime:	  longint     = 0;	{time of last status display}
   nextc:	  char	      = ' ';
   toktype:	  toktypes    = unknown;
   ptoktype:	  toktypes    = unknown;
   linestart:	  boolean     = true;
   extradot:	  boolean     = false;
   nospace:	  boolean     = false;
   cursym:	  symptr      = nil;
   curtype:	  symtypes    = s_void;
   cexprtype:	  symtypes    = s_void;
   cursuptype:	  supertypes  = ss_scalar;
   curlimit:	  integer     = 0;
   curbase:	  integer     = 0;
   curpars:	  integer     = 0;
   withlevel:	  integer     = 0;
   unitlevel:	  integer     = 0;
   srclevel:	  integer     = 0;
   srctotal:	  integer     = 1;
   objtotal:	  integer     = 0;
   procnum:	  string[2]   = 'AA';
   recovery:	  boolean     = false;
   in_interface:  boolean     = false;
   top_interface: symptr      = nil;
   globals:	  symptr      = nil;
   locals:	  symptr      = nil;
(* nonspecific library includes *)
{$I ljust.inc}	   {left justify writeln strings}
{$I atoi.inc}	   {ascii to integer conversion}
{$I itoa.inc}	   {integer to ascii conversion}
{$I ftoa.inc}	   {float to ascii conversion}
{$I stoupper.inc}  {map string to upper case}
{$I keypress.inc}  {msdos versions of keypressed and readkey}
{$I getenv.inc}    {get environment variables}
procedure fatal  (message:  string);	  forward;
procedure warning  (message:  string);	  forward;
procedure scan_tok;			  forward;
procedure gettok;			  forward;
procedure puttok;			  forward;
procedure putline;			  forward;
procedure puts(s: string);		  forward;
procedure putln(s: string);		  forward;
function  plvalue: string;		  forward;
function  pexpr:   string;		  forward;
procedure exit_procdef; 		  forward;
procedure pblock;			  forward;
procedure pstatement;			  forward;
procedure pimplementation;		  forward;
procedure punit;			  forward;
procedure pvar; 			  forward;
procedure pident;			  forward;
(********************************************************************)
{$I tpcsym.inc} 	 {symbol table handler}
{$I tpcmisc.inc}	 {misc functions}
{$I tpcscan.inc}	 {scanner; lexical analysis}
{$I tpcexpr.inc}	 {expression parser and translator}
{$I tpcstmt.inc}	 {statement parser and translator}
{$I tpcdecl.inc}	 {declaration parser and translator}
{$I tpcunit.inc}	 {program unit parser and translator}
(********************************************************************)
procedure initialize;
   {initializations before translation can begin}
   procedure enter(name: anystring; etype: symtypes; elimit: integer);
   begin
      newsym(name, etype, ss_scalar, -1, 0, elimit, 0);
   end;
begin
   srclines[srclevel] := 1;
   srcfiles[srclevel] := inname;
   assign(srcfd[srclevel],inname);
   {$I-} reset(srcfd[srclevel]); {$I+}
   if ioresult <> 0 then
   begin
      writeln('Can''t open input file: ',inname);
      halt(88);
   end;
   getmem(inbuf[srclevel],inbufsiz);
   SetTextBuf(srcfd[srclevel],inbuf[srclevel]^,inbufsiz);
   assign(ofd[unitlevel],outname);
{$I-}
   rewrite(ofd[unitlevel]);
{$I+}
   if ioresult <> 0 then
   begin
      writeln('Can''t open output file: ',outname);
      halt(88);
   end;
   getmem(outbuf[unitlevel],outbufsiz);
   SetTextBuf(ofd[unitlevel],outbuf[unitlevel]^,outbufsiz);
   mark_time(starttime);
   {enter predefined types into symbol table}
   enter('boolean',    s_bool,1);
   enter('integer',    s_int,maxint);
   enter('word',       s_int,0);
   enter('longint',    s_long,0);
   enter('real',       s_double,0);
   enter('char',       s_char,255);
   enter('byte',       s_int,255);
   enter('file',       s_file,0);
   enter('text',       s_file,0);
   enter('true',       s_bool,1);
   enter('false',      s_bool,1);
   newsym('string',    s_string, ss_scalar,    -1, 0, 0, 1);
   newsym('not',       s_int,	 ss_builtin,	0, 0, 0, 0);

   {enter predefined functions into symbol table}
   newsym('chr',       s_char,	 ss_builtin,	1, 0, 0, 0);
   newsym('pos',       s_int,	 ss_builtin,	2, 0, 0, 0);
   newsym('str',       s_void,	 ss_builtin,	2, 0, 0, 0);
   newsym('port',      s_int,	 ss_builtin,	1, 0, 0, 0);
   newsym('portw',     s_int,	 ss_builtin,	1, 0, 0, 0);
   newsym('mem',       s_int,	 ss_builtin,	2, 0, 0, 0);
   newsym('memw',      s_int,	 ss_builtin,	2, 0, 0, 0);
   newsym('exit',      s_void,	 ss_builtin,	1, 0, 0, 0);

   {load the standard 'system' unit unit symbol table}
   load_unitfile('TPTCSYS.UNS',globals);

   {mark the end of predefined entries in the symbol table}
   newsym('<predef>',  s_void,	 ss_builtin,-1, 0, 0, 0);
end;


(********************************************************************)
procedure usage(why: anystring);
   {print usage instructions and copyright}

   procedure pause;
   var
      answer:char;
   begin
      writeln;
      write('More: (Enter)=yes? ');
      answer:=readkey;
      if UpCase(answer) in [#27,'N'] then halt;
   end;

begin
   writeln;
   writeln('Error:   ',why);
   pause;

   writeln;
   writeln('Usage:   TPTC input_file [output_file] [options]');
   writeln;
   writeln('Where:   input_file      specifies the main source file, .PAS default');
   writeln('	     output_file     specifies the output file, .C default');
   writeln('	     -B 	     deBug trace during scan');
   writeln('	     -BP	     deBug trace during Parse');
   writeln('	     -D 	     Dump user symbols');
   writeln('	     -DP	     Dump Predefined system symbols');
   writeln('	     -I 	     output Include files'' contents');
   writeln('	     -L 	     map all identifiers to Lower case');
   writeln('	     -M 	     use Pascal/MT+ specific translations');
   writeln('	     -NC	     No Comments passed to output file');
   writeln('	     -Q 	     Quiet mode; suppress warnings');
   writeln('	     -Sdir\	     search dir\ for .UNS symbol files');
   writeln('	     -Tnn	     Tab nn columns in declarations');
   writeln('	     -Wdrive:	     use drive: for Work/scratch files (ramdrive)');
   writeln('	     -# 	     don''t translate lines starting with "#"');
   pause;

   writeln('Default command parameters are loaded from TPTC environment variable.');
   writeln;
   writeln('Example: tptc fmap');
   writeln('	     tptc fmap -L -d -wj:\tmp\');
   writeln('	     tptc -l -d -wj: -i -q -t15 fmap.pas fmap.out');
   writeln;
   writeln('	     set tptc=-wj: -i -l -sc:\libs');
   writeln('	     tptc test	     ;uses options specified earlier');
   halt(88);
end;


(********************************************************************)
procedure process_option(par: anystring);
begin
   stoupper(par);

   if (par[1] = '-') or (par[1] = '/') then
   begin
      delete(par,1,1);
      par[length(par)+1] := ' ';

      case(par[1]) of
	 'B': begin
		 if par[2] = 'P' then
		    debug_parse := true;
		 debug := true;
	      end;

	 'D': begin
		 if par[2] = 'P' then
		    dumppredef := true;
		 dumpsymbols := true;
	      end;

	 'I': includeinclude := true;
	 'L': map_lower := true;
	 'M': mt_plus := true;

	 'N': if par[2] = 'C' then
		 pass_comments := false;

	 'Q': quietmode := true;

	 'S': begin
		 symdir := copy(par,2,65);
		 if symdir[length(symdir)] <> '\' then
		    symdir := symdir + '\';
	      end;

	 'T': identlen := atoi(copy(par,2,10));

	 'W': begin
		 workdir := copy(par,2,65);
		 if workdir[length(workdir)] <> '\' then
		    workdir := workdir + '\';
	      end;

	 '#': tshell := true;

	 else usage('invalid option: -'+par);
      end;
   end
   else

   if inname = '' then
      inname := par
   else

   if outname = '' then
      outname := par
   else
      usage('extra output name: '+par);
end;


(********************************************************************)
procedure decode_options;
var
   i:	     integer;
   options:  string;
   opt:      string;

begin
   inname := '';
   outname := '';
   unitname := '';
   symdir := '';
   ltok := '';
   tok := '';
   ptok := '';
   spaces := '';
   decl_prefix := '';

   (* build option list from TPTC environment variable and from
      all command line parameters *)
   options := get_environment_var('TPTC=');
   for i := 1 to paramcount do
      options := options + ' ' + paramstr(i);
   options := options + ' ';


   (* parse the options into spaces and process each one *)
   repeat
      i := pos(' ',options);
      opt := copy(options,1,i-1);
      options := copy(options,i+1,255);
      if length(opt) > 0 then
	 process_option(opt);
   until length(options) = 0;
   (* verify all required options have been specified *)
   if inname = '' then
      usage('missing input name');
   if outname = '' then
   begin
      outname := inname;
      i := pos('.',outname);
      if i > 0 then
	outname := copy(outname,1,i-1);
   end;
   if pos('.',outname) = 0 then
      outname := outname + '.C';
   i := pos('.',outname);
   unitname := copy(outname,1,i-1);
   if pos('.',inname) = 0 then
      inname := inname + '.PAS';
   if inname = outname then
      usage('duplicate input/output name');
end;
(********************************************************************)
{* MAIN program *}
begin
   assign(output,'');
   rewrite(output);
{   writeln;}
   writeln(version1);
   writeln(version2);
(* do initializations *)
   decode_options;
   initialize;
(* process the source file(s) *)
   pprogram;
(* clean up and leave *)
   closing_statistics;
end.