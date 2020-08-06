#!/bin/bash

# Resources:
# Bash style guide: https://google.github.io/styleguide/shellguide.html
# ShellCheck: https://www.shellcheck.net/
mydir="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

# Source config file or exit.
if [ -e "${mydir}"/config.sh ]; then
  source "${mydir}"/config.sh
else
  echo "Could not find required config file at ${mydir}/config.sh. Exiting."
  exit 1
fi

# Make temp file for the main data
single_dump_file=$(mktemp);

# If there is a first argument assign it to target_dir
if [ "$#" != "1" ]; then
  echo "Could not find directory to put the extracted data."
  echo "Make sure to add directory as parameter ex: $(tput bold) bash dumpall.sh /target/directory. $(tput sgr0)"
  exit 1
else
  target_dir="$1"
fi

# dump all mysqldatabases to a single file in a single transaction
mysqldump -u root -p"$mysql_root_password" --single-transaction --all-databases > "$single_dump_file"

# Get all databases names from dumpfile
database_names=$(grep -P '^-- Current Database' "$single_dump_file" | awk '{ print $NF }' | sed 's/`//g');
for database_name in $database_names; do
  # Extract database
  $mysqldumpsplitter_command --source "$single_dump_file" --extract DB --match_str "$database_name" --compression none --output_dir "$target_dir"/"$database_name"-temp

  # Create main folders
  mkdir "$target_dir"/"$database_name"
  mkdir "$target_dir"/"$database_name"/tables

  # Get all table names from database file
  tables=$(grep -P '^-- Table structure for table ' "$target_dir"/"$database_name"-temp/"$database_name".sql | awk '{ print $NF }' | sed 's/`//g');

  for table in $tables; do
    # Extract table
    $mysqldumpsplitter_command --source "$target_dir"/"$database_name"-temp/"$database_name".sql --extract TABLE --match_str "$table" --compression none --output_dir "$target_dir"/"$database_name"-temp/tables-temp

    # Remove comments in database sql and copy it to the main folder
    grep -vP '^-- ' "$target_dir"/"$database_name"-temp/tables-temp/"$table".sql > "$target_dir"/"$database_name"/tables/"$table".sql
  done

  # Remove comments in database sql and copy it to the main folder
  grep -vP '^-- ' "$target_dir"/"$database_name"-temp/"$database_name".sql > "$target_dir"/"$database_name"/"$database_name".sql

  # Remove databases and tables with comments
  rm -r "$target_dir"/"$database_name"-temp
done


