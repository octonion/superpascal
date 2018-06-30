program pipeline;

const
    len = 100;

type
    channel = *(integer);

var
    left, right: channel;
    value: integer;

procedure node(i: integer; left, right: channel);
var value: integer;
begin
    receive(left, value);
    send(right, value+1)
end;

procedure create(left, right: channel);
type row = array [0..len] of channel;
var c: row; i: integer;
begin
    c[0] := left;
    c[len] := right;
    for i := 1 to len-1 do
        open(c[i]);
    forall i := 1 to len do
        node(i, c[i-1], c[i])
end;

begin
    open(left, right);

    parallel
        send(left, 0) |
        create(left, right) |
        receive(right, value)
    end;

    writeln('The resulting value is ', value)
end.
