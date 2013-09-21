program  Analize;

type
  diagrams = record
    ops, text  : string;
  end;

const
    max = 9;
    all : array [1..max] of diagrams = (
   ( ops:'+';   text: '($<)+($>)'),
   ( ops:'-';   text: '($<)-($>)'),
   ( ops:'*';   text: '($<)*(>)+($>)*(<)'),
   ( ops:'/';   text: '(($<)*(>)-($>)*(<))/((>)*(>))'),
   ( ops:'sin'; text: 'cos(>)*($>)'),
   ( ops:'cos'; text: '($>)*(-sin(>))'),
   ( ops:'exp'; text: '(($>)*exp(>))'),
   ( ops:'ln';  text: '($>)/(>)'),
   ( ops:'x';   text: '1') );

var str : string[60];

procedure find_simb (beg,end1:integer;wanted:string;var pos1,pos2:integer);
var
  i,bc,k,n : integer;
  fl : boolean;
begin
  bc := 0; n:=Length(wanted);
  for i:=beg to end1 do begin
    fl:=true;
    for  k:=0 to n-1 do
      if (str[i+k]<>wanted[k+1]) then begin fl := false; break end;
    if((fl)and(bc=0)) then break;
    if (str[i]='(') then Inc(bc);
    if (str[i]=')') then Dec(bc);
  end;
  pos1:=i;
  pos2:=i+n-1;
  if not(fl) then pos2:=end1+1;
end;

function df(beg,end1:integer):string;
  var
    st,sx,cur_adr : string;
    ch : char;
    i,j,pos1,pos2,uk : integer;
  begin
    st:='';sx:='';
    if (str[beg]='(') then begin find_simb(beg+1,end1,')',pos1,pos2);
      if (pos2>end1-1) then begin
        df := df(beg+1,pos2-1);
        exit
      end;
    end;
    for i:=1 to max do begin
      find_simb(beg,end1,all[i].ops,pos1,pos2);
      if(pos2<=end1) then begin
        cur_adr:=all[i].text;
        uk := 0;
        while (uk<Length(cur_adr)) do begin
          Inc(uk);
          ch := cur_adr[uk];
          case ch of
           '$' : begin Inc(uk); ch:=cur_adr[uk];
              if (ch='<') then sx:=df(beg,pos1-1)
               else sx:=df(pos2+1,end1);
             end;
           '<' : begin
              for j:=beg to pos1-1 do sx[j-beg+1]:=str[j];
              sx[0]:=chr(pos1-beg);
             end;
           '>' : begin for j:=pos2+1 to end1 do sx[j-pos2]:=str[j];
              sx[0]:=chr(end1-pos2);
             end;
           else sx:=ch;
          end;  { case }
          st:=st+sx;
        end; { while }
        df:=st; exit;
      end;  { if }
    end; { for }
    df:='0';
  end;  { df }

begin
  Readln(Str);
  while Str<>'' do begin
    Writeln( df(1, Length(Str)) );
    Readln( Str );
  end;
end.

