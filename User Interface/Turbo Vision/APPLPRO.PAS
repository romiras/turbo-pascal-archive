unit ApplPro;
interface
uses Dos,
     App,Drivers,Memory,Dialogs,
    {$IFDEF ExeHelp}
     ExeStrm,
    {$ENDIF}
     HelpFile,StdDlg,Gadgets,Objects,Menus,MsgBox,Views;

const
	cmHelp		  = 9100;
	cmHelpContents	  = 9101;
	cmHelpOnHelp	  = 9102;
	cmPreviousTopic   = 9103;
	cmNextTopic	  = 9104;
	cmSwitchToTopic   = 9109;

	hcHelp		  = 0;
	hcHelpWindow	  = 11111;  { Popup help's HelpCtx (for status line) }
	hcContents	  = 0;
	hcHelpIntro	  = 1;
	hcHelpOnHelp	  = 2;
	hcUsingHelp	  = 3;
	hcPreviousTopic   = 5;
	hcNextTopic	  = 6;

	PreviousTopic	= $EEEE;
{	 MaxOldTopics = 16;}
type
    PApplPro=^TApplPro;
    TApplPro=object(TApplication)
	ExeFileName    : PathStr;
	HelpFileName : PathStr;
	HelpInUse    : Boolean;
	constructor Init;
	procedure Idle;virtual;
	procedure GetEvent(var Event:TEvent); virtual;
	function  GetPalette:PPalette; virtual;
	function ExeDir:PathStr;
	procedure ShowHelp(aHelpCtx:word);
    end;
    function StdStatusHelp(Next:PStatusDef):PStatusDef;
implementation
var Heap:PHeapView;
    Clock:PClockView;

function StdStatusHelp(Next:PStatusDef):PStatusDef;
begin
  StdStatusHelp:=
    NewStatusDef(hcHelpWindow, hcHelpWindow,
      StdStatusKeys(
      NewStatusKey('~F1~ Help on Help', kbF1,	cmHelpOnHelp,
      NewStatusKey('~Alt+B~ Back',	kbAltB, cmPreviousTopic,
      NewStatusKey('~Alt+C~ Contents',	kbAltC, cmHelpContents,
      NewStatusKey('~F5~ Zoom', 	kbF5,	cmZoom,
      NewStatusKey('~Esc~ Close help',	kbEsc,	cmClose,
    Nil)))))),
  Next);
end;

function AddBackslash(const s:String):String;
begin
  if (s<>'') and not (s[Length(s)] in ['\',':']) then
    AddBackslash:=s+'\'
  else
    AddBackslash:=s;
end;

constructor TApplPro.Init;
var  R:TRect;
begin
     Inherited Init;
     GetExtent(R);
     R.A.X:= R.B.X-9;
     R.A.Y:= R.B.Y-1;
     Heap:=New(PHeapView,Init(R));
     Insert(Heap);
     GetExtent(R);
     R.A.X:=R.B.X-9;
     R.B.Y:=R.A.Y+1;
     Clock:=New(PClockView,Init(R));
     Insert(Clock);
     RegisterHelpFile;
end;

procedure TApplPro.Idle;
var  E:TEvent;
begin
  Inherited Idle;
  Heap^.Update;
  Clock^.Update;
end;
procedure TApplPro.GetEvent;
begin
  inherited GetEvent(Event);

  if Event.What=evCommand then
  begin
    case Event.Command of
      (* The usual TV help command *)
      cmHelp:	       ShowHelp(GetHelpCtx);
      (* These are status line commands and must reside in GetEvent,
	 else won't work inside (modal) Help *)
      cmPreviousTopic: ShowHelp(PreviousTopic);
      cmHelpContents:  ShowHelp(hcContents);
      cmHelpOnHelp:    ShowHelp(hcHelpOnHelp);
      else
	Exit;
    end;
    ClearEvent(Event);
  end;
end;
function TApplPro.ExeDir:PathStr;
  var
    EXEName : PathStr;
    Dir     : DirStr;
    Name    : NameStr;
    Ext     : ExtStr;
begin
  if Lo(DosVersion)>=3 then
    EXEName:=ParamStr(0)
  else
    EXEName:=FSearch(ExeFileName, GetEnv('PATH'));
  FSplit(EXEName, Dir, Name, Ext);
  ExeDir:=AddBackslash(Dir);
end;
  function TApplPro.GetPalette;
    const
      CNewColor      = CAppColor      + CHelpColor;
      CNewBlackWhite = CAppBlackWhite + CHelpBlackWhite;
      CNewMonochrome = CAppMonochrome + CHelpMonochrome;
      P : array [apColor..apMonochrome] of String[Length(CNewColor)] =
	(CNewColor, CNewBlackWhite, CNewMonochrome);
  begin
    GetPalette := PPalette(@P[AppPalette]);
  end;

procedure TApplPro.ShowHelp;
var
    W	     : PWindow;
    HFile    : PHelpFile;
    HelpStrm : PDosStream;
    Event    : TEvent;
begin
  { HelpInUse moved into the Application object }
  if HelpInUse then
  begin
    Event.What:=evCommand;
    Event.Command:=cmSwitchToTopic;
    Event.InfoWord:=aHelpCtx;
    PutEvent(Event);
  end
  else
  begin
    HelpInUse:=True;
   {$IFDEF ExeHelp}
    HelpStrm:=New(PExeScanningStream, Init(ParamStr(0), stOpenRead, magicHelpFile));
   {$ELSE}
    New(HelpStrm, Init(FSearch(HelpFileName, ExeDir), stOpenRead));
   {$ENDIF}

    New(HFile, Init(HelpStrm));
    if HelpStrm^.Status<>stOk then
    begin
      MessageBox(^C'Could not open help file', Nil, mfError+mfOkButton);
      Dispose(HFile, Done);
    end
    else
    begin
      W:=New(PHelpWindow, Init(HFile, aHelpCtx));
      if ValidView(W)<>Nil then
      begin
	W^.HelpCtx:=hcHelpWindow;
	Application^.ExecView(W);
	Dispose(W, Done);
      end;
    end;
    HelpInUse:=False;
  end;
end;
end.