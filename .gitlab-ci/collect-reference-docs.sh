#!/usr/bin/bash

BUILD_FOLDER=${1:doc-build}

VALADOC=public/reference/valadoc
mkdir -p $VALADOC
GTKDOC=public/reference/gtkdoc
mkdir -p $GTKDOC
for i in $BUILD_FOLDER/doc/reference/*/valadoc ; do
    lib=$(echo $i | cut -f 4 -d/)
    mv $i $VALADOC/$lib
done

for i in $BUILD_FOLDER/doc/reference/*/gtkdoc/html ; do
    lib=$(echo $i | cut -f 4 -d/)
    mv $i $GTKDOC/$lib
done
