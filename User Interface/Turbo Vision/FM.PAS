
(* 컴컴컴컴컴컴컴컴컴컴컴컴컴� FileModifier v2.1 컴컴컴컴컴컴컴컴컴컴컴컴컴 *)
Uses
{     VControl,}
     CRT,
     Convert,
     DOS,
     App,dialogs,objects,drivers,views,menus,procs,
     memory,stddlg,msgbox,gadgets,
     Progress;
Const
       VERSION=' File Modifier	   v2.2 (C) 2000';
{       opt=4; { count of ChkBoxes options }
       cmQuit	  =1001;
       cmFDlg	  =1002;
       cmTPTC	  =1003;
       cmRun	  =1004;
       cmAll	  =1005;
       cmCD	  =1006;
       cmCDW	  =1007;
{	cmDbClick  =1008;{}
Type
       DialogData = record
	InpLineData: string[12];
	ChkBoxData: word;
       end;

Var
       Heap:PHeapView;
       Clock:PClockView;
       DataRec: DialogData;
       DataRec2: word; {RadioButtons}
       i:byte;
{       CB,RD: word;
       IL: string[12];}
       PCount:integer;
Type
    PFM=^TFM;
    TFM=object(TApplication)
       constructor Init;
       procedure InitMenuBar;virtual;
       procedure HandleEvent(var Event:TEvent); virtual;
{	procedure Idle;virtual;}
       procedure FreshFiles;
       procedure DisplayBox; virtual;
       procedure FormatDlg;
       procedure TPTCDialog;
    end;
    PFileListBox=^TFileListBox;
    TFileListBox=object(TListBox)
       PFL:PStringCollection;
       MarkL:byte;
       procedure HandleEvent(var Event:TEvent);virtual;
       procedure GetDir(WC:string);
       procedure MarkF(var s:string);
       procedure DeMarkF(var s:string);
       procedure SetAll;
    end;

    PInpLine=^TInpLine;
    TInpLine=object(TInputLine)
       procedure HandleEvent(var Event:TEvent);virtual;
    end;

    PFreshFileBox=^TFreshFileBox;
    TFreshFileBox=object(TDialog)
       WildC:string;
       PL:PFileListBox;
       PInl:PInpLine;
       PDir:PStaticText;
       procedure HandleEvent(var Event:TEvent);virtual;
       procedure SetFiles;
    end;
var MyFMProg:TFM;

Constructor TFM.Init;
var  R:TRect;
begin
     Inherited Init;
     GetExtent(R);
     R.A.X:= R.B.X - 9;
     R.A.Y:= R.B.Y - 1;
{     Insert(New(PHeapView,Init(R)));}
     GetExtent(R);
     R.A.X:=R.B.X-9;
     R.B.Y:=R.A.Y+1;
 {    Insert(New(PClockView,Init(R)));}
     PCount:=0;
end;
{
procedure TFM.Idle;
var  E:TEvent;
begin
       Inherited Idle;
       Heap^.Update;
       Clock^.Update;
end;
}
procedure TFM.DisplayBox;
begin
   MessageBox(#3'Welcome to File Modifier!',
   nil, mfInformation or mfOkButton);
end;

procedure TFM.InitMenuBar;
var R: TRect;
begin
  GetExtent(R);
  R.B.Y:=R.A.Y+1;
    MenuBar := New(PMenuBar, Init(R, NewMenu(
      NewSubMenu('~F~ile', hcNoContext, NewMenu(
       NewItem('~F~ormat Dialog ', 'F4', kbF4, cmFDlg, hcNoContext,
       NewItem('~T~PTC', 'F5', kbF5, cmTPTC, hcNoContext,
      nil))),
    Nil))));
end;

procedure TFM.HandleEvent(var Event:TEvent);
begin
     inherited HandleEvent(Event);
     if Event.What = evCommand then
	 case Event.command of
              cmFDlg: begin FormatDlg; FreshFiles; end;
	      cmTPTC: TPTCDialog;
	 else exit;
	 end;
     ClearEvent(Event);
end;

procedure TFM.FormatDlg;
var
  Dlg : PDialog;
  R : TRect;
  Control: PView;
Begin
        R.Assign(26,5,53,18);
        New(Dlg, Init(R, 'Format Options'));

        R.Assign(6,3,21,9);
        Control := New(PRadiobuttons, Init(R,
          NewSItem('~F~ormat  ',
          NewSItem('~D~owncase',
          NewSItem('~U~pcase  ',
          NewSItem('~E~xprPack',
          NewSItem('Pas2~C~   ',
          NewSItem('Pre~P~roc ',
           Nil))))))));
          Dlg^.Insert(Control);

          R.Assign(9,10,17,12);
          Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
          Dlg^.Insert(Control);
          Dlg^.SelectNext(False);

          if DeskTop^.ExecView(Dlg) <> cmCancel
	     then Dlg^.GetData(DataRec2);
          Dispose(Dlg,done);
end;

Procedure TFM.Freshfiles;
Var    R,RR: TRect;
       Path0: string[80];
       PW: PFreshFileBox;
       Asb: PScrollBar;
       P: PView;
Const
       wildcard: string='*.pas';
begin
     getdir(0,path0);
     r.assign(18,2,60,20);
     pw:=new(pfreshfilebox,Init(r,''));
     with pw^ do begin

     wildc:=wildcard;

     r.assign(7,3,18,4);
     p:=new(plabel,Init(r,'File ~m~ask:',pinl));
     Insert(p);

     r.assign(19,3,31,4);
     pinl:=new(pinpline,Init(r,12));
     with pw^.PINL^ do
	 state:=state or sfCursorVis;
     pinl^.data^:=wildcard;
     Insert(pinl);

     r.assign(31,3,33,4);
     p:=new(phistory,Init(r,pinl,1));
     Insert(p);

     r.assign(2,5,35,6);
     PDir:=new(pstatictext,Init(r,'Path: '+path0));
     Insert(pw^.pdir);

     r.assign(2,8,39,14);
     rr.assign(39,8,40,14);
     asb:=new(pscrollbar,Init(rr));
     Insert(asb);

     new(pl,Init(r,2,asb));
     pl^.getdir(wildcard);
     Insert(PL);

     pl^.markL:=15;
     r.assign(2,7,14,8);
     p:=new(plabel,Init(r,'File ~l~ist:',PL));
     Insert(p);
     r.assign(1,15,15,17);
     Insert(new(PButton,Init(r,'Select ~A~ll',cmAll,bfnormal)));
     r.assign(16,15,30,17);
     Insert(new(PButton,Init(r,'Change ~D~ir',cmCD,bfnormal)));
     r.assign(31,15,40,17);
     Insert(new(PButton,Init(r,'~R~un',cmRun,bfDefault)));
     SelectNext(False);
     end;
     DeskTop^.ExecView(pw);
     Dispose(pw,done);
     chdir(path0)
end;

procedure TFM.TPTCDialog;
var
       Dlg: PDialog;
       R: TRect;
       Control: PView;
       Control2: word;
begin
     R.Assign(20, 3, 60, 20);
     New(Dlg, Init(R, 'TPTC Options'));

     with Dlg^ do
     begin
	  R.Assign(9,2,31,3);
	  Insert(New(PStaticText,Init(r,'Translate  Pascal to C')));
	  R.Assign(12, 5, 26, 6);
	  Control:=New(PInputLine, Init(R, 12));
	  Insert(Control);
	  R.Assign(12, 4, 24, 5);
	  Insert(New(PLabel, Init(R, '~O~utput file', Control)));

	  R.Assign(4, 8, 36, 12);
	  Insert(New(PCheckBoxes, Init(R,
	    NewSItem('Use ~M~T+ specifications',
	    NewSItem('~L~ower case of identifiers',
	    NewSItem('~N~o comments',
	    NewSItem('~Q~uiet mode',
          Nil)))))));

	  R.Assign(8, 14, 18, 16);
	  Insert(New(PButton, Init(R, 'O~K~', cmOK, bfDefault)));
	  R.Assign(22, 14, 32, 16);
	  Insert(New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal)));
	  SelectNext(False);
     end;
     Dlg^.SetData(DataRec);
     if DeskTop^.ExecView(Dlg) <> cmCancel
	then Dlg^.GetData(DataRec);
     Dispose(Dlg,done);
