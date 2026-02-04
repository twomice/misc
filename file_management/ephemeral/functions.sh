print_dir_url() {
  if [[ -n "$BASEDIR_BASE" && -n "$BASE_URL" ]]; then
    local URL=$(echo $1 | sed "s#^${BASEDIR_BASE}#${BASE_URL}#")
    echo "URLs:"
    echo "Directory:      $URL"
    echo "Timestamp file: $URL/.ephemeral.timestamp"
  else
    echo "RECOMMENDED: to support printing of generated URLs, add configs for BASEDIR_BASE and BASE_URL in"
    echo "             $MYDIR/config.sh"
    echo "             (See $MYDIR/config.sh.dist)"
  fi
}