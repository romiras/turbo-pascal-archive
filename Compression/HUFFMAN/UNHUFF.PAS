{$R-,I-,S-,G+}
program huffman;
const sb=512;
var a:array[0..511]of longint;
    b:array[byte]of word;
    c:array[0..1,byte]of word;
    j,co,gb:byte;
    f,g:file;
    size:longint;
    brp,brm,bwp,pp:word;
    bufr,bufw:array[0..sb-1]of byte;
    reof:boolean;
procedure opget(var f:file;s:string);
begin
 assign(f,s);
 reset(f,1);
 blockread(f,size,4);
 blockread(f,bufr,sb,brm)
end;
procedure init;
begin
 brp:=0;
 brm:=0;
 bwp:=0;
 co:=0;
 gb:=0;
 pp:=510;
 reof:=false
end;
procedure clput(var f:file);
begin
 blockwrite(f,bufw,bwp);
 close(f)
end;
procedure sift(l,r:word);
var i,j,x:word;
begin
 i:=l; j:=l+l+1; x:=b[l];
 if (j<r)and(a[b[j]]>a[b[j+1]])then inc(j);
 while (j<=r)and(a[x]>=a[b[j]])do begin
  b[i]:=b[j]; i:=j; j:=j+j+1;
  if (j<r)and(a[b[j]]>a[b[j+1]])then inc(j)
 end;
 b[i]:=x
end;
procedure build;
var i,p:word;
begin
 for i:=0 to 255 do b[i]:=i;
 for i:=127 downto 0 do sift(i,255);
 p:=0;
 for i:=255 downto 1 do begin
  c[0,p]:=b[0];
  b[0]:=b[i];
  sift(0,i-1);
  c[1,p]:=b[0];
  b[0]:=p+256;
  a[p+256]:=a[c[0,p]]+a[c[1,p]];
  sift(0,i-1);
  inc(p)
 end;
end;
function getc(var f:file):byte;
var ch:byte;
begin
 getc:=bufr[brp];
 inc(brp);
 if brp=brm then begin
  blockread(f,bufr,sb,brm); brp:=0
 end
end;
procedure putc(var f:file;b:byte);
begin
 inc(a[b]);
 if bwp=sb-1 then build;
 if bwp=sb then begin
  blockwrite(f,bufw,sb);
  bwp:=0
 end;
 dec(size);
 if size=0 then reof:=true;
 bufw[bwp]:=b;
 inc(bwp)
end;
procedure getb(var f:file);
var bb:byte;
begin
 if co=0 then begin gb:=getc(f); co:=8 end;
 dec(co);
 bb:=gb shr co and 1;
 pp:=c[bb,pp-256];
 if pp<256 then begin putc(g,pp); pp:=510 end
end;
begin
 init;
 opget(f,paramstr(1));
 assign(g,'test.out');
 rewrite(g,1);
 for j:=0 to 255 do a[j]:=1;
 build;
 while not reof do getb(f);
 clput(g)
end.
