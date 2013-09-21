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

UNIT CDPlayer;

{.$DEFINE UPD}

INTERFACE

USES xTime, Dialogs, Drivers, Objects, Views, ObjType;

CONST
  CDplace: Tpoint = ( X:0; Y:0 );
  CDsize: Tpoint = ( X:0; Y:0 );
  CDparams: array[ 1..3 ] of word = ( 3, 0, 0 );
  CDmixer : string[80]= '';

  CD_Player: PView = nil;

PROCEDURE RunPlayer;
PROCEDURE RegisterCDplayer;

{$IFDEF UPD}
PROCEDURE UpdateCDplayer;
{$ENDIF}

CONST
  cpNormal = 0;
  cpIntro  = 1;
  cpShuffle= 2;
  cpOne    = 3;
  cpOrder  = 4;

  cpAutoplay  = 1;
  cpAutoEject = 2;
  cpLockDoor  = 4;
  cpRepeat    = 8;

  cpTrack     = 0;
  cpLeftTrack = 1;
  cpDisk      = 2;
  cpLeftDisk  = 3;


TYPE
  _Status = ( noDisk, Play, Stopped, Paused, newDisk );

  _Err = record
     Stat: byte;
     Code: byte;
  end;

  _Diskinfo = record
    FirstTrack, LastTrack: byte;
    LeadStart: Longint;
  end;

  _TrackInfo = record
     case Boolean of
       True: ( CFrame: byte;
               CSec: byte;
               CMin: byte;
               CC: byte;
               CStat: byte );
       False: ( Addr: longint;
                Stat: byte )
  end;

  _TLen = record LSec, Lmin: byte end;

  _Tracks = array[ 1..100 ] of _TrackInfo;
  _Tlens  = array[ 1..100 ] of _Tlen;
  _Order  = array[ 1..100 ] of byte;

  _QChannel = record
     ADR,
     TNO,
     IDX,
     Rmin,
     RSec,
     Rfrm,
     Rzero,
     AMin,
     Asec,
     Afrm: byte;
     Stat: word;
   end;

  _UpcCode = record
    ADR: byte;
    UPC: array[ 1..7 ] of byte;
    ZERO,
    AFrame: byte;
  end;

  PCounter = ^TCounter;
  TCounter = object( TView )
    Line: array[ 1..3 ] of string[ 30 ];
    Constructor Init( R: Trect );
    Procedure SetCounter( T, A, B: byte );
    Destructor Done; virtual;
    Procedure Draw; virtual;
    procedure Awaken; virtual;
  end;

  PCdPlayer = ^TCdPlayer;
  TCdPlayer = Object( TDialog )
    DiskOk: boolean;
    CdDisk: integer;
    LowTrack,
    HighTrack: byte;
    DiskMin,
    DiskSec: byte;
    Tracks: _tracks;

    { new }
    DiskId    : Longint;
    DiskTitle : PString;
    Descr : PLineCollection ;
    TrkDescr : String;
    TrkOrder : String;
    TrkPlay  : String;
    { new }

    TLen: _tlens;
    Order: _Order;
    Counter: PCounter;
    Info0: PParamText;
    Info1: PParamText;
    Info2: PParamText;
    Qchannel: _Qchannel;
    UpdCnt: TEventTimer;
    NewPlay: TEventTimer;
    reqHdr: array[ 0..49 ] of byte;
    Status: _Status;
    Err: _Err;
    LastShuffle: byte;
    Parm: array[ 1..3 ] of longint;
    Parmt: longint;
    ParmD: longint;
   { Parm0: string[ 10 ];
     Parm1: string[ 10 ]; }
    Parm2: string[ 20 ];
    CD_Loaded : boolean ;
    Constructor Init( R: Trect; ACdDisk: integer );
    Procedure   InitInterior;
    Procedure   LoadDiskInfo;
    Procedure   Display( T, M, S: byte );
    Destructor  Done; virtual;
    Procedure   Update; virtual;
    Procedure   HandleEvent( var Event: Tevent );virtual;
    Procedure   Zoom; Virtual;
    Function    Valid( Command: Word ): Boolean; virtual;
    procedure   Store( var S: TStream ); virtual;
    constructor Load( var S: TStream );
    procedure   Awaken; virtual;
    procedure   SizeLimits(var Min, Max: TPoint); virtual;

  private
    procedure  _SetOrder;

    procedure  _Play;
    procedure  _Stop;
    procedure  _Next;
    procedure  _Prev;
    procedure  _Pause;
    procedure  _Eject;
    procedure  _Load;
    procedure  _FForward;
    procedure  _FRewind;
    procedure  _Setup;
    procedure  _Mix;
    procedure  _Door( DLock: Boolean );
    procedure  _Song( ASong : byte )  ;

    function   _DiskStatus: boolean;
    function   _DiskIsChanged: boolean;


    Function MakeTrackList : PLineCollection ;
    Procedure SelectTrack ;
    Procedure SelectOrder ;
    Procedure GetDescription ;
    Function  GetOrder : boolean ;

  end;

CONST
  RCdplayer: TStreamRec = (
  ObjType: otCdplayer;
  VmtLink: Ofs( TypeOf( TCdPlayer )^ );
  Load: @TCDplayer.Load;
  Store: @TCDplayer.Store );

  RCDCounter: TStreamRec = (
  ObjType: otCDCounter;
  VmtLink: Ofs( TypeOf( TCounter )^ );
  Load: @TCounter.Load;
  Store: @TCounter.Store );

IMPLEMENTATION

USES Advance, Messages, Commands, RStrings, DNHelp, DOS, DnApp, Startup,
     CDUtil ;

CONST
  cdDrive: integer = -1;

PROCEDURE RegisterCDplayer;
begin
  RegisterType( RCdPlayer );
  RegisterType( RCdCounter );
end;


const
  Crc32Table : array[0..255] of LongInt = (
  $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f, $e963a535,
  $9e6495a3, $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd,
  $e7b82d07, $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de, $1adad47d,
  $6ddde4eb, $f4d4b551, $83d385c7, $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec,
  $14015c4f, $63066cd9, $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
  $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b, $35b5a8fa, $42b2986c,
  $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59, $26d930ac,
  $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599, $b8bda50f,
  $2802b89e, $5f058808, $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab,
  $b6662d3d, $76dc4190, $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
  $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb,
  $086d3d2d, $91646c97, $e6635c01, $6b6b51f4, $1c6c6162, $856530d8, $f262004e,
  $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950, $8bbeb8ea,
  $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65, $4db26158, $3ab551ce,
  $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
  $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9,
  $5005713c, $270241aa, $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409,
  $ce61e49f, $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81,
  $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a, $ead54739,
  $9dd277af, $04db2615, $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
  $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344, $8708a3d2, $1e01f268,
  $6906c2fe, $f762575d, $806567cb, $196c3671, $6e6b06e7, $fed41b76, $89d32be0,
  $10da7a5a, $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5, $d6d6a3e8,
  $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
  $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
  $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236, $cc0c7795, $bb0b4703,
  $220216b9, $5505262f, $c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7,
  $b5d0cf31, $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c, $026d930a,
  $9c0906a9, $eb0e363f, $72076785, $05005713, $95bf4a82, $e2b87a14, $7bb12bae,
  $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
  $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777, $88085ae6,
  $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69, $616bffd3, $166ccf45,
  $a00ae278, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $4969474d,
  $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5,
  $47b2cf7f, $30b5ffe9, $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
  $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94,
  $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d
  );

var
  Crc32TableOfs : Word;

function UpdateCrc32(CurByte : Byte; CurCrc : LongInt) : LongInt;
  {-Returns an updated crc32}

  (* Model for inline code below
  UpdateCrc32 := Crc32Table[Byte(CurCrc xor LongInt(CurByte))] xor
                 ((CurCrc shr 8) and $00FFFFFF);
  *)

Inline(
                         {;Get args -- DX:BX = CurCrc, CX = CurByte;}
  $5B/                   {        POP     BX}
  $5A/                   {        POP     DX}
  $59/                   {        POP     CX}
  $52/                   {        PUSH    DX}
  $53/                   {        PUSH    BX      ;Save original CurCrc}
                         {;CX:AX := Get Crc32Table[CurCrc xor CurByte];}
  $31/$CB/               {        XOR     BX,CX   ;DX:BX = CurCrc xor CurByte}
  $30/$FF/               {        XOR     BH,BH   ;Byte(DX:BX)}
  $D1/$E3/               {        SHL     BX,1    ;LongInt index}
  $D1/$E3/               {        SHL     BX,1}
  $03/$1E/>CRC32TABLEOFS/{        ADD     BX,[>Crc32TableOfs]}
  $8B/$07/               {        MOV     AX,[BX]}
  $8B/$4F/$02/           {        MOV     CX,[BX+2]}
                         {;DX:BX := (CurCrc shr 8) and $00FFFFFF;}
  $5B/                   {        POP     BX      ;Get original CurCrc}
  $5A/                   {        POP     DX}
  $51/                   {        PUSH    CX      ;Save CX}
  $B9/$08/$00/           {        MOV     CX,8    ;Shift 8 bits}
  $D1/$EA/               {C1:     SHR     DX,1    ;Hi reg into carry}
  $D1/$DB/               {        RCR     BX,1    ;Carry into lo reg}
  $E2/$FA/               {        LOOP    C1      ; for 8 bits}
  $81/$E2/$FF/$00/       {        AND     DX,$00FF}
                         {;DX:AX := ES:AX xor DX:BX (sets function result)}
  $59/                   {        POP     CX}
  $31/$D8/               {        XOR     AX,BX}
  $89/$CB/               {        MOV     BX,CX}
  $31/$DA);              {        XOR     DX,BX}


