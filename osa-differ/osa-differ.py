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
import jinja2
import logging
import pygithub3
import os
import requests
import sys
from urlparse import urlparse
import yaml


def get_arguments():
    """Setup argument Parsing."""
    description = """OpenStack-Ansible Release Diff Generator
----------------------------------------

Finds changes in OpenStack projects and OpenStack-Ansible roles between two
commits in OpenStack-Ansible.

Tip: Set the GITHUB_TOKEN environment variable to provide a GitHub API token
and get higher API limits.

"""

    parser = argparse.ArgumentParser(
        usage='%(prog)s',
        description=description,
        epilog='Licensed "Apache 2.0"',
        formatter_class=argparse.RawTextHelpFormatter
    )
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
    parser.add_argument(
        '-d', '--debug',
        action='store_true',
        help="Enable debug output",
    )
    display_opts = parser.add_mutually_exclusive_group()
    display_opts.add_argument(
        "--projects-only",
        action="store_true",
        help="Only display commits for OpenStack projects"
    )
    display_opts.add_argument(
        "--roles-only",
        action="store_true",
        help="Only display commits for OpenStack-Ansible roles"
    )

    return vars(parser.parse_args())


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


def get_projects(base_url, commit):
    """Get all projects from multiple YAML files."""
    # Assemble the full URLs to our YAML files that contain our OpenStack
    # projects' details.
    logger.debug("Retrieving OSA project list at commit {0}".format(commit))
    repo_files = [
        'playbooks/defaults/repo_packages/openstack_services.yml',
        'playbooks/defaults/repo_packages/openstack_other.yml'
    ]
    yaml_urls = [base_url.format(commit, x) for x in repo_files]

    # Loop through both YAML files and merge the data into one dictionary.
    yaml_parsed = []
    for yaml_url in yaml_urls:
        r = requests.get(yaml_url)
        yaml_parsed.append(yaml.load(r.text))
    merged_dicts = {k: v for d in yaml_parsed for k, v in d.items()}

    return merged_dicts


def render_commit_template(user, repo, old_commit, new_commit, extra_vars={},
                           template_file='repo_details.j2'):
    """Render a template to generate RST content for commits."""
    global gh
    global jinja_env

    # Compare the two commits in the project's repository to see what
    # the differences are between them.
    if old_commit == new_commit:
        logger.debug("Same starting and ending commit ({0}) for {1}/{2} - "
                     "nothing to compare".format(short_commit(old_commit),
                                                 user, repo))
        commits = []
    else:
        logger.debug("Retrieving commits between {2} and {3} in "
                     "{0}/{1}".format(user, repo, short_commit(old_commit),
                                      short_commit(new_commit)))
        comparison = gh.repos.commits.compare(
            user=user,
            repo=repo,
            base=old_commit,
            head=new_commit
        )
        commits = comparison.commits

    # Render the jinja2 template
    rendered_template = jinja_env.get_template(template_file).render(
        repo=repo,
        commits=commits,
        latest_sha=short_commit(new_commit),
        older_sha=short_commit(old_commit),
        extra_vars=extra_vars
    )

    return rendered_template


def short_commit(commit_sha):
    """Return a short commit hash string."""
    return commit_sha[0:8]

