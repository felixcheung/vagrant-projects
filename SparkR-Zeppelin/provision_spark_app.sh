#!/bin/bash

echo "== start app $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

# R packages and data
pushd ~
# must use \ to escape $
cat > init.R <<EOF
ind = which(lapply(getCRANmirrors()\$Name, function(x) pmatch('USA (WA', x)) > 0)[1]
chooseCRANmirror(ind=ind)
install.packages(c('nycflights13', 'dplyr', 'ggplot2', 'magrittr'))
q()
EOF
popd

# Zeppelin
pushd /opt
sudo cp /vagrant/zeppelin-0.6.0-incubating-SNAPSHOT.tar.gz ./
sudo tar -xzf zeppelin-*.tar.gz
sudo rm -f zeppelin-*.tar.gz
sudo \
SPARK_HOME=/opt/spark-1.5.0-bin-hadoop2.6 \
/opt/zeppelin-0.6.0-incubating-SNAPSHOT/bin/zeppelin-daemon.sh start
popd

echo "== end app $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