Function GetCrc( var Buf ; BufSize : word ) : Longint ;
type
  AA = array[1..$F000] of byte ;
var CNT : word;
    CRC : Longint;
 begin
    Crc32TableOfs := Ofs(Crc32Table);
    CRC := 0;
    GetCrc := 0;
     if BufSize = 0 then Exit;
       for CNT :=1 to BufSize do
       CRC := UpdateCrc32(AA(Buf)[CNT] , Crc );
    GetCrc := CRC ;
 end;



FUNCTION CD_GetFirstDrive( var firstDrive: Integer ): integer; assembler;
asm
  mov ax, $1500
  mov bx, 0
  int $2f
  mov ax, bx {;# of drives }
  les bx, firstDrive
  mov es:[ bx ].word, cx
end;

FUNCTION CD_Req( drv: integer;
                  cmd: byte;
                  size: integer;
                  Var reqHdr: array of byte ):boolean;
var Buf: Pointer;

begin
  reqHdr[ 1 ] := 0;
  reqHdr[ 2 ] := cmd;
  reqHdr[ 0 ] := 20;
  Buf := System.Addr( reqHdr[ 20 ] );
  move( Buf, reqHdr[ 14 ], sizeOf( Buf ));
  reqHdr[ 18 ]:= lo( size );
  reqHdr[ 19 ]:= hi( size );
  asm
    les bx, reqHdr
    mov cx, drv
    mov ax, $1510
    int $2f
  end;

  CD_req := reqHdr[ 4 ] and $80 = $80;
  (*
    if ( reqHdr[ 4 ] and $80 ) > 0 { Error! } then begin
      if ( reqHdr[ 3 ] = 2 ) or ( reqHdr[ 3 ] = 12 ) then begin
        Writeln( 'Error: no disk in drive' );
        exit;
      end else
        Writeln( 'Error ', reqHdr[ 3 ], ' cmd ', reqHdr[ 20 ] );
      end
  *)
end;

FUNCTION CD_IsChanged( drive: integer ): boolean;
var
   reqHdr: array[ 0..39 ] of byte;
   Err: byte;
 begin
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );
  reqHdr[ 20 ] := 9; { Changed? cmd }
  CD_Req( drive, 3, 1, reqHdr );
  CD_IsChanged := ( reqHdr[ 21 ] = $FF );
 end;

FUNCTION CD_IsPaused( drive: integer ): boolean;
var
   reqHdr: array[ 0..39 ] of byte;
   Err: byte;
 begin
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );
  reqHdr[ 20 ] := 15; { AudioStat cmd }
  CD_Req( drive, 3, 3, reqHdr );
  CD_IsPaused := ( reqHdr[ 21 ] and 1 = 1 );
 end;


FUNCTION CD_IsDiskPresent( drive: integer ): boolean;
var
   reqHdr: array[ 0..39 ] of byte;
   Err: byte;
   devpar: WORD;
 begin
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );
  reqHdr[ 20 ] := 6; { DiskStat cmd }
  Err := 0;
  if CD_Req( drive, 3, 5, reqHdr ) then Err := reqHdr[ 3 ];
  move( reqHdr[ 21 ], devpar, sizeOf( devPar ));
{  CD_IsDiskPresent := (( reqHdr[ 22 ] and $1 ) = 1 ) and}
   CD_IsDiskPresent := ( DevPar and { $801} 1 = 0 ) and
   (( Err <> 2 ) and ( Err <> 12 ))
 end;

PROCEDURE CD_DiskInfo( drive: integer; var buf );
var
   reqHdr: array[ 0..39 ] of byte;
   Err: byte;
 begin
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );
  reqHdr[ 20 ] := 10; { Disk Info cmd }
  CD_Req( drive, 3, 7, reqHdr );
  move( reqHdr[ 21 ], buf, 6 );
end;

PROCEDURE CD_TrackInfo( drive, track: integer; var buf );
var
   reqHdr: array[ 0..39 ] of byte;
   Err: byte;
 begin
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );
  reqHdr[ 20 ]:= 11; { Track Info cmd }
  reqHdr[ 21 ]:= track;
  CD_Req( drive, 3, 7, reqHdr );
  move( reqHdr[ 22 ], buf, 5 );
end;


PROCEDURE CD_Status( drive: integer; var  buf: _Qchannel );
var
 reqHdr: array[ 0..39 ] of byte;
 Err: byte;
begin
 fillchar( reqHdr, SizeOf( reqHdr ), 0 );
 reqHdr[ 20 ]:=12; { Track Info cmd }
 reqHdr[ 21 ]:=1;
 CD_Req( drive, 3, 11, reqHdr );
 move( reqHdr[ 21 ], buf, 10 );
 with Buf do
  begin
     TNO :=(( TNO and $f )+(( TNO and $f0 )) * 10 div 16 );
     Move( reqHdr[ 3 ], STAT, sizeof( STAT ));
  end;
end;

(*
PROCEDURE CD_UpcCode( drive: integer; var  buf: array of byte );
var
   reqHdr: array[ 0..39 ] of byte;
   UP: _UpcCode;
       Err: byte;
begin
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );

 reqHdr[ 20 ]:=14; { UPC Info cmd }
 reqHdr[ 21 ]:=1;
 CD_Req( drive, 3, 11, reqHdr );
 move( reqHdr[ 21 ], UP, SizeOF( UP ));
 move( UP.UPC, buf, 7 );
end;

*)

FUNCTION CD_Stop( drv: integer; var reqHdr: array of byte ): word;
var
   statBuf: array[ 0..19 ] of byte;
   C: word;
   CC: array[ 1..2 ] of byte absolute C;
begin
  fillchar( reqHdr, SizeOf( reqHdr ), 10 );

  reqHdr[ 1 ]:=0;
  reqHdr[ 2 ]:=133;
  reqHdr[ 0 ]:=$5;

 asm
  les bx, reqHdr
  mov cx, drv
  mov ax, $1510
  clc
  int $2f
 end;

 Move( reqHdr[ 3 ], CC, 2 );

 CD_Stop := C;
 (*
if ( reqHdr[ 4 ] and $80 ) > 0 { Error! } then
 begin
  if ( reqHdr[ 3 ] = 2 ) or ( reqHdr[ 3 ] = 12 ) then
  begin
   Writeln( 'Error: no disk in drive' );
   exit;
  end else
   Writeln( 'Error ', reqHdr[ 3 ], ' cmd ', reqHdr[ 20 ] );
  end;
 *)

end;

(*


FUNCTION CD_PlayTracks( drv , fromTrack, toTrack: integer ): boolean;

var
   reqHdr: array[ 0..39 ] of byte;

   SAddr ,
   TAddr: _TrackInfo;

   DM, DS, DF: integer;
   TL: longint;

 begin
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );
  CD_PlayTracks := false;

 if ( fromTrack > toTrack ) or
    ( fromTrack < diskInfo.firstTrack ) or
    ( toTrack > diskInfo.lastTrack ) then
 begin
  Writeln( 'Bad track #' ); exit;
 end;

 if ( til[ fromTrack ].stat and $40 > 0 ) then
 begin
  Writeln( 'track ', fromTrack, ' is data' );
  exit;
 end;

 if not ( CD_IsPaused( drv )) then
 begin
  CD_Stop( drv ); { Always stop before playing! }
  CD_Stop( drv ); { Always stop before playing! }
 end;

 reqHdr[ 1 ]  := 0;
 reqHdr[ 2 ]  := 132;
 reqHdr[ 0 ]  := $16;
 reqHdr[ $d ] := 1; { Red book address mode }

 SAddr := til[ fromTrack ];
 move( Saddr, reqHdr[ $E ], 4 );

 Taddr := til[ toTrack+1 ];

 DM :=  Taddr.CMin - SAddr.Cmin;
 DS :=  Taddr.CSec - SAddr.CSec;
 DF :=  Taddr.CFrame - SAddr.CFrame;

 if DF < 0 then begin  Dec( DS ); inc( DF, 75 ) end;
 if DS < 0 then begin  Dec( DM ); inc( DS, 60 ) end;

 TAddr.CMin   := DM;
 TAddr.Csec   := DS;
 TAddr.Cframe := DF;

 TL := Longint( Longint( DM ) * 4500 + Longint( DS ) * 75 + DF - 150 );

 move( TL, reqHdr[ $12 ] , 4 );

 writeln( 'track ', fromTrack, '-', toTrack, ' at ', Saddr.Cmin,
     ':', Saddr.CSec, ' len ', DM, ':', DS );
  asm
  mov ax, ss
  mov es, ax
  lea bx, reqHdr
  mov cx, drv
  mov ax, $1510
  int $2f
  end;

 end;

