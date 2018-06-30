program heatequation(input, output); 
const
	n = 20 { n x n interior grid elements, n = q*m };
	q = 2 { q x q processor nodes };
	m = 10 { m x m interior subgrid elements, m even };
	m1 = 11 { m+1 };
	steps = n;
type
	row = array [1..n] of real;
	grid = array [1..n] of row;

procedure laplace(var u: grid; u1, u2, u3, u4, u5: real; steps: integer);
type
	subrow = array [0..m1] of real;
	subgrid = array [0..m1] of subrow;
	channel = *(real);

procedure node(qi, qj, steps: integer; up, down, left, right: channel);
const pi = 3.14159265358979;
var u: subgrid; k: integer; fopt: real;

	procedure copy(no: integer; inp, out: channel);
	var k: integer; uk: real; 
	begin
		for k := 1 to no do 
		begin
			receive(inp, uk); 
			send(out, uk)
		end
	end;

	procedure output(qi, qj: integer; inp, out: channel; var u: subgrid); 
	var i, j: integer;
	begin
		for i := 1 to m do
			begin
			for j := 1 to m do
				send(out, u[i,j]);
			copy((q - qj)*m, inp, out) 
			end;
		copy((q - qi)*m*n, inp, out) 
	end;

	procedure phase1(qi, qj, b: integer; up, down, left, right: channel; var u: subgrid);
	var k, last: integer;
	begin
		k := 2 - b;
		last := m - b;
		while k <= last do 
			begin
				{ 1 <= k <= m }
				[sic] parallel
				if qi > 1 then
					receive(up, u[0,k])|
				if qi < q then 
					send(down, u[m,k])|
				if qj > 1 then
					receive(left, u[k,0])|
				if qj < q then
					send(right, u[k,m])
			end;
			k := k + 2
		end
	end;

	procedure phase2(qi, qj, b: integer; up, down, left, right: channel; var u: subgrid);
	var k, last: integer;
	begin
		k := b + 1;
		last := m + b - 1; 
		while k <= last do 
			begin
			{ 1 <= k <= m } 
			[sic] parallel
			if qi > 1 then
				send(up, u[1,k])|
			if qi < q then
				receive(down, u[m+1,k])|
			 if qj > 1 then
				send(left, u[k,1])|
			if qj < q then 
				receive(right, u[k,m+1]) 
			end;
			k := k + 2
		end
	end;

	procedure exchange(qi, qj, b: integer; up, down, left, right: channel; var u: subgrid);
	begin
		phase1(qi, qj, b, up, down, left, right, u);
		phase2(qi, qj, b, up, down, left, right, u)
	end;

	function initial(i, j: integer): real; 
	begin
		if i = 0 then 
			initial := u1
		else if i = n + 1 then
			initial := u2
		else if j = n + 1 then
			initial := u3
		else if j = 0 then
			initial := u4 
		else
			initial := u5
	end;

	procedure nextstate(var u: subgrid; i, j: integer);
	{ 1 <= i <= m, 1 <= j <= m} 
	var res: real;
	begin
		res := (u[i-1,j] + u[i+1,j] + u[i,j+1] + u[i,j-1])/4.0 - u[i,j];
		u[i,j] := u[i,j] + fopt*res
	end;

	procedure newgrid(qi, qj: integer; var u: subgrid);
	var i, i0, j, j0: integer;
	begin
		i0 := (qi - 1)*m;
		j0 := (qj - 1)*m;
		for i := 0 to m + 1 do
			for j:= 0 to m + 1 do
				u[i,j] := initial(i0+i, j0+j)
	end;

	procedure relax(qi, qj: integer; up, down, left, right: channel; var u: subgrid);
	var b, i, j, k: integer;
	begin
		for b := 0 to 1 do
			begin
				exchange(qi, qj, 1 - b, up, down, left, right, u); 
				for i := 1 to m do
					begin
						k := (i + b) mod 2; 
						j := 2 - k;
						while j <= m - k do 
							begin
								nextstate(u, i, j); 
								j := j + 2
							end
					end
			end
	end;

begin
	fopt := 2.0 - 2.0*pi/n; 
	newgrid(qi, qj, u);
	for k := 1 to steps do
		relax(qi, qj, up, down, left, right, u); 
	output(qi, qj, right, left, u)
end { node };

procedure master(right: channel; var u: grid);
var i, j: integer;
begin
	for i := 1 to n do
		for j := 1 to n do 
			receive(right, u[i,j])
end;

procedure simulate(steps: integer; var u: grid); 
type
	line = array [1..q] of channel;
	matrix = array [0..q] of line;
var h, v: matrix; i, j: integer; 
begin
	open(h[0,q]);
	for i := 1 to q do
		for j := 1 to q do 
			open(h[i,j]);
	for i := 0 to q do 
		for j := 1 to q do 
			open(v[i,j]);
	parallel
		master(h[0,q], u)|
		forall j := 1 to q do
			node(j, 1, steps, v[j-1,1], v[j,1], h[j-1,q], h[j,1])|
		forall i := 1 to q do
			forall j := 2 to q do
				node(i, j, steps, v[i-1,j], v[i,j], h[i,j-1], h[i,j])
	end
end;
 
begin simulate(steps, u) end { laplace }; 

procedure run;
var u: grid;

	procedure display(var u: grid);
	var i, j: integer;
	begin
		for i := 1 to n do
		begin
			for j := 1 to n do
				write(round(u[i,j]):2, ' ');
			writeln
		end
	end;

begin
	laplace(u, 0.0, 100.0, 100.0, 0.0, 50.0, steps);
	display(u)
end{run};

begin
	writeln('Laplace matrix:',  ' n  =  ', n:1, ', p = ',q*q:1);
	writeln; run 
end.
