{$IFDEF WINDOWS}
{$W-}
{$ENDIF}
{$N-,V-,G+}

Unit NatLFN;

Interface

Uses
{$IFDEF Windows}
  WinDos,WinTypes,WinProcs
{$ELSE}
  Dos
{$ENDIF}
  ,strings,LFN;
const
     fsPathName      = 79;

  LFNRuntimeErrors: boolean = false; { Determines if runtime errors are generated }

  LFNErr_Uninitialized = 120; { LFN routines called before LFNAssign }
  LFNErr_NotAllocated  = 121; { LFN routines called before LFNNew    }
  LFNErr_NotATextFile  = 122; { Appending to a non-text file         }

{$IFDEF WINDOWS}
  ofn_LongNames = $00200000;  { Required to support LFN in the common dialogs. }
                              { OR it into the Flags record of TOpenFilename.  }
{$ENDIF}

type
{$IFNDEF WINDOWS}
  TSearchRec = SearchRec;
  TDateTime = DateTime;
  PString= ^string;
{$ENDIF}
  ShortPathStr = array[0..fsPathName] of char;

  { Form used for old-style searches, with an embedded TSearchRec }
  TLFNShortSearchRec = record
    Attr         : longint;
    Creation     : comp;
    LastAccess   : comp;                   
    LastMod      : comp;             
    HighFileSize : longint;              
    Size         : longint;               
    Reserved     : comp;                     
    Name         : array[0..13] of char;
    SRec         : TSearchRec;
    Filler       : array[1..260-14-sizeof(TSearchRec)] of byte;       
    ShortName    : array[0..13] of char;    
    Handle       : word;                       
  end;
  PLFNShortSearchRec = ^TLFNShortSearchRec;

  { A record to isolate the UserData parameters } 
  TLFNFileParam = record
    Handle     : word;                   { The file handle                  }
    Mode       : word;                   { The file mode                    } 
    Res1       : array[1..28] of byte;   { Everything else up to UserData   }
    { Begin UserData }
    lfname     : PString;                { The long filename in String form }
    plfname    : PChar;                  { The long filename in AsciiZ form }
    TextFile   : boolean;                { Is it a text or binary file      }
    Initialized: boolean;                { Has it been LFNAssigned          }
    Magic      : string[3];              { ID to check LFNNew               }
    Res2       : array[0..1] of byte;    { 2 bytes left in UserData         }
    { End UserData }
    SName      : array[0..79] of char;   { The short filename               }
  end;
  PLFNFileParam = ^TLFNFileParam;

var
  LFNAble: boolean;   { Is LFN supported or not. Upon startup it is determined }
                      { by the OS, but can be switched off later if need be.   }

function LFNToggleSupport(on: boolean): boolean;
function PathNameLength: integer;

{$IFNDEF WINDOWS}
{ I need these to access the Srec.Name field properly }
function PCharOf(var F): Pchar;
{$ENDIF}

{ Basic API calls }
function  LFNFindFirst(filespec: PChar; attr: word; var S: TLFNSearchRec): word;
function  LFNFindNext(var S: TLFNSearchRec): word;
function  LFNFindClose(var S: TLFNSearchRec): word;
function  LFNGetFAttr(var F; var Attr: word): integer;

{ Service routines }
{function  LFNFileExist(fname: PChar): boolean;
function  LFNFSearch(Path,DirList: PChar): PChar;
procedure LFNFSplit(Path: PChar; Dir,Name,Ext: PChar);
function  LFNFExpand(Path: PChar): PChar;
procedure CanonicalFname(var S: PChar);
function  CanonicalFilename(Fname: PChar): Pchar;}

{ Interface to the Pascal Input/Output routines }
procedure LFNNew    (var F; IsText: boolean);
function  LFNAssign (var F; name: PChar): integer;
function  LFNRewrite(var F; RecLen: word): integer;
function  LFNAppend (var F; RecLen: word): integer;
function  LFNReset  (var F; RecLen: word): integer;
function  LFNErase  (var F): integer;
function  LFNClose  (var F): integer;
procedure LFNDispose(var F);
function  LFNRename (var F; NewName: PChar): integer;


implementation

