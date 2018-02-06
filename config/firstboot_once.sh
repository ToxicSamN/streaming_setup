#!/bin/sh
### BEGIN INIT INFO
# Provides:          firstboot_once
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop:
# Short-Description: Run firstboot sequence for custom image
# Description:
### END INIT INFO

#/etc/rc3.d/S01firstboot_once -> /etc/init.d/firstboot_once.sh 

# function for generating a random 31 digit password
randpw(){ 
	< /dev/urandom tr -dc '_A-Z-a-z-0-9' | tail -n +1 | head -c${1:-32};
	echo;
}
randpwtv(){ 
	< /dev/urandom tr -dc '_!@#$%A-Z-a-z-0-9' | head -c${1:-12};
	echo;
}

cd /u01/prd/python
echo "Starting firstboot_once"
echo "Updating GIT Repos"
python3 /u01/prd/python/git_update.py
echo "Auto-Generating Teamviewer Passwd"
python3 /u01/prd/python/autogen_tvpw.py
echo "Generating new Icecast Source passwd"
srcPswd=$(echo $(python3 /u01/prd/python/autogen_pw.py))
echo "Generating new Icecast Admin passwd" 
adminPswd=$(echo $(python3 /u01/prd/python/autogen_pw.py))
echo "Generating new Icecast Relay passwd"
rlyPswd=$(echo $(python3 /u01/prd/python/autogen_pw.py))
echo "Saving new Icecast Admin passwd"
sed -i 's/<admin-password>hackme<\/admin-password>/<admin-password>'"$adminPswd"'<\/admin-password>/' /u01/prd/streaming/cfg/icecast/icecast.xml
echo "Saving new Icecast Source passwd"
sed -i 's/<source-password>hackme<\/source-password>/<source-password>'"$srcPswd"'<\/source-password>/' /u01/prd/streaming/cfg/icecast/icecast.xml
echo "Saving new Icecast Relay passwd"
sed -i 's/<relay-password>hackme<\/relay-password>/<relay-password>'"$rlyPswd"'<\/relay-password>/' /u01/prd/streaming/cfg/icecast/icecast.xml
echo "Saving new Icecast passwd to darkice"
sed -i 's/password.*=.*hackme.*/password = '"$srcPswd"'/' /u01/prd/streaming/cfg/darkice/darkice.conf
echo "Saving new Icecast passwd to vumeter.conf"
sudo sed -i 's/pswd.*=.*hackme.*/pswd = '"$adminPswd"'/' /u01/prd/streaming/cfg/vumeter/vumeter.conf
echo "Starting resize2fs_once"
resize2fs /dev/mmcblk0p2
echo "Removing firstboot_once from startup"
systemctl disable firstboot.service