*)
FUNCTION CD_Play( drv: integer; FromTrack, toTrack: _TrackInfo;
                  var reqHdr: array of byte ): boolean;

var
   {reqHdr: array[ 0..39 ] of byte;}

   DM, DS, DF: integer;
   TL: longint;

 begin
  fillchar( reqHdr, SizeOf( reqHdr ), $12 );
  CD_Play := false;
 if ( fromTrack.stat and $40 > 0 ) then Exit;
 if not ( CD_IsPaused( drv )) then
 begin
  CD_Stop( drv, reqHdr ); { Always stop before playing! }
  CD_Stop( drv, reqHdr ); { Always stop before playing! }
 end;
 reqHdr[ 1 ]  := 0;
 reqHdr[ 2 ]  := 132;
 reqHdr[ 0 ]  :=$16;
 reqHdr[ $d ] := 1; { Red book address mode }
 move( FromTrack, reqHdr[ $E ], 4 );
 DM :=  toTrack.CMin - FromTrack.Cmin;
 DS :=  toTrack.CSec - FromTrack.CSec;
 DF :=  toTrack.CFrame - FromTrack.CFrame;
 if DF < 0 then begin  Dec( DS ); inc( DF, 75 ) end;
 if DS < 0 then begin  Dec( DM ); inc( DS, 60 ) end;
 TL := Longint( Longint( DM ) * 4500 + Longint( DS ) * 75 + DF - 150 );
 move( TL, reqHdr[ $12 ] , 4 );

  asm
  les bx, reqHdr
  mov cx, drv
  mov ax, $1510
  int $2f
  end;

 end;




FUNCTION CD_GetDriverVersion:integer;assembler;
 asm
  mov ax, $150C
  int $2f
  mov ax, bx
 end;


PROCEDURE  TimeSub( var M1, S1: integer; M2, S2: byte );
    begin
      Inc( S1, 60 );
      Dec( S1, S2 );
      Dec( M1, M2 );
      if S1>59 then DEC( S1, 60 )
               else DEC( M1 );
     end;

PROCEDURE  TimeAdd( var M1, S1: integer; M2, S2: byte );
    begin
      Inc( S1, S2 );
      Inc( M1, M2 );
      if S1>59 then begin
                     DEC( S1, 60 );
                     Inc( M1 );
                    end;
     end;


(*
PROCEDURE CD_ShowInf( drive: integer );

var i, m, s, mb, ml, sb, sl: integer;
    statBuf: _Qchannel;
    dig: array[ 1..7 ] of byte;
begin

 I := CD_GetDriverVersion;

 Writeln( ^M^J'Drier version is ', hi( I ), '.', lo( I ));

 Writeln( 'Tracks ', diskInfo.firstTrack, ' to ', diskInfo.lastTrack );
 Writeln( 'track: start   len' );

  for i := diskInfo.firstTrack to diskInfo.lastTrack do

 begin

  M  := til[ i ].cmin;
  S  := til[ i ].csec;

  Mb := til[ i+1 ].cmin;
  Sb := til[ i+1 ].csec;

  ml:=mb-m;
  sl:=sb-s;

  if ( sl < 0 ) then begin inc( sl, 60 ); dec( ml ); end;
     Writeln( i:3, ': ', m:2, ':', s:2, '   ', ml:2, ':', sl:2 );
 end;

 CD_Status( drive, statBuf );

 Writeln( 'status =', statBuf.Stat );

 if ( CD_IsPaused( cdDrive )) then
  write( ^M^J^M^J'CD Paused at' )
 else
  write( ^M^J^M^J'Now playing' );
  Writeln( ' track ', statBuf.TNO, ' at ', statBuf.Rmin, ':', statBuf.Rsec );


  CD_UpcCode( drive, Dig );

  Write( 'Universal Product Code is :' );
  for I := 0 to 12 do
   begin
     m := Dig[ 1+ ( i shr 1 ) ];
     if i and 1 = 0 then m := m shr 4;
     m := m and $f;
     Write( m );
   end;
  Writeln;

end;

 *)

PROCEDURE GetDigit( Dig: byte; var S: string );
begin
  case Dig of
       0: S := 'ÜÜÜÛ ÛÛÜÛ';
       1: S := '  Ü  Û  Û';
       2: S := 'ÜÜÜÜÜÛÛÜÜ';
       3: S := 'ÜÜÜÜÜÛÜÜÛ';
       4: S := 'Ü ÜÛÜÛ  Û';
       5: S := 'ÜÜÜÛÜÜÜÜÛ';
       6: S := 'ÜÜÜÛÜÜÛÜÛ';
       7: S := 'ÜÜÜ  Û  Û';
       8: S := 'ÜÜÜÛÜÛÛÜÛ';
       9: S := 'ÜÜÜÛÜÛÜÜÛ';
{n}  $6E: S := '   ÜÜÜÛ Û';
{o}  $6F: S := '   ÜÜÜÛÜÛ';
{C} { $43: S := 'ÜÜÜÛ  ÛÜÜ';}
{D} { $44: S := 'ÜÜ Û ÛÛÜß';}
{C}  $43: S := '   ÜÜÜÛÜÜ';
{D}  $44: S := '   ÜÜ ÛÜÛ';

     else S := '         ';
  end;
end;

  {
       ÜÜÜ ÜÜÜ ÜÜÜ ÜÜÜ ÜÜÜ Ü Ü   ÜÜÜ
       ÛÜÛ ÛÜÛ   Û ÛÜÜ ÛÜÜ ÛÜÛ ß ÜÜÛ
       ÛÜÛ ÜÜÛ   Û ÛÜÛ ÜÜÛ   Û ß ÜÜÛ
       ÜÜÜ ÜÜÜ   ÜÜÜ ÜÜ
       Û Û ÛÜÛ   ÛÜÜ ÛÜÛ
  }


  Constructor TCounter.Init;
  var I: byte;
        begin
            R.B.Y := R.A.Y + 3;
            R.B.X := R.A.X + 18 + 9;
            inherited Init( R );
            for I := 1 to 3 do Line[ i ] := Strg(' ', Pred( SizeOf( Line[ i ] )));

         end;

PROCEDURE TCounter.Awaken;
    var I: byte;
  begin
    inherited Awaken;
    for I := 1 to 3 do Line[ i ] := Strg(' ', Pred( SizeOf( Line[ i ] )));
  end;

PROCEDURE TCounter.SetCounter( T, A, B: byte );
  var S: String[ 9 ];
      I: byte;
PROCEDURE InsertText( From: byte );
   var I: byte;
    begin
      for I := 1 to 3 do Move( S[ pred( I )*3+1 ], Line[ I, From ], 3 );
    end;
      begin
      for I:=1 to 3 do fillChar( Line[ I, 1 ], Length( Line[ I ] ), 32 );
      if T < $FF then
        begin
           GetDigit( T div 10, S ); InsertText( 1 );
           GetDigit( T mod 10, S ); InsertText( 5 );
           if T > 0 then
           begin
            S := Strg(' ', 9 ); if A > 9 then GetDigit( A div 10, S );
            InsertText( 10 );
            GetDigit( A mod 10, S ); InsertText( 14 );
            GetDigit( B div 10, S ); InsertText( 20 );
            GetDigit( B mod 10, S ); InsertText( 24 );
            Line[ 2, 9+9 ] := 'ß';
            Line[ 3, 9+9 ] := 'ß';
           end;
         end
        else
         begin
           GetDigit( $6E, S ); InsertText( 1 );
           GetDigit( $6F, S ); InsertText( 5 );

           GetDigit( $43, S ); InsertText( 10 );
           GetDigit( $44, S ); InsertText( 14 );
         end;
      end;
PROCEDURE TCounter.Draw;
  var C, I: byte;
      T: TdrawBuffer;
      begin
      C  := GetColor( 1 );
      for I := 0 to Pred( Size.Y ) do
       begin
        MoveStr( T, Line[ I+1 ], C );
        WriteLine( 0, I, Size.X, Succ( I ), T );
       end;
      end;
  Destructor TCounter.Done;
      begin
        Inherited Done;
      end;

