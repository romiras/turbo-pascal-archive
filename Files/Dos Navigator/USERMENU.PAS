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

unit UserMenu;

interface
uses Objects, Views, Scroller, Drivers, ObjType;

function QuickExecExternal(N: Integer): Boolean;
function ExecUserMenu(DoGlobal: Boolean): Boolean;
procedure ScreenGrabber(ShowMessage: Boolean);

type
     PUserView = ^TUserView;
     TUserView = object(TScroller)
      Grabbing: Boolean;
      constructor Init(var R: TRect; H, V: PScrollbar);
      procedure Draw; virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure ChangeBounds(var Bounds: TRect); virtual;
     end;

     PUserWindow = ^TUserWindow;
     TUserWindow = object(TWindow)
      OldScreenWidth: Word;
      constructor Init;
      procedure CalcBounds(var Bounds: TRect; Delta: TPoint); virtual;
      procedure SetState(AState: Word; Enable: Boolean); virtual;
     end;

const RunFrom2E : Boolean = False;


const
      RUserWindow: TStreamRec = (
       ObjType: otUserWindow;
       VmtLink: Ofs(TypeOf(TUserWindow)^);
       Load: @TUserWindow.Load;
       Store: @TUserWindow.Store);

      RUserView: TStreamRec = (
       ObjType: otUserView;
       VmtLink: Ofs(TypeOf(TUserView)^);
       Load: @TUserView.Load;
       Store: @TUserView.Store);

implementation
uses DNApp, Advance, Startup, Messages, Menus, Commands, MicroEd, WinClp,
     DNHelp, FilesCol, DOS, Memory, Dialogs, Tree, RStrings;

type
     PUserMenuItem = ^TUserMenuItem;
     TUserMenuItem = record
      Text: PString;
      Level: Word;
      Line: Word;
      RunFrom2E: Boolean;
     end;

     PUserCollection = ^TUserCollection;
     TUserCollection = object(TCollection)
      procedure FreeItem(P: Pointer); virtual;
     end;

Constructor TUserWindow.Init;
 var R: TRect;
begin
 DeskTop^.GetExtent(R);
 R.Grow(1, 1);
 inherited Init(R, GetString( dlOutputTitle ), 0);
 OldScreenWidth := ScreenWidth;
 GetExtent(R); R.Grow(-1,-1);
 Insert(New(PUserView, Init(R, StandardScrollBar(sbHorizontal+sbHandleKeyboard),
                               StandardScrollBar(sbVertical+sbHandleKeyboard))));
end;

procedure TUserWindow.CalcBounds(var Bounds: TRect; Delta: TPoint);
begin
  if (Size.X <= ScreenWidth) and (ScreenWidth = OldScreenWidth) then
   begin inherited CalcBounds(Bounds, Delta); Exit end;
  DeskTop^.GetExtent(Bounds);
  Bounds.Grow(1, 2); Inc(Bounds.B.Y);
  OldScreenWidth := ScreenWidth;
end;

procedure TUserWindow.SetState(AState: Word; Enable: Boolean);
var
  WindowCommands: TCommandSet;
begin
  inherited SetState(AState, Enable);
  if AState = sfSelected then
  begin
    SetState(sfActive, Enable);
    if Enable then EnableCommands([cmHideLeft,cmHideRight,cmHideInactive])
    else DisableCommands([cmHideLeft,cmHideRight,cmHideInactive]);
  end;
end;

constructor TUserView.Init;
begin
 inherited Init(R, H, V);
 SetLimit(ScreenWidth, ScreenHeight);
 GrowMode := gfGrowHiX+gfGrowHiY;
 EventMask := $FFFF;
 Options := Options or ofSelectable;
 Grabbing := Off;
 ScrollTo( 0,
   Byte(InterfaceData.Options and ouiHideMenu = 0){ +
   Byte(InterfaceData.Options and ouiHideStatus = 0)});
 Delta.Y := VScrollBar^.Value;
end;

procedure TUserView.ChangeBounds;
begin
  inherited ChangeBounds(Bounds);
end;

procedure TUserView.Draw;
var
  I: Integer;
  B: TDrawBuffer;
begin
 for I := 0 to Size.Y - 1 do
  begin
   MoveChar(B, ' ', 07, SizeOf(B) div 2);
   if I + Delta.Y < UserScreenSize div (UserScreenWidth * 2)
     then Move( PWordArray(UserScreen)^[ ( I + Delta.Y ) * UserScreenWidth ], B, UserScreenWidth * 2 );
   WriteLine(0,I,Size.X,1,B[Delta.X]);
  end;
