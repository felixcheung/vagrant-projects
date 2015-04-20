# Spark-IPython-Zeppelin-Lightning

Setup a Vagrant multinode (2) with Spark, IPython, Zeppelin on 'node' and Lightning on 'lgn'

### Content

CabinSketch-Bold.ttf - used in Word2Vec demo, https://github.com/korin/stupid_captcha
Humor-Sans-1.0.ttf - required for xkcd plots, http://antiyawn.com/uploads/Humor-Sans-1.0.ttf
Vagrantfile
database.js - Lightning database config
ipython-pyspark.py - IPython setup/launch script
lightning.tar.gz - Lightning
pg_hba.conf - Postgres config
postgresql.conf - Postgres config
provision_lgn_app.sh - provisioning, Lightning on lgn
provision_spark_app.sh - provisioning, Spark app and demo stuff
provision_spark_node.sh - provisioning, Spark on node
spark-ml-streaming.tar.gz - Streaming k-means project

### Prereq

Vagrant, VirtualBox as a provider

Lightning, Streaming k-means builds are included for convenience but building your own is recommended.

Unfortunately these are too large for GitHub,
spark-1.3.0-bin-hadoop2.4.tgz
 - Spark 1.3.0 official release, you can download from http://spark.apache.org/downloads.html, choose 1.3.0, Hadoop 2.4

zeppelin-0.5.0-SNAPSHOT.tar.gz
 - Zeppelin build, see https://github.com/apache/incubator-zeppelin
 - Build with
`mvn clean package -Pspark-1.3 -Phadoop-2.4 -Dhadoop.version=2.5.0 -P build-distr -DskipTests`

### Preparation

  - Go to local directory and run `vagrant up`
  - Vagrant will then prepare the VMs - this could take ~1 hour and require Internet connection to download various content from sources
  - Zeppelin, Lightning are running automatically from provisioning script; if you see the Lightning logo then the preparation & provisioning steps are complete
  - Use `vagrant ssh` to connect to these machine

### Start/Stop

#### IPython

`vagrant ssh node`

stop: Ctrl-C to break
start:
`$ MASTER=local[*] ./ipython-pyspark.py`

Connect to http://localhost:8888

#### Zeppelin

`vagrant ssh node`

stop:
`$ sudo /opt/zeppelin-0.5.0-SNAPSHOT/bin/zeppelin-daemon.sh stop`
start:
`$ sudo SPARK_HOME=/opt/spark-1.3.0-bin-hadoop2.4 PYSPARK_PYTHON=/usr/local/bin/python2.7 LD_LIBRARY_PATH=/usr/local/lib /opt/zeppelin-0.5.0-SNAPSHOT/bin/zeppelin-daemon.sh start`

Connect to http://localhost:8080

#### Lightning

`vagrant ssh lgn`

stop: Ctrl-C to break
start:
```
$ cd /opt/lightning
$ sudo npm start
```

Connect to http://localhost:3000

#### Streaming k-means

`vagrant ssh node`

Driver script:
```
$ cd ~/streamingcluster/bin
$ /usr/local/bin/python2.7 streaming-kmeans -nc 4 -nd 2 -hl 10 -nb 100 -tu points
```

IPython notebook:
You can get it from https://github.com/felixcheung/spark-ml-streaming

More information to come!
