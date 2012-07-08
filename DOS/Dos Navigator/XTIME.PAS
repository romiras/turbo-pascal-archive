(***********************************************************************)
(*                                                                     *)
(*  This file contains code from                                       *)
(*  ASYNC Professional Library Copyright (c) TurboPower Software 1991  *)
(*                                                                     *)
(***********************************************************************)

unit xTime;

interface

type

  {For calculating timeouts}
    TEventTimer = record
      StartTics : LongInt;
      ExpireTics : LongInt;
    end;

  {For internal date/time manipulations}
  Date = Word;
  Time = LongInt;

  DateTimeRec =
    record
      D : Date;
      T : Time;
    end;

function xYMTimeStampToPack(YMTime : LongInt) : LongInt;
function xPackToYMTimeStamp(RawTime : LongInt) : LongInt;
procedure xIncDateTime(var DT1, DT2 : DateTimeRec; Days : Integer; Secs : LongInt);

procedure NewTimerSecs(var ET : TEventTimer; Secs : LongInt);
procedure NewTimer(var ET : TEventTimer; Tics : LongInt);
function TimerExpired(ET : TEventTimer) : Boolean;

function ElapsedTime(ET : TEventTimer) : LongInt;
function ElapsedTimeInSecs(ET : TEventTimer) : LongInt;

procedure DelayTics(Tics : LongInt);


implementation uses Dos;
type
  DayType = (Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday);



const
  {Set to 1/1/1970 00:00 GMT}
  StartDate : DateTimeRec = (D:25567;T:0);
  GmtHourOffset : Integer = 0;   {Default no GMT adjustments}

  MinYear  = 1900;
  MaxYear  = 2078;
  MinDate  = $0000;        {= 01/01/1900}
  MaxDate  = $FF62;        {= 12/31/2078}
  Date1900 = $0000;        {= 01/01/1900}
  Date1980 = $7223;        {= 01/01/1980}
  Date2000 = $8EAC;        {= 01/01/2000}
  BadDate  = $FFFF;

  Threshold2000 : Integer = 1900;

  MinTime = 0;               {= 00:00:00 am}
  MaxTime = 86399;           {= 23:59:59 pm}
  BadTime = $FFFFFFFF;
  First2Months = 58;         {1900 was not a leap year}
  FirstDayOfWeek = Monday;   {01/01/1900 was a Monday}

  SecondsInDay = 86400;      {number of seconds in a day}
  SecondsInHour = 3600;      {number of seconds in an hour}
  SecondsInMinute = 60;      {number of seconds in a minute}
  HoursInDay = 24;           {number of hours in a day}
  MinutesInHour = 60;        {number of minutes in an hour}

  TicsFreq = 1675;
  SecsFreq = 92;

  TicsPerDay = 1573040;      {Assumes 18.20648 tics/sec}

