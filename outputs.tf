output "instance_name" {
  value       = module.workstation.instance_name
  description = "The name of the compute instance"
}

output "instance_public_ip" {
  value       = module.workstation.instance_public_ip
  description = "The public IP address of the compute instance"
}

output "instance_private_ip" {
  value       = module.workstation.instance_private_ip
  description = "The private IP address of the compute instance"
}

output "rdp_connection_info" {
  value = <<-EOT

    ========================================
    RDP Connection Information
    ========================================

    Instance Name: ${module.workstation.instance_name}
    Public IP: ${module.workstation.instance_public_ip}
    Zone: ${var.gcp_zone}

    Default User: ubuntu
    Default Password: ChangeMe123! (CHANGE THIS IMMEDIATELY!)

    ========================================
    Connection Methods:
    ========================================

    1. DIRECT RDP CONNECTION (Windows Remote Desktop):
       - Open Remote Desktop Connection
       - Enter: ${module.workstation.instance_public_ip}
       - Port: 3389
       - Username: ubuntu
       - Password: ChangeMe123!

    2. IAP TUNNEL (Recommended for secure access):

       a) Using gcloud command:
       gcloud compute start-iap-tunnel ${module.workstation.instance_name} 3389 \
         --local-host-port=localhost:3389 \
         --zone=${var.gcp_zone} \
         --project=${var.gcp_project}

       Then connect via Remote Desktop to: localhost:3389

       b) Using IAP Desktop (Windows application):
       - Download from: https://github.com/GoogleCloudPlatform/iap-desktop
       - Install and authenticate with your GCP account
       - Find your VM and double-click to connect

    ========================================
  EOT
}
