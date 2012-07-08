{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on TinyWeb Server by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}

{$DEFINE AsUnit}

{$IFDEF AsUnit} UNIT Setups; INTERFACE {$ENDIF}

USES
  ObjType,
  Dos,
  Objects,
  Drivers,
  Views,
  Dialogs,
{$IFNDEF AsUnit}
  Menus,
  DNApp,
{$ELSE}
  DNApp,
{$ENDIF}
  Commands,
  RStrings,
  Startup;

{$IFNDEF AsUnit}
TYPE
  TMyApp = Object( TApplication )
    procedure InitMenuBar; virtual;
    procedure HandleEvent( var Event: TEvent ); virtual;
  end;

CONST
  cmInterface = 300;
  cmMouse = 301;
  cmSavers = 302;
  cmStartUp = 303;
  cmSystem = 304;
  cmCountry = 305;
{$ENDIF}

{                                System Setup
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
TYPE
  TSysData = record
    Options: Word;
    Mode1: String[5];
    Mode2: String[5];
    Drives: TTextListboxRec;
    Current: Word;
    Temp: PathStr;
  end;

  PSysDialog =^TSysDialog;
  TSysDialog = Object( TDialog )
    LocalData: TSystemData;
    SysData: TSysData;
    {constructor Init;}
    procedure Awaken; virtual;
    destructor Done; virtual;
    procedure GetData( var Rec ); virtual;
  end;

  PCurrDriveInfo =^TCurrDriveInfo;
  TCurrDriveInfo = Object( TCheckBoxes )
    procedure HandleEvent( var Event: TEvent ); virtual;
    procedure Press( Item: Integer ); virtual;
  end;

  PMouseDialog =^TMouseDialog;
  TMouseDialog = Object( TDialog )
    constructor Init;
  end;

  PMouseBar =^TMouseBar;
  TMouseBar = Object( TScrollBar )
    constructor Init( var Bounds: TRect );
    procedure SetData( var Rec ); virtual;
    procedure GetData( var Rec ); virtual;
    function DataSize: Word; virtual;
    procedure HandleEvent( var Event: TEvent ); virtual;
  end;

  PSaversDialog =^TSaversDialog;
  TSaversDialog = Object( TDialog )
    constructor Init;
    destructor Done; virtual;
    procedure Awaken; virtual;
  end;

  PSaversListBox =^TSaversListBox;
  TSaversListBox = Object( TListBox )
    procedure HandleEvent( var Event: TEvent ); virtual;
  end;

  PUpperTable = ^TUpperTable;
  TUpperTable = object(TView)
    Table: Array[0..127] of Char;
    CurrentChar: Integer;
    Delta: Integer;
    constructor Init(var R: TRect);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    function GetPalette: PPalette; virtual;
  end;


CONST
  RSysDialog: TStreamRec = (
     ObjType: otSysDialog;
     VmtLink: Ofs(TypeOf(TSysDialog)^);
     Load:    @TSysDialog.Load;
     Store:   @TSysDialog.Store
  );

  RCurrDriveInfo: TStreamRec = (
     ObjType: otCurrDriveInfo;
     VmtLink: Ofs(TypeOf(TCurrDriveInfo)^);
     Load:    @TCurrDriveInfo.Load;
     Store:   @TCurrDriveInfo.Store
  );

  RMouseDialog: TStreamRec = (
     ObjType: otMouseDialog;
     VmtLink: Ofs(TypeOf(TMouseDialog)^);
     Load:    @TMouseDialog.Load;
     Store:   @TMouseDialog.Store
  );

  RMouseBar: TStreamRec = (
     ObjType: otMouseBar;
     VmtLink: Ofs(TypeOf(TMouseBar)^);
     Load:    @TMouseBar.Load;
     Store:   @TMouseBar.Store
  );

  RSaversDialog: TStreamRec = (
     ObjType: otSaversDialog;
     VmtLink: Ofs(TypeOf(TSaversDialog)^);
     Load:    @TSaversDialog.Load;
     Store:   @TSaversDialog.Store
  );

  RSaversListBox: TStreamRec = (
     ObjType: otSaversListBox;
     VmtLink: Ofs(TypeOf(TSaversListBox)^);
     Load:    @TSaversListBox.Load;
     Store:   @TSaversListBox.Store
  );

  RUpperTable: TStreamRec = (
     ObjType: otUpperTable;
     VmtLink: Ofs(TypeOf(TUpperTable)^);
     Load:    @TUpperTable.Load;
     Store:   @TUpperTable.Store
  );

procedure SetupCountryInfo;
procedure FMDefaults;
procedure FMSetup;
procedure DriveInfoSetup;
procedure SetupEditorDefaults;
procedure SystemSetup;
procedure InterfaceSetup;
procedure StartupSetup;
procedure MouseSetup;
procedure SaversSetup;
procedure ConfirmSetup;
function TerminalSetup: boolean;
function SetupColumnDefaults: boolean;

{$IFDEF AsUnit}
FUNCTION MakeSaversDialog: PDialog;
{
FUNCTION MakeStartupDialog: PDialog;
FUNCTION MakeInterfaceDialog: PDialog;
FUNCTION MakeMouseDialog: PDialog;
}
IMPLEMENTATION
uses Tree, Drives, Advance, Messages, DNHelp;
{$ENDIF}

procedure ConfirmSetup;
begin
  If ExecResource( dlgConfirmations, Confirms ) <> cmOK then Exit;
  ConfigModified := On;
end;

function TerminalSetup;
begin
  TerminalSetup := Off;
  If ExecResource( dlgSetupTerminal, TerminalDefaults ) <> cmOK then Exit;
  TerminalSetup := On;
  Message(Application, evCommand, cmUpdateConfig, nil);
end;

procedure SystemSetup;
 var W: Word;
     D: PDialog;
     B: Boolean;
     Data: TSysData;
begin
 OpenResource; if Resource = nil then Exit;
 D := PDialog(Application^.ValidView(PDialog(Resource^.Get( dlgSystemSetup ))));
 If D = nil then Exit;
 W := Desktop^.ExecView(D);
 If W <> cmCancel then begin
   D^.GetData(Data);
   SystemData := PSysDialog( D )^.LocalData;
   Message(Application, evCommand, cmUpdateConfig, nil);
 end;
 Dispose(D, Done);
end;

procedure InterfaceSetup;
  var AltTab: Boolean;
      R: TRect;
begin
  with PApplication(Application)^ do
  If ExecResource( dlgInterfaceSetup, InterfaceData ) <> cmCancel then begin
    GetExtent( R );
    if InterfaceData.Options and ouiHideMenu = 0 then Inc(R.A.Y);
    if InterfaceData.Options and ouiHideStatus = 0 then Dec(R.B.Y);
    if InterfaceData.Options and ouiHideCmdline = 0 then Dec( R.B.Y );
    Desktop^.Locate( R );
    R.A.Y := R.B.Y;
    R.B.Y := R.A.Y + Byte(InterfaceData.Options and ouiHideCmdline = 0);
    CommandLine^.Locate( R );
    CommandLine^.SetState( sfVisible, InterfaceData.Options and ouiHideCmdline = 0 );
    Message(Application, evCommand, cmUpdateConfig, nil);
    if InterfaceData.Options and ouiClock <> 0 then
      if not Clock^.GetState(sfVisible) then Clock^.Show;
    if InterfaceData.Options and ouiClock = 0 then
      if Clock^.GetState(sfVisible) then Clock^.Hide;
  end;
end;

procedure StartupSetup;
var
  Data: Record
    Load, Unload, Slice: Word;
    OvrBuf: String[ 3 ];
  end;
  W: Word;
  R: Integer;
label
  Retry;
begin
  Data.Load := StartupData.Load;
  Data.Unload := StartupData.Unload;
  Data.Slice := StartupData.Slice;
Retry:
  Data.OvrBuf := ItoS( StartupData.OvrSize );
  If ExecResource( dlgStartupSetup, Data ) <> cmCancel then begin
    Val( Data.OvrBuf, W, R );
    If ( W < 64 ) or ( W > 200 ) or ( R > 0 ) then begin
      Msg( erInvalidOvrSize, NIL, mfError + mfOKButton );
      goto Retry;
    end;
    StartupData.Load := Data.Load;
    StartupData.Unload := Data.Unload;
    StartupData.Slice := Data.Slice;
    StartupData.OvrSize := W;
    LSliceCnt := -3;
    Message(Application, evCommand, cmUpdateConfig, nil);
  end;
end;

procedure MouseSetup;
begin
  if ExecResource( dlgMouseSetup, MouseData ) <> cmOK then Exit;
  if StdMouse xor (MouseData.Options and omsCursor <> 0) then begin
    DoneEvents;
    InitEvents;
  end;
  MouseReverse := MouseData.Options and omsReverse <> 0;
  SetMouseSpeed(MouseData.HSense, MouseData.VSense);
  Message(Application, evCommand, cmUpdateConfig, nil);
end;

procedure SaversSetup;
 var W: Word;
     D: PDialog;
     B: Boolean;
begin
  OpenResource; if Resource = nil then Exit;
  D := PDialog(Application^.ValidView(PDialog(Resource^.Get( dlgSaversSetup ))));
  If D = nil then Exit;
  W := Desktop^.ExecView( D );
  If W <> cmCancel then begin
    D^.GetData( SaversData );
    Message(Application, evCommand, cmUpdateConfig, nil);
  end;
  Dispose( D, Done );
end;

procedure SetupCountryInfo;
begin
  if ExecResource(dlgCountrySetup, CountryInfo) <> cmOK then Exit;
  GlobalMessage(evCommand, cmReboundPanel, nil);
  ConfigModified := On;
end;

procedure FMDefaults;
begin
  if ExecResource(dlgFMDefaults, Startup.PanelDefaults ) <> cmOK then Exit;
  Message(Application, evCommand, cmUpdateConfig, nil);
  GlobalMessage(evCommand, cmReboundPanel, nil);
end;

procedure FMSetup;
begin
  if ExecResource(dlgFMSetup, Startup.FMSetup) <> cmOK then Exit;
  Message(Application, evCommand, cmUpdateConfig, nil);
  GlobalMessage(evCommand, cmReboundPanel, nil);
end;

procedure DriveInfoSetup;
begin
  if ExecResource(dlgDriveInfoSetup, Startup.DriveInfoData) <> cmOK then Exit;
  Message(Application, evCommand, cmUpdateConfig, nil);
  GlobalMessage(evCommand, cmReboundPanel, nil);
end;

procedure SetupEditorDefaults;
begin
  if ExecResource(dlgEditorDefaults, EditorDefaults) = cmOK then
    Message(Application, evCommand, cmUpdateConfig, nil);
end;


function SetupColumnDefaults: Boolean;
begin
  SetupColumnDefaults := ExecResource(dlgColumnsDefaults, ColumnsDefaults) = cmOK;
end;

PROCEDURE TCurrDriveInfo.HandleEvent;
var
  W: Word;
  Data: TSysData;
begin
  inherited HandleEvent( Event );
  If ( Event.What = evBroadcast ) and ( Event.Command = cmScrollBarChanged ) then begin
    W := PSysDialog( Owner )^.LocalData.Drives[ Char( Byte( 'A' ) + PScrollBar( Event.InfoPtr )^.Value ) ];
    SetData( W );
  end else
  If ( Event.What = evKeydown ) and ( Event.CharCode = ' ' ) and ( TypeOf( Owner^.Current^ ) = TypeOf( TListBox ))
    then Press( 0 );
end;

PROCEDURE TCurrDriveInfo.Press;
var
  Data: TSysData;
begin
  inherited Press( Item );
  Owner^.GetData( Data );
  PSysDialog( Owner )^.LocalData.Drives[ Char( Byte( 'A' ) + Data.Drives.Focus ) ] := Value;
end;

(*
CONSTRUCTOR TSysDialog.Init;
var
  R: TRect;
  Control, Labl: PView;
begin

  R.Assign(0,0,63,21);
  inherited Init(R, GetString(dlSystemSetup));
  Options := Options or ofCentered;
  HelpCtx := hcSystemSetup;

  R.Assign(3,3,60,7);
  Control := New(PCheckboxes, Init(R,
    NewSItem(GetString(dlSysInternal_E_ditor),
    NewSItem(GetString(dlSysInternal_V_iewer),
    NewSItem(GetString(dlUseSysClip),
    NewSItem(GetString(dlSys_S_howHiddenFiles),
    NewSItem(GetString(dlSys_F_astCommand),
    NewSItem(GetString(dlSysD_i_sableXMSEMS),
    NewSItem(GetString(dlSysDetectAccess),
    NewSItem(GetString(dlSysClearRO),
    Nil))))))))));
  Insert(Control);

  FreeStr := GetString(dlSys_O_ptions);
  R.Assign(3,2,5+Length(FreeStr),3);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Insert(Labl);

  FreeStr := GetString(dlSysVideoMode1);

  R.Assign(3+Length(FreeStr), 8, 30, 9);
  Control := New(PInputLine, Init(R, 5));
  Insert(Control);

  R.Assign(2, 8, 3+Length(FreeStr), 9);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Insert(Labl);

  FreeStr := GetString(dlSysVideoMode2);
  R.Assign(33+Length(FreeStr),8,59,9);
  Control := New(PInputLine, Init(R, 5));
  Insert(Control);

  R.Assign(32,8,33+Length(FreeStr),9);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Insert(Labl);

  R.Assign(18,11,19,19);
  Control := New(PScrollbar, Init(R));
  Insert(Control);

  R.Assign(3,11,18,19);
  Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
  Insert(Control);

  FreeStr := GetString(dlSys_D_rives);
  R.Assign(3,10,5+Length(FreeStr),11);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Insert(Labl);

  R.Assign(20,11,58,14);
  Control := New(PCurrDriveInfo, Init(R,
    NewSItem(GetString(dlSysDirect_A_ccess),
    NewSItem(GetString(dlSysStoreT_r_eeInformation),
    NewSItem(GetString(dlSysCopyVerify),
    Nil)))));
  With Control^ do begin
    Options := Options or ofPostProcess;
    EventMask := evBroadcast + evCommand + evKeyDown + evMouseDown;
  end;
  Insert(Control);

  FreeStr := GetString(dlSys_C_urrentDriveOptions);
  R.Assign(20,10,22+Length(FreeStr),11);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Insert(Labl);

  R.Assign(20,16,58,17);
  Control := New( PInputLine, Init( R, 79 ));
  Insert( Control );

  R.Assign(20,15,58,16);
  Insert( New( PLabel, Init( R, GetString(dlSys_T_emporaryDir), Control )));

  R.Assign(29,18,39,20);
  Control := New(PButton, Init(R, GetString(dlOKButton), cmOK, bfDefault));
  Insert(Control);

  R.Assign(39,18,49,20);
  Control := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
  Insert(Control);

  R.Assign(49,18,59,20);
  Control := New(PButton, Init(R, GetString(dlHelpButton), cmHelp, bfNormal));
  Insert(Control);

  SelectNext(False);
{$IFNDEF AsUnit} Awaken {$ENDIF}
end;
*)

PROCEDURE TSysDialog.Awaken;
var
  C: Char;
begin
  LocalData := SystemData;
  New( SysData.Drives.List, Init( 26, 1 ));
  For C := 'A' to 'Z' do SysData.Drives.List^.Insert( NewStr( C + ':' ));
  Move( SystemData, SysData, SizeOf( SysData.Options ) + SizeOf( SysData.Mode1 )*2 );
  SysData.Temp := SystemData.Temp;
  SysData.Drives.Focus := 2;
  SysData.Current := LocalData.Drives[ 'C' ];
  SetData( SysData );
end;

DESTRUCTOR TSysDialog.Done;
var
  Data: TSysData;
begin
  GetData( Data );
  inherited Done;
  Dispose( Data.Drives.List, Done );
end;

PROCEDURE TSysDialog.GetData;
var
  Data: TSysData;
begin
  inherited GetData( Data );
  TSysData( Rec ) := Data;
  LocalData.Options := Data.Options;
  LocalData.Mode1 := Data.Mode1;
  LocalData.Mode2 := Data.Mode2;
  LocalData.Temp := Data.Temp;
end;


{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function MakeStartupDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, Labl, Histry : PView;
begin
  R.Assign(5,0,34,13);
  New(Dlg, Init(R, 'Startup'));
  With Dlg^ do begin
    Options := Options or ofCentered;

    R.Assign(2,2,27,8);
    Control := New(PCheckboxes, Init(R,
      NewSItem('Autosave ~D~esktop',
      NewSItem('Auto run ~U~ser Menu',
      NewSItem('Disable ~b~linking',
      NewSItem('~R~estore screen mode',
      NewSItem('~K~ill History',
      NewSItem('OS/~2~ support',
      Nil))))))));
    Insert(Control);

    R.Assign(4,9,14,11);
    Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
    Insert(Control);

    R.Assign(15,9,25,11);
    Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
    Insert(Control);

    SelectNext(False);
  end;
  MakeStartupDialog := Dlg;
end;

{                                 Mouse Setup
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
CONSTRUCTOR TMouseBar.Init;
begin
  inherited Init( Bounds );
  Options := Options or ofSelectable;
  SetParams( 0, 0, Size.X-1, 3, 1 );
end;

const
  HSenseY = 3;

FUNCTION TMouseBar.DataSize; assembler;
asm mov ax,2 end;

PROCEDURE TMouseBar.SetData;
begin SetValue( Integer( Rec )) end;

PROCEDURE TMouseBar.GetData;
begin Integer( Rec ) := Value end;

PROCEDURE TMouseBar.HandleEvent;
begin
  inherited HandleEvent( Event );
end;

CONSTRUCTOR TMouseDialog.Init;
var
  R: TRect;
  Control, Labl: PView;
begin
  R.Assign(0,0,39,13);
  inherited Init( R, 'Mouse Setup' );
  Options := Options or ofCentered;

  R.Assign(3,HSenseY,26,HSenseY + 1);
  Control := New( PMouseBar, Init( R ));
  Insert(Control);

  R.Assign(3,2,26,3);
  Labl := New(PLabel, Init(R, '~X~-Sensitivity', Control));
  Insert(Labl);

  R.Assign(3,HSenseY + 3,26,HSenseY + 4);
  Control := New(PMouseBar, Init(R));
  Insert(Control);

  R.Assign(3,5,24,6);
  Labl := New(PLabel, Init(R, '~Y~-sensitivity', Control));
  Insert(Labl);

  R.Assign(3,9,26,11);
  Control := New(PCheckboxes, Init(R,
    NewSItem('~R~everse buttons',
    NewSItem('~S~tandard cursor',Nil))));
  Insert(Control);

  R.Assign(3,8,12,9);
  Labl := New(PLabel, Init(R, '~O~ptions', Control));
  Insert(Labl);

  R.Assign(27,3,37,5);
  Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  Insert(Control);

  R.Assign(27,5,37,7);
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  Insert(Control);

  R.Assign(27,9,37,11);
  Control := New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
  Insert(Control);

  SelectNext(False);
end;

function MakeMouseDialog: PDialog;
begin
  MakeMouseDialog := New( PMouseDialog, Init );
end;

{                               Interface Setup
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
function MakeInterfaceDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, Labl, Histry : PView;
begin
  R.Assign(0,0,46,17);
  New(Dlg, Init(R, 'Interface Setup'));
  With Dlg^ do begin
    Options := Options or ofCentered;
    R.Assign(3,3,33,7);
    Control := New(PCheckboxes, Init(R,
      NewSItem('~C~lock',
      NewSItem('Hide ~m~enu bar',
      NewSItem('Hide ~s~tatus line',
      NewSItem('~E~SC for user screen',
{     NewSItem('~Q~uiet archive processing',}
      Nil))))));
    Insert(Control);

    R.Assign(3,2,11,3);
    Labl := New(PLabel, Init(R, '~O~ptions', Control));
    Insert(Labl);

    R.Assign(3,09,33,11);
    Control := New(PRadioButtons, Init(R,
      NewSItem('Alt-Tab and Ctrl-Tab',
      NewSItem('F9 and Shift-F9',Nil))));
    Insert(Control);

    R.Assign(3,8,21,09);
    Labl := New(PLabel, Init(R, '~W~indows switching', Control));
    Insert(Labl);

    R.Assign(3,13,33,15);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~F~ile Panel',
      NewSItem('Command ~l~ine',Nil))));
    Insert(Control);

    R.Assign(3,12,20,13);
    Labl := New(PLabel, Init(R, '/'#26' ~a~rrows usage', Control));
    Insert(Labl);

    R.Assign(34,3,44,5);
    Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
    Insert(Control);

    R.Assign(34,5,44,7);
    Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
    Insert(Control);

    R.Assign(34,13,44,15);
    Control := New(PButton, Init(R, '~H~elp', cmHelp, bfNormal));
    Insert(Control);

    SelectNext(False);
  end;
  MakeInterfaceDialog := Dlg;
end;

{                                Savers Setup
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
PROCEDURE TSaversListBox.HandleEvent;
var
  PS: PString;
  F: Integer;
  A, S: PCollection;
  LocalData: TSaversData;
  function SeekStr( P: PString ): boolean; far;
  begin
    SeekStr := ( P <> NIL ) and ( P^ = PS^ );
  end;
begin
  If Event.What = evBroadcast then
    case Event.Command of
      cmYes: begin
          Owner^.GetData( LocalData );
          A := LocalData.Available.List;
          If A^.Count > 0 then begin
            PS := A^.At( LocalData.Available.Focus );
            If ( PS <> NIL ) and ( List^.FirstThat( @SeekStr ) = NIL ) then begin
              List^.Insert( NewStr( PS^ ));
              S := List;
              List := NIL;
              NewList( S );
            end;
          end;
          ClearEvent( Event );
        end;
      cmNo: begin
          F := Focused;
          If F < List^.Count then begin
            S := List;
            S^.AtFree( F );
            List := NIL;
            Owner^.Lock;
            NewList( S );
            If ( F > 0 ) and ( F >= List^.Count ) then Dec( F );
            FocusItem( F );
            Owner^.Unlock;
          end;
          ClearEvent( Event );
        end;
    end;
  inherited HandleEvent( Event );
end;

CONSTRUCTOR TSaversDialog.Init;
var
  R: TRect;
  D: PDialog;
  Control, Labl, Histry: PView;
begin
  R.Assign(0,0,57,22);
  inherited Init(R, GetString(dlScreenSaverSetup));
  Options := Options or ofCentered;
  HelpCtx := hcSavers;
  R.Assign(19,3,20,13);
  Control := New(PScrollbar, Init(R));
  Insert(Control);

  R.Assign(2,3,19,13);
  Control := New(PSaversListBox, Init(R, 1, PScrollbar(Control)));
  Insert(Control);

  R.Assign(2,2,18,3);
  Labl := New(PLabel, Init(R, GetString(dlSS_S_electedSavers), Control));
  Insert(Labl);

  R.Assign(20,6,36,8);
  Control := New(PButton, Init(R, GetString(dlSS_A_dd), cmYes, bfNormal + bfBroadcast ));
  Insert(Control);

  R.Assign(20,8,36,10);
  Control := New(PButton, Init(R, GetString(dlSS_R_emove), cmNo, bfNormal + bfBroadcast ));
  Insert(Control);

  R.Assign(54,3,55,13);
  Control := New(PScrollbar, Init(R));
  Insert(Control);

  R.Assign(37,3,54,13);
  Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
  Insert(Control);

  R.Assign(37,2,54,3);
  Labl := New(PLabel, Init(R, GetString(dlSSA_v_ailableSavers), Control));
  Insert(Labl);

  R.Assign(2,15,18,20);
  Control := New(PRadioButtons, Init(R,
    NewSItem(GetString(dlSS_N_ever),
    NewSItem(GetString(dlSS_1_minute),
    NewSItem(GetString(dlSS_2_minutes),
    NewSItem(GetString(dlSS_5_minutes),
    NewSItem(GetString(dlSS1_0_minutes) ,Nil)))))));
  Insert(Control);

  R.Assign(2,14,18,15);
  Labl := New(PLabel, Init(R, GetString(dlSS_T_ime), Control));
  Insert(Labl);

  R.Assign(20,15,55,16);
  Control := New(PCheckboxes, Init(R,
    NewSItem(GetString(dlSSUse_M_ouse),Nil)));
  Insert(Control);

  R.Assign(25,19,35,21);
  Control := New(PButton, Init(R, GetString(dlOKButton), cmOK, bfDefault));
  Insert(Control);

  R.Assign(35,19,45,21);
  Control := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
  Insert(Control);

  R.Assign(45,19,55,21);
  Control := New(PButton, Init(R, GetString(dlHelpButton), cmHelp, bfNormal));
  Insert(Control);

  SelectNext(False);
{$IFNDEF AsUnit} Awaken {$ENDIF}
end;

PROCEDURE TSaversDialog.Awaken;
var
  SR: SearchRec;
  Data: TSaversData;
begin
  Data := SaversData;
  Data.Available.Focus := 0;
  Data.Selected.Focus := 0;
  New( Data.Available.List, Init( 5, 5 ));
  If Data.Selected.List = NIL
    then New( Data.Selected.List, Init( 5, 5 ));
  With Data.Available.List^ do begin
    Insert( NewStr( 'ù Star flight' ));
    Insert( NewStr( 'ù Flash-light' ));
    Insert( NewStr( 'ù Clock' ));
    Insert( NewStr( 'ù Blackness' ));
  {$IFDEF AsUnit}
    FindFirst( SourceDir + 'SSAVERS\*.SS', AnyFile, SR );
  {$ELSE}
    FindFirst( '*.PAS', AnyFile, SR );
  {$ENDIF}
    While DosError = 0 do begin
      Insert( NewStr( SR.Name ));
      FindNext( SR );
    end;
  end;
  SetData( Data );
end;

DESTRUCTOR TSaversDialog.Done;
var
  Data: TSaversData;
begin
  GetData( Data );
  inherited Done;
  if (Data.Available.List <> nil) then Dispose( Data.Available.List, Done );
end;

FUNCTION MakeSaversDialog : PDialog;
begin
  MakeSaversDialog := New( PSaversDialog, Init );
end;

constructor TUpperTable.Init;
 var I: Integer;
begin
  inherited Init(R);
  for I := 0 to 127 do Table[I] := Char(I+128);
  CurrentChar := 0; Delta := 0;
  Options := Options or ofSelectable;
  EventMask := evKeyDown or evMouse;
end;

function TUpperTable.GetPalette;
 const S: String[Length(CInputLine)] = CInputLine;
begin
  GetPalette := @S;
end;

function TUpperTable.DataSize; begin DataSize := 128; end;
procedure TUpperTable.GetData; begin Move(Table, Rec, 128); end;
procedure TUpperTable.SetData; begin Move(Rec, Table, 128); end;

procedure TUpperTable.Draw;
  var B: TDrawBuffer;
      I: Integer;
      C: Word;
begin
  if CurrentChar < Delta then Delta := CurrentChar;
  if CurrentChar - Delta > Size.X - 1 then Delta := CurrentChar - Size.X + 1;
  C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  for I := 0 to Size.X - 1 do
      WordRec(B[I]).Lo := I + Delta + 128;
  WordRec(B[CurrentChar - Delta]).Hi := GetColor(3);
  WriteLine(0,0,Size.X,1,B);
  MoveChar(B, ' ', C, Size.X);
  for I := 0 to Size.X - 1 do
      WordRec(B[I]).Lo := Byte(Table[I + Delta]);
  WordRec(B[CurrentChar - Delta]).Hi := GetColor(3);
  WriteLine(0,1,Size.X,1,B);
  ShowCursor; SetCursor(CurrentChar - Delta, 1); NormalCursor;
end;

procedure TUpperTable.HandleEvent;
  procedure CE; begin ClearEvent(Event); DrawView; end;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evKeyDown: case Event.KeyCode of
                 kbLeft: begin if CurrentChar > 0 then Dec(CurrentChar); CE end;
                 kbRight: begin if CurrentChar < 127 then Inc(CurrentChar); CE end;
                 else
                 if Event.CharCode in ['A'..'Z','a'..'z',#128..#255] then begin
                          Table[CurrentChar] := Event.CharCode;
                          Message(@Self, evKeyDown, kbRight, nil); CE
                        end;
               end;
  end;
end;

{$IFNDEF AsUnit}
{                                 Application
{ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ}
VAR
  T: TMyApp;

procedure TMyApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent( R );
  R.B.Y := R.A.Y + 1;
  New( PMenuBar( MenuBar ), Init( R, NewMenu(
    NewItem( '~I~nterface', '', kbF1, cmInterface, 0,
    NewItem( '~M~ouse', '', kbF2, cmMouse, 0,
    NewItem( '~S~avers', '', kbF3, cmSavers, 0,
    NewItem( 'Start~U~p', '', kbF4, cmStartUp, 0,
    NewItem( 'S~y~stem', '', kbF5, cmSystem, 0,
  NIL ) )))))));
end;

procedure TMyApp.HandleEvent;
var
  D: PDialog;
begin
  inherited HandleEvent( Event );
  If Event.What = evCommand then begin
    case Event.Command of
      cmInterface: D := MakeInterfaceDialog;
      cmMouse: D := MakeMouseDialog;
      cmSavers: D := MakeSaversDialog;
      cmStartUp: D := MakeStartupDialog;
      cmSystem: begin CountrySetup; exit end;
      else Exit
    end;
    If D <> NIL then begin
      Desktop^.ExecView( D );
      Dispose( D, Done );
    end;
  end;
end;


BEGIN
  FillChar( SystemData, SizeOf( SystemData ), 0 );
  SystemData.Options := 3;
  SystemData.Mode1 := '29';
  SystemData.Mode2 := '30';
  SystemData.Drives[ 'A' ] := 1;
  SystemData.Drives[ 'C' ] := 3;
  SystemData.Drives[ 'D' ] := 2;
  T.Init;
  MenuBar^.MoveTo(0,0); MenuBar^.GrowTo(80, 1);
  Desktop^.MoveTo(0,1);
  T.Run;
  T.Done;
{$ENDIF}
END.