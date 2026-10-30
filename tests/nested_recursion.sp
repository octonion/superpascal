program nested(input, output);
procedure outer(n: integer);
  procedure inner(k: integer);
  begin
    if k > 0 then outer(k - 1)
  end;
begin
  if n = 0 then writeln('Nested recursion succeeded')
  else inner(n)
end;
begin
  outer(4)
end.
