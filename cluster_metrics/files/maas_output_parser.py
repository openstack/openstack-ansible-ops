#!/usr/bin/env python
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
# This script calls the cinder API and gathers the volume group capacity
# information and outputs to Influx Protocol Line format

import argparse
import subprocess


def parse_output(service, command):
    output = subprocess.check_output('python {}'.format(command),
                                     shell=True,
                                     stderr=subprocess.PIPE)
    new_lines = []
    for line in output.splitlines():
        if 'status ok' not in line:
            line = line.replace('metric', service)
            line_parts = line.split(' ')
            unit = 'none'
            if len(line_parts) >= 5:
                unit = line_parts[len(line_parts) - 1:][0]
            line = '{} {}={},unit="{}"'.format(line_parts[0],
                                               line_parts[1],
                                               line_parts[3],
                                               unit)
            new_lines.append(line)

    return '\n'.join(new_lines)


def main(args):
    print (parse_output(args.service, args.command))

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="MaaS output parser")
    parser.add_argument('service',
                        type=str,
                        help="openstack maas service name e.g: nova_api")
    parser.add_argument('command',
                        type=str,
                        help="Python script path with posargs if needed")
    args = parser.parse_args()
    main(args)
