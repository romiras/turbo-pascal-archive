
uses
  Objects,Dos,
  App,Views,Drivers,Dialogs,Menus,MsgBox, StdDlg,mulsel;

const
     cmDlg=101;
type
  PPickWindow = ^TPickWindow;
  TPickWindow = object(TDialog)
    D: PMultiSelListBox;
    constructor Init;
  end;

  TPickApp = object(TApplication)
    PickWindow: PPickWindow;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitStatusLine; virtual;
  end;

constructor TPickWindow.Init;
var
  R: TRect;
  Control: PView;
  PS: PScrollBar;
  Lis: PStringCollection;
  i: byte;
begin
  R.Assign(0, 0, 40, 20);
  inherited Init(R, 'Pick List Window');
  Options := Options or ofCentered;

  R.Assign(2, 14, 38, 15);
  PS:=New(PScrollBar, Init(R));
  Insert(PS);

  R.Assign(2, 2, 38, 14);
  D := New (PMultiSelListBox, Init (R, PS));

  Lis := New (PStringCollection, Init (10,4));
  if Lis <> Nil then
  for i := 0 to 9 do
      Lis^.Insert (NewStr ('item' + Chr (48 + i)));

  D^.NewList (Lis);
  Insert(D);

  R.Assign(15, 16, 25, 18);
  Insert(New(PButton, Init(R, '~O~k', cmOk, bfDefault)));

  SelectNext(True);
end;

procedure TPickApp.InitStatusLine;
var
  R: TRect;
begin
     GetExtent(R);
     R.A.Y := R.B.Y - 1;
     New(StatusLine, Init(R,
     NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, 1,
      NewStatusKey('~F1~ List dialog', kbF1, cmDlg,
      nil)),
     nil)));
end;

procedure TPickApp.HandleEvent(var Event: TEvent);
var
   Control: Word;
begin
     inherited HandleEvent(Event);
     if Event.What = evCommand then
     begin
          case Event.Command of
           cmDlg:
            begin
                 PickWindow := New(PPickWindow, Init);
                 control:=DeskTop^.ExecView(PickWindow);
                 Dispose(PickWindow, Done);
            end;
          end;
          ClearEvent(Event)
     end;
end;

var
  PickApp: TPickApp;

begin
     PickApp.Init;
     PickApp.Run;
     PickApp.Done;
end.