#!/bin/bash

echo "== start node $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

# machine config
sudo sysctl -w vm.swappiness=0
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag

sudo yum -y install wget

# plaform - Python 2.7
# Python 2.7
sudo yum -y groupinstall "Development tools"
sudo yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel
pushd /opt
sudo wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tar.xz -nv
sudo tar xf Python-2.7.?.tar.xz
sudo rm -f Python-2.7.?.tar.xz
# pushd doesn't work with Python-2.7.?
pushd Python-2.7.9
sudo ./configure --prefix=/usr/local
sudo make
sudo make altinstall
popd
popd

sudo /usr/local/bin/python2.7 -m ensurepip

sudo yum -y install epel-release

# JDK
# 1.7.0_67
sudo wget -q --no-check-certificate --no-cookies - --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/7u67-b01/jdk-7u67-linux-x64.rpm" -O /tmp/jdk-7u67-linux-x64.rpm
sudo rpm -Uvh /tmp/jdk-7u67-linux-x64.rpm

# configure it on the system using the alternatives command. This is in order to tell the system what are the default commands for JAVA
sudo alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_67/jre/bin/java 20000
sudo alternatives --install /usr/bin/jar jar /usr/java/jdk1.7.0_67/bin/jar 20000
sudo alternatives --install /usr/bin/javac javac /usr/java/jdk1.7.0_67/bin/javac 20000
sudo alternatives --install /usr/bin/javaws javaws /usr/java/jdk1.7.0_67/jre/bin/javaws 20000
sudo alternatives --set java /usr/java/jdk1.7.0_67/jre/bin/java
sudo alternatives --set javaws /usr/java/jdk1.7.0_67/jre/bin/javaws
sudo alternatives --set javac /usr/java/jdk1.7.0_67/bin/javac
sudo alternatives --set jar /usr/java/jdk1.7.0_67/bin/jar

sudo rm -f /tmp/jdk-7u67-linux-x64.rpm

ls -lA /etc/alternatives/ | grep java
java -version
javac -version

echo '' >> /etc/profile
echo '# set JAVA_HOME' >> /etc/profile
echo 'export JAVA_HOME=/usr/java/jdk1.7.0_67' >> /etc/profile
export JAVA_HOME=/usr/java/jdk1.7.0_67
echo "JAVA_HOME=${JAVA_HOME}"

# To change Spark version, change SPARKVER to the right distribution package

# Spark
SPARKVER=1.3.0 #1.2.1
pushd /opt
sudo cp /vagrant/spark-$SPARKVER* ./
sudo tar -xzf spark-*
sudo rm -f spark-*.tgz
cd spark-*
SPARKHOME=$(pwd)
echo '' >> /etc/profile
echo '# set SPARK_HOME and PATH' >> /etc/profile
echo "export SPARK_HOME=${SPARKHOME}" >> /etc/profile
echo 'export PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH' >> /etc/profile
export SPARK_HOME=$SPARKHOME
export PATH=$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH
echo "SPARK_HOME=${SPARK_HOME}"
popd

echo "== end node $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
