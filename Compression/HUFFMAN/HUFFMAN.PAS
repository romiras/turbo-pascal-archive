{$R-,I-,S-,G+}
program huffman;
const sb=256;
type obr=record
      vl:longint;
      len:byte
     end;
var a:array[0..511]of longint;
    b:array[byte]of word;
    c:array[0..1,byte]of word;
    st:array[byte]of byte;
    j,obc:byte;
    f,g:file;
    obb,size:longint;
    brp,brm,bwp:word;
    bufr,bufw:array[0..sb-1]of byte;
    reof:boolean;
    o:array[byte]of obr;
procedure opget(var f:file;s:string);
begin
 assign(f,s);
 reset(f,1);
 blockread(f,bufr,sb,brm)
end;
procedure init;
begin
 brp:=0;
 brm:=0;
 bwp:=0;
 obb:=0;
 obc:=0;
 reof:=false
end;
procedure putc(var f:file;b:byte);
begin
 if bwp=sb then begin blockwrite(f,bufw,sb); bwp:=0 end;
 bufw[bwp]:=b;
 inc(bwp)
end;
procedure clput(var f:file);
begin
 putc(f,obb shr 24);
 blockwrite(f,bufw,bwp);
 close(f)
end;
procedure out(var out:file;ch:byte);
var glk:byte;
begin
 obb:=obb or o[ch].vl shl (32-o[ch].len-obc);
 inc(obc,o[ch].len);
 while obc>=8 do begin
  glk:=obb shr 24;
  putc(out,glk);
  obb:=obb shl 8;
  dec(obc,8)
 end
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
procedure obh(i:word;p:byte);
begin
 if i<256 then begin
  o[i].len:=p;
  o[i].vl:=0;
  for j:=0 to p-1 do o[i].vl:=o[i].vl shl 1+st[j]
 end
 else begin
  st[p]:=0;
  obh(c[0,i-256],p+1);
  st[p]:=1;
  obh(c[1,i-256],p+1)
 end
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
 obh(p+255,0)
end;
procedure getc(var f:file);
var ch:byte;
begin
 ch:=bufr[brp];
 out(g,ch);
 inc(a[ch]);
 inc(brp);
 if brp=brm then begin
  if eof(f) then reof:=true else build;
  blockread(f,bufr,sb,brm); brp:=0
 end
end;
begin
 init;
 opget(f,paramstr(1));
 size:=filesize(f);
 assign(g,'test.glk');
 rewrite(g,1);
 blockwrite(g,size,4);
 for j:=0 to 255 do a[j]:=1;
 build;
 while not reof do getc(f);
 clput(g)
end.
