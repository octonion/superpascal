program forestfire(input, output); 
const
	n = 20 { n x n interior grid elements, n = q*m };
	q = 2 { q x q processor nodes }; 
	m = 10 { m x m interior subgrid elements, m even };
	m1 = 11 { m+1 };
	steps = n;
	pa = 0.30 { Prob(alive) };
	pb = 0.01 { Prob(burning) }; 

type
	state = (alive, burning, dead);
	row = array [1..n] of state; 
	grid = array [1..n] of row;

procedure fire(var u: grid; u1, u2, u3, u4, u5: state; steps: integer);
type
	subrow = array [0..m1] of state;
	subgrid = array [0..m1] of subrow; 
	channel = *(state);

procedure node(qi, qj, steps: integer; up, down, left, right: channel);
var u: subgrid; k: integer; seed: real;

	procedure copy(no: integer; inp, out: channel);
	var k: integer; uk: state; 
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

	function initial(i, j: integer): state;
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

	procedure random(var no: real);
	{ 0 <= no <= 1 }
	const a = 16807.0; m = 2147483647.0; 
	var temp: real;
	begin
		temp := a*seed;
		seed := temp - m*trunc(temp/m); 
		no := seed/m
	end;

	procedure nextstate(var u: subgrid; i, j: integer);
	{ 1 <= i <= m, 1 <=j <=m} 
	var x: real;
	begin
		case u[i,j] of
			alive:
			if
				(u[i-1,j] = burning) or 
				(u[i+1,j] = burning) or 
				(u[i,j+1] = burning) or 
				(u[i,j-1] = burning)
			then u[i,j]:= burning
			else
				begin
					random(x);
					if x <= pb then
						u[i,j] := burning
				end;
			burning:
				u[i,j] := dead;
			dead:
			begin
				random(x);
				if x <= pa then
					u[i,j] := alive
			end
		end
	end;

	procedure newgrid(qi, qj : integer; var u: subgrid); 
	var i, i0, j, j0: integer;
	begin
		i0 := (qi - 1)*m;
		j0 := (qj - 1)*m;
		for i := 0 to m + 1 do
			for j := 0 to m + 1 do
				u[i,j] :=  initial(i0+i,  j0+j)
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
						while j <= m - k  do  
							begin
								nextstate(u, i, j); 
								j := j + 2
							end
					end
			end
	end;

begin
	seed := 1.0;
	newgrid(qi, qj, u);
	for k := 1 to steps do 
		relax(qi, qj, up, down,left, right, u); 
	output(qi,qj, right, left, u)
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
			node(j, 1, steps, v[j-1,1], v[j,1], h[j-1,q] , h[j,1])|
			forall i := 1 to q do
				forall j := 2 to q do
					node(i, j, steps, v[i-1,j], v[i,j], h[i,j-1], h[i,j])
	end
end;

begin simulate(steps, u) end { fire };

procedure run;
var u: grid;

	procedure display(var u: grid); 
	var i, j: integer;
	begin
		for i := 1 to n do
		begin
			for j := 1 to n do
				case u[i,j] of
				alive: write('+ ');
				burning: write('* '); 
				dead: write(' ')
				end;
			writeln
		end
	end;

	begin
		fire(u, dead, dead, dead, dead, alive, steps); 
		display(u)
	end { run };

	begin
		writeln('Forest fire matrix:', ' n = ', n:1, ', p = ', q*q:1);
		writeln; run 
	end.
