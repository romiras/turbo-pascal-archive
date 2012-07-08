  {SWAG=OOP.SWG,BRIAN RICHARDSON,Printing A tcollection,PRINTING,TCOLLECTION}

  unit BPrint;
  interface
  uses Objects, Prt;   { Prt is included after! }
  procedure PrintCollection(const Port : word; P : PStringCollection); 
  implementation 
  uses MsgBox, Views; 
  function WriteStr(Port : word; Str : String): boolean; 
  var x : boolean; 
      q : word;
      i : byte; 
  begin 
      repeat 
          x := Ready(Port); 
          if not x then q := MessageBox(^C'Printer not Ready.  Try Again?', nil, 
                             mfYesButton + mfNoButton + mfError); 
      until x or (q = cmNo); 
      i := 1; 
      while (Ready(Port)) and (q <> cmNo) and (i <> Length(Str)+1) do begin 
          x := Ready(Port); 
          if not x then q := MessageBox(^C'Printer Error!  Try Again?', nil, 
                             mfYesButton + mfNoButton + mfError);
          if q <> cmNo then 
              if WriteChar(Port, Str[i]) then Inc(i);
      end; 
      WriteStr := False; 
      if Ready(Port) and (q <> cmNo) then begin 
          WriteChar(Port, #13); 
          WriteChar(Port, #10); 
          WriteStr := True; 
      end; 
  end; 
   
  procedure PrintCollection(const Port : word; P : PStringCollection);
  var x : integer; 
      q : word; 
  begin 
      q := MessageBox(^C'To print, ready your printer and Press OK', nil, 
           mfInformation + mfOkCancel); 
      if q = cmOk then begin 
          x := -1; 
          repeat 
              inc(x); 
          until not WriteStr(Port, PString(P^.At(x))^) or (X = P^.Count - 1);
      end;

  end;
  end.

  { ----          CUT HERE  -------- }

  unit Prt;
  interface 
  uses objects; 
  const 
      Lpt1        =   0;                  Lpt2        =   1; 
      Lpt3        =   2;                  lf          = #10; 
      cr          = #13;                  pTimeOut    = $01; 
      pIOError    = $08;                  pNoPaper    = $20; 
      pNotBusy    = $80;
      pTestAll    = pTimeOut + pIOError + pNoPaper; 
  function WriteChar(const APort : word; s : char): boolean; 
  function Ready(const APort : word): boolean; 
  function Status(const APort : word): byte; 
  procedure InitPrinter(const APort : word); 
  implementation 
  procedure InitPrinter(const APort : word); assembler; 
  asm 
      mov     ah, 1 
      mov     bx, APort
      int     17h 
  end;
  function Status(const APort : word): byte; assembler; 
  asm 
      mov     ah, 2                   { Service 2 - Printer Status } 
      mov     dx, APort             { Printer Port               } 
      int     17h                     { ROM Printer Services       } 
      mov     al, ah                  { Set function value         } 
  end; 
  function Ready(const APort : word): boolean; 
  begin 
      Ready := Status(APort) and pTestAll = $00; 
  end; 
  function WriteChar(const APort : word; s : char): boolean;
  begin 
      if Ready(APort) then 
       asm 
          mov     ah, 0               { Printer Service - Write Char } 
          mov     al, s               { Char to write                } 
          mov     dx, APort           { Printer Port                 }
          int     17h                 { ROM Printer Services         } 
          mov     al, 0               { Set procedure to false       } 
          and     ah, 1               { Check for Error              } 
          jnz     @End                { Jump to end if error         } 
          mov     al, 1               { Set procedure to true        } 
         @End:
      end; 
  end;

  end.

  { ----------------   CUT HERE --------------------- }
  {
      Here's a sample test program so you don't have to write one yourself
      :).
  }

  uses BPrint, Prt;
   
  function Int2Str(const i : longint): string; 
  var s : string; 
  begin 
     Str(i, s); 
     Int2Str := s; 
  end; 
   
  var x : integer; 
      q : PStringCollection; 
  begin 
      q := New(PStringCollection, Init(10, 10)); 
      for x := 0 to 64 do q^.Insert(NewStr(Int2Str(Random(4000)))); 
      PrintCollection(Lpt1 {Change for your printer}, q); 
  end.