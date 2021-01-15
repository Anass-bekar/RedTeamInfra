#!/bin/bash
#Get C2 server IP address
IP="$(ping -c 1 example.domain.com | grep data |  sed 's/PING example.domain.com //' | awk '{print $1}' | tr -d '()' )"
#allow access to redirector outside of vpn network
sed "/tls-client/s/$/ \nroute-nopull \nroute ${IP} /" /tmp/redirect.ovpn > /tmp/redirector.ovpn
#install vpn
sudo apt install -y openvpn
sudo apt install -y network-manager-openvpn
openvpn --config /tmp/redirector.ovpn --daemon
#your websites ssl certificates, if not use http
chmod 600 /tmp/ssl/*
#install nginx
apt install -y nginx
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak; cp /tmp/nginx.conf /etc/nginx/nginx.conf
#configure nginx
echo "server {" > /etc/nginx/sites-enabled/default
echo  "        listen 443;" >> /etc/nginx/sites-enabled/default
echo  "          proxy_pass example.domain.com:443;" >> /etc/nginx/sites-enabled/default
echo  "}" >> /etc/nginx/sites-enabled/default
#reload our proxy
service nginx reload
