# Spark-Cassandra-Zeppelin

SACZ - Setup a Vagrant node with Spark, HBase, Cassandra, and Zeppelin


### Content

apache-mirror-selector - script to pick Apache mirror URL  
provision_spark_node.sh - provisioning, JDK, Spark, HBase, Cassandra, Zeppelin  
spark-1.6.1-bin-hadoop2.6.tgz - Spark 1.6.1 official release  
hbase-1.2.1-bin.tar.gz
apache-cassandra-3.5-bin.tar.gz
apache-maven-3.3.9-bin.tar.gz
Vagrantfile  

### Prereq

Vagrant, VirtualBox as a provider

A Spark 1.6.1 build - provisioning script will download Spark from Apache mirror if not supplied

### Start/Stop

  - Go to local directory and run `vagrant up`
  - Zeppelin is running automatically from provisioning script
  - Zeppelin is configured to have these interpreters working: Spark, HBase, Cassandra
  - Use `vagrant ssh` to connect to the machine

#### Zeppelin

`vagrant ssh`

stop:
`$ sudo /opt/incubator-zeppelin/bin/zeppelin-daemon.sh stop`
start:
`$ sudo SPARK_HOME=/opt/spark-1.6.1-bin-hadoop2.6 /opt/incubator-zeppelin/bin/zeppelin-daemon.sh start`

Connect to http://localhost:8080

#### interpreters

To start, run this in the paragraph
```
%hbase
help
```

```
%cassandra
HELP;
```

More information to come!
