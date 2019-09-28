#!/bin/bash

function setEnv(){
    cd `cd $(dirname $0) && pwd`
    base_dir=`pwd`
    nodeNum=$1
    hostCount=$2
    ipPrefix=$3
    source /etc/profile
}

function addHosts(){
    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        ip=${ipPrefix}.$(($x+1))
        echo "${ip} ${hostName}" >> /etc/hosts;
    wait
    done

}

function copySshKey(){
    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        sshpass -p cluster ssh-copy-id -i ~/.ssh/id_rsa.pub root@${hostName} -o StrictHostKeyChecking=no
    wait
    done
}

function setZookeeperCluster(){
    echo ${nodeNum} >> /data/bigdata/zookeeper/data/myid
}

setEnv $*
addHosts
copySshKey
setZookeeperCluster

