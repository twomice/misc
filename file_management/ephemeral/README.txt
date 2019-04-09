ephemeral

Bash scripts to manage emphemeral files.

===================
CONFIGURATION

Copy config.sh.dist to config.sh, and then edit config.sh
according to the comments in that file.

===================
USAGE

After configuration is complete, run any of these commands:

bash ./create.sh
  - Create a new ephemeral directory. Run without arguments for usage notes.
  
base ./cleanup.sh
  - Cleanup all ephemeral files that are old enough to delete. Run without
    arguments for usage notes.

