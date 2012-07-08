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

unit ComLnk;

{$DEFINE CL_PACK}

{$I LINK.INC} interface

{$A+}

type
  TCL_BlockType = Byte;

const
   b_Nothing    = $FF;

   bt_DataZero  =  0;
   bt_Data      =  1;

{$IFDEF CL_PACK}
   bt_DataLZW   =  2;
{$ENDIF}

   bt_Spec      =  3;

   bt_SpcBits   =  2;
   bt_TypMask   =  (1 shl bt_SpcBits)-1;

   bt_NotSpc    =  not bt_TypMask;


 {*** bt_DataZero ***}

   b_GetDrvs    =  0 shl bt_SpcBits + bt_DataZero;

 {*** bt_DataUnp ***}

   b_Drives     =  1 shl bt_SpcBits + bt_Data;
   b_GetDir     =  2 shl bt_SpcBits + bt_Data;
   b_GetDirNfo  =  3 shl bt_SpcBits + bt_Data;
   b_Dir        =  4 shl bt_SpcBits + bt_Data;
   b_DirNfo     =  5 shl bt_SpcBits + bt_Data;
   b_GetFile    =  6 shl bt_SpcBits + bt_Data;
   b_dFileBlk   =  7 shl bt_SpcBits + bt_Data;
   b_dFileNfo   =  8 shl bt_SpcBits + bt_Data;
   b_cFileBlk   =  9 shl bt_SpcBits + bt_Data;
   b_cFileNfo   = 10 shl bt_SpcBits + bt_Data;
   b_DirValid   = 11 shl bt_SpcBits + bt_Data;
   b_EraseFile  = 12 shl bt_SpcBits + bt_Data;
   b_EraseDir   = 13 shl bt_SpcBits + bt_Data;
   b_MkDir      = 14 shl bt_SpcBits + bt_Data;
   b_IOstatus   = 15 shl bt_SpcBits + bt_Data;

 {*** bt_Spec0 ***}

   b_RemoteOK   = 1 shl bt_SpcBits + bt_Spec;
   b_SubBlkOK   = 2 shl bt_SpcBits + bt_Spec;
   b_Logon      = 3 shl bt_SpcBits + bt_Spec;
   b_LogonOK    = 4 shl bt_SpcBits + bt_Spec;
   b_ResendFull = 5 shl bt_SpcBits + bt_Spec;
   b_SRej0      = 6 shl bt_SpcBits + bt_Spec;
   b_NotifyLast = 7 shl bt_SpcBits + bt_Spec;

function  CL_InitComLink(AMaxBuf: LongInt; AMaxBlockSize, AStartBlockSize: Word): Boolean;
procedure CL_DoneComLink;
function  CL_QueueFree(BufSz: LongInt; Delta: Integer): Boolean;

procedure CL_Clear;
function CL_OK: Boolean;

function  CL_InputBlock(var AP: Pointer; var ASize: Word): TCL_BlockType;
procedure CL_PostBlock(P: Pointer; A_Size: Word; ATyp: TCL_BlockType);

function CL_GetBufPtr: Pointer;

procedure CL_FillNfo(var ANumErrs, ABlkSz: Word; var ATotalTrs: LongInt);

{$IFDEF CL_LOG}
procedure CL_WLog(const s: string);
procedure CL_Statux;
var CL_LogF : File;
{$ENDIF}

function DropCD: Boolean;

implementation uses Objects,Dos,

                    xTime, Advance,

                    ComLnkIO
                    ;


const
  CL_MaxRemoteOK = 4;

function SStr(L: LongInt): string; var s: string; begin Str(L, s); SStr := s end;

{$IFDEF CL_LOG}
procedure WLog(s: string);
begin
  s := 'btc'+ItoS(BiosTics^)+' '+s+#13#10; InOutRes := 0;

 {$IFDEF HARD_LOG}
  FileMode := 1;Reset(Cl_LogF, 1); if IOResult>0 then Exit;
  Seek(Cl_LogF, FileSize(Cl_LogF)); if IOResult>0 then Exit;
 {$ENDIF}

  BlockWrite(CL_LogF, s[1], Length(s));

 {$IFDEF HARD_LOG}
  Close(CL_LogF);
 {$ENDIF}

  InOutRes := 0;
end;

procedure CL_WLog(const s: string); begin WLog(s) end;

{$ENDIF}

procedure Halt_;
begin
  {$IFDEF CL_LOG}
  WLog('!!!! H A L T !!!!');
  Close(CL_LogF);
  {$ENDIF}
  RunError(221);
end;

const
  cDle  = 16;
  cXon  = 17;
  cXoff = 19;

  cBlkA   = ord('l');
  cBlkB   = ord('i');
  cBlkC   = ord('n');
  cBlkD   = ord('k');

  CBlkPrefix = cBlkA shl (8*0) +
               cBlkB shl (8*1) +
               cBlkC shl (8*2) +
               cBlkD shl (8*3) ;

  MinBlockSize   = 256;

  SuccessStep  = 8;

type
  TArr8 = array[0..7] of Byte;

  TCollectState = (
    stUnknown,
    stSeekPfx,
    stCollCRC,
    stCollHdr,
    stCollBlk
  );

  TransBlockPrefix = packed record
    Prefix : LongInt;
    CRC32  : TArr8;
  end;

  PTransBlockHeader = ^TTransBlockHeader;
  TTransBlockHeader = packed record { Transmition Block Header }
    ChkSum   : Byte; {Must be the first}
    Typ      : TCL_BlockType;
    case Byte of

       0 : ( Id        : LongInt;
             TotSize   : Word;
             SubSize   : Word;
             SubOfs    : Word);

       1 : ( LastSnt   : LongInt; {!!! The same as Id }
             FirstSnt  : LongInt; {!!! The same as TotSize & SubSize }
             Rsrvd1    : Word);   {!!! The same as SubOfs }

       2 : ( RqBegin   : LongInt; {!!! The same as Id }
             RqEnd     : LongInt; {!!! The same as TotSize & SubSize }
             Rsrvd2    : Word);   {!!! The same as SubOfs }
  end;

  PTransBlock    = ^TTransBlock;
  TTransBlock    = packed record { Outbound Block Header }
    Hdr     : TTransBlockHeader;
    Buf     : array[0..0] of Byte;
  end;

const
  TransBlkHdrSz = SizeOf(TTransBlockHeader);

type

  PSortedCL_Coll = ^TSortedCL_Coll;
  TSortedCL_Coll = object(TSortedCollection)
    constructor Init;
    procedure FreeItem(Item: Pointer); virtual;
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    function Volume: LongInt;
  end;

  TComState = (csLogon, csBegin, csOK);

  TZeroInitData = record
    TotTrs    : LongInt;
    NumErrs   : Word;
    Last4     : LongInt;
    CId       : LongInt;
    LastSntRj : TTransBlockHeader;
    LastSntBl : TTransBlockHeader;
    LastRcvBl : TTransBlockHeader;
    NeedClrId : LongInt;

    CollPos   : Word;
    CollCRC   : TArr8;

    RemoteOK  : Byte;
    APIok     : Boolean;

    SentAllTm : TCL_Timer;
  end;

  PLinkData = ^TLinkData;
  TLinkData = record
    Port      : Pointer;
    OutSpec   : PSortedCL_Coll;
    OutQueue  : PSortedCL_Coll;
    OutSent   : PSortedCL_Coll;
    InDirty   : PSortedCL_Coll;
    InClean   : PSortedCL_Coll;
    InSpec    : PSortedCL_Coll;

    z         : TZeroInitData;

    CollState : TCollectState;
    CollBlkAm : Word;
    TmpBufAm  : Word;

    TmpBuf    : PByteArray;

    ComState  : TComState;

    DelBlkSz  : Word;
    DelBlkPtr : Pointer;

    CharDLE   : Boolean;
    NeedDLE   : Boolean;

    MaxBuf    : LongInt;

    InCRC     : LongInt;
    InSize    : Word;

    CollBlk   : PTransBlock;

    SubBlkSz  : Word;
    MxOBlkSz  : Word;
    RcvBufSz  : Word;

    SuccessNm : Byte;
    EscTbl    : array[byte] of Boolean;
  end;

