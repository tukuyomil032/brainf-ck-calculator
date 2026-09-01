# Brainf*ck Calculator

A command-line calculator with arithmetic implemented in Brainfuck.

## Requirements

- A Brainfuck runtime named `brainfuck` on `PATH`, or an executable path supplied through `BF_RUNTIME`
- An 8-bit-cell Brainfuck runtime with wrapping cells, a sufficiently large tape, and EOF handled as zero

The bundled runtime wrapper normalizes the validated expression into the line-oriented input format expected by the `brainfuck` runtime. The calculator program itself performs the arithmetic and decimal output.

## Usage

```sh
./bin/brainf-ck-calculator 12 + 3
# 15

./bin/brainf-ck-calculator 12-3
# 9

./bin/brainf-ck-calculator 12 \* 3
# 36

./bin/brainf-ck-calculator 10 / 3
# 3
```

The wrapper also accepts a spaced expression without surrounding quotes by joining its arguments. The `*` operator must be escaped because most shells expand it as a filename wildcard.

To use a runtime at another path:

```sh
BF_RUNTIME=/path/to/brainfuck ./bin/brainf-ck-calculator "12 + 3"
```

`BF_RUNTIME` must contain one executable path or command name. It is not parsed as a shell command line with additional arguments.

## Expression format

The calculator accepts exactly two non-negative decimal integers and one operator. Spaces and tabs around the tokens are allowed.

Supported operators:

- `+` addition
- `-` subtraction
- `*` multiplication
- `/` integer division, truncating the remainder

Operands and results must be in the range `0` through `255`. Addition and multiplication that exceed `255`, subtraction that would become negative, and division by zero are rejected. Parentheses, negative operands, fractional values, and multiple operators are not supported.

Successful calculations print only the decimal result to stdout and exit with status `0`.

Input and arithmetic errors print a message to stderr and exit with status `2`. If the configured Brainfuck runtime cannot be found, the command exits with status `127`. A failure returned by the runtime is propagated by the wrapper.

Examples:

```sh
$ ./bin/brainf-ck-calculator "3 - 5"
ERROR: result would be negative

$ ./bin/brainf-ck-calculator "8 / 0"
ERROR: division by zero
```

## Tests

Run the shell syntax check and integration suite with:

```sh
sh -n bin/brainf-ck-calculator
BF_RUNTIME=brainfuck sh tests/test_cli.sh
```

If the runtime is installed under another name or path, pass its executable path:

```sh
BF_RUNTIME=/path/to/brainfuck sh tests/test_cli.sh
```
