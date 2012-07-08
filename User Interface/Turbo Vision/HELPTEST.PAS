
program HelpTest;
{$X+}
uses
  Dos, App,
  ApplPro,
  Drivers, Menus, Objects, Views,
  HelpFile;
const
  ExeName	    = 'HELPTEST.EXE';
  cmUsingHelp	    = 1000;
var HName:string;
type
  TMain=object(TApplPro)  { (TApplication) }
      constructor Init;
      procedure InitMenubar; virtual;
      procedure InitStatusLine; virtual;
      procedure HandleEvent(var Event:TEvent); virtual;
    end;
constructor TMain.Init;
begin
  inherited Init;
  ExeFileName:=ExeName;
  HelpFileName:=HName;
  ShowHelp(hcContents);    { Intro text }
end;
procedure TMain.HandleEvent;
begin
  inherited HandleEvent(Event);
  if Event.What=evCommand then
  begin
    case Event.Command of
      (* This command should not be handled by TMain.GetEvent *)
      cmUsingHelp: ShowHelp(hcContents); (* TP IDE uses hcHelpOnHelp *)
      else
	Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TMain.InitMenubar;
  var
    R : TRect;
begin
  GetExtent(R);
  R.B.Y:=R.A.Y+1;
  MenuBar:=New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~H~elp', hcHelp, NewMenu(
      NewItem('~C~ontents',	'F1', kbF1, cmHelpContents,  hcContents,
      NewItem('~P~revious topic', 'F5', kbF5, cmPreviousTopic, hcPreviousTopic,
      NewItem('~U~sing help',	  'F2', kbF2, cmUsingHelp,	hcUsingHelp,
    nil)))),
  nil))));
end;

procedure TMain.InitStatusLine;
  var
    R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  New(StatusLine, Init(R,
    StdStatusHelp(
    NewStatusDef(0, $FFFF,
      StdStatusKeys(
      NewStatusKey('~F1~ Help',    kbF1,   cmHelp,
      NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    Nil))),
  Nil))));
end;

{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴횺AIN컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�}
var
  Main : TMain;

begin
     HName:='HELPTEST.HLP';
     if paramcount=1 then HName:=paramstr(1);
  Main.Init;
  Main.Run;
  Main.Done;
end.