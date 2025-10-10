# Start/Stop Ubuntu Workstation - Quick Reference

## 🚀 Start the VM

```bash
gcloud compute instances start ubuntu-workstation --zone=europe-west4-a
```

## 🛑 Stop the VM

```bash
gcloud compute instances stop ubuntu-workstation --zone=europe-west4-a
```

## 📊 Check VM Status

```bash
gcloud compute instances describe ubuntu-workstation --zone=europe-west4-a --format="get(status)"
```

Possible statuses: `RUNNING`, `TERMINATED`, `STOPPING`, `PROVISIONING`

## 📋 List All Your VMs

```bash
gcloud compute instances list
```

## 🔄 Restart the VM

```bash
gcloud compute instances reset ubuntu-workstation --zone=europe-west4-a
```

## ⏰ Auto Shutdown

The VM is configured to **automatically shut down at 22:30 CET every night** via Cloud Scheduler.

You don't need to remember to turn it off - it will stop automatically!

## 💰 Cost Savings Tip

The VM only charges when it's **RUNNING**. When stopped, you only pay for disk storage (~$16/month for 400GB).

**Estimated costs:**
- Running 24/7: ~$148/month (VM + disk)
- Running 8 hours/day: ~$55/month (VM) + $16/month (disk) = ~$71/month
- Stopped: $16/month (disk only)

## 🌐 Get VM Public IP

```bash
gcloud compute instances describe ubuntu-workstation \
  --zone=europe-west4-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

## 🔗 Quick Connect via RDP

1. **Start the VM:**
   ```bash
   gcloud compute instances start ubuntu-workstation --zone=europe-west4-a
   ```

2. **Wait ~30 seconds** for it to boot

3. **Get the IP:**
   ```bash
   gcloud compute instances describe ubuntu-workstation \
     --zone=europe-west4-a \
     --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
   ```

4. **Connect via Remote Desktop** using the IP address
   - Username: `ubuntu`
   - Password: `ChangeMe123!` (change on first login!)

## 🔒 Connect via IAP Tunnel (Secure)

```bash
# Create tunnel
gcloud compute start-iap-tunnel ubuntu-workstation 3389 \
  --local-host-port=localhost:3389 \
  --zone=europe-west4-a

# Then connect via Remote Desktop to: localhost:3389
```

## 📝 Notes

- The VM must be in `RUNNING` state before you can connect
- Boot time: ~30-60 seconds after start command
- Auto-shutdown at 22:30 CET prevents forgetting to turn it off
- Remember to stop the VM manually if you finish earlier to save costs
