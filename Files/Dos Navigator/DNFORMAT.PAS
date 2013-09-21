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

unit DnFormat;

{$DEFINE nFAST}

interface

     uses Objects,Drivers,Dialogs,Views,Advance,Gauge,DnApp,Messages,
          Format, Commands;

type

   ByteRange = set of byte;


   { Used to display status messages }
  PStatusBox = ^TStatusBox;
  TStatusBox = object(TDialog)
    procedure HandleEvent(var Event: TEvent); virtual;
    function Valid(C: Word): Boolean; virtual;
  end;


  TListBoxRec = record
      Data : PCollection ;
      Focused : integer ;
     end;


  DialogData = record

    Drive  : Word;  {Radiobuttons}
    Ftypes : TListboxRec;  {Listbox}
    Field3 : String[11]; {Inputline}
    Field4 : Word;  {Radiobuttons}
    Field5 : Word; {Checkbox}

  end;

  AdvDialogData = record
    A_DriveA     : TListboxRec;  {Listbox}
    A_DriveB     : TListboxRec;  {Listbox}
    A_Boot       : TListboxRec;  {Listbox}
    A_Dirs       : TListboxRec;  {Listbox}
    A_Clust      : TListboxRec;  {Listbox}
    A_Tracks     : TListboxRec;  {Listbox}
    A_Heads      : TListboxRec;  {Listbox}
    A_Sectors    : TListboxRec;  {Listbox}
    A_Track      : TListboxRec;  {Listbox}
    A_intl       : TListboxRec;  {Listbox}
    A_Shft       : TListboxRec;  {Listbox}
    A_HeadShft   : TListboxRec;  {Listbox}
    A_TrackShft  : TListboxRec;  {Listbox}
    A_Ssize      : TListboxRec;  {Listbox}
    end;

   AdvDD = array [1..14] of TlistBoxRec;


  AdvDialogDataR = record
    A_DriveA     ,
    A_DriveB     ,
    A_Boot       ,
    A_Dirs       ,
    A_Clust      ,
    A_Tracks     ,
    A_Heads      ,
    A_Sectors    ,
    A_Track      ,
    A_intl       ,
    A_Shft       ,
    A_HeadShft   ,
    A_TrackShft  ,
    A_Ssize      : Word ;
    end;

    AdvDDR = array [1..14] of Word ;



     PFlTypeRec = ^FlTypeRec;
     FlTypeRec = record
       FlSize           : string[4];
       FlTrk,FlSec,FlSd : byte ;
       FlMedia          : string[5];
     end;

    PMediaCollection = ^TMediaCollection;
    TMediaCollection = object(TStringCollection)
       function Compare(Key1, Key2: Pointer): Integer; virtual;
       Procedure SetCFocus( WhatFind : Integer ; var Focus ) ;
       Procedure SetCData( Focus : Integer ; var Data ) ;
      end;


    PDriveButtons    =^TDriveButtons;
    TDriveButtons    = object(TRadioButtons)
       Procedure  MovedTo(Item: Integer); virtual;
       Procedure  Press(Item: Integer); virtual;
     end;

    PFormatter  =  ^TFormatter;
    TFormatter  =  object(TFMT)

               StdFormatRecord : byte ;
               Directory       : PMediaCollection ;


               procedure   SetData;virtual;
               procedure   SetAdditionalData;virtual;
               procedure   SetStatus( status : integer );virtual;
               procedure   UpdateParams;virtual;
               function    ScanEvents : boolean ;virtual;
               function    FormatDialog( Code : integer ):integer;virtual;

               procedure   AddFile(Name : string); virtual ;
               function    CheckFilesOnDisk : boolean ; virtual ;

             end;


    procedure FormatDisk;


    Function BuildFormatDialog :  Pdialog;
    Function BuildAdvFormatDialog :  Pdialog;

    Procedure BuildFormatDialogData(Item : integer);
    Procedure DisposeFormatDialogData;

    Procedure BuildAdvFormatDialogData;
    Procedure DisposeAdvFormatDialogData;
    Procedure AdvFormatWarning;



    Function  GetDriveCapacity(DrvType : byte): PCollection;


    Function  BuildDrivesCollection :  PCollection;
    Function  BuildSSizeCollection :  PCollection;
    Function  BuildBootsCollection :  PCollection;
    Function  BuildDirsCollection(Dirs: byte) :  PCollection;

    Function  BuildRangeCollection(Range : ByteRange): PCollection;


    procedure ShowStatusBox(Mesg : String);
    procedure KillStatusBox;


Const
     FlTypes = 12;

     FlSizes : array [1..FlTypes] of
      String[5] = (
  ' 160K',' 180K',' 320K',' 360K',' 400K',' 720K',' 800K',' 830K',
  ' 1.2M','1.44M',' 1.6M','2.88M');
     FlTracks : array [1..FlTypes] of byte = (
  40,40,40,40,40,80,80,83,
  80,80,80,80 );
     FlSectors : array [1..FlTypes] of byte = (
   8, 9, 8, 9,10, 9,10,10,
  15,18,20,36 );
     Flsides   : array [1..FlTypes] of byte = (
   1, 1, 2, 2, 2, 2, 2, 2,
   2, 2, 2, 2 );
     FlMedias  : array [1..FlTypes] of string[5] = (
  'SS/SD','SS/SD','DS/DD','DS/DD','DS/DD','DS/DD','DS/DD','DS/DD',
  'HD','HD','HD','ED' );

   FlLimits : array [1..5,1..2] of byte =
     ((1,5),(1,8),(1,10),(6,11),(6,12));  { Type range for drives }

   FlStdType : array [1..5] of byte =
     (3,5,8,4,6);                    { Standart format for drives }


   AStdDrives = 5;

   ATitles : array [0..AStdDrives] of string [10] = (
   'Autodetect','360k  5''25','720k  3''5','1.2M  5''25','1.44M 3''5','2.88M 3''5' );

   ALimits : array [1..AStdDrives,1..2] of byte =
   ((43,10),(83,10),(83,18),(83,22),(83,38)); { MAX tracks,MAX sectors }

    FmtUserDefined : boolean = false ;

