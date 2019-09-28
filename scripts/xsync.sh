#!/bin/bash

hostCount=3

for x in `seq 1 ${hostCount}`
do
    hostName=hadoop0${x}
    echo "----------------------------${hostName}------------------------------------"
    rsync -avz "$1" ${hostName}:"${2}"
    echo ""
done
