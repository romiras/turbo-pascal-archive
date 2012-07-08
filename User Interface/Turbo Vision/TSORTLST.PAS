  {SWAG=OOP.SWG,MIKE SORTZ,Sorting using tCollection,SORTING,USING,TCOLLECTION}
  unit TSortLst;

  (*
      Version 1.0 5/12/95 - Mike Stortz

        Borland Pascal 7.0 has a very useful object called a TCollection that
      allows you to sort items by any key you wish and that disposes
      of any objects it owns when the collection itself is freed.
      Inexplicably, these very useful behaviors were omitted from Delphi's
      TStringList.  But now... 

        This unit contains a class called "TSortableList" derived from
      TStringList that supports the ability for you to define descendent classes
      that sort the list any way you wish and has the option to "own" the objects
      that are added to it, so that they are disposed with the list.

      How to use a TSortableList that owns its objects:

      1. Create a new TSortableList and tell it that it should own any objects
         in it.

        var
          my_list : TSortableList;
        begin
        my_list := TSortableList.Create(True);     { "True" = Owns objects }
        my_list.Add('Aaa', TObject.Create);        { In a TStringList, this... }
        my_list.Add('Bbb', TObject.Create);        { ...would be... }
        my_list.Add('Ccc', TObject.Create);        { ...very bad! }
        my_list.Free;                              { All objects freed }
        end;

      How to sort on an arbitrary key:

      Suppose you wanted a list of strings sorted by all but the first character
      (i.e. this order -> "ZAble", "YBaker", "XCharlie").

      1. Declare a descendent of TSortableList and override the Compare method.
         The Compare method should return an integer such that the result is:
           -1 if the item at index i1 is "less" than the item at i2
            0 if the item at index i1 is "equal" than the item at i2
            1 if the item at index i1 is "more" than the item at i2

        TExList = class(TSortableList)
          function Compare(i1, i2 : Integer) : Integer; override;
          end;

      2. Define the new compare method

        function Compare(i1, i2 : Integer) : Integer;
          begin
          case Key of
            1 :
              Result := AnsiCompareText(Copy(Strings[i1], 2, 254),
                                        Copy(Strings[i2], 2, 254));
            else
              Result := inherited Compare(i1, i2);
            end;
          end;

      3. Specify the key you just defined.

        var
          my_list : TExList;
        begin
        my_list := TExList.Create;
        my_list.Key := 1;               { <<<<< New key is made active }
        DoSomeStuff;
        my_list.Free;
        end;

        There you go!  I =strongly= suggest that any Key that you define Compare
      methods for have a value of at least 1 and that all unhandled Key
      values be passed to the inherited method, as above.  A Key of 0 is
      defined to be the default alphabetical sort.

        Note that you can define a Key based on the objects in a list, like so:

        function Compare(i1, i2 : Integer) : Integer;
          begin
          case Key of
            1 :
              Result := AnsiCompareText(TSomeObject(Objects[i1]).Text,
                                        TSomeObject(Objects[i2].Text);
            else
              Result := inherited Compare(i1, i2);
            end;
          end;

        Of course, it is your responsibility to be sure that the objects in
      the list are the type that your Compare method assumes them to be.

                    === Important ===

     If you do have a list that is
       a) sorted, and
       b) determines its order via values derived from the objects that are
          stored in the list,
     watch out for changing objects in such a way as to change their sort order;
     the TSortableList will not know that the list is now out of order and
     calls to routines that depend on knowing this (such as Add) may fail to
     work.  Your best bet in this case is to set Sorted to False, make whatever
     changes to the objects you wish, and then set Sorted back to True.  This
     will resort the list.

       I also took the liberty of "protecting" the Find method against the
     possibility that someone would call it when the list was not sorted --
     in that case, it now calls IndexOf (which, somewhat recursively, would
     call Find if the list =was= sorted).  This is exactly what happened in
     the example code for Find!  If you look at the method list for
     TStringList, you won't find Find -- but you can do a topic search for
     it.  The example code for Find works, but only by chance -- add another
     string to either end of the list, and "Flowers" won't be found.  What's
     wrong with the example code is that the list's Sorted property is not set
     to True; the reason it (accidently) works is because the item that
     was being found ("Flowers") happened to be the middle item in the list,
     which is where the search algorithm looks first.

       If you have any comments, suggestions or even criticisms  for
     TSortableList, hey, tough!  No, really, send me some mail at 71744,422.
     I am particularly interested in bug reports.

  *)

  interface

  Uses
    Classes;

  type
    TSortableList = class(TStringList)
      private
      FOwnsObjects : Boolean;
      FKey : Integer;
      FAscending : Boolean;
      procedure QuickSort(left, right: Integer);
      function CallCompare(i1, i2 : Integer) : Integer;
      procedure SetAscending(value : Boolean);
      procedure SetKey(value : Integer);
      protected
      procedure PutObject(index : Integer; AObject : TObject); override;
      function Compare(i1, i2 : Integer) : Integer; virtual;
      public
      constructor Create(owns_objects : Boolean);
      procedure Clear; override;
      procedure Delete(index : Integer); override;
      function Find(const s : string; var index : Integer): Boolean; override;
      procedure Sort; override;
      property Ascending : Boolean read FAscending write SetAscending;
      property Key : Integer read FKey write SetKey;
      property OwnsObjects : Boolean read FOwnsObjects;
      end;

  implementation

  Uses
    SysUtils;

  { Private Methods }

  procedure TSortableList.QuickSort(left, right: Integer);
    var
      i, j, pivot : Integer;
      s : String;
    begin
    i := left;
    j := right;

    { Rather than store the pivot value (which was assumed to be a string),
      store the pivot index }
    pivot := (left + right) shr 1;

    repeat
      while CallCompare(i, pivot) < 0 do
        Inc(i);
      while CallCompare(j, pivot) > 0 do
        Dec(j);
      if i <= j then
        begin
        Exchange(i, j);

        { If we just moved the pivot item, reset the pivot index }
        if pivot = i then
          pivot := j
        else if pivot = j then
          pivot := i;

        Inc(i);
        Dec(j);
        end;
      until i > j;
    if left < j then
      QuickSort(left, j);
    if i < right then
      QuickSort(i, right);
    end;

  function TSortableList.CallCompare(i1, i2 : Integer) : Integer;
    begin
    Result := Compare(i1, i2);
    if not FAscending then
      Result := -Result;
    end;

  procedure TSortableList.SetAscending(value : Boolean);
    begin
    if value <> FAscending then
      begin
      FAscending := value;
      if Sorted then
        begin
        Sorted := False;
        Sorted := True;
        end
      end;
    end;

  procedure TSortableList.SetKey(value : Integer);
    begin
    if value <> FKey then
      begin
      FKey := value;
      if Sorted then
        begin
        Sorted := False;
        Sorted := True;
        end
      end;
    end;

  { Protected Methods }

  function TSortableList.Compare(i1, i2 : Integer) : Integer;
    begin
    Result := AnsiCompareText(Strings[i1], Strings[i2]);
    end;

  { Public Methods }

  constructor TSortableList.Create(owns_objects : Boolean);
    begin
    inherited Create;
    FOwnsObjects := owns_objects;
    FKey := 0;
    FAscending := True;
    end;

  procedure TSortableList.Clear;
    var
      index : Integer;
    begin
    Changing;
    if FOwnsObjects then
      for index := 0 to Count - 1 do
        GetObject(index).Free;
    inherited Clear;
    Changed;
    end;

  procedure TSortableList.Delete(index: Integer);
    begin
    Changing;
    if FOwnsObjects then
      GetObject(index).Free;
    inherited Delete(index);
    Changed;
    end;

  function TSortableList.Find(const s : string; var index : Integer): Boolean;
    begin
    if not Sorted then
      begin
      index := IndexOf(s);
      Result := (index <> -1);
      end
    else
      Result := inherited Find(s, index);
    end;

  procedure TSortableList.PutObject(index: Integer; AObject: TObject);
    begin
    Changing;
    if FOwnsObjects then
      GetObject(index).Free;
    inherited PutObject(index, AObject);
    Changed;
    end;

  procedure TSortableList.Sort;
    begin
    if not Sorted and (Count > 1) then
      begin
      Changing;
      QuickSort(0, Count - 1);
      Changed;
      end;
    end;

  end.