<?php if($_GET['phpinfo']) {phpinfo(); exit;} ?>
<!DOCTYPE html>
<html>
<head>
  <style>
    td.bool-false{font-weight:bold; color: red;} 
    td.bool-true{font-weight: bold; color: green;}
    th {font-weight: bold; background:lightgray;}
    table {border-collapse: collapse;}
    td, th {text-align: left; padding: .25em; border: 1px solid lightgrey;}
    iframe {width: 100%; border: 0;  height: 1000000px;}
  </style>
  <title>PHP Tests</title>
</head>
<body>
<h2>session test</h2>
(reload to ensure that session vars increment, and session id remains constant.)<br>
<strong>NOTE: proper session handling probably depends on using https.</strong>  If this site requires sessions over insecure http , disable the <em>session.cookie_httponly</em> and <em>session.cookie_secure</em> settings in PHP.<br>
<?php 
  $statusMessages=[];
  
  session_start(); 
  
  $dir = realpath(dirname($_SERVER["SCRIPT_FILENAME"]));
  
  $file = $dir . "/test_". uniqid();
  $fp = fopen($file, "w");
  fwrite($fp, "This file is writable. ". uniqid());
  fclose($fp);
  
  $statusMessages['This directory is'] = $dir;
  $statusMessages['This file'] = __FILE__;
  $statusMessages['Test File path'] = $file;
  $statusMessages['Test File Path Is this directory'] = (bool)(strpos($file, $dir) !== FALSE);
  
  $statusMessages['Test file has been created'] = (bool)file_exists($file);
  $statusMessages['Test file contents written dynamically'] = file_get_contents($file);
  
  $pwuid = posix_getpwuid(fileowner($file));
  $statusMessages['Test file owner'] = $pwuid["name"];
  $statusMessages['Test file mtime'] = filemtime($file);
  $statusMessages['Test file perms'] = substr(sprintf("%o", fileperms($file)), -4);
  
  $statusMessages['Test file deleted successfullly']= unlink($file);
  $statusMessages['Files remaining in this directory']= "<pre>". var_export(scandir(__DIR__), 1) . "</pre>";
  
  $statusMessages['session ID'] = session_id();
  $statusMessages['session vars'] = var_export($_SESSION, 1);
  $statusMessages['Session var $a is set (reload page if FALSE)'] = isset($_SESSION['a']);
  $statusMessages['Value of Session var $a (should increment with each page load)'] = $_SESSION['a'];
  
  $_SESSION['a']++;
?>
<hr>
<h2>Tests:</h2>
<table>
  <tr>
    <th>Test</th>
    <th>Status</th>
  </tr>
  <?php
  foreach ($statusMessages as $label => $value) {
    unset($tdClass);
    if (is_bool($value)) {
      $tdClass = ($value ? "bool-true" : "bool-false");
      $value = ($value ? "TRUE" : "FALSE");
    }
    echo "<tr><td>$label</td><td class=\"$tdClass\">$value</td></tr>";
  }
  ?>
</table>

<iframe src="<?= $_SERVER['SCRIPT_NAME'] ?>?phpinfo=1"></iframe>
</body>
</html>