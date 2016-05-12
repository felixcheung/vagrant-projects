#!/bin/bash

echo "== start node $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

ISTRUSTY=`lsb_release -a | grep -e "14.04"`

set -xe

# machine config
sudo sysctl -w vm.swappiness=0
echo never > /sys/kernel/mm/transparent_hugepage/defrag

sudo apt-get update
# sudo apt-get -y upgrade
# sudo apt-get install wget

sudo apt-get -y install unzip

# JDK
if [ -n "${ISTRUSTY// }" ]; then
  # Trusty Tahr does not have JDK 8 support https://bugs.launchpad.net/trusty-backports/+bug/1368094
  sudo apt-get -y install openjdk-7-jdk
else
  sudo apt-get -y install openjdk-8-jdk
fi
java -version
javac -version

# python
sudo apt-get -y install python-pip
sudo apt-get -y install python-matplotlib
sudo apt-get -y install python-dev

# Spark
# To change Spark version, change SPARKVER to the right distribution package
SPARKVER=1.6.1
SPARKVER_SHORT=1.6
HADOOP_VERSION=2.6.0
HADOOP_VERSION_SHORT=2.6
cp /vagrant/apache-mirror-selector.py ~/
pushd /opt
if [ ! -f /vagrant/spark-$SPARKVER-bin-hadoop$HADOOP_VERSION_SHORT.tgz ]; then
  echo "downloading Spark ${SPARKVER}..."
  sudo wget -q `python ~/apache-mirror-selector.py http://www.apache.org/dyn/closer.cgi?path=spark/spark-$SPARKVER/spark-$SPARKVER-bin-hadoop$HADOOP_VERSION_SHORT.tgz`
  cp ./spark-$SPARKVER-bin-hadoop$HADOOP_VERSION_SHORT.tgz /vagrant/  # save it for the next time
else
  sudo cp /vagrant/spark-$SPARKVER-bin-hadoop$HADOOP_VERSION_SHORT.tgz ./
fi
sudo tar -xzf spark-*
sudo rm -f spark-*.tgz
cd spark-*
SPARKHOME=$(pwd)
echo '# set SPARK_HOME and PATH' >> /etc/profile.d/spark.sh
echo "export SPARK_HOME=${SPARKHOME}" >> /etc/profile.d/spark.sh
echo 'export PATH=$SPARK_HOME/bin:$PATH' >> /etc/profile.d/spark.sh
export SPARK_HOME=$SPARKHOME
export PATH=$SPARK_HOME/bin:$PATH
echo "SPARK_HOME=${SPARK_HOME}"
popd

# HBase
HBASEVER=1.2.1
pushd /opt
if [ ! -f /vagrant/hbase-$HBASEVER-bin.tar.gz ]; then
  echo "downloading HBase ${HBASEVER}..."
  sudo wget -q `python ~/apache-mirror-selector.py http://www.apache.org/dyn/closer.cgi?path=hbase/$HBASEVER/hbase-$HBASEVER-bin.tar.gz`
  cp ./hbase-$HBASEVER-bin.tar.gz /vagrant/  # save it for the next time
else
  sudo cp /vagrant/hbase-$HBASEVER-bin.tar.gz ./
fi
sudo tar -xzf hbase-*
sudo rm -f hbase-*.gz
popd

# Cassandra
CVER=3.5
pushd /opt
if [ ! -f /vagrant/apache-cassandra-$CVER-bin.tar.gz ]; then
  echo "downloading Cassandra ${CVER}..."
  sudo wget -q `python ~/apache-mirror-selector.py http://www.apache.org/dyn/closer.cgi?path=cassandra/$CVER/apache-cassandra-$CVER-bin.tar.gz`
  cp ./apache-cassandra-$CVER-bin.tar.gz /vagrant/  # save it for the next time
else
  sudo cp /vagrant/apache-cassandra-$CVER-bin.tar.gz ./
fi
sudo tar -xzf apache-cassandra-*
sudo rm -f apache-cassandra-*.gz
sudo mkdir /opt/apache-cassandra-$CVER/data
sudo chown -R vagrant:vagrant /opt/apache-cassandra-$CVER/data
# Enable UDF
sed -i 's/enable_user_defined_functions: false/enable_user_defined_functions: true/' /opt/apache-cassandra-$CVER/conf/cassandra.yaml
popd

# Zeppelin - we are going to build from source

# Install Maven 3
MAVENVER=3.3.9
pushd /opt
if [ ! -f /vagrant/apache-maven-$MAVENVER-bin.tar.gz ]; then
  echo "downloading Maven ${MAVENVER}..."
  sudo wget -q `python ~/apache-mirror-selector.py http://www.apache.org/dyn/closer.cgi?path=maven/maven-3/$MAVENVER/binaries/apache-maven-$MAVENVER-bin.tar.gz`
  cp ./apache-maven-$MAVENVER-bin.tar.gz /vagrant/  # save it for the next time
else
  sudo cp /vagrant/apache-maven-$MAVENVER-bin.tar.gz ./
fi
sudo tar -xzf apache-maven-*
sudo rm -f apache-maven-*.gz
ln -s /opt/apache-maven-$MAVENVER/bin/mvn /usr/bin/mvn
popd

# Install dependencies
apt-get install -y git vim emacs nodejs npm
ln -s /usr/bin/nodejs /usr/bin/node
npm update -g npm
npm install -g grunt-cli
npm install -g grunt
npm install -g bower

# Clone and build Zeppelin
pushd /opt
git clone https://github.com/felixcheung/incubator-zeppelin.git --branch abdc16 --depth 1
pushd incubator-zeppelin
mvn clean install -DskipTests "-Dspark.version=$SPARKVER" "-Dhadoop.version=$HADOOP_VERSION" -Pyarn -Phadoop-$HADOOP_VERSION_SHORT -Pspark-$SPARKVER_SHORT -Ppyspark -Dhbase.hbase.version=$HBASEVER -Dhbase.hadoop.version=$HADOOP_VERSION
popd
popd
# Create the conf/interpreter.json file for the first time
/opt/incubator-zeppelin/bin/zeppelin-daemon.sh start
sleep 10s
/opt/incubator-zeppelin/bin/zeppelin-daemon.sh stop
# Change settings, HBASE home directory, restart
sed -i "s#\"hbase.home\": \"/usr/lib/hbase/\"#\"hbase.home\": \"/opt/hbase-${HBASEVER}/\"#" /opt/incubator-zeppelin/conf/interpreter.json

cat > /lib/systemd/system/zeppelin.service <<EOF
[Unit]
Description=Apache Zeppelin

[Service]
Environment='SPARK_HOME=/opt/spark-1.6.1-bin-hadoop2.6'
ExecStart=/opt/incubator-zeppelin/bin/zeppelin-daemon.sh upstart
Restart=on-failure
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
sudo service zeppelin start

# Start HBase
# set JAVA_HOME
echo '# set JAVA_HOME' >> /etc/profile.d/java.sh
echo "export JAVA_HOME=/usr" >> /etc/profile.d/java.sh
export JAVA_HOME=/usr
/opt/hbase-$HBASEVER/bin/start-hbase.sh

# Start Cassandra
JDKVER=`java -version 2>&1 | grep -e "1.7"` || true
if [ -n "${JDKVER// }" ]; then
  echo "Cassandra 3.x requires JDK 8 to run"
else
  sudo -u vagrant sh /opt/apache-cassandra-$CVER/bin/cassandra &
fi

set +xe

echo "Ready - open http://localhost:8080"
echo "== end node $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
