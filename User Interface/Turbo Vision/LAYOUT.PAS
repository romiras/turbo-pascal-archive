
unit Layout;
interface
uses Objects, MsgBox;

procedure HandleError( Mess: String );
procedure Inform( R: TRect; Mess: String; Params: Pointer );
function  Confirm( Mess: String ): Word;

implementation

procedure HandleError( Mess: String );
var C: Word;
begin
	C:=MessageBox( Mess, nil, mfError + mfOKButton )
end;

procedure Inform( R: TRect; Mess: String; Params: Pointer );
var C: Word;
begin
	C:=MessageBoxRect( R, Mess, Params, mfInformation + mfOKButton )
end;

function Confirm( Mess: String ): Word;
var R: TRect;
begin
   R.Assign (10,4,60,12);
   Confirm:=MessageBoxRect( R, Mess, nil, mfConfirmation + mfOKCancel )
end;

end.