var

    FormatDialogData : DialogData ;
    AdvFormatDialogData  : AdvDialogData;
    AdvFormatDialogDataR : AdvDialogDataR;
    AdvFDD  : AdvDD  absolute AdvFormatDialogData ;
    AdvFDDR : AdvDDR absolute AdvFormatDialogDataR ;


    DrivesType : array [0..1] of byte ;

type

    StatusRec  = array[1..4] of Pstring;


const

    MediaListBox :  PListBox  =  Nil ;

    StatusBox    :  PStatusBox = Nil ;
    FormatBox    :  PStatusBox = Nil ;

    F1Msg        :  string = '';
    F2Msg        :  string = '';
    F3Msg        :  string = '';
    F4Msg        :  string = '';

    StatusRecord : StatusRec = (@F1Msg,@F2Msg,@F3Msg,@F4Msg);

   {  (P1Msg : @StatusMsg ;
      P2Msg : @OptionMsg ;
      P3Msg : @ParamsMsg );}
   {
    PStatusMsg   :  PString = @StatusMsg;
    PParamsMsg   :  PString = @ParamsMsg;
   }
implementation
uses RStrings, DNHelp;

{
Function  SStr(a : Longint; n : Byte; Ch : Char) : String;
  var s : String[8];
     i : Byte;
   begin
    Str(a:n,s);
    for i:=1 to n do if s[i]=' ' then s[i]:=Ch;
    SStr:=s;
   end;
}
procedure BuildFormatDialogData(Item : integer);
begin
  if MediaListBox = Nil then Exit;
  if not Item in [0..1] then Exit;
{
  if FormatDialogData.Ftypes.Data <> Nil then begin
    Dispose(FormatDialogData.Ftypes.Data,Done);
    FormatDialogData.Ftypes.Data := nil;
  end;
 }
  FormatDialogData.Ftypes.Data := GetDriveCapacity(DrivesType[Item]);
  FormatDialogData.Ftypes.Focused := FlStdType[DrivesType[Item]];
end;

procedure DisposeFormatDialogData;
begin
  if FormatDialogData.Ftypes.Data <> Nil then
    Dispose(FormatDialogData.Ftypes.Data,Done);
  FormatDialogData.Ftypes.Data := Nil;
end;

Procedure BuildAdvFormatDialogData;

var DrvNum : byte;
    I : integer ;

    begin

         with AdvFormatDialogData do
          begin

            A_DriveA.Focused := 0 ; { DrivesType[0] - 1 ; }
            A_DriveA.Data  :=  BuildDrivesCollection;

            A_DriveB.Focused := 0 ; { DrivesType[1] - 1; }
            A_DriveB.Data  :=  BuildDrivesCollection;

            A_Boot.Focused := 0;
            A_Boot.Data  :=  BuildBootsCollection;

            A_Dirs.Focused := 1;
            A_Dirs.Data  :=  BuildDirsCollection(6);

            A_Clust.Focused := 1;
            A_Clust.Data    :=  BuildRangeCollection([1,2,4,8]);


            DrvNum := FormatDialogData.Drive ;
            if DrvNum>1 then DrvNum := 0;

            A_Tracks.Focused := (ALimits[DrivesType[DrvNum],1])-4;
            A_Tracks.Data  := BuildRangeCollection([1..ALimits[DrivesType[DrvNum],1]]);

            A_Heads.Focused := 1;
            A_Heads.Data  := BuildRangeCollection([1..2]);

            A_Sectors.Focused := (ALimits[DrivesType[DrvNum],2])-1;
            A_Sectors.Data  := BuildRangeCollection([1..ALimits[DrivesType[DrvNum],2]]);

            A_Track.Focused := 0;
            A_Track.Data  := BuildRangeCollection([0..Pred(ALimits[DrivesType[DrvNum],1])]) ;


            A_Intl.Focused := 0;
            A_Intl.Data    := BuildRangeCollection([1..2]);


            A_Shft.Focused := 0 ;
            A_Shft.Data  := BuildRangeCollection([0..Pred(ALimits[DrivesType[DrvNum],2])]);


            A_HeadShft.Focused := 0 ;
            A_HeadShft.Data  := BuildRangeCollection([0..Pred(ALimits[DrivesType[DrvNum],2])]);


            A_TrackShft.Focused := 0 ;
            A_TrackShft.Data  := BuildRangeCollection([0..Pred(ALimits[DrivesType[DrvNum],2])]);

            A_Ssize.Focused := 2;
            A_Ssize.Data    := BuildSSizeCollection;



         end; { with }

         For I := Low(AdvFDD) to High(AdvFDD) do
          if AdvFDD[I].Data <> Nil then

            PMediaCollection(AdvFDD[I].Data)^.SetCFocus
              ( AdvFDDR[I], AdvFDD[I].Focused )
             { Set Focus 2 saved data from AdvFDDR }


      end;


Procedure DisposeAdvFormatDialogData;

var I  : integer ;
    begin

         For I := Low(AdvFDD) to High(AdvFDD) do
          if AdvFDD[I].Data <> Nil then

            begin
             PMediaCollection(AdvFDD[I].Data)^.SetCData
              ( AdvFDD[I].Focused , AdvFDDR[I] );
             { get Data from focused string }

              FreeObject(AdvFDD[i].Data);
            end;


          with AdvFormatdialogDataR do begin

            if FMTUserDefined then

               begin
                 if A_DriveA > 0 then
                 DrivesType[0] := A_DriveA;
                 if A_DriveB > 0 then
                 DrivesType[1] := A_DriveB;
               end;


         end; { with }
      end;



Procedure AdvFormatWarning;
    begin
                             Msg(dlFmtAdvWarning, nil, mfWarning +mfOkbutton);
    end;


Function TMediaCollection.Compare;
    begin
          Compare := -1 ;
    end;

Procedure TMediaCollection.SetCFocus;

var P : pointer ;
    I , J  : integer ;

   Function Find(Item : Pstring):boolean;far;
     begin
        Find := False;
            if Item = nil then Exit;
            Val(Item^,I,J);
            if J > 0 then Exit ;
            Find := I = WhatFind;
     end;
    begin

       P := FirstThat(@Find) ;
       if P = nil then Exit ;
       Integer(Focus) := TCollection.IndexOf( P );
    end;

