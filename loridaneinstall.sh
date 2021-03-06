#! /bin/sh
echo "#.......This script will now install all dependencies for a routed WiFi Accesspoint on RPi"
echo ".......as a service."
#
whiptail --msgbox "This script will set up a ROUTED (Own IP range) AP to your RasPi like:
                                         +- RPi ----------+
                                     +---+ 10.10.0.2      |          +-Loridane GW +
                                     |   |Loridane Server +-)))  (((-+     Client |
                                     |   | 192.168.4.1    |          |192.168.4.100|
                                     |   +----------------+          +-------------+
                 +- Router ----+     |
                 | Firewall    |     |   +- PC#2 ------+
(Internet)---WAN-+ DHCP server +-LAN-+---+ 10.10.0.3   |
                 |   10.10.0.1 |     |   +-------------+
                 +-------------+     |
                                     |   +- PC#1 ------+
                                     +---+ 10.10.0.4   |
                                         +-------------+" 30 90 ;

## Ask User for permission to install
if whiptail --yesno --yes-button OK --no-button Cancel "If you don't want this, press Cancel" 30 80 ;
	then
	echo "Cool"
else
	echo "Cool"
	exit 0
fi

if whiptail --yesno --yes-button OK --no-button Cancel "Set System Timezone to Europe/Berlin?" 30 80 ;
	then
	timedatectl set-timezone Europe/Berlin
fi

if whiptail --yesno --yes-button Yes! --no-button "No, I did that" "Update the apt repositories first?" 30 80 ;
	then
	echo "........................................................................"
	##Install needed Packages and running initial tasks
	echo "LORIDANE - Expanding FS"
	raspi-config --expand-rootfs
	echo "LORIDANE - Updating Repos"
	apt-get update
	apt-get upgrade -y
	echo "........................................................................"
else
	echo "Cool"
fi

## Save home and installation folder to a variable
datafolder=`pwd`
cd .. 
homedir=`pwd`
cd "$datafolder"
echo "LORIDANE - Found Homedirecory as $homedir"
echo "LORIDANE - Data Folder is $datafolder"
echo "Press Ctrl+C to Cancel"
sleep 10


## Ask user for permission to create a wifi AP
if whiptail --yesno --yes-button OK --no-button Cancel "Install a WiFi Access-Point?" 30 80 ;
	then
	echo "LORIDANE - Installing HostAPD"
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
		echo "	static ip_address=loridane.gw/24">>'/etc/dhcpcd.conf'
		echo "LORIDANE - Done. Set IP to $routerip"
	else
		echo "	static ip_address=$routerip">>"/etc/dhcpcd.conf"
		echo "	static domain_name_servers=$routerip 8.8.8.8">>"/etc/dhcpcd.conf"
		echo "LORIDANE - Done!"
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
	echo "LORIDANE - Configure /etc/dnsmasq.conf"
	echo "LORIDANE - with"
	echo "LORIDANE - interface=wlan0"
	echo "LORIDANE - domain=wlan"
	echo "LORIDANE - address=/loridane.gw/$routerip"
	echo "........................................................................"
	sleep 3
	echo "interface=wlan0 # Listening interface">>"/etc/dnsmasq.conf"
	#Set Up DHCP Range here from 192.168.4.100 to 192.168.4.200,
	from="192.168.4.100"
	fromto = "192.168.4.200"
	if whiptail --yesno --yes-button Default --no-button Configure "Would you like to configure the DHCP range or leave it default?
	From 192.168.4.100 TO 192.168.4.200" 30 80; then
		echo 'dhcp-range=192.168.4.100,192.168.4.200,255.255.255.0,24h'>>'/etc/dnsmasq.conf'
		echo "LORIDANE - Done!"
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


	echo "domain=gw">>"/etc/dnsmasq.conf"

	##Example SSID of the WiFi Network
	ssid="Loridane-01"
	ssid=$( whiptail --inputbox "Please enter the SSID your WiFi should have:" 20 30 Loridane-02 3>&1 1>&2 2>&3 )

	##loridane.gw is the DNS name of the pi
	echo "address=/$ssid/$routerip">>"/etc/dnsmasq.conf"

	echo "........................................................................"
	echo "LORIDANE - unblock WiFi"

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
	echo "LORIDANE - Done!........................................................................"
	echo ".................................................................................."

	if whiptail --yesno "Would you like to enable WiFi accesspoint as a service?" 30 80 ; then
		systemctl enable hostapd.service
		echo "LORIDANE - Done!"
	else
		echo "LORIDANE - Okay, hostapd.service not enabled"
	fi

	if whiptail --yesno "Start accesspoint now?" 30 80; then
		systemctl start hostapd.service
		echo "LORIDANE - Done!"
	else
		echo "LORIDANE - Okay, not started"
	fi

	whiptail --msgbox "You can start and stop the accesspoint via
	<sudo systemctl start|stop hostapd.service>\n
	Enable/disable AP autostart at boot via
	<sudo systemctl enable|disable hostapd.service>" 30 80
fi

if whiptail --yesno "Would you like to install NODE RED?" 30 80 ; then
	## Installing NodeRed as user "pi"
	sudo -u pi sh fetchNR.sh
	systemctl enable nodered.service
	node-red-stop
	echo "LORIDANE - Copying some files and set up directories"
	mkdir -p "$homedir/LORIDANE/config"
	mv "$homedir/.node-red/flows.json" "$homedir/.node-red/flows.json.orig"
	mv "$homedir/.node-red/settings.js" "$homedir/.node-red/settings.js.orig"
	cp "$datafolder/flows_loridane.json" "$homedir/.node-red/flows_loridane.json"
	cp "$datafolder/flows_loridane_cred.json" "$homedir/.node-red/flows_loridane_cred.json"
	cp "$datafolder/settings.js" "$homedir/.node-red/settings.js"
	mkdir -p "$homedir/LORIDANE/database"
	cp "$datafolder/loridaneConfig.json" "$homedir/LORIDANE/config/loridaneConfig.json"
	cd "$homedir/.node-red"
	echo "LORIDANE - Installing Additional Modules"
	npm install node-red-dashboard
	npm install node-red-contrib-fs
	npm install node-red-contrib-throttle
	npm install node-red-contrib-opcua
	npm install node-red-node-ui-table
	npm install crypto-js
	npm install crypto
	
	echo "LORIDANE - Enabled NODERED Service"
	echo "LORIDANE - Restart NODE RED"

	whiptail --msgbox "Please Enter a Credential Secret (like a password) which will be used to hash your passwords, if you think the one set is not appropriate" 30 90 ;
	sudo nano +24,97 "$homedir/.node-red/settings.js"
	echo "......................................................."
fi

cd

## Ask user for permission to install MOSQUITTO
if whiptail --yesno "Would you like to install a MQTT-Broker (mosquitto)?" 30 80 ; then
	echo "LORIDANE - Installing MQTT Broker"
	apt-get install mosquitto -y
	systemctl unmask mosquitto
	echo "......................................................."
	echo "LORIDANE - setting up Passwordfile for MQTT"
	echo "LORIDANE - you will be asked to input the password of your choice now"
	echo "LORIDANE - Username is mqtusr"
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
cd "$homedir/LORIDANE"

## change ownership of the loridane folder to the user as anything is installed as root
chown -R pi *
node-red-stop
#Set RAM space controlled by Node.js
node-red-pi --max-old-space-size=1024
if whiptail --yesno --defaultno "Script finished. Would you like to REBOOT NOW? " 30 80 ; then
	echo "LORIDANE - Okay. Shutdown"
	node-red-stop
	reboot now
else
	echo "LORIDANE - Okay, no reboot. Script finished"
fi


exit 0
