# Create a GCP Compute Engine Instance
resource "google_compute_instance" "ubuntu_workstation" {
  project      = var.gcp_project
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = var.startup_script_content != null ? var.startup_script_content : file("${path.module}/startup-script.sh")

  allow_stopping_for_update = true

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["rdp-server", "iap-ssh"]

  labels = {
    environment = "workstation"
    purpose     = "ai-lab"
  }
}

# Firewall rule for public SSH and RDP access
resource "google_compute_firewall" "allow_public_ssh_rdp" {
  name    = "allow-public-ssh-rdp-${var.instance_name}"
  network = "default"
  project = var.gcp_project

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["rdp-server", "iap-ssh"]
}

# Firewall rule for IAP SSH/RDP tunneling
resource "google_compute_firewall" "allow_iap" {
  name    = "allow-iap-ssh-rdp-${var.instance_name}"
  network = "default"
  project = var.gcp_project

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}

# Firewall rule for IAP Desktop RDP access
resource "google_compute_firewall" "allow_iap_rdp_server" {
  name    = "allow-iap-rdp-server-${var.instance_name}"
  network = "default"
  project = var.gcp_project

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["rdp-server"]
}

# Cloud Scheduler - Auto Shutdown VM
resource "google_service_account" "scheduler_sa" {
  account_id   = "sched-sa-${var.instance_name}"
  display_name = "Scheduler Service Account for ${var.instance_name}"
  project      = var.gcp_project
}

resource "google_project_iam_member" "scheduler_compute_admin" {
  project = var.gcp_project
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

resource "google_cloud_scheduler_job" "stop_vm_nightly" {
  name        = "stop-${var.instance_name}-nightly"
  description = "Stop ${var.instance_name} every night at 22:30 CET"
  schedule    = "30 22 * * *"
  time_zone   = "Europe/Rome"
  project     = var.gcp_project
  region      = var.gcp_region

  http_target {
    http_method = "POST"
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.gcp_project}/zones/${var.gcp_zone}/instances/${google_compute_instance.ubuntu_workstation.name}/stop"

    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }
}
