program multiplication(input, output); 
const
	n = 20 { n x n matrices }; 
	p = 3 { pipeline nodes };	
	qmin = 6 { n div p }; 
type
	vector = array [1..n] of real; 
	matrix = array [1..n] of vector;
	
procedure multiply(var a, b, c: matrix);
{ c := a*b }
type channel = *(vector);

	function f(ai, bj: vector): real; 
	var cij: real; k: integer; 
	begin 
		cij := 0.0; 
		for k := 1 to n do
			cij := cij + ai[k]*bj[k]; 
		f := cij 
	end;
	
	procedure node(r, s: integer; left, right: channel); 
	type 
		block = array [0..qmin] of vector; 
	var a, c: block; i, j: integer;
	ai, bj, ci: vector; 
	begin
		{ 1 <= r <= s <= n } 
		for i := 0 to s - r do
			receive(left, a[i]); 
		for i := s + 1 to n do 
			begin
				receive(left, ai); 
				send(right, ai) 
			end;
		for j := 1 to n do 
			begin
				receive(left, bj); 
				if s < n then
					send(right, bj); 
				for i := 0 to s - r do 
					c[i,j] := f(a[i], bj)
			end; 
		for i := 1 to r - 1 do 
			begin
				receive(left, ci); 
				send(right, ci) 
			end;
		for i := 0 to s - r do
		send(right, c[i])
	end;
	
	procedure master(var a, b, c: matrix; left, right: channel); 
	var i, j: integer; bj: vector; 
	begin
		for i := 1 to n do 
			send(left, a[i]); 
		for j := 1 to n do 
			begin
				for i := 1 to n do 
					bj[i] := b[i,j]; 
				send (left, bj) 
			end;
		for i := 1 to n do 
			receive (right, c[i]) 
	end;
	
	procedure ring(var a, b, c: matrix); 
	type net = array [0..p] of channel; 
	var k, long, qmax: integer; d: net; 
	begin
		qmax := qmin + 1;
		long := n mod p;
		for k := 0 to p do 
			open(d[k]);
		parallel
			master(a, b, c, d[0], d[p])|
			forall k := 1 to long do 
				node((k - 1)*qmax + 1, k*qmax, d[k-1], d[k])|
			forall k := long + 1 to p do
				node((k - 1)*qmin + long + 1, k*qmin + long, d[k-1], d[k])
		end 
	end;
	
begin ring(a, b, c) end { multiply };

procedure transpose(var a, b: matrix); 
{ b := aT } var i, j: integer; 
begin
	for i := 1 to n do 
		for j := 1 to n do 
			b[i,j] := a[j,i]
end;

procedure run; 
var a, b, c: matrix;

	procedure initialize(var a, b: matrix);
	var i, j: integer;
	begin
		for i := 1 to n do 
		begin
			for j := 1 to i do
				a[i,j] := 1.0; 
			for j := i + 1 to n do 
				a[i,j] := 0.0
		end;
	transpose(a, b) 
	end;
	
	procedure display(var c: matrix);
	var i, j: integer;
	begin
		for i := 1 to n do 
		begin
			for j := 1 to n do 
				write(round(c[i,j]):3);
			writeln 
		end
	end;

begin
	initialize(a, b); 
	multiply(a, b, c); 
	display(c) 
end { run };

begin
	writeln('Matrix multiplication:'); 
	writeln('n = ', n:1, ', p = ', p:1); 
	writeln; 
	run 
end.
