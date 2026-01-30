###################################
# Create Compute Instance - Main #
###################################

# Create a GCP Compute Engine Instance
resource "google_compute_instance" "ubuntu_workstation" {
  project      = var.gcp_project
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  # Boot disk configuration
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-standard" # Use pd-standard for cost optimization (pd-ssd is more expensive)
    }
  }

  # Network configuration
  network_interface {
    network = "default"

    # Comment out access_config to remove public IP (recommended for IAP-only access)
    # Uncomment if you need direct RDP access
    access_config {
      # Ephemeral public IP
    }
  }

  # Metadata and startup script
  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  # Allow stopping for updates
  allow_stopping_for_update = true

  # Service account with necessary permissions
  # Using default compute service account
  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["rdp-server", "iap-ssh"]

  labels = {
    environment = "workstation"
    purpose     = "docker-desktop"
  }
}

# Firewall rule for public SSH and RDP access
resource "google_compute_firewall" "allow_public_ssh_rdp" {
  name    = "allow-public-ssh-rdp"
  network = "default"
  project = var.gcp_project

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  # Allow from anywhere
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["rdp-server", "iap-ssh"]
}

# Firewall rule for IAP SSH/RDP tunneling
resource "google_compute_firewall" "allow_iap" {
  name    = "allow-iap-ssh-rdp"
  network = "default"
  project = var.gcp_project

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}

# Firewall rule for IAP Desktop RDP access
# Required for IAP Desktop to discover and connect to RDP servers
resource "google_compute_firewall" "allow_iap_rdp_server" {
  name    = "allow-iap-rdp-server"
  network = "default"
  project = var.gcp_project

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["rdp-server"]
}

# IAM binding to allow IAP tunnel access
# Note: This requires iam.serviceAccounts permissions
# If you get permission errors, add this role manually via GCP Console:
# IAM & Admin > Add member > your-email@example.com > Role: IAP-secured Tunnel User
# resource "google_project_iam_member" "iap_tunnel_user" {
#   project = var.gcp_project
#   role    = "roles/iap.tunnelResourceAccessor"
#   member  = "user:${var.user_email}"
# }
