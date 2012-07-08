{SWAG=OOP.SWG, T.V. Mouse right button}
program Localmenu;
uses
  Drivers, Objects, Views, App, Menus;

const
  cmNothing = 101;
type

  TMyApp = object(TApplication)
    LocalMenu: PMenu;
    LocalMenuOpen: boolean;
    constructor Init;
    procedure GetEvent(var Event: TEvent); virtual;
  end;

constructor TMyApp.Init;
begin
  inherited Init;
  LocalMenu :=	NewMenu(
    NewItem('Item~1~', '', 0, cmNothing, hcNOContext,
    NewItem('Item~2~', '', 0, cmNothing, hcNoContext,
    nil)));

  LocalMenuOpen := false;
  EventMask := EventMask or evBroadcast;
end;

procedure TMyApp.GetEvent(var Event: TEvent);
var
  MousePt: TPoint;
  R: TRect;
  Box: PMenuBox;
  NewEvent: TEvent;
  Code: Word;
begin
  inherited GetEvent(Event);
  if ((Event.What = evMouseDown) AND (Event.Buttons =
	  mbRightButton) AND NOT LocalMenuOpen)
  then
  begin
    LocalMenuOpen := true;
    MousePt := Event.Where;
    if (MousePt.X > 70) then MousePt.X := 70;

    if (MousePt.Y > 20) then MousePt.Y := 20;
    ClearEvent(Event);
    R.Assign(MousePt.X, MousePt.Y, MousePt.X+11, MousePt.Y+2);
    Box := new(PMenuBox, Init(R, LocalMenu, nil));
    Code := ExecView(Box);
    Dispose(Box);
    LocalMenuOpen := false;
    NewEvent.What := evBroadcast;
    NewEvent.Command := code;
    PutEvent(NewEvent);
  end;
end;
var
  MyApp: TMyApp;
begin
  MyApp.Init;
  MyApp.Run;
  MyApp.Done;
end.