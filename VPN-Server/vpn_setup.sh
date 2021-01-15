#!/bin/sh
#Setting up the environnement and updating
export PATH=$PATH:/usr/bin
apt-get update
#Installing a vpn server 
chmod +x /tmp/openvpn-install.sh
AUTO_INSTALL=y /tmp/openvpn-install.sh
#Modifying installation script to add a C2 new user
sed '1001s/.*/CLIENT=c2/' /tmp/openvpn-install.sh > /tmp/openvpn.sh
chmod +x /tmp/openvpn.sh
AUTO_INSTALL=y /tmp/openvpn.sh
#Modifying installation script to add a Redirector proxy new user
sed '1001s/.*/CLIENT=redirect/' /tmp/openvpn-install.sh > /tmp/openvpn-final.sh
chmod +x /tmp/openvpn-final.sh
AUTO_INSTALL=y /tmp/openvpn-final.sh
