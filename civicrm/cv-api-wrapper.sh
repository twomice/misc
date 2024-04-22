#!/bin/bash

# This is a wrapper around `cv api` intended to better handle api errors,
# mainly by:
#   - omitting output on STDOUT unless it contains '"is_error": 1,'; and
#   - omitting PHP messages of type Warning, Notice, and Deprecated.
#
# Prior art: civi_api_trap_errors.sh, which had an undiagnosed tendency to run
# forever until killed.


tmpfile=$(mktemp /tmp/cv-api-wrapper-XXXXXXX.txt);

# Call `cv api` with our given arguments, and pipe both STDERR and STDOUT to our tmpfile.
cv api $@ &> $tmpfile;
# If `cv api` exited with anything other than "0", we'll print (most of) our
# tmpfile content to STDOUT.
if [[ "$?" != "0" ]]; then
  # Use grep to print everything in tmpfile except PHP warnings, notices and deprecations.
  grep -vP "^\[?(PHP )?(Warning|Notice|Depreca)" $tmpfile;
fi

# Remove tmpfile to conserve disk space.
rm $tmpfile