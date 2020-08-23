#!/bin/bash
set -e;

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

DIRNAME="${backup_dir}/backup_$(date +%m%d%Y_%H%M%S)";

echo "Target dir: $DIRNAME";

mkdir -p $DIRNAME;

echo "Archiving files ..."
cd $wp_root_dir;
cd ..
wp_root_basename=$(basename $wp_root_dir);
tar --exclude="${wp_root_basename}/wp-content/updraft" -czf $DIRNAME/files.tgz "$wp_root_basename"; 

echo "Archiving databases ..."
echo "  Wordpress ..."
mysqldump -u $mysql_user --password="$mysql_password" $mysql_database_wordpress | gzip > $DIRNAME/mha_wp.sql.gz
if [[ -n $mysql_database_civicrm ]]; then
  echo "  CiviCRM..."
  mysqldump -u $mysql_user --password="$mysql_password" $mysql_database | gzip > $DIRNAME/mha_civicrm.sql.gz
fi

echo "Done. Target dir: $DIRNAME";

