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

unit Overlays;

interface
uses Objects, Overlay;

procedure OvrInitStream(S : PStream);
{ Copies overlay segment code to S as new segments are loaded,
  and does reloads from there.  Allows multiple calls, to buffer
  different segments on different streams. }

procedure OvrDetachStream(BadS : PStream);
  { Makes sure that the overlay system makes no references to BadS. }

procedure OvrDisposeStreams;
  { Detaches and disposes of all streams being used by the overlay system }

function OvrSizeNeeded : LongInt;
{ Returns the size required to load any segments which still haven't
  been loaded to a stream. }

function OvrLoadAll : Boolean;
{ Forces all overlay segments to be copied into the stream; if successful
  (true) then no more references to the overlay file will be made. }

procedure InitOverlay(const FileName: String);

implementation
uses ExtraMemory, Advance, Startup, Commands;

  { ****** Overlay stream code ****** }

type
  { This is the structure at the start of each "thunk" segment }
  POvrhead = ^TOvrhead;
  TOvrhead = record
               Signature : Word;  { CD 3F  - INT 3F call used on returns }
               Ret_Ofs : Word;    { The offset to jump to when a return triggers a
                            reload }
               Offset : LongInt;  { The offset to the segment in the .OVR file }
               Code_Bytes,        { Size of the code image }
               Reloc_Bytes,       { Number of relocation fixups times 2 }
               Entry_Count,       { The number of entry points }
               NextSeg,           { Next overlay segment - add prefixseg + $10 to find
                            thunks.  List starts with System.ovrcodelist. }
               LoadSeg,           { The segment at which the overlay is loaded, or 0 }
               Reprieve,          { Set to 1 to if overlay used while on probation }
               NextLoaded : Word; { The segment of the next loaded overlay.  List starts
                            with System.ovrloadlist.  Updated *after* call to
                            ovrreadbuf. }
               case Integer of
                 1 : (EMSPage,    { The EMS page where this overlay is stored }
                      EMSOffset : Word); { The offset within the EMS page }
                 2 : (S : PStream; { The stream holding this segment's code }
                      Soffset : LongInt); { The offset within S }
             end;

var
  OldReadFunc : OvrReadFunc;
  OvrOldExitProc : Pointer;
  OvrStream : PStream;
const
  OvrStreamInstalled : Boolean = False;
  OvrExitHandler : Boolean = False;

  function OvrPtr(Seg : Word) : POvrhead;
{ Convert map style segment number, as used by overlay manager, to
  pointer }
  begin
    OvrPtr := Ptr(Seg+PrefixSeg+$10, 0);
  end;

  function StdPtr(Seg : Word) : POvrhead;
    { Convert straight segment number to a pointer }
  begin
    StdPtr := Ptr(Seg, 0);
  end;

  function NewReadFunc(OvrSeg : Word) : Integer; Far;
  var
    Result : Integer;
  begin
    with StdPtr(OvrSeg)^ do
    begin
      if S = nil then
      begin                       { Segment not yet loaded }
        Result := OldReadFunc(OvrSeg);
        if Result = 0 then
        begin
          { Now copy the loaded code to our stream }
          Soffset := OvrStream^.GetSize;
          OvrStream^.Seek(Soffset);
          OvrStream^.Write(Ptr(LoadSeg, 0)^, Code_Bytes);
          Result := OvrStream^.Status;
          if Result = stOK then
            S := OvrStream
          else
            OvrStream^.Reset;     { Something failed; hope we haven't messed
                              up the stream too much }
        end;
      end
      else
      begin                       { Segment has been loaded into the stream }
        S^.Seek(Soffset);
        S^.Read(Ptr(LoadSeg, 0)^, Code_Bytes);
        Result := S^.Status;
        if Result <> stOK then
        begin
          S^.Reset;               { Fix the stream, and try a standard load }
          Result := OldReadFunc(OvrSeg);
        end;
      end;
    end;
    NewReadFunc := Result;
  end;

  procedure OvrExitProc; Far;
{ Installed exit procedure; disposes of any streams that are still
  handling overlays. }
  begin
    ExitProc := OvrOldExitProc;
    OvrDisposeStreams;
  end;

  procedure OvrInitStream(S : PStream);
  begin
    if not OvrStreamInstalled then
    begin
      OldReadFunc := OvrReadBuf;  { Install our reader function }
      OvrReadBuf := NewReadFunc;
      OvrStreamInstalled := True;
    end;
    if not OvrExitHandler then
    begin
      OvrOldExitProc := ExitProc;
      ExitProc := @OvrExitProc;
      OvrExitHandler := True;
    end;
    OvrStream := S;               { And set stream to use }
  end;

  procedure OvrDetachStream(BadS : PStream);
  var
    OvrSeg : Word;
  begin
    if OvrStreamInstalled then
    begin
      if OvrStream = BadS then
        OvrStream := nil;         { Detach default stream }
      OvrSeg := OvrCodeList;
      while OvrSeg <> 0 do        { Walk the overlay list }
        with OvrPtr(OvrSeg)^ do
        begin
          if S <> nil then
          begin
            if S <> BadS then
            begin
              if OvrStream = nil then
                OvrStream := S;   { Set default stream to first found }
            end
            else
              S := nil;           { Blank out BadS references }
          end;
          OvrSeg := NextSeg;
        end;
      if OvrStream = nil then
      begin
        OvrStreamInstalled := False; { If we don't have a stream, better
                                          uninstall. }
        OvrReadBuf := OldReadFunc;
      end;
    end;
  end;

  procedure OvrDisposeStreams;
  var
    S : PStream;
  begin
    while OvrStreamInstalled and (OvrStream <> nil) do
    begin
      S := OvrStream;
      OvrDetachStream(S);
      Dispose(S, Done);
    end;
  end;

  function OvrSizeNeeded : LongInt;
  var
    OvrSeg : Word;
    Result : LongInt;
  begin
    OvrSeg := OvrCodeList;
    Result := 0;
    while OvrSeg <> 0 do          { Walk the overlay list }
      with OvrPtr(OvrSeg)^ do
      begin
        if S = nil then
          Inc(Result, Code_Bytes);
        OvrSeg := NextSeg;
      end;
    OvrSizeNeeded := Result;
  end;

  function OvrLoadAll : Boolean;
  var
    OvrSeg : Word;
    Junk : Integer;
  begin
    if not OvrStreamInstalled then
      OvrLoadAll := False
    else
    begin
      OvrClearBuf;
      OvrSeg := OvrCodeList;
      while OvrSeg <> 0 do        { Walk the overlay list }
        with OvrPtr(OvrSeg)^ do
        begin
          if S = nil then
          begin
            LoadSeg := OvrHeapOrg; { load at start of overlay buffer }
            Junk := NewReadFunc(OvrSeg+PrefixSeg+$10);
            LoadSeg := 0;         { Don't really want it loaded yet }
          end;
          OvrSeg := NextSeg;
        end;
      OvrLoadAll := OvrStream^.Status = stOK;
    end;
  end;

procedure InitOverlay(const FileName: String);
  var S: PStream;
      LM,LL: LongInt;
      I : longint ;
      ST : string[8] ;
begin

{  if FindParam('/NCF')=0 then
  if SystemFiles < 25 then
      begin
        Writeln(' Not enough files. Set at least FILES=25 in CONFIG.SYS');
        Halt(250);
      end;
}
  ClrIo;
  S := New(PDosStream, Init(FileName, stOpenRead));
  if S^.Status <> stOK then
    begin
      Writeln('Could not initialize Overlays');
      Halt(1);
    end;
  LL := S^.GetSize;
  Dispose(S, Done);
  ovrInit(FileName);

  I := FindParam('/BUF:');
  if I > 0 then StartupData.OvrSize := Max( 64, StoI( Copy( ParamStr( I ), 6, 255 )));

  ovrSetBuf( StartupData.OvrSize * LongInt( 1024 ));

  if (FindParam('/NOXMS') = 0) then
   begin
    if XMSfound and (StartupData.Load and osuOverlayXMS <> 0) then
      begin
        S := New(PXMSStream, Init(LL + $2000 , LL + $4000 ));
        PXMSStream(S)^.Size := 0;
        if S^.Status = stOK then
         begin
          {Writeln( OvrSizeNeeded );}
          OvrInitStream(S);
          {if not OvrLoadAll then
              begin
                 OvrDisposeStreams;
                 Exit ;
              end;}
          Exit ;
         end;
       Dispose(S, Done) ;
      end
   end else XMSfound := off ;

  if (FindParam('/NOEMS') = 0) then
     begin
        if EMSFound and (StartupData.Load and osuOverlayEMS <> 0) then
        begin OvrInitEMS; if ovrResult = ovrOK then Exit end
     end else EMSfound := off ;

end;

end.