const
  TransPrfxSz   = SizeOf(TransBlockPrefix);
  SafeOutKeep   = $100;
  unk           = $FFFF;

var
  Lnk : PLinkData;

function DropCD: Boolean;
begin
  DropCD := CL_DCD(Lnk^.Port) = False;
end;

function CL_GetBufPtr: Pointer;
begin
  CL_GetBufPtr := Lnk^.TmpBuf;
end;

function CL_OK; begin Lnk^.z.APIok := Lnk^.ComState = csOK; CL_OK := Lnk^.z.APIok end;

procedure ClearRemoteOK;
begin with Lnk^.z do if RemoteOK<>0 then begin
  RemoteOK := 0;
  CL_ClearTimer(SentAllTm);
end end;

function BufdOut: LongInt;
begin
  with Lnk^ do
  BufdOut := OutSpec^.Volume  +
             OutQueue^.Volume +
             OutSent^.Volume  +
             InDirty^.Volume  +
             InClean^.Volume  +
             InSpec^.Volume;
end;

function DeltaSent: LongInt;
var
  MinId: LongInt;

procedure CalcMinId(P: PTransBlock); far;
begin with P^.Hdr do begin
  if (Typ and bt_TypMask) <> bt_Spec then if MinId > Id then MinId := Id;
end end;

begin
  MinId := Lnk^.z.CId;
  Lnk^.OutQueue^.ForEach(@CalcMinId);
  Lnk^.OutSent^.ForEach(@CalcMinId);
  DeltaSent := Lnk^.z.CId - MinId;
end;


{$IFDEF CL_LOG}

function ACSStr(ATyp: TComState): string;
begin
  case ATyp of
    csLogon   : ACSStr := 'csLogon';
    csBegin   : ACSStr := 'csBegin';
    csOK      : ACSStr := 'csOK';
   else ACSStr := '!!!== unknown TComState';
  end
end;

function ATypStr(ATyp: TCL_BlockType): string;
{$IFDEF CL_PACK}
var
  LZW: Boolean;
{$ENDIF}
begin
{$IFDEF CL_PACK}
  LZW := (ATyp and bt_TypMask) = bt_DataLZW;
  if LZW then ATyp := (ATyp and bt_NotSpc) or bt_Data;
{$ENDIF}

  case ATyp of
    b_IOstatus  : ATypStr := 'b_IOstatus';
    b_Nothing   : ATypStr := 'b_Nothing';
    b_GetDir    : ATypStr := 'b_GetDir';
    b_Drives    : ATypStr := 'b_Drives';
    b_Dir       : ATypStr := 'b_Dir';
    b_GetDirNfo : ATypStr := 'b_GetDirNfo';
    b_cFileBlk  : ATypStr := 'b_cFileBlk';
    b_cFileNfo  : ATypStr := 'b_cFileNfo';
    b_dFileBlk  : ATypStr := 'b_dFileBlk';
    b_dFileNfo  : ATypStr := 'b_dFileNfo';
    b_GetFile   : ATypStr := 'b_GetFile';
    b_DirNfo    : ATypStr := 'b_DirNfo';
    b_GetDrvs   : ATypStr := 'b_GetDrvs';
    b_RemoteOK  : ATypStr := 'b_RemoteOK';
    b_SubBlkOK  : ATypStr := 'b_SubBlkOK';
    b_ResendFull: ATypStr := 'b_ResendFull';
    b_SRej0     : ATypStr := 'b_SRej0';
    b_NotifyLast: ATypStr := 'b_NotifyLast';
    b_Logon     : ATypStr := 'b_Logon';
    b_LogonOK   : ATypStr := 'b_LogonOK';
   else ATypStr := '!!!== unknown TCL_BlockType (' + SStr(ATyp)+')';
  end
end;

procedure WrHdrNfo(const Pfx: string; const H: TTransBlockHeader);
begin
  with H do WLog(Pfx+'  Typ = '+ATypStr(Typ)+', Id = '+SStr(Id)+
  ', TS = '+ SStr(TotSize)+
  ', SO = '+ SStr(SubOfs)+
  ', SS = '+ SStr(SubSize)
  );

end;


procedure ShowColl(const s: string; P: PCollection);

procedure ShowIt(P: PTransBlock); far; begin WrHdrNfo(s, P^.Hdr) end;

begin
  P^.ForEach(@ShowIt);
end;

procedure CL_Statux;


begin
  with Lnk^ do
  WLog('                MA='+SStr(MemAvail)+', BufdO='+SStr(BufdOut)+
    ', SQc='+SStr(OutSpec^.Count)+
    ', OQc='+SStr(OutQueue^.Count)+
    ', OSc='+SStr(OutSent^.Count)+
    ', DIc='+SStr(InDirty^.Count)+
    ', CIc='+SStr(InClean^.Count)+
    ', DSn='+SStr(DeltaSent)+
    ', zCS='+ACSStr(ComState)
  );

  ShowColl('       *OutSent ', Lnk^.OutSent);
  ShowColl('       *InDirty ', Lnk^.InDirty);

end;

{$ENDIF}

{$IFDEF CL_PACK}

var
  LZWbuf : Pointer;

  le76, le77 : byte;
  InputOffs, InputSeg, OutPutOffs, OutPutSeg, Temp_offs, Temp_seg,
  le6A, le6C, le6E, le70, le72, le74, le78,
  le7A_0, le7A_2, le7A_4, le7A_6,
  le82a, le82b, OutPutOffs2 : word;

  CodeTable, PrefixTable, SymbolTable, CodeBuffer: LongInt;

  MaxCode, RunCode, RunningBits,
  CurCode, OldCode, CurBuffShift,
  TempSeg, Temp, DataSize: Word;


procedure LZWCompr; external;   {$L lzwc2}
procedure LZWDecompr; external; {$L lzwd2}

function LZW_Decompress(var Source,Dest): word; assembler;
asm
        mov     ax, word ptr LZWbuf[0]
        mov     bx, word ptr LZWbuf[2]
        mov     cx, word ptr Source[0]
        mov     dx, word ptr Source[2]
        mov     si, word ptr Dest[0]
        mov     di, word ptr Dest[2]
        call    LZWDecompr
end;

function LZW_Compress(var Source,Dest; Size:word): word; assembler;
asm
        mov     ax, Size
        mov     DataSize, ax
        mov     ax, word ptr LZWbuf[0]
        mov     bx, word ptr LZWbuf[2]
        mov     cx, word ptr Source[0]
        mov     dx, word ptr Source[2]
        mov     si, word ptr Dest[0]
        mov     di, word ptr Dest[2]
        call    LZWCompr
end;

const
        LZWCprBufSize  = 22*1024;
        LZWDcprBufSize = 18*1024;
{$ENDIF}



procedure InsertOutQ(P: PTransBlock);
begin
  CL_ClearTimer(Lnk^.z.SentAllTm);
  Lnk^.OutQueue^.Insert(P);
{$IFDEF CL_LOG}
  WrHdrNfo('@ InsOut',P^.Hdr);
{$ENDIF}
end;

procedure WaitNewBlk;
begin
  with Lnk^ do begin CollState := stSeekPfx; NeedDLE := False end;
end;

procedure ClearAll;
begin with Lnk^ do begin
  FillChar(z, SizeOf(z), 0);
  WaitNewBlk;
  z.LastSntBl.Id := -1;
  z.LastRcvBl.Id := -1;
  InDirty  ^. FreeAll;
  InClean  ^. FreeAll;
  InSpec   ^. FreeAll;
  OutQueue ^. FreeAll;
  OutSent  ^. FreeAll;
