#!/bin/bash
#
# Copied from: http://www.noah.org/engineering/src/shell/rsync_backup
#
# This maintains a one week rotating backup. This will normalize permissions on
# all files and directories on backups. It has happened that someone removed
# owner write permissions on some files, thus breaking the backup process. This
# prevents that from happening. All this permission changing it tedious, but it
# eliminates any doubts. I could have done this with "chmod -R +X", but I
# wanted to explicitly set the permission bits.
#
# Pass two arguments: rsync_backup SOURCE_PATH BACKUP_PATH
#
# $Id: rsync_backup 222 2008-02-21 22:05:30Z noah $

usage() {
    echo "usage: $0 [-v] [-n] BACKUP_PATH SOURCE_PATH [SOURCE_PATH [...]]"
    echo "    SOURCE_PATH and BACKUP_PATH may be ssh-style remote paths; although,"
    echo "    BACKUP_PATH is usually a local directory where you want the"
    echo "    backup set stored."
    echo "    You may specific multiple SOURCE_PATH arguments to backup multiple paths."
    echo "    -v : set verbose mode"
    echo "    -n : normalize directory and file permissions to 755 for dirs and 644 for files."
}

DEFAULT_MAXDAYS=7
VERBOSE=0
NORMALIZE_PERMS=0
while getopts ":vnh" options; do
    case $options in
        v ) VERBOSE=1;;
        n ) NORMALIZE_PERMS=1;;
        h ) usage
            exit 1;;
        \? ) usage
            exit 1;;
        * ) usage
            exit 1;;
    esac
done
shift $(($OPTIND - 1))

if [ "$#" -lt "2" ] ; then
    echo "Missing argument. Give source path and backup path."
    usage
    exit 1
fi

SECONDS=0;
if [ $VERBOSE ]; then
    echo "=============================== START: $(date)"
fi

BACKUP_PATH=$1
SOURCES=$(echo $@ | cut -f 1 -d ' ' --complement);

echo "Called as: $0 $@"
echo "VERBOSE=$VERBOSE"
echo "NORMALIZE_PERMS=$NORMALIZE_PERMS"

echo "backup: $BACKUP_PATH"
echo "source: $SOURCES"

SOURCE_BASE="rotation"
PERMS_DIR=755
PERMS_FILE=644
if [ $VERBOSE ]; then
    RSYNC_OPTS="-azR --delete -v"
    date
else
    RSYNC_OPTS="-azR --delete -q"
fi

echo "RSYNC_OPTS: $RSYNC_OPTS"

# Create the LATEST rotation directory if it doesn't exist.
mkdir -p $BACKUP_PATH/$SOURCE_BASE.LATEST

# Include config file if available.
if [[ -f $BACKUP_PATH/config.sh ]]; then
  . $BACKUP_PATH/config.sh
  cat $BACKUP_PATH/config.sh
fi
# Process config values.
MAXDAYS=${MAXDAYS:-$DEFAULT_MAXDAYS}
# Ensure positive integer for MAXDAYS
if [[ ! $MAXDAYS =~ ^[0-9]+$ || "$MAXDAYS" == "0" ]]; then
  MAXDAYS=1
fi


# TODO All these find operations to clean up permissions is going to add a lot
# of overhead as the backup set gets bigger. At 100 GB it's not a big deal. The
# correct thing would be to have an exception based system where I correct
# permissions when/if they cause a problem.

# Rotate backups.
#if [[ "$NORMALIZE_PERMS" == "1" ]]; then
#    if [ $VERBOSE ]; then
#        echo "Normalizing file permissions."
#    fi
#    find $BACKUP_PATH/$SOURCE_BASE.6 -type d -exec chmod $PERMS_DIR {} \;
#    find $BACKUP_PATH/$SOURCE_BASE.6 -type f -exec chmod $PERMS_FILE {} \;
#fi

# Find rotations older than MAXDAYS and delete them.
for i in $(find $BACKUP_PATH -maxdepth 2 -type f -name BACKUP_TIMESTAMP -mtime +$MAXDAYS); do
  DELETEDIR=$(dirname $i);
  # Never delete rotation.LATEST.
  if [[ "$DELETEDIR" = "$BACKUP_PATH/$SOURCE_BASE.LATEST" ]]; then
    continue;
  fi
  echo "Deleting $DELETEDIR; over $MAXDAYS days old."
  # Ensure all nodes in DELETEDIR are writable before deleting the directory. 
  # Otherwise, if some directories are not writable, files within them 
  # can't be removed, so `rm -rf` will ultimately leave the DELETEDIR intact.
  chmod -R u+w $DELETEDIR;
  rm -rf $DELETEDIR;
done

# Create hard-link copies of rotation.LATEST using that rotation's BACKUP_TIMESTAMP,
# if rotation.LATEST exists (i.e., after first run)
if [[ -f $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_TIMESTAMP ]]; then
  TIMENAME=$(date -d @$(stat -c %.Y $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_TIMESTAMP) +%Y-%m-%d_%H%M%S.%N);
  cp -al $BACKUP_PATH/$SOURCE_BASE.LATEST $BACKUP_PATH/$SOURCE_BASE.$TIMENAME;
fi

# Backup.
if [[ "$NORMALIZE_PERMS" == "1" ]]; then
    if [ $VERBOSE ]; then
        echo "Normalizing file permissions."
    fi
    find $BACKUP_PATH/$SOURCE_BASE.LATEST -type d -exec chmod $PERMS_DIR {} \;
    find $BACKUP_PATH/$SOURCE_BASE.LATEST -type f -exec chmod $PERMS_FILE {} \;
    if [ $VERBOSE ]; then
        echo "Done normalizing file permissions."
    fi
fi
rsync $RSYNC_OPTS $SOURCES $BACKUP_PATH/$SOURCE_BASE.LATEST/.
RSYNC_EXIT_STATUS=$?
if [[ "$NORMALIZE_PERMS" == "1" ]]; then
    if [ $VERBOSE ]; then
        echo "Normalizing file permissions."
    fi
    find $BACKUP_PATH/$SOURCE_BASE.LATEST -type d -exec chmod $PERMS_DIR {} \;
    find $BACKUP_PATH/$SOURCE_BASE.LATEST -type f -exec chmod $PERMS_FILE {} \;
fi

# Ignore error code 24, "rsync warning: some files vanished before they could be transferred".
if [ $RSYNC_EXIT_STATUS = 24 ] ; then
    RSYNC_EXIT_STATUS=0
fi

# Create a timestamp file to show when backup process completed successfully.
rm -f $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_ERROR
rm -f $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_TIMESTAMP
if [ $RSYNC_EXIT_STATUS = 0 ] ; then
    echo "This file's timestamp is the creation time of this backup." > $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_TIMESTAMP
else # Create a timestamp if there was an error.
    echo "rsync failed" > $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_ERROR
    date >> $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_ERROR
    echo $RSYNC_EXIT_STATUS >> $BACKUP_PATH/$SOURCE_BASE.LATEST/BACKUP_ERROR
fi

if [ $VERBOSE ]; then
    TOTALSECONDS=$SECONDS;
    printf 'Total time: %02dh:%02dm:%02ds\n' $(($TOTALSECONDS/3600)) $(($TOTALSECONDS%3600/60)) $(($TOTALSECONDS%60))
    echo "================================ END: $(date)"
fi

exit $RSYNC_EXIT_STATUS
