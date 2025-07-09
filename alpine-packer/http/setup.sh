#!/bin/sh

# Alpine Linux automated setup script for Packer

# Set up repositories
cat > /etc/apk/repositories << 'EOF'
https://dl-cdn.alpinelinux.org/alpine/v3.19/main
https://dl-cdn.alpinelinux.org/alpine/v3.19/community
EOF

# Update package index
apk update

# Install basic system packages
apk add --no-cache \
    openssh \
    sudo \
    curl \
    wget \
    bash \
    nano \
    htop \
    git

# Set root password (will be changed later)
echo "root:alpine" | chpasswd

# Configure SSH
rc-update add sshd default
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Configure networking
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Enable networking service
rc-update add networking default

# Setup system
setup-alpine -f << 'EOF'
us
us
alpine
eth0
dhcp
n
n
y
none
none
openssh
chrony
y
EOF

# Wait for setup to complete
sleep 5

# Enable SSH for Packer
service sshd start

echo "Alpine Linux setup completed successfully!"
echo "SSH is now available for Packer provisioning."