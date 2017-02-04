# Copyright 2016, Walmart Stores, Inc.
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

'''This script will parse the
openstack-ansible/ansible-role-requirements.yml file, clone any
associated openstack-ansible roles found, and generate a
requirements.yml for each openstack-ansible role.'''

import io
import os
import subprocess
import yaml


# recursive function to determine all role requirements
def resolve_deps(role, rdd):
    aggregate = []
    if rdd.get(role):
        for r in rdd.get(role):
            aggregate += resolve_deps(r, rdd)
        aggregate += rdd[role]
    return aggregate

filename = 'openstack-ansible/ansible-role-requirements.yml'
DEVNULL = open(os.devnull, 'w')

# load the yaml file
with io.open(filename, 'rb') as f:
    roles = yaml.safe_load(f)

role_names = []
role_dict = {}
formatted_dict = {}
role_dep_dict = {}

# convert the list of dicts to a more useful pattern.
for role in roles:
    role_name = role['name']
    role_names.append(role_name)
    role_scm = role.get('scm')
    if role_scm == 'git' and 'openstack-ansible' in role.get('src'):
        role_dict[role_name] = role['src']
        role_dict[role_name + "__version"] = role['version']
    else:
        print("role %s will not be cloned" % role['name'])
    formatted_string = '''- name: %s\n''' % role_name
    fields = ['scm', 'src', 'version']
    for field in fields:
        if role.get(field):
            formatted_string += '''  %s: %s\n''' % (field, role[field])
    formatted_dict[role_name] = formatted_string

for role in role_names:
    if role_dict.get(role):
        # clone or update the roles, and checkout the version
        # specified by the master role requirements

        if not os.path.exists(role):
            subprocess.check_call(["git", "clone", role_dict[
                                  role], role],
                                  stdout=DEVNULL, stderr=subprocess.STDOUT)
            os.chdir(role)
        else:
            os.chdir(role)
            subprocess.check_call(
                ["git", "checkout", "master"],
                stdout=DEVNULL, stderr=subprocess.STDOUT)
            subprocess.check_call(
                ["git", "pull"], stdout=DEVNULL, stderr=subprocess.STDOUT)
        subprocess.check_call(["git", "checkout", role_dict[
                              role + "__version"]],
                              stdout=DEVNULL, stderr=subprocess.STDOUT)
        os.chdir('..')

        requirements_list = []
        # Try to read the dependencies from the role's meta/main.yml
        try:
            with io.open(os.path.join(role, "meta", "main.yml")) as f:
                y = yaml.safe_load(f)
            for dep in y['dependencies']:
                try:
                    dep = dep['role']
                except:
                    pass
                if dep in role_names:
                    requirements_list.append(dep)
                else:
                    print("Unknown dependency found!: %s" % dep)
        except:
            print("Error getting role dependencies for: %s" % role)

        # Add our dependencies to role_dep_dict
        role_dep_dict[role] = requirements_list

# We can close this now.
DEVNULL.close()

# Now, we can generate all dependencies recursively.
for role in role_dep_dict:
    # create a new list to copy the direct dependencies into.
    recursive_list = []
    recursive_list += role_dep_dict[role]

    # recurse through our dependencies
    for r in role_dep_dict[role]:
        recursive_list += resolve_deps(r, role_dep_dict)

    # convert to set to deduplicate the list.
    recursive_list = set(recursive_list)

    # write out requirements.yml
    output_yaml = '---\n'
    for r in sorted(recursive_list):
        output_yaml += formatted_dict[r]
    try:
        with io.open(os.path.join(role, 'requirements.yml'), 'wb') as f:
            f.write(output_yaml)
            f.truncate()
        print("Successfully wrote: %s" %
              os.path.join(role, 'requirements.yml'))
    except:
        print("Error writing requirements.yml for %s" % role)
