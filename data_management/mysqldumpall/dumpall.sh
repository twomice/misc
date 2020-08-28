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

# If there is an arguments assign it to target_dir
if [ "$#" -lt "1" ]; then
  echo "Could not find directory to put the extracted data."
  echo "Make sure to add directory as parameter ex: $(tput bold) bash dumpall.sh /target/directory. $(tput sgr0)"
  exit 1
else
  if [ -z "$2" ]; then
    target_dir="$1"
  else
    target_dir="$2"
  fi
fi

# Prompt user if directory exist and [-f] is not in the argument
if [[ -e "$target_dir" ]] && [ "$1" != "-f" ]; then
  echo "The directory already exist."
  echo "Do you want to delete all files in the directory? [Y/n]"
  read -r confirm_delete
  case $confirm_delete in
    [yY] | [yY][Ee][Ss] )
      echo "Deleting and re-installing."
      ;;
    [nN] | [nN][Oo] )
      echo "Exiting.";
      exit 1
      ;;
     *) echo "Invalid input. Please enter 'yes' or 'no'."
      exit 1
      ;;
  esac
fi

# Delete directory
rm -rf "$target_dir"

# Add the target directory after delete
mkdir -p "$target_dir"

# dump all mysqldatabases to a single file in a single transaction
echo Dump all mysqldatabases to a single file in a single transaction
mysqldump -u root -p"$mysql_root_password" --single-transaction --all-databases > "$single_dump_file"

# remove temp file if canceled
trap "rm -f $single_dump_file" EXIT

# Get all databases names from dumpfile
echo Get all databases names from dumpfile
database_names=$(grep --text -P '^-- Current Database' "$single_dump_file" | awk '{ print $NF }' | sed 's/`//g');
for database_name in $database_names; do
  # Extract database
  echo Extract database $database_name
  $mysqldumpsplitter_command --source "$single_dump_file" --extract DB --match_str "$database_name" --compression none --output_dir "$target_dir"/"$database_name"-temp >&2

  # Create main folders
  echo Create main folders
  mkdir "$target_dir"/"$database_name"
  mkdir "$target_dir"/"$database_name"/tables

  # Get all table names from database file
  echo Get all table names from database file
  tables=$(grep --text -P '^-- Table structure for table ' "$target_dir"/"$database_name"-temp/"$database_name".sql | awk '{ print $NF }' | sed 's/`//g');

  for table in $tables; do
    # Extract table
    echo Extract table $database_name.$table
    $mysqldumpsplitter_command --source "$target_dir"/"$database_name"-temp/"$database_name".sql --extract TABLE --match_str "$table" --compression none --output_dir "$target_dir"/"$database_name"-temp/tables-temp >&2

    # Remove comments starts with -- in table sql
    echo Remove comments starts with -- in table sql $database_name.$table
    grep -vw --text '^--' "$target_dir"/"$database_name"-temp/tables-temp/"$table".sql > "$target_dir"/"$database_name"/tables/"$table".sql
  done

  # Remove comments starts with -- in the main database sql 
  echo Remove comments starts with -- in the main database sql $database_name
  grep -vw --text '^--' "$target_dir"/"$database_name"-temp/"$database_name".sql > "$target_dir"/"$database_name"-temp/database.sql

  # Copy only the selected line base on the starting text of the line
  grep --text -wE '(^CREATE DATABASE|^USE)' "$target_dir"/"$database_name"-temp/database.sql > "$target_dir"/"$database_name"/database.sql

  # Remove databases and tables with comments
  echo Remove databases and tables with comments $database_name
  rm -r "$target_dir"/"$database_name"-temp
done

# Remove temp file of main data
rm "$single_dump_file"
