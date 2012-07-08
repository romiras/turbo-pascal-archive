
uses Classes, crt;

type
     PUnitNode = ^TUnitNode;
     TUnitNode = record
       idx: integer;
       list: TList; { pointers (PUnitNode) to descendant unit nodes }
     end;

procedure ShowLevel (const level: integer);
var k: integer;
begin
  //writeln ('Level: ', level);
  for k := 1 to level do write ('#'); writeln;
end;

procedure ViewGraph (const node: PUnitNode; pos, lev: integer);
var k, cnt: integer;
const d = 4; // shift for units in graph
begin
  with Node^ do
  begin
    gotoXY (pos, lev);
    write (idx);
    if List = Nil then
      exit;
    cnt := List.Count;
    if cnt > 0 then
      dec (pos, d * Pred (cnt) div 2); // calc most left position for unit
    for k := 0 to Pred (cnt) do
    begin
      //gotoXY (pos, lev);
      //write (PUnitNode (List.Items[k])^.idx);
      ViewGraph (List.Items[k], pos, Succ (lev)); // recursive walk on tree
      inc (pos, d);
    end;
  end;
end;

procedure ViewTree (const node: PUnitNode; const level: integer);
var k: integer;
begin
  with Node^ do
  begin
    ShowLevel (level);
    writeln ({'index:', }idx : (level * 2 + 1));
    if List = Nil then
      exit;
    for k := 0 to Pred (List.Count) do
    begin
      writeln ( PUnitNode (List.Items[k])^.idx : (level * 2 + 1));
      ViewTree (List.Items[k], Succ (level)); // recursive walk on tree
    end;
  end;
end;

procedure AddNode (var node: PUnitNode; level: integer);

procedure FillList (var node: PUnitNode);
var
     yn: string[1];
     flag: boolean;
     newnode: PUnitNode;
begin
  with Node^ do
  begin

  List := TList.Create;
  repeat
    //writeln ('Level: ', level);
    ShowLevel (level);
    write ('New entry item[',level,'] (y/n) ? '); readln (yn);
    flag := (yn <> 'n');
    if flag then
    begin
      AddNode (newnode, Succ (level));
      List.Add (newnode);
    end;
  until Not Flag;

  end;
end;

procedure FillEntry (var node: PUnitNode);
var yn: string[1];
begin
  with node^ do
  begin
    write ('Entry index? '); readln (idx);
    write ('Add childs (y/n) ? '); readln (yn);
    if yn <> 'n' then
      FillList (node)
    else
      List := Nil;
  end;
end;

begin
//  writeln ('Level: ', level);
  New (node);
  FillEntry (node);
end;

procedure DeleteNode (Var node: PUnitNode);
var k: integer;
    P: PUnitNode;
begin
  // recursive deletion
  with node^ do
  if List <> Nil then
  begin
    // free all child descedants
    for k := 0 to Pred (List.Count) do
    begin
      p := PUnitNode (List.Items[k]);
      DeleteNode (p);
      List.Items[k] := p;
    end;
    List.Free;
  end;
  Dispose (node);
end;

var
  Units: TStringList;
  i: integer;
  root: PUnitNode;

begin
  randomize;
  clrscr;
{  Units := TStringList.Create;
  for i := 0 to 8 do
     Units.Add (chr(48+i));}

  AddNode (root, 0);
//  ViewTree (root, 0);
  ViewGraph (root, Lo (WindMax) div 2, 10 {line number});
  DeleteNode (root);

{  for i := 0 to pred (Units.Count) do
     writeln (Units.Strings[i]);

  Units.Free;}
  readln;
end.
