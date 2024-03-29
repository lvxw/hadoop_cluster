#!/bin/bash

function setEnv(){
    cd `cd $(dirname $0) && pwd`
    base_dir=`pwd`
}

function init(){
    yum install -y wget
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.bak
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    yum clean all && yum makecache && yum update -y

    yum remove -y docker* && rm -rf /data/docker/lib /data/docker/lib
    yum install -y docker net-tools ntpdate vim gcc gcc-c++ nc unzip zip lzop zlib* dos2unix sshpass
    ntpdate pool.ntp.org && hwclock --systohc
    systemctl stop firewalld && systemctl disable firewalld
    sed  -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config && setenforce 0
    hostnamectl set-hostname vm01

    mkdir -p /data/docker/lib /etc/docker
    sed -i 's/ExecStart=\/usr\/bin\/dockerd-current/ExecStart=\/usr\/bin\/dockerd-current --graph=\/data\/docker\/lib/' /lib/systemd/system/docker.service
    tee /etc/docker/daemon.json <<-'EOF'
    {
      "registry-mirrors": ["https://ltaa1zpv.mirror.aliyuncs.com"]
    }
EOF

    systemctl daemon-reload && systemctl restart docker && systemctl enable docker

    rm -rf /root/.ssh && ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''

    if [[ $? -eq 0 ]]
    then
        touch /root/.initSuccess
    fi

    source /etc/profile
}

function installMysql(){
    yum remove -y mysql*
    find / -name mysql | xargs rm -rf
    wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
    rpm -ivh mysql-community-release-el7-5.noarch.rpm && yum -y install mysql-server
    rm -rf mysql-community-release-el7-5.noarch.rpm

    systemctl stop mysqld
    chown -R root:root /var/lib/mysql
    systemctl start mysqld
    mysql -u root -e " use mysql; update user set password=password('base') where user='root';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'service' WITH GRANT OPTION;"
    systemctl restart mysqld
}

function installRedis(){
    yum remove -y redis
    yum install -y  epel-release redis
    systemctl start redis && systemctl enable redis
    sed -i 's/bind 127.0.0.1/\#bind 127.0.0.1/' /etc/redis.conf
    sed -i 's/protected-mode yes/protected-mode no/' /etc/redis.conf
    sed -i 's/daemonize no/daemonize yes/' /etc/redis.conf
    systemctl restart redis
}

function installMongoDb(){
    echo
}

setEnv
init
installMysql
installRedis
installMongoDb
