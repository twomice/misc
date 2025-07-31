#!/bin/bash

# This script aims to adhere to the Google Bash Style Guide:
# https://google.github.io/styleguide/shell.xml

# Print usage.
function usage() {
  echo ""
  echo "$0: for a given directory, report any identifiable php files therein which"
  echo "  contain php syntax errors."
  echo ""
  echo "Usage: $0 [directory]"
  echo "  directory: (optional) Path to directory to be scanned. If not given,"
  echo "    scan current directory."
}

# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
mydir="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

if [[ -n $1 ]]; then
  SCANDIR="$1";
else
  SCANDIR=$(pwd);
fi

read -p "About to scan $SCANDIR . Strike enter to continue or Ctrl+C to quit..."

cd $SCANDIR;

TEMPFILE=$(mktemp /tmp/phplinter.XXXXX);

ack -l '<\?(\s|php|=)' | grep -vP '\.(md|xml)$' > $TEMPFILE;
FILECOUNT=$(wc -l $TEMPFILE | awk '{print $1}');

echo "Scanning $FILECOUNT files ..."

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for f in $(cat $TEMPFILE); do
  ERRORS=$(php -d short_open_tag=On -l $f 2>&1 | grep -P '^PHP (Parse|Fatal) error')
  if [[ -n "$ERRORS" ]]; then
    echo "===== $f"
    echo "$ERRORS"
  else 
    >&2 echo -n '.'
  fi
done
IFS=$SAVEIFS

echo "Done."
echo "Scanned file list is at: $TEMPFILE"