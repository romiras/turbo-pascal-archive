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
//     "Based on Dos Navigator by RIT Research Labs."
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

unit HelpFile;

interface

uses Objects, Drivers, Views, Scroller, HelpKernel;

const
  CHelpColor      = #$37#$3F#$3A#$13#$13#$30#$3E#$1E#$3F;
  CHelpBlackWhite = #$07#$0F#$07#$70#$70#$07#$0F#$70#$7F;
  CHelpMonochrome = #$07#$0F#$07#$70#$70#$07#$0F#$70#$7F;
  CHelpViewer     = #6#7#8#9;
  CHelpWindow     = #139#140#141#142#143#144#145#146#163;

  MaxUndo = 200;

{ THelpViewer }

type
  PHelpViewer = ^THelpViewer;
  THelpViewer = object(TScroller)
    HFile: PHelpFile;
    Topic: PHelpTopic;
    Selected: Integer;
    Pos: TPoint;
    NumTopics: Integer;
    Indexes: Array [1..MaxUndo] of THelpParameters;
    constructor Init(var Bounds: TRect; AHScrollBar,
      AVScrollBar: PScrollBar; AHelpFile: PHelpFile; Context: Word);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

{ THelpWindow }

  PHelpWindow = ^THelpWindow;
  THelpWindow = object(TWindow)
    constructor Init(HFile: PHelpFile; Context: Word);
    function GetPalette: PPalette; virtual;
  end;

implementation
uses DNApp, Commands, DNHelp, RStrings;

{ THelpViewer }

constructor THelpViewer.Init(var Bounds: TRect; AHScrollBar,
  AVScrollBar: PScrollBar; AHelpFile: PHelpFile; Context: Word);
begin
  inherited Init(Bounds, AHScrollBar, AVScrollBar);
  HelpCtx := hcHelp;
  Options := Options or ofSelectable;
  GrowMode := gfGrowHiX + gfGrowHiY;
  HFile := AHelpFile;
  Topic := AHelpFile^.GetTopic(Context);
  Topic^.SetWidth(Size.X);
  SetLimit(78+Size.X, Topic^.NumLines+Size.Y);
  Selected := 1;
  with Indexes[1] do
   begin
     Selected:=0;
     Index:=Context;
     CursorXY:= Pos;
     DeltaXY := Delta;
   end;
  NumTopics := 1;
end;

destructor THelpViewer.Done;
begin
  inherited Done;
  Dispose(HFile, Done);
  Dispose(Topic, Done);
end;

procedure THelpViewer.ChangeBounds(var Bounds: TRect);
begin
  inherited ChangeBounds(Bounds);
  Topic^.SetWidth(Size.X);
  SetLimit({Limit.X} 78+Size.X, Topic^.NumLines + Size.Y);
end;

procedure THelpViewer.Draw;
var
  B: TDrawBuffer;
  Line: String;
  I, J, L: Integer;
  KeyCount: Integer;
  Normal, Keyword, SelKeyword, HiLite, C: Byte;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Word;
