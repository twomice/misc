#!/bin/bash
set -euo pipefail

# Full system path to the directory containing this file, with trailing slash.
# This line determines the location of the script even when called from a bash
# prompt in another directory (in which case `pwd` will point to that directory
# instead of the one containing this script).  See http://stackoverflow.com/a/246128
MYDIR="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

REQUIRED_CIVIX_VERSION="25.12.0"

ACTUAL_VERSION=$(civix --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

if [ "$ACTUAL_VERSION" != "$REQUIRED_CIVIX_VERSION" ]; then
  echo "Error: civix version mismatch"
  echo "  Required: $REQUIRED_CIVIX_VERSION"
  echo "  Found:    $ACTUAL_VERSION"
  exit 1
fi
echo "Using civix $ACTUAL_VERSION"

civix generate:module "$@"

# derive extension dir (civix creates it in cwd)
EXT_DIR=$1
echo "Created ext dir: $EXT_DIR"

echo "Priming $EXT_DIR with skel files..."
rsync -a --ignore-existing --info=NAME $MYDIR/skel/ "${EXT_DIR}/"
