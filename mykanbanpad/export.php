<?php

define('MYKANBANPAD_PATH', dirname(__FILE__));
define('MYKANBANPAD_CONFIG_PATH', MYKANBANPAD_PATH . '/config.php');

require_once (MYKANBANPAD_CONFIG_PATH);
require_once (MYKANBANPAD_PATH . '/Utils.class.php');

global $export_directory;
$export_directory = MYKANBANPAD_PATH . '/export_json';
if (!is_dir($export_directory)) {
  mkdir($export_directory);
}

$utils = Utils::singleton($username, $key);

$projects = $utils->fetch('https://www.kanbanpad.com/api/v1/projects.json', 'json');
$utils->screen_error($projects, Utils::ERROR_FATAL);

// Limit by organization, if so configured.
if ($limit_to_organization_id) {
  $new_projects = array();
  foreach ($projects as $project) {
    if ($project->organization_id == $limit_to_organization_id) {
      $new_projects[] = $project;
    }
  }
  $projects = $new_projects;
}
echo "saving projects to projects.json\n";
export_to_file('projects.json', json_encode($projects));

foreach ($projects as $project) {
  $tasks = $utils->fetch("https://www.kanbanpad.com/api/v1/projects/{$project->slug}/tasks.json", 'json');
  if ($utils->screen_error($tasks, Utils::ERROR_SILENT)) {
    echo "ERROR getting tasks on project {$project->slug}\n";
    continue;
  }
  else {
    echo "saving tasks to tasks_{$project->slug}.json\n";
    export_to_file("tasks_{$project->slug}.json", json_encode($tasks));
  }
  
  $steps = $utils->fetch("https://www.kanbanpad.com/api/v1/projects/{$project->slug}/steps.json", 'json');

  if ($utils->screen_error($steps, Utils::ERROR_SILENT)) {
    $steps = array();
    echo "ERROR getting steps on project {$project->slug}\n";
  }
  else {
    echo "saving steps to steps_{$project->slug}.json\n";
    export_to_file("steps_{$project->slug}.json", json_encode($steps));
  }

  foreach ($tasks as $task) {
    $comments = $utils->fetch("https://www.kanbanpad.com/api/v1/projects/{$project->slug}/tasks/{$task->id}/comments.json", 'json');
    if ($utils->screen_error($comments, Utils::ERROR_SILENT)) {
      echo "ERROR getting comments on project {$project->slug}, task {$task->id}\n";
    }
    else {
      echo "saving comments to comments_{$project->slug}_{$task->id}.json\n";
      export_to_file("comments_{$project->slug}_{$task->id}.json", json_encode($comments));
    }
  }
}
echo "Done.\n";


function export_to_file($filename, $content) {
  global $export_directory;
  $fp = fopen("$export_directory/$filename", 'w');
  fwrite($fp, $content);
}