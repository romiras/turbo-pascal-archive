uses DOS, Objects,
     App, Menus, Drivers, Views, StdDlg, Dialogs, MSGBOX,
     studobj, TV_Obj, Work_DB;

type
     PStudList = ^TStudList;
     TStudList = Object(TListBox)
       procedure   HandleEvent(var Event: TEvent); virtual;
       function    GetText(Item: Integer; MaxLen: Integer): String; virtual;
     end;

     PStuDialog = ^TStuDialog;
     TStuDialog = object(TDialog)
       SList: PStudList;
       constructor Init;
       procedure   HandleEvent(var Event: TEvent); virtual;
     end;

     TStudentsDB= object(TApplication)
       FName: PathStr;
       procedure  InitMenuBar; virtual;
       procedure  InitStatusLine; virtual;
       procedure  HandleEvent (var Event: TEvent); virtual;

       procedure  Open;
{       procedure  Save;}
       procedure  OpenDialog;
     end;

const
     Set1: Tcommandset = [cmSave, cmViewList, cmAdd, cmEdit, cmDelete, cmSearch];


function IntToStr (i: integer): string;
var s: string[10];
begin
     Str (i, s);
     IntToStr := s
end;


procedure TStudList.HandleEvent(var Event: TEvent);
begin
  if Event.What = evMouseDown then
    if Event.Double then
    begin
      if PC^.Count<>0
          then EditRecord(focused);
      Draw;
      ClearEvent(Event);
    end;
  TListBox.HandleEvent(Event);
end;


function TStudList.GetText(Item: Integer; MaxLen: Integer): String;
begin
     with PStudentInfo(List^.At (Item))^.TransferRecord do
     GetText := Name + ' ('+IntToStr(Mark)+')';
end;


constructor TStuDialog.Init;
var
  R: TRect;
  Control : PView;
begin
R.Assign(7, 2, 72, 21);
inherited Init(R, 'Students list');
Options := Options or ofCenterX or ofCenterY;

R.Assign(47, 3, 48, 17);
Control := New(PScrollBar, Init(R));
Insert(Control);

R.Assign(3, 3, 47, 17);
SList := New(PStudList, Init(R, 1, PScrollbar(Control)));
SList^.NewList(PC);
Insert(SList);

  R.Assign(2, 2, 19, 3);
  Insert(New(PLabel, Init(R, '~L~ist of students', SList)));

R.Assign(52, 3, 62, 5);
Control := New(PButton, Init(R, '~A~dd', cmAdd, bfNormal));
Insert(Control);

R.Assign(52, 6, 62, 8);
Control := New(PButton, Init(R, '~E~dit', cmEdit, bfDefault));
Insert(Control);

R.Assign(52, 9, 62, 11);
Control := New(PButton, Init(R, '~D~elete', cmDelete, bfNormal));
Insert(Control);

R.Assign(52, 12, 62, 14);
Control := New(PButton, Init(R, '~S~earch', cmSearch, bfNormal));
Insert(Control);

R.Assign(52, 16, 62, 18);
Control := New(PButton, Init(R, '~C~lose', cmOK, bfNormal));
Insert(Control);

SelectNext(False);
end;


procedure TStuDialog.HandleEvent(var Event: TEvent);
var i: integer;
    who: string;
begin
     Inherited HandleEvent(Event);
     if Event.What = evCommand then
     case Event.Command of
        cmAdd: AddRecord;
        cmSearch:
         if PC^.Count<>0 then
         begin
              who := '';
              InputBox ('Search for...', 'Name:', who, 20);
              i := Search (who);
              if i >= 0 then
                 SList^.FocusItem (i)
                 {EditRecord(i)}
         end;
     else exit;
     end;

     ClearEvent(Event);
end;


procedure TStudentsDB.OpenDialog;
var Dlg: PStuDialog;
    Control: word;
    r: trect;
begin
     Dlg:=New(PStuDialog, Init);
     Control:=Desktop^.ExecView(Dlg);
     Dispose(Dlg, Done);
end;

procedure TStudentsDB.Open;
var FS: TDosStream;
    PF: PFILEDIALOG;
    control: word;

begin
     New(pf, init('*.dat','Open database','File name',fdOpenButton,0));
     control:= Desktop^.ExecView(PF);
     PF^.GetFilename(FName);
     Dispose(PF, Done);

     if Control = cmFileOpen then
     begin
          LoadCollection (FName);
          EnableCommands(Set1);
          OpenDialog;
     end;
end;


{procedure TStudentsDB.Save;
begin
     SaveCollection (FName);
end;}


procedure TStudentsDB.InitMenuBar;
var r:trect;
begin
   GetExtent (R);
   R. B. Y := R. A. Y + 1;
   MenuBar := NEW (PMenuBar,
      Init (R,
         NewMenu (
            NewSubMenu ('~F~ile', hcNoContext, NewMenu (
               NewItem ('~N~ew',  'Alt-N', kbAltN, cmNew, hcNoContext,
               NewItem ('~O~pen', 'F3', kbF3, cmOpen, hcNoContext,
               NewItem ('~S~ave', 'F2', kbF2, cmSave, hcNoContext,
                  NewLine (
               NewItem ('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext,
                     nil)))))),
            NewSubMenu ('~W~ork', hcNoContext, NewMenu (
               NewItem ('~V~iew List', 'F9', kbF9, cmViewList, hcNoContext,
                  NewLine (
               NewItem ('~S~earch', 'F7', kbF7, cmSearch, hcNoContext,
               NewItem ('~A~dd record', 'F5', kbF5, cmAdd, hcNoContext,
               NewItem ('~E~dit record', 'F4', kbF4, cmEdit, hcNoContext,
               NewItem ('~D~elete record', 'F8', kbF8, cmDelete, hcNoContext,
                     nil))))))), nil)))));
end;


procedure TStudentsDB.InitStatusLine;
var
   r: TRect;
begin
   GetExtent (R);
   R. A. Y := R. B. Y - 1;
   StatusLine := NEW (PStatusLine,
      Init (R,
         NewStatusDef (0, $FFFF,
         NewStatusKey ('~Alt-X~ Exit', kbAltX, cmQuit,
         NewStatusKey ('~F10~ Menu', kbF10, cmMenu,
            nil)), nil)));
end;


procedure TStudentsDB.HandleEvent(var Event: TEvent);
begin
     Inherited HandleEvent(Event);
     if Event.What = evCommand then
     case Event.Command of
{        cmSave: Save;}
{        cmNew:  CreateColl;
        FName := InputBox;
        CreateCollection (FName);}
        cmOpen: Open;
        cmViewList: OpenDialog;
     else exit;
     end;

     ClearEvent(Event);
end;


var StudentsDB: TStudentsDB;

begin
     PC:=New(PStudentsColl,Init(15,5));

     StudentsDB.Init;
     StudentsDB.Disablecommands(Set1);
     StudentsDB.Run;
     StudentsDB.Done;

     Dispose(PC, Done);
end.