begin
  Normal := GetColor(1);
  Keyword := GetColor(2);
  SelKeyword := GetColor(3);
  HiLite := GetColor(4);
  KeyCount := 0;
  KeyPoint.X := 0;
  KeyPoint.Y := 0;
  if Delta.Y < Pos.Y then Pos.Y := Delta.Y;
  if Delta.X < Pos.X then Pos.X := Delta.X;
  if Pos.X + Size.X - 1 < Delta.X then Pos.X := Delta.X - Size.X + 1;
  if Pos.Y + Size.Y - 1 < Delta.Y then Pos.Y := Delta.Y - Size.Y + 1;
  SetCursor(Delta.X - Pos.X, Delta.Y - Pos.Y);
  ShowCursor;
  Topic^.SetWidth(Size.X); Selected := -1;
  if Topic^.GetNumCrossRefs > 0 then begin
    repeat
      Inc(KeyCount);
      Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
      if (KeyPoint.Y = Delta.Y + 1) and (KeyPoint.X - 1 <= Delta.X) and
         (Delta.X < KeyPoint.X + KeyLength) and (KeyRef > 0) then
          begin Selected := KeyCount; Break; end;
    until (KeyCount >= Topic^.GetNumCrossRefs) or (KeyPoint.Y > Pos.Y + Size.Y);
    KeyCount := 0;
    repeat
      Inc(KeyCount);
      Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
    until (KeyCount >= Topic^.GetNumCrossRefs) or (KeyPoint.Y > Pos.Y);
   end;
  for I := 1 to Size.Y do begin
    MoveChar(B, ' ', Normal, Size.X);
    Line := Topic^.GetLine(I + Pos.Y);
    MoveStr(B, Copy(Line, Pos.X+1, Size.X), Normal);
    while I + Pos.Y = KeyPoint.Y do begin
      L := KeyLength;
      if KeyPoint.X < Pos.X then
      begin
        Dec(L, Pos.X - KeyPoint.X);
        KeyPoint.X := Pos.X;
      end;
      If KeyRef >= $FFF0
        then C := HiLite
        else
      if KeyCount = Selected
        then C := SelKeyword
        else C := Keyword;
      for J := 0 to L-1 do
        WordRec(B[KeyPoint.X - Pos.X + J]).Hi := C;
      Inc(KeyCount);
      if KeyCount <= Topic^.GetNumCrossRefs then
        Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef)
      else KeyPoint.Y := 0;
    end;
    WriteLine(0, I-1, Size.X, 1, B);
  end;
end;

function THelpViewer.GetPalette: PPalette;
const
  P: String[Length(CHelpViewer)] = CHelpViewer;
begin
  GetPalette := @P;
end;

procedure THelpViewer.HandleEvent(var Event: TEvent);
var
  KeyPoint, Mouse: TPoint;
  KeyLength: Byte;
  KeyRef: Word;
  KeyCount: Integer;

procedure MakeSelectVisible;
var
  D: TPoint;
begin
  if (Selected <= 0) or (Selected > Topic^.GetNumCrossRefs) then Exit;
  Topic^.GetCrossRef(Selected, KeyPoint, KeyLength, KeyRef);
  ScrollTo(KeyPoint.X, KeyPoint.Y-1);
end;

procedure SwitchToTopic(KeyRef: Word);
begin
  If KeyRef >= $FFF0 then Exit;
  if NumTopics = MaxUndo then Move(Indexes[2], Indexes[1], (MaxUndo - 1)*SizeOf(THelpParameters))
                         else Inc(NumTopics);
  With Indexes[NumTopics] do
   begin
    Index := KeyRef;
    CursorXY.X := 0;
    CursorXY.Y:=  0;
    DeltaXY.X := 0;
    DeltaXY.Y := 0;
   end;
  With Indexes[NumTopics-1] do
   begin
    CursorXY:=Pos;
    DeltaXY:=Delta;
   end;

  if Topic <> nil then Dispose(Topic, Done);
  Topic := HFile^.GetTopic(KeyRef);
  Topic^.SetWidth(Size.X);
  ScrollTo(0, 0);
  SetLimit(78+Size.X{Limit.X}, Topic^.NumLines+Size.Y);
  Selected := 1;
  DrawView;
end;

procedure PrevTopic;
begin
 if NumTopics = 1 then Exit;
 Dec(NumTopics);
 if Topic <> nil then Dispose(Topic, Done);
 KeyCount := Indexes[NumTopics].Index;
 Topic := HFile^.GetTopic(KeyCount);
 Topic^.SetWidth(Size.X);
 HScrollBar^.Value := Indexes[NumTopics].DeltaXY.X;
 VScrollBar^.Value := Indexes[NumTopics].DeltaXY.Y;
 Pos:=Indexes[NumTopics].CursorXY;
 Delta:=Indexes[NumTopics].DeltaXY;
 SetLimit(78+Size.X{Limit.X}, Topic^.NumLines+Size.Y);
 DrawView;
end;

