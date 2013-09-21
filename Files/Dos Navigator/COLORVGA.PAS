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

Unit  ColorVGA;

interface

uses Objects, Drivers, Views, Dialogs, commands,
     Dos,
     DnApp,
     Startup ,
     Advance ;


 Procedure VGAColorRegister;    { dialog }

 Const  LastTTFocus : Byte        = 0;   { Last focused Color }

implementation


 uses   {Colorsel,} Messages ;
{var Pal : vga_pal ;}

 Const  cmColorSet               = 73;
        cmColorMouseSelection    = 74;
 type

  PRegLabel = ^TRegLabel;
  TRegLabel = Object(TLabel)
   Value : word ;
    procedure Draw; virtual;
   end;

  PColorView = ^TColorView;
  TColorView = Object( TView )
   Color2Display : byte ;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
   end;

  PColorVGADialog = ^TColorVGADialog ;
  TColorVGADialog = object (TDialog)
   ThisProcedureExecuteFirstTime : Boolean;
   TL : array [1..3] of PRegLabel ;
   TS : array [1..3] of PScrollBar ;
   TV : PColorView  ;
   TT : PListBox ;
   Color: PRegLabel ;

    Constructor Init ;
    procedure HandleEvent(var Event: TEvent); virtual;
   end;


procedure TColorView.HandleEvent;
const
  Width = 4;
var
 { MaxCol: Byte;}
  Mouse: TPoint;
  R: TRect;
  OldColor: Byte;

begin
  TView.HandleEvent(Event);
  if Event.What =  evMouseDown then
      begin
        OldColor := Color2Display;
        repeat
          if MouseInView(Event.Where) then
          begin
            R.Assign(5,1,17,5);
            MakeLocal(Event.Where, Mouse);
            if R.Contains(Mouse) then
             begin
              Dec(Mouse.X,5); Dec(Mouse.Y);
              Color2Display := Mouse.Y * 4 + Mouse.X div 3;
             end
          end
          else
           Color2Display := OldColor;
          Message(Owner, evBroadcast, cmColorMouseSelection,
                   Pointer(Color2Display));
          DrawView;
  {        ClearEvent(Event);}
        until not MouseEvent(Event, evMouseMove);
      end;
