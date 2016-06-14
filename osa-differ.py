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
"""Analyzes the differences between two OpenStack-Ansible commits."""

import argparse
import pygithub3
import requests
import sys
from urlparse import urlparse
import yaml


def get_arguments():
    """Setup argument Parsing."""
    parser = argparse.ArgumentParser(
        usage='%(prog)s',
        description='OpenStack-Ansible Release Diff Generator',
        epilog='Licensed "Apache 2.0"')
    parser.add_argument(
        'old_commit',
        action='store',
        nargs=1,
        help="Git SHA of the older commit",
    )
    parser.add_argument(
        'new_commit',
        action='store',
        nargs=1,
        help="Git SHA of the newer commit",
    )
    return vars(parser.parse_args())


def short_commit(commit_sha):
    """Return a short commit hash string."""
    return commit_sha[0:8]


def get_commit_data(commit_sha):
    """Get information about a commit from Github."""
    commit_data = gh.repos.commits.get(user='openstack',
                                       repo='openstack-ansible',
                                       sha=commit_sha)
    return commit_data


def get_commit_message(commit_sha):
    """Get the first line of the commit message for a particular commit."""
    commit_data = get_commit_data(commit_sha)
    commit_message = commit_data.commit.message.splitlines()[0]
    return commit_message


def get_project_names(project_dict):
    """Get project names from the list of project variables."""
    return [x[:-9] for x in project_dict if x.endswith('git_repo')]


def get_projects(yaml_urls):
    """Get all projects from multiple YAML files."""
    yaml_parsed = []
    for yaml_url in yaml_urls:
        r = requests.get(yaml_url)
        yaml_parsed.append(yaml.load(r.text))
    merged_dicts = {k: v for d in yaml_parsed for k, v in d.items()}
    return merged_dicts


if __name__ == "__main__":

    # Set up some initial variables
    gh = pygithub3.Github()
    args = get_arguments()
    report = ''

    # Store our arguments into variables to make things easier.
    old_commit = args['old_commit'][0]
    new_commit = args['new_commit'][0]

    # Get the first line of the commit message in the older commit
    try:
        old_commit_message = get_commit_message(old_commit)
    except pygithub3.exceptions.NotFound:
        print("The old commit SHA was not found: {0}".format(old_commit))
        sys.exit(1)

    # Get the first line of the commit message in the newer commit
    try:
        new_commit_message = get_commit_message(new_commit)
    except pygithub3.exceptions.NotFound:
        print("The new commit SHA was not found: {0}".format(new_commit))
        sys.exit(1)

    report_header = """
OpenStack-Ansible Release Diff Generator
-------------------------------------------------------------------------------
Old commit: {0} {1}
New commit: {2} {3}
-------------------------------------------------------------------------------
""".format(
        short_commit(old_commit),
        old_commit_message,
        short_commit(new_commit),
        new_commit_message
    )
    report += report_header

    # Set up the URLs for the YAML files which contain the projects used by
    # OpenStack-Ansible.
    base_url = 'https://raw.githubusercontent.com/openstack/' \
               'openstack-ansible/{0}/{1}'
    repo_files = [
        'playbooks/defaults/repo_packages/openstack_services.yml',
        'playbooks/defaults/repo_packages/openstack_other.yml'
    ]

    # Get all of the OpenStack projects that OpenStack-Ansible builds
    old_commit_yaml_urls = [base_url.format(old_commit, x) for x in repo_files]
    old_commit_projects = get_projects(old_commit_yaml_urls)
    new_commit_yaml_urls = [base_url.format(new_commit, x) for x in repo_files]
    new_commit_projects = get_projects(new_commit_yaml_urls)

    # Get the bare project names from the YAML data we retrieved
    old_commit_project_names = get_project_names(old_commit_projects)
    new_commit_project_names = get_project_names(new_commit_projects)

    # Loop through each project found in the latest commit
    for project in sorted(new_commit_project_names):

        # Find the git repo URL from the new commit
        git_repo = new_commit_projects["{0}_git_repo".format(project)]
        _, user, project_repo_name = urlparse(git_repo).path.split('/')

        # Determine the latest sha for this project
        project_sha = "{0}_git_install_branch".format(project)
        latest_sha = new_commit_projects[project_sha]

        # If this module didn't exist in the old OpenStack-Ansible commit,
        # just skip it for now.
        try:
            project_sha = "{0}_git_install_branch".format(project)
            older_sha = old_commit_projects[project_sha]
        except:
            continue

        # Compare the two commits in the project's repository to see what
        # the differences are between them.
        comparison = gh.repos.commits.compare(
            user=user,
            repo=project_repo_name,
            base=older_sha,
            head=latest_sha
        )

        project_header = "________ {0} (commits: {1}) ".format(
            project,
            len(comparison.commits)
        )
        project_header = project_header.ljust(78, '_')
        report += "\n{0}\n".format(project_header)

        if len(comparison.commits) == 0:
            report += "         No changes\n"
            continue

        for commit in comparison.commits:
            commit_line = commit.commit['message'].splitlines()[0]

            # Skip the merge messages since they're not terribly helpful
            if commit_line.startswith('Merge "'):
                continue

            report += "{0} {1}\n".format(commit.sha[0:8], commit_line)

    print(report)
