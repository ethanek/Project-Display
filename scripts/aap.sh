#! /bin/bash

# Please set the following env before you run the script:
#   AAP_HOST      = 
#   AAP_USERNAME  =
#   AAP_PASSWORD  =
set -e

api_prefix=/api/v2
path_list_job="$api_prefix/job_templates/"

function printErr() {
    err="\nInvalid input, Please enter the correct command.\n\nfor example: ls, launch\n"
    echo -e $err
}

function callAAP2API() {
    method=$1
    path=$2
    data=$3

    if [ "$method" = "GET" ]
    then
        curl -X $method -k -u "$AAP_USERNAME:$AAP_PASSWORD" -H "Content-Type: application/json" https://$AAP_HOST$path
    else
        curl -X $method -k -u "$AAP_USERNAME:$AAP_PASSWORD" -d "$data" -H "Content-Type: application/json" https://$AAP_HOST$path
    fi
}

function callListJobAPI() {
    callAAP2API GET $path_list_job
}

function callLaunchAPI() {
    id=$1
    data="{\"extra_vars\": $2 }"
    path_launch="$api_prefix/job_templates/$id/launch/"
    callAAP2API POST $path_launch "$data"
}

function listJobs() {
    callListJobAPI | jq
}

function getJobsIdByName() {
    name=$1
    echo $(callListJobAPI | jq -r ".results[] | select(.name==\"$name\") | .id")
}

function launchJobByName() {
    name=$1
    variable_json=$2
    jobid=$(getJobsIdByName "$name")
    if [ "$jobid" = "" ]
    then
        echo "[error] job not found"
        exit 1
    fi
    callLaunchAPI $jobid "$variable_json"
}


if [ $# -eq 0 ] ; then
    printErr
else
    cmd=$1
    shift
    if [ "$cmd" = "ls" ]
    then
        listJobs
    elif [ "$cmd" = "launch" ]
    then
        launchJobByName "$@"
    else
        printErr
    fi
fi