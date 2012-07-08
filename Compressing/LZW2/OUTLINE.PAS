(*-----------------------------------------------------------
    Демонстрация работы модуля LZW2
    (сжимает/расжимает файлы)
-------------------------------------------------------------*)
{$I-,R-,S-,O-,F-,B-}
uses bitfile2,{lzss}
             {to_bits}
             {lzss1}
             {arifm}
             lzw2
             {lzw_ar}
             {lzss3}  {}
             {lzw_hu}
             {haffman};

(*-----------------------------------------------------------
   Обработка фатальной ошибки при работе программы.
-------------------------------------------------------------*)
procedure fatal_error(str:string);
begin
   writeln( 'Сбой программы: ', str);
   halt(1);
end;

(*-----------------------------------------------------------
   Вывод сообщения об использовании
-------------------------------------------------------------*)

procedure usage_exit (prog_name:string);
begin
   writeln('Использование:  DLM A|X sou_file dest_file');
   halt(0);
end;

(*-----------------------------------------------------------
   Измерение длины файла
-------------------------------------------------------------*)

function file_size (name:string):longint;
var f:file;
begin
  assign(f,name);
  reset(f,1);
  file_size:=filesize(f);
  close(f);
end;

(*-----------------------------------------------------------
   Вывод сообщения о соотношении размеров файлов
*)
procedure print_ratios(inputf,outputf:string);
var
   input_size:longint;
   output_size:longint;
   ratio:integer;
begin
   input_size := file_size( inputf );
   if input_size = 0 then input_size := 1;
   output_size:= file_size( outputf );
   ratio:= 100 - integer ( output_size * 100 div input_size );
   writeln;
   writeln('Байт на входе:        ', input_size );
   writeln('Байт на выходе:       ', output_size );
   if ( output_size = 0 ) then
      output_size := 1;
   writeln('Степень сжатия: ', ratio,'%');
end;

procedure outputTime(t:longint);
var i:integer; s:string;
begin
   i:=t*100 div 182;
   Str(i,S);  insert('.',S,length(S)-1);
   writeln('Время        :        ',S,' сек');
end;

var inputf:TInputFile;
    outputf:TOutputFile;
    Com:char; S:string; t:longint;
begin
   if paramcount < 3 then usage_exit( paramstr(0) );
   S:=paramstr(1); Com:=upcase(S[1]);
   if (Com<>'A') and (Com<>'X') then usage_exit(paramstr(0));

   if Com='A' then
    begin
     inputf.Init;
     inputf. Open(paramstr(2));
     outputf.New(paramstr(3));
     writeln( 'Сжимаю ',paramstr(2),' в ',paramstr(3));
     writeln( 'Используя ', CompressionName );
      t:=meml[$0:$46C];
      CompressFile( inputf, outputf );
      t:=meml[$0:$46C]-t;
     outputf.Close;
     inputf.Close;
     print_ratios( paramstr(2), paramstr(3));
     outputTime(t);
    end else
    begin
     inputf.init;
     inputf. Open(paramstr(2));
     outputf.New(paramstr(3));
     writeln( 'Разжимаю ',paramstr(2),' в ',paramstr(3));
     writeln( 'Используя ', CompressionName );
      t:=meml[$0:$46C];
      ExpandFile( inputf, outputf );
      t:=meml[$0:$46C]-t;
      outputTime(t);
     outputf.Close;
     inputf.Close;
    end;

end.

