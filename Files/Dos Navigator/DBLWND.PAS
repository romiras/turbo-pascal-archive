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

unit DblWnd;

interface
 uses Views, Objects, Drivers, FlPanel, HideView, Tree, FViewer;

type
    {
    PCloseBox = ^TCloseBox;
    TCloseBox = object(TView)
      constructor Init(var R: TRect; ACommand: Word);
      procedure Draw; vurtual;
      procedure HandleEvent(var Event: TEvent); virtual;
    end;
    }

    PDoubleWindow = ^TDoubleWindow;
    TDoubleWindow = object(TStdWindow)
     isValid: Boolean;
     LeftView, RightView: PHideView;
     RDrive, LDrive: Byte;
     Separator: PSeparator;
     LPanel, RPanel: PFilePanel;
     Info: PHideView;
     LTree: PHTreeView;
     QView: PFileViewer;
     OldBounds: TRect;
     LType, RType: Integer;
     constructor Init(Bounds: TRect; ANumber, ADrive: Integer);
     procedure InitLeftView(R: TRect);
     procedure InitRightView(R: TRect);
     procedure InitInterior;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     function  Valid(C: Word): Boolean; virtual;
     procedure ChangeBounds(var Bounds: TRect); virtual;
     procedure HandleCommand(var Event: TEvent);
    end;


const
     CDoubleWindow = #80#81#82 +        { 1-3    Frame (P,A,I)            }
                     #83#84    +        { 4,5    Scroll Bar (Page, Arrow) }
                     #85#86#87#88#89 +  { 6-10   Panel (NT,Sp,ST,NC,SC)   }
                     #90#91    +        { 11,12  Panel Top (A,P)          }
                     #92#93    +        { 13,14  Viewer (NT,ST)           }
                     #94#95#96#97 +
                     #98#99#100 +       { 15-21  Tree (T,NI,SI,Df,DS,SI,DI}
                     #101 +             { 22     Tree info                }
                     #102#103 +         { 23,24  Disk info (NT, HT)       }
                     #119#120#121#122 +
                     #123#124#125 +     { 25-31  File Info                }
                     #165 +             { 32-38  File Panel               }
                     #172#173#174#175#176#177#180#181 +
                     #186#187#188       { Drive Line };

const dtInfo  = 1;
      dtPanel = 2;
      dtTree  = 3;
      dtView  = 4;

implementation
uses DiskInfo, Commands, FileCopy, FilesCol, Advance, Startup, DNApp, RStrings;

