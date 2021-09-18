#! /bin/sh
echo "#.......This script will now install all dependencies for a routed WiFi Accesspoint on RPi"
echo ".......as a service."
#
whiptail --msgbox "This script will set up a ROUTED (Own IP range) AP to your RasPi like:
                                       +- RPi -------+
                                     +---+ 10.10.0.2   |          +- Laptop ----+
                                     |   |     WLAN AP +-)))  (((-+ WLAN Client |
                                     |   | 192.168.4.1 |          |192.168.4.100|
                                     |   +-------------+          +-------------+
                 +- Router ----+     |
                 | Firewall    |     |   +- PC#2 ------+
(Internet)---WAN-+ DHCP server +-LAN-+---+ 10.10.0.3   |
                 |   10.10.0.1 |     |   +-------------+
                 +-------------+     |
                                     |   +- PC#1 ------+
                                     +---+ 10.10.0.4   |
                                         +-------------+" 30 90 ;

#OK
if whiptail --yesno --yes-button OK --no-button Cancel "If you don't want this, press Cancel" 30 80 ;
	then
	echo "Cool"
else
	echo "Cool"
	exit 0
fi

echo "........................................................................"
#Install needed Packages
echo "#####Updating Repos"
apt-get update
apt-get upgrade -y
echo "........................................................................"

if whiptail --yesno --yes-button OK --no-button Cancel "Install a WiFi Access-Point?" 30 80 ;
	then
echo ".......Installing HostAPD"
apt install hostapd -y
systemctl unmask hostapd
systemctl enable hostapd
apt install dnsmasq -y
DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent
#Set up WiFi DHCP
echo "interface wlan0">>"/etc/dhcpcd.conf"
routerip="192.168.4.1"
#Ip adress of the Raspberry set here
if whiptail --yesno --defaultno "I'll set the IP Adress of the Raspi Router to\n
192.168.4.1\n
Do you want to change it?" 30 80; then
routerip=$(whiptail --inputbox "Set an IP address:" 20 30 192.168.4.1 3>&1 1>&2 2>&3)
echo "	static ip_address=pi.wlangw/24">>'/etc/dhcpcd.conf'
echo "Done. Set IP to $routerip"
else
echo "	static ip_address=$routerip">>"/etc/dhcpcd.conf"
echo "	static domain_name_servers=$routerip 8.8.8.8">>"/etc/dhcpcd.conf"
echo "Done!"
fi
echo "	nohook wpa_supplicant">>"/etc/dhcpcd.conf"
echo "# Enable IPv4 routing">>"/etc/sysctl.d/routed-ap.conf"
echo "net.ipv4.ip_forward=1">>"/etc/sysctl.d/routed-ap.conf"
#Forward routing to Thernet
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
netfilter-persistent save
#Backup original dnsmasq.conf
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo "........................................................................"
echo ".....Configure /etc/dnsmasq.conf"
echo ".....with"
echo ".....interface=wlan0"
echo ".....domain=wlan"
echo ".....address=/pi.wlangw/$routerip"
echo "........................................................................"
sleep 3
echo "interface=wlan0 # Listening interface">>"/etc/dnsmasq.conf"
#Set Up DHCP Range here from 192.168.4.100 to 192.168.4.200,
from="192.168.4.100"
fromto = "192.168.4.200"
if whiptail --yesno --yes-button Default --no-button Configure "Would you like to configure the DHCP range or leave it default?
From 192.168.4.100 TO 192.168.4.200" 30 80; then
echo 'dhcp-range=192.168.4.100,192.168.4.200,255.255.255.0,24h'>>'/etc/dnsmasq.conf'
echo "Done!"
else
whiptail --msgbox "Now you'll configure the DHCP range
The first IP adress in the next window.\n
Like:
FROM 192.168.4.100
TO 192.168.4.200" 30 80
from=$( whiptail --inputbox "Set the FIRST IP address of your DHCP range:" 20 30 192.168.4.100 3>&1 1>&2 2>&3 )
fromto=$( whiptail --inputbox "Set the LAST IP address of your DHCP range:" 20 30 192.168.4.200 3>&1 1>&2 2>&3 )
echo "dhcp-range=$from,$fromto,255.255.255.0,24h">>'/etc/dnsmasq.conf'
echo "Done!"
fi


echo "domain=wlan">>"/etc/dnsmasq.conf"

#Example SSID of the WiFi Network
ssid="Loridane-01"
ssid=$( whiptail --inputbox "Please enter the SSID your WiFi should have:" 20 30 myCreative-SSID 3>&1 1>&2 2>&3 )

#pi.wlan is the DNS name of the pi
echo "address=/$ssid/$routerip">>"/etc/dnsmasq.conf"

echo "........................................................................"
echo ".....unblock WiFi"

#WLAN has to be unblocked
rfkill unblock wlan
echo "........................................................................"

echo ".....Configure /etc/hostapd/hostapd.conf"
sleep 3
echo "........................................................................"

echo "country_code=DE">>"/etc/hostapd/hostapd.conf"
echo "interface=wlan0">>"/etc/hostapd/hostapd.conf"

#Example SSID of the WiFi Network
echo "ssid=$ssid">>"/etc/hostapd/hostapd.conf"
hwmode="g"
hwmode=$(whiptail --inputbox "Which Hardware Mode?\n
for 5Ghz: a
for 2.4Ghz: b,g or n\n
If you don't know what to do choose g" 20 30 g 3>&1 1>&2 2>&3)

channel="7"
channel=$(whiptail --inputbox "Choose a WiFi-Channel:\n
If you chose 5GHz (a) in the last window use a even number between 32 and 64
e.g. 38\n
If you chose 2.4Ghz (b,g,n) in the last window use
e.g.: g" 20 30 7 3>&1 1>&2 2>&3)
echo "hw_mode=$hwmode">>"/etc/hostapd/hostapd.conf"
echo "channel=$channel">>"/etc/hostapd/hostapd.conf"
echo "macaddr_acl=0">>"/etc/hostapd/hostapd.conf"
echo "auth_algs=1">>"/etc/hostapd/hostapd.conf"
echo "ignore_broadcast_ssid=0">>"/etc/hostapd/hostapd.conf"
echo "wpa=2">>"/etc/hostapd/hostapd.conf"

wifipwd="12345678"
wifipwd=$( whiptail --inputbox "Please enter your new WiFi Password with at least 8 characters:\n
ATTENTION! Will be shown CLEARTEXT in this window!" 20 30 mySuperSecretPWD123 3>&1 1>&2 2>&3 )

#Examplepassword which is to be changed
echo "wpa_passphrase=$wifipwd">>"/etc/hostapd/hostapd.conf"
#Define Encryption
echo "wpa_key_mgmt=WPA-PSK">>"/etc/hostapd/hostapd.conf"
echo "wpa_pairwise=TKIP">>"/etc/hostapd/hostapd.conf"
echo "rsn_pairwise=CCMP">>"/etc/hostapd/hostapd.conf"
echo ".....Done!........................................................................"
echo ".................................................................................."

if whiptail --yesno "Would you like to enable WiFi accesspoint as a service?" 30 80 ; then
systemctl enable hostapd.service
echo "Done!"
else
echo "Okay, hostapd.service not enabled"
fi

if whiptail --yesno "Start accesspoint now?" 30 80; then
systemctl start hostapd.service
echo "Done!"
else
echo "Okay, not started"
fi

whiptail --msgbox "You can start and stop the accesspoint via
<sudo systemctl start|stop hostapd.service>\n
Enable/disable AP autostart at boot via
<sudo systemctl enable|disable hostapd.service>" 30 80


fi

if whiptail --yesno "Would you like to install NODE RED?" 30 80 ; then
sudo -u pi sh fetchNR.sh
#apt-get install npm -y
#apt-get install nodered -y
systemctl enable nodered.service
#echo "Installing Additional Modules"
#npm install node-red-dashboard
#npm install node-red-contrib-fs
#npm install node-red-contrib-throttle
#npm install cryptojs
#npm install crypto

echo "Copying some files and set up directories"
mkdir -p /home/pi/LORIDANE/config
mv /home/pi/.node-red/flows.json /home/pi/.node-red/flows.json.orig
mv /home/pi/.node-red/settings.js /home/pi/.node-red/settings.js.orig
cp flows_loridane.json /home/pi/.node-red/flows_loridane.json
cp settings.js /home/pi/.node-red/settings.js
mkdir -p /home/pi/LORIDANE/database
cp loridaneConfig.json /home/pi/LORIDANE/config/loridaneConfig.json

cd /home/pi/.node.red
echo "Installing Additional Modules"
npm install node-red-dashboard
npm install node-red-contrib-fs
npm install node-red-contrib-throttle
npm install cryptojs
npm install crypto

echo "Enabled NODERED Service"
echo "Restart NODE RED"

whiptail --msgbox "Please Enter a Credential Secret (like a password) which will be used to hash your passwords, if you think the one set is not appropriate" 30 90 ;
sudo nano +83,24 /home/pi/.node-red/settings.js
echo "......................................................."
fi

if whiptail --yesno "Would you like to install a MQTT-Broker (mosquitto)?" 30 80 ; then
echo "Installing MQTT Broker"
apt-get install mosquitto -y
systemctl unmask mosquitto
echo "......................................................."
echo "setting up Passwordfile for MQTT"
echo "you will be asked to input the password of your choice now"
echo "Username is mqtusr"
whiptail --msgbox "Please Enter a Password for your MQTT-Username: mqtusr" 30 80;
mosquitto_passwd -c /etc/mosquitto/passwd mqtusr
#Do
echo "allow_anonymous false">>"/etc/mosquitto/conf.d/default.conf"
echo "password_file /etc/mosquitto/passwd">>"/etc/mosquitto/conf.d/default.conf"
echo "listener 1883 $routerip">>"/etc/mosquitto/conf.d/default.conf"
systemctl restart mosquitto
echo "......................................................."
else
echo "OK"
fi

if whiptail --yesno --defaultno "Script finished. Would you like to REBOOT NOW? " 30 80 ; then
echo "Okay. Shutdown"
node-red-stop
reboot now
else
echo "Okay, no reboot. Script finished"
fi
exit 0
