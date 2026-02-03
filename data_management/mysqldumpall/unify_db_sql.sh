#!/bin/bash

# Resources:
# Bash style guide: https://google.github.io/styleguide/shellguide.html
# ShellCheck: https://www.shellcheck.net/
mydir="$( cd -P "$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )" && pwd )/"

# If there is an arguments assign it to target_dir
if [[ "$#" -lt "1" ]]; then
  echo "Usage:" >&2
  echo "$0 DATABASE_DIRECTORY [TARGET_DB_NAME]" >&2
  echo "  DATABASE_DIRECTORY: full system path to a directory created by dumpall.sh." >&2
  echo "    This directory will contain a file named database.sql" >&2
  echo " TARGET_DB_NAME (optional): Name of database to be the target of the resulting" >&2
  echo "    sql statements; expects certain special values or a string:" >&2
  echo "    * If not given, output sql file will include database-level statements" >&2
  echo "      (DROP DATABASE IF EXISTS, CREATE DATABASE, and USE) specifying the original"
  echo "      database name as contained in database.sql;" >&2
  echo "    * If '-' (the literal minus character), output sql file will contain none of" >&2
  echo "      these database-level statements; you will need to specify them yourself" >&2
  echo "      when importing the sql file into mysql" >&2
  echo "    * If any other string, output sql file will contain these database-level statements" >&2
  echo "      specifying the given string as a database name." >&2
  echo >&2
  echo "NOTE: This program requires strip-mysql-definers.pl, which at time of writing is part of the" >&2
  echo "      twomcie/misc repo (found at ./data_management/strip-mysql-definers.pl); it's recommended" >&2
  echo "      to symplink that script into your path." >&2
  exit 1
fi

# require strip-mysql-definers.pl
if ! command -v strip-mysql-definers.pl >/dev/null 2>&1; then
  echo "strip-mysql-definers.pl not found. Exiting. Run this script without arguments to see usage and notes." >&2;
  exit 1;
fi

db_dir="$1"

if [[ ! -d "$db_dir" ]]; then
  echo "ERROR: Could not find DATABASE_DIRECTORY $db_dir" >&2
  exit 1;
fi
if [[ ! -f "$db_dir/database.sql" ]]; then
  echo "ERROR: DATABASE_DIRECTORY $db_dir does not contain database.sql" >&2
  exit 1;
fi

if [[ -z "$2" ]]; then
  # TARGET_DB_NAME not given. Use original db name.
  target_db_name=$(basename "$db_dir");
elif [[ "$2" != "-" ]]; then
  # TARGET_DB_NAME is a string other than '-'; use this name.
  target_db_name="$2"; 
fi

if [[ -n "$target_db_name" ]]; then
  # We have a target db name, so use it in the sql filename, and seed that
  # file with database-level sql statements.
  sqlfile=$(mktemp --tmpdir "${target_db_name}-XXXXXXX.sql");
  echo "DROP DATABASE IF EXISTS \`$target_db_name\`;" >> "$sqlfile"
  echo "CREATE DATABASE /*!32312 IF NOT EXISTS*/ \`$target_db_name\` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;" >> "$sqlfile";
  echo "USE \`$target_db_name\`;" >> "$sqlfile";
else
  # Don't use a target db name. Create an sql file with generic name and
  # no db-level statements.
  sqlfile=$(mktemp --tmpdir "XXXXXXX.sql");
  echo "No db name will be used." >&2
fi

# Disable autocommit for faster imports
echo "set AUTOCOMMIT = 0;" >> "$sqlfile";

# add table sql.
for i in $(ls "$db_dir"/tables/); do 
  echo "  adding $db_dir/tables/$i" >&2
  tablefile=$(mktemp);
  cat "$db_dir"/tables/"$i" | strip-mysql-definers.pl >> "$tablefile"
  # Until https://github.com/twomice/misc/issues/7 is solved, sql files may have
  # spurious `USE` statements, which will reference the wrong database if we're not
  # using the original db name. Strip that.
  sed -i '/^USE /d' "$tablefile"
  cat "$tablefile" >> "$sqlfile"
  rm $tablefile;
done

# We've used sed to remove DEFINER from triggers and such, but some databases also
# contain `SQL SECURITY DEFINER` (on a single line) which specify DEFINER names.
# Remove those also.
strip-mysql-definers.pl -i "$sqlfile"

# Since we disabled autocommit above, add a commit statement to write all.
echo "COMMIT;" >> "$sqlfile";

echo "Created sql file:" >&2
echo "$sqlfile"; 
exit 0;

