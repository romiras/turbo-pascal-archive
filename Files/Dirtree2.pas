
uses Objects, Dos;

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
     rootdir: PDirTree;

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

     
function FindDirectory (dirname: string; where: PDirTree): PDirTree;
var
     location: PDirTree;

procedure RecursiveSearch (pdir: PDirTree);
begin
     if pdir = Nil then Exit;
     if pdir^.name^ = dirname then
     begin
          location := pdir;
          Exit;
     end;
     RecursiveSearch (pdir^.firstsubdir);
     RecursiveSearch (pdir^.nextdir);
end;

begin
     Result := Nil;
     RecursiveSearch (where);
     Result := location;
end;


procedure BuildTree (var dir: PDirTree);
var
     temp: PDirTree;
begin
     stop := false;
     rootdir := CreateDirEntry ('/'); { root directory }
     if Stop then Exit;

     dir := rootdir;

     AddSubDirectory ('sub1', dir);
     if Stop then Exit;

     AddNextDirectory ('sub2', dir);
     if Stop then Exit;
     
     temp := dir;
     AddSubDirectory ('sub2-sub', temp);
     if Stop then Exit;
     dir := temp;

     AddNextDirectory ('sub3', dir);
     if Stop then Exit;

     AddSubDirectory ('sub3-sub', dir);
     if Stop then Exit;

     dir := rootdir;
end;

procedure PlotTreeOnScreen (dir: PDirTree);
begin
     if dir = Nil then Exit;
     writeln ('--' , dir^.name^); { action with directory }
     PlotTreeOnScreen (dir^.firstsubdir); { at first, print subdirs }
     PlotTreeOnScreen (dir^.nextdir); { after that, print next dir }
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


var
     DirTree, dirfound: PDirTree;
     MemStatus: THeapStatus;
     Ptr: cardinal;

begin
     MemStatus := GetHeapStatus ();
     Ptr := MemStatus.TotalFree;

     writeln ('Creating directory tree...');
     BuildTree (DirTree);

     writeln ('Directory tree output:');
     PlotTreeOnScreen (DirTree);

     writeln ('Directory name search:');
     dirfound := FindDirectory ('sub3-sub', rootdir);
     if dirfound <> nil then
     begin
          writeln (dirfound^.name^:20);
               if dirfound^.nextdir <> Nil then
                    writeln ((dirfound^.nextdir)^.name^:20);
     end;

     writeln ('Deleting directory tree...');
     DeleteDirectory (DirTree);

     writeln ('Done.');

     writeln ('Memory leak, in bytes:', MemStatus.TotalFree - ptr);
end.
