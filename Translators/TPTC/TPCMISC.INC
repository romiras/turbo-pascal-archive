(********************************************************************)
procedure mark_time(var long: longint);
   {report time in clock ticks since midnight}
var
   words:   record
	       l,h: word;
	    end   absolute long;
   reg:     registers;

begin
   reg.ah := 0;  {get time of day}
   intr($1a,reg);
   words.l := reg.dx;
   words.h := reg.cx;
end;


(********************************************************************)
procedure abortcheck;
   {check for the abort(escape) key}
var
   c:  char;
begin
   if keypressed then
   begin
      c := readkey;
      if c = #27 then
	 fatal('Aborted by <escape> key');
   end;
end;


(********************************************************************)
procedure puttok;
   {output the current token and a space to the output}
begin
   write(ofd[unitlevel],ltok,' ');
   linestart := false;
end;


(********************************************************************)
procedure putline;
   {start a new line in the output file}
begin
   writeln(ofd[unitlevel]);
   inc(objtotal);
   linestart := true;
end;


(********************************************************************)
procedure closing_statistics;
var
   secs: real;
   rate: real;

begin

   {terminate any active output files}
   if in_interface then
      pimplementation;
   purgetable(locals,nil);
   while unitlevel > 0 do
      exit_procdef;
   putline;
   putline;
   purgetable(globals,nil);
   close(ofd[unitlevel]);

   {determine statistics}
   mark_time(curtime);
   secs := int(curtime-starttime) / ticks_per_second;

   {rate := int(srctotal) / secs * 60.0;}
   rate := int(objtotal) / secs * 60.0;

   {report statistics}
   if debug then writeln;
   writeln(^M,srcfiles[srclevel],'(',srclines[srclevel],')');
   writeln(srctotal,' source lines, ',
	   objtotal,' object lines, ',
	   secs:0:1,' seconds, ',
	   rate:0:0,' lines/min.');
end;


(********************************************************************)
procedure error_message (message:	string);
   {place an error message into the object file and on the screen}

   procedure report(var fd: text);
   begin
      writeln(fd,'/* TPTC: ',srcfiles[srclevel],'(',srclines[srclevel],'): ',
	   message,', tok=', ltok,' */');
   end;

begin
   if debug then writeln
   else write(^M);
   report(output);

   putline;
   report(ofd[unitlevel]);
   write(ofd[unitlevel],spaces);
   inc(objtotal);
end;


(********************************************************************)
procedure comment_statement;
begin
   puts(' /* ');

   repeat
      puttok;
      gettok;
   until (tok[1] = ';');

   puts(' */ ');
end;


(********************************************************************)
procedure warning (message:	  string);
   {report a warning message unless warnings are disabled}
begin
   if not quietmode then
      error_message('Warning: '+message);
end;


(********************************************************************)
procedure syntax (message:	 string);
   {report a syntax error and skip to the next ';'}
begin
   if (not recovery) or (not quietmode) then
      error_message('Error: '+message);
   gettok;
   recovery := true;
end;


(********************************************************************)
procedure fatal (message:	string);
   {abort translation with a fatal error}
begin
   error_message('Fatal: '+message);
   closing_statistics;
   halt(88);
end;


(********************************************************************)
procedure puts(s: string);
   {output a string the output file}
begin
   write(ofd[unitlevel],s);
   if s[1] = ^J then
   begin
      inc(objtotal);
      linestart := true;
   end
   else
      linestart := false;
end;


(********************************************************************)
procedure putln(s: string);
   {output a string the output file and newline}
begin
   puts(s);
   putline;
end;


(********************************************************************)
procedure newline;
   {start a new line in the output file;  indent to the same level
    as the current line}
begin
   putline;
   write(ofd[unitlevel],spaces);
end;