end end;

procedure CL_Clear;
begin
  ClearAll;
  Lnk^.ComState := csLogon;
end;

function DataBufSz(const Hdr: TTransBlockHeader): LongInt;
begin
  case (Hdr.Typ and bt_TypMask) of
    bt_DataZero,
    bt_Spec      : DataBufSz := 0;
    bt_Data
{$IFDEF CL_PACK}
    ,bt_DataLZW
{$ENDIF}
                 : DataBufSz := Hdr.SubSize;
   else Halt_;
  end;
end;

procedure Free_Mem(var AP; Size: Word);
var
  P: Pointer absolute AP;
begin
  FreeMem(P, Size); P := nil;
end;

procedure Get_Mem(var AP; Size: Word);
var
  P: Pointer absolute AP;
begin
  GetMem(P, Size);
end;


procedure FreeTrans(P: Pointer);
var
  A : PTransBlock absolute P;
  S : Word;
begin
  S := DataBufSz(A^.Hdr);
  Free_Mem(A, S + TransBlkHdrSz);
end;

function NewTrans(S: Word; AHdr: PTransBlockHeader): Pointer;
var
  P: PTransBlock;
begin
  Get_Mem(P, S+TransBlkHdrSz);
  with P^ do
  begin
    if AHdr<>nil then Hdr := AHdr^ else FillChar(Hdr, TransBlkHdrSz, 0);
    Hdr.SubSize := S;
  end;
  NewTrans := P;
end;

function SpecExist(AType: TCL_BlockType): Boolean;

function IsThis(P: PTransBlock): Boolean; far;
begin
  IsThis := P^.Hdr.Typ = AType;
end;

begin
  SpecExist := Lnk^.OutSpec^.FirstThat(@IsThis) <> nil;
end;


procedure InsertSpecQ(P: PTransBlock);
var cc: Word;
begin with Lnk^.OutSpec^ do begin
  cc := Count; Insert(P);
  if cc = Count then FreeTrans(P);
end end;

procedure GlobalNotify(AId: LongInt; ATyp: TCL_BlockType);
var
  P: PTransBlock;
begin
  P := NewTrans(0, nil);
  with P^.Hdr do
  begin
    Id  := AId;
    Typ := ATyp;
  end;
  InsertSpecQ(P);
end;

function AllocBlk(const Blk: TTransBlock): PTransBlock;
var
  S: Word;
  N: PTransBlock;
begin
  S := DataBufSz(Blk.Hdr);
  N := NewTrans(S, @Blk.Hdr); N^.Hdr.SubSize := Blk.Hdr.SubSize;
  if S>0 then Move(Blk.Buf, N^.Buf, S);
  AllocBlk := N;
end;

procedure LocInsSpec(P: PTransBlock);
begin
  if Lnk^.ComState <> csLogon then Lnk^.InSpec^.Insert(AllocBlk(P^));
end;

procedure InsertInSpec(P: PTransBlock);
var
  H: TTransBlockHeader;
begin
  H := P^.Hdr;
  case H.Typ of
    b_Logon      : begin
                     if Lnk^.ComState = csOK then
                     begin
                       ClearAll;
                       Lnk^.ComState := csBegin
                     end;
                     GlobalNotify(0, b_LogonOK)
                   end;
    b_LogonOK    : Lnk^.ComState := csBegin;
    b_NotifyLast : begin
                     if Lnk^.ComState = csBegin then Lnk^.ComState := csOK;
                     LocInsSpec(P);
                   end;
   else begin LocInsSpec(P) end;
  end;
end;


var
  CL_LastSgn: LongInt;

function Sgn(L: LongInt): LongInt;
begin
  if L = 0 then CL_LastSgn :=  0 else
  if L > 0 then CL_LastSgn := +1 else
                CL_LastSgn := -1;
  Sgn := CL_LastSgn;
end;

constructor TSortedCL_Coll.Init;
begin
  if not inherited Init(64,64) then Fail;
  Duplicates := True;
end;

function TSortedCL_Coll.Volume: LongInt;
var V: LongInt; procedure AddVol(Blk: PTransBlock); far; begin Inc(V, DataBufSz(Blk^.Hdr)) end;
begin V := 0; ForEach(@AddVol); Volume := V; end;

function CmpTransHdr(const Hdr1, Hdr2: TTransBlockHeader): Integer;
var
  AId: LongInt;
  ASo: LongInt;
begin
  with Hdr1 do begin AId := Id; ASo := SubOfs end;
  with Hdr2 do
  begin
    if Sgn(AId-Id)<>0     then CmpTransHdr := CL_LastSgn else
    if Sgn(ASo-SubOfs)<>0 then CmpTransHdr := CL_LastSgn else
                               begin CmpTransHdr := 0;
                                      end;


  end;
end;

function TSortedCL_Coll.Compare;
var
  A : PTransBlock absolute Key1;
  B : PTransBlock absolute Key2;
begin
  Compare := CmpTransHdr(A^.Hdr, B^.Hdr);
end;

procedure TSortedCL_Coll.FreeItem;
begin FreeTrans(Item) end;


function ByteSum(const ABuf; Cnt: LongInt): Byte;
var
  R: Byte;
  I: Word;
  Buf: TByteArray absolute ABuf;
begin
  R := 0;
  for I := 0 to Cnt-1 do Inc(R, Buf[I]);
  ByteSum := R;
end;

function FlushOB: Boolean;
begin
  with Lnk^ do begin
    if DelBlkSz > 0 then
    begin
      if CL_OutBuffFree(Port) > DelBlkSz then
      begin
        CL_PutBlock(Port, DelBlkPtr^, DelBlkSz);
        Free_Mem(DelBlkPtr, DelBlkSz);
        DelBlkSz := 0; DelBlkPtr := nil;
        FlushOB := True;
      end else FlushOB := False;
    end else FlushOB := True;
  end;
end;


procedure PutBlock(const Buf; Size: Word);
var
  a,b: LongInt;
  ar: TByteArray absolute Buf;
begin
  if not FlushOB then begin {$IFDEF CL_LOG}WLog('FlushOB Suxxxx');{$ENDIF} Halt_ end;
  with Lnk^ do
  begin
    a := CL_OutBuffFree(Lnk^.Port);
    if a>=Size then CL_PutBlock(Port, Buf, Size) else
    begin
      {$IFDEF CL_LOG}WLog('PutBlock-lazy!!!!');{$ENDIF}
      b := Size - a;
      CL_PutBlock(Port, Buf, a);
      Get_Mem(DelBlkPtr, b);
      Move(ar[a], DelBlkPtr^, b);
      DelBlkSz := b;
    end;
  end;
end;


function OutB_Free: Word;
var
  f,Result: LongInt;
begin
  FlushOB;
  if Lnk^.DelBlkSz > 0 then Result := 0 else
  begin
    f := CL_OutBuffFree(Lnk^.Port);
    if f<=SafeOutKeep then Result := 0 else Result := f-SafeOutKeep;
  end;
{$IFDEF CL_LOG}
  WLog('OutB_Free = '+SStr(Result));
{$ENDIF}
  OutB_Free := Result;
end;

function OutB_Used: Word;
begin
  FlushOB; OutB_Used := CL_OutBuffUsed(Lnk^.Port) + Lnk^.DelBlkSz;;
end;

procedure PackLI(L: LongInt; var Arr: TArr8);
var
  i: Byte;
begin
  for i := 0 to 7 do
  begin
    Arr[7-i] := (L and $F)+$40;
    L := L shr 4;
  end;
end;

function UnpackLI(Arr: TArr8; var LL: LongInt): Boolean;
var
  i: Byte;
  L: LongInt;
  b: Byte;
