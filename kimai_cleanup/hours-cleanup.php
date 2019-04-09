#!/usr/bin/php
<?php
// Default: assumes output is straight from Kimai
// Date,In,Out,h:m,Time,Rate (by hour),Dollar,Budget,Approved,Billable,Customer,Project,Activity,Description,Comment,Location,Track#,Username,cleared


# Ensure sufficient arguments.
if (empty($argv[1])) {
  echo "Usage: hours-cleanup FILENAME\n";
  echo "  FILENAME: Name of a Kimai export CSV file; this file is searched for\n";
  echo "    in the current directory, and in /tmp/.\n";
  exit;
}


// Writable temp directory.
$tmp = '/tmp';

$check_dirs = array(
  '',
  '.',
  $tmp,
);
$file_found = FALSE;
$location = '';
foreach ($check_dirs as $dir) {
  $filename = $argv[1];
  if ($dir) {
    $location = "in $dir";
  }
  echo "Checking for file $filename $location ... ";
  $filepath = "$dir/$filename";
  if(file_exists($filepath)) {
    echo "found.\n";
    $file_found = TRUE;
    break;
  }
  else {
    echo "not found\n";
  }
}

if (!$file_found) {
  echo ("File not found.\n");
  exit;
}


$fp = fopen($filepath, 'r');

// throw away the header row
fgetcsv($fp);

$rows = array();
$sort = array();
while ($row = fgetcsv($fp)) {
  $newrow = array();
  // Get columns

  $newrow['date'] = preg_replace('/^(\d+)\.(\d+).$/', '$2/$1/'. date('Y'), $row[0]);
  $newrow['in'] = $row[1];
  $newrow['out'] = $row[2];
  $newrow['hours'] = $row[3];
  $newrow['customer'] = $row[10];
  $newrow['project'] = $row[11];
  $newrow['activity'] = $row[12];
  $newrow['comment'] = $row[14];
  $newrow['trackingno'] = $row[16];
  $newrow['sorttimestamp'] = strtotime($newrow['date'] . ' ' . $newrow['in']);

  // Sort rows by client/activity/datetime
  $row_sort_string =
    // client
    $newrow['customer']
    // activity
    . '|'. $newrow['activity']
    // date and time
    . '|'. $newrow['sorttimestamp']
  ;

  $sort[] = $row_sort_string;
  $newrow['row_sort_string'] = $row_sort_string;
  $rows[] = $newrow;

  unset($row);

}
fclose($fp);

// Sort rows by client/activity/datetime
array_multisort($sort, $rows);

// Adjust for final display:
$last_project_comment = array();
foreach ($rows as &$row) {
  $row['client'] = (isset($row['client']) ? $row['client'] : '');
  $project_key = $row['client'] . '|' . $row['project'];

  // Initialize array member.
  $last_project_comment[$project_key] = (isset($last_project_comment[$project_key]) ? $last_project_comment[$project_key] : '');
  
  if ($row['comment']) {
    $comment = $row['comment'];
  }
  else {
    $comment = $last_project_comment[$project_key];
  }

  $row['extra_comment'] = $last_project_comment[$project_key] = $comment;

  $row = array(
    'zef_in' => strtotime("{$row['date']} {$row['in']}"),
    'trackingno' => $row['trackingno'],
    'date' => $row['date'],
    'hours' => $row['hours'],
    'project' => $row['project'],
    'extra_comment' => $row['extra_comment'],
    'comment' => $row['comment'],
    'customer' => $row['customer'],
    'in' => $row['in'],
    'out' => $row['out'],
    'activity' => $row['activity'],
    'row_sort_string' => $row['row_sort_string'],
  );
}
unset($row);

