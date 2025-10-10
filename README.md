# GCP Ubuntu Workstation with Docker, Xfce, and XRDP

This Terraform configuration creates a cost-optimized Ubuntu 22.04 workstation on Google Cloud Platform with:

- **32GB RAM** and **1TB disk** (using `e2-highmem-4` machine type - most cost-effective at ~$132/month)
- **Docker** and **Docker Compose** (latest versions)
- **Xfce Desktop Environment**
- **XRDP** for Windows Remote Desktop access
- **IAP (Identity-Aware Proxy)** support for secure browser-based access

## 📋 Prerequisites

1. **GCP Account** with billing enabled
2. **Terraform** installed (>= 0.12)
3. **gcloud CLI** installed and authenticated
4. **Service Account credentials** JSON file

## 🚀 Quick Start

### 1. Configure Variables

Edit `terraform.tfvars` and update:

```hcl
user_email = "your-email@gmail.com"  # Your GCP account email
```

### 2. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Wait for Deployment

The VM creation takes ~5-10 minutes. The startup script installs all software automatically.

**Monitor the startup script progress:**

```bash
# Follow the installation logs in real-time
gcloud compute ssh ubuntu-workstation --zone=europe-west4-a --project=cegeka-gcp-awareness --command="sudo tail -f /var/log/startup-script.log"

# Check if the startup script has completed
gcloud compute ssh ubuntu-workstation --zone=europe-west4-a --project=cegeka-gcp-awareness --command="ls -l /var/log/startup-script-complete"
```

When you see the file `/var/log/startup-script-complete`, the installation is complete and you can connect via RDP.

### 4. Get Connection Info

After deployment completes:

```bash
terraform output rdp_connection_info
```

## 🔐 Connection Methods

### Method 1: Direct RDP (Simple but less secure)

1. Open **Windows Remote Desktop** (`mstsc.exe`)
2. **Before connecting**, click **Show Options**
3. Go to **Local Resources** tab
4. Under **Local devices and resources**, ensure **Clipboard** is checked
5. Enter the public IP shown in terraform output
6. Username: `ubuntu`
7. Password: `ChangeMe123!` (change immediately!)

**Note:** Clipboard sharing (copy/paste) should work automatically. If you have issues, see the Troubleshooting section.

### Method 2: IAP Tunnel (Recommended - Secure)

#### Option A: gcloud Command Line

```bash
# Create IAP tunnel
gcloud compute start-iap-tunnel ubuntu-workstation 3389 \
  --local-host-port=localhost:3389 \
  --zone=europe-west4-a \
  --project=cegeka-gcp-awareness

# Then connect via Remote Desktop to: localhost:3389
```

#### Option B: IAP Desktop Application (Best for Windows)

IAP Desktop is like Azure Bastion but for GCP - provides browser-based or application-based RDP access.

1. **Download IAP Desktop**: https://github.com/GoogleCloudPlatform/iap-desktop/releases
2. **Install** the Windows application
3. **Launch** and authenticate with your GCP account
4. **Select your project** (`cegeka-gcp-awareness`)
5. **Find your VM** (`ubuntu-workstation`) and double-click to connect

**Features:**
- No public IP required (can be disabled in `compute-instance.tf`)
- Automatic tunnel management
- Multi-tab support for multiple VMs
- Session recording
- Clipboard integration

### Method 3: Browser-Based Access (Like Azure Bastion)

While GCP doesn't have an exact Azure Bastion equivalent, you can use:

1. **GCP Console Serial Console**: Limited functionality
2. **IAP Desktop in browser mode**: Coming soon in future versions
3. **Third-party solutions**: Guacamole, Apache Guacamole on GCP

### Method 4: SSH Access

Connect via SSH to run commands or troubleshoot:

```bash
# SSH to the instance
gcloud compute ssh ubuntu-workstation --zone=europe-west4-a --project=cegeka-gcp-awareness

# SSH with specific user
gcloud compute ssh ubuntu@ubuntu-workstation --zone=europe-west4-a --project=cegeka-gcp-awareness
```

**Note:** OS Login is enabled, so gcloud will use your Google identity for SSH authentication.

## 📤 Transferring Files to the VM

### Upload files using gcloud scp