begin
  UnpackLI := False;
  L := 0;
  for i := 0 to 7 do
  begin
    L := L shl 4;
    b := Arr[i];
    if (b < $40) or (b>$4F) then Exit;
    Inc(L, b-$40);
  end;
  LL := L;
  UnpackLI := True;
end;

  function Calc_CRC(const Buffer; Len : Word; Crc32TableOfs : Word): LongInt; assembler;
    asm
      MOV     CX,Len                  {CX = Len}
      JCXZ    @@ucDone                {nothing to do if Len = 0}

      LES     SI,Buffer               {DS:SI => Buffer}
      XOR     AX,AX
      CWD
  @@ucNext:
      MOV     BL,AL                   {BL = AL}
      MOV     AL,[ES:SI]
      INC     SI
      XOR     BL,AL                   {XOR BL with AL}
      XOR     BH,BH                   {use result as index into DWORD table}
      SHL     BX,1
      SHL     BX,1
      MOV     AL,AH                   {shift DX:AX left 8 bits}
      MOV     AH,DL
      MOV     DL,DH
      XOR     DH,DH
      ADD     BX,Crc32TableOfs
      XOR     AX,[BX]                 {XOR with CRC table entry}
      XOR     DX,[BX+2]
      LOOP    @@ucNext                {repeat}
  @@ucDone:
  end;

function CalcCRC(const Buffer; Len : Word): LongInt;
begin
  CalcCRC := Calc_CRC(Buffer, Len, CL_GetCRC32ofs);
end;

function CL_QueueFree;
begin
  CL_QueueFree := (DeltaSent < Delta) and (Lnk^.ComState = csOK) and (BufdOut < BufSz);
end;

procedure SendSubBlk(var Blk: TTransBlock);
var
  Pfx : TransBlockPrefix;
  TS  : Word;
  I,O : Word;
  B   : Byte;
begin
  TS := DataBufSz(Blk.Hdr)+TransBlkHdrSz;
  {$IFDEF CL_LOG}
  WrHdrNfo('+ Sent ',Blk.Hdr);
  {$ENDIF}
  with Blk do Hdr.ChkSum := ByteSum(Hdr.Typ, TransBlkHdrSz-SizeOf(Hdr.ChkSum));
  PackLI(CalcCRC(Blk,TS),Pfx.CRC32);
  Pfx.Prefix := CBlkPrefix;
  Move(Pfx, Lnk^.TmpBuf^[0], TransPrfxSz);
  O := TransPrfxSz;
  for I := 0 to TS-1 do
  begin
    B := PByteArray(@Blk)^[I];
    if Lnk^.EscTbl[B]
     then begin Lnk^.TmpBuf^[O]:=cDle; Lnk^.TmpBuf^[O+1]:= B xor $40; Inc(O,2) end
     else begin Lnk^.TmpBuf^[O]:=B; Inc(O) end;
  end;
  PutBlock(Lnk^.TmpBuf^, O);
end;

procedure SendDataBlk(var Blk: TTransBlock);
begin
  if CmpTransHdr(Blk.Hdr, Lnk^.z.LastSntBl)>0 then Lnk^.z.LastSntBl := Blk.Hdr;
  ClearRemoteOK;
  SendSubBlk(Blk);
end;

procedure SendSpecBlk(var Blk: TTransBlock); begin SendSubBlk(Blk) end;

procedure StartSentAllTm; begin CL_NewTimer(Lnk^.z.SentAllTm, 5) end;

procedure NotifyState;
begin
  with Lnk^ do
  begin
    if ComState = csLogon then GlobalNotify(0, b_Logon) else
    begin
      z.LastSntBl.Typ := b_NotifyLast;
      SendSpecBlk(PTransBlock(Addr(z.LastSntBl))^);
    end;
    StartSentAllTm;
  end;
end;

procedure FlushQueue;
var
  CBS : Word;
  OB  : PTransBlock;
  OBH : TTransBlockHeader;
  NBO : PTransBlock;
  NBL : PTransBlock;
  NS  : Word;
  LS  : Word;
  SS  : Word;
begin

  repeat

    if OutB_Free < 100 then Exit;

    with Lnk^ do
    begin

      with OutSpec^ do
      while Count>0 do
      begin
        SendSpecBlk(PTransBlock(At(0))^); { Send special block without buffering }
        AtFree(0);
        if OutB_Free < 100 then Exit;
      end;

      if OutQueue^.Count = 0 then
      begin

        if z.RemoteOK < CL_MaxRemoteOK then
        begin
          if z.RemoteOK <> 0 then Inc(z.RemoteOK);
        end else Break;

          if CL_TimerInstalled(z.SentAllTm) then
          begin
            if (CL_TimerExpired(z.SentAllTm)) and
               (not SpecExist(b_Logon)) and
               (not SpecExist(b_NotifyLast)) then NotifyState;
          end else NotifyState;
        Break;
      end;

      if OutSpec^.Count > 0 then Continue;

      CBS := SubBlkSz;

    end;

    if OutB_Free < CBS then Break;

    OB := Lnk^.OutQueue^.At(0);

    OBH := OB^.Hdr;

    if (OBH.Typ and bt_TypMask) = bt_Spec then
    begin
      {$IFDEF CL_LOG}
      WrHdrNfo('!!! SpecBlock in DataOut Collection !!!', OBH);
      {$ENDIF}
      Halt_;
    end else
    begin
      SS := DataBufSz(OBH);
      if SS<=CBS then
      begin
        SendDataBlk(OB^); { Send last or single block with buffering }
        Lnk^.OutSent^.Insert(OB);
        Lnk^.OutQueue^.Delete(OB);
      end else
      begin
        if SS>CBS then NS := CBS else NS := SS;

        NBO := NewTrans(NS, @OBH);
        Move(OB^.Buf, NBO^.Buf, NS);
        LS := SS-NS;
        NBL := NewTrans(LS, @OBH); with NBL^ do
        begin
          Inc(Hdr.SubOfs,  NS);
          Move(OB^.Buf[NS], Buf, LS);
        end;
        with Lnk^ do
        begin
          OutQueue^.Free(OB);
          InsertOutQ(NBL);
          SendDataBlk(NBO^); { Send last or single block with buffering }
          Lnk^.OutSent^.Insert(NBO);
        end;
      end;
    end;
  until False;
end;


procedure Insss(P: Pointer; ASize: Word; ATyp: TCL_BlockType);
var
  OB : PTransBlock;
begin
  OB := NewTrans(ASize, nil);
  if ASize > 0 then Move(P^, OB^.Buf, ASize);
  with OB^.Hdr do
  begin
    Id       := Lnk^.z.CId; Inc(Lnk^.z.CId);
    TotSize  := ASize;
    SubOfs   := 0;
    Typ      := ATyp;
  end;
  InsertOutQ(OB);
end;

procedure CL_PostBlock;
var
  ns,ss : LongInt;
  cs : Word;
  pp : PWordArray;
  ASize : LongInt;


procedure FreeLoc;
begin
  FreeMem(pp, ns);
end;

begin
  ASize := A_Size;
  Inc(Lnk^.z.TotTrs, ASize);
  repeat
   {$IFDEF CL_PACK}
    if (Test8086>=2) and (ASize>10) then
    begin
      ns := (ASize * 8) div 5+10;
      if (ns < $FF00) and (ns + LZWCprBufSize < MemAvail) then
      begin
        GetMem(pp, ns);
        cs := ASize;
        GetMem(LZWbuf,LZWCprBufSize);
        cs := LZW_Compress(P^, pp^[1], cs);
        FreeMem(LZWbuf, LZWCprBufSize);
        ss := cs; ss := (ss * 7) div 5;
        if ss<ASize then
        begin
          pp^[0] := ASize;
          Insss(pp, cs+2, (ATyp and bt_NotSpc) or bt_DataLZW);
          FreeLoc;
          Break;
        end;
        FreeLoc;
      end;
    end;
   {$ENDIF}
    Insss(p, ASize, ATyp);
  until True;
  FlushQueue;
