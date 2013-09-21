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

unit Views;

{-----------------------------------------------------}
{ This module is based on Turbo Vision Views Unit     }
{ Copyright (c) 1990 by Borland International         }
{-----------------------------------------------------}


interface

uses Objects, Drivers, Memory, xTime, ObjType;

const

{ TView State masks }

  sfVisible     = $0001;
  sfCursorVis   = $0002;
  sfCursorIns   = $0004;
  sfShadow      = $0008;
  sfActive      = $0010;
  sfSelected    = $0020;
  sfFocused     = $0040;
  sfDragging    = $0080;
  sfDisabled    = $0100;
  sfModal       = $0200;
  sfDefault     = $0400;
  sfExposed     = $0800;

{ TView Option masks }

  ofSelectable  = $0001;
  ofTopSelect   = $0002;
  ofFirstClick  = $0004;
  ofFramed      = $0008;
  ofPreProcess  = $0010;
  ofPostProcess = $0020;
  ofBuffered    = $0040;
  ofTileable    = $0080;
  ofCenterX     = $0100;
  ofCenterY     = $0200;
  ofCentered    = $0300;
  ofValidate    = $0400;
  ofSecurity    = $0800;
  ofVersion     = $3000;
  ofVersion10   = $0000;
  ofVersion20   = $1000;

{ TView GrowMode masks }

  gfGrowLoX = $01;
  gfGrowLoY = $02;
  gfGrowHiX = $04;
  gfGrowHiY = $08;
  gfGrowAll = $0F;
  gfGrowRel = $10;

{ TView DragMode masks }

  dmDragMove = $01;
  dmDragGrow = $02;
  dmLimitLoX = $10;
  dmLimitLoY = $20;
  dmLimitHiX = $40;
  dmLimitHiY = $80;
  dmLimitAll = $F0;

{ TView Help context codes }

  hcNoContext = 0;
  hcDragging  = 1;

{ TScrollBar part codes }

  sbLeftArrow  = 0;
  sbRightArrow = 1;
  sbPageLeft   = 2;
  sbPageRight  = 3;
  sbUpArrow    = 4;
  sbDownArrow  = 5;
  sbPageUp     = 6;
  sbPageDown   = 7;
  sbIndicator  = 8;

{ TScrollBar options for TWindow.StandardScrollBar }

  sbHorizontal     = $0000;
  sbVertical       = $0001;
  sbHandleKeyboard = $0002;

{ TWindow Flags masks }

  wfMove  = $01;
  wfGrow  = $02;
  wfClose = $04;
  wfZoom  = $08;

{ TWindow number constants }

  wnNoNumber = 0;

{ TWindow palette entries }

  wpBlueWindow = 0;
  wpCyanWindow = 1;
  wpGrayWindow = 2;

{ Standard command codes }

  cmValid   = 0;
  cmQuit    = 1;
  cmError   = 2;
  cmMenu    = 3;
  cmClose   = 4;
  cmZoom    = 5;
  cmResize  = 6;
  cmNext    = 7;
  cmPrev    = 8;
  cmHelp    = 9;

{ Application command codes }

  cmCut     = 20;
  cmCopy    = 21;
  cmPaste   = 22;
  cmUndo    = 23;
  cmClear   = 24;
  cmTile    = 25;
  cmCascade = 26;

{ TDialog standard commands }

  cmOK      = 10;
  cmCancel  = 11;
  cmYes     = 12;
  cmNo      = 13;
  cmDefault = 14;
  cmSkip    = 15;

{ Standard messages }

  cmReceivedFocus     = 50;
  cmReleasedFocus     = 51;
  cmCommandSetChanged = 52;

{ TScrollBar messages }

  cmScrollBarChanged  = 53;
  cmScrollBarClicked  = 54;

{ TWindow select messages }

  cmSelectWindowNum   = 55;

{ TListViewer messages }

  cmListItemSelected  = 56;

{ Color palettes }

  CFrame      = #1#1#2#2#3;
  CScrollBar  = #4#5#5;
  CScroller   = #6#7;
  CListViewer = #26#26#27#28#29;

  CBlueWindow = #8#9#10#11#12#13#14#15;
  CCyanWindow = #16#17#18#19#20#21#22#23;
  CGrayWindow = #24#25#26#27#28#29#30#31;

{ TDrawBuffer maximum view width }

  MaxViewWidth = 256;

type

{ Command sets }

  PCommandSet = ^TCommandSet;
  TCommandSet = set of Byte;

{ Color palette type }

  PPalette = ^TPalette;
  TPalette = String;

{ TDrawBuffer, buffer used by draw methods }

  TDrawBuffer = array[0..MaxViewWidth - 1] of Word;

{ TView object Pointer }

  PView = ^TView;

{ TGroup object Pointer }

  PGroup = ^TGroup;

{ TView object }

  TView = object(TObject)
    Owner: PGroup;
    Next: PView;
    Origin: TPoint;
    Size: TPoint;
    Cursor: TPoint;
    GrowMode: Byte;
    DragMode: Byte;
    HelpCtx: Word;
    State: Word;
    Options: Word;
    EventMask: Word;
    UpTmr: TEventTimer;
    UpdTicks: LongInt;
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Awaken; virtual;
    procedure BlockCursor;
    procedure CalcBounds(var Bounds: TRect; Delta: TPoint); virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure ClearEvent(var Event: TEvent);
    function CommandEnabled(Command: Word): Boolean;
    function DataSize: Word; virtual;
    procedure DisableCommands(Commands: TCommandSet);
    procedure DragView(Event: TEvent; Mode: Byte;
      var Limits: TRect; MinSize, MaxSize: TPoint);
    procedure Draw; virtual;
    procedure DrawView;
    procedure EnableCommands(Commands: TCommandSet);
    procedure EndModal(Command: Word); virtual;
    function EventAvail: Boolean;
    function Execute: Word; virtual;
    function Exposed: Boolean;
    function Focus: Boolean;
    procedure GetBounds(var Bounds: TRect);
    procedure GetClipRect(var Clip: TRect);
    function GetColor(Color: Word): Word;
    procedure GetCommands(var Commands: TCommandSet);
    procedure GetData(var Rec); virtual;
    procedure GetEvent(var Event: TEvent); virtual;
    procedure GetExtent(var Extent: TRect);
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure GetPeerViewPtr(var S: TStream; var P);
    function GetState(AState: Word): Boolean;
    procedure GrowTo(X, Y: Integer);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Hide;
    procedure HideCursor;
    procedure KeyEvent(var Event: TEvent);
    procedure Locate(var Bounds: TRect);
    procedure MakeFirst;
    procedure MakeGlobal(Source: TPoint; var Dest: TPoint);
    procedure MakeLocal(Source: TPoint; var Dest: TPoint);
    function MouseEvent(var Event: TEvent; Mask: Word): Boolean;
    function MouseInView(Mouse: TPoint): Boolean;
    procedure MoveTo(X, Y: Integer);
    function NextView: PView;
    procedure NormalCursor;
    function Prev: PView;
    function PrevView: PView;
    procedure PutEvent(var Event: TEvent); virtual;
    procedure PutInFrontOf(Target: PView);
    procedure PutPeerViewPtr(var S: TStream; P: PView);
    procedure Select;
    procedure SetBounds(var Bounds: TRect);
    procedure SetCommands(Commands: TCommandSet);
    procedure SetCmdState(Commands: TCommandSet; Enable: Boolean);
    procedure SetCursor(X, Y: Integer);
    procedure SetData(var Rec); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Show;
    procedure ShowCursor;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    function TopView: PView;
    function Valid(Command: Word): Boolean; virtual;
    procedure WriteBuf(X, Y, W, H: Integer; var Buf);
    procedure WriteChar(X, Y: Integer; C: Char; Color: Byte;
      Count: Integer);
    procedure WriteLine(X, Y, W, H: Integer; var Buf);
    procedure WriteStr(X, Y: Integer; Str: String; Color: Byte);
    procedure StoreText(var F: Text); virtual;
    function  GetOptionsStr: String;
    procedure Update; virtual;
  private
    procedure DrawCursor;
    procedure DrawHide(LastView: PView);
    procedure DrawShow(LastView: PView);
    procedure DrawUnderRect(var R: TRect; LastView: PView);
    procedure DrawUnderView(DoShadow: Boolean; LastView: PView);
    procedure ResetCursor; virtual;
  end;

{ TFrame types }

  TTitleStr = string[80];

{ TFrame object }

  { Palette layout }
  { 1 = Passive frame }
  { 2 = Passive title }
  { 3 = Active frame }
  { 4 = Active title }
  { 5 = Icons }

  PFrame = ^TFrame;
  TFrame = object(TView)
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  private
    procedure FrameLine(var FrameBuf; Y, N: Integer; Color: Byte);
  end;

{ ScrollBar characters }

  TScrollChars = array[0..4] of Char;

{ TScrollBar object }

  { Palette layout }
  { 1 = Page areas }
  { 2 = Arrows }
  { 3 = Indicator }

  PScrollBar = ^TScrollBar;
  TScrollBar = object(TView)
    Value: Integer;
    Min: Integer;
    Max: Integer;
    PgStep: Integer;
    ArStep: Integer;
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure ScrollDraw; virtual;
    function ScrollStep(Part: Integer): Integer; virtual;
    procedure SetParams(AValue, AMin, AMax, APgStep, AArStep: Integer);
    procedure SetRange(AMin, AMax: Integer);
    procedure SetStep(APgStep, AArStep: Integer);
    procedure SetValue(AValue: Integer);
    procedure Store(var S: TStream);
    procedure StoreText(var F: Text); virtual;
  private
    Chars: TScrollChars;
    procedure DrawPos(Pos: Integer);
    function GetPos: Integer;
    function GetSize: Integer;
  end;

{ Video buffer }

  PVideoBuf = ^TVideoBuf;
  TVideoBuf = array[0..3999] of Word;

{ Selection modes }

  SelectMode = (NormalSelect, EnterSelect, LeaveSelect);

{ TGroup object }

  TGroup = object(TView)
    Last: PView;
    Current: PView;
    Phase: (phFocused, phPreProcess, phPostProcess);
    Buffer: PVideoBuf;
    Clip: TRect;
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Awaken; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function DataSize: Word; virtual;
    procedure Delete(P: PView);
    procedure Draw; virtual;
    procedure EndModal(Command: Word); virtual;
    procedure EventError(var Event: TEvent); virtual;
    function ExecView(P: PView): Word;
    function Execute: Word; virtual;
    function First: PView;
    function FirstThat(P: Pointer): PView;
    function FocusNext(Forwards: Boolean): Boolean;
    procedure ForEach(P: Pointer);
    procedure GetData(var Rec); virtual;
    function GetHelpCtx: Word; virtual;
    procedure GetSubViewPtr(var S: TStream; var P);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Insert(P: PView);
    procedure InsertBefore(P, Target: PView);
    procedure Lock;
    procedure PutSubViewPtr(var S: TStream; P: PView);
    procedure Redraw; virtual;
    procedure SelectNext(Forwards: Boolean);
    procedure SetData(var Rec); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure Unlock;
    function Valid(Command: Word): Boolean; virtual;
    procedure FreeBuffer;
    procedure GetBuffer;
    procedure InsertView(P, Target: PView);
    procedure SetCurrent(P: PView; Mode: SelectMode);
  private
    LockFlag: Byte;
    EndState: Word;
    function At(Index: Integer): PView;
    procedure DrawSubViews(P, Bottom: PView);
    function FirstMatch(AState: Word; AOptions: Word): PView;
    function FindNext(Forwards: Boolean): PView;
    function IndexOf(P: PView): Integer;
    procedure RemoveView(P: PView);
    procedure ResetCurrent;
    procedure ResetCursor; virtual;
  end;

