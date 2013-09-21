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

UNIT FBB;

interface
uses Dos;

 Function LongCopy(fn1: PathStr): Boolean;

implementation
uses Advance, FileCopy, DNApp, Messages, Views, Objects, Dialogs, Commands,
     Drivers, Memory, FilesCol, DiskTool, RStrings, HistList, Gauge,
     StartUp, DNutil, xTime, DiskInfo;

 type Ar65000 = Array [1..65000] of Byte;
      ArPtr = ^Ar65000;

      HRec = record
       Num : Word;
       NR  : Word;
       NW  : Word;
       Buf : ^Ar65000;
      end;

 var Bf      : Array [1..20] of HRec;
     NBf     : Byte;
     dr1,dr2 : Byte;
     FreeSpc : TSize;
     Timer: TEventTimer;

 function MaxAvail: LongInt;
 begin
   MaxAvail := MemAdjust(System.MaxAvail);
 end;

 procedure GetMaxMem;
  var l : LongInt;
 begin
  NBf:=0;
  repeat
   l:=MaxAvail-15000;
   if l>0 then
    begin
     Inc(NBf);
     if l>65000 then l:=65000;
     Bf[NBF].Buf := MemAlloc(l);
     Bf[NBf].Num:=l;
     if Bf[NBF].Buf = nil then Dec(NBF);
    end;
  until (MaxAvail<16000) or LowMemory;

 end;

 procedure ClearMem;
  var i : Byte;
 begin
  for i:=1 to NBf do FreeMem(Bf[i].Buf,Bf[i].Num);
 end;

 procedure DskOn;
 begin
  if dr1<=NumFloppy then DiskOn(dr1);
  if dr2<=NumFloppy then DiskOn(dr2);
 end;

 Function LongCopy(fn1: PathStr): Boolean;
  label Ex, _Abort_;
  type Hdr=record
        nm : array[1..23] of Char;
        xt : array[1..3] of Char;
        ln : LongInt;
       end;

  const StdHdr : Hdr=(nm:'Navigator Long Copy '#13#10#26;xt:'   ';ln:0);
        NStr : String[40]='123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  var f1,f2 : File;
      Cs,Cd : LongInt;
      Ls,Ld : LongInt;
      Tuda  : Boolean;
      i     : Byte;
      NumW  : Word;
      Count : Byte;
      wx,wy : Integer;
      wl    : Byte;
      d,fn2 : PathStr;
      n,x   : NameStr;
      hd    : Hdr;
      PInfo : PWhileView;
      CopyCancelled: Boolean;
      BinarySplit: Boolean;
      DiskVerify: Boolean;
      LastPos: LongInt;
      Olddate: LongInt;
      AlarmTimer: TEventTimer;

  procedure DsplInfo;
  begin
    PInfo^.Write(5, GetString(dlRead)+
                 Copy(Strg(#219,(LongInt(wl)*Cs) div Ls)+Strg(#177, wl),1,wl));
    PInfo^.Write(6, GetString(dlWrite)+
                 Copy(Strg(#219,(LongInt(wl)*Cd) div Ls)+Strg(#177, wl),1,wl));
  end;

  procedure MaxRead;
   var  i : Byte;
        b : Boolean;
  begin
    b:=On;
    DsplInfo;
    for i:=1 to NBf do
     begin
      DskOn;
      if b then BlockRead(f1,Bf[i].Buf^,Bf[i].Num,Bf[i].NR)
           else Bf[i].Nr:=0;
      if IOResult <> 0 then
       begin
        MessageBox(GetString(dlFBBNotReadSource)+fn1, nil, mfError+mfOKButton);
        Abort := On;
        NewTimer(Timer, 0);
        NewTimer(AlarmTimer, 0);
       end;
      DskOn;
      DispatchEvents(PInfo, CopyCancelled);
      if Abort or CopyCancelled then
       begin
        Close(f2);
        Erase(f2);
        Exit;
       end;
      Bf[i].NW:=0;
      Inc(Cs,Bf[i].NR);
      DsplInfo;
      b:=Bf[i].NR<>0;
     end;
  end;

  function OverWr : Boolean;
   var sr : SearchRec;
       f  : File;
  begin
   DosError:=0; OverWr:=On; Abort := Off;
   FindFirst(d+n+'.d??',$3F xor VolumeID,sr);
   if DOSError=0 then
    begin
     i:=MessageBox(GetString(dlFBBOver1) + sr.Name + GetString(dlFBBOver2), nil,
                   mfQuery+mfYesButton+mfNextDButton+mfCancelButton);
     NewTimer(Timer, 0);
     NewTimer(AlarmTimer, 0);
     Abort:=i=cmCancel;
     if i=cmYes
       then EraseFile( d+sr.name )
       else OverWr:= I <> cmCancel;
    end;
  end;

  procedure RequireDisk;
  begin
   Abort:=MessageBox(GetString(dlFBBInsertDisk)+SStr(Count,2,'0'), nil,
                     mfConfirmation + mfOKButton + mfCancelButton)<>cmOK;
   NewTimer(Timer, 0);
   NewTimer(AlarmTimer, 0);
  end;

  procedure RequireNew;
   label 1;
  begin
   Inc(Count);DskOn;
1: repeat
    if Count>1 then
    begin
     SetFTime(F2, OldDate);
     Close(f2);ClrIO;
     RequireDisk;
    end;
    FSplit(fn2,d,n,x);
    fn2:=d+n+'.d'+SStr(Count,2,'0');
   Until OverWr or Abort or CopyCancelled;
   if Abort or CopyCancelled then Exit;
   FreeSpc:=Disk_Free(Byte(d[1])-64);
   While (FreeSpc<512) do
    begin
     i:=MessageBox(GetString(dlFBBDiskFull1),nil,mfWarning + mfOKButton + mfCancelButton);
     NewTimer(Timer, 0);
     FreeSpc:=Disk_Free(Byte(d[1])-64);
     if i<>cmOK then
       begin
        Abort:=On;
        Exit;
       end;
     DskOn;
    end;
   DskOn;
   CreateDirInheritance(d, Off);
   Assign(f2,fn2); PInfo^.Write(3, fn2);
   ClrIO; ReWrite(f2,1);
   if not BinarySplit then BlockWrite(f2,StdHdr,SizeOf(Hdr));
   DskOn;
   if IOResult<>0 then
    begin
    i:=MessageBox(GetString(dlFBBNoCreate)+SStr(Count,2,'0'), nil,
                  mfError + mfOKButton + mfCancelButton);
    NewTimer(Timer, 0);
    NewTimer(AlarmTimer, 0);
    if i<>cmOK then
       begin
        Abort:=On;
        Exit;
       end;
     GoTo 1;
    end;
  end;

  procedure MaxWrite;
   label Rep,1,2, 33;
   var i  : Byte;
       wr : LongInt;
  begin
   Rep:
    if Abort or CopyCancelled then Exit;
    for i:=1 to NBf do
     if BF[i].NW<BF[i].NR then
     begin
      DskOn;
      wr:=LongInt(Bf[i].NR)-LongInt(Bf[i].NW);
2:    LastPos := FilePos(f2);
      BlockWrite(f2,Bf[i].Buf^[Bf[i].NW+1],Word(wr),NumW);
      if DiskVerify then
        begin
           asm
             mov ah,0dh
             int 21h
           end;
           Seek(f2, LastPos);
           BlockRead(f2,Bf[i].Buf^[Bf[i].NW+1],Word(wr),NumW);
        end;
      if (IOResult <> 0) then
       begin
        MessageBox(GetString(dlFBBNoWrite)+fn2, nil, mfError+mfOKButton);
        Abort := On;
        NewTimer(Timer, 0);
       end;
      if Abort then Goto 33;
      DskOn;
      if NumW=0 then
       begin
        wr:=DiskFree(dr2);
        if wr=0 then GoTo 1
                else GoTo 2;
       end;
      Inc(Bf[i].NW,NumW);
      Inc(Cd,NumW);
      DsplInfo;
      DispatchEvents(PInfo, CopyCancelled);
      if Abort or CopyCancelled then
         begin
33:       CopyCancelled := On;
          Close(f2);
          Erase(f2);
          Exit;
         end;
1:    if NumW=0 then if Tuda then begin
                                   MessageBox(GetString(dlFBBDiskFull2), nil, mfError+mfOKButton);
                                   NewTimer(Timer, 0);
                                   Abort:=On;
                                   Exit;
                                  end else begin
                                            if (ElapsedTimeInSecs(AlarmTimer) > 20)
                                              and (FMSetup.Options and fmoBeep <> 0) then
                                                BeepAftercopy;
                                            ReQuireNew;
                                            GoTo Rep;
                                           end;
      if Bf[i].NR>Bf[i].NW then Dec(i);
     end;
  end;

  function CheckSvoi : Boolean;
  begin
   CheckSvoi:=Off;
   FillChar(hd,SizeOf(Hdr),255);
   BlockRead(f1,hd,SizeOf(Hdr));
   CheckSvoi:=(IOResult=0) and (hd.nm=StdHdr.nm) and (hd.Ln>0);
   Ls:=Hd.Ln;
  end;

  procedure InsCor;
  begin
   Inc(Count);
   repeat
    Close(f1);
    if Count>1 then
     begin
      ClrIO;
      RequireDisk;
      if Abort then Exit;
     end;
     ClrIO;
     FSplit(fn1,d,n,x);
     fn1:=d+n+'.d'+SStr(Count, 2, '0');
     FileMode := 0;
     Assign(f1,fn1); Reset(f1,1); PInfo^.Write(1, fn1);
    until ((IOResult=0) and CheckSvoi) or Abort or CopyCancelled;
  end;

  procedure Nedochit;
   var i : Byte;
       b : Boolean;
  begin
   b:=Off;
   for i:=1 to NBF do b:=b or (BF[i].NR=0);
   if b and (cd<ls) then InsCor;
  end;

  var CopyDir: PathStr;

  function CopyDialog: Boolean;
   var D: PDialog;
       P, P1: PView;
       R: TRect;
       S,Mask: String;
       SR: SearchRec;
       I: Integer;
       DTA: record S: String[70]; W: Word; end;
    function IsLabel( P: PView ): boolean; far;
    begin
      IsLabel := TypeOf( P^ ) = TypeOf( TLabel );
    end;
  begin
    CopyDialog := Off;
    If Tuda
      then D := PDialog( LoadResource( dlgCombineFile ))
      else D := PDialog( LoadResource( dlgSplitFile ));
    P := D^.FirstThat( @IsLabel );
    R.Assign( P^.Origin.X + P^.Size.X-1, P^.Origin.Y, D^.Size.X - 1, P^.Origin.Y + 1 );
    D^.Insert( New( PLabel, Init( R, '~'+LowCaseStr(GetName( fn1 ))+'~'+
               GetString(dlSplit_To), PLabel(P)^.Link)));
    S := '';
    GlobalMessage(evCommand, cmPushFirstName, @S);
    GlobalMessage(evCommand, cmPushName, Pointer(hsFBBCopy));
    if S[2] <> ':' then S := '';
    if S = '' then S := HistoryStr(hsFBBCopy, 1);
    DTA.S := S;
{    DTA.W := 0; }

        i := Byte(UpCase(s[1]));
        if i in [65..90] then
         begin
           if (SystemData.Drives[Char(i)] and 8) > 0 then
              DTA.W := 2  else DTA.W := 0 ;
         end;


    D^.SetData(DTA);
    if Desktop^.ExecView(D) = cmCancel then begin Dispose(D, Done); Exit end;
    D^.GetData(DTA);
    BinarySplit := DTA.W and 1 <> 0;
    DiskVerify := DTA.W and 2 <> 0;
    S := DTA.S;
    Dispose(D, Done);
    if S = '' then Exit;
    S := FExpand(S);
    if S[Length(S)] = '\' then begin
      CopyDir := S; Mask := x_x
    end else
    if (pos('*',S)=0) and (pos('?',S)=0) then begin
      DosError := 0; FindFirst(S+'\*.*', $3E xor VolumeID, SR); if Abort or CopyCancelled then Exit;
      if (DOSError = 0)
        then begin CopyDir := S+'\'; Mask := x_x end
        else begin FSplit(S,CopyDir,N,X); Mask := N+X end
      end
    else begin
      FSplit(S,CopyDir,N,X); Mask := N+X
    end;
    Mask := Norm12(Mask);
    Fn1 := FExpand(fn1);
    FSplit(fn1, S, N, X);
    S := Norm12(N + X);
    for I := 1 to 12 do if Mask[I] = '?' then Mask[I] := S[I];
    fn2 := DelSpaces(CopyDir + Mask);
    if fn2[Length(fn2)] = '.' then Dec(fn2[0]);
    CopyDialog := True;
  end;

  var R: TRect;
      PP: Pointer;
  begin
    NewTimer(Timer, 0);
    LongCopy := On;
    Count:=0; Tuda:=Off; Abort:=Off; CopyCancelled := False; BinarySplit := Off;
    fn1:=FExpand(fn1);
    FSplit(fn1,d,n,x);
    dr1:=Byte(fn1[1])-64;
    Cs:=0; Cd:=0; DskOn;
    FileMode := $40;
    Assign(f1,fn1); ClrIO;
    Reset(f1,1);
    if IOResult<>0 then
     begin MessageBox(GetString(dlFBBNoOpen)+fn1, nil, mfError + mfOKButton); LongCopy := Off; Exit; end;
    GetFTime(F1, OldDate);
    FSplit(fn1,d,n,x);

         {!! IB 18.07.95}
{    Tuda:=(X[0]=#4) and (Copy(x,2,1)='D') and (StoI(Copy(x,3,2)) > 0) and CheckSvoi; }

    Tuda := (X[0]=#4) and (Copy(x,2,1)='D') and (StoI(Copy(x,3,2)) > 0);
    if Tuda and not CheckSvoi then
           begin
            Close(f1);
            Message(Desktop, evCommand, cmSingleCopy, nil);
            LongCopy := Off;
            Exit;
           end;


    if Tuda then Count:=1;
    if Tuda and (x[4]<>'1') then
     begin
      Close(F1); ClrIO;
      x[4] := '1'; fn1 := d+n+x;
      Assign(f1, fn1);
      repeat
       RequireDisk;
       if Abort then begin LongCopy := Off; Exit; end;
       FileMode := 0;
       Reset(f1,1);
      until (IOresult = 0) and CheckSvoi;
     end;
    if not Tuda then
      begin
       Ls:=FileSize(f1);
       x:=x+'    ';
       Move(x[2],StdHdr.Xt,3);
       Seek(F1, 0);
      end;
    StdHdr.Ln:=Ls;

    if (not CopyDialog) or Abort then
_Abort_:    begin Close(f1); LongCopy := Off; Exit; end;

    fn2:=FExpand(fn2);
    if Abort then Goto _Abort_;
    dr2:=Byte(fn2[1])-64;
    if fn1=fn2 then Goto _Abort_;

    R.Assign(1,1,36,13);
    New(PInfo, Init(R));
    if PInfo = nil then Goto _Abort_;
    if Tuda then PInfo^.Top := GetString(dlFBBDeFragment)
            else PInfo^.Top := GetString(dlFBBFragment);
    PInfo^.Bottom := '';
    PInfo^.SetState(sfShadow, On);
    Desktop^.Insert(PInfo);
    PInfo^.Write(1, fn1);
    FSplit(fn2,d,n,x); x := UpStrg(x);
    if Tuda and (Copy(x,2,1)='D') and (StoI(Copy(x,3,2)) > 0)  then fn2 := d+n+'.'+hd.xt;
    Assign(f2,fn2);ClrIO;
    PInfo^.Write(2, GetString(dlFBBFragmentTo));
    PInfo^.Write(3, fn2);
    wl := PInfo^.Size.X - 8;
    if not Tuda then RequireNew
                else
                 begin
                  CreateDirInheritance(d, Off);
                  Reset(f2);
                  if IOResult=0 then
                   begin
                   PP:=@fn2;
                   if MessageBox(GetString(dlFileExist)+^M, @PP, mfQuery+mfYesButton+mfNoButton+mfCancelButton)
                    <> cmYes then
                       begin
                        Desktop^.Delete(PInfo);
                        Dispose(PInfo, Done);
                        Close(F2);
                        Goto _Abort_;
                       end;
                   end;
                  ClrIO;
                  Rewrite(f2,1);
                  if (IOResult<>0) or Abort then
                   begin
                    MessageBox(GetString(erCantCreateFile)+fn2, nil, mfError + mfOKButton);
                    Desktop^.Delete(PInfo);
                    Dispose(PInfo, Done);
                    Goto _Abort_;
                   end;
                 end;
    GetMaxMem;
    if NBf=0 then begin Close(F2); Erase(F2); Goto _Abort_; end;
    Inc(SkyEnabled);
    Repeat
     MaxRead;
     MaxWrite;
     if Tuda then NedoChit;
    until (Cd>=Ls) or Abort or CopyCancelled;
    Dec(SkyEnabled);
  Ex:
    Desktop^.Delete(PInfo);
    Dispose(PInfo, Done);
    Close(f1);
    SetFTime(F2, OldDate);
    Close(f2);
    if (Abort or CopyCancelled) and Tuda then Erase(f2);
    ClearMem;
    Abort := Off;
    {RereadDirectory(CopyDir);}
    GlobalMessage(evCommand, cmPanelReread, @CopyDir);
{    GlobalMessage(evCommand, cmRereadInfo, nil);}
    GlobalMessage(evCommand, cmRereadTree, @CopyDir);
    if not (Abort or CopyCancelled) then

    if (FMSetup.Options and fmoBeep <> 0) and
       (ElapsedTimeInSecs(Timer) > 20) then BeepAfterCopy;
  end;

end.