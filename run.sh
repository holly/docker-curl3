#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -C


APP=$(basename $PWD | sed -e 's/^docker\-//')
TAG="$USER/$APP"

SRC=$PWD/tmp
DST=/data

test -d $SRC &&  rm -fr $SRC
mkdir $SRC
docker run --rm --mount type=bind,src=$SRC,dst=$DST -it $TAG:latest $@
