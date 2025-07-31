# Copy this file to config.sh and edit per comments.

# PCRE expression matching file paths not to be scanned 
# (to be used in the context of `grep -vP "$FILE_EXCLUSION_PCRE"`).
# e.g. FILE_EXCLUSION_PCRE="(ConfigAndLog)"
FILE_EXCLUSION_PCRE="(ConfigAndLog)"
# FILE_EXCLUSION_PCRE=""