var
  BiosTics : LongInt absolute $40:$6C;



  function IsLeapYear(Year : Integer) : Boolean;
    {-Return True if Year is a leap year}
  begin
    IsLeapYear := (Year mod 4 = 0) and (Year mod 4000 <> 0) and
      ((Year mod 100 <> 0) or (Year mod 400 = 0));
  end;

  function DaysInMonth(Month, Year : Integer) : Integer;
    {-Return the number of days in the specified month of a given year}
  begin
    if Word(Year) < 100 then begin
      Inc(Year, 1900);
      if Year < Threshold2000 then
        Inc(Year, 100);
    end;

    case Month of
      1, 3, 5, 7, 8, 10, 12 :
        DaysInMonth := 31;
      4, 6, 9, 11 :
        DaysInMonth := 30;
      2 :
        DaysInMonth := 28+Ord(IsLeapYear(Year));
    else
      DaysInMonth := 0;
    end;
  end;

  function ValidDate(Day, Month, Year : Integer) : Boolean;
    {-Verify that day, month, year is a valid date}
  begin
    if Word(Year) < 100 then begin
      Inc(Year, 1900);
      if Year < Threshold2000 then
        Inc(Year, 100);
    end;

    if (Day < 1) or (Year < MinYear) or (Year > MaxYear) then
      ValidDate := False
    else case Month of
      1..12 :
        ValidDate := Day <= DaysInMonth(Month, Year);
    else
      ValidDate := False;
    end
  end;

  function DMYtoDate(Day, Month, Year : Integer) : Date;
    {-Convert from day, month, year to a julian date}
  begin
    if Word(Year) < 100 then begin
      Inc(Year, 1900);
      if Year < Threshold2000 then
        Inc(Year, 100);
    end;

    if not ValidDate(Day, Month, Year) then
      DMYtoDate := BadDate
    else if (Year = MinYear) and (Month < 3) then
      if Month = 1 then
        DMYtoDate := Pred(Day)
      else
        DMYtoDate := Day+30
    else begin
      if Month > 2 then
        Dec(Month, 3)
      else begin
        Inc(Month, 9);
        Dec(Year);
      end;
      Dec(Year, MinYear);
      DMYtoDate :=
          ((LongInt(Year)*1461) div 4)+
          (((153*Month)+2) div 5)+Day+First2Months;
    end;
  end;

  procedure DateToDMY(Julian : Date; var Day, Month, Year : Integer);
    {-Convert from a julian date to month, day, year}
  var
    I : LongInt;
  begin
    if Julian = BadDate then begin
      Day := 0;
      Month := 0;
      Year := 0;
    end
    else if Julian <= First2Months then begin
      Year := MinYear;
      if Julian <= 30 then begin
        Month := 1;
        Day := Succ(Julian);
      end
      else begin
        Month := 2;
        Day := Julian-30;
      end;
    end
    else begin
      I := (4*LongInt(Julian-First2Months))-1;
      Year := I div 1461;
      I := (5*((I mod 1461) div 4)) + 2;
      Month := I div 153;
      Day := ((I mod 153)+5) div 5;
      if Month < 10 then
        Inc(Month, 3)
      else begin
        Dec(Month, 9);
        Inc(Year);
      end;
      Inc(Year, MinYear);
    end;
  end;

  procedure DateTimeDiff(DT1, DT2 : DateTimeRec; var Days : Word; var Secs : LongInt);
    {-Return the difference in days and seconds between two points in time}
  var
    DTTemp : DateTimeRec;
  begin
    {swap if DT1 later than DT2}
    if (DT1.D > DT2.D) or ((DT1.D = DT2.D) and (DT1.T > DT2.T)) then begin
      DTTemp := DT1;
      DT1 := DT2;
      DT2 := DTTemp;
    end;

    {the difference in days is easy}
    Days := DT2.D-DT1.D;

    {difference in seconds}
    if DT2.T < DT1.T then begin
      {subtract one day, add 24 hours}
      Dec(Days);
      Inc(DT2.T, SecondsInDay);
    end;
    Secs := DT2.T-DT1.T;
  end;

  procedure TimeToHMS(T : Time; var Hours, Minutes, Seconds : Byte);
    {-Convert a Time variable to Hours, Minutes, Seconds}
  begin
    if T = BadTime then begin
      Hours := 0;
      Minutes := 0;
      Seconds := 0;
    end
    else begin
      Hours := T div SecondsInHour;
      Dec(T, LongInt(Hours)*SecondsInHour);
      Minutes := T div SecondsInMinute;
      Dec(T, LongInt(Minutes)*SecondsInMinute);
      Seconds := T;
    end;
  end;

  function HMStoTime(Hours, Minutes, Seconds : Byte) : Time;
    {-Convert Hours, Minutes, Seconds to a Time variable}
  var
    T : Time;
  begin
    Hours := Hours mod HoursInDay;
    T := (LongInt(Hours)*SecondsInHour)+(LongInt(Minutes)*SecondsInMinute)+Seconds;
    HMStoTime := T mod SecondsInDay;
  end;

  procedure xIncDateTime(var DT1, DT2 : DateTimeRec; Days : Integer; Secs : LongInt);
    {-Increment (or decrement) DT1 by the specified number of days and seconds
      and put the result in DT2}
  begin
    DT2 := DT1;

    {date first}
    Inc(Integer(DT2.D), Days);

    if Secs < 0 then begin
      {change the sign}
      Secs := -Secs;

      {adjust the date}
      Dec(DT2.D, Secs div SecondsInDay);
      Secs := Secs mod SecondsInDay;

      if Secs > DT2.T then begin
        {subtract a day from DT2.D and add a day's worth of seconds to DT2.T}
        Dec(DT2.D);
        Inc(DT2.T, SecondsInDay);
      end;

      {now subtract the seconds}
      Dec(DT2.T, Secs);
    end
    else begin
      {increment the seconds}
      Inc(DT2.T, Secs);

      {adjust date if necessary}
      Inc(DT2.D, DT2.T div SecondsInDay);

      {force time to 0..SecondsInDay-1 range}
      DT2.T := DT2.T mod SecondsInDay;
    end;
  end;

  function xYMTimeStampToPack(YMTime : LongInt) : LongInt;
    {-Return a file time stamp in packed format from a Ymodem time stamp}
  var
    DT : DateTime;
    DTR  : DateTimeRec;
    Ptime : LongInt;
    H,M,S : Byte;
  begin
    {Add the time stamp to StartDate}
    xIncDateTime(StartDate, DTR, 0, YMTime);

    {Add the GMT hour offset}
    xIncDateTime(DTR, DTR, 0, 3600 * GmtHourOffset);

    {Convert to DT format}
    with DT do begin
      DateToDMY(DTR.D, Integer(Day), Integer(Month), Integer(Year));
      TimeToHMS(DTR.T, H, M, S);
      Hour := H;
      Min := M;
      Sec := S;
    end;

    {Convert to packed format}
    PackTime(DT, Ptime);
    xYMTimeStampToPack := Ptime;
  end;


function Secs2Tics(Secs : LongInt) : LongInt;
  {-Returns tics value for Secs seconds}
begin
  Secs2Tics := (Secs * TicsFreq) div SecsFreq;
end;

procedure NewTimer(var ET : TEventTimer; Tics : LongInt);
  {-Returns a set EventTimer that will expire in Tics}
begin
  {Max acceptable value is 24 hours}
  if Tics > TicsPerDay then
    Tics := TicsPerDay;

  with ET do begin
    StartTics := BiosTics;
    ExpireTics := StartTics + Tics;
  end;
end;

procedure NewTimerSecs(var ET : TEventTimer; Secs : LongInt);
  {-Returns a set EventTimer}
begin
  NewTimer(ET, Secs2Tics(Secs));
end;


function TimerExpired(ET : TEventTimer) : Boolean;
  {-Returns True if ET has expired}
var
  CurTics : LongInt;
begin
  with ET do begin
    {Get current tics; assume timer has expired}
    CurTics := BiosTics;
    TimerExpired := True;

    {Check normal expiration}
    if CurTics > ExpireTics then
      Exit;
    {Check wrapped CurTics}
    if (CurTics < StartTics) and ((CurTics + TicsPerDay) > ExpireTics) then
      Exit;

    {If we get here, timer hasn't expired yet}
    TimerExpired := False;
  end;
end;

function ElapsedTime(ET : TEventTimer) : LongInt;
  {-Returns elapsed time, in tics, for this timer}
var
  CurTics : LongInt;
begin
  with ET do begin
    CurTics := BiosTics;
    if CurTics >= StartTics then
      {No midnight wrap yet}
      ElapsedTime := CurTics - StartTics
    else
      {Got a midnight wrap, account for it}
      ElapsedTime := (TicsPerDay - StartTics) + CurTics;
  end;
end;

function Tics2Secs(Tics : LongInt) : LongInt;
  {-Returns seconds value for Tics tics}
begin
  Tics2Secs := ((Tics + 9) * SecsFreq) div TicsFreq;
end;


function ElapsedTimeInSecs(ET : TEventTimer) : LongInt;
  {-Returns elapsed time, in seconds, for this timer}
begin
  ElapsedTimeInSecs := Tics2Secs(ElapsedTime(ET));
end;

procedure DelayTics(Tics : LongInt);
  {-Delay for Tics tics}
var
  ET : TEventTimer;
begin
  if Tics <= 0 then
    Exit
  else if Tics > TicsPerDay then
    Tics := TicsPerDay;

  NewTimer(ET, Tics);
  repeat
  until TimerExpired(ET);
end;



  function xPackToYMTimeStamp(RawTime : LongInt) : LongInt;
    {-Return date/time stamp as octal seconds since 1/1/1970 00:00 GMT}
  var
    DT : DateTime;
    DTR : DateTimeRec;
    DiffDays : Word;
    DiffSecs : LongInt;
  begin
    {Convert to julian date}
    UnpackTime(RawTime, DT);
    with DT do begin
      DTR.D := DMYtoDate(Day, Month, Year);
      DTR.T := HMStoTime(Hour, Min, Sec);
    end;

    {Subtract GMT hour offset}
    xIncDateTime(DTR, DTR, 0, -(3600 * GmtHourOffset));

    {Diff between date/time stamp and 1/1/1970 (in seconds)}
    DateTimeDiff(DTR, StartDate, DiffDays, DiffSecs);
    xPackToYMTimeStamp := DiffSecs + (DiffDays * SecondsInDay);
  end;



end.