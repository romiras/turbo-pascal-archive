
 Unit MulSel;

 Interface
 uses
   Dos,App,Objects,Views,Dialogs,Drivers;

 type

   TByteArray = array[0..$FF-1] of byte;
   PByteArray = ^TByteArray;

   PMultiSelListBox = ^TMultiSelListBox;
   TMultiSelListBox = object (TListBox)
     SelArr    : PByteArray;
     constructor Init (var Bounds: TRect; AScrollBar: PScrollBar);
     destructor  Done; virtual;
     procedure   SelectItem (Item: Integer); virtual;
     function    IsSelected (Item: Integer): Boolean; virtual;
     procedure   HandleEvent(var Event: TEvent); virtual;
     end;

Implementation

constructor TMultiSelListBox.Init;
begin
     Inherited Init (Bounds, 2, AScrollBar);
     New (SelArr);
     if SelArr <> Nil then
        FillChar (SelArr^, SizeOf (TByteArray), 0);
end;

destructor TMultiSelListBox.Done;
begin
     if SelArr <> Nil then
        Dispose (SelArr);
     Inherited Done
end;

function TMultiSelListBox.IsSelected;
begin
     IsSelected := (SelArr^[Item] <> 0)
end;

procedure TMultiSelListBox.SelectItem;
begin
    SelArr^[Item] := SelArr^[Item] xor 1; {switch selection: 1 <-> 0 }
    DrawView;
end;

procedure TMultiSelListBox.HandleEvent;
begin
     case Event.What of

     evMouseDown:
      begin
	  if Event.Buttons = mbRightButton then
	  begin
            SelectItem (Focused);
	  end;
       inherited HandleEvent(Event);
       ClearEvent(Event);
      end;

     evKeyDown:
      if Event.CharCode = ' ' then
      begin
        SelectItem(Focused);
	   Event.KeyCode := kbDown;
	   DrawView;
      end;
     end;

     inherited HandleEvent(Event);
end;

end.