CONSTRUCTOR TCdPlayer.Init;
var
  R1: Trect;
  TR : word ;
begin
 {if CD_GetFirstDrive( cdDrive ) = 0 then Fail;}
  R1 := R;
  R1.B.X := R1.A.X + 36;
  R1.B.Y := R1.A.Y + 8;

  if R.B.Y - R.A.Y > 8 then begin
    R.B.X := R.A.X + 36;
    R.B.Y := R.A.Y + {10}15;
  end else
    R := R1;
    {R.Assign( 1, 4, 35, 9 );  }   { 34 7 59 12 }
    {R.Assign( 1, 4, 60, 14 ); }
  inherited Init( R, GetString( dlCDPlayer ));
  {Options := Options or ofCentered;}
  Flags := Flags or wfZoom;

  ZoomRect := R1;
  CdDisk := ACDdisk;

  {$ifdef upd}
  NewTimer( UpdCnt, 18 );
  {$else}
  UpdTicks := 18;
  RegisterToBackGround( @Self );
  {$endif}

  HelpCTX := hcCDplayer;

    DiskId    := 0 ;
    DiskTitle := Nil;
    New(Descr,Init(100,10));
    for TR :=1 to 100 do Descr^.Insert(Nil);

  InitInterior;
  LoadDiskInfo;
end;

PROCEDURE TCdPlayer.Awaken;
begin
  inherited Awaken;
end;

PROCEDURE TCdPlayer.Store;
begin
  inherited Store( S );
  PutSubViewPtr( S, Counter );
  PutSubViewPtr( S, Info0 );
  PutSubViewPtr( S, Info1 );
  PutSubViewPtr( S, Info2 );
  S.Write( Order, SizeOf( Order ));
  S.Write( LastShuffle, SizeOf( LastShuffle ));
  S.Write( CDParams, SizeOf( CDParams));

  {!!SF}
  S.Write( DiskId , SizeOF(DiskId) ) ;
  S.WriteStr( DiskTitle );
  S.Put( Descr );
  S.WriteStr( @TrkOrder );
  S.WriteStr( @TrkPlay );

 end;

constructor TCdPlayer.Load;
var P : PString;
begin
  inherited Load( S );
  GetSubViewPtr( S, Counter );
  GetSubViewPtr( S, Info0 );
  GetSubViewPtr( S, Info1 );
  GetSubViewPtr( S, Info2 );
  S.Read( Order, SizeOf( Order ));
  S.Read( LastShuffle, SizeOf( LastShuffle ));
  S.Read( CDParams, SizeOf( CDParams ));

  {!!SF}
  S.Read( DiskId , SizeOF(DiskId) ) ;
  DiskTitle := S.ReadStr;
  Descr := PLineCollection(S.Get);
  P := S.ReadStr; TrkOrder := CnvString(P); DisposeStr(P);
  P := S.ReadStr; TrkPlay := CnvString(P); DisposeStr(P);

  UpdTicks := 18;
  RegisterToBackGround( @Self );
  CD_Player := @Self;
  {Coder := GlobalMessage( evCommand, cmXdata+1, nil );}
  CD_GetFirstDrive( CdDisk );
  LoadDiskInfo;
  Update;
  Redraw;
end;


PROCEDURE  TCdPlayer.InitInterior;
var
  R: TRect;
  Control, Labl, Histry: PView;
  D: array[ 1..2 ] of PString;

  Y : byte ;
begin
  Y := 6;

  R.Assign( 1, Y, 7, Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonRew), cdFRew, bfBroadcast ));
  Insert( Control );

  R.Assign( 7, Y, 12, Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonPrev), cdPrev, bfBroadcast ));
  Insert( Control );

  R.Assign( 12, Y, 23, Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonPlay), cdPlay, bfBroadcast ));
  Insert( Control );

  R.Assign( 23, Y, 28, Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonNext), cdNext, bfBroadcast ));
  Insert( Control );

  R.Assign( 28, Y, 34, Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonFFwd), cdFFwd, bfBroadcast ));
  Insert( Control );

  inc(Y,2);
  R.Assign( 1, Y, 10, Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonPause), cdPause, bfBroadCast ));
  Insert( Control );

  R.Move(9,0); Inc(R.B.X,6);
  Control := New( PButton, Init( R, GetString(dlCDButtonStop), cdStop, bfBroadcast ));
  Insert( Control );

  R.Move(15,0); Dec(R.B.X,6);
  Control := New( PButton, Init( R, GetString(dlCDButtonEject), cdEject, bfBroadCast ));
  Insert( Control );


  inc(Y,2);
  R.Assign( 1,  Y, 12,  Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonSet), cdSetup, bfBroadCast ));
  Insert( Control );

  R.Move( 11, 0 );
  Control := New( PButton, Init( R, GetString(dlCDButtonTime), cdDisplay, bfBroadCast ));
  Insert( Control );

  R.Move( 11, 0 );
  Control := New( PButton, Init( R, GetString(dlCDButtonMode), cdMode, bfBroadCast ));
  Insert( Control );

  inc(Y,2);
  R.Assign( 1, Y, 12,  Y+2 );
  Control := New( PButton, Init( R, GetString(dlCDButtonMix), cdMix, bfBroadCast ));
  Insert( Control );

  R.Move( 11, 0 );
  Control := New( PButton, Init( R, GetString(dlCDButtonOrder), cdOrder, bfBroadCast ));
  Insert( Control );

  R.Move( 11, 0 );
  Control := New( PButton, Init( R, GetString(dlCDButtonTitle), cdTitle, bfBroadCast ));
  Insert( Control );


  {
  R.Assign( 56, 2, 57, 8 );
  Control := New( PScrollbar, Init( R ));
  Dlg^.Insert( Control );

  R.Assign( 36, 2, 56, 8 );
  Control := New( PListBox, Init( R, 1, PScrollbar( Control )));
  Dlg^.Insert( Control );
  }



  R.Assign( 2, 2, 34, 5 );
  Control := New( Pview, Init( R ));
  Control^.Options := Control^.Options or ofFramed;
  Insert( Control );

  R.Assign( 4, 2, 32, 3 );
  Counter := New( PCounter, Init( R ));
  {Counter^.Options := Counter^.Options or ofFramed;}
  Insert( Counter );

  R.Assign( 2,5,2,6 );
  New( Info2, Init( R, '%s', 1 ));
  Insert( Info2 );
  {
  R.Assign( 35, 2, 45, 5 );
  New( Info0, Init( R, ^M^C + '%s' + ^M^C + '%s', 2 ));
  Info0^.Options := Info0^.Options or ofFramed;
  Insert( Info0 );
  }


  R.Assign( 33, 2, 34, 5 );
  New( Info0, Init( R,'%c'+^M +'%c'+^M+'%c',3));
  {Info0^.Options := Info0^.Options or ofFramed;}
  Insert( Info0 );

  FreeStr:=GetString(dlCDTrack);
  R.Assign( 11-Length(FreeStr), 1, 11, 2 );
  Insert( New( PStaticText, Init( R, FreeStr  )));


  R.Move( 13, 0 ); R.B.X := R.A.X + 4;
  New( Info1, Init( R, '%s', 1 ));
  Insert( Info1 );

  {
  R.Move( 20, 0 ); R.B.X := R.A.X + 4;
  Insert( New( PStaticText, Init( R, 'Mode' )));
  }
  {
  R.Assign( 35, 2, 45, 5 );
  Control := New( PView, Init( R ));
  Control^.Options := Control^.Options or ofFramed;
  Insert( Control );
  }
  {New( PStaticText, Init( R, 'Time' )));}

  SelectNext( False );
  SelectNext( False );
  SelectNext( False );
end;

DESTRUCTOR TcdPlayer.Done;
begin
  ConfigModified := (LongInt(Origin) <> LongInt(CDSize)) or (LongInt(CDSize) <> LongInt(Size));
  CDplace := Origin;
  CDsize  := Size;
  CD_Player := Nil;
  DisposeStr( DiskTitle );
  Dispose( Descr,Done );

  Inherited Done;
