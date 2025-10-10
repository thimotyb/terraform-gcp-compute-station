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

# Install PulseAudio module for XRDP (improves audio and clipboard support)
apt-get install -y pulseaudio

# Configure PulseAudio for XRDP users
cat > /etc/pulse/default.pa.d/xrdp.pa <<'EOF'
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulseaudio-socket
EOF

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
# Install Git Credential Manager
#######################################
echo "Installing Git Credential Manager..."

# Download latest Git Credential Manager
GCM_VERSION="2.6.0"
wget -q https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.deb -O /tmp/gcm-linux.deb

# Install GCM
apt-get install -y /tmp/gcm-linux.deb

# Configure Git to use GCM globally
git-credential-manager configure

# Clean up
rm /tmp/gcm-linux.deb

echo "Git Credential Manager installed successfully"

#######################################
# Install GitHub CLI
#######################################
echo "Installing GitHub CLI..."

# Add GitHub CLI GPG key and repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

# Update and install GitHub CLI
apt-get update
apt-get install -y gh

echo "GitHub CLI installed successfully"

#######################################
# Install NVM and Node.js
#######################################
echo "Installing NVM and Node.js..."

# Install NVM for all users
export NVM_DIR="/usr/local/nvm"
mkdir -p "$NVM_DIR"

# Download and install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | NVM_DIR="$NVM_DIR" bash

# Load NVM
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install latest LTS version of Node.js
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

# Make NVM available to all users
cat >> /etc/profile.d/nvm.sh <<'EOF'
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

chmod +x /etc/profile.d/nvm.sh

# Add NVM to ubuntu user's profile
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        cat >> "$user_home/.bashrc" <<'EOF'

# NVM configuration
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
        chown $username:$username "$user_home/.bashrc"
    fi
done

echo "NVM and Node.js installed successfully"

#######################################
# Install SDKMAN
#######################################
echo "Installing SDKMAN..."

# Install dependencies for SDKMAN
apt-get install -y zip unzip curl sed

# Install SDKMAN for ubuntu user
export SDKMAN_DIR="/usr/local/sdkman"
curl -s "https://get.sdkman.io" | bash

# Source SDKMAN
export SDKMAN_DIR="/usr/local/sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Make SDKMAN available to all users
cat >> /etc/profile.d/sdkman.sh <<EOF
export SDKMAN_DIR="/usr/local/sdkman"
[[ -s "\$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "\$SDKMAN_DIR/bin/sdkman-init.sh"
EOF

chmod +x /etc/profile.d/sdkman.sh

# Add SDKMAN to ubuntu user's profile
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        cat >> "$user_home/.bashrc" <<'EOF'

# SDKMAN configuration
export SDKMAN_DIR="/usr/local/sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF
        chown $username:$username "$user_home/.bashrc"
    fi
done

# Install latest Java with SDKMAN (optional, comment out if not needed)
source "$SDKMAN_DIR/bin/sdkman-init.sh"
sdk install java 21.0.5-tem < /dev/null
sdk install gradle < /dev/null
sdk install maven < /dev/null

echo "SDKMAN installed successfully"

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
echo "- Git Credential Manager: $(git-credential-manager --version)"
echo "- GitHub CLI: $(gh --version | head -n1)"
echo "- Node.js: $(source /usr/local/nvm/nvm.sh && node --version) (via NVM)"
echo "- npm: $(source /usr/local/nvm/nvm.sh && npm --version)"
echo "- Java: $(source /usr/local/sdkman/bin/sdkman-init.sh && java -version 2>&1 | head -n1)"
echo "- SDKMAN: $(source /usr/local/sdkman/bin/sdkman-init.sh && sdk version)"
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
