program ExtraMenuBar;
uses Objects, Drivers, Views, Menus, App;
const
  cmFileOpen = 100;
  cmNewWin   = 101;
type
  PExtraMenuBar = ^TExtraMenuBar;
  TExtraMenuBar = object(TMenuBar)
   procedure Draw;virtual;
  end;

  TMyApp = object(TApplication)
    ExtraMenuBar : PExtraMenuBar;
    procedure InitMenuBar; virtual;
  end;
procedure TExtraMenuBar.Draw;
const
 ProgName : String=' eXtra Bar ';
begin
      TMenuBar.Draw;
      WriteStr(35,0,ProgName,$0);
end;

{ TMyApp }
procedure TMyApp.InitMenuBar;
var R: TRect;
begin
  GetExtent(R);
  ExtraMenuBar := New(PExtraMenuBar,Init(R,nil));
  Insert(ExtraMenuBar);
{    R.B.Y := R.A.Y + 2;
    R.A.Y := 1;
    MenuBar := New(PMenuBar, Init(R, NewMenu(
      NewSubMenu('~F~ile', hcNoContext, NewMenu(
	NewItem('~O~pen', 'F3', kbF3, cmFileOpen, hcNoContext,
	NewItem('~N~ew', 'F4', kbF4, cmNewWin, hcNoContext,
	NewLine(
	NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext,
	nil))))),
	nil))));
}
end;
var
  MyApp: TMyApp;
begin
  MyApp.Init;
  MyApp.Run;
  MyApp.Done;
end.