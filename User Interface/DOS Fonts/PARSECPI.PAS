{$I-}
uses DOS;
Type CPIHeader=Record
                LibraryID:Byte;{Must be $FF}
                LibraryName:Array[1..7] of Char;
                Reserved:Array[1..8] of byte;
                PtrCount:Word;{Usially 1}
                FontInfoType:Byte;{Must be 1}
                FontInfoPtr:LongInt;
              end;
      CodePageHeader=Record
                      Size:Integer;
                      Next:LongInt;
                      Device:Integer;{1 for Display}
                      Name:Array[1..8] of Char;
                      CodePage:Integer;
                      Reserved:Array[1..6] of byte;
                      DataPtr:LongInt;
                     end;
       DataHeader=Record
                    Id:Word;{Must be 1}
                    FontCount:Integer;
                    TotalSize:Word;
                  end;
       FontPrefix=Record
                   Rows:Byte;
                   Columns:Byte;
                   Aspect:Word;
                   CharCount:Word;
                  end;
var F,F2:File;
    LibHdr:CpiHeader;
    InfoHdr:CodePageHeader;
    i,CodePageNum:Word;
    S:String;
    FileName:String;
    DesiredCodePage:Integer;
    Prefix:FontPrefix;
    DH:DataHeader;
    FontPtr:Pointer;
Function NumStr(N:Integer):String;
var S:String[6];
begin
 Str(N,S);
 NumStr:=S;
end;
begin
  S:=ParamStr(1);
  val(S,DesiredCodePage,i);
  if i<>0 then
   begin
    Writeln('Usage: PARSECPI codepage [cpi-file]');
    Writeln('If no CPI file is cpecified, program tries to open EGA.CPI');
    Halt;
   end;
   FileName:=ParamStr(2);
   if FileName='' then
    FileName:=FSearch('EGA.CPI',GetEnv('PATH'));
   if FileName='' then begin Writeln('Cannot open EGA.CPI');halt;end;
 Assign(F,FileName);
 FileMode:=0;
 Reset(F,1);
 if IOResult<>0 then begin Writeln('Cannot open ',FileName);halt end;
 BlockRead(F,LibHDR,SizeOf(CpiHeader));
 Seek(F,LibHdr.FontInfoPtr);
 BlockRead(F,CodePageNum,2);
 Writeln('Number of CodePages=',CodePageNum);
 i:=0;
  Repeat
   BlockRead(F,InfoHDR,SizeOf(InfoHdr));
   inc(i);
   S:=InfoHdr.Name;
   Writeln(S,InfoHdr.CodePage);
   if InfoHdr.Next<>0 then
     Seek(F,InfoHdr.Next);
  Until (InfoHdr.Next=0)or (i=CodePageNum)or(InfoHdr.CodePage=DesiredCodePage);
  if InfoHdr.CodePage<>DesiredCodePage then
   Writeln('Code page ',DesiredCodePage,' not found')
   else
    begin
      FileMode:=2;
      Seek(F,InfoHdr.DataPtr);
      S:=InfoHdr.Name;
      While S[Length(S)]=' ' do dec(S[0]);
      Write('Found code page ',InfoHdr.CodePage,' for device ',S);
      BlockRead(F,DH,SizeOf(DataHeader));
      Writeln(' containing ',DH.FontCount,' fonts');
      For i:=1 to DH.FontCount do
       begin
        BlockRead(F,Prefix,6);
        Write('Font ',Prefix.Columns,'x',Prefix.Rows,' Reading...');
        GetMem(FontPtr,Prefix.Rows*Prefix.CharCount);
        BlockRead(F,FontPtr^,Prefix.Rows*Prefix.CharCount);
        Write(#8#8#8#8#8#8#8#8#8#8'Writing...');
        Assign(F2,'Font'+NumStr(Prefix.Columns)+'x'+NumStr(Prefix.Rows)+'.BIN');
        Rewrite(F2,1);
        BlockWrite(F2,FontPtr^,Prefix.Rows*Prefix.CharCount);
        FreeMem(FontPtr,Prefix.Rows*Prefix.CharCount);
        if Ioresult=0 then WriteLn(#8#8#8#8#8#8#8#8#8#8'Done.     ')
                      else WriteLn(#8#8#8#8#8#8#8#8#8#8'Error!!!  ');
       end;
    end;
  Close(F);
end.


