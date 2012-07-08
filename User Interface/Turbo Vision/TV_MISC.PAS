type
DialogData = record
  CheckBoxData: Word;
  RadioButtonData: Word;
  InputLineData: string[128];
end;

var
  DemoDialogData: DialogData;

-------------
  with DemoDialogData do
  begin
    CheckboxData := 1;
    RadioButtonData := 2;
    InputLineData := 'Phone home.';
  end;
-------------
  Dialog^.SetData(DemoDialogData);
  Control := DeskTop^.ExecView(Dialog);
  if Control <> cmCancel then Dialog^.GetData(DemoDialogData);
-------------