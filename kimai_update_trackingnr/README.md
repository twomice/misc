# Kimai Tracking Number Updater

Bare-bones form to update Tracking Number for any (reasonable) number of Kimai
entries.


## CONFIGURATION:
Copy config.dist.php to config.php; edit config.php according to comments in
that file.

## INSTALATION:
1. Copy all files to a single directory on the web server where Kimai is installed.
You may place this entire directory under the document root for the web server,
or create a symbolic link ("symlink") to the update_trackingnr.php file in a
location under the document root (assuming the web server supports symbolic
links).
2. Run the SQL queries in install.sql against the Kimai database.