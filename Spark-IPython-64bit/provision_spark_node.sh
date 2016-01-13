#!/bin/bash

echo "== start vm provisioning $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

sudo apt-get update && sudo apt-get -y upgrade

# OpenJDK 1.8.0_45
sudo apt-get -y install openjdk-8-jre-headless

# Set JAVA_HOME
java -version
echo '' >> /etc/profile
echo '# set JAVA_HOME' >> /etc/profile
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64' >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
echo "JAVA_HOME=${JAVA_HOME}"

# Spark
pushd ~
echo "Getting Spark..."
cp /vagrant/apache-mirror-selector.py ./
chmod 700 apache-mirror-selector.py
wget -q `./apache-mirror-selector.py http://www.apache.org/dyn/closer.cgi?path=spark/spark-1.5.1/spark-1.5.1-bin-hadoop2.6.tgz`
sudo cp ./spark-1.5.1-bin-hadoop2.6.tgz /opt
pushd /opt
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
rm -f apache-mirror-selector.py
popd

sudo apt-get -y install pkg-config
sudo apt-get -y install python-pip

# matplotlib
# required to get freetype, png
sudo apt-get -y install python-matplotlib

# IPython notebook
sudo apt-get -y install libzmq-dev
# required to get pyzmq
sudo apt-get -y install python-dev
sudo python -m pip install "ipython[notebook]" --upgrade
IPYTHONVER=`ipython -V`
echo "IPython version ${IPYTHONVER}"

# Start IPython notebook
cd ~
cp /vagrant/ipython-pyspark.py ~/
~/ipython-pyspark.py

echo "== end vm provisioning $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
