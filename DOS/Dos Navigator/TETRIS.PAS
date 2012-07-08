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

{$define dn}
{$ifdef dn}
unit Tetris;

interface
{$endif}

USES Objects, Drivers, Views, DNApp, Dialogs, Memory, Menus, Messages,
     Commands, Advance, RStrings, ObjType;

const
  Shi      = 12;
  Vis      = 19;
  F        = False;
  T        = True;

type
{$ifndef dn}
    TApp = object(TApplication)
     procedure Idle; virtual;
    end;
{$endif}
    PGameWindow = ^TGameWindow;
    TGameWindow = object(TDialog)
     constructor Init;
     procedure HandleEvent(var Event: TEvent); virtual;
    end;

    PGameView = ^TGameView;
    TGameView = object(TView)
     Info: PView;
     {Hi  : PView;}

     Glass: Array [-2..Vis+2,-1..Shi+2] of Byte;

     Delay: Word;
     CurFig: Integer;
     Fig,OldF  : Array [1..5,1..2] of Byte;

     Pos: TPoint;
     LastT: LongInt;
     ChPos: Boolean;
     HideFig, Stop: Boolean;
     Score, Lines: LongInt;
     NextFig: Byte;
     OldX, OldY, x, y : shortint;

     TMaxFig: Byte;

     Level, StartLevel: Integer;
     Preview: Boolean;
     Pentix: Boolean;
     HiScores: Array [1..20] of record Name: String[30]; StLv, EndLv: Byte; Score: LongInt; end;
     constructor Init(R: TRect);
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
     procedure NewGame;
     procedure Draw; virtual;
     procedure HandleEvent(var Event: TEvent); virtual;
     procedure Rotate;
     procedure ReadFig;
     procedure Update; virtual;
     function  MoveFig(DeltaX, DeltaY: Integer): Boolean;
     function  ValidMove(DeltaX, DeltaY: Integer): Boolean;
     function  MoveDown: Boolean;
     procedure MakeTime;
     procedure ShowScores(HighLight: Integer);
     procedure SetState(AState: Word; Enable: Boolean); virtual;
     destructor Done; virtual;
    end;

    PGameInfo = ^TGameInfo;
    TGameInfo = object(TView)
     Hc,Gm: PGameView;
     function GetPalette: PPalette; virtual;
     procedure Draw; virtual;
     constructor Load(var S: TStream);
     procedure Store(var S: TStream);
    end;

const Game : PGameView = nil;

      RGameWindow: TStreamRec = (
       ObjType: otGameWindow;
       VmtLink: Ofs(TypeOf(TGameWindow)^);
       Load: @TGameWindow.Load;
       Store: @TGameWindow.Store);

      RGameView: TStreamRec = (
       ObjType: otGameView;
       VmtLink: Ofs(TypeOf(TGameView)^);
       Load: @TGameView.Load;
       Store: @TGameView.Store);

      RGameInfo: TStreamRec = (
       ObjType: otGameInfo;
       VmtLink: Ofs(TypeOf(TGameInfo)^);
       Load: @TGameInfo.Load;
       Store: @TGameInfo.Store);

