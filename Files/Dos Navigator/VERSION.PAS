Uses Advance ;

{$I STDEFINE.INC}

CONST
  VersionName = '1.51';
  VersionDate = 'April 19, 1999';
  VersionWord = $100 + 51;


  SourceDir  = '';

{
 function CrStr( S : String ) : String ;
  var I,Y : word ;
      L : array[0..$ff] of byte absolute S;
      B : byte ;
      Ok : boolean ;
 begin

  B := L[0];
     for I := 1 to L[0] do
      begin

         OK := false ;
      for Y :=0 to $FF do
        if L[I] = Y xor ( ( B xor $ff ) and ( I ) )
         then
         begin
          B := L[i];
          L[I] := Y;
          Ok := true ;
          Break ;
         end;
        if not Ok then Writeln('ERR');
      end;

  Crstr := S ;
 end;
 }
{


 function CrStr( S : String ) : String ;
 var I : integer ;
     W,Y : word ;
     BB : array[1..2] of byte absolute W ;
     C : byte ;
     D : byte ;
     OK: boolean ;
  begin

   C := byte(S[0]);
   W := C or $100 ;

     for I := 1 to Length(S) do
      begin

        OK := False ;

        for Y:=1 to $FF do
         begin

         D:= W mod Y ;

          if D = byte(S[I]) then
             begin
              OK := true ;
              Break;
             end;
         end;

         if Not ok then Writeln('ERR');



         C := byte(S[i]);
         inc(W,C);

         byte(S[i]) := Y ;

      end;


     CrStr := S;
  end;


 function DeStr( S : String ) : String ;
 var I : Integer ;
  begin
     for I := 1 to Length(S) do
      begin
       byte( S[I] ) :=  (byte(S[I-1]) shl 8) mod
                        (byte(S[I]) );
      end;

    DeStr := S;
  end;

 }

var F : Text ;
    S,S1 : string ;

 begin
  {
  S:=' This is sample test string an nothing else .... ±±±±±±±±±±±±±±±±±±±±±±±±±±±±' ;
  S:='                                                                             ';

  Writeln(S);
  S1:=CrStr(S);

  }
  {
  Writeln(S);
  Writeln(S1);
  S1:=DeStr(S1);
  Writeln(S1);
  halt(1);
  }


  Writeln(' þ Creating ',SourceDir + 'VERSION.INC');
  Assign(F,SourceDir + 'VERSION.INC');
  ClrIo;
  Rewrite(F);
  Writeln(F,'  Const');
  Writeln(F,'     VersionName =''',VersionName,''';');
  Writeln(F,'     VersionDate =''',VersionDate,''';');
  Writeln(F,'     VersionWord = $', Hex4(VersionWord) , ';');

  Close(F);
 end .