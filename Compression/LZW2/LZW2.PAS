{$I-,R-,S-,O-,F-,B-}
unit lzw2;   {с переменной длинной кода }
interface
uses bitfile2;

const CompressionName:string = 'LZW 12-bit Coder (var code length)';

procedure CompressFile (var inputf:TInputFile;var outputf:TOutputFile);
procedure ExpandFile( var inputf:TInputFile;var outputf:TOutputFile);

implementation

{******************************************************}
{************* для        LZW      кодирования ********}
{******************************************************}

const BITS= 12;            { Количество битов в коде }

      FIRST_BITS=9;        { начальный размер кода}
      LAST_BITS=BITS;      { конечный размер кода }
      MAX_CODE= ( 1 shl BITS ) - 1 ;{ Максимальное значение кода }
      TABLE_SIZE   = 5021; { Размер словаря в элементах }

      END_OF_STREAM= 256;  { Специальный код конца потока }
      INC_CODE_SIZE= 257;  { Необходимо увеличить разрядность индекса на 1}
      CLEAR_DICT   = 258;  { очистка словаря }
      FIRST_CODE   = 259;  { Значение кода, которое получает первая добавленная
                             в словарь фраза }
      UNUSED=-1;           { Признак свободной ячейки в словаре }

{ Структура словаря для алгоритма LZW }
var   dict:array[0..TABLE_SIZE-1] of
           record
            code_value :integer;
            prefix_code:integer;
            charact    :char;
            LRU        :word;
           end;

{ Стек для декодирования }
      decode_stack:array[0..TABLE_SIZE-1] of char;

(*=============== процедуры/функции для LZW ====================*)

(*-----------------------------------------------------------
   Процедура поиска в словаре указанной пары <код фразы,
   символ>. Для ускорения поиска используется хеш, получаемый
   из параметров.
*)

function find_dictionary_match(aprefix_code:integer;character:byte):word;
var
   index,offset:integer;
begin
   (* Собственно получение значения хеш-функции *)
{   character:=character and $FF;}
   index:= (word(character) shl ( BITS - 8 ) ) xor aprefix_code;
   (* Разрешение возможных коллизий *)
   if index = 0 then offset := 1
                else offset := TABLE_SIZE - index;
   repeat
      with dict[index] do
      begin
       { Эта ячейка словаря не использована }
      if code_value=UNUSED then break;
      (* Найдено соответствие *)
      if (prefix_code = aprefix_code) and
         (charact = char(character)) then break;
      (* Коллизия. Подготовка к следующей попытке ее разрешения *)
      end;
      dec(index,offset);
      if index < 0 then index :=index + TABLE_SIZE;
   until false;
  find_dictionary_match:=index;
end;

(*-----------------------------------------------------------
   Процедура декодирования строки. Размещает символы в стеке,
   возвращает их количество.
*)

function decode_string ( count:word; code:word):word;
begin
   while code > 255 do(* Пока не встретится код символа *)
   begin
      decode_stack[count] := dict[code].charact;
      inc(count);
      code := dict[code].prefix_code;
   end;
   decode_stack[count] := char(code);
   inc(count);
   decode_string:=count;
end;


(*----------------------------------------------------------
   Очистка словаря
*)
{var tmp:array[0..MAX_CODE] of integer;}
{function ClearDict(LRUmin:word):word;
var i,maxcode:integer;
begin}
{ for i:=0 to high(tmp) do tmp[i]:=-1;

 for i:=0 to TABLE_SIZE-1 do
   with dict[i] do
    if code_value<>UNUSED then tmp[code_value]:=i;

 maxcode:=MAX_CODE;
 while tmp[maxcode]=-1 do dec(maxcode); }

{ for i:=0 to TABLE_SIZE-1 do
 with dict[i] do
 if code_value<>UNUSED then
  begin
   if LRU<LRUmin then
    begin
     code_value:=UNUSED;
    end
  end;
end; }


