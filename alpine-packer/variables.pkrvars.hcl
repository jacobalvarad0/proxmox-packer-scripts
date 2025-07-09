# variables.pkrvars.hcl
# Copy this file and customize for your environment

# Proxmox server settings
proxmox_url      = "https://your-proxmox-server:8006/api2/json"
proxmox_username = "root@pam"
proxmox_password = "your-proxmox-password"
proxmox_node     = "pve"

# Storage settings
proxmox_storage = "local-lvm"
iso_storage     = "local"

# VM settings
vm_name = "alpine-youtube-downloader-template"
