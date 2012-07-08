
uses Objects;

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
     CreateDirEntry := nil;

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
     CreateDirEntry := ptr;
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

procedure BuildTree (var dir: PDirTree);
var
     rootdir: PDirTree;
begin
     stop := false;
     rootdir := CreateDirEntry ('/'); { root directory }
     if Stop then Exit;

     dir := rootdir;

     AddSubDirectory ('sub1', dir);
     if Stop then Exit;

     AddNextDirectory ('sub2', dir);
     if Stop then Exit;

     AddNextDirectory ('sub3', dir);
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
     DirTree: PDirTree;

begin
     writeln ('Creating directory tree...');
     BuildTree (DirTree);

     writeln ('Directory tree output:');
     PlotTreeOnScreen (DirTree);

     writeln ('Deleting directory tree...');
     DeleteDirectory (DirTree);

     writeln ('Done.');
end.
