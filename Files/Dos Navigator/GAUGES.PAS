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

{$I DN.DEF}

unit Gauges;

{ Useful gauges: clock and heap available viewer }

interface

uses Dos, Objects, Views, Drivers, FileCopy, Eraser,
     Commands, xTime, ObjType;


type

  { Trash can object }
  PTrashCan = ^TTrashCan;
  TTrashCan = object(TView)
    constructor Init(var R: TRect);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function GetPalette: PPalette; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

  PKeyMacros = ^TKeyMacros;
  TKeyMacros = object(TObject)
   Limit: Integer;
   Count: Integer;
   Keys: PWordArray;
   constructor Init;
   constructor Load(var S: TStream);
   procedure PutKey(KeyCode: Word);
   procedure Store(var S: TStream);
   procedure Play;
   destructor Done; virtual;
  end;


const LastHour: Word = $FF;
      LastMin: Word = 0;


      RTrashCan: TStreamRec = (
       ObjType: otTrashCan;
       VmtLink: Ofs(TypeOf(TTrashCan)^);
       Load: @TTrashCan.Load;
       Store: @TTrashCan.Store);

      RKeyMacros: TStreamRec = (
       ObjType: otKeyMacros;
       VmtLink: Ofs(TypeOf(TKeyMacros)^);
       Load: @TKeyMacros.Load;
       Store: @TKeyMacros.Store);

const
     KeyMacroses: PCollection = nil;
     MacroRecord: Boolean = False;

type
  PHeapView = ^THeapView;
  THeapView = object(TView)
    OldMem : LongInt;
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    procedure Update; virtual;
  end;

  PClockView = ^TClockView;
  TClockView = object(TView)
    Refresh: Byte;
    LastTime: DateTime;
    TimeStr: string[12];
    Vversion : word ;
    Utimer: TEventTimer;
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function FormatTimeStr(H, M, SS: Word): String; virtual;
    procedure Update; virtual;
  end;

procedure PrintFiles(Files: PCollection; Own: PView);


implementation
uses Memory, Tree, Messages, DNApp, Advance, FilesCol, RStrings, Startup;

{$I Version.INC}

constructor TKeyMacros.Init;
begin
 inherited Init;
 Limit := 10;
 Count := 0;
 Keys := MemAlloc(Limit * sizeOf(Word));
 if Keys = nil then Fail;
end;

destructor TKeyMacros.Done;
begin
 if Keys <> nil then FreeMem(Keys, Limit * sizeOf(Word));
 inherited Done;
end;

constructor TKeyMacros.Load;
begin
 S.Read(Limit, SizeOf(Word) * 2);
 Keys := MemAlloc(SizeOf(Word) * Limit);
 if Keys = nil then Fail;
 S.Read(Keys^, SizeOf(Word) * Count);
end;

procedure TKeyMacros.Store;
begin
 S.Write(Limit, SizeOf(Word) * 2);
 S.Write(Keys^, SizeOf(Word) * Count);
end;

procedure TKeyMacros.PutKey;
 var P: Pointer;
begin
 if Count >= Limit then
    begin
       Inc(Limit, 10);
       P := MemAlloc(Limit * SizeOf(Word));
       if P = nil then Exit;
       Move(Keys^, P^, Count * SizeOf(Word));
       Keys := P;
    end;
 Keys^[Count] := KeyCode;
 Inc(Count);
end;

procedure TKeyMacros.Play;
 var I: Integer;
begin
 for I := 0 to Count - 1 do
  Message(Application, evKeyDown, Keys^[I], nil);
end;

{------ Heap Window object ----------}

constructor THeapView.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  OldMem := 0;
end;

procedure THeapView.Draw;
var
  S: String;
  B: TDrawBuffer;
  C: Byte;
begin
  OldMem := MemAvail;
  Str(OldMem, S);
  C := GetColor(2);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;


procedure THeapView.Update;
begin
  if (OldMem <> MemAvail) then DrawView;
end;

{-------- ClockView Object --------}

function LeadingZero(w: Word): String;
var s: String[20];
begin
  Str(w:0, s);
  LeadingZero := Copy('00', 1, 2 - Length(s)) + s;
end;

constructor TClockView.Init(var Bounds: TRect);
  var s,hund: word;
