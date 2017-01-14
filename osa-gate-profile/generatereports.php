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

$f = json_decode(file_get_contents($argv[1]), true);
$profiles = [];
$sorted = array();
foreach ($f as $taskname => $nodeproviders) {
  echo "$taskname:\n";
  foreach ($nodeproviders as $p => $n) {
    $avg = round(array_sum($n) / count($n), 2);
    $samples = count($n);
    echo "\t$p ($samples samples) - $avg\n";
    $sorted[$p][$taskname] = $avg;
  }
}

foreach ($sorted as $k => $v) {
  echo $k."\n";
  arsort($v);
  foreach ($v as $tasks => $avgs) {
    echo "\t$tasks = $avgs\n";
  }
}
?>
