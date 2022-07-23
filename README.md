# setupLoridane
As a readme first of all please refer to my Bachelor Thesis

Aufbau und Bewertung eines low-cost Energiemessstellenkonzepts als LoRa-Netzwerk zur Energiekennzahlenaggregation im Produktionsumfeld
/
Evaluation of a low-cost energy metering concept implemented as a LoRa
network for energy key performance indicator aggregation in a production
environment

As published 24.11.2021
Lindsay Stebe
Insitute of PTW
Department Mechanical Engineering
TU Darmstadt

Abstract:
The work on hand concerns the development, the implementation and evaluation of a cordless
energy measurement approach for production machines. In focus is selecting adequate hardware as
well as implementing software code for individual network instances and the aggregation and
utilization of measurement data. This includes acquiring the specifications on energy metering
devices in this context and the requirements regarding a LoRa network structure for an optimum
implementation accounting cost optimization and feasibility. The energy metering devices are
realized with LoRa-capable microcontrollers which transmit data to a gateway based on the identical
low-cost one-channel LoRa/microcontroller hardware which then forwards the datasets via MQTT
and Wi-Fi to a Raspberry Pi based server. For this purpose, microcontrollers on an ESP32 basis with
a Semtech SX1267 LoRa transceiver are employed. The objective of this implementation is the
extension of UDP-based LoRa radio with a time disk system that complies with the principles of a
fixed TDMA approach but benefits from the efficient implementation of a relative time system
without the necessity of dealing with absolute timestamps. This way any device as a part of the
network can transmit its information in a predefined timeframe which substantially reduces signal
overlapping and therefore packet loss as a principle. Thereby the maximum network capacity and
the packet delivery rate increases.

On a raspberry pi 4 as the user you want to install LORIDANE, in terminal run
```
sudo apt-get install git
git clone https://github.com/lstebe/setupLoridane.git
cd setupLoridane
sudo sh loridaneinstall.sh
```

and follow the whiptail instructions :) Most of the actions are performed automatically.

7--------------------------------------------------------------------------------------
if you already are a raspberryPI and NodeRed User, fret not, you can simply import the flowfile. if you would like to install a mqtt broker or a raspi wifi AP (for the Loridane Gateways,e.g ) you can use the installation script as well and skip the node red steps. if you have WiFi and a MQTT broker running at you spot, you can configure the Gateway to your WiFi and MQTT. In this case, for Loridane to work install following prerequisites:

npm install node-red-dashboard
npm install node-red-contrib-fs
npm install node-red-contrib-throttle
npm install node-red-contrib-opcua
npm install node-red-node-ui-table
npm install crypto-js
npm install crypto

In addition you will have to load the packages via the setting.js file, please make the following change (Line ~410):
```
functionGlobalContext: {
  os:require('os'),
  fs:require("fs"),
  crjs:require("crypto-js"),
  crypto:require("crypto")
  }
```
