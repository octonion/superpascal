# Super Pascal compiler and interpreter

A maintained Free Pascal build of **Per Brinch Hansen's 1993 Super Pascal**
compiler and bytecode interpreter. Super Pascal is an educational Pascal
extension for parallel programming with processes, channels, and communication.
The original source and its period documentation are retained, including
`software.shar`, `report.tex`, `readthis.tex`, `notes.tex`, and `user.tex`.

This repository contains a Free Pascal compatibility port; the interpreter
executes **Super Pascal bytecode**, not native machine code. Source examples are
in [`examples/`](examples/) and historical, precompiled bytecode is in
[`bin/`](bin/). The original Super Pascal example programs use the historical
language, not modern Free Pascal syntax.

## Requirements

- Free Pascal Compiler **3.2.2** (tested on Ubuntu 24.04 and 26.04, x86-64).
- GNU Make and the Linux C development toolchain for the provided build commands.
- Python 3 (standard library only) to run tests.

On Ubuntu/Kubuntu:

```sh
sudo apt update
sudo apt install fp-compiler make python3 build-essential
```

The `fpc` package also works; `fp-compiler` suffices for this repository.

## Build

```sh
make
```

This generates `build/compile` and `build/interpret` and keeps generated
objects outside the source tree. A direct build is also supported (64-bit Linux):

```sh
fpc -O3 -Miso compile.p
fpc -O3 -Miso interpret.p
```

The Makefile uses ISO Pascal compatibility mode (`-Miso`) and optimization
(`-O3`). To override these flags, use for example
`make FPCFLAGS='-O2 -Miso -gl -Cr -Co'`.

## Run an example

The historical tools are interactive and ask for filenames. From the repository
root:

```sh
printf 'examples/primality.sp\nbuild/primality\n' | ./build/compile
printf 'build/primality\nno\n' | ./build/interpret
```

Expected output includes:

```text
1653701519(10)
0 composite votes, 2 prime votes

1653701518(10)
2 composite votes, 0 prime votes
```

The last line reports elapsed *wall-clock* time in seconds to three decimal
places. On 64-bit Linux, the interpreter uses `clock_gettime(CLOCK_MONOTONIC)`
with nanosecond timestamps, instead of the old Unix epoch-seconds routine.

**Note:** the historical implementation limits filenames entered in its prompts
to 30 characters. Use short relative paths from the repository root.

## Run tests

```sh
make test
```

Tests compile all **11** supplied example programs and run assertions for:

- Primality: both known inputs and prime/composite vote counts.
- Parallel pipeline: expected output of 100.
- Recursion/array passing: the [original `outcomes.sp` program](tests/outcomes.sp)
  from [`octonion/recursion`](https://github.com/octonion/recursion/tree/master/superpascal).
  All ten dealer-upcard values and the total of **6,398,430** partitions are
  checked against the previously recorded output.
- Interpreter timing: an elapsed-seconds line with millisecond precision,
  consistent with the enclosing test's monotonic timer.
- Nested scope analysis: a valid nested procedure call is accepted, while
  forbidden recursive calls with implicit dependencies are rejected.

`make test-full` additionally **runs** all other supplied examples, including
the expensive 50,000-step `nbody` example. The default test target deliberately
keeps the continuous integration test short.

The tests run on Ubuntu 24.04 and Ubuntu 26.04 using GitHub Actions. They do
not overwrite the historical bytecode checked into `bin/`.

Remove generated executables, objects, test bytecode, and the historical
`errors` log with `make clean`.

## Source layout

| Path | Purpose |
| --- | --- |
| `compile.p` | Super Pascal compiler driver |
| `scan.p` | Scanner/lexer, included by `compile.p` |
| `parse.p` | Parser and semantic checks |
| `assemble.p` | Bytecode assembly and optimization |
| `common.p` | Shared constants and VM representations |
| `interpret.p` | Stack-based bytecode interpreter |
| `examples/` | 11 historical example programs |
| `bin/` | Historical compiled bytecode |
| `tests/` | Test harness and recursive partition benchmark |

## Port notes and limitations

The project retains the original compiler architecture and much of the 1993
code. The port updates source-file handling and host Pascal compatibility.
The VM is deliberately bounded by static table sizes in `common.p`, including
its stack and bytecode storage; these are not arbitrary-size programs.

The compiler's `testoptions = false` constant intentionally excludes
interactive tracing/test-output options. Free Pascal may report one *unreachable
code* warning for the corresponding disabled branch. Other warnings are
investigated in the source rather than suppressed wholesale.

The original bytecode format and runtime are historical. These smoke tests
provide evidence for a subset of behavior; they are not a complete correctness
proof, nor a security audit of bytecode loaded from untrusted sources.

## Provenance and license

Original Super Pascal compiler/interpreter by **Per Brinch Hansen**, 1993.
The Free Pascal compatibility changes and repository organization are maintained
here. See [LICENSE](LICENSE) for the repository's MIT licensing terms and
retain the original attribution in the source.
