uses CRT;

Type
   MenuType = (Vertical, Horizontal);

const
   MaxItems = 5; { Max of items in menu }
   width = 6; { Max length of items }
   optText: array [1..MaxItems] of string[width] =
   ('item 1',
    'item 2',
    'item 3',
    'item 4',
    'item 5');

   optNormal = LightGray;
   optSelected = Yellow;

var
   X, Y,
   selected,  { Index of item, selected by color at start }
   row: byte;

procedure MakeMenu;
var
   i: byte;
begin
     ClrScr;
     Y := row;
     for i := 1 to MaxItems do
     begin
          GoToXY (X, Y);
          if i = selected then
             TextColor (optSelected)
          else
             TextColor (optNormal);
          write (optText[i]);
          inc (Y, 2);
     end;
end;

function Choice: byte;
var
   ch: char;
begin
     selected := 1;
     X := (80 - width) div 2;
     row := (25 - MaxItems) div 2;
     repeat
           MakeMenu;
           ch := readkey;
           if ch = #0 then
              ch := readkey;
           case ch of
           #80: {Down}
           begin
                inc (Selected);
                if Selected > MaxItems then
                   Selected := 1;
                MakeMenu;
           end;

           #72: {Up}
           begin
                dec (Selected);
                if Selected = 0 then
                   Selected := MaxItems;
                MakeMenu;
           end;
           end;
     until ch = #13; {Enter}
     Choice := Selected;
end;

var
  Option: byte;

begin
     Option := Choice;

     TextColor (LightGray);
     clrscr;
     writeln (optText[option]);
     readln;
end.