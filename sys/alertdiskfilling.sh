#!/bin/bash

# Resources:
# Bash style guide: https://google.github.io/styleguide/shellguide.html
# ShellCheck: https://www.shellcheck.net/
# Directory
DIRECTORY=$1
# Desk space percentage
PERCENT=$2
# Email to send alert
EMAIL=$3

# Ensure sufficient arguments.
if [[ -z $DIRECTORY || -z $PERCENT || -z $EMAIL ]]; then
  echo "Insufficient arguments. It should be 'alertdiskfilling.sh [directory] [percentage] [email]'"
  exit 1;
fi

# Check if it is correct directory. Echo error if not
if [ ! -d "$DIRECTORY" ]; then
   echo "Directory $DIRECTORY doesn't exist."
   exit 1
fi

CHECKINT='^[0-9]+$'
if ! [[ $PERCENT =~ $CHECKINT ]] ; then
   echo "$PERCENT is not an integer."; 
   exit 1
fi

# Get current diskspace of the directory
# grep is used to remove the label..
# awk will get the current diskspace..
# cut will remove the % on it
DISKSPACE=$(df -H "$DIRECTORY" | grep -vE "^Filesystem|tmpfs|cdrom" | awk '{print $5}' | cut -d'%' -f1)

# If DISKSPACE is equal to or greater than the PERCENT..
# send alert email
if [ "$DISKSPACE" -ge "$PERCENT" ] ; then
	# Subject of the email
	SUBJECT="ATTENTION: disk usage at {$DISKSPACE}% at $(hostname)"
	# Body of the email
	BODY="ATTENTION: Disk usage exceeded threshold
		Server: $(hostname)
		Disk containing directory: $DIRECTORY
		Threshold: $PERCENT
		Usage: $DISKSPACE"
	# Send the email to EMAIL arg
	echo "$BODY" | mail -s "$SUBJECT" "$EMAIL"
	echo "$BODY"
else
	echo "Disk space normal"
fi
exit 1