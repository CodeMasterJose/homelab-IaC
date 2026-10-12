packer {
  required_plugins {
    name = {
      version = "~> 1"
      source = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" { type = string, default = "${env("PROXMOX_URL")}"}
variable "proxmox_username" { type = string, default = "${env("PROXMOX_USERNAME")}"}
variable "proxmox_token" { type = string, default = "${env("PROXMOX_TOKEN")}", sensitive = true}
variable "proxmox_node" { type = string, default = "${env("PROXMOX_NODE")}"}

source "proxmox-iso" "ubuntu-server" {
  proxmox_url = var.proxmox_url
  username = var.proxmox_username
  token = var.proxmox_token
  insecure_skip_tls_verify = true

  node = var.proxmox_node
  vm_id = 9000
  vm_name = "ubuntu-26"
  template_description = "Ubuntu 26 Server Base Image"

  iso_file = "local:/iso/ubuntu-26.04.1-live-server-amd64.iso"
  iso_storage_pool = "local"
  unverified = true

  os = "l26"
  cores = 2
  memory = 2048
  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    model = "virtio"
    bridge = "vmbr0"
  }

  disks {
    type = "scsi"
    disk_size = "20G"
    storage_pool = "local-lvm"
  }

  cloud_init = true
  clout_init_storage_pool = "local-lvm"

  http_directory = "http"

  boot_commad = [
    "e<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]
  boot_wait = "5s"

  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_timeout = "20m"
}

build {
  sources = ["source.proxmox-iso.ubuntu-server"]

  provisioner "shell" {
    inline = [
      # Wait for the cloud-init installation process to completely finish
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 2; done",
      
      # Clean up the machine-id so cloned VMs get unique IP addresses from your DHCP server
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "sudo apt-get clean",
      "sudo sync"
    ]
  }
}
