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

BASE_DIR="$SCANDIR/export_all_to_sql"
mkdir -p $BASE_DIR
echo "Looking for *mdb files in ${SCANDIR} ..."
cd $SCANDIR;


for db in *mdb; do
  TABLES=`mdb-tables -1 $db`
  DB_DIR="${BASE_DIR}/${db}"
  >&2 echo "exporting ${db} structure ${DB_DIR}/export.sql ..."
  mkdir -p ${DB_DIR}
  rm ${DB_DIR}/export.sql
  touch ${DB_DIR}/export.sql

  IFS=$'\n'       # make newlines the only separator
  for t in $TABLES; do
    echo "DROP TABLE IF EXISTS \`$t\`;" >> ${DB_DIR}/export.sql
  done
  unset IFS

  mdb-schema $db mysql >> "${DB_DIR}/export.sql"
  
  IFS=$'\n'       # make newlines the only separator
  for t in $TABLES; do
    >&2 echo -n "exporting \`${db}\`.\`${t}\` data to ${DB_DIR}/export.sql ..."
    mdb-export -D '%Y-%m-%d %H:%M:%S' -I mysql $db $t | sed -e 's/\\/\\\\/g' >> "${DB_DIR}/export.sql"
    >&2 echo " done."
  done
  unset IFS
done
echo "Done."
