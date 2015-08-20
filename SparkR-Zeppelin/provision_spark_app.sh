#!/bin/bash

echo "== start app $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

# Zeppelin
pushd /opt
sudo cp /vagrant/zeppelin-0.6.0-incubating-SNAPSHOT.tar.gz ./
sudo tar -xzf zeppelin-*.tar.gz
sudo rm -f zeppelin-*.tar.gz
sudo ./zeppelin-0.6.0-incubating-SNAPSHOT/bin/zeppelin-daemon.sh start
popd

echo "== end app $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