end;

procedure NewBlk; begin with Lnk^ do begin CollState := stCollCRC; NeedDLE := False; z.CollPos := 0 end end;

procedure InsertClean(B: PTransBlock);
{$IFDEF CL_PACK}
var
  ss,s: Word;
  H: TTransBlockHeader;
  N: PTransBlock;
{$ENDIF}
begin
{$IFDEF CL_PACK}
  H := B^.Hdr;
  if (H.Typ and bt_TypMask) = bt_DataLZW then
  begin
    s := Word(Addr(B^.Buf[0])^);
    N := NewTrans(s, Addr(H)); N^.Hdr.TotSize := s;
    GetMem(LZWbuf, LZWDcprBufSize);
    if LZW_Decompress(PWordArray(Addr(B^.Buf))^[1], N^.Buf) <> s then Halt_;
    FreeMem(LZWbuf, LZWDcprBufSize);
    N^.Hdr.Typ := (H.Typ and bt_NotSpc) or bt_Data;
    FreeTrans(B); B := N;
  end;
{$ENDIF}
  Lnk^.InClean^.Insert(B);
  Inc(Lnk^.z.NeedClrId);
  Inc(Lnk^.z.TotTrs, B^.Hdr.TotSize);
end;

procedure InsertDirty(B: PTransBlock);begin Lnk^.InDirty^.Insert(B) end;

procedure PasteClean(First, Last: Word);
var
  I       : Word;
  A, N    : PTransBlock;
begin
  {$IFDEF CL_LOG}WLog('+++ PasteClean');{$ENDIF}
  A := Lnk^.InDirty^.At(First); N := NewTrans(A^.Hdr.TotSize, Addr(A^.Hdr));
  Move(A^.Buf, N^.Buf, A^.Hdr.SubSize);
  for I := First+1 to Last do
  begin
    A := Lnk^.InDirty^.At(I);
    with A^ do Move(Buf, N^.Buf[Hdr.SubOfs], Hdr.SubSize);
  end;
  for I := First to Last do Lnk^.InDirty^.AtFree(First);
  InsertClean(N);
end;

procedure ProcessCollDataBlk;
var
  B     : PTransBlock;
  BHdr  : TTransBlockHeader;
  F,S   : Integer;
  LSub  : Word;
  PId   : LongInt;
  PPs   : LongInt;
begin
  B := AllocBlk(Lnk^.CollBlk^);

  if B^.Hdr.Id < Lnk^.z.NeedClrId
     then begin {$IFDEF CL_LOG}WrHdrNfo(' & already rcvd!!! ', B^.Hdr);{$ENDIF} Halt_ end
     {$IFDEF CL_LOG}else WrHdrNfo('- InData', B^.Hdr){$ENDIF};


  if B^.Hdr.TotSize = B^.Hdr.SubSize then
  begin
    if Lnk^.z.NeedClrId = B^.Hdr.Id then begin {$IFDEF CL_LOG}WLog('--- Insert Clean ');{$ENDIF}InsertClean(B) end
                                  else
   begin
     {$IFDEF CL_LOG}WLog('=== Dirty Tot:  HdrId='+SStr(B^.Hdr.Id)+', NeedId='+SStr(Lnk^.z.NeedClrId));{$ENDIF}
     InsertDirty(B)
   end;
  end else
  begin
    InsertDirty(B);
  end;

  S := 0; PId := -1;
  while S < Lnk^.InDirty^.Count do
  begin
    B := Lnk^.InDirty^.At(S); BHdr := B^.Hdr;

    if Lnk^.z.NeedClrId <> BHdr.Id then
    begin
      {$IFDEF CL_LOG}WLog('=== Dirty Sub: HdrId='+SStr(BHdr.Id)+', NeedId='+SStr(Lnk^.z.NeedClrId));{$ENDIF}
      Break;
    end;

    repeat
      if PId = -1 then
      begin
        if BHdr.SubOfs=0 then
        begin
          if BHdr.SubSize = BHdr.TotSize then
          begin
            {$IFDEF CL_LOG}WLog('--- Catch Clean ');{$ENDIF}
            InsertClean(B);
            Lnk^.InDirty^.AtDelete(S);
            Dec(S);
          end else
          begin
            PId := BHdr.Id; F := S;  LSub := BHdr.SubSize;
          end;
        end;
        Break;
      end else
      begin
        if PId = BHdr.Id then
        begin
          if BHdr.SubOfs = LSub then Inc(LSub, BHdr.SubSize) else begin PId := -1; Break end;
          if LSub = BHdr.TotSize then
          begin
            PasteClean(F, S); S := F-1; PId := -1;
          end;
          Break;
        end else
        begin {PId<>Id}
          PId := -1;
          Continue;
        end;
      end;
    until False;
    Inc(S);
  end;
end;


procedure DecSubSize;
begin
  with Lnk^ do
  begin
    if SubBlkSz > MinBlockSize then SubBlkSz := SubBlkSz div 2;
    Inc(z.NumErrs);
  end;
end;

function InRange(A, Mn, Mx: Integer): Boolean;
begin
  InRange := (A>Mn) and (A<Mx);
end;

function Cross(a1, a2, b1, b2: Integer): Boolean;
begin
  Cross := InRange(a1, b1, b2) or
           InRange(a2, b1, b2) or
           InRange(b1, a1, a2) or
           InRange(b2, a1, a2);
end;

const
  cob_FullBlk    = True;
  cob_PartialBlk  = False;

procedure FreeCL_Coll(AC: PSortedCL_Coll; AId : LongInt; ASubSz, ASubOfs: Word; Easy: Boolean);
var
  i, c, ao, ho: LongInt;
  H: TTransBlockHeader;
  Fre: Boolean;
begin
  c := AC^.Count; if c = 0 then Exit; ao := ASubOfs + ASubSz; i:=0;
  while i < c do
  begin
    H := PTransBlock(AC^.At(i))^.Hdr;
    Fre := False;
    if AId = H.Id then
    begin
      ho := H.SubOfs + H.SubSize;
      if Easy then Fre := Cross(ASubOfs, ao, H.SubOfs, ho);
      Fre := Fre or ((H.SubOfs >= ASubOfs) and (ho <= ao));
    end;
    if Fre then begin AC^.AtFree(i); Dec(c) end else Inc(i);
  end;
end;

procedure FreeOB(AId : LongInt; ASubSz, ASubOfs: Word);begin FreeCL_Coll(Lnk^.OutSent, AId, ASubSz, ASubOfs, False) end;

function ReturnIt(   var H : TTransBlockHeader;
                         P : PTransBlock;
                         i : Integer;
                        cc : Word;
                       AId : LongInt;
   ATotSz, ASubSz, ASubOfs : Word;
                      Full : Boolean): PTransBlock;

var
  ds: Word;
  N: PTransBlock;

procedure MoveData(sz: word);
begin
  {$IFDEF CL_LOG}
  WLog('   ^ mdat ds='+SStr(ds)+', sz='+SStr(sz)+', TotSz = '+SStr(H.TotSize)+', ASubSz='+SStr(ASubSz));
  WrHdrNfo('~       ',P^.Hdr);
  {$ENDIF}
  if (ds+sz>H.TotSize) or (ds+sz>ASubSz) then
  begin
    Halt_
  end;
  Move(P^.Buf, N^.Buf[ds], sz);
  Inc(ds, sz);
  Lnk^.OutSent^.AtFree(i); Dec(cc);
end;


