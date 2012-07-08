   {SWAG=OOP.SWG,SWAG SUPPORT TEAM,SORTCOLL.PAS,SORTCOLL,PAS}
   {
   This post is just to demonstrate a very simple sorted collection using
   non-Object Types With the collection.  If it is needed to store itself
   to a stream, it will need additional over-ridden methods to do that.
   I'm just posting this, because I wrote it several days ago to implement
   a simple Variable system in a script language For a menu Program that I
   wrote, and I was looking For an *easier* way to maintain the Variable
   list than With a linked list.  To my astonishment, today, I needed a
   similar structure, and (ohmygosh) I found that I could *re-use* this
   code, by merely deriving a child class and adding another method or so.
   This is the first time that I have ever *re-used* an Object Type that I
   have modified.  Of course, I haven't been actually using TurboVision for
   more than a month or so, so I haven't had much of a chance, but it is
   very nice to see that when people talk about "Object oriented
   Programming paradigm", they are not ONLY speaking in big Words, but that
   they also (apparently) are telling the truth.

   I'm not taking any responsibility if this overWrites your interrupt
   vector table, so be carefull.  If you find any mistakes, or actually
   modify this code to become more usefull, I'd appreciate it if you could
   tell me- actually determining the best way to implement a new Object
   class is kind of difficult For me since I've only been doing this for
   about a month, trying to squeeze it in along With school and a job.

   Here's the code...
   {********* STARTS HERE **********}
   { Unit: STROBJ.PAS
     WRITTEN BY: Brian Pape
     DATE: 03/28/93
     Copyright 1993 by Brian Pape and Alphawave Technologies
     This Unit contains String Type Objects
   }
   {$P+}  { Enable open String parameters.  Replace by $V- For TP 6.0 or lower }
   Unit strobj;

   Interface

   Uses
     Objects;

   Type
     str20 = String[20];

     PVarType = ^TVarType;
     TVarType = Record
       name  : str20;
       value : String;
     end;  { TVarType }

     PVarCollection = ^TVarCollection;
     TVarCollection = Object(TSortedCollection)
       Constructor init(Alimit,Adelta:Integer);
       Function KeyOf(item:Pointer):Pointer; virtual;
       Function Compare(Key1,Key2:Pointer):Integer; virtual;
       Procedure freeitem(Item:Pointer); virtual;

       { This Function will return the value of a Variable in a TVarCollection }
       Function getVar(s:String):String;

       { Adds a PVarType Record to the collection, without having to manually
         create, and allocate memory for, a Record Type }
       Procedure add(aname:str20;avalue:String);
     end;  { TVarCollection }

   Implementation

   Constructor TVarCollection.init(ALimit,ADelta:Integer);
   begin
     inherited init(ALimit,ADelta);
   end;  { TVarCollection.init }

   Function TVarCollection.KeyOf(item:Pointer):Pointer;
   begin
     KeyOf := @(TVarType(item^).name);
   end;  { TVarCollection.KeyOf }

   Function TVarCollection.Compare(Key1,Key2:Pointer):Integer;
   begin
     if String(Key1^) > String(Key2^) then
       Compare := 1
     else if String(Key1^) = String(Key2^) then
       Compare := 0
     else Compare := -1;
   end;  { TVarCollection.Compare }

   Procedure TVarCollection.freeitem(Item:Pointer);
   begin
     dispose(Item);
   end;  { freeitem }

   Function TVarCollection.getVar(s:String):String;
   Var
     t : TVarType;
     where : Integer;
   begin
     t.name := s;
     if Search(@t,where) then
       getVar := TVarType(at(where)^).value
     else
       getVar := '';
   end;  { getVar }


   Procedure TVarCollection.add(aname:str20;avalue:String);
   Var
     rec : PVarType;
   begin
     rec := new(PVarType);
     rec^.name := aname;
     rec^.value := avalue;
     insert(rec);
   end;  { add }

   begin
   end.  { strobj }
   {*********** endS HERE *************}