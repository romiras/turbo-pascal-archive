   { -----------------   DEMO ---------------- }
   Program TestPwd;

   {***************************************************************************
   Written by Mark S. Van Leeuwen.
   This Code is Public Domain.
   This is a Test Program that shows the use of the unit.
   Please Include my Name in any application that uses this code.
   ***************************************************************************}

   Uses Objects,App,Dialogs,Drivers,Passwd,Views,StdDlg,MsgBox,Menus;

   Const
   cmPassword = 1001;

   Type
   PTestApp=^TTestApp;
   TTestApp=Object(TApplication)
   Procedure HandleEvent(Var Event:TEvent);Virtual;
   Procedure InitStatusLine;Virtual;

   End;

   Procedure TTestApp.HandleEvent(Var Event:TEvent);
   Procedure Password;
   Var
    D         : PDialog;
    Control   : Word;
    A         : PView;
    R         : TRect;
    S         : String[21];
    Begin
     R.Assign(0,0,30,08);
     D := New(PDialog, Init(R, 'Enter password'));
     With D^ Do
     Begin
     Options := Options or ofCentered;

       R.Assign(02, 05, 12, 07);
       Insert(New(PButton, Init(R, 'O~K', cmOk, bfDefault)));

       R.Assign(17, 05, 27, 07);
       Insert(New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal)));

       R.Assign(02,03,28,04);
       Insert(New(PStaticText, Init(R,'Password is not Displayed.')));{}

       R.Assign(02,02,28,03);
       A:= New(PPasswordLine, Init(R,20));
       Insert(A);

      End;
       Control:=Desktop^.ExecView(D);
       IF Control <> cmCancel THEN
         Begin
         A^.GetData(S);
        MessageBox(#3+S,nil,mfInformation+mfOkButton);
       End;
       Dispose(D, Done);
    End;

   Begin
    TApplication.HandleEvent(Event);
     case Event.What of
       evCommand:
         begin
           case Event.Command of
            cmPassword: Password;
            else
             Exit;
           end;
           ClearEvent(Event);
         end;
     end;
   end;
   {***************************************************************************}
   {**************** Application Status Line Procedure ************************}
   {***************************************************************************}
    Procedure TTestApp.InitStatusLine;
    Var
    R :Trect;
    Begin
     GetExtent(R);
     R.A.Y := R.B.Y - 1;
     StatusLine := New(PStatusLine, Init(R,
       NewStatusDef(0, $FFFF,
{         NewStatusKey('~F1~ Help', kbF1, cmHelp,}
         NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
         NewStatusKey('~F2~ Password', kbF2, cmPassword,nil)),
       nil)));
   End;


   Var
   TMyApp  :TTestApp;

   Begin
   TMyapp.Init;
   TMyapp.Run;
   TMyapp.Done;
   End.
