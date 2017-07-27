#!/bin/bash

if test $# -ne 2; then
    echo "Syntax: $0 libraryName PathToLib"
    exit 2
fi

LIBRARYNAME=$1
PATHTOLIB=$2

TARGETS="Linux  linux_x64  MacOSX  Windows  Windows_x64"

echo "Remove previous libraries ..."
for d in $TARGETS; do
    svn remove $d/thirdparty/$LIBRARYNAME-*jar
done

echo "Add the new library version ..."
for d in $TARGETS; do
    FILENAME=$(basename $PATHTOLIB)
    cp $PATHTOLIB $d/thirdparty/$FILENAME
    svn add $d/thirdparty/$FILENAME
done

echo "Commit ..."
for d in $TARGETS; do
    svn commit -m "New release of $LIBRARYNAME" $d/thirdparty/
done

