#!/usr/bin/env python

# https://github.com/felixcheung/vagrant-projects

import getpass
import glob
import inspect
import os
import platform
import re
import subprocess
import sys
import time

#-----------------------
# PySpark
#

master = 'local[*]'

num_executors   = 12 #24
executor_cores  = 2
executor_memory = '1g' #10g

pyspark_submit_args = os.getenv('PYSPARK_SUBMIT_ARGS', None)
if not pyspark_submit_args:
    pyspark_submit_args = '--num-executors %d --executor-cores %d --executor-memory %s' % (num_executors, executor_cores, executor_memory)
pyspark_submit_args = '--master %s %s' % (master, pyspark_submit_args)

if not os.getenv('PYSPARK_PYTHON', None):
    os.environ['PYSPARK_PYTHON'] = sys.executable
os.environ['PYSPARK_DRIVER_PYTHON']='ipython' # PySpark Driver (ie. IPython)
profile_name = 'pyspark'
os.environ['PYSPARK_DRIVER_PYTHON_OPTS'] = 'notebook --profile=%s' % profile_name

#-----------------------
# IPython Notebook
#

ipython_notebook_config_template = '''c = get_config()
c.NotebookApp.ip = '{ip}'
c.NotebookApp.port = {port}
c.NotebookApp.open_browser = False
'''

pyspark_setup_template = '''import os
if not os.getenv('PYSPARK_SUBMIT_ARGS', None):
    raise ValueError('PYSPARK_SUBMIT_ARGS environment variable is not set')

spark_home = os.getenv('SPARK_HOME', None)
if not spark_home:
    raise ValueError('SPARK_HOME environment variable is not set')
'''

ip = '*' # Warning: this is potentially insecure
port = 1088

#-----------------------
# Create profile and start
#

try:
    ipython_profile_path         = os.popen('ipython locate').read().rstrip('\n') + '/profile_%s' % profile_name
    setup_py_path                = ipython_profile_path + '/startup/00-pyspark-setup.py'
    ipython_notebook_config_path = ipython_profile_path + '/ipython_notebook_config.py'
    ipython_kernel_config_path   = ipython_profile_path + '/ipython_kernel_config.py'

    if not os.path.exists(ipython_profile_path):
        print 'Creating IPython Notebook profile\n'
        cmd = 'ipython profile create %s' % profile_name
        os.system(cmd)
        print '\n'

    if not os.path.exists(setup_py_path):
        print 'Writing PySpark setup\n'
        setup_file = open(setup_py_path, 'w')
        setup_file.write(pyspark_setup_template)
        setup_file.close()
        os.chmod(setup_py_path, 0600)

    # matplotlib inline
    kernel_config = open(ipython_kernel_config_path).read()
    if "c.IPKernelApp.matplotlib = 'inline'" not in kernel_config:
        print 'Writing IPython kernel config\n'
        new_kernel_config = kernel_config.replace('# c.IPKernelApp.matplotlib = None', "c.IPKernelApp.matplotlib = 'inline'")
        kernel_file = open(ipython_kernel_config_path, 'w')
        kernel_file.write(new_kernel_config)
        kernel_file.close()
        os.chmod(ipython_kernel_config_path, 0600)

    if not os.path.exists(ipython_notebook_config_path) or 'open_browser = False' not in open(ipython_notebook_config_path).read():
        print 'Writing IPython Notebook config\n'
        config_file = open(ipython_notebook_config_path, 'w')
        config_file.write(ipython_notebook_config_template.format(ip = ip, port = port))
        config_file.close()
        os.chmod(ipython_notebook_config_path, 0600)

    print 'Launching PySpark with IPython Notebook\n'
    cmd = 'pyspark %s' % pyspark_submit_args
    os.system(cmd)
    sys.exit(0)
except KeyboardInterrupt:
    print 'Aborted\n'
    sys.exit(1)
