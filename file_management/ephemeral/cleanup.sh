#!/bin/bash

# This script aims to adhere to the Google Bash Style Guide:
# https://google.github.io/styleguide/shell.xml

# Fail on error. Note some of the many caveats associated with this usage:
# http://mywiki.wooledge.org/BashFAQ/105
set -o errexit;

# Errors to STDERR.
err() {
  echo "ERROR:" $@ >&2
}

# Print usage.
function usage() {
  echo ""
  echo "Usage: $0 [DO_DELETE]"
  echo "  Cleanup all ephemeral directories which have exceeded their MAX_AGE."
  echo "  See also: usage notes for create.sh (Run create.sh without arguments)."
  echo "  DO_DELETE: (Optional) If string '1', files will be deleted. Otherwise,"
  echo "    they will merely be printed to STDOUT, preceded by this help text."
}

# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
mydir="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

# Reject root. This script uses `rm -rf`. We also enforce the same limitation in
# in create.sh.
if [ "$(id -u)" == "0" ]; then
	err "You may not run $0 as root.";
	exit 1;
fi

# Source config file or exit.
if [ -e ${mydir}/config.sh ]; then
  source ${mydir}/config.sh
else
  err "Could not find required config file at ${mydir}/config.sh. Exiting."
  exit 1;
fi

if [[ -z "${BASEDIR}" || -z "${DEFAULT_MAX_AGE}" ]]; then
  err "Missing required settings in config.sh. Please edit the file and try again. Exiting."
  exit 1;
fi

NOWFILE=$(tempfile);

# Determine proper behavior based on $1
if [ "$1" == "1" ]; then
  FILE_CMD='rm -rf';
else
  FILE_CMD='echo';
  usage;
  echo ""
  echo "THESE DIRECTORIES HAVE EXCEEDED THEIR MAX AGE (if any):"
fi

files=$(find $BASEDIR -type f -name '.ephemeral.timestamp' ! -newer $NOWFILE);
if [[ -z "$files" ]]; then
  echo "[NONE FOUND]"
else
  while read -r timesatmp_file; do
    if [[ -e $timesatmp_file ]]; then
      $FILE_CMD $(dirname $timesatmp_file);
    fi
  done <<< "$files"
fi