end;


   Function TCdPlayer.MakeTrackList : PLineCollection ;
    var C : PLineCollection;
        I : word ;
     begin
       New(C,Init(10,10));
        for I := LowTrack to HighTrack do
         C^.Insert(NewStr(
                 SStr( I- LowTrack +1 ,2,' ' ) + ' ³ ' +
               + SStr( Tlen[I].Lmin,2,' ' ) + ':' +
               + SStr( Tlen[I].Lsec,2,'0' ) + ' ³ ' +
               CnvString(Descr^.At(I))
         ));
      MakeTrackList := C ;
     end;

    Procedure TCdPlayer.SelectTrack ;
     var T : _OrderRec ;
         s : string ;
         I : byte ;
      begin
       if status=noDisk then Exit ;
       S := '';
       for  I:= LowTrack to HighTrack do AddStr(S, char(I));

       with T do begin
                  pCD := @Self ;
                  Selection := QChannel.TNO - LowTrack;
                  pOrder := @S ;
                 end;

        if Application^.ExecuteDialog(
         New(POrder,Init(False, Succ(HighTrack-LowTrack) ,'')),@T)=cmOk
          then _Song( T.Selection+1 );
      end;

    Procedure TCdPlayer.SelectOrder ;
     var T : _OrderRec ;
         s : string ;
         I : byte ;
      begin
       S := trkOrder ;
       {for  I:= LowTrack to HighTrack do AddStr(S, char(I));}

       T.Selection := 0;

       if (S<>'') and (CDparams[ 2 ] = cpOrder) then
       T.Selection := Length(S) - Length(TrkPlay);

       with T do begin
                  pCD := @Self ;
                  pOrder := @S ;
                 end;

        if Application^.ExecuteDialog(
         New(POrder,Init(True,Length(S),'')),@T)=cmOk
          then begin
                 trkOrder := S;
                 trkPlay  := S;
                 {_Song( T.Selection+1 );}
                 CDparams[ 2 ] := cpOrder ;
                 _Stop;
                 _Play;
               end;
      end;


PROCEDURE TcdPlayer.Update;
  FUNCTION CheckEject: boolean;
  begin
    CheckEject := False;
    if CDparams[ 1 ] and cpRepeat > 0 then Exit;
    if CDparams[ 1 ] and cpAutoEject > 0 then
        begin
           _Eject;
           CheckEject := True;
           Exit;
        end;
    _Stop;
    CheckEject := True;
  end;

  FUNCTION Reached( M, S: byte ):boolean;
  var DT, DS: integer;
  begin
    with Qchannel do begin
       DT := M*60 + S;
       DS := AMin*60 + Asec;
       Reached := ( DS+2>=DT );
    end;
  end;

  PROCEDURE NormalPlay;
  begin
    with Qchannel do begin
      if TNO < HighTrack then Exit;
      with Tracks[ HighTrack+1 ] do if not Reached( CMin, CSec ) then Exit;
      if checkEject then Exit;
      CD_Play( CDdisk, tracks[ LowTrack ], tracks[ HighTrack+1 ], reqHdr );
    end;
  end;

  PROCEDURE IntroPlay;
  var TTo: byte;
  begin
    if not TimerExpired( NewPlay ) then Exit;
    with Qchannel do begin
      TTO := TNO + 1;
      if TTO > ( HighTrack ) then begin
        if CheckEject then Exit;
        TTO := HighTrack;
        CD_Play( CDdisk, tracks[ LowTrack ], tracks[ LowTrack+1 ], reqHDr );
      end else
        CD_Play( CDdisk, tracks[ TNO + 1 ], tracks[ TTO + 1 ], reqHdr );
      NewTimerSecs( NewPlay, 17 );
    end;
  end;

  PROCEDURE ShufflePlay;
  var I: byte;
  begin
    with Qchannel do begin
      with Tracks[ LastShuffle+1 ] do if not Reached( CMin, CSec ) then Exit;
      for I:= LowTrack to HighTrack do
        if TNO = Order[ I ] then Break;
      if not TimerExpired( NewPlay ) Then Exit;
      if I = HighTrack then begin
        if CheckEject then Exit;
        I := LowTrack;
      end else
        Inc( I );
      I := Order[ I ];
      CD_Play( CDdisk, tracks[ I ], tracks[ I+1 ], reqHdr );
      NewTimerSecs( NewPlay, 3 );
      LastShuffle := I;
    end;
  end;

  PROCEDURE OnePlay;
  var I: byte;
  begin
    with Qchannel do begin
      with Tracks[ LastShuffle+1 ] do if not Reached( CMin, CSec ) then Exit;
      if not TimerExpired( NewPlay ) Then Exit;
      {if TNO = LastShuffle+1 then } begin
        NewTimerSecs( NewPlay, 3 );
        if CheckEject then Exit;
        CD_Play( CDdisk, tracks[ TNO ], tracks[ TNO+1 ], reqHdr );
        LastShuffle := TNO;
      end
    end;
  end;

  PROCEDURE OrderPlay;
  var I: byte;
  begin
    with Qchannel do begin
      with Tracks[ LastShuffle+1 ] do if not Reached( CMin, CSec ) then Exit;
      if not TimerExpired( NewPlay ) Then Exit;
      DelFC(TrkPlay);
      if TrkPlay='' then begin
        if CheckEject then Exit;
        TrkPlay := TrkOrder ;
      end;
       I := byte(TrkPlay[ 1 ]);
      CD_Play( CDdisk, tracks[ I ], tracks[ I+1 ], reqHdr );
      NewTimerSecs( NewPlay, 3 );
      LastShuffle := I;
    end;
  end;

begin
  {$ifdef upd}
  if not TimerExpired( UpdCnt ) then Exit;
  NewTimerSecs( UpdCnt, 1 );
  {$endif}

  DiskOk := not _DiskStatus;
  {if not DiskOk then Exit;}

  if ( Status = noDisk ) and DiskOk then
    {if  _DiskIsChanged then} begin
      LoadDiskInfo;
      if _DiskStatus then begin
                           Status := NewDisk;
                           NewTimerSecs( NewPlay, 5 );
                          end;
    end;
    {
    else begin
      Status := Stopped;
      Display( Succ( HighTrack-LowTrack ), DiskMin, DiskSec );
    end;
    }

  if Status = Play then case CDparams[ 2 ] of
    cpNormal: NormalPlay;
    cpIntro: IntroPlay;
    cpShuffle: ShufflePlay;
    cpOne: OnePlay;
    cpOrder: if TrkOrder<>'' then OrderPlay
                             else NormalPlay;
   end;

  with Qchannel do case Status of
    Play, Paused: Display( TNO, RMin, RSec );
    noDisk: Display( $FF, 0, 0 );
    NewDisk: if TimerExpired( NewPlay ) then
               if ( CDparams[ 1 ] and cpAutoPlay > 0 ) then _Play;
  end;

end;

procedure TcdPlayer.SizeLimits;
begin
  Min.X := 36;
  Min.Y := 7;
  Max.X := 36;{59}
  Max.Y := 15;{10}
end;

PROCEDURE TcdPlayer.Display;
var DS, DM: integer;
    I : word ;
    PP: Pstring ;
    Tdscr : string;

  PROCEDURE GetShAcc;
  var I: byte;
  begin
    with  Qchannel do
    begin
      DS := 0;
      DM := 0;
      for I := LowTrack to HighTrack do
      with Tlen[ Order[ I ] ] do begin
        if TNO = Order[ I ] then Break;
        TimeAdd( DM, DS, LMin, LSec );
      end;
      TimeAdd( DM, DS, M, S );
    end;
  end;

  PROCEDURE GetShDcc;
  var I: byte;
  begin
    with  Qchannel do begin
      DS := 0;
      DM := 0;
      for I := HighTrack downto LowTrack do with Tlen[ Order[ I ] ] do begin
        TimeAdd( DM, DS, LMin, LSec );
        if TNO = Order[ I ] then Break;
      end;
      TimeSub( DM, DS, M, S );
      end;
    end;

  PROCEDURE GetOrAcc;
  var I: byte;
      C : Integer ;
  begin
    with  Qchannel do
    begin
      DS := 0;
      DM := 0;
    C := Length(TrkOrder)-Length(TrkPlay);
      if C>1 then
      for I := 1 to C do
      with Tlen[ byte(TrkOrder[I]) ] do
        TimeAdd( DM, DS, LMin, LSec );
      TimeAdd( DM, DS, M, S );
    end;
  end;

 PROCEDURE GetOrDcc;
  var I: byte;
      C : Integer ;
  begin
    with  Qchannel do
    begin
      DS := 0;
      DM := 0;
    C := Length(TrkPlay);
      if C>0 then
      for I := C downto 1 do
      with Tlen[ byte(TrkPlay[I]) ] do
        TimeAdd( DM, DS, LMin, LSec );
      TimeSub( DM, DS, M, S );
    end;
  end;

  var C1,C2,C3 : char ;

