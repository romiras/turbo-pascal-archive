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

unit Reanimator;

interface

uses DNApp, Dialogs, Objects, Views, Drivers, DiskTool, Dos, Advance, Memory,
     FViewer, Commands, FilesCol, Drives, RStrings, Messages, DNHelp, DNStdDlg,Tree;

type
     PReaData = ^TReaData;
     TReaData = record
      Name: String[12];
      Attr: Byte;
      Size: LongInt;
      Day, Month, Year,
      Hour, Min: Byte;
      Cluster: Word;
      State: Byte;
      Dir, DirEntry: Word;
      ValidChars: Set of Char;
     end;

     PReaCollection = ^TReaCollection;
     TReaCollection = object(TSortedCollection)
      procedure FreeItem(Item: Pointer); virtual;
      function Compare(P1, P2: Pointer): Integer; virtual;
     end;

     PReanimateTreeInfoView = ^TReanimateTreeInfoView;
     TReanimateTreeInfoView = object(TDTreeInfoView)
      CurDir, OldDir: PathStr;
      FirstCall: Boolean;
      constructor Init(R: TRect);
      destructor Done; virtual;
      procedure Draw; virtual;
      end;

     PReanimator = ^TReanimator;
     TReanimator = object(TSortedListBox)
      Drv: PDiskDriver;
      isValid: Boolean;
      DirCluster, FreeClusters: Word;
      constructor Init(R: TRect; SB: PScrollBar);
      destructor Done; virtual;
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure GetDirData;
      function Valid(Command: Word): Boolean; virtual;
      function GetText(Item: Integer; MaxLen: Integer): String; virtual;
      function GetKey(var S: String): Pointer; virtual;
     end;

     PIView = ^TIView;
     TIView = object(TView)
      C: Char;
      constructor Init(R: TRect);
      procedure Draw; virtual;
     end;

     PWordCollection = ^TWordCollection;
     TWordCollection = object(TObject)
      MaxSize: Word;
      Data: Array[0..3] of PWordArray;
      constructor Init(AMaxSize: Word);
      procedure SetData(N, NewData: Word);
      function GetData(N: Word): Word;
      destructor Done; virtual;
     end;

     PClusterStream = ^TClusterStream;
     TClusterStream = object(TStream)
      Clusters: PWordCollection;
      Drv: PDiskDriver;
      FileSize, FilePos: LongInt;
      BlockSize: Word;
      constructor Init(AClusters: PWordCollection; ADrv: PDiskDriver; ASize: LongInt);
      destructor Done; virtual;
      function GetPos: Longint; virtual;
      function GetSize: Longint; virtual;
      procedure Read(var Buf; Count: Word); virtual;
      procedure Seek(Pos: Longint); virtual;
     end;

procedure OpenReanimator;

implementation
var InfoPane : PReanimateTreeInfoView;

const
     RereadDrives: Set of Char = [];

constructor TClusterStream.Init(AClusters: PWordCollection; ADrv: PDiskDriver; ASize: LongInt);
begin
 inherited Init;
 Clusters := AClusters;
 Drv := ADrv;
 BlockSize := Drv^.ClusterSize(2);
 FileSize := ASize;
 FilePos := 0;
end;

destructor TClusterStream.Done;
begin
{ if Clusters <> nil then Dispose(Clusters, Done);
 if Drv <> nil then Dispose(Drv, Done);}
 Inherited Done;
end;

function TClusterStream.GetPos: Longint;
begin
 GetPos := FilePos;
end;

function TClusterStream.GetSize: Longint;
begin
 GetSize := FileSize
end;

procedure TClusterStream.Read(var Buf; Count: Word);
 var Cl, Pos, M, T: Word;
     L: LongInt;
     Buffer: Pointer;
begin
 if Count = 0 then Exit;
 Pos := 0; L := Count; T := BlockSize;
 Cl := LongInt(FilePos) div LongInt(BlockSize);
 M :=  LongInt(FilePos) mod LongInt(BlockSize);
 Buffer := MemAlloc(BlockSize);
 if Buffer = nil then Exit;
 repeat
  if L < BlockSize then T := L;
  Drv^.ClusterRead(Buffer^, Clusters^.GetData(Cl));
  Move(Buffer^, TByteArray(Buf)[Pos], T - M);
  Inc(Cl);
  Inc(Pos, T - M);
  Dec(L, T - M);
  M := 0;
 until L <= 0;
 FreeMem(Buffer, BlockSize);
 Inc(FilePos, Count);
