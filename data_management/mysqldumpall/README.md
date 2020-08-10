# dumpall.sh
A mysqldump that create database dumps in a certain way.


============================
## INSTALLATION:
1. Copy config.sh.dist to config.sh
2. Edit config.sh according to comments in that file.
   (Variables named in this README file are defined in confg.sh)
3. Requires [mysqldumpsplitter](https://github.com/kedarvj/mysqldumpsplitter)

============================
## USAGE:
```bash
bash dumpall.sh [-f] TARGET_DIRECTORY
```

**TARGET_DIRECTORY**: Full system path to a directory where you want to extract the database dumps. If this directory doesn't exist, it will be created. If it exists, any existing files or directories inside it will be deleted (see -f).

**-f**: If given, the user will NOT be prompted before deleting the contents of **TARGET_DIRECTORY**; otherwise the user will be prompted to confirm before such deletion.