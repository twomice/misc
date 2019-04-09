#!/bin/bash

# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
MYDIR="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

if ! command -v mdb-tables > /dev/null || ! command -v mdb-export > /dev/null; then
  echo "ERROR: This script requires mdb-tables and mdb-export, which are not found."
  echo "  (These are probably available for your system in the mdbtools package.)"
  exit 1
fi

if [[ -z $1 ]]; then
  echo "ERROR: Must provide directory to scan for *mdb files."
  exit 1
fi

SCANDIR=$1

BASE_DIR="$SCANDIR/export_all_to_csv"
mkdir -p $BASE_DIR
echo "Looking for *mdb files in ${SCANDIR} ..."
cd $SCANDIR;
for db in *mdb; do
  DB_DIR="${BASE_DIR}/${db}"
  for t in `mdb-tables $db`; do
    mkdir -p ${DB_DIR}
    >&2 echo -n "exporting ${db}.${t} to ${DB_DIR}/${t}.csv ..."
    mdb-export -D '%Y-%m-%d %H:%M:%S' $db $t > "${DB_DIR}/${t}.csv"
    >&2 echo " done."
  done
done
echo "Done."
