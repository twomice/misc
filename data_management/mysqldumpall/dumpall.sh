#!/bin/bash

# Resources:
# Bash style guide: https://google.github.io/styleguide/shellguide.html
# ShellCheck: https://www.shellcheck.net/

mysql_root_password="" # I'll be editing this line differently for each server.

single_dump_file=$(mktemp);
target_dir="" # Actually, this should come from an argument on the command line.

# dump all mysqldatabases to a single file in a single transaction
mysqldump -u root -p"$mysql_root_password" --single-transaction --all-databases > "$single_dump_file"

# Get all databases names from dumpfile
database_names=$(grep -P '^-- Current Database' "$single_dump_file" | awk '{ print $NF }' | sed 's/`//g');
for database_name in $database_names; do
  # Extract database
  sh mysqldumpsplitter.sh --source "$single_dump_file" --extract DB --match_str "$database_name" --compression none --output_dir ./"$database_name"
  # Delete last 3 line in the database extracted file
  # head -n -3 ./"$database_name"/"$database_name".sql

  # Extract all table in the database folder
  sh mysqldumpsplitter.sh --source ./"$database_name"/"$database_name".sql --extract ALLTABLES --decompression none --compression none --output_dir ./"$database_name"/tables
done


