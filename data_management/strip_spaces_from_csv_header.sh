#!/bin/bash

# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
MYDIR="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"


if [[ -z $1 ]]; then
  echo "ERROR: Must provide path/name of csv file to clean up."
  exit 1
fi

INFILE="$1"


head -n 1 "$INFILE" | sed 's/[^0-9a-zA-Z,"]/_/g'
tail -n+2  "$INFILE"
