#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CLI="$ROOT_DIR/bin/brainf-ck-calculator"
BF_RUNTIME=${BF_RUNTIME:-brainfuck}

if case "$BF_RUNTIME" in
    */*) [ -x "$BF_RUNTIME" ] ;;
    *) command -v "$BF_RUNTIME" >/dev/null 2>&1 ;;
esac
then
    :
else
    echo "ERROR: test Brainfuck runtime not found: $BF_RUNTIME" >&2
    exit 77
fi

assert_success() {
    expression=$1
    expected=$2
    actual=$(BF_RUNTIME="$BF_RUNTIME" "$CLI" "$expression")
    if [ "$actual" != "$expected" ]; then
        echo "FAIL: $expression -> $actual (expected $expected)" >&2
        exit 1
    fi
}

assert_error() {
    expression=$1
    expected_status=$2
    expected_message=$3
    error_file=$(mktemp "${TMPDIR:-/tmp}/brainf-ck-calculator-test.XXXXXX")
    trap 'rm -f "$error_file"' EXIT HUP INT TERM

    if BF_RUNTIME="$BF_RUNTIME" "$CLI" "$expression" > /dev/null 2>"$error_file"; then
        echo "FAIL: $expression unexpectedly succeeded" >&2
        exit 1
    else
        actual_status=$?
    fi

    actual_message=$(awk '{ print }' "$error_file")
    rm -f "$error_file"
    trap - EXIT HUP INT TERM

    if [ "$actual_status" -ne "$expected_status" ]; then
        echo "FAIL: $expression returned $actual_status (expected $expected_status)" >&2
        exit 1
    fi
    if [ "$actual_message" != "$expected_message" ]; then
        echo "FAIL: $expression wrote '$actual_message' (expected '$expected_message')" >&2
        exit 1
    fi
}

assert_success "12 + 3" "15"
assert_success "12-3" "9"
assert_success "12 * 3" "36"
assert_success "10 / 3" "3"
assert_success "0 + 0" "0"
assert_success "255 - 0" "255"
assert_success "100 + 155" "255"
assert_success "100 * 2" "200"

assert_error "3 - 5" 2 "ERROR: result would be negative"
assert_error "255 + 1" 2 "ERROR: operand or result is out of range (0-255)"
assert_error "20 * 20" 2 "ERROR: operand or result is out of range (0-255)"
assert_error "8 / 0" 2 "ERROR: division by zero"
assert_error "4 % 2" 2 "ERROR: invalid expression"
assert_error "2 + 3 + 4" 2 "ERROR: invalid expression"
assert_error "-1 + 2" 2 "ERROR: invalid expression"
assert_error "256 + 1" 2 "ERROR: operand or result is out of range (0-255)"

assert_error "" 2 "ERROR: invalid expression"

error_file=$(mktemp "${TMPDIR:-/tmp}/brainf-ck-calculator-test.XXXXXX")
trap 'rm -f "$error_file"' EXIT HUP INT TERM
if BF_RUNTIME="$BF_RUNTIME" "$CLI" > /dev/null 2>"$error_file"; then
    echo "FAIL: missing argument unexpectedly succeeded" >&2
    exit 1
else
    actual_status=$?
fi
actual_message=$(awk '{ print }' "$error_file")
rm -f "$error_file"
trap - EXIT HUP INT TERM
[ "$actual_status" -eq 2 ]
[ "$actual_message" = "usage: brainf-ck-calculator \"NUMBER OPERATOR NUMBER\"" ]

error_file=$(mktemp "${TMPDIR:-/tmp}/brainf-ck-calculator-test.XXXXXX")
trap 'rm -f "$error_file"' EXIT HUP INT TERM
if BF_RUNTIME="$BF_RUNTIME" "$CLI" "1+1" "2+2" > /dev/null 2>"$error_file"; then
    echo "FAIL: extra arguments unexpectedly succeeded" >&2
    exit 1
else
    actual_status=$?
fi
actual_message=$(awk '{ print }' "$error_file")
rm -f "$error_file"
trap - EXIT HUP INT TERM
[ "$actual_status" -eq 2 ]
[ "$actual_message" = "usage: brainf-ck-calculator \"NUMBER OPERATOR NUMBER\"" ]

if BF_RUNTIME=/definitely/missing/brainfuck "$CLI" "1+1" > /dev/null 2> /dev/null; then
    echo "FAIL: missing runtime unexpectedly succeeded" >&2
    exit 1
else
    actual_status=$?
fi
[ "$actual_status" -eq 127 ]

echo "CLI integration tests: PASS"
