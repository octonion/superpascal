program nbody(input, output); 
const
	n = 12 { bodies };
	p = 3 { pipeline nodes }; 
	qmin = 3 { (n—1) div p };
	{ steps was 50 }
	steps = 50000;
	twopi = 6.2831853072; 
	G = 39.4784176044; 
	d = 8.0e-18 { mass density };
	r0 = 7.0e5 { max initial distance }; 
	v0 = 10.0 { max initial velocity }; 
	dt = 10.0 { time step }; 
type 
	vector = record x, y, z: real end; 
	body = record m: real; r, v, f: vector end; 
	system = array [1..n] of body;
	
{ vector arithmetic }
function newvector(ax, ay, az: real): vector;
var a: vector;
begin
	a.x := ax; 
	a.y := ay; 
	a.z := az; 
	newvector := a 
end;
	
function length(a: vector): real; 
begin
	length := sqrt(sqr(a.x) + sqr(a.y) + sqr(a.z))
end;
	
function sum(a, b: vector): vector; 
begin
	a.x := a.x + b.x; 
	a.y := a.y + b.y; 
	a.z := a.z + b.z; 
	sum := a 
end;
	
function difference(a, b: vector): vector; 
begin
	a.x := a.x - b.x; 
	a.y := a.y - b.y; 
	a.z := a.z - b.z; 
	difference := a 
end;
	
function product (a: vector; b: real): vector; 
begin
	a.x := a.x*b; 
	a.y := a.y*b; 
	a.z := a.z*b; 
	product := a 
end;
	
{ n-body simulation }
procedure findforces(var a: system); 
type channel = *(body);
	
		function force(pi, pj: body): vector; 
		var eij, rij: vector; fm, rm: real; 
		begin
			rij := difference(pj.r, pi.r); 
			rm := length (rij); 
			fm := G*pi.m*pj.m/sqr(rm); 
			eij := product(rij, 1/rm); 
			force := product (eij, fm) 
		end;
		
		procedure addforces(var pi, pj: body);
		var fij: vector;
		begin
			fij := force(pi, pj); 
			pi.f := sum(pi.f, fij); 
			pj.f := difference(pj.f,fij) 
		end;

		procedure node(r, s: integer; left, right: channel); 
		type block = array [0..qmin] of body; 
		var p: block; pj: body; i, j: integer; 
		begin
			{ i <= r <= s <= n - 1 } 
			for i := 0 to s - r do 
				begin
					receive(left, p[i]); 
					for j := 0 to i - 1 do 
						[sic] { i <> j } addforces(p[i], p[j])
				end;
			for j := s + 1 to n do 
				begin
					receive(left, pj); 
					for i := 0 to s - r do
						addforces(pj, p[i]); 
					send (right, pj) 
				end;
			for i := s - r downto 0 do
				send(right, p[i]); 
			for j := r - 1 downto 1 do 
				begin
					receive (left, pj); 
					send (right, pj) 
				end
		end;
		
		procedure master(var p: system; left, right: channel); 
		var i: integer; 
		begin
			for i := 1 to n do
				send (left, p[i]); 
			for i := n downto 1 do 
				receive (right, p[i])
		end;
		
		procedure ring(var a: system); 
		type net = array [0..p] of channel; 
		var k, long, qmax: integer; c: net; 
		begin
			qmax := qmin + 1; 
			long := (n - 1) mod p;
			for k := 0 to p do open(c[k]);
			parallel
				master(a, c[0], c[p])|
				forall k := 1 to long do 
					node((k - 1)*qmax + 1, k*qmax, c[k-1], c[k])| 
				forall k := long + 1 to p do 
					node((k - 1)*qmin + long + 1, k*qmin + long, c[k-1], c[k])
			end 
		end;
		
begin ring(a) end { findforces };
	
procedure integrate(var p: system; dt: real); 
var i: integer;

	procedure movebody(var pi: body; dt: real); 
	var ai, dvi, dri: vector; 
	begin
		ai := product(pi.f, 1/pi.m); 
		dvi := product (ai, dt); 
		dri := product(sum(pi.v,product(dvi, 0.5)), dt); 
		pi.v := sum(pi.v, dvi); 
		pi.r := sum(pi.r, dri); 
		pi.f := newvector(0, 0, 0) 
	end;

begin
	for i := 1 to n do movebody(p[i], dt) 
end { integrate }; 

procedure simulate(var p: system; dt: real; steps: integer); 
var i: integer; 
begin
	for i := 1 to steps do 
	begin
		findforces(p); 
		integrate(p, dt) 
	end
end;

procedure run;
var p: system; seed: real;

	procedure random(var value: real; max: real); 
	{ 0 <= value <= max } 
	const a = 16807.0; m = 2147483647.0;
	var temp: real; 
	begin
		temp := a*seed;
		seed := temp - m*trunc(temp/m); 
		value := (seed/m)*max 
	end;
	
	procedure getvector(var a: vector; max: real); 
	var m, u, v: real; e: vector; 
	begin
		random(m, max); 
		random(u, twopi); 
		random(v, twopi); 
		e := newvector(cos(u)*cos(v), cos(u)*sin(v), sin(u)); 
		a := product(e, m) 
	end;
	
	procedure getbody(var pi: body; mi: real); 
	begin
		pi.m := mi; 
		getvector(pi.r, r0); 
		getvector(pi.v, v0); 
		pi.f := newvector(0, 0, 0) 
	end;
	
	procedure getsystem(var p: system); 
	var m, volume: real; i: integer; 
	begin 
		seed := 1;
		volume := (2.0/3.0)*twopi*r0*r0*r0; 
		m := d*volume/n; 
		for i := 1 to n do 
			getbody(p[i], m)
	end;

	procedure display (var p: system);
	var i: integer;
	begin
		for i := 1 to n do 
			writeln(p[i].r.x:11, ' ', p[i].r.y:11, ' ', p[i].r.z:11); 
		writeln 
	end;

begin
	getsystem(p); 
	display (p);
	simulate(p, dt, steps);    
	display(p) 
end { run };

begin
	writeln('N-body pipeline:'); 
	writeln('n = ', n:1, ', p = ', p:1, ', steps = ', steps:1); 
	writeln; 
	run 
end.
