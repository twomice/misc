<?php

class Utils {

  private $lastURL;

  const ERROR_FATAL = 1;
  const ERROR_WARNING = 2;
  const ERROR_SILENT = 4;

  function fetch($url, $username, $password, $decode_from) {
    $response = $this->curl($url, $username, $password);
    if ($decode_from == 'json') {
      $response = json_decode($response);
    }
    return $response;
  }

  function curl($url, $username, $password, $referer = null, $post = null, $return_header = false) {
    static $tmpfile;

    if(!isset($tmpfile) || ($tmpfile == '')) $tmpfile = tempnam('/tmp', 'FOO');

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_COOKIEFILE, $tmpfile);
    curl_setopt($ch, CURLOPT_COOKIEJAR, $tmpfile);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_USERPWD, "$username:$password");
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
    if (is_object($response) && property_exists($response, 'success') && $response->success === FALSE) {
      if ($error_type == Utils::ERROR_SILENT) {
        return TRUE;
      }
      require_once(MYKANBANPAD_PATH . '/krumo/class.krumo.php');
      echo "<fieldset><legend>ERROR</legend>";
      krumo($response);
      $db = debug_backtrace();
      echo '<h2>Backtrace:</h2>';
      krumo($db);
      echo "</fieldset>";
      if ($error_type == Utils::ERROR_FATAL) {
        die('Fatal error. Exiting.');
      }
      else {
        return TRUE;
      }
    }
  }
}