begin
  inherited HandleEvent(Event);
  case Event.What of
    evKeyDown:
      begin
        case Event.KeyCode of
          kbTab:
            begin
              if Selected >= Topic^.GetNumCrossRefs then Selected := 1
               else if Selected > 0 then Inc(Selected) else
                if Topic^.GetNumCrossRefs > 0  then
                 begin
                  repeat
                   KeyCount := 0;
                   repeat
                    Inc(KeyCount);
                    Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
                   until (KeyCount >= Topic^.GetNumCrossRefs) or (KeyPoint.Y > Delta.Y) or
                         (KeyPoint.Y = Delta.Y) and (KeyPoint.X >= Delta.X);
                   if (KeyPoint.Y > Delta.Y) or (KeyPoint.Y = Delta.Y) and (KeyPoint.X >= Delta.X) then Break;
                   LongInt(Delta) := 0;
                  until False;
                  ScrollTo(KeyPoint.X, KeyPoint.Y-1);
                  Selected := KeyCount;
                 end;
              MakeSelectVisible;
            end;
          kbShiftTab:
            begin
               if Selected > 1 then Dec(Selected) else
               if Selected > 0 then Selected := Topic^.GetNumCrossRefs else
                if Topic^.GetNumCrossRefs > 0  then
                 begin
                  repeat
                   KeyCount := Topic^.GetNumCrossRefs + 1;
                   repeat
                    Dec(KeyCount);
                    Topic^.GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
                   until (KeyCount >= 1) or (KeyPoint.Y < Delta.Y) or
                         (KeyPoint.Y = Delta.Y) and (KeyPoint.X <= Delta.X);
                   if (KeyPoint.Y < Delta.Y) or (KeyPoint.Y = Delta.Y) and (KeyPoint.X <= Delta.X) then Break;
                   Delta.X := Limit.X;
                   Delta.Y := Limit.Y;
                  until False;
                  ScrollTo(KeyPoint.X, KeyPoint.Y-1);
                  Selected := KeyCount;
                 end;
              MakeSelectVisible;
            end;
          kbEnter:
            begin
              if (Selected >= 0) and (Selected <= Topic^.GetNumCrossRefs) then
              begin
                Topic^.GetCrossRef(Selected, KeyPoint, KeyLength, KeyRef);
                SwitchToTopic(KeyRef);
              end;
            end;
          kbAltF1: PrevTopic;
          kbEsc:
            begin
              Event.What := evCommand;
              Event.Command := cmClose;
              PutEvent(Event);
            end;
        else
          Exit;
        end;
        DrawView;
        ClearEvent(Event);
      end;
    evMouseDown:
      if Event.Buttons and mbLeftButton <> 0 then
       begin
        if Event.Double then Message(@Self, evKeyDown, kbEnter, nil);
        repeat
         MakeLocal(Event.Where, Mouse);
         ScrollTo(Pos.X + Mouse.X, Pos.Y + Mouse.Y);
        until not MouseEvent(Event, evMouseMove+evMouseAuto);
        ClearEvent(Event);
      end;
    evCommand:
     Case Event.Command of
      cmClose: if (Owner^.State and sfModal <> 0) then
        begin
          EndModal(cmClose);
          ClearEvent(Event);
        end;
      cmNo: PrevTopic;
      cmOk: begin
                Event.What := evKeyDown;
                Event.KeyCode := kbEnter;
                PutEvent(Event);
            end;
      cmYes, cmSave: begin
                Event.What := evKeyDown;
                if Event.Command = cmYes then Event.KeyCode := kbTab
                                         else Event.KeyCode := kbShiftTab;
                PutEvent(Event);
             end;
      cmDefault: with Indexes[NumTopics] do
           if NOT (Index=2) then
                    SwitchToTopic(2);
      cmCancel: with Indexes[NumTopics] do
           if NOT (Index=2) then
                    SwitchToTopic(2);
     end;
  end;
end;

{ THelpWindow }

constructor THelpWindow.Init(HFile: PHelpFile; Context: Word);
var
  R: TRect;
begin
  R.Assign(0, 0, 72, 20);
  TWindow.Init(R, GetString( dlHelp ), wnNoNumber);
  Options := Options or ofCentered;
  R.Grow(-2,-1);
  Insert(New(PHelpViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard), HFile, Context)));
end;

function THelpWindow.GetPalette: PPalette;
const
  P: String[Length(CHelpWindow)] = CHelpWindow;
begin
  GetPalette := @P;
end;

end.