{$ifdef dn}
implementation
uses xTime,StartUp, DNHelp;
{$endif}
const
  sAnonymous = 'Anonymous';

  MaxFig   = 27;
  Figures  : array[1..5*MaxFig,1..2] of byte=
      ((1,3),(2,3),(3,3),(3,2),(0,0),  {0}{Ù}
       (1,2),(2,2),(3,2),(3,3),(0,0),     {À}
       (1,2),(2,2),(3,2),(4,2),(0,0),     {³}
       (2,2),(2,3),(3,2),(3,3),(0,0),     {þ}
       (1,2),(2,2),(2,3),(3,2),(0,0),     {Ã}
       (1,2),(2,2),(2,3),(3,3),(0,0),  {5}{~}
       (1,3),(2,3),(2,2),(3,2),(0,0),{-4-}{~}
       (1,1),(0,0),(0,0),(0,0),(0,0),{-1-}{ù}
       (1,1),(2,1),(0,0),(0,0),(0,0),{-2-}{³}
       (1,2),(2,2),(3,2),(0,0),(0,0),     {³}
       (1,1),(2,1),(2,2),(0,0),(0,0),{-3-} {10}{À}
       (1,3),(2,3),(3,3),(4,3),(5,3),          {³}
       (1,2),(2,1),(2,2),(2,3),(3,2),          {Å}
       (2,2),(2,3),(3,2),(3,3),(3,4),          {Ü_}
       (2,2),(2,3),(3,1),(3,2),(3,3),          {_Ü}
       (1,1),(1,3),(2,1),(2,2),(2,3), {15}     {ÚÄ¿}
       (1,1),(2,1),(2,2),(3,2),(3,3),          {\}
       (1,2),(2,2),(3,2),(3,3),(4,3),          {~}
       (1,3),(2,3),(3,2),(3,3),(4,2),          {~}
       (1,1),(1,2),(2,2),(3,2),(3,3),          {Z}
       (1,2),(1,3),(2,2),(3,1),(3,2), {20}     {Z}
       (1,1),(2,1),(2,2),(2,3),(3,2),          {n}
       (1,3),(2,1),(2,2),(2,3),(3,2),          {n}
       (1,1),(1,2),(1,3),(2,2),(3,2),          {T}
       (1,2),(2,2),(2,3),(3,2),(4,2),          {|~}
       (1,3),(2,2),(2,3),(3,3),(4,3),          {~|}
       (1,1),(2,1),(3,1),(3,2),(3,3)           {L}
       );
  ColPo    : array[0..MaxFig-1] of byte=
      (4,4,4,4,4,4,4,1,2,3, 3,5,5,5,5, 5,5,5,5,5, 5,5,5,5,5,5,5);
      {0         5         10         15         20}
  CRot     : array[0..MaxFig-1] of byte=
      (4,4,4,4,3,4,4,1,2,3, 2,5,3,4,4, 3,3,4,4,3, 3,3,3,3,4,4,3);

function LevelDelay(Level: Byte): Word;
 var Delay: Word;
begin
 case Level of
  1: Delay := 80;
  2: Delay := 60;
  3: Delay := 50;
  4: Delay := 30;
  5: Delay := 25;
  6: Delay := 20;
  7: Delay := 15;
  8: Delay := 10;
  9: Delay := 5;
 10: Delay := 4;
 end;
 LevelDelay := Delay
end;

constructor TGameWindow.Init;
 var R: TRect;
     Gm: PGameView;
     Hi,Info: PGameInfo;
begin
 R.Assign(1, 1, 30+shi*2, 4+Vis);
 Inherited Init(R, GetString(dlGameTitle));
 HelpCtx := hcTetris + Byte( TetrisRec.S = 1 );
 Options := Options or ofCentered;
 R.Assign(2,2,2+Shi*2,2+Vis);
 Gm := New(PGameView, Init(R));
 Insert(Gm);
 R.Assign(4+Shi*2,1,27+Shi*2,16);
 Info := New(PGameInfo, Init(R));
 Insert(Info);
 {R.Assign(6+Shi*2,13,25+Shi*2,16);
 Hi := New(PGameInfo, Init(R));
 Insert(Hi);}
 {Info^.Options := Info^.Options or ofFramed;}
 Info^.Gm := Gm; Gm^.Info := Info; {Gm^.Hi := Hi;}
 R.Assign(4+Shi*2, 17, 15+Shi*2, 19);
 Insert(New(PButton, Init(R, GetString(dlNewButton), cmNewGame, 0)));
 R.Assign(15+Shi*2, 17, 26+Shi*2, 19);
 Insert(New(PButton, Init(R, GetString(dlSetupButton), cmSetup, 0)));
 R.Assign(4+Shi*2, 19, 15+Shi*2, 21);
 Insert(New(PButton, Init(R, GetString(dlTop10Button), cmShowHi, 0)));
 R.Assign(15+Shi*2, 19, 26+Shi*2, 21);
 Insert(New(PButton, Init(R, GetString(dlPauseButton), cmStop, 0)));
 SelectNext(False);
end;

constructor TGameInfo.Load(var S: TStream);
begin
 inherited Load(S);
 GetPeerViewPtr(S, Gm);
end;

procedure TGameInfo.Store(var S: TStream);
begin
 inherited Store(S);
 PutPeerViewPtr(S, Gm);
end;

function TGameInfo.GetPalette;
  const S: String[2] = #7#8;
begin
  GetPalette := @S;
end;

procedure TGameInfo.Draw;
var B: TDrawBuffer;
    S: String;
    C, I, J, K: Word;
