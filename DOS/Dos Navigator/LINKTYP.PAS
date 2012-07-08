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

unit LinkTyp;

{$A+}

{$I LINK.INC} interface uses {$IFDEF OS2} ObjOS2 {$ELSE} Objects {$ENDIF};


type

   {$IFDEF CL_MASTER}
   TInDatTyp   = (id_Nothing, id_Drives,
                  id_FileNfo, id_FileBlk,
                  id_IOstat,
                  id_DirNfo, id_Dir);
   {$ENDIF}

   TInCmdTyp   = (ic_Nothing, ic_GetDrives,
                  ic_FileNfo, ic_FileBlk, ic_GetFile,
                  ic_GetDirNfo, ic_GetDirValid, ic_GetDir,
                  ic_EraseFile, ic_EraseDir, ic_MkDir);

   TCL_File = record
    TotSize : LongInt;
    CurPos  : LongInt;
    Handle  : file;
    Error   : Word;
    Id      : Byte
   end;

   TCL_IOstatus = (CL_stUnk, CL_stError, CL_stOK);

   TCL_IOstat = packed record
     Status : TCL_IOstatus;
     Error  : Word;
     Id     : Byte;
   end;

   TCL_FileNfo = packed record
     Size : LongInt;
     Time : LongInt;
     Attr : Byte;
     Id   : Byte;
   end;


   TCL_DirEntry = packed record
     Name : array[1..8] of char;
     Ext  : array[1..3] of char;
     Attr : Byte;
     Time : LongInt;
     Size : LongInt;
   end;

   PCL_DirNfo = ^TCL_DirNfo;
   TCL_DirNfo = packed record
     VolNm    : array[1..8] of char;
     VolXt    : array[1..3] of char;
     DrvTotal : LongInt;
     DrvFree  : LongInt;
     DirLen   : LongInt;
     NumFiles : Word;
     DifNfoSz : Word;
     DirNfo   : Char; {Last}
   end;

   PCL_DirPrefix = ^TCL_DirPrefix;
   TCL_DirPrefix = packed record
     TotalLen : LongInt;
     DrvFree  : LongInt;
     NumFiles : Word;
   end;

   TCL_DirReq = packed record
     PanelFlags: Integer;
     SortMode: Integer;
   end;

const
  CL_DirRecSz          = SizeOf(TCL_DirEntry);
  CL_MaxDirEntries     =  1500;

  CL_MaxInBufStorage   = $A000;
  CL_MaxBackOutBuf     = $8000;  { for LinkUtil }
  CL_NormBackOutBuf    = $4000;  { for LinkUtil }
  CL_FileBuf           = $2000;  { for LinkUtil }
  CL_MaxBlockSize      = $1000;  { for ComLnk }
  CL_StartBlockSize    = $0800;  { for ComLnk }

  CL_StatusStrWdth     = 36;


type
  TCL_StatusStr        = string[CL_StatusStrWdth];

  TCL_StatusInfo = record
    ConnectOK: Boolean;
    Speed: LongInt;
    ComNum, DataBits, StopBits, Parity: Byte;
    PortStr : TCL_StatusStr;
    ErrStr  : TCL_StatusStr;
  end;

var
  CL_InCmd,
  CL_InData   : PCollection;

implementation

end.