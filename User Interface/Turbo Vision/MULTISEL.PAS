
 Unit MultiSel;

 Interface
 uses
   Dos,App,Objects,Views,Dialogs,Drivers;

 type
   PSelStr = ^TSelStr;
   TSelStr = object (TObject)
     Selected: Boolean;
     Name: PString;
     constructor Init (AName: String);
     function    GetSel: Boolean;
     procedure   SetSel (AState: Boolean);
     destructor  Done; virtual;
     end;

   PSelStrCollection = ^TSelStrCollection;
   TSelStrCollection = object (TSortedCollection)
     Sel: PSelStr;
     constructor Init(ALimit, ADelta: Integer);
     function    Compare (Key1,Key2: Pointer): Integer; virtual;
     end;

   PMultiSelListBox = ^TMultiSelListBox;
   TMultiSelListBox = object (TListBox)
     C: PSelStrCollection;
     constructor Init(var Bounds: TRect; AScrollBar: PScrollBar);
     function    GetText (Item: Integer; MaxLen: Integer): String; virtual;
     procedure   SelectItem (Item: Integer); virtual;
     function    IsSelected(Item: Integer): Boolean; virtual;
     procedure   HandleEvent(var Event: TEvent); virtual;
     end;

Implementation

 constructor TSelStr.Init;
 begin
      Inherited Init;
      Name := NewStr (AName);
      Selected := False;
 end;

 function TSelStr.GetSel: Boolean;
 begin
      GetSel := Selected;
 end;

 procedure TSelStr.SetSel (AState: Boolean);
 begin
      Selected := AState;
 end;

 destructor TSelStr.Done;
 begin
      DisposeStr (Name);
      Inherited Done;
 end;

constructor TSelStrCollection.Init;
begin
     Inherited Init(ALimit, ADelta);
     Sel:=nil;
end;

 function TSelStrCollection.Compare;
 begin
      if PSelStr (Key1)^.Name^ < PSelStr (Key2)^.Name^ then Compare := -1
      else if PSelStr (Key1)^.Name^ > PSelStr (Key2)^.Name^ then Compare := 1
      else Compare := 0;
 end;

constructor TMultiSelListBox.Init;
begin
     Inherited Init(Bounds, 2, AScrollBar);
end;

 function TMultiSelListBox.GetText;
 begin
      GetText := PSelStr(List^.At (Item))^.Name^
 end;

 procedure TMultiSelListBox.SelectItem;
 begin
      with C^ do
      begin
           Sel:=PSelStr(List^.At (Item));
           Sel^.SetSel (not Sel^.GetSel);
      end;
      DrawView;
 end;

function TMultiSelListBox.IsSelected;
begin
     IsSelected:=PSelStr(List^.At (Item))^.Selected;
end;

procedure TMultiSelListBox.HandleEvent;
begin
     case Event.What of
     evMouseDown:
      begin
{	  if Event.Double then
	  begin
               Message(Owner,evCommand,cmViewInfo,list^.at(focused));
	  end;}
	  if Event.Buttons=mbRightButton then
	  begin
               inherited HandleEvent(Event);
               SelectItem(Focused);
	  end;
          inherited HandleEvent(Event);
          ClearEvent(Event);
      end;
     evKeyDown:
      if Event.CharCode=' ' then
      begin
           SelectItem(Focused);
	   Event.KeyCode:=kbDown;
	   Draw;
      end;
     end;
     inherited HandleEvent(Event);
end;

end.