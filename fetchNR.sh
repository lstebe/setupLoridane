#! /bin/sh/

##original command
#bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)
echo "Fetch Installation Script"
curl -o installnr.sh https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
bash ./installnr.sh --confirm-install --confirm-pi
echo "Installing NPM and"
echo "Installing NODE RED and setup as Service"
exit 0
curl -o installnr.sh https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered
