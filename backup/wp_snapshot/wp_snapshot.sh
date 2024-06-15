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

DIRNAME="${backup_dir}/backup_$(date +%m%d%Y_%H%M%S)";

echo "Target dir: $DIRNAME";

mkdir -p $DIRNAME;

if [[ "$use_sudo" == "1" ]]; then
  sudocmd="sudo"
  echo "Acquiring sudo access ..."
  sudo echo "Thank you."
fi

echo "Archiving files ..."
cd $wp_root_dir;
cd ..
wp_root_basename=$(basename $wp_root_dir);
$sudocmd tar --exclude="${wp_root_basename}/wp-content/updraft" -czf $DIRNAME/files.tgz "$wp_root_basename";

MYSQL_OPTIONS=""
if [[ -n "$mysql_host" ]]; then
  MYSQL_OPTIONS=" --host=$mysql_host"
fi
if [[ -n "$mysql_port" ]]; then
  MYSQL_OPTIONS="$MYSQL_OPTIONS --port=$mysql_port"
fi

echo "Archiving databases ..."
echo "  Wordpress ..."
mysqldump -u $mysql_user --password="$mysql_password" --no-tablespaces --routines $MYSQL_OPTIONS $mysql_database_wordpress | gzip > $DIRNAME/wp.sql.gz

if [[ -n $mysql_database_civicrm ]]; then
  if [[ -z "$mysql_user_civicrm" ]]; then
    mysql_user_civicrm="$mysql_user";
  fi
  if [[ -z "$mysql_password_civicrm" ]]; then
    mysql_password_civicrm="$mysql_password";
  fi
  if [[ -z "$mysql_host_civicrm" ]]; then
    mysql_host_civicrm="$mysql_host";
  fi
  if [[ -z "$mysql_port_civicrm" ]]; then
    mysql_port_civicrm="$mysql_port";
  fi
  MYSQL_OPTIONS=""
  if [[ -n "$mysql_host_civicrm" ]]; then
    MYSQL_OPTIONS=" --host=$mysql_host_civicrm"
  fi
  if [[ -n "$mysql_port_civicrm" ]]; then
    MYSQL_OPTIONS="$MYSQL_OPTIONS --port=$mysql_port_civicrm"
  fi
  echo "  CiviCRM..."
  mysqldump -u $mysql_user_civicrm --password="$mysql_password_civicrm" --no-tablespaces --routines $MYSQL_OPTIONS $mysql_database_civicrm | gzip > $DIRNAME/civicrm.sql.gz
fi

echo "Done. Target dir: $DIRNAME";