begin
  if Counter = nil then exit;

  if SkyVisible then Exit;

  if Info0 <> nil then begin
  {
    Case CDparams[ 2 ] of
      cpNormal: Parm1 := 'Normal';
      cpIntro: Parm1 := 'Intro';
      cpShuffle: Parm1 := 'Shuffle';
      cpOne: Parm1 := 'One track';
      cpOrder: if (TrkOrder<>'') then Parm1 := 'Order'
                                 else Parm1 := 'Normal';
    end;

    Parm0 := '';

    if CDparams[ 1 ] and cpAutoPlay > 0 then Parm0 := 'Auto';
    if CDparams[ 1 ] and cpRepeat > 0 then Parm0 := 'Repeat';


    Parm[ 1 ] := Longint( @Parm0 );
    Parm[ 2 ] := Longint( @Parm1 );

    Info0^.SetData( Parm );
    }
    C2 :=' ';
    Case CDparams[ 2 ] of
      cpNormal: C2 := 'N';
      cpIntro:  C2 := 'I';
      cpShuffle: C2 := 'S';
      cpOne:    C2 := '1';
      cpOrder: if (TrkOrder<>'') then C2 := 'O'
                                 else C2 := 'N';
    end;
    C1 := ' ';
    if CDparams[ 1 ] and cpAutoPlay > 0 then C1 :='A'; { 'Auto' }
    if CDparams[ 1 ] and cpRepeat > 0 then C1 :='R';  {'Repeat'}
    C3 := ' ';
    if CDparams[ 1 ] and cpAutoEject > 0 then C3 :='J';
    if CDparams[ 1 ] and cpLockDoor  > 0 then C3 :='L';
    Parm[ 1 ] := Longint( c1 );
    Parm[ 2 ] := Longint( c2 );
    Parm[ 3 ] := Longint( c3 );
    Info0^.SetData( Parm );
  end;


  if Info1 <> nil then begin
    Case CdParams[ 3 ] of
      0: Parm2 := GetString(dlCDTrackTime);
      1: Parm2 := GetString(dlCDTrackLeft);
      2: Parm2 := GetString(dlCDDiskTime);
      3: Parm2 := GetString(dlCDDiskLeft);
    end;
    Parmt := Longint( @Parm2 );
    with Info1^ do begin
      GrowTo( Length( Parm2 ), 1 );
      SetData( ParmT );
    end;

   if Info2<>nil then
    begin
     if (Status in [play,paused])
     then Tdscr := CnvString(Descr^.At( Qchannel.TNO-LowTrack ))
     else Tdscr := '';
      if Descr^.Count=0 then Tdscr := '';
     if Pos(';',Tdscr)>0 then system.Delete(Tdscr,Pos(';',Tdscr),255);
     ParmD := Longint( @TrkDescr );
     if TrkDescr<>Tdscr then
      begin
        TrkDescr := Tdscr ;
        Info2^.GrowTo( Length( TrkDescr ),1);
        Info2^.SetData( ParmD );
      end;

    end;

  end;
  if not (Status in [Play,Paused]) then begin
    Counter^.SetCounter( T, M, S );
    Counter^.DrawView;
    Exit;
  end;
  with QChannel do begin
    case CDparams[ 3 ] of
      cpTrack: begin
          DS := S;
          DM := M;
        end;
      cpLeftTrack: begin
          DS := tracks[ TNO+1 ].CSec - ASec;
          DM := tracks[ TNO+1 ].CMin - AMin;
        end;
      cpDisk: begin
          DS := ASec;
          DM := AMin;
          if CDparams[ 2 ] = cpShuffle then GetShAcc
           else if CDparams[ 2 ] = cpOrder then GetOrAcc;
        end;
      cpLeftDisk: begin
          DS := DiskSec - Asec;
          DM := DiskMin - Amin;
          if CDparams[ 2 ] = cpShuffle then GetShDcc
          else if CDparams[ 2 ] = cpOrder then GetOrDcc;
        end;
    end{ case };
  end;
  if DS < 0 then begin
    Dec( DM );
    Inc( DS, 60 );
  end;
   if DM > 99
     then Counter^.SetCounter( T, DM div 60, DM mod 60 )
     else Counter^.SetCounter( T, DM, DS );
  Counter^.DrawView;
end;

 Procedure TcdPlayer.GetDescription ;
 var F : PTextReader ;
     T,S : String;
     T1 : string[2];
     TR : Word ;
  Begin

    DisposeStr(title);
    Title := NewStr( GetString( dlCDPlayer ) );
    Frame^.DrawView;

    DisposeStr(DiskTitle);
    DiskTitle := Nil ;
    Descr^.FreeAll ;

    for TR :=1 to 100 do Descr^.Insert(Nil);

    T := SourceDir + 'CD\' + Hex8(DiskID) + '.CD';

    F := New(PTextReader, Init(T));
    if F = nil then Exit;

     while Not F^.EOF do
      begin
          S := F^.GetStr;;
          if S<>'' then
           begin
            if UpStrg(Copy(S,1,6))='TITLE:' then DiskTitle := NewStr(Copy(S,7,255))
            else
              if Pos(':',S)=3 then
               begin
                  T1 := Copy(S,1,2);
                  System.Delete(S,1,3);
                  if T1[1] = '0' then DelFC(T);
                  TR := StoI(T1);
                  if (TR>0) and (TR<100) then
                   begin
                    if (Descr^.At(TR-1)<>Nil) then Descr^.AtFree(TR-1);
                    Descr^.AtInsert(TR-1,NewStr(S))
                   end;
               end;
           end;
      end;
     Dispose(F, Done);

    if CnvString(DiskTitle)<>'' then
     begin
        DisposeStr(Title);
        Title := NewStr(CnvString(DiskTitle));
        Frame^.DrawView;
     end;

  End;

Function TcdPlayer.GetOrder ;
 var F : PTextReader ;
     T,S : String;
     T1 : string[2];
     TR : Byte ;
     NewOrder : String ;
  Begin

    GetOrder := False ;
    NewOrder := '';

    T := SourceDir + 'CD\' + Hex8(DiskID) + '.TRK';

    F := New(PTextReader, Init(T));
    if F = nil then Exit;


     while Not F^.Eof do
      begin
          S := F^.GetStr;
          if S<>'' then
               begin
                  TR := StoI(S);
                  if (TR>0) and (TR<100) then
                   AddStr(NewOrder,char((TR-1)+LowTrack));
               end;
      end;
     Dispose(F, Done);

  if NewOrder<>'' then
     begin
         GetOrder := True ;
         trkOrder := NewOrder ;
         trkPlay  := NewOrder ;
     end;
  End;



PROCEDURE TcdPlayer.LoadDiskInfo;
var DD: _DiskInfo;
  I: byte;
  DS, DM: integer;
  DR: integer;


begin
  {CD_GetFirstDrive( DR );}
  if CD_ISdiskPresent( CDdisk ) then begin
    CD_DiskInfo( CDdisk, DD );
    with DD do begin
      LowTrack  := FirstTrack;
      HighTrack := LastTrack;

      for I := FirstTrack to LastTrack do
        CD_TrackInfo( cdDisk, i, Tracks[ i ] ); { read tracks info }
      Tracks[ LastTrack+1 ].addr := LeadStart;
      DiskMin := Tracks[ LastTrack+1 ].CMin;
      DiskSec := Tracks[ LastTrack+1 ].CSec;

      for I := FirstTrack to LastTrack+1 do with TLen[ i ] do begin
        DM := Tracks[ I+1 ].CMin;
        DS := Tracks[ I+1 ].CSec;
        with Tracks[ I ] do
          TimeSub( DM, DS, CMin, CSec );
          LMin := DM;
          LSec := DS;
        end;
      end;

      Display( Succ( HighTrack-LowTrack ), DiskMin, DiskSec );
      Status := Stopped;

      DiskOk := not _DiskStatus;

      if DiskOk then with Qchannel do begin
        if ( TNO > 0 ) and (( RSec <> 0 ) or ( RMin<>0 ))
          then Status := Play
          else begin
            Status := NewDisk;
            NewTimerSecs( NewPlay, 5 );
          end;
      if CDparams[ 1 ] and cpLockDoor > 0 then _Door( True );
    end; { with }

    { calcDiskID }
     DiskID := GetCrc( Tracks[ LowTrack ] ,
                       SizeOF(_TrackInfo ) * Succ(HighTrack-LowTrack)) ;
     GetDescription;
     _SetOrder;

  end else begin
    Display( $FF, 0, 0 );
    Status := NoDisk;
  end;
end;

PROCEDURE TcdPlayer._Play;
begin
  if Status = noDisk then Exit;
  with QChannel do begin
    if Status = Play then begin
         RMin := 0;
         RSec := 0;
         Display( TNO, Rmin, Rsec );
         CD_Play( CDdisk, tracks[ TNO ], tracks[ highTrack+1 ] ,
                  reqHDr );
    end else case CDparams[ 2 ] of
      cpOne,
      cpNormal,
      cpShuffle: begin
          CD_Play( CDdisk, tracks[ order[ lowTrack ] ], tracks[ highTrack+1 ], reqHdr );
          LastShuffle := order[ lowTrack ];
        end;
      cpIntro: begin
          CD_Play( CDdisk, tracks[ order[ lowTrack ] ], tracks[ highTrack+1 ], reqHdr );
          LastShuffle := order[ lowTrack ];
          NewTimerSecs( NewPlay, 17 );
        end;
      cpOrder:
       if trkOrder<>'' then
        begin
          TrkPlay := TrkOrder ;
          CD_Play( CDdisk, tracks[ byte(Trkorder[1]) ],
                           tracks[ byte(Trkorder[1])+1 ], reqHdr );
          LastShuffle := byte(Trkorder[1]);
        end
         else

        begin
          CD_Play( CDdisk, tracks[ order[ lowTrack ] ], tracks[ highTrack+1 ], reqHdr );
          LastShuffle := order[ lowTrack ];
        end;

    end;
  end;
  Status := Play;
