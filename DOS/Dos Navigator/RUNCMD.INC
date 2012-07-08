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

procedure SaveDsk;
begin
 if StartupData.Unload and osuAutosave = 0 then
    PDNApplication(Application)^.SaveDesktop(SwpDir+'DN'+ItoS(DNNumber)+'.SWP');
end;

procedure ExecString(S: Str128);
 var F1: Text;
     I: Integer;
     M: String;
     DT: DateTime;
 label 1;
begin
 DelRight(S);
 if not Chk4Dos and (Pos('||', S) <> 0) then
  begin
    Assign(F1, SwpDir+'$DN'+ItoS(DNNumber)+'$.BAT'); ClrIO;
    Rewrite(F1); if IOResult <> 0 then begin Close(F1); Exit; end;
    I := 0;
    repeat
      I := Pos('||', S);
      if I = 0 then I := Length(S)+1;
      WriteLn(F1, MakeCMDParams(Copy(S, 1, I-1),
                                CnvString(CurFileActive),
                                CnvString(CurFilePassive)));
      Delete(S, 1, I+1);
    until (S = '');
    Close(F1);
    S := SwpDir+'$DN'+ItoS(DNNumber)+'$.BAT ';
  end else S := MakeCMDParams(S, CnvString(CurFileActive), CnvString(CurFilePassive));
1:
 S := ' '+S+#13; Dec(S[0]);
 if (LoaderSeg <> 0) then Move(S, mem[LoaderSeg:CommandOfs], Length(S)+2);
 if (SystemData.Options and ossFastExec <> 0) or RunFrom2E then asm
                                               mov ax, 9903h
                                               mov cl, 1
                                               int 2Fh
                                            end;
 if TimerMark then DDTimer := Get100s
              else DDTimer := 0;
 asm
    mov ax, 9904h
    mov  dx, word ptr DDTimer
    mov  cx, word ptr DDTimer+2
    int 2Fh
    mov ax, 9902h
    mov cl, 1
    int 2Fh
 end;
 Halt(1);
end;

function SearchExt(Name: NameStr; Ext: ExtStr; var HS: String): Boolean;
var
  AllRight : Boolean;
  f        : PTextReader;
  f1       : Text;
  s,s1     : String;
  BgCh,EnCh: Char;
  EF, First: Boolean;
  I        : Integer;
  Local: Boolean;
