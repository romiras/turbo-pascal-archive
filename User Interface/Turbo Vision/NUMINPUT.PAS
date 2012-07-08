unit      NumInput;

{ ************************************************************************** }
{ * Numeric Input for Turbo Vision version 2                               * }
{ * ----------------------------------------                               * }
{ *                                                                        * }
{ * Offers you the possibility of Byte-, Word- Integer and                 * }
{ *                                                 Longint-inputlines.    * }
{ *                                                                        * }
{ * Byte- and Word-inputlines are range-checked at the moment the data     * }
{ * is entered, so no validation-checking afterwards is needed.            * }
{ *                                                                        * }
{ * Warning: Let the length of your inputview be long enough, because      * }
{ *          the scrolling of this unit is not that good. (In my           * }
{ *          opinion not necessary)                                        * }
{ *                                                                        * }
{ * Author: Edwin Groothuis (S89405079@hsepm1.hse.nl or 2:284/205.1)       * }
{ * How to newer versions:                                                 * }
{ *                internet-users:                                         * }
{ *                 garbo.uwasa.fi:/pc/turbovis/numinp#.zip                * }
{ *                 oak.oakland.edu:/pub/msdos/turbovis/numinp#.zip        * }
{ *                fidonet-users:                                          * }
{ *                 freq NUMINP at 2:284/205 (+31-40-550352)               * }
{ *                 download NUMINP#.ZIP from 2:284/205 area: TurboPascal  * }
{ *                                                                        * }
{ * The source is hereby Public Domain, no warrenties are made, feel free  * }
{ * to modify or update. Please send bugs reports/fixes to me.             * }
{ *                                                                        * }
{ ************************************************************************** }

{$F+}
interface

uses      dialogs,drivers,objects;

type
{ A ByteInputLine gives you a byte. Can be in the range of 0..255 }
          PByteInputLine=^TByteInputLine;
          TByteInputLine=object(TInputLine)
                           constructor Init(var Bounds:TRect);
                           procedure HandleEvent(var E:TEvent);virtual;
                           function  DataSize:Word;virtual;
                           procedure GetData(var Rec);virtual;
                           procedure SetData(var Rec);virtual;
                        end;
{ A WordInputLine gives you a word. Can be in the range of 0..65535 }
          PWordInputLine=^TWordInputLine;
          TWordInputLine=object(TInputLine)
                           constructor Init(var Bounds:TRect);
                           procedure HandleEvent(var E:TEvent);virtual;
                           function  DataSize:Word;virtual;
                           procedure GetData(var Rec);virtual;
                           procedure SetData(var Rec);virtual;
                        end;
{ A IntInputLine gives you a integer. Can be in the range of -32768..32767 }
          PIntInputLine=^TIntInputLine;
          TIntInputLine=object(TInputLine)
                           constructor Init(var Bounds:TRect);
                           procedure HandleEvent(var E:TEvent);virtual;
                           function  DataSize:Word;virtual;
                           procedure GetData(var Rec);virtual;
                           procedure SetData(var Rec);virtual;
                        end;
{ A LongInputLine gives you a longint. Can be in the range of -2147483648..2147483647 }
          PLongintInputLine=^TLongintInputLine;
          TLongintInputLine=object(TInputLine)
                           constructor Init(var Bounds:TRect);
                           procedure HandleEvent(var E:TEvent);virtual;
                           function  DataSize:Word;virtual;
                           procedure GetData(var Rec);virtual;
                           procedure SetData(var Rec);virtual;
                        end;


implementation


{****************************************************************************}




{****************************************************************************}


constructor TByteInputLine.Init(var Bounds:TRect);
begin
  Inherited Init(Bounds,3);
end;



procedure TByteInputLine.HandleEvent(var E:TEvent);
var       s:string;
          l:longint;
          code:integer;
begin
  inherited HandleEvent(e);
  s:=Data^;
  val(s,l,code);
  if code=0 then { everything seems to be OK }
  begin
    if l>255 then { It was meant to be a byte, so remove the
                    last inputted character }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end else begin
      if pos(' ',s)<>0 then { yes, it was entered }
      begin
        system.delete(s,pos(' ',s),1);
        Dec(CurPos);
      end else begin
        if s[1]='0' then { don't let something begin with a 0! }
        begin
          system.delete(s,1,1);
          Dec(CurPos);
        end else begin { everything IS ok }
          { PARTY! }
        end;
      end;
    end;
  end else begin { ohoh... integer overflow or non-numericalcharacter typed
                   just kill the last inputted character of the string }
    if s[0]<>#0 then { but don't make it smaller than it can be }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end;
  end;
  Data^:=s;
  inherited Draw;
end;



function  TByteInputLine.DataSize:Word;
begin
  DataSize:=1;
end;
procedure TByteInputLine.SetData(var Rec);
begin
  str(Byte(Rec),Data^);
end;
procedure TByteInputLine.GetData(var Rec);
var       code:integer;
begin
  val(Data^,Byte(Rec),code);
end;


{****************************************************************************}


constructor TWordInputLine.Init(var Bounds:TRect);
begin
  Inherited Init(Bounds,5);
end;



procedure TWordInputLine.HandleEvent(var E:TEvent);
var       s:string;
          l:longint;
          code:integer;
begin
  inherited HandleEvent(e);
  s:=Data^;
  val(s,l,code);
  if code=0 then { everything seems to be OK }
  begin
    if l>longint($FFFF) then { It was meant to be a word, so remove the
                               last inputted character }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end else begin
      if pos(' ',s)<>0 then { yes, it was entered }
      begin
        system.delete(s,pos(' ',s),1);
        Dec(CurPos);
      end else begin
        if s[1]='0' then { don't let something begin with a 0! }
        begin
          system.delete(s,1,1);
          Dec(CurPos);
        end else begin { everything IS ok }
          { PARTY! }
        end;
      end;
    end;
  end else begin { ohoh... integer overflow or non-numericalcharacter typed
                   just kill the last inputted character of the string }
    if s[0]<>#0 then { but don't make it smaller than it can be }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end;
  end;
  Data^:=s;
  inherited Draw;
end;



function  TWordInputLine.DataSize:Word;
begin
  DataSize:=2;
end;
procedure TWordInputLine.SetData(var Rec);
begin
  str(Word(Rec),Data^);
end;
procedure TWordInputLine.GetData(var Rec);
var       code:integer;
begin
  val(Data^,Word(Rec),code);
end;


{****************************************************************************}


constructor TIntInputLine.Init(var Bounds:TRect);
begin
  Inherited Init(Bounds,6);
end;



procedure TIntInputLine.HandleEvent(var E:TEvent);
var       s,t:string;
          l:longint;
          code:integer;
          len:byte;
begin
  len:=length(Data^);
  inherited HandleEvent(e);
  s:=Data^;
  if e.charcode='-' then
  begin
    t:=copy(s,pos('-',s)+1,length(s));
    if pos('-',t)=0 then
    begin
      if length(s)<>len then
      begin
        system.Delete(s,CurPos,1);
        system.Insert('-',s,1);
      end else begin
        system.Delete(s,1,1);
        Dec(CurPos);
      end;
    end else begin
      system.Delete(s,CurPos,1);
      system.Delete(s,1,1);
      Dec(CurPos,2);
    end;
  end;
  val(s,l,code);
  if code=0 then { everything seems to be OK }
  begin
    if l>longint(32767) then { It was meant to be an integer, so remove the
                               last inputted character }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end else begin
    if l<longint(-32768) then { It was meant to be an integer, so remove the
                               last inputted character }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end else begin
      if pos(' ',s)<>0 then { yes, it was entered }
      begin
        system.delete(s,pos(' ',s),1);
        Dec(CurPos);
      end else begin
        if s[1]='0' then { don't let something begin with a 0! }
        begin
          system.delete(s,1,1);
          Dec(CurPos);
        end else begin { everything IS ok }
          { PARTY! }
        end;
      end;
    end;
    end;
  end else begin { ohoh... integer overflow or non-numericalcharacter typed
                   just kill the last inputted character of the string }
    if s[0]<>#0 then { but don't make it smaller than it can be }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end;
  end;
  Data^:=s;
  inherited Draw;
end;



function  TIntInputLine.DataSize:Word;
begin
  DataSize:=2;
end;
procedure TIntInputLine.SetData(var Rec);
begin
  str(Integer(Rec),Data^);
end;
procedure TIntInputLine.GetData(var Rec);
var       code:integer;
begin
  val(Data^,Integer(Rec),code);
end;


{****************************************************************************}


constructor TLongintInputLine.Init(var Bounds:TRect);
begin
  Inherited Init(Bounds,11);
end;



procedure TLongintInputLine.HandleEvent(var E:TEvent);
var       s,t:string;
          l:longint;
          code:integer;
          len:byte;
begin
  len:=length(Data^);
  inherited HandleEvent(e);
  s:=Data^;
  if e.charcode='-' then
  begin
    t:=copy(s,pos('-',s)+1,length(s));
    if pos('-',t)=0 then
    begin
      if length(s)<>len then
      begin
        system.Delete(s,CurPos,1);
        system.Insert('-',s,1);
      end else begin
        system.Delete(s,1,1);
        Dec(CurPos);
      end;
    end else begin
      system.Delete(s,CurPos,1);
      system.Delete(s,1,1);
      Dec(CurPos,2);
    end;
  end;
  val(s,l,code);
  if code=0 then { everything seems to be OK }
  begin
    if pos(' ',s)<>0 then { yes, it was entered }
    begin
      system.delete(s,pos(' ',s),1);
      Dec(CurPos);
    end else begin
      if s[1]='0' then { don't let something begin with a 0! }
      begin
        system.delete(s,1,1);
        Dec(CurPos);
      end else begin { everything IS ok }
        { PARTY! }
      end;
    end;
  end else begin { ohoh... integer overflow or non-numericalcharacter typed
                   just kill the last inputted character of the string }
    if s[0]<>#0 then { but don't make it smaller than it can be }
    begin
      system.Delete(s,CurPos,1);
      Dec(CurPos);
    end;
  end;
  Data^:=s;
  inherited Draw;
end;



function  TLongintInputLine.DataSize:Word;
begin
  DataSize:=4;
end;
procedure TLongintInputLine.SetData(var Rec);
begin
  str(Longint(Rec),Data^);
end;
procedure TLongintInputLine.GetData(var Rec);
var       code:integer;
begin
  val(Data^,Longint(Rec),code);
end;



end.
{$F-}
