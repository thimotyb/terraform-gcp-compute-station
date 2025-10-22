# GCP Settings
gcp_project = "cegeka-gcp-awareness"
gcp_region  = "us-east1"

# Compute Instance
instance_name = "ubuntu-workstation"
machine_type  = "e2-highmem-4"  # 4 vCPU, 32GB RAM - most cost-effective (~$132/month)
gcp_zone      = "us-east1-b"
disk_size_gb  = 400  # 400GB disk (saves ~$40/month vs 1TB)
user_email    = "your-email@example.com"  # CHANGE THIS to your GCP account email
