Unit GenreBox;

INTERFACE
uses App, Dialogs, Drivers , Views, Objects, GenreObj, ComboBox;

type
    PGenreBox = ^TGenreBox;
    TGenreBox = Object(TCombo)
      GenreIndex: byte;
      constructor Init(var Bounds : TRect; ALink : PInputline; AFlags : word);
      constructor Load(var S: TStream);
      procedure   NewList(AList: PSortedCollection); virtual;
      procedure   SetData(var Rec); virtual;
      procedure   IncrementalSearch(var Event : TEvent); virtual;
      PROCEDURE   HandleEvent(var Event : TEvent); virtual;
      function    InitListBox(var R : TRect; PSB : PScrollbar) : PListBox; virtual;
    end;

    PGenreListBox = ^TGenreListBox;
    TGenreListBox = object(TStringListBox)
      function    GetText(Item: Integer; MaxLen: Integer): String; virtual;
      procedure   HandleEvent(var Event: TEvent); virtual;
    end;

IMPLEMENTATION

function TGenreListBox.GetText(Item: Integer; MaxLen: Integer): String;
begin
{->     inherited GetText(Item,MaxLen);}
     if List<>nil
        then GetText:=PString(PGenre(List^.At(Item))^.G)^
        else GetText:='';
end;

procedure TGenreListBox.HandleEvent(var Event: TEvent);
var
  CurString, NewString: String;
  Value, OldPos, OldValue : Integer;

begin
if (Event.What = evMouseDown) and (Event.Double) then
  begin
  Event.What := evCommand;
  Event.Command := cmOK;
  PutEvent(Event);
  ClearEvent(Event);
  end
