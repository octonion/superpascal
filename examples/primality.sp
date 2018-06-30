program primality(input, output); 
const
	b = 10 { even radix };
	b1 = 9 { maxdigit b - 1 };
	n = 10 { radix test digits };
	w = 20 { max radix digits 2n }; 
	m = 2 { trials, m mod p = 0 };
	p = 2 { pipeline nodes };
type
	number = array [0..w] of integer; 
	table = array [1..m] of boolean;

function value(x: integer): number; 
var y: number; i: integer;
begin
	for i := 0 to w do
	begin
		y[i] := x mod b;
		x:= x div b
	end;
	value := y
end;

function length(x: number): integer; 
var i, j: integer;
begin
	i := w; j := 0;
	while i <> j do
		if x[i] <> 0 then j := i
		else i := i - 1; 
	length := i + 1
end;

procedure writeno(x: number); 
{ 1 <= length(x) <= w+1 } 
var i, m: integer;
begin
	m := length(x);
	for i := m - 1 downto 0 do
		write(chr(x[i] + ord('0'))); writeln('(', m:1, ')')
end;

procedure solve(p: number; var sure: boolean; trial: integer); 
{ 1 <= trial <= m }
var seed: real; x: number;

	function maxlong: number; 
	var x: number; i: integer;
	begin
		for i := 0 to w - 1 do
			x[i] := b1;
		x[w] := 0;
		maxlong := x
    	end;

	function min(x, y: integer): integer;
	begin
		if x <= y then min := x
		else min := y
	end;

	function less(x, y: number): boolean;
	var i, j: integer;
	begin
		i := w; j := 0; 
		while i <> j do
			if x[i] <> y[i] then j := i
			else i := i - 1;
		less := x[i] < y[i]
	end;

	function equal(x, y: number): boolean;
	var i, j: integer;
	begin
		i := w; j := 0; 
		while i <> j do
			if x[i] <> y[i] then j := i
			else i := i - 1;
		equal := x[i] = y[i]
	end;

	function greater(x, y: number): boolean;
	var i, j: integer;
	begin
		i := w; j := 0; 
		while i <> j do
			if x[i] <> y[i] then j := i
			else i := i - 1;
		greater :=  x[i] > y[i]
	end;

	function odd(x: number): boolean; 
	{ even radix b }
	begin
		odd := x[0] mod 2 = 1
	end;

	function product(x: number; k: integer): number;
	var carry, i, m, temp: integer;
	begin
		m := length(x); carry := 0; 
		for i := 0 to m - 1 do 
		begin
			temp := x[i]*k + carry; x[i] := temp mod b; 
			carry := temp div b
		end;
		if m <= w then x[m] := carry else assume carry = 0; 
		product := x
	end;

	function quotient(x: number; k: integer): number;
	var carry, i, m, temp: integer;
	begin	
		m := length(x); carry := 0;
		for i := m - 1 downto 0 do
		begin	
			temp := carry*b + x[i];
			x[i] := temp div k;
			carry := temp mod k
		end;	
		quotient := x
	end;	

	function remainder(x: number; k: integer): number;
	var carry, i, m: integer;
	begin
		m := length(x); carry := 0;
		for i := m - 1 downto 0 do
			carry := (carry*b + x[i]) mod k; remainder := value(carry)
	end;

	function increment(x: number): number; var i: integer;
	begin
		assume less(x, maxlong);
		i := 0;
		while x[i] = b1 do
		begin
			x[i] := 0; 
			i := i + 1 
		end;
		x[i] := x[i] + 1;
		increment := x
	end;

	function decrement(x: number): number; var i: integer;
	begin
		assume greater(x, value(0)); 
		i := 0;
		while x[i] = 0 do
		begin
			x[i] := b1;
			i := i + 1
		end;
		x[i] := x[i] - 1;
		decrement := x 
	end;

	function half(x: number): number; 
	begin
		half := quotient(x, 2)
	end;

	function multiply(x, y: number) : number;
	var z: number; carry, i, j, n, m, temp, yi: integer; 
	begin
		n := length(x);
		m := length(y);
		assume n + m <= w; 
		z := value(0);
		for i := 0 to m - 1 do 
		begin
			yi := y[i];
			carry := 0;
			for j := 0 to n - 1 do 
			begin
				temp := x[j]*yi + z[i+j] + carry;
				z[i+j] := temp mod b; 
				carry := temp div b
			end;
			z[i+n] := carry
		end;
		multiply := z
	end;

	function trialdigit(r, d: number; k, m: integer): integer;
	{ trialdigit(r,d,k,m) = min( r[k+m..k+m–2]  div d[m–1..m–2], b - 1) }
	var d2, km, r3: integer;
	begin
		{ 2 <= m <= k+m <= w }
		km := k + m;
		r3 := (r[km]*b + r[km-1])*b + r[km-2]; 
		d2 := d[m-1]*b + d[m-2];
		trialdigit := min(r3 div d2, b - 1)
	end;

	function smaller(r, dq: number; k, m: integer): boolean 
	{ r[k+m..k] < dq[m..0] }; 
	var i, j: integer;
	begin
		{ 0 <= k <= k+m <= w } 
		i := m; j := 0;
		while i <> j do
			if r[i+k] <> dq[i] then j := i
			else i := i - 1;
		smaller := r[i+k] < dq[i]
	end;

	function difference(r, dq: number; k, m: integer): number; 
	{ r[k+m..k] := r[k+m..k] - dq[m..0]; difference := r }
	var borrow, diff, i: integer;
	begin
		{ 0 <= k <= k+m <= w } 
		borrow := 0;
		for i := 0 to m do
		begin
			diff := r[i+k] - dq[i] - borrow + b;
			r[i+k] := diff mod b; 
			borrow := 1 - diff div b
		end;
		assume borrow = 0;
		difference := r
	end;

	function longmod(x, y: number; n, m: integer): number;
	{ longmod = x mod y }
	var d, dq, r: number; f, k, qt: integer;
	begin
		{ 2 <= m <= n <= w }
		f := b div (y[m-1] + 1);
		r := product(x, f);
		d := product(y, f);
		for k := n - m downto 0 do
		begin 
			{2<=m<=k+m<=n<w} 
			qt := trialdigit(r, d, k, m);
			dq := product(d, qt);
			if smaller(r, dq, k, m) then
			begin
				qt := qt - 1;
				dq := product(d, qt) 
			end;
			r := difference(r, dq, k, m) 
		end;
		longmod := quotient(r, f)
	end;

	function modulo(x, y: number): number; 
	var m, n, y1: integer; r: number;
	begin
		m := length(y);
		if m = 1 then
		begin
			y1 := y[m-1];
			assume y1 > 0;
			r := remainder(x, y1) 
		end
		else
		begin
			n := length(x);
			if m > n then r := x 
			else {2<=m<=n<=w}
			r := longmod(x, y, n, m)
		end;
		modulo := r
	end;

	function square(x: number): number;
	begin
		assume 2*length(x) <= w;
		square := multiply(x, x)
	end;

	procedure random(var no: real); 
	{ 0 <= no <= 1 }
	const a = 16807.0; m = 2147483647.0; 
	var temp: real;
	begin
		temp := a*seed;
		seed := temp - m*trunc(temp/m); 
		no := seed/m
	end;

	procedure randomno(var no: number; max: number);
	{ 1 <= no <= max }
	var x: number; i, m: integer; f: real;
	begin
		x := value(0); 
		m := length(max);
		for i := 0 to m - 1 do
		begin
			random(f);
			x[i] := trunc(f*b1)
		end;
		no := increment (modulo (x, max))
	end;

	function witness(x, p: number): boolean; 
	var e, m, one, p1, r, y, zero: number;   sure: boolean;
	begin
		{ 1 <= x <= p - 1}
		zero := value(0);
		one := value(1);
		m := one; y := x;
		e := decrement(p);
		p1 := e; sure := false;
		while not sure and greater(e, zero) do 
			if odd(e) then
			begin
				m := modulo(multiply(m, y), p); 
				e := decrement(e)
			end
			else
			begin
				r := y;
				y := modulo(square(y),  p);
				e := half(e); 
				if equal(y, one) then
					sure := less(one, r) and less(r, p1)
			end;
		witness := sure or not equal(m, one)
	end;