label RL;

  function transl(var s: string): string;
  var i: integer;
      b: ExtStr;
      r: NameStr;
      ad: string;
  begin
    ad := ActiveDir; if ad[Length(ad)]<>'\' then ad := ad + '\';
    B := Ext; LowStr(B); Insert('.', B, 1);
    R := Name; DelRight(R); LowStr(R);
    Replace('!!', #0, S);
    Replace('.!', B, S);
    Replace('!\', LowStrg(ad), S);
    Replace('!/', Copy(LowStrg(ad), 1, Length(ad)-1), S);
    Replace('!', R, S);
    Replace(#0, '!!', S);
    Transl:=S;
  end;

  function InFilter(const S: String): Boolean;
    var I: Integer;
        M: String[3];
  begin
    InFilter := On;
    repeat
       I := PosChar(';', S1);
       if I = 0 then I := PosChar(',',S1);
       if I = 0 then I := Length(S1)+1;
       M := Copy(S1, 1, I-1); Delete(S1, 1, I);
       if M = '.' then M := '';
       if InMask(S, Norm12('*.'+M)) then Exit;
    until (S1 = '');
    InFilter := Off;
  end;


begin
  First := True;
  GetDir(0, ActiveDir);
  SearchExt:=False;
  Local := On;
  f := New(PTextReader, Init('DN.EXT'));
  if f=nil then
   begin
  RL:
     Local := Off;
     f := New(PTextReader, Init(SourceDir+'DN.EXT'));
   end;
  if f=nil then Exit; AllRight:=False;
  BgCh:='{';EnCh:='}'; Abort := Off; EF:=Off;
  if PShootState and 8 > 0 then begin BgCh:='[';EnCh:=']';end else
  if PShootState and 3 > 0 then begin BgCh:='(';EnCh:=')';end;
  While (not f^.EOF) and (not AllRight) do begin
    S := f^.GetStr;
    if S[1] <> ' ' then
     begin
      I := PosChar(BgCh, S); if I = 0 then Continue;
      S1 := Copy(S, 1, I-1); UpStr(S1);
      if InFilter(Name+'.'+Ext) then
       begin
        Assign(f1, SwpDir+'$DN'+ItoS(DNNumber)+'$.BAT'); ClrIO;
        Rewrite(F1); if IOResult <> 0 then begin Dispose(F, Done); Exit; end;
        System.Delete(S, 1, PosChar(BgCh, S));
        repeat
         Replace(']]', #0, S);  Replace('))', #1, S);  Replace('}}', #2, S);
         DelLeft(S); DelRight(S);
         if S[Length(S)] = EnCh then
          begin Dec(S[0]); EF := On; if S <> '' then
           begin S := Transl(S); HS := S;
             Replace(#0, ']', S);  Replace(#1, ')', S);  Replace(#2, '}', S);
             WriteLn(F1, S); Break
           end;
          end;
         if S <> '' then
          begin
           if (BgCh <> '[') then S := Transl(S);
           if First and (BgCh <> '[') then HS := S;
           Replace(#0, ']', S);  Replace(#1, ')', S);  Replace(#2, '}', S);
           WriteLn(F1, S);
           First := False;
          end;
         if (F^.EOF) then Break;
         if not EF then S := F^.GetStr;
        until (IOResult <> 0) or Abort or EF;
        Write(F1, '@echo off');
        Close(F1);
        AllRight := On;
       end;
      end;
   end;
  Dispose(F, Done);
  if not EF and not Abort and Local then Goto RL;
  if EF and (BgCh = '[') then
   begin
    EraseFile( SwpDir+'$dn'+ItoS(DNNumber)+'$.mnu' );
    Rename(F1, SwpDir+'$dn'+ItoS(DNNumber)+'$.mnu');
    EF := ExecUserMenu(Off);
    if not EF then Erase(F1);
   end;
  SearchExt:=not Abort and EF;
end;

function ExecExtFile(const ExtFName, FName: PathStr; SIdx: TStrIdx): Boolean;
 var F: PTextReader;
     S: String;
     Mask, Nm: String[12];
     Dr: PathStr;
     Xt: ExtStr;
     Event: TEvent;
     I,J: Integer;
     PP: PView;
     Success, CD: Boolean;
     Local: Boolean;
 label 1,1111, RepeatLocal;
begin
 ExecExtFile := Off;
 FileMode := $40;
 Local := On;

 F := New(PTextReader, Init(ExtFName));

 if F = nil then
  begin
RepeatLocal:
    Local := Off;
    F := New(PTextReader, Init(SourceDir+ExtFName));
  end;
 if F = nil then Exit;
 FSplit(FExpand(FName), Dr, Nm, Xt);
 Nm := Norm12(Nm+Xt);
 While not F^.EOF do
   begin
      S := F^.GetStr;
      DelLeft(S);
      if (S <> '') and (S[1] <> ';') then
        begin
          repeat
             J := PosChar(':', S); if J = 0 then Goto 1;
             I := PosChar(',', S);
             if (I <> 0) and (I < J) then
               begin
                 Mask := Norm12('*.'+Copy(S,1,I-1));
                 if InMask(Nm, Mask) then
                   begin
                     Delete(S, 1, J); Goto 1111;
                   end else Delete(S, 1, I);
               end else
               begin
                 Mask := Norm12('*.'+Copy(S,1,J-1));
                 Delete(S, 1, J);
                 if InMask(Nm, Mask) then Goto 1111;
                 Break;
               end;
          until S='';
        end;
    1:
   end;
   ExecExtFile := Off;
   Dispose(F, Done);
   if Local then Goto RepeatLocal;
   Exit;
1111:
   Dispose(F,Done);
   if not Application^.Valid(cmQuit) then Exit;
   Replace('!!', #0, S);
   Success := PosChar('!', S) = 0;
   CD := Off;
   FSplit(FExpand(FName), Dr, Nm, Xt);
   if not Success then
     begin
        Replace('!', #0, Dr);
        Replace('!', #0, Nm);
        Replace('!', #0, Xt);
        CD := not Replace('!\', Copy(Dr, 3, 255), S);
        Replace('!:', Copy(Dr, 1, 2), S);
        Replace('.!', Xt, S);
        Replace('!',  Nm, S);
     end else S := S + ' ' + Dr+Nm+Xt;
   Replace(#0, '!', S);
   ClrIO;
   if CD then
     begin
        GetDir(0, DirToChange);
        ChDir(Dr);
     end else DirToChange := '';
   if Abort then Exit;
   if S[1] = '*' then DelFC(S);
    begin
        PP := _WriteMsg(' '+GetString(SIdx));
        InsertUserSaver(Off);
        SaveDsk;
        Application^.Done;
        ExecString(S);
    end;
end;

procedure ExecFile(Name: PathStr);
 var S, M: String;

 procedure PutHistory(B: Boolean);
 begin
  if M = '' then Exit;
  CmdLine.Str := M;
  CmdLine.StrModified := On;
  CmdDisabled := B;
  Message(CommandLine, evKeyDown, kbDown, nil);
  Message(CommandLine, evKeyDown, kbUp, nil);
 end;

 procedure RunCommand(B: Boolean);
   var ST: SessionType;
 begin
    if (PCommandLine(CommandLine)^.LineType in [ltOS2Window,ltOS2FullScreen]) then
     begin
       if PCommandLine(CommandLine)^.LineType = ltOS2FullScreen then ST := stOS2FullScreen
         else ST := stOS2Windowed;
       RunOS2Command(M, Off, ST);
       CmdLine.StrModified := On;
       Message(CommandLine, evKeyDown, kbDown, nil);
       Exit;
     end;
    SaveDsk;
    Application^.Done;
    if B then begin WriteLn(#13#10, ActiveDir+'>', M); M := M + #13 end;
    ExecString(M);
 end;

begin
 S := LowStrg(Norm12(Name));
 FreeStr := '';
 M := '';
 if (ShiftState and (3 or kbAltShift) <> 0) or
    (Pos(#0+Copy(S, 10, 3)+#0, Executables) = 0) then
  begin
   if SearchExt(Copy(S, 1, 8), Copy(S, 10, 3), M) then
   begin
    PutHistory(On);
    M := SwpDir+'$DN'+ItoS(DNNumber)+'$.BAT ' + FreeStr;
    RunCommand(Off);
   end else Exit;
  end;
 M := LowStrg(MakeFileName(S));
 PutHistory(Off);
 M := Name;
 RunCommand(On);
end;