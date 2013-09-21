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

UNIT
  Startup;

INTERFACE

USES
  Objects,
  Dos,
  Commands,
  Advance,
  ObjType;

PROCEDURE FatalError( const S: String );

CONST
  FBRPBSignature: Array[1..5] of Char = 'FBRPB';
  CConfigSign = 'DN2 Configuration'#26#1#36;
  ConfigSignLen = Length( CConfigSign );
  ConfigSign: String[ ConfigSignLen ] = CConfigSign;
  CDskSign = 'DN2 Desktop'#26#1#40;
  DskSignLen = Length( CDskSign );
  DskSign: String[ DskSignLen ] = CDskSign;
  Security: Boolean = True;
  ConfigModified: Boolean = Off;
  DateMode: Byte = 0;
  SkyDelay: Byte = 1;


TYPE
  PTextCollection =^TTextCollection;
  TTextCollection = Object( TCollection )
    procedure FreeItem( Item: Pointer ); virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
  end;

  TListBoxRec = record List: PCollection; Focus: Integer end;
  TTextListBoxRec = record List: PTextCollection; Focus: Integer end;

  TSystemData = record
    Options: Word;
    Mode1: String[5];
    Mode2: String[5];
    Temp: PathStr;
    Drives: Array [ 'A'..'Z' ] of Byte;
  end;

  TMouseData = record
    HSense: Word;
    VSense: Word;
    Options: Word;
  end;

  TSaversData = record
    Selected: TTextListBoxRec;
    Available: TTextListBoxRec;
    Time: Word;
    Mouse: Boolean;
    _: Byte;
  end;

  TInterfaceData = record
    Options: Word;
  end;

  TPanelDefaultsData = record
    Sort: Word;
    Show: Word;
    LeftPanel: Word;
  end;

  TFMSetup = record
    Options: Word;
    Show: Word;
    Quick: Word;
    TagChar: String[1];
    DIZ: String;
  end;

  TEditorDefaultsData = record
    EdOpt: Word;
    ViOpt: Word;
    LM,
    RM,
    PM: String[3];
    NewLine: Word;
    TabSize: String[3];
  end;

  TTerminalDefaults = record
    Emulation: Word;
    Options: Word;
  end;

  TStartupData = record
    Load, Unload, Slice, OvrSize: Word;
  end;

  TUUEncodeData = record
    Name: String[79];
    Prefix, Checksum: Word;
    NLines: String[4];
    Format : Word ;
  end;


var TempBounds: TRect;


