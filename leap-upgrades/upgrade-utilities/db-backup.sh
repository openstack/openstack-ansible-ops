#!/usr/bin/env bash
# Copyright 2017, Rackspace US, Inc.
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
# Set the full path to the MYSQL commands

## Shell Opts ----------------------------------------------------------------
set -e -u -v

MYSQLDUMP=$(which mysqldump)
MYSQL=$(which mysql)
TAR=$(which tar)

# If a my.cnf file is not found, force the user to enter the mysql root password
if [ ! -f "${HOME}/.my.cnf" ];then
    echo -e "No \".my.cnf\" in \"${HOME}\". You are going to need the MySQL Root password."
    MYSQL="${MYSQL} -u root -p"
    MYSQLDUMP="${MYSQLDUMP} -u root -p"
fi

# return a list of databases to backup
DB_NAMES=$(${MYSQL} -Bse "show databases;" | grep -v -e "schema" -e "mysql")

# Set the backup directory
DB_BACKUP_DIR=${DB_BACKUP_DIR:-"/var/backup"}

# Go to the Database Backup Dir
pushd ${DB_BACKUP_DIR}
    # Backup all databases individually
    for db in ${DB_NAMES};do
        echo "Performing a Database Backup on ${db}"
        if [ -f "${db}.sql" ];then
            echo "Moving old Database Backup to ${db}.sql.old"
            mv ${db}.sql ${db}.backup-$(date +%y%m%d-%H%M%S).sql
        fi
        ${MYSQLDUMP} ${db} > ${db}.sql
    done
    # Create an archive of the new backup.
    echo "Creating an Archive of the Database Backup Directory"
    if [ -f "OpenstackDatabases.tgz" ];then
        echo "Moving old Database archive to OpenstackDatabases.tgz.old"
        mv OpenstackDatabases.tgz OpenstackDatabases.tgz.old
    fi
    ${TAR} -cvzf OpenstackDatabases-$(date +%y%m%d).tgz ${DB_BACKUP_DIR}/*.sql
    echo "Done."
popd

exit 0