end;

PROCEDURE TcdPlayer._Stop;
begin
  Display( 0, $CC, $CC );
  CD_Stop( CDDISK, reqHdr );
  {
  fillchar( reqHdr, SizeOf( reqHdr ), 0 );
  reqHdr[ 1 ]:=0;
  reqHdr[ 2 ]:=133;
  reqHdr[ 0 ]:=$5;
  asm
    les bx, SELF
    mov bx, offset es:reqHdr
    mov cx, es: CDdisk
    mov ax, $1510
    clc
    int $2f
  end;
  Move( reqHdr[ 3 ], Err, 2 );
  }
  Status := Stopped;
end;

PROCEDURE TcdPlayer._Next;
begin
  if not DiskOk then Exit;
  with QChannel do begin
    if TNO >= HighTrack then begin _Stop; Exit end;
    Rmin := 0;
    Rsec := 0;
    Display( TNO+1, 0, 0 );
    CD_Play( CDdisk, tracks[ TNO + 1 ], tracks[ highTrack+1 ] ,
             reqHdr );
    Status := Play;
    {fillChar( UpdCnt, SizeOf( UpdCnt ), 0 );}
    LastShuffle := order[ TNO + 1 ];
    Update;
  end;
end;

PROCEDURE TcdPlayer._Prev;
begin
  if not DiskOk then Exit;
  with QChannel do begin
    if TNO <= LowTrack then begin _Stop; Exit end;
    RMin := 0;
    RSec := 0;
    Display( TNO-1, 0, 0 );
    {
    if Status = Stopped then
      begin
        Dec( TNO );
        AMin := tracks[ tno ].CMin;
        ASec := tracks[ tno ].CSec;
        AFrm := 0;
        Exit;
      end;
    }
    CD_Play( CDdisk, tracks[ TNO - 1 ], tracks[ highTrack+1 ], reqHdr );
    Status := Play;
    {fillChar( UpdCnt, SizeOf( UpdCnt ), 0 );}
    LastShuffle := order[ TNO - 1 ];
    Update;
  end;
end;

PROCEDURE TcdPlayer._Pause;
var Res: _trackInfo;
begin
  if Status = Play then begin
    if _DiskStatus
      then Exit; _Stop; Status := Paused; Exit end
      else if Status = Paused then begin
        with QChannel do begin
          FillChar( Res, SizeOf( Res ), 0 );
          Res.CMin := AMin;
          Res.CSec := ASec;
          Res.CFrame := AFrm;
          Display( TNO, Rmin, Rsec );
          CD_Play( CDdisk, Res, tracks[ highTrack+1 ], reqHdr );
          Status := Play;
        end;
      end;
end;

FUNCTION TcdPlayer._DiskStatus;
     begin
      _DiskStatus := True;
      fillchar( reqHdr, SizeOf( reqHdr ), 0 );
      reqHdr[ 20 ]:=12; { Get Audio Q-Channel }
      reqHdr[ 21 ]:=1;
      if CD_Req( cdDisk, 3, 11, reqHdr ) then
       begin
        if ( reqHDr[ 3 ] = 2 ) or ( reqHDr[ 3 ] = 12 ) then
           Status := NoDisk
          else _DiskStatus := false;
        Exit;
       end;
      move( reqHdr[ 21 ], Qchannel, 10 );
      with Qchannel do
          TNO :=(( TNO and $f )+(( TNO and $f0 )) * 10 div 16 );
      _DiskStatus := false;
  end;

FUNCTION TcdPlayer._diskIsChanged;
     begin
      fillchar( reqHdr, SizeOf( reqHdr ), 0 );
      reqHdr[ 20 ] := 9; { Changed? cmd }
      CD_Req( CdDisk, 3, 1, reqHdr );
      _DiskIsChanged := ( reqHdr[ 21 ] = $FF );
     end;

PROCEDURE TcdPlayer._Door;
     begin
      if Status = play then _Stop;
      fillchar( reqHdr, SizeOf( reqHdr ), 0 );
      reqHdr[ 20 ] := 1; { Lock cmd }
      reqHdr[ 21 ] := Ord( DLock );
      CD_Req( CdDisk , 12, 2, reqHdr );
      {Status := noDisk;}
     end;

PROCEDURE TcdPlayer._Eject;
  var E: Tevent;
     begin
      E.What := evCommand;
      E.Command := cmAbout;
      if Status = play then _Stop;
      fillchar( reqHdr, SizeOf( reqHdr ), 0 );
      reqHdr[ 20 ] := 0; { Eject cmd }
      CD_Req( CdDisk , 12, 1, reqHdr );
      Status := noDisk;
      _Door( False );    { Unlock Door }
      Cd_loaded := False ;
     end;

PROCEDURE TcdPlayer._Load;
  var E: Tevent;
     begin
      if Status <> noDisk then Exit;
       if Cd_Loaded then begin _Eject; Exit; end;
       {Cd_Loaded := not Cd_Loaded;}
      fillchar( reqHdr, SizeOf( reqHdr ), 0 );
      reqHdr[ 20 ] := 5; { Load cmd }
      CD_Req( CdDisk , 12, 1, reqHdr );
      Cd_Loaded := True;
     end;

PROCEDURE TcdPlayer._FForward;
   var DM, DS: integer;
       TR: _TrackInfo;
     begin
      if Status <> play then Exit;
      if _DiskStatus then Exit;
      with QChannel do
       begin
         fillchar( TR, SizeOf( Tr ), 0 );
         DM := AMin*60 + Asec;
         DS := tracks[ TNO+1 ].CMin*60 + tracks[ TNO+1 ].CSec;

         TR.CMin := AMin;
         TR.CSec := ASec;
         TR.Cframe := 0;

         DS := DS-DM;
         if DS < 2 then
          if TNO < HighTrack then
              DS := 15;
         if DS > 15 then DS:=15;

         with TR do
          begin
           inc( CSec, DS );
           Inc( CMin, CSec div 60 );
           CSec := CSec mod 60;
          end;
        {Display( TNO, Rmin, Rsec );}
        CD_Play( CDdisk, Tr, tracks[ highTrack+1 ] ,
                 reqHdr );
        Update;
       end;
     end;

PROCEDURE TcdPlayer._FRewind;
var
  DM, DS: integer;
  TR: _TrackInfo;
begin
  if Status <> play then Exit;
  if _DiskStatus then Exit;
  with QChannel do begin
    fillchar( TR, SizeOf( Tr ), 0 );
    DM := AMin*60 + Asec;
    DS := tracks[ TNO ].CMin*60 + tracks[ TNO ].CSec;

    TR.CMin := AMin;
    TR.CSec := ASec;
    TR.Cframe := 0;

    DS := DM-DS;
    if DS < 2 then
      if TNO > LowTrack
        then DS := 15;
    if DS > 15 then DS:=15;
    with TR do begin
      dec( CSec, DS );
      dec( CMin, byte( CSec > 59 ));
      if CSec > 59 then
      Inc( CSec, 60 );
    end;
    {Display( TNO, Rmin, Rsec );}
    CD_Play( CDdisk, Tr, tracks[ highTrack+1 ], reqHdr );
    {fillChar( UpdCnt, SizeOf( UpdCnt ), 0 );}
    Update;
  end;
end;

PROCEDURE TcdPlayer._Setup;
var
  Prm : record
   P1,P2 : word;
   P3    : string[80];
   end;
begin

 with PRM do begin
  P1 := CDparams[ 1 ];
  P2 := CDparams[ 2 ];
  P3 := CDmixer ;

  if Application^.ExecuteDialog( PDialog( LoadResource( dlgCDOptions )), @PRM ) = cmOk then begin
   CDmixer := P3;
   CDparams[ 1 ] := P1;
    if P2 <> CDparams[ 2 ]  then begin
      CDparams[ 2 ] := P2;
      _Stop;
      _SetOrder;
    end;
    CDparams[ 2 ] := P2;
    _Door( CDparams[ 1 ] and cpLockDoor > 0 );
    ConfigModified := On;
  end;
 end;
