<?php

// NOTES:
// Password is hardcoded in authenticate_or_die().

//
// check password | exit
// read input; validate input; apply input.

verify_ssl_or_die();
setup();
run();

function setup() {
  $config_file = dirname(__FILE__) . '/config.php';
  if (!file_exists($config_file) || !is_readable($config_file)) {
    fatal('Missing configuration. See "CONFIGURATION" in README.md.');
  }
  require_once($config_file);
  if (!defined('UPSTREAM_DIR') || !is_dir(UPSTREAM_DIR) || !file_exists(UPSTREAM_DIR . '/kimaiversion.php')) {
    fatal('Bad configuration. See "CONFIGURATION" in README.md. Is UPSTREAM_DIR correct?');
  }
}

function run() {
  if (empty($_POST)) {
    print_form_and_die();
  }
  else {
    process_form_and_die();
  }
}

function process_form_and_die() {
  authenticate_or_die();
  $data = format_data_or_die();
  apply_data_or_die($data);
}

function fatal($message) {
  $vars = array(
    'error' => $message,
  );
  print_form_and_die($vars);
  exit();
}

function status($message) {
  $vars = array(
    'status' => $message,
  );
  print_form_and_die($vars);
  exit();
}


function apply_data_or_die($data) {
  $query_status_counts = array(
    TRUE => 0,
    FALSE => 0,
  );
  $db = db_connect();
  foreach ($data as $id => $row) {
    $zef_in = (int)$row['zef_in'];
    $zef_trackingnr = mysqli_real_escape_string($db, $row['zef_trackingnr']);
    if ($zef_trackingnr === NULL) {
      $query_status_counts[0]++;
    }
    else {
      $query = "UPDATE kimai_zef SET zef_trackingnr = '$zef_trackingnr' WHERE zef_in = '$zef_in'";
      $result = db_unsafe_query($query);
      $query_status_counts[$result]++;
    }
  }
  $status = "Query results
    SUCCESS: {$query_status_counts[1]}
    FAILURE: {$query_status_counts[0]}
  ";
  status(nl2br($status));
}



function get_config_or_die() {
  static $config;
  if (empty($config)) {
    require_once (UPSTREAM_DIR . '/includes/autoconf.php');
    $config['server_hostname'] = $server_hostname;
    $config['server_database'] = $server_database;
    $config['server_username'] = $server_username;
    $config['server_password'] = $server_password;
    $config['server_conn'] = $server_conn;
    $config['server_type'] = $server_type;
    $config['server_prefix'] = $server_prefix;
    $config['language'] = $language;
    $config['password_salt'] = $password_salt;
  }
  return $config;
}

function format_data_or_die() {
  $data = filter_input(INPUT_POST, 'data', FILTER_UNSAFE_RAW);
  $data_rows = array_map('trim', explode("\n", $data));
  $returned_rows = array();

  $header_row = array_shift($data_rows);
  $parts = explode("\t", $header_row);
  if (count($parts) != 2 || $parts[0] != 'zef_in' || $parts[1] != 'zef_trackingnr') {
    fatal('Bad values in header row. Should be: zef_in\tzef_trackingnr');
  }

  foreach($data_rows as $row_id => $row) {
    if (empty($row)) {
      continue;
    }
    $rownum = ($row_id + 2);
    $parts = explode("\t", $row);
    if (empty($parts)) {
      continue;
    }
    if (count($parts) != 2) {
      fatal("Wrong number of values (should be exactly 2), in row $rownum.");
    }
    $zef_in = $parts[0];
    $zef_trackingnr = $parts[1];
    $zef_in = (int)$zef_in;
    if (empty($zef_in)) {
      fatal("Bad zef_in value in row $rownum");
    }
    $returned_rows[] = array(
      'zef_in' => $zef_in,
      'zef_trackingnr' => $zef_trackingnr,
    );

  }
  return $returned_rows;
}

function is_authentication_available() {
  $result = db_unsafe_query("
    SELECT 1
    FROM twomice_auth_log
    WHERE timestamp > DATE_ADD(NOW(),INTERVAL -5 SECOND)
  ");
  if ($result->num_rows) {
    echo "<pre>". var_export($result, 1) . '</pre>';
    echo "<pre>". var_export(mysqli_fetch_assoc($result)) . '</pre>';
    return FALSE;
  }
  return TRUE;
}

function log_authentication() {
  $result = db_unsafe_query("INSERT INTO twomice_auth_log(timestamp) values (now());");
  $result = db_unsafe_query("
    DELETE FROM `twomice_auth_log`
    WHERE authlog_ID != (
      SELECT id FROM (
          SELECT authlog_ID id
          FROM twomice_auth_log
          ORDER BY authlog_ID DESC LIMIT 1
      ) id
    )
  ");
}


function authenticate_or_die() {
  $is_authentication_available = is_authentication_available();
  log_authentication();
  if ($is_authentication_available) {
    $username = filter_input(INPUT_POST, 'username', FILTER_UNSAFE_RAW);
    $password = filter_input(INPUT_POST, 'password', FILTER_UNSAFE_RAW);

    $checked = password_verify($password, PASSWORD_HASH) && password_verify($username, USERNAME_HASH);
    if ($checked) {
      return TRUE;
    }
  }
  fatal('ERROR: Authentication failure.');
}

// Insist on https
function verify_ssl_or_die() {
  if (!isset($_SERVER['HTTPS']) || $_SERVER['HTTPS'] == 'off') {
    die('Must use https.');
  }
}

function print_form_and_die($vars = array()) {
  $error_html = '';
  $status_html = '';
  
  if (!empty($vars['error'])) {
    $error_html = '<div class="error">'. $vars['error'] . '</div>';
  }
  if (!empty($vars['status'])) {
    $status_html = '<div class="status">'. $vars['status'] . '</div>';
  }

  echo <<< EOF
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <title>Form</title>
    <style type="text/css">
      div.error {
        color: darkred;
        background: pink;
        border: 1px solid darkred;
        padding: 1em;
        margin-bottom: 1em;
      }
      div.status {
        color: darkgreen;
        background: lightgreen;
        border: 1px solid darkgreen;
        padding: 1em;
        margin-bottom: 1em;
      }
    </style>
    </head>
    <body>
    $error_html
    $status_html
    <form action="" method="POST">
      <div>
        username:<input type="text" name="username" />
      </div>

      <div>
        password:<input type="password" name="password" />
      </div>

      <div>
      data:<br>
        <textarea cols="200" rows="40" name="data"></textarea><br>
      </div>

      <input type="submit" value="submit" />
    </form>
    </body>
    </html>

EOF;

    exit();

}

function db_unsafe_query($query) {
  $db = db_connect();
  $result = mysqli_query($db, $query);
  return $result;
}
function db_connect() {
  $config = get_config_or_die();
  static $db;
  if (!isset($db)) {
    $db = mysqli_connect($config['server_hostname'], $config['server_username'], $config['server_password'], $config['server_database']);
  }
  return $db;
}