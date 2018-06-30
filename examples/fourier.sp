program fourier(input, output); 
const
	d = 2 { tree depth: log(p+l)-l }; 
	p = 7 { tree nodes: 2**(d+l)-l }; 
	n = 128 { items: 2power>=2**d }; 
type
	complex = record re, im: real end; 
	table = array [1..n] of complex;

	{ complex arithmetic }
	function pair (re, im: real): complex;
	var a: complex;
	begin
		a.re := re; 
		a.im := im; 
		pair := a 
	end; 
	
	function sum(a, b: complex): complex; 
	begin
		a.re := a.re + b.re; 
		a.im := a.im + b.im; 
		sum := a 
	end;
	
	function difference(a, b: complex): complex; 
	begin
		a.re := a.re - b.re; 
		a.im := a.im - b.im; 
		difference := a 
	end;
	
	function product (a, b: complex): complex;
	var c: complex;
	begin
		c.re := a.re*b.re - a.im*b.im; 
		c.im := a.re*b.im + a.im*b.re; 
		product := c 
	end;

	{ discrete fourier transform }
	procedure dft(var a: table); 
	type channel = *(complex, integer); 
	var bottom: channel;
	
		procedure permute(var a: table); 
		type map = array [1..n] of integer; 
		var rev: map; half, incr, size, j, k: integer; aj: complex; 
		begin
			rev[1] := 1; 
			half := n div 2; 
			size := 1;
			while size <= half do
			begin
				incr := half div size; 
				for j := 1 to size do
					rev[j + size] := rev[j] + incr; 
				size := 2*size 
			end;
			for j := 1 to n do 
			begin
				k := rev[j]; 
				if j < k then 
				begin
					aj := a[j]; 
					a[j] := a[k]; 
					a[k] := aj 
				end
			end
		end;
		
		procedure combine(var a: table; first, last: integer); 
		const pi = 3.1415926536; 
		var even, half, odd, j: integer; w, wj, x: complex; 
		begin
			half := (last - first + 1) div 2;
			w := pair(cos(pi/half), sin(pi/half));
			wj := pair(1, 0);
			for j := 0 to half - 1 do 
			begin
				even := first + j; 
				odd := even + half; 
				x := product (wj, a[odd]); 
				a[odd] := difference(a[even], x); 
				a[even] := sum (a[even], x); 
				wj := product (wj, w) 
			end
		end;
		
		procedure fft(var a: table; first, last: integer); 
		var size, k, m: integer; 
		begin
			m := last - first + 1; 
			size := 2;
			while size <= m do 
			begin
				k := first + size - 1; 
				while k <= last do 
				begin
					combine(a, k - size + 1, k); 
					k := k + size 
				end; 
				size := 2*size 
			end
		end;
		
		procedure leaf(bottom: channel); 
		var a: table; first, last, i: integer; 
		begin
			receive(bottom, first, last); 
			for i := first to last do 
				receive(bottom, a[i]); 
			fft(a, first, last); 
			for i := first to last do 
				send(bottom, a[i])
		end;
		
		procedure root(bottom, left, right: channel); 
		var a: table; first, last, middle, middle2, i: integer; 
		begin
			receive(bottom, first, last); 
			for i := first to last do 
				receive(bottom, a[i]); 
			middle := (first + last) div 2; 
			send (left, first, middle); 
			for i := first to middle do
				send(left, a[i]); 
			middle2 := middle + 1; 
			send(right, middle2, last); 
			for i := middle2 to last do
				send (right, a[i]); 
			for i := first to middle do
				receive (left, a[i]); 
			for i := middle2 to last do
				receive (right, a[i]); 
			combine(a, first, last); 
			for i := first to last do 
				send(bottom, a[i])
		end;
		
		procedure tree(depth: integer; bottom: channel); 
		var left, right: channel; 
		begin
			if depth > 0 then 
			begin
				open (left, right); 
				parallel
					tree(depth - 1, left)|
					tree(depth - 1, right)| 
					root(bottom, left, right) 
				end 
			end
			else 
				leaf(bottom) 
		end;
		
		procedure master(var a: table; bottom: channel); 
		var i: integer; 
		begin 
			send(bottom, 1, n); 
			for i := 1 to n do
				send(bottom, a[i]); 
			for i := 1 to n do
				receive(bottom, a[i])
		end;
	
	begin
		permute(a);
		open(bottom);
		parallel
			tree(d, bottom)| 
			master(a, bottom) 
		end 
	end { dft};

	procedure run; 
	var a: table; seed: real;
	
		procedure random(var value: real);
		{ 0 <= value <= 1 }
		const a = 16807.0; m = 2147483647.0;
		var temp: real;
		begin
			temp := a*seed;
			seed := temp - m*trunc(temp/m); 
			value := seed/m 
		end;
		
		procedure initialize (var a: table);
		var i: integer; re: real;
		begin
			seed := 1.0; 
			for i := 1 to n do 
			begin
				random(re); 
				a[i] := pair(re, 0) 
			end
		end;
		
		procedure display(a: table); 
		const m = 4 { items/line }; 
		var i, j, k: integer; aij: complex; 
		begin
			k := n div m; 
			for i := 0 to k - 1 do 
			begin
				for j := 1 to m do 
				begin
					aij :=a[i*m + j]; 
					write(aij.re:8, ' ', aij.im:8, ', ')
				end;
				writeln 
			end; 
			writeln 
		end;
	
	begin
		initialize(a); 
		dft(a); 
		display(a) 
	end { run };
begin
	writeln('FFT tree:', ' n = ', n:1, ', p = ', p:1);
	writeln; 
	run 
end.
