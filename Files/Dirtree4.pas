
uses Classes;

type
     TDirName = Pstring;
     PStringList = ^TStringList;

     PDirTree = ^TDirTree;
     TDirTree = record
       name: TDirName;
       filelist: TStringList;

       nextdir: PDirTree;
       firstsubdir: PDirTree;
     end;

var
     stop : boolean;
     infile: Text;

FUNCTION NewStr (Const S: String): PString;
VAR P: PString;
BEGIN
   If (S = '') Then P := Nil Else Begin               { Return nil }
     GetMem(P, Length(S) + 1);                        { Allocate memory }
     If (P<>Nil) Then P^ := S;                        { Hold string }
   End;
   NewStr := P;                                       { Return result }
END;

PROCEDURE DisposeStr (P: PString);
BEGIN
   If (P <> Nil) Then FreeMem(P, Length(P^) + 1);     { Release memory }
END;

procedure DebugPtr (p: PDirTree);
begin
     writeln ('-----');
     if p <> Nil then
     begin
          if p^.name <> Nil then
               writeln (p^.name^);
          write (' > firstsubdir: ');
          if p^.firstsubdir <> Nil then
               writeln (p^.firstsubdir^.name^)
          else
               writeln ('0');
          write (' > nextdir: '); 
          if (p^.nextdir <> Nil) and (p^.nextdir^.name <> Nil) then
               writeln (p^.nextdir^.name^)
          else
               writeln ('0');
     end;
end;


procedure NoMem;
begin
     writeln (' << ! >> Error: Cannot allocate memory!');
     stop := true;
end;


function CreateDirEntry (dirname: string): PDirTree;
//const
//     strList: TStringlist = Nil;
var
     dn: TDirName;
     ptr: PDirTree;
begin
     Result := nil;

     dn := NewStr (dirname);
     if dn = Nil then
     begin
          NoMem;
          Exit;
     end;

     New (ptr);
     if ptr = Nil then
     begin
          NoMem;
          Exit;
     end;
     ptr^.name := dn;
     ptr^.nextdir := Nil;
     ptr^.firstsubdir := Nil;

//     strList := TStringList.Create;
     ptr^.filelist := TStringList.Create; //@strList;

     Result := ptr;
end;


function AddSubDirectory (const dirname: string; var ParentDir: PDirTree): PDirTree;
var
     ptr: PDirTree;
begin
     ptr := CreateDirEntry (dirname);
     if ptr = Nil then
     begin
          NoMem;
          Exit;
     end;

     ParentDir^.firstsubdir := ptr;
     ParentDir^.nextdir := Nil;

     Result := ptr;
end;


function AddNextDirectory (const dirname: string; var ToDir: PDirTree): PDirTree;
var
     ptr: PDirTree;
begin
     ptr := CreateDirEntry (dirname);
     if ptr = Nil then
     begin
          NoMem;
          Exit;
     end;

     ToDir^.firstsubdir := Nil;
     ToDir^.nextdir := ptr;

     Result := ptr;
end;


procedure PlotTreeOnScreen (dir: PDirTree; level: word);
var i: integer;
begin
     if dir = Nil then Exit;

     { action with directory }
     writeln (' ':(level*2), dir^.name^);
     with dir^.filelist do
     for i := 0 to  Count - 1 do
          writeln (' ':(level*2), '--',  Strings[i]);

     { Process other directories}
     PlotTreeOnScreen (dir^.firstsubdir, succ (level)); { at first, print subdirs }
     PlotTreeOnScreen (dir^.nextdir, level); { after that, print next dir }
end;


procedure DeleteDirectory (var  dir: PDirTree);
begin
     { Same as PlotTreeOnScreen, recursively }
     if dir = Nil then Exit;

     writeln (dir^.name^); { action with directory }
     DeleteDirectory (dir^.firstsubdir); { at first, delete subdirs }
     DeleteDirectory (dir^.nextdir); { after that, delete next dir }
     if dir^.name <> Nil then
        Dispose (dir^.name);
     dir^.filelist.Free;
     Dispose (dir);