```bash
# Upload a single file
gcloud compute scp /path/to/your/file.zip ubuntu-workstation:/home/ubuntu/ --zone=europe-west4-a --project=cegeka-gcp-awareness

# Upload with specific user
gcloud compute scp /path/to/your/file.zip ubuntu@ubuntu-workstation:/home/ubuntu/ --zone=europe-west4-a --project=cegeka-gcp-awareness

# Upload entire folder (recursive)
gcloud compute scp --recurse /path/to/folder ubuntu-workstation:/home/ubuntu/ --zone=europe-west4-a --project=cegeka-gcp-awareness

# Upload multiple files
gcloud compute scp /path/to/*.zip ubuntu-workstation:/home/ubuntu/ --zone=europe-west4-a --project=cegeka-gcp-awareness
```

### Download files from the VM

```bash
# Download a file from VM to local machine
gcloud compute scp ubuntu-workstation:/home/ubuntu/file.zip /local/path/ --zone=europe-west4-a --project=cegeka-gcp-awareness

# Download folder recursively
gcloud compute scp --recurse ubuntu-workstation:/home/ubuntu/folder /local/path/ --zone=europe-west4-a --project=cegeka-gcp-awareness
```

## 🔧 Post-Installation Steps

### 1. Change Default Password (Important!)

After first RDP connection:

```bash
sudo passwd ubuntu
```

### 2. Verify Docker Installation

```bash
docker --version
docker compose version

# Test Docker
docker run hello-world
```

### 3. Configure Development Tools

The VM comes pre-installed with:
- **Git Credential Manager** and **GitHub CLI** for Git authentication
- **NVM (Node Version Manager)** with latest Node.js LTS
- **SDKMAN** with Java 21, Gradle, and Maven

#### Configure Git Authentication

#### Option A: Using GitHub CLI (Recommended)

```bash
# Authenticate with GitHub using device flow
gh auth login

# Follow the prompts:
# - Select GitHub.com
# - Select HTTPS
# - Authenticate Git with your GitHub credentials: Yes
# - Login with a web browser
# - Copy the one-time code and open the URL in your browser
```

#### Option B: Using Git Credential Manager

```bash
# GCM is already configured. On first git operation, you'll get a device code
git clone https://github.com/yourusername/yourrepo.git

# Follow the URL and enter the code shown
```

#### Option C: SSH Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your@email.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: https://github.com/settings/keys
```

#### Using NVM (Node Version Manager)

```bash
# NVM is already configured. Check Node.js version
node --version
npm --version

# List available Node versions
nvm list-remote

# Install a specific Node version
nvm install 18.20.0

# Switch between versions
nvm use 18
nvm use --lts

# Set default version
nvm alias default 20
```

#### Using SDKMAN

```bash
# SDKMAN is already configured. Check installed SDKs
sdk list

# View installed Java versions
sdk list java

# Install a different Java version
sdk install java 17.0.13-tem

# Switch Java versions
sdk use java 17.0.13-tem
sdk default java 21.0.5-tem

# Install other tools
sdk install kotlin
sdk install scala
sdk install groovy

# Check current versions
java -version
gradle --version
mvn --version
```

### 4. Check Startup Script Logs

```bash
cat /var/log/startup-script.log
```

### 5. Update System (Optional)

```bash
sudo apt update
sudo apt upgrade -y
```

## 💰 Cost Optimization

Current configuration uses `e2-highmem-4`:
- **4 vCPUs**
- **32 GB RAM**
- **~$132/month** in europe-west4 region

### Alternative Machine Types:

If you need more CPU power:

```hcl
# In terraform.tfvars:
machine_type = "t2d-standard-8"  # 8 vCPUs, 32GB RAM, ~$163/month
```

If you can accept 16GB RAM (cheaper):

```hcl
machine_type = "e2-standard-4"   # 4 vCPUs, 16GB RAM, ~$101/month
```

### Use Spot/Preemptible Instances (60-91% discount):

Add to `compute-instance.tf`:

```hcl
resource "google_compute_instance" "ubuntu_workstation" {
  # ... existing config ...

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}
```

**Note**: Spot instances can be terminated by Google at any time.

## 🔒 Security Best Practices

### 1. Remove Public IP (Use IAP Only)

In `compute-instance.tf`, comment out the `access_config` block:

```hcl
network_interface {
  network = "default"

  # Comment out for IAP-only access (no public IP)
  # access_config {
  #   # Ephemeral public IP
  # }
}
```

### 2. Restrict RDP Access by IP

In `compute-instance.tf`, change firewall rule:

```hcl
resource "google_compute_firewall" "allow_rdp" {
  # ... existing config ...

  # Allow only from your IP
  source_ranges = ["YOUR_IP_ADDRESS/32"]
}
```

### 3. Enable OS Login (Recommended)

Already enabled via metadata. Use gcloud SSH instead of password auth:

```bash
gcloud compute ssh ubuntu-workstation --zone=europe-west4-a
```

### 4. Enable Automatic Updates

SSH into the VM and enable unattended upgrades:

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 🐳 Docker Usage Examples

### Run a Container

```bash
docker run -d -p 8080:80 nginx
```

### Use Docker Compose

```bash
# Create docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
EOF

