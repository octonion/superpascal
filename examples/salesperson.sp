program salesperson(input, output); 
const 
	s = 4 { s*s square, s even }; 
	n = 16 { s*s cities }; 
	m = 2 { trials, m mod p = 0 }; 
	p = 2 { pipeline nodes }; 
type
	city = record x, y: real end; 
	tour = array [1..n] of city; 
	table = array [1..m] of tour;
	
	function distance(p, q: city): real;
	var dx, dy: real;
	begin
		dx := q.x - p.x;
		dy := q.y - p.y;
		distance := sqrt(dx*dx + dy*dy) 
	end;
	
	procedure solve(a: tour; var b: tour; trial: integer); 
	{ 1 <= trial <= m } 
	var seed: real; index: integer;

		procedure random(var value: real);
		{ 0 <= value <= 1 }
		const a = 16807.0; m = 2147483647.0;
		var temp: real;
		begin
			temp := a*seed;
			seed := temp - m*trunc(temp/m); 
			value := seed/m 
		end;
		
		procedure generate(var i, j: integer); 
		{ 1 <= ij <= n } 
		var x: real; 
		begin
			random(x); 
			i := trunc(x*n) + 1; 
			j := index;
			index := index mod n + 1 
		end;
		
		procedure select (var a: tour; var si, j: integer; var dE: real); 
		var i, sj: integer; 
		begin
			generate(i, j); 
			si := i mod n + 1; 
			sj := j mod n + 1; 
			if i <> j then
				dE := distance(a[i], a[j]) + distance(a[si], a[sj]) - distance(a[i], a[si]) - distance(a[j], a[sj]) 
			else 
				dE := 0.0
		end;
		
		function accept (dE, T: real): boolean; 
		begin 
			accept := dE < T 
		end;
		
		procedure swap(var a: tour; i, j: integer); 
		var ai: city; 
		begin
			ai := a[i]; 
			a[i] := a[j]; 
			a[j] := ai 
		end;
		
		procedure change(var a: tour; i, j: integer); 
		var k, nij: integer; 
		begin
			nij := (j - i + n) mod n + 1; 
			for k := 1 to nij div 2 do 
			swap (a,(i + k - 2) mod n + 1, (j - k + n) mod n + 1)
		end;
		
		procedure search(var a: tour; T: real; attempts, changes: integer); 
		var i, j, na, nc: integer; dE: real; 
		begin
			na := 0; 
			nc := 0; 
			while (na < attempts) and (nc < changes) do 
			begin
				select (a, i, j, dE); 
				if accept(dE, T) then 
				begin
					change(a, i, j); 
					nc := nc + 1 
				end;
				na := na + 1 
			end
		end;
		
		procedure anneal(var a: tour; Tmax, alpha: real; steps, attempts, changes: integer); 
		var T: real; k: integer; 
		begin
			T := Tmax; 
			for k := 1 to steps do 
			begin
				search(a, T, attempts, changes); 
				T := alpha*T 
			end
		end;

		procedure permute(var a: tour; changes: integer); 
		var i, j, k: integer; 
		begin
			for k := 1 to changes do
			begin
				generate(i, j);           
				swap(a, i, j) 
			end
		end;

	begin
		seed := trial; 
		index := trial;
		b := a;
		permute(b, n);
		anneal(b, sqrt(n), 0.95, trunc(20.0*ln(n)), 100*n, 10*n)
	end { solve };

	procedure compute(a: tour; var b: table); 
	type channel = *(tour);

		procedure master(a: tour; var b: table; left, right: channel);
		var trial: integer;
		begin
			send(left, a);
			for trial := 1 to m do
			receive(right, b[trial])
		end;

		procedure node(i: integer; left, right: channel);
		{ 1 <= i <= p }
		var a, b: tour; j, k, q, trial: integer; 
		begin
			receive(left, a);
			if i < p then 
			send(right, a);  
			q := m div p;
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

procedure ring(a: tour; var b: table); 
type net = array [0..p] of channel;
var c: net; i: integer;
begin
	for i := 0 to p do 
		open(c[i]); 
	parallel
		master(a, b, c[0], c [p])|
		forall i := 1 to p do 
			node(i, c[i-1], c[i])
	end
end;

begin ring(a, b) end { compute };

procedure run;
	var a: tour; b: table;

	procedure initialize(var a: tour); 
	{ grid of s*s cities }
	var i, j, k: integer;
	begin
		for i := 1 to s do
			for j := 1 to s do
			begin
				k := (i - 1)*s + j; 
				a[k].x := i;
				a[k].y := j
			end
	end;

	function length(a: tour): real; 
	var i: integer; sum: real;
	begin
		sum := distance(a[n], a[1]); 
		for i := 1 to n - 1 do
		sum := sum + distance(a[i], a[i+1]);
		length := sum
	end;

	function shortest(b: table): tour;
	var Ek, Emin: real;
	k, min: integer; 
	begin
		min := 1;
		Emin := length(b[min]);
		for k := 2 to m do 
		begin
			Ek := length(b[k]);
			if Emin > Ek then
			begin
				min := k; 
				Emin := Ek 
			end
		end;
		shortest := b[min] 
	end;

	procedure summarize(var b: table); 
	var a: tour; i: integer;
	begin
		a := shortest(b);
		for i := 1 to n do
			writeln(a[i].x:11, ' ', a[i].y:11);
		writeln(length(a))
	end;

begin
	initialize(a);
	compute(a, b); 
	summarize(b)
end { run };

begin
	writeln('Traveling salesperson: ', n:1, ' cities, ', m:1, ' trials, ', p:1, ' pipeline nodes');
	writeln; 
	run
end.
