#!/bin/bash

set -Euo pipefail


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TEST_DIFF=""
OUTPUT=""
RECKON_CMD="reckon -v"
export RUBYLIB=$SCRIPT_DIR/../../lib:${RUBYLIB:-}
export PATH="$SCRIPT_DIR/../../bin:$PATH"

main () {
    trap test_fail EXIT

    if [[ $# -eq 1 ]]; then
        TESTS=$1/test_args
    else
        TESTS=$(find "$SCRIPT_DIR" -name 'test_args')
    fi

    echo > test.log

    NUM_TESTS=$(echo "$TESTS" |wc -l |awk '{print $1}')

    echo "1..$NUM_TESTS"

    I=1

    for t in $TESTS; do
        TEST_DIR=$(dirname "$t")
        TEST_LOG=$(mktemp)
        pushd "$TEST_DIR" >/dev/null || exit 1
        if [[ -e "cli_input.txt" ]]; then
            cli_test >$TEST_LOG 2>&1
        else
            unattended_test >$TEST_LOG 2>&1
        fi

        popd >/dev/null || exit 1
        # have to save output after popd
        echo -e "\n\n======>$TEST_DIR" >> test.log
        echo -e "TEST_CMD: $TEST_CMD" >> test.log
        cat $TEST_LOG >> test.log

        if [[ $ERROR -ne 0 ]]; then
            echo -e "not ok $I - $TEST_DIR"
            tail -n25 test.log
            exit 1
        else
            echo -e "ok $I - $TEST_DIR"
        fi
        I=$(($I + 1))
    done
}

cli_test () {
    OUTPUT_FILE=$(mktemp)
    TEST_CMD="$RECKON_CMD --table-output-file $OUTPUT_FILE $(cat test_args)"
    cat cli_input.txt | $TEST_CMD
    TEST_DIFF=$(diff -u "$OUTPUT_FILE" expected_output)

    # ${#} is character length, test that there was no output from diff
    if [ ${#TEST_DIFF} -eq 0 ]; then
        ERROR=0
    else
        ERROR=1
    fi
}

unattended_test() {
    OUTPUT_FILE=$(mktemp)
    TEST_CMD="$RECKON_CMD -o $OUTPUT_FILE $(cat test_args)"
    eval "$TEST_CMD" 2>&1
    ERROR=0

    compare_output "$OUTPUT_FILE"
}

test_fail () {
    STATUS=$?
    if [[ $STATUS -ne 0 ]]; then
        echo -e "FAILED!!!\n$TEST_DIFF\nTest output saved to $OUTPUT_FILE\n"
        exit $STATUS
    fi
}

compare_output () {
    OUTPUT_FILE=$1
    pwd
    if [[ -e compare_cmds ]]; then
        COMPARE_CMDS=$(cat compare_cmds)
    else
        COMPARE_CMDS=$'ledger\nhledger'
    fi

    ERROR=1
    while IFS= read -r n; do
        if compare_output_for "$OUTPUT_FILE" "$n"; then
            ERROR=0
        else
            ERROR=1
            break
        fi
    done <<< "$COMPARE_CMDS"
}

compare_output_for () {
    OUTPUT_FILE=$1
    LEDGER=$2

    EXPECTED_FILE=$(mktemp)
    ACTUAL_FILE=$(mktemp)

    EXPECTED_CMD="$LEDGER -f output.ledger r >$EXPECTED_FILE"
    echo "$EXPECTED_CMD"
    eval "$EXPECTED_CMD" || return 1

    ACTUAL_CMD="$LEDGER -f \"$OUTPUT_FILE\" r"
    echo "running $ACTUAL_CMD"
    eval $ACTUAL_CMD >$ACTUAL_FILE || return 1

    TEST_DIFF=$(diff -u "$EXPECTED_FILE" "$ACTUAL_FILE")

    # ${#} is character length, test that there was no output from diff
    if [ ${#TEST_DIFF} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

main "$@"
