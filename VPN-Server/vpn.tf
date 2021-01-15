# provider configuration
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "1.22.2"
  }
}
}
#A token generated in your cloud provider panel
provider "digitalocean" {
  token = "your DigitalOcean generated token"
}
#ssh key added to cloud provider database
data "digitalocean_ssh_key" "primary-key" {
  name = "primary-key"
}

#Aceess restriction
variable "access_addr" {
    type    = string
    default = "0.0.0.0/0"

}
#define allowed ports
resource "digitalocean_firewall" "vpnGroup" {
  name        = "vpnGroup"
  #droplet_ids = [digitalocean_droplet.web.id]
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["192.168.1.0/24", "2002:1:2::/48"]
  }

  inbound_rule {
    protocol         = "udp"
    port_range       = "1194"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
}
#launch instance
resource "digitalocean_droplet" "vpn_server" {
  #Instance details(name,os,specifications...)
  image = "ubuntu-18-04-x64"
  name = "vpn-server"
  region = "fra1"
  size = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.primary-key.id
  ]
  #Ssh connection parameters
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file("~/.ssh/id_rsa")
    timeout = "2m"
  }
  #transfer neccessary files and execute commands over ssh
    provisioner "file" {
    source      = "openvpn-install.sh"
    destination = "/tmp/openvpn-install.sh"
  }
    provisioner "file" {
    source      = "config.sh"
    destination = "/tmp/config.sh"
  }
  provisioner "remote-exec" {
    inline = [
    "chmod +x /tmp/config.sh",
    "/bin/bash /tmp/config.sh",
    ]
  }
  #dowload client vpn files from the vpn server via ssh
  provisioner "local-exec" {
   command="scp -o StrictHostKeyChecking=no root@${self.ipv4_address}:/root/redirect.ovpn ../serverless-redirector"
  }
    provisioner "local-exec" {
   command="scp -o StrictHostKeyChecking=no root@${self.ipv4_address}:/root/c2.ovpn ../base-c2"
  }
    provisioner "local-exec" {
   command="scp -o StrictHostKeyChecking=no root@${self.ipv4_address}:/root/client.ovpn ../base-vpn"

  }
}
#print Ip addrress
output "IP" {
  value = digitalocean_droplet.vpn_server.ipv4_address
}
