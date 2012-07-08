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

Unit ModemIO;

Interface uses OOCOM, apPort, DOS;

type  ModemString   = String[32];
      Str15         = String[15];
      TModemSetup = Record
           Port: Word;
           Baud: Word;
           UseCustom: Word;
           CustIRQ: String[2];
           CustPort: String[3];
           Init: String[80];
           Escape, Onhook: String[20];
           Prefix, Suffix: String[20];
           DownLoad: PathStr;
           Redial: String[4];
          end;

      TAdvModemData = record
        Data: Word;
        Stop: Word;
        Parity: ParityType;
        Byte_0: Byte;
        HFlow: Word;
        SFlow: Word;
      end;

const
      HangUpTime    : Word = 5;
  {°±²Û Max time to wait a character from modem, sec Û²±°}
      WaitAnswer    = 1;
      COMport       : AbstractPortPtr = nil;

      ModemSetup: TModemSetup =
       (Port:1; Baud:6;
        UseCustom:0;
        CustIRQ:''; CustPort:'';
        Init:'~ATZ'#13;
        Escape:'+++'; OnHook:'ATH0'#13;
        Prefix:'ATDP'; Suffix:#13;
        DownLoad:'';
        Redial:'10'
        );

  {°±²Û Modem answers Û²±°}
      maOK          : Str15 = 'OK';
      maCONNECT     : Str15 = 'CONNECT';
      maBUSY        : Str15 = 'BUSY';
      maNOCARRIER   : Str15 = 'NO CARRIER';
      maNODIALTONE  : Str15 = 'NO DIALTONE';
      maNOANSWER    : Str15 = 'NO ANSWER';
      maVOICE       : Str15 = 'VOICE';
      maNODIAL      : Str15 = 'NO DIAL';

       AdvModemData: TAdvModemData =
         (Data:0; Stop:0; Parity: NoParity; Byte_0: 0; HFlow: 1; SFlow: 0);

  {°±²Û Modem errors Û²±°}
      moOk          = 0;
      moAlreadyUsed = 1;             {°±²Û COMport variable already used Û²±°}
      moInitFail    = 2;             {°±²Û  No UART or hardware failure  Û²±°}
      ModemAnswer   : String = '';
var   StartTime     : Word;
      ModemChar     : Char;       {°±²Û Last character readed from modem Û²±°}

      Procedure HangUp;
      Procedure ModemDone;
      Procedure InitTimeOut(Max : Word);
      Function  ReadModem : Boolean;
      Function  InitModem : Byte;
      Function  Dial(Number : String) : Byte;
      Function  TimeOut : Boolean;
      Function  ModemSay(s : ModemString) : Boolean;
      Procedure SetupModem;
      procedure ModemWrite(S: String);
      procedure StoreModemSetup;

Implementation
uses xTime, Advance, Objects, DNApp, Views, Terminal, Messages, StartUp, Commands, RStrings,
     apUART, apFossil, DnUtil, Drivers;

var MaxTime : Word;

Function ReadModem : Boolean;
begin
 if COMport^.CharReady
    then begin
          COMport^.GetChar(ModemChar);
          if ModemAnswer[0]>#254 then Delete(ModemAnswer,1,50);
          ModemAnswer:=ModemAnswer+ModemChar;
          ReadModem:=True;
         end
    else ReadModem:=False;
end;

Function ModemSay(s : ModemString) : Boolean;
var i,j : Integer;
begin
 ModemSay:=False;
 i:=Length(ModemAnswer)-Length(s)+1;j:=1;
 if i<1 then Exit;
 {
 While i<=Length(ModemAnswer) do
       if ModemAnswer[i]<>s[j] then Exit else begin Inc(i);Inc(j);end;
 }
 if Pos(S, ModemAnswer) > 0 then
  begin ModemAnswer := ''; ModemSay:=True; end;
end;

Procedure InitTimeOut(Max : Word);
begin
 StartTime:=memw[0:$46C];
 MaxTime:=Max*18;
