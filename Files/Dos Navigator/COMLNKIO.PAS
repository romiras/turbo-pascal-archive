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

unit ComLnkIO;

{$I LINK.INC} interface

const
  TCL_TimerSz = 8;

type
  TCL_Timer   = array[1..TCL_TimerSz] of byte;

function  CL_OutBuffFree(APort: Pointer): Word;
function  CL_OutBuffUsed(APort: Pointer): Word;
function  CL_GetBlock(APort: Pointer; var Buf; Size: Word): Word;
procedure CL_PutBlock(APort: Pointer; const Buf; Size: Word);
function  CL_InitCOM: Pointer;
procedure CL_DoneCOM(APort: Pointer);
function  CL_DCD(APort: Pointer): Boolean;

procedure CL_NewTimer(var Timer: TCL_Timer; Tics : LongInt);
procedure CL_ClearTimer(var Timer: TCL_Timer);
function  CL_TimerExpired(const Timer: TCL_Timer): Boolean;
function  CL_TimerInstalled(const Timer: TCL_Timer): Boolean;

function  CL_GetCRC32ofs: Word;

{$IFDEF NLSLAVE}
var
    _Speed: LongInt;
    _ComNum: Byte;
{$ENDIF}


implementation uses
        {$IFDEF DN} ModemIO, {$ENDIF}
        {$IFDEF OS2}
                    CrtOS2,
                    OS2Def,
                    DosTypes,
                    DosProcs,
                    OS2Timer
        {$ELSE}
                    apFossil,
                    ooCOM,
                    apPort,
                    apMisc,
                    xTime
        {$ENDIF} ;

{$IFDEF OS2} {$I OS2IO.INC} {$ENDIF}

function  CL_GetCRC32ofs: Word;
begin
   CL_GetCRC32ofs := {$IFDEF OS2} Ofs(CRC32Table)
   {$ELSE} CRC32TableOfs {$ENDIF};
end;

function CL_OutBuffFree;

{$IFDEF OS2}
var
  StatStruc : record NumBytes, BufSize: Word end;
begin
  rc := DosDevIOctl(StatStruc, (nil)^, ASYNC_GETOUTQUECOUNT, IOCTL_ASYNC, hfCOM);
  if rc <> NO_ERROR then Usage;
  with StatStruc do
  begin
    {WriteLn('NumBytes = ', NumBytes,', BufSize = ',BufSize);}
    CL_OutBuffFree := BufSize - NumBytes;
  end;
end;
{$ELSE}
begin CL_OutBuffFree := AbstractPortPtr(APort)^.OutBuffFree end;
{$ENDIF}

function CL_OutBuffUsed;

{$IFDEF OS2}
var
  StatStruc : record NumBytes, BufSize: Word end;
begin
  rc := DosDevIOctl(StatStruc, (nil)^, ASYNC_GETOUTQUECOUNT, IOCTL_ASYNC, hfCOM);
  if rc <> NO_ERROR then Usage;
  CL_OutBuffUsed := StatStruc.NumBytes;
end;
{$ELSE}
begin CL_OutBuffUsed := AbstractPortPtr(APort)^.OutBuffUsed end;
{$ENDIF}

procedure CL_PutBlock;

{$IFDEF OS2}
var
  Actually: Word;
begin
  DosWrite(hfCOM, (@Buf)^, Size, Actually);
end;
{$ELSE}
var Dummy : Word;
begin
  AbstractPortPtr(APort)^.PutBlockDirect(Addr(Buf)^, Size, Dummy);
end;
{$ENDIF}

function CL_GetBlock;
{$IFDEF OS2}
var Actual: Word;
begin
  DosRead(hfCOM, Buf, Size, Actual);
  CL_GetBlock := Actual;
end;
{$ELSE}
var Actual : Word;
begin
  AbstractPortPtr(APort)^.GetBlockDirect(Buf, Size, Actual, []);
  CL_GetBlock := Actual;
end;
{$ENDIF}

{$IFNDEF DN}

procedure Usage;
begin
  WriteLn('Usage: NLslave <COMn> [115200] [FOSSIL]');
  WriteLn('   valid ports are COM1-COM8');
  WriteLn('   valid BPS are 300, 1200, 2400, 4800, 9600, 14400, 19200, 38400, 57600,');
  WriteLn('     and 115200 for Registered Users Only');
  WriteLn('   valid interfaces are DEFAULT, FOSSIL and DIGI14');
  Halt;
end;

{$ENDIF}

function CL_DCD;
begin
  CL_DCD := AbstractPortPtr(APort)^.CheckDCD;
end;

function CL_InitCOM;

{$IFDEF DN}
begin
  CL_InitCOM := COMport;
end;

{$ELSE}

{$IFDEF OS2}

{ ------------------------------ OS/2 ------------------------------ }
var
  ctrl: packed record
          D, P, S: Byte;
        end;
