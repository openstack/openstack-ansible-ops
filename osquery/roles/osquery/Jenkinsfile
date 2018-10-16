// Work in progress

node {

    try{
        currentBuild.result = "SUCCESS"
        def workspace = pwd()
        def directory = "kbrebanov.osquery"

        stage 'Clean Workspace'
            deleteDir()

        stage("Download source and capture commit ID") {
            sh "mkdir $directory"
            dir("$directory") {
                checkout scm
                // Get the commit ID
                sh 'git rev-parse --verify HEAD > GIT_COMMIT'
                git_commit = readFile('GIT_COMMIT').take(7)
                echo "Current commit ID: ${git_commit}"
            }
        }

        dir("$directory") {

            stage("Get dependencies"){
                sh "sh -x get-dependencies.sh"
            }
            stage("Build and verify 1"){
                defaultplatform = sh (
                    script: '''#!/bin/bash
kitchen list | awk "!/Instance/ {print \\$1; exit}"
                        ''',
                    returnStdout: true
                    ).trim()
                echo "default platform: ${defaultplatform}"

                sh "kitchen test ${defaultplatform}"
                // must keep instance for security testing after
                //sh "kitchen verify ${defaultplatform}"
            }

            stage("Build and verify all platforms"){
                sh "kitchen test"
            }

            stage("Cleanup if no errors"){
                sh "kitchen destroy"
            }

        }

    }

    catch(err) {
        currentBuild.result = "FAILURE"
        throw err
    }
}