# Start services
docker compose up -d
```

## 📊 Monitoring and Logs

### View Startup Script Progress

```bash
# Follow startup script logs in real-time
tail -f /var/log/startup-script.log
```

### Check if Startup Script Completed

```bash
ls /var/log/startup-script-complete
```

### View XRDP Logs

```bash
sudo tail -f /var/log/xrdp.log
sudo tail -f /var/log/xrdp-sesman.log
```

### GCP Console Monitoring

1. Go to **Compute Engine** > **VM instances**
2. Click on your instance
3. View **Monitoring** tab for CPU, disk, network usage

## 🛠️ Troubleshooting

### Cannot connect via RDP

1. **Check firewall rules**:
   ```bash
   gcloud compute firewall-rules list --filter="name=allow-rdp-workstation"
   ```

2. **Check XRDP status**:
   ```bash
   gcloud compute ssh ubuntu-workstation --zone=europe-west4-a
   sudo systemctl status xrdp
   ```

3. **Check startup script completed**:
   ```bash
   gcloud compute ssh ubuntu-workstation --zone=europe-west4-a
   cat /var/log/startup-script.log | grep "Setup Complete"
   ```

### IAP Tunnel not working

1. **Enable IAP API**:
   ```bash
   gcloud services enable iap.googleapis.com
   ```

2. **Check IAM permissions**:
   ```bash
   gcloud projects get-iam-policy cegeka-gcp-awareness \
     --flatten="bindings[].members" \
     --filter="bindings.role:roles/iap.tunnelResourceAccessor"
   ```

3. **Test connection**:
   ```bash
   gcloud compute ssh ubuntu-workstation --zone=europe-west4-a --tunnel-through-iap
   ```

### Docker not working

1. **Check Docker status**:
   ```bash
   sudo systemctl status docker
   ```

2. **Check user in docker group**:
   ```bash
   groups ubuntu
   ```

3. **Re-login** if you just added user to docker group

### Copy/Paste (Clipboard) not working via RDP

1. **In Windows Remote Desktop Client** (before connecting):
   - Click **Show Options**
   - Go to **Local Resources** tab
   - Ensure **Clipboard** is checked under "Local devices and resources"
   - Click **Details** and verify "Clipboard" is enabled
   - Connect to the VM

2. **If still not working**, SSH into the VM and restart XRDP:
   ```bash
   gcloud compute ssh ubuntu-workstation --zone=europe-west4-a --project=cegeka-gcp-awareness
   sudo systemctl restart xrdp
   ```

3. **Disconnect and reconnect** your RDP session

**Note:** Clipboard support is automatically configured in the startup script via PulseAudio integration.

## 🗑️ Cleanup

To destroy all resources and stop billing:

```bash
terraform destroy
```

## 📚 Additional Resources

- [GCP Compute Engine Documentation](https://cloud.google.com/compute/docs)
- [IAP Desktop GitHub](https://github.com/GoogleCloudPlatform/iap-desktop)
- [Docker Documentation](https://docs.docker.com/)
- [Xfce Desktop](https://www.xfce.org/)
- [XRDP Documentation](http://xrdp.org/)

## 📝 Notes

- Default user: `ubuntu` / Password: `ChangeMe123!` (**CHANGE THIS!**)
- Startup script logs: `/var/log/startup-script.log`
- RDP Port: 3389
- SSH Port: 22
- Docker installed with latest stable version
- Xfce desktop environment (lightweight and fast)
- Firewall (UFW) enabled with SSH and RDP allowed

## 🆘 Support

For issues with:
- **Terraform**: Check [Terraform GCP Provider docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- **GCP IAP**: Check [IAP documentation](https://cloud.google.com/iap/docs)
- **This configuration**: Open an issue on the repository
