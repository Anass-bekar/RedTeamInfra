# provider conf
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "1.22.2"
  }
}
}
#Token generated in your Digitalocean's admin panel
provider "digitalocean" {
  token = "your generated token"
}

data "digitalocean_ssh_key" "primary-key" {
  name = "primary-key"
}

#Aceess restriction
variable "access_addr" {
    type    = string
    default = "0.0.0.0/0"

}
#specify allowed ports
resource "digitalocean_firewall" "RedirectGroup" {
  name        = "RedirectGroup"
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["192.168.1.0/24", "2002:1:2::/48"]
  }
    inbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
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
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol         = "tcp"
    port_range       = "443"
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
#Launch the instance
resource "digitalocean_droplet" "Redirector" {
  #instance info(name,Os,specs)
  image = "ubuntu-18-04-x64"
  name = "Redirector"
  region = "fra1"
  size = "s-1vcpu-1gb"
  private_networking = true
  #ssh connection parameters
  ssh_keys = [
    data.digitalocean_ssh_key.primary-key.id
  ]
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file("~/.ssh/id_rsa")
    timeout = "2m"
  }
  #create files and execute commands with the help of ssh
    provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/ssl",
     ]
  } 
    provisioner "file" {
    source      = "ssl/server.crt"
    destination = "/tmp/ssl/server.crt"
  }
    provisioner "file" {
    source      = "ssl/private.key"
    destination = "/tmp/ssl/private.key"
  }
    provisioner "file" {
    source      = "redirect.ovpn"
    destination = "/tmp/redirect.ovpn"
  }
    provisioner "file" {
    source      = "conf.sh"
    destination = "/tmp/conf.sh"
  }
      provisioner "file" {
    source      = "nginx.conf"
    destination = "/tmp/nginx.conf"
  }
  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "export PATH=$PATH:/usr/bin",
      "apt-get update",
      "chmod +x /tmp/conf.sh",
      "/bin/bash /tmp/conf.sh",
    ]
  }
}
#print ressource's Ip address
output "IP" {
  value = digitalocean_droplet.c2Server.ipv4_address
}
