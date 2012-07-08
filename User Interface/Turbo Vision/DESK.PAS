{ File: TVDESK.PAS   Version: 1.0
Note: Allows a full Turbo Vision desktop with a specific character pattern.}
uses App, Objects, Menus;
type
   TTutorApp = object(TApplication)
	       procedure InitStatusLine; virtual;
	       procedure InitMenuBar; virtual;
	       procedure InitDesktop; virtual;
   end;

procedure TTutorApp.InitStatusLine;	    { draw nothing, allow ALT-X quit }
var R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;			    { below screen bottom }
  New(StatusLine, Init(R, NewStatusDef(0, $EFFF, StdStatusKeys(nil), nil)));
end;

procedure TTutorApp.InitMenuBar;	    { do nothing }
begin end;

procedure TTutorApp.InitDesktop;
var R: TRect;
begin
  GetExtent(R); 			    { get application rectangle }
					    { Adjust R.A.Y and R.B.Y here! }
  New(Desktop, Init(R));		    { construct custom desktop }
  Desktop^.Background^.Pattern := '°';	    { change pattern character }
end;

Var TutorApp : TTutorApp;		    { declare an instance of yours }
begin
  TutorApp.Init;
  TutorApp.Run;
  TutorApp.Done;
end.

