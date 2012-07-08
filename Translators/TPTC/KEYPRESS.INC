
   (* -------------------------------------------------------- *)
   function ReadKey: Char;
   var
      reg: registers;
   begin
      reg.ax := $0700;   {direct console input}
      msdos(reg);
      ReadKey := chr(reg.al);
   end;


   (* -------------------------------------------------------- *)
   function KeyPressed: Boolean;
   var
      reg: registers;
   begin
      reg.ax := $0b00;   {ConInputStatus}
      msdos(reg);
      KeyPressed := (reg.al = $FF);
   end;

