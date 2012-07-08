type
   PInfo = ^TInfo;      { указатель на тип TInfo}
   TInfo = record
     Size,
     Len: integer;
     ss:  string[20];
   end;

   Arr = array[1..10] of word;
   PArr     = ^Arr;     { указатель на тип Arr}

   PInteger = ^Integer; { указатель на тип Integer }

var
   i:     integer;
   PInt:  PInteger;
   PI:    PInfo;
   PA:    PArr;

begin

     writeln;

     PInt := New (PInteger); { выделение памяти под указатель на тип Integer }
      PInt^ := 123; { значению по адресу PInt зададим значение }
      writeln ('Value = ', PInt^);
     Dispose (PInt); { освобождение зарезервированной памяти }

     writeln;

     PA := New (PArr); { выделение памяти под указатель на тип Arr }
      for i := 1 to 10 do PA^[i] := i * 2 - 1; { значениям массива по адресу PA зададим значения }
      for i := 1 to 10 do write (PA^[i] : 4); { выведем элементы массива по адресу PA }
     Dispose (PA); { освобождение зарезервированной памяти }

     writeln;
     writeln;

     PI := New (PInfo); { выделение памяти под указатель на тип TInfo}
      with PI^ do { заносим данные в запись по адресу PI }
      begin
          writeln ('Enter some information');
          { вводим значения переменных в записи }
          write ('Size: '); readln (Size);
          write ('Length: '); readln (Len);
          write ('String: '); readln (ss);

          writeln;
          { выводим их значения }
          writeln ('Size: ', Size : 20);
          writeln ('Length: ', Len : 18);
          writeln ('String: ', ss : 18);
      end;
     Dispose (PI); { освобождение зарезервированной памяти после использования записи }

end.