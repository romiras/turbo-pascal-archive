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

unit HideView;

interface
uses Menus, Objects, Views, Drivers;

type  PHideView = ^THideView;
      THideView = object(TView)
       OldSizeX: Integer;
       procedure HideView; virtual;
       procedure ShowView; virtual;
      end;

      PStdWindow = ^TStdWindow;
      TStdWindow = object(TWindow)
       constructor Init(var R: TRect; ATitle: TTitleStr; ANumber: Integer);
       procedure HandleEvent(var Event: TEvent); virtual;
       procedure ExecWindowMenu; virtual;
       function  GetWindowMenu(var N, W: Word): PMenu; virtual;
      end;

implementation
uses DNApp, Dialogs, Advance, Commands;

constructor TStdWindow.Init;
begin
 inherited Init(R, ATitle, ANumber);
 {Flags := Flags or wfMenu;}
end;

procedure TStdWindow.HandleEvent;
begin
 inherited HandleEvent(Event);
{ if (Event.What = evCommand) and (Event.Command = cmWindowMenu) then
  begin ExecWindowMenu; ClearEvent(Event) end;
 if (Event.What = evKeyDown) and (Event.KeyCode = kbAltSpace)
     then begin Message(@Self, evCommand, cmWindowMenu, nil); ClearEvent(Event) end;
 }
end;

function TStdWindow.GetWindowMenu;
begin
 GetWindowMenu := NewMenu(
                    NewItem('~S~ize/move'     ,'',kbNoKey,cmResize,hcResize,
                    NewItem('~Z~oom'          ,'',kbNoKey,cmZoom,hcZoom,
                    NewItem('~N~ext'          ,'',kbNoKey,cmNext,hcNext,
                    NewItem('~P~revious'      ,'',kbNoKey,cmPrev,hcPrev,
                    NewItem('~C~lose'         ,'',kbNoKey,cmClose,hcClose,
                     nil))))));
 N := 5; W := 15;
end;

procedure TStdWindow.ExecWindowMenu;
 var Menu: PMenu;
     N, W: Word;
     R: TRect;
     P: PView;
begin
 Menu := GetWindowMenu(N, W);
 DeskTop^.GetExtent(R);
 R.A := Origin;
 if R.A.X < 0 then R.A.X := 0 else if R.A.X + W > R.B.X then R.A.X := R.B.X - W;
 if R.A.Y < 0 then R.A.Y := 0 else if R.A.Y + N + 2 > R.B.Y then R.A.Y := R.B.Y - N - 2;
 R.B.X := R.A.X + W; R.B.Y := R.A.Y + N + 2;
 P := New(PMenuBox, Init(R, Menu, nil));
 N := DeskTop^.ExecView(P);
 Dispose(P, Done);
 DisposeMenu(Menu);
 if N <> cmCancel then Message(@Self, evCommand, N, nil);
end;

procedure THideView.HideView;
begin
 OldSizeX := Size.X; GrowTo(0, Size.Y);
 EventMask := 0;
 TView.Hide;
end;

procedure THideView.ShowView;
begin
 EventMask := $FFFF;
 TView.Show;
end;

end.