begin
  TView.Init(Bounds);
  FillChar(LastTime, SizeOf(LastTime), #$FF);
  TimeStr := '';
  Refresh := 1;
  EventMask:= evMouse or evMessage ;
  Vversion := VersionWord ;
  Options:=Options or ofTopSelect;
  GrowMode := gfGrowHiX;
  GetTime(LastHour,LastMin , s , hund );
 { SetState(sfShadow,False);}
  RegisterToBackground(@Self);
  UpdTicks := 18;
  NewTimerSecs(UTimer, 1200+Random(1200));
end;

procedure TClockView.Draw;
var
  B: TDrawBuffer;
  C: Byte;
begin
  Size.Y := 1;
  C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  if MacroRecord then MoveStr(B, '>MACRO<', C)
                 else
                   begin
                     if Length(TimeStr) <> Size.X then
                       begin GrowTo(Length(TimeStr), 1); Exit end;
                     MoveStr(B, TimeStr, C);
                   end;
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TClockView.HandleEvent;
var P : TPoint;
    R : TRect;
begin
 P:=Size;Application^.GetBounds(R);
 If Event.What=evMouseDown then
   TView.DragView(Event,dmDragMove,R,P,P)
end;

procedure TClockView.Update;
var
  h,m,s,hund: word;
  d,mn,y : word ;
  SS: String[40];
  Event: TEvent;
  P : Pview ;
begin
  GetTime(h,m,s,hund);
  if Abs(s - LastTime.sec) >= Refresh then
  begin
    GetDate(y,mn,d,hund);
    if ShiftState and 7 <> 0 then
      begin
        if ShiftState and 3 <> 0 then TimeStr := ' '+FStr(MemAvail)+' '
          else begin
                 MakeDate(0, d, mn, y, 0, 0, SS);
                 TimeStr := ' '+Copy(SS, 1, 8); AddStr(TimeStr, ' ');
               end;
        UpdTicks := 6;
      end else
      begin
        UpdTicks := 18;
        with LastTime do
        begin
          inc(LastMin);
          Hour := h;
          Min := m;
          Sec := s;
          Day := d ;
          Month := mn ;
          Year := y ;
        end;
        TimeStr := FormatTimeStr(h, m, s);
      end;
    DrawView;
  end;
end;

function TClockView.FormatTimeStr;
  var N: String[3];
      S: String[20];
begin
  if (CountryInfo.TimeFmt = 0) and (H > 12) then
   begin
      S := ' '+LeadingZero(h-12) + CountryInfo.TimeSep + LeadingZero(m) + CountryInfo.TimeSep + LeadingZero(ss);
      N := 'pm ';
    end
  else
    begin
      S := ' '+LeadingZero(h)+ CountryInfo.TimeSep + LeadingZero(m) + CountryInfo.TimeSep + LeadingZero(ss);
      if CountryInfo.TimeFmt = 0
         then if (H < 12) then N := 'am ' else N := 'pm '
         else N := ' ';
    end;
  FormatTimeStr := S + N;
end;

const
  CTrashCan : string[Length(CGrayWindow)] = CGrayWindow;

{ TTrashCan }

constructor TTrashCan.Init;
begin
  inherited Init(R);
  GrowMode := gfGrowAll;
  Options := Options or ofTopSelect;
  EventMask := EventMask or evBroadcast;
  Hide;
end;

function TTrashCan.GetPalette: PPalette;
begin
   GetPalette := @CTrashCan;
end;

procedure TTrashCan.Draw;
var
  B: TDrawBuffer;
  C: Word;
begin
  if State and sfDragging <> 0 then C := 3
  else if State and sfSelected = 0 then C := 1
  else C := 2;
  C := GetColor(C);
  MoveStr(B, #209#209#216#209#209, C);
  WriteLine(0, 0, Size.X, 1, B);
  MoveStr(B, 'Trash', C);
  WriteLine(0, 1, Size.X, 1, B);
  MoveStr(B, #192#193#193#193#217, C);
  WriteLine(0, 2, Size.X, 1, B);
end;

procedure TTrashCan.HandleEvent(var Event:TEvent);
var
  Where: TPoint;
  SaveConfirm: Boolean;
  Extent: TRect;
  Msg: String;
  Cfms: Word;


begin
  inherited HandleEvent(Event);

  if (Event.What = evBroadcast) and (Event.Command = cmDropped) then
  begin
   Cfms := Confirms;
   if Confirms and cfMouseConfirm = 0 then Confirms := 0;
   Message(PCopyRec(Event.InfoPtr)^.Owner, evCommand, cmEraseGroup, PCopyRec(Event.InfoPtr)^.FC);
   Confirms := Cfms;
   {EraseFiles(PCopyRec(Event.InfoPtr)^.FC);}
   ClearEvent(Event);
  end;
  if Event.What = evMouseDown then
   if Event.Double then
    begin
      Event.What := evCommand;
      Event.Command := cmReanimator;
      Event.InfoPtr := nil;
      PutEvent(Event);
      ClearEvent(Event);
    end else
    begin
      Owner^.GetExtent(Extent);
      DragView(Event, dmDragMove, Extent, Size, Size);
    end;
end;

procedure TTrashCan.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and sfSelected <> 0 then
    EnableCommands([cmNext, cmPrev]);
  if (AState and (sfSelected + sfFocused + sfDragging) <> 0) then
    DrawView;
end;

procedure PrintFiles;
  var PF: PFileRec;
      I,J: Integer;
      S: String;
begin
  if Files = nil then Exit;
  J := 0;
  for I := 0 to Files^.Count-1 do
    begin
      PF := Files^.At(I);
      if PF^.Attr and Directory = 0 then Inc(J);
    end;
  if J = 0 then Exit;
  if Files^.Count = 1 then
    begin
      S := GetString(dlDIFile) + ' ' + MakeFileName(PFileRec(Files^.At(0))^.Name)
    end else S := ItoS(Files^.Count)+' '+GetString(dlDIFiles);
  if MessageBox(GetString(dlPM_Print)+S+'?', nil, mfYesNoConfirm) <> cmYes then Exit;
  for I := 0 to Files^.Count - 1 do
    begin
       PF := Files^.At(I);
       if PF^.Attr and Directory = 0 then
         begin
           S := MakeNormName(PF^.Owner^, MakeFileName(PF^.Name));
           Message(Own, evCommand, cmCopyUnselect, PF);
           Message(Application, evCommand, cmFilePrint, @S);
         end;
    end;
end;

end.