var
  s: string;
  sp: LongInt;
  er: Integer;
  procedure UpStr;var I:Byte;begin for I:=1 to Length(S) do S[I] := UpCase(S[I]) end;

begin

  CL_InitCOM := nil;

  s := ParamStr(1); UpStr;
  if (Length(s)<>4) or (Copy(s,1,3)<>'COM') or (not (s[4] in ['1'..'8'])) then
  begin
    WriteLn('Illegal COM Port - '+s); Usage;
  end;
  s[Length(s)+1] := #0;
  rc := DosOpen(@s[1], hfCOM, ComAction, 0, FILE_NORMAL, FILE_OPEN,
    OPEN_ACCESS_READWRITE or OPEN_SHARE_DENYNONE, 0);
  if rc = NO_ERROR then CL_InitCOM := @hfCOM else
  begin
    WriteLn('Failed to open '+s); Usage;
  end;

  s := ParamStr(2);
  Val(s, sp, er);
  if er>0 then
  begin
    WriteLn('Illegal COM Speed - '+s); Usage;
  end;
  WriteLn('Initializing ',s);
  rc := DosDevIOctl((nil)^, sp, ASYNC_SETBAUDRATE, IOCTL_ASYNC, hfCOM);
  if rc <> NO_ERROR then
  begin
    WriteLn('Failed to set baudrate '+s); Usage;
  end;

  with ctrl do begin D:=8;P:=0;S:=0 end;
  rc := DosDevIOctl((nil)^, ctrl, ASYNC_SETLINECTRL, IOCTL_ASYNC, hfCOM);
  if rc <> NO_ERROR then
  begin
    WriteLn('Failed to port characteristics of '+s); Usage;
  end;

end;


{$ELSE}

{ ------------------------------ DOS ------------------------------ }

type
  Tp = (tDefault, tFossil, tDigi);

const
  bs = 16384;

var
  s: string;
  er: Integer;
  p: Pointer;
  optn : Word;
  t: tp;

  procedure UpStr;var I:Byte;begin for I:=1 to Length(S) do S[I] := UpCase(S[I]) end;

begin
  if ParamCount < 1 then Usage;
  InitApMisc;
  s := ParamStr(1); UpStr;
  if (Length(s)<>4) or (Copy(s,1,3)<>'COM') or (not (s[4] in ['1'..'8'])) then
  begin
    WriteLn('Illegal COM Port - '+s); Usage;
  end;
  _ComNum := byte(s[4])-byte('0');

  if ParamCount > 1 then
  begin
    s := ParamStr(2);
    Val(s, _Speed, er);
    if er>0 then
    begin
      WriteLn('Illegal COM Speed - '+s); Usage;
    end;
  end else _Speed := 115200;


           {FossilPortPtr}

  if ParamCount = 3 then
  begin
    s := ParamStr(3); UpStr;
    if s = 'DEFAULT' then t := tDefault else
    if s = 'FOSSIL'  then t := tFossil  else
    if s = 'DIGI14'  then t := tDigi    else
    begin
      WriteLn('Illegal interface - '+s); Usage;
    end;
  end else t := tDefault;

  optn := ptReturnPartialGets +
          ptExecutePartialPuts +
          ptReturnDelimiter +
          ptDropModemOnClose +
          ptRaiseModemOnOpen +
          ptTrueOutBuffFree +
          ptRestoreOnClose;


  case t of
   tDefault : p := New(UARTPortPtr, InitCustom(ComNameType(_ComNum-1), _Speed, NoParity, 8, 1, bs, bs, optn));
   tFossil  : p := New(FossilPortPtr, InitCustom(ComNameType(_ComNum-1), _Speed, NoParity, 8, 1, bs, bs, optn));
   tDigi    : p := New(Digi14PortPtr, InitCustom(ComNameType(_ComNum-1), _Speed, NoParity, 8, 1, bs, bs, optn));
  end;

  if p = nil then
  begin
    WriteLn('Can''t initialize COM port!!!');
  end;
  CL_InitCOM := p;
end;

{$ENDIF} {-NLSLAVE-}

{$ENDIF DN}


{ ================================================================= }

procedure CL_DoneCOM;

{$IFDEF DN}
begin end;
{$ELSE}

{$IFDEF OS2}
begin
  rc := DosClose(HFILE(APort^));
end;
{$ELSE}
begin
  Dispose(AbstractPortPtr(APort), Done);
end;
{$ENDIF}

{$ENDIF DN}

procedure CL_NewTimer;
begin
  NewTimer(TEventTimer(Timer), Tics);
end;

function CL_TimerExpired;
begin
  CL_TimerExpired := TimerExpired(TEventTimer(Timer));
end;

procedure  CL_ClearTimer;
begin
  FillChar(Timer, TCL_TimerSz, 0);
end;

function  CL_TimerInstalled;
var
  ET : TEventTimer absolute Timer;
begin
  CL_TimerInstalled := (ET.StartTics<>0) or (ET.ExpireTics<>0);
end;


end.

aptimer
dosprocs
dostypess