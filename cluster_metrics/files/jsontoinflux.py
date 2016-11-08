#!/usr/bin/env python
# Copyright 2016, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This script converts JSON to Influx Line Protocol
# Since JSON input is deprecatd from InfluxDN in favor
# of Influx Line Protocol


def jsontoinflux(measurement, tagkeys, measurements):
    out = measurement
    for key in tagkeys:
        out = out + ',' + key + '=' + tagkeys[key]
    out = out + ' '
    i = 0
    for key in measurements:
        if i == 0:
            out = out + key + '=' + str(measurements[key])
        else:
            out = out + ',' + key + '=' + str(measurements[key])
        i = i + 1
    return out
