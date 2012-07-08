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

program DN;

{$M 20480,0,655350}
{$I STDEFINE.INC}
{$I DN.DEF}
{.$DEFINE GRABPalette}

uses
{$IFDEF Debug} DEBUG, {$ENDIF}

     Overlay,
     Overlays,

     Dos,
     Drivers,
     Objects,
     Views,
     Scroller,
     DNApp,
     Menus,
     FlPanelX,
     FlPanel,
     FileCopy,
     Eraser,
     DiskInfo,
     Advance,
     Startup,
     Dialogs,
     Gauges,
     Memory,
     DblWnd,
     Messages,
     HistList,
     FileFind,
     Commands,
     Tree,
     FViewer,
     CmdLine,
     FBB,
     DNStdDlg,
     MemInfo,
     FilesCol,
     UserMenu,
     RStrings,
     ColorSel,
     ColorVGA,
     Colors,
     Microed,
     Macro,
     DNFormat,
     Format,

{$ifdef CdPlayer}
     CdPlayer,
{$endif}

{$IFDEF SpreadSheet}
     Calc,
     CellsCol,
{$ENDIF}

{$IFDEF DEMO}
     Demo,
{$ENDIF}

{$IFDEF DBView}
     DBView,
     DBWatch,
{$ENDIF}

     Reanimator,
     Fixer,
     ArcView,
     HelpKernel,
     HelpFile,
     Validate,

{$IFDEF Modem}
     NavyLink,
     ModemIO,
     Terminal,
     apUART,
     apPort,
{$ENDIF}
     Phones,
     ASCIITab,
     xTime,

{$IFDEF Game}
     Tetris,
{$ENDIF}
     Drives,
     Archiver,
     Idlers,
     Editor,

{$IFDEF PrintManager}
     PrintManager,
{$ENDIF}
     Setups,
     ExtraMemory,
     DNUtil,
     XDblWnd,
     Histries,
     CCalc;

  {!$O DNApp}
  {!$O Drivers}
  {!$O Overlays}
  {!$O ExtraMemory}
  {!$O Startup}

{$IFDEF FULLOVR}
  {$O RStrings}
  {$O UniWin}
  {$O FlPanelX}
  {$O FlPanel}
  {$O XDBlWnd}
  {$O FStorage}
  {$O Menus}
  {$O Drives}
  {$O DblWnd}
  {$O CmdLine}
  {$O Gauge}
  {$O Gauges}
{$ENDIF}

  {$O HistList}
  {$O Histries}
  {$O FlTools}
  {$O Scroller}
  {$O DiskTool}
  {$O HideView}
  {$O Setups}
  {$O FViewer}
  {$O MicroEd}
  {$O Macro}
  {$O FileCopy}
  {$O DiskInfo}
  {$O Eraser}
  {$O FileFind}
  {$O Dialogs}
  {$O DNUtil}
  {$O Editor}
  {$O DNFormat}
  {$O Format}
  {$O Par}
  {$O CCalc}
  {$O Reanimator}
  {$O ArcView}
  {$O Archiver}
  {$O ASCIITab}
  {$O Phones}
  {$O DNStdDlg}
  {$O SBlocks}
  {$O FBB}
  {$O Tree}
  {$O Messages}
  {$O MemInfo}
  {$O ColorSel}
  {$O Colors}
  {$O UserMenu}
  {$O Validate}
  {$O HelpFile}
  {$O HelpKernel}
  {$O Idlers}
  {$O UUCode}
  {$O Arvid}
  {$O ColorVGA}
  {$O WinClp}
  {$O DiskImg}


{$IFDEF Game}
  {$O Tetris}
{$ENDIF}
{$IFDEF PrintManager}
  {$O PrintManager}
{$ENDIF}
{$IFDEF DiskEdit}
  {$O Fixer}
  {$O SWE}
{$ENDIF}
{$IFDEF CDPLAYER}
  {$O CdPlayer}
  {$O CdUtil}
{$ENDIF}
{$IFDEF DBView}
  {$O DBView}
  {$O DBWatch}
{$ENDIF}
{$IFDEF SpreadSheet}
  {$O Calc}
  {$O CellsCol}
{$ENDIF}
{$IFDEF Modem}
  {$O ApFossil}
  {$O ApInt14}
  {$O ApMisc}
  {$O ModemIO}
  {$O Terminal}
  {$O ScrollBk}
  {$O OOCOM}
  {$O OOAbsPcl}
  {$O OOXmodem}
  {$O OOYmodem}
  {$O OOZmodem}
  {$O OOKermit}
  {$O NavyLink}
  {$O LinkUtil}
  {$O ComLnk}
{$ENDIF}
{$IFDEF DEMO}
  {$O DEMO}
{$ENDIF}

