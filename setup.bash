#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

# function for generating a random 31 digit password
randpw(){ 
	< /dev/urandom tr -dc '_!@#$%A-Z-a-z-0-9' | head -c${1:-32};
	echo;
}
randpwtv(){ 
	< /dev/urandom tr -dc '_!@#$%A-Z-a-z-0-9' | head -c${1:-12};
	echo;
}

echo

echo "Which Radio Station do you wish to configure?"
select uin in "KGRO" "KOMX" "KDRL"; do
    case $uin in
        KGRO ) StationID="KGRO"; 
			   StreamDescription="KGRO Radio"; 
			   StreamName="KGRO Broadcast";
			   StreamMP="kgro";
			   StreamPort="8000";
			   srcPswd=$(randpw);
			   adminPswd=$(randpw);
			   rlyPswd=$(randpw);
			   break;;
        KOMX ) StationID="KOMX";
			   StreamDescription="KOMX Radio"; 
			   StreamName="KOMX Broadcast";
			   StreamMP="komx";
			   StreamPort="8001";
			   srcPswd=$(randpw);
			   adminPswd=$(randpw);
			   rlyPswd=$(randpw);
			   break;;
		KDRL ) StationID="KDRL";
			   StreamDescription="KDRL Radio"; 
			   StreamName="KDRL Broadcast";
			   StreamMP="kdrl";
			   StreamPort="8002";
			   srcPswd=$(randpw);
			   adminPswd=$(randpw);
			   rlyPswd=$(randpw);
			   break;;
    esac
done

sudo apt update -y
sudo apt upgrade -y
sudo apt-get --no-install-recommends install -y build-essential devscripts autotools-dev fakeroot dpkg-dev debhelper autotools-dev dh-make quilt ccache libsamplerate0-dev libpulse-dev libaudio-dev lame libjack-jackd2-dev libasound2-dev libtwolame-dev libfaad-dev libflac-dev libmp4v2-dev libshout3-dev libmp3lame-dev
sudo apt-get install -y libsdl-dev libsdl-image1.2-dev libsdl-mixer1.2-dev libsdl-ttf2.0-dev 
sudo apt-get install -y libsmpeg-dev libportmidi-dev libavformat-dev libswscale-dev
sudo apt-get install -y python3-dev python3-numpy
sudo apt-get install -y mercurial git
sudo apt-get install -y mplayer vim # possibly using mpg321
sudo apt-get install -y darkice mutt
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y icecast2
sudo apt install -y $SCRIPTPATH/teamviewer-host_13.0.5641_armhf.deb

echo

echo "Loading Raspberry Pi Configuration Tool"

echo

echo "export LC_ALL=en_US.UTF-8" | sudo tee --append ~/.bashrc
sudo ln -fs /usr/share/zoneinfo/US/Central /etc/localtime
sudo dpkg-reconfigure -f noninteractive tzdata
 
echo
echo "Setting up Python PyGame"
cd ~/
hg clone https://bitbucket.org/pygame/pygame
cd pygame
python3 setup.py build 
sudo python3 setup.py install
cd ~/
sudo rm -fR ~/pygame/

echo
echo
echo "Setting up Python PyAudio"
sudo apt-get install -y python3-pyaudio
pip3 install psutil
pip3 install pycryptodome

echo

echo "Setting up Audio Loopback Devices"
sudo cp -f $SCRIPTPATH/config/alsa-aloop.conf /etc/modprobe.d/alsa-aloop.conf
sudo modprobe snd-aloop
sudo cp -f $SCRIPTPATH/config/modules /etc/modules
sudo cp -f $SCRIPTPATH/config/asound.conf /etc/

echo