{ TWindow object }

  { Palette layout }
  { 1 = Frame passive }
  { 2 = Frame active }
  { 3 = Frame icon }
  { 4 = ScrollBar page area }
  { 5 = ScrollBar controls }
  { 6 = Scroller normal text }
  { 7 = Scroller selected text }
  { 8 = Reserved }

  PWindow = ^TWindow;
  TWindow = object(TGroup)
    Flags: Byte;
    ZoomRect: TRect;
    Number: Integer;
    Palette: Integer;
    Frame: PFrame;
    Title: PString;
    constructor Init(var Bounds: TRect; ATitle: TTitleStr; ANumber: Integer);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Close; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitFrame; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    function StandardScrollBar(AOptions: Word): PScrollBar;
    procedure Store(var S: TStream);
    procedure Zoom; virtual;
    function  ReactOnCmd: Boolean; virtual;
  end;

{ Message dispatch function }

function Message(Receiver: PView; What, Command: Word;
  InfoPtr: Pointer): Pointer;

{ Views registration procedure }

const

{ Event masks }

  PositionalEvents: Word = evMouse;
  FocusedEvents: Word = evKeyboard + evCommand;

{ Minimum window size }

  MinWinSize: TPoint = (X: 16; Y: 6);

{ Shadow definitions }

  ShadowSize: TPoint = (X: 2; Y: 1);
  ShadowAttr: Byte = $08;

{ Markers control }

  ShowMarkers: Boolean = False;

{ MapColor error return value }

  ErrorAttr: Byte = $CF;

{ Stream Registration Records }

const
  RView: TStreamRec = (
     ObjType: otView;
     VmtLink: Ofs(TypeOf(TView)^);
     Load:    @TView.Load;
     Store:   @TView.Store
  );

const
  RFrame: TStreamRec = (
     ObjType: otFrame;
     VmtLink: Ofs(TypeOf(TFrame)^);
     Load:    @TFrame.Load;
     Store:   @TFrame.Store
  );

const
  RScrollBar: TStreamRec = (
     ObjType: otScrollBar;
     VmtLink: Ofs(TypeOf(TScrollBar)^);
     Load:    @TScrollBar.Load;
     Store:   @TScrollBar.Store
  );

const
  RGroup: TStreamRec = (
     ObjType: otGroup;
     VmtLink: Ofs(TypeOf(TGroup)^);
     Load:    @TGroup.Load;
     Store:   @TGroup.Store
  );

const
  RWindow: TStreamRec = (
     ObjType: otWindow;
     VmtLink: Ofs(TypeOf(TWindow)^);
     Load:    @TWindow.Load;
     Store:   @TWindow.Store
  );

{ Characters used for drawing selected and default items in  }
{ monochrome color sets                                      }

  SpecialChars: array[0..5] of Char = ('>', '<', ')', '(', ' ', ' ');

{ True if the command set has changed since being set to false }

  CommandSetChanged: Boolean = False;
  UpdateViews: PCollection = nil;
  UpdatePrior: PCollection = nil;

procedure RegisterToPrior(P: PView);
procedure RegisterToBackground(P: PView);
procedure Deregister(P: PView);
procedure UpdateAll(All: Boolean);

implementation
uses Commands, Startup, DNapp, Advance;

type
  PFixupList = ^TFixupList;
  TFixupList = array[1..4096] of Pointer;

const
  OwnerGroup: PGroup = nil;
  FixupList: PFixupList = nil;
  TheTopView: PView = nil;

const

{ Current command set. All but window commands are active by default }

  CurCommandSet: TCommandSet =
    [0..255] - [cmZoom, cmClose, cmResize, cmNext, cmPrev];

{ Convert color into attribute                          }
{ In    AL = Color                                      }
{ Out   AL = Attribute                                  }

procedure MapColor; near; assembler;
const
  Self = 6;
  TView_GetPalette = vmtHeaderSize + $2C;
asm
        OR      AL,AL
        JE      @@3
        LES     DI,[BP].Self
@@1:    PUSH    ES
        PUSH    DI
        PUSH    AX
        PUSH    ES
        PUSH    DI
        MOV     DI,ES:[DI]
        CALL    DWORD PTR [DI].TView_GetPalette
        MOV     BX,AX
        MOV     ES,DX
        OR      AX,DX
        POP     AX
        POP     DI
        POP     DX
        JE      @@2
        CMP     AL,ES:[BX]
        JA      @@3
        SEGES   XLAT
        OR      AL,AL
        JE      @@3
@@2:    MOV     ES,DX
        LES     DI,ES:[DI].TView.Owner
        MOV     SI,ES
        OR      SI,DI
        JNE     @@1
        JMP     @@4
@@3:    MOV     AL,ErrorAttr
@@4:
end;

{ Convert color pair into attribute pair                }
{ In    AX = Color pair                                 }
{ Out   AX = Attribute pair                             }

procedure MapCPair; near; assembler;
asm
        OR      AH,AH
        JE      @@1
        XCHG    AL,AH
        CALL    MapColor
        XCHG    AL,AH
@@1:    CALL    MapColor
end;

{ Write to view                                         }
{ In    AX    = Y coordinate                            }
{       BX    = X coordinate                            }
{       CX    = Count                                   }
{       ES:DI = Buffer Pointer                          }

procedure WriteView; near; assembler;
const
  Self   =   6;
  Target =  -4;
  Buffer =  -8;
  BufOfs = -10;
asm
        MOV     [BP].BufOfs,BX
        MOV     [BP].Buffer[0],DI
        MOV     [BP].Buffer[2],ES
        ADD     CX,BX
        XOR     DX,DX
        LES     DI,[BP].Self
        OR      AX,AX
        JL      @@3
        CMP     AX,ES:[DI].TView.Size.Y
        JGE     @@3
        OR      BX,BX
        JGE     @@1
        XOR     BX,BX
@@1:    CMP     CX,ES:[DI].TView.Size.X
        JLE     @@2
        MOV     CX,ES:[DI].TView.Size.X
@@2:    CMP     BX,CX
        JL      @@10
@@3:    RET
@@10:   TEST    ES:[DI].TView.State,sfVisible
        JE      @@3
        CMP     ES:[DI].TView.Owner.Word[2],0
        JE      @@3
        MOV     [BP].Target[0],DI
        MOV     [BP].Target[2],ES
        ADD     AX,ES:[DI].TView.Origin.Y
        MOV     SI,ES:[DI].TView.Origin.X
        ADD     BX,SI
        ADD     CX,SI
        ADD     [BP].BufOfs,SI
        LES     DI,ES:[DI].TView.Owner
        CMP     AX,ES:[DI].TGroup.Clip.A.Y
        JL      @@3
        CMP     AX,ES:[DI].TGroup.Clip.B.Y
        JGE     @@3
        CMP     BX,ES:[DI].TGroup.Clip.A.X
        JGE     @@11
        MOV     BX,ES:[DI].TGroup.Clip.A.X
@@11:   CMP     CX,ES:[DI].TGroup.Clip.B.X
        JLE     @@12
        MOV     CX,ES:[DI].TGroup.Clip.B.X
@@12:   CMP     BX,CX
        JGE     @@3
        LES     DI,ES:[DI].TGroup.Last
@@20:   LES     DI,ES:[DI].TView.Next
        CMP     DI,[BP].Target[0]
        JNE     @@21
        MOV     SI,ES
        CMP     SI,[BP].Target[2]
        JNE     @@21
        JMP     @@40
@@21:   TEST    ES:[DI].TView.State,sfVisible
        JE      @@20
        MOV     SI,ES:[DI].TView.Origin.Y
        CMP     AX,SI
        JL      @@20
        ADD     SI,ES:[DI].TView.Size.Y
        CMP     AX,SI
        JL      @@23
        TEST    ES:[DI].TView.State,sfShadow
        JE      @@20
        ADD     SI,ShadowSize.Y
        CMP     AX,SI
        JGE     @@20
        MOV     SI,ES:[DI].TView.Origin.X
        ADD     SI,ShadowSize.X
        CMP     BX,SI
        JGE     @@22
        CMP     CX,SI
        JLE     @@20
        CALL    @@30
@@22:   ADD     SI,ES:[DI].TView.Size.X
        JMP     @@26
@@23:   MOV     SI,ES:[DI].TView.Origin.X
        CMP     BX,SI
        JGE     @@24
        CMP     CX,SI
        JLE     @@20
        CALL    @@30
@@24:   ADD     SI,ES:[DI].TView.Size.X
        CMP     BX,SI
        JGE     @@25
        CMP     CX,SI
        JLE     @@31
        MOV     BX,SI
@@25:   TEST    ES:[DI].TView.State,sfShadow
        JE      @@20
        PUSH    SI
        MOV     SI,ES:[DI].TView.Origin.Y
        ADD     SI,ShadowSize.Y
        CMP     AX,SI
        POP     SI
        JL      @@27
        ADD     SI,ShadowSize.X
@@26:   CMP     BX,SI
        JGE     @@27
        INC     DX
        CMP     CX,SI
        JLE     @@27
        CALL    @@30
        DEC     DX
@@27:   JMP     @@20
@@30:   PUSH    [BP].Target.Word[2]
        PUSH    [BP].Target.Word[0]
        PUSH    [BP].BufOfs.Word[0]
        PUSH    ES
        PUSH    DI
        PUSH    SI
        PUSH    DX
        PUSH    CX
        PUSH    AX
        MOV     CX,SI
        CALL    @@20
        POP     AX
        POP     CX
        POP     DX
        POP     SI
        POP     DI
        POP     ES
        POP     [BP].BufOfs.Word[0]
        POP     [BP].Target.Word[0]
        POP     [BP].Target.Word[2]
        MOV     BX,SI
@@31:   RET
@@40:   LES     DI,ES:[DI].TView.Owner
        MOV     SI,ES:[DI].TGroup.Buffer.Word[2]
        OR      SI,SI
        JE      @@44
        CMP     SI,ScreenBuffer.Word[2]
        JE      @@41
        CALL    @@50
        JMP     @@44
@@41:   CLI
        CMP     GraphMouse, 0
        JNE     @@43
        CMP     AX,MouseWhere.Y
        JNE     @@42
        CMP     BX,MouseWhere.X
        JA      @@42
        CMP     CX,MouseWhere.X
        JA      @@43
@@42:   MOV     MouseIntFlag,0
        STI
        CALL    @@50
        CMP     MouseIntFlag,0
        JE      @@44
@@43:   STI
        CALL    HideMouse
        CALL    @@50
        CALL    ShowMouse
@@44:   CMP     ES:[DI].TGroup.LockFlag,0
        JNE     @@31
        JMP     @@10
@@50:   PUSH    ES
        PUSH    DS
        PUSH    DI
        PUSH    CX
        PUSH    AX
        MUL     ES:[DI].TView.Size.X.Byte[0]
        ADD     AX,BX
        SHL     AX,1
        ADD     AX,ES:[DI].TGroup.Buffer.Word[0]
        MOV     DI,AX
        MOV     ES,SI
        XOR     AL,AL
        CMP     SI,ScreenBuffer.Word[2]
        JNE     @@51
        MOV     AL,CheckSnow
@@51:   MOV     AH,ShadowAttr
        SUB     CX,BX
        MOV     SI,BX
        SUB     SI,[BP].BufOfs
        SHL     SI,1
        ADD     SI,[BP].Buffer.Word[0]
        MOV     DS,[BP].Buffer.Word[2]
        CLD
        OR      AL,AL
        JNE     @@60
        OR      DX,DX
        JNE     @@52
        REP     MOVSW
        JMP     @@70
@@52:   LODSB
        INC     SI
        STOSW
        LOOP    @@52
        JMP     @@70
@@60:   PUSH    DX
        PUSH    BX
        OR      DX,DX
        MOV     DX,03DAH
        JNE     @@65
@@61:   LODSW
        MOV     BX,AX
@@62:   IN      AL,DX
        TEST    AL,1
        JNE     @@62
        CLI
@@63:   IN      AL,DX
        TEST    AL,1
        JE      @@63
        MOV     AX,BX
        STOSW
        STI
        LOOP    @@61
        JMP     @@68
@@65:   LODSB
        MOV     BL,AL
        INC     SI
@@66:   IN      AL,DX
        TEST    AL,1
        JNE     @@66
        CLI
@@67:   IN      AL,DX
        TEST    AL,1
        JE      @@67
        MOV     AL,BL
        STOSW
        STI
        LOOP    @@65
@@68:   POP     BX
        POP     DX
@@70:   MOV     SI,ES
        POP     AX
        POP     CX
        POP     DI
        POP     DS
        POP     ES
        RET