CONST
  UUDecodeOptions: Word = 3;
  MakeListFileOptions: Word = 0;

  UUEncodeData : TUUEncodeData =
    ( Name:'';
    Prefix: ckFileTime+ckStatistic;
    Checksum: ckStd;
    NLines: '100';
    Format: 0 );

  DriveInfoData: Word = $FFFF;

  StartupData: TStartupData =
    ( Load: osuRestoreScrMode + osuOverlayXMS + osuOverlayEMS;
      Unload: 0;
      Slice: 0;
      OvrSize: 95
    );

  Confirms: Word = cfSingleErase + cfMultiErase + cfEraseReadonly +
                   cfEraseSubdir + cfExitConfirm;

  TerminalDefaults: TTerminalDefaults = (Emulation:emANSIBBS;Options:toCtrlCLS+toAutoZModem);

  CustomMask1: String = #0'pas'#0'asm'#0'inc'#0'c'#0'cpp'#0;
  CustomMask2: String = #0'.'#0'doc'#0'txt'#0'ctl'#0'diz'#0'ini'#0;
  CustomMask3: String = #0'dbf'#0'wkz'#0'wks'#0'123'#0'wk1';
  CustomMask4: String = #0'tmp'#0'$$$'#0'bak'#0;
  CustomMask5: String = #0'pcx'#0'bmp'#0'pic'#0'gif'#0'rle'#0'ico'#0'jpg'#0;

  InterfaceData: TInterfaceData = (
    Options: ouiClock +
             ouiHideMenu
  );

  PanelDefaults: TPanelDefaultsData = (
    Sort:  psmExtension;
    Show:  fmiCurrent +
           fmiSelected +
           fmiHiliteFiles +
           fmiFree +
           fmiExeFirst +
           fmiArchivesFirst;
    LeftPanel: fdoDriveDrive
  );

  FMSetup: TFMSetup =
    ( Options: fmoAutoChangeDir +
               fmoEnterArchives +
               fmoSpaceToggle +
               fmoDelErase +
               fmoUseArrows;
      Show: fmsColumnTitles +
            fmsDriveLine +
            fmsTagChar +
            fmsDivider;
      Quick: pqsAlt;
      TagChar: 'û';
      DIZ: 'descript.ion;files.bbs'
    );

  EditorDefaults: TEditorDefaultsData = (
    EdOpt: ebfBSU +
           ebfAId +
           ebfPBl +
           ebfEMS +
           ebfXMS;
    ViOpt: 0;
    LM: '0';
    RM: '78';
    PM: '5';
    NewLine: 0;
    TabSize: '8'
  );

  MouseData: TMouseData = (
    HSense: 22;
    VSense: 22;
    Options: omsCursor
  );

  SaversData: TSaversData = (
    Selected: ( List: NIL; Focus: 0 );
    Available: ( List: NIL; Focus: 0 );
    Time: 1;
    Mouse: False
  );

  SystemData: TSystemData = (
    Options: ossEditor + ossViewer + ossAdvCopy + ossFlushDsk;
    Mode1: '256';
    Mode2: '265';
    Temp: '';
    Drives: (
      ossDirectAccess,
      ossDirectAccess,
      ossTree,
      ossTree,
      ossTree,
      0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    )
  );

  ColumnsDefaults: record
    DiskDrive,
    FindDrive,
    Temp,
    Arc,
    Arvid: Word
  end = (
    DiskDrive:0;
    FindDrive:0;
    Temp:0;
    Arc: 0;
    Arvid: 0
  );

  RPrinterSetup: record Device: Word; InitPrinter, AfterFile: String[80]; end =
    (Device: 0; InitPrinter:''; AfterFile:#12);

  TetrisRec : record
    L : Word; S : Word; P: Word;
  end = (L:4; S:0; P:0);

  RTextCollection: TStreamRec = (
    ObjType: otTextCollection;
    VmtLink: Ofs(TypeOf(TTextCollection)^);
    Load:    @TTextCollection.Load;
    Store:   @TTextCollection.Store);

  rfDescriptions = $0002;
  rfPhoneBook    = $0004;
  rfDiskCopy     = $0008;
  rfFormat       = $0010;
  rfArchives     = $0020;
  rfAdvFind      = $0040;

  Registered: Word = 0;

IMPLEMENTATION

PROCEDURE TTextCollection.FreeItem;
begin
  DisposeStr( Item );
end;

PROCEDURE TTextCollection.PutItem;
begin
  S.WriteStr(Item);
end;

FUNCTION TTextCollection.GetItem;
begin
  GetItem := S.ReadStr
end;

PROCEDURE FatalError;
begin
  InOutRes := 0;
  WriteLn( S );
  Halt( 1 );
end;

begin
  StartupDir:='';
  SourceDir:='';
  TempDir:='';
  TempFile:='';

  SourceDir := FExpand(ParamStr(0));
  while SourceDir[Length(SourceDir)] <> '\' do Dec(SourceDir[0]);
  StartupDir := SourceDir;
  SourceDir := Advance.GetEnv('DN');
  if SourceDir = '' then SourceDir := StartupDir;
  if SourceDir[Length(SourceDir)] <> '\' then AddStr(SourceDir, '\');
  UpStr(SourceDir); UpStr(StartupDir);
END.