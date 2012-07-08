{$N+}
uses Drivers, Objects, Views, Menus, App,Dialogs,
     numinput;

const cmOpenDialog=1500;
type
  TTutorApp = object(TApplication)
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitStatusLine; virtual;
    procedure Dialog;
  end;
var F: word;
    S:string;

procedure TTutorApp.HandleEvent(var Event: TEvent);
var
  R: TRect;
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmOpenDialog:
	begin
	      Dialog;
	end;
    end;
  end;
end;

procedure TTutorApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  New(StatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, 1,
      NewStatusKey('~F3~ OpenDialog', kbF3, cmOpenDialog,
      nil)),
    nil)));
end;

procedure TTutorApp.Dialog;
{type
	DlgData = record
	 InputLineData: string[128];
	end;}
var
  Dlg : PDialog;
  R : TRect;
  Control : PView;
  ctr:word;
  DialogData: string; {DlgData;}
  WIL: PWordInputLine;   {}
begin
	R.Assign(25, 7, 55, 16);
	New(Dlg, Init(R, 'Demo Dialog'));

	R.Assign(4,2,26,3);
	Control:= New(PStaticText,Init(r,#3'Input number'));
	Dlg^.Insert(Control);

	R.Assign(10, 3, 20, 4);
	WIL:= New(PWordInputLine, Init(R));{}
	Dlg^.Insert(WIL);

	R.Assign(5, 6, 13, 8);
	Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
	Dlg^.Insert(Control);
	R.Assign(16, 6, 26, 8);
	Control := (New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
	Dlg^.Insert(Control);

	Dlg^.SelectNext(False);
	Ctr := DeskTop^.ExecView(Dlg);
	if Ctr <> cmCancel then begin
	   WIL^.GetData(F);
{	   S:=WIL^.Data^;}
	end;
	Dispose(Dlg,done);
end;


var
  TutorApp: TTutorApp;

begin
  TutorApp.Init;
  TutorApp.Run;
  TutorApp.Done;
  writeln(F);
{  writeln(S);}
end.