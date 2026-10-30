program invalidrecursion(input, output);
var counter: integer;
procedure outer(n: integer);
  procedure inner(k: integer);
  begin
    if k > 0 then outer(k - 1)
  end;
begin
  counter := counter + 1;
  inner(n)
end;
begin
  counter := 0;
  outer(2);
  writeln(counter)
end.