(*-----------------------------------------------------------
   Процедура сжатия файла
*)
procedure CompressFile (var inputf:TInputFile;var outputf:TOutputFile);
var
   next_code:integer; character:byte; string_code:integer;
   index:word;  bit_size:byte; overflow:boolean;
                cur_max_code:word;

  procedure InitCoder;
  var i:integer;
  begin
   bit_size:=FIRST_BITS;
   cur_max_code:=1 shl bit_size - 1;
   next_code := FIRST_CODE;
   for i:=0 to TABLE_SIZE-1 do dict[i].code_value:= UNUSED;
   overflow:=false;
  end;

begin
{ Инициализация кодера LZW}
   InitCoder;

  (* Считать первый символ *)
   string_code:=inputf.getbyte;
  (* Пока не конец сообщения *)
   while not inputf.eof do
   begin
     character:=inputf.getbyte;
     if inputf.eof then
               break;
     (* Попытка найти в словаре пару <фраза, символ> *)
      index:= find_dictionary_match( string_code, character );
      (* Соответствие найдено *)
      if dict[index].code_value <> -1 then
          begin
           string_code:= dict[index].code_value;
          end
      (* Такой пары в словаре нет *)
      else
      begin
         (* Добавление в словарь *)
         if next_code <= MAX_CODE then
         with dict[index] do
         begin
            code_value := next_code; inc(next_code);
            prefix_code:= string_code;
            charact    := char(character);
         end else
              overflow:=true;

         {если надо, то увеличиваем разрядность выходного кода}
         if string_code >= cur_max_code then
          if bit_size<LAST_BITS then
           begin
            outputf.putbits( INC_CODE_SIZE,bit_size);
            inc(bit_size);   cur_max_code:=1 shl bit_size - 1;
            write('^');
           end;

         (* Выдача кода *)
         outputf.putbits(string_code, bit_size);
         string_code:=character;

         if overflow then
           begin
            {очистка словаря}
            outputf.putbits( CLEAR_DICT,bit_size);
            InitCoder;
            write('C');
           end;
      end;
   end;
 { Завершение кодирования }
   outputf.putbits( string_code, bit_size );
   outputf.putbits( END_OF_STREAM,bit_size);
end;

(*-----------------------------------------------------------
   Процедура декодирования сжатого файла
*)

procedure ExpandFile( var inputf:TInputFile;var outputf:TOutputFile);
var
   next_code, new_code, old_code:integer;
   character:integer;   bit_size:byte;
   count,i:word;

 function getcode:integer;
 begin
   getcode:= inputf.getbits(bit_size);
 end;

 procedure InitDecoderAndGo;
 var i:integer;
 begin
   bit_size:=FIRST_BITS;
   next_code := FIRST_CODE;
    for i:=0 to TABLE_SIZE-1 do dict[i].code_value:= UNUSED;

   {начало декодирования}
   old_code := getcode;
   if old_code = END_OF_STREAM then exit;

   character:= old_code;

   outputf.putbyte(old_code);
 end;

begin
{ Инициализация кодера LZW}
   InitDecoderAndGo;

   repeat
      new_code:=getcode;
      case new_code of
       INC_CODE_SIZE: begin
                       inc(bit_size);
                       write('^');
                       continue;
                      end;
       CLEAR_DICT   : begin
                       {очистка словаря}
                       InitDecoderAndGo;
                       continue;
                      end;
       END_OF_STREAM,-1: break;
      end;
      { Обработка возможной исключительной ситуации }
      if new_code>=next_code then
      begin
         decode_stack[0]:=char(character);
         count := decode_string( 1, old_code );
      end
      else count := decode_string( 0, new_code );

      character := integer(decode_stack[ count - 1 ]);
      { Выдача раскодированной строки }
      while count > 0 do
        begin
         dec(count);
         outputf.putbyte(byte(decode_stack[count]));
        end;
      { Обновление словаря }
      if next_code <= MAX_CODE then
      begin
         dict[next_code].prefix_code:= old_code;
         dict[next_code].charact:= char(character);
         inc(next_code);
      end;

      old_code := new_code;
   until false;
end;

end.

