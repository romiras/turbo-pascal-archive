unit linklist;
interface
type
    entry = double; {may be any type}
    node_ptr=^node;
    node = record
              info:entry;
              next:node_ptr;
           end;

procedure list_init(var head:node_ptr);
{initializes the list to be empty}

function list_next(p:node_ptr):node_ptr;
{returns a pointer to the next node in the list
 asumption:  p points to a node in the list }

function list_prev(head:node_ptr; p:node_ptr):node_ptr;
{returns a pointer to the previous node in the list
 assumption: p points to a node in the list}

function retrieve(head:node_ptr):entry;
{return the number (x) that is pointing to}

procedure headinsert(var head:node_ptr; x:entry);
{a new node containing 'x' insert at the head of the list}

procedure insert_after(p:node_ptr; x:entry);
{insert x AFTER a node that p point to it}

procedure insert_before(p:node_ptr; x:entry);
{insert x BEFORE a node that p point to it}

procedure delete_num(var head:node_ptr; x:entry);
{if there is a node that contains 'x', then the first
 such a node has been removed from the list.
 if no node contains 'x', the list is not change}

function search(head:node_ptr; x:entry):node_ptr;
{returns pointer to the first node contains 'x'.
 if no node contains 'x', then returns nil.}

function is_empty(head:node_ptr):boolean;
{returns true if the list is empty, and false otherwise.}

procedure destroy_list(var head:node_ptr);
{destroy the list and free the memory}

implementation

procedure list_init(var head:node_ptr);
begin
     head:=nil;
end; {list_init}

function list_next(p:node_ptr):node_ptr;
begin
     list_next := p^.next;
end; {list_next}

function list_prev(head:node_ptr; p:node_ptr):node_ptr;
begin
     while (head <> nil) and (head^.next <> p) do
           head:=head^.next;
     list_prev:=head;
end; {list_prev}

function retrieve(head:node_ptr):entry;
begin
   retrieve:=head^.info;
end; {retrieve}

procedure headinsert(var head:node_ptr; x:entry);
var temp:node_ptr;
begin
   new(temp);
   temp^.info:=x;
   temp^.next:=head;
   head:=temp;
end; {headinsert}

procedure insert_after(p:node_ptr; x:entry);
var temp:node_ptr;
begin
   new(temp);
   temp^.info:=x;
   temp^.next:=p^.next;
   p^.next:=temp;
end; {insert_after}

procedure insert_before(p:node_ptr; x:entry);
var temp:node_ptr;
begin
   new(temp);
   temp^:=p^;
   p^.info:=x;
   p^.next:=temp;
end; {insert_before}

procedure delete_num(var head:node_ptr; x:entry);
var
   currptr,prevptr:node_ptr;
begin
   if (head <> nil) then
   begin {traverse the list}
      prevptr:=nil;
      currptr:=head;
      while (currptr <> nil) and (currptr^.info <> x) do
      begin
         prevptr:=currptr;
         currptr:=currptr^.next;
      end;
      if (prevptr = nil) then  {x is the first elemnt}
         begin
            head:=head^.next;
            dispose(currptr);
         end
      else if (currptr <> nil) then  {x if not the first element}
         begin
            prevptr^.next:=currptr^.next;
            dispose(currptr);
         end;
   end;
end; {delete_num}

function search(head:node_ptr; x:entry):node_ptr;
begin
   while (head <> nil) and (head^.info <> x) do
         head:=head^.next;
   search:=head;
end; {search}

function is_empty(head:node_ptr):boolean;
begin
     is_empty:= (head=nil); {true if head=nil}
end; {is_empty}

procedure destroy_list(var head:node_ptr);
var p:node_ptr;
begin
   while head <> nil do
   begin
      p:=head^.next;
      dispose(head);
      head:=p;
   end;
   p := Nil; 
end; {destroy_list}

begin
end.
