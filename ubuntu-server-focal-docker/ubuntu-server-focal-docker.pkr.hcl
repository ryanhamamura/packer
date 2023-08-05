# Ubuntu Server Focal 
# ---
# Packer Template to create an Ubuntu Server (Focal) on Proxmox 
packer {
  required_plugins {
    proxmox = {
      version = ">=1.1.2"
      source = "github.com/hashicorp/proxmox"
    }
  }
}

# Variable Definitions
variable "proxmox_api_url" {
  type = string 
}

variable "proxmox_api_token_id" {
  type = string 
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true 
}

variable "ssh_username" {
  type = string
}

variable "ssh_private_key_file" {
  type = string 
}

# Resource Definition for the VM template 
source "proxmox" "ubuntu-server-focal-docker" {

  # Proxmox connection settings
  proxmox_url = "${var.proxmox_api_url}"
  username = "${var.proxmox_api_token_id}"
  token = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true 

  # VM General Settings 
  node = "proxmox" # name of the proxmox instance
  vm_id = "902" # can comment this out and proxmox will use next available
  vm_name = "ubuntu-server-focal-docker"
  template_description = "Ubuntu Server Focal Image with Docker pre-installed"

  # VM OS Settings 
  # (Option 1) Local ISO file
  iso_file = "local:iso/ubuntu-20.04.5-live-server-amd64.iso"
  # - or - 
  # (Option 2) Download ISO 
  # iso_url = ""
  # iso_checksum = ""
  iso_storage_pool = "local"
  unmount_iso = true 

  # VM System Settings 
  qemu_agent = true 

  # VM Hard Disk Settings 
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size = "32G"
    format = "raw"
    storage_pool = "local-lvm"
    storage_pool_type = "lvm"
    type = "virtio"
  }

  # VM CPU Settings 
  cores = "4"

  # VM Memory Settings 
  memory = "4096" 

  # VM Network Settings 
  network_adapters {
    model = "virtio"
    bridge = "vmbr0"
    firewall = "false"
  }

  # VM Cloud-Init Settings 
  cloud_init = true 
  cloud_init_storage_pool = "local-lvm"


  # Packer Autoinstall Settings 
  http_directory = "http"
  # (Optional) Bind IP Address and Port 
  # http_bind_address = "0.0.0.0"
  #http_bind_address = "192.168.55.70"
  http_port_min = 8802
  http_port_max = 8802
  
  # Packer Boot Commands 
  boot_command = [
    "<esc><wait><esc><wait>",
    "<f6><wait><esc><wait>",
    "<bs><bs><bs><bs><bs>",
    "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    #"autoinstall ds=nocloud-net;s=http://192.168.55.70:80/",
    "--- <enter>"
  ]
  boot = "c"
  boot_wait = "5s"

  ssh_username = "${var.ssh_username}"

  # (Option 1) Add your password here
  # ssh_password = "your_pasword"
  # - or - 
  # (Option 2) Add your Private SSH Key file here
  ssh_private_key_file = "${var.ssh_private_key_file}"

  # Raise the timeout if installation is taking too long 
  ssh_timeout = "20m" 
}

build {

  name = "ubuntu-server-focal-docker"
  sources = ["source.proxmox.ubuntu-server-focal-docker"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox 
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  provisioner "file" {
    source = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  
  provisioner "shell" {
    inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",
      "sudo apt-get install -y docker-compose-plugin"
    ]
  }
}
