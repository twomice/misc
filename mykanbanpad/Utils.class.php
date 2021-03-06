<?php

class Utils {

  private $lastURL;

  const ERROR_FATAL = 1;
  const ERROR_WARNING = 2;
  const ERROR_SILENT = 4;

  function  __construct($username, $password) {
    $this->username = $username;
    $this->password = $password;
  }
  public static function singleton($username = NULL, $password = NULL) {
    static $singleton;
    if ($singleton === NULL) {
      $singleton = new Utils($username, $password);
    }
    return $singleton;
  }
  
  function fetch($url, $decode_from) {
    $response = $this->curl($url);
    if ($decode_from == 'json') {
      $response = json_decode($response);
    }
    return $response;
  }

  function curl($url, $referer = null, $post = null, $return_header = false) {
    static $tmpfile;

    if(!isset($tmpfile) || ($tmpfile == '')) $tmpfile = tempnam('/tmp', 'FOO');

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_COOKIEFILE, $tmpfile);
    curl_setopt($ch, CURLOPT_COOKIEJAR, $tmpfile);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_USERPWD, "{$this->username}:{$this->password}");
    curl_setopt($ch, CURLOPT_USERAGENT, "Mozilla/5.0 (iPhone; U; CPU iPhone OS 2_2_1 like Mac OS X; en-us) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5H11 Safari/525.20");
    if($referer) curl_setopt($ch, CURLOPT_REFERER, $referer);

    if(!is_null($post))
    {
      curl_setopt($ch, CURLOPT_POST, true);
      curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
    }

    if($return_header)
    {
      curl_setopt($ch, CURLOPT_HEADER, 1);
      $html    = curl_exec($ch);
      $header_size = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
      $this->lastURL = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
      return substr($html, 0, $header_size);
    }
    else
    {
      $html = curl_exec($ch);
      $this->lastURL = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
      return $html;
    }
  }

  function screen_error($response, $error_type) {
    $is_cli = $this->is_cli();
    $error = $response_error = $bt_error = '';

    if($response === NULL) {
      $error = 'KanbanPad.com API has returned null; cannot process this step.';
    }
    if (is_object($response) && property_exists($response, 'success') && $response->success === FALSE) {
      $bt = debug_backtrace();
      $krumo_class_file = MYKANBANPAD_PATH . '/krumo/class.krumo.php';
      if (file_exists($krumo_class_file)) {
        require_once($krumo_class_file);
        $response_error = $this->krumo_ob($response);
        $bt_error = $this->krumo_ob($bt);
      }
      else {
        $response_error = var_export($response, 1);
        $bt_error = var_export($bt, 1);
        if (!$is_cli) {
          $response_error = "<pre>$response_error</pre>";
          $bt_error = "<pre>$bt_error</pre>";
        }
      }

      if ($is_cli) {
        $error = "ERROR:\n";
        $error .= $response_error . "\n";
      }
      else {
        $error .= "<fieldset><legend>ERROR</legend>";
        $error .= $response_error;
        $error .= '<h2>Backtrace:</h2>';
        $error .= $bt_error;
        $error .= "</fieldset>";
      }
    }

    if ($error) {
      if ($error_type == Utils::ERROR_SILENT) {
        return TRUE;
      }
      elseif ($error_type == Utils::ERROR_FATAL) {
        die($error . 'Fatal error. Exiting.');
      }
      else {
        echo $error;
        return TRUE;
      }
    }
  }

  // Save krumo htlm using output buffering.
  function krumo_ob($object) {
    ob_start();
    krumo($object);
    $output = ob_get_contents();
    ob_end_clean();
    return $output;
  }
  
  function is_cli() {
    if(defined('STDIN')) {
      return true;
    }
    return false;
  }
}