begin
 C := GetColor($0201);
 MoveChar(B, 'Ä', C, Size.X);
 S := GetString(dlGameInfo);
 MoveCStr(B[(Size.X - CStrLen(S)) div 2], S, C);
 MoveChar(B, 'Ú', C, 1);
 MoveChar(B[Size.X-1], '¿', C, 1);
 WriteLine(0,0,Size.X,1,B);

 MoveChar(B, ' ', C, Size.X);
 MoveCStr(B, GetString(dlGameScore2) + ItoS(Gm^.Score) + '~', C);
 MoveChar(B[Size.X-1], '³', C, 1);
 WriteLine(0,1,Size.X,1,B);
 MoveChar(B, ' ', C, Size.X);
 MoveCStr(B, GetString(dlGameLines) + ItoS(Gm^.Lines) + '~' , C);
 MoveChar(B[Size.X-1], '³', C, 1);
 WriteLine(0,2,Size.X,1,B);
 MoveChar(B, ' ', C, Size.X);
 MoveCStr(B, GetString(dlGameLevel) + ItoS(Gm^.Level) + '~', C);
 MoveChar(B[Size.X-1], '³', C, 1);
 WriteLine(0,3,Size.X,1,B);
{ MoveChar(B, 'Ä', C, Size.X);
 MoveChar(B, 'À', C, 1);
 MoveChar(B[Size.X-1], 'Ù', C, 1);
 WriteLine(0,4,Size.X,1,B);}

 MoveChar(B, 'Ä', C, Size.X);
 S := GetString(dlTetrisNext);
 MoveCStr(B[(Size.X - CStrLen(S)) div 2], S, C);
 MoveChar(B, 'Ã', C, 1);
 MoveChar(B[Size.X-1], '´', C, 1);
 WriteLine(0,4,Size.X,1,B);
 K := ((15-Gm^.NextFig mod 7) shl 8) + 219;
 For I := 5 to 10 do
  begin
   MoveChar(B, ' ', 07, Size.X);
   if not Gm^.Stop and Gm^.Preview then
    begin
     for J := 1 to ColPo[Gm^.NextFig] do
      if Figures[Gm^.NextFig*5+j,1]=I-4 then
        begin B[Figures[Gm^.NextFig*5+j,2]*2+3] := K; B[Figures[Gm^.NextFig*5+j,2]*2+4] := K; end;
    end;
   MoveChar(B, '³', C, 1);
   MoveChar(B[Size.X-1], '³', C, 1);
   WriteLine(0,I,Size.X,1,B);
  end;
 MoveChar(B, 'Ä', C, Size.X);
 MoveChar(B, 'À', C, 1);
 MoveChar(B[Size.X-1], 'Ù', C, 1);
 WriteLine(0,10,Size.X,1,B);

 C :=Owner^.GetColor($1112);
 MoveChar(B, 'Ä', C, Size.X);
 S := GetString(dlTetrisBest);
 MoveCStr(B[(Size.X - CStrLen(S)) div 2], S, C);
 MoveChar(B, 'Ú', C, 1);
 MoveChar(B[Size.X-1], '¿', C, 1);
 WriteLine(0,11,Size.X,1,B);
 MoveChar(B, ' ', C, Size.X);
 MoveCStr(B, GetString(dlTetName)+ Gm^.HiScores[1+10*byte(Gm^.Pentix)].Name, C);
 MoveChar(B[Size.X-1], '³', C, 1);
 WriteLine(0,12,Size.X,1,B);
 MoveChar(B, ' ', C, Size.X);
 MoveCStr(B,+GetString(dlGameScore) + ItoS(Gm^.HiScores[1+10*byte(Gm^.Pentix)].Score), C);
 MoveChar(B[Size.X-1], '³', C, 1);
 WriteLine(0,13,Size.X,1,B);
 MoveChar(B, 'Ä', C, Size.X);
 MoveChar(B, 'À', C, 1);
 MoveChar(B[Size.X-1], 'Ù', C, 1);
 WriteLine(0,14,Size.X,1,B);
end;

Constructor TGameView.Init;
 var I, J: Integer;
     S: TDOSStream;
     C: Word;
     B: Array[0..512] of Word;