Procedure TMediaCollection.SetCData;

var  P   :  Pstring;
  I ,  J : Integer ;

    begin
      P := At(Focus);
      if P = nil then Exit;
        Val(P^,I,J) ;
         if  J = 0 then
          Integer(Data) := I
         else
          Integer(Data) := Focus ;
    end;


{ TDriveButtons }
Procedure TDriveButtons.MovedTo;
    begin
       inherited MovedTo(Item);
       FmtUserDefined := False;
       BuildFormatDialogData(item);
       MediaListBox^.SetData(FormatDialogData.Ftypes);
    end;

Procedure TDriveButtons.Press;
    begin
       inherited Press(Item);
       FmtUserDefined := False;
       BuildFormatDialogData(item);
       MediaListBox^.SetData(FormatDialogData.Ftypes);
    end;


{ TStatusBox }
procedure TStatusBox.HandleEvent(var Event:TEvent);
begin
  inherited HandleEvent(Event);
  if (Event.What=evBroadcast) and (Event.Command = cmStatusUpdate) then
    DrawView;
  if (Event.What = evCommand) and (Event.Command = cmGetName) then
    PString(Event.InfoPtr)^ := GetString(dlFmtTitle);
end;

function TStatusBox.Valid;
 var E: TEvent;
begin
  case C of
    cmQuit: Valid := False;
    cmClose: begin
               Valid := False;
               E.What := evCommand;
               E.Command := cmCloseFormat;
               E.InfoPtr := nil;
               PutEvent(E);
             end;
    else Valid := inherited Valid(C);
  end;
end;


{ TFormatter }
procedure   TFormatter.SetStatus;
var Mesg : String[40];
    begin   { Setup Status }

  Mesg := GetStatusString(Status);

  KillStatusBox;
  if Mesg <>'' then
     ShowStatusBox(Mesg);
  {
  Message(FormatBox, evBroadcast, cmStatusUpdate, nil);
  }
    end;

function    TFormatter.ScanEvents;
            { Status changed }
 var Event : Tevent;
    begin

      ScanEvents := False ;

      Application^.GetEvent(Event);
      if Event.What <> evNothing then
      begin
      if (Event.What = evCommand) and (Event.Command = cmCloseFormat) or
         (Event.What = evKeyDown) and (Event.KeyCode = kbESC) and
         ((FormatBox <> nil) and FormatBox^.GetState(sfFocused) or
          (StatusBox <> nil) and StatusBox^.GetState(sfFocused)) then
      begin
          ScanEvents := True;
          Application^.ClearEvent(Event);
      end;

      Application^.HandleEvent(Event);
      end;

    end;

procedure   TFormatter.UpdateParams;
            { Data changed }
 var Mesg : string ;
     DatArr : array[0..5] of longint;
     a,b,c,d  : string [12];
     LA,LB,LC,LD : longint ;
    begin

    asm
      sub ax,ax
      int 28h
    end;


  A := FileSizeStr(I_Size div 1024 {* 1024});

  LB := I_formatted * Boots.Tsect * Boots.Ssize div 1024 ;
  LC := I_bads * Boots.SSize div 1024 ;

  LD := LB - LC - I_SysSpace div 1024 ;
  if  LD < 0 then LD := 0;

  B := FileSizeStr( I_SysSpace div 1024 );  { formatted }
  C := FileSizeStr( LC );  { bads }
  D := FileSizeStr( LD );  { usable }

  DatArr[0]:=Longint(@A);
  DatArr[1]:=Longint(@B);
  DatArr[2]:=Longint(@C);
  DatArr[3]:=Longint(@D);


    FormatStr(Mesg,  GetString(dlFmtMsgStr) , DatArr );

  F3Msg := Mesg ;

  DatArr[1] := I_Track;
  DatArr[2] := I_Head;
  DatArr[0] := Longint(@I_Operation) ;

    FormatStr(Mesg,  ^C'%6s  Cyl %2d  Head %2d ', DatArr );

  F2Msg := Mesg ;


     LA := t_elaps div 18 ;
     LB := LA div 60 ;
     LC := LB div 60 ;

  DatArr[3] := LC mod 60;
  DatArr[4] := LB mod 60;
  DatArr[5] := LA mod 60;

     LA := t_estim div 18 ;
     LB := LA div 60 ;
     LC := LB div 60 ;

  DatArr[0] := LC mod 60;
  DatArr[1] := LB mod 60;
  DatArr[2] := LA mod 60;


    FormatStr(Mesg, GetString(dlFmtTimeStr), DatArr );


  F4Msg := Mesg ;


  Message(FormatBox, evBroadcast, cmStatusUpdate, nil);
  Message(FormatBox, evBroadcast, cmUpdateGauge, Pointer(I_formatted));

  asm
    sub ax,ax
    int 28h
  end

    end;

function    TFormatter.FormatDialog;

