Unit IO_Byte;

Interface

Uses Dos,Declare;

Procedure OpenFiles (InF,OutF : String);
FUNCTION Endinput: BOOLEAN ;
FUNCTION Readbyte: Byte ;
PROCEDURE Writebyte( b: INTEGER) ;

Type
	FileType = Record
				  IOFIle : File;
				  CurLength,
				  CurPos : LongInt;
			   end;


Var
	InFile,OutFile : FileType;


Implementation


Procedure OpenFiles (InF,OutF : String);
begin
	With InFile do
	begin
		Assign(IOFile,InF);
		{$I-}
			Reset(IOFIle,1);
		{$I+}
		If IOResult <> 0 then
			begin
				Writeln('ERROR : File ',InF,' Not Found.');
				Halt(1);
			end
		Else
			begin
				CurPos := -1;
				CurLength := FileSize(IOFile)
			end;
	end;

	With OutFile do
	begin
		Assign(IOFile,OutF);
		{$I-}
			ReWrite(IOFile,1);
		{$I+}
		If IOResult <> 0 then
			begin
				Writeln('ERROR # ',IOResult:3,' While Opening File ',OutF);
				Halt(1);
			end
		Else
			begin
				CurPos := -1;
				CurLength := 0;
			end;
	end;
end;


FUNCTION Endinput: BOOLEAN ;
BEGIN
	With InFile do
	begin
		IF (CurPos+1 = CurLength) THEN
			Endinput := true
		ELSE
			Endinput := false
	end;
END { Endinput } ;



FUNCTION Readbyte: Byte ;
VAR
	Temp : Byte;
BEGIN
	 IF (EndInput) THEN
		 ReadByte := 0
	 Else
		begin
			Inc(InFile.CurPos);
			BlockRead(InFile.IOFile,Temp,1);
			ReadByte := Temp;
		end;
end;


PROCEDURE Writebyte (b: INTEGER) ;
BEGIN
	With OutFile do
	begin
		BlockWrite(IOFile,b,1);
		Inc(CurPos);
		Inc(CurLength);
	end;
END { Writebyte } ;



end.
