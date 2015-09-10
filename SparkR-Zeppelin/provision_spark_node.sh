#!/bin/bash

echo "== start node $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

# machine config
sudo sysctl -w vm.swappiness=0
echo never > /sys/kernel/mm/transparent_hugepage/defrag

# add CRAN mirror
echo '' >> /etc/apt/sources.list
echo 'deb http://cran.cnr.Berkeley.edu/bin/linux/ubuntu vivid/' >> /etc/apt/sources.list
gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install wget

# R
# this takes a while...
sudo apt-get -y install r-base
R --version

# JDK
sudo apt-get -y install openjdk-8-jdk
java -version
javac -version

# Spark
# To change Spark version, change SPARKVER to the right distribution package
SPARKVER=1.5.0
cp /vagrant/apache-mirror-selector.py ~/
pushd /opt
if [ ! -f /vagrant/spark-$SPARKVER-bin-hadoop2.6.tgz ]; then
  echo "downloading Spark ${SPARKVER}..."
  sudo wget -q `python ~/apache-mirror-selector.py http://www.apache.org/dyn/closer.cgi?path=spark/spark-$SPARKVER/spark-$SPARKVER-bin-hadoop2.6.tgz`
  cp ./spark-$SPARKVER-bin-hadoop2.6.tgz /vagrant/  # save it for the next time
else
  sudo cp /vagrant/spark-$SPARKVER-bin-hadoop2.6.tgz ./
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

# SparkR, installing it from within R is optional - it can otherwise be loaded with lib.loc
pushd $SPARKHOME/R/lib/SparkR
sudo R CMD INSTALL $(pwd)/
sudo R -e 'library(SparkR)' --slave
popd

# RScala package
pushd ~
# must use \ to escape $
# for some reason it doesn't work without the repos parameter to install.packages()
cat > init.R <<EOF
ind = which(lapply(getCRANmirrors()\$Name, function(x) pmatch('USA (WA', x)) > 0)[1]
chooseCRANmirror(ind=ind)
install.packages('rscala', repos = 'http://cran.us.r-project.org/')
library(rscala)
packageVersion('rscala')
rscala::scalaInstall()
q()
EOF

sudo R --slave < init.R
rm -f init.R
popd

echo "== end node $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
