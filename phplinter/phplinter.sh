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
MYDIR="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

# Source config file or exit.
if [ -e ${MYDIR}/config.sh ]; then
  source ${MYDIR}/config.sh
else
  echo "Could not find required config file at ${MYDIR}/config.sh. Exiting."
  exit 1
fi


if [[ -n $1 ]]; then
  SCANDIR="$1";
else
  SCANDIR=$(pwd);
fi

if [[ ! -d "$SCANDIR" ]]; then
  >&2 echo "Directory $SCANDIR does not exist. Exiting."
  exit 1;
fi

read -p "About to scan $SCANDIR . Strike enter to continue or Ctrl+C to quit..."

cd $SCANDIR;

TEMPFILE=$(mktemp /tmp/phplinter.XXXXX);

# Scan for lintable files (optionally using config var to exclude more files)
spinner() {
  while :; do
    for s in / - \\ \|; do
      printf "\r${1} $s" >&2; sleep 0.1;
    done;
  done;
}
spinner 'Scanning ...' &
SPINNER_PID=$!

DEFAULT_EXCLUSION_REGEX='\.(md|xml|js|tpl|css|markdown|scss|txt|yml|sh)$';
if [[ -n "$FILE_EXCLUSION_PCRE" ]]; then
  ack -l --no-follow '<\?(\s|php|=)' | grep -vP "$DEFAULT_EXCLUSION_REGEX" | grep -vP "${FILE_EXCLUSION_PCRE}" > $TEMPFILE;
else
  ack -l --no-follow '<\?(\s|php|=)' | grep -vP "$DEFAULT_EXCLUSION_REGEX" > $TEMPFILE;
fi

FILECOUNT=$(wc -l $TEMPFILE | awk '{print $1}');

kill $SPINNER_PID  # stop spinner

echo "Scanning $FILECOUNT files ..."

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
FILECOUNTER=1;
for f in $(cat $TEMPFILE); do
  ERRORS=$(php -d short_open_tag=On -l $f 2>&1 | grep -P '^PHP (Parse|Fatal) error')
  if [[ -n "$ERRORS" ]]; then
    echo "===== $f"
    echo "$ERRORS"
  fi
  ((FILECOUNTER++))
  pct=$((FILECOUNTER*100/FILECOUNT))
  >&2 printf "\rFiles processed: $FILECOUNTER out of $FILECOUNT (${pct}%% complete)"
done
>&2 echo;
IFS=$SAVEIFS

echo "Done."
echo "Scanned file list is at: $TEMPFILE"