else
  begin
  OldValue := Focused;
  if Event.What = evKeyDown then
    case CtrlToArrow(Event.KeyCode) of
      kbUp, kbDown, kbPgDn, kbPgUp, kbHome, kbEnd, kbCtrlPgDn, kbCtrlPgUp:
       SearchPos := 0;
      kbEsc : Exit;
      end;
  if (Event.What <> evKeyDown) or (Event.CharCode <> ' ') then
    TListBox.HandleEvent(Event);
  if (OldValue <> Focused) then SearchPos := 0;
  if Assigned(List) and (Event.What = evKeyDown) then
    begin
    if (Event.CharCode <> #0) or (Event.KeyCode = kbLeft) then
      begin
      Value := Focused;
      if Value < Range then CurString := GetText(Value, 255)
      else CurString := '';
      OldPos := SearchPos;
      if (Event.KeyCode = kbBack) or (Event.KeyCode = kbLeft) then
       begin
       if SearchPos = 0 then Exit;
       Dec(SearchPos);
       CurString[0] := Char(SearchPos);
       end
      else
       begin
       Inc(SearchPos);
       CurString[0] := Char(SearchPos);
       CurString[SearchPos] := Event.CharCode;
       end;
{}      PGenreCollection(List)^.Search(@CurString, Value);
      if Value < Range then
       begin
       NewString := GetText(Value, 255);
       if MyCombo^.Equal(NewString, CurString, SearchPos) then
       begin
       if Value <> OldValue then
	 begin
	 FocusItem(Value);
	 SetCursor(Cursor.X+SearchPos, Cursor.Y);
	 end
       else SetCursor(Cursor.X+(SearchPos-OldPos), Cursor.Y);
       end
       else SearchPos := OldPos;
       end
      else SearchPos := OldPos;
      ClearEvent(Event);
      end;
    end;
  end;
end;

constructor TGenreBox.Init(var Bounds : TRect; ALink : PInputline; AFlags : word);
var
  R : TRect;
begin
     TView.Init(Bounds);
     Flags := AFlags;
     ILink := ALink;

     ComboList := Nil;

     ShowChar := #25;      {a thin arrow}
     ActivateCode := kbDown;  {a down arrow}
     Options := Options or ofPreProcess;
     EventMask := EventMask or evBroadcast;
     GenreIndex:=255;
end;

constructor TGenreBox.Load(var S : TStream);
begin
     inherited Load(S);
     S.Read(Flags, Ofs(ILink) - Ofs(Flags));
     GetPeerViewPtr(S, ILink);
{}     ComboList := PGenreCollection(S.Get);
end;

procedure TGenreBox.NewList(AList: PSortedCollection);
begin
if Assigned(ComboList) then Dispose(ComboList, Done);
ComboList := AList;
if Assigned(AList) and (Flags and cbxOnlyList <> 0) then
{}  PutString(PString(PGenre(AList^.At(0))^.G)^);
end;

procedure TGenreBox.SetData(var Rec);
begin
if Flags and cbxNoTransfer = 0 then
{}  NewList(PGenreCollection(Rec));
end;

procedure TGenreBox.IncrementalSearch(var Event : TEvent);
var
  CurString, NewString: String;
  Value, OldPos, OldValue, SearchPos : Integer;
begin
if Assigned(ComboList) then
  if (Event.CharCode <> #0) or (Event.KeyCode = kbLeft)
       or (Event.KeyCode = kbHome) then
    begin
    CurString := ILink^.Data^;
    SearchPos := ILink^.CurPos;
    OldPos := SearchPos;
    if (Event.KeyCode = kbBack) or (Event.KeyCode = kbLeft)
       or (Event.KeyCode = kbHome) then
      begin
      if SearchPos = 0 then Exit;
      if Event.Keycode = kbHome then SearchPos := 0
       else Dec(SearchPos);
      CurString[0] := Char(SearchPos);
      end
    else
      begin
      Inc(SearchPos);
      CurString[0] := Char(SearchPos);
      CurString[SearchPos] := Event.CharCode;
      end;
{}    if not PGenreCollection(ComboList)^.Search(ILink^.Data, OldValue)
       then OldValue := -1;
{}    PGenreCollection(ComboList)^.Search(@CurString, Value);
    if Value < ComboList^.Count then
      begin
{}      NewString :=  PString(PGenre(ComboList^.At(Value))^.G)^;
      if Equal(NewString, CurString, SearchPos) then
       with ILink^ do
       begin
       if Value <> OldValue then
	 begin
	 PutString(NewString);
	 SelectAll(True);
	 SetCursor(Cursor.X+SearchPos, Cursor.Y);
	 end
       else SetCursor(Cursor.X+(SearchPos-OldPos), Cursor.Y);
       end
      else SearchPos := OldPos;
      end
    else SearchPos := OldPos;
    ILink^.CurPos := SearchPos;
    end;
ClearEvent(Event);
end;

PROCEDURE TGenreBox.HandleEvent(var Event : TEvent);
var
  Value : integer;

  PROCEDURE PopUp;
  var
    Command : Word;
    Index : integer;
    Dlg : PView;
{->?}    PLB : PListBox;
  begin
  Dlg := Application^.ValidView(PListDialog(MakeDialog(PLB)));
  if Assigned (Dlg) then
    begin
    if Assigned(ComboList) then
      begin
{}      if not PGenreCollection(ComboList)^.Search(ILink^.Data, Index) then
       Index := 0;
      end
    else Index := 0;
{}    PGenreListBox(PLB)^.FocusItem(Index);
    Command := Owner^.ExecView(Dlg);
    if Assigned(ComboList) and (Command = cmOK) then
      begin
      Index := PGenreListBox(PLB)^.Focused;
{}      GenreIndex:=PGenre(ComboList^.At(Index))^.I^;
{}      ILink^.Data^ := PGenreListBox(PLB)^.GetText(Index, ILink^.MaxLen);
      ILink^.SelectAll(False); {nothing selected, drawview}
      Update(Index);
      end;
    Dispose(Dlg, Done);
    end;
  end;

begin
     if (Owner^.Current = PView(ILink)) and (Event.What = evKeydown) then
     begin {PreProcess of chars going to our TInputLine}
           {the active key may be either a character key or a special key with
           charcode = 0}
           if ((Char(ActivateCode) <> #0)
              and (Event.CharCode = Char(ActivateCode)))
              or (Event.KeyCode = ActivateCode) then
           begin   {actvate by key}
                   Popup;
                   ClearEvent(Event);
           end
           else if (Flags and cbxOnlyList <> 0) then
           begin   {cbxOnlyList is set}
                Event.KeyCode := CtrlToArrow(Event.KeyCode);
                case Event.CharCode of
                ' ':
                begin  {toggle to next or previous item in list}
                     if Assigned(ComboList) then
	                 begin
{}	                      if not PGenreCollection(ComboList)^.Search(ILink^.Data, Value)
                          then Value := -1;
	                      if GetShiftState and (kbRightShift or kbLeftShift) <> 0 then
	                      Dec(Value) else Inc(Value);
	                      if Value < 0 then Value := ComboList^.Count-1
	                      else if Value >= ComboList^.Count then Value := 0;
{}	                      PutString(PString(PGenre(ComboList^.At(Value))^.G)^);
	                      ILink^.SelectAll(False);
                     end;
                     ClearEvent(Event);
                end;
                ' '..#255 : IncrementalSearch(Event);
                else case Event.KeyCode of
	            kbBack, kbLeft, kbHome : IncrementalSearch(Event);
	            kbDel, kbEnd, kbIns, kbRight : ClearEvent(Event);
                end;
          end;
    end;
  end
  else if (Event.What = evMouseDown) and (MouseInView(Event.Where)) then
  begin    {activate by mouse}
       ILink^.Select;
       Popup;
       ClearEvent(Event);
  end;
  TView.HandleEvent(Event);
  if (Flags and cbxOnlyList <> 0) then
  with ILink^ do    {make sure nothing is hilited}
  if SelEnd <> SelStart then
  begin
       SelEnd := SelStart;
       DrawView;
  end;
end;

function TGenreBox.InitListBox(var R : TRect; PSB : PScrollbar) : PListBox;
var
  Rslt : PGenreListBox;
begin
     Rslt := New(PGenreListBox, Init(R, 1, PSB, @Self));
     Rslt^.GrowMode := gfGrowHiX or gfGrowHiY;
     Rslt^.NewList(ComboList);
     InitListBox := Rslt;
end;

END.