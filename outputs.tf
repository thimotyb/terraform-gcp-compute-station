##################################
# Compute Instance - Output      #
##################################

output "instance_name" {
  value       = google_compute_instance.ubuntu_workstation.name
  description = "The name of the compute instance"
}

output "instance_public_ip" {
  value       = google_compute_instance.ubuntu_workstation.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of the compute instance"
}

output "instance_private_ip" {
  value       = google_compute_instance.ubuntu_workstation.network_interface[0].network_ip
  description = "The private IP address of the compute instance"
}

output "rdp_connection_info" {
  value = <<-EOT

    ========================================
    RDP Connection Information
    ========================================

    Instance Name: ${google_compute_instance.ubuntu_workstation.name}
    Public IP: ${google_compute_instance.ubuntu_workstation.network_interface[0].access_config[0].nat_ip}
    Zone: ${var.gcp_zone}

    Default User: ubuntu
    Default Password: ChangeMe123! (CHANGE THIS IMMEDIATELY!)

    ========================================
    Connection Methods:
    ========================================

    1. DIRECT RDP CONNECTION (Windows Remote Desktop):
       - Open Remote Desktop Connection
       - Enter: ${google_compute_instance.ubuntu_workstation.network_interface[0].access_config[0].nat_ip}
       - Port: 3389
       - Username: ubuntu
       - Password: ChangeMe123!

    2. IAP TUNNEL (Recommended for secure access):

       a) Using gcloud command:
       gcloud compute start-iap-tunnel ${google_compute_instance.ubuntu_workstation.name} 3389 \
         --local-host-port=localhost:3389 \
         --zone=${var.gcp_zone} \
         --project=${var.gcp_project}

       Then connect via Remote Desktop to: localhost:3389

       b) Using IAP Desktop (Windows application):
       - Download from: https://github.com/GoogleCloudPlatform/iap-desktop
       - Install and authenticate with your GCP account
       - Find your VM and double-click to connect

    ========================================
    Post-Installation Steps:
    ========================================

    1. Connect via RDP using one of the methods above
    2. Change the default password immediately:
       sudo passwd ubuntu

    3. Verify Docker installation:
       docker --version
       docker compose version

    4. Check startup script logs:
       cat /var/log/startup-script.log

    5. Add additional users if needed:
       sudo adduser newusername
       sudo usermod -aG docker newusername

    ========================================
  EOT
  description = "Complete RDP connection information and setup instructions"
}

output "scheduler_info" {
  value = <<-EOT

    ========================================
    Auto Shutdown Schedule
    ========================================

    VM will automatically STOP at: 22:30 CET every day

    To manually start the VM:
    gcloud compute instances start ${google_compute_instance.ubuntu_workstation.name} --zone=${var.gcp_zone}

    To manually stop the VM:
    gcloud compute instances stop ${google_compute_instance.ubuntu_workstation.name} --zone=${var.gcp_zone}

    To disable auto-shutdown, comment out the scheduler.tf file and run terraform apply

    ========================================
  EOT
  description = "Auto shutdown schedule information"
}
