import time
import os
import subprocess

"""
A simple script to keep git repos up to date with master so that the most recent code is
always being used.
"""

if __name__ == '__main__':

    subprocess.Popen('cd /u01/prd/python/pycrypt && git pull',
                     shell=True,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE)
    subprocess.Popen('cd /u01/prd/python/StreamingVUMeter && git pull',
                     shell=True,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE)
    subprocess.Popen('cd /u01/prd/lcd/lcd35_install && git pull',
                     shell=True,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE)
    subprocess.Popen('cd /home/pi/streaming_setup && git pull',
                     shell=True,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE)
    subprocess.Popen('cd /home/pi/streaming_setup && cp -f *.py /u01/prd/python/',
                     shell=True,
                     stdout=subprocess.PIPE,
                     stderr=subprocess.PIPE)