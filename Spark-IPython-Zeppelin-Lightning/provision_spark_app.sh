#!/bin/bash

echo "== start app $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

# [DEMO-only] font, must be installed before matplotlib
sudo cp /vagrant/Humor-Sans-1.0.ttf /usr/share/fonts/
sudo chmod 644 /usr/share/fonts/Humor-Sans-1.0.ttf
sudo fc-cache -fv

# matplotlib on Python2.7
pushd /tmp
sudo wget http://download.savannah.gnu.org/releases/freetype/freetype-2.5.5.tar.gz -nv
sudo tar xzf freetype-*.tar.gz
pushd freetype-*
sudo ./configure --prefix=/usr/local --without-png
sudo make
sudo make install
popd

sudo wget http://downloads.sourceforge.net/project/libpng/libpng16/1.6.16/libpng-1.6.16.tar.gz -nv
sudo tar xzf libpng-*.tar.gz
pushd libpng-*
sudo ./configure --prefix=/usr/local
sudo make
sudo make install
popd

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
sudo /usr/local/bin/python2.7 -m pip install matplotlib --upgrade
popd

# IPython notebook
sudo /usr/local/bin/python2.7 -m pip install "ipython[notebook]"

# Zeppelin
pushd /opt
sudo cp /vagrant/zeppelin-0.5.0-SNAPSHOT.tar.gz ./
sudo tar -xzf zeppelin-0.5.0-SNAPSHOT.tar.gz
sudo rm -f zeppelin-0.5.0-SNAPSHOT.tar.gz
sudo \
PYSPARK_PYTHON=/usr/local/bin/python2.7 \
./zeppelin-0.5.0-SNAPSHOT/bin/zeppelin-daemon.sh start
popd

cd ~

# [DEMO-only] spark-ml-streaming
# numpy, scipy
sudo yum -y install lapack lapack-devel blas blas-devel
sudo /usr/local/bin/python2.7 -m pip install numpy scipy
cp /vagrant/spark-ml-streaming.tar.gz ./
mkdir streamingcluster
pushd streamingcluster
tar -xzf ../spark-ml-streaming.tar.gz
# This will install required Python packages:
# argparse, numpy, scipy, scikit-learn, lightning-python
sudo /usr/local/bin/python2.7 -m pip install -e ./
popd
rm -f spark-ml-streaming.tar.gz

# [DEMO-only] IPython/PySpark
cp /vagrant/ipython-pyspark.py ./

# [DEMO-only] Python packages: Seaborn, Bokeh
sudo /usr/local/bin/python2.7 -m pip install seaborn
sudo /usr/local/bin/python2.7 -m pip install bokeh

# # [DEMO-only] Python package: Word Cloud
sudo /usr/local/bin/python2.7 -m pip install Image
# pip install git+git://github.com/amueller/word_cloud.git - doesn't work - think it's missing Cypthon
wget https://github.com/amueller/word_cloud/archive/master.zip
unzip master.zip
rm -f master.zip
pushd word_cloud-master
sudo /usr/local/bin/python2.7 -m pip install -r requirements.txt
sudo /usr/local/bin/python2.7 setup.py install
popd

# [DEMO-only] JDBC
sudo rpm -Uvh http://yum.postgresql.org/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-1.noarch.rpm
sudo yum install -y postgresql93-jdbc
cp /usr/share/java/postgresql93-jdbc.jar /opt/zeppelin-0.5.0-SNAPSHOT/interpreter/spark/

echo "== end app $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