end;

procedure TFreshFileBox.HandleEvent;
var S:string;
    PCD:PChDirDialog;
    C:word;
    R:TRect;
label l1,all;
begin
     TDialog.HandleEvent(Event);
     case Event.what of
     evbroadcast: case Event.command of
		 cmCDW:
		 begin
		 L1:  s:=pinl^.data^;
		      pl^.list:=nil;
		      dispose(pl^.pfl,done);
		      wildc:=s;
		      pl^.getdir(s)
		 end;
{		  cmDBClick:
		 begin
		    s:=PString(pl^.list^.at(pl^.focused))^;
		 end;}
		 end;
     evcommand: case Event.command of
	       cmCD: begin
			  new(PCD,Init(0,0));
			  c:=desktop^.execview(pcd);
			  getdir(0,s);
			  dispose(pdir,done);
			  r.assign(2,5,35,6);
			  pdir:=new(pstaticText,Init(r,#3+'Directory  '+s));
			  Insert(pdir);
			  goto l1;
		     end;
	       cmAll:begin
		     All:
			  pl^.SetAll;
			  pl^.draw;
		     end;
	       cmRun: Setfiles;
	       end;
     evkeydown: case Event.keycode of
	       kbLeft:	Selectnext(true);
	       kbRight: Selectnext(false);
	       kbGrayPlus: goto All
	       end;
     end;
     ClearEvent(Event)
end;
procedure TFreshFileBox.SetFiles;
var s,ss:string;
    k:integer;
    r:TRect;
    ps:pstring;
var
  i,cnt:integer;
  Dlg: TDialog;
  MyBar: PGrowView;

begin
     R.Assign( 22, 5, 58, 10);
     Dlg.Init (R, 'Progress');
     Dlg.Flags := Dlg.Flags and not wfClose;
     R.assign( 2, 2, 34, 3);
     i:=PCount;
     cnt:=0;
     MyBar:=New( PGrowView, Init(r, i));
     Dlg.Insert(MyBar);
     Desktop^.Insert(@Dlg);

     with pl^,pfl^ do
     for k:=0 to count-1 do
     begin
	 s:=getText(k,255);
	 if s[length(s)]=#251 then
	 begin
	      DemarkF(s);
	      inc(cnt);
	      system.getdir(0,ss);
	      if ss[length(ss)]<>'\' then ss:=ss+'\';
	      ss:=ss+s;
	      r.assign(1,1,48,2);
	      case DataRec2+1 of
	      1: ProcSF(ss);
	      2: ProcSd(ss);
	      3: ProcSU(ss);
	      4: ExprPack(ss);
	      5: Pas2C(ss);
	      6: PreProc(ss);
              else break;
	      end;
	      MyBar^.Update(cnt);
	      R.Assign(2,3,25,4);
	      Dlg.Insert(New( PStaticText, Init(R, s)));
	      R.Assign(25,3,35,4);
	      Dlg.Insert(New( PStaticText,
		  Init(R, I2S(MyBar^.Percent(cnt,i))+'% done')));
	      PS:=At(k);
	      PS^:=s
	 end
     end;
     Dlg.Done;
     pl^.Draw
end;

procedure TInpLine.HandleEvent;
begin
     TInputLine.HandleEvent(Event);
     if (Event.what=evkeydown) and (Event.keycode=kbenter)
       then Message(owner,evbroadcast,cmCDW,@self);
end;

procedure TFileListBox.SetAll;
var s:string;
    k:integer;
begin
     with pfl^ do
     for k:=0 to count-1 do
     begin
	 s:=gettext(k,255);
	 if s[length(s)]<>#251 then MarkF(s)
			       else DeMarkF(s);
	 atfree(k);
	 Insert(newstr(s));
     end
end;

procedure TFileListBox.GetDir(wc:string);
var sr:searchRec;
begin
     if (wc='*.*') or (wc='*') then wc:='*.pas';
     pfl:=new(PStringCollection,Init(10,5));
     Findfirst(wc,$27,sr);
     while doserror=0 do
     begin
	 if (sr.name<>'.') and (sr.name<>'..')
	    then pfl^.Insert(newstr(sr.name));
	 findnext(sr)
     end;
     Self.newlist(pfl)
end;

procedure TFileListBox.HandleEvent;
var s:string;
begin
     if ( (Event.What = evMouseDown) and (Event.Double)
       or (Event.what = evkeydown) and (Event.CharCode =' ') )
{	 then Message(Owner,evBroadCast,cmDbClick,list^.at(focused))}
{}	 then
	 begin
	      s:=gettext(focused,255);
	      pfl^.atfree(focused);
	      if s[length(s)]=#251 then DeMarkF(s)
				   else MarkF(s);
	      pfl^.Insert(newstr(s));
	      Event.keycode:=kbdown;
	      draw;
	      TListBox.HandleEvent(Event)
	 end
{}   else if   (Event.what=evkeydown) and (Event.KeyCode=kbGrayPlus)
	 then Message(@self,evcommand,cmAll,@self)
     else inherited HandleEvent(Event);
end;

procedure TFileListBox.MarkF(var s:string);
begin
     while length(s)<markL do s:=s+' ';
     inc(PCount);
     s:=s+#251
end;

procedure TFileListBox.DeMarkF(var s:string);
begin
     while (s[length(s)]=#251) or (s[length(s)]=' ')
	  do system.delete(s,length(s),1);
     dec(PCount);
end;

(* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� MAIN 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� *)
BEGIN
	Writeln(VERSION);
{	 VControl;}

	DataRec.InpLineData := 'filename.ext';
	DataRec.ChkBoxData := 0;

	MyFMProg.Init;
	MyFMProg.DisplayBox;
	MyFMProg.Run;
	MyFMProg.Done;

{        with DataRec do
	begin
	    IL:=InpLineData;
	    CB:=ChkBoxData;
	end;}
END.