end;

procedure TClusterStream.Seek(Pos: Longint);
begin
 FilePos := Pos;
end;

constructor TWordCollection.Init;
 var I: Integer;
begin
 inherited Init;
 MaxSize := AMaxSize;
 for I := 0 to MaxSize div 16384 do
  begin
   Data[I] := MemAlloc(((MaxSize-I*16384+1) mod 16384)*2);
   if Data[I] = nil then
    begin
     for I := I-1 downto 0 do FreeMem(Data[I], ((MaxSize-I*16384+1) mod 16384)*2);
     Fail;
    end;
   FillChar(Data[I]^, ((MaxSize-I*16384+1) mod 16384)*2, 0);
  end;
end;

destructor TWordCollection.Done;
 var I: Integer;
begin
 for I := 0 to MaxSize div 16384 do
   if Data[I] <> nil then FreeMem(Data[I],(((MaxSize-I*16384+1) mod 16384)*2));
 inherited Done;
end;

procedure TWordCollection.SetData;
begin
 Data[N div 16384]^[N mod 16384] := NewData;
end;

function TWordCollection.GetData;
begin
 GetData := Data[N div 16384]^[N mod 16384];
end;

constructor TIView.Init;
begin
 inherited Init(R);
 C := ' ';
 Options := Options or ofSelectable;
end;

procedure TIView.Draw;
 var B: TDrawBuffer;
begin
 MoveChar(B, C, $07*Byte(C=' ')+Owner^.GetColor(6)*Byte(C<>' '), Size.X);
 WriteLine(0,0,Size.X,Size.Y,B);
 SetCursor(0,0);
 if C = ' ' then ShowCursor else HideCursor;
end;

procedure TReaCollection.FreeItem;
begin
 if Item <> nil then Dispose(PReaData(Item));
end;

function TReaCollection.Compare;
 var T1, T2: PReaData;
begin
 T1 := P1; T2 := P2;
 if (T1^.State <> T2^.State) and ((T1^.State < 2) or (T2^.State < 2)) then
   Compare := 1 - 2*Byte(T1^.State < T2^.State) else
 if T1^.Name[1] = '.' then Compare := -1
  else if T2^.Name[1] = '.' then Compare := 1
   else Compare := 1 - 2*Byte(T1^.Name < T2^.Name);
end;

constructor TReanimateTreeInfoView.Init;
begin
 Inherited Init(R, nil);
 GetDir(0, CurDir);
 FirstCall:= On;
 OldDir:=CurDir;
end;

destructor TReanimateTreeInfoView.Done;
begin
 Inherited Done;
 ChDir(OldDir);
end;

procedure TReanimateTreeInfoView.Draw;
 var B: TDrawBuffer;
     C: Byte;
begin
 C := GetColor(1);
 MoveChar(B, ' ', C, Size.X);
 MoveStr(B[1], Cut(CurDir,Size.X), C);
 WriteLine(0, 0, Size.X, 1, B);
end;


constructor TReanimator.Init;
 var CurDir: String;
begin
 inherited Init(R, 1, SB);
 EventMask := $FFFF;
 Options := Options or ofPostProcess;
 isValid := False;
 Abort := False;
 GetDir(0, CurDir);
 if Abort then Exit;
 New(Drv, Init(Byte(CurDir[1])-64, True));
 if (Drv = nil) or Abort then Exit;
 DirCluster := Drv^.GetPath(CurDir);
 if not Abort then GetDirData;
end;

function TReanimator.Valid;
begin
 Valid := IsValid and inherited Valid(Command);
end;

function TReanimator.GetKey(var S: String): Pointer;
const
  SR: TReaData = ();
begin
 if S[1]='?' then GetKey := @S else
 begin
  SR.Attr := 0;
  SR.Name := S;
  UpStr(SR.Name);
  GetKey := @SR;
 end;
end;