begin
 Randomize;
 inherited Init(R);
 Options := Options or ofFramed or ofSelectable or ofPreProcess;
 EventMask := $FFFF;
 Game := @Self; Delay := 30;
 StartLevel := TetrisRec.L + 1;
 Level := StartLevel;
 Pentix := TetrisRec.S = 1;
 Preview := TetrisRec.P and 1 <> 0;
 for I := 1 to 20 do
  begin
   HiScores[I].Name := sAnonymous; HiScores[I].Score := 0;
   HiScores[I].StLv := 1;
   HiScores[I].EndLv := 1;
  end;
 S.Init(SourceDir+'dn.tet', stOpenRead);
 if S.Status = stOK then S.Read(B, sizeof(HiScores));
 S.Done;
 I := SizeOf(HiScores);
 asm
   lea bx, B
   mov cx, I
 @@1:
   mov dl, cl
   xor dl, $AA
   xor ss:[bx], dl
   inc bx
   loop @@1
 end;
 Move(B, HiScores, SizeOf(HiScores));
 for I := 1 to 20 do
 if not (HiScores[I].StLv in [1..10]) then
  begin
   for I := 1 to 20 do
   begin
    HiScores[I].Name := sAnonymous; HiScores[I].Score := 0;
    HiScores[I].StLv := 1;
    HiScores[I].EndLv := 1;
   end;
   S.Init(SourceDir+'dn.tet', stCreate);
   S.Write(HiScores, sizeof(HiScores));
   S.Done;
   Break;
  end;
 NewGame;
 RegisterToBackground(@Self);
end;

FUNCTION CLen(s:string):byte;
var i,l: byte;
begin
  l:=0;
  for i:=1 to length(s) do if s[i]<>'~' then inc(l);
  CLen:=l
end;

procedure TGameView.ShowScores;
var
  D: PDialog;
  R: TRect;
  P: PView;
  S: String;
  I: Byte;
  PP: Boolean;
begin
  D := PDialog( LoadResource( TDlgIdx( Byte( dlgTetrisTop10 ) + Byte( Pentix ))));
  R.Assign( 2, 4, D^.Size.X - 2, 14 );
  P := New( PView, Init( R ));
  P^.Options := P^.Options or ofFramed;
  D^.Insert( P );
  for I := 1 to 10 do with HiScores[ I + 10 * Byte( Pentix ) ] do begin
    If Score > 0 then begin
      S := Name;
      if I = HighLight then S := '~' + S + '~';
      S := S + Strg('.', 30 - CLen( S ));
      S := S + ' ' + SStr( StLv, 5, '.' ) + ' ' +
                     SStr( EndLv, 5, '.' ) + ' ' +
                     SStr( Score, 10, '.' );
    end else
      S := '';
    R.Assign( 2, 3 + I, D^.Size.X - 2, 4 + I );
    D^.Insert( New( PLabel, Init( R, S, nil)));
  end;
  PP := Stop;
  Stop := On;
  DeskTop^.ExecView(D);
  Stop := PP;
  Dispose(D, Done);
end;

constructor TGameView.Load(var S: TStream);
begin
 inherited Load(S);
 GetPeerViewPtr(S, Info);
 S.Read(Glass, SizeOf(Self) - SizeOf(TView) - SizeOf(PView));
 Game := @Self;
end;

procedure TGameView.Store(var S: TStream);
begin
 inherited Store(S);
 PutPeerViewPtr(S, Info);
 S.Write(Glass, SizeOf(Self) - SizeOf(TView) - SizeOf(PView));
end;

destructor TGameView.Done;
begin
 Game := nil;
 inherited Done;
end;

procedure TGameView.NewGame;
 var I, J: Integer;
begin
 TmaxFig:=7;

 if Pentix then TMaxFig:=MaxFig;

 for I := 0 to Vis+2 do
  for J := -1 to Shi+2 do
   Glass[I, J] := Byte((J < 1) or (J > Shi) or (i>Vis-1) or (i<0));

 CurFig := Random(TMaxFig);
 Readfig;
 X:=Shi shr 1 - 2;
 Y:=0;
 NextFig := Random(TMaxFig);
 Score := 0; Lines := 0;
 Delay := LevelDelay(StartLevel);
 Level := StartLevel;

 if Info <> nil then Info^.DrawView;

end;

function TGameView.ValidMove;
 var I: Integer;
begin
 ValidMove := False;
 for i:=1 to ColPo[CurFig] do
   if Glass[fig[i,1]+y+DeltaY,fig[i,2]+x+DeltaX+1]<>0 then Exit;
 ValidMove := True;
end;

procedure TGameView.SetState;
begin
  inherited SetState(AState, Enable);
  if not Enable and (AState and (sfActive + sfFocused) <> 0) and
     (Owner^.State and sfActive <> 0) and not Stop and
     ValidMove(0,0) then Stop := On;
