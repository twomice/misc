#!/bin/bash

# This script aims to adhere to the Google Bash Style Guide:
# https://google.github.io/styleguide/shell.xml

# Get sudo privs.
echo "Securing sudo privileges..."
sudo echo "Thank you."

TARGET_VERSION=$1;
ERRORS="";

function err {
  echo $1;
}

if [[ ! -f "/etc/apache2/mods-available/php${TARGET_VERSION}.conf" ]]; then
  err "Apache conf /etc/apache2/mods-available/php${TARGET_VERSION}.conf not found";
  ERRORS=1;
fi
if [[ ! -f "/etc/apache2/mods-available/php${TARGET_VERSION}.load" ]]; then
  err "Apache module loader /etc/apache2/mods-available/php${TARGET_VERSION}.load not found";
  ERRORS=1;
fi
if [[ ! -f "/usr/bin/php${TARGET_VERSION}" ]]; then
  err "PHP executable /usr/bin/php${TARGET_VERSION} not found";
  ERRORS=1;
fi

ENABLED_MODULE=$(a2query -m | grep php | awk '{print $1}');
ENABLED_MODULE_COUNT=$(echo "$ENABLED_MODULE" | wc -l);
if [[ "$ENABLED_MODULE_COUNT" != "1" ]]; then
  err "Expected exactly one enabled apache module matching 'php...', but found $ENABLED_MODULE_COUNT";
  ERRORS=1;
fi

if [[ "$ERRORS" != "" ]]; then
  err "ERRORS! No action taken. Exiting."
  exit;
fi


echo "Switching to PHP $TARGET_VERSION ... Please wait"
sudo a2dismod "$ENABLED_MODULE";
sudo a2enmod "php${TARGET_VERSION}";
sudo service apache2 restart
sudo update-alternatives --set php "/usr/bin/php${TARGET_VERSION}"

echo "Done. New php version is:"
echo "  cli: $(php -v | head -n1)"
echo "  web: See http://localhost/info.php (which hopefully exists)"

exit;
