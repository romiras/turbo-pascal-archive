PROGRAM PopUp;
USES App, Objects, Menus, Drivers, Views;

TYPE TPopupMenu = OBJECT(TMenuPopup)
	DESTRUCTOR Done; VIRTUAL;
     END;
     PPopupMenu = ^TPopupMenu;

TTestApp = OBJECT(TApplication)
   PROCEDURE HandleEvent(VAR Event : TEvent); VIRTUAL;
   FUNCTION  MakePopup(where : TPoint) : PPopupMenu;
END;

DESTRUCTOR TPopupMenu.Done;
BEGIN
  IF (Menu <> NIL) THEN DisposeMenu(menu);
  INHERITED Done;
END;

FUNCTION TTestApp.MakePopup(where : TPoint) : PPopupMenu;
VAR R : TRect;
BEGIN
     R.Assign(where.x, where.y, where.x+10, where.y);  {*}
     MakePopup := New(PPopupMenu, Init(R, NewMenu(
	NewItem('~N~ew', '', kbNoKey, cmNew, hcNew,
	NewItem('~O~pen...', 'F3', kbF3, cmOpen, hcOpen,
     NIL)))));
END;

PROCEDURE TTestApp.HandleEvent(VAR event : TEvent);
VAR MenuChoice : Word;
    Popup      : PPopupMenu;
BEGIN
     IF (Event.what = evMouseDown) AND
	(Event.Buttons = mbRightButton) THEN
     BEGIN
	  Popup := MakePopup(event.where);
	  MenuChoice := ExecView(popup);
	  { Jetzt Auswahl abarbeiten }

	  Dispose(popup, Done);
	  ClearEvent(event);
     END
     ELSE INHERITED HandleEvent(event);
END;

VAR T: TTestApp;
BEGIN
     T.Init;
     T.Run;
     T.Done;
END.