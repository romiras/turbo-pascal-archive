
Unit GrowView;

Interface
Uses Objects, App, Views, Dialogs, Drivers, Crt, convert;
Type
	PGrowView = ^TGrowView ;
	TGrowView = Object( TView )
	  Constructor Init( Var R : TRect ; Atotal : Longint ) ;
	  Procedure   Draw ; Virtual ;
	  Function    GetPalette : PPalette ; Virtual ;
	  Procedure   Update( Newvalue : Longint ) ;
	  Function    Percent( Xvalue,xtotal:longint):integer;
     Private
	  Total       : Longint ;
	  Value       : Longint ;
	  Numblock    : Integer ;
	  Function    Calcblock : Integer ;
	End;

 Const
  CGrowView = #6#9; {This Palette Maps Into The TDialog Palette And Produces
   A Black 'Background' Bar With Yellow Blocks.}

 Implementation

 Constructor TGrowView.init( Var R : TRect ; Atotal : Longint ) ;
  Begin
   Inherited Init( R ) ;
   Total	:= Atotal ;  { Remember The 100% Value }
   Value	:= 0 ;	     { Current Value Is 0 }
   Numblock	:= 0 ;	     { No Colored Blocks So Far }
  End ;

 { Calculate The Number Of Colored Blocks For The Current 'Value' }
 Function TGrowView.Calcblock : Integer ;
  Begin
   Calcblock := Value * Size.x div Total ;
  End ;

 Function TGrowView.percent;
  Begin
   Percent:= xvalue * 100 div xtotal ;
  End ;

 Procedure TGrowView.Draw ;
  Var
   R	  : TRect ;
   B	  : TDrawbuffer ;
  Begin
   Movechar( B, 'þ', Getcolor( 1 ), Size.x ) ;
   Movechar( B, #0 , Getcolor( 2 ), Numblock ) ;
   Writeline( 0, 0, Size.x, Size.y, B ) ;
  End ;

 Function TGrowView.GetPalette: PPalette ;
  Const
   P : String[ Length(cGrowView) ] = CGrowView ;
  Begin
   GetPalette := Addr(p);
  End ;
 {
  This Object Was Originally Written In My Graphical Turbo Vision Variant. In
  This Graphical World, Drawing Is Very Expensive (In Terms Of Execution Time)
  Compared To Calculating. I Therefor Try To Avoid To ReDraw The Progress Bar
  If It Is Not Necessary. The Optimisations In The Graphical Variant Are
  More Complicated Then What I Left In Here.
 }
 Procedure TGrowView.Update( Newvalue : Longint );
  Var
   Newblock : Integer ;
  Begin
   { An Update Request : Did My Situation Change ? }
   If (NewValue <> Value) Then
    Begin
     { Yes It Did, Remember The New Situation }
     Value    := Newvalue ;
     { Calculate The New Number Of Colored Blocks }
     Newblock := Calcblock ;
     { If This Number Didn't Change We Don't Need To ReDraw }
     If (Newblock <> Numblock) Then
      Begin
       { Pitty, We Do Need The ReDraw. }
       Numblock := Newblock ;
       Draw ;
      End ;
    End ;
  End ;

End.