end;

  Procedure TColorView.Draw;
    var    B : TDrawBuffer;
           I,J,C : byte ;
    begin
    {  MoveChar(B,' ',  Color2Display shl 4, Size.X);
      WriteLine(0, 0, Size.X, Size.Y, B);
     }
  MoveChar(B, ' ', $70, Size.X);
  for I := 0 to Size.Y do
  begin
    MoveChar(B,' ',  Color2Display shl 4, Size.X);
    if (I>0) and (I<5) then
      for J := 0 to 3 do
      begin
        C := (I-1) * 4 + J;
        MoveChar(B[ J*3 + 5 ], #219, C, 3);
        if C = Byte(Color2display) then
        begin
          WordRec(B[ J*3+1 + 5 ]).Lo := 8;
          if C = 0 then WordRec(B[ J*3+1 + 5 ]).Hi := $70;
        end;
      end;
    WriteLine(0, I, Size.X, 1, B);
  end;

    end;

 Procedure TRegLabel.Draw;
   var    S : string[20];
          P : Pointer ;
          i : Byte;
    begin
      S := SStr(Value,2,' ');
      if Text <> Nil then
      begin
        P := Text ;
        if Pos('~',Text^) = 0 then S := AddSpace( Text^ , 9 )+' '+S
                              else S := AddSpace( Text^ , 11 )+' '+S;
        Text := @S ;
        Inherited Draw ;
        Text := P ;
      end;
    end;


 Constructor TColorVGADialog.Init ;
   var
     R : TRect;
     Control, Labl, Histry : PView;
     i : integer;
     F: Text;
     S: String;
  begin

   R.Assign(6,0,56,22);
   Inherited Init(R, GetString(dlColors_VGA));
   Options := Options or ofCentered ;
   R.Assign(21,2,22,18);
   Control := New(PScrollbar, Init(R));
   Insert(Control);

   R.Assign(3,2,21,18);
   TT  := New(PListBox, Init(R, 1, PScrollbar(Control)));
{   TT^.HelpCtx := hcHelp;}
   Insert( TT );


     R.Assign(2,1,17,2);
     Labl := New(PLabel, Init(R, GetString(dlColors_P_alette), TT));
     Insert(Labl);

   R.Assign(25,12,47,18);
   TV  := New( PColorView , Init( R ));
   Insert( TV );

   R.Assign(24,11,38,12);
   Color := New(PRegLabel, Init(R, GetString(dlColorsColor_),nil));
   Insert(Color);



   if {StartupData.Load and osuVGAmonoMix = 0}
       appPalette=apColor then
    begin
     R.Assign(25,3,47,4);
     TS[1] := New(PScrollBar , Init(R ));
     Insert( TS[1] );

     R.Assign(24,2,45,3);
     TL[1] := New( PRegLabel, Init(R, GetString(dlColors_R_ed), TS[1] ));
     Insert( TL[1] );

     R.Assign(25,6,47,7);
     TS[2] := New(PScrollBar , Init(R ));
     Insert( TS[2] );

      R.Assign(24,5,45,6);
      TL[2] := New(PRegLabel, Init(R, GetString(dlColors_G_reen), TS[2] ));
      Insert( TL[2] );


     R.Assign(25, 9,47,10);
     TS[3] := New(PScrollBar , Init(R ));
     Insert( TS[3] );

      R.Assign(24, 8,45, 9);
      TL[3] := New(PRegLabel, Init(R, GetString(dlColors_B_lue), TS[3] ));
      Insert( TL[3] );
    end else
    begin
     R.Assign(25,6,47,7);
     TS[1] := New(PScrollBar , Init(R ));
     Insert( TS[1] );

     R.Assign(24,5,45,6);
     TL[1] := New( PRegLabel, Init(R, GetString(dlColors_G_ray), TS[1] ));
     Insert( TL[1] );
    end;

   S := GetString(dlColors_D_efault);
   R.Assign(2,19,4+Length(S),21);
   Control := New(PButton, Init(R, S, cmYes, bfBroadcast+bfNormal));
   Insert(Control);

   R.Assign(18,19,28,21);
   Control := New(PButton, Init(R, GetString(dlOKButton), cmOk, bfDefault));
   Control^.HelpCtx := cmOk;
   Insert(Control);

   R.Assign(28,19,38,21);
   Control := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
   Control^.HelpCtx := cmCancel;
   Insert(Control);

   R.Assign(38,19,48,21);
   Control := New(PButton, Init(R, GetString(dlHelpButton), cmHelp, bfNormal));
   Insert(Control);

   SelectNext(False);

   for i:=1 to 1+2*Byte({StartupData.Load and osuVGAmonoMix = 0}
                        appPalette=apColor) do
       With TS[i]^ do
        begin
         SetRange(0,63);
         Options := Options or (ofSelectable + ofFirstClick);
        end;

   ThisProcedureExecuteFirstTime:=True;
  end;

 Procedure TColorVGADialog.HandleEvent ;

 Function UpdateRGB : boolean ;
  var I : byte ;
    L : PScrollBar ;

   begin

      UpdateRGB := False ;
      L := Nil;

      for i:=1 to 1+2*Byte({StartupData.Load and osuVGAmonoMix = 0}
                           appPalette=apColor) do
      {for I:=1 to 3 do}
         if Event.InfoPtr = TS[I] then
          begin
           L := TS[I] ;
           Break;
          end;

     if L=nil then Exit ;
     UpdateRGB := True ;
     TL[I]^.Value := TS[I]^.Value ;
     TL[I]^.DrawView ;


    if {StartupData.Load and osuVGAmonoMix = 0}
      appPalette=apColor then
     Set_palette( sl[ TT^.Focused ] ,
         TL[1]^.Value ,
         TL[2]^.Value ,
         TL[3]^.Value ) else
     Set_palette( sl[ TT^.Focused ] ,
         TL[1]^.Value ,
         TL[1]^.Value ,
         TL[1]^.Value );

{     for i:=1 to 3 do  Pal[i, TT^.Focused]:=TL[i]^.Value;}

   end;


  Procedure UpdateColor ;
   var i : Integer;
     gc  : array [1..3] of byte ;

   begin


     with TT^ do
      begin
        {Focused}
        TV^.Color2Display := Focused ;
        TV^.DrawView ;
        Color^.Value := Focused;
        Color^.DrawView;

       Get_palette( sl[Focused], gc[1], gc[2], gc[3]);

       if appPalette<>apColor then
        begin
         gc[1] := (gc[1] +  gc[2] + gc[3]) div 3;
        end;


       for i:=1 to 1+2*Byte({StartupData.Load and osuVGAmonoMix = 0}
                            appPalette=apColor) do
     {  for i:=1 to 3 do}
        begin
         With TL[i]^ do
          begin
           Value := gc[i];
           DrawView;
          end;
         With TS[i]^ do
          begin
           Value := gc[i];
           DrawView;
          end;
        end;
      end;
   End ;


   begin
    if ThisProcedureExecuteFirstTime then TT^.FocusItem(LastTTFocus);
    ThisProcedureExecuteFirstTime := False;

    if Event.What = evBroadCast then
     case Event.Command of
      cmYes :
               begin
                ResetVGAPalette( False ) ;
                UpdateColor
               end;
      cmColorMouseSelection: begin
                                TT^.FocusItem(Event.Infobyte);
                                UpdateColor
                             end;
      cmListItemSelected : UpdateColor ;
      cmScrollBarChanged : if not UpdateRGB then
         begin
          Inherited HandleEvent( Event ) ;
          UpdateColor ;
          LastTTFocus := TT^.Focused;
          exit;
         end
     end;

      Inherited HandleEvent( Event ) ;

   end;


Procedure VGAColorRegister;

var
  DataRec : record
        List: PStringCollection;
   Selection: Word;
   end;

{  oldPalette: VGA_pal;         }

 begin

 With DataRec do begin
   New( List,Init(16,0));
   List^.ATInsert(0,  NewStr(GetString(dlColors_C00)));
   List^.AtInsert(1,  NewStr(GetString(dlColors_C01)));
   List^.AtInsert(2,  NewStr(GetString(dlColors_C02)));
   List^.AtInsert(3,  NewStr(GetString(dlColors_C03)));
   List^.AtInsert(4,  NewStr(GetString(dlColors_C04)));
   List^.AtInsert(5,  NewStr(GetString(dlColors_C05)));
   List^.AtInsert(6,  NewStr(GetString(dlColors_C06)));
   List^.AtInsert(7,  NewStr(GetString(dlColors_C07)));
   List^.AtInsert(8,  NewStr(GetString(dlColors_C08)));
   List^.AtInsert(9,  NewStr(GetString(dlColors_C09)));
   List^.AtInsert(10, NewStr(GetString(dlColors_C10)));
   List^.AtInsert(11, NewStr(GetString(dlColors_C11)));
   List^.AtInsert(12, NewStr(GetString(dlColors_C12)));
   List^.AtInsert(13, NewStr(GetString(dlColors_C13)));
   List^.AtInsert(14, NewStr(GetString(dlColors_C14)));
   List^.AtInsert(15, NewStr(GetString(dlColors_C15)));

  { oldPalette := VGA_palette;}

   If Application^.ExecuteDialog(
      New( PColorVGADialog, Init) ,
      @DataRec       ) = cmCancel
       then SetPalette( VGA_palette )
       else
        begin
         GetPalette( VGA_Palette ) ;
         ConfigModified := True  ;
         {
         if not isVideo(osvEnableVgaPal) then
          begin
           SystemData.Video := SystemData.Video OR osvEnableVgaPal;
           Msg(dlVGAEnabled,nil,mfInformation+mfOKButton);
          end;
         }
        end;
    Dispose(List,Done);

  end;

 end;



end.