echo "Setting up directory tree"
sudo mkdir -p /u01/prd/streaming/cfg/icecast
sudo mkdir -p /u01/prd/streaming/cfg/darkice
sudo mkdir -p /u01/prd/streaming/cfg/vumeter
sudo mkdir -p /u01/prd/lcd/
sudo mkdir -p /u01/prd/rsa/
sudo mkdir -p /u01/prd/python
sudo mkdir -p /u01/prd/.ssh
sudo mkdir -p /u01/prd/tmp
sudo mkdir -p /u01/prd/tmp/.mutt/cache/headers
sudo mkdir /u01/prd/tmp/.mutt/cache/bodies
sudo touch /u01/prd/tmp/.mutt/certificates
sudo cp /boot/key /u01/prd/rsa
sudo cp /boot/enc_secret /u01/prd/rsa
sudo cp $SCRIPTPATH/rsa/* /u01/prd/rsa/
sudo chown -R pi:root /u01
tree /u01

echo 

echo "Pulling down all of the git repos"
cd /u01/prd/lcd/
git clone https://github.com/ToxicSamN/lcd35_install.git
cd /u01/prd/python/
git clone https://github.com/ToxicSamN/StreamingVUMeter.git
git clone https://github.com/ToxicSamN/pycrypt.git

echo

echo "Configuring the streaming services"
sudo cp /u01/prd/python/StreamingVUMeter/streaming.service /etc/systemd/system
sudo cp $SCRIPTPATH/config/passwdgen.service /etc/systemd/system
sudo cp $SCRIPTPATH/config/icecast.xml /u01/prd/streaming/cfg/icecast/icecast.xml
sudo cp $SCRIPTPATH/config/darkice.conf /u01/prd/streaming/cfg/darkice/darkice.conf
sudo cp $SCRIPTPATH/config/vumeter.conf /u01/prd/streaming/cfg/vumeter/vumeter.conf
sudo cp $SCRIPTPATH/config/icecast2 /etc/default/
sudo cp $SCRIPTPATH/config/streaming-vu-meter.desktop /usr/share/applications/streaming-vu-meter.desktop
cp $SCRIPTPATH/config/panel.new /home/pi/.config/lxpanel/LXDE-pi/panels/panel
cp $SCRIPTPATH/config/autostart /home/pi/.config/lxsession/LXDE-pi/autostart
sudo cp /usr/share/applications/streaming-vu-meter.desktop /home/pi/Desktop/
sudo systemctl daemon-reload
sudo systemctl disable darkice.service
sudo systemctl enable icecast2.service
sudo systemctl enable streaming.service

echo

echo "Configuring the configuration files"
cd /u01/prd/streaming/cfg  # Working Directory
echo "Configuring Icecast2.xml"
sudo sed -i.bak 's/<admin-user>admin<\/admin-user>/<admin-user>stream<\/admin-user>/' /u01/prd/streaming/cfg/icecast/icecast.xml
sudo sed -i 's/<admin-password>hackme<\/admin-password>/<admin-password>'"$adminPswd"'<\/admin-password>/' /u01/prd/streaming/cfg/icecast/icecast.xml
sudo sed -i 's/<source-password>hackme<\/source-password>/<source-password>'"$srcPswd"'<\/source-password>/' /u01/prd/streaming/cfg/icecast/icecast.xml
sudo sed -i 's/<relay-password>hackme<\/relay-password>/<relay-password>'"$rlyPswd"'<\/relay-password>/' /u01/prd/streaming/cfg/icecast/icecast.xml
sudo sed -i 's/<port>8000<\/port>/<port>'"$StreamPort"'<\/port>/' /u01/prd/streaming/cfg/icecast/icecast.xml
echo
echo "Configuring Darkice.conf"
sudo sed -i.bak 's/port.*=.*8000.*/port = '"$StreamPort"'/' /u01/prd/streaming/cfg/darkice/darkice.conf
sudo sed -i 's/password.*=.*hackme.*/password = '"$srcPswd"'/' /u01/prd/streaming/cfg/darkice/darkice.conf
sudo sed -i 's/mountPoint.*=.*mpid.*/mountPoint = '"$StreamMP"'/' /u01/prd/streaming/cfg/darkice/darkice.conf
sudo sed -i 's/name.*=.*mpnm.*/name = '"$StreamName"'/' /u01/prd/streaming/cfg/darkice/darkice.conf
sudo sed -i 's/description.*=.*XXXX Radio.*/description = '"$StreamDescription"'/' /u01/prd/streaming/cfg/darkice/darkice.conf
echo
echo "Configuring Vumeter.conf"
sudo sed -i.bak 's/streamName.*=.*XXXX Broadcast.*/streamName = '"$StreamName"'/' /u01/prd/streaming/cfg/vumeter/vumeter.conf
sudo sed -i 's/mountPoint.*=.*mpid.*/mountPoint = '"$StreamMP"'/' /u01/prd/streaming/cfg/vumeter/vumeter.conf
sudo sed -i 's/port.*=.*8000.*/port = '"$StreamPort"'/' /u01/prd/streaming/cfg/vumeter/vumeter.conf
sudo sed -i 's/pswd.*=.*hackme.*/pswd = '"$adminPswd"'/' /u01/prd/streaming/cfg/vumeter/vumeter.conf

echo
echo "Setting file/folder ownerships"
sudo chown -R pi:root /u01/prd/streaming
sudo chown -R icecast2:icecast /u01/prd/streaming/cfg/icecast

sudo hostnamectl set-hostname "$StreamMP-stream"
python3 /u01/prd/python/autogen_tvow.py

echo 
echo "Setting up CRON job for Teamviewer PW creation"
(crontab -l; echo "0 0 1 * * python3 /u01/prd/python/autogen_tvpw.py") | crontab -

echo "Installing the LCD Screen Components"
/u01/prd/lcd/lcd35_install/install_lcd35 # this will cause an auto-reboot which signal the end of the setup