end;

Function TimeOut : Boolean;
begin
 TimeOut:=(memw[0:$46C]-StartTime)>MaxTime;
end;

const ReadSetup: Boolean = False;

procedure RDSetup;
 var S: TBufStream;
begin
 if not ReadSetup then
   begin
    S.Init(SourceDir+'DN.MDM', stOpenRead, 1024);
    S.Read(FreeStr[1], 13); FreeStr[0] := #13;
    if (S.Status = stOK) and (FreeStr = 'DN ComSetup'#26#1)
        then S.Read(ModemSetup, SizeOf(modemSetup)+16*7);
    if (S.Status = stOK) and (S.GetSize - S.GetPos >= SizeOf(AdvModemData)) then
       S.Read(AdvModemData, SizeOf(AdvModemData));
    S.Done;
    ReadSetup := True;
   end;
end;

procedure StoreModemSetup;
  var S: TBufStream;
begin
  S.Init(SourceDir+'DN.MDM', stCreate, 1024);
  FreeStr := 'DN ComSetup'#26#1;
  if S.Status = stOK then
    begin
      S.Write(FreeStr[1], 13);
      S.Write(ModemSetup, SizeOf(modemSetup)+16*7);
      S.Write(AdvModemData, SizeOf(AdvModemData));
    end;
  S.Done;
end;

procedure SetupModem;

 var DT, ODT: TModemSetup;
     CP: AbstractPortPtr;

  procedure ReplaceChar(C1, C2: Char; var S: String);
  begin
   While Pos(C1, S)>0 do S[Pos(C1,S)] := C2;
  end;

begin
 if Protocol <> nil then
  begin
     MessageBox(GetString(dlModemNoSetup), nil, mfError + mfOKButton);
     Exit;
  end;
 RDSetup;
 DT := ModemSetup; ODT := DT;
 ReplaceChar(#13, '|', DT.Escape);
 ReplaceChar(#13, '|', DT.OnHook);
 ReplaceChar(#13, '|', DT.Init);
 ReplaceChar(#13, '|', DT.Prefix);
 ReplaceChar(#13, '|', DT.Suffix);
 if ExecResource(dlgSetupModem, DT) <> cmOK then Exit;
 ReplaceChar('|', #13, DT.Escape);
 ReplaceChar('|', #13, DT.OnHook);
 ReplaceChar('|', #13, DT.Init);
 ReplaceChar('|', #13, DT.Prefix);
 ReplaceChar('|', #13, DT.Suffix);
 CP := COMPort; COMPort := nil;
 ModemSetup := DT;
 if (CP <> nil) then
  begin
    Dispose(CP, Done);
    {if (InitModem = moInitFail) then DT := ODT;}
    InitModem;
  end;
 StoreModemSetup;
 if Term <> nil then Term^.Owner^.Redraw;
end;

procedure ModemWrite(S: String);
  var I: Integer;
      DTR, RTS: Boolean;
begin
  for I := 1 to Length(S) do
   case S[I] of
      '~': DelayTics(19);
      '^': begin
             COMPort^.SetDTR(On);
           end;
      'v': begin
             COMPort^.SetDTR(Off);
           end;
      '|': ComPort^.PutChar(#13);
        else ComPort^.PutChar(S[I]);
   end;
end;

Function InitModem;
 const
       bs = 16384;
       fmin = bs div 10;
       fmax = bs - fmin;
 var
     Bauds : array[0..9] of Word;
     B,R: Boolean;
     I,J,K: Word;
     DB, SB: byte;
     PR: ParityType;
     BD : LongInt;
begin
 RDSetup;
 InitModem:=moAlreadyUsed;
 if COMport<>NIL then Exit;
 InitModem:=moInitFail;

 Bauds[0] := 3;
 Bauds[1] := 12;
 Bauds[2] := 24;
 Bauds[3] := 48;
 Bauds[4] := 96;
 Bauds[5] := 144;
 Bauds[6] := 192;
 Bauds[7] := 384;
 Bauds[8] := 576;
 Bauds[9] := 1152;

 BD := Bauds[ModemSetup.Baud];
 BD := BD*100;

 DB := 8-AdvModemData.Data;
 SB := AdvModemData.Stop+1;
 PR := ParityType(AdvModemData.Parity);
 case ModemSetup.UseCustom of
   2: begin
        COMport := New(FossilPortPtr,
                         InitCustom(COMNameType(ModemSetup.Port),BD,PR,DB,SB,
                                    bs, bs, defPortOptions or DefFossilOptionsSimple ));
      end;
   3: begin
        COMport := New(Int14PortPtr, InitCustom(COMNameType(ModemSetup.Port),BD,PR,DB,SB,
                                           bs, bs, defPortOptions ));

      end;
   else begin
          if ModemSetup.UseCustom = 1 then
             begin
               I := StoI(ModemSetup.CustIRQ);
               if (I = 0) or (I > 15) then I := DefIrqNumber[ComNameType(ModemSetup.Port)];
               if I < 8 then J := 8+I else J := $68+I-8;
               K := StoI('$'+ModemSetup.CustPort);
               if K = 0 then K := DefBaseAddr[ComNameType(ModemSetup.Port)];
               ActivateApUART;
               SetUART(COMNameType(ModemSetup.Port), K, I, J);
             end;
          COMport := New(UARTPortPtr, InitCustom(COMNameType(ModemSetup.Port),BD,PR,DB,SB,
                                    bs, bs, defPortOptions ));

          if  (ComPort <> nil) and (ClassifyUART(COMPort^.GetBaseAddr, Off) = U16550A) then
               SetFIFOBuffering(COMPort^.GetBaseAddr, On, 8);
        end;
 end;
 if COMport=NIL then
  begin
     MessageBox(GetString(dlNoModemPort), nil, mfError + mfOKButton);
     Exit;
  end else
       begin
         if AdvModemData.HFlow and 1 <> 0 then
            ComPort^.HWFlowEnable(fmax, fmin, hfUseRTS+hfRequireCTS) else
         if AdvModemData.HFlow and 2 <> 0 then
            ComPort^.HWFlowEnable(fmax, fmin, hfUseDTR+hfRequireDSR) else
              ComPort^.HWFlowDisable;
         if AdvModemData.SFlow and 1 <> 0 then
            ComPort^.SWFlowEnable(fmax, fmin) else
              ComPort^.SWFlowDisable;
       end;
 COMPort^.SetModem(On, On);
 InitModem:=moOk;
 ModemWrite(ModemSetup.Init+#10);
 COMPort^.SetModem(On, On);

end;

Function Dial(Number : String) : Byte;
begin
 Dial:=moInitFail;
 if COMport=NIL then Exit;
 ComPort^.SetModem(On, On);
 ModemWrite(ModemSetup.Prefix+Number+ModemSetup.Suffix);
 Dial:=moOk;
end;

Procedure ModemDone;
begin
 if COMport=NIL then Exit;
 Dispose(COMport,Done);
end;

Procedure HangUp;
var i: Word;
    C: Char;
    B1, B2: Boolean;
begin
 ComPort^.SetModem(Off, Off);
 ComPort^.FlushInBuffer;
 ComPort^.FlushOutBuffer;
 DelayTics(2);
 ComPort^.SetModem(On, On);
 ModemWrite(ModemSetup.Escape);
 i:=memw[$40:$6C];While (memw[$40:$6C]-i)<36 do ;
 ModemWrite(ModemSetup.OnHook);
 {COMPort^.FlushAllBufs;}
 While ComPort^.CharReady do ComPort^.GetChar(C);
 InitTimeOut(HangUpTime);
 repeat ReadModem; until ModemSay(maOK) or TimeOut;
 COMPort^.SetModem(On, On);
 COMPort^.GetModem(B1, B2);
 ModemAnswer:='';
end;


end.

