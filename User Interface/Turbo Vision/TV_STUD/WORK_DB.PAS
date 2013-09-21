unit Work_DB;

interface
uses Objects, Drivers, Views, Dialogs;

procedure CreateCollection (FN: string);
procedure SaveCollection (FN: string);
procedure LoadCollection (FN: string);

function  Search (Who: string): integer;
procedure EditRecord (index: word);
procedure AddRecord;

var
  Created: boolean;

Implementation
uses App, MsgBox, studobj, TV_obj;


procedure AbortMsg (msg: string);
 { Вывести сообщение об ошибке и выйти из программы }
begin
     MessageBox (msg ,nil, mfError+ mfOkButton);
end;


procedure CreateCollection (FN: string);
 { Создать коллекцию. Информация о фамилиях берется из текстового файла. }
var
  SI: PStudentInfo;
  Rec: TRecord;
  F: text;
  s: string;

begin
  Assign (F, FN);
  {$I-}
  Reset (F);
  {$I+}
  if IOresult <> 0 then
  begin
       AbortMsg ('Can''t open file ' + FN); { Файл не найден }
       exit
  end;

  { Build student collection }
  randomize;
  while not eof (F) do
  begin
       readln (F, s); { Чтение строки с именем }
       with Rec do
       begin
         Name := s;
         Mark := random (80)+21; {1..100}
       end;
       SI := New (PStudentInfo,Init);  { Создаем "карточку" студента }
       SI^.TransferRecord := Rec;
       PC^.Insert (SI); { Вставляем данные о студенте в коллекцию }
  end;

  close (F);
  Created := true;
end;


procedure LoadCollection (FN: string);
 { Загрузка сохраненной раннее коллекции из бинарного файла коллекции }
var
  FS: TBufStream;
begin
  FS.Init (FN, stOpen,1024);
  if FS.Status <> stOK then
  begin
       AbortMsg ('File not found.'); { Файл не найден }
       exit
  end;
  PC := PStudentsColl (FS.Get); { Вставить коллекцию из файла  }
  FS.Done;
  if FS.Status <> stOK then
     AbortMsg ('Error of loading collection.');
end;


procedure SaveCollection (FN: string);
 { Сохранить коллекцию в файл }
var
  FS: TBufStream;
begin
  FS.Init (FN, stCreate,1024); { Открываем файл коллекции на создание }
  FS.Put (PC); { Вставляем коллекцию в файл }
  FS.Done; { Закрываем работу с потоком }
  if FS.Status <> stOK then
     AbortMsg ('Error while saving collection!'); { Произошла ошибка при сохранении коллекции }
end;


function Search (Who: string): integer;
 function Matches (Item: Pointer): Boolean; far;
 begin
     Matches := PStudentInfo (Item)^.TransferRecord.Name = Who;
 end;

 var P: PStudentInfo;

begin
     P := PC^.FirstThat (@Matches);
     Search := PC^.IndexOf (P);
end;

procedure AddRecord;
var Dlg: PInfoDlg;
    Control: word;
    SI: PStudentInfo;
    Rec: TRecord;
begin
     Dlg := New (PInfoDlg, Init);
     Dlg^.Options := Dlg^.Options or ofCentered;
     Control := Desktop^.ExecView (Dlg);
     if Control = cmOk then
     begin
          Dlg^.GetData (Rec);
          SI := New (PStudentInfo,Init);
          SI^.TransferRecord := Rec;
          PC^.Insert (SI);
     end;
     Dispose (Dlg, Done);
end;

procedure EditRecord (index: word);
var Dlg: PInfoDlg;
    Control: word;
    SI: PStudentInfo;
    Rec: TRecord;
begin
     Dlg := New (PInfoDlg, Init);
     Dlg^.Options := Dlg^.Options or ofCentered;
     if Index>=0 then
     begin
          Rec := PStudentInfo (PC^.At (index))^.TransferRecord;
          Dlg^.SetData (Rec);
     end;
     Control := Desktop^.ExecView (Dlg);
     if Control = cmOk then
     begin
          Dlg^.GetData (Rec);
          SI := New (PStudentInfo,Init);
          SI^.TransferRecord := Rec;
          PC^.AtPut (index,SI);
     end;
     Dispose (Dlg, Done);
end;

end.