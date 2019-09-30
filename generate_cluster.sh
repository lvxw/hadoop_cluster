#!/bin/bash
###############################################################################
#Script:        generate_cluster.sh
#Author:        吕学文<2622478542@qq.com>
#Date:          2019-09-23
#Description:
#Usage:         generate_cluster
#Jira:
###############################################################################

function setEnv(){
    cd `cd $(dirname $0) && pwd`

    if [[ $# -eq 0 ]]
    then
       echo 'You can enter the number of nodes'
       echo 'Because you did not enter the number of nodes, we used the default value of 3'
       hostCount=3
    else
       if [[ $1 -le 3 ]]
       then
            echo 'The number of nodes must be greater than or equal to 3. so we use 3'
            hostCount=3
       else
            hostCount=$1
       fi
    fi

    base_dir=`pwd`
    ipPrefix=172.23.16
}

function init(){
    if [[ ! -e /root/.initSuccess ]]
    then
        chmod 755 ${base_dir}/scripts/base_mechine_config.sh
        dos2unix  ${base_dir}/scripts/base_mechine_config.sh
        ${base_dir}/scripts/base_mechine_config.sh
    fi

    dos2unix scripts/* hadoop/conf/*
    chmod 755 scripts/* hadoop/conf/*.sh
    sed -i "s/hostCount=.*/hostCount=${hostCount}/g" ${base_dir}/scripts/xcall.sh
    sed -i "s/hostCount=.*/hostCount=${hostCount}/g" ${base_dir}/scripts/xsync.sh
    cp -f scripts/vm01_clear_docker.sh  scripts/xcall.sh scripts/xsync.sh /usr/local/bin

    echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts
    echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts
    echo "" >> /etc/hosts
    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        ip=${ipPrefix}.$(($x+1))
        echo "${ip}    ${hostName}" >> /etc/hosts
    done

    rm -rf /root/.ssh
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''

    source /etc/profile
}

function cleanWork(){
  /usr/local/bin/vm01_clear_docker.sh
}

function createHadoopBaseImage(){
    docker build -t hadoop-base:v1 .
    wait
}

function executeNodesInit(){
    docker network create -d bridge --subnet ${ipPrefix}.0/24 --gateway ${ipPrefix}.1 cluster
    wait

    docker run --privileged --network=cluster --ip=${ipPrefix}.2 --name hadoop01 -itd  \
            -p 2181:2181 -p 50070:50070 -p 50075:50075 -p 19888:19888 -p 9000:9000 -p 8088:8088 -p 8042:8042 \
            -v ${base_dir}/hadoop/conf:/usr/local/hadoop/etc/hadoop -v ${base_dir}/zookeeper/conf:/usr/local/zookeeper/conf  \
            hadoop-base:v1 /usr/sbin/init
    wait

    for x in `seq 2 ${hostCount}`
    do
        hostName=hadoop0${x}
        ip=${ipPrefix}.$(($x+1))
        docker run --privileged --network=cluster --ip=${ip} --name ${hostName} -itd  \
            -v ${base_dir}/hadoop/conf:/usr/local/hadoop/etc/hadoop -v ${base_dir}/zookeeper/conf:/usr/local/zookeeper/conf  \
            hadoop-base:v1 /usr/sbin/init
        wait
    done

    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        docker exec -it ${hostName} \
            systemctl start sshd
        wait
    done

    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        docker exec -it ${hostName} \
            ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''
        wait
    done

    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        sshpass -p cluster ssh-copy-id -i ~/.ssh/id_rsa.pub root@${hostName} -o StrictHostKeyChecking=no
        ssh -o StrictHostKeyChecking=no ${hostName} hostnamectl set-hostname ${hostName}
    done

    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        ip=${ipPrefix}.$(($x+1))
        docker exec -it ${hostName} \
            /usr/local/bin/node_config.sh ${x}  ${hostCount} ${ipPrefix}
        wait
    done
}


function startZookeeperCluster(){
    cp -f zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg
    echo "" >> zookeeper/conf/zoo.cfg
    echo "dataLogDir=/data/bigdata/zookeeper/log" >> zookeeper/conf/zoo.cfg
    echo "dataDir=/data/bigdata/zookeeper/data" >> zookeeper/conf/zoo.cfg
    echo "" >> zookeeper/conf/zoo.cfg
    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        echo "server.${x}=${hostName}:2888:3888" >> zookeeper/conf/zoo.cfg
    done

    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        ip=${ipPrefix}.$(($x+1))
        docker exec -it ${hostName} \
            /usr/local/zookeeper/bin/zkServer.sh start
        wait
    done
}

function startHadoopCluster(){
    rm -rf ${base_dir}/hadoop/conf/slaves
    for x in `seq 1 ${hostCount}`
    do
        hostName=hadoop0${x}
        echo ${hostName} >>  ${base_dir}/hadoop/conf/slaves
    done

    docker exec -it  hadoop01  /usr/local/hadoop/bin/hdfs  namenode -format
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

    ssh -o StrictHostKeyChecking=no hadoop01 "source /etc/profile && echo 'hello world' > 1.txt && hdfs dfs -mkdir -p /tmp/input && hdfs dfs -put 1.txt /tmp/input"
    ssh -o StrictHostKeyChecking=no hadoop01 "source /etc/profile && hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.7.jar  wordcount /tmp/input/ /tmp/output"
    ssh -o StrictHostKeyChecking=no hadoop01 "source /etc/profile && hdfs dfs -cat /tmp/output/*"
}

setEnv $*
init
cleanWork
createHadoopBaseImage
executeNodesInit
startZookeeperCluster
startHadoopCluster
