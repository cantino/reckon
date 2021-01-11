#!/bin/bash

# set -x

set -Euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TEST_DIFF=""
OUTPUT=""
RECKON_CMD="env RUBYLIB=$SCRIPT_DIR/../../lib reckon -v"

main () {
    trap test_fail ERR

    if [[ $# -eq 1 ]]; then
        TESTS=$1/test_args
    else
        TESTS=$(find "$SCRIPT_DIR" -name 'test_args')
    fi

    echo > test.log

    for t in $TESTS; do
        OUTPUT=$(mktemp)
        TEST_DIR=$(dirname "$t")
        pushd "$TEST_DIR" >/dev/null || exit 1
        echo "$TEST_DIR Running..."
        TEST_CMD="$RECKON_CMD -o $OUTPUT $(cat test_args)"
        TEST_LOG=$(eval "$TEST_CMD" 2>&1)
        ERROR=0

        run_test ledger
        run_test hledger

        popd >/dev/null || exit 1
        echo -e "\n\n======>$TEST_DIR\n$TEST_CMD\n$TEST_LOG" >> test.log

        if [[ $ERROR -ne 0 ]]; then
            exit 1
        fi
    done
}

test_fail () {
    STATUS=$?
    if [[ $STATUS -ne 0 ]]; then
        echo -e "FAILED!!!\n$TEST_DIFF\nTest output saved to $OUTPUT\n"
        exit $STATUS
    fi
}

run_test () {
    LEDGER=$1
    TEST_DIFF=$(diff -u <($LEDGER -f output.ledger r --date-format %F 2>&1) <($LEDGER -f "$OUTPUT" r --date-format %F 2>&1) )

    echo -n "  - $LEDGER..."

    # ${#} is character length, test that there was no output from diff
    if [ ${#TEST_DIFF} -eq 0 ]; then
        echo "SUCCESS!"
    else
        echo "FAILED!"
        ERROR=1
    fi
}

main "$@"
