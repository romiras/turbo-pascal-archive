unit setbox;
{ListBox для множественного выбора}
{ Отметка элемента пробелом или двойным нажатием кнопки мыши}
{Методы GetData и SetData работают с записью вида}
{ record                                         }
{   List:PCollection;                            }
{   Selected:Set of 0..255;                      }
{ Проверки на List^.Сount<=255 нет               }
interface
uses objects,drivers,views,dialogs;
Type
    TSet = set of 0..255;
    PSetBox = ^TSetBox;
    TSetBox = Object (TListBox)
              Selected:TSet;
              Procedure HandleEvent(var Event:TEvent);virtual;
              Procedure SetData(var Rec);virtual;
              Procedure GetData(var Rec);virtual;
              Procedure NewList(Alist:PCollection);virtual;
              {Do not override this method!! override GetItemText if needed}
              function GetText(Item: Integer; MaxLen: Integer): String; virtual;
              function GetItemText(Item: Integer; MaxLen: Integer): String; virtual;
              Function DataSize:Word;virtual;
             end;
implementation
 Function TSetBox.DataSize;
 begin
  DataSize:=SizeOf(List)+SizeOf(Selected);
 end;
 Procedure TSetBox.GetData(var Rec);
 var R:record
        List:Pointer;
        Selected:TSet
       end absolute Rec;
 begin
  R.List:=List;
  R.Selected:=Selected;
 end;
 Procedure TSetBox.SetData(var Rec);
 var R:record
        List:Pointer;
        Selected:TSet
       end absolute Rec;
 begin
  NewList(R.List);
  Selected:=R.Selected;
 end;
 Procedure TSetBox.NewList(Alist:PCollection);
 begin
  TListBox.NewList(AList);
  Selected:=[];
 end;
 function TSetBox.GetItemText(Item: Integer; MaxLen: Integer): String;
 begin
  GetItemText:=TListBox.GetText(Item,MaxLen);
 end;
 function TSetBox.GetText(Item: Integer; MaxLen: Integer): String;
 var C:Char;
 begin
  if Item in Selected then C:='' else C:=' ';
  GetText:=C+GetItemText(Item,Pred(MaxLen));
 end;
 Procedure TSetBox.HandleEvent(var Event:TEvent);
 var ChangeSelection:Boolean;
 begin
  ChangeSelection:= ((Event.What=evKeyDown)and(Event.CharCode=' '))or
  ((Event.What=evMouseDown) and  Event.Double and MouseInView(Event.Where));
  TListBox.HandleEvent(Event);
  if  ChangeSelection then
   begin
    if Focused in Selected then Selected:=Selected - [Focused] else
     Selected:=Selected+[Focused];
     DrawView;
   end;
 end;
end.