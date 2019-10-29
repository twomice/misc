#!/bin/bash

# CiviCRM api wrapper, written mainly to avoid noise in cron jobs.
#
# Pipe civicrm api output to this script. If the output contains "is_error: 0", 
# this script will exit silently and exit 0. Otherwise it will print the output
# and exit 1.

# Check to see if a pipe exists on stdin.
if [ -p /dev/stdin ]; then

  # Store lines in a string for reprint if needed.
  LINES=""

  # Read the input line by line
  while IFS= read line; do
    # Add line to LINES for reprint if needed, with IFS for line-feed.
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