const
{$IFDEF WINDOWS}
  SEM_FailCriticalErrors = $0001;
  SEM_NoOpenFileErrorBox = $8000;
{$ELSE}
  faReadOnly      =  ReadOnly;
  faHidden        =  Hidden;
  faSysFile       =  SysFile;                
  faVolumeID      =  VolumeID;
  faDirectory     =  Directory;                
  faArchive       =  Archive;                
  faAnyFile       =  AnyFile;
{$ENDIF}

  LFNMagic = 'LFN';

type
  PSearchRec = ^TSearchRec;
  TByteArray = array[0..$FFF0-1] of char;
  PByteArray = ^TByteArray;

function PathNameLength: integer;
begin
  if LFNAble then PathNameLength:=255
  else PathNameLength:=fsPathName;
end;

{$IFDEF WINDOWS}
procedure Message(S: PChar);
begin
  MessageBox(0,S,'Message',mb_ok or mb_TaskModal);
end;

{$ELSE}
function PCharOf(var F): Pchar;
{ A very simple function which returns a pointer to its argument. }
{ Its main use is in turning array[...] of char in to PChar, to   }
{ simulate the TPW/TP7/BP7 extended syntax.                       }
begin
  PCharOf:=@F;
end;
{$ENDIF}

{$IFDEF WINDOWS}
function SupportsLFN: boolean;
var
  WinVersion: word;
begin
  WinVersion := LoWord(GetVersion);
  SupportsLFN:=true;
  If ((Lo(WinVersion) =  3)  and                    {windows 95 first}
      (Hi(WinVersion) < 95)) or                     {version is 3.95 }
      (Lo(WinVersion) <  3)  then SupportsLFN := False;
end;
{$ELSE}
function SupportsLFN: boolean; assembler;
asm
  mov ax, $160a
  int $2f
  cmp ax, 0 
  jne @no         { Not running under Windows   }
  cmp bh, 2
  jle @no         { Major version <3            }
  cmp bh, 4
  jge @yes        { Major version >3            }
  cmp bl, 94
  jle @no         { Major version =3, minor <95 }
@yes:
  mov al, true
  jmp @exit
@no:
  mov al, false
@exit:
end; { SupportsLFN }
{$ENDIF}

function LFNToggleSupport(on: boolean): boolean;
{ This routine toggles LFN support on and off, provided }
{ the OS supports it. It returns the previous status.   }
begin
  LFNToggleSupport:=LFNAble;
  LFNAble:=on and SupportsLFN;
end;

{==============================================================}
{ BASIC LFN API CALLS.                                         }
{ This is a set of routines which implement the WIn95 LFN API, }
{ in Turbo Pascal form.                                        }
{==============================================================}
{ Pascal-string based interface routines }

function LFNFindFirst(filespec: PChar; attr: word; var S: TLFNSearchRec): word;
{ Implement the FindFirst procedure. This routine will call the TP }
{ FindFirst if LFN is not supported, and will translate the result }
{ into the TLFNSearchRec variable.                                 }
{ NOTE: Under Win95, the filespec will be checked against both the }
{ long and the short filenames, so an additional check may be      }
{ necessary.                                                       }
var
  EMode: word;
