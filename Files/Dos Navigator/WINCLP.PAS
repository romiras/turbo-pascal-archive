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
//     "Based on TinyWeb Server by RIT Research Labs."
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

Unit WinClp ;

interface

 Uses Objects , Advance ;

 Function SetWinClip( PC : PLineCollection ):boolean;
 Function GetWinClip( Var PC : PLineCollection ):boolean;
 Function GetWinClipSize : boolean ;
 procedure SyncClipIn;
 procedure SyncClipOut;

Implementation
uses MicroEd;

function MaxAvail: LongInt;
begin
  MaxAvail := MemAdjust(System.MaxAvail);
end;

 procedure SyncClipIn;
 begin
    if Clipboard <> nil then
      SetWinClip(PLineCollection(Clipboard));
 end;


 procedure SyncClipOut;
 begin
    GetWinClip(PLineCollection(Clipboard));
 end;


 Function OpenClip : boolean ; assembler ;
   asm    mov  ax,1701h
          int  2fh
          or   ax,ax
          jz   @@1
          mov  ax,1
   @@1:   end;

 Function CloseClip : boolean ; assembler ;
   asm    mov  ax,1708h
          int  2fh
          or   ax,ax
          jz   @@1
          mov  ax,1
   @@1:   end;

 Function SetClip(var Buf; Size : word ) : boolean ; assembler ;
   asm
          les  bx,Buf
          mov  cx,size
          sub  si,si
          mov  dx, 7  { CF_OEMTEXT }
          mov  ax,1703h
          int  2fh
          or   ax,ax
          jz   @@1
          mov  ax,1
   @@1:   end;

 Function GetClipSize : longint ; assembler ;
   asm
          mov  dx, 7  { CF_OEMTEXT }
          mov  ax,1704h
          int  2fh
   end;
 Function EmptyClip : boolean ; assembler ;
   asm
          mov  ax,1702h
          int  2fh
          or   ax,ax
          jz   @@1
          mov  ax,1
   @@1:   end;
 Function CompactClip( Size : longint  ) : longint ; assembler ;
   asm
          mov  cx,Size.word
          mov  si,[Size+2].word
          mov  ax,1709h
          int  2fh
   end;
 Function GetClip(var Buf ) : boolean ; assembler ;
   asm
          les  bx,Buf
          mov  dx, 7  { CF_OEMTEXT }
          mov  ax,1705h
          int  2fh
          or   ax,ax
          jz   @@1
          mov  ax,1
   @@1:   end;

 Type
     DA  =  array [0..$FFF0] of byte ;
     pDA = ^DA ;

 Function SetWinClip( PC : PLineCollection ):boolean;
 var Size : longint ;
     Buf : PDA;
     BufPos : Word ;
    TmStr : String ;
   Function CopyLine( Line : PString ):boolean; far;
    begin
      CopyLine := False ;
      TmStr := CnvString(Line) + #13#10 ;
      if BufPos + Length(TmStr) > Size then
          begin
           CopyLine := True ;
           Exit;
          end;
      Move(TmStr[1],Buf^[BufPos],Length(TmStr));
      inc(BufPos,Length(TmStr));
    end;
   begin
     SetWinClip := False ;
     if PC=nil then Exit;
     if PC^.Count=0 then Exit;
     if not OpenClip then Exit;
     if not EmptyClip then begin CloseClip; Exit; end;
     Size := $FFF0;
     if (Maxavail < Size ) then Size := (Maxavail - $FF0);
     GetMem(Buf,Size);
     BufPos := 0 ;
     PC^.FirstThat(@CopyLine);
     if BufPos = 0 then begin FreeMem(Buf,Size);CloseClip;Exit; end;
     if ( CompactClip( BufPos ) >= BufPos ) then
         SetWinClip := SetClip( Buf^ , BufPos );
     FreeMem(Buf,Size);
     CloseClip;
   end;


 Function GetWinClip( Var PC : PLineCollection ):boolean;
    var
       Size : longint ;
        Buf : PDA;
     BufPos,SZ : Word ;
      TmStr : String ;
    begin
     GetWinClip := False;
     if not OpenClip then Exit;
     Size := GetClipSize ;
     if Size > $EF00 then begin CloseClip; Exit; end;
     if (Size + $800) > (MaxAvail div 2) then begin CloseClip; Exit; end;
     GetMem(Buf,Size);
     if not GetClip(Buf^) then begin FreeMem(Buf,Size); CloseClip; Exit; end;
     if PC = nil then New(PC,Init(10,10));
     PC^.FreeAll;
     BufPos := 0 ; SZ := Size;
     TmStr := '';
      while BufPos < SZ do
       begin
         case Buf^[BufPos] of
           10: begin
                 PC^.Insert(NewStr(TmStr));
                 TmStr:='';
                end;
          {13: if Buf^[BufPos+1]=10 then}
          13,0:;
         else
          begin
           if Length(TmStr)<200 then AddStr(TmStr,char(Buf^[BufPos]));
          end;
         end; { case }
         inc(BufPos);
       end;
     if TmStr<>'' then PC^.Insert(NewStr(TmStr));
     FreeMem(Buf,Size);
     CloseClip;
     GetWinClip := PC^.Count>0;
    end;

 Function GetWinClipSize : boolean ;
  var SZ : longint ;
    begin
      GetWinClipSize := false ;
      if not OpenClip then Exit;
       SZ := GetClipSize ;
        GetWinClipSize := ((SZ<$EF00) and (SZ>0));
      CloseClip ;
    end;

end.