Unit TV_Obj;

Interface
uses Objects, Drivers, Dialogs;

type
  DataRec = record
    _Name : String[30];
    _Mark : String[4];
    end;
  PDataRec = ^DataRec;

  { TInfoDlg }

  PInfoDlg = ^TInfoDlg;
  TInfoDlg = object(TDialog)
    constructor Init;
  end;

  PStuDialog = ^TDialog;


const
     cmViewList = 100;
     cmAdd        = 110;
     cmEdit       = 111;
     cmDelete     = 112;
     cmSearch     = 113;
     cmSave       = 120;


Implementation
uses Views, MsgBox, Studobj;


{ TInfoDlg }

constructor TInfoDlg.Init;
var
  R: TRect;
  Control : PView;
begin
R.Assign(12, 4, 52, 15);
inherited Init(R, 'Student info');

R.Assign(17, 7, 27, 9);
Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
Insert(Control);

R.Assign(28, 7, 38, 9);
Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
Insert(Control);

R.Assign(4, 4, 36, 5);
Control := New(PInputLine, Init(R, 30));
Insert(Control);

  R.Assign(4, 3, 9, 4);
  Insert(New(PLabel, Init(R, '~N~ame', Control)));

R.Assign(4, 7, 8, 8);
Control := New(PInputLine, Init(R, 4));
Insert(Control);

  R.Assign(4, 6, 9, 7);
  Insert(New(PLabel, Init(R, '~M~ark', Control)));

SelectNext(False);
end;


end.
