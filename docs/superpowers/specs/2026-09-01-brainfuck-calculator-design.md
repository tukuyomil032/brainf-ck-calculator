# Brainfuck Calculator CLI Design

## Goal

Build a command-line calculator whose arithmetic and input parsing are implemented in Brainfuck. A small POSIX shell wrapper exposes the Brainfuck program as a convenient CLI and translates its machine-readable output into a stable command-line interface.

## CLI contract

The command accepts exactly one expression argument:

```sh
./bin/brainf-ck-calculator "12 + 3"
```

The accepted grammar is two non-negative decimal integers separated by exactly one operator. ASCII spaces, tabs, and the trailing newline supplied by the wrapper are ignored around tokens. The supported operators are `+`, `-`, `*`, and `/`. Parentheses, multiple operators, negative operands, and fractional operands are invalid.

Operands and successful results are limited to `0` through `255`. Addition and multiplication overflow, subtraction below zero, division by zero, malformed input, and out-of-range operands are errors. Division uses integer truncation.

Successful commands print the decimal result followed by a newline to stdout and exit with status 0. Input and arithmetic errors print a human-readable message to stderr and exit with status 2. A failure from the external Brainfuck runtime is propagated by the wrapper. If the runtime cannot be found, the wrapper exits with status 127 and explains how to configure `BF_RUNTIME`.

## Components

### `calculator.bf`

The Brainfuck program reads the expression from stdin, parses both operands and the operator, performs the requested arithmetic, checks the range rules, and emits the internal protocol. It uses 8-bit wrapping cells and multiple cells for the multiplication accumulator so that overflow can be detected instead of silently wrapping.

The program emits exactly one protocol record followed by a newline:

```text
OK:15
ERR:INVALID_INPUT
ERR:OUT_OF_RANGE
ERR:NEGATIVE_RESULT
ERR:DIV_ZERO
```

The target runtime is expected to provide 8-bit cells, a sufficiently large tape to the right, and EOF as zero. These assumptions are documented because Brainfuck runtimes do not share one universal machine specification.

### `bin/brainf-ck-calculator`

The POSIX shell wrapper resolves `calculator.bf` relative to its own location, validates the argument count, invokes the external runtime, and translates the protocol. The default runtime command is `brainfuck`; users can override it with a command path in `BF_RUNTIME`:

```sh
BF_RUNTIME=/path/to/brainfuck ./bin/brainf-ck-calculator "12 + 3"
```

`BF_RUNTIME` is treated as one executable path or command name, not as a shell command line with additional arguments.

### Tests and documentation

`tests/test_cli.sh` exercises successful operations, boundary values, arithmetic errors, malformed input, argument-count errors, and runtime lookup failures. `README.md` documents installation assumptions, usage, constraints, error behavior, runtime overrides, and test execution. `.gitattributes` marks `*.bf` as Brainfuck for GitHub Linguist.

## Operational boundary

The repository is cloned to `/Users/hosiyomi322/Documents/dev/brainf-ck-calculator`. The implementation is committed on the feature branch `feat/brainfuck-calculator`. No remote push is performed as part of this work.
