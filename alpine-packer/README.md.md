# Proxmox Alpine Linux Packer Template

This Packer configuration builds an Alpine Linux VM template for Proxmox with the YouTube Audio Downloader pre-installed.

## Prerequisites

1. **Packer installed** with Proxmox plugin
2. **Alpine Linux ISO** uploaded to Proxmox
3. **Proxmox API access** configured

## Setup Steps

### 1. Download Alpine Linux ISO

```bash
# Download Alpine Linux standard ISO
wget https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-standard-3.19.0-x86_64.iso

# Upload to Proxmox storage (via web UI or CLI)
```

### 2. Create Directory Structure

```bash
mkdir alpine-packer
cd alpine-packer
mkdir http
```

### 3. Create Files

- Copy the Packer configuration to `alpine.pkr.hcl`
- Copy the setup script to `http/setup.sh`
- Copy the variables file to `variables.pkrvars.hcl`

### 4. Configure Variables

Edit `variables.pkrvars.hcl` with your Proxmox settings:

```hcl
proxmox_url      = "https://your-proxmox-server:8006/api2/json"
proxmox_username = "root@pam"
proxmox_password = "your-actual-password"
proxmox_node     = "your-node-name"
proxmox_storage  = "your-storage-pool"
```

### 5. Install Packer Proxmox Plugin

```bash
packer init alpine.pkr.hcl
```

### 6. Build Template

```bash
# Validate configuration
packer validate -var-file="variables.pkrvars.hcl" alpine.pkr.hcl

# Build the template
packer build -var-file="variables.pkrvars.hcl" alpine.pkr.hcl
```

## What Gets Installed

- **Alpine Linux** (latest 3.19 with all updates)
- **YouTube Audio Downloader** from the specified GitHub repo
- **Node.js and npm** for the downloader
- **Python 3 and pip** with yt-dlp
- **FFmpeg** for audio processing
- **Git, curl, wget, bash** and other utilities
- **SSH server** enabled
- **QEMU guest agent** for Proxmox integration
- **Service user** (`downloader`) for running the application

## Post-Build Usage

After the template is built, you can:

1. **Create VMs from template** in Proxmox
2. **Access YouTube downloader** via command line:
   ```bash
   youtube-audio-downloader [URL]
   ```
3. **Service management** (if needed):
   ```bash
   service youtube-downloader start
   ```

## File Structure

```
alpine-packer/
├── alpine.pkr.hcl           # Main Packer configuration
├── variables.pkrvars.hcl    # Variables file
└── http/
    └── setup.sh             # Alpine setup script
```

## Troubleshooting

- **ISO not found**: Ensure Alpine ISO is uploaded to Proxmox storage
- **Network issues**: Check Proxmox bridge configuration (vmbr0)
- **Storage errors**: Verify storage pool names and permissions
- **SSH timeout**: Increase ssh_timeout in configuration if needed

## Security Notes

- Default root password is set during build (change after deployment)
- SSH root login is enabled (disable in production)
- Consider using SSH keys instead of passwords
- Update the system regularly after deployment

## Customization

To modify the installation:

1. Edit the shell provisioners in `alpine.pkr.hcl`
2. Modify `http/setup.sh` for different Alpine configurations
3. Adjust VM specifications (memory, CPU, disk) as needed
4. Add additional software installations in the provisioner blocks