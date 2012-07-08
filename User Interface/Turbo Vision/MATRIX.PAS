{ From : Nick Doodka                   2:4641/58.18            24.12.97}
{ Subj : Двумерный массив на базе коллекций }
unit Matrix;

interface

uses Objects;

type
  PMatrix = ^TMatrix;
  TMatrix = object(TCollection)
    Column: Integer;
    constructor Init(Cols, Rows: Integer);
    function Get(X, Y: Integer): PObject;
    procedure Put(X, Y: Integer; Item: PObject);
    procedure InsCol(Col: Integer);
    procedure InsRow(Row: Integer);
    procedure DelCol(Col: Integer);
    procedure DelRow(Row: Integer);
  end;

implementation

constructor TMatrix.Init(Cols, Rows: Integer);
begin
  inherited Init(Rows, 10);
  Column := Cols;
  for Rows := 0 to Pred(Rows) do InsRow(0);
end;

function TMatrix.Get(X, Y: Integer): PObject;
begin
  Get := PCollection(At(Y))^.At(X)
end;

procedure TMatrix.Put(X, Y: Integer; Item: PObject);
var
  P: PObject;
begin
  P := Get(X, Y);
  PCollection(At(Y))^.AtPut(X, Item);
  if P <> nil then Dispose(P, Done);
end;

procedure TMatrix.InsCol(Col: Integer);

  procedure InsertColumn(P: PCollection); far;
  begin
    P^.AtInsert(Col, nil);
  end;

begin
  ForEach(@InsertColumn);
  Column := PCollection(At(0))^.Count;
end;

procedure TMatrix.InsRow(Row: Integer);
var
  C: PCollection;
begin
  C := New(PCollection, Init(Column, 10));
  AtInsert(Row, C);
  for Row := 0 to Column - 1 do C^.Insert(nil);
end;

procedure TMatrix.DelCol(Col: Integer);

  procedure FreeColumn(P: PCollection); far;
  begin
    P^.AtFree(Col);
  end;

begin
  ForEach(@FreeColumn);
  Column := PCollection(At(0))^.Count;
end;

procedure TMatrix.DelRow(Row: Integer);
begin
  AtFree(Row);
end;

end.

