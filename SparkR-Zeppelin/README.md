# SparkR-Zeppelin

Setup a Vagrant node with Spark, SparkR, and Zeppelin

### Content

apache-mirror-selector - script to pick Apache mirror URL  
provision_spark_app.sh - provisioning, Zeppelin and R packages for demo  
provision_spark_node.sh - provisioning, JDK, R, Spark, SparkR, rscala  
spark-1.4.1-bin-hadoop2.4.tgz - Spark 1.4.1 official release  
Vagrantfile  
zeppelin-0.6.0-incubating-SNAPSHOT.tar.gz - Zeppelin build with SparkR interpreter  

### Prereq

Vagrant, VirtualBox as a provider

A Spark 1.4.1, Zeppelin build - provisioning script will download Spark from Apache mirror if not supplied

### Start/Stop

  - Go to local directory and run `vagrant up`
  - Zeppelin is running automatically from provisioning script
  - Use `vagrant ssh` to connect to the machine

#### Zeppelin

`vagrant ssh`

stop:
`$ sudo /opt/zeppelin-0.6.0-incubating-SNAPSHOT/bin/zeppelin-daemon.sh stop`
start:
`$ sudo SPARK_HOME=/opt/spark-1.4.1-bin-hadoop2.4 /opt/zeppelin-0.6.0-incubating-SNAPSHOT/bin/zeppelin-daemon.sh start`

Connect to http://localhost:8080


More information to come!