end;

function TGameView.MoveFig;
 label 1;
 var I, J: Integer;
begin
 MoveFig := False; if not ValidMove(DeltaX, DeltaY) then Exit;
 MoveFig := True;
 ChPos := True; HideFig := True; Draw;
 Inc(X, DeltaX); Inc(Y, DeltaY); ChPos := True; Draw;
1:
end;

function TGameView.MoveDown;
 var I, J, K, L, W, BW: Integer;
     B, BB, BBW: Boolean;

 procedure CheckHiScores;
  var I, J: Integer;
      S: TDOSStream;
      Nm: String;
      B: Array[0..1024] of Byte;
  label 1;
 begin
  for I := 1 to 10 do if HiScores[I+10*Byte(Pentix)].Score < Score then Goto 1;
  Exit;
  1: for J := 10 downto I+1 do HiScores[J+10*Byte(Pentix)] := HiScores[J-1+10*Byte(Pentix)];
  Nm := sAnonymous;
  ExecResource( dlgTetrisWinner, Nm );

  HiScores[I+10*Byte(Pentix)].Name := Nm;
  HiScores[I+10*Byte(Pentix)].StLv := StartLevel;
  HiScores[I+10*Byte(Pentix)].EndLv := Level;
  HiScores[I+10*Byte(Pentix)].Score := Score;
  S.Init(SourceDir+'dn.tet',stCreate);
  Move(HiScores, B, SizeOf(HiScores));
  J := SizeOf(HiScores);
  asm
    lea bx, B
    mov cx, J
  @@1:
    mov dl, cl
    xor dl, $AA
    xor ss:[bx], dl
    inc bx
    loop @@1
  end;
  S.Write(B, SizeOf(HiScores));
  S.Done;
  ShowScores(I);
 end;

begin
 if Stop then Exit;
 if MoveFig(0, 1) then moveDown := True
  else
  begin
   for I := 1 to ColPo[CurFig] do
     Glass[Fig[I,1]+y,Fig[I,2]+x+1] := 15 - CurFig mod 7;
   Inc(Score, ((Size.Y - Y)*2+Level*6)*(10 - 3*Byte(Preview)) div 10); BB := False; W:=0;
   BW := 0;
   for I := 0 to Vis-1 do
    begin
     B := True; BBW := True;
     for J := 1 to Shi do
      begin
       B := B and (Glass[I,J] <> 0);
       BBW := BBW and (Glass[I,J] = 0);
      end;
     Inc(BW, Byte(BBW));
     if B then
      begin
       for K := I Downto 1 do
        for J := 1 to Shi do begin Glass[K, J] := Glass[K - 1, J]; Glass[K - 1, J] := 0; end;
       Inc(Score, (W+Size.Y - I)*30); Inc(Lines); Inc(W);
       BB := True;
      end;
    end;
   if BW = Vis then Inc(Score, (Level * 300 * (10 - 3*Byte(Preview))) div 10);
   CurFig := NextFig;ReadFig;
   NextFig := Random(TMaxFig); X := Shi shr 1-2; Y := -Fig[1,1];
   if Lines > 90-(9-StartLevel)*10 then
    begin
     Level := 1 + (Lines - (90-(9-StartLevel)*10)) div 20 + StartLevel;
     if Level > 10 then Level := 10;
     if Level < StartLevel then Level := StartLevel;
     Delay := LevelDelay(Level);
    end;
   Info^.DrawView;
   Stop := not ValidMove(0,0);
   if BB then xTime.DelayTics(2) else xTime.DelayTics(1);
   if Stop then
    begin
      for I := 1 to ColPo[CurFig] do
       Glass[Fig[I,1]+y,Fig[I,2]+x+1] := 15 - CurFig mod 7;
      Draw;
      MessageBox(GetString(dlGameOver), @Score, mfInformation+mfOKButton);
      CheckHiScores;
      Info^.Draw;
    end;
   DrawView; MoveDown := False; MakeTime;
  end

end;

procedure TGameView.Draw;
 var B: Array [0..230] of Word;
     I, J, K: Integer;