begin
  if Full then
  begin
    ATotSz := H.TotSize;
    ASubSz := ATotSz;
  end else if ATotSz <> H.TotSize then begin {$IFDEF CL_LOG}WLog('TotSz Mismatch!!!');{$ENDIF} Halt_ end;
  if ASubSz = H.SubSize then
  begin
    ReturnIt := P;
    Lnk^.OutSent^.AtDelete(i); Dec(cc);
    Exit;
  end else
  begin
    N := NewTrans(ASubSz, @H);
    ds := 0;
    MoveData(H.SubSize);
    while (i < cc) and (ds < ASubSz) do
    begin
      P := Lnk^.OutSent^.At(i);
      if P^.Hdr.Id <> AId then begin {$IFDEF CL_LOG}WLog('Invalid AId!!!');{$ENDIF} Halt_ end;
      if P^.Hdr.SubOfs <> ds+H.SubOfs then
      begin
        {$IFDEF CL_LOG}WLog('SubOfs Mismatch!!!');{$ENDIF} Halt_
      end;
      if P^.Hdr.TotSize <> ATotSz then begin {$IFDEF CL_LOG}WLog('Invalid ATotSz!!!');{$ENDIF} Halt_ end;
      MoveData(P^.Hdr.SubSize);
    end;
    if Full then
    if ds <> ASubSz then
    begin
      {$IFDEF CL_LOG}WLog('ds <> ASubSj !!!');{$ENDIF} Halt_
    end;
    ReturnIt := N;
  end;
end;

function CompileOB(AId : LongInt; ATotSz, ASubSz, ASubOfs : Word; Full: Boolean): PTransBlock;

{ Return the desired block and delete it from OutSent}

var
  i, cc: LongInt;
  P: PTransBlock;
  H: TTransBlockHeader;

begin
  {$IFDEF CL_LOG}  WLog('ccc CompileOB  AId='+SStr(AId)+
  ', TotSz='+SStr(ATotSz)+', SubSz='+SStr(ASubSz)+', ASubOfs='+SStr(ASubOfs));
  {$ENDIF}

  cc := Lnk^.OutSent^.Count; i := 0;
  while i < cc do
  begin
    P := Lnk^.OutSent^.At(i); H := P^.Hdr;
    if (AId = H.Id) and (ASubOfs = H.SubOfs) then
    begin
      CompileOB := ReturnIt(H, P, i, cc, AId, ATotSz, ASubSz, ASubOfs, Full);
      Exit
    end;
    Inc(i);
  end;
  {$IFDEF CL_LOG}WLog('CompileOB - not found!!!');{$ENDIF} Halt_
end;

procedure NotifyHdr(const Blk: TTransBlock; ATyp: TCL_BlockType);
var
  B: PTransBlock;
  S: Word;
  H: TTransBlockHeader;
begin
  with Blk do
  begin
    H := Hdr; H.Typ := ATyp;
    S := DataBufSz(H);
    B := NewTrans(S, @H);
    B^.Hdr.SubSize := H.SubSize;
    if S>0 then Move(Buf, B^.Buf, S);
  end;
  InsertSpecQ(B);
end;

procedure NotifyColl(ATyp: TCL_BlockType); begin NotifyHdr(Lnk^.CollBlk^, ATyp) end;

function FoundDirtyIn(AId: LongInt; var Ps: Integer): Boolean;
var
  P,C: Integer;
begin
  P := Ps;
  C := Lnk^.InDirty^.Count;
  while P < C do
  begin
    if PTransBlock(Lnk^.InDirty^.At(P))^.Hdr.Id = AId then
    begin
      Ps := P;
      FoundDirtyIn := True;
      Exit;
    end;
    Inc(P);
  end;
  FoundDirtyIn := False;
end;

const
  cForcedResend = True;
  cNormalResend = False;

procedure SendSRej0(AId: LongInt; ATotSz, ASubSz, ASubOfs: Word; Force: Boolean);
var
  P: PTransBlock;
  N: Boolean;
begin
  P := NewTrans(0, nil);
  with P^.Hdr do
  begin
    Typ     := b_SRej0;
    Id      := AId;
    TotSize := ATotSz;
    SubSize := ASubSz;
    SubOfs  := ASubOfs;
  end;
  with Lnk^ do
  begin
    N := CmpTransHdr(P^.Hdr, z.LastSntRj) > 0;
    if N then z.LastSntRj := P^.Hdr;
    if N or Force then InsertSpecQ(P)
                  else FreeTrans(P);
  end;
end;

procedure ReqFullResend(AB, AE: LongInt; Force: Boolean);
var
  L,D: LongInt;
  P: PTransBlock;
begin
  D := Lnk^.z.LastSntRj.Id;

  if not Force then
   if D > AB then AB := D;

  if D < AE then
  with Lnk^.z.LastSntRj do
  begin
    Id := AE;
    TotSize := 0;
    SubSize := 0;
    SubOfs  := 0;
  end;

  if AB > AE then Exit;

  P := NewTrans(0, nil);
  with P^.Hdr do
  begin
    Typ      := b_ResendFull;
    RqBegin  := AB;
    RqEnd    := AE;
    Rsrvd2   := 0;
  end;

  InsertSpecQ(P);

end;

procedure NoteLast(const A_Hdr: TTransBlockHeader);

{ Last block remote send is [AId/ATotSz/ASubSz/ASubOfs] }
{ Request absent parts }

var
  Dlt : LongInt;
  PtrOfs, i, cc: Word;
  L, H: TTransBlockHeader;
  P: PTransBlock;
  ok : Boolean;
  lp : Boolean;

  procedure RFR(f,t: LongInt);
  begin ReqFullResend(f, t, cForcedResend); ok := False end;

  procedure SRj(A: LongInt; B, C, D: Word);
  begin SendSRej0(A, B, C, D, cForcedResend); ok := False end;

  procedure Chk(AId: LongInt; ATotSz, ASubOfs: Word);
  begin                                          {SubSize}   {SubOfs}
    if PtrOfs < ASubOfs then SRj(AId, ATotSz, ASubOfs-PtrOfs, PtrOfs);
  end;

  procedure ChkIt;
  begin with H do Chk(Id, TotSize, SubOfs) end;

  procedure ChkJump;
  begin
    if L.SubOfs = unk then RFR(L.Id,H.Id-1) else
    begin
      with L do Chk(Id, TotSize, TotSize);
      if dlt>1 then RFR(L.Id+1,H.Id-1)
    end;
    PtrOfs := 0; ChkIt;
  end;

  procedure Compare;
  begin
    Dlt := H.Id - L.Id;
    if Dlt = 0 then ChkIt else ChkJump;
    PtrOfs := H.SubOfs + H.SubSize;
  end;

begin
  cc := Lnk^.InDirty^.Count;
  H.Id  := Lnk^.z.NeedClrId;
  H.SubOfs := unk;
  i := 0; PtrOfs := 0;
  ok := True;
  if A_Hdr.Id >= Lnk^.z.NeedClrId then
  begin

    while i<cc do
    begin
      L := H;
      P := Lnk^.InDirty^.At(i);
      H := P^.Hdr; Inc(i);
      NotifyHdr(P^, b_SubBlkOK);
      {$IFDEF CL_LOG}WrHdrNfo('   ^^^ ',H);{$ENDIF}
      Compare;
    end;

    L := H; H := A_Hdr;

    lp := (L.Id=H.Id) and (L.SubOfs=H.SubOfs);

    Compare;

    if not lp then with H do SRj(Id, TotSize, SubSize, SubOfs);

  end;

  if ok then NotifyHdr(TTransBlock((@A_Hdr)^), b_RemoteOK);

end;


procedure AnswerFullResend(var B, E: LongInt);
var
  I: LongInt;
begin
  for I := B to E do InsertOutQ(CompileOB(I, 0, 0, 0, cob_FullBlk));
end;


procedure ReqSkipped(const Hdr1, Hdr2: TTransBlockHeader);
var
  A, B, so, ss, ts, e: LongInt;
