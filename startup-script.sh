#!/bin/bash
#######################################################
# Startup Script for Ubuntu 22.04 Workstation
# Installs: Docker, Docker Compose, Xfce Desktop, XRDP
#######################################################

set -e

# Log file
LOG_FILE="/var/log/startup-script.log"
exec > >(tee -a ${LOG_FILE})
exec 2>&1

echo "========================================="
echo "Starting Ubuntu Workstation Setup"
echo "Date: $(date)"
echo "========================================="

# Update system
echo "Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    git \
    vim \
    net-tools

#######################################
# Install Docker
#######################################
echo "Installing Docker..."

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Verify Docker installation
docker --version
docker compose version

echo "Docker and Docker Compose installed successfully"

#######################################
# Install Xfce Desktop Environment
#######################################
echo "Installing Xfce desktop environment..."

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    dbus-x11 \
    x11-xserver-utils

echo "Xfce desktop installed successfully"

#######################################
# Install and Configure XRDP
#######################################
echo "Installing XRDP..."

apt-get install -y xrdp

# Configure XRDP to use Xfce
echo "xfce4-session" > /etc/skel/.xsession
echo "xfce4-session" > /root/.xsession

# Create .xsession for existing users
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        echo "xfce4-session" > "$user_home/.xsession"
        chown $username:$username "$user_home/.xsession"
    fi
done

# Configure XRDP to start Xfce
cat > /etc/xrdp/startwm.sh <<'EOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi

# Start Xfce session
startxfce4
EOF

chmod +x /etc/xrdp/startwm.sh

# Configure XRDP settings
sed -i 's/max_bpp=32/max_bpp=128/g' /etc/xrdp/xrdp.ini
sed -i 's/xserverbpp=24/xserverbpp=128/g' /etc/xrdp/xrdp.ini

# Add xrdp user to ssl-cert group
adduser xrdp ssl-cert

# Enable and start XRDP service
systemctl enable xrdp
systemctl start xrdp

# Allow console sessions
sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config || echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

echo "XRDP installed and configured successfully"

#######################################
# Configure Firewall (UFW)
#######################################
echo "Configuring firewall..."

apt-get install -y ufw

# Allow SSH and RDP
ufw allow 22/tcp
ufw allow 3389/tcp

# Enable firewall (non-interactive)
echo "y" | ufw enable

echo "Firewall configured successfully"

#######################################
# Create default user for RDP access
#######################################
echo "Creating default user 'ubuntu'..."

# Check if user exists
if ! id "ubuntu" &>/dev/null; then
    useradd -m -s /bin/bash ubuntu
    echo "ubuntu:ChangeMe123!" | chpasswd
    usermod -aG sudo ubuntu
    usermod -aG docker ubuntu

    # Create .xsession for ubuntu user
    echo "xfce4-session" > /home/ubuntu/.xsession
    chown ubuntu:ubuntu /home/ubuntu/.xsession

    echo "User 'ubuntu' created with password 'ChangeMe123!' - PLEASE CHANGE THIS PASSWORD"
fi

#######################################
# Additional tools
#######################################
echo "Installing additional tools..."

apt-get install -y \
    firefox \
    htop \
    tree \
    unzip \
    zip

#######################################
# Install Google Chrome
#######################################
echo "Installing Google Chrome..."

# Download Chrome
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb

# Install Chrome
apt-get install -y /tmp/google-chrome-stable_current_amd64.deb

# Clean up
rm /tmp/google-chrome-stable_current_amd64.deb

echo "Google Chrome installed successfully"

#######################################
# Install Visual Studio Code
#######################################
echo "Installing Visual Studio Code..."

# Add Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg

# Add VS Code repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list

# Update and install VS Code
apt-get update
apt-get install -y code

echo "Visual Studio Code installed successfully"

#######################################
# Cleanup
#######################################
echo "Cleaning up..."
apt-get autoremove -y
apt-get clean

#######################################
# Final status
#######################################
echo "========================================="
echo "Ubuntu Workstation Setup Complete!"
echo "Date: $(date)"
echo "========================================="
echo ""
echo "Installed components:"
echo "- Docker version: $(docker --version)"
echo "- Docker Compose version: $(docker compose version)"
echo "- Xfce Desktop Environment"
echo "- XRDP Server"
echo "- Google Chrome: $(google-chrome --version)"
echo "- Visual Studio Code: $(code --version | head -n1)"
echo ""
echo "Default user: ubuntu"
echo "Default password: ChangeMe123! (CHANGE THIS!)"
echo ""
echo "RDP Port: 3389"
echo "SSH Port: 22"
echo ""
echo "To connect via RDP:"
echo "1. Direct: Use Remote Desktop to connect to the VM's public IP"
echo "2. IAP Tunnel: gcloud compute start-iap-tunnel <instance-name> 3389 --local-host-port=localhost:3389 --zone=<zone>"
echo ""
echo "========================================="

# Create a marker file to indicate script completion
touch /var/log/startup-script-complete
