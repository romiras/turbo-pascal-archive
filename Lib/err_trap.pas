   { перехват ошибок } 

  var OldExitProcAddress : Pointer;
      x : real;
  {$F+} procedure MyExitProcedure; {$F-}
  begin
    if ErrorAddr <> nil then
      begin
        writeln ('Runtime error number ', ExitCode, ' has occurred');
        writeln ('The error address in decimal is ',
                  Seg(ErrorAddr^):5,':',Ofs(ErrorAddr^):5);
        writeln ('That''s all folks, bye bye');
        ErrorAddr := nil;
        ExitCode  := 0;
      end;
    {... Restore the pointer to the original exit procedure ...}
    ExitProc := OldExitProcAddress;
  end;  (* MyExitProcedure *)
  (* Main *)
  begin
    OldExitProcAddress := ExitProc;
    ExitProc := @MyExitProcedure;
    x := 7.0; writeln (1.0/x);
    x := 0.0; writeln (1.0/x);   {The trap}
    x := 7.0; writeln (4.0/x);   {We won't get this far}
  end.
