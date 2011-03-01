#!/bin/sh

on_exit() {
    ret="$?"
    if [ $ret -ne 0 ] ; then
        echo "exiting with error"
    fi
    exit $?
}

trap on_exit EXIT INT

set -e

gcc -o test test.c -lrt -lpthread
../sample-memory-usage --interval 100000 --out test.dat ./test > test.labels
../graph-memory-usage --title "memtime sample" test.dat test.ps test.labels
ps2pdf test.ps
