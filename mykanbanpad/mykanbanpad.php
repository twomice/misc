<?php

define('MYKANBANPAD_PATH', dirname(__FILE__));
require_once (MYKANBANPAD_PATH . '/config.php');
require_once (MYKANBANPAD_PATH . '/Utils.class.php');

$utils = new Utils();

$projects = $utils->fetch('https://www.kanbanpad.com/api/v1/projects.json', $username, $key, 'json');

$utils->screen_error($projects, Utils::ERROR_FATAL);

require_once (MYKANBANPAD_PATH . '/header.html');

if (is_array($my_aliases) && !empty($my_aliases)) {
  $limit_by_alias = TRUE;
  $my_aliases_string = implode($my_aliases, ', ');
}
else {
  $limit_by_alias = FALSE;
  $my_aliases_string = '(ALL)';
}

echo "<h1>Kanbanpad tasks assigned to: ". $my_aliases_string . "</h1>";
echo "<dl>";
foreach ($projects as $project) {
  $tasks = $utils->fetch("https://www.kanbanpad.com/api/v1/projects/{$project->slug}/tasks.json", $username, $key, 'json');
  if ($utils->screen_error($tasks, Utils::ERROR_SILENT)) {
    continue;
  }

  echo "<h2>{$project->name}</h2>";
  $project_has_tasks = FALSE;
  
  $steps = $utils->fetch("https://www.kanbanpad.com/api/v1/projects/{$project->slug}/steps.json", $username, $key, 'json');

  if ($utils->screen_error($steps, Utils::ERROR_WARNING)) {
    $steps = array();
  }
  else {
    $new_steps = array();
    foreach($steps as $step) {
      $new_steps[$step->id] = $step->name;
    }
    $steps = $new_steps;
  }

  foreach ($tasks as $task) {
    $task_title = (property_exists($task, 'title') ? $task->title : 'no_title');

    if ($steps[$task->step_id] == 'Released') {
      // Step is "Released", so we skip.
      continue;
    }
    if ($limit_by_alias) {
      $alias_matches = FALSE;
      if (
        property_exists($task, 'assigned_to')
        && is_array($task->assigned_to)
      ) {
        $assignment_matches = array_intersect($task->assigned_to, $my_aliases);
        if (!empty($assignment_matches)) {
          $alias_matches = TRUE;
        }
      }
      if (!$alias_matches) {
        // We're limiting by alias, and the alias doesn't match, so skip.
        continue;
      }
    }

    $project_has_tasks = TRUE;
    $url = "https://www.kanbanpad.com/projects/{$project->slug}#!xt-{$task->id}";
    echo "<dt><a target=\"_blank\" href=\"$url\">{$task_title}</a></dt>";
    echo '<dd><table class="task-properties-table">';
    echo "<tr><td class=\"label\">ID:</td><td>{$task->task_id}</td></tr>";
    echo "<tr><td class=\"label\">Note:</td><td>". (property_exists($task, 'note') ? nl2br($task->note) : '') ."</td></tr>";
    echo "<tr><td class=\"label\">Comments:</td><td> {$task->comments_total}</td></tr>";
    echo "<tr><td class=\"label\">Current step:</td><td> ". $steps[$task->step_id]."</td></tr>";
    echo "<tr><td class=\"label\">Urgent:</td><td> ". ($task->urgent ? 'Yes' : 'No' ) ."</td></tr>";
    echo "</table></dd>";
  }
  if (!$project_has_tasks) {
    echo "(no tasks)";
  }
  ob_flush();
  flush();
}
echo "</dl>";

require_once (MYKANBANPAD_PATH . '/footer.html');