{$I Version.Inc}

type
   MyApp = object (TDNApplication)
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure GetEvent(var Event: TEvent); virtual;
      procedure Idle; virtual;
   end;

var
  MyApplication: MyApp;

procedure InvalidateTempDir;
var
  I: Integer;
begin
  TempDir := SystemData.Temp;
  I := PosChar('%', TempDir);
  if I > 0 then
   begin
     Delete(TempDir, 1, I);
     I := PosChar('%', TempDir);
     if I > 0 then Delete(TempDir, I, 255);
     if TempDir <> '' then TempDir := GetEnv(TempDir);
   end;
  if TempDir = '' then TempDir := GetEnv('TEMP');
  if TempDir = '' then TempDir := GetEnv('TMP');
  if TempDir = '' then TempDir := SourceDir;
  if (TempDir <> '') and (TempDir[Byte(TempDir[0])] <> '\') then TempDir := TempDir + '\';
  UpStr(TempDir);
end;

procedure UpdateConfig;
var
  OldSecurity: Boolean;
  R: TRect;
begin
  InvalidateTempDir;
  OldSecurity := Security;
  smSVGALo := StoI(SystemData.Mode1);
  smSVGAHi := StoI(SystemData.Mode2);
  if smSVGALo = 0 then smSVGALo := StartupMode;
  if smSVGAHi = 0 then smSVGAHi := StartupMode;
  SystemData.Mode1 := ItoS(smSVGALo);
  SystemData.Mode2 := ItoS(smSVGAHi);
  case SaversData.Time of
   0: SkyDelay := 255;
   1: SkyDelay := 1;
   2: SkyDelay := 2;
   3: SkyDelay := 5;
   4: SkyDelay := 10;
  end;

  {TempDir := SystemData.Temp;}

  MouseReverse := MouseData.Options and omsReverse <> 0;
  Security := SystemData.Options and ossShowHidden = 0;

  if OldSecurity xor Security then
   begin
    if Application <> nil then GlobalMessage(evCommand, cmPanelReread, nil);
   end;

  SetBlink(CurrentBlink);
  UpcaseInit := Off;
end;

PROCEDURE DoStartup;
var
  SavePos, SPos1: LongInt;


  function ReadConfig: LongInt;
  var
    S: TBufStream;
    Chk: String;
    ID,L: Word;

    procedure SRead(var Buf);
    begin
      S.Read(Buf, L);
    end;

  begin
    ReadConfig := -1;
    SPos1 := -1;
    S.Init(SourceDir+'DN'+GetEnv('DNCFG')+'.CFG', stOpenRead, 16384);
    if ( S.Status <> stOK ) or ( S.GetSize < SizeOf( ConfigSign )) then begin S.Done; Exit; end;
    S.Read( Chk[ 1 ], ConfigSignLen );
    Chk[ 0 ] := Char( ConfigSignLen );
    If Chk <> CConfigSign then begin S.Done; Exit end;
    while S.GetPos < S.GetSize do
      begin
        S.Status := stOK;
        S.Read(ID, SizeOf(Word));
        S.Read(L, SizeOf(Word));
        case ID of
          0: Break;
             cfgSystemData: SRead(SystemData);
            cfgStartupData: SRead(StartupData);
              cfgMouseData: SRead(MouseData);
          cfgInterfaceData: SRead(InterfaceData);
             cfgSaversData: S.Read(SaversData.Time, SizeOf(SaversData)-SizeOf(SaversData.Selected)*2);
           cfgSystemColors: begin
                              S.Read(SystemColors, SizeOf(SystemColors));
                            end;
          cfgPanelDefaults: SRead(PanelDefaults);
         cfgEditorDefaults: SRead(EditorDefaults);
           cfgFFindOptions: SRead(FileFind.FindRec.Options);
              cfgTetrisRec: S.Read(TetrisRec, SizeOf(TetrisRec));
           cfgPrinterSetup: S.Read(RPrinterSetup, SizeOf(RPrinterSetup));
            cfgCustomMasks: begin
                              S.Read(CustomMask1, SizeOf(CustomMask1));
                              S.Read(CustomMask2, SizeOf(CustomMask1));
                              S.Read(CustomMask3, SizeOf(CustomMask1));
                              S.Read(CustomMask4, SizeOf(CustomMask1));
                              S.Read(CustomMask5, SizeOf(CustomMask1));
                            end;
         cfgColumnDefaults: SRead(ColumnsDefaults);
          cfgDriveInfoData: SRead(DriveInfoData);
            cfgCountryInfo: S.Read(CountryInfo, SizeOf(CountryInfo));
               cfgConfirms: S.Read(Confirms, SizeOf(Confirms));
                cfgUUEData: SRead(UUDecodeOptions);
           cfgMakeListFile: SRead(MakeListFileOptions);
           cfgTermDefaults: S.Read(TerminalDefaults, SizeOf(TerminalDefaults));
                cfgFMSetup: S.Read(Startup.FMSetup, SizeOf(Startup.FMSetup));
               cfgCDParams: SRead(CDPlace);
                  cfgBlink: begin
                              S.Read(CurrentBlink, SizeOf(CurrentBlink));
                              SetBlink(CurrentBlink);
                            end;
             cfgVGApalette: begin
                              SRead(VGA_Palette);
                              if (StartupData.Load and osuResetPalette <> 0) and VGASystem then
                                  SetPalette(VGA_Palette);
                            end;
           cfgDirsToChange: begin SPos1 := S.GetPos; S.Seek(S.GetPos+L); end;
                 cfgSavers: begin ReadConfig := S.GetPos; S.Seek(S.GetPos+L); end;
            else S.Seek(S.GetPos+L);
        end;
      end;

    S.Done;
  end;

  procedure ReadSavers( Pos: LongInt );
  var
    S: TBufStream;
    Chk: String;
    I: Integer;
  begin
    I := FindParam('/C');
    if I = 0 then Chk := SourceDir + 'DN' + GetEnv('DNCFG') + '.CFG'
      else begin
             Chk := Copy(ParamStr(I), 3, 255);
             if PosChar('\', Chk) = 0 then Insert(SourceDir, Chk, 1);
           end;
    S.Init(Chk, stOpenRead, 16384);
    if ( S.Status <> stOK ) or ( S.GetSize < SizeOf( ConfigSign )) then begin S.Done; Exit; end;
    S.Read( Chk[ 1 ], ConfigSignLen );
    Chk[ 0 ] := Char( ConfigSignLen );
    If Chk <> CConfigSign then begin S.Done; Exit end;
    S.Seek( SavePos );
    If S.Status = 0 then SaversData.Selected.List := PTextCollection(S.Get);
    if SPos1 > 0 then
      begin
        S.Seek(SPos1);
        for I := 0 to 8 do
           DirsToChange[I] := S.ReadStr;
      end;
    S.Done;
  end;

  procedure SetOverlay;
  var S: String;
      I: LongInt;
  begin
    InitExtraMem;
    SwpDir := GetEnv('DNSWP');
    if SwpDir = '' then
      begin
        I := FindParam('/S');
        if I > 0 then SwpDir := Copy(ParamStr(I), 3, 255);
      end;
    if SwpDir = '' then SwpDir := TempDir;
    if SwpDir[Length(SwpDir)] <> '\' then SwpDir := SwpDir+'\'; ClrIO;
    UpStr(SwpDir);
    if RunFirst then EraseFile(SwpDir+'DN'+ItoS(DNNumber)+'.SWP');
    S := GetEnv('DNOVR');
    if S = '' then S := StartupDir + 'DN.OVR'
              else S := MakeNormName(S, 'DN.OVR');
    OvrFileMode := $40;
    InitOverlay(S);
  end;

begin
  RegisterType( RTextCollection );
  SavePos := ReadConfig;

  if SavePos >= 0 then UpdateConfig else InvalidateTempDir;
  StdMouse := MouseData.Options and omsCursor <> 0;
  if OS210 then Executables := Executables + 'cmd'#0;
  if Chk4Dos then Executables := Executables + 'btm'#0;
  RunMenu := (StartupData.Load and osuAutoMenu <> 0);
  SetOverlay;
  EraseFile(SwpDir+'$DN'+ItoS(DNNumber)+'$.BAT');
  EraseFile(SwpDir+'$DN'+ItoS(DNNumber)+'$.MNU');
  EraseFile(SwpDir+'$$$DN$$.LST');
  EraseFile(SwpDir+'$$$DN$$$.LST');
  If SavePos >= 0 then ReadSavers( SavePos );
end;

procedure MyApp.GetEvent;
 var W: Word;
     WW: Word;
     PM: PKeyMacros;

const
     MacroPlaying: Boolean = False;
     MacroKey: Integer = 0;
     CurrentMacro: PKeyMacros = nil;

begin
 inherited GetEvent(Event);
 if MacroPlaying and ((Event.What = evKeyDown) or (Event.What = evNothing)) then
                      begin
                        Event.What := evKeyDown;
                        Event.KeyCode := CurrentMacro^.Keys^[MacroKey];
                        Inc(MacroKey);
                        MacroPlaying := MacroKey < CurrentMacro^.Count;
                      end;
 case Event.What of
  evNothing: if (NeedLocated > 0) and (GetSTime - NeedLocated > 30) then
               begin
                 NeedLocated := 0;
                 Message(Desktop, evCommand, cmDoSendLocated, nil);
               end;
  evKeyDown:
       begin
           if (Event.KeyCode = kbAltQ) and Desktop^.GetState(sfFocused) then begin OpenSmartpad; ClearEvent(Event) end;
           if Event.KeyCode = kbNoKey then begin Event.What := evNothing; Exit end else
             if (not MacroPlaying) and (Event.KeyCode = kbShiftIns) and (ShiftState and kbAltShift <> 0) then
                 begin Event.What := evNothing; ScreenGrabber(Off); Exit end;
           if (Event.ScanCode >= Hi(kbCtrlF1)) and (Event.ScanCode <= Hi(kbCtrlF10))
             and (Pointer(Current) = Pointer(Desktop)) and (ShiftState and 3 <> 0) then
             begin
               if QuickExecExternal(Event.ScanCode - Hi(kbCtrlF1) + 1) then
                begin
                  Event.What := evCommand;
                  Event.Command := cmExecString;
                  QuickExecExternalStr := FreeStr;
                  Event.InfoPtr := @QuickExecExternalStr;
                end else Event.What := evNothing;
               Exit;
             end;
           if (ShiftState and 7 <> 0) and ((ShiftState and 4 = 0) or (ShiftState and 3 = 0)) and
              (Event.ScanCode >= kbAlt1 shr 8) and (Event.ScanCode <= kbAlt9 shr 8) then
             begin
              WW := Event.ScanCode - (kbAlt1 shr 8);
              if ShiftState and 3 <> 0 then
                begin
                 if KeyMacroses = nil then
                                        begin
                                         New(KeyMacroses, Init(10,10));
                                         for W := 1 to 10 do KeyMacroses^.Insert(nil);
                                        end;
                 if MacroRecord then begin Macrorecord := False; ClearEvent(Event); Exit; end;
                 MacroRecord := True;
                 KeyMacroses^.AtFree(WW);
                 New(PM, Init);
                 KeyMacroses^.AtInsert(WW,PM);
                 CurrentMacro := PM;
                end else if KeyMacroses <> nil then
                begin
                 if MacroRecord then begin Macrorecord := False; ClearEvent(Event); Exit; end;
                 CurrentMacro := KeyMacroses^.At(WW);
                 MacroPlaying := CurrentMacro <> nil;
                 MacroKey := 0;
                end;
               ClearEvent(Event);
             end;
           if (Event.KeyCode = kbAlt0) and (ShiftState and 3 <> 0) then
              begin Event.What := evCommand; Event.Command := cmListOfDirs; Exit; end;
           if MsgActive then
           if Event.KeyCode = kbLeft then Event.KeyCode := kbShiftTab
             else if Event.KeyCode = kbRight then Event.KeyCode := kbTab;
           if (Event.What = evKeyDown) then
            begin
              if MacroRecord and (CurrentMacro <> nil) then
                  CurrentMacro^.PutKey(Event.KeyCode);
              if (StatusLine <> nil) and not SkyVisible then
                 StatusLine^.HandleEvent(Event);
            end;
       end;
 end;
 case Event.What of
     evCommand:
       case Event.Command of
              cmTree,
              cmGetTeam,
              cmHelp,
              cmClearData,
              cmSearchAdvance,
              cmAdvancePortSetup,
              cmNavyLinkSetup,
              cmQuit : HandleCommand(Event);
       end;
end;
end;

const
  opUnk  = 0;  { Unk     }
  opDOS  = 1;  { DOS     }
  opOS2  = 2;  { OS/2    }
  opWin  = 3;  { Wind0ze }
  opDV   = 4;  { DV      }

  ops : byte = opUnk;

procedure CheckOS; assembler;
{ Currently Supports DesqView, Microsoft Windows and IBM's OS/2 }
asm
  mov   ops, opDOS   { Default DOS }
  mov   ah, 30h      { AH = 30h }
  int   21h          { dos version }
  cmp   al, 14h
  jae   @IBMOS2      { Jump if >= to 20 }

  mov   ax, 2B01h
  mov   cx, 4445h
  mov   dx, 5351h
  int   21h           { Desqview Installed? }
  cmp   al, 255
  jne   @DesqView     { Jump if AL <> 255 }

  mov   ax, 160Ah
  int   2Fh           { Windows Install?}
  cmp   ax, 0h
  je    @Windows      { If = Jump to Windows }

  jmp   @Finish       { Nothing found, go to the end }

@IBMOS2:
  mov   ops, opOS2    { Set OS Value }
  jmp   @Finish

@DesqView:
  mov   ops, opDV     { Set OS Value }
  jmp   @Finish

@Windows:
  mov   ops, opWin    { Set OS Value }
  jmp   @Finish

@FINISH:
end; { checkos }

procedure GiveSlice; assembler; {Gives up remainder of clock cycle }
asm                             { under dos, windows, os/2 }
  cmp   ops, opUnk
  jne   @Chk
  call  CheckOS

@Chk:
  cmp   ops, opDOS   { Compare to DOS }
  je    @MSDOS
  cmp   ops, opDV    { Compare to Desqview }
  je    @DESQView
  cmp   ops, opWin   { Compare to Windows }
  je    @VM
  cmp   ops, opOS2   { Compare OS/2 }
  je    @VM

  jmp   @NONE        { None found, Jump to End }

@MSDOS:
  int   28h          { Interupt 28h }
  jmp   @NONE        { Jump to the end }

@DESQView:
  mov   ax,1000h     { AX = 1000h }
  int   15h          { Call Interupt 15h }
  jmp   @NONE        { Jump to the end }

@VM:
  mov   ax,1680h     { AX = 1680h }
  int   2Fh          { Call Interupt 2Fh for Win-OS/2 TimeSlice }

@NONE:

end; {GiveSlice}


procedure TinySlice;
begin
 if StartupData.Slice and osuInt28 <> 0 then
 asm
  cmp DESQDetected, 0
  je  @@1
  mov ax, $1000
  int 15h
@@1:
  int 28h
 end;
end;

var
     L_Tmr: TEventTimer;


procedure MyApp.Idle;

 procedure L_On; begin NewTimer(L_Tmr, 2) end;
 procedure NLS;  begin NewTimer(LSliceTimer, 3) end;

var
  Event: TEvent;

begin

  TinySlice;

  if StartupData.Slice and osuSleep <> 0 then
  case LSliceCnt of

    -1 : if TimerExpired(L_Tmr) then SliceAwake else
         begin
           NewTimer(L_Tmr, 18*60);
           repeat
             GiveSlice;
             TinySlice;
             GetMouseEvent(Event);
             if Event.What = evNothing then GetKeyEvent(Event);
             if Event.What <> evNothing then
             begin
               Inc(EventsLen);
               EventQueue[EventsLen] := Event;
               Break;
             end;
           until TimerExpired(L_Tmr);
           L_On;
         end;

    -2 : if TimerExpired(LSliceTimer) then begin NLS; LSliceCnt := 0 end;
    -3 : begin NewTimerSecs(LSliceTimer, 5); LSliceCnt := 0 end;

    else if TimerExpired(LSliceTimer) then
         begin
           if LSliceCnt > 100 then
           begin
             LSliceCnt := -1;
             L_On;
           end else LSLiceCnt := 0;
           NLS;
         end else Inc(LSliceCnt);
  end;

  {$IFDEF DEMO}
  if Demos <> nil then
    begin
      Demos^.Update;
      if Demos = nil then Dec(SkyEnabled);
    end;
  {$ENDIF}


  {  Put IdleEvt after IdleClick Expired  }
    with IdleEvt do
   if What<>evNothing then if TimerExpired(IdleClick) then
       begin
        PutEvent(IdleEvt);
        if What = evCommand then
         begin
           What := evBroadCast ;
           PutEvent(IdleEvt);
         end;
        ClearEvent(IdleEvt);
       end;

 if not SkyVisible then
 begin
   TApplication.Idle;
 end;

 UpdateAll(On);

 if CtrlWas then
   if mem[$40:$17] and kbCtrlShift = 0 then
     begin
       CtrlWas := Off;
       {if DelSpaces(CmdLine.Str) = '' then}
         Message(@Self, evCommand, cmTouchFile, nil);
     end;

  IdleWas := True;

end;

procedure MyApp.HandleEvent;

 procedure UpView(P: PView);
 begin
   P^.MakeFirst;
   Clock^.MakeFirst;
 end;

begin
 if Event.What = evMouseDown then
  if (Event.Where.Y = 0) and (Event.Buttons and mbLeftButton <> 0) then
                   begin
                     MenuBar^.HandleEvent(Event);
                   end;
 if Event.What <> evNothing then inherited HandleEvent(Event);
 if CheckingRegister > 0 then NotRegister := True;
 case Event.What of
   evCommand : case Event.Command of
     cmUpdateConfig: begin UpdateConfig; WriteConfig; end;
     cmMenuOn: if (Event.InfoPtr = MenuBar) then
                 UpView(MenuBar);
     cmMenuOff: if (Event.InfoPtr = MenuBar) then
                 UpView(Desktop);
     cmEnvEdit: {if LoaderSeg <> 0 then }EditDosEvironment(Ptr(PWordArray(Ptr(LoaderSeg, 0))^[$2C div 2], 0));
     else
     {
     cmCalculator,
     cmPutInClipboard,
     cmGetFromClipboard,
     cmListOfDirs,
     cmFormatDisk,
     cmFilePrint,
     cmRSearchAdvance,
     cmSetupPrinter,
     cmOpenSmartpad,
     cmExecGrabber,
     cmTerminalDefaults,
     cmSetupConfirmation,
     cmCountrySetup,
     cmColumnDefaults,
     cmInsertLink, cmDiskCopy,
     cmHighlightGroups,
     cmDBFView,
     cmNewTable,
     cmSheetLoad,
     cmWKZView,
     cmPhoneBook,
     cmUndial,
     cmSetupModem,
     cmTerminal,
     cmHangUp,
     cmDiskEdit,
     cmTextView,
     cmHexView,
     cmSystemSetup,
     cmInterfaceSetup,
     cmStartup,
     cmSetupMouse,
     cmSaversSetup,
     cmReanimator,
     cmSetVolumeLabel,
     cmXEditFile,
     cmWindowManager,
     cmUserMenu,
     cmGlobalUserMenu,
     cmReadArchive,
     cmScreenRest,
     cmASCIITable,
     cmAbout,
     cmRefresh,
     cmClearDesktop,
     cmFileView,
     cmFileEdit,
     cmIntFileView,
     cmIntFileEdit,
     cmExtFileEdit,
     cmMenuFileEdit,
     cmLocalMenuFileEdit,
     cmExternalViewers,
     cmExternalEditors,
     cmShowUserScreen,
     cmRenameKeyFile,
     cmPirateKey,
     cmRFormat,
     cmCreatePanel,
     cmCreateTree,
     cmFindFile,
     cmFormatDisk,
     cmSystemInfo,
     cmMemoryInfo,
     cmShowOutput,
     cmHistoryList,
     cmLoadDesk,
     cmSaveDesk,
     cmExecFile,
     cmExecString,
     cmExecCommandLine,
     cmChangeColors,
     cmChangeUserMode1,
     cmChangeUserMode2,
     cmKnormal..cmLoadKey,
     cmCancelIdleClick,
     cmHideShowTools,
     cmShowAbout,
     cmShowRegAbout,
     cmChangeMode,
     cmLoadColors,
     cmSetupArchive,
     cmConfigARJ..cmConfigLastArchive,
     cmFMDefaults,
     cmFMSetup,
     cmEditorDefaults,
     cmStoreColors,
     cmPlayCD,
     cmEditHGL,
     cmExecuteDOScmd,
     cmFirstTimePanel,
     cmGame:} HandleCommand(Event);
   end;
 end;
end;

procedure CrLf; assembler;
asm
  MOV  DL,0DH
  MOV  AH,2
  INT  21H
  MOV  DL,0AH
  MOV  AH,2
  INT  21H
end;

var
  ShiftRec: record ScrH, CurY: Byte end absolute FreeStr; { just to reduce DS }


{$IFDEF GRABPalette}
procedure GrabPalette;
  var F: Text;
      I: Integer;
begin
  Assign(F, 'Pallete.PAS');
  Rewrite(F);
  Write(F, '    ');
  FreeStr := Application^.GetPalette^;
  for I := 1 to Length(FreeStr) do
    begin
      Write(F, '#$', Hex2(Byte(FreeStr[I])));
      if I mod 16 = 0 then WriteLn(F, ' + ');
    end;
  WriteLn(F, ';');
  Close(F);
end;
{$ENDIF}
begin
 if memAvail < 100000 then begin
    WriteLn(#10#13'Not enough memory for Navigator.');
    WriteLn(      'Please check if 400K memory is available');
    Halt(203);
 end;
 Randomize;
 LoaderSeg := 0;
 LSliceCnt := -3;
 asm
  mov ax, $9900
  int 2Fh
  cmp bx, 'DN'
  jne @@1
  mov DNNumber, Al
  mov RunFirst, Ah
  xor ax, ax
  mov es, ax
  mov ax, $9901
  int 2Fh
  mov ax, es
  mov LoaderSeg, ax
  mov CommandOfs, bx
 @@1:
  mov ah,1
  xor bl,bl
  mov cx, $0607
  push bp
  int 10h
  pop bp
  mov ax, $9905
  xor dx, dx
  xor cx, cx
  push bp
  int  2Fh
  mov  word ptr DDTimer, dx
  mov  word ptr DDTimer+2, cx
  pop  bp
 end;


 if DDTimer > 0 then DDTimer := Get100s-DDTimer;

 TempBounds.Assign(0,0,0,0);

 DoStartUp;

 asm
   MOV  AH, 03 { Get cursor position }
   MOV  BX, 0  { DL - X }
   INT  10H    { DH - Y }
   OR   DL,DL
   JE   @Pass
   CALL CrLf   { if WhereX <> 0 then WriteLn }
   MOV  AH, 03
   MOV  BX, 0
   INT  10H
 @Pass:
   MOV  ShiftRec.CurY,DH
   CALL GetCrtMode { DL - ScreenHeight }
   MOV  ShiftRec.ScrH,DL
 end;

 with ShiftRec do begin
   If ( CurY = ScrH ) and ( InterfaceData.Options and ouiHideStatus = 0 ) then begin
     CrLf;
     asm
       XOR  DX,DX
       MOV  DH,ShiftRec.CurY
       DEC  DH
       MOV  AH,2
       XOR  BX,BX
       INT  10H
     end
   end
 end;


{$IFDEF DEBUG} DEBUG.Flash( $4E64 ); {$ENDIF}
 SetBlink(CurrentBlink);

 NoSound;
 MyApplication.Init;

 if RunFirst then
   begin
     if (StartupData.Load and osuKillHistory <> 0) then ClearHistories;
   end;

{$IFDEF DEBUG} DEBUG.Flash( $1F64 ); {$ENDIF}

 if not RunFirst then EraseFile(SwpDir+'DN'+ItoS(DNNumber)+'.SWP');

 If RunFirst then
   begin
    if (Message( @MyApplication, evBroadcast, cmLookForPanels, NIL ) = NIL)
       then Message( @MyApplication, evCommand, cmFirstTimePanel, NIL );

    FreeStr[1] := Char(FindParam('/P'));
    if (FreeStr[1] > #0) then LoadPalFromFile(Copy(ParamStr(Byte(FreeStr[1])), 3, 255));
   end;

{$IFDEF GRABPalette}
GrabPalette;
{$ENDIF}
 if DDTimer > 0 then ShowTimeInfo;


 MyApplication.Run;
 GlobalMessage(evCommand, cmKillUsed, nil);
 TottalExit := On;
 MyApplication.Done;
END.

