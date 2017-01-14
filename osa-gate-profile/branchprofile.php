#!/usr/bin/php
<?php
/*
  Copyright 2016, Logan Vig <logan2211@gmail.com>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

$fetch_results = 10000;
$search_days = 14;

$search = '{"query":{"filtered":{"filter":{"bool":{"must":[{"range":{"@timestamp":{"from":1463241312439,"to":1463846112439}}},{"fquery":{"query":{"query_string":{"query":"project:(\"openstack\/openstack-ansible\")"}},"_cache":true}},{"fquery":{"query":{"query_string":{"query":"build_name:(\"gate-openstack-ansible-dsvm-commit\")"}},"_cache":true}},{"fquery":{"query":{"query_string":{"query":"message:(\"- Operation: [\u00a0openstack-ansible --forks\")"}},"_cache":true}}]}}}},"size":10000,"sort":[{"@timestamp":{"order":"desc","ignore_unmapped":true}},{"@timestamp":{"order":"desc","ignore_unmapped":true}}]}';
$search = json_decode($search);
$ts =& $search->query->filtered->filter->bool->must[0]->range->{'@timestamp'};
$ts->from = strtotime("-$search_days days")*1000;
$ts->to = time()*1000;

//remove timestamp limit from search
//$nothing = array_shift($search->query->filtered->filter->bool->must);

$search->size = $fetch_results;
$search = json_encode($search);

$date = time();
$stats = array();
$total_samples = 0;
while ($total_samples < $fetch_results && $date > strtotime("-$search_days days")) {
  $strdate = date('Y.m.d', $date);
  $date -= 86400;

  echo "Fetching results for $strdate\n";
  $url = "http://logstash.openstack.org/elasticsearch/logstash-$strdate/_search";
  $result = json_decode(fetch_results($search, $url));
  if (empty($result) || isset($result->error) || $result->status == 404) {
    echo "Error fetching results for $strdate.. skipping\n";
    continue;
  }

  echo "Analyzing ".count($result->hits->hits)." samples\n";
  $total_samples += process_results($result, $stats);
}

foreach ($stats as &$branch) {
  foreach ($branch as &$nodepool) {
    foreach ($nodepool as &$playbook) {
      $avg = array_sum($playbook) / count($playbook);
      $playbook['samples'] = count($playbook);
      $playbook['average'] = $avg;
    }
  }
}

foreach ($stats as $bname => $branch) {
  echo "Stats for openstack-ansible/$bname\n";
  foreach ($branch as $npname => $nodepool) {
    echo "Node pool $npname:\n";
    uasort($nodepool, 'avg_cmp');
    foreach ($nodepool as $pbname => $playbook) {
      echo "\t$pbname: ".ceil($playbook['average'])." avg, ({$playbook['samples']} samples)\n";
    }
  }
}

function fetch_results($search, $url) {
  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $search);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_HTTPHEADER, array(
      'Content-Type: application/json',
      'Content-Length: ' . strlen($search))
  );
  return curl_exec($ch);
}

function process_results($result, &$stats) {
  $regex = '/Operation: \[ openstack-ansible --forks [0-9]+\s+(?<play_name>[^\.]+).yml \]\s+(?<play_seconds>[0-9]+)\s+seconds/';
  foreach ($result->hits->hits as $r) {
    $rs = $r->{'_source'};
    if (!preg_match($regex, $rs->message, $m)) continue;
    $stats[$rs->build_branch][$rs->node_provider][$m['play_name']][] = $m['play_seconds'];
  }
  return count($result->hits->hits);
}

function avg_cmp($a, $b) {
  if ($a['average'] == $b['average']) {
    return 0;
  }
  return ($a['average'] > $b['average']) ? -1 : 1;
}
?>