end;

{ TView }

constructor TView.Init(var Bounds: TRect);
begin
  TObject.Init;
  Owner := nil;
  State := sfVisible;
  SetBounds(Bounds);
  DragMode := dmLimitLoY;
  HelpCtx := hcNoContext;
  EventMask := evMouseDown + evKeyDown + evCommand;
end;

constructor TView.Load(var S: TStream);
begin
  TObject.Init;
  S.Read(Origin,
    SizeOf(TPoint) * 3 +
    SizeOf(Byte) * 2 +
    SizeOf(Word) * 4);
end;

destructor TView.Done;
begin
  Deregister(@Self);
  Hide;
  if Owner <> nil then Owner^.Delete(@Self);
end;

procedure TView.Awaken;
begin
end;

procedure TView.BlockCursor;
begin
  SetState(sfCursorIns, True);
end;

procedure TView.CalcBounds(var Bounds: TRect; Delta: TPoint);
var
  S, D: Integer;
  Min, Max: TPoint;

procedure Grow(var I: Integer);
begin
  if GrowMode and gfGrowRel = 0 then Inc(I, D) else
    I := (I * S + (S - D) shr 1) div (S - D);
end;

function Range(Val, Min, Max: Integer): Integer;
begin
  if Val < Min then Range := Min else
    if Val > Max then Range := Max else
      Range := Val;
end;

begin
  GetBounds(Bounds);
  S := Owner^.Size.X;
  D := Delta.X;
  if GrowMode and gfGrowLoX <> 0 then Grow(Bounds.A.X);
  if GrowMode and gfGrowHiX <> 0 then Grow(Bounds.B.X);
  if Bounds.B.X - Bounds.A.X > MaxViewWidth then
    Bounds.B.X := Bounds.A.X + MaxViewWidth;
  S := Owner^.Size.Y;
  D := Delta.Y;
  if GrowMode and gfGrowLoY <> 0 then Grow(Bounds.A.Y);
  if GrowMode and gfGrowHiY <> 0 then Grow(Bounds.B.Y);
  SizeLimits(Min, Max);
  Bounds.B.X := Bounds.A.X + Range(Bounds.B.X - Bounds.A.X, Min.X, Max.X);
  Bounds.B.Y := Bounds.A.Y + Range(Bounds.B.Y - Bounds.A.Y, Min.Y, Max.Y);
  if (Origin.X < 0) and (Origin.Y < 0) then Bounds.A := Origin;
end;

procedure TView.ChangeBounds(var Bounds: TRect);
begin
  SetBounds(Bounds);
  DrawView;
end;

procedure TView.ClearEvent(var Event: TEvent);
begin
  Event.What := evNothing;
  Event.InfoPtr := @Self;
end;

function TView.CommandEnabled(Command: Word): Boolean;
begin
  CommandEnabled := (Command > 255) or (Command in CurCommandSet);
end;

function TView.DataSize: Word;
begin
  DataSize := 0;
end;

procedure TView.DisableCommands(Commands: TCommandSet);
begin
  CommandSetChanged := CommandSetChanged or (CurCommandSet * Commands <> []);
  CurCommandSet := CurCommandSet - Commands;
end;

procedure TView.DragView(Event: TEvent; Mode: Byte;
  var Limits: TRect; MinSize, MaxSize: TPoint);
var
  P, S: TPoint;
  SaveBounds: TRect;

function Min(I, J: Integer): Integer;
begin
  if I < J then Min := I else Min := J;
end;

function Max(I, J: Integer): Integer;
begin
  if I > J then Max := I else Max := J;
end;

procedure MoveGrow(P, S: TPoint);
var
  R: TRect;
begin
  S.X := Min(Max(S.X, MinSize.X), MaxSize.X);
  S.Y := Min(Max(S.Y, MinSize.Y), MaxSize.Y);
  P.X := Min(Max(P.X, Limits.A.X - S.X + 1), Limits.B.X - 1);
  P.Y := Min(Max(P.Y, Limits.A.Y - S.Y + 1), Limits.B.Y - 1);
  if Mode and dmLimitLoX <> 0 then P.X := Max(P.X, Limits.A.X);
  if Mode and dmLimitLoY <> 0 then P.Y := Max(P.Y, Limits.A.Y);
  if Mode and dmLimitHiX <> 0 then P.X := Min(P.X, Limits.B.X - S.X);
  if Mode and dmLimitHiY <> 0 then P.Y := Min(P.Y, Limits.B.Y - S.Y);
  R.Assign(P.X, P.Y, P.X + S.X, P.Y + S.Y);
  Locate(R);
end;

procedure Change(DX, DY: Integer);
begin
  if (Mode and dmDragMove <> 0) and (ShiftState and $03 = 0) then
  begin
    Inc(P.X, DX);
    Inc(P.Y, DY);
  end else
  if (Mode and dmDragGrow <> 0) and (ShiftState and $03 <> 0) then
  begin
    Inc(S.X, DX);
    Inc(S.Y, DY);
  end;
end;

begin
  SetState(sfDragging, True);
  if Event.What = evMouseDown then
  begin
    if Mode and dmDragMove <> 0 then
    begin
      P.X := Origin.X - Event.Where.X;
      P.Y := Origin.Y - Event.Where.Y;
      repeat
        Inc(Event.Where.X, P.X);
        Inc(Event.Where.Y, P.Y);
        MoveGrow(Event.Where, Size);
      until not MouseEvent(Event, evMouseMove);
    end else
    begin
      P.X := Size.X - Event.Where.X;
      P.Y := Size.Y - Event.Where.Y;
      repeat
        Inc(Event.Where.X, P.X);
        Inc(Event.Where.Y, P.Y);
        MoveGrow(Origin, Event.Where);
      until not MouseEvent(Event, evMouseMove);
    end;
  end else
  begin
    GetBounds(SaveBounds);
    repeat
      P := Origin;
      S := Size;
      KeyEvent(Event);
      case Event.KeyCode of
        kbLeft,kbShiftTab: Change(-1, 0);
        kbRight,kbTab: Change(1, 0);
        kbUp: Change(0, -1);
        kbDown: Change(0, 1);
        kbCtrlLeft: Change(-8, 0);
        kbCtrlRight: Change(8, 0);
        kbHome: P.X := Limits.A.X;
        kbEnd: P.X := Limits.B.X - S.X;
        kbPgUp: P.Y := Limits.A.Y;
        kbPgDn: P.Y := Limits.B.Y - S.Y;
      end;
      MoveGrow(P, S);
    until (Event.KeyCode = kbEnter) or (Event.KeyCode = kbEsc);
    if Event.KeyCode = kbEsc then Locate(SaveBounds);
  end;
  SetState(sfDragging, False);
end;

procedure TView.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, ' ', GetColor(1), Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TView.DrawCursor;
begin
  if State and sfFocused <> 0 then ResetCursor;
end;

procedure TView.DrawHide(LastView: PView);
begin
  DrawCursor;
  DrawUnderView(State and sfShadow <> 0, LastView);
end;

procedure TView.DrawShow(LastView: PView);
begin
  DrawView;
  if State and sfShadow <> 0 then DrawUnderView(True, LastView);
end;

procedure TView.DrawUnderRect(var R: TRect; LastView: PView);
begin
  Owner^.Clip.Intersect(R);
  Owner^.DrawSubViews(NextView, LastView);
  Owner^.GetExtent(Owner^.Clip);
end;

procedure TView.DrawUnderView(DoShadow: Boolean; LastView: PView);
var
  R: TRect;
begin
  GetBounds(R);
  if DoShadow then
  begin
    Inc(R.B.X, ShadowSize.X);
    Inc(R.B.Y, ShadowSize.Y);
  end;
  DrawUnderRect(R, LastView);
end;

procedure TView.DrawView;
begin
  if Exposed then
  begin
    Draw;
    DrawCursor;
  end;
end;

procedure TView.EnableCommands(Commands: TCommandSet);
begin
  CommandSetChanged := CommandSetChanged or
    (CurCommandSet * Commands <> Commands);
  CurCommandSet := CurCommandSet + Commands;
end;

procedure TView.EndModal(Command: Word);
var
  P: PView;
begin
  P := TopView;
  if TopView <> nil then TopView^.EndModal(Command);
end;

function TView.EventAvail: Boolean;
var
  Event: TEvent;
begin
  GetEvent(Event);
  if Event.What <> evNothing then PutEvent(Event);
  EventAvail := Event.What <> evNothing;
end;

procedure TView.GetBounds(var Bounds: TRect); assembler;
asm
        PUSH    DS
        LDS     SI,Self
        ADD     SI,OFFSET TView.Origin
        LES     DI,Bounds
        CLD
        LODSW                           {Origin.X}
        MOV     CX,AX
        STOSW
        LODSW                           {Origin.Y}
        MOV     DX,AX
        STOSW
        LODSW                           {Size.X}
        ADD     AX,CX
        STOSW
        LODSW                           {Size.Y}
        ADD     AX,DX
        STOSW
        POP     DS
end;

function TView.Execute: Word;
begin
  Execute := cmCancel;
end;

function TView.Exposed: Boolean; assembler;
var
  Target: Pointer;
asm
        LES     DI,Self
        TEST    ES:[DI].TView.State,sfExposed
        JE      @@2
        XOR     AX,AX
        CMP     AX,ES:[DI].TView.Size.X
        JGE     @@2
        CMP     AX,ES:[DI].TView.Size.Y
        JGE     @@2
@@1:    XOR     BX,BX
        MOV     CX,ES:[DI].TView.Size.X
        PUSH    AX
        CALL    @@11
        POP     AX
        JNC     @@3
        LES     DI,Self
        INC     AX
        CMP     AX,ES:[DI].TView.Size.Y
        JL      @@1
@@2:    MOV     AL,0
        JMP     @@30
@@3:    MOV     AL,1
        JMP     @@30
@@8:    STC
@@9:    RETN
@@10:   LES     DI,ES:[DI].TView.Owner
        CMP     ES:[DI].TGroup.Buffer.Word[2],0
        JNE     @@9
@@11:   MOV     Target.Word[0],DI
        MOV     Target.Word[2],ES
        ADD     AX,ES:[DI].TView.Origin.Y
        MOV     SI,ES:[DI].TView.Origin.X
        ADD     BX,SI
        ADD     CX,SI
        LES     DI,ES:[DI].TView.Owner
        MOV     SI,ES
        OR      SI,DI
        JE      @@9
        CMP     AX,ES:[DI].TGroup.Clip.A.Y
        JL      @@8
        CMP     AX,ES:[DI].TGroup.Clip.B.Y
        JGE     @@8
        CMP     BX,ES:[DI].TGroup.Clip.A.X
        JGE     @@12
        MOV     BX,ES:[DI].TGroup.Clip.A.X
@@12:   CMP     CX,ES:[DI].TGroup.Clip.B.X
        JLE     @@13
        MOV     CX,ES:[DI].TGroup.Clip.B.X
@@13:   CMP     BX,CX
        JGE     @@8
        LES     DI,ES:[DI].TGroup.Last
@@20:   LES     DI,ES:[DI].TView.Next
        CMP     DI,Target.Word[0]
        JNE     @@21
        MOV     SI,ES
        CMP     SI,Target.Word[2]
        JE      @@10
@@21:   TEST    ES:[DI].TView.State,sfVisible
        JE      @@20
        MOV     SI,ES:[DI].TView.Origin.Y
        CMP     AX,SI
        JL      @@20
        ADD     SI,ES:[DI].TView.Size.Y
        CMP     AX,SI
        JGE     @@20
        MOV     SI,ES:[DI].TView.Origin.X
        CMP     BX,SI
        JL      @@22
        ADD     SI,ES:[DI].TView.Size.X
        CMP     BX,SI
        JGE     @@20
        MOV     BX,SI
        CMP     BX,CX
        JL      @@20
        STC
        RETN
@@22:   CMP     CX,SI
        JLE     @@20
        ADD     SI,ES:[DI].TView.Size.X
        CMP     CX,SI
        JG      @@23
        MOV     CX,ES:[DI].TView.Origin.X
        JMP     @@20
