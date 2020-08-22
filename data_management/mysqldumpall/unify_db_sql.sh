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
  exit 1
fi

db_dir="$1"
if [[ -n "$2" ]]; then
  target_db_name="$2"
fi

if [[ ! -d "$db_dir" ]]; then
  echo "ERROR: Could not find DATABASE_DIRECTORY $db_dir" >&2
  exit 1;
fi
if [[ ! -f "$db_dir/database.sql" ]]; then
  echo "ERROR: DATABASE_DIRECTORY $db_dir does not contain database.sql" >&2
  exit 1;
fi

if [[ -z "$target_db_name" ]]; then
  # TARGET_DB_NAME not given. Use original db name.
  # Because older versions of dumpall.sh don't include DROP DATABASE, we'll add that here.
  original_db_name=$(basename "$db_dir");

  # Make temp file for the main data, using original db name.
  sqlfile=$(mktemp --tmpdir "${original_db_name}-XXXXXXX.sql");
  
  echo "DROP DATABASE IF EXISTS \`$original_db_name\`;" >> "$sqlfile"
  grep -v 'DROP DATABASE' "$db_dir/database.sql" >> "$sqlfile";
elif [[ "$target_db_name" != "-" ]]; then
  # TARGET_DB_NAME is a string other than '-'; use this name.
  # Make temp file for the main data, using specified db name.
  sqlfile=$(mktemp --tmpdir "${target_db_name}-XXXXXXX.sql");
  echo "DROP DATABASE IF EXISTS \`$target_db_name\`;" >> "$sqlfile"
  echo "CREATE DATABASE /*!32312 IF NOT EXISTS*/ \`$target_db_name\` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;" >> "$sqlfile";
  echo "USE \`$target_db_name\`;" >> "$sqlfile";
  
else
  # TARGET_DB_NAME is '-'; don't specify a db name.
  # Make temp file for the main data, using no specified db name.
  sqlfile=$(mktemp --tmpdir "XXXXXXX.sql");
  echo "No db name will be used." >&2
fi

# add table sql.
for i in $(ls "$db_dir"/tables/); do 
  echo "  adding $db_dir/tables/$i" >&2
  sed 's#^/\*!50003 CREATE\*/ /\*!50017 DEFINER=`[^`]*`@`[^`]*`\*/#/*!50003 CREATE*/#g' "$db_dir"/tables/"$i" >> "$sqlfile"
done

# We've used sed to remove DEFINER from triggers and such, but some databases also
# contain `SQL SECURITY DEFINER` (on a single line) which specify DEFINER names.
# Remove those also.
sed -i '/DEFINER/d' "$sqlfile"
echo "Created sql file:" >&2
echo "$sqlfile"; 
exit 0;