$columns_ordered = array(
  array(
    'key' => 'zef_in',
    'label' => 'zef_in',
  ),
  array(
    'key' => 'trackingno',
    'label' => 'zef_trackingnr',
  ),
  array(
    'key' => 'activity',
    'label' => 'activity',
  ),
  array(
    'key' => 'customer',
    'label' => 'Client',
  ),
  array(
    'key' => 'project',
    'label' => 'Project',
  ),
  array(
    'key' => 'date',
    'label' => 'Date',
  ),
  array(
    'key' => 'hours',
    'label' => 'Hours',
  ),
  array(
    'key' => 'extra_comment',
    'label' => 'Description',
  ),
  array(
    'key' => 'in',
    'label' => 'in',
  ),
  array(
    'key' => 'out',
    'label' => 'out',
  ),
  array(
    'key' => 'comment',
    'label' => 'Original comment',
  ),
  array(
    'key' => 'row_sort_string',
    'label' => 'row_sort_string',
  ),
);

$header_row = array();
foreach ($columns_ordered as $column) {
  $header_row[] = $column['label'];
}

$file_prefix = uniqid();
$cleaned_file = "$tmp/{$file_prefix}_cleaned.csv";
echo "Cleaned data: $cleaned_file\n";
$op = fopen($cleaned_file, 'w');
fputcsv($op, $header_row);
foreach ($rows as $row) {
//  var_dump($row); exit;
  
  $output_row = array();
  foreach ($columns_ordered as $column) {
    $output_row[] = $row[$column['key']];
  }
  fputcsv($op, $output_row);
}
fclose($op);


// Begin processing "consolidated" list.
$date_activities = array();
foreach ($rows as $row) {
  // Initialize arrays
  $customer = $row['customer'];
  $date = $row['date'];
  $activity = $row['activity'];
  $extra_comment = $row['extra_comment'];

  if (!isset($date_activities[$customer])) {
    $date_activities[$customer] = array();
  }
  if (!isset($date_activities[$customer][$date])) {
    $date_activities[$customer][$date] = array();
  }
  if (!isset($date_activities[$customer][$date][$activity])) {
    $date_activities[$customer][$date][$activity] = array();
  }
  if (!isset($date_activities[$customer][$date][$activity][$extra_comment])) {
    $date_activities[$customer][$date][$activity][$extra_comment] = array();
  }
  if (!isset($date_activities[$customer][$date][$activity][$extra_comment]['seconds'])) {
    $date_activities[$customer][$date][$activity][$extra_comment]['seconds'] = 0;
  }

  list($hours, $minutes, $seconds) = explode(':', $row['hours']);
  $minutes += ($hours * 60);
  $seconds += ($minutes * 60);
  $date_activities[$customer][$date][$activity][$extra_comment]['seconds'] += $seconds;
  if (!isset($date_activities[$customer][$date][$activity][$extra_comment]['row'])) {
    $date_activities[$customer][$date][$activity][$extra_comment]['row'] = $row;
    $date_activities[$customer][$date][$activity][$extra_comment]['row']['extra_comment'] = $row['extra_comment'];
  }
}

$consolidated_file = "$tmp/{$file_prefix}_consolidated.csv";
echo "Consolidated data: $consolidated_file\n";
$op = fopen($consolidated_file, 'w');
fputcsv($op, $header_row);

foreach($date_activities as $client => $dates) {
  foreach($dates as $date => $activities) {
    foreach($activities as $activity) {
      foreach($activity as $comment => $comment_properties) {
        $comment_row = $comment_properties['row'];
        $comment_row['hours'] = secondstotimestring($comment_properties['seconds']);
        $comment_row['date'] = $date;

        $row = array();
        foreach ($columns_ordered as $column) {
          $row[] = $comment_row[$column['key']];
        }

        fputcsv($op, $row);
      }
    }
  }
}

echo "\nLazy command line for OpenOffice users:\n";
echo "oocalc $cleaned_file $consolidated_file\n\n";
echo "Done.\n";
exit;



function secondstotimestring($seconds) {
  $hours = floor($seconds / 3600);
  $minutes = floor(($seconds / 60) % 60);
  $seconds = $seconds % 60;
  return sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
}
