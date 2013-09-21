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

Unit CdUtil;

 Interface

  Uses   CdPlayer,
         xTime,
         Dialogs,
         Drivers,
         Objects,
         Views,
         DnApp,
         FileCopy,
         StartUp,
         Microed,
         Commands,
         Advance ;

    type

      _OrderRec = record
            pCD : PCdPlayer ;
      Selection : Integer ;
        pOrder  : PString ;
         end;


      POrder = ^Torder;
      TOrder = object( TDialog )

         Mode  : Boolean ;
         List  : PLineCollection ;
         Box   : PListBox ;
         Order : String;
         CD    : PCDplayer ;
         Sel   : String ;

        Constructor Init( AMode: Boolean; AHeight: byte; ASel: String ) ;
        procedure HandleEvent(var Event: TEvent); virtual;
        procedure GetData(var Rec); virtual;
        procedure SetData(var Rec); virtual;
        function  DataSize: Word; virtual;
        Destructor Done ; virtual ;

       End;


      PSpad = ^TSpad ;
      TSpad = Object( TDialog )
            Songs : word ;
            Selection : word ;

            Ent : array [1..2] of char ;
            EntPos : byte ;

              Constructor Init( ASongs  : integer );
              Procedure   HandleEvent( var Event : Tevent);virtual;

              procedure   UpdateTitle ;
              procedure   GetData(var Rec); virtual;
              {procedure   SetData(var Rec); virtual;}
            end   ;


 Procedure EditDescr( CD : PCdPlayer );


 Implementation
 uses FViewer;

     {
      PTrks = ^TTrks ;
      TTrks = object( TListBox )
        function GetText(Item: Integer; MaxLen: Integer): String; virtual;
      end;
     }


   Procedure EditDescr;
   var T : String ;
       D : String[80];
       F : Text ;
       I : Word ;
       R : Trect ;
    begin
      With CD^ do
       begin

        D := SourceDir + 'CD\';
        T := D + Hex8(DiskID) + '.CD';
        Assign(F,T);
        ClrIo;
        Reset(F);
        if IOResult<>0 then begin
                             ClrIo ;
                             CreateDirInheritance(D,off);
                             Rewrite(F);
                             if IoResult<>0 then Exit;
                             Writeln(F,'TITLE:',CnvString(DiskTitle));
                             for I:=LowTrack to HighTrack do
                             Writeln(F,SStr(I-LowTrack+1,2,'0'),':');
                            end;
         System.Close(F);

         if (InterfaceData.Options and ouiStoreEditorPosition <> 0) then
           begin
              if not TempBounds.Empty then R := TempBounds
                                      else begin Desktop^.GetExtent(R); LastEditDeskSize := Desktop^.Size end;
              AdjustToDesktopSize(R, LastEditDeskSize);
           end else Desktop^.GetExtent(R);
         Application^.InsertWindow(New(PEditWindow,Init(R, T )));

       end;
    end;

   Function MakeTrackList( CD : PCDplayer ;
                       AOrder : string ;
                       ASel   : string ;
                        AList : Boolean ) : PLineCollection ;

    var C : PLineCollection;
        I : word ;
        T : byte ;
     begin
       New(C,Init(10,10));
       if AOrder<>'' then
      with CD^ do
       begin
        for I := 1 to Length(AOrder) do
        begin
         T := byte(AOrder[I]);

         if not Alist then
          begin
           if Pos(Char(T),ASel)=0 then
             C^.Insert(NewStr(
                     SStr( I ,3,' ' ) + ' ³ ' +
                   + SStr( Tlen[T].Lmin,2,' ' ) + ':' +
                   + SStr( Tlen[T].Lsec,2,'0' ) + ' ³ ' +
                   CnvString(Descr^.At(I-1))
             )) else
             C^.Insert(NewStr(
                  '*' + SStr( I ,2,' ' ) + ' ³ ' +
                   + SStr( Tlen[T].Lmin,2,' ' ) + ':' +
                   + SStr( Tlen[T].Lsec,2,'0' ) + ' ³ ' +
                   CnvString(Descr^.At(I-1))
             ))


          end
         else
          C^.Insert(NewStr(
                 SStr( T ,3,' ' ) + ' ³ ' +
               + SStr( Tlen[T].Lmin,2,' ' ) + ':' +
               + SStr( Tlen[T].Lsec,2,'0' ) + ' ³ ' +
               CnvString(Descr^.At(T-LowTrack))
         ))
        end;
       end;
      MakeTrackList := C ;
     end;

    {
    function TTrks.GetText;
    var S : String ;
       I : Integer ;
     begin
        S := '';
         if CD_Player <> Nil then
          with PCdPlayer( CD_Player )^ do
           begin
            I := FirstTrack+Item;
            S := SStr( Item+1,2,' '      ) + ' ³ ' +
               + SStr( Tlen[I].Lmin,2,' ' ) + ':' +
               + SStr( Tlen[I].Lsec,2,'0' ) + ' ³ ' +
               CnvString(Decr^.At(I));
           end;
        GetText := S;
     end;
    }


      (*
      var
        DataRec : record
          trks : TListboxRec;  {Listbox}
           list
           Selection
          end;
       *)

   Constructor TSpad.Init;
      var

        R, R1 : TRect;
        Control, Labl, Histry : PView;

        KeyLines : byte ;
        Keys     : byte ;

        I,Y,L  : integer ;

      begin

      Keys := ASongs ;
      if Keys > 9 then Keys := 12 ;
      KeyLines := 4 ;
      R.Assign(16,4,54,16);

      Inherited Init( R  , GetString(dlCDPlayTrack)+' (1..'+ itos(ASongs) +') þþ' ) ;
        Options := Options or ofCentered ;

      Songs := ASongs ;


      Ent[1] := 'þ';
      Ent[2] := 'þ';
      EntPos := 1;


      R1.Assign(1,2,8,4);

      Y := 1;
      L := 1;

       for I := 1 to Keys do
        begin

         Case I of
         11: Control := New(PButton, Init(R1, GetString(dlCD_R_Button), cdSong + 99 , bfBroadCast ));
         12: Control := New(PButton, Init(R1, GetString(dlCD_C_Button), cmCancel , bfNormal ));
          else
           Control := New(PButton, Init(R1, '~' + ItoS(I Mod 10) + '~', cdSong + (I mod 10)  , bfBroadCast ));
         end;

          Insert(Control);
          inc(Y);
           R1.Move(7,0);
          if Y = 4 then
           begin

              if Songs >= (L*10) then
                 begin
                   Inc(R1.B.X,3);
                   Control := New(PButton, Init(R1, '+~'+ItoS( L ) + '~0' , cdSong + L*10 , bfBroadCast ));
                   Insert(Control);
                   Dec(R1.B.X,3);
                 end;

              Y := 1;
              R1.Move(-21,2);
              inc(L);
           end;


        end;


    if Keys < 12 then

    begin
      EntPos := 2;

      R.Assign( 12, KeyLines*2 ,22,KeyLines*2 + 2 ) ;
      Control := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
      {Control^.Options := Control^.Options or ofCenterX ;}
      Insert(Control);
    end;
      {

      if Asongs > 1 then
       begin
        R.Move( -11 , 0);
        Control := New(PButton, Init(R, '~E~nter', cmOk, bfNormal));
        Insert(Control);

       end;
       }

      {
      R.Assign(13,10,23,12);
      Control := New(PButton, Init(R, 'O~K~', cmOk, bfDefault));
      Dlg^.Insert(Control);
      }

      {R.Assign(25,10,35,12);}

      SelectNext(False);
      end;

   Procedure TSPad.UpdateTitle ;
      begin
        Title^[ Length(Title^) - 1] := Ent[1];
        Title^[ Length(Title^)    ] := Ent[2];
        frame^.DrawView;
      end;


   procedure TSPad.GetData(var Rec);
       begin
         Move(Selection,Rec,2);
       end;


   Procedure TSPad.HandleEvent ;
   var  P : byte ;


   function CheckEnter : boolean ;
   var B : byte ;
    begin
       B := 0;
       if byte(Ent[1]) <= byte( '9') then B := (byte(Ent[1])-byte('0')) * 10 ;
       if byte(Ent[2]) <= byte( '9') then Inc ( B , (byte(Ent[2])-byte('0')) );
       Selection := B ;
       CheckEnter := (B > 0 ) and ( B <= Songs ) ;
    end;

      begin

      if Event.What = evBroadCast then
       if (Event.Command >= cdSong) and
          (Event.Command < cdSong + 100 ) then
       begin
         P := Event.Command - cdSong ;

         case p of
          99  : begin
                   Ent[1] := 'þ';
                   Ent[2] := 'þ';
                 EntPos := 1 ;
                end;
            {
          99  : begin

                end;
            }
            else
              begin
                if P > 9 then
                P := P div 10 ;
                Ent[EntPos] := Char( P + byte('0') );
                inc(EntPos);
              end;

        end; { case }


        if EntPos = 3 then
         begin

             if CheckEnter
              then EndModal( cmOk )
              else begin
                    Ent[1] := 'þ';
                    Ent[2] := 'þ';
                    EntPos := 1 ;
                    UpdateTitle ;
                   end;

             Exit;
         end;

        UpdateTitle ;

      end;


        Inherited HandleEvent( Event );


      end;


  Constructor TOrder.Init;
      var
        Dlg : PDialog;
        R : TRect;
        Control, Labl, Histry : PView;

        Y2,Y3 : integer ;
      begin



      Y2 := 8;

      Desktop^.GetExtent(R);
      if AHeight > 6 then
      if AHeight > R.B.Y-R.A.Y-6 then Y2:= R.B.Y-R.A.Y-6
                                 else Y2:= AHeight;

      R.Assign(0,0,68,Y2+7); {12}

        { box -4 butt -3+2 }

      Inherited Init(R, GetString(dlCDSelectTrack));
      Options := Options or ofCentered ;

      Mode := AMode ;
      Sel  := ASel  ;

      R.Assign(64,2,65,Y2+2{8});
      Control := New(PScrollbar, Init(R));
      Insert(Control);

      R.Assign(4,2,64,Y2+2{8});
      Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
      Insert(Control);
      BOX := PListBox(Control) ;

        R.Assign(4,1,11,2);
        Labl := New(PLabel, Init(R, GetString(dlCDTrackButton), Control));
        Insert(Labl);

      R.Assign(2,Y2+3,14,Y2+5);
      if not Mode then R.Move(20,0);

      Control := New(PButton, Init(R, GetString(dlOKButton), cmOk, bfDefault));
      Insert(Control);


      if Mode then
       begin
         R.Move(13,0);
         Control := New(PButton, Init(R, GetString(dlCDAddButton), cmYes, bfNormal + bfBroadCast));
         Insert(Control);
         R.Move(13,0);
         Control := New(PButton, Init(R, GetString(dlCDDeleteButton), cmNo, bfNormal + bfBroadCast));
         Insert(Control);
         R.Move(13,0);
         Control := New(PButton, Init(R, GetString(dlCDSaveButton), cmSave, bfNormal + bfBroadCast));
         Insert(Control);
       end;

      R.Move(13,0);
      Control := New(PButton, Init(R, GetString(dlCancelButton), cmCancel, bfNormal));
      Insert(Control);

      SelectNext(False);
    end;

   Function TOrder.DataSize;
    begin
      DataSize := SizeOF(_Order);
    end;

   Procedure TOrder.SetData ;
    begin
         with _OrderREc(Rec) do
          begin
             CD := pCD ;
             Order := pOrder^ ;
             List := MakeTrackList( CD , order , Sel, Mode );
             Box^.NewList( List );
             Box^.FocusItem( Selection  );
          end;
    end;

   Procedure TOrder.GetData ;
    begin
         with _OrderRec(Rec) do
          begin
             pOrder^:= Order ;
             Selection := Box^.Focused;
          end;
    end;

  Destructor TOrder.Done ;
   begin
     Dispose(List,Done);
     Inherited Done ;
   end;


 Procedure TOrder.HandleEvent(var Event: TEvent);

  procedure AddSong;
     var T : _OrderRec ;
         s : string ;
         I : byte ;
      begin

      with CD^ do begin
       S := '';
       for  I:= LowTrack to HighTrack do AddStr(S, char(I));

       with T do begin
                  pCD := CD ;
                  Selection := 0;
                  pOrder := @S ;
                 end;

        if Application^.ExecuteDialog(
         New(POrder,Init(False,Succ(HighTrack-LowTrack),Self.order )),@T)=cmOk
          then begin
                AddStr(Self.Order,S[T.Selection+1]{,BOX^.Focused+2});
                List := MakeTrackList( CD , Self.order,'', On );
                Box^.NewList( List );
               end;
        end;
      end;

 procedure DelSong;
 var I : integer ;
  begin

    i := Box^.Focused;
    System.Delete( Order, i+1,1 );

    List := MakeTrackList( CD , order ,'', On );
    Box^.NewList( List );

  end;


  Procedure SaveOrder ;
   var T : String ;
       D : String[80];
       F : Text ;
       I : Word ;
       R : Trect ;
    begin
      if Order='' then Exit;
      With CD^ do
       begin
        D := SourceDir + 'CD\';
        T := D + Hex8(DiskID) + '.TRK';
        Assign(F,T);
        ClrIo;
        ReWrite(F);
        if IOResult<>0 then begin
                             ClrIo ;
                             CreateDirInheritance(D,off);
                             Rewrite(F);
                             if IoResult<>0 then Exit;
                            end;
         For I:=1 to Length(Self.order) do
         Writeln(F,ItoS( Byte(Self.Order[I]) - LowTrack + 1));
         System.Close(F);
       end;
    end;



    begin
         if Event.What = evBroadCast then
          case
           Event.Command of
            cmYES:AddSong;
            cmNo:DelSong;
            cmSave:SaveOrder;
           else inherited HandleEvent(Event);
          end else inherited HandleEvent(Event);
    end;

 End.