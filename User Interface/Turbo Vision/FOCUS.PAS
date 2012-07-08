
uses
  App, Dialogs, Drivers, Menus, MsgBox, Validate, Views, Objects;

const
  cmDialogBox = 101;
  cmTest      = 102;
  cmButton    = 103;
  cmInput      = 104;
  InputLength = 128;
  TheMessage = 'The Input line just received focus.' + #13#10 +
	       'Chose OK to set Ok in the Inputline' + #13#10 +
	       'Chose Cancel to set Cancel in the InputLine';

type
  PMyButton = ^TMyButton;
  TMyButton = Object(TButton)
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

  PTrainDialog = ^TTrainDialog;
  TTrainDialog = Object(TDialog)
      MyInputLine: PInputLine;
    constructor Init(Bounds: TRect; ATitle: String);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  TMyApp = Object(TApplication)
    constructor Init;
    procedure InitStatusLine; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure DialogBox;
  end;

procedure TMyButton.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState = sfFocused) and (Enable = False) then
    DisableCommands([cmButton]);
  if (AState = sfFocused) and (Enable = True) then
    EnableCommands([cmButton]);
end;

constructor TTrainDialog.Init(Bounds: TRect; ATitle: String);
var
  R: TRect;
  Control: PView;
  S: String;
begin
  TDialog.Init(Bounds, ATitle);
  R.Assign(2, 2, 37, 4);
  Insert(New(PMyButton, Init(R, 'Test', cmTest, bfNormal)));
  R.Assign(3, 5, 37, 6);
  MyInputLine := New(PInputLine, Init(R, InputLength));
  Insert(MyInputLine);
  R.Assign(2, 4, 24, 5);
  Insert(New(PLabel, Init(R, 'Delivery instructions',
     MyInputLine)));
  R.Assign(2, 7, 37, 9);
  Insert(New(PButton, Init(R, 'O~k~', cmOk, bfDefault)));

  S := '32';
  SetData(S);
end;

procedure TTrainDialog.HandleEvent(var Event: TEvent);
var
  Result: Word;
  S: String;
begin
  if (Event.What = EvBroadCast) and
     (Event.InfoPtr = MyInputLine) then
    case Event.Command of
      cmReceivedFocus: EnableCommands([cmInput]);
      cmReleasedFocus: DisableCommands([cmInput]);
    end;
  TDialog.HandleEvent(Event);
end;

constructor TMyApp.Init;
begin
  inherited Init;
  DisableCommands([cmInput,cmButton]);
end;

procedure TMyApp.HandleEvent(var Event: TEvent);
begin
  TApplication.HandleEvent(Event);
  if Event.What = EvCommand then begin
    case Event.Command of
      cmDialogBox: DialogBox;
    else
      Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TMyApp.InitStatusLine;
var R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('', kbF10, cmMenu,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~Alt-D~ Dialog', kbAltD, cmDialogBox,
      NewStatusKey('~Alt-F4~ Button Focused?',
	       kbAltF4, cmButton,
      NewStatusKey('~Alt-F5~ InputLine Focused?',
	       kbAltF5, cmInput,
      nil))))),
    nil)
  ));
end;

procedure TMyApp.DialogBox;
var
  R: TRect;
  D: PDialog;
begin
  R.Assign(20,5,60,15);
  D := New(PTrainDialog, Init(R, 'Hit Tab, watch statusline'));
  if ValidView(D) <> Nil then DeskTop^.ExecView(D);
  Dispose(D, Done);
end;

var
  A: TMyApp;
begin
  A.Init;
  A.Run;
  A.Done;
end.