@@23:   PUSH    Target.Word[2]
        PUSH    Target.Word[0]
        PUSH    ES
        PUSH    DI
        PUSH    SI
        PUSH    CX
        PUSH    AX
        MOV     CX,ES:[DI].TView.Origin.X
        CALL    @@20
        POP     AX
        POP     CX
        POP     BX
        POP     DI
        POP     ES
        POP     Target.Word[0]
        POP     Target.Word[2]
        JC      @@20
        RETN
@@30:
end;

function TView.Focus: Boolean;
var
  Result: Boolean;
begin
  Result := True;
  if State and (sfSelected + sfModal) = 0 then
  begin
    if Owner <> nil then
    begin
      Result := Owner^.Focus;
      if Result then
        if ((Owner^.Current = nil) or
          (Owner^.Current^.Options and ofValidate = 0) or
          (Owner^.Current^.Valid(cmReleasedFocus))) then
          Select
        else
          Result := False;
    end;
  end;
  Focus := Result;
end;

procedure TView.GetClipRect(var Clip: TRect);
begin
  GetBounds(Clip);
  if Owner <> nil then Clip.Intersect(Owner^.Clip);
  Clip.Move(-Origin.X, -Origin.Y);
end;

function TView.GetColor(Color: Word): Word; assembler;
asm
        MOV     AX,Color
        CALL    MapCPair
end;

procedure TView.GetCommands(var Commands: TCommandSet);
begin
  Commands := CurCommandSet;
end;

procedure TView.GetData(var Rec);
begin
end;

procedure TView.GetEvent(var Event: TEvent);
begin
  if Owner <> nil then Owner^.GetEvent(Event);
end;

procedure TView.GetExtent(var Extent: TRect); assembler;
asm
        PUSH    DS
        LDS     SI,Self
        ADD     SI,OFFSET TView.Size
        LES     DI,Extent
        CLD
        XOR     AX,AX
        STOSW
        STOSW
        MOVSW
        MOVSW
        POP     DS
end;

function TView.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging else
    GetHelpCtx := HelpCtx;
end;

function TView.GetPalette: PPalette;
begin
  GetPalette := nil;
end;

procedure TView.GetPeerViewPtr(var S: TStream; var P);
var
  Index: Integer;
begin
  S.Read(Index, SizeOf(Word));
  if (Index = 0) or (OwnerGroup = nil) then Pointer(P) := nil
  else
  begin
    Pointer(P) := FixupList^[Index];
    FixupList^[Index] := @P;
  end;
end;

function TView.GetState(AState: Word): Boolean;
begin
  GetState := State and AState = AState;
end;

procedure TView.GrowTo(X, Y: Integer);
var
  R: TRect;
begin
  R.Assign(Origin.X, Origin.Y, Origin.X + X, Origin.Y + Y);
  Locate(R);
end;

procedure TView.HandleEvent(var Event: TEvent);
begin
  if Event.What = evMouseDown then
    if (State and (sfSelected + sfDisabled) = 0) and
       (Options and ofSelectable <> 0) then
      if not Focus or (Options and ofFirstClick = 0) then
        ClearEvent(Event);
end;

procedure TView.Hide;
begin
  if State and sfVisible <> 0 then SetState(sfVisible, False);
end;

procedure TView.HideCursor;
begin
  SetState(sfCursorVis, False);
end;

procedure TView.KeyEvent(var Event: TEvent);
begin
  repeat GetEvent(Event) until Event.What = evKeyDown;
end;

procedure TView.Locate(var Bounds: TRect);
var
  R: TRect;
  Min, Max: TPoint;

function Range(Val, Min, Max: Integer): Integer;
begin
  if Val < Min then Range := Min else
    if Val > Max then Range := Max else
      Range := Val;
end;

begin
  SizeLimits(Min, Max);
  Bounds.B.X := Bounds.A.X + Range(Bounds.B.X - Bounds.A.X, Min.X, Max.X);
  Bounds.B.Y := Bounds.A.Y + Range(Bounds.B.Y - Bounds.A.Y, Min.Y, Max.Y);
  GetBounds(R);
  if not Bounds.Equals(R) then
  begin
    ChangeBounds(Bounds);
    if (Owner <> nil) and (State and sfVisible <> 0) then
    begin
      if State and sfShadow <> 0 then
      begin
        R.Union(Bounds);
        Inc(R.B.X, ShadowSize.X);
        Inc(R.B.Y, ShadowSize.Y);
      end;
      DrawUnderRect(R, nil);
    end;
  end;
end;

procedure TView.MakeFirst;
begin
  PutInFrontOf(Owner^.First);
end;

procedure TView.MakeGlobal(Source: TPoint; var Dest: TPoint); assembler;
asm
        LES     DI,Self
        XOR     AX,AX
        MOV     DX,AX
@@1:    ADD     AX,ES:[DI].TView.Origin.X
        ADD     DX,ES:[DI].TView.Origin.Y
        LES     DI,ES:[DI].TView.Owner
        MOV     SI,ES
        OR      SI,DI
        JNE     @@1
        ADD     AX,Source.X
        ADD     DX,Source.Y
        LES     DI,Dest
        CLD
        STOSW
        XCHG    AX,DX
        STOSW
end;

procedure TView.MakeLocal(Source: TPoint; var Dest: TPoint); assembler;
asm
        LES     DI,Self
        XOR     AX,AX
        MOV     DX,AX
@@1:    ADD     AX,ES:[DI].TView.Origin.X
        ADD     DX,ES:[DI].TView.Origin.Y
        LES     DI,ES:[DI].TView.Owner
        MOV     SI,ES
        OR      SI,DI
        JNE     @@1
        NEG     AX
        NEG     DX
        ADD     AX,Source.X
        ADD     DX,Source.Y
        LES     DI,Dest
        CLD
        STOSW
        XCHG    AX,DX
        STOSW
end;

function TView.MouseEvent(var Event: TEvent; Mask: Word): Boolean;
 label Ex;
begin
  if ButtonCount = 0 then Exit;
{  asm
    mov ax, 3
    push bp
    int 33h
    pop bp
    or  bx, bx
    jz  Ex
  end;}
  repeat GetEvent(Event) until Event.What and (Mask or evMouseUp) <> 0;
  MouseEvent := Event.What <> evMouseUp;
 Ex:
end;

function TView.MouseInView(Mouse: TPoint): Boolean;
var
  Extent: TRect;
begin
  MakeLocal(Mouse, Mouse);
  GetExtent(Extent);
  MouseInView := Extent.Contains(Mouse);
end;

procedure TView.MoveTo(X, Y: Integer);
var
  R: TRect;
begin
  R.Assign(X, Y, X + Size.X, Y + Size.Y);
  Locate(R);
end;

function TView.NextView: PView;
begin
  if @Self = Owner^.Last then NextView := nil else NextView := Next;
end;

procedure TView.NormalCursor;
begin
  SetState(sfCursorIns, False);
end;

function TView.Prev: PView; assembler;
asm
        LES     DI,Self
        MOV     CX,DI
        MOV     BX,ES
@@1:    MOV     AX,DI
        MOV     DX,ES
        LES     DI,ES:[DI].TView.Next
        CMP     DI,CX
        JNE     @@1
        MOV     SI,ES
        CMP     SI,BX
        JNE     @@1
end;

function TView.PrevView: PView;
begin
  if @Self = Owner^.First then PrevView := nil else PrevView := Prev;
end;

procedure TView.PutEvent(var Event: TEvent);
begin
  if Owner <> nil then Owner^.PutEvent(Event);
end;

procedure TView.PutInFrontOf(Target: PView);
var
  P, LastView: PView;
  R: TRect;

procedure MoveView;
begin
  Owner^.RemoveView(@Self);
  Owner^.InsertView(@Self, Target);
end;

begin
  if (Owner <> nil) and (Target <> @Self) and (Target <> NextView) and
    ((Target = nil) or (Target^.Owner = Owner)) then
    if State and sfVisible = 0 then MoveView else
    begin
      LastView := NextView;
      P := Target;
      while (P <> nil) and (P <> LastView) do P := P^.NextView;
      if P = nil then LastView := Target;
      State := State and not sfVisible;
      if LastView = Target then DrawHide(LastView);
      MoveView;
      State := State or sfVisible;
      if LastView <> Target then DrawShow(LastView);
      if Options and ofSelectable <> 0 then Owner^.ResetCurrent;
    end;
end;

procedure TView.PutPeerViewPtr(var S: TStream; P: PView);
var
  Index: Integer;
begin
  if (P = nil) or (OwnerGroup = nil) then Index := 0
  else Index := OwnerGroup^.IndexOf(P);
  S.Write(Index, SizeOf(Word));
end;

procedure TView.ResetCursor; assembler;
asm
        LES     DI,Self
        MOV     AX,ES:[DI].TView.State
        NOT     AX
        TEST    AX,sfVisible+sfCursorVis+sfFocused
        JNE     @@4
        MOV     AX,ES:[DI].TView.Cursor.Y
        MOV     DX,ES:[DI].TView.Cursor.X
@@1:    OR      AX,AX
        JL      @@4
        CMP     AX,ES:[DI].TView.Size.Y
        JGE     @@4
        OR      DX,DX
        JL      @@4
        CMP     DX,ES:[DI].TView.Size.X
        JGE     @@4
        ADD     AX,ES:[DI].TView.Origin.Y
        ADD     DX,ES:[DI].TView.Origin.X
        MOV     CX,DI
        MOV     BX,ES
        LES     DI,ES:[DI].TView.Owner
        MOV     SI,ES
        OR      SI,DI
        JE      @@5
        TEST    ES:[DI].TView.State,sfVisible
        JE      @@4
        LES     DI,ES:[DI].TGroup.Last
@@2:    LES     DI,ES:[DI].TView.Next
        CMP     CX,DI
        JNE     @@3
        MOV     SI,ES
        CMP     BX,SI
        JNE     @@3
        LES     DI,ES:[DI].TView.Owner
        JMP     @@1
@@3:    TEST    ES:[DI].TView.State,sfVisible
        JE      @@2
        MOV     SI,ES:[DI].TView.Origin.Y
        CMP     AX,SI
        JL      @@2
        ADD     SI,ES:[DI].TView.Size.Y
        CMP     AX,SI
        JGE     @@2
        MOV     SI,ES:[DI].TView.Origin.X
        CMP     DX,SI
        JL      @@2
        ADD     SI,ES:[DI].TView.Size.X
        CMP     DX,SI
        JGE     @@2
@@4:    MOV     CX,2000H
        JMP     @@6
@@5:    MOV     DH,AL
        XOR     BH,BH
        MOV     AH,2
        INT     10H
        MOV     CX,CursorLines
        LES     DI,Self
        TEST    ES:[DI].TView.State,sfCursorIns
        JE      @@6
        MOV     CH,0
        OR      CL,CL
        JNE     @@6
        MOV     CL,7
@@6:    MOV     AH,1
        INT     10H
end;

procedure TView.Select;
begin
  if Options and ofSelectable <> 0 then
    if Options and ofTopSelect <> 0 then MakeFirst else
      if Owner <> nil then Owner^.SetCurrent(@Self, NormalSelect);
end;

procedure TView.SetBounds(var Bounds: TRect); assembler;
asm
        PUSH    DS
        LES     DI,Self
        LDS     SI,Bounds
        MOV     AX,[SI].TRect.A.X
        MOV     ES:[DI].Origin.X,AX
        MOV     AX,[SI].TRect.A.Y
        MOV     ES:[DI].Origin.Y,AX
        MOV     AX,[SI].TRect.B.X
        SUB     AX,[SI].TRect.A.X
        MOV     ES:[DI].Size.X,AX
        MOV     AX,[SI].TRect.B.Y
        SUB     AX,[SI].TRect.A.Y
        MOV     ES:[DI].Size.Y,AX
        POP     DS
end;

procedure TView.SetCmdState(Commands: TCommandSet; Enable: Boolean);
begin
  if Enable then EnableCommands(Commands)
  else DisableCommands(Commands);
end;

procedure TView.SetCommands(Commands: TCommandSet);
begin
  CommandSetChanged := CommandSetChanged or (CurCommandSet <> Commands);
  CurCommandSet := Commands;
end;

