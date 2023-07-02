#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -C


APP=$(basename $PWD)
TAG="$USER/$APP"
docker build -t ${TAG}:latest  .