{
constructor TCloseBox.Init;
begin
  inherited Init(R);
  Command := ACommand;
end;

procedure TCloseBox.Draw;
 var B: TDrawBuffer;
begin
  if Owner^.GetState(sfSelected+sfActive) then
    if Size.X > 0 then GrowTo(0,1) else Exit
    else if Size.X = 0 then GrowTo(0,3);
  MoveChar(B, ' ', Owner^.GetColor(1), Size.X);
  MoveCStr(B, '[~þ~]', Owner^.GetColor($0302));
  WriteLine(0,0,Size.X,Size.Y,B);
end;

procedure TCloseBox.HandleEvent;
begin
  inherited HnadleEvent(Event);
  if Event.What = evMouseDown then
    Message(Owner, evCommand, cm
end;

}
constructor TDoubleWindow.Init;
 var P: PFilePanel;
     P1: PInfoView;
     P2: PTopView;
     R: TRect;
     PV: PView;
begin
 inherited Init(Bounds, '', ANumber); isValid := On;
 Options := Options or ofTileAble;
 EventMask := $FFFF; Abort := Off;
 if (ADrive <= 0) or not ValidDrive(Char(ADrive+64)) then ADrive := 0;
 LDrive := ADrive; RDrive := ADrive;
 GetExtent(R); R.Grow(-1, 0);
 R.A.X := R.B.X div 2;
 R.B.X := R.A.X+2;
 Separator := New(PSeparator, Init(R, Size.X));
 Insert(Separator); LeftView := nil; RightView := nil;
 InitInterior;
 if Abort then IsValid := False;
 case PanelDefaults.LeftPanel of
   fdoInfoDrive: Message(@Self, evCommand, cmDiskInfo, nil);
   fdoTreeFrive: Message(@Self, evCommand, cmDirTree, nil);
   fdoRightOnly: Message(@Self, evCommand, cmHideLeft, nil);
 end;
end;

procedure TDoubleWindow.InitLeftView;
 var PV: PSpecScroll;
     P: PFilePanel;
     P1: PInfoView;
     P2: PTopView;
     PD: PDriveLine;
     B: TRect;
begin
 if Abort then Exit;
 B := R; B.A.X := B.B.X; Inc(B.B.X); Inc(B.A.Y); Dec(B.B.Y, 3);
 New(PV, Init(B));
 New(P, Init(R, LDrive, PV));
 if Abort then begin Dispose(P, Done); Dispose(PV, Done); Exit end;

 New(P1, Init(R)); P1^.Panel := P; P^.InfoView := P1;

 New(P2, Init(R)); P2^.Panel := P;
 P^.DirView := P2; P2^.EventMask := $FFFF;

 New(PD, Init(R, P));
 P^.DriveLine := PD;

 P^.ChangeBounds(R);


 Insert(PV);
 Insert(P2);
 Insert(P1);
 Insert(P);
 Insert(PD);
 LeftView := P;
end;

procedure TDoubleWindow.InitRightView;
 var
     P: PFilePanel;
     P1: PInfoView;
     P2: PTopView;
     PS: PSpecScroll;
     PD: PDriveLine;
     RR: TRect;
begin
 if Abort then Exit;
 RR.B.X := RR.A.X + 1;
 New(PS, Init(RR));

 New(P, Init(R, RDrive, PS));
 if Abort then begin Dispose(P, Done); Dispose(PS, Done); Exit end;

 New(P1, Init(R)); P1^.Panel := P; P^.InfoView := P1;

 New(P2, Init(R)); P2^.Panel := P;
 P^.DirView := P2; P2^.EventMask := $FFFF;

 New(PD, Init(R, P));
 P^.DriveLine := PD;

 P^.ChangeBounds(R);
 Insert(PS); Insert(P2); Insert(P1); Insert(PD);
 Insert(P); RightView := P;
end;

function TDoubleWindow.Valid;
begin
 Valid := inherited Valid(C) and isValid;
end;

procedure TDoubleWindow.ChangeBounds(var Bounds: TRect);
var
  D: TPoint;
  R: TRect;
  P: PSeparator;
  LVisible, RVisible, SVisible: Boolean;
label 1;
begin
  D.X := Bounds.B.X - Bounds.A.X - Size.X;
  D.Y := Bounds.B.Y - Bounds.A.Y - Size.Y;
  P := PSeparator(Separator);
  GetExtent(R); R.Grow(-1, 0);
  R.A.X := (R.B.X * P^.OldX) div P^.OldW;
  if (Longint(D) = 0) and (R.A.X = P^.Origin.X) then
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
    GetExtent(R);
    Frame^.ChangeBounds(R);
    P := PSeparator(Separator);
    LVisible := LeftView^.GetState(sfVisible);
    RVisible := RightView^.GetState(sfVisible);
    SVisible := P^.GetState(sfVisible);
    if not LVisible or not RVisible then
        begin
         if SVisible then P^.Hide;
         GetExtent(R); R.Grow(-1,-1);
         if LVisible then LeftView^.ChangeBounds(R)
                     else RightView^.ChangeBounds(R);
         Goto 1;
        end;
    if not SVisible then P^.Show;
    GetExtent(R); R.Grow(-1, 0);
    R.A.X := (R.B.X * P^.OldX) div P^.OldW;
    R.B.X := R.A.X + 2;
    Separator^.ChangeBounds(R);
    GetExtent(R); R.Grow(-1, -1);
    R.A.X := (R.B.X * P^.OldX) div P^.OldW+2;
    RightView^.ChangeBounds(R);
    GetExtent(R); R.Grow(-1, -1);
    R.B.X := (R.B.X * P^.OldX) div P^.OldW;
    LeftView^.ChangeBounds(R);
1:
    Redraw;
    UnLock;
   end;
end;


constructor TDoubleWindow.Load;
 var B: Boolean;
begin
 inherited Load(S);
 S.Read(OldBounds, sizeof(OldBounds)+2*sizeof(Integer));
 GetSubViewPtr(S, Separator);
 GetSubViewPtr(S, LeftView);
 GetSubViewPtr(S, RightView);
 GetSubViewPtr(S, LPanel);
 GetSubViewPtr(S, RPanel);
 GetSubViewPtr(S, Info);
 S.Read(B, 1); LTree := nil;
 if B then GetSubViewPtr(S, LTree);
 S.Read(B, 1); QView := nil;
 if B then GetSubViewPtr(S, QView);
 if (LTree <> nil) and (LTree^.Size.X > 0) then LTree^.ReadAfterLoad;
 if (RType = dtInfo) or (LType = dtInfo) then PDiskInfo(Info)^.ReadData(False);
 if (RType = dtView) or (LType = dtView) then
    Message(@Self, evCommand, cmEnableView, nil);
 IsValid := True;
end;

procedure TDoubleWindow.Store;
 var B: Boolean;
begin
 inherited Store(S);
 S.Write(OldBounds, sizeof(OldBounds)+sizeof(LType)+sizeof(RType));
 PutSubViewPtr(S, Separator);
 PutSubViewPtr(S, LeftView);
 PutSubViewPtr(S, RightView);
 PutSubViewPtr(S, LPanel);
 PutSubViewPtr(S, RPanel);
 PutSubViewPtr(S, Info);
 if LTree <> nil then B := True else B := False;
 S.Write(B,1);
 if B then PutSubViewPtr(S, LTree);
 if QView <> nil then B := True else B := False;
 S.Write(B,1);
 if B then PutSubViewPtr(S, QView);
end;

procedure TDoubleWindow.InitInterior;
 var R: TRect;
begin
 GetExtent(R); R.Grow(-1, -1); R.A.X := R.B.X div 2+2;
 InitRightView(R);
 if Abort then Exit;

 GetExtent(R); R.Grow(-1, -1); R.B.X := R.B.X div 2;
 InitLeftView(R);

 if Abort then Exit;
 RightView^.Select;
 RPanel := PFilePanel(RightView); LType := dtPanel; RType := dtPanel; LType := dtPanel;
 LPanel := PFilePanel(LeftView); GetExtent(R);
 R.Grow(-1,-1); R.B.X := Separator^.Origin.X;
 Info := nil;
 LTree := nil;
 QView := nil;
end;


procedure TDoubleWindow.HandleCommand;
 var R, R1, R2: TRect;
     I, K: Integer;
     LVisible, RVisible, LSelected: Boolean;
     Sp: PSeparator;
     EV: TEvent;
     P: PView;
     S: String;

 procedure UnLck; begin Dec(R.A.X); ChangeBounds(R); Inc(R.A.X); ChangeBounds(R); UnLock; end;

 procedure SwitchLeft;
 begin
  if not RVisible then Exit;
  if LVisible then
   begin
    GetBounds(R); OldBounds := R;
    R.A.X := RightView^.Origin.X + R.A.X - 1;
    Lock; LeftView^.HideView; RightView^.Select; Locate(R); Redraw; UnLock;
   end else
   begin
    GetBounds(R);
    K := (Sp^.OldW - Sp^.OldX);
    if K > 0 then
       I := ((10 * (Size.X * Sp^.OldX)) div K) div 10
     else I := 0;
    Dec(R.A.X, I);
    Lock; LeftView^.ShowView; Redraw; ChangeBounds(R); UnLock;
    Owner^.Redraw;
   end
 end;

 procedure SwitchRight;
 begin
  if not LVisible then Exit;
  if RVisible then
   begin
    GetBounds(R); OldBounds := R;
    R.B.X := Separator^.Origin.X + R.A.X + 1;
    Lock; RightView^.HideView; LeftView^.Select; Locate(R); Redraw; UnLock;
   end else
   begin
    GetBounds(R); {R.A.X := OldBounds.A.X; R.B.X := OldBounds.B.X;}
    if Sp^.OldX > 0 then
       I := ((Size.X * 10 * (Sp^.OldW - Sp^.OldX)) div Sp^.OldX) div 10
      else I := 1;
    Inc(R.B.X, I);
    Lock; RightView^.ShowView; Redraw; ChangeBounds(R); UnLock;
    Owner^.Redraw;
   end
 end;

 procedure GetDirName;
 begin
  if LVisible and (LType = dtPanel) then
     PString(Event.InfoPtr)^ := PFilePanel(LPanel)^.DirectoryName else
  if RVisible and (RType = dtPanel) then
     PString(Event.InfoPtr)^ := PFilePanel(RPanel)^.DirectoryName
 end;

 procedure ChangeDrvLeft;
  var S: String;
      P: TPoint;
 begin
  if LType <> dtPanel then
   begin
    LeftView^.GetBounds(R);
    R.A.Y := 1; R.B.Y := Size.Y;
    LPanel^.Locate(R);
   end;
  GetBounds(R);
  if not LVisible or (LType <> dtPanel) then
  begin
   if LVisible then P.X := Origin.X + (1+LeftView^.Size.X) div 2
      else if Separator^.OldW > 0 then
              P.X := (OldBounds.A.X + ((OldBounds.B.X - OldBounds.A.X) * Separator^.OldX) div Separator^.OldW) div 2
             else P.X := 1;
   P.Y := Origin.Y + 3;
   S := SelectDrive(P.X, P.Y, LPanel^.DirectoryName[1], On);
   if S = '' then Exit; ClrIO;
   Message(LPanel, evCommand, cmChangeDrv, @S);
   if LType <> dtPanel then
    begin
     Lock; if not LVisible then SwitchLeft; LeftView^.GetBounds(R1);
     LeftView^.HideView; R1.A.Y := 1; R1.B.Y := Size.Y - 1; LPanel^.Locate(R1);
     LeftView := LPanel; LType := dtPanel; LPanel^.ShowView; UnLck;
    end else if not LVisible then SwitchLeft; LeftView^.GetBounds(R1);
   end else
    begin
     Message(LPanel, evCommand, cmChangeDrive, nil);
    end;
   if (ShiftState and 3 <> 0) and (not LSelected) then LeftView^.Select;
 end;

 procedure ChangeDrvRight;
  var S: String;
      P: TPoint;
 begin
  if RType <> dtPanel then
   begin
    RightView^.GetBounds(R);
    R.A.Y := 1; R.B.Y := Size.Y;
    RPanel^.Locate(R);
   end;
  GetBounds(R);
  if not RVisible or (RType <> dtPanel) then
  begin
   if RVisible then P.X := Origin.X + RightView^.Origin.X + (1+RightView^.Size.X) div 2
               else if Separator^.OldW > 0 then
                       P.X := (OldBounds.B.X + OldBounds.A.X + ((OldBounds.B.X - OldBounds.A.X) *
                                            Separator^.OldX) div Separator^.OldW) div 2
                     else P.X := OldBounds.B.X + OldBounds.A.X;
   P.Y := Origin.Y + 3;
   S := SelectDrive(P.X, P.Y, RPanel^.DirectoryName[1], On);
   if S = '' then Exit; ClrIO;
   Message(RPanel, evCommand, cmChangeDrv, @S);
   if RType <> dtPanel then
    begin
     Lock; if not RVisible then SwitchRight; RightView^.GetBounds(R1);
     RightView^.HideView; R1.A.Y := 1; R1.B.Y := Size.Y - 1; RPanel^.Locate(R1);
     RightView := RPanel; RType := dtPanel; RPanel^.ShowView; UnLck;
    end else if not RVisible then SwitchRight; RightView^.GetBounds(R1);
  end else Message(RPanel, evCommand, cmChangeDrive, nil);
  if (mem[$40:$17] and 3 <> 0) and LSelected then RightView^.Select;
 end;

 procedure ViewInsert;
  var R2: TRect;
      S: PViewScroll;
      P: PView;
 begin
  R2.Assign(1,1,2,5);
  S := New(PViewScroll, Init(R2)); S^.Options := S^.Options or ofPostProcess;
  QView := New(PHFileViewer, Init(R1, nil, '', S, True, (EditorDefaults.ViOpt and 1) <> 0));
  if not QView^.Valid(0) then
    begin Dispose(S, Done); Dispose(QView, Done); QView := nil; Exit end
    else begin
          Lock; Insert(QView); Insert(S); QView^.HideView; UnLock;
         end;
 end;

 procedure InsertTree;
  var R2: TRect;
      S: PScrollBar;
      P: PView;
 begin
  R2.Assign(1,1,2,5);
  S := New(PScrollBar, Init(R2));
  S^.Options := S^.Options or ofPostProcess;
  LTree := New(PHTreeView, Init(R1, 0, False, S));
  if not LTree^.Valid(0) then
    begin Dispose(S, Done); Dispose(LTree, Done); LTree := nil; Exit end
    else begin
          P := New(PTreeInfoView, Init(R1, LTree)); LTree^.Info := P;
          Lock; Insert(LTree); Insert(S); Insert(P); LTree^.HideView; UnLock;
         end;
 end;

 type PPView = ^PView;

 procedure SwitchView(dtType: Byte);
  var V: PHideView;
 begin
  GetBounds(R); if LSelected then RightView^.GetBounds(R1)
                             else LeftView^.GetBounds(R1);
  case dtType of
    dtTree: begin
              if LTree = nil then InsertTree; if LTree = nil then Exit;
              V := LTree;
            end;
    dtView: begin
              if QView = nil then ViewInsert; if QView = nil then Exit;
              V := QView;
            end;
    dtInfo: begin if Info = nil then
                  begin Info := New(PDiskInfo, Init(R)); Info^.HideView;
                        Insert(Info);
                  end;
                  V := Info;
            end;
  end;
  V^.GetBounds(R1);
  if (LType = dtType) and LVisible then
   begin LeftView := LPanel; Lock; V^.HideView;
         R1.A.Y := 1; R1.B.Y := Size.Y - 1; LPanel^.Locate(R1);
         LPanel^.ShowView; LType := dtPanel;
         if LSelected then LPanel^.Select; UnLck end else
  if (RType = dtType) and RVisible then
   begin RightView := RPanel; Lock; V^.HideView;
         R1.A.Y := 1; R1.B.Y := Size.Y - 1; RPanel^.Locate(R1);
         RPanel^.ShowView; RType := dtPanel;
         if not LSelected then RPanel^.Select; UnLck end else
  if (RType = dtType) and not RVisible then SwitchRight else
  if (LType = dtType) and not LVisible then SwitchLeft else
  if LSelected then
   begin Lock; RightView^.GetBounds(R1); RightView^.HideView; RightView := V;
         R1.A.Y := 1; R1.B.Y := Size.Y - 1; V^.Locate(R1);
         V^.ShowView; RType := dtType;
         if not RVisible then SwitchRight;
             {begin GetBounds(R); R.A.X := OldBounds.A.X; R.B.X := OldBounds.B.X;end;}
          LeftView^.Select;
          Redraw; UnLock;
         end else
   begin Lock; LeftView^.GetBounds(R1); LeftView^.HideView; LeftView := V;
         R1.A.Y := 1; R1.B.Y := Size.Y - 1; V^.Locate(R1);
         V^.ShowView; LType := dtType;
         if not LVisible then SwitchLeft;
          { begin GetBounds(R); R.A.X := OldBounds.A.X; R.B.X := OldBounds.B.X end;}
         RightView^.Select;
         Redraw; UnLock; end;
   if not V^.GetState(sfVisible) then
    begin
      V^.Free;
      case dtType of
        dtTree: LTree := nil;
        dtView: QView := nil;
        dtInfo: Info := nil;
      end;
    end;
 end;

procedure CE; begin ClearEvent(Event) end;

var AP, PP: PFilePanel;

begin
 RVisible := RightView^.GetState(sfVisible);
 LVisible := LeftView^.GetState(sfVisible);
 LSelected := LeftView^.GetState(sfSelected);
 Sp := Separator;
 case Event.What of
  evKeyDown: case Event.KeyCode of
              kbCtrlLeft,
              kbCtrlRight:
                     if FMSetup.Options and fmoCtrlDifference <> 0 then
                           begin
                             if LVisible and (Mem[$40:$18] and 1 <> 0) then
                                LeftView^.HandleEvent(Event) else
                                RightView^.HandleEvent(Event);
                             Exit;
                           end;

              kbAlt1, kbAlt2, kbAlt3, kbAlt4, kbAlt5,  kbAlt0,
              kbAlt6, kbAlt7, kbAlt8, kbAlt9:
                     if FMSetup.Options and fmoAltDifference <> 0 then
                          begin
                             if LVisible and (Mem[$40:$18] and 2 <> 0) then
                                LeftView^.HandleEvent(Event) else
                                RightView^.HandleEvent(Event);
                             Exit;
                          end;

              kbAltLeft: if RVisible and LVisible then begin
                          if Sp^.OldX > 0 then Dec(Sp^.OldX);
                          Sp^.OldW := Size.X;
                          R.A := Origin;
                          R.B.X := Origin.X + Size.X;
                          R.B.Y := Origin.Y + Size.Y;
                          ChangeBounds(R);
                          CE;
                         end;

             kbAltRight: if RVisible and LVisible then begin
                          Sp^.OldW := Size.X;
                          if Sp^.OldX < Sp^.OldW - 1 then Inc(Sp^.OldX);
                          R.A := Origin;
                          R.B.X := Origin.X + Size.X;
                          R.B.Y := Origin.Y + Size.Y;
                          ChangeBounds(R);
                          CE;
                         end;
                   $1A1B: begin
                            S := '';
                            Message(LeftView, evCommand, cmGetName, @S);
                            if S[Length(S)] <> '\' then AddStr(S, '\');
                            Message(CommandLine, evCommand, cmInsertName, @S);
                            CE;
                          end;
                   $1B1D: begin
                            S := '';
                            Message(RightView, evCommand, cmGetName, @S);
                            if S[Length(S)] <> '\' then AddStr(S, '\');
                            Message(CommandLine, evCommand, cmInsertName, @S);
                            CE;
                          end;
             end;
  evBroadcast: case Event.Command of
                cmLookForPanels: ClearEvent( Event );
                cmGetUserParams: begin
                                   AP := RPanel; PP := LPanel;
                                   if LSelected then begin PP := RPanel; AP := LPanel; end;
                                   with PUserParams(Event.InfoPtr)^ do
                                      begin
                                        AP^.GetUserParams(Active, ActiveList);
                                        PP^.GetUserParams(Passive, PassiveList);
                                      end;
                                   CE;
                                 end;
(*                cmDropped: begin
                            if LeftView^.MouseInView(PCopyRec(Event.InfoPtr)^.Where) then LeftView^.HandleEvent(Event) else
                             if RightView^.MouseInView(PCopyRec(Event.InfoPtr)^.Where) then RightView^.HandleEvent(Event);
{                            CE;}
                           end;
*)
               end;
  evCommand: case Event.Command of

              cmSwitchOther: begin CE; if LSelected then SwitchRight else SwitchLeft end;

              cmGetDirInfo: begin
                              if LSelected then
                                if (LType = dtPanel) then LeftView^.HandleEvent(Event)
                                                     else RightView^.HandleEvent(Event)
                               else
                                if (RType = dtPanel) then RightView^.HandleEvent(Event)
                                                     else LeftView^.HandleEvent(Event);

                              ClearEvent(Event);
                            end;
              cmZoom: begin
                       if LSelected and (LType = dtView) then SwitchRight else
                         if not LSelected and (RType = dtView) then SwitchLeft;
                      end;
              cmGetName: begin PString(Event.InfoPtr)^ := GetString(dlFileManager) + Cut(LPanel^.DirectoryName, 20) +
                                                          ',' + Cut(RPanel^.DirectoryName, 20); CE end;
              cmPostHideRight: begin
                                 if not RVisible then SwitchRight;
                                 RVisible := On;
                                 if LVisible then SwitchLeft;
                               end;
              cmPostHideLeft: begin
                                 if not LVisible then SwitchLeft;
                                 LVisible := On;
                                 if RVisible then SwitchRight;
                               end;
              cmChangeInactive: begin
                                   Event.Command := cmFindGotoFile;
                                   if LSelected then
                                    begin
                                      RPanel^.HandleEvent(Event);
                                      if RType <> dtPanel then SwitchView(RType);
                                    end else
                                    begin
                                      LPanel^.HandleEvent(Event);
                                      if LType <> dtPanel then SwitchView(LType);
                                    end;
                                   CE;
                                end;
              cmGetDirName: GetDirName;
              cmPanelCompare: begin
                               if LSelected then RPanel^.HandleEvent(Event)
                                            else LPanel^.HandleEvent(Event);
                              end;
              cmDiskInfo: begin
                            SwitchView(dtInfo); CE;
                            if LSelected then Message(LeftView, evCommand, cmLViewFile, nil)
                                         else Message(RightView, evCommand, cmLViewFile, nil);
                           end;
              cmLoadViewFile: begin
                               if (QView <> nil) and ((LType = dtView) or (RType = dtView))
                                 then QView^.HandleEvent(Event) else
                                  if (Info <> nil) and Info^.GetState(sfVisible) then
                                     Info^.HandleEvent(Event);
                               CE;
                              end;
              cmGLoadViewFile: CE;
              cmEnableView: begin
                             Message(LPanel, evCommand, cmEnableView, nil);
                             Message(RPanel, evCommand, cmEnableView, nil);
                            end;
              cmDisableView: begin
                              Message(LPanel, evCommand, cmDisableView, nil);
                              Message(RPanel, evCommand, cmDisableView, nil);
                             end;
              cmPushFullName,
              cmPushFirstName:begin LeftView^.HandleEvent(Event);
                                     RightView^.HandleEvent(Event);
                                     CE;
                                     Exit;
                               end;
              cmFindTree,
              cmRereadTree: if LTree <> nil then
                    LTree^.HandleEvent(Event);
              cmHideLeft: begin
                            if LVisible and not RVisible then
                              Message(Application, evCommand, cmShowOutput, nil)
                               else SwitchLeft; CE end;
              cmHideRight: begin
                            if RVisible and not LVisible then
                              Message(Application, evCommand, cmShowOutput, nil)
                               else SwitchRight; CE end;
              cmChangeLeft: begin ChangeDrvLeft; CE end;
              cmChangeRight: begin ChangeDrvRight; CE end;
              cmDirTree: begin SwitchView(dtTree); CE end;
              cmQuickView: begin SwitchView(dtView);
                               if LSelected then Message(LeftView, evCommand, cmLViewFile, nil)
                                            else Message(RightView, evCommand, cmLViewFile, nil);
                               CE end;
              cmSwapPanels: begin
                             Lock;
                             if not RVisible then
                              Message(@Self, evCommand, cmHideRight, nil) else
                             if not LVisible then
                              Message(@Self, evCommand, cmHideLeft, nil);
                             LeftView^.GetBounds(R1);
                             R1.B.Y := Size.Y - 1;
                             RightView^.GetBounds(R2);
                             R2.B.Y := Size.Y - 1;
                             Lock;
                             I := LType; LType := RType; RType := I;
                             if (LType = dtPanel) or (RType = dtPanel) then
                              begin
                               P := LPanel; LPanel := RPanel;
                               RPanel := PFilePanel(P);
                              end;
                             LeftView^.ChangeBounds(R2);
                             RightView^.ChangeBounds(R1);
                             P := LeftView; LeftView := RightView;
                             RightView := PHideView(P);
                             ReDraw;
                             UnLock;
                             if not LVisible then
                              Message(@Self, evCommand, cmHideRight, nil) else
                             if not RVisible then
                              Message(@Self, evCommand, cmHideLeft, nil);
                            UnLock;
                            CE
                           end;
             end;
 end;
 inherited HandleEvent(Event);
end;

end.