procedure TView.SetCursor(X, Y: Integer);
begin
  Cursor.X := X;
  Cursor.Y := Y;
  DrawCursor;
end;

procedure TView.SetData(var Rec);
begin
end;

procedure TView.SetState(AState: Word; Enable: Boolean);
var
  Command: Word;
begin
  if Enable then
    State := State or AState else
    State := State and not AState;
  if Owner <> nil then
    case AState of
      sfVisible:
        begin
          if Owner^.State and sfExposed <> 0 then
            SetState(sfExposed, Enable);
          if Enable then DrawShow(nil) else DrawHide(nil);
          if Options and ofSelectable <> 0 then Owner^.ResetCurrent;
        end;
      sfCursorVis, sfCursorIns:
        DrawCursor;
      sfShadow:
        DrawUnderView(True, nil);
      sfFocused:
        begin
          ResetCursor;
          if Enable then
            Command := cmReceivedFocus else
            Command := cmReleasedFocus;
          Message(Owner, evBroadcast, Command, @Self);
        end;
    end;
end;

procedure TView.Show;
begin
  if State and sfVisible = 0 then SetState(sfVisible, True);
end;

procedure TView.ShowCursor;
begin
  SetState(sfCursorVis, True);
end;

procedure TView.SizeLimits(var Min, Max: TPoint);
begin
  Longint(Min) := 0;
  if Owner <> nil then
    Max := Owner^.Size else
    Longint(Max) := $7FFF7FFF;
end;

procedure TView.Store(var S: TStream);
var
  SaveState: Word;
begin
  SaveState := State;
  State := State and not (sfActive + sfSelected + sfFocused + sfExposed);
  S.Write(Origin,
    SizeOf(TPoint) * 3 +
    SizeOf(Byte) * 2 +
    SizeOf(Word) * 4);
  State := SaveState;
end;

function TView.TopView: PView;
var
  P: PView;
begin
  if TheTopView = nil then
  begin
    P := @Self;
    while (P <> nil) and (P^.State and sfModal = 0) do P := P^.Owner;
    TopView := P;
  end
  else TopView := TheTopView;
end;

function TView.Valid(Command: Word): Boolean;
begin
  Valid := True;
end;

procedure TView.WriteBuf(X, Y, W, H: Integer; var Buf); assembler;
var
  Target: Pointer; {Variables used by WriteView}
  Buffer: Pointer;
  Offset: Word;
asm
        CMP     H,0
        JLE     @@2
@@1:    MOV     AX,Y
        MOV     BX,X
        MOV     CX,W
        LES     DI,Buf
        CALL    WriteView
        MOV     AX,W
        SHL     AX,1
        ADD     WORD PTR Buf[0],AX
        INC     Y
        DEC     H
        JNE     @@1
@@2:
end;

procedure TView.WriteChar(X, Y: Integer; C: Char; Color: Byte;
  Count: Integer); assembler;
var
  Target: Pointer; {Variables used by WriteView}
  Buffer: Pointer;
  Offset: Word;
asm
        MOV     AL,Color
        CALL    MapColor
        MOV     AH,AL
        MOV     AL,C
        MOV     CX,Count
        OR      CX,CX
        JLE     @@2
        CMP     CX,256
        JLE     @@1
        MOV     CX,256
@@1:    MOV     DI,CX
        SHL     DI,1
        SUB     SP,DI
        MOV     DI,SP
        PUSH    SS
        POP     ES
        MOV     DX,CX
        CLD
        REP     STOSW
        MOV     CX,DX
        MOV     DI,SP
        MOV     AX,Y
        MOV     BX,X
        CALL    WriteView
@@2:
end;

procedure TView.WriteLine(X, Y, W, H: Integer; var Buf); assembler;
var
  Target: Pointer; {Variables used by WriteView}
  Buffer: Pointer;
  Offset: Word;
asm
        CMP     H,0
        JLE     @@2
@@1:    MOV     AX,Y
        MOV     BX,X
        MOV     CX,W
        LES     DI,Buf
        CALL    WriteView
        INC     Y
        DEC     H
        JNE     @@1
@@2:
end;

procedure TView.WriteStr(X, Y: Integer; Str: String; Color: Byte); assembler;
var
  Target: Pointer; {Variables used by WriteView}
  Buffer: Pointer;
  Offset: Word;
asm
        MOV     AL,Color
        CALL    MapColor
        MOV     AH,AL
        MOV     BX,DS
        LDS     SI,Str
        CLD
        LODSB
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    @@3
        MOV     DI,CX
        SHL     DI,1
        SUB     SP,DI
        MOV     DI,SP
        PUSH    SS
        POP     ES
        MOV     DX,CX
@@1:    LODSB
        STOSW
        LOOP    @@1
        MOV     DS,BX
        MOV     CX,DX
        MOV     DI,SP
        MOV     AX,Y
        MOV     BX,X
        CALL    WriteView
        JMP     @@2
@@3:    MOV     DS,BX
@@2:
end;

{ TFrame }

constructor TFrame.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  EventMask := EventMask or evBroadcast;
end;

procedure TFrame.FrameLine(var FrameBuf; Y, N: Integer;
  Color: Byte); assembler;
const
  InitFrame: array[0..17] of Byte =
    ($06, $0A, $0C, $05, $00, $05, $03, $0A, $09,
     $16, $1A, $1C, $15, $00, $15, $13, $1A, $19);
  FrameChars: array[0..31] of Char =
    '   À ³ÚÃ ÙÄÁ¿´ÂÅ   È ºÉÇ ¼ÍÏ»¶Ñ ';
var
  FrameMask: array[0..MaxViewWidth-1] of Byte;
asm
        LES     BX,Self
        MOV     DX,ES:[BX].TFrame.Size.X
        MOV     CX,DX
        DEC     CX
        DEC     CX
        MOV     SI,OFFSET InitFrame
        ADD     SI,N
        LEA     DI,FrameMask
        PUSH    SS
        POP     ES
        CLD
        MOVSB
        LODSB
        REP     STOSB
        MOVSB
        LES     BX,Self
        LES     BX,ES:[BX].TFrame.Owner
        LES     BX,ES:[BX].TGroup.Last
        DEC     DX
@1:     LES     BX,ES:[BX].TView.Next
        CMP     BX,WORD PTR Self[0]
        JNE     @2
        MOV     AX,ES
        CMP     AX,WORD PTR Self[2]
        JE      @10
@2:     TEST    ES:[BX].TView.Options,ofFramed
        JE      @1
        TEST    ES:[BX].TView.State,sfVisible
        JE      @1
        MOV     AX,Y
        SUB     AX,ES:[BX].TView.Origin.Y
        JL      @3
        CMP     AX,ES:[BX].TView.Size.Y
        JG      @1
        MOV     AX,0005H
        JL      @4
        MOV     AX,0A03H
        JMP     @4
@3:     INC     AX
        JNE     @1
        MOV     AX,0A06H
@4:     MOV     SI,ES:[BX].TView.Origin.X
        MOV     DI,ES:[BX].TView.Size.X
        ADD     DI,SI
        CMP     SI,1
        JG      @5
        MOV     SI,1
@5:     CMP     DI,DX
        JL      @6
        MOV     DI,DX
@6:     CMP     SI,DI
        JGE     @1
        OR      BYTE PTR FrameMask[SI-1],AL
        XOR     AL,AH
        OR      BYTE PTR FrameMask[DI],AL
        OR      AH,AH
        JE      @1
        MOV     CX,DI
        SUB     CX,SI
@8:     OR      BYTE PTR FrameMask[SI],AH
        INC     SI
        LOOP    @8
        JMP     @1
@10:    INC     DX
        MOV     AH,Color
        MOV     BX,OFFSET FrameChars
        MOV     CX,DX
        LEA     SI,FrameMask
        LES     DI,FrameBuf
@11:    SEGSS   LODSB
        XLAT
        STOSW
        LOOP    @11
end;

procedure TFrame.Draw;
var
  CFrame, CTitle: Word;
  F, I, L, Width: Integer;
  B: TDrawBuffer;
  Title: TTitleStr;
  Min, Max: TPoint;
