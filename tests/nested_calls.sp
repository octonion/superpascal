program nestedcalls(input, output);
procedure outer(n: integer);
  procedure inner(k: integer);
  begin
    writeln('Nested call ', k:1)
  end;
begin
  inner(n)
end;
begin
  outer(4)
end.
