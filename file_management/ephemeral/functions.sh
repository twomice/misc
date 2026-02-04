print_dir_url() {
  local URL=$(echo $1 | sed "s#^${BASEDIR_BASE}#${BASE_URL}#")
  echo "URLs:"
  echo "Directory:      $URL"
  echo "Timestamp file: $URL/.ephemeral.timestamp"
}