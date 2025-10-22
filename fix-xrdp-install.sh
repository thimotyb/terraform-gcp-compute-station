#!/bin/bash
#######################################################
# Fix XRDP Installation on Existing VM
# Run this script on the VM to complete the setup
#######################################################

set -e

LOG_FILE="/var/log/fix-xrdp-install.log"
exec > >(tee -a ${LOG_FILE})
exec 2>&1

echo "========================================="
echo "Starting XRDP Fix Installation"
echo "Date: $(date)"
echo "========================================="

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
# Verify XRDP Status
#######################################
echo ""
echo "========================================="
echo "XRDP Installation Complete!"
echo "========================================="
echo ""
echo "XRDP Service Status:"
systemctl status xrdp --no-pager
echo ""
echo "Listening Ports:"
ss -tlnp | grep 3389
echo ""
echo "========================================="
