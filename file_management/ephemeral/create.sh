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
  echo "Usage: $0 DIRNAME [MAX_AGE]"
  echo "  DIRNAME: Name of ephemeral directory to create under $BASEDIR"
  echo "  MAX_AGE: (optional) Time, relative to creation, at which the created"
  echo "    ephemeral directory will be marked for deletion. This is a string"
  echo '    suitable for use in the -d argument to `date`, e.g., "3days". If'
  echo "    omitted, the default value of ${DEFAULT_MAX_AGE} is used."
}

# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
mydir="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

# Reject root. It's not so bad in create.sh, but in cleanup.sh we're using `rm -rf`,
# so let's break them of the sudo/root habit now.
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

# Ensure sufficient arguments.
if [[ "$#" != "1" &&  "$#" != "2" ]]; then
  usage;
  exit 1;
fi

DIRNAME=$1;
MAX_AGE=$2;
if [[ -z $MAX_AGE ]]; then
  MAX_AGE=$DEFAULT_MAX_AGE;
fi

TARGET_DIR="${BASEDIR}/${DIRNAME}";
if [[ -e $TARGET_DIR ]]; then
  err "Directory $TARGET_DIR already exists. Exiting.";
  exit 1;
fi
mkdir -p $TARGET_DIR;
TIMESTAMP_FILE="${TARGET_DIR}/.ephemeral.timestamp"
echo "Timestamp file for maximum age calculations for ephemral directories. DO NOT MODIFY." > $TIMESTAMP_FILE
touch -d "$MAX_AGE" $TIMESTAMP_FILE

echo "Ephemeral directory created at: ${TARGET_DIR}"
