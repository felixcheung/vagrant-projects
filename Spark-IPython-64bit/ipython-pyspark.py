#!/usr/bin/env python

# https://github.com/felixcheung/vagrant-projects

import os
import sys

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

ip = '*' # Warning: this is potentially insecure
port = 1088

os.environ['PYSPARK_DRIVER_PYTHON_OPTS'] = 'notebook --ip=%s --port=%s --no-browser --notebook-dir=/vagrant' % (ip, port)

try:
    print 'Launching PySpark with IPython Notebook\n'
    cmd = 'pyspark %s' % pyspark_submit_args
    os.system(cmd)
    sys.exit(0)
except KeyboardInterrupt:
    print 'Aborted\n'
    sys.exit(1)
