#!/bin/bash

# This is a wrapper around `cv api` intended to better handle api errors,
# mainly by:
#   - omitting output on STDOUT unless it contains '"is_error": 1,'; and
#   - omitting PHP messages of type Warning, Notice, and Deprecated.
#
# NOTE:
# If calling this from crontab, `cv` is probably not in $PATH. In that case, define
# CV_PATH as an environment on the crontab command, e.g.
# * * * * * CV_PATH='/opt/buildkit/bin/cv' /full/path/to/cv-api-wrapper.sh --user=civiadmin --cwd=/var/www/example.com contact.getsingle id=11111111
#
# Prior art: civi_api_trap_errors.sh, which had an undiagnosed tendency to run
# forever until killed.

# Try to determine path to cv.
if [[ -n "$CV_PATH" ]]; then
  cv=$CV_PATH;
else
  cv=$(command -v cv 2>/dev/null);
fi
if [[ -z "$cv" ]]; then
  echo "Could not find cv in PATH ($PATH). HINT: try defining CV_PATH as an environment variable.";
  exit 1;
fi

# create a temp file to hold `cv` api STDERR and STDOUT.
tmpfile=$(mktemp /tmp/cv-api-wrapper-XXXXXXX.txt);

# Call `cv api` with our given arguments, and pipe both STDERR and STDOUT to our tmpfile.
$cv api $@ &> $tmpfile;
# If `cv api` exited with anything other than "0", we'll print (most of) our
# tmpfile content to STDOUT.
if [[ "$?" != "0" ]]; then
  # Use grep to print everything in tmpfile except PHP warnings, notices and deprecations.
  grep -vP "^\[?(PHP )?(Warning|Notice|Depreca)" $tmpfile;
fi

# Remove tmpfile to conserve disk space.
rm $tmpfile