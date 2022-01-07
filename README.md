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

on a raspberry pi 4 as the user you want to install LORIDANE, in terminal run
sudo apt-get install git
git clone https://github.com/lstebe/setupLoridane.git
cd setupLoridane
sudo sh loridaneinstall.sh

and follow the whiptail instructions :)

if you already are a raspberryPI and NodeRed User, fret not, you can simply import the flowfile. if you would like to install a mqtt broker or a raspi wifi AP (for the Loridane Gateways,e.g ) you can use the installation script as well and skip the node red steps. if you have WiFi and a MQTT broker running at you spot, you can configure the Gateway to your WiFi and MQTT.
