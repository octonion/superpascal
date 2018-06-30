program sorting(input, output); 
const
	d = 2 { tree depth: log(p+l)-l }; 
	p = 7 { tree nodes: 2**(d+l)-1 }; 
	n = 500 { items: >=2**d }; 
type table = array [1..n] of integer;

procedure sort(var a: table); 
type channel = *(integer); 
var bottom: channel;
		
	procedure partition(var a: table; var i, j: integer; first, last: integer); 
	var ai, key: integer; 
	begin 
		i := first; 
		j := last; 
		key := a[(i+j) div 2];
		while i <= j do 
		begin
			while a[i] < key do 
				i := i + 1;
			while key < a[j] do 
				j := j - 1;
			if i <= j then 
			begin
				ai := a[i]; 
				a[i] := a[j]; 
				a[j]:=ai; 
				i := i + 1; 
				j := j - 1 
			end
		end
	end;
		
	procedure find(var a: table; first, last, middle: integer); 
	var left, right, i, j: integer; 
	begin
		left := first; 
		right := last; 
		while left < right do 
		begin
			partition(a, i, j, left, right); 
			if middle <= j then 
				right := j 
			else if i <= middle then 
				left := i 
			else 
				left := right 
			end
	end;
		
	procedure quicksort(var a: table; first, last: integer); 
	var i, j: integer; 
	begin
		if first < last then 
		begin
			partition(a, i, j, first, last); 
			quicksort(a, first, j);
			quicksort(a, i, last) 
		end
	end;
		
	procedure leaf(bottom: channel); 
	var a: table; first, last, i: integer; 
	begin
		receive(bottom, first, last); 
		for i := first to last do 
			receive(bottom, a[i]); 
		quicksort (a, first, last); 
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
			find(a, first, last, middle); 
			send(left, first, middle); 
			for i := first to middle do
				send(left, a[i]); 
			middle2 := middle + 1; 
			send(right, middle2, last); 
			for i := middle2 to last do
				send(right, a[i]); 
			for i := first to middle do
				receive(left, a[i]); 
			for i := middle2 to last do
				receive(right, a[i]); 
			for i := first to last do 
				send(bottom, a[i])
		end;
		
		procedure tree(depth: integer; bottom: channel); 
		var left, right: channel; 
		begin
			if depth > 0 then 
			begin
				open(left, right); 
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
		open(bottom); 
		parallel
			tree(d, bottom)| 
			master(a, bottom) 
		end 
	end { sort }; 
	
procedure run; 
var a: table; seed: real;

	procedure random(var value: integer); 
	{ 0 <= value <= max-1 } 
	const max = 10000; a = 16807.0;
	m = 2147483647.0; 
	var temp: real; 
	begin
		temp := a*seed;
		seed := temp - m*trunc(temp/m); 
		value := trunc((seed/m)*max) 
	end;
	
	procedure initialize (var a: table);
	var i: integer;
	begin
		seed := 1.0;
		for i := 1 to n do 
			random(a[i])
	end;

	procedure display(a: table); 
	const m = 11 { items/line }; 
	var i, j, k: integer; 
	begin
		k := n div m; 
		for i := 0 to k - 1 do 
		begin
			for j := 1 to m do 
				write(a[i*m+j]:5); 
			writeln 
		end;
		for j := 1 to n mod m do
			write(a[k*m+j]:5); 
		writeln 
	end; 

	begin
		initialize(a); 
		sort(a); 
		display(a) 
	end { run };

begin
	writeln('Quicksort tree:',' n = ', n:1, ', p = ', p:1); 
	writeln; 
	run 
end.
