#!/bin/bash

# This file is deprecated. Do not use.
echo "DO NOT USE:"
echo "This script ($0) has an undiagnosed tendency to run forever until"
echo "killed manually. Please try using cv-api-wrapper.sh instead."
exit 1;

# CiviCRM api wrapper, written mainly to avoid noise in cron jobs.
#
# Pipe civicrm api output to this script. If the output contains "is_error: 0", 
# this script will exit silently and exit 0. Otherwise it will print the output
# and exit 1.

# Check to see if a pipe exists on stdin.
if [ -p /dev/stdin ]; then

  # Store lines in a string for reprint if needed.
  LINES=""

  # Pattern to match PHP warnings and notices; output will be stripped of lines
  # matching this pattern, thus preventing them from generating cron emails. 
  # Note this will really only be helpful if stderr is redirected to stdin.
  IGNORE_PATTERN="^PHP (Warning|Notice)\b"
  # Read the input line by line
  while IFS= read line; do
    # Add line to LINES for reprint if needed, with IFS for line-feed.
    if [[ $line =~ $IGNORE_PATTERN ]]; then
      continue;
    fi
    LINES="$LINES$line$IFS"
    if [[ "$line" == *'"is_error": 0,'* ]]; then
      # CiviCRM api reported no error, so exit 0.
      exit 0;          
    fi
  done
  
  # if we're still here, it means there was an error. Print the output, and exit 1.
  echo "$LINES"
  exit 1;
      
fi
