{SWAG=OOP.SWG,MARK VAN LEEUWEN,TV Password Unit,PASSWORD,UNIT}
   Unit Passwd;
   {***************************************************************************
   Written by Mark S. Van Leeuwen.
   This Code is Public Domain.
   Please Include my Name in any application that uses this code.
   ***************************************************************************}

   Interface

   Uses Objects,Dialogs,Views,Drivers;

   Type
   PPasswordLine=^TPasswordLine;
   TPasswordLine=Object(TInputline)
   Data1  :String;
   Constructor Init(Var Bounds :TRect; AMaxLen :Integer);
   Procedure GetData(Var Rec);Virtual;
   Procedure SetData(Var Rec);Virtual;
   Procedure HandleEvent(Var Event :TEvent);Virtual;
   End;

   Implementation

   {**************** Constructor for the Password Inputline Data **************}
   Constructor TPasswordLine.Init(Var Bounds :TRect; AMaxlen :Integer);
   Begin
   Data1:='';
   TInputline.Init(Bounds,AMaxLen);
   End;
   {******************* Get Data from Procedure *******************************}
   Procedure TPasswordLine.GetData(Var Rec);
   Begin
   String(Rec):=Data1;
   End;
   {****************** Set Data to Procedure **********************************}
   Procedure TPasswordLine.SetData(Var Rec);
   Begin
   Data1:=String(Rec);
   SelectAll(True);
   End;
   {******************** Handle Inputline Event *******************************}
   Procedure TPasswordLine.HandleEvent(Var Event :TEvent);
   Var
   C: String[1];
   Begin
     With Event Do
       If (What = evKeyDown) And (KeyCode = kbEsc) Then
       Begin
         What := Command;
         Command := cmClose;
       End;
      Case Event.What Of
       evKeyDown:
         Begin
            If(UpCase(Event.CharCode) In ['A'..'Z','0'..'9']) Then
              Begin
            C:=Event.CharCode;
            Data1:=Concat(Data1,C);
            Event.CharCode:='*';
            End;
           If(Event.KeyCode = kbBack) OR (Event.KeyCode = kbDel) Then
             Begin
              If(byte(Data1[0]) <> 0)Then Dec(Data1[0]);
             Event.KeyCode:=kbBack;
           End;
         End;
       evBroadcast:
         Begin
         End;
     End;
   TInputLine.HandleEvent(Event);
   End;
   End.