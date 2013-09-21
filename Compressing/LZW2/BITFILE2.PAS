{$Q-,R-,S-}
unit bitfile2;
interface
uses objects;
const BUF_SIZE=10000 and not($F); {выравниваем на границу параграфа}
      BITS_IN_REGISTER=16;
type
      PBuffer=^TBuffer;
      TBuffer=array[0..BUF_SIZE-1] of byte;

      PInputFile=^TInputFile;
      TInputFile=object(TObject)
      f        :file;
      buffer   :PBuffer;
      cur_pos  :word;
      in_buffer:word;
      eof      :boolean;

      B,BC:byte;

      bits_to_go,garbage_bits,buff:integer;
      function  open(const filename:string):boolean;
      procedure close;
      function  getbyte:byte;virtual;
      procedure getnbytes(var Buf; Size:word);
      function  GetBits(Count:word):word;virtual;
      function  input_bit:integer;
      procedure LoadBuffer;
     end;

     POutputFile=^TOutputFile;
     TOutputFile=object
      f        :file;
      buffer   :PBuffer;
      cur_pos  :word;
      tmp      :word;
      error    :boolean;

      pacifier_counter:integer;
      bits,BUF:byte;

      bits_to_go,buff:integer;
      bits_to_follow:longint;

      procedure output_bit(bit:integer);
      procedure output_bits(bts:integer;count:integer);
      procedure done_outputing_bits;
      procedure output_bit_plus_follow(bit:integer);
      function  new(const filename:string):boolean;
      procedure close;
      procedure putbyte(ch:byte);
      procedure PutBits(W:word;Count:word);
     end;

implementation
{========================================================}

function TInputFile.open(const filename:string):boolean;
 begin
       assign(f,filename);
       reset (f,1);
       if ioresult>0 then open:=false
        else
          begin
           New(buffer);

           in_buffer:=BUF_SIZE;
             cur_pos:=BUF_SIZE+1;
                open:=true;
                 eof:=false;

                 BC:=0; B:=0;

                 bits_to_go := 0;
                 garbage_bits := 0;
                 buff:=0;
          end;
 end;

procedure TInputFile.close;
begin
    system.close(f);
    dispose(buffer);
end;

procedure TInputFile.LoadBuffer;
begin
 if in_buffer < BUF_SIZE then eof:=true
       else
         begin
          blockread(f,buffer^,BUF_SIZE,in_buffer);
          if in_buffer=0 then eof:=true;
          cur_pos:=0;
         end;
end;

function TInputFile.getbyte;
begin
   inc(cur_pos);
   if cur_pos >= in_buffer then LoadBuffer;
   if not eof then getbyte:=buffer^[cur_pos];
end;

procedure TInputFile.getnbytes;
var i:integer;
begin
 for i:=0 to Size-1 do
 begin
  pchar(@Buf)[i]:=char(getbyte);
 end;
end;

(*------Ввод очередного бита сжатой информации----------*)
function TInputFile.input_bit:integer;
var t:integer;
begin
   if bits_to_go = 0 then
   begin
      buff:=getbyte;
      if eof then
      begin
         inc(garbage_bits);
         if garbage_bits > (BITS_IN_REGISTER - 2) then
         begin
           writeln('Ошибка в сжатом файле');
           halt(1);
         end;
      end;
      bits_to_go:= 8;
   end;
   t := buff and 1;
   buff:=buff shr 1;
   dec(bits_to_go);;
   input_bit:=t;
end;

{=================================================================}

function TOutputFile.new(const filename:string):boolean;
 begin
       assign(f,filename);
       rewrite (f,1);
       if ioresult>0 then new:=false
        else
          begin
             system.New(buffer);
             cur_pos:=0;
               error:=false;
                 new:=true;

                pacifier_counter:= 0;
                bits:=0;
                BUF:=0;

                bits_to_follow := 0;
                buff := 0;
                bits_to_go := 8;
          end;
 end;

procedure TOutputFile.close;
 begin
     if bits<>0 then putbyte(BUF);
     if cur_pos>0 then
        begin
         blockwrite(f,buffer^,cur_pos,tmp);
         if tmp<cur_pos then error:=true;
        end;
     system.close(f);
     dispose(buffer);
 end;

procedure TOutputFile.putbyte(ch:byte);
 begin
    buffer^[cur_pos]:=ch;
    inc(cur_pos);
    if cur_pos>=BUF_SIZE then
        begin
         blockwrite(f,buffer^,BUF_SIZE,tmp);
         {}write('w');{}
         if tmp<BUF_SIZE then error:=true;
         cur_pos:=0;
        end;
 end;

(*------ Вывод очередного бита сжатой информации ----------*)
procedure TOutputFile.output_bit(bit:integer);
begin
  buff:=buff shr 1;
  if bit<>0 then buff:=buff or $80;
  dec(bits_to_go);
  if bits_to_go=0 then
  begin
    putbyte(byte(buff));
    bits_to_go := 8;
  end;
end;

procedure TOutputFile.output_bits;
var i:integer;
begin
 for i:=count-1 downto 0 do
  output_bit(integer((bts and (1 shl i))<>0));
end;
(*----- Очистка побитового вывода -------------------------*)
procedure TOutputFile.done_outputing_bits;
var b:byte;
begin
  b:=buff shr bits_to_go;
  putbyte(b);
end;

(*------ Вывод указанного бита и отложенных ранее -----------*)
procedure TOutputFile.output_bit_plus_follow(bit:integer);
begin
   output_bit (bit);
   if bit=0 then bit:=1 else bit:=0;
   while bits_to_follow > 0 do
   begin
      output_bit (bit);
      dec(bits_to_follow);
   end;
end;

const PACIFIER_COUNT=2047;

procedure TOutputFile.PutBits;
var len:byte;
begin
 len:=bits+Count;
 if len<8 then begin
                BUF:=BUF or byte(W shl (8-len));
                inc(bits,count);
               end
          else begin
                BUF:=BUF or byte(W shr (len-8));
                putbyte(BUF);
                while len>=16 do
                 begin
                  putbyte(byte(W shr (len-16)));
                  dec(len,8);
                 end;
                BUF:=byte(W shl (16-len));
                bits:=len-8;
               end;
end;

function TInputFile.GetBits(count:word):word;
var  BW:word;
begin
   if BC=0 then begin B:=GetByte; BC:=8; end;
   if Count > BC+8 then begin
                          WordRec(BW).Hi := B;
                          WordRec(BW).Lo := GetByte;
                          B  := GetByte;
                          GetBits := ( BW shl (Count-BC-8)) and
                                     ( $FFFF shr (16-Count)) or
                                     ( B shr (16-Count+BC));
                          BC:=16-Count+BC;
                        end
   else if Count > BC then
                        begin
                         WordRec(BW).Hi := B;
                         WordRec(BW).Lo := GetByte;
                         inc(BC,8);
                         GetBits := ( BW shr (BC-Count)) and
                                    ( $FFFF shr (16-Count));
                         B:=WordRec(BW).Lo;
                         dec(BC,Count);
                        end
   else begin
         GetBits:=( B shr (BC-Count)) and ($FF shr (8-Count));
         dec(BC,Count);
        end;
end;
end.