if __name__ == "__main__":

    # Get our arguments from the command line
    args = get_arguments()

    # Configure logging
    log_format = "%(asctime)s - %(levelname)s - %(message)s"
    logging.basicConfig(level=logging.WARNING, format=log_format)
    logger = logging.getLogger(__name__)
    if 'debug' in args and args['debug']:
        logger.setLevel(logging.DEBUG)

    # Configure our connection to GitHub
    github_token = os.environ.get('GITHUB_TOKEN')
    if github_token is None:
        logger.warning("Provide a GitHub API token via the GITHUB_TOKEN "
                       "environment variable to avoid exceeding GitHub API "
                       "limits.")
    gh = pygithub3.Github(token=github_token)

    # Load our Jinja templates
    TEMPLATE_DIR = "{0}/templates".format(
        os.path.dirname(os.path.abspath(__file__))
    )
    jinja_env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(TEMPLATE_DIR),
        trim_blocks=True
    )

    # Store our arguments into variables to make things easier.
    old_commit = args['old_commit'][0]
    new_commit = args['new_commit'][0]

    # Get the first line of the commit message in the older commit
    logger.debug("Retrieving commit message from the older OSA commit")
    try:
        old_commit_message = get_commit_message(old_commit)
    except pygithub3.exceptions.NotFound:
        print("The old commit SHA was not found: {0}".format(old_commit))
        sys.exit(1)

    # Get the first line of the commit message in the newer commit
    logger.debug("Retrieving commit message from the newer OSA commit")
    try:
        new_commit_message = get_commit_message(new_commit)
    except pygithub3.exceptions.NotFound:
        print("The new commit SHA was not found: {0}".format(new_commit))
        sys.exit(1)

    # Generate header and initial report for OpenStack-Ansible itself
    logger.debug("Generating initial report header for OpenStack-Ansible")
    report = render_commit_template(
        user='openstack',
        repo='openstack-ansible',
        old_commit=old_commit,
        new_commit=new_commit,
        template_file='header.j2',
        extra_vars={
            'roles_only': args['roles_only'],
            'projects_only': args['projects_only']
        }
    )

    # Add a horizontal line to report after the OpenStack-Ansible commits.
    report += "----\n"

    # Set up the base url that allows us to retrieve data from
    # OpenStack-Ansible at a particular commit.
    base_url = 'https://raw.githubusercontent.com/openstack/' \
               'openstack-ansible/{0}/{1}'

    if args['roles_only']:
        # Short circuit here and don't get any projects since the user only
        # wants to see role commits.
        old_commit_projects = []
        new_commit_projects = []
    else:
        report += "\nOpenStack Projects\n------------------\n"

        # Get all of the OpenStack projects that OpenStack-Ansible builds
        old_commit_projects = get_projects(base_url, old_commit)
        new_commit_projects = get_projects(base_url, new_commit)

    # Get the bare project names from the YAML data we retrieved
    old_commit_project_names = get_project_names(old_commit_projects)
    new_commit_project_names = get_project_names(new_commit_projects)

    # Loop through each OpenStack project found in the latest commit
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

        # Render a template showing the commits in this project's repository.
        report += render_commit_template(
            user=user,
            repo=project_repo_name,
            old_commit=older_sha,
            new_commit=latest_sha
        )

    # Set up the URLs for the old and new ansible-role-requirements.yml
    old_role_url = base_url.format(old_commit, 'ansible-role-requirements.yml')
    new_role_url = base_url.format(new_commit, 'ansible-role-requirements.yml')

    if args['projects_only']:
        # Short circuit here and don't get any roles since the user only wants
        # to see OpenStack project commits.
        old_role_yaml = {}
        new_role_yaml = {}
    else:
        report += "\nOpenStack-Ansible Roles\n-----------------------\n"

        # Retrieve the roles YAML
        old_role_yaml = yaml.load(requests.get(old_role_url).text)
        new_role_yaml = yaml.load(requests.get(new_role_url).text)

    # Loop through each OpenStack-Ansible role found in the latest commit
    for role in new_role_yaml:

        # Get the user and repo name that we will need to use with GitHub
        _, user, role_repo_name = urlparse(role['src']).path.split('/')

        # Determine the older and newer SHA for this role
        latest_sha = role['version']
        try:
            older_sha = next(x['version'] for x in old_role_yaml
                             if x['name'] == role['name'])
        except StopIteration:
            older_sha = latest_sha

        # Render a template showing the commits in this role's repository.
        report += render_commit_template(
            user=user,
            repo=role_repo_name,
            old_commit=older_sha,
            new_commit=latest_sha
        )

    print(report)
