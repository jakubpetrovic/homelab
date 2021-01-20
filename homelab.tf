terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
}

variable "domain" {
  default = "home.lab"
}

variable "rootdiskBytes" {
    default = 1024*1024*1024*30
}

variable "templatePath" {
    default = "/mnt/md0/kvm"
}

provider "libvirt" {
  uri = "qemu:///system"
}

#TODO fix download image within this tf file
#Create base template for all VMS
# resource "libvirt_volume" "os_image" {
#   name = "ubuntu-template.qcow2"
#   pool = "default"
#   source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
#   format = "qcow2"
# }

##-----ELASTIC01-----

#TODO fix cloudinit network setup
# Use CloudInit ISO to add various things to the base iso
resource "libvirt_cloudinit_disk" "elastic01_init" {
          name = "elastic01-commoninit.iso"
          pool = "default"
          user_data = data.template_file.elastic01_user_data.rendered
          #network_config = data.template_file.elastic01_network_config.rendered
}

data "template_file" "elastic01_user_data" {
  template = file("${path.module}/cloud_init/cloud_init_base.cfg")
  vars = {
    hostname = "elastic01"
    fqdn = "elastic01${var.domain}"
  }
}

#elastic01 cloud init network config
data "template_file" "elastic01_network_config" {
  template = file("${path.module}/cloud_init/network_config.cfg")
  vars = {
      addresses = "192.168.100.10/24"
      gateway = "192.168.100.1"
      nsaddresses = "8.8.8.8"
      searchdomain = "home.lab"
  }
}


#create elastic01 osdisk - link from ubuntu-template
resource "libvirt_volume" "elastic01_os_image" {
  name = "elastic01.qcow2"
  
  # can specify size larger than backing disk
  # but would need to be extended at OS level to be recognized
  size = var.rootdiskBytes

  # parent disk
  base_volume_pool = "default"
  base_volume_name = "ubuntu-template.qcow2"
}  

# resource "libvirt_volume" "elastic01_os_image" {
#   name = "elastic01.qcow2"
#   pool = "default"
#   source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
#   format = "qcow2"
# }

#create elastic01 VM
resource "libvirt_domain" "domain-ubuntu" {
  name = "elastic01"
  memory = 2048
  vcpu = 2

  disk {
       volume_id = libvirt_volume.elastic01_os_image.id
  }
  network_interface {
       network_name = "default"
  }

  cloudinit = libvirt_cloudinit_disk.elastic01_init.id

console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}

##-----ELASTIC02-----
#TODO add more VMS


terraform { 
  required_version = ">= 0.12"
}

