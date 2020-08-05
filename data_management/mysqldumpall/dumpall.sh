#!/bin/bash

# Resources:
# Bash style guide: https://google.github.io/styleguide/shellguide.html
# ShellCheck: https://www.shellcheck.net/

mysql_root_password="" # I'll be editing this line differently for each server.

single_dump_file=$(mktemp);
target_dir="" # Actually, this should come from an argument on the command line.

# dump all mysqldatabases to a single file in a single transaction
mysqldump -u root -p$mysql_root_password --single-transaction --all-databases > $single_dump_file

# Get all databases names from dumpfile
database_names=$(grep -P '^-- Current Database' $single_dump_file | awk '{ print $NF }' | sed 's/`//g');
for database_name in $database_names; do
  # do something with $database_name
done