begin
  A := Hdr1.Id;
  B := Hdr2.Id;
  if A < B then
  begin
    with Hdr1 do begin so := SubOfs; ss := SubSize; ts := TotSize end;

    e := so + ss;
    if e < ts then SendSRej0(A, ts, ts-e, e, cNormalResend);

    Inc(A);

    if A >= B-1 then ReqFullResend(A, B-1, cNormalResend);
  end;

end;

procedure FreeLess(AColl: PCollection; const AH: TTransBlockHeader);
var
  c,i: Word;
  LH: TTransBlockHeader;
begin
  c := AColl^.Count; i := 0;
  while i<c do
  begin
    LH := PTransBlock(AColl^.At(i))^.Hdr;
    if CmpTransHdr(AH, LH) >= 0 then
    begin
      AColl^.AtFree(i); Dec(c);
    end
    else Inc(I);
  end;
end;


procedure ProcessSpecIn;
var
  B, NtLast, RmtOK: TTransBlockHeader;
  P: PTransBlock;
  i, c: LongInt;
  cRFull, cSRej, cSubOK: TSortedCL_Coll;

procedure SeekFull(AId: LongInt);
var
  Cnt: Word; Z: TTransBlockHeader;
begin
  Cnt := 0;
  while Cnt < cRFull.Count do
  begin
    Z := PTransBlock(cRFull.At(Cnt))^.Hdr;              {Poka tak}
    if (Z.RqBegin <= AId) and (Z.RqEnd >= AId) then cRFull.AtFree(Cnt) else Inc(Cnt);
  end;
end;

procedure DoSubOK(P: PTransBlock); far;
var H: TTransBlockHeader;
begin
  H := P^.Hdr; with H do
  begin
    SeekFull(Id);
    FreeCL_Coll(@cSRej, Id, SubSize, SubOfs, True);
    FreeOB(Id, SubSize, SubOfs)
  end;
end;

procedure DoFull(P: PTransBlock); far;
var H: TTransBlockHeader;
begin
  H := P^.Hdr; with H do AnswerFullResend(RqBegin, RqEnd);
end;

procedure Ins(A: PCollection);
var cc: Word;
begin
  cc := A^.Count; A^.Insert(P);
  if cc = A^.Count then Lnk^.InSpec^.AtFree(i) else Lnk^.InSpec^.AtDelete(i);
  Dec(c)
end;

procedure SetSpc(var AH: TTransBlockHeader);
begin
  AH := B; Lnk^.InSpec^.AtFree(i); Dec(c);
end;

  {$IFDEF CL_LOG}
procedure SC;
begin
  ShowColl('       *cRFull ', @cRFull);
  ShowColl('       *cSRej  ', @cSRej);
  ShowColl('       *cSubOK ', @cSubOK);
end;
  {$ENDIF}

begin
  c := Lnk^.InSpec^.Count; if c = 0 then Exit;

  i := 0;

  {$IFDEF CL_LOG} WLog('ProcessSpec----------------'); {$ENDIF}

  NtLast.SubOfs := unk;
  RmtOk.SubOfs := unk;

  cRFull.Init; cRFull.Duplicates := False;
  cSRej .Init; cSRej .Duplicates := False;
  cSubOK.Init; cSubOK.Duplicates := False;

  {cRemoteOK := False; cLogon := False; cLogonOK := False;}

  while i < c do
  begin
    P := Lnk^.InSpec^.At(i); B := P^.Hdr;
    case B.Typ of
       b_RemoteOK   : SetSpc(RmtOK);
       b_NotifyLast : SetSpc(NtLast);
       b_ResendFull : Ins(@cRFull);
       b_SRej0      : Ins(@cSRej);
       b_SubBlkOK   : Ins(@cSubOK);
      else Halt_;
    end;
  end;

  {$IFDEF CL_LOG} SC; {$ENDIF}

  if RmtOK.SubOfs <> unk then
  begin
    if Lnk^.z.RemoteOK <= CL_MaxRemoteOK then Inc(Lnk^.z.RemoteOK);
    FreeLess(Lnk^.OutQueue, RmtOK);
    FreeLess(Lnk^.OutSent, RmtOK);
    FreeLess(@cRFull, RmtOK);
    FreeLess(@cSRej, RmtOK);
    FreeLess(@cSubOK, RmtOK);
  end;

  cSubOK.ForEach(@DoSubOK);

  c := cSRej.Count-1; if c>=0 then
  begin
    DecSubSize;
    while i<=c do
    begin
      P := cSRej.At(i);
      B := P^.Hdr; with B do
      begin
        SeekFull(Id);
        InsertOutQ(CompileOB(Id, TotSize, SubSize, SubOfs, cob_PartialBlk));
        repeat
          if i<c then
          begin
            P := cSRej.At(i+1);
            if (P^.Hdr.Id = Id) and (SubOfs+SubSize>P^.Hdr.SubOfs) then
            begin
              cSRej.AtFree(i+1);
              Dec(c);
              Continue;
            end;
          end;
          Break;
        until False;
      end;
      Inc(i);
    end;
  end;

  cRFull.ForEach(@DoFull);

  if NtLast.SubOfs <> unk then
  begin
    {if NtLast.Id = -1 then NotifyHdr(TTransBlock((@NtLast)^), b_RemoteOK) else}
    begin
      if CmpTransHdr(Lnk^.z.LastRcvBl, NtLast) <= 0 then
      begin
        {$IFDEF CL_LOG} WLog('********DoNoteLast'); {$ENDIF}
        NoteLast(NtLast);
      end else
      begin
        {$IFDEF CL_LOG} WLog('********SkipNoteLast'); {$ENDIF}
      end;
    end;
  end;

  cRFull.Done;
  cSRej.Done;
  cSubOK.Done;

end;


procedure ArrivedOK; { Insert & Send Notification }
begin
 with Lnk^ do begin
  WaitNewBlk;
  if (CollBlk^.Hdr.Typ and bt_TypMask) <> bt_Spec then
  begin
    ClearRemoteOK;
    {$IFDEF CL_LOG}WrHdrNfo('o Rcvd Data', CollBlk^.Hdr);{$ENDIF}
    {if not IsNextBlock(LastRcvBl, CollBlk.Hdr) then ReqSkipped(LastRcvBl, CollBlk.Hdr);}
    NotifyColl(b_SubBlkOK);
    if CmpTransHdr(CollBlk^.Hdr, z.LastRcvBl) > 0 then z.LastRcvBl := CollBlk^.Hdr;
    ProcessCollDataBlk;
  end else
  begin
    {$IFDEF CL_LOG}WrHdrNfo('i Rcvd Spec', CollBlk^.Hdr);{$ENDIF}
    InsertInSpec(CollBlk);
  end;
 end;
end;

function Uniq(const Blk: TTransBlock): Boolean;
var
  Dummy: Integer;
  uq: Boolean;
  NC: LongInt;
  BI: LongInt;
begin
  Uniq := False;

  if (Blk.Hdr.SubSize + Blk.Hdr.TotSize) > MemAvail then Exit;

  if Lnk^.ComState = csLogon then
  begin
    {$IFDEF CL_LOG}
    CL_Statux;
    WrHdrNfo(' ComState=csLogon to receive DataBlock ', Blk.Hdr);
    {$ENDIF}
    Exit;
  end;

  if Lnk^.z.NeedClrId > Blk.Hdr.Id then
  begin
    {$IFDEF CL_LOG}
    CL_Statux;
    WrHdrNfo(' NeedClrId > Blk.Hdr.Id ', Blk.Hdr);
    {$ENDIF}
    Exit;
  end;

  if Lnk^.InDirty^.Search(@Blk, Dummy) then
  begin
    {$IFDEF CL_LOG}
    CL_Statux;
    WrHdrNfo(' Already Received ', Blk.Hdr);
    {$ENDIF}
    Exit;
  end;

  if BufdOut > Lnk^.MaxBuf then
  begin
    {$IFDEF CL_LOG}
    CL_Statux;
    WrHdrNfo(' Buf Overflow ', Blk.Hdr);
    {$ENDIF}
    Exit;
  end;

  Uniq := True;