end;


function FindDirectory (const dirname: string; where: PDirTree): PDirTree;
var
     location: PDirTree;

procedure RecursiveSearch (pdir: PDirTree);
begin
     if pdir = Nil then Exit;

     DebugPtr (pdir);

     //if CompareStr (pdir^.name^, dirname) = 0 then
     if (pdir^.name^ = dirname) then
     begin
          location := pdir;
          Exit;
     end;
     RecursiveSearch (pdir^.firstsubdir);
     RecursiveSearch (pdir^.nextdir);
end;

begin
     writeln;
     writeln ('Looking for "', dirname, '"');
     location := Nil;
     if where = Nil then exit;
     RecursiveSearch (where);
     Result := location;
end;


procedure ParseString (s: string; var Tree: PDirTree);
var
     ptr, temp: PDirTree;
     m: word;
     dirname: string;
const
     Delimiter = '/';

begin
     ptr := Tree;

     temp := Tree;

     repeat

          m := pos (Delimiter, s);
	  
          if m <> 0 then
          begin
               writeln ('Parsing>> ', s);
               dirname := copy (s, 1, m-1);
               delete (s, 1, m);
               writeln (' > parsed name: ', s);
               writeln (' > parsed dir: ', dirname);

               // looking for 'dirname' in parent directory (ptr)
               temp := FindDirectory (dirname, ptr);

               // if found, file will be created in that directory
               // if not found, we need create it in dirtree
               if temp <> Nil then
                    writeln ('dir found: "', temp^.name^,'"')
               else
               begin
                    // create dir
                    if ptr^.firstsubdir = Nil then
                    begin
                         writeln ('Trying add "', dirname, '" to "', ptr^.name^, '"');
                         ptr := AddSubDirectory (dirname, ptr);
                         writeln ('Ok.');
                    end
                    else
                    begin
                         temp := ptr^.firstsubdir;
                         writeln (' Debugging ''temp'': ');
                         DebugPtr (temp);

                         // find last subdir
                         while temp^.nextdir <> Nil do
                              temp := temp^.nextdir;

                         writeln ('Trying add "', dirname, '" after "', temp^.name^, '"');
                         ptr := AddNextDirectory (dirname, temp);
                         DebugPtr (ptr);
                         writeln ('Ok.');
                    end;
               end;
          end;
	  
     until (m = 0) or (temp = Nil); { no delimiters found in string }

     // Add file to tree
     if temp <> Nil then
     begin
        writeln ('File: ', s, ' placed in "', temp^.name^, '"');
        temp^.filelist.add(s);
     end;

end;


procedure BuildTree (var dir: PDirTree);
var
     rootdir: PDirTree;
     str: string;

begin
     stop := false;
     rootdir := CreateDirEntry ('/'); { root directory }
     rootdir^.nextdir := Nil;
     rootdir^.firstsubdir := Nil;

     if Stop then Exit;

     while Not EOF (infile) do
     begin
        readln (infile, str);
        // Parse path string and build tree from dir. names
        ParseString (str, rootdir);
     end;

     dir := rootdir;
end;


var
     DirTree: PDirTree;
     //MemStatus: THeapStatus;
     //Ptr: cardinal;

begin
     if ParamCount <> 1 then
     begin
          writeln;
          writeln ('Usage: dirtree inputfile');
          writeln;
          writeln ('No file specified for input');
          exit;
     end;

     Assign (infile, ParamStr (1));
     Reset (infile);

     //MemStatus := GetHeapStatus ();
     //Ptr := MemStatus.TotalFree;

     writeln;
     writeln ('Creating directory tree...');
     BuildTree (DirTree);

     writeln ('Directory tree output:');
     PlotTreeOnScreen (DirTree, 0);

     writeln ('Deleting directory tree...');
     DeleteDirectory (DirTree);

     writeln ('Done.');

     //writeln ('Memory leak, in bytes:', MemStatus.TotalFree - ptr);

     Close (infile);
end.