begin
{$IFDEF WINDOWS}
  EMode:=SetErrorMode(SEM_FailCriticalErrors or SEM_NoOpenFileErrorBox);
{$ENDIF}
  Attr:=Attr and not faVolumeID;  { required on net drives! }
  If LFNAble then
  begin
    LFindFirst(Filespec,Attr,S);
    if (DosError=0) and (S.shortname[0]=#0) then
         strcopy(S.shortname,S.name);
  end
  else DosError:=2;
  LFNFindFirst:=DosError;
{$IFDEF WINDOWS}
  SetErrorMode(EMode);
{$ENDIF}
end; { LFNFindFirst }

function LFNFindNext(var S: TLFNSearchRec): word;
{ Implement the FindNext procedure. This routine will call the TP  }
{ FindNext if LFN is not supported, and will translate the result  }
{ into the TLFNSearchRec variable.                                 }
{ NOTE: Under Win95, the filespec will be checked against both the }
{ long and the short filenames, so an additional check may be      }
{ necessary.                                                       }
begin
  If LFNAble then
  begin
    LFindNext(S);
    if (DosError=0) and (S.shortname[0]=#0) then
       strcopy(S.shortname,S.name);
  end else DosError:=18;
  LFNFindNext:=DosError;
end; { LFNFindNext }

function LFNFindClose(var S: TLFNSearchRec): word;
{ Close the Win95 TLFNSearchRec structure. if LFN is not suppported, }
{ this routine does nothing.                                         }
begin
  If LFNAble then LFNFindClose:=LFindClose(S)
  else LFNFindClose:=0;
end;

{====================================================================}
{ DERIVATIVE SERVICE ROUTINES.                                       }
{ This is a set of routines which mimic, as closely as possible, the }
{ equivalent routines in Turbo Pascal, except that they support      }
{ long filenames. In many cases, they are drop-in replacements, but  }
{ some are new.                                                      }
{====================================================================}

function LFNGetFAttr(var F; var Attr: word): integer;
{ Get the attributes of a file, using its File variable. }
{ The file should have been LFNAssign'ed first. Its not  }
{ strictly required, except for error checking.          }
{ Returns the DOS error code.                            }  
var
  EMode: word;                    
begin
     LFNGetFAttr:=0; DosError:=0;
     with PLFNFileParam(@F)^ do
     if (Magic<>LFNMagic) or (not Initialized) then
     begin
          DosError:=2; LFNGetFAttr:=DosError; Exit;
     end;
{$IFDEF WINDOWS}
     EMode:=SetErrorMode(SEM_FailCriticalErrors or SEM_NoOpenFileErrorBox);
{$ENDIF}
     GetFAttr(F,Attr); LFNGetFAttr:=DosError;
{$IFDEF WINDOWS}
     SetErrorMode(EMode);
{$ENDIF}
end; { LFNGetFAttr }

function LFNFileExist(fname: PChar): boolean;
{ Returns TRUE if the file exists, and FALSE otherwise. }
var
  fl: file;
  attr,i,len,EMode: word;
  P: PChar;
begin
{$IFDEF WINDOWS}
     EMode:=SetErrorMode(SEM_FailCriticalErrors or SEM_NoOpenFileErrorBox);
{$ENDIF}
     LFNFileExist:=(LFNAble and LFileExist(fname));
{$IFDEF WINDOWS}
     SetErrorMode(EMode);
{$ENDIF}
end; { LFNFileExist }

{=========================================================================}
{ BINARY AND TEXT FILE INPUT/OUTPUT ROUTINES.                             }
{ This set of routines is an interface between the LFN API and the Pascal }
{ style input/output routines. It uses ordinary text and file variables,  }
{ storing special info in the UserData field. The variable is then fully  }
{ compatible with the Pascal read(ln), write(ln), BlockRead, BlockWrite,  }
{ etc input/output routines.                                              }
{ All the functions return the DOS error code, and also put it into       }
{ DOSERROR. The global "LFNRuntimeError" determines if runtime errors     }
{ will be generated (by default, no.)                                     }                    
{=========================================================================}

procedure LFNNew(var F; IsText: boolean);
{ This routine prepares a text or file variable for LFN use. It allocates }
{ memory for the long name, and initializes the entries in the UserData.  }
{ It must be called before any other.                                     }
{ The "IsText" flag tells if the variable is of type "file" or "text".    }
begin
  with PLFNFileParam(@F)^ do
  begin
    TextFile:=IsText;
    Initialized:=false;
    Magic:=LFNMagic;
    lfname:=Nil; plfname:=Nil;
    GetMem(lfname,261);
    FillChar(lfname^,261,#0);
    plfname:=PChar(@PByteArray(lfname)^[1]);
  end;
end; { LFNNew }

function LFNAssign(var F; name: PChar): integer;
{ This routine replaces the Pascal "Assign" routine. For existing files, }
{ it first determines the short name, and then invokes "Assign". If the  }
{ file does not exist, it only stores the information in the UserData    }
{ fields, since the equivalent short name is not known. The assign       }
{ operation is then deferred to the first "LFNRewrite" call.             }
{ LFNAssign may be called for the same variable for different filenames, }
{ so long as the type (file or text) is the same.                        }
var
  tmp: PString;
  IsText: boolean;
  P,fname,sname: PChar;
  EMode: Word;
begin
  if PLFNFileParam(@F)^.Magic<>LFNMagic then
  begin
       DosError:=LFNErr_NotAllocated;
       LFNAssign:=DosError;
       Exit;
  end;
{$IFDEF WINDOWS}
  EMode:=SetErrorMode(SEM_FailCriticalErrors or SEM_NoOpenFileErrorBox);
{$ENDIF}
  DosError:=0;
  LFNAssign:=DosError;
  fname:=StrNew(name);
  with PLFNFileParam(@F)^ do
  begin
       if LFNFileExist(fname)
          and (LGetShortName(name,fname)=0)
          then Initialized:=true;
       if Initialized then
       begin
            IsText:=TextFile;
            tmp:=lfname;
            P:=plfname;
            if IsText
               then Assign(text(F),fname)
               else assign(file(F),fname);
            Initialized:=True;
            TextFile:=IsText; lfname:=tmp; plfname:=P;
            Magic:=LFNMagic;
       end;
       plfname:=name;
  end;
  StrDispose(fname);
{$IFDEF WINDOWS}
  SetErrorMode(EMode);
{$ENDIF}
  if PLFNFileParam(@F)^.Initialized
     then LFNAssign:=DosError
     else LFNAssign:=LFNErr_Uninitialized;
end; { LFNAssign }

function Err(e: byte): byte;
begin
  DosError:=e; Err:=e;
  if LFNRuntimeErrors and (e<>0) then RunError(e);
end;

function LFNRewrite(var F; RecLen: word): integer;
{ This routine readies a file for output. If the file does not yet exist, }
{ it creates an empty file to get the system-determined short name, and   }
{ performs a deferred Assign, since at Assign time a short name was not   }
{ yet available (see description of LFNAssign).                           }
{ The routine returns 0 if successful, and the DOS errorcode if not.      }
var
  tmp: PString;
  IsText: boolean;
  P,fname: PChar;
  EMode: Word;

begin
  LFNRewrite:=Err(0);
  if PLFNFileParam(@F)^.Magic<>LFNMagic then
  begin
    Err(LFNErr_NotAllocated); Exit;
  end;
{$IFDEF WINDOWS}
  EMode:=SetErrorMode(SEM_FailCriticalErrors or SEM_NoOpenFileErrorBox);
{$ENDIF}
  with PLFNFileParam(@F)^ do
  begin
       if not Initialized then    { create the file, so we can get a valid short name }
          if Err(LCreateEmpty(plfname))=0
             then LFNAssign(F,plfname);
       if Initialized then
       begin
            {$I-}
            if TextFile then Rewrite(text(F))
            else if RecLen=0 then Rewrite(file(F))
            else Rewrite(file(F),RecLen);
            Err(IoResult);
            {$I+}
       end
       else LFNRewrite:=DosError;
  end;
{$IFDEF WINDOWS}
  SetErrorMode(Emode);
{$ENDIF}
end; { LFNRewrite }

function LFNAppend(var F; RecLen: word): integer;
{ This routines opens a previously LFNAssigned for output at the EOF. }
{ Its not really necessary, except that it performs additional error  }
{ checking to make  sure that the file was properly initialized.      }
{ Also, in contrast to the TP Append, if the file does not exist the  }
{ routine calls LFNRewrite to create and open it.                     }
{ The routine returns 0 if successful, and the DOS errorcode if not.  }
var
  EMode: Word;

begin
  LFNAppend:=Err(0);
  if PLFNFileParam(@F)^.Magic<>LFNMagic then
  begin
    Err(LFNErr_NotAllocated); Exit;
  end;
  with PLFNFileParam(@F)^ do
  begin
    if Magic<>LFNMagic then
    begin
      Err(LFNErr_NotAllocated); Exit;
    end else if not TextFile then
    begin
      Err(LFNErr_NotATextFile); Exit;
    end else if not Initialized then Err(LFNRewrite(F,RecLen))
    else begin
{$IFDEF WINDOWS}
      EMode:=SetErrorMode(SEM_FailCriticalErrors or SEM_NoOpenFileErrorBox);
{$ENDIF}
      {$I-}
      Append(text(F)); Err(IoResult);
      {$I+}
{$IFDEF WINDOWS}
      SetErrorMode(EMode);
{$ENDIF}
    end;
  end;
end; { LFNAppend }

function LFNReset(var F; RecLen: word): integer;
{ This routines opens a file for input, instead of "reset". Its not really }
{ necessary, except that it performs additional error checking to make     }
{ sure that the file was properly initialized.                             }
{ The routine returns 0 if successful, and the DOS errorcode if not.       }

begin
  LFNReset:=Err(0);
  if PLFNFileParam(@F)^.Magic<>LFNMagic then
  begin
    Err(LFNErr_NotAllocated); Exit;
  end;
  with PLFNFileParam(@F)^ do
  begin
    if not Initialized then LFNReset:=LFNErr_UnInitialized
    else begin
      {$I-}
      if TextFile then Reset(text(F))
      else if RecLen=0 then Reset(file(F))
      else Reset(file(F),RecLen);
      Err(IoResult);
      {$I+}
    end;
  end;
end; { LFNReset }

function LFNErase(var F): integer;
{ This routines erases a previously LFNAssigned, but not opened, file. }
{ Its not really necessary, except that it performs additional error   }
{ checking to make  sure that the file was properly initialized. Also, }
{ it re-assignes the file so it will be properly ready for a rewrite.  }
{ The routine returns 0 if successful, and the DOS errorcode if not.   }
begin
  with PLFNFileParam(@F)^ do
  begin
       LFNErase:=0;
       if (Magic<>LFNMagic) then
       begin
            Err(LFNErr_NotAllocated); Exit;
       end
       else
       if not Initialized then
       begin
            Err(LFNErr_UnInitialized); Exit;
       end;
       LFNClose(F);
       {$I-}
       if TextFile then Erase(text(F)) else Erase(file(F));
       {$I+}
       if Err(IoResult)=0 then LFNAssign(F,plfname)
  end;
end; { LFNErase }

function LFNClose(var F): integer;
{ This routines closes a previously LFNAssigned and opened file.     }
{ Its not really necessary, except that it performs additional error }
{ checking to make  sure that the file was properly initialized.     }
{ The routine returns 0 if successful, and the DOS errorcode if not. }
begin
     LFNClose:=Err(0);
     with PLFNFileParam(@F)^ do
     begin
          if Magic<>LFNMagic then
          begin
               Err(LFNErr_NotAllocated); Exit;
          end
          else
          if not Initialized then
          begin
               Err(LFNErr_UnInitialized); Exit;
          end;
          {$I-}
          if TextFile then close(text(F)) else close(file(F));
          {$I+}
          Err(IoResult);
     end;
end; { LFNClose }

procedure LFNDispose(var F);
{ This routine disposes of the additional memory allocated by LFNNew, }
{ and cleans up the UserData fields. If the file is open, it also     }
{ closes it, so that there is no need to call LFNClose previously.    }
begin
     with PLFNFileParam(@F)^ do
     begin
          if (Magic<>LFNMagic) or (not Initialized) then Exit;
          if lfname<>Nil then FreeMem(lfname,261);
          lfname:=Nil; plfname:=Nil; Initialized:=false; Magic:='';
     end;
end;                 { LFNDispose }

function LFNRename(var F; NewName: PChar): integer;
{ This routines renames a previously LFNAssigned, but not opened, file. }
{ The file variable is then re-assigned to the new name.                }
{ The routine returns 0 if successful, and the DOS errorcode if not.    }
var
  i,len: integer;
  EMode: Word;

begin
  LFNRename:=Err(0);
  if NewName=nil then Exit;
  with PLFNFileParam(@F)^ do
  begin
    if Magic<>LFNMagic then
    begin
         LFNRename:=Err(LFNErr_NotAllocated); Exit;
    end
    else if not Initialized then
    begin
         LFNRename:=Err(LFNErr_UnInitialized); Exit;
    end;
{$IFDEF WINDOWS}
    EMode:=SetErrorMode(SEM_FailCriticalErrors or SEM_NoOpenFileErrorBox);
{$ENDIF}
    if Err(LRenameFile(plfname,NewName))=0
       then LFNAssign(F,NewName);
{$IFDEF WINDOWS}
    SetErrorMode(EMode);
{$ENDIF}
  end;
end;                    { LFNRename }

begin
     LFNAble:=SupportsLFN;
end.