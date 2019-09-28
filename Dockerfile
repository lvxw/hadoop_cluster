FROM docker.io/centos

RUN echo "cluster" | passwd --stdin root
WORKDIR /usr/local

RUN yum install -y which wget sshpass net-tools openssh* java-1.8.0-openjdk-devel.x86_64

RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz; \
    wget https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz; \
    tar zxvf zookeeper-3.4.14.tar.gz; \
    tar zxvf hadoop-2.7.7.tar.gz; \
    ln -s zookeeper-3.4.14 zookeeper; \
    ln -s hadoop-2.7.7 hadoop; \
    chown -R root:root zookeeper-3.4.14; \
    chown -R root:root hadoop-2.7.7; \
    rm -rf hadoop/etc/hadoop/*; \
    rm -rf zookeeper/conf/*; \
    rm -rf zookeeper-3.4.14.tar.gz; \
    rm -rf hadoop-2.7.7.tar.gz

RUN echo "" >> /etc/profile; \
    echo 'JAVA_HOME=/usr/lib/jvm/java' >> /etc/profile; \
    echo 'HADOOP_HOME=/usr/local/hadoop' >> /etc/profile; \
    echo 'ZOOKEEPER_HOME=/usr/local/zookeeper'>> /etc/profile; \
    echo 'PATH=${PATH}:${JAVA_HOME}/bin:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${ZOOKEEPER_HOME}/bin' >> /etc/profile; \
    source /etc/profile

RUN mkdir -p /data/bigdata/hadoop/tmp \
    /data/bigdata/hadoop/dfs/data \
    /data/bigdata/hadoop/dfs/name \
    /data/bigdata/hadoop/log \
    /data/bigdata/zookeeper/data \
    /data/bigdata/zookeeper/log; \
    chown -R root:root /data/bigdata

COPY scripts/node_config.sh /usr/local/bin
COPY scripts/xcall.sh /usr/local/bin
COPY scripts/xsync.sh /usr/local/bin

CMD /bin/bash


