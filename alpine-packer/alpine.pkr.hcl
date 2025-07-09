packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variables
variable "proxmox_url" {
  type        = string
  description = "Proxmox API URL"
  default     = "https://your-proxmox-server:8006/api2/json"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox username"
  default     = "root@pam"
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox password"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve"
}

variable "proxmox_storage" {
  type        = string
  description = "Proxmox storage pool"
  default     = "local-lvm"
}

variable "iso_storage" {
  type        = string
  description = "ISO storage location"
  default     = "local"
}

variable "vm_name" {
  type        = string
  description = "VM template name"
  default     = "alpine-youtube-downloader"
}

# Source configuration
source "proxmox-iso" "alpine" {
  # Proxmox connection
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM configuration
  vm_name              = var.vm_name
  vm_id                = 9000
  memory               = 2048
  cores                = 2
  cpu_type             = "host"
  scsi_controller      = "virtio-scsi-pci"
  qemu_agent           = true
  cloud_init           = true
  cloud_init_storage_pool = var.proxmox_storage

  # Network
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  # Storage
  disks {
    type              = "scsi"
    disk_size         = "20G"
    storage_pool      = var.proxmox_storage
    storage_pool_type = "lvm"
    format            = "raw"
  }

  # ISO configuration
  iso_file         = "local:iso/alpine-standard-3.19.0-x86_64.iso"
  iso_storage_pool = var.iso_storage
  unmount_iso      = true

  # Boot configuration
  boot_wait = "10s"
  boot_command = [
    "root<enter><wait>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
    "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/setup.sh<enter><wait5>",
    "chmod +x setup.sh<enter>",
    "./setup.sh<enter><wait>"
  ]

  # HTTP server for serving setup files
  http_directory = "http"
  http_port_min  = 8000
  http_port_max  = 8100

  # SSH configuration
  ssh_username = "root"
  ssh_password = "alpine"
  ssh_timeout  = "15m"

  # Template configuration
  template_name        = var.vm_name
  template_description = "Alpine Linux with YouTube Audio Downloader"
}

# Build configuration
build {
  sources = ["source.proxmox-iso.alpine"]

  # Wait for system to be ready
  provisioner "shell" {
    inline = [
      "sleep 30"
    ]
  }

  # Update system and install dependencies
  provisioner "shell" {
    inline = [
      "apk update",
      "apk upgrade",
      "apk add --no-cache git python3 py3-pip nodejs npm curl wget bash sudo",
      "python3 -m pip install --upgrade pip"
    ]
  }

  # Install YouTube audio downloader
  provisioner "shell" {
    inline = [
      "cd /opt",
      "git clone https://github.com/jacobalvarad0/youtube-audio-downloader.git",
      "cd youtube-audio-downloader",
      "npm install",
      "chmod +x *.js",
      "ln -s /opt/youtube-audio-downloader/download.js /usr/local/bin/youtube-audio-downloader"
    ]
  }

  # Install yt-dlp (modern youtube-dl alternative)
  provisioner "shell" {
    inline = [
      "python3 -m pip install yt-dlp",
      "apk add --no-cache ffmpeg"
    ]
  }

  # Create service user
  provisioner "shell" {
    inline = [
      "adduser -D -s /bin/bash downloader",
      "echo 'downloader ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers",
      "chown -R downloader:downloader /opt/youtube-audio-downloader"
    ]
  }

  # Setup system service (optional)
  provisioner "shell" {
    inline = [
      "mkdir -p /etc/init.d",
      "cat > /etc/init.d/youtube-downloader << 'EOF'",
      "#!/sbin/openrc-run",
      "",
      "name=\"YouTube Audio Downloader\"",
      "description=\"YouTube Audio Downloader Service\"",
      "command=\"/usr/local/bin/youtube-audio-downloader\"",
      "command_user=\"downloader\"",
      "pidfile=\"/var/run/youtube-downloader.pid\"",
      "",
      "depend() {",
      "    need net",
      "}",
      "EOF",
      "chmod +x /etc/init.d/youtube-downloader"
    ]
  }

  # Install qemu-guest-agent
  provisioner "shell" {
    inline = [
      "apk add --no-cache qemu-guest-agent",
      "rc-update add qemu-guest-agent default"
    ]
  }

  # Enable SSH
  provisioner "shell" {
    inline = [
      "apk add --no-cache openssh",
      "rc-update add sshd default",
      "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
    ]
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "apk cache clean",
      "rm -rf /var/cache/apk/*",
      "rm -rf /tmp/*",
      "history -c"
    ]
  }

  # Final system configuration
  provisioner "shell" {
    inline = [
      "echo 'Template build completed successfully!'",
      "echo 'YouTube Audio Downloader installed in /opt/youtube-audio-downloader'",
      "echo 'Service user: downloader'",
      "echo 'Command available: youtube-audio-downloader'"
    ]
  }
}
