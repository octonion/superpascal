```bash
fpc -O3 -Miso -Fabaseunix interpret.p
fpc -O3 -Miso compile.p
```
```
./compile
    source = examples/primality.sp
    code = bin/primality

./interpret 
    code = bin/primality
    select files? no

Primality testing:
10 digits, 2 trials, 2 pipeline nodes

1653701519(10)
0 composite votes, 2 prime votes

1653701518(10)
2 composite votes, 0 prime votes

0 s
```
