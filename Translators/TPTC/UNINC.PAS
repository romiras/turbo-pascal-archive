
(*
 * uninc - post-processor for TPTC
 *
 * This program will read a TPTC output file and produce a new
 * file without the inline include file contents.  The include
 * files will be written along with the main file to the specified
 * destination directory.
 *
 * S.H.Smith, 3/13/88  (rev. 3/13/88)
 *
 * Copyright 1988 by Samuel H. Smith;  All rights reserved.
 *
 *)

{$T+}    {Produce mapfile}
{$R-}    {Range checking}
{$B-}    {Boolean complete evaluation}
{$S-}    {Stack checking}
{$I+}    {I/O checking}
{$N-}    {Numeric coprocessor}
{$V-}    {Relax string rules}
{$M 65500,16384,655360} {stack, minheap, maxhep}


program TPTC_post_processor;

const
   version1 =     'UNINC - Post-processor for TPTC';
   version2 =     'Version 1.1 03/25/88    (C) 1988 S.H.Smith';

const
   max_incl = 3;     {maximum include nesting}
   bufsize = 20000;  {input file buffer size}
   obufsize = 4000;  {output file buffer size}
         
                   {1234567890123456}
   start_include = '/* TPTC: include';           
   end_include   = '/* TPTC: end of ';
   key_length    = 16;     {length(start_include)}

var
   line:       string;     {current source line}
   key:        string;     {current keyword}
   name:       string;     {filenames}
   
   infd:       text;       {input file and buffer}
   inbuf:      array[1..bufsize] of byte;

   destdir:    string;     {output directory and files}
   ofd:        array[1..max_incl] of text;
   obuf:       array[1..max_incl] of array[1..obufsize] of byte;
   level:      integer;



(* ------------------------------------------------------------------ *)
procedure init;
   {parse command line, initialize global variables, open files}
begin
   if paramcount <> 2 then
   begin
      writeln('Usage:   uninc INFILE DESTDIR');
      writeln('Example: unint test.c c:\tran');
      halt;
   end;

   {process input file}   
   name := paramstr(1);
   assign(infd,name);
   {$i-} reset(infd); {$i+}
   if ioresult <> 0 then
   begin
      writeln('Can''t open input file: ',name);
      halt;
   end;
   setTextBuf(infd,inbuf);

   {process destination directory specification}      
   destdir := paramstr(2);
   if destdir[length(destdir)] <> '\' then
      destdir := destdir + '\';

   {process initial output file}
   name := destdir + name;
   writeln(name);
   level := 1;
   assign(ofd[level],name);
   {$i-} rewrite(ofd[level]); {$i+}
   if ioresult <> 0 then
   begin
      writeln('Can''t create output file: ',name);
      halt;
   end;

   setTextBuf(ofd[level],obuf[level]);   
end;


(* ------------------------------------------------------------------ *)
procedure enter_include;
var
   i: integer;
begin       
   {determine new include filename}
   name := copy(line,18,99);        {/* tptc: include <filename> */}
   name := copy(name,1,pos(' ',name)-1);
   
   {remove any directory specification fron the include filename}
   if name[2] = ':' then
      name := copy(name,3,99);
   repeat
      i := pos('\',name);
      if i > 0 then name := copy(name,i+1,99);
   until i = 0;
   
   {generate include statement in main file}
   write(ofd[level],'#include "',name,'"');

   {display new include filename on screen}
   name := destdir + name;
   writeln(name);

   {create the new include file}
   inc(level);
   assign(ofd[level],name);
   {$i-} rewrite(ofd[level]); {$i+}
   if ioresult <> 0 then
   begin
      writeln('Can''t create include file: ',name);
      halt;
   end;

   setTextBuf(ofd[level],obuf[level]);   
end;


(* ------------------------------------------------------------------ *)
procedure exit_include;
begin
   if level < 2 then
      writeln('Improper include nesting (too many exits) (',line,')')
   else
   begin
      close(ofd[level]);
      dec(level);
   end;
end;


(* ------------------------------------------------------------------ *)
(*
 * main procedure - initialize, process input, cleanup
 *
 *)
        
begin
   {get things rolling}
   writeln;
   writeln(version1,'   ',version2);
   init;

   {process each line in the file}   
   while not eof(infd) do
   begin
      readln(infd,line);
      
      if pos('/* TPTC:',line) > 0 then
         while line[1] = ' ' do
            delete(line,1,1);
            
      key := copy(line,1,key_length);

      if key = start_include then
         enter_include
      else
      if key = end_include then
         exit_include
      else
         writeln(ofd[level],line);
   end;
   
   {close files and terminate}
   close(ofd[level]);
   if level > 1 then
   begin
      writeln('unint: Premature eof');
      repeat
         dec(level);
         close(ofd[level]);
      until level = 1;
   end;
end.

