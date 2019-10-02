#!/bin/bash

hostCount=3

function startNodes(){
    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        docker start ${hostName}
    done
}

function startZookeeperCluster(){
    for x in `seq 1 ${hostCount}`
        do
            hostName=hadoop0${x}
            docker exec -it ${hostName} \
                /usr/local/zookeeper/bin/zkServer.sh start
            wait
    done
}

function startHadoopCluster(){
    docker exec -it  hadoop01  /usr/local/hadoop/sbin/hadoop-daemon.sh  start namenode
    docker exec -it  hadoop01  /usr/local/hadoop/sbin/yarn-daemon.sh  start resourcemanager
    docker exec -it  hadoop01  /usr/local/hadoop/sbin/mr-jobhistory-daemon.sh start historyserver
    docker exec -it  hadoop02  /usr/local/hadoop/sbin/hadoop-daemon.sh  start secondarynamenode
    for x in `seq 1 ${hostCount}`
    do
         hostName=hadoop0${x}
        docker exec -it  ${hostName}  /usr/local/hadoop/sbin/hadoop-daemon.sh  start datanode
        docker exec -it  ${hostName}  /usr/local/hadoop/sbin/yarn-daemon.sh  start nodemanager
    done

    /usr/local/bin/xcall.sh jps
}

startNodes
startZookeeperCluster
startHadoopCluster
