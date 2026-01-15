#!/bin/bash

# Resources:
# Bash style guide: https://google.github.io/styleguide/shellguide.html
# ShellCheck: https://www.shellcheck.net/

# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
MYDIR="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/";

# Source config file or exit.
if [ -e ${MYDIR}/config.sh ]; then
  source ${MYDIR}/config.sh;
else
  echo "Could not find required config file at ${MYDIR}/config.sh. Exiting.";
  exit 1;
fi

# Source data file or exit.
if [ ! -e ${MYDIR}/data.psv ]; then
  echo "Could not find required data file at ${MYDIR}/data.psv. Exiting.";
  exit 1;
fi

LINE_GREP_EXPR='^[0-9.a-zA-Z]+@[0-9.a-zA-Z]+\|[^|]+$';
for LINE in $(grep -P "${LINE_GREP_EXPR}" $MYDIR/data.psv); do
  >&2 echo $LINE;
  USERHOST=$(echo $LINE | awk -F'|' '{print $1}');
  DIRECTORY=$(echo $LINE | awk -F'|' '{print $2}');
  CMD="ssh $USERHOST git -C $DIRECTORY status --porcelain"
  OUTPUT=$($CMD);
  >&2 echo "$CMD ..."
  >&2 echo "   $OUTPUT"
  if [[ -n "$OUTPUT" ]]; then
    echo "$OUTPUT" | mail -s "uncommitted git changes on $USERHOST in $DIRECTORY" $NOTIFY_TO_EMAIL
  fi
done;

echo "TODO: support an option to print vs email"