begin
  if State and sfDragging <> 0 then
  begin
    CFrame := $0505;
    CTitle := $0005;
    F := 0;
  end else if State and sfActive = 0 then
  begin
    CFrame := $0101;
    CTitle := $0002;
    F := 0;
  end else
  begin
    CFrame := $0503;
    CTitle := $0004;
    F := 9;
  end;
  CFrame := GetColor(CFrame);
  CTitle := GetColor(CTitle);
  Width := Size.X;
  L := Width - 10;
  if PWindow(Owner)^.Flags and (wfClose+wfZoom) <> 0 then Dec(L,6);
  FrameLine(B, 0, F, Byte(CFrame));
  if (PWindow(Owner)^.Number <> wnNoNumber) and
     (PWindow(Owner)^.Number < 10) then
  begin
    Dec(L,4);
    if PWindow(Owner)^.Flags and wfZoom <> 0 then I := 7
    else I := 3;
    WordRec(B[Width - I]).Lo := PWindow(Owner)^.Number + $30;
  end;
  if Owner <> nil then Title := PWindow(Owner)^.GetTitle(L)
  else Title := '';
  if Title <> '' then
  begin
    L := Length(Title);
    if L > Width - 10 then L := Width - 10;
    if L < 0 then L := 0;
    I := (Width - L) shr 1;
    MoveChar(B[I - 1], ' ', CTitle, 1);
    MoveBuf(B[I], Title[1], CTitle, L);
    MoveChar(B[I + L], ' ', CTitle, 1);
  end;
  if State and sfActive <> 0 then
  begin
    if PWindow(Owner)^.Flags and wfClose <> 0 then
      MoveCStr(B[2], '[~þ~]', CFrame);
    if PWindow(Owner)^.Flags and wfZoom <> 0 then
    begin
      MoveCStr(B[Width - 5], '[~'#24'~]', CFrame);
      Owner^.SizeLimits(Min, Max);
      if Longint(Owner^.Size) = Longint(Max) then
        WordRec(B[Width - 4]).Lo := 18;
    end;
  end;
  WriteLine(0, 0, Size.X, 1, B);
  for I := 1 to Size.Y - 2 do
  begin
    FrameLine(B, I, F + 3, Byte(CFrame));
    WriteLine(0, I, Size.X, 1, B);
  end;
  FrameLine(B, Size.Y - 1, F + 6, Byte(CFrame));
  if State and sfActive <> 0 then
    if PWindow(Owner)^.Flags and wfGrow <> 0 then
      MoveCStr(B[Width - 2], '~ÄÙ~', CFrame);
  WriteLine(0, Size.Y - 1, Size.X, 1, B);
end;

function TFrame.GetPalette: PPalette;
const
  P: String[Length(CFrame)] = CFrame;
begin
  GetPalette := @P;
end;

procedure TFrame.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;

procedure DragWindow(Mode: Byte);
var
  Limits: TRect;
  Min, Max: TPoint;
begin
  Owner^.Owner^.GetExtent(Limits);
  Owner^.SizeLimits(Min, Max);
  Owner^.DragView(Event, Owner^.DragMode or Mode, Limits, Min, Max);
  ClearEvent(Event);
end;

begin
  TView.HandleEvent(Event);
  if Event.What = evMouseDown then
  begin
    MakeLocal(Event.Where, Mouse);
    if Mouse.Y = 0 then
    begin
      if (PWindow(Owner)^.Flags and wfClose <> 0) and
        (State and sfActive <> 0) and (Mouse.X >= 2) and (Mouse.X <= 4) then
      begin
        Event.What := evCommand;
        Event.Command := cmClose;
        Event.InfoPtr := Owner;
        PutEvent(Event);
        ClearEvent(Event);
      end else
        if (PWindow(Owner)^.Flags and wfZoom <> 0) and
          (State and sfActive <> 0) and (Event.Double or
          (Mouse.X >= Size.X - 5) and
          (Mouse.X <= Size.X - 3)) then
        begin
          Event.What := evCommand;
          Event.Command := cmZoom;
          Event.InfoPtr := Owner;
          PutEvent(Event);
          ClearEvent(Event);
        end else
          if PWindow(Owner)^.Flags and wfMove <> 0 then
            DragWindow(dmDragMove);
    end else
      if (State and sfActive <> 0) and (Mouse.X >= Size.X - 2) and
          (Mouse.Y >= Size.Y - 1) then
        if PWindow(Owner)^.Flags and wfGrow <> 0 then
          DragWindow(dmDragGrow);
  end;
end;

procedure TFrame.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  if AState and (sfActive + sfDragging) <> 0 then DrawView;
end;

{ TScrollBar }

constructor TScrollBar.Init(var Bounds: TRect);
const
  VChars: TScrollChars = (#30, #31, #177, #254, #178);
  HChars: TScrollChars = (#17, #16, #177, #254, #178);
begin
  TView.Init(Bounds);
  Value := 0;
  Min := 0;
  Max := 0;
  PgStep := 1;
  ArStep := 1;
  if Size.X = 1 then
  begin
    GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
    Chars := VChars;
  end else
  begin
    GrowMode := gfGrowLoY + gfGrowHiX + gfGrowHiY;
    Chars := HChars;
  end;
end;

constructor TScrollBar.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(Value, SizeOf(Integer) * 5 + SizeOf(TScrollChars));
end;

procedure TScrollBar.Draw;
begin
  DrawPos(GetPos);
end;

procedure TScrollBar.DrawPos(Pos: Integer);
var
  S: Integer;
  B: TDrawBuffer;
begin
  S := GetSize - 1;
  MoveChar(B[0], Chars[0], GetColor(2), 1);
  if Max = Min then
    MoveChar(B[1], Chars[4], GetColor(1), S - 1)
  else
  begin
    MoveChar(B[1], Chars[2], GetColor(1), S - 1);
    MoveChar(B[Pos], Chars[3], GetColor(3), 1);
  end;
  MoveChar(B[S], Chars[1], GetColor(2), 1);
  WriteBuf(0, 0, Size.X, Size.Y, B);
end;

function TScrollBar.GetPalette: PPalette;
const
  P: String[Length(CScrollBar)] = CScrollBar;
begin
  GetPalette := @P;
end;

function TScrollBar.GetPos: Integer;
var
  R: Integer;
begin
  R := Max - Min;
  if R = 0 then
    GetPos := 1 else
    GetPos := LongDiv(LongMul(Value - Min, GetSize - 3) + R shr 1, R) + 1;
end;

function TScrollBar.GetSize: Integer;
var
  S: Integer;
begin
  if Size.X = 1 then S := Size.Y else S := Size.X;
  if S < 3 then GetSize := 3 else GetSize := S;
end;

procedure TScrollBar.HandleEvent(var Event: TEvent);
var
  Tracking: Boolean;
  I, P, S, ClickPart: Integer;
  Mouse: TPoint;
  Extent: TRect;

function GetPartCode: Integer;
var
  Mark, Part: Integer;
begin
  Part := -1;
  if Extent.Contains(Mouse) then
  begin
    if Size.X = 1 then Mark := Mouse.Y else Mark := Mouse.X;
    if Mark = P then Part := sbIndicator else
    begin
      if Mark < 1 then Part := sbLeftArrow else
        if Mark < P then Part := sbPageLeft else
          if Mark < S then Part := sbPageRight else
            Part := sbRightArrow;
      if Size.X = 1 then Inc(Part, 4);
    end;
  end;
  GetPartCode := Part;
end;

procedure Clicked;
begin
  Message(Owner, evBroadcast, cmScrollBarClicked, @Self);
end;

begin
  TView.HandleEvent(Event);
  case Event.What of
    evMouseDown:
      begin
        Clicked;
        MakeLocal(Event.Where, Mouse);
        GetExtent(Extent);
        Extent.Grow(1, 1);
        P := GetPos;
        S := GetSize - 1;
        ClickPart := GetPartCode;
        if ClickPart <> sbIndicator then
        begin
          repeat
            MakeLocal(Event.Where, Mouse);
            if GetPartCode = ClickPart then
              SetValue(Value + ScrollStep(ClickPart));
          until not MouseEvent(Event, evMouseAuto);
        end else
        begin
          repeat
            MakeLocal(Event.Where, Mouse);
            Tracking := Extent.Contains(Mouse);
            if Tracking then
            begin
              if Size.X = 1 then I := Mouse.Y else I := Mouse.X;
              if I <= 0 then I := 1;
              if I >= S then I := S - 1;
            end else I := GetPos;
            if I <> P then
            begin
              DrawPos(I);
              P := I;
            end;
          until not MouseEvent(Event, evMouseMove);
          if Tracking and (S > 2) then
          begin
            Dec(S, 2);
            SetValue(LongDiv(LongMul(P - 1, Max - Min) + S shr 1, S) + Min);
          end;
        end;
        ClearEvent(Event);
      end;
    evKeyDown:
      if State and sfVisible <> 0 then
      begin
        ClickPart := sbIndicator;
        if Size.Y = 1 then
          case CtrlToArrow(Event.KeyCode) of
            kbLeft: ClickPart := sbLeftArrow;
            kbRight: ClickPart := sbRightArrow;
            kbCtrlLeft: ClickPart := sbPageLeft;
            kbCtrlRight: ClickPart := sbPageRight;
            kbHome: I := Min;
            kbEnd: I := Max;
          else
            Exit;
          end
        else
          case CtrlToArrow(Event.KeyCode) of
            kbUp: ClickPart := sbUpArrow;
            kbDown: ClickPart := sbDownArrow;
            kbPgUp: ClickPart := sbPageUp;
            kbPgDn: ClickPart := sbPageDown;
            kbCtrlPgUp: I := Min;
            kbCtrlPgDn: I := Max;
          else
            Exit;
          end;
        Clicked;
        if ClickPart <> sbIndicator then I := Value + ScrollStep(ClickPart);
        SetValue(I);
        ClearEvent(Event);
      end;
  end;
end;

procedure TScrollBar.ScrollDraw;
begin
  Message(Owner, evBroadcast, cmScrollBarChanged, @Self);
end;

function TScrollBar.ScrollStep(Part: Integer): Integer;
var
  Step: Integer;
begin
  if Part and 2 = 0 then Step := ArStep else Step := PgStep;
  if Part and 1 = 0 then ScrollStep := -Step else ScrollStep := Step;
end;

procedure TScrollBar.SetParams(AValue, AMin, AMax, APgStep,
  AArStep: Integer);
var
  SValue: Integer;
begin
  if AMax < AMin then AMax := AMin;
  if AValue < AMin then AValue := AMin;
  if AValue > AMax then AValue := AMax;
  SValue := Value;
  if (SValue <> AValue) or (Min <> AMin) or (Max <> AMax) then
  begin
    Value := AValue;
    Min := AMin;
    Max := AMax;
    DrawView;
    if SValue <> AValue then ScrollDraw;
  end;
  PgStep := APgStep;
  ArStep := AArStep;
end;

procedure TScrollBar.SetRange(AMin, AMax: Integer);
begin
  SetParams(Value, AMin, AMax, PgStep, ArStep);
end;

procedure TScrollBar.SetStep(APgStep, AArStep: Integer);
begin
  SetParams(Value, Min, Max, APgStep, AArStep);
end;

procedure TScrollBar.SetValue(AValue: Integer);
begin
  SetParams(AValue, Min, Max, PgStep, ArStep);
end;

procedure TScrollBar.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Value, SizeOf(Integer) * 5 + SizeOf(TScrollChars));
end;

{ TGroup }

constructor TGroup.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  Options := Options or (ofSelectable + ofBuffered);
  GetExtent(Clip);
  EventMask := $FFFF;
end;

constructor TGroup.Load(var S: TStream);
var
  FixupSave: PFixupList;
  Count, I: Integer;
  P, Q: ^Pointer;
  V: PView;
  OwnerSave: PGroup;
begin
  TView.Load(S);
  GetExtent(Clip);
  OwnerSave := OwnerGroup;
  OwnerGroup := @Self;
  FixupSave := FixupList;
  S.Read(Count, SizeOf(Word));
  asm
        MOV     CX,Count
        SHL     CX,1
        SHL     CX,1
        SUB     SP,CX
        MOV     FixupList.Word[0],SP
        MOV     FixupList.Word[2],SS
        MOV     DI,SP
        PUSH    SS
        POP     ES
        XOR     AL,AL
        CLD
        REP     STOSB
  end;
  for I := 1 to Count do
  begin
    V := PView(S.Get);
    if V <> nil then InsertView(V, nil);
  end;
  V := Last;
  for I := 1 to Count do
  begin
    V := V^.Next;
    P := FixupList^[I];
    while P <> nil do
    begin
      Q := P;
      P := P^;
      Q^ := V;
    end;
  end;
  OwnerGroup := OwnerSave;
  FixupList := FixupSave;
  GetSubViewPtr(S, V);
  SetCurrent(V, NormalSelect);
  if OwnerGroup = nil then Awaken;
end;

destructor TGroup.Done;
var
  P, T: PView;
begin
  Hide;
  P := Last;
  if P <> nil then
  begin
    repeat
      P^.Hide;
      P := P^.Prev;
    until P = Last;
    repeat
      T := P^.Prev;
      Dispose(P, Done);
      P := T;
    until Last = nil;
  end;
  FreeBuffer;
  TView.Done;
end;

function TGroup.At(Index: Integer): PView; assembler;
asm
        LES     DI,Self
        LES     DI,ES:[DI].TGroup.Last
        MOV     CX,Index
@@1:    LES     DI,ES:[DI].TView.Next
        LOOP    @@1
        MOV     AX,DI
        MOV     DX,ES
end;

procedure TGroup.Awaken;

  procedure DoAwaken(P: PView); far;
  begin
    P^.Awaken;
  end;

begin
  ForEach(@DoAwaken);
end;

procedure TGroup.ChangeBounds(var Bounds: TRect);
var
  D: TPoint;

procedure DoCalcChange(P: PView); far;
var
  R: TRect;
begin
  P^.CalcBounds(R, D);
  P^.ChangeBounds(R);
end;

begin
  D.X := Bounds.B.X - Bounds.A.X - Size.X;
  D.Y := Bounds.B.Y - Bounds.A.Y - Size.Y;
  if Longint(D) = 0 then
  begin
    SetBounds(Bounds);
    DrawView;
  end else
  begin
    FreeBuffer;
    SetBounds(Bounds);
    GetExtent(Clip);
    GetBuffer;
    Lock;
    ForEach(@DoCalcChange);
    Unlock;
  end;
end;

function TGroup.DataSize: Word;
var
  T: Word;

procedure AddSubviewDataSize(P: PView); far;
begin
  Inc(T, P^.DataSize);
end;

begin
  T := 0;
  ForEach(@AddSubviewDataSize);
  DataSize := T;
end;

procedure TGroup.Delete(P: PView);
var
  SaveState: Word;
begin
  SaveState := P^.State;
  P^.Hide;
  RemoveView(P);
  P^.Owner := nil;
  P^.Next := nil;
  if SaveState and sfVisible <> 0 then P^.Show;
end;

procedure TGroup.Draw;
var
  R: TRect;
begin
  if Buffer = nil then
  begin
    GetBuffer;
    if Buffer <> nil then
    begin
      Inc(LockFlag);
      Redraw;
      Dec(LockFlag);
    end;
  end;
  if Buffer <> nil then WriteBuf(0, 0, Size.X, Size.Y, Buffer^) else
  begin
    GetClipRect(Clip);
    Redraw;
    GetExtent(Clip);
  end;
end;

procedure TGroup.DrawSubViews(P, Bottom: PView);
begin
  while P <> Bottom do
  begin
    P^.DrawView;
    P := P^.NextView;
  end;
end;

procedure TGroup.EndModal(Command: Word);
begin
  if State and sfModal <> 0 then EndState := Command
  else TView.EndModal(Command);
end;

procedure TGroup.EventError(var Event: TEvent);
begin
  if Owner <> nil then Owner^.EventError(Event);
end;

function TGroup.Execute: Word;
var
  E: TEvent;
begin
  repeat
    EndState := 0;
    repeat
      GetEvent(E);
      if E.What <> evNothing then HandleEvent(E);
      if E.What <> evNothing then EventError(E);
    until EndState <> 0;
  until Valid(EndState);
  Execute := EndState;
end;

function TGroup.ExecView(P: PView): Word;
var
  SaveOptions: Word;
  SaveOwner: PGroup;
  SaveTopView: PView;
  SaveCurrent: PView;
  SaveCommands: TCommandSet;
  PP: TPoint;
  EV: TEvent;
begin
  if P <> nil then
  begin
    SaveOptions := P^.Options;
    SaveOwner := P^.Owner;
    SaveTopView := TheTopView;
    SaveCurrent := Current;
    GetCommands(SaveCommands);
    TheTopView := P;
    P^.Options := P^.Options and not ofSelectable;
    P^.SetState(sfModal, True);
    SetCurrent(P, EnterSelect);
    if SaveOwner = nil then Insert(P);
    ExecView := P^.Execute;
    if SaveOwner = nil then Delete(P);
    SetCurrent(SaveCurrent, LeaveSelect);
    P^.SetState(sfModal, False);
    P^.Options := SaveOptions;
    P := Current;
    if (P <> nil) and not P^.GetState(sfFocused) then
     begin
       EV.What := evMouseDown; PP.X := P^.Origin.X; PP.Y := P^.Size.Y - 1;
       MakeGlobal(PP, PP); EV.Where := PP;
       EV.Buttons := mbRightButton; PutEvent(EV);
     end;
    TheTopView := SaveTopView;
    SetCommands(SaveCommands);
  end else ExecView := cmCancel;
end;

function TGroup.First: PView;
begin
  if Last = nil then First := nil else First := Last^.Next;
end;

function TGroup.FirstMatch(AState: Word; AOptions: Word): PView;

function Matches(P: PView): Boolean; far;
begin
  Matches := (P^.State and AState = AState) and
    (P^.Options and AOptions = AOptions);
end;

begin
  FirstMatch := FirstThat(@Matches);
end;

function TGroup.FirstThat(P: Pointer): PView; assembler;
var
  ALast: Pointer;
asm
        LES     DI,Self
        LES     DI,ES:[DI].TGroup.Last
        MOV     AX,ES
        OR      AX,DI
        JE      @@3
        MOV     WORD PTR ALast[2],ES
        MOV     WORD PTR ALast[0],DI
@@1:    LES     DI,ES:[DI].TView.Next
        PUSH    ES
        PUSH    DI
        PUSH    ES
        PUSH    DI
        PUSH    WORD PTR [BP]
        CALL    P
        POP     DI
        POP     ES
        OR      AL,AL
        JNE     @@2
        CMP     DI,WORD PTR ALast[0]
        JNE     @@1
        MOV     AX,ES
        CMP     AX,WORD PTR ALast[2]
        JNE     @@1
        XOR     DI,DI
        MOV     ES,DI
@@2:    MOV     SP,BP
@@3:    MOV     AX,DI
        MOV     DX,ES
end;

function TGroup.FindNext(Forwards: Boolean): PView;
var
  P: PView;
begin
  FindNext := nil;
  if Current <> nil then
  begin
    P := Current;
    repeat
      if Forwards then P := P^.Next else P := P^.Prev;
    until ((P^.State and (sfVisible + sfDisabled) = sfVisible) and
      (P^.Options and ofSelectable <> 0)) or (P = Current);
    if P <> Current then FindNext := P;
  end;
end;

function TGroup.FocusNext(Forwards: Boolean): Boolean;
var
  P: PView;
begin
  P := FindNext(Forwards);
  FocusNext := True;
  if P <> nil then FocusNext := P^.Focus;
end;

procedure TGroup.ForEach(P: Pointer); assembler;
var
  ALast: Pointer;
asm
        LES     DI,Self
        LES     DI,ES:[DI].TGroup.Last
        MOV     AX,ES
        OR      AX,DI
        JE      @@4
        MOV     WORD PTR ALast[2],ES
        MOV     WORD PTR ALast[0],DI
        LES     DI,ES:[DI].TView.Next
@@1:    CMP     DI,WORD PTR ALast[0]
        JNE     @@2
        MOV     AX,ES
        CMP     AX,WORD PTR ALast[2]
        JE      @@3
@@2:    PUSH    WORD PTR ES:[DI].TView.Next[2]
        PUSH    WORD PTR ES:[DI].TView.Next[0]
        PUSH    ES
        PUSH    DI
        PUSH    WORD PTR [BP]
        CALL    P
        POP     DI
        POP     ES
        JMP     @@1
@@3:    PUSH    WORD PTR [BP]
        CALL    P
@@4:
end;

procedure TGroup.FreeBuffer;
begin
  if (Options and ofBuffered <> 0) and (Buffer <> nil) then
    DisposeCache(Pointer(Buffer));
end;

{ Allocate a group buffer if the group is exposed, buffered, and
  its area is less than 32768 bytes }

procedure TGroup.GetBuffer; assembler;
asm
        LES     DI,Self
        TEST    ES:[DI].State,sfExposed
        JZ      @@1
        TEST    ES:[DI].Options,ofBuffered
        JZ      @@1
        MOV     AX,ES:[DI].Buffer.Word[0]
        OR      AX,ES:[DI].Buffer.Word[2]
        JNZ     @@1
        MOV     AX,ES:[DI].TView.Size.X
        MUL     ES:[DI].TView.Size.Y
        JO      @@1
        SHL     AX,1
        JC      @@1
        JS      @@1
        LEA     DI,[DI].TView.Buffer
        PUSH    ES
        PUSH    DI
        PUSH    AX
        CALL    NewCache
@@1:
end;

procedure TGroup.GetData(var Rec);
type
  Bytes = array[0..65534] of Byte;
var
  I: Word;
  V: PView;
begin
  I := 0;
  if Last <> nil then
  begin
    V := Last;
    repeat
      V^.GetData(Bytes(Rec)[I]);
      Inc(I, V^.DataSize);
      V := V^.Prev;
    until V = Last;
  end;
end;

function TGroup.GetHelpCtx: Word;
var
  H: Word;
begin
  H:= hcNoContext;
  if Current <> nil then H := Current^.GetHelpCtx;
  if H = hcNoContext then H := TView.GetHelpCtx;
  GetHelpCtx := H;
end;

procedure TGroup.GetSubViewPtr(var S: TStream; var P);
var
  Index: Word;
begin
  S.Read(Index, SizeOf(Word));
  if Index > 0 then
    Pointer(P) := At(Index)
  else
    Pointer(P) := nil;
end;

procedure TGroup.HandleEvent(var Event: TEvent);

procedure DoHandleEvent(P: PView); far;
begin
  if (P = nil) or ((P^.State and sfDisabled <> 0)
    and (Event.What and (PositionalEvents or FocusedEvents) <> 0)) then Exit;
  case Phase of
    phPreProcess: if P^.Options and ofPreProcess = 0 then Exit;
    phPostProcess: if P^.Options and ofPostProcess = 0 then Exit;
  end;
  if Event.What and P^.EventMask <> 0 then P^.HandleEvent(Event);
end;

function ContainsMouse(P: PView): Boolean; far;
begin
  ContainsMouse := (P^.State and sfVisible <> 0) and
    P^.MouseInView(Event.Where);
end;

begin
  TView.HandleEvent(Event);
  if Event.What and FocusedEvents <> 0 then
  begin
    Phase := phPreProcess;
    ForEach(@DoHandleEvent);
    Phase := phFocused;
    DoHandleEvent(Current);
    Phase := phPostProcess;
    ForEach(@DoHandleEvent);
  end else
  begin
    Phase := phFocused;
    if (Event.What and PositionalEvents <> 0) then
      DoHandleEvent(FirstThat(@ContainsMouse)) else
      ForEach(@DoHandleEvent);
  end;
end;

function TGroup.IndexOf(P: PView): Integer; assembler;
asm
        LES     DI,Self
        LES     DI,ES:[DI].TGroup.Last
        MOV     AX,ES
        OR      AX,DI
        JE      @@3
        MOV     CX,DI
        MOV     BX,ES
        XOR     AX,AX
@@1:    INC     AX
        LES     DI,ES:[DI].TView.Next
        MOV     DX,ES
        CMP     DI,P.Word[0]
        JNE     @@2
        CMP     DX,P.Word[2]
        JE      @@3
@@2:    CMP     DI,CX
        JNE     @@1
        CMP     DX,BX
        JNE     @@1
        XOR     AX,AX
@@3:
end;

procedure TGroup.Insert(P: PView);
begin
  InsertBefore(P, First);
end;

procedure TGroup.InsertBefore(P, Target: PView);
var
  SaveState: Word;
begin
  if (P <> nil) and (P^.Owner = nil) and
    ((Target = nil) or (Target^.Owner = @Self)) then
  begin
    if P^.Options and ofCenterX <> 0 then
      P^.Origin.X := (Size.X - P^.Size.X) div 2;
    if P^.Options and ofCenterY <> 0 then
      P^.Origin.Y := (Size.Y - P^.Size.Y) div 2;
    SaveState := P^.State;
    P^.Hide;
    InsertView(P, Target);
    if SaveState and sfVisible <> 0 then P^.Show;
    if State and sfActive <> 0 then
      P^.SetState(sfActive, True);
  end;
end;

procedure TGroup.InsertView(P, Target: PView);
begin
  P^.Owner := @Self;
  if Target <> nil then
  begin
    Target := Target^.Prev;
    P^.Next := Target^.Next;
    Target^.Next := P;
  end else
  begin
    if Last = nil then P^.Next := P else
    begin
      P^.Next := Last^.Next;
      Last^.Next := P;
    end;
    Last := P;
  end;
end;

procedure TGroup.Lock;
begin
  if (Buffer <> nil) or (LockFlag <> 0) then Inc(LockFlag);
end;

procedure TGroup.PutSubViewPtr(var S: TStream; P: PView);
var
  Index: Word;
begin
  if P = nil then Index := 0
  else Index := IndexOf(P);
  S.Write(Index, SizeOf(Word));
end;

procedure TGroup.Redraw;
begin
  DrawSubViews(First, nil);
end;

procedure TGroup.RemoveView(P: PView); assembler;
asm
        PUSH    DS
        LDS     SI,Self
        LES     DI,P
        LDS     SI,DS:[SI].TGroup.Last
        PUSH    BP
        MOV     AX,DS
        OR      AX,SI
        JE      @@7
        MOV     AX,SI
        MOV     DX,DS
        MOV     BP,ES
@@1:    MOV     BX,WORD PTR DS:[SI].TView.Next[0]
        MOV     CX,WORD PTR DS:[SI].TView.Next[2]
        CMP     CX,BP
        JE      @@5
@@2:    CMP     CX,DX
        JE      @@4
@@3:    MOV     SI,BX
        MOV     DS,CX
        JMP     @@1
@@4:    CMP     BX,AX
        JNE     @@3
        JMP     @@7
@@5:    CMP     BX,DI
        JNE     @@2
        MOV     BX,WORD PTR ES:[DI].TView.Next[0]
        MOV     CX,WORD PTR ES:[DI].TView.Next[2]
        MOV     DS:WORD PTR [SI].TView.Next[0],BX
        MOV     DS:WORD PTR [SI].TView.Next[2],CX
        CMP     DX,BP
        JNE     @@7
        CMP     AX,DI
        JNE     @@7
        CMP     CX,BP
        JNE     @@6
        CMP     BX,DI
        JNE     @@6
        XOR     SI,SI
        MOV     DS,SI
@@6:    POP     BP
        PUSH    BP
        LES     DI,Self
        MOV     WORD PTR ES:[DI].TView.Last[0],SI
        MOV     WORD PTR ES:[DI].TView.Last[2],DS
@@7:    POP     BP
        POP     DS
end;

procedure TGroup.ResetCurrent;
begin
  SetCurrent(FirstMatch(sfVisible, ofSelectable), NormalSelect);
end;

procedure TGroup.ResetCursor;
begin
  if Current <> nil then Current^.ResetCursor;
end;

procedure TGroup.SelectNext(Forwards: Boolean);
var
  P: PView;
begin
  P := FindNext(Forwards);
  if P <> nil then P^.Select;
end;

procedure TGroup.SetCurrent(P: PView; Mode: SelectMode);

procedure SelectView(P: PView; Enable: Boolean);
begin
  if P <> nil then P^.SetState(sfSelected, Enable);
end;

procedure FocusView(P: PView; Enable: Boolean);
begin
  if (State and sfFocused <> 0) and (P <> nil) then
    P^.SetState(sfFocused, Enable);
end;

begin
  if Current <> P then
  begin
    Lock;
    FocusView(Current, False);
    if Mode <> EnterSelect then SelectView(Current, False);
    if Mode <> LeaveSelect then SelectView(P, True);
    FocusView(P, True);
    Current := P;
    Unlock;
  end;
end;

procedure TGroup.SetData(var Rec);
type
  Bytes = array[0..65534] of Byte;
var
  I: Word;
  V: PView;
begin
  I := 0;
  if Last <> nil then
  begin
    V := Last;
    repeat
      V^.SetData(Bytes(Rec)[I]);
      Inc(I, V^.DataSize);
      V := V^.Prev;
    until V = Last;
  end;
end;

procedure TGroup.SetState(AState: Word; Enable: Boolean);

procedure DoSetState(P: PView); far;
begin
  P^.SetState(AState, Enable);
end;

procedure DoExpose(P: PView); far;
begin
  if P^.State and sfVisible <> 0 then P^.SetState(sfExposed, Enable);
end;

begin
  TView.SetState(AState, Enable);
  case AState of
    sfActive, sfDragging:
      begin
        Lock;
        ForEach(@DoSetState);
        Unlock;
      end;
    sfFocused:
      if Current <> nil then Current^.SetState(sfFocused, Enable);
    sfExposed:
      begin
        ForEach(@DoExpose);
        if not Enable then FreeBuffer;
      end;
  end;
end;

procedure TGroup.Store(var S: TStream);
var
  Count: Integer;
  OwnerSave: PGroup;

procedure DoPut(P: PView); far;
begin
  S.Put(P);
end;

begin
  TView.Store(S);
  OwnerSave := OwnerGroup;
  OwnerGroup := @Self;
  Count := IndexOf(Last);
  S.Write(Count, SizeOf(Word));
  ForEach(@DoPut);
  PutSubViewPtr(S, Current);
  OwnerGroup := OwnerSave;
end;

procedure TGroup.Unlock;
begin
  if LockFlag <> 0 then
  begin
    Dec(LockFlag);
    if LockFlag = 0 then DrawView;
  end;
end;

function TGroup.Valid(Command: Word): Boolean;

function IsInvalid(P: PView): Boolean; far;
begin
  IsInvalid := not P^.Valid(Command);
end;

begin
  Valid := True;
  if Command = cmReleasedFocus then
  begin
    if (Current <> nil) and (Current^.Options and ofValidate <> 0) then
      Valid := Current^.Valid(Command);
  end
  else
    Valid := FirstThat(@IsInvalid) = nil;
end;

{ TWindow }

constructor TWindow.Init(var Bounds: TRect; ATitle: TTitleStr;
  ANumber: Integer);
begin
  TGroup.Init(Bounds);
  State := State or sfShadow;
  Options := Options or (ofSelectable + ofTopSelect);
  GrowMode := gfGrowAll + gfGrowRel;
  Flags := wfMove + wfGrow + wfClose + wfZoom;
  Title := NewStr(ATitle);
  Number := ANumber;
  Palette := wpBlueWindow;
  InitFrame;
  if Frame <> nil then Insert(Frame);
  GetBounds(ZoomRect);
end;

constructor TWindow.Load(var S: TStream);
var
  FrameIdent: Word;
begin
  TGroup.Load(S);
  S.Read(Flags, SizeOf(Byte) + SizeOf(TRect) + 2 * SizeOf(Integer));
  GetSubViewPtr(S, Frame);
  Title := S.ReadStr;
end;

destructor TWindow.Done;
begin
  TGroup.Done;
  DisposeStr(Title);
end;

procedure TWindow.Close;
begin
  if Valid(cmClose) then Free;
end;

function TWindow.ReactOnCmd;
begin
  ReactOnCmd := False;
end;

function TWindow.GetPalette: PPalette;
const
  P: array[wpBlueWindow..wpGrayWindow] of string[Length(CBlueWindow)] =
    (CBlueWindow, CCyanWindow, CGrayWindow);
begin
  GetPalette := @P[Palette];
end;

function TWindow.GetTitle(MaxSize: Integer): TTitleStr;
begin
  if Title <> nil then GetTitle := Title^
  else GetTitle := '';
end;

procedure TWindow.HandleEvent(var Event: TEvent);
var
  Limits: TRect;
  Min, Max: TPoint;
begin
  TGroup.HandleEvent(Event);
  if (Event.What = evCommand) then
    case Event.Command of
      cmResize:
        if Flags and (wfMove + wfGrow) <> 0 then
        begin
          Owner^.GetExtent(Limits);
          Dec(Limits.A.Y, Limits.B.Y);
          SizeLimits(Min, Max);
          DragView(Event, DragMode or (Flags and (wfMove + wfGrow)),
            Limits, Min, Max);
          ClearEvent(Event);
        end;
      cmClose:
        if (Flags and wfClose <> 0) and
          ((Event.InfoPtr = nil) or (Event.InfoPtr = @Self)) then
        begin
          ClearEvent(Event);
          if State and sfModal = 0 then Close else
          begin
            Event.What := evCommand;
            Event.Command := cmCancel;
            PutEvent(Event);
            ClearEvent(Event);
          end;
        end;
      cmZoom:
        if (Flags and wfZoom <> 0) and
          ((Event.InfoPtr = nil) or (Event.InfoPtr = @Self)) then
        begin
          Zoom;
          ClearEvent(Event);
        end;
    end
  else if Event.What = evKeyDown then
    case Event.KeyCode of
      kbTab:
        begin
          FocusNext(False);
          ClearEvent(Event);
        end;
      kbShiftTab:
        begin
          FocusNext(True);
          ClearEvent(Event);
        end;
    end
  else if (Event.What = evBroadcast) and (Event.Command = cmSelectWindowNum)
         and (Event.InfoInt = Number) and (Options and ofSelectable <> 0) then
  begin
    Select;
    ClearEvent(Event);
  end;
end;

procedure TWindow.InitFrame;
var
  R: TRect;
begin
  GetExtent(R);
  Frame := New(PFrame, Init(R));
end;

procedure TWindow.SetState(AState: Word; Enable: Boolean);
var
  WindowCommands: TCommandSet;
begin
  if (AState and sfActive <> 0) and ReactOnCmd and
     (InterfaceData.Options and (ouiAutoCmdLine+ouiHideCmdLine) = ouiAutoCmdLine) then
     ToggleCommandLine(not Enable);
  TGroup.SetState(AState, Enable);
  if AState = sfSelected then
  begin
    SetState(sfActive, Enable);
    WindowCommands := [cmNext, cmPrev, cmTile, cmCascade, cmClearDesktop, cmWindowManager];
    if Flags and wfGrow + wfMove <> 0 then
      WindowCommands := WindowCommands + [cmResize];
    if Flags and wfClose <> 0 then
      WindowCommands := WindowCommands + [cmClose];
    if Flags and wfZoom <> 0 then
      WindowCommands := WindowCommands + [cmZoom];
    if Enable then EnableCommands(WindowCommands)
    else DisableCommands(WindowCommands);
  end;
end;

function TWindow.StandardScrollBar(AOptions: Word): PScrollBar;
var
  R: TRect;
  S: PScrollBar;
begin
  GetExtent(R);
  if AOptions and sbVertical = 0 then
    R.Assign(R.A.X + 2, R.B.Y-1, R.B.X-2, R.B.Y) else
    R.Assign(R.B.X-1,R.A.Y+1,R.B.X,R.B.Y-1);
  S := New(PScrollBar, Init(R));
  Insert(S);
  if AOptions and sbHandleKeyboard <> 0 then
    S^.Options := S^.Options or ofPostProcess;
  StandardScrollBar := S;
end;

procedure TWindow.SizeLimits(var Min, Max: TPoint);
begin
  TView.SizeLimits(Min, Max);
  Min.X := MinWinSize.X;
  Min.Y := MinWinSize.Y;
end;

procedure TWindow.Store(var S: TStream);
begin
  TGroup.Store(S);
  S.Write(Flags, SizeOf(Byte) + SizeOf(TRect) + 2 * SizeOf(Integer));
  PutSubViewPtr(S, Frame);
  S.WriteStr(Title);
end;

procedure TWindow.Zoom;
var
  R: TRect;
  Max, Min: TPoint;
begin
  SizeLimits(Min, Max);
  if Longint(Size) <> Longint(Max) then
  begin
    GetBounds(ZoomRect);
    Longint(R.A) := 0;
    R.B := Max;
    Locate(R);
  end else Locate(ZoomRect);
end;

{ Message dispatch function }

function Message(Receiver: PView; What, Command: Word;
  InfoPtr: Pointer): Pointer;
var
  Event: TEvent;
begin
  Message := nil;
  if Receiver <> nil then
  begin
    Event.What := What;
    Event.Command := Command;
    Event.InfoPtr := InfoPtr;
    Receiver^.HandleEvent(Event);
    if Event.What = evNothing then Message := Event.InfoPtr;
  end;
end;

procedure TView.StoreText;
  var S: String;
      R: TRect;
      L: Array[1..4] of LongInt;
begin
  GetBounds(R); L[1] := R.A.X; L[2] := R.A.Y; L[3] := R.B.X; L[4] := R.B.Y;
  FormatStr(S, '%d, %d, %d, %d', L);
  WriteLn(F, '    View ', S, GetOptionsStr);
end;

function TView.GetOptionsStr;
  var S: String;
begin
  S := '';
  if Options and ofCenterX <> 0 then S := S + ', ofCenterX';
  if Options and ofCenterY <> 0 then S := S + ', ofCenterY';
  if Options and ofFramed <> 0 then S := S + ', ofFramed';
  if Options and ofPostProcess <> 0 then S := S + ', ofPostProcess';
  if Options and ofPreProcess <> 0 then S := S + ', ofPreProcess';
  if Options and ofValidate <> 0 then S := S + ', ofValidate';
  if Options and ofSecurity <> 0 then S := S + ', ofSecurity';
  GetOptionsStr := S;
end;


procedure TScrollBar.StoreText;
  var S: String;
      R: TRect;
      L: Array[1..4] of LongInt;
begin
  GetBounds(R); L[1] := R.A.X; L[2] := R.A.Y; L[3] := R.B.X; L[4] := R.B.Y;
  FormatStr(S, '%d, %d, %d, %d', L);
  WriteLn(F, '    SCROLLBAR ', S, GetOptionsStr);
end;

{ Background work }

procedure TView.Update;
begin
end;

procedure RegisterToPrior(P: PView);
begin
  if P = nil then Exit;
  if UpdatePrior = nil then New(UpdatePrior, Init(10,10));
  UpdatePrior^.AtInsert(0, P);
end;

procedure RegisterToBackground(P: PView);
begin
  if P = nil then Exit;
  if UpdateViews = nil then New(UpdateViews, Init(10,10));
  UpdateViews^.AtInsert(0, P);
end;

procedure Deregister(P: PView);
  var I: Integer;
begin
  I := 0;
  if UpdateViews <> nil then
    while I < UpdateViews^.Count do
       if P = UpdateViews^.At(I) then UpdateViews^.AtDelete(I) else Inc(I);
  I := 0;
  if UpdatePrior <> nil then
    while I < UpdatePrior^.Count do
       if P = UpdatePrior^.At(I) then UpdatePrior^.AtDelete(I) else Inc(I);
end;

procedure UpdateAll;
  procedure DoUpdate(P: PView); far;
  begin if (P <> nil) and ((P^.UpdTicks=0) or TimerExpired(P^.UpTmr)) then
         begin P^.Update; NewTimer(P^.UpTmr, P^.UpdTicks); end; end;
begin
  if UpdateViews <> nil then UpdateViews^.ForEach(@DoUpdate);
  if All and (UpdatePrior <> nil) and (UpdatePrior^.Count > 0) then
     DoUpdate(UpdatePrior^.At(0));
end;

end.
