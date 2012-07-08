Unit StudObj;

Interface
Uses Objects;

type
     PRecord = ^TRecord;
     TRecord = record
       Name: String[12];
       Mark: Integer;
     end;

     PStudentInfo=^TStudentInfo;
     TStudentInfo=object(TObject)
       TransferRecord: TRecord;
       constructor Load(var S: TStream);
       procedure   Store(var S: TStream);
       Procedure   Print; Virtual;
     end;

     PStudentsColl=^TStudentsColl;
     TStudentsColl=object(TSortedCollection)
       function Compare(Key1, Key2: Pointer): Integer; virtual;
     end;


const
  RStudentInfo: TStreamRec = (
    ObjType: 55001;
    VmtLink: Ofs(TypeOf(TStudentInfo)^);
    Load:    @TStudentInfo.Load;
    Store:   @TStudentInfo.Store
  );

  RStudentsColl: TStreamRec = (
    ObjType: 55002;
    VmtLink: Ofs(TypeOf(TStudentsColl)^);
    Load: @TStudentsColl.Load;
    Store: @TStudentsColl.Store);


var
  PC: PStudentsColl;


Implementation
Uses Drivers;

type
     TLinkRecord = record
       PName: PString;
       PMark: longint;
     end;



constructor TStudentInfo.Load(var S: TStream);
begin
  Inherited Init;
  S.Read(TransferRecord, SizeOf(TransferRecord));
end;

procedure TStudentInfo.Store(var S: TStream);
begin
  S.Write(TransferRecord, SizeOf(TransferRecord));
end;

Procedure TStudentInfo.Print;
var str: string;
    LinkRecord: TLinkRecord;
Begin
  with LinkRecord do
  begin
       PName := @TransferRecord.Name;
       PMark := TransferRecord.Mark;
  end;
  FormatStr (str,'  %-24s%-4d', LinkRecord);
  writeln (str);
End;

{$i ..\sortfunc.inc}

function TStudentsColl.Compare(Key1, Key2: Pointer): Integer;
begin
     Compare:=StrICmp(PStudentInfo(Key1)^.TransferRecord.Name, PStudentInfo(Key2)^.TransferRecord.Name);
end;


begin

{  RegisterType (RSortedCollection);}
  RegisterType (RStudentsColl);
  RegisterType (RStudentInfo);

end.