end;

procedure TUserView.HandleEvent;
begin
 inherited HandleEvent(Event);
 SetLimit(ScreenWidth, ScreenHeight);
 case Event.What of
  evCommand: case Event.Command of
              {cmGrabscreen: begin ClearEvent(Event); if Execute = cmOK then  end;}
              cmGetName: PString(Event.Infoptr)^ := GetString( dlOutputTitle );
              cmShowOutput, cmHideRight, cmHideLeft: begin
                             if Event.Command <> cmShowOutPut then
                                begin
                                  if Event.Command = cmHideLeft then Event.Command := cmPostHideLeft
                                                                else Event.Command := cmPostHideRight;
                                  PutEvent(Event);
                                end;
                             if Owner^.GetState(sfSelected) then Message(Owner, evCommand, cmClose, nil)
                               else PView(Event.InfoPtr^) := Owner;
                             ClearEvent(Event);
                            end;
             end;
  evKeyDown: begin
              if Size.X = ScreenWidth then CommandLine^.HandleEvent(Event);
             end;
 end;
end;

procedure TUserCollection.FreeItem(P: Pointer);
begin
 DisposeStr(PUserMenuItem(P)^.Text);
 Dispose(PUserMenuItem(P));
end;


function MakeString(S: String;
                    const AD, ADD, PD, PDD: DirStr;
                    const AN, PN: NameStr;
                    const AE, PE: ExtStr): String;
