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

 * Argument required is json output from logstash.openstack.org's table of metrics. There is no an export option so hack this together by changing the paging size
 * and watch the network traffic in chrome, then save it to a file.
 * Once the file exists, feed it to this script as an argument and it will go through and download all of the log_url items to a directory called 'dump'
 * You should probably mkdir dump/ in the same directory as this script first.
 */

date_default_timezone_set('US/Central');

$fetch_results = 500;
$search_days = 30;

$search = '{"query":{"filtered":{"filter":{"bool":{"must":[{"range":{"@timestamp":{"from":1463241312439,"to":1463846112439}}},{"fquery":{"query":{"query_string":{"query":"project:(\"openstack\/openstack-ansible\")"}},"_cache":true}},{"fquery":{"query":{"query_string":{"query":"build_name:(/gate-openstack-ansible-openstack-ansible-aio-ubuntu-(trusty|xenial-nv)/)"}},"_cache":true}},{"fquery":{"query":{"query_string":{"query":"message:(\"gate-check-commit.sh\")"}},"_cache":true}}]}}}},"size":'.$fetch_results.',"sort":[{"@timestamp":{"order":"desc","ignore_unmapped":true}},{"@timestamp":{"order":"desc","ignore_unmapped":true}}]}';
$search = json_decode($search);
$ts =& $search->query->filtered->filter->bool->must[0]->range->{'@timestamp'};
$ts->from = strtotime("-$search_days days")*1000;
$ts->to = time()*1000;

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

  echo "Fetching ".count($result->hits->hits)." samples\n";
  foreach($result->hits->hits as $h) {
    $outfile = $h->{'_source'}->{'build_change'}.'-'.$h->{'_source'}->{'build_patchset'}.'.html';
    if (file_exists('dump/'.$outfile)) {
      echo "Already downloaded $outfile..skipping\n";
      continue;
    }
    $url = $h->{'_source'}->{'log_url'};
    $wget = "wget -O dump/{$outfile} {$url}";
    echo "running $wget\n";
    echo "Fetching $url to $outfile\n";
    $exec = fetch_log($url, $outfile);
    if ($exec['exit_code'] != 0) {
      $url = $url.'.gz';
      echo "Fetch failed. Trying $url\n";
      $exec = fetch_log($url, $outfile);
      if ($exec['return_code'] != 0) echo "Fetch failed retry. Skipping file.\n";
      else echo "Fetch succeeded retry\n";
    }
    else echo "Fetch succeeded\n";
  }
}

function fetch_log($url, $outfile) {
  $wget = "wget -O dump/{$outfile} {$url}";
  exec($wget, $shell_output, $code);
  return array('output' => $shell_output, 'exit_code' => $code);
}

function fetch_results($search, $url) {
  $ch = curl_init($url);
  //curl_setopt($ch, CURLOPT_VERBOSE, true);
  //curl_setopt($ch, CURLOPT_HEADER, true);
  curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "POST");
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $search);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_HTTPHEADER, array(
      'Content-Type: application/json',
      'Content-Length: ' . strlen($search))
  );
  $result = curl_exec($ch);
  return $result;
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
?>
