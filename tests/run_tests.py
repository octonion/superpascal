#!/usr/bin/env python3
"""Compile all examples and exercise the Super Pascal bytecode interpreter.

Uses only the Python standard library. Invoke from anywhere via make test.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
COMPILER = BUILD / "compile"
INTERPRETER = BUILD / "interpret"

EXPECTED_OUTCOMES = [
    417334, 560954, 658854, 679464, 680299,
    680305, 680305, 680305, 680305, 680305,
]


def execute(args: list[str], input_text: str, timeout: int) -> tuple[str, float]:
    started = time.monotonic()
    try:
        result = subprocess.run(
            args, input=input_text, text=True, capture_output=True,
            cwd=ROOT, timeout=timeout, check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise AssertionError(f"{args[0]} timed out after {timeout}s") from exc
    elapsed = time.monotonic() - started
    if result.returncode != 0:
        raise AssertionError(
            f"Command {args} failed ({result.returncode})\n"
            f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
        )
    return result.stdout, elapsed


def compile_source(source: Path) -> Path:
    relative = source.relative_to(ROOT).as_posix()
    output = BUILD / "programs" / source.stem
    output.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)

    # Historical compiler prompts for two filenames; successful exit alone is
    # insufficient because syntax errors are reported to the 'errors' file.
    output_name = output.relative_to(ROOT).as_posix()
    if max(len(relative), len(output_name)) > 30:
        raise AssertionError("Historical filename limit exceeded (30 chars)")
    stdout, _ = execute(
        [str(COMPILER)], f"{relative}\n{output_name}\n", timeout=30
    )
    errors = (ROOT / "errors").read_text()
    if "no errors found" not in errors or not output.is_file() or output.stat().st_size == 0:
        raise AssertionError(
            f"Could not compile {source}:\n"
            f"STDOUT={stdout!r}\nERRORS={errors!r}\n"
            f"OUTPUT EXISTS={output.is_file()}\n"
            f"OUTPUT SIZE={output.stat().st_size if output.is_file() else 'missing'}"
        )
    print(f"  COMPILE OK: {relative}")
    return output


def interpret(program: Path, timeout: int = 60) -> tuple[str, float]:
    relative = program.relative_to(ROOT).as_posix()
    output, elapsed = execute([str(INTERPRETER)], f"{relative}\nno\n", timeout)
    if re.search(r"\b(?:error|deadlock|memorylimit|rangeerror)\b", output, re.I):
        raise AssertionError(f"Runtime error in {relative}:\n{output}")
    times = re.findall(r"(?m)^(\d+\.\d{3}) s$", output)
    if len(times) != 1:
        raise AssertionError(f"Missing fractional elapsed time in {relative}:\n{output}")
    seconds = float(times[0])
    if not 0 <= seconds <= elapsed + 1:
        raise AssertionError(
            f"Interpreter timing differs from monotonic elapsed time: "
            f"{seconds}s vs {elapsed:.3f}s"
        )
    print(f"  RUN OK: {relative} ({seconds:.3f} s)")
    return output, seconds


def check_primality(program: Path) -> None:
    output, _ = interpret(program)
    for expected in (
        "1653701519(10)",
        "0 composite votes, 2 prime votes",
        "1653701518(10)",
        "2 composite votes, 0 prime votes",
    ):
        assert expected in output, (expected, output)


def check_pipeline(program: Path) -> None:
    output, _ = interpret(program)
    assert "The resulting value is 100" in output, output


def check_recursion(program: Path) -> None:
    output, elapsed = interpret(program, timeout=120)
    found = re.findall(
        r"Dealer showing (\d+) partitions = (\d+)", output
    )
    expected = [(str(i), str(v)) for i, v in enumerate(EXPECTED_OUTCOMES)]
    assert found == expected, (found, expected, output)
    total = sum(EXPECTED_OUTCOMES)
    assert f"Total partitions = {total}" in output, output
    # With a multi-second benchmark, a zero reading would expose a clock bug.
    assert elapsed > 0, f"Timer returned zero for recursion benchmark:\n{output}"



def check_nested_scopes() -> None:
    nested = compile_source(ROOT / "tests" / "nested_recursion.sp")
    output, _ = interpret(nested)
    assert "Nested recursion succeeded" in output, output

    invalid = ROOT / "tests" / "recursive_implicit.sp"
    target = BUILD / "reject"
    target.unlink(missing_ok=True)
    stdout, _ = execute(
        [str(COMPILER)], f"tests/recursive_implicit.sp\nbuild/reject\n", timeout=30
    )
    errors = (ROOT / "errors").read_text()
    if "recursion error" not in errors.lower() or target.exists():
        raise AssertionError(
            f"Expected semantic recursion error for {invalid}:\n{stdout}\n{errors}"
        )
    print("  REJECTION OK: recursive implicit global state")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--full", action="store_true",
        help="also execute all remaining, potentially expensive examples",
    )
    args = parser.parse_args()
    for program in (COMPILER, INTERPRETER):
        if not program.is_file():
            raise SystemExit(f"Missing {program}; run 'make all' first")

    print("Compiling original example programs:")
    binaries = {
        src.stem: compile_source(src)
        for src in sorted((ROOT / "examples").glob("*.sp"))
    }
    if len(binaries) != 11:
        raise AssertionError(f"Expected 11 bundled examples, found {len(binaries)}")

    print("Testing interpreter:")
    check_primality(binaries["primality"])
    check_pipeline(binaries["pipeline"])
    check_recursion(compile_source(ROOT / "tests" / "outcomes.sp"))
    check_nested_scopes()

    if args.full:
        for name in sorted(set(binaries) - {"primality", "pipeline"}):
            # nbody's supplied 50,000 steps can be slow under interpretation.
            interpret(binaries[name], timeout=300)

    print("All tests passed.")


if __name__ == "__main__":
    main()
