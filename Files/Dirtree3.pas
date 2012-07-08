
uses Objects, SysUtils;

type
     TDirName = Pstring;

     PDirTree = ^TDirTree;
     TDirTree = record
       name: TDirName;
       nextdir: PDirTree;
       firstsubdir: PDirTree;
     end;

var
     stop : boolean;
     infile: Text;

procedure NoMem;
begin
     writeln ('Error: Cannot allocate memory!');
     stop := true;
end;

function CreateDirEntry (dirname: string): PDirTree;
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
     Result := ptr;
end;

procedure AddSubDirectory (dirname: string; var ParentDir: PDirTree);
var
     ptr: PDirTree;
begin
     ptr := CreateDirEntry (dirname);
     if ptr = Nil then
     begin
          NoMem;
          Exit;
     end;

     ParentDir^.nextdir := Nil;
     ParentDir^.firstsubdir := ptr;

     ParentDir := ParentDir^.firstsubdir; { From now you are parent }
end;

procedure AddNextDirectory (dirname: string; var ParentDir: PDirTree);
var
     ptr: PDirTree;
begin
     ptr := CreateDirEntry (dirname);
     if ptr = Nil then
     begin
          NoMem;
          Exit;
     end;

     ParentDir^.nextdir := ptr;
     ParentDir^.firstsubdir := Nil;

     ParentDir := ParentDir^.nextdir;
end;


procedure PlotTreeOnScreen (dir: PDirTree; level: word);
begin
     if dir = Nil then Exit;
     writeln (' ':(level*2), dir^.name^); { action with directory }
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
     Dispose (dir);
end;


function FindDirectory (dirname: string; where: PDirTree): PDirTree;
var
     location: PDirTree;

procedure RecursiveSearch (pdir: PDirTree);
begin
     if pdir = Nil then Exit;
     if CompareStr (pdir^.name^, dirname) = 0 then
     begin
          location := pdir;
          Exit;
     end;
     RecursiveSearch (pdir^.firstsubdir);
     RecursiveSearch (pdir^.nextdir);
end;

begin
     location := Nil;
     RecursiveSearch (where);
     Result := location;
end;

procedure AddFileToTree;
begin
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

     repeat

          m := pos (Delimiter, s);

          if m <> 0 then
          begin
               dirname := copy (s, 1, m-1);
               delete (s, 1, m);

               // looking for 'dirname' in parent directory (ptr)
               temp := FindDirectory (dirname, ptr);

               // if not found, we need create it in dirtree
               if temp <> Nil then
                   //AddFileToTree;
                   writeln ('dir found: "', temp^.name^,'"')
               else
                   // create dir
                   writeln ('Dir "', dirname, '" need to be created in parent "', ptr^.name^,'"');

               ptr := temp;
          end;

     until m = 0; { no delimiters found in string }

     writeln ('File: ', s);
     Tree := ptr;
end;

procedure BuildTree (var dir: PDirTree);
var
     rootdir: PDirTree;
     str: string;

begin
     stop := false;
     rootdir := CreateDirEntry ('/'); { root directory }
     if Stop then Exit;

     while Not EOF (infile) do
     begin
        readln (infile, str);
        dir := rootdir;
        // Parse path string and build tree from dir. names
        ParseString (str, dir);
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
          writeln ('No file specified for input');
          exit;
     end;

     Assign (infile, ParamStr (1));
     Reset (infile);

     //MemStatus := GetHeapStatus ();
     //Ptr := MemStatus.TotalFree;

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
