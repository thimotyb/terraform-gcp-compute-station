# Connecting to Ubuntu Workstation via RDP with IAP

## Important: IAP Desktop Limitation

**IAP Desktop does NOT support RDP connections to Linux VMs**, even with XRDP installed.

IAP Desktop is designed to:
- Use **RDP** for Windows VMs only
- Use **SSH** for Linux VMs only

However, you can still use IAP tunneling with RDP to your Ubuntu workstation using the methods below.

## Method 1: Using the Helper Script (Easiest)

### Step 1: Start the IAP Tunnel

From your local machine (Windows/Mac/Linux), run:

```bash
./connect-rdp.sh
```

This will create an IAP tunnel and keep it open.

### Step 2: Connect via Remote Desktop

While the tunnel is running:

1. Open **Remote Desktop Connection** (mstsc.exe on Windows)
2. Connect to: `localhost:3389`
3. Username: `ubuntu`
4. Password: `ChangeMe123!` (change this!)

### Step 3: Close the Tunnel

Press `Ctrl+C` in the terminal when you're done to close the tunnel.

## Method 2: Manual gcloud Command

If you prefer to run the command manually:

```bash
gcloud compute start-iap-tunnel ubuntu-workstation 3389 \
  --local-host-port=localhost:3389 \
  --zone=europe-west1-c \
  --project=cegeka-gcp-awareness
```

Then connect to `localhost:3389` with Remote Desktop.

## Method 3: Direct RDP (No IAP - Less Secure)

If you need direct RDP access without IAP:

### Get the Public IP:

```bash
gcloud compute instances describe ubuntu-workstation \
  --zone=europe-west1-c \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

### Connect:

1. Open Remote Desktop Connection
2. Enter the public IP address
3. Port: 3389
4. Username: `ubuntu`
5. Password: `ChangeMe123!`

**Note:** This method exposes RDP to the internet. IAP tunnel is more secure.

## Why IAP Desktop Shows Only SSH

IAP Desktop detects the operating system of your VM:
- **Windows OS** → Shows RDP option
- **Linux OS** → Shows SSH option only

There is no way to make IAP Desktop show RDP for Linux VMs because it's not supported by the application.

## Alternative: Use IAP Desktop for SSH + Port Forwarding

You could theoretically use IAP Desktop's SSH connection with local port forwarding to tunnel RDP, but the helper script method above is much simpler.

## Firewall Rules Created

The following firewall rules have been configured:

1. **allow-iap-rdp-server**: Allows IAP IP range (35.235.240.0/20) to reach RDP port on instances with `rdp-server` tag
2. **allow-rdp-workstation**: Allows direct RDP access from anywhere (0.0.0.0/0)

Both rules are active and allow RDP connections via IAP tunnel or direct access.

## Troubleshooting

### IAP Tunnel Connection Refused

**Problem:** `gcloud compute start-iap-tunnel` fails with "connection refused"

**Solutions:**
1. Ensure VM is running: `gcloud compute instances describe ubuntu-workstation --zone=europe-west1-c --format="get(status)"`
2. Check XRDP is running: `gcloud compute ssh ubuntu-workstation --zone=europe-west1-c --command="sudo systemctl status xrdp"`
3. Verify firewall rules: `gcloud compute firewall-rules list --filter="name~rdp"`

### IAP Desktop Doesn't Show RDP Option

**Problem:** IAP Desktop only shows SSH connection for the VM

**Solution:** This is expected behavior. IAP Desktop does not support RDP for Linux VMs. Use the `connect-rdp.sh` script instead.

### Cannot Authenticate

**Problem:** RDP asks for username/password but credentials don't work

**Solutions:**
1. Default credentials: username=`ubuntu`, password=`ChangeMe123!`
2. If you changed the password, use the new one
3. Reset password via SSH: `gcloud compute ssh ubuntu-workstation --zone=europe-west1-c --command="sudo passwd ubuntu"`

## Security Recommendations

1. **Use IAP tunnel** instead of direct RDP when possible
2. **Change the default password** immediately after first login
3. **Consider removing the public IP** from the VM and using IAP-only access:
   - Edit `compute-instance.tf`
   - Comment out the `access_config` block
   - Run `terraform apply`

## References

- [IAP Desktop Documentation](https://googlecloudplatform.github.io/iap-desktop/)
- [Cloud IAP TCP Forwarding](https://cloud.google.com/iap/docs/using-tcp-forwarding)
- [XRDP Documentation](http://xrdp.org/)