begin
  Replace('$$',#0, S);
  Replace('!!',#1, S);

  Replace('.!', AE, S);
  Replace('.$', PE, S);

  Replace('!:', Copy(AD,1,2), S);
  Replace('$:', Copy(PD,1,2), S);

  Replace('!\', Copy(AD,3,255), S);
  Replace('$\', Copy(PD,3,255), S);

  Replace('!/', Copy(ADD,3,255), S);
  Replace('$/', Copy(PDD,3,255), S);

  Replace('!', AN, S);
  Replace('$', PN, S);

  Replace(#0,'$', S);
  Replace(#1,'!', S);

  MakeString := S;
end;


function ExecUserMenu;
 var F: PTextReader;
     F1: Text;
     P: PUserCollection;
     S, S1: String;
     I: LongInt;
     UI: PUserMenuItem;
     StartPos: Integer;
     Items, OItems, SItems: PMenuItem;
     Menu: PMenu;
     PV: PView;
     R: TRect;
     NI, NW, LL: Word;
     EnterParms: Boolean;
     TitleStr: String[30];
     DefStr: String[125];
     RF2E: Boolean;
     Event: TEvent;

 Label 1, 2;

 function CheckFKeys(S: String): Word;
  var I: Integer;
      S1: String;
 begin
  CheckFKeys := kbNoKey;
  for I := 1 to 12 do
   begin
    S1 := 'F'+ItoS(I)+' ';
    if UpStrg(Copy(S, 1, Length(S1))) = S1 then begin CheckFKeys := kbF1+(I-1) shl 8; Exit end;
   end;
 end;

 var MenuLast: PMenuItem;

 function DoSubMenu: PMenuItem;
   var P1, P2: PMenuItem;
       UI,PU: PUSerMenuItem;
       KB: Word;
 begin
   DoSubMenu := nil;
   if I = P^.Count then Exit;
   UI := P^.At(I);
   {if UI^.Text = nil then begin DoSubMenu := NewLine(DoSubMenu); Exit end;}
   KB := kbNoKey;
   P2 := nil;
   if UI^.Text <> nil then P1 := NewItem(UI^.Text^, '', CheckFKeys(UI^.Text^), 1000 + I,
                                 hcLUserMenu+Byte(DoGlobal), nil)
                     else P1 := NewItem('Empty line', '', CheckFKeys(UI^.Text^), 1000 + I,
                                 hcLUserMenu+Byte(DoGlobal), nil);
   DoSubMenu := P1;
   while (I < P^.Count-1) do
    begin
     Inc(I);
     PU := P^.At(I);
     MenuLast := P1;
     if PU^.Level < UI^.Level then begin Dec(I); Exit; end;
     if PU^.Level > UI^.Level then begin P1^.SubMenu := NewMenu(DoSubMenu); P1^.Command := 0; end
      else begin
             if PU^.Text <> nil then
                 P1^.Next := NewItem(PU^.Text^, '', CheckFKeys(PU^.Text^), 1000 + I,
                                 hcLUserMenu+Byte(DoGlobal), nil) else P1^.Next := NewLine(nil);
             P1 := P1^.Next;
           end;
     MenuLast := P1;
    end;
 end;

 var UserParams: TUserParams;
     AD, ADD, PD, PDD: DirStr;
     AN, PN: NameStr;
     AE, PE: ExtStr;

begin
 FillChar(UserParams, SizeOf(UserParams), 0);
 RunFrom2E := Off;
 ExecUserMenu := False;
 TitleStr := '';
 DefStr := '';
 EnterParms := False;
 if DoGlobal then Goto 2;

 F := New(PTextReader, Init(SwpDir+'$dn'+ItoS(DNNumber)+'$.mnu'));
 if F <> nil then Goto 1;

 S := Advance.FExpand('dn.mnu');
 I := Length(S); if Abort then Goto 2;
 While (I > 0) and (S[I] <> '\') do Dec(I);
 if I = 0 then Goto 2;
 repeat
   F := New(PTextReader, Init(S));
   if F <> nil then Goto 1;

   While (I > 2) and (S[I-1] <> '\') do
     begin Delete(S,I-1,1); Dec(I); end;
   Delete(S,I-1,1); Dec(I);
 until I < 3;
2:
 DoGlobal := True;
 F := New(PTextReader, Init(SourceDir+'dn.mnu'));
 if F = nil then
  begin
   ErrMsg(dlMNUNotFound);
   Exit;
  end;
1:
 Message(Desktop, evBroadcast, cmGetUserParams, @UserParams); ClrIO;
 FSplit(UserParams.Active, AD, AN, AE); LowStr(AN); LowStr(AE);
 FSplit(UserParams.Passive, PD, PN, PE); LowStr(PN); LowStr(PE);
 Replace('$', #0, AD); Replace('!', #1, AD);
 Replace('$', #0, AE); Replace('!', #1, AE);
 Replace('$', #0, AN); Replace('!', #1, AN);
 Replace('$', #0, PD); Replace('!', #1, PD);
 Replace('$', #0, PN); Replace('!', #1, PN);
 Replace('$', #0, PE); Replace('!', #1, PE);
 ADD := AD; if ADD[0] > #3 then Dec(ADD[0]);
 PDD := PD; if PDD[0] > #3 then Dec(PDD[0]);
 New(P, Init(10, 10)); I := 0; NW := 30;
 while (not F^.EOF) and (IOResult = 0) do
  begin
   S := F^.GetStr; Inc(I);
   DelLeft(S); DelRight(S);
   if (S <> '') and (S[1]<>';') and (S[1] = '>') then
    begin
     RF2E := Off;
     DelFC(S);
     if S[1] = '>' then begin DelFC(S); RF2E := On end;
     S1 := ''; repeat S1 := S1+S[1]; DelFC(S); until (S = '') or (S[1] = ' ');
     DelFC(S);
     if (StoI(S1) > 0) then
      begin
       New(UI);
       S := MakeString(S, AD, ADD, PD, PDD, AN, PN, AE, PE);
       UI^.Text := NewStr(S);
       if Length(S) > NW then NW := Length(S);
       UI^.Line := I;
       UI^.Level := StoI(S1);
       UI^.RunFrom2E := RF2E;
       P^.Insert(UI);
      end;
    end;
  end;
 S := F^.FileName;
 Dispose(F, Done);
 if P^.Count > 0 then
  begin
   StartPos := -1;
   repeat
     I := 0; OItems := nil; SItems := nil; NI := 2;
     SItems := DoSubMenu;
     if SItems = nil then Break;
     Menu := NewMenu(SItems);
     R.Assign(0,0,NW+8,NI);
     PV := New(PMenuBox, Init(R, Menu, nil));
     PV^.Options := PV^.Options or ofCentered;
     I := DeskTop^.ExecView(PV);
     Dispose(PV, Done);
     DisposeMenu(Menu);
     if I < 1000 then
      begin
        EraseFile(UserParams.ActiveList);
        EraseFile(UserParams.PassiveList);
        if I = cmEditMenu then
         begin
            Event.What := evCommand;
            Event.Command :=  Byte(not DoGlobal)*cmLocalMenuFileEdit +
                              Byte(DoGlobal)*cmMenuFileEdit;
            Event.InfoPtr := nil;
            Application^.PutEvent(Event);
         end;
        Break;
      end;
     StartPos := I - 999;
     if (StartPos >= P^.Count - 1) or
        (PUserMenuItem(P^.At(StartPos-1))^.Level >= PUserMenuItem(P^.At(StartPos))^.Level) then
        begin
         ExecUserMenu := True;
         I := I - 1000; NW := I;
         UI := P^.At(I); LL := UI^.Line;
         if I >= P^.Count - 1 then LL := 65535 else LL := PUserMenuItem(P^.At(I+1))^.Line - 1;
         F := New(PTextReader, Init(S));
         Assign(F1, SwpDir+'$DN'+ItoS(DNNumber)+'$.BAT');
         Rewrite(F1);
         I := I - 1001;
         if F<>nil then
         begin
           for I := 0 to UI^.Line-1 do S := F^.GetStr;
           while not F^.EOF do
            begin
             S := F^.GetStr;
             DelLeft(S); DelRight(S);
             if (S <> '') then
               if (S[1] = '>') then Break else
                  if (S[1] = '<') then
                    begin
                     EnterParms := On;
                     DelFC(S);
                     if (S <> '') and (S[1] = '=') then
                      begin DelFC(S); DefStr := S; end
                      else
                       begin
                        DelLeft(S);
                        TitleStr := S;
                       end;
                     Continue;
                    end;
             { begin
               S1 := '';
               repeat
                S1 := S1+S[1]; DelFC(S);
               until (S = '') or (S[1] = ' ');
               DelFC(S);
               if (StoI(S1) <= UI^.Level) then Break;
              end else}
              EnterParms := EnterParms or (Pos('%3', S) > 0);
              WriteLn(F1, MakeString(S, AD, ADD, PD, PDD, AN, PN, AE, PE));
              RunFrom2E := UI^.RunFrom2E;
            end;
         end;
         Write(F1, '@Echo off');
         Close(F1);
         Dispose(F, Done);
         Break;
        end;
   until False;
  end;
 Dispose(P, Done);
 FreeStr := DefStr;
 if TitleStr = '' then TitleStr := GetString(dlMenuParamLabel);
 if EnterParms then
   ExecUserMenu := InputBox(GetString(dlMenuParams), TitleStr, FreeStr, 125, hsInputParams) = cmOK;
 with UserParams do
  begin
   if ActiveList = '' then ActiveList := '-';
   if PassiveList = '' then PassiveList := '-';
   FreeStr := ActiveList + ' ' + PassiveList + ' ' + FreeStr;
  end;
end;

type
     PGrabber = ^TGrabber;
     TGrabber = object(TView)
       ModalEnd: Boolean;
       Screen: PWordArray;
       R: TRect;
       BufSize: Word;
       constructor Init;
       destructor Done; virtual;
       procedure HandleEvent(var Event: TEvent); virtual;
       procedure Draw; virtual;
       function Execute: Word; virtual;
     end;

const Top: TPoint = (X:10;Y:5);
      Bot: TPoint = (X:21;Y:6);
      NotMessage: Boolean = On;
      Here: Boolean = Off;

procedure ScreenGrabber(ShowMessage: Boolean);
 var P: PGrabber;
     B: Boolean;
begin
  if Here then Exit;
  Here := On;
  if NotMessage and ShowMessage then
   begin
     MessageBox(GetString(dlGrabWelcome),
                nil, mfOKButton + mfInformation);
     NotMessage := Off;
   end;
  B := MsgActive; MsgActive := Off;
  P := New(PGrabber, Init);
  Application^.ExecView(P);
  Dispose(P, Done);
  Here := Off;
  MsgActive := B;
end;

constructor TGrabber.Init;
  var BB: TRect;
begin
  Application^.GetExtent(BB);
  inherited Init(BB);
  R.A := Top; R.B := Bot;
  BufSize := Application^.Size.X*2*Application^.Size.Y;
  Screen := memAlloc(BufSize);
  if Screen = nil then Fail;
  HideMouse;
  Move(ScreenBuffer^, Screen^, BufSize);
  ShowMouse;
  if Screen = nil then Fail;
  Options := Options or ofSelectable or ofTopSelect;
  {EventMask := $FFFF;}
end;


destructor TGrabber.Done;
begin
  if Screen <> nil then FreeMem(Screen, BufSize);
  inherited Done;
end;


procedure TGrabber.Draw;

 var B: TDrawBuffer;
     I: Integer;

      procedure Invert(var B; K: integer); assembler;
       asm
         mov cx, K
         les bx, B
        @@1:
         mov ax, word ptr es:[bx]
         xor ah, $7F
         and ah, $7F
         jnz @@2
         mov ah, 7
       @@2:
         mov word ptr es:[bx], ax
         add bx, 2
         loop @@1
       end;
begin
  with R do
   begin
     if A.X < 0 then Move(-A.X,0);
     if A.Y < 0 then Move(0,-A.Y);
     if B.X - A.X > Size.X then B.X := A.X + Size.X;
     if B.Y - A.Y > Size.Y then B.Y := A.Y + Size.Y;
     if B.X > Size.X then Move(Size.X-B.X, 0);
     if B.Y > Size.Y then Move(0, Size.Y-B.Y);
   end;
  Top := R.A; Bot := R.B;
  for I := 0 to Size.Y-1 do
   begin
     Move(Screen^[Size.X*I], B, Size.X*2);
     if (I >= R.A.Y) and (I < R.B.Y) and (R.A.X < R.B.X) then
          Invert(B[R.A.X], R.B.X - R.A.X);
     WriteLine(0,I,Size.X,1,B);
   end;
end;

function TGrabber.Execute;
 var E: TEvent;
begin
   ModalEnd := Off;
   DrawView;
   repeat
     GetEvent(E);
     if E.What <> evNothing then HandleEvent(E);
   until ModalEnd;
end;

procedure TGrabber.HandleEvent;
  var B: Boolean;
      Sh: Boolean;
      Stp: Integer;
  procedure CED; begin ClearEvent(Event); DrawView end;

  procedure MakeClip;
    var I, J: Integer;
        S: String;
  begin
    if Clipboard <> nil then Dispose(Clipboard, Done);
    Clipboard := New(PLineCollection, Init(R.B.Y - R.A.Y,10));
    for I := R.A.Y to R.B.Y-1 do
     begin
       S := '';
       for J := R.A.X to R.B.X-1 do S := S+Char(WordRec(Screen^[I*Size.X+J]).Lo);
       Clipboard^.Insert(NewStr(S));
     end;
    if SystemData.Options and ossUseSysClip <> 0 then SyncClipIn;
  end;


begin
  B := On;
  inherited HandleEvent(Event);
  case Event.What of
    evKeyDown:
      begin
        Sh := ShiftState and 3 <> 0;
        if ShiftState and 4 <> 0 then Stp := 8 else Stp := 1;
        case Event.KeyCode of
          kbPgUp, kbCtrlPgUp:  R.Move(0, -R.A.Y);
          kbHome, kbCtrlHome:  R.Move(-R.A.X, 0);
          kbEnd,  kbCtrlEnd:   R.Move(Size.X, 0);
          kbPgDn, kbCtrlPgDn:  R.Move(0, Size.Y);
          kbRight,kbCtrlRight: if Sh then begin Inc(R.B.X,Stp);R.B.X := Min(R.B.X, Size.X) end else R.Move(Stp,0);
          kbLeft, kbCtrlLeft:  if Sh then
                               begin
                                 if R.B.X > R.A.X+Stp then Dec(R.B.X, Stp)
                                                      else R.B.X := R.A.X+1;
                               end else R.Move(-Stp,0);
          kbEnter: begin
                     ModalEnd := On;
                     MakeClip;
                   end;
          kbESC: begin
                     ModalEnd := On;
                   end;
          else
          begin
            if Stp>1 then Stp := Stp div 2;
            case Event.KeyCode of
              kbUp,   kbCtrlUp:    if Sh then
                                   begin
                                     if R.B.Y > R.A.Y+Stp then Dec(R.B.Y,Stp)
                                                          else R.B.Y := R.A.Y+1;
                                   end else R.Move(0, -Stp);
              kbDown, kbCtrlDown : if Sh then begin Inc(R.B.Y,Stp);R.B.Y := Min(R.B.Y, Size.Y) end else R.Move(0,Stp);
              else B := Off;
            end;
          end;
        end;
      end
    else B := Off;
  end;
  if B then CED;
end;


function QuickExecExternal(N: Integer): Boolean;

 label 1;

 var UserParams: TUserParams;
     AD, ADD, PD, PDD: DirStr;
     AN, PN: NameStr;
     AE, PE: ExtStr;
     TitleStr, DefStr, S: String;
     F: PTextReader;
     F1: Text;
     I: Integer;
     OS2: char;
     SR: SearchRec absolute TitleStr;
     EnterParms, Local: Boolean;
  label RL;
begin
  QuickExecExternal := Off;

  Local := On;
  F := New(PTextReader, Init('DN.XRN'));

  if F = nil then
    begin
  RL:
      Local := Off;
      F := New(PTextReader, Init(SourceDir+'DN.XRN'));
    end;
  if F = nil then Exit;
  while not F^.EOF do
    begin
      OS2 := #0;
      TitleStr := F^.GetStr;

      I := PosChar(';', TitleStr);
      if I > 0 then TitleStr[0] := Char(I-1);
      if TitleStr[1] = '>' then
        begin
          if PosChar(TitleStr[2],'[]><')>0 then OS2 := TitleStr[2] ;
           {OS2 := Byte(TitleStr[2]=']')+2*Byte(TitleStr[2]='[');}
          if StoI(DelSpaces(Copy(TitleStr, 2+Byte(OS2<>#0), 255))) = N then Goto 1;
        end;
    end;
  Dispose(F, Done);
  if Local then Goto RL;
  Exit;
1:
  I := DNNumber;
  if OS2 = #0 then FreeStr := 'BAT'
    else
    begin
       I := 0;
       repeat
         ClrIO;
         Inc(I);
         FindFirst(SwpDir+'$DN'+ItoS(I)+'$.CMD', $3F xor VolumeID, SR);
       until (DOSError <> 0) or (I = 99) or Abort;
       ClrIO;
       FreeStr := 'CMD';
    end;

  FreeStr := SwpDir+'$DN'+ItoS(I)+'$.'+FreeStr;
  Assign(F1, FreeStr); ClrIO;
  Rewrite(F1);

  if IOResult <> 0 then begin Dispose(F, Done); Exit end;

  if OS2 <> #0 then
    begin
       GetDir(0, TitleStr);
       WriteLn(F1, '@', Copy(TitleStr, 1, 2));
       WriteLn(F1, '@cd ', TitleStr);
    end;

  TitleStr := ''; DefStr := ''; EnterParms := Off;
  Message(Desktop, evBroadcast, cmGetUserParams, @UserParams); ClrIO;
  FSplit(UserParams.Active, AD, AN, AE); LowStr(AN); LowStr(AE);
  FSplit(UserParams.Passive, PD, PN, PE); LowStr(PN); LowStr(PE);
  ADD := AD; if ADD[0] > #3 then Dec(ADD[0]);
  PDD := PD; if PDD[0] > #3 then Dec(PDD[0]);

  while not F^.EOF do
   begin
     S := F^.GetStr;
     DelRight(S);
     DelLeft(S);
     if (S <> '') and (S[1]=';') then Continue; {!!SF}
     if (S <> '') then
       if (S[1] = '>') then Break else
          if (S[1] = '<') then
            begin
             EnterParms := On;
             DelFC(S);
             if (S <> '') and (S[1] = '=') then
              begin DelFC(S); DefStr := S; end
              else
               begin
                DelLeft(S);
                TitleStr := S;
               end;
             Continue;
            end;
         EnterParms := EnterParms or (Pos('%3', S) > 0);
         WriteLn(F1, MakeString(S, AD, ADD, PD, PDD, AN, PN, AE, PE));
       end;
  WriteLn(F1, '@Echo off');

with UserParams do
 begin
  if ActiveList  <> '' then Writeln(F1, '@DEL ', ActiveList  );
  if PassiveList <> '' then Writeln(F1, '@DEL ', PassiveList );
 end;

  Write(F1, '@DEL ', FreeStr);
  Close(F1);
  Dispose(F, Done);

  if OS2<>#0 then S := Os2 + 'call ' + FreeStr
             else S :=FreeStr ;

  if TitleStr = '' then TitleStr := GetString(dlMenuParamLabel);

  QuickExecExternal := not EnterParms or (InputBox(GetString(dlMenuParams), TitleStr, DefStr, 125, hsInputParams) = cmOK);

  with UserParams do
   begin
    if ActiveList = '' then ActiveList := '-';
    if PassiveList = '' then PassiveList := '-';
    FreeStr := S + ' ' + ActiveList + ' ' + PassiveList + ' ' + DefStr;
   end;

end;




end.