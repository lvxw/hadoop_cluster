#!/bin/bash

hostCount=3

for x in `seq 1 ${hostCount}`
do
    hostName=hadoop0${x}
    echo "----------------------------${hostName}------------------------------------"
    ssh -o StrictHostKeyChecking=no ${hostName} "source /etc/profile;$*"
    echo ""
done
