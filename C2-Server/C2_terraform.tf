#provider conf
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "1.22.2"
  }
}
}
#Your Cloud provider token
provider "digitalocean" {
  token = "your DigitalOcean Token generated from the admin panel"
}
#SSh key given name
data "digitalocean_ssh_key" "primary-key" {
  name = "primary-key"
}

#Aceess restriction
variable "access_addr" {
    type    = string
    default = "0.0.0.0/0"

}
#allowed ports
resource "digitalocean_firewall" "c2Group" {
  name        = "c2Group"
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
    port_range       = "1337"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "31337"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "55553"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "5555"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
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
    protocol              = "tcp"
    port_range            = "433"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

}
#Instance Creation
resource "digitalocean_droplet" "c2Server" {
  #Instance name,Os,Region,size(Ram,Disk...)
  image = "debian-9-x64"
  name = "c2Server"
  region = "fra1"
  size = "s-1vcpu-1gb"
  private_networking = true
  #using your own machine's ssh key that was added to the cloud provider database to connect to created instances
  ssh_keys = [
    data.digitalocean_ssh_key.primary-key.id
  ]
  #Setting ssh connection parameters
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file("~/.ssh/id_rsa")
    timeout = "2m"
  }
  #Ovpn file created by our vpn server
    provisioner "file" {
    source      = "c2.ovpn"
    destination = "/tmp/c2.ovpn"
  }
  #Executing Commands and transferring files to our Instance via ssh
      provisioner "remote-exec" {
    inline = [
      "mkdir /tmp/ssl",
     ]
  } 
    provisioner "file" {
    source      = "ssl/cert.pem"
    destination = "/tmp/ssl/cert.pem"
  }
    provisioner "file" {
    source      = "ssl/key.pem"
    destination = "/tmp/ssl/key.pem"
  }
    provisioner "file" {
    source      = "c2_setup.sh"
    destination = "/tmp/c2_setup.sh"
  }
  #Executing bash script to set up our C2 server
  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "export PATH=$PATH:/usr/bin",
      "apt-get update",
    "chmod +x /tmp/c2_setup.sh",
       "/tmp/c2_setup.sh",
    ]
  }
}
# Add an A record to the domain for www.example.com.
resource "digitalocean_record" "default" {
  domain = "Your domain"
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.c2Server.ipv4_address
}
#print Instance IP  addrress
output "IP" {
  value = digitalocean_droplet.c2Server.ipv4_address
}