begin
 if not ChPos then
   for I := 0 to Vis do
    begin
     MoveChar(B, ' ', $0, Shi*2);
     for J := 1 to Shi do
      begin K := (J-1)*2; B[K] := (Glass[I, J] shl 8) + 219; B[K+1] := B[K]; end;
     WriteLine(0,I,Shi*2,1,B);
    end;

 if not Stop then
  begin
   K := (((15-CurFig mod 7) shl 8) + 219)*Byte(not HideFig);
   B[0] := K; B[1] := K;
   for I := 1 to ColPo[CurFig] do
     WriteBuf((X+Fig[i,2])*2, Y+Fig[i,1], 2, 1, B);

  end;
 ChPos := False; HideFig := False;
end;

procedure TGameView.MakeTime;
 var A, B, C: Byte;
begin
 if Stop then Exit;
 asm
  mov ah, 2Ch
  int 21h
  mov A, DH
  mov B, DL
  mov C, CL
 end;
 LastT := LongInt (A + LongInt(C)*60) * 100 + B;
end;

procedure TGameView.Update;
 var A, B, C: Byte;
begin
 if Stop then Exit;
 asm
  mov ah, 2Ch
  int 21h
  mov A, DH
  mov B, DL
  mov C, CL
 end;
 if LongInt(LongInt(C)*60 + Word(A))*100 + B > LastT + Delay then
  begin MoveDown; MakeTime end;
end;

procedure TGameView.HandleEvent;
 procedure CE; begin ClearEvent(Event) end;

 procedure Setup;
 begin
  Stop := On;
  TetrisRec.L := Level - 1; TetrisRec.S := Byte(Pentix); TetrisRec.P := Byte(Preview);
  if ExecResource(dlgGameSetup, TetrisRec) <> cmOK then Exit;
  StartLevel := TetrisRec.L + 1;
  Pentix := TetrisRec.S = 1;
  Preview := TetrisRec.P and 1 <> 0;
  HelpCtx := hcTetris + Byte( Pentix );
  NewGame;
  Owner^.Redraw;
  Message(Application, evCommand, cmUpdateConfig, nil);
 end;

 var O: Integer;
begin
 inherited HandleEvent(Event);
 case Event.What of
  evCommand: case Event.Command of
              cmGetName: PString(Event.InfoPtr)^ := GetString(dlGameTitle);
              cmStop: begin if ValidMove(0,0) then Stop := not Stop; CE end;
              cmNewGame: begin NewGame; Stop := False; DrawView; CE end;
              cmSetup: begin Setup; CE end;
              cmShowHi: begin ShowScores(0); CE end;
              cmTetrisIncLevel: begin if Level < 10 then Inc(Level);
                                  Delay := LevelDelay(Level);
                                  Owner^.Redraw; CE
                                end;
              cmTetrisPreview: begin Preview := not Preview; Owner^.Redraw; CE end;
             end;
  evKeyDown: case Event.KeyCode of
               kbESC: begin Message(Owner, evCommand, cmClose, nil); CE end;
               else
                if not Stop then
                case Event.KeyCode and $FF00 of
                  kbLeft, kbHome: begin MoveFig(-1, 0); CE end;
                  kbRight, kbPgUp: begin MoveFig(1, 0); CE end;
                  kbDown, $3900
                  : begin
                     if not Stop then while ValidMove(0,1) do MoveDown;
                     MakeTime; CE;
                    end;
                  kbUp: begin
                         OldF:=Fig; Rotate;
                         if ValidMove(0,0) then
                          begin
                           Fig:=OldF; ChPos := True; HideFig := True; Draw;
                           Rotate; MoveFig(0,0)
                          end else Fig:=OldF;
                         CE;
                        end;
                  else if (Event.CharCode > #0) and (CommandLine <> nil) then CommandLine^.HandleEvent(Event);
               end else if (Event.CharCode > #0) and (CommandLine <> nil) then CommandLine^.HandleEvent(Event);
             end;
 end;
end;

procedure TGameView.Rotate;
Var i:Integer;
begin
 for i:=1 to ColPo[CurFig] do
  begin
   fig[i,2]:=oldf[i,1];
   fig[i,1]:=CRot[CurFig]+1-oldf[i,2];
  end;
end;

procedure TGameView.ReadFig;
var I: Integer;
begin
 for i:=1 to ColPo[CurFig] do
  begin
   Fig[i,1]:=Figures[CurFig*5+i,1];
   Fig[i,2]:=Figures[CurFig*5+i,2];
  end;
end;

procedure TGameWindow.HandleEvent;
begin
 if (Event.What = evKeyDown) and (Event.CharCode = ' ') then
  Event.KeyCode := kbDown;
 inherited HandleEvent(Event);
end;

end.