procedure TReanimator.HandleEvent;
 var P: PReaData;
     I, OldClu: Word;

 function GetCol: PWordCollection;
  var ClC: PWordCollection;
      Cl, I: Word;
 begin
  New(ClC, Init(LongInt(P^.Size) div LongInt(Drv^.ClusterSize(2))));
  Cl := P^.Cluster;
  for I := 0 to LongInt(P^.Size) div LongInt(Drv^.ClusterSize(2)) do
   begin
    ClC^.SetData(I, Cl);
    repeat
     if Cl < Drv^.TotalClu + 2 then Inc(Cl) else Cl := 0;
    until (Drv^.GetFAT(Cl) = 0)
   end;
  GetCol := ClC;
 end;

 procedure ReanimateFile;
  var W: PWindow;
      PV: PView;
      R: TRect;
      C: Char;
      S,S2: String;
      S1: String[12];
      Dir: ^DirPtr;
      Cl: PWordCollection;
      I: Word;
      OldPos: Word;
      PP: Array[1..2] of Pointer;
 begin
  OldPos := Focused;
  R.Assign(1,1,40,14);
  New(W, Init(R, GetString(dlReanimateTitle), 0));
  W^.Options := W^.Options or ofCentered;
  W^.Palette := wpGrayWindow;
  W^.Flags := 0;

  S := '';
  for C := #33 to #254 do
   if (Pos(C,#$E5';.,=+<>|"[] \/*?:') = 0) and not (C in P^.ValidChars) then
    if Length(S)=0 then S:= S+C
                   else S:= S+','+C;
  if S = '' then S := GetString(dlReanimateNone);
  W^.GetExtent(R);
  R.Grow(-1, -1);
  S1 := UpStrg(Copy(P^.Name,2,255));
  if Copy(S1,10,3)<>'   ' then S1[Pos(' ',S1)]:='.';
  i:=Length(s1);
  DelSpace(S1);
  S1:=S1+Copy('           ',1,i-Length(s1));
  PP[1] := @S1; PP[2] := @S;
  FormatStr(S2, GetString(dlReanimateWrite), PP);
  PV := New(PStaticText, Init(R, S2));
  W^.Insert(PV);

  R.Assign(13,7,14,8);
  PV := New(PIView, Init(R));
  W^.Insert(PV);

  Desktop^.Insert(W);
  repeat
   KeyEvent(Event);
   Event.CharCode := UpCase(Event.CharCode);
  until (Event.KeyCode = kbESC) or (Event.CharCode in P^.ValidChars);

  if Event.CharCode in P^.ValidChars then
    begin
     PIView(PV)^.C := Event.CharCode;
     PV^.DrawView;
     Dir := MemAlloc(Drv^.ClusterSize(P^.Dir));
     if Dir <> nil then
      begin
       Drv^.ClusterRead(Dir^, P^.Dir);
       S := Dir^[P^.DirEntry].Name; S[1] := '?'; Insert(' ', S, 9);
       if UpStrg(P^.Name) = S then
        begin
         Dir^[P^.DirEntry].Name[0] := Event.CharCode;
         Drv^.ClusterWrite(Dir^, P^.Dir);
         RereadDrives := RereadDrives + [Char(Drv^.Drive+65)];
         FreeMem(Dir,Drv^.ClusterSize(P^.Dir));
         if (P^.Size <> 0) or (P^.Attr and Directory <> 0) then
          begin
           Cl := GetCol;
           for I := 0 to Cl^.MaxSize do
            if I < Cl^.MaxSize then Drv^.SetFAT(Cl^.GetData(I),Cl^.GetData(I+1))
                               else Drv^.SetFAT(Cl^.GetData(I), $FFF+$F000*Byte(not Drv^.FAT12));
           Drv^.WriteFAT;
           Dispose(Cl, Done);
           InfoPane^.FirstCall := On;
           GetDirData;
          end;
        end else FreeMem(Dir,Drv^.ClusterSize(P^.Dir));
      end;
    end;
  Desktop^.Delete(W);
  Dispose(W, Done);
  Owner^.SetState(sfActive, True);
  ClearEvent(Event);
  SetRange(List^.Count);
  FocusItem(OldPos);
  NormalCursor;
  ShowCursor; { Не работает 8-() }
 end;

 procedure ViewFile;
  var
      D: PDialog;
      R: TRect;
      PV: PView;
      MemoStream: PStream;
      Xt: ExtStr;
      Cl: PWordCollection;
      Sz: LongInt;
 begin
  if P^.Attr and Directory = 0 then Sz := P^.Size
                               else Sz := Drv^.ClusterSize(2);
  if Sz = 0 then Exit;
  Cl := GetCol;
  MemoStream := New(PClusterStream, Init(Cl, Drv, Sz));
  R.Assign(1,1,80,23);
  D := New(PDialog, Init(R, GetString(dlReanimateView)));
  D^.Options := D^.Options or ofCentered;

  R.Assign(78, 2, 79, 18);
  PV := New(PViewScroll, Init(R));
  D^.Insert(PV);

  R.Assign(1, 2, 78, 18);
  PV := New(PNFileViewer, Init(R, MemoStream, '', PV, False, P^.Attr and Directory <> 0));
  PNFileViewer(PV)^.NoEdit := On;
  D^.Insert(PV);

{  R.Assign(13, 16, 28, 18);
  PV := New(PButton, Init(R, GetString(dlHexASCIIButton), cmHexMode, 0));
  D^.Insert(PV);
 }
  R.Assign(20, 19, 30, 21);
  PV := New(PButton, Init(R, GetString(dlOKButton), cmOK, bfDefault));
  D^.Insert(PV);

  R.Assign(35, 19, 55, 21);
  PV := New(PButton, Init(R, GetString(dlCopyButton)+'...', cmReanimator, bfBroadcast));
  D^.Insert(PV);

  D^.SelectNext(False);

  D := PDialog(Application^.ValidView(D));
  if D = nil then Exit;
  Desktop^.ExecView(D);
  Dispose(D, Done);
  Dispose(Cl, Done);
 end;

 procedure ChCluster;
  var I: Integer;
 begin
   if P^.Attr and Directory <> 0 then
     begin
        OldClu := DirCluster;
        DirCluster := P^.Cluster;
        GetDirData;
        for I := 1 to List^.Count do
          begin
                 P := List^.At(I-1);
                 if (P^.State = 0) and (P^.Cluster = OldClu) then
                  begin FocusItem(I-1); Exit; end;
          end;
     end;
 end;

 procedure ChangeDrive;
  var T: TPoint;
      S: String;
 begin
  if Drv = nil then Exit;
  S[1] := Char(Drv^.Drive+65);
  T.X := Size.X div 2; T.Y := 1; MakeGlobal(T, T); Desktop^.MakeLocal(T,T);
  S := SelectDrive(T.X, T.Y, S[1], Off); if S = '' then Exit;
  if S[1] = Char(Drv^.Drive+65) then Exit;
  ChDir(S);
  GetDir(Byte(S[1])-64, S); if Abort then Exit;
  Dispose(Drv, Done);
  New(Drv, Init(Byte(S[1])-64, True));
  if Drv = nil then Message(Owner, evCommand, cmCancel, @Self);
  DirCluster := Drv^.GetPath(S);
  GetDirData;
 end;

begin
 if (Event.What = evMouseDown) and (Event.Double) then
  begin
    Event.What := evKeyDown;
    Event.Command := kbEnter;
  end;
{    PutEvent(Event);
    ClearEvent(Event);
  end;}

 inherited HandleEvent(Event);
 case Event.What of
  evCommand: case Event.Command of
              cmRChDrive: begin
                          ChangeDrive;
                          ClearEvent(Event);
                         end;
              cmRViewFile: begin
                            ClearEvent(Event);
                            if Focused >= List^.Count then Exit;
                            P := List^.At(Focused);
                            if P^.State < 2 then
                             begin ChCluster; Exit end;
                            if P^.State < 4 then ViewFile;
                          end;
              cmReanimateFile: begin
                            ClearEvent(Event);
                            if Focused >= List^.Count then Exit;
                            P := List^.At(Focused);
                            if P^.State < 2 then
                             begin ChCluster; Exit end;
                            if (P^.State > 2) and
                                (P^.Attr and Directory <> 0) then
                                 begin
                                  Msg(dlCantReanimateDirectory, nil, mfInformation+mfOKButton);
                                  Exit;
                                 end;
                            if (P^.State < 4) then ReanimateFile
                                            else Msg(dlCantReanimate, nil, mfInformation+mfOKButton);
                           end;

             end;
 end;
end;

destructor TReanimator.Done;
begin
 if Drv <> nil then Dispose(Drv, Done);
 if List <> nil then Dispose(List, Done);
 inherited Done;
end;

procedure TReanimator.GetDirData;
 var P: PReaData;
     Cl, I, J: Word;
     Dir: ^DirPtr;
     DirSize: Word;
     DirEnd: Boolean;
     PC: PCollection;
     S: String;
     Msg: PView;

 procedure NewEntry(State: Byte);
  var T: DateTime;
      K: Word;
 begin
  New(P);
  P^.Name := Dir^[I].Name;
  {if P^.Name[1] <> '.' then }Insert(' ', P^.Name, 9);
  if Dir^[I].Name[0] = #$E5 then P^.Name[1] := '?';
  if Dir^[I].Attr and Directory = 0 then LowStr(P^.Name);
  UnpackTime(Dir^[I].Date, T);
  P^.Size := Dir^[I].Len;
  P^.Cluster := Dir^[I].Clus;
  P^.Attr := Dir^[I].Attr;
  P^.Year := T.Year mod 100;
  P^.Month := T.Month;
  P^.Day := T.Day;
  P^.Hour := T.Hour;
  P^.Min := T.Min;
  P^.State := State;
  P^.Dir := Cl;
  P^.DirEntry := I;
  P^.ValidChars := [#33..#254] - [#$E5,'+','"','=','/','?',':','.',';','*','[',']','<','>','|','\'];
  PC^.Insert(P);
  K := P^.Cluster;
  if P^.State > 1 then
   begin
    J := LongInt(P^.Size) div LongInt(Drv^.ClusterSize(2));
    if (J > FreeClusters) or (Drv^.GetFAT(P^.Cluster) <> 0) then P^.State := 4 else
     begin
      while (J > 0) and (K < Drv^.TotalClu + 2) and (Drv^.GetFAT(K) = 0) do begin Dec(J); Inc(K); end;
      if J > 0 then P^.State := 3;
     end;
   end;
 end;

 procedure InfoPaneUpdate;
 var S,S1: PathStr;

 begin
  With InfoPane^ do
    begin
     if FirstCall then begin FirstCall:=False; DrawView; Exit; end;
     GetDir(0,S1);

     if (S1[1]<>CurDir[1])  then
                              begin
                               CurDir:=S1; DrawView; Exit;
                              end;
     S:=Copy(GetText(Focused,12),1,12);
     if Copy(S,10,3)<>'   ' then S[Pos(' ',S)]:='.';
     DelSpace(s);
     if S='..' then begin
                      ChDir(CurDir);
                      CurDir:=FExpand(S);
                    end
               else if Length(CurDir)>3 then CurDir:=CurDir+'\'+S
                                        else CurDir:=CurDir+S;
     DrawView;
    end;
 end;

begin
 InfoPaneUpdate;

 Cl := DirCluster;
 DirSize := Drv^.ClusterSize(Cl);
 Dir := MemAlloc(DirSize);
 if Dir = nil then Exit;
 if LowMemory then
  begin Application^.OutOfMemory; FreeMem(Dir, DirSize); Exit end;
 Msg := WriteMsg(^M^M^C+GetString(dlReanimateScan));
 if FreeClusters = 0 then FreeClusters := LongInt(DiskFree(0)) div LongInt(Drv^.ClusterSize(2));
 PC := New(PReaCollection, Init(10,10));
 DirEnd := False;
 repeat
  Drv^.ClusterRead(Dir^, Cl);
  for I := 0 to DirSize div 32 - 1 do
   begin
    if Dir^[I].Name[0] < #32 then begin DirEnd := True; Break; end;
    if (Dir^[I].Name[0] <> #$E5) and (Dir^[I].Attr and Directory <> 0) and
       (Copy(Dir^[I].Name,1,2) <> '. ') and
       (Dir^[I].Attr and VolumeID = 0) then NewEntry(0);
    if (Dir^[I].Name[0] = #$E5) and (Dir^[I].Attr and VolumeID = 0) then
     NewEntry(2);
   end;
  Cl := Drv^.GetFAT(Cl);
 until (Cl = 0) or (Cl >= Drv^.EOFMark) or DirEnd;
 DirEnd := False;
 Cl := DirCluster;
 repeat
  Drv^.ClusterRead(Dir^, Cl);
  for I := 0 to DirSize div 32 - 1 do
   begin
    if Dir^[I].Name[0] < #32 then begin DirEnd := True; Break; end;
    if Dir^[I].Name[0] <> #$E5 then
     begin
      S := Dir^[I].Name; Insert(' ', S, 9); S[1] := '?';
      for J := 1 to PC^.Count do
       begin
        P := PC^.At(J-1);
        if S = UpStrg(P^.Name) then P^.ValidChars := P^.ValidChars - [Dir^[I].Name[0]];
       end;
     end;
   end;
  Cl := Drv^.GetFAT(Cl);
 until (Cl = 0) or (Cl >= Drv^.EOFMark) or DirEnd;
 Desktop^.Delete(Msg);
 Dispose(Msg, Done);
 FreeMem(Dir, DirSize);
 if Owner <> nil then
  begin
   Owner^.SetState(sfActive, True);
   SetState(sfActive, True);
  end;
 if List <> nil then Dispose(List, Done);

 List := nil;
 NewList(PC);
 isValid := not Abort;
end;

function TReanimator.GetText;
 var P: PReaData;
     S,S1: String;
begin
 P := List^.At(Item);
 S := '---- ';
 if P^.Attr and Directory <> 0 then S[1] := 'd';
 if P^.Attr and Archive <> 0 then S[2] := 'a';
 if P^.Attr and SysFile <> 0 then S[3] := 's';
 if P^.Attr and ReadOnly <> 0 then S[4] := 'r';
 with P^ do
  begin
   if P^.Attr and Directory <> 0 then S1 := {'DIR'}GetString(dlReanimateDirectory)
                                 else S1 := FStr(Size);
   S := Name + PredSpace(S1, 12) + ' ' + S;
   MakeDate(0, Day, Month, Year, Hour, Min, S1);
   S := S + S1 + PredSpace(FStr(Cluster), 7) + ' ';
   case State of
    0: S1 := '';
    1: S1 := GetString(dlReanimateRecovered);
    2: S1 := GetString(dlReanimateGood);
    3: S1 := GetString(dlReanimateAverage);
    4: S1 := GetString(dlReanimatePoor);
   end;
  end;
 GetText := S + S1;
end;

procedure OpenReanimator;
 var D: PDialog;
     P: PView;
     R: TRect;
     S: String;
     B: Byte;

begin
 R.Assign(1,1,70,21);
 D := New(PDialog, Init(R, GetString(dlReanimateTitle)));
 D^.Options := D^.Options or ofCentered;
 D^.HelpCtx := hcReanimator;

 R.Assign(66,3,67,15);
 P := New(PScrollBar, Init(R));
 P^.Options := P^.Options or ofPostProcess;
 D^.Insert(P);

 R.Assign(2,15,67,16);
 InfoPane := New(PReanimateTreeInfoView, Init(R));
 D^.Insert(InfoPane);

 R.Assign(2,3,66,15);
 P := New(PReanimator, Init(R, PScrollBar(P)));
 D^.Insert(P);

 R.Assign(2,2,66,3);
 P := New(PLabel, Init(R, GetString(dlReanimateHead), P));
 D^.Insert(P);

 S:=GetString(dlDriveButton)+GetString(dlViewButton)+GetString(dlReanimateButton);
 B:=37-Length(S);
 S:=GetString(dlDriveButton);

 R.Assign(B,17,B+Length(S)+2,19);
 P := New(PButton, Init(R, S, cmRChDrive, 0));
 D^.Insert(P);

 S:=GetString(dlViewButton);
 R.A.X:=R.B.X+1; Inc(R.B.X,Length(S)+3);
 P := New(PButton, Init(R, S, cmRViewFile, 0));
 D^.Insert(P);

{ R.Assign(32,17,45,19);}
 S:=GetString(dlReanimateButton);
 R.A.X:=R.B.X+1; Inc(R.B.X,Length(S)+3);
 P := New(PButton, Init(R, S, cmReanimateFile, bfDefault));
 D^.Insert(P);

 R.Assign(46,17,56,19);
 P := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, 0));
 D^.Insert(P);

 R.Assign(57,17,67,19);
 P := New(PButton, Init(R, GetString(dlHelpButton), cmHelp, 0));
 D^.Insert(P);

 D^.SelectNext(False);

 D := PDialog(Application^.ValidView(D));
 if D = nil then Exit;
 RereadDrives := [];
 Desktop^.ExecView(D);
 S := 'A:\';
 for S[1] := 'A' to 'Z' do
  if S[1] in RereadDrives then
   begin
    RereadDirectory(S);
    GlobalMessage(evCommand, cmRereadInfo, nil);
    GlobalMessage(evCommand, cmRereadTree, @S);
   end;


 Dispose(D, Done);

end;

end.