var  result : longint ;
     Mesg    : String ;
     A,B,C,D : string [12];
     LA,LB,LC,LD : longint ;
     DatArr : array [1..7] of longint;
     R: TRect;

    begin
         {  Write(' Error Occured... (A)bort or (C)ontinue'); }
         {  Error := acContinue; }

         FormatDialog := fdAbort ;


        case Code of

        fdInsertNewDisk : begin

                           Mesg := '';
                           if StdFormatRecord>0 then
                           Mesg := FlMedias[StdFormatRecord];
                           DatArr[1] := Longint(@Mesg);
                           DatArr[2] := 65+DrvNum ;
                           Result := Msg(dlFmtNewDisk,
                              @DatArr, mfConfirmation+mfOKbutton+mfCancelButton);
                           if Result = cmOk then FormatDialog := FdContinue;

                          end;

        fdUserInterrupt :begin
                           Result := Msg(dlFmtContQuery,
                                 @DatArr, mfQuery+mfYesbutton+mfNoButton);
                           if Result = cmYes then FormatDialog := FdContinue;
                         end;

        fdHardwareError :begin

                           Mesg := GetErrorString(IO_Error);

                           DatArr[1] := Longint(@Mesg);

                           Result :=
                             MessageBox(^C'%s',
                           @DatArr,
                           mfError+mfOkbutton);

                         end;

        fdErrorSysAreas :begin

                           Mesg := GetErrorString(IO_Error);

                           DatArr[1] := Longint(@Mesg);

                             Msg(dlFmtErrorSysAreas,
                                         @DatArr, mfError+mfOkbutton);

                         end;

        fdNoDiskInDrive :begin

                           DatArr[1] := 65 + DrvNum ;

                             Msg(dlFmtNoDisk,
                                         @DatArr, mfError+mfOkbutton);

                         end;

        fdDiskProtected :begin

                           DatArr[1] := 65 + DrvNum ;

                             Msg(dlFmtDiskProtected,
                                                  @DatArr, mfError+mfOkbutton);

                         end;

        fdDiskFormatted :begin


                          LB := I_bads * Boots.SSize  ; { Total Bad }

                          LD := I_Size - I_SysSpace - LB ;      { Usable }
                          if  LD < 0 then LD := 0;

                          A := FileSizeStr( I_Size );  { Total Space }
                          B := FileSizeStr( LB );  { Bad Space }
                          C := FileSizeStr( I_SysSpace );  { formatted }
                          D := FileSizeStr( LD );  { usable }

                          DatArr[1] := 65 + DrvNum ;
                          if DelSpaces(FvLabel)='' then
                             FvLabel := 'NO NAME';
                          DatArr[2]:=Longint(@FvLabel);
                          DatArr[3]:=Longint(@A);
                          DatArr[4]:=Longint(@B);
                          DatArr[5]:=Longint(@C);
                          DatArr[6]:=Longint(@D);
                          DatArr[7]:= I_Serial;

                          FormatDialog := Msg(dlFmtDiskFormatted,@DatArr,mf2YesButton or mfNoButton or mfQuery);
                         end;


        fdNonDosFormat  : Msg(dlFmtNonDos, @DatArr, mfWarning + mfOkbutton );
        fdNQuickFormat  : ErrMsg(dlFmtQuickFormat);
        fdTrack0Bad     : ErrMsg(dlFmtTrack0Bad);
        fdNoSystemFiles : ErrMsg(dlFmtNoSysFiles);
        fdBadInterleave : ErrMsg(dlFmtBadInterleave);


              end;
    end;