end;

procedure Drop;
begin
  {$IFDEF CL_LOG}WLog('-drop!');{$ENDIF}
  if Lnk^.CollState = stCollBlk then with Lnk^.CollBlk^.Hdr do
    SendSRej0(Id, TotSize, SubSize, SubOfs, cNormalResend);
  WaitNewBlk;
end;

procedure Collect;
const
  ClSize = $1000;
var
  gs: Boolean;


  ClBuf: array[0..ClSize] of byte;
  GotNow: Word;
  I: Word;
  B: Byte;
  FoundPfx: Boolean;


begin
  gs := False;

  with Lnk^ do
  repeat

    GotNow := CL_GetBlock(Port,ClBuf,ClSize);
    if GotNow = 0 then Exit;

    if not GS then
    begin
      {$IFDEF CL_LOG}
        WLog('Got something');
      {$ENDIF}
      GS := True;
    end;



    for I:= 0 to GotNow-1 do
    begin
      B := ClBuf[I];

      z.Last4 := z.Last4 shr 8;
      PByteArray(Addr(z.Last4))^[3] := B;

      if NeedDLE then
        if CharDLE then begin CharDLE := False; B := B xor $40 end
                   else if B = cDle then begin CharDLE := True; Continue end;

      FoundPfx := z.Last4 = CBlkPrefix;

      case CollState of
        stSeekPfx : if FoundPfx then begin NewBlk; (*{$IFDEF CL_LOG}WLog('&&&&');CL_Statux{$ENDIF}*) end;
        stCollCRC : if FoundPfx then NewBlk else
           begin
             z.CollCRC[z.CollPos] := B;
             if z.CollPos = 7 then
             begin
               if UnpackLI(z.CollCRC, InCRC) then
               begin
                 NeedDLE := True;
                 CollState := stCollHdr;
                 z.CollPos := 0;
               end
               else
               Drop;
             end else Inc(z.CollPos);
           end;
        stCollHdr : if FoundPfx then NewBlk else
           begin
             PByteArray(Addr(CollBlk^.Hdr))^[z.CollPos] := B;
             if z.CollPos = TransBlkHdrSz-1 then
             begin
               if ByteSum(CollBlk^.Hdr.Typ, TransBlkHdrSz-SizeOf(CollBlk^.Hdr.ChkSum)) = CollBlk^.Hdr.ChkSum then
               begin
                 {$IFDEF CL_LOG}WrHdrNfo(' b Rcvd ',CollBlk^.Hdr);{$ENDIF}
                 if ((CollBlk^.Hdr.Typ and bt_TypMask) <> bt_Spec) and (not Uniq(CollBlk^)) then
                 Drop
                 else
                 begin
                   InSize := DataBufSz(CollBlk^.Hdr);
                   if InSize = 0 then ArrivedOK else
                   if InSize > RcvBufSz then Halt_ else
                   begin
                     CollState := stCollBlk;
                     z.CollPos := 0;
                   end;
                 end;
               end
               else
               Drop;
             end else Inc(z.CollPos);
           end;
        stCollBlk :
             if FoundPfx then
             begin
               Drop;
               NewBlk
             end else
             begin
               CollBlk^.Buf[z.CollPos] := B;
               Inc(z.CollPos);
               if z.CollPos = InSize then
               begin
                 if CalcCRC(CollBlk^, z.CollPos + TransBlkHdrSz) <> InCRC
                   then
                   Drop
                   else
                 begin
                   if Uniq(CollBlk^) then ArrivedOK else NewBlk;
                 end;
               end else
             end;
      end;

    end;
  until False;
end;


function CL_InitComLink;
var
  Ptr : Pointer;
begin
  CL_InitComLink := False;
  Ptr := CL_InitCOM;
  if Ptr = nil then Exit;
  New(Lnk); FillChar(Lnk^, SizeOf(TLinkData), 0);
  with Lnk^ do
  begin
    Port := Ptr;

    InDirty  := New(PSortedCL_Coll, Init);
    InClean  := New(PSortedCL_Coll, Init);
    InSpec   := New(PSortedCL_Coll, Init);
    OutQueue := New(PSortedCL_Coll, Init);
    OutSent  := New(PSortedCL_Coll, Init);
    OutSpec  := New(PSortedCL_Coll, Init); OutSpec^.Duplicates := False;

    FillChar(EscTbl, SizeOf(EscTbl), False);

    EscTbl[ cDle   ]:=True;
    EscTbl[ cBlkA  ]:=True;
    EscTbl[ cBlkB  ]:=True;
    EscTbl[ cBlkC  ]:=True;
    EscTbl[ cBlkD  ]:=True;

    EscTbl[ cXon   ]:=True;
    EscTbl[ cXoff  ]:=True;

    RcvBufSz := AMaxBlockSize;

    MxOBlkSz := CL_OutBuffFree(Port) div 3;
    while AMaxBlockSize > MxOBlkSz do AMaxBlockSize := AMaxBlockSize div 2;

    if AStartBlockSize < AMaxBlockSize
     then SubBlkSz := AStartBlockSize
     else SubBlkSz := AMaxBlockSize;

    MxOBlkSz := AMaxBlockSize;

    TmpBufAm  := (TransBlkHdrSz+MxOBlkSz)*2+TransPrfxSz;
    CollBlkAm := TransBlkHdrSz+RcvBufSz;

    GetMem(CollBlk, CollBlkAm);
    GetMem(TmpBuf, TmpBufAm);

    MaxBuf := AMaxBuf;

    ClearAll;

  end;

  CL_InitComLink := True;
end;

procedure CL_DoneComLink;
begin
  with Lnk^ do
  begin
    Dispose(InDirty, Done);
    Dispose(InClean, Done);
    Dispose(InSpec, Done);
    Dispose(OutQueue, Done);
    Dispose(OutSent, Done);
    Dispose(OutSpec, Done);

    FreeMem(CollBlk, CollBlkAm);
    FreeMem(TmpBuf, TmpBufAm);

    CL_DoneCOM(Port);
  end;
  Dispose(Lnk);
end;


function NumInSrejs: Integer;
var
  n: Integer;

procedure CalcSRejs(P: PTransBlock); far;
begin
  if P^.Hdr.Typ = b_SRej0 then Inc(n);
end;

begin
  n := 0;
  Lnk^.InSpec^.ForEach(@CalcSRejs);
  NumInSrejs := n;
end;

function  CL_InputBlock;
var
  B    : PTransBlock;
  Size : Word;
  P    : PByteArray;
begin
  {$IFDEF CL_LOG}CL_Statux;{$ENDIF}
  Collect;
  if (NumInSrejs = 0) or (Lnk^.OutQueue^.Count = 0) then ProcessSpecIn;
  FlushQueue;
  P := nil; Size := 0;
  if (not Lnk^.z.APIok) or (Lnk^.InClean^.Count = 0) then CL_InputBlock := b_Nothing else
  begin
    B := Lnk^.InClean^.At(0);
    Size := DataBufSz(B^.Hdr);
    {$IFDEF CL_LOG}WLog('-+- Size = '+SStr(Size));{$ENDIF}
    CL_InputBlock := B^.Hdr.Typ;
    if Size > 0 then
    begin
      Get_Mem(P, Size); Move(B^.Buf, P^, Size);
    end;
    Lnk^.InClean^.AtFree(0);
  end;
  ASize := Size;
  AP    := P;
end;

procedure CL_FillNfo;
begin with Lnk^ do begin
  ANumErrs := z.NumErrs;
  ATotalTrs := z.TotTrs;
  ABlkSz := SubBlkSz;
end end;

end.

