#!/usr/local/bin/python2.7
#
# inspired by http://blog.cloudera.com/blog/2014/08/how-to-use-ipython-notebook-with-apache-spark/
# and references
#
# Configurable settings:
# JAVA_HOME
#
# (Spark environment)
# SPARK_HOME
# MASTER
# DEPLOY_MODE
#
# (Hadoop/YARN)
# YARN_CONF_DIR
#
# (PySpark)
# PYSPARK_PYTHON
# PYSPARK_SUBMIT_ARGS
#
# (IPython)
# IPYTHON_IP
# IPYTHON_PORT
#


import getpass
import glob
import inspect
import os
import platform
import re
import subprocess
import sys
import time
from IPython.lib import passwd

v = sys.version_info
if v[:2] < (2,7) or v[0] >= 3:
    # 2.7.9; PySpark requires Python 2.6/2.7, IPython 2.x requires Python 2.7.x (or 3.3.x) 
    print 'Error: Only Python 2.7.x (2.7.9) is supported'
    sys.exit(1)

if platform.uname()[0] == 'Windows':
    # untested on Windows and calls ifconfig
    print 'Error: Windows not supported'
    sys.exit(1)

if getpass.getuser() == 'root':
    print 'Error: Run as normal user'
    sys.exit(1)
    
#-----------------------
# LD_LIBRARY_PATH - required to have Python/IPython/matplotlib find .so
#
py_os_path = inspect.getfile(os)
if py_os_path.find('/usr/local') == 0:
    # if this is a custom python path, set the custom library path relative to it
    rel_lib_path = '..'
    lib_path = os.path.normpath(os.path.join(os.path.dirname(py_os_path), rel_lib_path))
    current_lib_path = os.getenv('LD_LIBRARY_PATH', None)
    if not current_lib_path:
        os.environ['LD_LIBRARY_PATH'] = lib_path
    else: 
        os.environ['LD_LIBRARY_PATH'] = '%s:%s' % (lib_path, current_lib_path)

#-----------------------
# SPARK_HOME, JAVA_HOME
#

spark_shell = '/usr/bin/spark-shell'
rel_spark_path = '../lib/spark'
spark_home = os.getenv('SPARK_HOME', None)
if not spark_home:
    spark_home = os.path.normpath(os.path.join(os.path.dirname(os.path.realpath(spark_shell)), rel_spark_path))
    os.environ['SPARK_HOME'] = spark_home

if not os.getenv('JAVA_HOME', None):
    # try to detect JAVA_HOME the same way spark-shell does
    rel_detect_script_path = '../bigtop-utils/bigtop-detect-javahome'
    detect_script = os.path.normpath(os.path.join(spark_home, rel_detect_script_path))
    variables = subprocess.Popen(
        ['bash', '-c', "trap 'env' exit; source \"$1\" > /dev/null 2>&1",
        '_', detect_script],
        shell=False, stdout=subprocess.PIPE).communicate()[0]
    script_env = dict([line.strip().split('=', 1) for line in variables.splitlines()])
    # only set JAVA_HOME
    os.environ['JAVA_HOME'] = script_env['JAVA_HOME']

if not os.getenv('SPARK_HOME', None):
    print 'Error: SPARK_HOME not set or detected'
    sys.exit(2)
if not os.getenv('JAVA_HOME', None):
    print 'Error: JAVA_HOME not set or detected'  # JAVA_HOME not set will cause Spark errors
    sys.exit(2)
    
#-----------------------
# PySpark
#

# YARN
# client mode is spark-shell default
default_master = 'yarn'
default_deploy_mode = 'client'

master = os.getenv('MASTER', default_master)
deploy_mode = os.getenv('DEPLOY_MODE', default_deploy_mode)

num_executors   = 12 #24
executor_cores  = 5
executor_memory = '1g' #10g

if not os.getenv('YARN_CONF_DIR', None):
    os.environ['YARN_CONF_DIR'] = '/etc/hadoop/conf'

pyspark_submit_args = os.getenv('PYSPARK_SUBMIT_ARGS', None)
if not pyspark_submit_args:
    pyspark_submit_args = '--num-executors %d --executor-cores %d --executor-memory %s' % (num_executors, executor_cores, executor_memory)
pyspark_submit_args = '--master %s --deploy-mode %s %s' % (master, deploy_mode, pyspark_submit_args)

# Must use the same Python version otherwise PySpark Driver will fail to communicate with Workers
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
c.NotebookApp.password = open('{passwd_txt_path}').read().strip()
# c.IPKernelApp.pylab = 'inline' # IPython v2.x, not supported in v3.x - run '%pylab inline' in the notebook
'''

pyspark_setup_template = '''import os
if not os.getenv('PYSPARK_SUBMIT_ARGS', None):
    raise ValueError('PYSPARK_SUBMIT_ARGS environment variable is not set')

spark_home = os.getenv('SPARK_HOME', None)
if not spark_home:
    raise ValueError('SPARK_HOME environment variable is not set')
'''

default_ip = '*' # Warning: this is potentially insecure
default_port = 8888

ip = os.getenv('IPYTHON_IP', None)
if not ip:
    # Try getting IP with default Gateway
    ip = os.popen("ifconfig $(netstat -rn | awk '/^0.0.0.0[[:space:]]/ {print $8}') | sed -n '2 s/.*inet addr://; 2 s/ .*// p'").read().rstrip('\n')
    if not re.match('^\d+\.\d+\.\d+\.\d+$', ip):
        ip = default_ip

port = os.getenv('IPYTHON_PORT', default_port)

#-----------------------

password  = ''
password2 = ''

def get_password():
    global password
    global password2
    print 'Set password to access IPython NoteBook with Spark:\n'
    password = getpass.getpass()
    password2 = getpass.getpass('Repeat password: ')

try:
    ipython_profile_path         = os.popen('ipython locate').read().rstrip('\n') + '/profile_%s' % profile_name
    passwd_txt_path              = ipython_profile_path + '/passwd.txt'
    setup_py_path                = ipython_profile_path + '/startup/00-pyspark-setup.py'
    ipython_notebook_config_path = ipython_profile_path + '/ipython_notebook_config.py'

    if not os.path.exists(ipython_profile_path):
        print 'Creating IPython Notebook profile\n'
        cmd = 'ipython profile create %s' % profile_name
        os.system(cmd)
        print '\n'

    if not os.path.exists(passwd_txt_path):
        get_password()
        while(password != password2):
            print 'Passwords do not match, please try again\n'
            get_password()
        print '\nWriting hashed password\n'
        passwd_file = open(passwd_txt_path, 'w')
        passwd_file.write(passwd(password))
        passwd_file.close()
        os.chmod(passwd_txt_path, 0600)

    if not os.path.exists(setup_py_path):
        print 'Writing PySpart setup\n'
        setup_file = open(setup_py_path, 'w')
        setup_file.write(pyspark_setup_template)
        setup_file.close()
        os.chmod(setup_py_path, 0600)
 
    if not os.path.exists(ipython_notebook_config_path) or passwd_txt_path not in open(ipython_notebook_config_path).read():
        print 'Writing IPython Notebook config\n'
        config_file = open(ipython_notebook_config_path, 'w')
        config_file.write(ipython_notebook_config_template.format(passwd_txt_path = passwd_txt_path, ip = ip, port = port))
        config_file.close()
        os.chmod(ipython_notebook_config_path, 0600)

    print 'Launching PySpark with IPython Notebook\n'
    cmd = 'pyspark %s' % pyspark_submit_args
    os.system(cmd)
    sys.exit(0)
except KeyboardInterrupt:
    print 'Aborted\n'
    sys.exit(1)
