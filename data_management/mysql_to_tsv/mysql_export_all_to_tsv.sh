#!/bin/bash
set -e;

# This script aims to adhere to the Google Bash Style Guide:
# https://google.github.io/styleguide/shell.xml

# Print usage.
function usage() {
  echo ""
  echo "$0:"
  echo "Export the tables in a given mysql database to separate tab-separated files into a new, randomly named directory."
  echo ""
  echo "Usage: $0 DATABASE"
  echo "  DATABASE: Name of the mysql database to export"
  echo ""
}

# Ensure sufficient arguments.
if [[ "$#" -lt "1" ]]; then
  usage;
  exit 1
fi


# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
MYDIR="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

# Source config file or exit.
if [ -e ${MYDIR}/config.sh ]; then
  source ${MYDIR}/config.sh
else
  echo "Could not find required config file at ${MYDIR}/config.sh. Exiting."
  exit 1
fi

DATABASE=$1
DESTINATION=$(mktemp -d)
echo "Exporting to $DESTINATION"

TABLES=$(mysql --user=$MYSQL_USER_NAME --password=$MYSQL_USER_PASS -D $DATABASE -e "show tables" -B -N)
for t in $TABLES; do
  2>&1 echo "Exporting $t";
  mysql --user=$MYSQL_USER_NAME --password=$MYSQL_USER_PASS -D $DATABASE -e "select * from $t" -B > $DESTINATION/$t.tsv
done

echo "Done. Tables exported to $DESTINATION"
exit;
