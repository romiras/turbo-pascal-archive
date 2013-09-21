UNIT
  IniFiles;

INTERFACE

USES
  Objects;

TYPE
  { Collection of strings like "video=vesa.bgi"  }
  { Note, "=" must be directly between key and   }
  {                   value, no blanks allowed   }
  { Empty key means insertion of ordinary string }
  { It may be used to implement indexed logfiles }
  { Of course, these lines must not contain
  { strings with "=" or starting with "[".       }
  PIniSection =^TIniSection;
  TIniSection = Object( TCollection )
    TheName: PString;
    constructor Init( const AName: String );
    destructor Done; virtual;
    function GetIndexOf( Key: String ): Integer;
    function Get( const Key: String ): String;
    procedure Put( const Key, Value: String; var Modified: Boolean );
    function GetKeyAt( const Index: Integer ): String;
    function GetValueAt( const Index: Integer ): String;
    function Name: String;
    procedure FreeItem( Item: Pointer ); virtual;
    procedure Insert( Item: Pointer ); virtual;
    constructor Load( var S: TStream );
    procedure Store( var S: TStream );
  end;

  { Collection of TIniSections }
  PIniFile =^TIniFile;
  TIniFile = Object( TCollection )
    Modified: Boolean;
    Name: PString;
    constructor Init( FileName: String; var Status: Integer );
    destructor Done; virtual;
    function Get( const Section, Key: String ): String;
    procedure Put( const Section, Key, Value: String );
    function GetSection( Section: String ): PIniSection;
  end;

IMPLEMENTATION

USES
  Advance;

CONST
  CrLf: Array [ 0..1 ] of Char = ( #13, #10 );

FUNCTION PStr2Str( P: PString ): String;
begin
  If P <> NIL
    then PStr2Str := P^
    else PStr2Str := ''
end;

FUNCTION ReadString( var Stream: TStream ): String;
var
  S: String;
  C: Char;
label
  Loop, Failure;
begin
  S := '';
Loop:
  Stream.Read( C, 1 );
  If ( C <> #13 ) and ( Stream.Status = stOK ) then begin
    S := S + C;
    goto Loop;
  end;
  ReadString := S;
  If Stream.Status <> stOK then Failure: begin
    Stream.Reset;
    Exit;
  end;
  Stream.Read( C, 1 );
  If ( C <> #10 ) or ( Stream.Status <> stOK ) then begin
    Stream.Reset;
    Stream.Seek( Stream.GetPos - 1 );
  end;
end;

{                                INI Section
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
CONSTRUCTOR TIniSection.Init;
begin
  inherited Init( 5, 5 );
  TheName := NewStr( AName );
end;

FUNCTION RemoveLeadSpaces( const S: String ): String;
var I: Integer;
begin
  I := 1;
  While ( I <= Length( S )) and ( S[ I ] = ' ' ) do Inc( I );
  RemoveLeadSpaces := Copy( S, I, 255 );
end;

FUNCTION TruncSpace(S:String): String;
var I: Byte;
begin
  I:=Length(S); While S[I]=' ' do DEC(I);
  S[0]:=Char(I);
  TruncSpace:=S
end;


CONSTRUCTOR TIniSection.Load;
var
  Base, L: LongInt;
  Str: String;
  function Simplify( S: String ): String;
  var
    I: Integer;
  begin
    I := Pos( '=', S );
    If I <> 0 then begin
      Simplify := RemoveLeadSpaces( TruncSpace( Copy( S, 1, I - 1 )))
        + '=' + RemoveLeadSpaces( TruncSpace( Copy( S, I + 1, 255 )));
    end else
      Simplify := RemoveLeadSpaces( TruncSpace( S ));
  end;
label
  Loop, Skip;
begin
  Base := S.GetPos;
  Str := ReadString( S );
  If ( Str[ 1 ] = '[' ) and ( Str[ Length( Str ) ] = ']' ) then begin
    TheName := NewStr( Copy( Str, 2, Length( Str ) - 2 ));
  end else begin
    TheName := NIL;
    S.Seek( Base );
  end;

  Items := NIL;
  Count := 0;
  Limit := 0;
  Delta := 5;

Loop:
  Str := Simplify( ReadString( S ));
  If Str <> '' then begin
    Insert( NewStr( Str ));
    goto Loop;
  end;

Skip:
  L := S.GetPos;
  Str := ReadString( S );
  If Str <> ''
    then S.Seek( L )
    else
  If S.GetPos <> L then goto Skip;

  If S.GetPos = Base then begin
    inherited Done;
    Fail
  end;
end;

PROCEDURE TIniSection.FreeItem;
begin
  DisposeStr( Item );
end;

PROCEDURE TIniSection.Insert;
begin
  If Item <> NIL then inherited Insert( Item );
end;

PROCEDURE TIniSection.Store;
var
  Str: String;
  procedure DoPutItem( P: PString ); far;
  begin
    Str := PStr2Str( P ) + #13#10;
    S.Write( Str[ 1 ], Length( Str ));
  end;
begin
  Str := PStr2Str( TheName );
  If Str <> '' then begin
    Str := '[' + Str + ']' + #13#10;
    S.Write( Str[ 1 ], Length( Str ));
  end;
  ForEach( @DoPutItem );
  S.Write( CrLf, SizeOf( CrLf ));
end;

DESTRUCTOR TIniSection.Done;
begin
  inherited Done;
  DisposeStr( TheName );
end;

FUNCTION TIniSection.Name;
begin
  Name := PStr2Str( TheName )
end;

FUNCTION TIniSection.GetIndexOf;
var
  P: PString;
  S: String;
  I: Integer;
  function Search( P: PString ): boolean; far;
  var
    S: String;
    I: Integer;
  begin
    S := UpStrg( PStr2Str( P ));
    I := Pos( Key, S );
    Search := ( I = 1 ) and ( S[ Length( Key ) + 1 ] = '=' );
  end;
begin
  Key := UpStrg( Key );
  GetIndexOf := IndexOf( FirstThat( @Search ));
end;

FUNCTION TIniSection.Get;
var
  I: Integer;
  S: String;
begin
  I := GetIndexOf( Key );
  If I >= 0 then begin
    S := PStr2Str( At( I ));
    I := Pos( '=', S );
    If I > 0 then begin
      Get := Copy( S, I + 1, 255 );
      Exit
    end;
  end;
  Get := ''
end;

PROCEDURE TIniSection.Put;
var
  I: Integer;
  S: String;
  NewValue: String;
begin
  If Key = '' then begin
    Insert( NewStr( Value ));
    Exit;
  end;
  I := GetIndexOf( Key );
  NewValue := Key + '=' + Value;
  If I >= 0 then begin
    S := PStr2Str( At( I ));
    If S <> NewValue then begin
      DisposeStr( At( I ));
      AtPut( I, NewStr( NewValue ));
      Modified := True;
    end;
  end else begin
    Insert( NewStr( NewValue ));
    Modified := True;
  end;
end;

FUNCTION TIniSection.GetKeyAt;
var
  S: String;
  I: Integer;
begin
  S := PStr2Str( At( Index ));
  I := PosChar( '=', S );
  If I = 0
    then GetKeyAt := ''
    else GetKeyAt := TruncSpace( Copy( S, 1, I - 1 ));
end;

FUNCTION TIniSection.GetValueAt;
var
  S: String;
  I: Integer;
begin
  S := PStr2Str( At( Index ));
  I := PosChar( '=', S );
  If I = 0
    then GetValueAt := ''
    else GetValueAt := RemoveLeadSpaces( Copy( S, I + 1, 255 ));
end;

{                                  INI File
{컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴}
CONSTRUCTOR TIniFile.Init;
var
  T: TBufStream;
  P: PIniSection;
begin
  inherited Init( 5, 5 );
  Name := NewStr( FileName );
  T.Init( FileName, stOpenRead, 512 );
  If T.Status = stOK then
    repeat
      P := New( PIniSection, Load( T ));
      If P <> NIL
        then Insert( P );
    until P = NIL;
  Status := T.Status;
  T.Done;
end;

DESTRUCTOR TIniFile.Done;
var
  T: TBufStream;
  procedure DoPutItem( P: PIniSection ); far;
  begin
    If P <> NIL then P^.Store( T );
  end;
begin
  If Modified then begin
    T.Init( PStr2Str( Name ), stCreate, 512 );
    ForEach( @DoPutItem );
    T.Done;
  end;
  DisposeStr( Name );
  inherited Done;
end;

FUNCTION TIniFile.GetSection;
  function Search( P: PIniSection ): boolean; far;
  begin
    Search := UpStrg( P^.Name ) = Section
  end;
begin
  Section := UpStrg( Section );
  GetSection := FirstThat( @Search )
end;

FUNCTION TIniFile.Get;
var
  P: PIniSection;
begin
  P := GetSection( Section );
  If P <> NIL
    then Get := P^.Get( Key )
    else Get := ''
end;

PROCEDURE TIniFile.Put;
var
  P: PIniSection;
begin
  P := GetSection( Section );
  If P = NIL then begin
    New( P, Init( Key ));
    Insert( P );
    Modified := True;
  end;
  P^.Put( Key, Value, Modified );
end;

END.