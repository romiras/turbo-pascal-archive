{$X+}
 uses
   Drivers,Objects,Views,Dialogs,App,MsgBox,Strings,LFN,NatLFN;
 {--}
 Type
   PDirCollection=^TDirCollection;
   TDirCollection=object(TStringCollection)
     Constructor Init(ALimit, ADelta: Integer);
   end;

   PMyListBox=^TMyListBox;
   TMyListBox=object(TListBox)
     C: PDirCollection;
     procedure HandleEvent(var Event: TEvent); virtual;
   end;

   PMyDlg = ^TMyDlg;
   TMyDlg = object(TDialog)
     M: PMyListBox;
     constructor Init(Bounds: TRect; ATitle: TTitleStr);
   end;
 {--}
   PApp = ^TApp;
   TApp = object(TApplication)
     constructor Init;
   end;

Constructor TDirCollection.Init;
 var
  S: PString;
  ss: string;
  Info: TLFNSearchRec;
  e: word;
begin
     Inherited Init(ALimit, ADelta);
     e:=LFNFindFirst('*.',$10, Info);
     While e=0 do
     begin
          ss:= strpas(@(Info.Name));
          if ss<>'.' then Insert(NewStr(ss));
          e:=LFNFindNext(Info);
     End;
end;

procedure TMyListBox.HandleEvent(var Event: TEvent);
var
  S: String;
begin
    if ((Event.What=evMouseDown) and Event.Double) OR
       ((Event.What=evKeyDown) and (Event.KeyCode=kbEnter)) then
       begin
            S :=PString(List^.At(Focused))^;
            if s<>'.' then
            begin
                 chdir(s);
                 NewList(New(PDirCollection,Init(20,10)));
                 DrawView;
            end;
	    ClearEvent(Event);
      end;
   TListBox.HandleEvent(Event);
end;									 
 {--}
 constructor TMyDlg.Init(Bounds: TRect; ATitle: TTitleStr);
 var
   R: TRect;
   B: PView;
 begin
   Inherited Init(Bounds, ATitle);
   Options := Options or ofCentered;
   R.Assign (24,1,25,10);
   B := New(PScrollBar,Init (R));
   Insert(B);
   R.Assign (2,1,24,10);
   M := New (PMyListBox,Init (R,1,PScrollBar(B)));
   Insert(M);
   M^.NewList(New(PDirCollection,Init(20,10)))
 end;

 constructor TApp.Init;
 var
   R: TRect;
   D: PDialog;
 begin
   TApplication.Init;
   R.Assign (0,0,27,15);
   D := New (PMyDlg,Init (R,'Dir list'));
   DeskTop^.ExecView (D);
 end;
 {--}
var
   A: TApp;
begin
   A.Init;
   A.Run;
   A.Done;
end.