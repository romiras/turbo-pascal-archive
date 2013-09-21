
Type 
  ttype = integer;

  ptitem = ^titem;
  titem = Record
            data: ttype;
            next: ptitem;
End;

tqueue = Object
           head, tail: ptitem;

           constructor init;
           destructor done;

           Procedure put(x: ttype);

           Function get: ttype;

           Function empty: boolean;

           Procedure print;

           Function get_count: word;
End;


constructor tqueue.init;
Begin
  head := Nil;
  tail := Nil;
End;
destructor tqueue.done;
Begin
  while empty Do get
End;

Procedure tqueue.put(x: ttype);

Var p: ptitem;
Begin
  new(p);
  p^.data := x;
  p^.next := Nil;
  If empty Then head := p
  Else tail^.next := p;
  tail := p
End;

Function tqueue.get: ttype;

Var p: ptitem;
Begin
  If Not empty Then
    Begin
      p := head;
      head := head^.next;

      get := p^.data;
      dispose(p);
    End
  Else
    Begin
      writeln('reading from empty queue');
      halt(102)
    End;
End;

Function tqueue.empty: boolean;
Begin
  empty := Not assigned(head)
End;

Procedure tqueue.print;

Var p: ptitem;
Begin
  p := head;
  write('(queue) <');
  while assigned(p) Do
  Begin
    write(p^.data, ' ');
    p := p^.next
  End;
  writeln('>')
End;

Function tqueue.get_count: word;

Var 
  count: word;
  p: ptitem;
Begin
  p := head;
  count := 0;
  while assigned(p) Do
  Begin
    inc(count);
    p := p^.next
  End;
  get_count := count
End;

{ А вот и сама сортировка очереди }

Procedure sort(Var q: tqueue);

Var 
  i, j, k,
  it, it_next: integer;
  len: word;
Begin
  len := q.get_count;
  For i := 1 To len Do
    Begin
      it := q.get;
      For j := 1 To len - i Do
        Begin
          it_next := q.get;
          If it > it_next Then
            Begin
              q.put(it);
              it := it_next;
            End
          Else
            q.put(it_next)
        End;

      For k := 1 To pred(i) Do
        q.put(q.get);

      q.put(it);
    End;
End;

Const 
  test: array[1 .. 10] Of integer = 
                                    (2, 5, 17, 7, 9, 3, 4, 6, 11, 71);

Var 
  i: integer;
  qint: tqueue;

Begin
  qint.init;

  For i := 1 To 10 Do
    qint.put(test[i]);
  qint.print;
  sort(qint);
  qint.print;

  qint.done;
End.
