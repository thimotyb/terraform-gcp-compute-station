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
# Install Kubernetes Tooling
#######################################
echo "Installing kubectl and Minikube..."

# Add Google Cloud apt repo for kubectl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubectl

# Install Minikube
curl -Lo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x /usr/local/bin/minikube

# Quick version checks
kubectl version --client=true
minikube version

echo "kubectl and Minikube installed successfully"

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
# Install Google Chrome & VS Code
#######################################
echo "Installing Google Chrome and Visual Studio Code..."

install -m 0755 -d /usr/share/keyrings

# Google Chrome repository
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
  gpg --dearmor -o /usr/share/keyrings/google-linux.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-linux.gpg] \
  http://dl.google.com/linux/chrome/deb/ stable main" \
  > /etc/apt/sources.list.d/google-chrome.list

# Visual Studio Code repository
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list

apt-get update
apt-get install -y google-chrome-stable code

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
else
    # If user already exists, ensure it's in docker group
    usermod -aG docker ubuntu 2>/dev/null || true
fi

# Ensure ubuntu user is in docker group (redundant but safe)
usermod -aG docker ubuntu 2>/dev/null || true

# Add any OS Login users to docker group automatically
cat >> /etc/profile.d/docker-group.sh <<'EOF'
# Automatically add new users to docker group
if ! groups | grep -q docker; then
    sudo usermod -aG docker $USER 2>/dev/null || true
fi
EOF

chmod +x /etc/profile.d/docker-group.sh

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
# Install Git Credential Manager
#######################################
echo "Installing Git Credential Manager..."

# Download latest Git Credential Manager
GCM_VERSION="2.6.0"
wget -q https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.deb -O /tmp/gcm-linux.deb

# Install GCM
apt-get install -y /tmp/gcm-linux.deb

# Configure Git to use GCM globally (non-interactive)
if HOME=/root git-credential-manager configure; then
  echo "Git Credential Manager configured successfully"
else
  echo "Warning: Git Credential Manager configure step failed (continuing)" >&2
fi

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

# Expose Node.js binaries system-wide
CURRENT_NODE="$(nvm current)"
NVM_BIN="${NVM_DIR}/versions/node/${CURRENT_NODE}/bin"

ln -sf "${NVM_BIN}/node" /usr/local/bin/node
ln -sf "${NVM_BIN}/npm" /usr/local/bin/npm
ln -sf "${NVM_BIN}/npx" /usr/local/bin/npx

# Provide an executable wrapper for nvm so the command is always available
cat > /usr/local/bin/nvm <<'EOF'
#!/usr/bin/env bash
export NVM_DIR="/usr/local/nvm"
if [ -s "${NVM_DIR}/nvm.sh" ]; then
  # shellcheck source=/dev/null
  . "${NVM_DIR}/nvm.sh"
  nvm "$@"
else
  echo "nvm shim: /usr/local/nvm/nvm.sh not found" >&2
  exit 1
fi
EOF

chmod +x /usr/local/bin/nvm
chmod -R a+rx /usr/local/nvm

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
# Install Claude CLI
#######################################
echo "Installing Claude CLI..."

# Install Claude CLI via npm (requires Node.js from NVM)
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Claude CLI globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version || echo "Claude CLI installed, version check failed (may need API key setup)"

# Ensure Claude CLI is on the global PATH
if [[ -x "${NVM_BIN}/claude" ]]; then
  ln -sf "${NVM_BIN}/claude" /usr/local/bin/claude
fi

#######################################
# Install Codex CLI
#######################################
echo "Installing Codex CLI..."

npm install -g @openai/codex

if [[ -x "${NVM_BIN}/codex" ]]; then
  ln -sf "${NVM_BIN}/codex" /usr/local/bin/codex
fi

codex --version || echo "Warning: Codex CLI installation may have failed" >&2

#######################################
# Configure XFCE Panel Launchers
#######################################
echo "Setting up XFCE panel launchers for Chrome and VS Code..."

cat > /usr/local/bin/configure-xfce-panel.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SENTINEL="${HOME}/.config/.panel-configured"

if [[ -f "${SENTINEL}" ]]; then
  exit 0
fi

if ! command -v xfconf-query >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$(dirname "${SENTINEL}")"

PANEL_PROP="/panels/panel-1/plugin-ids"
GLOBAL_PROP="/plugins/plugin-ids"

readarray -t PANEL_IDS < <(xfconf-query -c xfce4-panel -p "${PANEL_PROP}" 2>/dev/null || true)
readarray -t GLOBAL_IDS < <(xfconf-query -c xfce4-panel -p "${GLOBAL_PROP}" 2>/dev/null || true)

contains_id() {
  local id=$1
  shift
  local item
  for item in "$@"; do
    if [[ "${item}" == "${id}" ]]; then
      return 0
    fi
  done
  return 1
}

write_uint_array() {
  local property=$1
  shift
  local -a values=("$@")
  local -a args=()
  local value
  for value in "${values[@]}"; do
    args+=(-t uint -s "${value}")
  done
  if ((${#args[@]})); then
    xfconf-query -c xfce4-panel -p "${property}" "${args[@]}"
  fi
}

add_launcher() {
  local plugin_id=$1
  shift
  local -a items=("$@")

  if ! contains_id "${plugin_id}" "${PANEL_IDS[@]}"; then
    PANEL_IDS+=("${plugin_id}")
  fi

  if ! contains_id "${plugin_id}" "${GLOBAL_IDS[@]}"; then
    GLOBAL_IDS+=("${plugin_id}")
  fi

  if ! xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}" -s launcher -t string >/dev/null 2>&1; then
    xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}" -n -t string -s launcher >/dev/null 2>&1 || true
  fi

  xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/items" --reset >/dev/null 2>&1 || true

  local -a item_args=()
  local item
  for item in "${items[@]}"; do
    item_args+=(-t string -s "${item}")
  done

  if ((${#item_args[@]})); then
    xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/items" -n "${item_args[@]}" >/dev/null 2>&1 || \
      xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/items" "${item_args[@]}"
  fi
}

add_launcher 200 google-chrome.desktop
add_launcher 201 code.desktop

write_uint_array "${PANEL_PROP}" "${PANEL_IDS[@]}"
write_uint_array "${GLOBAL_PROP}" "${GLOBAL_IDS[@]}"

xfce4-panel --restart >/dev/null 2>&1 || true

touch "${SENTINEL}"
rm -f "${HOME}/.config/autostart/configure-xfce-panel.desktop"
EOF

chmod +x /usr/local/bin/configure-xfce-panel.sh

for target in /etc/skel /home/ubuntu; do
  mkdir -p "${target}/.config/autostart"
  cat > "${target}/.config/autostart/configure-xfce-panel.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Configure XFCE Panel
Exec=/usr/local/bin/configure-xfce-panel.sh
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
EOF
done

chown -R ubuntu:ubuntu /home/ubuntu/.config

echo "Claude CLI installed successfully"

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
echo "- Claude CLI: $(source /usr/local/nvm/nvm.sh && claude --version 2>/dev/null || echo 'installed')"
echo "- kubectl: $(kubectl version --client --short || echo 'installed')"
echo "- Minikube: $(minikube version)"
echo "- Codex CLI: $(codex --version 2>/dev/null || echo 'installed via npm')"
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
