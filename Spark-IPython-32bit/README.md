# Spark-IPython-32bit

Setup a Vagrant single node with Spark, IPython, and matplotlib

### Content

Vagrantfile
apache-mirror-selector.py - Script to help select a Apache mirror to download from
ipython-pyspark.py - IPython notebook config and launch script
provision_spark_node.sh - Vagrant provisioning script

### Prereq

Vagrant http://docs.vagrantup.com/v2/installation/index.html
VirtualBox https://www.virtualbox.org/wiki/Downloads as a provider

### Preparation

  - Go to local directory and run `vagrant up`
  - Vagrant will then prepare the VM - this should take about ~2 min to download the core vm (aka "box") and then ~4 min for other downloads and provisioning - it will require Internet connection to download various content from sources
  - Spark distribution is automatically downloaded during the provisioning phase
  - IPython notebook is downloaded and configured during provisioning, and it is launched with PySpark as the very last step. Port forwarding is configured in Vagrant such that to connect to IPython notebook, use http://localhost:1088
  - Use `vagrant ssh` to connect to the VM machine

### Start/Stop

#### IPython

`vagrant ssh`

stop: Ctrl-C to break  
start:  
`$ ./ipython-pyspark.py`

Connect to http://localhost:1088

### Data transfer

Vagrant support a "mapped directory". The local directory on the host where Vagrantfile is, is mapped to `/vagrant` in the VM. Any file there can be accessed from within the VM (use `vagrant ssh` to connect)
