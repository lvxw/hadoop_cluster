#!/bin/bash

function clearDockerInfo(){
    docker ps -aq | xargs docker rm -f
    docker rmi hadoop-base:v1
    docker network rm cluster
}

function showDockerInfo(){
    echo '------------------------------------images info-------------------------------------------'
    docker images
    echo ''
    echo ''

    echo '------------------------------------container info-------------------------------------------'
    docker ps -a
    echo ''
    echo ''

    echo '------------------------------------images info-------------------------------------------'
    docker network list
    echo ''
    echo ''
}

clearDockerInfo
showDockerInfo