begin
	{ trial > 0 }
	seed := trial;
	randomno(x, decrement(p)); sure := witness(x, p)
end { solve };

procedure compute(a: number; var b: table); type channel = *(boolean, number);

	procedure master(a: number; var b: table; left, right: channel);
	var trial: integer;
	begin
		send(left, a);
		for trial := 1 to m do
			receive(right, b[trial])
	end;

	procedure node(i: integer; left, right: channel);
	{ 1 <= i <= p }
	var a: number; b: boolean; j, k, q, trial: integer;
	begin
		receive(left, a);
		if i < p then 
			send(right, a); 
		q:= m div p;
		for j := 1 to q do
		begin
			trial := (i - 1)*q + j; 
			solve(a, b, trial);
			send(right, b);
			for k := 1 to i - 1 do
			begin
				receive(left, b);
				send(right, b)
			end
		end
	end;

	procedure ring(a: number; var b: table); 
	type net = array [0..p] of channel;
	var c: net; i: integer;
	begin
	for i := 0 to p do open(c[i]);
	parallel
		master(a, b, c[0], c[p])| 
		forall i := 1 to p do
			node(i, c[i-1], c[i])
		end
	end;

begin
	ring(a, b);
end { compute };

procedure run(a: number); var b: table;

	procedure summarize(a: number; var b: table);
	var cn, i, pn: integer;
        begin
		writeln; writeno(a); cn := 0; pn := 0; 
		for i := 1 to m do
			if b[i] then cn := cn + 1
			else pn := pn + 1; 
		writeln(cn:1, ' composite votes, ', pn:1, ' prime votes')
	end;

begin
	compute(a, b); 
	summarize(a, b) 
end { run };

begin
	writeln('Primality testing:'); 
	writeln(n:1, ' digits, ', m:1, ' trials, ', p:1, ' pipeline nodes');
	run(value(1653701519));
	run(value(1653701518))
end.
