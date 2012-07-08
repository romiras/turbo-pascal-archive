Program Diall;

uses App, Objects, Drivers, Views, Menus, Dialogs, MsgBox,
     Crt, GrowView;
const
  cmDialog = 1001;
type
  PMyApp = ^TMyApp;
  TMyApp = object(TApplication)
    procedure MakeDialog;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitStatusLine; virtual;
  end;

procedure TMyApp.HandleEvent(var Event: TEvent);
begin
  TApplication.HandleEvent(Event);
  if Event.What = evCommand then
    begin
      case Event.Command of
	 cmDialog:begin
		       MakeDialog;
		  end;
      else
	Exit;
      end;
	ClearEvent(Event);
     end;
end;

procedure TMyApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y-1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('Dialog - ~F5~', kbF5, cmDialog,
      nil)),
      nil)));
end;

procedure TMyApp.MakeDialog;
const max=55;
var
  R:TRect;
  Dlg: TDialog;
  MyBar: PGrowView;
  i:integer;
  L: longint;
  ps: string;

begin
     R.Assign( 24, 9, 60, 14);
     Dlg.Init (R, 'Progress bar');
     Dlg.Flags := Dlg.Flags and not wfClose;
     R.assign( 2, 2, 34, 3);
     MyBar:=New( PGrowView, Init(r, max));
     Dlg.Insert(MyBar);
     Desktop^.Insert(@Dlg);
     for i:=1 to max do
     begin
	  Delay(1500);
      MyBar^.Update(i);
	  R.Assign(2,3,14,4);
	  Dlg.Insert(New( PStaticText, Init(R, 'filename.ext')));
      L:=MyBar^.Percent(i,max);
      formatstr(ps,'%3d%%',L);
	  R.Assign(30,3,34,4);
	  Dlg.Insert(New( PStaticText,
	      Init(R, ps)));
     end;
     Dlg.Done;
end;

var
  MyAppWorld: TMyApp;
begin
  MyAppWorld.Init;
  MyAppWorld.Run;
  MyAppWorld.Done;
end.