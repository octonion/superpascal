program householder (input, output);
const    
	n = 50 { equations };
	p = 3 { pipeline nodes };
	qmin = 16 { (n - 1) div p steps/node };
type
	column = array [1..n] of real;
	matrix = array [1..n] of column;

procedure reduce(var a: matrix; var b: column); 

type channel = *(column);

	function product(i: integer; a, b: column): real; { the scalar product of elements i..n of a and b }
	var ab: real; k: integer; 
	begin 
		ab := 0.0; 
		for k := i to n do 
			ab := ab + a[k]*b[k]; 
		product := ab 
	end;

	procedure eliminate(i: integer; var ai, vi: column); 
	var anorm, dii, fi, wii: real; k: integer; 
	begin
		anorm := sqrt(product(i, ai, ai));
		if (ai[i] > 0.0) 
			then dii := -anorm
			else dii := anorm; 
		wii := ai[i] - dii; 
		fi := sqrt(-2.0*wii*dii); 
		vi[i] := wii/fi; 
		ai[i] := dii;
		for k := i + 1 to n do 
		begin
			vi[k] := ai[k]/fi; 
			ai[k] := 0.0 
		end
	end;

	procedure transform(i: integer; var aj, vi: column);
	var fi: real; k: integer; 
	begin
		fi := 2.0*product(i, vi, aj); 
		for k := i to n do
			aj[k] := aj[k] - fi*vi[k]
	end;

	procedure node(r, s: integer; left, right: channel); 
	type block = array [0..qmin] of column;
	var a, v: block; aj, b: column; i, j: integer; 
	begin
		{ 1 <= r <= s <= n - 1 } 
		receive(left, b); 
		for i := 0 to s - r do 
			begin
				receive(left, a[i]); 
				for j := 0 to i - 1 do
					transform(j + r, a[i], v[j]); 
				eliminate(i + r, a[i], v[i]); 
				transform(i + r, b, v[i]) 
			end; 
		send(right, b); 
		for j := s + 1 to n do 
			begin
				receive (left, aj); 
				for i := 0 to s - r do
					transform(i + r, aj, v[i]); 
				send(right, aj) 
			end;
		for i := s - r downto 0 do
			send(right, a[i]); 
		for j := r - 1 downto 1 do 
			begin
				receive(left, aj); 
				send (right, aj) 
			end
	end;

	procedure master(var a: matrix; var b: column; left, right: channel); 
	var i: integer; 
	begin
		send(left, b); 
		for i := 1 to n do 
			send(left, a[i]);
		receive (right, b);
		for i := n downto 1 do
			receive (right, a[i])
	end;

	procedure ring(var a: matrix; var b: column); 
	type net = array [0..p] of channel; 
	var k, long, qmax: integer; c: net; 
	begin
		qmax := qmin + 1; 
		long := (n - 1) mod p; 
		for k := 0 to p do open(c[k]); 
		parallel
			master(a, b, c[0], c[p])| 
				forall k := 1 to long do
					node((k - 1)*qmax + 1, k*qmax, c[k-1], c[k])|
				forall k := long + 1 to p do 
					node((k - 1)*qmin + long + 1, k*qmin + long, c[k-1], c[k])
		end 
	end;

begin ring(a, b) end { reduce };

procedure substitute(var a: matrix; var b, x: column); 
var i, j: integer; 
begin
	for i := n downto 1 do 
	begin
		x[i] := b[i]/a[i,i]; 
		for j := i - 1 downto 1 do 
			b[j] := b[j] - a[i,j]*x[i]
	end 
end;
	
procedure run;
var a: matrix; b, x: column;
	
	procedure initialize(var a: matrix; var b: column); 
	var i, j, s: integer; 
	begin
		s := (n + 1)*(n + 2) div 2; 
		for i := 1 to n do 
		begin
			for j := 1 to n - i do
				a[i,j] := 1.0; 
			a[i,n-i+1] := 2.0; 
			for j := n - i + 2 to n do
				a[i,j] := 1.0; 
			b[i] := s - i 
		end
	end;

	procedure display(x: column); 
	const m = 10 { items/line };
	var i, j, k: integer; 
	begin
		k := n div m; 
		for i := 0 to k - 1 do 
		begin
			for j := 1 to m do
			write(x[i*m+j]:6:1); 
			writeln 
		end;
		for j := 1 to n mod m do
			write(x[k*m+j]:6:1); 
		writeln 
	end;

begin
	initialize (a, b); 
	reduce(a, b); 
	substitute(a, b, x); 
	display (x) 
end;

begin
	writeln('Householder pipeline:',' n = ', n:1, ', p = ', p:1); 
	writeln; 
	run 
end.