end;

  Procedure TcdPlayer._Song ;
   var trk,trks : word ;
      begin

       if status=noDisk then  Exit ;

       trks := Succ(HighTrack - LowTrack) ;
        trk := trks ;
       {trk := 42 ;}
       if ASong=0 then
         begin
           if Application^.ExecuteDialog(
              New( PSPad , Init( trk ) ) , @trk
                                        ) <> cmOk then Exit;
         End
         Else trk := ASong ;
       if trk > trks then Exit ;



        if not DiskOk then Exit ;
        with QChannel do
        begin

         TNO := LowTrack - 1 + trk ;
         if TNO < LowTrack then
          begin
           _Stop;
           Exit;
          end;
          RMin := 0;
          RSec := 0;
         Display(TNO ,0,0);
         cd_Play( CDdisk , tracks[ TNO ] , tracks[highTrack+1] ,
                  reqHdr ) ;
         status := Play ;
         {fillChar(UpdCnt,SizeOf(UpdCnt),0);}
         LastShuffle := order[TNO] ;
         Update ;
        end ;
      end;

PROCEDURE TcdPlayer._Mix;
 begin
 end;

PROCEDURE TcdPlayer._SetOrder;
var
  I: byte;
  S, D: byte;
begin
  if status=noDisk then Exit ;
  LastShuffle := LowTrack;
  for I := LowTrack to HighTrack do order[ i ] := I;

  GetOrder ;

  if CDparams[ 2 ] <> cpShuffle  then Exit;
  Randomize;
  For I:=LowTrack to HighTrack do begin
    S := LowTrack + Random( Succ( HighTrack-LowTrack ));
    D := order[ i ];
    order[ i ] := order[ S ];
    order[ s ] := D;
  end;
end;

PROCEDURE TcdPlayer.Zoom;
begin
  if Size.Y > 8 then begin
    GrowTo( 36, 8 );
  end else begin
    GrowTo( 36, 15 );
  end;
end;

FUNCTION TcdPlayer.Valid( Command: Word ): Boolean;
begin
  Valid := inherited Valid( Command ) ;
  if ((Command = cmClose) and (( Confirms and cfExitCDconfirm ) > 0 ))
   then
    Valid := MessageBox( GetString( dlCloseCD ), nil, mfConfirmation+ mfYesButton or mfNoButton ) = cmYes ;
end;

PROCEDURE TcdPlayer.HandleEvent;
  var MS : Tpoint ;
(*
PROCEDURE ProcessCmd;
var cd: word;
begin
  CD :=  Event.Command xor ( Longint( Coder ) shr 16 );
  with Event do
    if CD = cmd[ 2 ]
      then {cdFFwd :} _FForward
      else
    if CD = cmd[ 5 ]
      then {cdFREW :} _FRewind
      else
    if CD = Command then begin
      Event.Command := cmAbout;
      Event.What := evCommand;
      PutEvent( Event );
    end else
    if CD = cmd[ 1 ]
      then {cdSetup:} _Setup
      else
    if CD = cmd[ 4 ] then { cdDisplay:} begin
      Inc( CDparams[ 3 ] );
      if CDparams[ 3 ] > 3 then CDparams[ 3 ] := 0;
      {fillChar( UpdCnt, SizeOf( UpdCnt ), 0 );}
      Update;
    end else
    if CD = cmd[ 3 ] then {cdMode} begin
      Inc( CDparams[ 2 ] );
      if CDparams[ 2 ] > 3 then CDparams[ 2 ] := 0;
      _Stop;
      _SetOrder;
      {fillChar( UpdCnt, SizeOf( UpdCnt ), 0 );}
      Update;
    end;
  end{ with };
*)
begin
  if ( Event.What = evBroadCast ) or
     ( Event.What = evCommand ) then begin
    case Event.Command of
      cdPlay: _Play;
      cdStop: _Stop;
      cdPrev: _Prev;
      cdNext: _Next;
      cdPause: _Pause;
      cdEject: if Status=noDisk then _Load else _Eject;
      cdZoom: Zoom;
      (*
      cdDisplay,
      cdFFwd,
      cdFREW,
      cdSetup,
      cdMode: ProcessCmd;
      *)
      cdFFwd: _FForward;
      cdFREW: _FRewind;
      cdSetup: _Setup;
      cdDisplay: begin
          Inc( CDparams[ 3 ] );
          if CDparams[ 3 ] > 3 then CDparams[ 3 ] := 0;
          {fillChar( UpdCnt, SizeOf( UpdCnt ), 0 );}
          Update;
        end;
      cdZoom: Zoom;
      cdTitle: begin
                      GetDescription;
                      EditDescr(@Self);
               end;
      cdOrder: SelectOrder;
      cdMix: if CDmixer <>'' then
               Message(Application, evCommand, cmExecString, @CDmixer);
      cdMode: begin
          Inc( CDparams[ 2 ] );
          if CDparams[ 2 ] > 3 then CDparams[ 2 ] := 0;
          _Stop;
          _SetOrder;
          {fillChar( UpdCnt, SizeOf( UpdCnt ), 0 );}
          Update;
        end;
      cmGetName: begin
          if Status = NoDisk then FreeStr := GetString(dlCDPlayerNoCD)
                             else FreeStr := CnvString(DiskTitle);
          if FreeStr<>'' then FreeStr:= ' - '+FreeStr;
          PString(Event.InfoPtr)^ := GetString( dlCDPlayer ) + FreeStr;
          ClearEvent(Event);
          Exit;
        end;
      else{ case } begin
          Inherited HandleEvent( Event );
          Exit;
        end;
    end{ case };
    ClearEvent( Event );
    Exit;
  end;


 if Event.What = evMouseDown then
            begin
             MakeLocal(Event.Where,MS);
             if (MS.X<33) and (MS.Y < 5) and (MS.Y > 1) then _Song(0)
              else if (MS.Y=5) and (MS.X<30) then SelectTrack
               else if (MS.X>32) and (MS.X<36) and (MS.Y>0) then _Setup
                else if (MS.Y=1) and (MS.X>18) then  begin
                                                      Inc( CDparams[ 3 ] );
                                                      if CDparams[ 3 ] > 3 then CDparams[ 3 ] := 0;
                                                      Update;
                                                     end;
            end;

  if Event.What = evKeyDown then begin
    case Upcase( Event.CharCode ) of
      #27: begin
          Event.What := evCommand; Event.Command := cmClose; Event.InfoPtr := nil;
          inherited HandleEvent( Event );
        end;
      'P': _Play;
      'S': _Stop;
      'U': _Pause;
      'V', '<', ',': _Prev;
      'N', '>', '.': _Next;
      'F', '}', ']': _FForward;
                      { begin
                        Event.Command := cdFFwd;
                        ProcessCmd;
                       end; }
      'B', '{', '[': _FRewind;
                    { begin
                      Event.Command := cdFRew;
                      ProcessCmd;
                     end; }
      'J': if Status=noDisk then _Load else _Eject;
      'Z': Zoom;
      '0'..'9'  :  _Song( byte(Event.CharCode) - byte ('0')) ;
      'O': SelectOrder ;
      'T': begin  GetDescription;
                  EditDescr(@Self);
           end;
      else
       Case Event.KeyCode of
        KbUp:    _Next;
        KbDown:  _Prev;
        KBPgUp:  _Next;
        KbPgDn:  _Prev;
        KbLeft:  _FRewind;
        KbRight: _FForward;
       else
      begin
        inherited HandleEvent( Event );
        Exit;
      end;
     end; { case }
    end{ case };
    ClearEvent( Event );
    Exit;
  end;
  inherited HandleEvent( Event );
end;

PROCEDURE RunPlayer;
var
  R, R1: TRect;
  CD: integer;
  DRV: String[ 20 ];
  PP: Pointer;
begin
  if CD_Player <> nil then begin
    CD_Player^.Select;
    Exit;
  end;

  CD := -1;
  if CD_GetFirstDrive( CD ) = 0 then begin
    DRV := 'MSCDEX.EXE';
    if ( Lo( DosVersion )>=20 ) and ( Hi( DosVersion )>=10 )
      then DRV := 'VCDROM.SYS';
    PP := @DRV;
    Msg(dlNoCD, @PP, mfError or mfOkButton );
    Exit;
  end;

  Desktop^.GetExtent( R1 );
  if ( CDplace.X > R1.B.X ) or
     ( CDplace.Y > R1.B.Y ) then
       CDplace.X := -100;

  if CDsize.X < 0 then CdSize.X := 60;
  if CDsize.Y < 0 then CdSize.Y := 11;

  R.Assign( 0, 0, 10, 11 );

  if CdPlace.X > -100 then R.A := CDplace;

  R.B.X := R.A.X + CDsize.X;
  R.B.Y := R.A.Y + CDsize.Y;

  CD_Player := New( PCdPlayer, Init( R, CD ));
  if CDplace.X = -100 then with CD_Player^ do Options := Options or ofCentered;

  Desktop^.Insert( CD_Player );
end;

{$IFDEF UPD}
PROCEDURE UpdateCdPlayer;
begin
  if CD_Player = nil then Exit;
  PCdPlayer( CD_Player )^.Update;
end;
{$ENDIF}

END.