Procedure   TFormatter.SetData;
  var P,S,D : byte ;

      MSG    :  string ;
      DatArr :  array [1..6] of longint;

      S1,S2,S3,S4,S5,S6 : string[40] ;

      Sectors : integer ;

    begin

            DrvNum := FormatDialogData.Drive ;

            fMode := FormatDialogData.Field4;
            fOptions := FormatDialogData.Field5;


            if DrvNum>1 then DrvNum := 0;

            DrvSave := DrivesType[DrvNum] ;

            { start record 4 this drive }
            S :=  FlLimits[DrivesType[DrvNum],1] ;

            P :=  FormatDialogData.Ftypes.Focused ;


            S2 := 'MS-DOS';   { System Type }



            if FmtUserDefined and ( P = FlLimits[DrivesType[DrvNum],2] - FlLimits[DrivesType[DrvNum],1] + 1)
               then
                with  AdvFormatDialogDataR do
                   begin
                     Tracks       :=   A_Tracks;
                     Sectors      :=   A_Sectors;
                     Heads        :=   A_Heads;
                     BTrack       :=   A_Track;
                     U_ClustSZ    :=   A_Clust;
                     U_Roots      :=   A_Dirs;
                     Boots.SSize  :=   A_Ssize;
                     Shifts       :=   A_Shft;
                     Shiftt       :=   A_TrackShft;
                     Shifth       :=   A_HeadShft;
                     Interl       :=   A_Intl;

                     P := DrivesType[DrvNum];


                     if Btrack + Tracks > Alimits[P,1] then
                         Tracks := Succ( Alimits[P,1] - Btrack );


                     fMode := fmDosFormat;
                     S3 := FLMode[fmNonDos];   {   Get Format Mode  }

                     if ( Boots.SSize<>512 )
                        or ( Btrack<>0 )
                         then
                           begin
                            fMode := fmNonDos;
                            S2 := 'NON DOS';
                           end ;


                     StdFormatRecord := 0 ;


                   end

              else {  Standart types }
               begin

            S3 := FLMode[fMode];   {   Get Format Mode  }

            D :=  S + P ; { absolute record }

            Tracks  := FlTracks[D];
            Sectors := FlSectors[D];
            Heads   := FlSides[D];

            StdFormatRecord := D ;

                end ;  {  Standart types }


            Boots.Tsect := Sectors;

            Verify := 'y';

            { Interl := 1 ;}     {2/4 for 1600 }

            Shiftt := 0;
            Shifth := 0;

            if fMode = fmFastFormat
               then   Shifts := 4
               else   Shifts := 0;


             if fOptions and foOptimize > 0 then

                 begin
                      ShiftH := 1;
                      if Sectors < 15 then Inc(ShiftH);
                      ShiftT := 1;
                      if Sectors > 10 then Inc(ShiftT);
                 end;

                 {1/3 for 1440 }
            {Shiftt := 0;
            Shifth := 0;}

            { Build Options String }
           { DatArr[0]:= Longint(@FlSizes[D]);}


            { S2 := 'MS-DOS'; }


           if FormatDialogData.Field5 and foSystemDisk >0 then
         {  if s2='' then
            S2 := 'Bootable'
             else s2 := s2 +', bootable';
          } S2 := S2 +' Bootable' ;





          if (FormatDialogData.Field5 and foOptimize >0)
          then
            if ( fMode = fmDosFormat ) then
                S3 := S3 + ' with optimize'  else
                S3 := S3+ #0'             ' ;

          DatArr[1] := Longint ( 65 + DrvNum ); { Drive A: B: }
          DatArr[2] := Longint ( @S2 ) ;        { System }


          S4 :=  FileSizeStr( Longint( Tracks )
           * Sectors * Heads * Boots.Ssize div 1024  )+' K';

          DatArr[3] := Longint ( @S4 ) ;    { Size 1200K }

          DatArr[4] := Longint ( @S3 ) ;    { }


          DatArr[5] := Longint ( @S5 ) ;    { }

          S5 := FormatDialogData.Field3 ;
          FVlabel := '';

          if S5 = '' then
          S5 := 'No volume label' else
            formatStr(FVlabel,'%-11s', DatArr[5]);


          S6 := '';

          if FormatDialogData.Field5 and foMarkTrack >0 then
             S6 := 'Mark full track' ;


          DatArr[6] := Longint ( @S6 ) ;

            formatStr(MSG,

            {            WARNING!!!                 }
            { THOSE LINES IS CHECK-SUM PROTECTED!!! }
            {       DON'T MODIFY THEM !!!           }

             '   Drive : %c:                System type : %s'+
           ^M'    Size : %-8s          Format mode : %s'+
           ^M'  Volume : %-15s       Options : %s' ,
           DatArr);

            { CHECK SUM HERE :#$@%#$%@#$            }

           F1MSG := Msg;


    end;

Procedure   TFormatter.SetAdditionalData;
var St : byte ;

const
    Optimize : string[14] = ' with optimize';

    begin

        St := Pos(#0,F1MSG) ;

        if St = 0 then
          begin
          (*
            asm
               mov ax,3
               int 10h
            end;
            Writeln(^G^G^G^G,'Stefan ! one more BUG detected!');
            Write(' Bug identification in progress.');
              for st:= 1 to 15 do
                begin
                 delay(500);
                 write('.');
                end;
                 writeln;
                 Writeln('Module: DNFORMAT.PAS; Object TFormatter; Method:SetData;Line undefined');
            asm
              xor ax,ax
              int 16h
            end;
              *)
              Exit;

          end;

     move(Optimize[1],F1MSG[ST],14);

    end;


Procedure   TFormatter.AddFile;
    begin
            Directory^.Insert(NewStr('  '+Name));
    end;



function    TFormatter.CheckFilesOnDisk ;

var
        Dlg : PDialog;
        R : TRect;
        Control, Labl  : PView;

        Data  : TListBoxRec;

    begin

         CheckFilesOnDisk  := False ;

         New(Directory,Init(6,2));
         if Directory = nil then Exit;

         if not inherited CheckFilesOnDisk
            then
                 begin
                   Dispose(Directory,Done);
                   exit;
                 end;



      R.Assign(0,0,41,17);
      New(Dlg, Init(R, 'WARNING'));
      Dlg^.Options := Dlg^.Options or ofCentered;


      R.Assign(1,2,40,4);
      Control := New(PStaticText, Init(R,
               GetString(dlFmtDriveHas1)+char(65 + DrvNum)+GetString(dlFmtDriveHas2)
               ));
      Dlg^.Insert(Control);

      R.Assign(30,5,31,10);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(10,5,30,10);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Control^.Options := Control^.Options or ofFramed ;
      Dlg^.Insert(Control);

      R.Assign(1,11,40,13);
      Control := New(PStaticText, Init(R,
              GetString(dlFmtAreYou)
                ));
      Dlg^.Insert(Control);


      R.Assign(8,14,18,16);
      Control := New(PButton, Init(R, GetString(dlYesButton), cmOk, bfDefault + bfNormal ));
      Dlg^.Insert(Control);

      R.Assign(22,14,32,16);
      Control := New(PButton, Init(R, GetString(dlNoButton), cmCancel, bfNormal));
      Dlg^.Insert(Control);

      Dlg^.SelectNext(False);

      Data.Data := Directory ;
      Data.Focused := 0;

      if Application^.ExecuteDialog(Dlg,@Data) = cmCancel then
           CheckFilesOnDisk := True ;

      Dispose( Directory,Done );


    end;


Function GetDriveCapacity;   {  Builds Collection Drive standart formats }
var I  : Byte;
    S  : PString;
    P  : PMediaCollection;
    S1,S2 : string[40] ;

    L1,L2 : longint ;

   begin
          GetDriveCapacity := Nil;
      if not DrvType in [1..4] then Exit;

      P := New(PMediaCollection,Init(6,2));

      For I:= FlLimits[DrvType,1] to
              FlLimits[DrvType,2] do
          begin
            S := NewStr (
              '  '+FlSizes[I]+
              '   '+SStr(FlTracks[i],2,' ')+
              '  '+SStr(FlSectors[i],2,' ')+
              '  '+SStr(FlSides[i],2,' ')+
              ' '+FlMedias[i]
                         );
            P^.Insert(S);
          end;

          if FmtUserDefined then
           with AdvFormatDialogDataR do
               begin

                 L2 := Longint ( A_Tracks ) *
                   A_Sectors  *
                   A_heads  *
                   A_ssize  div 1024;

                 S1 := FileSizeStr(L2);
                 L1 := Longint(@S1);
                 FormatStr(S2,'%5sK * User defined type *',L1);

                 S := NewStr(S2);
                 P^.Insert(S);

               end;

          GetDriveCapacity := P ;

   end;

Function BuildRangeCollection; { Range collection ex 1..3,2..25 }
var I  : integer;
    S  : PString;
    P  : PMediaCollection;
   begin
          BuildRangeCollection := Nil;

      P := New(PMediaCollection,Init(10,10));

      For I:= 0 to
              255 do
        if I in Range then
          begin
            S := NewStr (SStr(I,0,' ') );
            P^.Insert(S);
          end;

          BuildRangeCollection := P ;

   end;


Function BuildDrivesCollection;  { Standart Drives Collection }
var I  : integer;
    S  : PString;
    P  : PMediaCollection;
   begin
          BuildDrivesCollection := Nil;

      P := New(PMediaCollection,Init(5,2));

      For I:= 0 to AStdDrives do
          begin
            S := NewStr (ATitles[I]);
            P^.Insert(S);
          end;
          BuildDrivesCollection := P ;
   end;

Function BuildSsizeCollection;   { Sector Size Collection }
var I,Y: integer;
    S  : PString;
    P  : PMediaCollection;
   begin
          BuildSSizeCollection := Nil;

      P := New(PMediaCollection,Init(5,2));
      Y := 128;

      For I:= 1 to 4 do
          begin
            S := NewStr (SStr(Y,4,' '));
            P^.Insert(S);
            Y := Y shl 1;
          end;
          BuildSSizeCollection := P ;
   end;

Function BuildDirsCollection;   { Sector Size Collection }
var I,Y: integer;
    S  : PString;
    P  : PMediaCollection;
   begin
          BuildDirsCollection := Nil;

      P := New(PMediaCollection,Init(5,2));

      Y:=16;

      For I:= 1 to Dirs do
          begin
            S := NewStr (SStr(Y,4,' '));
            P^.Insert(S);
            Y:= Y shl 1;
          end;
          BuildDirsCollection := P ;
   end;

Function BuildBootsCollection;   { Boot Sectors Collection }
var
    S  : PString;
    P  : PMediaCollection;
   begin
          BuildBootsCollection := Nil;

      P := New(PMediaCollection,Init(5,2));

            S := NewStr ('Vitamin-B');
            P^.Insert(S);

          BuildBootsCollection := P ;
   end;


Function BuildFormatDialog: PDialog;

var
  Dlg : PDialog;
  R : TRect;
  Control, Labl, Histry : PView;
begin
  BuildFormatDialog := NIL;

  if NumFloppy = 0 then begin
    ErrMsg(dlFmtNoFloppy);
    exit;
  end;

  R.Assign(6,2,68,21);
  New(Dlg, Init(R, GetString(dlFmtTitle)));
  Dlg^.Options := Dlg^.Options or ofCentered;
  Dlg^.HelpCtx := hcFloppyFormat;

  R.Assign(3,2,25,4);

  if numFloppy = 1 then begin
    Control := New(PDriveButtons, Init(R,
    NewSItem('A: '+ ATitles[DrivesType[0]],Nil)));
  end else begin
    Control := New(PDriveButtons, Init(R,
    NewSItem('A: '+ ATitles[DrivesType[0]],
    NewSItem('B: '+ ATitles[DrivesType[1]],Nil))));
  end;

  PCluster(Control)^.Value := 0;
  Control^.Options := Control^.Options or ofFramed;
  Dlg^.Insert(Control);

  FreeStr := GetString(dlFmtDriveLabel);
  R.Assign(3,1,5+CStrLen(FreeStr),2);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Dlg^.Insert(Labl);

  R.Assign(59,2,60,8);
  Control := New(PScrollbar, Init(R));
  Dlg^.Insert(Control);

  R.Assign(29,2,59,8);
  Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
  Control^.Options := Control^.Options or ofFramed;
  Dlg^.Insert(Control);

  MediaListBox := PListBox(Control);

  FreeStr := GetString(dlFmtCapacityLabel);
  R.Assign(29,1,31+CStrLen(FreeStr),2);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Dlg^.Insert(Labl);

  R.Assign(5,7,18,8);
  Control := New(PInputLine, Init(R, 11));
  Dlg^.Insert(Control);

  FreeStr := GetString(dlFmtVolumeL);
  R.Assign(5,6,7+CStrLen(FreeStr),7);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Dlg^.Insert(Labl);

  R.Assign(3,10,25,14);
  Control := New(PRadioButtons, Init(R,
  NewSItem(GetString(dlFmt_F_astFormat),
  NewSItem(GetString(dlFmt_D_OSFormat),
  NewSItem(GetString(dlFmt_S_afeFormat),
  NewSItem(GetString(dlFmt_Q_uickFormat),Nil))))));
  PCluster(Control)^.Value := 0;
  Control^.Options := Control^.Options or ofFramed;
  Dlg^.Insert(Control);

  FreeStr := GetString(dlFmtFTypeLabel);
  R.Assign(3,9,5+CStrLen(FreeStr),10);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Dlg^.Insert(Labl);

  R.Assign(29,10,59,14);
  Control := New(PCheckboxes, Init(R,
  NewSItem(GetString(dlFmt_M_akeDiskBootable) ,
  NewSItem(GetString(dlFmtFo_r_cedFormatting),
  NewSItem(GetString(dlFmtMarkFullTrack),
  NewSItem(GetString(dlFmtOptimi_z_eSectors),Nil))))));
  PCluster(Control)^.Value := 1;
  Control^.Options := Control^.Options or ofFramed;
  Dlg^.Insert(Control);

  FreeStr := GetString(dlOptions);
  R.Assign(29,9,31+CStrLen(FreeStr),10);
  Labl := New(PLabel, Init(R, FreeStr, Control));
  Dlg^.Insert(Labl);

  R.Assign(7,16,18,18);
  Control := New(PButton, Init(R, GetString(dlFmtStartButton), cmOk , bfDefault));
  Dlg^.Insert(Control);

  R.Assign(20,16,32,18);
  Control := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
  Dlg^.Insert(Control);

  R.Assign(34,16,46,18);
  Control := New(PButton, Init(R, GetString(dlFmtAdvButton), cmYes, bfNormal));
  Dlg^.Insert(Control);

  R.Assign(48,16,58,18);
  Control := New(PButton, Init(R, GetString(dlHelpButton), cmHelp, bfNormal));
  Dlg^.Insert(Control);

  Dlg^.SelectNext(False);

  BuildFormatDialog  :=  Dlg;

  BuildFormatDialogData(FormatDialogData.Drive);
end;


function BuildAdvFormatDialog : PDialog;
   var
     Dlg : PDialog;
     R : TRect;
     Control, Labl, Histry : PView;

   begin

      R.Assign(3,0,75,23);
      New(Dlg, Init(R, 'Advanced Format Parameters for drive '
      +char(65+FormatDialogData.Drive)+':' ));

      Dlg^.Options := Dlg^.Options or ofCentered;
      Dlg^.HelpCtx := hcAdvancedFloppyFormat;

      { Drive types options }

      R.Assign(3,2,31,8);
      Control := New(PView,Init(R));
      Control^.Options := Control^.Options or ofFramed;
      Dlg^.Insert(Control);

      R.Assign(15,3,16,8);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(4,3,15,8);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(4,2,13,3);
        Labl := New(PLabel, Init(R, 'Drive ~A~:', Control));
        Dlg^.Insert(Labl);

      R.Assign(29,3,30,8);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(18,3,29,8);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(18,2,27,3);
        Labl := New(PLabel, Init(R, 'Drive ~B~:', Control));
        Dlg^.Insert(Labl);

      { DOS options }

      R.Assign(34,2,69,8);
      Control := New(PView,Init(R));
      Control^.Options := Control^.Options or ofFramed;
      Dlg^.Insert(Control);

      R.Assign(46,3,47,6);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(35,3,46,6);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(35,2,47,3);
        Labl := New(PLabel, Init(R, 'Boot Secto~r~', Control));
        Dlg^.Insert(Labl);

      R.Assign(66,3,67,6);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(60,3,66,6);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

      {  R.Assign(47,3,55,4);
        Labl := New(PLabel, Init(R, 'Entries', Control));
        Dlg^.Insert(Labl); }

        R.Assign(49,2,69,3);
        Labl := New(PLabel, Init(R, '~D~irectory Entries', Control));
        Dlg^.Insert(Labl);

      { Disk options }

      R.Assign(3,10,69,13);
      Control := New(PView,Init(R));
      Control^.Options := Control^.Options or ofFramed;
      Dlg^.Insert(Control);

      R.Assign(55,5,56,8);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(52,5,55,8);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

{        R.Assign(47,6,52,7);
        Labl := New(PLabel, Init(R, 'Size', Control));
        Dlg^.Insert(Labl);                   }

        R.Assign(37,7,50,8);
       { R.Assign(45,4,58,5);}
        Labl := New(PLabel, Init(R, 'Cluster Si~z~e', Control));
        Dlg^.Insert(Labl);


     {  DISK parameters }

      R.Assign(15,10,16,13);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(11,10,15,13);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(3,10,10,11);
        Labl := New(PLabel, Init(R, '~T~racks', Control));
        Dlg^.Insert(Labl);

      R.Assign(27,10,28,13);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(24,10,27,13);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(17,10,23,11);
        Labl := New(PLabel, Init(R, '~H~eads', Control));
        Dlg^.Insert(Labl);

      R.Assign(42,10,43,13);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(38,10,42,13);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(29,10,37,11);
        Labl := New(PLabel, Init(R, '~S~ectors', Control));
        Dlg^.Insert(Labl);

      R.Assign(55,10,56,13);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(51,10,55,13);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(44,10,50,11);
        Labl := New(PLabel, Init(R, 'Start', Control));
        Dlg^.Insert(Labl);

        R.Assign(44,11,50,12);
        Labl := New(PLabel, Init(R, 'Tra~c~k', Control));
        Dlg^.Insert(Labl);

      R.Assign(67,10,68,13);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(64,10,67,13);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

      R.Assign(57,10,63,11);
      Labl := New(PLabel, Init(R, 'Inter', Control));
      Dlg^.Insert(Labl);

      R.Assign(57,11,63,12);
      Labl := New(PLabel, Init(R, 'lea~v~e', Control));
      Dlg^.Insert(Labl);

      { Track options }

      R.Assign(3,15,69,18);
      Control := New(PView,Init(R));
      Control^.Options := Control^.Options or ofFramed;
      Dlg^.Insert(Control);

      R.Assign(20,15,21,18);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(16,15,20,18);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(8,15,15,16);
        Labl := New(PLabel, Init(R, 'Sector', Control));
        Dlg^.Insert(Labl);
        R.Assign(8,16,15,17);
        Labl := New(PLabel, Init(R, 'Sh~i~ft', Control));
        Dlg^.Insert(Labl);
        R.Assign(8,17,15,18);
        Labl := New(PLabel, Init(R, 'Factor', Control));
        Dlg^.Insert(Labl);

      R.Assign(34,15,35,18);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(30,15,34,18);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(22,15,27,16);
        Labl := New(PLabel, Init(R, 'Head', Control));
        Dlg^.Insert(Labl);
        R.Assign(22,16,29,17);
        Labl := New(PLabel, Init(R, 'Sector', Control));
        Dlg^.Insert(Labl);
        R.Assign(22,17,28,18);
        Labl := New(PLabel, Init(R, 'Shi~f~t', Control));
        Dlg^.Insert(Labl);


      R.Assign(48,15,49,18);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(44,15,48,18);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(36,17,42,18);
        Labl := New(PLabel, Init(R, 'Shift', Control));
        Dlg^.Insert(Labl);

        R.Assign(36,16,43,17);
        Labl := New(PLabel, Init(R, 'Sect~o~r', Control));
        Dlg^.Insert(Labl);

        R.Assign(36,15,42,16);
        Labl := New(PLabel, Init(R, 'Track', Control));
        Dlg^.Insert(Labl);

      R.Assign(64,15,65,18);
      Control := New(PScrollbar, Init(R));
      Dlg^.Insert(Control);

      R.Assign(58,15,64,18);
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Dlg^.Insert(Control);

        R.Assign(50,16,55,17);
        Labl := New(PLabel, Init(R, 'Siz~e~', Control));
        Dlg^.Insert(Labl);

        R.Assign(50,15,57,16);
        Labl := New(PLabel, Init(R, 'Sector', Control));
        Dlg^.Insert(Labl);

      R.Assign(4,1,15,2);
      Control := New(PStaticText, Init(R, 'Drives type'));
      Dlg^.Insert(Control);

      R.Assign(4,9,8,10);
      Control := New(PStaticText, Init(R, 'Disk'));
      Dlg^.Insert(Control);

      R.Assign(35,1,38,2);
      Control := New(PStaticText, Init(R, 'DOS'));
      Dlg^.Insert(Control);

      R.Assign(4,14,9,15);
      Control := New(PStaticText, Init(R, 'Track'));
      Dlg^.Insert(Control);

      R.Assign(18,19,32,21);
      Control := New(PButton, Init(R, GetString(dlOKButton), cmOk, bfDefault));
      Dlg^.Insert(Control);

      R.Assign(35,19,49,21);
      Control := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
      Dlg^.Insert(Control);

      R.Assign(52,19,66,21);
      Control := New(PButton, Init(R, GetString(dlHelpButton), cmHelp, bfNormal));
      Dlg^.Insert(Control);

      Dlg^.SelectNext(False);

      BuildAdvFormatDialog := Dlg;
      BuildAdvFormatDialogData;
end;

procedure ShowStatusBox;
var
  R: TRect;
  P: PView;
begin
  if StatusBox <> nil then exit;
  R.Assign(0,0,40,5);
  StatusBox := New(PStatusBox, Init(R, ''));
  with StatusBox^ do
  begin
    Options := Options or ofCentered;
    Options := Options and (not ofBuffered) {and ( not ofSelectable)} ;
    Flags := Flags and (not wfClose) and (not wfMove);
    R.Assign(2,2,38,4);
   {
    P := New(PParamText, Init(R, ^C'%s', 1));
   }
    P := New(PStaticText, Init(R,^C+Mesg));
    Insert(P);
  end;
{
  StatusMsg := '';
  OptionMsg := '';
  ParamsMsg := '';
  StatusRecord.SMsg := @StatusMsg;
  StatusRecord.OMsg := @OptionMsg;
  StatusRecord.PMsg := @ParamsMsg;
}
{
  FOperationMSg := '';
  POperationMsg := @FOperationMSg;

  StatusBox^.SetData(POperationMsg);
}
  Desktop^.Insert(StatusBox);

end;



procedure ShowFormatBox(Lim : longint);
var
  R: TRect;
  P: PView;
begin
  if FormatBox <> nil then exit;
  R.Assign(0,0,70,18{7});

  FormatBox := New(PStatusBox, Init(R, 'Status'));
  with FormatBox^ do
  begin
    Options := Options or ofCentered;
    Options := Options and (not ofBuffered);
    Flags := Flags {and (not wfClose)} and (not wfMove);

    R.Assign(3,2,67,5);
    P := New(PView,Init(R));
    P^.Options := P^.Options or ofFramed;
    Insert(P);

{    R.Assign(3,2,67,5); }
    P := New(PParamText, Init(R, '%s', 1));
    insert(P);



    R.Assign(3,7,40,12);
    P := New(PView,Init(R));
    P^.Options := P^.Options or ofFramed;
    Insert(P);

{    R.Assign(3,7,40,12);}
    P := New(PParamText, Init(R, '%s', 1));
    insert(P);


    R.Assign(43,7,67,12);
    P := New(PView,Init(R));
    P^.Options := P^.Options or ofFramed;
    Insert(P);

{    R.Assign(43,7,67,12);}
    P := New(PParamText, Init(R, '%s', 1));
    insert(P);


    R.Assign(3,14,40,16);
    P := New(PView,Init(R));
    P^.Options := P^.Options or ofFramed;
    Insert(P);

    P := New(PParamText, Init(R, '%s', 1));
    insert(P);

  {
    R.Assign(2,2,58,5);
    P := New(PParamText, Init(R, ^C'%s', 1));
    P^.Options := P^.Options or ofFramed;
    Insert(P);

    R.Assign(2,4,58,6);
    P := New(PParamText, Init(R, '%s', 1));
    P^.Options := P^.Options or ofFramed;
    Insert(P);
  }

    R.Assign(5,9,38,10);
    Insert(New(PBarGauge, Init(R, Lim )));

    R.Assign(15,11,18,12);
    Insert(New(PPercentGauge, Init(R, Lim )));

    R.Assign(18,11,29,12);
    Insert(New(PStaticText, Init(R, '% Complete')));

    


 {
    R.Assign(2,7,4,8);
    Insert(New(PStaticText, Init(R, '0%')));
    R.Assign(54,7,58,8);
    Insert(New(PStaticText, Init(R, '100%')));
 }

 {
    R.Assign(2,10,58,13);
    P := New(PParamText, Init(R, '%s', 1));
    insert(P);
 }

    R.Assign(45,14,65,16);
    Insert(New(PButton,Init(R,'~S~top',cmCloseFormat,bfDefault)));
  end;

{  F1Msg := '';}
  F2Msg := '';
  F3Msg := '';

  StatusRecord[1] := @F1Msg;
  StatusRecord[2] := @F2Msg;
  StatusRecord[3] := @F3Msg;


  FormatBox^.SetData(StatusRecord);
  Desktop^.Insert(FormatBox);
end;

{
function MakeDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, Labl, Histry : PView;
begin

R.Assign(3,2,68,5);
Control := New(PStaticText, Init(R, 'Info'));
Dlg^.Insert(Control);

R.Assign(3,7,43,13);
Control := New(PStaticText, Init(R, 'Gauge'));
Dlg^.Insert(Control);

R.Assign(48,7,68,13);
Control := New(PStaticText, Init(R, 'SysInfo'));
Dlg^.Insert(Control);

R.Assign(3,15,43,17);
Control := New(PStaticText, Init(R, 'Time'));
Dlg^.Insert(Control);

R.Assign(51,15,66,17);
Control := New(PButton, Init(R, 'Stop', cmCancel, bfNormal));
Dlg^.Insert(Control);

Dlg^.SelectNext(False);
MakeDialog := Dlg;
end;

var
  DataRec : record
    end;

}



procedure KillFormatBox;
    begin
      if FormatBox <> nil then
      begin
        Dispose(FormatBox, Done);
        FormatBox := nil;
      end;
    end;

procedure KillStatusBox;
    begin
      if StatusBox <> nil then
      begin
        Dispose(StatusBox, Done);
        StatusBox := nil;
      end;
    end;


procedure FormatDisk;
var P : PFormatter;
    Lim : Longint ;
    R : integer ;
    S: String[5];
label Again ;
    begin
        New(P,Init);
Again:
        if P^.FormatDialog(fdInsertNewDisk) = fdContinue
         then
           begin
        Lim := P^.GetLimit;
         ShowFormatBox(Lim);
         R :=  P^.RunFormat;

         KillFormatBox;

         if  R = FdDiskFormatted then
         if P^.FormatDialog(fdDiskFormatted) = cmYes then Goto Again;

           end;
          Dispose(P,Done);

         S := Char(65+FormatDialogData.Drive)+':';
         GlobalMessage(evCommand, cmRereadDir, @S);

    end;

end.



